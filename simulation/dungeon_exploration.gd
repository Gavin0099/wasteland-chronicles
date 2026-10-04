extends RefCounted

# DUN-1: the ledger owns room checkpoints. Walking inside a room is presentation.
const SITE: String = "dungeon:sealed_waterworks"
const HOME: StringName = &"settlement:gray_valley"
const ROOMS: Dictionary = {"entrance": "水廠入口", "foyer": "設備前廳"}
const EVENTS: Array[String] = ["DUNGEON_ENTERED", "DUNGEON_ROOM_ENTERED", "DUNGEON_LEFT"]

static func state(world: WorldState) -> Dictionary:
	var result: Dictionary = {"active": false, "room_id": "", "from_room_id": ""}
	if world == null or world.player == null:
		return result
	for event: EventRecord in world.event_log:
		if event.actor_id != world.player.npc_id or event.type not in EVENTS:
			continue
		match event.type:
			"DUNGEON_ENTERED":
				result = {"active": true, "room_id": "entrance", "from_room_id": "outside"}
			"DUNGEON_ROOM_ENTERED":
				result = {"active": true, "room_id": event.payload.get("room_id", ""), "from_room_id": event.payload.get("from_room_id", "")}
			"DUNGEON_LEFT":
				result = {"active": false, "room_id": "", "from_room_id": ""}
	return result

static func validate_world(world: WorldState) -> String:
	var room: String = ""
	var last_day: int = -1
	for event: EventRecord in world.event_log:
		if not event.type.begins_with("DUNGEON_"):
			continue
		if event.type not in EVENTS or world.player == null or event.actor_id != world.player.npc_id or event.target_id != StringName(SITE):
			return "DUNGEON_INVALID_EVENT_OWNER"
		var payload: Dictionary = event.payload
		var expected_size: int = 3 if event.type == "DUNGEON_ROOM_ENTERED" else 2
		if payload.size() != expected_size or payload.get("dungeon_id") != SITE or typeof(payload.get("room_id")) != TYPE_STRING:
			return "DUNGEON_INVALID_EVENT_PAYLOAD"
		if event.day < last_day or event.day < 0 or event.day > world.current_day:
			return "DUNGEON_INVALID_EVENT_DAY"
		last_day = event.day
		match event.type:
			"DUNGEON_ENTERED":
				if room != "" or payload.room_id != "entrance":
					return "DUNGEON_INVALID_ENTRY"
				room = "entrance"
			"DUNGEON_ROOM_ENTERED":
				if typeof(payload.get("from_room_id")) != TYPE_STRING or payload.from_room_id != room or not adjacent(room, payload.room_id):
					return "DUNGEON_INVALID_ROOM_TRANSITION"
				room = payload.room_id
			"DUNGEON_LEFT":
				if room != "entrance" or payload.room_id != "entrance":
					return "DUNGEON_INVALID_EXIT"
				room = ""
	if room != "":
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life == null or life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME:
			return "DUNGEON_INVALID_LOCAL_CONTEXT"
		if world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0:
			return "DUNGEON_CONFLICTING_ACTIVITY"
	return ""

static func adjacent(from_room: String, to_room: String) -> bool:
	return (from_room == "entrance" and to_room == "foyer") or (from_room == "foyer" and to_room == "entrance")

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
			if not current.active or payload.from_room_id != current.room_id or not adjacent(current.room_id, payload.room_id):
				return "DUNGEON_INVALID_ROOM_TRANSITION"
			return ""
		"EXIT":
			if payload.size() != 1:
				return "DUNGEON_INVALID_INTENT"
			return "" if current.active and current.room_id == "entrance" else "DUNGEON_EXIT_REQUIRES_ENTRANCE"
	return "DUNGEON_UNAUTHORIZED_COMMAND"

static func commit(world: WorldState, payload: Dictionary, tick_events: Array[EventRecord]) -> Dictionary:
	var refusal: String = authorize(world, payload)
	if refusal != "":
		return {"success": false, "error": refusal}
	var event_type: String = "DUNGEON_ENTERED"
	var facts: Dictionary = {"dungeon_id": SITE, "room_id": "entrance"}
	match payload.command:
		"MOVE":
			event_type = "DUNGEON_ROOM_ENTERED"
			facts.room_id = payload.room_id
			facts.from_room_id = payload.from_room_id
		"EXIT":
			event_type = "DUNGEON_LEFT"
	var event: EventRecord = EventRecord.new(world.current_day, event_type, world.player.npc_id, StringName(SITE), facts)
	world.record_event(event)
	if tick_events != null:
		tick_events.append(event)
	return {"success": true, "action": "DUNGEON_ACTION", "exploration": state(world)}
