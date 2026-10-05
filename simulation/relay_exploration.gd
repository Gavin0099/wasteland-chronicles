extends RefCounted

# RLY-1 is a second fixed site, with its own ledger. The waterworks wire stays intact.
const SITE: String = "dungeon:buried_relay"
const HOME: StringName = &"settlement:gray_valley"
const MOVES_PER_DAY: int = 4
const PRIZE: String = "military_backpack"
const ROOMS: Dictionary = {"relay_entrance": "中繼站入口", "relay_corridor": "守望走廊", "relay_tunnel": "掩埋維修道", "relay_records": "值勤檔案室", "relay_vault": "地下保管室"}
const PASSAGES: Dictionary = {"relay_entrance": ["relay_corridor", "relay_tunnel"], "relay_corridor": ["relay_entrance", "relay_records"], "relay_tunnel": ["relay_entrance", "relay_records"], "relay_records": ["relay_corridor", "relay_tunnel", "relay_vault"], "relay_vault": ["relay_records"]}
const REWARDS: Dictionary = {"relay_corridor": {"caps": 0, "scrap": 0}}
const EVENTS: Dictionary = {"RELAY_ENTERED": 2, "RELAY_MOVED": 3, "RELAY_LEFT": 2, "RELAY_TUNNEL_FOUND": 2, "RELAY_TUNNEL_OPENED": 4, "RELAY_CARD_FOUND": 2, "RELAY_PRIZE_TAKEN": 4, "RELAY_DAY_SPENT": 8, "RELAY_TRIP_ENDED": 3, "RELAY_BATTLE_STARTED": 6, "RELAY_BATTLE_CONFIRMED": 4}

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = {"active": false, "room_id": "", "from_room_id": "", "visited": [], "tunnel_found": false, "tunnel_open": false, "card_found": false, "prize_taken": false, "cleared": [], "work_units": 0, "trip_moves": 0, "trip_days": 0, "trip_rules": 1}
	if world == null or world.player == null: return s
	for e: EventRecord in world.event_log:
		if e.actor_id != world.player.npc_id: continue
		if e.type == "FIELD_RESULT" and e.payload.get("dungeon_id") == SITE and e.payload.get("outcome") == "VICTORY":
			if e.payload.room_id not in s.cleared: s.cleared.append(e.payload.room_id)
		if e.type not in EVENTS: continue
		match e.type:
			"RELAY_ENTERED":
				s.active = true
				s.room_id = "relay_entrance"
				s.from_room_id = "outside"
				s.trip_moves = 0
				s.trip_days = 0
			"RELAY_MOVED":
				s.room_id = e.payload.room_id
				s.from_room_id = e.payload.from_room_id
				s.work_units += 1
				s.trip_moves += 1
			"RELAY_DAY_SPENT":
				s.work_units = 0
				s.trip_days += 1
			"RELAY_LEFT", "RELAY_TRIP_ENDED": s.active = false
			"RELAY_TUNNEL_FOUND": s.tunnel_found = true
			"RELAY_TUNNEL_OPENED": s.tunnel_open = true
			"RELAY_CARD_FOUND": s.card_found = true
			"RELAY_PRIZE_TAKEN": s.prize_taken = true
			"RELAY_BATTLE_CONFIRMED":
				if world.event_log[int(e.payload.result_index)].payload.outcome == "DEAD": s.active = false
		if s.active and s.room_id not in s.visited: s.visited.append(s.room_id)
	return s

static func gate(from_room: String, to_room: String, s: Dictionary) -> String:
	if from_room not in PASSAGES or to_room not in PASSAGES[from_room]: return "RELAY_INVALID_PASSAGE"
	if to_room == "relay_tunnel" and not s.tunnel_found: return "RELAY_FIND_TUNNEL"
	if (from_room == "relay_corridor" and to_room == "relay_records") or (from_room == "relay_records" and to_room == "relay_corridor"):
		if "relay_corridor" not in s.cleared: return "RELAY_DOG_BLOCKS_ROUTE"
	if (from_room == "relay_tunnel" and to_room == "relay_records") or (from_room == "relay_records" and to_room == "relay_tunnel"):
		if not s.tunnel_open: return "RELAY_OPEN_TUNNEL"
	if to_room == "relay_vault" and not s.card_found: return "RELAY_FIND_CARD"
	return ""

static func tool(world: WorldState) -> String:
	if world.player.field_kit.crowbar: return "crowbar"
	for item: String in ["wrench", "crowbar"]:
		if world.player.item_inventory.contains(item): return item
	return ""

static func authorize(world: WorldState, payload: Dictionary) -> String:
	var history_error: String = SimulationEngine.Dungeon.validate_world(world)
	if history_error != "": return history_error
	if typeof(payload.get("site_id")) != TYPE_STRING or payload.site_id != SITE or typeof(payload.get("command")) != TYPE_STRING: return "RELAY_INVALID_INTENT"
	if payload.command in SimulationEngine.RelayTarget.COMMANDS: return SimulationEngine.RelayTarget.authorize(world, payload)
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or not life.is_alive(): return "RELAY_PLAYER_DEAD"
	if life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME: return "RELAY_REQUIRES_GRAY_VALLEY"
	if SimulationEngine.Dungeon.state(world).active or world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0: return "RELAY_ACTIVITY_PENDING"
	var s: Dictionary = state(world)
	var expected: int = 4 if payload.command == "MOVE" else 2
	if payload.size() != expected: return "RELAY_INVALID_INTENT"
	if payload.command == "ENTER": return "RELAY_ALREADY_INSIDE" if s.active else ""
	if not s.active: return "RELAY_NOT_INSIDE"
	match payload.command:
		"MOVE":
			if typeof(payload.get("from_room_id")) != TYPE_STRING or typeof(payload.get("room_id")) != TYPE_STRING or payload.from_room_id != s.room_id: return "RELAY_INVALID_INTENT"
			return gate(s.room_id, payload.room_id, s)
		"EXIT": return "" if s.room_id == "relay_entrance" else "RELAY_EXIT_REQUIRES_ENTRANCE"
		"SEARCH": return "" if s.room_id == "relay_entrance" and not s.tunnel_found else "RELAY_SEARCH_UNAVAILABLE"
		"OPEN_TUNNEL":
			if s.room_id != "relay_tunnel" or s.tunnel_open: return "RELAY_TUNNEL_UNAVAILABLE"
			if tool(world) == "": return "RELAY_NEED_TOOL"
			return "" if world.player.inventory.scrap >= 2 else "RELAY_NEED_SCRAP"
		"FIND_CARD": return "" if s.room_id == "relay_records" and not s.card_found else "RELAY_CARD_UNAVAILABLE"
		"TAKE_PRIZE":
			if s.room_id != "relay_vault" or s.prize_taken: return "RELAY_PRIZE_UNAVAILABLE"
			if world.player.item_inventory.contains(PRIZE): return "RELAY_PRIZE_ALREADY_OWNED"
			return "" if world.player.item_inventory.has_capacity_for(PRIZE, 1, world.player.equipment.equipped_item("back")) else "ITEM_CAPACITY_EXCEEDED"
		"FIGHT": return "" if s.room_id == "relay_corridor" and s.room_id not in s.cleared else "RELAY_FIGHT_UNAVAILABLE"
	return "RELAY_UNAUTHORIZED_COMMAND"

static func commit(world: WorldState, payload: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var error: String = authorize(world, payload)
	if error != "": return {"success": false, "error": error}
	if payload.command in SimulationEngine.RelayTarget.COMMANDS: return SimulationEngine.RelayTarget.commit(world, payload, events, engine)
	if payload.command == "FIGHT": return WorldState.Field.begin_relay_battle(world, events)
	var s: Dictionary = state(world)
	if payload.command == "MOVE" and s.work_units == 3 and engine == null: return {"success": false, "error": "RELAY_CLOCK_REQUIRED"}
	var kind: String = {"ENTER": "RELAY_ENTERED", "MOVE": "RELAY_MOVED", "EXIT": "RELAY_LEFT", "SEARCH": "RELAY_TUNNEL_FOUND", "OPEN_TUNNEL": "RELAY_TUNNEL_OPENED", "FIND_CARD": "RELAY_CARD_FOUND", "TAKE_PRIZE": "RELAY_PRIZE_TAKEN"}[payload.command]
	var facts: Dictionary = {"dungeon_id": SITE, "room_id": "relay_entrance" if payload.command == "ENTER" else s.room_id}
	match payload.command:
		"MOVE":
			facts.room_id = payload.room_id
			facts.from_room_id = s.room_id
		"OPEN_TUNNEL":
			facts.tool_id = tool(world)
			facts.scrap_spent = 2
			world.player.inventory.scrap -= 2
		"TAKE_PRIZE":
			var pickup: Dictionary = world.player.pickup_item(PRIZE, 1)
			if not pickup.success: return pickup
			facts.item_id = PRIZE
			facts.quantity = 1
	record(world, kind, facts, world.current_day, events)
	if payload.command == "MOVE" and state(world).work_units == 4:
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
	record(world, "RELAY_DAY_SPENT", {"dungeon_id": SITE, "room_id": state(world).room_id, "water_before": water, "food_before": food, "water_after": budget.water, "food_after": budget.food, "companion_id": companion, "companion_fed": budget.fed}, day, events)
	if companion != "" and not budget.fed:
		var leave: EventRecord = EventRecord.new(day, "COMPANION_LEFT", world.player.npc_id, StringName(SITE), {"companion_id": companion, "reason": "HUNGER"})
		world.record_event(leave)
		events.append(leave)
	return {"water_unmet": 1.0 if water == 0 else 0.0, "food_unmet": 1.0 if food == 0 else 0.0}

static func end_deprivation_trip(world: WorldState, day: int, events: Array[EventRecord]) -> void:
	if not state(world).active: return
	if not world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive():
		record(world, "RELAY_TRIP_ENDED", {"dungeon_id": SITE, "room_id": state(world).room_id, "cause": world.event_log.back().payload.cause}, day, events)

static func number(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

static func text(value: Variant, expected: String) -> bool:
	return typeof(value) == TYPE_STRING and value == expected

static func validate_world(world: WorldState) -> String:
	var s: Dictionary = {"active": false, "room_id": "", "tunnel_found": false, "tunnel_open": false, "card_found": false, "prize_taken": false, "cleared": []}
	var combat: Dictionary = {}
	var units: int = 0
	var last_day: int = -1
	var battle_id: int = 0
	var companion: String = ""
	var waterworks: bool = false
	for index: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[index]
		var p: Dictionary = e.payload
		if world.player != null and e.actor_id == world.player.npc_id:
			if e.type == "DUNGEON_ENTERED":
				if s.active: return "RELAY_CONFLICTING_ACTIVITY"
				waterworks = true
			elif e.type in ["DUNGEON_LEFT", "DUNGEON_TRIP_ENDED"]: waterworks = false
			elif e.type == "COMPANION_JOINED": companion = String(p.get("companion_id", ""))
			elif e.type == "COMPANION_LEFT": companion = ""
			elif s.active and e.type in ["PLAYER_TRAVEL_STARTED", "TRAVEL_ENCOUNTER_STARTED"]: return "RELAY_CONFLICTING_ACTIVITY"
		if e.type in ["FIELD_TURN", "FIELD_RESULT"] and text(p.get("source"), "dungeon") and text(p.get("dungeon_id"), SITE):
			if world.player == null or e.actor_id != world.player.npc_id or e.target_id != HOME or not s.active or combat.is_empty() or not text(p.get("room_id"), s.room_id) or not number(p.get("battle_id"), int(combat.id), int(combat.id)) or e.day != last_day: return "RELAY_INVALID_COMBAT_CONTEXT"
			var error: String = SimulationEngine.Dungeon._turn(combat, p) if e.type == "FIELD_TURN" else validate_result(combat, p, index)
			if error != "": return error
			if e.type == "FIELD_RESULT" and combat.outcome == "VICTORY": s.cleared.append(s.room_id)
			continue
		if not e.type.begins_with("RELAY_"): continue
		if e.type not in EVENTS or world.player == null or e.actor_id != world.player.npc_id or e.target_id != StringName(SITE): return "RELAY_INVALID_EVENT_OWNER"
		if p.size() != int(EVENTS[e.type]) or not text(p.get("dungeon_id"), SITE) or typeof(p.get("room_id")) != TYPE_STRING or p.room_id not in ROOMS: return "RELAY_INVALID_EVENT_PAYLOAD"
		if e.day < 0 or e.day < last_day or e.day > world.current_day: return "RELAY_INVALID_EVENT_DAY"
		var previous_day: int = last_day
		last_day = e.day
		if not combat.is_empty() and e.type != "RELAY_BATTLE_CONFIRMED": return "RELAY_COMBAT_PENDING"
		if units >= 4 and e.type != "RELAY_DAY_SPENT": return "RELAY_DAY_PENDING"
		if e.type == "RELAY_ENTERED":
			if s.active or waterworks or p.room_id != "relay_entrance": return "RELAY_INVALID_ENTRY"
			s.active = true
			s.room_id = p.room_id
			continue
		if not s.active or (e.type != "RELAY_MOVED" and p.room_id != s.room_id): return "RELAY_INVALID_LOCAL_CONTEXT"
		match e.type:
			"RELAY_MOVED":
				if not text(p.get("from_room_id"), s.room_id) or gate(s.room_id, p.room_id, s) != "": return "RELAY_INVALID_PASSAGE_HISTORY"
				s.room_id = p.room_id
				units += 1
			"RELAY_LEFT":
				if s.room_id != "relay_entrance": return "RELAY_INVALID_EXIT"
				s.active = false
			"RELAY_TUNNEL_FOUND":
				if s.room_id != "relay_entrance" or s.tunnel_found: return "RELAY_INVALID_DISCOVERY"
				s.tunnel_found = true
			"RELAY_TUNNEL_OPENED":
				if s.room_id != "relay_tunnel" or s.tunnel_open or typeof(p.get("tool_id")) != TYPE_STRING or p.tool_id not in ["wrench", "crowbar"] or not number(p.get("scrap_spent"), 2, 2): return "RELAY_INVALID_TUNNEL_PROOF"
				s.tunnel_open = true
			"RELAY_CARD_FOUND":
				if s.room_id != "relay_records" or s.card_found: return "RELAY_INVALID_CARD"
				s.card_found = true
			"RELAY_PRIZE_TAKEN":
				if s.room_id != "relay_vault" or s.prize_taken or not text(p.get("item_id"), PRIZE) or not number(p.get("quantity"), 1, 1): return "RELAY_INVALID_PRIZE"
				s.prize_taken = true
			"RELAY_DAY_SPENT":
				if units != 4 or e.day != previous_day + 1: return "RELAY_INVALID_DAY_CONTEXT"
				for key: String in ["water_before", "food_before", "water_after", "food_after"]:
					if not number(p.get(key), 0, 2147483647): return "RELAY_INVALID_SUPPLIES"
				if not text(p.get("companion_id"), companion) or typeof(p.get("companion_fed")) != TYPE_BOOL: return "RELAY_INVALID_SUPPLIES"
				var budget: Dictionary = SimulationEngine.Dungeon.ration_budget(int(p.water_before), int(p.food_before), companion)
				if p.water_after != budget.water or p.food_after != budget.food or p.companion_fed != budget.fed: return "RELAY_INVALID_SUPPLIES"
				if companion != "" and not budget.fed:
					if index + 1 >= world.event_log.size(): return "RELAY_MISSING_HUNGER_DEPARTURE"
					var leave: EventRecord = world.event_log[index + 1]
					if leave.type != "COMPANION_LEFT" or leave.actor_id != e.actor_id or leave.target_id != e.target_id or leave.day != e.day or leave.payload.size() != 2 or not text(leave.payload.get("companion_id"), companion) or not text(leave.payload.get("reason"), "HUNGER"): return "RELAY_MISSING_HUNGER_DEPARTURE"
				units = 0
			"RELAY_TRIP_ENDED":
				if index == 0 or typeof(p.get("cause")) != TYPE_STRING or p.cause not in ["dehydration", "starvation"]: return "RELAY_INVALID_DEATH"
				var death: EventRecord = world.event_log[index - 1]
				if death.type != "PLAYER_DIED" or death.actor_id != e.actor_id or death.target_id != HOME or death.day != e.day or not text(death.payload.get("cause"), p.cause) or world.npc_life_state_registry.get_life_state(e.actor_id).is_alive(): return "RELAY_INVALID_DEATH"
				s.active = false
			"RELAY_BATTLE_STARTED":
				if s.room_id != "relay_corridor" or s.room_id in s.cleared or not text(p.get("enemy"), "feral_dog") or not number(p.get("battle_id"), battle_id + 1, 2147483647) or not number(p.get("hp"), 1, 12) or not number(p.get("site_enemy_hp"), 0, WorldState.Field.Enemies.highest_hp()): return "RELAY_INVALID_BATTLE_START"
				battle_id = int(p.battle_id)
				combat = {"id": battle_id, "enemy": "feral_dog", "turn": 1, "prepared": false, "hp": int(p.hp), "enemy_hp": WorldState.Field.Enemies.max_hp("feral_dog"), "site_enemy_hp": int(p.site_enemy_hp), "outcome": "", "result_index": -1}
			"RELAY_BATTLE_CONFIRMED":
				if combat.is_empty() or combat.result_index < 0 or not number(p.get("battle_id"), int(combat.id), int(combat.id)) or not number(p.get("result_index"), int(combat.result_index), int(combat.result_index)): return "RELAY_INVALID_BATTLE_CONFIRMATION"
				if combat.outcome == "DEAD": s.active = false
				combat = {}
	if units >= 4: return "RELAY_DAY_PENDING"
	if s.active:
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		var fatal: bool = not combat.is_empty() and combat.outcome == "DEAD"
		if life == null or (fatal and life.is_alive()) or (not fatal and (not life.is_alive() or life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME)): return "RELAY_INVALID_LOCAL_CONTEXT"
		if world.active_encounter != null or world.pending_encounter_result >= 0 or SimulationEngine.Dungeon.state(world).active: return "RELAY_CONFLICTING_ACTIVITY"
		if combat.is_empty() and (not world.field_state.battle.is_empty() or world.field_state.receipt >= 0): return "RELAY_CONFLICTING_ACTIVITY"
	var snapshot_error: String = validate_snapshot(world, s, combat)
	return SimulationEngine.RelayTarget.validate_world(world) if snapshot_error == "" else snapshot_error

static func validate_result(combat: Dictionary, p: Dictionary, index: int) -> String:
	if combat.result_index >= 0 or combat.outcome == "" or not text(p.get("outcome"), combat.outcome) or not number(p.get("hp"), int(combat.hp), int(combat.hp)) or not text(p.get("enemy"), "feral_dog") or not number(p.get("site_enemy_hp"), int(combat.site_enemy_hp), int(combat.site_enemy_hp)) or typeof(p.get("gained")) != TYPE_DICTIONARY or not p.gained.is_empty() or typeof(p.get("left_behind")) != TYPE_DICTIONARY or not p.left_behind.is_empty() or not number(p.get("caps_gained", 0), 0, 0): return "RELAY_INVALID_COMBAT_RESULT"
	combat.result_index = index
	return ""

static func validate_snapshot(world: WorldState, s: Dictionary, combat: Dictionary) -> String:
	var field: Dictionary = world.field_state
	var context: Dictionary = field.battle
	if context.is_empty() and field.receipt >= 0 and field.receipt < world.event_log.size(): context = world.event_log[field.receipt].payload
	if combat.is_empty(): return "RELAY_ORPHAN_COMBAT" if text(context.get("dungeon_id"), SITE) else ""
	if world.player.field_kit.hp != combat.hp or field.enemy_hp != combat.enemy_hp: return "RELAY_INVALID_COMBAT_SNAPSHOT"
	if combat.result_index >= 0: return "" if field.battle.is_empty() and field.receipt == combat.result_index else "RELAY_INVALID_COMBAT_SNAPSHOT"
	if context.size() != 8 or field.receipt >= 0 or not text(context.get("source"), "dungeon") or not text(context.get("dungeon_id"), SITE) or not text(context.get("room_id"), s.room_id) or not number(context.get("id"), int(combat.id), int(combat.id)) or not text(context.get("enemy"), "feral_dog") or not number(context.get("turn"), int(combat.turn), int(combat.turn)) or typeof(context.get("prepared")) != TYPE_BOOL or context.prepared != combat.prepared or not number(context.get("site_enemy_hp"), int(combat.site_enemy_hp), int(combat.site_enemy_hp)): return "RELAY_INVALID_COMBAT_SNAPSHOT"
	return ""
