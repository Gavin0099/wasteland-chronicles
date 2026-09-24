extends SceneTree

# ==============================================================================
# S5-C3b : SPEECH Training Path (Roadside Negotiation)
# ==============================================================================
# Verifies that low-rank / rank-0 players can negotiate at roadblocks and bandit
# ambushes, that persuasion influences the cost deterministically, and that
# successful persuasion awards canonical SPEECH practice without free-XP exploits.
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

func create_test_world(background: String = "CARAVAN_GUARD", speech_rank: int = 0, caps: int = 200, day: int = 1) -> WorldState:
	var world := S1WorldData.create_s1_world()
	var res := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": String(ORIGIN), "character_name": "Speaker", "age": 25,
		"background_id": background, "trait_ids": [],
	}))
	check(res.success, "creation fixture succeeds")
	world.current_day = day
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = caps
	if speech_rank > 0:
		var profile_dict: Dictionary = world.player.capability.to_dict()
		profile_dict.ranks["SPEECH"] = speech_rank
		world.player.capability = Profile.from_dict_checked(profile_dict).profile
	return world

func stage_encounter(world: WorldState, kind: StringName, travel_day: int = 1, min_sec: float = 50.0) -> void:
	var life := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life.status == NpcLifeState.Status.SETTLED:
		var travel := engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, DEST))
		check(travel.success, "travel begins")
	world.pending_encounter_result = -1
	world.active_encounter = TravelEncounterState.create(
		kind, world.current_day, ORIGIN, DEST, travel_day,
		{"min_security": min_sec, "headcount": 10, "origin_name": "Gray Valley", "destination_name": "New Hope"})

func resolve(world: WorldState, option_id: StringName) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option_id))

func _init() -> void:
	print("================================================================================")
	print("      WASTELAND CHRONICLES - S5-C3b SPEECH TRAINING SUITE                       ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 1] Low Rank / Novice Accessibility ---")
	var w1 := create_test_world("CARAVAN_GUARD", 0, 100)
	check(w1.player.capability.get_rank("SPEECH") == 0, "novice starts with SPEECH 0")
	stage_encounter(w1, Enc.ROADBLOCK)
	check(engine.authorize_encounter_option(w1, &"PERSUADE") == "", "rank 0 is authorized to PERSUADE at ROADBLOCK")

	var options := Enc.options(Enc.ROADBLOCK)
	var found_persuade := false
	for opt in options:
		if opt.id == &"PERSUADE":
			found_persuade = true
			check(opt.get("requires", {}).is_empty(), "PERSUADE has no rank prerequisite")
			check(String(opt.get("label", "")).find("跟他們談談") >= 0, "label matches plain Chinese")
	check(found_persuade, "ROADBLOCK catalogue offers PERSUADE")

	stage_encounter(w1, Enc.BANDIT_AMBUSH)
	check(engine.authorize_encounter_option(w1, &"PARLEY") == "", "rank 0 is authorized to PARLEY at BANDIT_AMBUSH")
	var ambush_options := Enc.options(Enc.BANDIT_AMBUSH)
	var found_parley := false
	for opt in ambush_options:
		if opt.id == &"PARLEY":
			found_parley = true
			check(opt.get("requires", {}).is_empty(), "PARLEY has no rank prerequisite")
			check(String(opt.get("label", "")).find("出言周旋") >= 0, "label matches plain Chinese")
	check(found_parley, "BANDIT_AMBUSH catalogue offers PARLEY")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 2] Insufficient Funds Refusal is Atomic ---")
	var broke_road := create_test_world("CARAVAN_GUARD", 0, 9) # needs 10
	stage_encounter(broke_road, Enc.ROADBLOCK)
	var before_road := sha(broke_road)
	var auth_road := engine.authorize_encounter_option(broke_road, &"PERSUADE")
	check(auth_road.begins_with("INSUFFICIENT_FUNDS"), "refuses PERSUADE when player has < 10 caps: " + auth_road)
	var res_road := resolve(broke_road, &"PERSUADE")
	check(not res_road.get("success", false) and sha(broke_road) == before_road, "refused PERSUADE leaves world byte-identical")

	var broke_bandit := create_test_world("CARAVAN_GUARD", 0, 14) # needs 15
	stage_encounter(broke_bandit, Enc.BANDIT_AMBUSH)
	var before_bandit := sha(broke_bandit)
	var auth_bandit := engine.authorize_encounter_option(broke_bandit, &"PARLEY")
	check(auth_bandit.begins_with("INSUFFICIENT_FUNDS"), "refuses PARLEY when player has < 15 caps: " + auth_bandit)
	var res_bandit := resolve(broke_bandit, &"PARLEY")
	check(not res_bandit.get("success", false) and sha(broke_bandit) == before_bandit, "refused PARLEY leaves world byte-identical")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 3] Deterministic Success vs Failure Outcomes ---")
	# Find a deterministic seed (day/index) that yields SUCCESS and one that yields FAILURE for rank 0 at ROADBLOCK
	var day_success := -1
	var day_failure := -1
	for d in range(1, 30):
		var ok := Enc.check_persuasion_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 0, {"min_security": 50.0})
		if ok and day_success < 0:
			day_success = d
		elif not ok and day_failure < 0:
			day_failure = d
		if day_success >= 0 and day_failure >= 0:
			break
	check(day_success >= 0 and day_failure >= 0, "found both success and failure test seeds for rank 0")

	# Test SUCCESS at Roadblock
	var ws := create_test_world("CARAVAN_GUARD", 0, 50, day_success)
	stage_encounter(ws, Enc.ROADBLOCK, 1, 50.0)
	var caps_before_s := ws.player.money
	var res_s := resolve(ws, &"PERSUADE")
	check(res_s.success, "persuade commits successfully")
	check(res_s.get("persuasion_success", false) == true, "persuasion marked successful in receipt")
	check(int(res_s.get("spent", {}).get("caps", 0)) == Enc.ROADBLOCK_PERSUADED_CAPS, "discounted toll of 5 caps was spent")
	check(caps_before_s - ws.player.money == Enc.ROADBLOCK_PERSUADED_CAPS, "player deducted exactly 5 caps")
	check(res_s.has("skill_practice"), "successful persuasion awards skill practice")
	check(res_s.get("skill_practice", {}).get("skill_id", "") == "SPEECH", "practice award is for SPEECH")
	check(res_s.get("skill_practice", {}).get("points", 0) == 1, "awarded 1 practice point")
	check(ws.player.capability.get_practice_progress("SPEECH").points == 1, "capability profile records 1 practice point")

	# Test FAILURE at Roadblock
	var wf := create_test_world("CARAVAN_GUARD", 0, 50, day_failure)
	stage_encounter(wf, Enc.ROADBLOCK, 1, 50.0)
	var caps_before_f := wf.player.money
	var res_f := resolve(wf, &"PERSUADE")
	check(res_f.success, "failed persuade still resolves encounter via full toll")
	check(res_f.get("persuasion_success", false) == false, "persuasion marked failure in receipt")
	check(int(res_f.get("spent", {}).get("caps", 0)) == 10, "full toll of 10 caps was spent")
	check(caps_before_f - wf.player.money == 10, "player deducted full 10 caps")
	check(not res_f.has("skill_practice"), "failed persuasion DOES NOT award skill practice (no free XP on fail)")
	check(wf.player.capability.get_practice_progress("SPEECH").points == 0, "capability profile has 0 practice points")

	# Test Bandit Ambush (15 caps demand -> 8 on success, 15 on failure)
	var b_success := -1
	var b_failure := -1
	for d in range(1, 30):
		var ok := Enc.check_persuasion_success(Enc.BANDIT_AMBUSH, ORIGIN, DEST, d, 1, 0, {"min_security": 50.0})
		if ok and b_success < 0:
			b_success = d
		elif not ok and b_failure < 0:
			b_failure = d
		if b_success >= 0 and b_failure >= 0:
			break
	check(b_success >= 0 and b_failure >= 0, "found bandit ambush success and failure seeds")

	var w_bs := create_test_world("CARAVAN_GUARD", 0, 50, b_success)
	stage_encounter(w_bs, Enc.BANDIT_AMBUSH, 1, 50.0)
	var res_bs := resolve(w_bs, &"PARLEY")
	check(res_bs.success and res_bs.get("persuasion_success", false) == true, "bandit parley succeeds")
	check(int(res_bs.get("spent", {}).get("caps", 0)) == Enc.BANDIT_PERSUADED_CAPS, "spent exactly 8 caps (user spec: 15 -> 8)")
	check(res_bs.get("skill_practice", {}).get("skill_id", "") == "SPEECH", "bandit parley awards SPEECH practice")

	var w_bf := create_test_world("CARAVAN_GUARD", 0, 50, b_failure)
	stage_encounter(w_bf, Enc.BANDIT_AMBUSH, 1, 50.0)
	var res_bf := resolve(w_bf, &"PARLEY")
	check(res_bf.success and res_bf.get("persuasion_success", false) == false, "bandit parley fails")
	check(int(res_bf.get("spent", {}).get("caps", 0)) == Enc.BANDIT_BRIBE_CAPS, "spent full 15 caps on failure (user spec: fail -> 15)")
	check(not res_bf.has("skill_practice"), "bandit parley failure gives no practice")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 4] Daily Cap & Level-Up Progression ---")
	# Two successful persuasions on the same day: second must NOT award practice
	var w_same_day := create_test_world("CARAVAN_GUARD", 0, 100, day_success)
	stage_encounter(w_same_day, Enc.ROADBLOCK, 1, 50.0)
	var r1 := resolve(w_same_day, &"PERSUADE")
	check(r1.has("skill_practice"), "first persuade awards practice")
	w_same_day.pending_encounter_result = -1
	stage_encounter(w_same_day, Enc.ROADBLOCK, 2, 50.0)
	var r2 := resolve(w_same_day, &"PERSUADE")
	check(not r2.has("skill_practice"), "second persuade on same world day awards no practice")

	# Advance to next day and practice again -> Rank 0 -> 1 level up!
	w_same_day.current_day += 1
	var next_day_success := -1
	for d in range(w_same_day.current_day, w_same_day.current_day + 30):
		if Enc.check_persuasion_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 0, {"min_security": 50.0}):
			next_day_success = d
			break
	check(next_day_success >= 0, "found next day success seed")
	w_same_day.current_day = next_day_success
	w_same_day.pending_encounter_result = -1
	stage_encounter(w_same_day, Enc.ROADBLOCK, 1, 50.0)
	var r3 := resolve(w_same_day, &"PERSUADE")
	check(r3.has("skill_practice") and r3.skill_practice.get("rank_up", false) == true, "second practice day triggers rank up from 0 to 1")
	check(w_same_day.player.capability.get_rank("SPEECH") == 1, "SPEECH rank is now 1 in capability profile")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 5] Skill Rank Influences Success Rate ---")
	# With rank 4 SPEECH, all 30 days should succeed
	var all_succeed := true
	for d in range(1, 31):
		if not Enc.check_persuasion_success(Enc.ROADBLOCK, ORIGIN, DEST, d, 1, 4, {"min_security": 50.0}):
			all_succeed = false
			break
	check(all_succeed, "SPEECH rank 4 guarantees negotiation success")

	# --------------------------------------------------------------------------
	print("\n--- [GATE 6] Save/Load Persistence & Two-Track Determinism ---")
	var w_replay_a := create_test_world("CARAVAN_GUARD", 0, 100, day_success)
	stage_encounter(w_replay_a, Enc.ROADBLOCK, 1, 50.0)
	resolve(w_replay_a, &"PERSUADE")
	var hash_a := sha(w_replay_a)

	var loaded := WorldState.from_dict_checked(w_replay_a.to_dict())
	check(loaded.success, "persuasion state loads from dict")
	check(sha(loaded.world) == hash_a, "save/load roundtrip preserves byte-identical hash")

	var json_loaded := WorldState.from_json_checked(w_replay_a.to_canonical_json())
	check(json_loaded.success, "persuasion state loads from canonical json")
	check(sha(json_loaded.world) == hash_a, "json roundtrip preserves byte-identical hash")

	var w_replay_b := create_test_world("CARAVAN_GUARD", 0, 100, day_success)
	stage_encounter(w_replay_b, Enc.ROADBLOCK, 1, 50.0)
	resolve(w_replay_b, &"PERSUADE")
	var hash_b := sha(w_replay_b)
	check(hash_a == hash_b, "two-track determinism holds for SPEECH training")

	check(engine.validate_invariants(w_replay_a) == "", "global invariants hold after SPEECH training")

	if failures > 0:
		print("\nS5-C3b SPEECH TRAINING SUITE FAILED WITH %d ERRORS!" % failures)
		quit(1)
	else:
		print("\n================================================================================")
		print("S5-C3b SPEECH TRAINING SUITE PASSED ALL GATES! (Replay SHA: %s)" % hash_a)
		print("================================================================================")
		quit(0)
