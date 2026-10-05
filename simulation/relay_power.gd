extends RefCounted

const SITE: String = "dungeon:buried_relay"
const COMMANDS: Array[String] = ["INSPECT_POWER", "POWER_TURRET", "POWER_LIFT", "POWER_OFF"]
const EVENTS: Dictionary = {"STATION_POWER_FOUND": 2, "STATION_POWER_CONFIGURED": 9, "STATION_POWER_OFF": 3, "STATION_POWER_SHOT": 7}

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = {"inspected": false, "mode": "OFF", "charges": 0}
	if world == null or world.player == null: return s
	for event: EventRecord in world.event_log:
		if event.actor_id != world.player.npc_id: continue
		match event.type:
			"STATION_POWER_FOUND": s.inspected = true
			"STATION_POWER_CONFIGURED": s.mode = event.payload.mode; s.charges = int(event.payload.charges)
			"STATION_POWER_OFF": s.mode = "OFF"; s.charges = 0
			"STATION_POWER_SHOT": s.charges = int(event.payload.remaining)
	return s

static func method(world: WorldState, mode: String) -> Dictionary:
	var skill: String = "ELECTRONICS" if mode == "TURRET" else "MECHANICS"
	var rank: int = world.player.capability.get_rank(skill)
	if rank >= 1: return {"method": skill, "rank": rank, "tool_id": ""}
	if mode == "LIFT":
		var tool_id: String = SimulationEngine.Relay.tool(world)
		if tool_id != "": return {"method": "TOOL", "rank": 0, "tool_id": tool_id}
	return {}

static func authorize(world: WorldState, payload: Dictionary) -> String:
	var invalid: String = SimulationEngine.Dungeon.validate_world(world)
	if invalid != "": return invalid
	if SimulationEngine.RelayCustody.pending(world): return "PURSUIT_ACTIVITY_PENDING"
	if payload.size() != 2 or not SimulationEngine.Relay.text(payload.get("site_id"), SITE) or typeof(payload.get("command")) != TYPE_STRING or payload.command not in COMMANDS: return "POWER_INVALID_INTENT"
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if ls == null or not ls.is_alive(): return "POWER_PLAYER_DEAD"
	var relay: Dictionary = SimulationEngine.Relay.state(world)
	if not relay.active or relay.room_id != "relay_tunnel" or ls.status != NpcLifeState.Status.SETTLED or ls.population_container_id != SimulationEngine.Relay.HOME: return "POWER_REQUIRES_PANEL"
	if not world.field_state.battle.is_empty() or world.field_state.receipt >= 0 or world.active_encounter != null or world.pending_encounter_result >= 0 or SimulationEngine.Dungeon.state(world).active: return "POWER_ACTIVITY_PENDING"
	var s: Dictionary = state(world)
	if payload.command == "INSPECT_POWER": return ""
	if not s.inspected: return "POWER_INSPECT_FIRST"
	if payload.command == "POWER_OFF": return "" if s.mode != "OFF" else "POWER_ALREADY_OFF"
	var mode: String = "TURRET" if payload.command == "POWER_TURRET" else "LIFT"
	if s.mode == mode and (mode == "LIFT" or s.charges == 2): return "POWER_ALREADY_READY"
	if method(world, mode).is_empty(): return "POWER_NEED_ELECTRONICS" if mode == "TURRET" else "POWER_NEED_MECHANICS_OR_TOOL"
	if world.player.inventory.fuel < 1: return "POWER_NEED_FUEL"
	return "" if world.player.inventory.scrap >= 1 else "POWER_NEED_SCRAP"

static func record(world: WorldState, kind: String, payload: Dictionary) -> void:
	payload.site_id = SITE
	world.record_event(EventRecord.new(world.current_day, kind, world.player.npc_id, StringName(SITE), payload))

static func commit(world: WorldState, payload: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var invalid: String = authorize(world, payload)
	if invalid != "": return {"success": false, "error": invalid}
	if payload.command == "INSPECT_POWER" and state(world).inspected: return {"success": true, "action": "DUNGEON_ACTION"}
	if engine == null: return {"success": false, "error": "POWER_ENGINE_REQUIRED"}
	var staged: WorldState = world.duplicate_state()
	var facts: Dictionary = {"room_id": "relay_tunnel"}
	match payload.command:
		"INSPECT_POWER": record(staged, "STATION_POWER_FOUND", facts)
		"POWER_OFF":
			facts.discarded = state(staged).charges
			record(staged, "STATION_POWER_OFF", facts)
		_:
			facts.mode = "TURRET" if payload.command == "POWER_TURRET" else "LIFT"
			facts.merge(method(staged, facts.mode))
			facts.fuel_spent = 1
			facts.scrap_spent = 1
			facts.charges = 2 if facts.mode == "TURRET" else 0
			staged.player.inventory.fuel -= 1
			staged.player.inventory.scrap -= 1
			record(staged, "STATION_POWER_CONFIGURED", facts)
	invalid = engine.validate_invariants(staged)
	if invalid != "": return {"success": false, "error": invalid}
	var count: int = world.event_log.size()
	world.player = staged.player
	world.event_log = staged.event_log
	if events != null:
		for index: int in range(count, world.event_log.size()): events.append(world.event_log[index])
	return {"success": true, "action": "DUNGEON_ACTION"}

static func supported_battle(world: WorldState) -> bool:
	var battle: Dictionary = world.field_state.battle
	return battle.get("source", "") == "dungeon" and battle.get("dungeon_id", "") == SITE and battle.get("room_id", "") == "relay_corridor" and state(world).mode == "TURRET" and state(world).charges > 0

static func preview(world: WorldState, ordinary: int) -> int:
	return min(2, max(0, world.field_state.enemy_hp - ordinary)) if supported_battle(world) else 0

static func fire_after_strike(world: WorldState) -> int:
	if not supported_battle(world) or world.field_state.enemy_hp <= 0: return 0
	var damage: int = min(2, world.field_state.enemy_hp)
	var battle: Dictionary = world.field_state.battle
	record(world, "STATION_POWER_SHOT", {"room_id": "relay_corridor", "battle_id": battle.id, "turn": battle.turn, "enemy": "feral_dog", "damage": damage, "remaining": state(world).charges - 1})
	return damage

static func validate_world(world: WorldState) -> String:
	var s: Dictionary = {"inspected": false, "mode": "OFF", "charges": 0}
	var room: String = ""
	var battle_id: int = 0
	var turn: int = 1
	var enemy_hp: int = 6
	var awaiting: int = -1
	var last_day: int = -1
	var context_day: int = -1
	var player_dead: bool = false
	for index: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[index]
		var p: Dictionary = e.payload
		if world.player != null and e.actor_id == world.player.npc_id:
			match e.type:
				"RELAY_ENTERED", "RELAY_MOVED": room = String(p.get("room_id", "")); context_day = e.day
				"RELAY_DAY_SPENT": context_day = e.day
				"RELAY_LEFT", "RELAY_TRIP_ENDED": room = ""
				"PLAYER_DIED": player_dead = true
				"RELAY_BATTLE_STARTED": battle_id = int(p.battle_id); turn = 1; enemy_hp = 6
				"RELAY_BATTLE_CONFIRMED": battle_id = 0
		if e.type == "FIELD_TURN":
			if p.has("turret_dealt"):
				if awaiting != index - 1 or not SimulationEngine.Relay.number(p.turret_dealt, 1, 2) or p.get("source", "") != "dungeon" or p.get("dungeon_id", "") != SITE or e.actor_id != world.player.npc_id: return "POWER_UNPAIRED_SHOT"
			elif awaiting >= 0: return "POWER_UNPAIRED_SHOT"
			if p.get("source", "") == "dungeon" and p.get("dungeon_id", "") == SITE:
				if awaiting >= 0:
					var shot: EventRecord = world.event_log[awaiting]
					if e.actor_id != shot.actor_id or e.day != shot.day or p.get("battle_id") != battle_id or p.get("turn") != turn or p.get("room_id") != room or p.get("command") not in ["ATTACK", "SHOOT"] or p.turret_dealt != shot.payload.damage or not SimulationEngine.Relay.number(p.get("dealt"), int(p.turret_dealt) + 1, enemy_hp) or p.turret_dealt != min(2, enemy_hp - (int(p.dealt) - int(p.turret_dealt))): return "POWER_INVALID_SHOT_TURN"
				enemy_hp = int(p.enemy_hp)
				turn += 1
			awaiting = -1
		if not e.type.begins_with("STATION_POWER_"): continue
		if e.type not in EVENTS or world.player == null or e.actor_id != world.player.npc_id or e.target_id != StringName(SITE) or p.size() != EVENTS[e.type] or not SimulationEngine.Relay.text(p.get("site_id"), SITE) or e.day < 0 or e.day < last_day or e.day > world.current_day or player_dead: return "POWER_INVALID_EVENT"
		last_day = e.day
		if e.type == "STATION_POWER_SHOT":
			if s.mode != "TURRET" or s.charges <= 0 or battle_id == 0 or room != "relay_corridor" or awaiting >= 0 or not SimulationEngine.Relay.text(p.get("room_id"), room) or not SimulationEngine.Relay.text(p.get("enemy"), "feral_dog") or not SimulationEngine.Relay.number(p.get("battle_id"), battle_id, battle_id) or not SimulationEngine.Relay.number(p.get("turn"), turn, turn) or not SimulationEngine.Relay.number(p.get("damage"), 1, 2) or not SimulationEngine.Relay.number(p.get("remaining"), int(s.charges) - 1, int(s.charges) - 1): return "POWER_INVALID_SHOT"
			s.charges -= 1
			awaiting = index
			continue
		if room != "relay_tunnel" or battle_id != 0 or e.day != context_day or not SimulationEngine.Relay.text(p.get("room_id"), room): return "POWER_INVALID_PANEL_CONTEXT"
		match e.type:
			"STATION_POWER_FOUND":
				if s.inspected: return "POWER_DUPLICATE_DISCOVERY"
				s.inspected = true
			"STATION_POWER_OFF":
				if not s.inspected or s.mode == "OFF" or not SimulationEngine.Relay.number(p.get("discarded"), int(s.charges), int(s.charges)): return "POWER_INVALID_OFF"
				s.mode = "OFF"; s.charges = 0
			"STATION_POWER_CONFIGURED":
				if not s.inspected or typeof(p.get("mode")) != TYPE_STRING or p.mode not in ["TURRET", "LIFT"] or not SimulationEngine.Relay.number(p.get("fuel_spent"), 1, 1) or not SimulationEngine.Relay.number(p.get("scrap_spent"), 1, 1) or not SimulationEngine.Relay.number(p.get("charges"), 2 if p.mode == "TURRET" else 0, 2 if p.mode == "TURRET" else 0) or (s.mode == p.mode and (p.mode == "LIFT" or s.charges == 2)): return "POWER_INVALID_CONFIGURATION"
				var skill: String = "ELECTRONICS" if p.mode == "TURRET" else "MECHANICS"
				var valid_tool: bool = p.mode == "LIFT" and SimulationEngine.Relay.text(p.get("method"), "TOOL") and typeof(p.get("tool_id")) == TYPE_STRING and p.tool_id in ["wrench", "crowbar"] and SimulationEngine.Relay.number(p.get("rank"), 0, 0)
				var valid_skill: bool = SimulationEngine.Relay.text(p.get("method"), skill) and SimulationEngine.Relay.text(p.get("tool_id"), "") and SimulationEngine.Relay.number(p.get("rank"), 1, world.player.capability.get_rank(skill))
				if not valid_tool and not valid_skill: return "POWER_INVALID_METHOD"
				s.mode = p.mode; s.charges = int(p.charges)
	if awaiting >= 0: return "POWER_UNPAIRED_SHOT"
	return ""

static func describe(world: WorldState) -> String:
	var s: Dictionary = state(world)
	var device: String = {"OFF": "設備未供電", "LIFT": "貨梯供電中：入口↔檔案室，每次仍計一次換房", "TURRET": "砲塔接管中：剩%d次支援，僅在守路戰鬥進攻後補射最多2傷害" % s.charges}[s.mode]
	return device + "\n改接砲塔：本人電子1；改接貨梯：本人機械1或工具。每次耗燃料1＋廢料1，互斥供電。斷電不退款，未用支援會丟失。"
