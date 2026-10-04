extends RefCounted

# The ledger owns room checkpoints, discovery and the return shortcut.
const SITE: String = "dungeon:sealed_waterworks"
const HOME: StringName = &"settlement:gray_valley"
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Party = preload("res://simulation/party.gd")
const MAINTENANCE_COSTS: Dictionary = {"SKILL": 1, "TOOL": 2, "ABBAN": 1}
const MOVES_PER_DAY: int = 4
const PROTECTION_ITEM: String = "military_gas_mask"
const DEEP_REWARD: String = "fieldrepair_precision_kit"
const DEVICE_ARMOR: String = "leather_jacket"
const DEVICE_REWARD: String = "reinforced_leather_jacket"
const DEVICE_COST: int = 3
const DEVICE_SALVAGE: int = 4
const ROOM_ENEMIES: Dictionary = {"guard": "bandit", "pump": "feral_dog", "polluted_store": "ash_ghoul"}
const REWARDS: Dictionary = {"guard": {"caps": 5, "scrap": 2}, "pump": {"caps": 0, "scrap": 2}, "polluted_store": {"caps": 10, "scrap": 3}}
const ROOMS: Dictionary = {"entrance": "水廠入口", "foyer": "設備前廳", "guard": "警衛區", "maintenance": "維修廊", "pump": "泵房", "control": "控制室", "parts_store": "零件庫", "polluted_store": "污染庫房"}
const PASSAGES: Dictionary = {
	"entrance": ["foyer"], "foyer": ["entrance", "guard", "maintenance", "parts_store"],
	"guard": ["foyer", "pump"], "maintenance": ["foyer", "pump"],
	"pump": ["guard", "maintenance", "control", "polluted_store"],
	"control": ["pump"], "parts_store": ["foyer"], "polluted_store": ["pump"]
}
const EVENTS: Array[String] = ["DUNGEON_ENTERED", "DUNGEON_ROOM_ENTERED", "DUNGEON_LEFT", "DUNGEON_SHORTCUT_OPENED", "DUNGEON_BATTLE_STARTED", "DUNGEON_BATTLE_CONFIRMED", "DUNGEON_MAINTENANCE_OPENED", "DUNGEON_DAY_SPENT", "DUNGEON_TRIP_ENDED", "DUNGEON_TOOLS_RECOVERED", "DUNGEON_DEVICE_DECIDED"]

static func state(world: WorldState) -> Dictionary:
	var result: Dictionary = {"active": false, "room_id": "", "from_room_id": "", "visited": [], "shortcut_open": false, "cleared": [], "route_rules": 0, "maintenance_open": false, "maintenance_method": "", "trip_rules": 0, "work_units": 0, "trip_moves": 0, "trip_days": 0, "deep_rules": 0, "tools_recovered": false}
	result.device_rules = 0
	result.device_choice = ""
	result.device_day = -1
	result.device_companion = ""
	if world == null or world.player == null:
		return result
	for event: EventRecord in world.event_log:
		if event.actor_id != world.player.npc_id:
			continue
		if event.type == "FIELD_RESULT" and text_is(event.payload.get("source", "field"), "dungeon") and text_is(event.payload.get("outcome"), "VICTORY"):
			if event.payload.room_id not in result.cleared: result.cleared.append(event.payload.room_id)
		if event.type not in EVENTS: continue
		match event.type:
			"DUNGEON_ENTERED":
				result.route_rules = int(event.payload.get("route_rules", 0))
				result.trip_rules = int(event.payload.get("trip_rules", 0))
				result.deep_rules = int(event.payload.get("deep_rules", 0))
				result.device_rules = int(event.payload.get("device_rules", 0))
				result.trip_moves = 0
				result.trip_days = 0
				result.active = true
				result.room_id = "entrance"
				result.from_room_id = "outside"
			"DUNGEON_ROOM_ENTERED":
				result.room_id = event.payload.get("room_id", "")
				result.from_room_id = event.payload.get("from_room_id", "")
				if result.trip_rules == 1:
					result.work_units += 1
					result.trip_moves += 1
			"DUNGEON_DAY_SPENT":
				result.work_units = 0
				result.trip_days += 1
			"DUNGEON_LEFT", "DUNGEON_TRIP_ENDED":
				result.active = false
				result.room_id = ""
				result.from_room_id = ""
			"DUNGEON_SHORTCUT_OPENED":
				result.shortcut_open = true
			"DUNGEON_MAINTENANCE_OPENED":
				result.maintenance_open = true
				result.maintenance_method = event.payload.get("method", "")
			"DUNGEON_TOOLS_RECOVERED":
				result.tools_recovered = true
			"DUNGEON_DEVICE_DECIDED":
				result.device_choice = event.payload.choice
				result.device_day = event.day
				result.device_companion = event.payload.companion_id
			"DUNGEON_BATTLE_CONFIRMED":
				var receipt: Variant = event.payload.get("result_index", -1)
				if number(receipt, 0, world.event_log.size() - 1) and text_is(world.event_log[int(receipt)].payload.get("outcome"), "DEAD"):
					result.active = false
					result.room_id = ""
					result.from_room_id = ""
		if result.active and result.room_id not in result.visited:
			result.visited.append(result.room_id)
	return result

static func validate_world(world: WorldState) -> String:
	var field_error: String = WorldState.Field.validate_state(world.field_state)
	if field_error != "": return field_error
	if world.player != null:
		field_error = WorldState.Field.validate_kit(world.player.field_kit)
		if field_error != "": return field_error
	var room: String = ""
	var last_day: int = -1
	var shortcut_open: bool = false
	var combat: Dictionary = {}
	var cleared: Array[String] = []
	var last_battle: int = 0
	var route_rules: int = 0
	var maintenance_open: bool = false
	var companion: String = ""
	var trip_rules: int = 0
	var work_units: int = 0
	var deep_rules: int = 0
	var tools_recovered: bool = false
	var device_rules: int = 0
	var device_decided: bool = false
	for index: int in range(world.event_log.size()):
		var event: EventRecord = world.event_log[index]
		if world.player != null and event.actor_id == world.player.npc_id:
			if event.type == "COMPANION_JOINED": companion = String(event.payload.get("companion_id", ""))
			elif event.type == "COMPANION_LEFT": companion = ""
		if event.type in ["FIELD_TURN", "FIELD_RESULT"]:
			var source: Variant = event.payload.get("source", "field")
			if typeof(source) != TYPE_STRING or source not in ["field", "road", "dungeon"]: return "DUNGEON_INVALID_COMBAT_SOURCE"
			if source != "dungeon": continue
			if world.player == null or event.actor_id != world.player.npc_id or event.target_id != HOME or combat.is_empty() or not text_is(event.payload.get("dungeon_id"), SITE) or not text_is(event.payload.get("room_id"), room) or not number(event.payload.get("battle_id"), int(combat.id), int(combat.id)):
				return "DUNGEON_INVALID_COMBAT_CONTEXT"
			if event.day < last_day or event.day < 0 or event.day > world.current_day: return "DUNGEON_INVALID_EVENT_DAY"
			last_day = event.day
			var combat_error: String = _turn(combat, event.payload) if event.type == "FIELD_TURN" else _result(combat, event.payload, room, index)
			if combat_error != "": return combat_error
			if event.type == "FIELD_RESULT" and combat.outcome == "VICTORY": cleared.append(room)
			continue
		if not event.type.begins_with("DUNGEON_"):
			continue
		if event.type not in EVENTS or world.player == null or event.actor_id != world.player.npc_id or event.target_id != StringName(SITE):
			return "DUNGEON_INVALID_EVENT_OWNER"
		var payload: Dictionary = event.payload
		var expected_size: int = {"DUNGEON_ROOM_ENTERED": 3, "DUNGEON_BATTLE_STARTED": 6, "DUNGEON_BATTLE_CONFIRMED": 4, "DUNGEON_MAINTENANCE_OPENED": 5, "DUNGEON_DAY_SPENT": 8, "DUNGEON_TRIP_ENDED": 3, "DUNGEON_TOOLS_RECOVERED": 4}.get(event.type, 2)
		if event.type == "DUNGEON_ENTERED" and payload.has("route_rules"):
			expected_size = 3
			if not number(payload.route_rules, 1, 1): return "DUNGEON_INVALID_ROUTE_RULES"
		if event.type == "DUNGEON_ENTERED" and payload.has("trip_rules"):
			expected_size += 1
			if not payload.has("route_rules") or not number(payload.trip_rules, 1, 1): return "DUNGEON_INVALID_TRIP_RULES"
		if event.type == "DUNGEON_ENTERED" and payload.has("deep_rules"):
			expected_size += 1
			if not payload.has("trip_rules") or not number(payload.deep_rules, 1, 1): return "DUNGEON_INVALID_DEEP_RULES"
		if event.type == "DUNGEON_ENTERED" and payload.has("device_rules"):
			expected_size += 1
			if not payload.has("deep_rules") or not number(payload.device_rules, 1, 1): return "DUNGEON_INVALID_DEVICE_RULES"
		if event.type == "DUNGEON_DEVICE_DECIDED": expected_size = 9
		if event.type == "DUNGEON_ROOM_ENTERED" and deep_rules == 1 and text_is(payload.get("room_id"), "polluted_store"):
			expected_size += 1
			if not text_is(payload.get("protection_item"), PROTECTION_ITEM): return "DUNGEON_INVALID_PROTECTION_PROOF"
		if payload.size() != expected_size or not text_is(payload.get("dungeon_id"), SITE) or typeof(payload.get("room_id")) != TYPE_STRING:
			return "DUNGEON_INVALID_EVENT_PAYLOAD"
		if event.day < last_day or event.day < 0 or event.day > world.current_day:
			return "DUNGEON_INVALID_EVENT_DAY"
		var previous_day: int = last_day
		last_day = event.day
		if not combat.is_empty() and event.type != "DUNGEON_BATTLE_CONFIRMED": return "DUNGEON_COMBAT_PENDING"
		if work_units >= MOVES_PER_DAY and event.type != "DUNGEON_DAY_SPENT": return "DUNGEON_DAY_PENDING"
		match event.type:
			"DUNGEON_ENTERED":
				if room != "" or payload.room_id != "entrance":
					return "DUNGEON_INVALID_ENTRY"
				if route_rules == 1 and not payload.has("route_rules"): return "DUNGEON_ROUTE_RULES_DOWNGRADE"
				if trip_rules == 1 and not payload.has("trip_rules"): return "DUNGEON_TRIP_RULES_DOWNGRADE"
				if deep_rules == 1 and not payload.has("deep_rules"): return "DUNGEON_DEEP_RULES_DOWNGRADE"
				if device_rules == 1 and not payload.has("device_rules"): return "DUNGEON_DEVICE_RULES_DOWNGRADE"
				room = "entrance"
				route_rules = int(payload.get("route_rules", 0))
				trip_rules = int(payload.get("trip_rules", 0))
				deep_rules = int(payload.get("deep_rules", 0))
				device_rules = int(payload.get("device_rules", 0))
			"DUNGEON_DEVICE_DECIDED":
				if device_rules != 1 or room != "control" or payload.room_id != room or device_decided: return "DUNGEON_INVALID_DEVICE_CONTEXT"
				if typeof(payload.get("choice")) != TYPE_STRING or payload.choice not in ["PRESERVE", "SALVAGE"] or not text_is(payload.get("companion_id"), companion) or typeof(payload.get("worn")) != TYPE_BOOL: return "DUNGEON_INVALID_DEVICE_PROOF"
				var preserve: bool = payload.choice == "PRESERVE"
				if (preserve and companion != Party.ABBAN) or (not preserve and payload.worn) or not number(payload.get("scrap_spent"), DEVICE_COST if preserve else 0, DEVICE_COST if preserve else 0) or not number(payload.get("scrap_gained"), 0 if preserve else DEVICE_SALVAGE, 0 if preserve else DEVICE_SALVAGE) or not text_is(payload.get("item_spent"), DEVICE_ARMOR if preserve else "") or not text_is(payload.get("item_gained"), DEVICE_REWARD if preserve else ""): return "DUNGEON_INVALID_DEVICE_PROOF"
				device_decided = true
			"DUNGEON_ROOM_ENTERED":
				if typeof(payload.get("from_room_id")) != TYPE_STRING or payload.from_room_id != room or not adjacent(room, payload.room_id, shortcut_open):
					return "DUNGEON_INVALID_ROOM_TRANSITION"
				if passage_refusal(room, payload.room_id, route_rules, cleared, maintenance_open, deep_rules, true) != "": return "DUNGEON_CLOSED_ROUTE_HISTORY"
				room = payload.room_id
				if trip_rules == 1: work_units += 1
			"DUNGEON_DAY_SPENT":
				if room == "" or payload.room_id != room or trip_rules != 1 or event.day != previous_day + 1: return "DUNGEON_INVALID_DAY_CONTEXT"
				var day_error: String = validate_day(world, index, payload, companion)
				if day_error != "": return day_error
				work_units = 0
			"DUNGEON_TOOLS_RECOVERED":
				if deep_rules != 1 or room != "polluted_store" or payload.room_id != room or room not in cleared or tools_recovered or not text_is(payload.get("item_id"), DEEP_REWARD) or not number(payload.get("quantity"), 1, 1): return "DUNGEON_INVALID_TOOLS_RECOVERY"
				tools_recovered = true
			"DUNGEON_TRIP_ENDED":
				if room == "" or payload.room_id != room or trip_rules != 1 or index == 0 or typeof(payload.get("cause")) != TYPE_STRING or payload.cause not in ["dehydration", "starvation"]: return "DUNGEON_INVALID_TRIP_END"
				var death: EventRecord = world.event_log[index - 1]
				if death.type != "PLAYER_DIED" or death.actor_id != world.player.npc_id or death.target_id != HOME or death.day != event.day or not text_is(death.payload.get("cause"), payload.cause): return "DUNGEON_INVALID_TRIP_END"
				var ended_life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
				if ended_life == null or ended_life.is_alive(): return "DUNGEON_INVALID_TRIP_END"
				room = ""
			"DUNGEON_LEFT":
				if room != "entrance" or payload.room_id != "entrance":
					return "DUNGEON_INVALID_EXIT"
				room = ""
			"DUNGEON_SHORTCUT_OPENED":
				if room != "control" or payload.room_id != "control" or shortcut_open:
					return "DUNGEON_INVALID_SHORTCUT"
				shortcut_open = true
			"DUNGEON_MAINTENANCE_OPENED":
				if room != "maintenance" or payload.room_id != room or route_rules != 1 or maintenance_open or typeof(payload.get("method")) != TYPE_STRING or payload.method not in MAINTENANCE_COSTS or not number(payload.get("scrap_spent"), int(MAINTENANCE_COSTS.get(payload.get("method"), 0)), int(MAINTENANCE_COSTS.get(payload.get("method"), 0))):
					return "DUNGEON_INVALID_MAINTENANCE_HISTORY"
				if (payload.method == "SKILL" and not number(payload.get("proof"), 2, 5)) or (payload.method == "TOOL" and (typeof(payload.get("proof")) != TYPE_STRING or payload.proof not in ["crowbar", "wrench"])) or (payload.method == "ABBAN" and (typeof(payload.get("proof")) != TYPE_STRING or payload.proof != Party.ABBAN)): return "DUNGEON_INVALID_MAINTENANCE_PROOF"
				if payload.method == "ABBAN" and companion != Party.ABBAN: return "DUNGEON_INVALID_MAINTENANCE_PROOF"
				maintenance_open = true
			"DUNGEON_BATTLE_STARTED":
				if room not in ROOM_ENEMIES or payload.room_id != room or room in cleared or not text_is(payload.get("enemy"), ROOM_ENEMIES[room]) or not number(payload.get("battle_id"), last_battle + 1, 2147483647) or not number(payload.get("hp"), 1, 12) or not number(payload.get("site_enemy_hp"), 0, Enemies.highest_hp()):
					return "DUNGEON_INVALID_BATTLE_START"
				last_battle = int(payload.battle_id)
				combat = {"id": last_battle, "enemy": payload.enemy, "turn": 1, "prepared": false, "hp": int(payload.hp), "enemy_hp": Enemies.max_hp(payload.enemy), "site_enemy_hp": int(payload.site_enemy_hp), "outcome": "", "result_index": -1}
			"DUNGEON_BATTLE_CONFIRMED":
				if combat.is_empty() or combat.result_index < 0 or payload.room_id != room or not number(payload.get("battle_id"), int(combat.id), int(combat.id)) or not number(payload.get("result_index"), int(combat.result_index), int(combat.result_index)):
					return "DUNGEON_INVALID_BATTLE_CONFIRMATION"
				if combat.outcome == "DEAD": room = ""
				combat = {}
	if room != "":
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		var fatal_result: bool = not combat.is_empty() and combat.result_index >= 0 and combat.outcome == "DEAD"
		if life == null or (not fatal_result and (not life.is_alive() or life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME)) or (fatal_result and life.is_alive()):
			return "DUNGEON_INVALID_LOCAL_CONTEXT"
		if world.active_encounter != null or world.pending_encounter_result >= 0:
			return "DUNGEON_CONFLICTING_ACTIVITY"
		if combat.is_empty() and (not world.field_state.battle.is_empty() or world.field_state.receipt >= 0): return "DUNGEON_CONFLICTING_ACTIVITY"
	if work_units >= MOVES_PER_DAY: return "DUNGEON_DAY_PENDING"
	return _snapshot(world, room, combat)

static func ration_budget(water: int, food: int, companion: String) -> Dictionary:
	var after: Dictionary = {"water": maxi(0, water - 1), "food": maxi(0, food - 1), "fed": false}
	if companion != "":
		var info: Dictionary = Party.info(companion)
		if after.water >= int(info.road_water) and after.food >= int(info.road_food):
			after.water -= int(info.road_water)
			after.food -= int(info.road_food)
			after.fed = true
	return after

static func validate_day(world: WorldState, index: int, payload: Dictionary, companion: String) -> String:
	for key: String in ["water_before", "food_before", "water_after", "food_after"]:
		if not number(payload.get(key), 0, 2147483647): return "DUNGEON_INVALID_DAY_SUPPLIES"
	if not text_is(payload.get("companion_id"), companion) or (companion != "" and not Party.exists(companion)) or typeof(payload.get("companion_fed")) != TYPE_BOOL: return "DUNGEON_INVALID_DAY_COMPANION"
	var budget: Dictionary = ration_budget(int(payload.water_before), int(payload.food_before), companion)
	if payload.water_after != budget.water or payload.food_after != budget.food or payload.companion_fed != budget.fed: return "DUNGEON_INVALID_DAY_SUPPLIES"
	if companion != "" and not budget.fed:
		if index + 1 >= world.event_log.size(): return "DUNGEON_MISSING_HUNGER_DEPARTURE"
		var leave: EventRecord = world.event_log[index + 1]
		if leave.type != "COMPANION_LEFT" or leave.actor_id != world.player.npc_id or leave.target_id != StringName(SITE) or leave.day != world.event_log[index].day or leave.payload.size() != 2 or not text_is(leave.payload.get("companion_id"), companion) or not text_is(leave.payload.get("reason"), "HUNGER"): return "DUNGEON_MISSING_HUNGER_DEPARTURE"
	return ""

static func has_trip_costs(world: WorldState) -> bool:
	var checkpoint: Dictionary = state(world)
	return checkpoint.active and checkpoint.trip_rules == 1

# Called by the engine's existing personal-needs phase, before mortality.
static func consume_daily_supplies(world: WorldState, day: int, tick_events: Array[EventRecord]) -> Dictionary:
	var water: int = world.player.inventory.water
	var food: int = world.player.inventory.food
	var companion: String = Party.current(world)
	var budget: Dictionary = ration_budget(water, food, companion)
	world.player.inventory.water = int(budget.water)
	world.player.inventory.food = int(budget.food)
	var payload: Dictionary = {"dungeon_id": SITE, "room_id": state(world).room_id, "water_before": water, "food_before": food, "water_after": budget.water, "food_after": budget.food, "companion_id": companion, "companion_fed": budget.fed}
	var event: EventRecord = EventRecord.new(day, "DUNGEON_DAY_SPENT", world.player.npc_id, StringName(SITE), payload)
	world.record_event(event)
	tick_events.append(event)
	if companion != "" and not budget.fed:
		var leave: EventRecord = EventRecord.new(day, "COMPANION_LEFT", world.player.npc_id, StringName(SITE), {"companion_id": companion, "reason": "HUNGER"})
		world.record_event(leave)
		tick_events.append(leave)
	return {"water_unmet": 1.0 if water == 0 else 0.0, "food_unmet": 1.0 if food == 0 else 0.0}

static func end_deprivation_trip(world: WorldState, day: int, tick_events: Array[EventRecord]) -> void:
	if not has_trip_costs(world): return
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life != null and not life.is_alive():
		var death: EventRecord = world.event_log.back()
		var event: EventRecord = EventRecord.new(day, "DUNGEON_TRIP_ENDED", world.player.npc_id, StringName(SITE), {"dungeon_id": SITE, "room_id": state(world).room_id, "cause": death.payload.cause})
		world.record_event(event)
		tick_events.append(event)

static func number(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

static func text_is(value: Variant, expected: String) -> bool:
	return typeof(value) == TYPE_STRING and value == expected

static func _turn(combat: Dictionary, payload: Dictionary) -> String:
	if combat.outcome != "" or not number(payload.get("turn"), int(combat.turn), int(combat.turn)) or typeof(payload.get("command")) != TYPE_STRING or payload.get("command") not in ["ATTACK", "SHOOT", "DEFEND", "FLEE"] or not number(payload.get("dealt"), 0, int(combat.enemy_hp)) or not number(payload.get("taken"), 0, int(combat.hp)):
		return "DUNGEON_INVALID_COMBAT_TURN"
	if not number(payload.get("hp"), int(combat.hp - payload.taken), int(combat.hp - payload.taken)) or not number(payload.get("enemy_hp"), int(combat.enemy_hp - payload.dealt), int(combat.enemy_hp - payload.dealt)) or (payload.command in ["DEFEND", "FLEE"] and payload.dealt != 0): return "DUNGEON_INVALID_COMBAT_HEALTH"
	combat.hp = int(payload.hp)
	combat.enemy_hp = int(payload.enemy_hp)
	combat.prepared = payload.command == "DEFEND"
	if combat.hp == 0: combat.outcome = "DEAD"
	elif combat.enemy_hp == 0: combat.outcome = "VICTORY"
	elif payload.command == "FLEE": combat.outcome = "ESCAPED"
	else: combat.turn += 1
	return ""

static func _result(combat: Dictionary, payload: Dictionary, room: String, index: int) -> String:
	if combat.result_index >= 0 or combat.outcome == "" or not text_is(payload.get("outcome"), combat.outcome) or not number(payload.get("hp"), int(combat.hp), int(combat.hp)) or not text_is(payload.get("enemy"), combat.enemy) or not number(payload.get("site_enemy_hp"), int(combat.site_enemy_hp), int(combat.site_enemy_hp)) or typeof(payload.get("gained")) != TYPE_DICTIONARY or typeof(payload.get("left_behind")) != TYPE_DICTIONARY:
		return "DUNGEON_INVALID_COMBAT_RESULT"
	var gains: Dictionary = payload.gained
	var left: Dictionary = payload.left_behind
	if combat.outcome == "VICTORY":
		var reward: Dictionary = REWARDS[room]
		if not number(payload.get("caps_gained", 0), int(reward.caps), int(reward.caps)) or gains.size() > 1 or left.size() > 1 or (not gains.is_empty() and not gains.has("scrap")) or (not left.is_empty() and not left.has("scrap")) or not number(gains.get("scrap", 0), 0, int(reward.scrap)) or not number(left.get("scrap", 0), 0, int(reward.scrap)) or gains.get("scrap", 0) + left.get("scrap", 0) != reward.scrap:
			return "DUNGEON_INVALID_COMBAT_REWARD"
	elif not gains.is_empty() or not left.is_empty() or not number(payload.get("caps_gained", 0), 0, 0):
		return "DUNGEON_INVALID_COMBAT_REWARD"
	combat.result_index = index
	return ""

static func _snapshot(world: WorldState, room: String, combat: Dictionary) -> String:
	var field: Dictionary = world.field_state
	if combat.is_empty():
		var context: Dictionary = field.battle
		if context.is_empty() and field.receipt >= 0 and field.receipt < world.event_log.size(): context = world.event_log[field.receipt].payload
		return "DUNGEON_ORPHAN_COMBAT" if text_is(context.get("source", "field"), "dungeon") else ""
	if world.player.field_kit.hp != combat.hp or field.enemy_hp != combat.enemy_hp: return "DUNGEON_INVALID_COMBAT_SNAPSHOT"
	if combat.result_index >= 0:
		return "" if field.battle.is_empty() and field.receipt == combat.result_index else "DUNGEON_INVALID_COMBAT_SNAPSHOT"
	var battle: Dictionary = field.battle
	if battle.size() != 8 or field.receipt >= 0 or not text_is(battle.get("source"), "dungeon") or not text_is(battle.get("dungeon_id"), SITE) or not text_is(battle.get("room_id"), room) or not number(battle.get("id"), int(combat.id), int(combat.id)) or not text_is(battle.get("enemy"), combat.enemy) or not number(battle.get("turn"), int(combat.turn), int(combat.turn)) or battle.get("prepared") != combat.prepared or not number(battle.get("site_enemy_hp"), int(combat.site_enemy_hp), int(combat.site_enemy_hp)):
		return "DUNGEON_INVALID_COMBAT_SNAPSHOT"
	return ""

static func adjacent(from_room: String, to_room: String, shortcut_open: bool = false) -> bool:
	if from_room not in ROOMS or to_room not in ROOMS:
		return false
	if to_room in PASSAGES[from_room]:
		return true
	return shortcut_open and ((from_room == "entrance" and to_room == "control") or (from_room == "control" and to_room == "entrance"))

static func passage_refusal(from_room: String, to_room: String, rules: int, cleared: Array, opened: bool, deep_rules: int = 0, protected: bool = false) -> String:
	if rules == 0: return ""
	if ((from_room == "guard" and to_room == "pump") or (from_room == "pump" and to_room == "guard")) and "guard" not in cleared: return "DUNGEON_GUARD_BLOCKS_ROUTE"
	if ((from_room == "maintenance" and to_room == "pump") or (from_room == "pump" and to_room == "maintenance")) and not opened: return "DUNGEON_MAINTENANCE_CLOSED"
	if deep_rules == 1 and to_room == "polluted_store" and not protected: return "DUNGEON_NEED_GAS_MASK"
	return ""

static func recovery_requirement(world: WorldState) -> String:
	var checkpoint: Dictionary = state(world)
	if not checkpoint.active or checkpoint.deep_rules != 1 or checkpoint.room_id != "polluted_store": return "DUNGEON_RECOVERY_UNAVAILABLE"
	if checkpoint.tools_recovered: return "DUNGEON_TOOLS_ALREADY_RECOVERED"
	if "polluted_store" not in checkpoint.cleared: return "DUNGEON_CLEAR_POLLUTED_ROOM"
	if world.player.item_inventory.contains(DEEP_REWARD): return "DUNGEON_TOOL_ALREADY_OWNED"
	return "" if world.player.item_inventory.has_capacity_for(DEEP_REWARD, 1, world.player.equipment.equipped_item("back")) else "ITEM_CAPACITY_EXCEEDED"

static func prepared_device_armor(world: WorldState) -> Dictionary:
	var items: RefCounted = world.player.item_inventory.duplicate_state()
	var equipment: RefCounted = world.player.equipment.duplicate_state()
	var removed: Dictionary = items.remove_item(DEVICE_ARMOR)
	if not removed.success: return removed
	var added: Dictionary = items.add_item(DEVICE_REWARD, 1, equipment.equipped_item("back"))
	if not added.success: return added
	var worn: bool = equipment.equipped_item("body") == DEVICE_ARMOR
	if worn:
		var fitted: Dictionary = equipment.equip(DEVICE_REWARD, "body", items)
		if not fitted.success: return fitted
	return {"success": true, "error": "", "items": items, "equipment": equipment, "worn": worn}

static func device_requirement(world: WorldState, choice: String) -> String:
	if choice not in ["PRESERVE", "SALVAGE"]: return "DUNGEON_INVALID_DEVICE_CHOICE"
	var checkpoint: Dictionary = state(world)
	if not checkpoint.active or checkpoint.device_rules != 1 or checkpoint.room_id != "control": return "DUNGEON_DEVICE_UNAVAILABLE"
	if checkpoint.device_choice != "": return "DUNGEON_DEVICE_ALREADY_DECIDED"
	if choice == "SALVAGE": return "" if world.player.has_cargo_capacity(DEVICE_SALVAGE) else "DUNGEON_NEED_CARGO_SPACE"
	if Party.current(world) != Party.ABBAN: return "DUNGEON_NEED_ABBAN"
	if world.player.inventory.scrap < DEVICE_COST: return "DUNGEON_NEED_DEVICE_SCRAP"
	if not world.player.item_inventory.contains(DEVICE_ARMOR): return "DUNGEON_NEED_LEATHER_JACKET"
	var prepared: Dictionary = prepared_device_armor(world)
	return "" if prepared.success else String(prepared.error)

static func device_note(world: WorldState) -> String:
	var checkpoint: Dictionary = state(world)
	if checkpoint.device_choice == "": return ""
	var shared: String = "你和阿扳" if checkpoint.device_companion == Party.ABBAN else "你"
	return "共同經歷｜第%d天，%s在封存水廠%s" % [checkpoint.device_day, shared, "保留修復台，花3廢料把皮甲改成強化皮甲；設備仍保留。" if checkpoint.device_choice == "PRESERVE" else "拆解修復台，帶走4廢料；再也無法在這裡改甲。"]

static func maintenance_requirement(world: WorldState, method: String) -> String:
	if method not in MAINTENANCE_COSTS: return "DUNGEON_INVALID_METHOD"
	if method == "SKILL" and (world.player.capability == null or world.player.capability.get_rank("MECHANICS") < 2): return "DUNGEON_NEED_MECHANICS_2"
	if method == "TOOL" and maintenance_tool(world) == "": return "DUNGEON_NEED_TOOL"
	if method == "ABBAN" and Party.current(world) != Party.ABBAN: return "DUNGEON_NEED_ABBAN"
	return "DUNGEON_NEED_SCRAP" if world.player.inventory.scrap < int(MAINTENANCE_COSTS[method]) else ""

static func maintenance_tool(world: WorldState) -> String:
	if world.player.field_kit.crowbar: return "crowbar"
	return "wrench" if world.player.item_inventory.contains("wrench") else ""

static func authorize(world: WorldState, payload: Dictionary) -> String:
	var history_error: String = validate_world(world)
	if history_error != "":
		return history_error
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or not life.is_alive():
		return "DUNGEON_PLAYER_NOT_ALIVE"
	if life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME:
		return "DUNGEON_REQUIRES_GRAY_VALLEY"
	if world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0:
		return "DUNGEON_ACTIVITY_PENDING"
	if typeof(payload.get("command")) != TYPE_STRING:
		return "DUNGEON_INVALID_INTENT"
	var current: Dictionary = state(world)
	match payload.command:
		"ENTER":
			if payload.size() != 1:
				return "DUNGEON_INVALID_INTENT"
			return "DUNGEON_ALREADY_INSIDE" if current.active else ""
		"MOVE":
			if payload.size() != 3 or typeof(payload.get("from_room_id")) != TYPE_STRING or typeof(payload.get("room_id")) != TYPE_STRING:
				return "DUNGEON_INVALID_INTENT"
			if not current.active or payload.from_room_id != current.room_id or not adjacent(current.room_id, payload.room_id, current.shortcut_open):
				return "DUNGEON_INVALID_ROOM_TRANSITION"
			return passage_refusal(current.room_id, payload.room_id, current.route_rules, current.cleared, current.maintenance_open, current.deep_rules, world.player.item_inventory.contains(PROTECTION_ITEM))
		"EXIT":
			if payload.size() != 1:
				return "DUNGEON_INVALID_INTENT"
			return "" if current.active and current.room_id == "entrance" else "DUNGEON_EXIT_REQUIRES_ENTRANCE"
		"OPEN_SHORTCUT":
			if payload.size() != 1:
				return "DUNGEON_INVALID_INTENT"
			return "" if current.active and current.room_id == "control" and not current.shortcut_open else "DUNGEON_SHORTCUT_UNAVAILABLE"
		"FIGHT":
			if payload.size() != 2 or typeof(payload.get("room_id")) != TYPE_STRING: return "DUNGEON_INVALID_INTENT"
			return "" if current.active and payload.room_id == current.room_id and current.room_id in ROOM_ENEMIES and current.room_id not in current.cleared else "DUNGEON_FIGHT_UNAVAILABLE"
		"OPEN_MAINTENANCE":
			if payload.size() != 2 or typeof(payload.get("method")) != TYPE_STRING: return "DUNGEON_INVALID_INTENT"
			if not current.active or current.room_id != "maintenance" or current.route_rules != 1 or current.maintenance_open: return "DUNGEON_MAINTENANCE_UNAVAILABLE"
			return maintenance_requirement(world, payload.method)
		"RECOVER_TOOLS":
			if payload.size() != 1: return "DUNGEON_INVALID_INTENT"
			return recovery_requirement(world)
		"DECIDE_DEVICE":
			if payload.size() != 2 or typeof(payload.get("choice")) != TYPE_STRING: return "DUNGEON_INVALID_INTENT"
			return device_requirement(world, payload.choice)
	return "DUNGEON_UNAUTHORIZED_COMMAND"

static func commit(world: WorldState, payload: Dictionary, tick_events: Array[EventRecord], engine: SimulationEngine = null) -> Dictionary:
	var refusal: String = authorize(world, payload)
	if refusal != "":
		return {"success": false, "error": refusal}
	if payload.command == "FIGHT":
		return WorldState.Field.begin_dungeon_battle(world, payload.room_id, tick_events)
	var checkpoint: Dictionary = state(world)
	if payload.command == "MOVE" and checkpoint.trip_rules == 1 and checkpoint.work_units == MOVES_PER_DAY - 1 and engine == null: return {"success": false, "error": "DUNGEON_CLOCK_REQUIRED"}
	var event_type: String = "DUNGEON_ENTERED"
	var facts: Dictionary = {"dungeon_id": SITE, "room_id": "entrance"}
	if payload.command == "ENTER":
		facts.route_rules = 1
		facts.trip_rules = 1
		facts.deep_rules = 1
		facts.device_rules = 1
	match payload.command:
		"MOVE":
			event_type = "DUNGEON_ROOM_ENTERED"
			facts.room_id = payload.room_id
			facts.from_room_id = payload.from_room_id
			if checkpoint.deep_rules == 1 and payload.room_id == "polluted_store": facts.protection_item = PROTECTION_ITEM
		"EXIT":
			event_type = "DUNGEON_LEFT"
		"OPEN_SHORTCUT":
			event_type = "DUNGEON_SHORTCUT_OPENED"
			facts.room_id = "control"
		"OPEN_MAINTENANCE":
			event_type = "DUNGEON_MAINTENANCE_OPENED"
			facts.room_id = "maintenance"
			facts.method = payload.method
			facts.scrap_spent = int(MAINTENANCE_COSTS[payload.method])
			facts.proof = world.player.capability.get_rank("MECHANICS") if payload.method == "SKILL" else (maintenance_tool(world) if payload.method == "TOOL" else Party.ABBAN)
			world.player.inventory.scrap -= int(facts.scrap_spent)
		"RECOVER_TOOLS":
			var pickup: Dictionary = world.player.pickup_item(DEEP_REWARD, 1)
			if not pickup.success: return {"success": false, "error": pickup.error}
			event_type = "DUNGEON_TOOLS_RECOVERED"
			facts.room_id = "polluted_store"
			facts.item_id = DEEP_REWARD
			facts.quantity = 1
		"DECIDE_DEVICE":
			var preserve: bool = payload.choice == "PRESERVE"
			facts.worn = false
			if preserve:
				var prepared: Dictionary = prepared_device_armor(world)
				if not prepared.success: return {"success": false, "error": prepared.error}
				world.player.item_inventory = prepared.items
				world.player.equipment = prepared.equipment
				facts.worn = prepared.worn
			world.player.inventory.scrap += -DEVICE_COST if preserve else DEVICE_SALVAGE
			event_type = "DUNGEON_DEVICE_DECIDED"
			facts.room_id = "control"
			facts.choice = payload.choice
			facts.companion_id = Party.current(world)
			facts.scrap_spent = DEVICE_COST if preserve else 0
			facts.scrap_gained = 0 if preserve else DEVICE_SALVAGE
			facts.item_spent = DEVICE_ARMOR if preserve else ""
			facts.item_gained = DEVICE_REWARD if preserve else ""
	var event: EventRecord = EventRecord.new(world.current_day, event_type, world.player.npc_id, StringName(SITE), facts)
	world.record_event(event)
	if tick_events != null:
		tick_events.append(event)
	if payload.command == "MOVE" and state(world).trip_rules == 1 and state(world).work_units == MOVES_PER_DAY:
		var daily_events: Array[EventRecord] = engine.tick(world)
		if tick_events != null: tick_events.append_array(daily_events)
	return {"success": true, "action": "DUNGEON_ACTION", "exploration": state(world)}
