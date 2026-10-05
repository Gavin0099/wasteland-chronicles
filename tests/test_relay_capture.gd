extends "res://tests/test_relay_power.gd"

const Capture = preload("res://simulation/relay_custody.gd")

func _init() -> void:
	store = Store.new("user://tests/rly4/journey.json")
	call_deferred("run_capture")

func capture_pair(world: WorldState, twin: WorldState, command_id: String) -> void:
	var result: Dictionary = pair_intent(world, twin, Capture.intent(world, command_id), "capture " + command_id)
	if not result.success: print("CAPTURE FAILURE ", result)
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "capture global invariants")

func capture_prepared(ropes: int = 2, background: String = "MECHANIC", gear: Dictionary = {}) -> WorldState:
	var world: WorldState = PlayableWorld.create_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "追獵旅人", "age": 28, "background_id": background, "trait_ids": []})).success, "actual authored background for capture")
	world.player.money = 120 # Explicit preparation budget fixture; all equipment is bought.
	for slot: String in gear:
		check(world.player.pickup_item(gear[slot]).success, "explicit gear boundary owns " + gear[slot])
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, gear[slot], slot)).success, "actual boundary gear equipped in town")
	var twin: WorldState = disk_copy(world, "explicit120caps capture preparation budget")
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "rope", 1), "actual exit rope; unique item cannot carry two")
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "wrench", 1), "actual side-route tool")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 3), "actual exit and inner-door scrap")
	target_setup(world, twin)
	target_enter(world, twin)
	target_pair(world, twin, "BLOCK_EXIT")
	if ropes == 2:
		relay_pair(world, twin, "MOVE", "relay_entrance")
		relay_pair(world, twin, "EXIT")
		pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "rope", 1), "return to Gray buys a separate binding rope")
		relay_pair(world, twin, "ENTER")
		relay_pair(world, twin, "MOVE", "relay_tunnel")
	relay_pair(world, twin, "OPEN_TUNNEL")
	relay_pair(world, twin, "MOVE", "relay_records")
	check(world.player.money >= 0 and world.player.money < 120 and world.player.item_inventory.quantity("rope") == ropes - 1, "actual paid preparation within explicit120caps budget; exit rope really spent")
	return world

func capture_return(world: WorldState, twin: WorldState) -> void:
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "EXIT")

func capture_variants() -> void:
	var guard: WorldState = capture_prepared(2, "CARAVAN_GUARD")
	var twin: WorldState = disk_copy(guard, "actual personalMELEE1 guard")
	capture_pair(guard, twin, "CHALLENGE_TARGET")
	capture_pair(guard, twin, "DISARM_TARGET")
	check(guard.player.field_kit.hp == 11 and Capture.state(guard).target_hp == 8, "personalMELEE1 can first disarm; incoming1 immediately")
	capture_pair(guard, twin, "SUBDUE_TARGET")
	capture_pair(guard, twin, "SUBDUE_TARGET")
	check(guard.player.field_kit.hp == 9 and Capture.state(guard).target_hp == 2, "two base2+rank1 strikes with two unarmed1 counters")
	capture_pair(guard, twin, "BIND_TARGET")
	capture_pair(guard, twin, "CONFIRM_CAPTURE")
	var heavy: WorldState = capture_prepared(2, "MECHANIC", {"main_hand": "sledgehammer", "body": "ballistic_vest"})
	twin = disk_copy(heavy, "actual heavy weapon and protection fixture")
	capture_pair(heavy, twin, "CHALLENGE_TARGET")
	capture_pair(heavy, twin, "SUBDUE_TARGET")
	check(Capture.state(heavy).target_hp == 2 and heavy.player.field_kit.hp == 12, "authored hammer6 and protection3 versus armed3")
	capture_pair(heavy, twin, "SUBDUE_TARGET")
	check(Capture.state(heavy).target_hp == 1 and last_fact(heavy.to_dict(), "PURSUIT_TURN").payload.dealt == 1, "strong melee keeps alive floor1")
	capture_pair(heavy, twin, "SUBDUE_TARGET")
	check(Capture.state(heavy).target_hp == 1 and last_fact(heavy.to_dict(), "PURSUIT_TURN").payload.dealt == 0, "no damage or practice below floor1")
	capture_pair(heavy, twin, "DISARM_TARGET")
	capture_pair(heavy, twin, "BIND_TARGET")
	capture_pair(heavy, twin, "CONFIRM_CAPTURE")
	var retreat: WorldState = capture_prepared(1)
	twin = disk_copy(retreat, "missing second rope control")
	capture_pair(retreat, twin, "CHALLENGE_TARGET")
	capture_pair(retreat, twin, "BRACE_TARGET")
	capture_pair(retreat, twin, "BRACE_TARGET")
	capture_pair(retreat, twin, "SUBDUE_TARGET")
	check(Capture.state(retreat).target_hp == 4, "brace never stacks beyond2")
	capture_pair(retreat, twin, "SUBDUE_TARGET")
	capture_pair(retreat, twin, "DISARM_TARGET")
	rejected(retreat, Capture.intent(retreat, "BIND_TARGET"), "exit rope cannot bind; real second rope missing")
	capture_pair(retreat, twin, "RETREAT_TARGET")
	check(retreat.player.field_kit.hp == 4 and not Capture.state(retreat).captured and Capture.state(retreat).target_hp == 2, "retreat1 leaves disarmed wounded target alive, no custody")
	twin = disk_copy(retreat, "real retreat receipt Continue")
	capture_pair(retreat, twin, "CONFIRM_CAPTURE")
	capture_return(retreat, twin)
	pair_intent(retreat, twin, PlayerIntent.create_buy_item(retreat.player.npc_id, "rope", 1), "actual later rope purchase")
	relay_pair(retreat, twin, "ENTER")
	relay_pair(retreat, twin, "MOVE", "relay_tunnel")
	relay_pair(retreat, twin, "MOVE", "relay_records")
	capture_pair(retreat, twin, "CHALLENGE_TARGET")
	check(Capture.state(retreat).session_id == 2 and Capture.state(retreat).target_hp == 2 and Capture.state(retreat).disarmed, "new monotonic session retains actual wounds and disarm, no healing/rearming")
	capture_pair(retreat, twin, "BIND_TARGET")
	capture_pair(retreat, twin, "CONFIRM_CAPTURE")

func capture_refusals() -> void:
	var town: WorldState = normal_relay_start()
	for command_id: String in Capture.COMMANDS: rejected(town, Capture.intent(town, command_id), "no target/location " + command_id)
	var world: WorldState = capture_prepared()
	var twin: WorldState = disk_copy(world, "capture intent boundaries")
	var open_exit: Dictionary = world.to_dict().duplicate(true)
	open_exit.events.erase(last_fact(open_exit, "BOUNTY_TARGET_EXIT_BLOCKED"))
	open_exit.event_count = open_exit.events.size()
	var checked: Dictionary = WorldState.from_json_checked(JSON.stringify(open_exit))
	check(checked.success, "unblocked old exploration is valid positive control")
	if checked.success: rejected(checked.world, Capture.intent(checked.world, "CHALLENGE_TARGET"), "no capture with open exit")
	capture_pair(world, twin, "CHALLENGE_TARGET")
	var stale: PlayerIntent = Capture.intent(world, "SUBDUE_TARGET")
	capture_pair(world, twin, "BRACE_TARGET")
	rejected(world, stale, "stale prior turn cannot strike")
	for payload: Dictionary in [{"site_id": Capture.SITE, "command": "SUBDUE_TARGET", "session_id": false, "turn": 2}, {"site_id": Capture.SITE, "command": "SUBDUE_TARGET", "session_id": 1, "turn": 2, "dealt": 999}, {"site_id": Capture.SITE, "command": "SHOOT_TARGET"}, {"site_id": Capture.SITE, "command": "KILL_TARGET"}, {"site_id": Capture.SITE, "command": "RELEASE_TARGET"}, {"site_id": false, "command": "BIND_TARGET"}]: rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload), "closed own capture intent")
	rejected(world, PlayerIntent.create_dungeon_action(&"npc:unknown", Capture.intent(world, "SUBDUE_TARGET").payload), "wrong actor cannot capture")
	for command_id: String in ["MOVE", "FIND_CARD", "CONFRONT_TARGET", "POWER_OFF"]: rejected(world, relay_intent(world, command_id, "relay_tunnel" if command_id == "MOVE" else ""), "own pending locks " + command_id)
	var before: String = world.to_canonical_json()
	check(engine.tick(world).is_empty() and world.to_canonical_json() == before, "direct day clock cannot bypass own active combat")
	check(not Capture.commit(world, {"site_id": Capture.SITE, "command": "BIND_TARGET", "session_id": 1, "turn": 2}, [], engine).success and before == world.to_canonical_json(), "direct bind precondition refusal is atomic")
	var invalid_dead: WorldState = world.duplicate_state()
	var dying_target: StringName = StringName(TargetRules.state(invalid_dead).npc_id)
	check(invalid_dead.npc_life_state_registry.commit_named_death(invalid_dead, dying_target).success, "explicit active-duel external named-death boundary")
	invalid_dead.record_event(EventRecord.new(invalid_dead.current_day, "NAMED_NPC_DIED", dying_target, TargetRules.HOME, {"npc_id": String(dying_target), "settlement_id": String(TargetRules.HOME)}))
	check(Capture.validate_world(invalid_dead) == "PURSUIT_INVALID_TARGET_LIFE", "unsupported active target death refuses, never accepts permanently stuck save")
	relay_reject_fixture(invalid_dead.to_dict(), "active duel dead target fail-closed live+checked regression")
	capture_pair(world, twin, "RETREAT_TARGET")
	capture_pair(world, twin, "CONFIRM_CAPTURE")
	rejected(world, Capture.intent(world, "CONFIRM_CAPTURE"), "duplicate confirmation refuses")

func capture_lifecycle(valid: WorldState) -> void:
	var world: WorldState = disk_copy(valid, "held actual lifecycle")
	var twin: WorldState = disk_copy(world, "held twin")
	var npc_id: StringName = StringName(TargetRules.state(world).npc_id)
	var before: String = world.to_canonical_json()
	check(not world.npc_life_state_registry.begin_named_migration(world, npc_id, TargetRules.DEST, &"refugee:held", 3, world.current_day).success and before == world.to_canonical_json(), "direct lifecycle cannot migrate captive; byte atomic")
	var obs: NpcDecisionObservation = engine.build_npc_observation(world, npc_id, world.current_day)
	var intention: NpcDecisionIntent = NpcDecisionIntent.create(obs, [NpcDecisionEngine.Action.MIGRATE], NpcDecisionEngine.Action.MIGRATE, &"WATER_PRESSURE", TargetRules.DEST)
	check(engine.revalidate_migration_intent(world, intention).contains("custody") and before == world.to_canonical_json(), "stale autonomous intent revalidation denies held person atomically")
	var free: WorldState = valid.duplicate_state()
	var original_facts: Array[EventRecord] = free.event_log.duplicate()
	var free_facts: Array[EventRecord] = []
	for e: EventRecord in free.event_log:
		if not e.type.begins_with("PURSUIT_"): free_facts.append(e)
	free.event_log = free_facts
	check(free.npc_life_state_registry.begin_named_migration(free, npc_id, TargetRules.DEST, &"refugee:custody_fixture", 3, free.current_day).success, "ordinary free resident direct migration positive control")
	var migration: EventRecord = EventRecord.new(free.current_day, "NAMED_NPC_MIGRATION_STARTED", npc_id, TargetRules.DEST, {"origin": String(TargetRules.HOME), "destination": String(TargetRules.DEST), "party_id": "refugee:custody_fixture", "route_days": 3})
	free.record_event(migration)
	check(TargetRules.validate_world(free) == "", "reviewed ordinary life history control accepts actual migration")
	# Reinsert capture history into that genuinely migrated snapshot: target life
	# history is plausible, but migration contradicted then-active custody.
	free.event_log = original_facts
	free.record_event(migration)
	check(Capture.validate_world(free) == "PURSUIT_HELD_MIGRATION", "own history specifically rejects migration while custody was active")
	relay_reject_fixture(free.to_dict(), "plausible population-balanced held migration live and checked")
	var prior_decisions: int = world.decision_audit_trail.size()
	capture_return(world, twin)
	world.get_settlement(TargetRules.HOME).water_pressure = 80.0
	twin.get_settlement(TargetRules.HOME).water_pressure = 80.0
	engine.tick(world); engine.tick(twin)
	parity(world, twin, "held actual world tick SHA256")
	check(engine.validate_invariants(world) == "" and TargetRules.life(world).status == NpcLifeState.Status.SETTLED, "held NPC omitted from deprivation migration while other world phases continue")
	for i: int in range(prior_decisions, world.decision_audit_trail.size()): check(world.decision_audit_trail[i].npc_id != npc_id, "held NPC has no new decision entry")
	check(store.save_game(world).success and store.load_game().success, "held fixed-site custody actual disk survives world tick")
	# Real sourced named-death API fixtures; anonymous settlement mortality does not select this NPC.
	var target_dead: WorldState = disk_copy(valid, "held target named death source")
	var population: int = target_dead.get_settlement(TargetRules.HOME).population
	check(target_dead.npc_life_state_registry.commit_named_death(target_dead, npc_id).success, "actual held target death lifecycle")
	target_dead.record_event(EventRecord.new(target_dead.current_day, "NAMED_NPC_DIED", npc_id, TargetRules.HOME, {"npc_id": String(npc_id), "settlement_id": String(TargetRules.HOME)}))
	check(engine.validate_invariants(target_dead) == "" and Capture.held_target(target_dead) == &"" and Capture.state(target_dead).captured and target_dead.get_settlement(TargetRules.HOME).population == population - 1 and Capture.describe(target_dead).contains("死亡"), "sourced target death ends effective custody, retains history, conserves one human")
	twin = disk_copy(target_dead, "dead detainee checked disk")
	rejected(target_dead, Capture.intent(target_dead, "CHALLENGE_TARGET"), "dead target never revived")
	var owner_dead: WorldState = disk_copy(valid, "held owner death source")
	twin = disk_copy(owner_dead, "owner source twin")
	capture_return(owner_dead, twin)
	population = owner_dead.get_settlement(TargetRules.HOME).population
	for candidate: WorldState in [owner_dead, twin]:
		check(candidate.npc_life_state_registry.commit_named_death(candidate, candidate.player.npc_id).success, "actual custodian death lifecycle")
		candidate.record_event(EventRecord.new(candidate.current_day, "PLAYER_DIED", candidate.player.npc_id, TargetRules.HOME, {"cause": "starvation", "days_survived": candidate.current_day, "in_transit": false}))
	check(Capture.held_target(owner_dead) == &"" and owner_dead.get_settlement(TargetRules.HOME).population == population - 1 and engine.validate_invariants(owner_dead) == "", "actual owner death ends holding authority without spawning/reviving target")
	owner_dead.get_settlement(TargetRules.HOME).water_pressure = 80.0
	twin.get_settlement(TargetRules.HOME).water_pressure = 80.0
	engine.tick(owner_dead); engine.tick(twin)
	parity(owner_dead, twin, "owner death releases actual ordinary migration SHA256")
	check(TargetRules.life(owner_dead).status == NpcLifeState.Status.IN_TRANSIT and Capture.state(owner_dead).captured and engine.validate_invariants(owner_dead) == "", "surviving resident resumes ordinary MIGRATE after owner death, same identity")
	twin = disk_copy(owner_dead, "released by death actual in-transit disk")
	# Real named mortality between a capture receipt and confirmation must not
	# resurrect a person or strand a pending receipt.
	for dies: String in ["target", "owner"]:
		var pending_dead: WorldState = valid.duplicate_state()
		pending_dead.event_log.pop_back() # Remove only already-recorded confirmation.
		var dying_id: StringName = npc_id if dies == "target" else pending_dead.player.npc_id
		check(pending_dead.npc_life_state_registry.commit_named_death(pending_dead, dying_id).success, "actual pending receipt named death " + dies)
		pending_dead.record_event(EventRecord.new(pending_dead.current_day, "NAMED_NPC_DIED" if dies == "target" else "PLAYER_DIED", dying_id, TargetRules.HOME, {"npc_id": String(dying_id), "settlement_id": String(TargetRules.HOME)} if dies == "target" else {"cause": "starvation", "days_survived": pending_dead.current_day, "in_transit": false}))
		check(engine.validate_invariants(pending_dead) == "" and Capture.held_target(pending_dead) == &"", "sourced pending death leaves historical capture without effective holding " + dies)
		twin = disk_copy(pending_dead, "actual pending named death checked " + dies)
		capture_pair(pending_dead, twin, "CONFIRM_CAPTURE")
		check(Relay.state(pending_dead).active == (dies == "target"), "pending death confirmation closes only dead custodian expedition " + dies)

func capture_fatal() -> WorldState:
	var world: WorldState = capture_prepared()
	world.player.field_kit.hp = 1 # Explicit fatal-risk fixture, before own duel.
	var twin: WorldState = disk_copy(world, "fatal-risk1HP control")
	var population: int = world.get_settlement(TargetRules.HOME).population
	var deaths: int = world.get_settlement(TargetRules.HOME).cumulative_deaths
	capture_pair(world, twin, "CHALLENGE_TARGET")
	capture_pair(world, twin, "RETREAT_TARGET")
	check(Capture.state(world).outcome == "DEAD" and world.player.field_kit.hp == 0 and world.get_settlement(TargetRules.HOME).population == population - 1 and world.get_settlement(TargetRules.HOME).cumulative_deaths == deaths + 1 and TargetRules.life(world).is_alive() and not Capture.state(world).captured, "fatal retreat1 counts actual player once; target alive8 without custody")
	twin = disk_copy(world, "fatal own receipt Continue")
	capture_pair(world, twin, "CONFIRM_CAPTURE")
	check(not Relay.state(world).active and world.get_settlement(TargetRules.HOME).cumulative_deaths == deaths + 1, "fatal receipt confirmation ends expedition without second death")
	rejected(world, Capture.intent(world, "CHALLENGE_TARGET"), "dead player no revival")
	return world

func capture_negative_history(valid: WorldState, fatal: WorldState) -> void:
	for case_id: int in range(28):
		var data: Dictionary = valid.to_dict().duplicate(true)
		var start: Dictionary = last_fact(data, "PURSUIT_STARTED")
		var turn: Dictionary = last_fact(data, "PURSUIT_TURN")
		var result: Dictionary = last_fact(data, "PURSUIT_RESULT")
		match case_id:
			0: start.actor_id = "npc:unknown"
			1: start.target_id = data.player.npc_id
			2: start.payload.site_id = "dungeon:sealed_waterworks"
			3: start.payload.room_id = "relay_tunnel"
			4: start.payload.session_id = false
			5: start.payload.session_id = 2
			6: start.payload.target_hp = 9
			7: start.payload.disarmed = true
			8: start.payload.prepared = true
			9: data.events.erase(last_fact(data, "BOUNTY_TARGET_EXIT_BLOCKED"))
			10: data.events.erase(last_fact(data, "BOUNTY_TARGET_INTERVIEW"))
			11: turn.payload.turn = 1
			12: turn.payload.session_id = 2
			13: turn.payload.command = "KILL_TARGET"
			14: turn.payload.rope_spent = 0
			15: turn.payload.target_hp = 0
			16: turn.payload.disarmed = false
			17: turn.payload.hp = false
			18: turn.payload.dealt = 1
			19: turn.payload.taken = 1
			20: turn.payload.practice = {"skill_id": "MELEE"}
			21: result.payload.outcome = "VICTORY"
			22: result.payload.target_hp = 0
			23: result.payload.turn = false
			24: data.events.append(result.duplicate(true))
			25: last_fact(data, "PURSUIT_CONFIRMED").payload.result_index = 0
			26: data.events.append({"day": data.current_day, "type": "PURSUIT_RELEASED", "actor_id": data.player.npc_id, "target_id": start.target_id, "payload": {}})
			27: data.events.append({"day": data.current_day, "type": "PLAYER_DIED", "actor_id": data.player.npc_id, "target_id": String(TargetRules.HOME), "payload": {"cause": "starvation", "days_survived": data.current_day, "in_transit": false}})
		relay_reject_fixture(data, "capture malformed history%d" % case_id)
	for case_id: int in range(4):
		var data: Dictionary = fatal.to_dict().duplicate(true)
		match case_id:
			0: data.events.erase(last_fact(data, "PLAYER_DIED"))
			1: last_fact(data, "PLAYER_DIED").payload.cause = "field_combat"
			2: last_fact(data, "PURSUIT_RESULT").payload.hp = 1
			3: last_fact(data, "PURSUIT_CONFIRMED").payload.outcome = "CAPTURED"
		relay_reject_fixture(data, "capture fatal malformed%d" % case_id)
	for bad_cause: Variant in [false, 1, {}, []]:
		var data: Dictionary = fatal.to_dict().duplicate(true)
		last_fact(data, "PLAYER_DIED").payload.cause = bad_cause
		relay_reject_fixture(data, "own fatal cause exact-type regression " + str(bad_cause))
	for key: String in ["days_survived", "in_transit"]:
		var data: Dictionary = fatal.to_dict().duplicate(true)
		if key == "in_transit": last_fact(data, "PLAYER_DIED").payload[key] = 1
		else: last_fact(data, "PLAYER_DIED").payload[key] = false
		relay_reject_fixture(data, "own fatal death proof exact " + key)

func capture_geometry(screen: Control) -> void:
	for control: Control in [screen.stage, screen.heading_label, screen.status_label, screen.intent_label, screen.close_button, screen.actions_box]:
		var rect: Rect2 = control.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x + 0.1 and rect.end.y <= root.size.y + 0.1, "actual native capture fits " + control.get_class())
	check(screen.close_button.size.y >= 40 and screen.reduce_motion.size.y >= 40, "actual native capture toolbar40px")
	for b: Button in screen.buttons.values(): check(b.size.y >= 40, "actual native capture action40px")
	check(screen.stage.current_enemy_id == "grey_crow" and not screen.stage.showing_placeholder and not screen.stage.support_turret.visible, "original named atlas loads, no generic enemy or turret support")
	check(screen.stage.enemy_actor.body.texture is AtlasTexture and screen.stage.enemy_actor.body.texture.atlas.get_size() == Vector2(1536, 1024), "actual original1536x1024 atlas used, never fallback portrait")

func capture_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var world: WorldState = capture_prepared()
		check(store.save_game(world).success, "native prepared records real disk")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var relay_screen: Control = main.shell.find_child("RelayScreen", false, false)
		target_guide(relay_screen, "CHALLENGE_TARGET")
		await relay_observe("capture_ready")
		relay_screen.interact_button.pressed.emit()
		await frames()
		var duel: Control = relay_screen.capture_screen
		capture_geometry(duel)
		check(duel.buttons.DISARM_TARGET.disabled and duel.buttons.DISARM_TARGET.text.contains("近戰1") and duel.close_button.disabled and not relay_screen.view.enabled, "real personal-rank lock visible; modal cannot escape pending state")
		var before: String = main.world.to_canonical_json()
		duel.close()
		check(is_instance_valid(duel) and main.world.to_canonical_json() == before, "direct close cannot bypass duel")
		await relay_observe("capture_armed_locked")
		duel.buttons.BRACE_TARGET.pressed.emit()
		await relay_combat_ready(duel)
		await relay_observe("capture_braced")
		var phases: Array[String] = []
		duel.stage.feedback_phase.connect(func(value: String) -> void: phases.append(value))
		duel.buttons.SUBDUE_TARGET.pressed.emit()
		for i: int in range(100):
			if "enemy_windup" in phases: break
			await create_timer(0.02).timeout
		await relay_observe("capture_knife_counter_motion")
		await relay_combat_ready(duel)
		check("enemy_windup" in phases and Capture.state(main.world).target_hp == 4 and main.world.player.field_kit.hp == 9, "actual receipt drives named knife windup, subdual4 and counter3")
		duel.stage.reduced_motion = true
		duel.buttons.SUBDUE_TARGET.pressed.emit()
		await relay_combat_ready(duel)
		check("reduced" in phases and Capture.state(main.world).target_hp == 2, "actual reduced subdual receipt")
		await relay_observe("capture_weakened_reduced")
		duel.buttons.DISARM_TARGET.pressed.emit()
		await relay_combat_ready(duel)
		check(duel.stage.enemy_actor.disarmed and duel.buttons.DISARM_TARGET.disabled and not duel.buttons.BIND_TARGET.disabled and main.world.player.field_kit.hp == 5, "actual disarm updates empty-handed art and binding availability")
		capture_geometry(duel)
		await relay_observe("capture_disarmed")
		check(store.save_game(main.world).success and SaveDialog.describe(main.world).contains("已繳械"), "actual own active Continue summary")
		before = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		relay_screen = main.shell.find_child("RelayScreen", false, false)
		duel = relay_screen.capture_screen
		check(main.world.to_canonical_json() == before and duel.stage.enemy_actor.disarmed and not relay_screen.view.enabled, "actual Continue restores own disarmed duel without mutation")
		await relay_observe("capture_continue_disarmed")
		duel.stage.reduced_motion = true
		duel.buttons.BIND_TARGET.pressed.emit()
		await relay_combat_ready(duel)
		check(duel.stage.enemy_actor.pose == "kneel" and Capture.state(main.world).captured and duel.buttons.has("CONFIRM_CAPTURE") and not main.world.player.item_inventory.contains("rope"), "actual living captive kneels, second rope spent, one explicit result")
		capture_geometry(duel)
		await relay_observe("capture_living_receipt")
		check(store.save_game(main.world).success and SaveDialog.describe(main.world).contains("待確認"), "captured pending Continue summary")
		before = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		relay_screen = main.shell.find_child("RelayScreen", false, false)
		duel = relay_screen.capture_screen
		check(main.world.to_canonical_json() == before and duel.stage.enemy_actor.pose == "kneel", "actual pending capture Continue remains living tied pose")
		await relay_observe("capture_continue_receipt")
		duel.buttons.CONFIRM_CAPTURE.pressed.emit()
		await frames()
		check(not is_instance_valid(relay_screen.capture_screen) and relay_screen.view.enabled and relay_screen.message.text.contains("拘留"), "real confirm returns to room with true custody")
		await relay_observe("capture_held_room")
		for destination: String in ["relay_tunnel", "relay_entrance"]:
			target_guide(relay_screen, "MOVE", destination)
			relay_screen.interact_button.pressed.emit()
			await frames()
		target_guide(relay_screen, "EXIT")
		relay_screen.interact_button.pressed.emit()
		await frames()
		var notice: AcceptDialog = await target_notice(main)
		target_geometry(notice)
		check(notice.detail.text.contains("拘留") and notice.detail.text.contains("尚未交人"), "actual town explains same live captive, no false bounty disposition")
		await relay_observe("capture_town_status")
		main.queue_free()
		await frames()
	clear_slot()

func capture_basic() -> WorldState:
	var world: WorldState = capture_prepared()
	var twin: WorldState = disk_copy(world, "actual blocked records")
	var caps: int = world.player.money
	var xp: int = world.player.xp
	var sequence: int = world.next_npc_sequence
	var population: int = world.get_settlement(TargetRules.HOME).population
	var day: int = world.current_day
	capture_pair(world, twin, "CHALLENGE_TARGET")
	check(Capture.state(world).target_hp == 8 and Capture.state(world).hp == 12 and TargetRules.state(world).interviewed, "reviewed first8HP and actual witnessed interview")
	rejected(world, Capture.intent(world, "DISARM_TARGET"), "personalMELEE0 cannot disarm fresh target")
	capture_pair(world, twin, "BRACE_TARGET")
	check(world.player.field_kit.hp == 12 and Capture.state(world).prepared, "brace reduction3 prevents armed3 and prepares once")
	capture_pair(world, twin, "SUBDUE_TARGET")
	check(Capture.state(world).target_hp == 4 and world.player.field_kit.hp == 9 and not Capture.state(world).prepared, "independent2base+2brace damage4, armedretaliation3")
	capture_pair(world, twin, "SUBDUE_TARGET")
	check(Capture.state(world).target_hp == 2 and world.player.field_kit.hp == 6, "ordinary2 strike weakens to2, second armed3")
	capture_pair(world, twin, "DISARM_TARGET")
	check(Capture.state(world).disarmed and world.player.field_kit.hp == 5 and Capture.state(world).target_hp == 2, "weakened disarm costs one turn, no damage, knife removed before1 retaliation")
	rejected(world, Capture.intent(world, "DISARM_TARGET"), "once-only disarm")
	twin = disk_copy(world, "disarmed actual Continue")
	capture_pair(world, twin, "BIND_TARGET")
	check(Capture.state(world).captured and Capture.state(world).outcome == "CAPTURED" and world.player.field_kit.hp == 5 and not world.player.item_inventory.contains("rope"), "second rope binds alive with no retaliation")
	check(world.player.money == caps and world.player.xp == xp and world.next_npc_sequence == sequence and world.get_settlement(TargetRules.HOME).population == population and TargetRules.life(world).status == NpcLifeState.Status.SETTLED and Capture.held_target(world) == StringName(TargetRules.state(world).npc_id) and world.current_day == day, "custody same resident, no moneyXPpopulationday or entity mint")
	rejected(world, relay_intent(world, "MOVE", "relay_tunnel"), "capture receipt locks departure")
	rejected(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": "bandage"}), "own duel receipt locks direct field treatment")
	twin = disk_copy(world, "captured pending receipt Continue")
	capture_pair(world, twin, "CONFIRM_CAPTURE")
	rejected(world, Capture.intent(world, "CHALLENGE_TARGET"), "no duplicate capture")
	return world

func run_capture() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	var original_poses: int = 0
	for spec: Array in BattleStage.PoseLibrary.FRAMES.grey_crow.values():
		if spec.size() > 4 and spec[4] == "grey-crow-capture": original_poses += 1
	check(original_poses == 6, "reviewed RLY4 original atlas retains exactly six authored poses")
	for pose: String in ["armed", "windup", "strike", "unarmed", "hurt", "kneel"]:
		check(not BattleStage.PoseLibrary.frame("grey_crow", pose).is_empty(), "actual generated Grey Crow pose exists " + pose)
	var world: WorldState = capture_basic()
	capture_variants()
	capture_refusals()
	capture_lifecycle(world)
	var fatal: WorldState = capture_fatal()
	capture_negative_history(world, fatal)
	await capture_ui()
	check(engine.validate_invariants(world) == "", "final custody invariant")
	print("RLY-4: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
