extends RefCounted

# MIN-1 is a third fixed site with its own ledger and its own replay validator.
# The waterworks and relay wires stay intact: neither validator vouches for MINE_*.
#
# Scope: three rooms, one-time observations, a permanent discovery. No combat, no
# loot, no controller, no machine, no companion work. The deeper passage is sealed.
const SITE: String = "dungeon:collapsed_mine"
const HOME: StringName = &"settlement:iron_pass"
const MOVES_PER_DAY: int = 4
const ROOMS: Dictionary = {"mine_entrance": "礦道入口", "mine_gallery": "外段坑道", "mine_pumphall": "舊集水廳"}
const PASSAGES: Dictionary = {"mine_entrance": ["mine_gallery"], "mine_gallery": ["mine_entrance", "mine_pumphall"], "mine_pumphall": ["mine_gallery"]}
# fact id -> the room it can be seen in, and the fact that must have been seen first.
const FACTS: Dictionary = {
	"cracked_supports": {"room": "mine_gallery", "after": ""},
	"stalled_pump": {"room": "mine_pumphall", "after": ""},
	"controller_missing": {"room": "mine_pumphall", "after": "stalled_pump"},
}
# Seeing this fact is the permanent discovery: the equipment is repairable, the control module is gone.
const DISCOVERY_FACT: String = "controller_missing"
const EVENTS: Dictionary = {"MINE_ENTERED": 2, "MINE_MOVED": 3, "MINE_OBSERVED": 3, "MINE_LEFT": 2, "MINE_DAY_SPENT": 8, "MINE_TRIP_ENDED": 3}
const COMMAND_SIZES: Dictionary = {"ENTER": 2, "MOVE": 4, "OBSERVE": 3, "EXIT": 2}
# Clearing a rockslide on the road costs one scrap (simulation_engine CLEAR); pinned by a test.
const ROAD_CLEAR_SCRAP: int = 1

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = {"active": false, "room_id": "", "from_room_id": "", "visited": [], "observed": [], "discovered": false, "work_units": 0, "trip_moves": 0, "trip_days": 0, "entries": 0}
	if world == null or world.player == null: return s
	for e: EventRecord in world.event_log:
		if e.actor_id != world.player.npc_id or e.type not in EVENTS: continue
		match e.type:
			"MINE_ENTERED":
				s.active = true
				s.room_id = "mine_entrance"
				s.from_room_id = "outside"
				s.trip_moves = 0
				s.trip_days = 0
				s.work_units = 0
				s.entries += 1
			"MINE_MOVED":
				s.room_id = e.payload.room_id
				s.from_room_id = e.payload.from_room_id
				s.work_units += 1
				s.trip_moves += 1
			"MINE_DAY_SPENT":
				s.work_units = 0
				s.trip_days += 1
			"MINE_OBSERVED":
				if e.payload.fact_id not in s.observed: s.observed.append(e.payload.fact_id)
				if e.payload.fact_id == DISCOVERY_FACT: s.discovered = true
			"MINE_LEFT", "MINE_TRIP_ENDED": s.active = false
		if s.active and s.room_id not in s.visited: s.visited.append(s.room_id)
	return s

static func visit_moves() -> int:
	# Entrance to the farthest room and back.
	return 2 * (ROOMS.size() - 1)

# The pre-departure and entrance disclosure. Everything is derived from the same
# rules the engine applies; nothing here is a promise about a particular road.
# Pinned against the real engine by tests/test_mine_entrance.gd.
static func forecast(route_days: int, companion: String) -> Dictionary:
	var info: Dictionary = SimulationEngine.Party.info(companion) if companion != "" and SimulationEngine.Party.exists(companion) else {}
	var guided: bool = bool(info.get("finds_water", false))
	# Each in-transit tick is charged; the arrival tick settles the traveller first.
	var transit_ticks: int = maxi(0, route_days - 1)
	var road_water: int = (0 if guided else 1) + int(info.get("road_water", 0))
	var road_food: int = 1 + int(info.get("road_food", 0))
	var mine_days: int = int(ceil(float(visit_moves()) / float(MOVES_PER_DAY)))
	var mine_water: int = 1 + int(info.get("road_water", 0))
	var mine_food: int = 1 + int(info.get("road_food", 0))
	var legs: int = 2
	return {
		"route_days": route_days, "legs": legs, "transit_days": transit_ticks * legs, "mine_days": mine_days,
		"water": road_water * transit_ticks * legs + mine_water * mine_days,
		"food": road_food * transit_ticks * legs + mine_food * mine_days,
		"scrap": ROAD_CLEAR_SCRAP,
		"extra_day_water": road_water, "extra_day_food": road_food,
		"bribe_caps": TravelEncounter.BANDIT_BRIBE_CAPS,
		"companion": companion,
	}

static func forecast_lines(f: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("預估往返：%d 水、%d 糧、%d 廢料（路程 %d 天；礦道 %d 天）" % [f.water, f.food, f.scrap, f.route_days, f.mine_days])
	lines.append("建議額外準備：%d 瓶蓋，或額外 %d 水＋%d 糧" % [f.bribe_caps, f.extra_day_water, f.extra_day_food])
	lines.append("路上事件可能延長行程。")
	return lines

static func authorize(world: WorldState, payload: Dictionary) -> String:
	var history_error: String = SimulationEngine.Dungeon.validate_world(world)
	if history_error != "": return history_error
	if typeof(payload.get("site_id")) != TYPE_STRING or payload.site_id != SITE or typeof(payload.get("command")) != TYPE_STRING: return "MINE_INVALID_INTENT"
	if payload.command not in COMMAND_SIZES or payload.size() != int(COMMAND_SIZES[payload.command]): return "MINE_INVALID_INTENT"
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or not life.is_alive(): return "MINE_PLAYER_DEAD"
	if life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME: return "MINE_REQUIRES_IRON_PASS"
	if SimulationEngine.Dungeon.state(world).active or SimulationEngine.Relay.state(world).active or world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0: return "MINE_ACTIVITY_PENDING"
	var s: Dictionary = state(world)
	if payload.command == "ENTER": return "MINE_ALREADY_INSIDE" if s.active else ""
	if not s.active: return "MINE_NOT_INSIDE"
	match payload.command:
		"MOVE":
			if typeof(payload.get("from_room_id")) != TYPE_STRING or typeof(payload.get("room_id")) != TYPE_STRING or payload.from_room_id != s.room_id: return "MINE_INVALID_INTENT"
			return gate(s.room_id, payload.room_id)
		"OBSERVE": return observation_refusal(s, payload.get("fact_id"))
		"EXIT": return "" if s.room_id == "mine_entrance" else "MINE_EXIT_REQUIRES_ENTRANCE"
	return "MINE_UNAUTHORIZED_COMMAND"

static func gate(from_room: String, to_room: String) -> String:
	if from_room not in PASSAGES or to_room not in PASSAGES[from_room]: return "MINE_INVALID_PASSAGE"
	return ""

static func observation_refusal(s: Dictionary, fact: Variant) -> String:
	if typeof(fact) != TYPE_STRING or fact not in FACTS: return "MINE_INVALID_INTENT"
	if fact in s.observed: return "MINE_ALREADY_OBSERVED"
	var rule: Dictionary = FACTS[fact]
	if s.room_id != rule.room: return "MINE_OBSERVATION_UNAVAILABLE"
	if rule.after != "" and rule.after not in s.observed: return "MINE_OBSERVE_FIRST"
	return ""

static func commit(world: WorldState, payload: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var error: String = authorize(world, payload)
	if error != "": return {"success": false, "error": error}
	var s: Dictionary = state(world)
	if payload.command == "MOVE" and s.work_units == MOVES_PER_DAY - 1 and engine == null: return {"success": false, "error": "MINE_CLOCK_REQUIRED"}
	var kind: String = {"ENTER": "MINE_ENTERED", "MOVE": "MINE_MOVED", "OBSERVE": "MINE_OBSERVED", "EXIT": "MINE_LEFT"}[payload.command]
	var facts: Dictionary = {"dungeon_id": SITE, "room_id": "mine_entrance" if payload.command == "ENTER" else s.room_id}
	match payload.command:
		"MOVE":
			facts.room_id = payload.room_id
			facts.from_room_id = s.room_id
		"OBSERVE": facts.fact_id = payload.fact_id
	record(world, kind, facts, world.current_day, events)
	if payload.command == "MOVE" and state(world).work_units == MOVES_PER_DAY:
		var daily: Array[EventRecord] = engine.tick(world)
		if events != null: events.append_array(daily)
	return {"success": true, "action": "DUNGEON_ACTION", "exploration": state(world)}

static func record(world: WorldState, kind: String, facts: Dictionary, day: int, events: Array[EventRecord]) -> void:
	var e: EventRecord = EventRecord.new(day, kind, world.player.npc_id, StringName(SITE), facts)
	world.record_event(e)
	if events != null: events.append(e)

static func consume_daily_supplies(world: WorldState, day: int, events: Array[EventRecord]) -> Dictionary:
	var water: int = world.player.inventory.water
	var food: int = world.player.inventory.food
	var companion: String = SimulationEngine.Dungeon.Party.current(world)
	var budget: Dictionary = SimulationEngine.Dungeon.ration_budget(water, food, companion)
	world.player.inventory.water = int(budget.water)
	world.player.inventory.food = int(budget.food)
	record(world, "MINE_DAY_SPENT", {"dungeon_id": SITE, "room_id": state(world).room_id, "water_before": water, "food_before": food, "water_after": budget.water, "food_after": budget.food, "companion_id": companion, "companion_fed": budget.fed}, day, events)
	if companion != "" and not budget.fed:
		var leave: EventRecord = EventRecord.new(day, "COMPANION_LEFT", world.player.npc_id, StringName(SITE), {"companion_id": companion, "reason": "HUNGER"})
		world.record_event(leave)
		events.append(leave)
	return {"water_unmet": 1.0 if water == 0 else 0.0, "food_unmet": 1.0 if food == 0 else 0.0}

static func end_deprivation_trip(world: WorldState, day: int, events: Array[EventRecord]) -> void:
	if not state(world).active: return
	if not world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive():
		record(world, "MINE_TRIP_ENDED", {"dungeon_id": SITE, "room_id": state(world).room_id, "cause": world.event_log.back().payload.cause}, day, events)

static func number(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

static func text(value: Variant, expected: String) -> bool:
	return typeof(value) == TYPE_STRING and value == expected

static func validate_world(world: WorldState) -> String:
	var s: Dictionary = {"active": false, "room_id": "", "observed": []}
	var units: int = 0
	var last_day: int = -1
	var companion: String = ""
	var waterworks: bool = false
	var relay: bool = false
	for index: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[index]
		var p: Dictionary = e.payload
		var mine_event: bool = e.type.begins_with("MINE_")
		if world.player != null and e.actor_id == world.player.npc_id:
			if e.type == "DUNGEON_ENTERED":
				if s.active: return "MINE_CONFLICTING_ACTIVITY"
				waterworks = true
			elif e.type in ["DUNGEON_LEFT", "DUNGEON_TRIP_ENDED"]: waterworks = false
			elif e.type == "RELAY_ENTERED":
				if s.active: return "MINE_CONFLICTING_ACTIVITY"
				relay = true
			elif e.type in ["RELAY_LEFT", "RELAY_TRIP_ENDED"]: relay = false
			elif e.type == "COMPANION_JOINED": companion = String(p.get("companion_id", ""))
			elif e.type == "COMPANION_LEFT": companion = ""
			elif s.active and e.type in ["PLAYER_TRAVEL_STARTED", "TRAVEL_ENCOUNTER_STARTED"]: return "MINE_CONFLICTING_ACTIVITY"
		if not mine_event: continue
		if e.type not in EVENTS or world.player == null or e.actor_id != world.player.npc_id or e.target_id != StringName(SITE): return "MINE_INVALID_EVENT_OWNER"
		if p.size() != int(EVENTS[e.type]) or not text(p.get("dungeon_id"), SITE) or typeof(p.get("room_id")) != TYPE_STRING or p.room_id not in ROOMS: return "MINE_INVALID_EVENT_PAYLOAD"
		if e.day < 0 or e.day < last_day or e.day > world.current_day: return "MINE_INVALID_EVENT_DAY"
		var previous_day: int = last_day
		last_day = e.day
		if units >= MOVES_PER_DAY and e.type != "MINE_DAY_SPENT": return "MINE_DAY_PENDING"
		if e.type == "MINE_ENTERED":
			if s.active or waterworks or relay or p.room_id != "mine_entrance": return "MINE_INVALID_ENTRY"
			s.active = true
			s.room_id = p.room_id
			units = 0
			continue
		if not s.active or (e.type != "MINE_MOVED" and p.room_id != s.room_id): return "MINE_INVALID_LOCAL_CONTEXT"
		match e.type:
			"MINE_MOVED":
				if not text(p.get("from_room_id"), s.room_id) or gate(s.room_id, p.room_id) != "": return "MINE_INVALID_PASSAGE_HISTORY"
				s.room_id = p.room_id
				units += 1
			"MINE_OBSERVED":
				if observation_refusal(s, p.get("fact_id")) != "": return "MINE_INVALID_OBSERVATION"
				s.observed.append(p.fact_id)
			"MINE_LEFT":
				if s.room_id != "mine_entrance": return "MINE_INVALID_EXIT"
				s.active = false
			"MINE_DAY_SPENT":
				if units != MOVES_PER_DAY or e.day != previous_day + 1: return "MINE_INVALID_DAY_CONTEXT"
				for key: String in ["water_before", "food_before", "water_after", "food_after"]:
					if not number(p.get(key), 0, 2147483647): return "MINE_INVALID_SUPPLIES"
				if not text(p.get("companion_id"), companion) or typeof(p.get("companion_fed")) != TYPE_BOOL: return "MINE_INVALID_SUPPLIES"
				var budget: Dictionary = SimulationEngine.Dungeon.ration_budget(int(p.water_before), int(p.food_before), companion)
				if p.water_after != budget.water or p.food_after != budget.food or p.companion_fed != budget.fed: return "MINE_INVALID_SUPPLIES"
				if companion != "" and not budget.fed:
					if index + 1 >= world.event_log.size(): return "MINE_MISSING_HUNGER_DEPARTURE"
					var leave: EventRecord = world.event_log[index + 1]
					if leave.type != "COMPANION_LEFT" or leave.actor_id != e.actor_id or leave.target_id != e.target_id or leave.day != e.day or leave.payload.size() != 2 or not text(leave.payload.get("companion_id"), companion) or not text(leave.payload.get("reason"), "HUNGER"): return "MINE_MISSING_HUNGER_DEPARTURE"
				units = 0
			"MINE_TRIP_ENDED":
				if index == 0 or typeof(p.get("cause")) != TYPE_STRING or p.cause not in ["dehydration", "starvation"]: return "MINE_INVALID_DEATH"
				var death: EventRecord = world.event_log[index - 1]
				if death.type != "PLAYER_DIED" or death.actor_id != e.actor_id or death.target_id != HOME or death.day != e.day or not text(death.payload.get("cause"), p.cause) or world.npc_life_state_registry.get_life_state(e.actor_id).is_alive(): return "MINE_INVALID_DEATH"
				s.active = false
	if units >= MOVES_PER_DAY: return "MINE_DAY_PENDING"
	if s.active:
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life == null or not life.is_alive() or life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME: return "MINE_INVALID_LOCAL_CONTEXT"
		if world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0: return "MINE_CONFLICTING_ACTIVITY"
		if SimulationEngine.Dungeon.state(world).active or SimulationEngine.Relay.state(world).active: return "MINE_CONFLICTING_ACTIVITY"
	return ""
