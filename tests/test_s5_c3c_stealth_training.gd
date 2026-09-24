extends SceneTree

# ==============================================================================
# S5-C3c : STEALTH Novice Training Path (Roadside Sneaking)
# ==============================================================================
# Verifies:
# Gate 1: Rank 0 accessibility across all 4 backgrounds with 0 caps.
# Gate 2: Deterministic success vs failure via stable hash (zero RNG).
# Gate 3: Canonical +1 day progression and mortality ordering (death stops practice & bypass).
# Gate 4: Practice integrity (success +1, failure +0, daily cap, 0->1 level up).
# Gate 5: No illegal ownership / safe world state (0 caps deducted, save/load valid, invariants hold).
# Gate 6: Scavenger Rank 1 (~70%) and Rank 2+ (100% provisional) non-regression and two-track replay.
# Gate 7: Failed attempt cannot bypass roadblock, and no reroll exploit (exposed roadblock locks SLIP_PAST).
# ==============================================================================

const Intent = preload("res://simulation/character_creation_intent.gd")
const Enc = preload("res://simulation/travel_encounter.gd")
const Profile = preload("res://simulation/capability_profile.gd")
const ORIGIN := &"settlement:gray_valley"
const DEST := &"settlement:new_hope"

var engine := SimulationEngine.new()
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
		print("  FAIL: " + message)

func sha(world: WorldState) -> String:
	return world.to_canonical_json().sha256_text()

func create_test_world(background: String = "CARAVAN_GUARD", stealth_rank: int = 0, caps: int = 200, day: int = 1) -> WorldState:
	var world := S1WorldData.create_s1_world()
	var res := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": String(ORIGIN), "character_name": "Sneaker", "age": 25,
		"background_id": background, "trait_ids": [],
	}))
	check(res.success, "creation fixture succeeds")
	world.current_day = day
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = caps
	if stealth_rank > 0:
		var profile_dict: Dictionary = world.player.capability.to_dict()
		profile_dict.skill_ranks["STEALTH"] = stealth_rank
		world.player.capability = Profile.from_dict_checked(profile_dict).profile
	return world

func stage_encounter(world: WorldState, kind: StringName, travel_day: int = 1, min_sec: float = 50.0, context_override: Dictionary = {}) -> void:
	var life := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life.status == NpcLifeState.Status.SETTLED:
		var travel := engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, DEST))
		check(travel.success, "travel begins")
	world.pending_encounter_result = -1
	var ctx: Dictionary = {"min_security": min_sec, "headcount": 10, "origin_name": "Gray Valley", "destination_name": "New Hope"}
	for k in context_override:
		ctx[k] = context_override[k]
	world.active_encounter = TravelEncounterState.create(
		kind, world.current_day, ORIGIN, DEST, travel_day, ctx)

func resolve(world: WorldState, option_id: StringName) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option_id))

func _init() -> void:
	print("================================================================================")
	print("      WASTELAND CHRONICLES - S5-C3c STEALTH TRAINING SUITE                      ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 1] Novice Accessibility Across All 4 Backgrounds ---")
	for bg in ["CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER"]:
		var w_bg := create_test_world(bg, -1, 0) # 0 caps!
		stage_encounter(w_bg, Enc.ROADBLOCK)
		var auth := engine.authorize_encounter_option(w_bg, &"SLIP_PAST")
		check(auth == "", "%s must be authorized to SLIP_PAST with 0 caps, got: %s" % [bg, auth])

	var options := Enc.options(Enc.ROADBLOCK)
	var found_slip := false
	for opt in options:
		if opt.id == &"SLIP_PAST":
			found_slip = true
			check(opt.get("requires", {}).is_empty(), "SLIP_PAST has no rank prerequisite")
			check(String(opt.get("label", "")).find("等天黑再摸過去") >= 0, "label matches plain Chinese")
	check(found_slip, "ROADBLOCK catalogue offers SLIP_PAST")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 2] Deterministic Success vs Failure (Zero RNG) ---")
	var success_day := -1
	var failure_day := -1
	for d in range(1, 100):
		var ok := Enc.check_stealth_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 0)
		if ok and success_day < 0:
			success_day = d
		elif not ok and failure_day < 0:
			failure_day = d
		if success_day >= 0 and failure_day >= 0:
			break
	check(success_day >= 0, "found deterministic success day for rank 0")
	check(failure_day >= 0, "found deterministic failure day for rank 0")
	print("  Rank 0 seed test: success on day %d, failure on day %d" % [success_day, failure_day])
	# Verify repeated calls are 100% identical
	check(Enc.check_stealth_success(Enc.ROADBLOCK, ORIGIN, DEST, success_day, 1, 0), "repeated success call is true")
	check(not Enc.check_stealth_success(Enc.ROADBLOCK, ORIGIN, DEST, failure_day, 1, 0), "repeated failure call is false")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 3] Canonical Day Progression and Mortality Ordering ---")
	# Successful sneak: +1 day, water -1, food -1, toll = 0
	var ws := create_test_world("CARAVAN_GUARD", 0, 50, success_day)
	var w_before_s := ws.player.inventory.get_amount("water")
	var f_before_s := ws.player.inventory.get_amount("food")
	var day_before_s := ws.current_day
	stage_encounter(ws, Enc.ROADBLOCK, 1)
	var res_s := resolve(ws, &"SLIP_PAST")
	check(res_s.get("success", false), "SLIP_PAST commit succeeds on success day")
	check(bool(res_s.get("stealth_success", false)), "receipt confirms stealth_success")
	check(ws.current_day == day_before_s + 1, "world day advanced by 1")
	check(ws.player.inventory.get_amount("water") == w_before_s - 1, "1 water consumed on success")
	check(ws.player.inventory.get_amount("food") == f_before_s - 1, "1 food consumed on success")
	check(ws.player.money == 50, "0 caps spent on successful sneak")
	check(ws.active_encounter == null, "roadblock bypassed on success")

	# Mortality ordering: player dying of thirst on +1 day tick cannot succeed or gain practice
	var w_dying := create_test_world("CARAVAN_GUARD", 0, 50, success_day)
	w_dying.player.inventory.set_amount("water", 0)
	w_dying.player.inventory.set_amount("food", 0)
	w_dying.player.water_exposure = 7.0 # lethal exposure past 6.0 grace period
	stage_encounter(w_dying, Enc.ROADBLOCK, 1)
	var res_dying := resolve(w_dying, &"SLIP_PAST")
	check(res_dying.get("success", false), "SLIP_PAST commits and resolves tick")
	var dead_ls := w_dying.npc_life_state_registry.get_life_state(w_dying.player.npc_id)
	check(not dead_ls.is_alive(), "player perished from thirst during +1 day progression")
	check(not res_dying.has("skill_practice"), "perished player receives zero skill practice")
	check(not bool(res_dying.get("stealth_success", true)), "perished player cannot claim stealth success")
	check(not res_dying.has("resume_encounter"), "dead player does not resume roadblock")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 4] Practice Integrity: Success Awards, Failure Gives 0, Daily Cap ---")
	# Failure gives 0 practice
	var wf := create_test_world("CARAVAN_GUARD", 0, 50, failure_day)
	stage_encounter(wf, Enc.ROADBLOCK, 1)
	var res_f := resolve(wf, &"SLIP_PAST")
	check(res_f.get("success", false), "SLIP_PAST commit succeeds on failure day")
	check(not bool(res_f.get("stealth_success", true)), "receipt confirms stealth failed")
	check(not res_f.has("skill_practice"), "no practice awarded on failed stealth")
	check(wf.player.capability.get_rank("STEALTH") == 0, "rank remains 0 after failure")

	# Success awards +1 practice and respects daily cap
	var wp := create_test_world("CARAVAN_GUARD", 0, 50, success_day)
	stage_encounter(wp, Enc.ROADBLOCK, 1)
	var res_p1 := resolve(wp, &"SLIP_PAST")
	check(res_p1.has("skill_practice"), "success awards practice")
	check(int(res_p1.skill_practice.points) == 1, "practice points now 1")
	# Confirmation
	engine.commit_player_intent(wp, PlayerIntent.create_continue_journey(wp.player.npc_id, wp.pending_encounter_result))

	# Advance to another day that also succeeds for rank 0, confirming level up 0 -> 1 (threshold 2)
	var next_success_day := -1
	for d in range(wp.current_day + 1, wp.current_day + 50):
		if Enc.check_stealth_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 0):
			next_success_day = d
			break
	check(next_success_day > 0, "found next success day")
	wp.current_day = next_success_day
	stage_encounter(wp, Enc.ROADBLOCK, 1)
	var res_p2 := resolve(wp, &"SLIP_PAST")
	check(res_p2.has("skill_practice"), "second day success awards practice")
	check(bool(res_p2.skill_practice.rank_up), "level up 0 -> 1 triggered")
	check(int(res_p2.skill_practice.to_rank) == 1, "now STEALTH rank 1")
	check(wp.player.capability.get_rank("STEALTH") == 1, "profile rank is 1")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 5] Safe World State on Failure (Zero Caps Lost, Invariants Hold) ---")
	var w_fail := create_test_world("CARAVAN_GUARD", 0, 0, failure_day) # 0 caps!
	stage_encounter(w_fail, Enc.ROADBLOCK, 1)
	var res_fail := resolve(w_fail, &"SLIP_PAST")
	check(res_fail.get("success", false), "SLIP_PAST resolved")
	check(not bool(res_fail.stealth_success), "stealth failed")
	check(w_fail.player.money == 0, "player still has 0 caps; no illegal negative balance")
	check(res_fail.has("resume_encounter"), "receipt contains resume_encounter payload")
	check(w_fail.pending_encounter_result >= 0, "pending encounter result active")

	# Save/Load round trip while receipt is pending
	var json_receipt := w_fail.to_canonical_json()
	var restored_receipt_world: WorldState = WorldState.from_json_checked(json_receipt).world
	check(restored_receipt_world != null, "saved world with pending receipt loads cleanly")
	check(restored_receipt_world.to_canonical_json().sha256_text() == json_receipt.sha256_text(), "receipt JSON roundtrip is identical")

	# Confirm the failure receipt: player faces roadblock again!
	var continue_res := engine.commit_player_intent(w_fail, PlayerIntent.create_continue_journey(w_fail.player.npc_id, w_fail.pending_encounter_result))
	check(continue_res.get("success", false), "continue_journey succeeds")
	check(bool(continue_res.get("resumed_encounter", false)), "action confirms encounter was resumed")
	check(w_fail.pending_encounter_result == -1, "pending result cleared")
	check(w_fail.active_encounter != null, "active_encounter is restored to roadblock")
	check(w_fail.active_encounter.encounter_type == Enc.ROADBLOCK, "it is still the roadblock")
	check(engine.validate_invariants(w_fail) == "", "all world invariants hold after resume")

	# Save/Load round trip while resumed encounter is active
	var json_resumed := w_fail.to_canonical_json()
	var restored_resumed_world: WorldState = WorldState.from_json_checked(json_resumed).world
	check(restored_resumed_world != null, "saved world with resumed encounter loads cleanly")
	check(restored_resumed_world.to_canonical_json().sha256_text() == json_resumed.sha256_text(), "resumed encounter JSON roundtrip is identical")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 6] Scavenger Rank 1 & Rank 2+ Non-Regression ---")
	var scav_successes := 0
	var total_trials := 100
	for d in range(1, total_trials + 1):
		if Enc.check_stealth_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 1):
			scav_successes += 1
	var scav_pct := float(scav_successes) / float(total_trials) * 100.0
	print("  Scavenger Rank 1 empirical success rate: %.1f%% (expected ~70%%)" % scav_pct)
	check(scav_pct >= 60.0 and scav_pct <= 80.0, "Rank 1 success rate is near 70%")

	# Rank 2+ is 100% (BALANCE_PROVISIONAL)
	var rank2_successes := 0
	for d in range(1, 50):
		if Enc.check_stealth_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 2):
			rank2_successes += 1
	check(rank2_successes == 49, "Rank 2+ is 100% success across all days")

	# Two-track determinism replay check
	var w_replay_a := create_test_world("SCAVENGER", 1, 100, 10)
	stage_encounter(w_replay_a, Enc.ROADBLOCK, 1)
	resolve(w_replay_a, &"SLIP_PAST")
	var sha_a := sha(w_replay_a)

	var w_replay_b := create_test_world("SCAVENGER", 1, 100, 10)
	stage_encounter(w_replay_b, Enc.ROADBLOCK, 1)
	resolve(w_replay_b, &"SLIP_PAST")
	var sha_b := sha(w_replay_b)

	check(sha_a == sha_b, "dual-track replay matches byte-for-byte")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 7] No Free Bypass & No Reroll Exploit on Failed Sneak ---")
	# 1. Verify player cannot bypass roadblock on failed sneak:
	# w_fail is currently back at active_encounter == ROADBLOCK
	check(w_fail.active_encounter != null, "player is still blocked by active encounter")
	var party := w_fail.get_refugee_party(w_fail.npc_life_state_registry.get_life_state(w_fail.player.npc_id).population_container_id)
	check(party.days_remaining > 0, "journey did not complete; party is still en route")

	# 2. Verify SLIP_PAST is removed from options on this exposed roadblock:
	var resumed_options := Enc.options(w_fail.active_encounter.encounter_type, w_fail.active_encounter.context)
	var has_slip_past := false
	for o in resumed_options:
		if o.id == &"SLIP_PAST":
			has_slip_past = true
	check(not has_slip_past, "SLIP_PAST is NOT available after sneaking was exposed")

	# 3. Verify attempting to commit SLIP_PAST anyway is rejected at authorization boundary:
	var re_sneak_auth := engine.authorize_encounter_option(w_fail, &"SLIP_PAST")
	check(re_sneak_auth.begins_with("INVALID_OPTION"), "re-attempting SLIP_PAST is rejected with INVALID_OPTION: " + re_sneak_auth)
	var re_sneak_res := resolve(w_fail, &"SLIP_PAST")
	check(not re_sneak_res.get("success", false), "re-attempting SLIP_PAST fails commit")

	# 4. Verify player can still choose other legal options like DETOUR:
	var detour_res := resolve(w_fail, &"DETOUR")
	check(detour_res.get("success", false), "player can choose DETOUR from resumed roadblock")
	check(w_fail.active_encounter == null, "DETOUR clears the roadblock")

	# --------------------------------------------------------------------------
	print("================================================================================")
	if failures == 0:
		print("S5-C3c STEALTH TRAINING SUITE PASSED ALL 7 GATES! (Replay SHA: %s)" % sha_a)
		print("================================================================================")
		quit(0)
	else:
		push_error("FAILED with %d errors" % failures)
		print("FAILED with %d errors" % failures)
		print("================================================================================")
		quit(1)
