extends RefCounted

# RLY-4/5: a bound named duel and custody of the existing resident.
const SITE: String = "dungeon:buried_relay"
const ROOM: String = "relay_records"
const COMMANDS: Array[String] = ["CHALLENGE_TARGET", "SUBDUE_TARGET", "DISARM_TARGET", "BRACE_TARGET", "BIND_TARGET", "RETREAT_TARGET", "CONFIRM_CAPTURE", "LETHAL_TARGET", "SHOOT_TARGET"]
const TURNS: Array[String] = ["SUBDUE_TARGET", "DISARM_TARGET", "BRACE_TARGET", "BIND_TARGET", "RETREAT_TARGET", "LETHAL_TARGET", "SHOOT_TARGET"]
const EVENTS: Dictionary = {"PURSUIT_STARTED": 7, "PURSUIT_TURN": 16, "PURSUIT_RESULT": 8, "PURSUIT_CONFIRMED": 5}

static func empty_state() -> Dictionary:
	return {"active": false, "session_id": 0, "turn": 1, "target_hp": 8, "disarmed": false, "prepared": false, "hp": 12, "receipt": -1, "outcome": "", "captured": false, "killed": false}

static func fold(s: Dictionary, e: EventRecord, index: int) -> void:
	var p: Dictionary = e.payload
	match e.type:
		"PURSUIT_STARTED":
			s.active = true; s.session_id = int(p.session_id); s.turn = 1
			s.hp = int(p.hp); s.prepared = false
		"PURSUIT_TURN":
			s.hp = int(p.hp); s.target_hp = int(p.target_hp)
			s.disarmed = p.disarmed; s.prepared = p.prepared; s.turn += 1
		"PURSUIT_RESULT":
			s.active = false; s.receipt = index; s.outcome = p.outcome
			if p.outcome == "CAPTURED": s.captured = true
			if p.outcome == "TARGET_DEAD": s.killed = true
		"PURSUIT_CONFIRMED": s.receipt = -1; s.outcome = ""

static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = empty_state()
	if world == null or world.player == null: return s
	for i: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[i]
		if e.actor_id == world.player.npc_id and e.type in EVENTS: fold(s, e, i)
	return s

static func pending(world: WorldState) -> bool:
	var s: Dictionary = state(world)
	return s.active or s.receipt >= 0

static func held_target(world: WorldState) -> StringName:
	if world == null or world.player == null: return &""
	var owner: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	var disposition: Dictionary = SimulationEngine.RelayDisposition.state(world)
	if not state(world).captured or disposition.released: return &""
	if not disposition.handed_over and (owner == null or not owner.is_alive()): return &""
	var target: NpcLifeState = SimulationEngine.RelayTarget.life(world)
	return target.npc_id if target != null and target.is_alive() else &""

static func intent(world: WorldState, command_id: String) -> PlayerIntent:
	var p: Dictionary = {"site_id": SITE, "command": command_id}
	var s: Dictionary = state(world)
	if command_id in TURNS: p.session_id = s.session_id; p.turn = s.turn
	elif command_id == "CONFIRM_CAPTURE": p.result_index = s.receipt
	return PlayerIntent.create_dungeon_action(world.player.npc_id, p)

static func authorize(world: WorldState, p: Dictionary) -> String:
	var invalid: String = SimulationEngine.Dungeon.validate_world(world)
	if invalid != "": return invalid
	if not SimulationEngine.Relay.text(p.get("site_id"), SITE) or typeof(p.get("command")) != TYPE_STRING or p.command not in COMMANDS: return "PURSUIT_INVALID_INTENT"
	var s: Dictionary = state(world)
	if p.command == "CONFIRM_CAPTURE":
		return "" if p.size() == 3 and typeof(p.get("result_index")) == TYPE_INT and s.receipt >= 0 and p.result_index == s.receipt else "PURSUIT_STALE_RESULT"
	var owner: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if owner == null or not owner.is_alive(): return "PURSUIT_PLAYER_DEAD"
	var relay: Dictionary = SimulationEngine.Relay.state(world)
	if not relay.active or relay.room_id != ROOM or owner.status != NpcLifeState.Status.SETTLED or owner.population_container_id != SimulationEngine.Relay.HOME: return "PURSUIT_REQUIRES_RECORDS"
	if s.receipt >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0 or world.active_encounter != null or world.pending_encounter_result >= 0 or SimulationEngine.Dungeon.state(world).active: return "PURSUIT_ACTIVITY_PENDING"
	if not SimulationEngine.RelayTarget.present_at_relay(world): return "PURSUIT_TARGET_NOT_HERE"
	if s.captured: return "PURSUIT_ALREADY_CAPTURED"
	if p.command == "CHALLENGE_TARGET":
		if p.size() != 2 or s.active: return "PURSUIT_INVALID_INTENT"
		return "" if SimulationEngine.RelayTarget.state(world).blocked else "PURSUIT_BLOCK_EXIT_FIRST"
	if p.size() != 4 or not s.active or typeof(p.get("session_id")) != TYPE_INT or typeof(p.get("turn")) != TYPE_INT or p.session_id != s.session_id or p.turn != s.turn: return "PURSUIT_STALE_TURN"
	match p.command:
		"DISARM_TARGET":
			if s.disarmed: return "PURSUIT_ALREADY_DISARMED"
			if world.player.capability.get_rank("MELEE") < 1 and s.target_hp > 3: return "PURSUIT_WEAKEN_OR_MELEE"
		"BIND_TARGET":
			if not s.disarmed or s.target_hp > 3: return "PURSUIT_DISARM_AND_WEAKEN"
			if not world.player.item_inventory.contains("rope"): return "PURSUIT_NEED_SECOND_ROPE"
		"SHOOT_TARGET":
			var gun: Dictionary = WorldState.Field.firearm_for(world)
			if gun.is_empty() or not world.player.item_inventory.contains(world.player.equipment.equipped_item("main_hand")): return "PURSUIT_NEED_FIREARM"
			if world.player.item_inventory.quantity(gun.ammo_item_id) < gun.ammo_spent: return "PURSUIT_NEED_AMMO"
	return ""

static func shot_damage(world: WorldState, s: Dictionary) -> int:
	var quick: int = 2 if s.turn == 1 and WorldState.Field.Properties.has(world.player.equipment.equipped_item("main_hand"), "quick_draw") else 0
	return WorldState.Field.shot_damage(world) + quick

static func record(world: WorldState, kind: String, p: Dictionary) -> void:
	p.site_id = SITE; p.room_id = ROOM
	world.record_event(EventRecord.new(world.current_day, kind, world.player.npc_id, StringName(SimulationEngine.RelayTarget.state(world).npc_id), p))

static func commit(world: WorldState, p: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var invalid: String = authorize(world, p)
	if invalid != "": return {"success": false, "error": invalid}
	if engine == null: return {"success": false, "error": "PURSUIT_ENGINE_REQUIRED"}
	var staged: WorldState = world.duplicate_state()
	var s: Dictionary = state(staged)
	match p.command:
		"CHALLENGE_TARGET":
			var target: Dictionary = SimulationEngine.RelayTarget.state(staged)
			if not target.interviewed and not target.escaped:
				SimulationEngine.RelayTarget.record(staged, "BOUNTY_TARGET_INTERVIEW", {"room_id": ROOM}, target.npc_id)
			record(staged, "PURSUIT_STARTED", {"session_id": int(s.session_id) + 1, "hp": staged.player.field_kit.hp, "target_hp": s.target_hp, "disarmed": s.disarmed, "prepared": false})
		"CONFIRM_CAPTURE": record(staged, "PURSUIT_CONFIRMED", {"session_id": s.session_id, "result_index": s.receipt, "outcome": s.outcome})
		_:
			var command_id: String = p.command
			var rank: int = staged.player.capability.get_rank("MELEE")
			var shot: bool = command_id == "SHOOT_TARGET"
			var attack: int = shot_damage(staged, s) if shot else WorldState.Field.attack_damage(staged)
			var offensive: bool = command_id in ["SUBDUE_TARGET", "LETHAL_TARGET", "SHOOT_TARGET"]
			var protection: int = WorldState.Field.Gear.protection(staged.player)
			var dealt: int = min(int(s.target_hp) - (1 if command_id == "SUBDUE_TARGET" else 0), attack + (2 if s.prepared else 0)) if offensive else 0
			var killed: bool = int(s.target_hp) - dealt == 0
			var disarmed: bool = s.disarmed or command_id == "DISARM_TARGET"
			var prepared: bool = true if command_id == "BRACE_TARGET" else (false if offensive else s.prepared)
			var incoming: int = 1 if disarmed else 3
			var raw: int = 0 if command_id == "BIND_TARGET" or killed else (1 if command_id == "RETREAT_TARGET" else max(0, incoming - protection - (3 if command_id == "BRACE_TARGET" else 0)))
			var taken: int = min(staged.player.field_kit.hp, raw)
			var practice: Dictionary = {}
			if dealt > 0:
				var skill: String = "FIREARMS" if shot else "MELEE"
				var growth: Dictionary = staged.player.capability.grant_practice(skill, staged.current_day)
				if growth.get("awarded", false): practice = {"skill_id": skill, "rank_up": growth.rank_up, "from_rank": growth.from_rank, "to_rank": growth.to_rank, "points": growth.points, "required": growth.required}
			if command_id == "BIND_TARGET":
				var removed: Dictionary = staged.player.item_inventory.remove_item("rope", 1)
				if not removed.success: return removed
			staged.player.field_kit.hp -= taken
			var facts: Dictionary = {"session_id": s.session_id, "turn": s.turn, "command": command_id, "dealt": dealt, "taken": taken, "hp": staged.player.field_kit.hp, "target_hp": int(s.target_hp) - dealt, "disarmed": disarmed, "prepared": prepared, "rope_spent": 1 if command_id == "BIND_TARGET" else 0, "melee_rank": rank, "attack": attack, "protection": protection, "practice": practice}
			if shot:
				var gun: Dictionary = WorldState.Field.firearm_for(staged)
				facts.weapon_id = staged.player.equipment.equipped_item("main_hand")
				facts.ammo_item_id = gun.ammo_item_id; facts.ammo_spent = gun.ammo_spent
				facts.firearms_rank = world.player.capability.get_rank("FIREARMS")
				var removed: Dictionary = staged.player.item_inventory.remove_item(gun.ammo_item_id, int(gun.ammo_spent))
				if not removed.success: return removed
				facts.ammo_remaining = staged.player.item_inventory.quantity(gun.ammo_item_id)
			record(staged, "PURSUIT_TURN", facts)
			var outcome: String = ""
			if killed:
				initialize_population_before_death(staged)
				var npc_id: StringName = StringName(SimulationEngine.RelayTarget.state(staged).npc_id)
				var death: Dictionary = staged.npc_life_state_registry.commit_named_death(staged, npc_id)
				if not death.success: return death
				staged.record_event(EventRecord.new(staged.current_day, "NAMED_NPC_DIED", npc_id, SimulationEngine.Relay.HOME, {"npc_id": String(npc_id), "settlement_id": String(SimulationEngine.Relay.HOME), "cause": "bounty_combat"}))
				outcome = "TARGET_DEAD"
			elif staged.player.field_kit.hp == 0:
				initialize_population_before_death(staged)
				var death: Dictionary = staged.npc_life_state_registry.commit_named_death(staged, staged.player.npc_id)
				if not death.success: return death
				staged.record_event(EventRecord.new(staged.current_day, "PLAYER_DIED", staged.player.npc_id, SimulationEngine.Relay.HOME, {"cause": "capture_combat", "days_survived": staged.current_day, "in_transit": false}))
				outcome = "DEAD"
			elif command_id == "BIND_TARGET": outcome = "CAPTURED"
			elif command_id == "RETREAT_TARGET": outcome = "ESCAPED"
			if outcome != "": record(staged, "PURSUIT_RESULT", {"session_id": s.session_id, "turn": s.turn, "outcome": outcome, "hp": staged.player.field_kit.hp, "target_hp": int(s.target_hp) - dealt, "disarmed": disarmed})
	invalid = engine.validate_invariants(staged)
	if invalid != "": return {"success": false, "error": invalid}
	var count: int = world.event_log.size()
	world.player = staged.player; world.settlements = staged.settlements
	world.total_initial_population = staged.total_initial_population
	world.npc_life_state_registry = staged.npc_life_state_registry
	world.event_log = staged.event_log
	if events != null:
		for index: int in range(count, world.event_log.size()): events.append(world.event_log[index])
	return {"success": true, "action": "DUNGEON_ACTION"}

static func initialize_population_before_death(world: WorldState) -> void:
	# An expedition can kill someone before the first daily tick establishes this
	# existing baseline. Preserve the same Living + In-Transit + Deaths invariant.
	if world.total_initial_population != -1: return
	var total: int = 0
	for settlement: SettlementState in world.settlements.values():
		total += settlement.population + settlement.cumulative_deaths
	for party: RefugeePartyState in world.refugees.values():
		if party.is_active and not party.is_arrived: total += party.headcount
	world.total_initial_population = total

static func validate_world(world: WorldState) -> String:
	var s: Dictionary = empty_state()
	var target_id: String = ""
	var target_city: String = String(SimulationEngine.Relay.HOME)
	var room: String = ""
	var target_dead: bool = false
	var owner_dead: bool = false
	var released: bool = false
	var transferred: bool = false
	var last_ammo: String = ""
	var ammo_remaining: int = -1
	var blocked: bool = false
	var witnessed: bool = false
	var generic_pending: bool = false
	var expected_result: String = ""
	var awaiting_turn: int = -1
	var result_turn: int = 0
	var day: int = -1
	for i: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[i]
		var p: Dictionary = e.payload
		if expected_result != "" and e.type not in ["PURSUIT_RESULT", "PLAYER_DIED", "NAMED_NPC_DIED"]: return "PURSUIT_MISSING_RESULT"
		if world.player != null and e.actor_id == world.player.npc_id:
			match e.type:
				"BOUNTY_TARGET_ACCEPTED": target_id = String(e.target_id)
				"BOUNTY_TARGET_EXIT_BLOCKED": blocked = true
				"BOUNTY_TARGET_INTERVIEW", "BOUNTY_TARGET_ESCAPED": witnessed = true
				"RELAY_ENTERED", "RELAY_MOVED": room = String(p.get("room_id", "")); day = e.day
				"RELAY_DAY_SPENT": day = e.day
				"RELAY_LEFT", "RELAY_TRIP_ENDED": room = ""
				"RELAY_BATTLE_STARTED": generic_pending = true
				"RELAY_BATTLE_CONFIRMED": generic_pending = false
				"NAMED_NPC_DIED", "PLAYER_DIED": owner_dead = true
				"CUSTODY_RELEASED": released = true
				"CUSTODY_REPORTED": transferred = SimulationEngine.Relay.text(p.get("outcome"), "LIVE")
		if target_id != "" and String(e.actor_id) == target_id:
			if e.type == "NAMED_NPC_DIED":
				if s.active and (expected_result != "TARGET_DEAD" or i != awaiting_turn + 1): return "PURSUIT_INVALID_TARGET_LIFE"
				target_dead = true
			elif e.type == "NAMED_NPC_MIGRATION_STARTED":
				if s.active or s.receipt >= 0 or (s.captured and not released and (transferred or not owner_dead) and not target_dead): return "PURSUIT_HELD_MIGRATION"
				target_city = ""
			elif e.type == "NAMED_MIGRATION_COMPLETED": target_city = String(e.target_id)
		if (s.active or s.receipt >= 0) and not e.type.begins_with("PURSUIT_") and (e.type.begins_with("RELAY_") or e.type.begins_with("BOUNTY_TARGET_") or e.type.begins_with("STATION_POWER_") or e.type in ["PLAYER_TRAVEL_STARTED", "FIELD_ACTION", "DUNGEON_ENTERED"]): return "PURSUIT_CONFLICTING_ACTIVITY"
		if not e.type.begins_with("PURSUIT_"): continue
		var payload_size: int = 21 if e.type == "PURSUIT_TURN" and SimulationEngine.Relay.text(p.get("command"), "SHOOT_TARGET") else int(EVENTS.get(e.type, -1))
		if e.type not in EVENTS or world.player == null or e.actor_id != world.player.npc_id or target_id == "" or String(e.target_id) != target_id or p.size() != payload_size or not SimulationEngine.Relay.text(p.get("site_id"), SITE) or not SimulationEngine.Relay.text(p.get("room_id"), ROOM) or room != ROOM or generic_pending or (target_dead and e.type != "PURSUIT_CONFIRMED" and not (e.type == "PURSUIT_RESULT" and expected_result == "TARGET_DEAD")) or target_city != String(SimulationEngine.Relay.HOME) or e.day != day or e.day > world.current_day: return "PURSUIT_INVALID_CONTEXT"
		if not SimulationEngine.Relay.number(p.get("session_id"), 1, 2147483647): return "PURSUIT_INVALID_SESSION"
		if e.type == "PURSUIT_STARTED":
			if s.active or s.receipt >= 0 or s.captured or owner_dead or not blocked or not witnessed or p.session_id != int(s.session_id) + 1 or not SimulationEngine.Relay.number(p.get("hp"), 1, 12) or not SimulationEngine.Relay.number(p.get("target_hp"), int(s.target_hp), int(s.target_hp)) or typeof(p.get("disarmed")) != TYPE_BOOL or p.disarmed != s.disarmed or typeof(p.get("prepared")) != TYPE_BOOL or p.prepared: return "PURSUIT_INVALID_START"
			last_ammo = ""; ammo_remaining = -1
		elif p.session_id != s.session_id: return "PURSUIT_INVALID_SESSION"
		elif e.type == "PURSUIT_TURN":
			if not s.active or owner_dead or expected_result != "" or typeof(p.get("command")) != TYPE_STRING or p.command not in TURNS or not SimulationEngine.Relay.number(p.get("turn"), int(s.turn), int(s.turn)): return "PURSUIT_INVALID_TURN"
			for key: String in ["dealt", "taken", "hp", "target_hp", "rope_spent", "melee_rank", "attack", "protection"]:
				if not SimulationEngine.Relay.number(p.get(key), 0, 1024): return "PURSUIT_INVALID_TURN"
			if typeof(p.get("disarmed")) != TYPE_BOOL or typeof(p.get("prepared")) != TYPE_BOOL or typeof(p.get("practice")) != TYPE_DICTIONARY or p.attack < 2 or p.melee_rank > world.player.capability.get_rank("MELEE") or p.protection > 12: return "PURSUIT_INVALID_TURN"
			var skill_rank: int = int(p.melee_rank)
			if p.command == "SHOOT_TARGET":
				var gun: Dictionary = WorldState.Field.Weapons.firearm(p.get("weapon_id"))
				if gun.is_empty() or not SimulationEngine.Relay.text(p.get("ammo_item_id"), String(gun.ammo_item_id)) or not SimulationEngine.Relay.number(p.get("ammo_spent"), int(gun.ammo_spent), int(gun.ammo_spent)) or not SimulationEngine.Relay.number(p.get("ammo_remaining"), 0, 99) or not SimulationEngine.Relay.number(p.get("firearms_rank"), 0, world.player.capability.get_rank("FIREARMS")) or p.attack < int(gun.damage) + int(p.firearms_rank): return "PURSUIT_INVALID_AMMO"
				if last_ammo == p.ammo_item_id and p.ammo_remaining != ammo_remaining - int(gun.ammo_spent): return "PURSUIT_INVALID_AMMO"
				last_ammo = p.ammo_item_id; ammo_remaining = int(p.ammo_remaining)
				skill_rank = int(p.firearms_rank)
			if p.command == "DISARM_TARGET" and (s.disarmed or (p.melee_rank < 1 and s.target_hp > 3)): return "PURSUIT_INVALID_DISARM"
			if p.command == "BIND_TARGET" and (not s.disarmed or s.target_hp > 3): return "PURSUIT_INVALID_BIND"
			var disarmed: bool = s.disarmed or p.command == "DISARM_TARGET"
			var offensive: bool = p.command in ["SUBDUE_TARGET", "LETHAL_TARGET", "SHOOT_TARGET"]
			var prepared: bool = true if p.command == "BRACE_TARGET" else (false if offensive else s.prepared)
			var dealt: int = min(int(s.target_hp) - (1 if p.command == "SUBDUE_TARGET" else 0), int(p.attack) + (2 if s.prepared else 0)) if offensive else 0
			var raw: int = 0 if p.command == "BIND_TARGET" or int(s.target_hp) - dealt == 0 else (1 if p.command == "RETREAT_TARGET" else max(0, (1 if disarmed else 3) - int(p.protection) - (3 if p.command == "BRACE_TARGET" else 0)))
			if p.dealt != dealt or p.taken != min(int(s.hp), raw) or p.hp != int(s.hp) - int(p.taken) or p.target_hp != int(s.target_hp) - dealt or p.disarmed != disarmed or p.prepared != prepared or p.rope_spent != (1 if p.command == "BIND_TARGET" else 0): return "PURSUIT_INVALID_DAMAGE"
			if not valid_practice(p.practice, p.command, dealt, skill_rank): return "PURSUIT_INVALID_PRACTICE"
			if p.target_hp == 0: expected_result = "TARGET_DEAD"
			elif p.hp == 0: expected_result = "DEAD"
			elif p.command == "BIND_TARGET": expected_result = "CAPTURED"
			elif p.command == "RETREAT_TARGET": expected_result = "ESCAPED"
			result_turn = int(s.turn)
			awaiting_turn = i
		elif e.type == "PURSUIT_RESULT":
			if not s.active or expected_result == "" or not SimulationEngine.Relay.text(p.get("outcome"), expected_result) or not SimulationEngine.Relay.number(p.get("turn"), result_turn, result_turn) or not SimulationEngine.Relay.number(p.get("hp"), int(s.hp), int(s.hp)) or not SimulationEngine.Relay.number(p.get("target_hp"), int(s.target_hp), int(s.target_hp)) or typeof(p.get("disarmed")) != TYPE_BOOL or p.disarmed != s.disarmed: return "PURSUIT_INVALID_RESULT"
			if expected_result == "DEAD":
				if not owner_dead or i != awaiting_turn + 2: return "PURSUIT_INVALID_DEATH"
				var death: EventRecord = world.event_log[i - 1]
				if death.type != "PLAYER_DIED" or death.actor_id != e.actor_id or death.day != e.day or death.target_id != SimulationEngine.Relay.HOME or death.payload.size() != 3 or not SimulationEngine.Relay.text(death.payload.get("cause"), "capture_combat") or not SimulationEngine.Relay.number(death.payload.get("days_survived"), e.day, e.day) or typeof(death.payload.get("in_transit")) != TYPE_BOOL or death.payload.in_transit: return "PURSUIT_INVALID_DEATH"
			elif expected_result == "TARGET_DEAD":
				if owner_dead or not target_dead or i != awaiting_turn + 2: return "PURSUIT_INVALID_TARGET_DEATH"
				var death: EventRecord = world.event_log[i - 1]
				if death.type != "NAMED_NPC_DIED" or String(death.actor_id) != target_id or death.target_id != SimulationEngine.Relay.HOME or death.day != e.day or death.payload.size() != 3 or not SimulationEngine.Relay.text(death.payload.get("npc_id"), target_id) or not SimulationEngine.Relay.text(death.payload.get("settlement_id"), String(SimulationEngine.Relay.HOME)) or not SimulationEngine.Relay.text(death.payload.get("cause"), "bounty_combat"): return "PURSUIT_INVALID_TARGET_DEATH"
			elif owner_dead or i != awaiting_turn + 1: return "PURSUIT_INVALID_RESULT"
			expected_result = ""
		elif e.type == "PURSUIT_CONFIRMED":
			if s.active or s.receipt < 0 or not SimulationEngine.Relay.number(p.get("result_index"), int(s.receipt), int(s.receipt)) or not SimulationEngine.Relay.text(p.get("outcome"), s.outcome): return "PURSUIT_INVALID_CONFIRMATION"
			if s.outcome == "DEAD": room = ""
		fold(s, e, i)
	if expected_result != "": return "PURSUIT_MISSING_RESULT"
	if s.active or s.receipt >= 0:
		if last_ammo != "" and world.player.item_inventory.quantity(last_ammo) != ammo_remaining: return "PURSUIT_INVALID_AMMO_SNAPSHOT"
		if world.current_day != day or world.player.field_kit.hp != s.hp or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0 or not SimulationEngine.Relay.state(world).active: return "PURSUIT_INVALID_SNAPSHOT"
		var owner: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if owner == null or owner.is_alive() == owner_dead or (owner_dead and s.active): return "PURSUIT_INVALID_SNAPSHOT"
		if s.active and not SimulationEngine.RelayTarget.present_at_relay(world): return "PURSUIT_INVALID_TARGET_LIFE"
	if s.captured and not released and (transferred or not owner_dead) and not target_dead:
		var ls: NpcLifeState = SimulationEngine.RelayTarget.life(world)
		if ls == null or not ls.is_alive() or ls.status != NpcLifeState.Status.SETTLED or ls.population_container_id != SimulationEngine.Relay.HOME: return "PURSUIT_INVALID_CUSTODY"
	if s.captured:
		var owner: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if owner == null or owner.is_alive() == owner_dead: return "PURSUIT_INVALID_OWNER_LIFE"
	return ""

static func valid_practice(p: Dictionary, command_id: String, dealt: int, rank: int) -> bool:
	if p.is_empty(): return true
	var skill: String = "FIREARMS" if command_id == "SHOOT_TARGET" else "MELEE"
	return command_id in ["SUBDUE_TARGET", "LETHAL_TARGET", "SHOOT_TARGET"] and dealt > 0 and CapabilityProfile.valid_practice_award(p, skill) and p.from_rank == rank

static func describe(world: WorldState) -> String:
	if state(world).captured or state(world).killed: return SimulationEngine.RelayDisposition.describe(world)
	if not state(world).captured: return "堵住退路後可制伏灰鴉：本人近戰1可先繳械；或先削弱至3生命。繳械後再用第二條繩索綁縛。"
	if not SimulationEngine.RelayTarget.life(world).is_alive(): return "灰鴉已死亡；歷史活捉紀錄保留，拘留已結束。"
	if held_target(world) == &"": return "拘留者已死亡，灰鴉已恢復普通居民行動；歷史活捉紀錄保留。"
	return "灰鴉仍活著，被拘留在灰谷舊中繼站。他不會隨你旅行或自主遷徙；目前尚未交人，也沒有領到活捉賞金。"
