extends "res://tests/test_relay_capture.gd"

const Disposition = preload("res://simulation/relay_disposition.gd")
const Trust = preload("res://simulation/local_trust.gd")

func _init() -> void:
	store = Store.new("user://tests/rly5/journey.json")
	call_deferred("run_disposition")

func disposition_pair(world: WorldState, twin: WorldState, command_id: String) -> void:
	var result: Dictionary = pair_intent(world, twin, Disposition.intent(world, command_id), "disposition " + command_id)
	if not result.success: print("DISPOSITION FAILURE ", result)
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "disposition global invariants")

func sourced_death(world: WorldState, target: bool = true) -> void:
	var npc_id: StringName = StringName(TargetRules.state(world).npc_id) if target else world.player.npc_id
	check(world.npc_life_state_registry.commit_named_death(world, npc_id).success, "actual named death source fixture")
	world.record_event(EventRecord.new(world.current_day, "NAMED_NPC_DIED" if target else "PLAYER_DIED", npc_id, TargetRules.HOME, {"npc_id": String(npc_id), "settlement_id": String(TargetRules.HOME)} if target else {"cause": "starvation", "days_survived": world.current_day, "in_transit": false}))

func disposition_live() -> WorldState:
	var world: WorldState = capture_basic()
	var twin: WorldState = disk_copy(world, "confirmed live capture for disposition")
	rejected(world, Disposition.intent(world, "HAND_OVER_TARGET"), "handover requires actual town")
	capture_return(world, twin)
	var caps: int = world.player.money
	var pop: int = world.get_settlement(TargetRules.HOME).population
	var sequence: int = world.next_npc_sequence
	var day: int = world.current_day
	var postings_before: Array = engine.JobBoard.postings(world, TargetRules.HOME)
	var base_rewards: Dictionary = {}
	for entry: Dictionary in postings_before:
		base_rewards[entry.definition.id] = job_caps(entry.definition)
	var accepted: Dictionary = {}
	if not postings_before.is_empty():
		accepted = postings_before[0].definition
		pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, accepted.id), "accept real job before live standing")
		caps = world.player.money
	disposition_pair(world, twin, "HAND_OVER_TARGET")
	check(world.player.money == caps + 80 and Trust.score(world, String(TargetRules.HOME)) == 4 and Trust.tier(world, String(TargetRules.HOME)) == "REGULAR", "independently authored live80 and local4 crosses real regular threshold")
	check(Trust.faction_score(world, "forge") == 4 and Trust.faction_tier(world, "forge") == "COOPERATE" and Trust.faction_score(world, "oasis") == 0, "same local receipt shares forge4 exactly once, unrelated faction unchanged")
	check(Trust.reward_multiplier(world, String(TargetRules.HOME)) == 1.1 and Trust.faction_reward_multiplier(world, "forge") == 1.05, "existing local10percent and regional5percent reward terms activate")
	if not accepted.is_empty(): check(job_caps(world.accepted_jobs[accepted.id]) == base_rewards[accepted.id], "already accepted real contract keeps promised pay after handover")
	for entry: Dictionary in engine.JobBoard.postings(world, TargetRules.HOME):
		if base_rewards.has(entry.definition.id): check(job_caps(entry.definition) == int(round(float(base_rewards[entry.definition.id]) * 1.1)), "real future Gray job offer uses existing10percent, not compounded15percent")
	check(Trust.reward_multiplier(world, "iron_pass") == 1.05 and Trust.reward_multiplier(world, "new_hope") == 1.0, "forge peer job terms gain5percent, unrelated city unchanged")
	check(world.get_settlement(TargetRules.HOME).population == pop and world.next_npc_sequence == sequence and world.current_day == day and TargetRules.life(world).status == NpcLifeState.Status.SETTLED and Disposition.state(world).handed_over, "handover authority only, no teleport/entity/pop/day")
	for command_id: String in Disposition.COMMANDS: rejected(world, Disposition.intent(world, command_id), "one report closes all dispositions " + command_id)
	twin = disk_copy(world, "handed over actual disk")
	var owner_dead: WorldState = disk_copy(world, "town custody owner mortality")
	twin = disk_copy(owner_dead, "town custody owner twin")
	sourced_death(owner_dead, false); sourced_death(twin, false)
	owner_dead.get_settlement(TargetRules.HOME).water_pressure = 80.0
	twin.get_settlement(TargetRules.HOME).water_pressure = 80.0
	engine.tick(owner_dead); engine.tick(twin)
	parity(owner_dead, twin, "town holds after owner death SHA256")
	check(Capture.held_target(owner_dead) == StringName(TargetRules.state(world).npc_id) and TargetRules.life(owner_dead).status == NpcLifeState.Status.SETTLED and engine.validate_invariants(owner_dead) == "", "town authority survives owner death and ordinary migration phase")
	var unchanged: String = owner_dead.to_canonical_json()
	check(not owner_dead.npc_life_state_registry.begin_named_migration(owner_dead, StringName(TargetRules.state(world).npc_id), TargetRules.DEST, &"refugee:illegal-town-captive", 3, owner_dead.current_day).success and owner_dead.to_canonical_json() == unchanged, "direct named migration cannot bypass town custody after owner death")
	twin = disk_copy(owner_dead, "owner dead town custody checked disk")
	sourced_death(owner_dead); sourced_death(twin)
	parity(owner_dead, twin, "town held target death SHA256")
	check(Capture.held_target(owner_dead) == &"" and Disposition.state(owner_dead).handed_over and engine.validate_invariants(owner_dead) == "", "actual detainee death ends town custody, preserves historical live report")
	twin = disk_copy(owner_dead, "dead town captive historical report disk")
	return world

func job_caps(definition: Dictionary) -> int:
	for reward: Dictionary in definition.outcomes.resolved.rewards:
		if reward.type == "CURRENCY": return int(reward.amount)
	return 0

func disposition_release() -> WorldState:
	var world: WorldState = capture_basic()
	var twin: WorldState = disk_copy(world, "release confirmed source")
	var caps: int = world.player.money
	var pop: int = world.get_settlement(TargetRules.HOME).population
	var day: int = world.current_day
	disposition_pair(world, twin, "RELEASE_TARGET")
	check(Disposition.state(world).released and Capture.held_target(world) == &"" and not TargetRules.present_at_relay(world) and world.player.money == caps and world.current_day == day and world.get_settlement(TargetRules.HOME).population == pop and Trust.score(world, String(TargetRules.HOME)) == 0, "release no refund/cash/day/pop; town does not know until voluntary report")
	rejected(world, Capture.intent(world, "CHALLENGE_TARGET"), "historical captive cannot be recaptured")
	rejected(world, Disposition.intent(world, "HAND_OVER_TARGET"), "released person cannot be handed over")
	rejected(world, Disposition.intent(world, "RELEASE_TARGET"), "once-only release")
	twin = disk_copy(world, "released actual Continue")
	capture_return(world, twin)
	disposition_pair(world, twin, "REPORT_TARGET_RELEASE")
	check(world.player.money == caps and Trust.score(world, String(TargetRules.HOME)) == -3 and Trust.faction_score(world, "forge") == -3 and Disposition.state(world).outcome == "RELEASED", "independent voluntary release0 minus3 sourced local/faction receipt")
	var before: WorldState = disk_copy(world, "released ordinary decision source")
	twin = disk_copy(before, "released ordinary decision twin")
	before.get_settlement(TargetRules.HOME).water_pressure = 80.0; twin.get_settlement(TargetRules.HOME).water_pressure = 80.0
	engine.tick(before); engine.tick(twin)
	parity(before, twin, "released resident ordinary migration SHA256")
	check(TargetRules.life(before).status == NpcLifeState.Status.IN_TRANSIT and engine.validate_invariants(before) == "", "released same resident resumes actual ordinary MIGRATE")
	twin = disk_copy(before, "released moving actual disk")
	var dies: WorldState = capture_basic()
	twin = disk_copy(dies, "release then death source")
	disposition_pair(dies, twin, "RELEASE_TARGET")
	sourced_death(dies); sourced_death(twin)
	check(engine.validate_invariants(dies) == "", "released later sourced death valid life history")
	rejected(dies, Disposition.intent(dies, "WITNESS_CAPTIVE_DEATH"), "released death never captive witness")
	capture_return(dies, twin)
	rejected(dies, Disposition.intent(dies, "REPORT_TARGET_DEATH"), "released later dead cannot claim bounty")
	disposition_pair(dies, twin, "REPORT_TARGET_RELEASE")
	return world

func disposition_lethal() -> WorldState:
	var last: WorldState
	for weapon: String in ["sledgehammer", "old_revolver", "short_shotgun"]:
		var world: WorldState = capture_prepared(1, "MECHANIC", {"main_hand": weapon})
		var shot: bool = weapon != "sledgehammer"
		var ammo: String = "shotgun_shell" if weapon == "short_shotgun" else "revolver_round"
		if shot: check(world.player.pickup_item(ammo, 3).success, "explicit real ammo fixture3 " + ammo)
		var twin: WorldState = disk_copy(world, "actual lethal gear/ammo disk")
		var pop: int = world.get_settlement(TargetRules.HOME).population
		var deaths: int = world.get_settlement(TargetRules.HOME).cumulative_deaths
		var caps: int = world.player.money
		var xp: int = world.player.xp
		capture_pair(world, twin, "CHALLENGE_TARGET")
		if not shot: rejected(world, Capture.intent(world, "SHOOT_TARGET"), "melee weapon cannot shoot")
		var command_id: String = "SHOOT_TARGET" if shot else "LETHAL_TARGET"
		capture_pair(world, twin, command_id)
		if weapon != "short_shotgun":
			check(Capture.state(world).target_hp == 2 and world.player.field_kit.hp == 9, "independent actual hammer/revolver6 and armed3")
			twin = disk_copy(world, "wounded lethal mid-duel Continue")
			capture_pair(world, twin, command_id)
		check(Capture.state(world).outcome == "TARGET_DEAD" and not Capture.state(world).captured and not TargetRules.life(world).is_alive() and world.get_settlement(TargetRules.HOME).population == pop - 1 and world.get_settlement(TargetRules.HOME).cumulative_deaths == deaths + 1, "actual same named target death accounted exactly once " + weapon)
		check(world.player.field_kit.hp == (12 if weapon == "short_shotgun" else 9) and world.player.money == caps and world.player.xp == xp and world.field_state.battle.is_empty() and Relay.state(world).cleared.is_empty(), "lethal terminal no counter/generic clear/loot/XP/bounty " + weapon)
		if shot: check(world.player.item_inventory.quantity(ammo) == (2 if weapon == "short_shotgun" else 1), "real one bullet per shot " + weapon)
		rejected(world, Disposition.intent(world, "REPORT_TARGET_DEATH"), "pending dead result locks reporting")
		twin = disk_copy(world, "actual target-dead pending Continue")
		capture_pair(world, twin, "CONFIRM_CAPTURE")
		check(Relay.state(world).active, "target death confirmation preserves living player expedition")
		capture_return(world, twin)
		disposition_pair(world, twin, "REPORT_TARGET_DEATH")
		check(world.player.money == caps + 30 and Trust.score(world, String(TargetRules.HOME)) == 1 and Trust.tier(world, String(TargetRules.HOME)) == "STRANGER" and Trust.faction_score(world, "forge") == 1 and world.get_settlement(TargetRules.HOME).cumulative_deaths == deaths + 1, "independent dead30 local/faction1, report never kills twice")
		rejected(world, Disposition.intent(world, "REPORT_TARGET_DEATH"), "no duplicate dead bounty")
		last = world
	# Own brace/first-turn quick draw use own turn, never a fake generic battle.
	var quick: WorldState = capture_prepared(1, "CARAVAN_GUARD", {"main_hand": "police_revolver"})
	check(quick.player.pickup_item("revolver_round", 1).success, "real quick first bullet")
	var first_shot_twin: WorldState = disk_copy(quick, "first shot rank2 source")
	capture_pair(quick, first_shot_twin, "CHALLENGE_TARGET")
	capture_pair(quick, first_shot_twin, "SHOOT_TARGET")
	check(Capture.state(quick).killed and quick.player.field_kit.hp == 12 and quick.player.item_inventory.quantity("revolver_round") == 0, "rank2 known firearm9 kills8 before counter, consumes last bullet")
	var empty: WorldState = capture_prepared(1, "MECHANIC", {"main_hand": "old_revolver"})
	first_shot_twin = disk_copy(empty, "empty ammo source")
	capture_pair(empty, first_shot_twin, "CHALLENGE_TARGET")
	rejected(empty, Capture.intent(empty, "SHOOT_TARGET"), "empty gun no turn/damage/practice")
	return last

func disposition_witness() -> WorldState:
	var world: WorldState = capture_basic()
	var twin: WorldState = disk_copy(world, "held actual external mortality source")
	sourced_death(world); sourced_death(twin)
	check(engine.validate_invariants(world) == "" and Disposition.state(world).death_held and Capture.held_target(world) == &"", "death eligibility uses historical player custody at death, not current hold")
	var death_count: int = world.get_settlement(TargetRules.HOME).cumulative_deaths
	disposition_pair(world, twin, "WITNESS_CAPTIVE_DEATH")
	check(world.get_settlement(TargetRules.HOME).cumulative_deaths == death_count, "personal inspection does not account death again")
	twin = disk_copy(world, "personal captive death inspected disk")
	capture_return(world, twin)
	var caps: int = world.player.money
	disposition_pair(world, twin, "REPORT_TARGET_DEATH")
	check(world.player.money == caps + 30 and world.get_settlement(TargetRules.HOME).cumulative_deaths == death_count, "witnessed real captive death30 no second mortality")
	return world

func disposition_negative(live: WorldState, dead: WorldState, released: WorldState, witnessed: WorldState) -> void:
	for valid: WorldState in [live, dead, released, witnessed]:
		for case_id: int in range(16):
			var data: Dictionary = valid.to_dict().duplicate(true)
			var report: Dictionary = last_fact(data, "CUSTODY_REPORTED")
			match case_id:
				0: report.actor_id = "npc:unknown"
				1: report.target_id = data.player.npc_id
				2: report.payload.site_id = "dungeon:sealed_waterworks"
				3: report.payload.city_id = "settlement:new_hope"
				4: report.payload.evidence_index = false
				5: report.payload.evidence_index = 0
				6: report.payload.caps_gained = false
				7: report.payload.caps_gained = 99
				8: report.payload.standing_delta = false
				9: report.payload.standing_delta = 99
				10: report.payload.outcome = {}
				11: report.payload.outcome = "UNKNOWN"
				12: report.payload.extra = true
				13: data.events.append(report.duplicate(true))
				14: data.events.erase(last_fact(data, "PURSUIT_CONFIRMED"))
				15: report.type = "CUSTODY_INVENTED"
			relay_reject_fixture(data, "typed disposition malformed%d %s" % [case_id, Disposition.state(valid).outcome])
	for case_id: int in range(12):
		var data: Dictionary = dead.to_dict().duplicate(true)
		var turn: Dictionary = last_fact(data, "PURSUIT_TURN")
		var death: Dictionary = last_fact(data, "NAMED_NPC_DIED")
		match case_id:
			0: death.payload.cause = false
			1: death.payload.cause = "field_combat"
			2: death.actor_id = data.player.npc_id
			3: death.target_id = "settlement:new_hope"
			4: death.payload.npc_id = false
			5: data.events.erase(death)
			6: turn.payload.ammo_spent = 0
			7: turn.payload.ammo_item_id = "food"
			8: turn.payload.weapon_id = "sledgehammer"
			9: turn.payload.ammo_remaining = false
			10: turn.payload.firearms_rank = {}
			11: turn.payload.practice = {"skill_id": "MELEE", "from_rank": 0, "to_rank": 0, "rank_up": false, "points": 1, "required": 3}
		relay_reject_fixture(data, "own lethal source/ammo malformed%d" % case_id)
	for key: String in ["capture_index", "death_index"]:
		var data: Dictionary = witnessed.to_dict().duplicate(true)
		last_fact(data, "CUSTODY_DEATH_WITNESSED").payload[key] = false
		relay_reject_fixture(data, "captive inspection typed source " + key)
	var release_data: Dictionary = released.to_dict().duplicate(true)
	last_fact(release_data, "CUSTODY_RELEASED").payload.capture_index = 0
	relay_reject_fixture(release_data, "release cannot substitute acceptance proof")
	for outcome: String in ["LIVE", "DEAD", "RELEASED"]:
		for valid: WorldState in [live, dead, released]:
			if Disposition.state(valid).outcome == outcome: continue
			var crossed_data: Dictionary = valid.to_dict().duplicate(true)
			var report: Dictionary = last_fact(crossed_data, "CUSTODY_REPORTED")
			report.payload.outcome = outcome
			# Correct reward numbers alone never substitute for outcome/source authority.
			report.payload.caps_gained = 80 if outcome == "LIVE" else (30 if outcome == "DEAD" else 0)
			report.payload.standing_delta = 4 if outcome == "LIVE" else (1 if outcome == "DEAD" else -3)
			relay_reject_fixture(crossed_data, "crossed disposition with correct authored reward " + outcome)
	for bad: Variant in [false, [], {}, "0"]:
		var malformed_data: Dictionary = dead.to_dict().duplicate(true)
		last_fact(malformed_data, "PURSUIT_TURN").payload.command = bad
		relay_reject_fixture(malformed_data, "shot command typed non-string " + str(bad))
		malformed_data = witnessed.to_dict().duplicate(true)
		last_fact(malformed_data, "CUSTODY_DEATH_WITNESSED").payload.death_index = bad
		relay_reject_fixture(malformed_data, "inspection malformed reference " + str(bad))

func disposition_return_ui(screen: Control) -> void:
	for destination: String in ["relay_tunnel", "relay_entrance"]:
		target_guide(screen, "MOVE", destination)
		screen.interact_button.pressed.emit()
		await frames()
	target_guide(screen, "EXIT")
	screen.interact_button.pressed.emit()
	await frames()

func disposition_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var world: WorldState = capture_basic()
		check(store.save_game(world).success, "native confirmed captive save")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("RelayScreen", false, false)
		target_guide(screen, "INSPECT_CAPTIVE")
		screen.interact_button.pressed.emit()
		await frames()
		var dialog: AcceptDialog = screen.disposition_dialog
		target_geometry(dialog)
		check(not screen.view.enabled and not dialog.action_buttons.RELEASE_TARGET.disabled and dialog.action_buttons.HAND_OVER_TARGET.disabled and dialog.action_buttons.HAND_OVER_TARGET.text.contains("需回灰谷"), "native actual custody actions/location lock")
		await relay_observe("disposition_live_room")
		var before: String = main.world.to_canonical_json()
		dialog.action_buttons.RELEASE_TARGET.pressed.emit()
		await frames()
		check(dialog.release_confirmation.visible and dialog.release_confirmation.get_ok_button().size.y >= 40 and dialog.release_confirmation.get_cancel_button().size.y >= 40 and main.world.to_canonical_json() == before, "native release confirmation no authority before explicit consent")
		await relay_observe("disposition_release_confirmation")
		dialog.release_confirmation.canceled.emit()
		await frames()
		check(main.world.to_canonical_json() == before and not is_instance_valid(dialog.release_confirmation), "native cancel/escape release leaves exact world intact")
		dialog.action_buttons.RELEASE_TARGET.pressed.emit()
		await frames()
		dialog.release_confirmation.confirmed.emit()
		await frames()
		check(Disposition.state(main.world).released and not TargetRules.present_at_relay(main.world) and dialog.action_buttons.RELEASE_TARGET.disabled, "native actual confirmation commits once, original same person now free")
		await relay_observe("disposition_released")
		dialog.confirmed.emit()
		await frames()
		await disposition_return_ui(screen)
		dialog = await target_notice(main)
		target_geometry(dialog)
		dialog.action_buttons.REPORT_TARGET_RELEASE.pressed.emit()
		await frames()
		check(Trust.score(main.world, String(TargetRules.HOME)) == -3 and dialog.action_buttons.HAND_OVER_TARGET.disabled and dialog.detail.text.contains("已坦白放人"), "native release report commits source−3 and locks conflicting bounty")
		await relay_observe("disposition_release_town_report")
		main.queue_free(); await frames()
		world = capture_basic()
		var twin: WorldState = disk_copy(world, "native living handover town source")
		capture_return(world, twin)
		check(store.save_game(world).success, "native living handover town saved")
		main = new_main(); await frames()
		main.save_dialog.load_button.pressed.emit(); await frames()
		dialog = await target_notice(main)
		var caps: int = main.world.player.money
		dialog.action_buttons.HAND_OVER_TARGET.pressed.emit(); await frames()
		target_geometry(dialog)
		check(main.world.player.money == caps + 80 and dialog.detail.text.contains("灰谷") and Disposition.state(main.world).handed_over and dialog.action_buttons.RELEASE_TARGET.disabled, "native handover actual80 town authority and visible settled closure")
		await relay_observe("disposition_handed_over")
		main.queue_free(); await frames()
		world = capture_prepared(1, "MECHANIC", {"main_hand": "old_revolver"})
		check(world.player.pickup_item("revolver_round", 3).success, "native explicit three real bullets")
		twin = disk_copy(world, "native firearm source")
		capture_pair(world, twin, "CHALLENGE_TARGET")
		check(store.save_game(world).success, "native firearm pending actual disk")
		main = new_main(); await frames()
		main.save_dialog.load_button.pressed.emit(); await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		var duel: Control = screen.capture_screen
		capture_geometry(duel)
		check(not duel.buttons.SHOOT_TARGET.disabled and duel.buttons.SHOOT_TARGET.text.contains("致命") and duel.buttons.SHOOT_TARGET.text.contains("剩3"), "native lethal gun actual ammo/cost visible")
		await relay_observe("disposition_firearm_ready")
		var phases: Array[String] = []
		duel.stage.feedback_phase.connect(func(value: String) -> void: phases.append(value))
		duel.buttons.SHOOT_TARGET.pressed.emit()
		await relay_combat_ready(duel)
		check(Capture.state(main.world).target_hp == 2 and main.world.player.field_kit.hp == 9 and main.world.player.item_inventory.quantity("revolver_round") == 2, "native first actual lethal shot6 counter3 ammunition1")
		await relay_observe("disposition_first_shot")
		duel.stage.reduced_motion = true
		duel.buttons.SHOOT_TARGET.pressed.emit()
		await relay_combat_ready(duel)
		capture_geometry(duel)
		check(duel.stage.enemy_actor.pose == "fall" and Capture.state(main.world).outcome == "TARGET_DEAD" and main.world.player.field_kit.hp == 9 and "reduced" in phases, "native original fallen pose from real lethal result, no terminal counter, reduced feedback")
		await relay_observe("disposition_target_dead")
		check(store.save_game(main.world).success, "native actual dead pending Continue save")
		before = main.world.to_canonical_json()
		main.queue_free(); await frames()
		main = new_main(); await frames()
		main.save_dialog.load_button.pressed.emit(); await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		duel = screen.capture_screen
		check(main.world.to_canonical_json() == before and duel.stage.enemy_actor.pose == "fall" and duel.buttons.has("CONFIRM_CAPTURE"), "native Continue restores real dead receipt and fall, no resurrection")
		await relay_observe("disposition_dead_continue")
		duel.buttons.CONFIRM_CAPTURE.pressed.emit(); await frames()
		await disposition_return_ui(screen)
		dialog = await target_notice(main)
		caps = main.world.player.money
		dialog.action_buttons.REPORT_TARGET_DEATH.pressed.emit(); await frames()
		target_geometry(dialog)
		check(main.world.player.money == caps + 30 and Disposition.state(main.world).outcome == "DEAD" and dialog.action_buttons.REPORT_TARGET_DEATH.disabled, "native dead report actual30 and once-only lock")
		await relay_observe("disposition_dead_report")
		main.queue_free(); await frames()
	clear_slot()

func disposition_day_zero_player() -> void:
	var world: WorldState = capture_prepared(1)
	check(world.current_day == 0 and world.total_initial_population == -1, "actual one-rope preparation before first world day")
	world.player.field_kit.hp = 1
	var twin: WorldState = disk_copy(world, "day0 fatal player risk")
	var population: int = 0
	for settlement: SettlementState in world.settlements.values(): population += settlement.population
	capture_pair(world, twin, "CHALLENGE_TARGET")
	rejected(world, Capture.intent(world, "SHOOT_TARGET"), "day0 refusal cannot initialize baseline")
	check(world.total_initial_population == -1, "refused intent preserves absent baseline")
	capture_pair(world, twin, "RETREAT_TARGET")
	check(world.total_initial_population == population and not world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive(), "day0 actual player death fixes baseline before single subtraction")
	twin = disk_copy(world, "day0 player death receipt checked disk")
	capture_pair(world, twin, "CONFIRM_CAPTURE")
	engine.tick(world); engine.tick(twin)
	parity(world, twin, "day0 player death then first actual tick SHA256")
	check(engine.validate_invariants(world) == "" and world.total_initial_population == population, "first daily tick preserves already established conservation baseline")
	twin = disk_copy(world, "day0 player death then tick actual disk")

func run_disposition() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	var live: WorldState = disposition_live()
	var released: WorldState = disposition_release()
	var dead: WorldState = disposition_lethal()
	var witnessed: WorldState = disposition_witness()
	disposition_day_zero_player()
	disposition_negative(live, dead, released, witnessed)
	await disposition_ui()
	print("RLY-5: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
