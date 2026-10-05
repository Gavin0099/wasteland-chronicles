extends RefCounted

const SITE: String = "dungeon:buried_relay"
const DEVICE: StringName = &"device:relay_hound"
const COMMANDS: Array[String] = ["INSPECT_HOUND", "REPAIR_HOUND", "CHARGE_HOUND", "HOUND_SUPPORT_ON", "HOUND_SUPPORT_OFF", "HOUND_OPEN_TUNNEL"]
const EVENTS: Dictionary = {"DOG_FOUND": 4, "DOG_REPAIRED": 12, "DOG_CHARGED": 7, "DOG_MODE_SET": 5, "DOG_DOOR_OPENED": 7, "DOG_ASSISTED": 10}
const Party = preload("res://simulation/party.gd")

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = {"found": false, "repaired": false, "energy": 0, "support": false, "door_open": false, "revision": -1}
	if world == null or world.player == null: return s
	for index: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[index]
		if e.actor_id != world.player.npc_id or e.type not in EVENTS: continue
		s.revision = index
		match e.type:
			"DOG_FOUND": s.found = true
			"DOG_REPAIRED": s.repaired = true; s.energy = 4
			"DOG_CHARGED", "DOG_ASSISTED", "DOG_DOOR_OPENED": s.energy = int(e.payload.energy_remaining)
			"DOG_MODE_SET": s.support = e.payload.enabled
		if e.type == "DOG_DOOR_OPENED": s.door_open = true
	return s

static func method(world: WorldState) -> Dictionary:
	var rank: int = world.player.capability.get_rank("MECHANICS")
	if rank >= 1: return {"method": "PERSONAL", "rank": rank, "tool_id": "", "companion_id": ""}
	var tool_id: String = SimulationEngine.Relay.tool(world)
	if tool_id != "": return {"method": "TOOL", "rank": 0, "tool_id": tool_id, "companion_id": ""}
	if Party.current(world) == Party.ABBAN: return {"method": "ABBAN", "rank": 2, "tool_id": "", "companion_id": Party.ABBAN}
	return {}

static func intent(world: WorldState, command_id: String) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"site_id": SITE, "command": command_id, "revision": int(state(world).revision)})

static func context(world: WorldState) -> Dictionary:
	var room: String = ""
	var relay: Dictionary = SimulationEngine.Relay.state(world)
	var waterworks: Dictionary = SimulationEngine.Dungeon.state(world)
	if relay.active: room = relay.room_id
	elif waterworks.active: room = waterworks.room_id
	return {"site_id": SITE, "room_id": room, "city_id": String(world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id), "revision": int(state(world).revision)}

static func authorize(world: WorldState, p: Dictionary) -> String:
	var invalid: String = SimulationEngine.Dungeon.validate_world(world)
	if invalid != "": return invalid
	if p.size() != 3 or not SimulationEngine.Relay.text(p.get("site_id"), SITE) or typeof(p.get("command")) != TYPE_STRING or p.command not in COMMANDS: return "HOUND_INVALID_INTENT"
	var s: Dictionary = state(world)
	if typeof(p.get("revision")) != TYPE_INT or p.revision != s.revision: return "HOUND_STALE_REVISION"
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or not life.is_alive(): return "HOUND_PLAYER_DEAD"
	if life.status != NpcLifeState.Status.SETTLED or world.get_settlement(life.population_container_id) == null: return "HOUND_REQUIRES_SETTLED"
	if SimulationEngine.RelayCustody.pending(world) or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0 or world.active_encounter != null or world.pending_encounter_result >= 0: return "HOUND_ACTIVITY_PENDING"
	var relay: Dictionary = SimulationEngine.Relay.state(world)
	if p.command in ["INSPECT_HOUND", "REPAIR_HOUND"]:
		if not relay.active or relay.room_id != "relay_entrance": return "HOUND_REQUIRES_ENTRANCE"
	if p.command == "INSPECT_HOUND": return ""
	if not s.found: return "HOUND_INSPECT_FIRST"
	if p.command == "REPAIR_HOUND":
		if s.repaired: return "HOUND_ALREADY_REPAIRED"
		if world.player.capability.get_rank("ELECTRONICS") < 1: return "HOUND_NEED_ELECTRONICS"
		if method(world).is_empty(): return "HOUND_NEED_MECHANICAL_HELP"
		if world.player.inventory.fuel < 1: return "HOUND_NEED_FUEL"
		return "" if world.player.inventory.scrap >= 3 else "HOUND_NEED_SCRAP"
	if not s.repaired: return "HOUND_REPAIR_FIRST"
	match p.command:
		"CHARGE_HOUND":
			if s.energy == 4: return "HOUND_ALREADY_FULL"
			return "" if world.player.inventory.fuel >= 1 else "HOUND_NEED_FUEL"
		"HOUND_SUPPORT_ON", "HOUND_SUPPORT_OFF": return "HOUND_MODE_UNCHANGED" if s.support == (p.command == "HOUND_SUPPORT_ON") else ""
		"HOUND_OPEN_TUNNEL":
			if not relay.active or relay.room_id != "relay_tunnel": return "HOUND_REQUIRES_DOOR"
			if relay.tunnel_open: return "HOUND_DOOR_ALREADY_OPEN"
			return "" if s.energy >= 2 else "HOUND_NEED_ENERGY_2"
	return "HOUND_INVALID_INTENT"

static func commit(world: WorldState, p: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var invalid: String = authorize(world, p)
	if invalid != "": return {"success": false, "error": invalid}
	if p.command == "INSPECT_HOUND" and state(world).found: return {"success": true, "action": "DUNGEON_ACTION"}
	if engine == null: return {"success": false, "error": "HOUND_ENGINE_REQUIRED"}
	var staged: WorldState = world.duplicate_state()
	var s: Dictionary = state(staged)
	var facts: Dictionary = context(staged)
	var kind: String = {"INSPECT_HOUND": "DOG_FOUND", "REPAIR_HOUND": "DOG_REPAIRED", "CHARGE_HOUND": "DOG_CHARGED", "HOUND_SUPPORT_ON": "DOG_MODE_SET", "HOUND_SUPPORT_OFF": "DOG_MODE_SET", "HOUND_OPEN_TUNNEL": "DOG_DOOR_OPENED"}[p.command]
	match p.command:
		"REPAIR_HOUND":
			facts.merge(method(staged)); facts.merge({"electronics_rank": staged.player.capability.get_rank("ELECTRONICS"), "fuel_spent": 1, "scrap_spent": 3, "energy_remaining": 4})
			staged.player.inventory.fuel -= 1; staged.player.inventory.scrap -= 3
		"CHARGE_HOUND":
			facts.merge({"energy_before": s.energy, "energy_remaining": 4, "fuel_spent": 1}); staged.player.inventory.fuel -= 1
		"HOUND_SUPPORT_ON", "HOUND_SUPPORT_OFF": facts.enabled = p.command == "HOUND_SUPPORT_ON"
		"HOUND_OPEN_TUNNEL": facts.merge({"energy_before": s.energy, "energy_remaining": int(s.energy) - 2, "energy_spent": 2})
	staged.record_event(EventRecord.new(staged.current_day, kind, staged.player.npc_id, DEVICE, facts))
	invalid = engine.validate_invariants(staged)
	if invalid != "": return {"success": false, "error": invalid}
	var count: int = world.event_log.size()
	world.player = staged.player; world.event_log = staged.event_log
	if events != null:
		for index: int in range(count, world.event_log.size()): events.append(world.event_log[index])
	return {"success": true, "action": "DUNGEON_ACTION"}

static func preview(world: WorldState, ordinary: int) -> int:
	var s: Dictionary = state(world)
	return min(2, max(0, world.field_state.enemy_hp - ordinary)) if s.repaired and s.support and s.energy > 0 and not world.field_state.battle.is_empty() else 0

# Called only inside the existing field combat's detached stage, before turret.
static func assist(world: WorldState) -> int:
	var damage: int = preview(world, 0)
	if damage <= 0: return 0
	var s: Dictionary = state(world)
	var battle: Dictionary = world.field_state.battle
	world.record_event(EventRecord.new(world.current_day, "DOG_ASSISTED", world.player.npc_id, DEVICE, {"site_id": SITE, "revision": s.revision, "battle_id": battle.id, "turn": battle.turn, "source": battle.get("source", "field"), "dungeon_id": battle.get("dungeon_id", ""), "room_id": battle.get("room_id", ""), "enemy": WorldState.Field.battle_enemy(world.field_state), "damage": damage, "energy_remaining": int(s.energy) - 1}))
	return damage

static func validate_world(world: WorldState) -> String:
	if not world.event_log.any(func(e: EventRecord) -> bool: return e.type.begins_with("DOG_") or (e.type == "FIELD_TURN" and e.payload.has("dog_dealt"))): return ""
	if world.player == null: return "HOUND_ORPHAN_DEVICE" if world.event_log.any(func(e: EventRecord) -> bool: return e.type.begins_with("DOG_")) else ""
	var found: bool = false
	var repaired: bool = false
	var energy: int = 0
	var support: bool = false
	var revision: int = -1
	var city: String = ""
	var room: String = ""
	var site: String = ""
	var companion: String = ""
	var player_dead: bool = false
	var door_open: bool = false
	var last_day: int = -1
	var pending: bool = false
	var battle: Dictionary = {}
	var field_hp: int = 6
	var battle_sequence: int = 0
	var party_id: String = ""
	var awaiting: int = -1
	for index: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[index]
		var p: Dictionary = e.payload
		var ours: bool = e.actor_id == world.player.npc_id
		if ours:
			last_day = max(last_day, e.day) if not e.type.begins_with("DOG_") else last_day
			match e.type:
				"PLAYER_MATERIALIZED", "NAMED_MIGRATION_COMPLETED": city = String(e.target_id); party_id = ""; pending = false
				"PLAYER_TRAVEL_STARTED": city = ""; party_id = String(p.get("party_id", ""))
				"PLAYER_DIED", "NAMED_NPC_DIED": player_dead = true
				"RELAY_ENTERED", "RELAY_MOVED": room = String(p.get("room_id", "")); site = SITE
				"DUNGEON_ENTERED", "DUNGEON_ROOM_ENTERED": room = String(p.get("room_id", "")); site = SimulationEngine.Dungeon.SITE
				"RELAY_LEFT", "RELAY_TRIP_ENDED", "DUNGEON_LEFT", "DUNGEON_TRIP_ENDED": room = ""; site = ""
				"COMPANION_JOINED": companion = String(p.get("companion_id", ""))
				"COMPANION_LEFT": companion = ""
				"RELAY_TUNNEL_OPENED": door_open = true
				"PURSUIT_STARTED", "TRAVEL_ENCOUNTER": pending = true
				"PURSUIT_CONFIRMED", "TRAVEL_ENCOUNTER_CONFIRMED": pending = false
				"RELAY_BATTLE_STARTED", "DUNGEON_BATTLE_STARTED": battle = {"id": int(p.battle_id), "turn": 1, "source": "dungeon", "dungeon_id": site, "room_id": room, "enemy": p.enemy, "enemy_hp": WorldState.Field.Enemies.max_hp(p.enemy)}; battle_sequence = int(p.battle_id)
				"ROAD_COMBAT_BEGAN":
					if not SimulationEngine.Relay.number(p.get("battle_id"), 1, 2147483647) or (p.has("target_enemy") and (typeof(p.target_enemy) != TYPE_STRING or not WorldState.Field.Enemies.exists(p.target_enemy))): return "HOUND_INVALID_ROAD_CONTEXT"
					var party: RefugeePartyState = world.get_refugee_party(StringName(party_id))
					var enemy: String = WorldState.Field.road_enemy_for({"target_enemy": p.get("target_enemy", ""), "route_type": String(party.route_type) if party != null else ""})
					battle = {"id": int(p.battle_id), "turn": 1, "source": "road", "dungeon_id": "", "room_id": "", "enemy": enemy, "enemy_hp": WorldState.Field.Enemies.max_hp(enemy)}; battle_sequence = int(p.battle_id); pending = false
				"FIELD_ACTION":
					if SimulationEngine.Relay.text(p.get("command"), "START"):
						battle_sequence += 1; battle = {"id": battle_sequence, "turn": 1, "source": "field", "dungeon_id": "", "room_id": "", "enemy": "feral_dog", "enemy_hp": field_hp}
					elif SimulationEngine.Relay.text(p.get("command"), "CONFIRM"): battle = {}; pending = false
				"RELAY_BATTLE_CONFIRMED", "DUNGEON_BATTLE_CONFIRMED": battle = {}; pending = false
				"FIELD_RESULT":
					if SimulationEngine.Relay.text(p.get("source", "field"), "field") and SimulationEngine.Relay.text(p.get("outcome"), "VICTORY"): field_hp = 0
					pending = true
		if awaiting >= 0 and index != awaiting:
			if e.type == "STATION_POWER_SHOT" and index == awaiting + 1: continue
			if e.type != "FIELD_TURN" or not ours or index not in [awaiting + 1, awaiting + 2]: return "HOUND_UNPAIRED_SUPPORT"
		if e.type == "FIELD_TURN" and ours:
			if p.has("dog_dealt"):
				if awaiting < 0 or not SimulationEngine.Relay.number(p.get("dog_dealt"), 1, 2): return "HOUND_UNPAIRED_SUPPORT"
				if typeof(p.get("command")) != TYPE_STRING or p.command not in ["ATTACK", "SHOOT"]: return "HOUND_INVALID_SUPPORT_COMMAND"
				var proof: EventRecord = world.event_log[awaiting]
				if e.day != proof.day or battle.is_empty() or not SimulationEngine.Relay.number(p.get("battle_id"), int(battle.id), int(battle.id)) or not SimulationEngine.Relay.number(p.get("turn"), int(battle.turn), int(battle.turn)) or not SimulationEngine.Relay.number(p.get("dog_dealt"), int(proof.payload.damage), int(proof.payload.damage)) or not SimulationEngine.Relay.number(p.get("dealt"), int(p.dog_dealt) + 1, int(battle.enemy_hp)) or not SimulationEngine.Relay.number(p.get("enemy_hp"), 0, int(battle.enemy_hp)) or int(p.enemy_hp) + int(p.dealt) != int(battle.enemy_hp): return "HOUND_INVALID_SUPPORT_TURN"
				if not SimulationEngine.Relay.number(p.get("turret_dealt", 0), 0, 2): return "HOUND_INVALID_SUPPORT_DAMAGE"
				var turret: int = int(p.get("turret_dealt", 0))
				if p.dog_dealt != min(2, int(p.enemy_hp) + int(p.dog_dealt) + turret): return "HOUND_INVALID_SUPPORT_DAMAGE"
				if battle.source == "dungeon" and (not SimulationEngine.Relay.text(p.get("source"), "dungeon") or not SimulationEngine.Relay.text(p.get("dungeon_id"), battle.dungeon_id) or not SimulationEngine.Relay.text(p.get("room_id"), battle.room_id)): return "HOUND_INVALID_SUPPORT_SOURCE"
				if battle.source == "road" and (city != "" or party_id == "" or e.target_id != StringName(party_id)): return "HOUND_INVALID_SUPPORT_SOURCE"
				if battle.source in ["field", "road"] and p.has("source") and not SimulationEngine.Relay.text(p.source, battle.source): return "HOUND_INVALID_SUPPORT_SOURCE"
				awaiting = -1
			elif awaiting >= 0: return "HOUND_UNPAIRED_SUPPORT"
			if not battle.is_empty():
				if not SimulationEngine.Relay.number(p.get("enemy_hp"), 0, int(battle.enemy_hp)): return "HOUND_INVALID_SUPPORT_TURN"
				battle.turn += 1; battle.enemy_hp = int(p.enemy_hp)
				if battle.source == "field": field_hp = int(p.enemy_hp)
		elif e.type == "FIELD_TURN" and p.has("dog_dealt"): return "HOUND_INVALID_SUPPORT_OWNER"
		if not e.type.begins_with("DOG_"): continue
		if e.type not in EVENTS or not ours or e.target_id != DEVICE or p.size() != EVENTS[e.type] or not SimulationEngine.Relay.text(p.get("site_id"), SITE) or not SimulationEngine.Relay.number(p.get("revision"), revision, revision) or e.day < 0 or e.day < last_day or e.day > world.current_day or player_dead: return "HOUND_INVALID_EVENT"
		last_day = e.day
		if e.type == "DOG_ASSISTED":
			if not repaired or not support or energy <= 0 or battle.is_empty() or awaiting >= 0 or not SimulationEngine.Relay.number(p.get("battle_id"), int(battle.id), int(battle.id)) or not SimulationEngine.Relay.number(p.get("turn"), int(battle.turn), int(battle.turn)) or not SimulationEngine.Relay.text(p.get("source"), battle.source) or not SimulationEngine.Relay.text(p.get("dungeon_id"), battle.dungeon_id) or not SimulationEngine.Relay.text(p.get("room_id"), battle.room_id) or not SimulationEngine.Relay.text(p.get("enemy"), battle.enemy) or not SimulationEngine.Relay.number(p.get("damage"), 1, 2) or not SimulationEngine.Relay.number(p.get("energy_remaining"), energy - 1, energy - 1): return "HOUND_INVALID_SUPPORT"
			energy -= 1; awaiting = index; revision = index
			continue
		if city == "" or world.get_settlement(StringName(city)) == null or not SimulationEngine.Relay.text(p.get("city_id"), city) or not SimulationEngine.Relay.text(p.get("room_id"), room) or pending or not battle.is_empty(): return "HOUND_INVALID_CONTEXT"
		match e.type:
			"DOG_FOUND":
				if found or site != SITE or room != "relay_entrance": return "HOUND_INVALID_DISCOVERY"
				found = true
			"DOG_REPAIRED":
				if not found or repaired or site != SITE or room != "relay_entrance" or not SimulationEngine.Relay.number(p.get("electronics_rank"), 1, world.player.capability.get_rank("ELECTRONICS")) or not SimulationEngine.Relay.number(p.get("fuel_spent"), 1, 1) or not SimulationEngine.Relay.number(p.get("scrap_spent"), 3, 3) or not SimulationEngine.Relay.number(p.get("energy_remaining"), 4, 4): return "HOUND_INVALID_REPAIR"
				var personal: bool = SimulationEngine.Relay.text(p.get("method"), "PERSONAL") and SimulationEngine.Relay.number(p.get("rank"), 1, world.player.capability.get_rank("MECHANICS")) and SimulationEngine.Relay.text(p.get("tool_id"), "") and SimulationEngine.Relay.text(p.get("companion_id"), "")
				var tool: bool = SimulationEngine.Relay.text(p.get("method"), "TOOL") and SimulationEngine.Relay.number(p.get("rank"), 0, 0) and typeof(p.get("tool_id")) == TYPE_STRING and p.tool_id in ["wrench", "crowbar"] and SimulationEngine.Relay.text(p.get("companion_id"), "")
				var abban: bool = SimulationEngine.Relay.text(p.get("method"), "ABBAN") and companion == Party.ABBAN and SimulationEngine.Relay.text(p.get("companion_id"), companion) and SimulationEngine.Relay.text(p.get("tool_id"), "") and SimulationEngine.Relay.number(p.get("rank"), 2, 2)
				if not personal and not tool and not abban: return "HOUND_INVALID_METHOD"
				repaired = true; energy = 4
			"DOG_CHARGED":
				if not repaired or energy >= 4 or not SimulationEngine.Relay.number(p.get("energy_before"), energy, energy) or not SimulationEngine.Relay.number(p.get("energy_remaining"), 4, 4) or not SimulationEngine.Relay.number(p.get("fuel_spent"), 1, 1): return "HOUND_INVALID_CHARGE"
				energy = 4
			"DOG_MODE_SET":
				if not repaired or typeof(p.get("enabled")) != TYPE_BOOL or p.enabled == support: return "HOUND_INVALID_MODE"
				support = p.enabled
			"DOG_DOOR_OPENED":
				if not repaired or site != SITE or room != "relay_tunnel" or door_open or energy < 2 or not SimulationEngine.Relay.number(p.get("energy_before"), energy, energy) or not SimulationEngine.Relay.number(p.get("energy_spent"), 2, 2) or not SimulationEngine.Relay.number(p.get("energy_remaining"), energy - 2, energy - 2): return "HOUND_INVALID_DOOR"
				door_open = true; energy -= 2
		revision = index
	return "HOUND_UNPAIRED_SUPPORT" if awaiting >= 0 else ""

static func describe(world: WorldState) -> String:
	var s: Dictionary = state(world)
	if not s.repaired: return "中繼站入口有一台損壞的機械犬。修復需本人電子1，並有機械1／扳手或撬棍／阿扳協助；消耗燃料1＋廢料3。修好後能源4，先不自動支援。"
	return "機械犬 · 能源%d／4 · 戰鬥支援%s\n開維修內門耗能源2。一般戰鬥進攻後補上最多2傷害，耗能源1；普通攻擊已擊倒敵人便不耗電。\n燃料1可補滿至4；剩餘能源不折抵。可暫停支援，把能源留給開門。" % [s.energy, "開啟" if s.support else "關閉"]
