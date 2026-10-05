extends RefCounted

# RLY-2: one existing human, explicit investigation, existing migration authority.
const SITE: String = "dungeon:buried_relay"
const HOME: StringName = &"settlement:gray_valley"
const DEST: StringName = &"settlement:new_hope"
const NAME: String = "灰鴉・洛克"
const FEE: int = 12
const COMMANDS: Array[String] = ["ACCEPT_TARGET", "ASK_TARGET", "INSPECT_EXIT", "BLOCK_EXIT", "CONFRONT_TARGET", "WITNESS_TARGET", "REPORT_TARGET"]
const EVENTS: Dictionary = {"BOUNTY_TARGET_ACCEPTED": 5, "BOUNTY_TARGET_INTEL": 2, "BOUNTY_TARGET_EXIT_FOUND": 2, "BOUNTY_TARGET_EXIT_BLOCKED": 4, "BOUNTY_TARGET_INTERVIEW": 2, "BOUNTY_TARGET_ESCAPED": 7, "BOUNTY_TARGET_WITNESSED": 2, "BOUNTY_TARGET_REPORTED": 4}

static func empty_state() -> Dictionary:
	return {"accepted": false, "npc_id": "", "intel": false, "exit_found": false, "blocked": false, "interviewed": false, "escaped": false, "left_home": false, "evidence_index": -1, "reported": false}

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = empty_state()
	if world == null or world.player == null: return s
	for i: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[i]
		if e.type == "NAMED_NPC_MIGRATION_STARTED" and String(e.actor_id) == s.npc_id: s.left_home = true
		if e.actor_id != world.player.npc_id or e.type not in EVENTS: continue
		match e.type:
			"BOUNTY_TARGET_ACCEPTED": s.accepted = true; s.npc_id = String(e.target_id)
			"BOUNTY_TARGET_INTEL": s.intel = true
			"BOUNTY_TARGET_EXIT_FOUND": s.exit_found = true
			"BOUNTY_TARGET_EXIT_BLOCKED": s.blocked = true
			"BOUNTY_TARGET_INTERVIEW": s.interviewed = true; s.evidence_index = i
			"BOUNTY_TARGET_ESCAPED": s.escaped = true; s.left_home = true; s.evidence_index = i
			"BOUNTY_TARGET_WITNESSED": s.evidence_index = i
			"BOUNTY_TARGET_REPORTED": s.reported = true
	return s

static func party_id(npc_id: String) -> StringName:
	return StringName("refugee:relay_target_" + npc_id.trim_prefix("npc:"))

static func life(world: WorldState) -> NpcLifeState:
	return world.npc_life_state_registry.get_life_state(StringName(state(world).npc_id))

static func present_at_relay(world: WorldState) -> bool:
	if SimulationEngine.RelayDisposition.state(world).released: return false
	var ls: NpcLifeState = life(world)
	return ls != null and ls.is_alive() and ls.status == NpcLifeState.Status.SETTLED and ls.population_container_id == HOME

static func town(world: WorldState) -> StringName:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	return ls.population_container_id if ls != null and ls.is_alive() and ls.status == NpcLifeState.Status.SETTLED else &""

static func authorize(world: WorldState, payload: Dictionary) -> String:
	var invalid: String = SimulationEngine.Dungeon.validate_world(world)
	if invalid != "": return invalid
	if SimulationEngine.RelayCustody.pending(world): return "PURSUIT_ACTIVITY_PENDING"
	if payload.size() != 2 or typeof(payload.get("site_id")) != TYPE_STRING or payload.site_id != SITE or typeof(payload.get("command")) != TYPE_STRING or payload.command not in COMMANDS: return "TARGET_INVALID_INTENT"
	if town(world) == &"": return "TARGET_REQUIRES_LIVING_TOWN"
	if SimulationEngine.Dungeon.state(world).active or world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0: return "TARGET_ACTIVITY_PENDING"
	var s: Dictionary = state(world)
	var relay: Dictionary = SimulationEngine.Relay.state(world)
	var command_id: String = payload.command
	if command_id == "ACCEPT_TARGET":
		if relay.active or town(world) != HOME: return "TARGET_REQUIRES_GRAY_VALLEY"
		if s.accepted: return "TARGET_ALREADY_ACCEPTED"
		if world.get_settlement(HOME).population <= world.npc_registry.get_named_count_at(HOME): return "TARGET_NO_ANONYMOUS_SLOT"
		return ""
	if not s.accepted: return "TARGET_NOTICE_REQUIRED"
	if command_id in ["ASK_TARGET", "WITNESS_TARGET", "REPORT_TARGET"]:
		if relay.active: return "TARGET_RETURN_TO_TOWN"
		if command_id == "ASK_TARGET": return "" if town(world) == HOME and not s.intel else "TARGET_INTEL_UNAVAILABLE"
		if command_id == "REPORT_TARGET": return "" if town(world) == HOME and s.evidence_index >= 0 and not s.reported else "TARGET_REPORT_UNAVAILABLE"
		var ls: NpcLifeState = life(world)
		if not s.left_home: return "TARGET_FOLLOW_MOVEMENT_FIRST"
		return "" if ls != null and ls.is_alive() and ls.status == NpcLifeState.Status.SETTLED and ls.population_container_id == town(world) else "TARGET_NOT_HERE"
	if not relay.active: return "TARGET_REQUIRES_RELAY"
	match command_id:
		"INSPECT_EXIT": return "" if relay.room_id == "relay_tunnel" and not s.exit_found else "TARGET_EXIT_UNAVAILABLE"
		"BLOCK_EXIT":
			if relay.room_id != "relay_tunnel" or not s.exit_found or s.blocked: return "TARGET_BLOCK_UNAVAILABLE"
			if not world.player.item_inventory.contains("rope"): return "TARGET_NEED_ROPE"
			return "" if world.player.inventory.scrap >= 1 else "TARGET_NEED_SCRAP"
		"CONFRONT_TARGET":
			if relay.room_id != "relay_records" or s.interviewed or s.escaped or not present_at_relay(world): return "TARGET_NOT_HERE"
			if not s.blocked and world.get_refugee_party(party_id(s.npc_id)) != null: return "TARGET_PARTY_ID_OCCUPIED"
			return ""
	return "TARGET_UNAUTHORIZED_COMMAND"

static func escape_days(world: WorldState) -> int:
	for route: CaravanState in world.caravans.values():
		if (route.origin_id == HOME and route.destination_id == DEST) or (route.origin_id == DEST and route.destination_id == HOME): return route.route_days
	return 0

static func record(world: WorldState, kind: String, payload: Dictionary, npc_id: String) -> void:
	payload.site_id = SITE
	world.record_event(EventRecord.new(world.current_day, kind, world.player.npc_id, StringName(npc_id), payload))

static func commit(world: WorldState, payload: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var invalid: String = authorize(world, payload)
	if invalid != "": return {"success": false, "error": invalid}
	if engine == null: return {"success": false, "error": "TARGET_ENGINE_REQUIRED"}
	var staged: WorldState = world.duplicate_state()
	var s: Dictionary = state(staged)
	var command_id: String = payload.command
	match command_id:
		"ACCEPT_TARGET":
			var identity: Dictionary = staged.npc_registry.materialize_identity(staged, HOME, NAME, 28)
			if not identity.success: return identity
			var npc_id: String = String(identity.npc.id)
			var registered: Dictionary = staged.npc_life_state_registry.register_life_state(staged, StringName(npc_id), HOME)
			if not registered.success: return registered
			var biography: Dictionary = staged.npc_profile_registry.assign_background(staged, StringName(npc_id), NpcProfile.Background.SCAVENGER)
			if not biography.success: return biography
			record(staged, "BOUNTY_TARGET_ACCEPTED", {"origin_id": String(HOME), "name": NAME, "age": 28, "background": NpcProfile.Background.SCAVENGER}, npc_id)
		"ASK_TARGET": record(staged, "BOUNTY_TARGET_INTEL", {"city_id": String(HOME)}, s.npc_id)
		"INSPECT_EXIT": record(staged, "BOUNTY_TARGET_EXIT_FOUND", {"room_id": "relay_tunnel"}, s.npc_id)
		"BLOCK_EXIT":
			var dropped: Dictionary = staged.player.drop_item("rope", 1)
			if not dropped.success: return dropped
			staged.player.inventory.scrap -= 1
			record(staged, "BOUNTY_TARGET_EXIT_BLOCKED", {"room_id": "relay_tunnel", "rope_spent": 1, "scrap_spent": 1}, s.npc_id)
		"CONFRONT_TARGET":
			if s.blocked:
				record(staged, "BOUNTY_TARGET_INTERVIEW", {"room_id": "relay_records"}, s.npc_id)
			else:
				var days: int = escape_days(staged)
				if days <= 0: return {"success": false, "error": "TARGET_ESCAPE_ROUTE_MISSING"}
				# Interaction occurs after the current day snapshot. The first full
				# road day is the next tick, retaining arrival = departure + D - 1.
				var departure: int = staged.current_day + 1
				var migrated: Dictionary = staged.npc_life_state_registry.begin_named_migration(staged, StringName(s.npc_id), DEST, party_id(s.npc_id), days, departure)
				if not migrated.success: return migrated
				record(staged, "BOUNTY_TARGET_ESCAPED", {"room_id": "relay_records", "origin_id": String(HOME), "destination_id": String(DEST), "party_id": String(party_id(s.npc_id)), "route_days": days, "departure_day": departure}, s.npc_id)
		"WITNESS_TARGET": record(staged, "BOUNTY_TARGET_WITNESSED", {"city_id": String(town(staged))}, s.npc_id)
		"REPORT_TARGET":
			staged.player.money += FEE
			record(staged, "BOUNTY_TARGET_REPORTED", {"city_id": String(HOME), "evidence_index": s.evidence_index, "caps_gained": FEE}, s.npc_id)
	invalid = engine.validate_invariants(staged)
	if invalid != "": return {"success": false, "error": invalid}
	var count: int = world.event_log.size()
	world.npc_registry = staged.npc_registry
	world.npc_life_state_registry = staged.npc_life_state_registry
	world.npc_profile_registry = staged.npc_profile_registry
	world.next_npc_sequence = staged.next_npc_sequence
	world.settlements = staged.settlements
	world.refugees = staged.refugees
	world.player = staged.player
	world.event_log = staged.event_log
	if events != null:
		for i: int in range(count, world.event_log.size()): events.append(world.event_log[i])
	return {"success": true, "action": "DUNGEON_ACTION", "target": state(world)}

static func validate_world(world: WorldState) -> String:
	var s: Dictionary = empty_state()
	var relay_room: String = ""
	var player_city: String = ""
	var target_city: String = String(HOME)
	var target_party: String = ""
	var target_dead: bool = false
	var escape_index: int = -1
	var last_day: int = -1
	var arrival_day: int = -1
	var waterworks: bool = false
	var combat_pending: bool = false
	var player_dead: bool = false
	for i: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[i]
		var p: Dictionary = e.payload
		if world.player != null and e.actor_id == world.player.npc_id:
			if e.type == "DUNGEON_ENTERED": waterworks = true
			elif e.type in ["DUNGEON_LEFT", "DUNGEON_TRIP_ENDED"]: waterworks = false
			elif e.type in ["RELAY_BATTLE_STARTED", "PURSUIT_STARTED"]: combat_pending = true
			elif e.type in ["RELAY_BATTLE_CONFIRMED", "PURSUIT_CONFIRMED"]: combat_pending = false
			elif e.type == "PLAYER_DIED": player_dead = true
			if e.type == "PLAYER_MATERIALIZED": player_city = String(e.target_id)
			elif e.type == "PLAYER_TRAVEL_STARTED": player_city = ""
			elif e.type == "NAMED_MIGRATION_COMPLETED": player_city = String(e.target_id)
			elif e.type in ["RELAY_ENTERED", "RELAY_MOVED"]: relay_room = String(p.get("room_id", ""))
			elif e.type in ["RELAY_LEFT", "RELAY_TRIP_ENDED"]: relay_room = ""
		if s.accepted and String(e.actor_id) == s.npc_id:
			if e.type == "NAMED_NPC_MIGRATION_STARTED":
				if target_dead or target_party != "" or not exact(p.get("origin"), target_city) or typeof(p.get("party_id")) != TYPE_STRING or typeof(p.get("destination")) != TYPE_STRING or not SimulationEngine.Relay.number(p.get("route_days"), 1, 2147483647): return "TARGET_INVALID_LIFE_HISTORY"
				target_party = p.party_id
				target_city = p.destination
				arrival_day = e.day + int(p.route_days) - 1
				s.left_home = true
			elif e.type == "NAMED_MIGRATION_COMPLETED":
				if target_dead or target_party == "" or not exact(p.get("party_id"), target_party) or String(e.target_id) != target_city or not exact(p.get("destination"), target_city) or not exact(p.get("npc_id"), s.npc_id) or e.day != arrival_day: return "TARGET_INVALID_LIFE_HISTORY"
				target_party = ""
			elif e.type == "NAMED_NPC_DIED": target_dead = true; target_party = ""; target_city = ""
		if not e.type.begins_with("BOUNTY_TARGET_"): continue
		if waterworks or combat_pending or player_dead: return "TARGET_CONFLICTING_ACTIVITY"
		if e.type not in EVENTS or world.player == null or e.actor_id != world.player.npc_id or p.size() != EVENTS[e.type] or not exact(p.get("site_id"), SITE) or e.day < 0 or e.day < last_day or e.day > world.current_day: return "TARGET_INVALID_EVENT"
		last_day = e.day
		if e.type == "BOUNTY_TARGET_ACCEPTED":
			if s.accepted or relay_room != "" or player_city != String(HOME) or e.target_id == e.actor_id or not exact(p.get("origin_id"), String(HOME)) or not exact(p.get("name"), NAME) or not integer(p.get("age"), 28) or not integer(p.get("background"), NpcProfile.Background.SCAVENGER): return "TARGET_INVALID_ACCEPTANCE"
			var parsed_id: String = String(e.target_id).trim_prefix("npc:")
			if parsed_id.length() != 8 or not parsed_id.is_valid_int() or int(parsed_id) <= 0 or String(e.target_id) != "npc:%08d" % int(parsed_id) or world.next_npc_sequence <= int(parsed_id): return "TARGET_INVALID_IDENTITY"
			s.accepted = true
			s.npc_id = String(e.target_id)
			continue
		if not s.accepted or String(e.target_id) != s.npc_id: return "TARGET_INVALID_EVENT_OWNER"
		match e.type:
			"BOUNTY_TARGET_INTEL":
				if s.intel or relay_room != "" or player_city != String(HOME) or not exact(p.get("city_id"), player_city): return "TARGET_INVALID_INTEL"
				s.intel = true
			"BOUNTY_TARGET_EXIT_FOUND":
				if s.exit_found or relay_room != "relay_tunnel" or not exact(p.get("room_id"), relay_room): return "TARGET_INVALID_EXIT"
				s.exit_found = true
			"BOUNTY_TARGET_EXIT_BLOCKED":
				if not s.exit_found or s.blocked or relay_room != "relay_tunnel" or not exact(p.get("room_id"), relay_room) or not integer(p.get("rope_spent"), 1) or not integer(p.get("scrap_spent"), 1): return "TARGET_INVALID_BLOCK"
				s.blocked = true
			"BOUNTY_TARGET_INTERVIEW", "BOUNTY_TARGET_ESCAPED":
				if s.interviewed or s.escaped or target_dead or target_party != "" or target_city != String(HOME) or relay_room != "relay_records" or not exact(p.get("room_id"), relay_room): return "TARGET_INVALID_CONFRONTATION"
				if e.type == "BOUNTY_TARGET_INTERVIEW":
					if not s.blocked: return "TARGET_EXIT_NOT_BLOCKED"
					s.interviewed = true
				else:
					if s.blocked or escape_days(world) <= 0 or not exact(p.get("origin_id"), String(HOME)) or not exact(p.get("destination_id"), String(DEST)) or not exact(p.get("party_id"), String(party_id(s.npc_id))) or not integer(p.get("route_days"), escape_days(world)) or not integer(p.get("departure_day"), e.day + 1): return "TARGET_INVALID_ESCAPE"
					s.escaped = true
					s.left_home = true
					target_party = p.party_id
					target_city = String(DEST)
					arrival_day = int(p.departure_day) + int(p.route_days) - 1
					escape_index = i
				s.evidence_index = i
			"BOUNTY_TARGET_WITNESSED":
				if not s.left_home or target_dead or target_party != "" or relay_room != "" or player_city == "" or player_city != target_city or not exact(p.get("city_id"), player_city): return "TARGET_INVALID_WITNESS"
				s.evidence_index = i
			"BOUNTY_TARGET_REPORTED":
				if s.reported or s.evidence_index < 0 or relay_room != "" or player_city != String(HOME) or not exact(p.get("city_id"), player_city) or not integer(p.get("evidence_index"), s.evidence_index) or not integer(p.get("caps_gained"), FEE): return "TARGET_INVALID_REPORT"
				s.reported = true
	if not s.accepted: return ""
	var identity: NpcIdentity = world.npc_registry.get_npc(StringName(s.npc_id))
	var profile: NpcProfile = world.npc_profile_registry.get_profile(StringName(s.npc_id))
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(StringName(s.npc_id))
	if identity == null or identity.name != NAME or identity.age_at_materialization != 28 or identity.origin_settlement_id != HOME or profile == null or profile.background != NpcProfile.Background.SCAVENGER or ls == null: return "TARGET_INVALID_IDENTITY"
	if target_dead:
		if ls.is_alive(): return "TARGET_INVALID_LIFE_SNAPSHOT"
	elif target_party != "":
		if ls.status != NpcLifeState.Status.IN_TRANSIT or String(ls.population_container_id) != target_party: return "TARGET_INVALID_LIFE_SNAPSHOT"
	elif ls.status != NpcLifeState.Status.SETTLED or String(ls.population_container_id) != target_city: return "TARGET_INVALID_LIFE_SNAPSHOT"
	if escape_index >= 0:
		var escaped: EventRecord = world.event_log[escape_index]
		var party: RefugeePartyState = world.get_refugee_party(party_id(s.npc_id))
		if party == null or party.origin_id != HOME or party.destination_id != DEST or party.route_days != escaped.payload.route_days or party.departure_day != escaped.payload.departure_day: return "TARGET_INVALID_ESCAPE_PARTY"
		if target_party == String(party.id) and (not party.is_active or party.is_arrived or party.headcount < 1 or party.days_remaining != max(0, party.route_days - max(0, world.current_day - party.departure_day + 1))): return "TARGET_INVALID_ESCAPE_PARTY"
	return ""

static func exact(value: Variant, expected: String) -> bool:
	return typeof(value) == TYPE_STRING and value == expected

static func integer(value: Variant, expected: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value == expected

static func describe(world: WorldState) -> String:
	var s: Dictionary = state(world)
	if not s.accepted: return "灰谷委託追查灰鴉的藏身處與動向，親自確認後回報可得12瓶蓋。\n" + SimulationEngine.RelayDisposition.describe(world)
	var ls: NpcLifeState = life(world)
	var location: String = "目標已死亡；已有的見證仍可回報。"
	if ls != null and ls.is_alive():
		if ls.status == NpcLifeState.Status.IN_TRANSIT:
			var party: RefugeePartyState = world.get_refugee_party(ls.population_container_id)
			location = "目標在途，正前往%s；還有%d天。" % [world.get_settlement(party.destination_id).name, party.days_remaining]
		else:
			location = "目標目前停留%s。" % world.get_settlement(ls.population_container_id).name
	if SimulationEngine.RelayCustody.state(world).captured: location += "\n" + SimulationEngine.RelayCustody.describe(world)
	elif s.interviewed: location += "\n你已堵住維修出口，在檔案室當面問過他；尚未拘捕，可帶第二條繩索回去制伏。"
	elif s.escaped: location += "\n你親眼看見他從維修出口逃上灰谷—新希望商路；可追到城鎮再確認。"
	elif s.intel: location += "\n居民指認他的破損左靴；他遇到人時會鑽維修出口。先到維修道查出口，繩索＋1廢料可封住。"
	else: location += "\n先在灰谷打聽習慣，再進中繼站值勤檔案室找人；也可以直接去。"
	location += "\n偵查費已領取，不能重領。" if s.reported else ("\n已有親見紀錄；返回灰谷可領12瓶蓋。" if s.evidence_index >= 0 else "\n尚未親自確認動向，不能領偵查費。")
	return location
