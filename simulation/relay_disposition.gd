extends RefCounted

const SITE: String = "dungeon:buried_relay"
const ROOM: String = "relay_records"
const COMMANDS: Array[String] = ["HAND_OVER_TARGET", "RELEASE_TARGET", "WITNESS_CAPTIVE_DEATH", "REPORT_TARGET_DEATH", "REPORT_TARGET_RELEASE"]
const EVENTS: Dictionary = {"CUSTODY_RELEASED": 3, "CUSTODY_DEATH_WITNESSED": 4, "CUSTODY_REPORTED": 6}
const TERMS: Dictionary = {"LIVE": {"caps": 80, "standing": 4}, "DEAD": {"caps": 30, "standing": 1}, "RELEASED": {"caps": 0, "standing": -3}}

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = {"capture_index": -1, "kill_index": -1, "confirmed": false, "released": false, "release_index": -1, "witness_index": -1, "death_index": -1, "death_held": false, "handed_over": false, "reported": false, "outcome": ""}
	if world == null or world.player == null: return s
	var target_id: String = ""
	var owner_dead: bool = false
	for i: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[i]
		if target_id != "" and String(e.actor_id) == target_id and e.type == "NAMED_NPC_DIED":
			s.death_index = i
			s.death_held = s.capture_index >= 0 and not s.released and not s.handed_over and not owner_dead
		if e.actor_id != world.player.npc_id: continue
		match e.type:
			"BOUNTY_TARGET_ACCEPTED": target_id = String(e.target_id)
			"PLAYER_DIED", "NAMED_NPC_DIED": owner_dead = true
			"PURSUIT_RESULT":
				if SimulationEngine.Relay.text(e.payload.get("outcome"), "CAPTURED"): s.capture_index = i; s.confirmed = false
				elif SimulationEngine.Relay.text(e.payload.get("outcome"), "TARGET_DEAD"): s.kill_index = i; s.confirmed = false
			"PURSUIT_CONFIRMED":
				if SimulationEngine.Relay.number(e.payload.get("result_index"), int(s.capture_index), int(s.capture_index)) or SimulationEngine.Relay.number(e.payload.get("result_index"), int(s.kill_index), int(s.kill_index)): s.confirmed = true
			"CUSTODY_RELEASED": s.released = true; s.release_index = i
			"CUSTODY_DEATH_WITNESSED": s.witness_index = i
			"CUSTODY_REPORTED":
				s.reported = true; s.outcome = e.payload.get("outcome", "")
				s.handed_over = SimulationEngine.Relay.text(s.outcome, "LIVE")
	return s

static func evidence(s: Dictionary, command_id: String) -> int:
	if command_id == "REPORT_TARGET_RELEASE": return int(s.release_index)
	if command_id == "REPORT_TARGET_DEATH": return int(s.kill_index) if s.kill_index >= 0 else int(s.witness_index)
	return int(s.capture_index)

static func intent(world: WorldState, command_id: String) -> PlayerIntent:
	var s: Dictionary = state(world)
	var p: Dictionary = {"site_id": SITE, "command": command_id, "evidence_index": evidence(s, command_id)}
	if command_id == "WITNESS_CAPTIVE_DEATH": p.death_index = s.death_index
	return PlayerIntent.create_dungeon_action(world.player.npc_id, p)

static func authorize(world: WorldState, p: Dictionary) -> String:
	var invalid: String = SimulationEngine.Dungeon.validate_world(world)
	if invalid != "": return invalid
	if not SimulationEngine.Relay.text(p.get("site_id"), SITE) or typeof(p.get("command")) != TYPE_STRING or p.command not in COMMANDS or p.size() != (4 if p.command == "WITNESS_CAPTIVE_DEATH" else 3): return "CUSTODY_INVALID_INTENT"
	var s: Dictionary = state(world)
	if typeof(p.get("evidence_index")) != TYPE_INT or p.evidence_index < 0 or p.evidence_index != evidence(s, p.command): return "CUSTODY_STALE_EVIDENCE"
	if s.reported: return "CUSTODY_ALREADY_REPORTED"
	var owner: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if owner == null or not owner.is_alive(): return "CUSTODY_PLAYER_DEAD"
	if SimulationEngine.RelayCustody.pending(world) or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0 or world.active_encounter != null or world.pending_encounter_result >= 0 or SimulationEngine.Dungeon.state(world).active: return "CUSTODY_ACTIVITY_PENDING"
	if not s.confirmed: return "CUSTODY_CONFIRM_FIRST"
	var relay: Dictionary = SimulationEngine.Relay.state(world)
	var target: NpcLifeState = SimulationEngine.RelayTarget.life(world)
	if p.command in ["RELEASE_TARGET", "WITNESS_CAPTIVE_DEATH"]:
		if not relay.active or relay.room_id != ROOM or owner.status != NpcLifeState.Status.SETTLED or owner.population_container_id != SimulationEngine.Relay.HOME: return "CUSTODY_REQUIRES_RECORDS"
	else:
		if relay.active or SimulationEngine.RelayTarget.town(world) != SimulationEngine.Relay.HOME: return "CUSTODY_RETURN_GRAY_VALLEY"
	match p.command:
		"HAND_OVER_TARGET", "RELEASE_TARGET":
			if s.released or s.handed_over or SimulationEngine.RelayCustody.held_target(world) == &"": return "CUSTODY_NOT_YOURS"
		"WITNESS_CAPTIVE_DEATH":
			if typeof(p.get("death_index")) != TYPE_INT or p.death_index != s.death_index or not s.death_held or s.witness_index >= 0 or s.released or target == null or target.is_alive(): return "CUSTODY_NO_DEATH_TO_WITNESS"
		"REPORT_TARGET_DEATH":
			if s.released or target == null or target.is_alive() or (s.kill_index < 0 and s.witness_index < 0): return "CUSTODY_NO_DEATH_PROOF"
		"REPORT_TARGET_RELEASE":
			if not s.released: return "CUSTODY_NO_RELEASE_PROOF"
	return ""

static func commit(world: WorldState, p: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var invalid: String = authorize(world, p)
	if invalid != "": return {"success": false, "error": invalid}
	if engine == null: return {"success": false, "error": "CUSTODY_ENGINE_REQUIRED"}
	var staged: WorldState = world.duplicate_state()
	var kind: String
	var facts: Dictionary
	if p.command == "RELEASE_TARGET":
		kind = "CUSTODY_RELEASED"; facts = {"site_id": SITE, "room_id": ROOM, "capture_index": p.evidence_index}
	elif p.command == "WITNESS_CAPTIVE_DEATH":
		kind = "CUSTODY_DEATH_WITNESSED"; facts = {"site_id": SITE, "room_id": ROOM, "capture_index": p.evidence_index, "death_index": p.death_index}
	else:
		var outcome: String = {"HAND_OVER_TARGET": "LIVE", "REPORT_TARGET_DEATH": "DEAD", "REPORT_TARGET_RELEASE": "RELEASED"}[p.command]
		var terms: Dictionary = TERMS[outcome]
		staged.player.money += int(terms.caps)
		kind = "CUSTODY_REPORTED"; facts = {"site_id": SITE, "city_id": String(SimulationEngine.Relay.HOME), "evidence_index": p.evidence_index, "outcome": outcome, "caps_gained": terms.caps, "standing_delta": terms.standing}
	staged.record_event(EventRecord.new(staged.current_day, kind, staged.player.npc_id, StringName(SimulationEngine.RelayTarget.state(staged).npc_id), facts))
	invalid = engine.validate_invariants(staged)
	if invalid != "": return {"success": false, "error": invalid}
	var count: int = world.event_log.size()
	world.player = staged.player; world.event_log = staged.event_log
	if events != null:
		for i: int in range(count, world.event_log.size()): events.append(world.event_log[i])
	return {"success": true, "action": "DUNGEON_ACTION"}

static func validate_world(world: WorldState) -> String:
	var target: String = ""
	var room: String = ""
	var city: String = ""
	var owner_dead: bool = false
	var target_dead: bool = false
	var target_settled: bool = true
	var pending: bool = false
	var other_pending: bool = false
	var capture: int = -1
	var kill: int = -1
	var confirmed: bool = false
	var released: int = -1
	var handed_over: bool = false
	var reported: bool = false
	var witnessed: int = -1
	var death_index: int = -1
	var death_held: bool = false
	var last_day: int = -1
	for i: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[i]
		var p: Dictionary = e.payload
		if target != "" and String(e.actor_id) == target:
			if e.type == "NAMED_NPC_DIED":
				target_dead = true; death_index = i
				death_held = capture >= 0 and released < 0 and not handed_over and not owner_dead and target_settled
			elif e.type == "NAMED_NPC_MIGRATION_STARTED": target_settled = false
			elif e.type == "NAMED_MIGRATION_COMPLETED": target_settled = e.target_id == SimulationEngine.Relay.HOME
		if world.player != null and e.actor_id == world.player.npc_id:
			match e.type:
				"BOUNTY_TARGET_ACCEPTED": target = String(e.target_id)
				"PLAYER_MATERIALIZED", "NAMED_MIGRATION_COMPLETED": city = String(e.target_id)
				"PLAYER_TRAVEL_STARTED": city = ""
				"RELAY_ENTERED", "RELAY_MOVED": room = String(p.get("room_id", ""))
				"RELAY_LEFT", "RELAY_TRIP_ENDED": room = ""
				"PLAYER_DIED", "NAMED_NPC_DIED": owner_dead = true
				"PURSUIT_STARTED": pending = true
				"PURSUIT_RESULT":
					if SimulationEngine.Relay.text(p.get("outcome"), "CAPTURED"): capture = i; confirmed = false
					elif SimulationEngine.Relay.text(p.get("outcome"), "TARGET_DEAD"): kill = i; confirmed = false
				"PURSUIT_CONFIRMED":
					pending = false
					if SimulationEngine.Relay.number(p.get("result_index"), capture, capture) or SimulationEngine.Relay.number(p.get("result_index"), kill, kill): confirmed = true
				"DUNGEON_ENTERED", "RELAY_BATTLE_STARTED": other_pending = true
				"DUNGEON_LEFT", "DUNGEON_TRIP_ENDED", "RELAY_BATTLE_CONFIRMED": other_pending = false
		if not e.type.begins_with("CUSTODY_"): continue
		if e.type not in EVENTS or world.player == null or e.actor_id != world.player.npc_id or target == "" or String(e.target_id) != target or p.size() != EVENTS[e.type] or not SimulationEngine.Relay.text(p.get("site_id"), SITE) or e.day < 0 or e.day < last_day or e.day > world.current_day or owner_dead or pending or other_pending or not confirmed or reported: return "CUSTODY_INVALID_CONTEXT"
		last_day = e.day
		if e.type in ["CUSTODY_RELEASED", "CUSTODY_DEATH_WITNESSED"]:
			if room != ROOM or city != String(SimulationEngine.Relay.HOME) or not SimulationEngine.Relay.text(p.get("room_id"), ROOM) or capture < 0 or not SimulationEngine.Relay.number(p.get("capture_index"), capture, capture) or released >= 0 or handed_over: return "CUSTODY_INVALID_CAPTURE_SOURCE"
			if e.type == "CUSTODY_RELEASED":
				if target_dead or not target_settled: return "CUSTODY_INVALID_RELEASE"
				released = i
			else:
				if not target_dead or not death_held or witnessed >= 0 or not SimulationEngine.Relay.number(p.get("death_index"), death_index, death_index): return "CUSTODY_INVALID_DEATH_SOURCE"
				var death: EventRecord = world.event_log[death_index]
				if death.target_id != SimulationEngine.Relay.HOME or death.payload.size() not in [2, 3] or not SimulationEngine.Relay.text(death.payload.get("npc_id"), target) or not SimulationEngine.Relay.text(death.payload.get("settlement_id"), String(SimulationEngine.Relay.HOME)) or (death.payload.has("cause") and typeof(death.payload.cause) != TYPE_STRING): return "CUSTODY_INVALID_DEATH_SOURCE"
				witnessed = i
		else:
			if room != "" or city != String(SimulationEngine.Relay.HOME) or not SimulationEngine.Relay.text(p.get("city_id"), city) or typeof(p.get("outcome")) != TYPE_STRING or p.outcome not in TERMS: return "CUSTODY_INVALID_REPORT"
			var source: int = capture if p.outcome == "LIVE" else (released if p.outcome == "RELEASED" else (kill if kill >= 0 else witnessed))
			var terms: Dictionary = TERMS[p.outcome]
			if source < 0 or not SimulationEngine.Relay.number(p.get("evidence_index"), source, source) or not SimulationEngine.Relay.number(p.get("caps_gained"), int(terms.caps), int(terms.caps)) or not SimulationEngine.Relay.number(p.get("standing_delta"), int(terms.standing), int(terms.standing)): return "CUSTODY_INVALID_REPORT_SOURCE"
			if p.outcome == "LIVE":
				if target_dead or not target_settled or released >= 0: return "CUSTODY_INVALID_HANDOVER"
				handed_over = true
			elif p.outcome == "DEAD" and (not target_dead or released >= 0): return "CUSTODY_INVALID_DEAD_REPORT"
			reported = true
	return ""

static func describe(world: WorldState) -> String:
	var s: Dictionary = state(world)
	var ls: NpcLifeState = SimulationEngine.RelayTarget.life(world)
	var current: String = "灰鴉已死亡。" if ls != null and not ls.is_alive() else "灰鴉仍活著。"
	if s.reported:
		return current + {"LIVE": "\n已移交灰谷：80瓶蓋、地方信任＋4。灰谷在原中繼站接手看管；不能再由你放人。", "DEAD": "\n已回報死訊：30瓶蓋、地方信任＋1。", "RELEASED": "\n已坦白放人：沒有賞金、地方信任−3。"}[s.outcome] + "\n這張懸賞已結案，不能重領。"
	if s.released: return current + "\n你已放他自由；他會照自己的處境留居或遷徙。可自願回灰谷坦白：無賞金、地方信任−3。"
	if s.capture_index >= 0:
		if ls != null and not ls.is_alive(): return current + ("\n已親自檢視死訊，可回灰谷領30瓶蓋、信任＋1。" if s.witness_index >= 0 else "\n需在檔案室親自檢視，才有死訊可回報。")
		if SimulationEngine.RelayCustody.held_target(world) == &"": return current + "\n拘留者已死亡，他已恢復普通居民行動。"
		return current + "\n仍拘留在舊中繼站，尚未交人。回灰谷移交：80瓶蓋、信任＋4；或回檔案室放人。"
	if s.kill_index >= 0: return current + "\n你親眼確認了他的死亡；回灰谷可領30瓶蓋、信任＋1。"
	return "懸賞條件：活人移交80瓶蓋／信任＋4；親見死訊30瓶蓋／信任＋1。放人後坦白無賞金／信任−3。偵查費12瓶蓋另計。"
