extends RefCounted

# The ledger owns room checkpoints, discovery and the return shortcut.
const SITE: String = "dungeon:sealed_waterworks"
const HOME: StringName = &"settlement:gray_valley"
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const ROOM_ENEMIES: Dictionary = {"guard": "bandit", "pump": "feral_dog", "polluted_store": "ash_ghoul"}
const REWARDS: Dictionary = {"guard": {"caps": 5, "scrap": 2}, "pump": {"caps": 0, "scrap": 2}, "polluted_store": {"caps": 10, "scrap": 3}}
const ROOMS: Dictionary = {"entrance": "水廠入口", "foyer": "設備前廳", "guard": "警衛區", "maintenance": "維修廊", "pump": "泵房", "control": "控制室", "parts_store": "零件庫", "polluted_store": "污染庫房"}
const PASSAGES: Dictionary = {
	"entrance": ["foyer"], "foyer": ["entrance", "guard", "maintenance", "parts_store"],
	"guard": ["foyer", "pump"], "maintenance": ["foyer", "pump"],
	"pump": ["guard", "maintenance", "control", "polluted_store"],
	"control": ["pump"], "parts_store": ["foyer"], "polluted_store": ["pump"]
}
const EVENTS: Array[String] = ["DUNGEON_ENTERED", "DUNGEON_ROOM_ENTERED", "DUNGEON_LEFT", "DUNGEON_SHORTCUT_OPENED", "DUNGEON_BATTLE_STARTED", "DUNGEON_BATTLE_CONFIRMED"]

static func state(world: WorldState) -> Dictionary:
	var result: Dictionary = {"active": false, "room_id": "", "from_room_id": "", "visited": [], "shortcut_open": false, "cleared": []}
	if world == null or world.player == null:
		return result
	for event: EventRecord in world.event_log:
		if event.actor_id != world.player.npc_id:
			continue
		if event.type == "FIELD_RESULT" and event.payload.get("source", "field") == "dungeon" and event.payload.get("outcome") == "VICTORY":
			if event.payload.room_id not in result.cleared: result.cleared.append(event.payload.room_id)
		if event.type not in EVENTS: continue
		match event.type:
			"DUNGEON_ENTERED":
				result.active = true
				result.room_id = "entrance"
				result.from_room_id = "outside"
			"DUNGEON_ROOM_ENTERED":
				result.room_id = event.payload.get("room_id", "")
				result.from_room_id = event.payload.get("from_room_id", "")
			"DUNGEON_LEFT":
				result.active = false
				result.room_id = ""
				result.from_room_id = ""
			"DUNGEON_SHORTCUT_OPENED":
				result.shortcut_open = true
			"DUNGEON_BATTLE_CONFIRMED":
				var receipt: Variant = event.payload.get("result_index", -1)
				if number(receipt, 0, world.event_log.size() - 1) and world.event_log[int(receipt)].payload.get("outcome") == "DEAD":
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
	for index: int in range(world.event_log.size()):
		var event: EventRecord = world.event_log[index]
		if event.type in ["FIELD_TURN", "FIELD_RESULT"] and event.payload.get("source", "field") == "dungeon":
			if world.player == null or event.actor_id != world.player.npc_id or event.target_id != HOME or combat.is_empty() or event.payload.get("dungeon_id") != SITE or event.payload.get("room_id") != room or event.payload.get("battle_id") != combat.id:
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
		var expected_size: int = {"DUNGEON_ROOM_ENTERED": 3, "DUNGEON_BATTLE_STARTED": 6, "DUNGEON_BATTLE_CONFIRMED": 4}.get(event.type, 2)
		if payload.size() != expected_size or payload.get("dungeon_id") != SITE or typeof(payload.get("room_id")) != TYPE_STRING:
			return "DUNGEON_INVALID_EVENT_PAYLOAD"
		if event.day < last_day or event.day < 0 or event.day > world.current_day:
			return "DUNGEON_INVALID_EVENT_DAY"
		last_day = event.day
		if not combat.is_empty() and event.type != "DUNGEON_BATTLE_CONFIRMED": return "DUNGEON_COMBAT_PENDING"
		match event.type:
			"DUNGEON_ENTERED":
				if room != "" or payload.room_id != "entrance":
					return "DUNGEON_INVALID_ENTRY"
				room = "entrance"
			"DUNGEON_ROOM_ENTERED":
				if typeof(payload.get("from_room_id")) != TYPE_STRING or payload.from_room_id != room or not adjacent(room, payload.room_id, shortcut_open):
					return "DUNGEON_INVALID_ROOM_TRANSITION"
				room = payload.room_id
			"DUNGEON_LEFT":
				if room != "entrance" or payload.room_id != "entrance":
					return "DUNGEON_INVALID_EXIT"
				room = ""
			"DUNGEON_SHORTCUT_OPENED":
				if room != "control" or payload.room_id != "control" or shortcut_open:
					return "DUNGEON_INVALID_SHORTCUT"
				shortcut_open = true
			"DUNGEON_BATTLE_STARTED":
				if room not in ROOM_ENEMIES or payload.room_id != room or room in cleared or payload.get("enemy") != ROOM_ENEMIES[room] or not number(payload.get("battle_id"), last_battle + 1, 2147483647) or not number(payload.get("hp"), 1, 12) or not number(payload.get("site_enemy_hp"), 0, Enemies.highest_hp()):
					return "DUNGEON_INVALID_BATTLE_START"
				last_battle = int(payload.battle_id)
				combat = {"id": last_battle, "enemy": payload.enemy, "turn": 1, "prepared": false, "hp": int(payload.hp), "enemy_hp": Enemies.max_hp(payload.enemy), "site_enemy_hp": int(payload.site_enemy_hp), "outcome": "", "result_index": -1}
			"DUNGEON_BATTLE_CONFIRMED":
				if combat.is_empty() or combat.result_index < 0 or payload.room_id != room or payload.get("battle_id") != combat.id or payload.get("result_index") != combat.result_index:
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
	return _snapshot(world, room, combat)

static func number(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

static func _turn(combat: Dictionary, payload: Dictionary) -> String:
	if combat.outcome != "" or payload.get("turn") != combat.turn or payload.get("command") not in ["ATTACK", "SHOOT", "DEFEND", "FLEE"] or not number(payload.get("dealt"), 0, int(combat.enemy_hp)) or not number(payload.get("taken"), 0, int(combat.hp)):
		return "DUNGEON_INVALID_COMBAT_TURN"
	if payload.get("hp") != combat.hp - payload.taken or payload.get("enemy_hp") != combat.enemy_hp - payload.dealt or (payload.command in ["DEFEND", "FLEE"] and payload.dealt != 0): return "DUNGEON_INVALID_COMBAT_HEALTH"
	combat.hp = int(payload.hp)
	combat.enemy_hp = int(payload.enemy_hp)
	combat.prepared = payload.command == "DEFEND"
	if combat.hp == 0: combat.outcome = "DEAD"
	elif combat.enemy_hp == 0: combat.outcome = "VICTORY"
	elif payload.command == "FLEE": combat.outcome = "ESCAPED"
	else: combat.turn += 1
	return ""

static func _result(combat: Dictionary, payload: Dictionary, room: String, index: int) -> String:
	if combat.result_index >= 0 or combat.outcome == "" or payload.get("outcome") != combat.outcome or payload.get("hp") != combat.hp or payload.get("enemy") != combat.enemy or payload.get("site_enemy_hp") != combat.site_enemy_hp or typeof(payload.get("gained")) != TYPE_DICTIONARY or typeof(payload.get("left_behind")) != TYPE_DICTIONARY:
		return "DUNGEON_INVALID_COMBAT_RESULT"
	var gains: Dictionary = payload.gained
	var left: Dictionary = payload.left_behind
	if combat.outcome == "VICTORY":
		var reward: Dictionary = REWARDS[room]
		if payload.get("caps_gained", 0) != reward.caps or gains.size() > 1 or left.size() > 1 or (not gains.is_empty() and not gains.has("scrap")) or (not left.is_empty() and not left.has("scrap")) or not number(gains.get("scrap", 0), 0, int(reward.scrap)) or not number(left.get("scrap", 0), 0, int(reward.scrap)) or gains.get("scrap", 0) + left.get("scrap", 0) != reward.scrap:
			return "DUNGEON_INVALID_COMBAT_REWARD"
	elif not gains.is_empty() or not left.is_empty() or payload.get("caps_gained", 0) != 0:
		return "DUNGEON_INVALID_COMBAT_REWARD"
	combat.result_index = index
	return ""

static func _snapshot(world: WorldState, room: String, combat: Dictionary) -> String:
	var field: Dictionary = world.field_state
	if combat.is_empty():
		var context: Dictionary = field.battle
		if context.is_empty() and field.receipt >= 0 and field.receipt < world.event_log.size(): context = world.event_log[field.receipt].payload
		return "DUNGEON_ORPHAN_COMBAT" if context.get("source", "field") == "dungeon" else ""
	if world.player.field_kit.hp != combat.hp or field.enemy_hp != combat.enemy_hp: return "DUNGEON_INVALID_COMBAT_SNAPSHOT"
	if combat.result_index >= 0:
		return "" if field.battle.is_empty() and field.receipt == combat.result_index else "DUNGEON_INVALID_COMBAT_SNAPSHOT"
	var battle: Dictionary = field.battle
	if battle.size() != 8 or field.receipt >= 0 or battle.get("source") != "dungeon" or battle.get("dungeon_id") != SITE or battle.get("room_id") != room or battle.get("id") != combat.id or battle.get("enemy") != combat.enemy or battle.get("turn") != combat.turn or battle.get("prepared") != combat.prepared or battle.get("site_enemy_hp") != combat.site_enemy_hp:
		return "DUNGEON_INVALID_COMBAT_SNAPSHOT"
	return ""

static func adjacent(from_room: String, to_room: String, shortcut_open: bool = false) -> bool:
	if from_room not in ROOMS or to_room not in ROOMS:
		return false
	if to_room in PASSAGES[from_room]:
		return true
	return shortcut_open and ((from_room == "entrance" and to_room == "control") or (from_room == "control" and to_room == "entrance"))

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
			return ""
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
	return "DUNGEON_UNAUTHORIZED_COMMAND"

static func commit(world: WorldState, payload: Dictionary, tick_events: Array[EventRecord]) -> Dictionary:
	var refusal: String = authorize(world, payload)
	if refusal != "":
		return {"success": false, "error": refusal}
	if payload.command == "FIGHT":
		return WorldState.Field.begin_dungeon_battle(world, payload.room_id, tick_events)
	var event_type: String = "DUNGEON_ENTERED"
	var facts: Dictionary = {"dungeon_id": SITE, "room_id": "entrance"}
	match payload.command:
		"MOVE":
			event_type = "DUNGEON_ROOM_ENTERED"
			facts.room_id = payload.room_id
			facts.from_room_id = payload.from_room_id
		"EXIT":
			event_type = "DUNGEON_LEFT"
		"OPEN_SHORTCUT":
			event_type = "DUNGEON_SHORTCUT_OPENED"
			facts.room_id = "control"
	var event: EventRecord = EventRecord.new(world.current_day, event_type, world.player.npc_id, StringName(SITE), facts)
	world.record_event(event)
	if tick_events != null:
		tick_events.append(event)
	return {"success": true, "action": "DUNGEON_ACTION", "exploration": state(world)}
