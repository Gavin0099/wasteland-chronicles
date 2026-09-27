extends SceneTree

# ==============================================================================
# PLAY-3B: BOUNTY JOB VERB SUITE (PLAY-3B Target Hunt & Combat Progression)
# ==============================================================================
# Verifies the 7 Hard Gates for the Bounty Job Verb loop:
#   Gate 1: Roster & Contract Completeness (3 tiers, heavy raider on wilderness, 100% security)
#   Gate 2: Target-Aware Encounter Semantics & Guarantee + Coexistence
#   Gate 3: Exact Attribution & Non-Combat Rejection (no bribe/parley/flee victory, attribution pipeline)
#   Gate 4: Tactical Intel Knowledge Boundary (qualitative vs DEATH_TESTED forecast)
#   Gate 5: Turn-in, Payout & Board Cleanup (receipt, board cleanup, history increment)
#   Gate 6: Combat Build Payoff Gate (MELEE 0 unarmed vs MELEE 0 machete vs MELEE 1 machete)
#   Gate 7: Save/Load Determinism & Simulation Invariants
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const FieldAdventure = preload("res://simulation/field_adventure.gd")
const Route = preload("res://simulation/travel_route.gd")
const Definition = preload("res://simulation/quest_definition.gd")
const PlayerUiProjection = preload("res://ui/player_ui_projection.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-3B FAIL: " + label)
	else:
		print("  PASS: " + label)

func _init() -> void:
	call_deferred("run")

func create_test_world(origin_id: String = "settlement:gray_valley", background: String = "SCAVENGER") -> WorldState:
	var world := S1WorldData.create_s1_world()
	var creation_res := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin_id,
		"character_name": "Bounty Hunter",
		"age": 30,
		"background_id": background,
		"trait_ids": [],
	}))
	if not creation_res.success:
		push_error("Failed character creation: " + String(creation_res.get("error", "")))
	return world

func run() -> void:
	print("\n================================================================================")
	print("      WASTELAND CHRONICLES - PLAY-3B BOUNTY JOB VERB SUITE")
	print("================================================================================")

	test_gate_1_roster_and_contract()
	test_gate_2_encounter_semantics_and_coexistence()
	test_gate_3_exact_attribution_and_non_combat()
	test_gate_4_tactical_intel_boundary()
	test_gate_5_turn_in_and_cleanup()
	test_gate_6_combat_build_payoff()
	test_gate_7_determinism_and_invariants()

	print("================================================================================")
	if failures == 0:
		print("PLAY-3B SUITE PASSED ALL 7 GATES! assertions=%d, failures=0\n" % assertions)
		quit(0)
	else:
		print("PLAY-3B SUITE FAILED! assertions=%d, failures=%d\n" % [assertions, failures])
		quit(1)

# ── Gate 1: Roster & Contract Completeness ────────────────────────────────────
func test_gate_1_roster_and_contract() -> void:
	print("\n--- [GATE 1] Roster & Contract Completeness ---")
	var world := create_test_world("settlement:gray_valley")

	# Check window 0 across settlements
	var gv_postings := Board.postings(world, &"settlement:gray_valley")
	var dw_postings := Board.postings(world, &"settlement:dry_well")
	var nh_postings := Board.postings(world, &"settlement:new_hope")

	var gv_bounty: Dictionary = {}
	for p in gv_postings:
		if p.get("archetype") == "BOUNTY": gv_bounty = p
	var dw_bounty: Dictionary = {}
	for p in dw_postings:
		if p.get("archetype") == "BOUNTY": dw_bounty = p
	var nh_bounty: Dictionary = {}
	for p in nh_postings:
		if p.get("archetype") == "BOUNTY": nh_bounty = p

	check(not gv_bounty.is_empty(), "G1: Gray Valley posts bounty in window 0")
	check(not dw_bounty.is_empty(), "G1: Dry Well posts bounty in window 0")
	check(not nh_bounty.is_empty(), "G1: New Hope posts bounty in window 0")

	check(gv_bounty.get("target_enemy") == Enemies.FERAL_DOG, "G1: Gray Valley window 0 targets feral_dog")
	check(dw_bounty.get("target_enemy") == Enemies.BANDIT, "G1: Dry Well window 0 targets bandit")
	check(nh_bounty.get("target_enemy") == Enemies.HEAVY_RAIDER, "G1: New Hope window 0 targets heavy_raider")

	# Check Heavy Raider constraints
	check(nh_bounty.get("target_route_type") == "WILDERNESS", "G1: Heavy Raider bounty is strictly on WILDERNESS")
	check(nh_bounty.get("target_route_destination") == "dry_well", "G1: Heavy Raider route connects New Hope to Dry Well")
	check(nh_bounty.definition.get("target_route_type") == "WILDERNESS", "G1: Definition mirrors target_route_type")

	# Check contract validation
	check(Definition.validate_definition(gv_bounty.definition) == "", "G1: Gray Valley bounty definition passes validation")
	check(Definition.validate_definition(dw_bounty.definition) == "", "G1: Dry Well bounty definition passes validation")
	check(Definition.validate_definition(nh_bounty.definition) == "", "G1: New Hope bounty definition passes validation")

	# Check 100% security world still generates Heavy Raider tier (never suppressed)
	world.get_settlement(&"settlement:new_hope").security = 100.0
	world.get_settlement(&"settlement:dry_well").security = 100.0
	var nh_postings_sec100 := Board.postings(world, &"settlement:new_hope")
	var nh_bounty_sec100: Dictionary = {}
	for p in nh_postings_sec100:
		if p.get("archetype") == "BOUNTY": nh_bounty_sec100 = p
	check(nh_bounty_sec100.get("target_enemy") == Enemies.HEAVY_RAIDER, "G1: Heavy Raider exists in 100% security world (never suppressed)")

# ── Gate 2: Target-Aware Encounter Semantics & Guarantee + Coexistence ─────────
func test_gate_2_encounter_semantics_and_coexistence() -> void:
	print("\n--- [GATE 2] Target-Aware Encounter Semantics & Coexistence ---")
	var world := create_test_world("settlement:gray_valley")

	# Accept Gray Valley Bounty (feral dog on Highway to Dry Well)
	var gv_postings := Board.postings(world, &"settlement:gray_valley")
	var bounty_entry: Dictionary = {}
	for p in gv_postings:
		if p.get("archetype") == "BOUNTY": bounty_entry = p
	var accept_res: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, bounty_entry.definition.id))
	check(accept_res.success, "G2: Accepted feral_dog bounty job")

	# Start travel to Dry Well (untyped standard highway departure)
	var dest_id: StringName = StringName("settlement:" + String(bounty_entry.target_route_destination))
	world.player.inventory.set_amount("water", 10)
	world.player.inventory.set_amount("food", 10)
	var travel_intent := PlayerIntent.create_travel(world.player.npc_id, dest_id)
	var travel_res: Dictionary = engine.commit_player_intent(world, travel_intent)
	check(travel_res.success, "G2: Started travel on target Highway route")

	# Guaranteed ambush trigger
	check(world.active_encounter != null, "G2: Guaranteed ambush encounter triggered")
	var enc := world.active_encounter
	check(enc != null and enc.encounter_type == TravelEncounter.BANDIT_AMBUSH, "G2: Encounter type is BANDIT_AMBUSH")
	check(enc.context.get("target_enemy") == "feral_dog", "G2: Encounter context binds target_enemy feral_dog")
	check(enc.context.get("bounty_job_id") == bounty_entry.definition.id, "G2: Encounter context binds bounty_job_id")

	# Semantic text check: feral dog is singular "野犬", title is target-aware
	var title_str := TravelEncounter.title(enc.encounter_type, enc.context)
	check(title_str == "懸賞目標：野犬", "G2: Title reflects target feral dog: %s" % title_str)
	var body_str := TravelEncounter.body(enc.encounter_type, enc.context)
	check(body_str.contains("野犬") and not body_str.contains("野犬群"), "G2: Body names singular dog, not pack")

	# Semantic options check: feral dog cannot parley/bribe
	var options := TravelEncounter.options(enc.encounter_type, enc.context)
	var option_ids: Array = []
	for opt in options: option_ids.append(opt.id)
	check(option_ids.has(&"FIGHT") and option_ids.has(&"FLEE_ROAD"), "G2: Options contain FIGHT and FLEE_ROAD")
	check(not option_ids.has(&"BRIBE") and not option_ids.has(&"PARLEY"), "G2: Options do NOT contain BRIBE or PARLEY for feral_dog")

	# Check Heavy Raider options as well
	var raider_options := TravelEncounter.options(TravelEncounter.BANDIT_AMBUSH, {"target_enemy": "heavy_raider"})
	var raider_opt_ids: Array = []
	for opt in raider_options: raider_opt_ids.append(opt.id)
	check(not raider_opt_ids.has(&"BRIBE") and not raider_opt_ids.has(&"PARLEY"), "G2: Options do NOT contain BRIBE or PARLEY for heavy_raider")

	# Coexistence test: active Salvage and active Bounty on the same route
	var world_co := create_test_world("settlement:gray_valley")
	var postings_co := Board.postings(world_co, &"settlement:gray_valley")
	var salvage_job_id := ""
	var bounty_job_id := ""
	for p in postings_co:
		if p.get("archetype") == "SALVAGE": salvage_job_id = p.definition.id
		elif p.get("archetype") == "BOUNTY": bounty_job_id = p.definition.id
	engine.commit_player_intent(world_co, PlayerIntent.create_accept_quest(world_co.player.npc_id, salvage_job_id))
	engine.commit_player_intent(world_co, PlayerIntent.create_accept_quest(world_co.player.npc_id, bounty_job_id))

	var dest_co: StringName = StringName("settlement:dry_well")
	world_co.player.inventory.set_amount("water", 10)
	world_co.player.inventory.set_amount("food", 10)
	var travel_co := PlayerIntent.create_travel(world_co.player.npc_id, dest_co)
	var travel_co_res: Dictionary = engine.commit_player_intent(world_co, travel_co)
	check(travel_co_res.success, "G2: Coexistence travel started")
	check(world_co.active_encounter != null, "G2: Coexistence travel triggered encounter")
	check(world_co.active_encounter.encounter_type == TravelEncounter.WRECK, "G2: Salvage has deterministic priority -> WRECK fires first")

	# Bounty job remains active and not consumed
	var b_quest = world_co.quest_state.get_quest(bounty_job_id)
	check(b_quest != null and b_quest.status == &"ACTIVE", "G2: Bounty job remains active and unconsumed during salvage priority")

# ── Gate 3: Exact Attribution & Non-Combat Rejection ──────────────────────────
func test_gate_3_exact_attribution_and_non_combat() -> void:
	print("\n--- [GATE 3] Exact Attribution & Non-Combat Rejection ---")
	var world := create_test_world("settlement:gray_valley")
	var postings := Board.postings(world, &"settlement:gray_valley")
	var bounty_entry: Dictionary = {}
	for p in postings:
		if p.get("archetype") == "BOUNTY": bounty_entry = p
	var quest_id: String = bounty_entry.definition.id
	engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, quest_id))

	# Meet encounter
	var dest_id: StringName = StringName("settlement:" + String(bounty_entry.target_route_destination))
	world.player.inventory.set_amount("water", 10)
	world.player.inventory.set_amount("food", 10)
	var travel_intent := PlayerIntent.create_travel(world.player.npc_id, dest_id)
	engine.commit_player_intent(world, travel_intent)
	check(world.active_encounter != null, "G3: Ambush active")

	# Test 1: FLEE_ROAD does NOT satisfy bounty
	var flee_res: Dictionary = engine.commit_encounter_choice(world, &"FLEE_ROAD")
	check(flee_res.success, "G3: Committed FLEE_ROAD")
	check(not QuestEngine.evaluate_objectives(world, quest_id), "G3: FLEE_ROAD does not satisfy bounty objective")

	# Test 2: In-combat FLEE does NOT satisfy bounty
	var world_combat := create_test_world("settlement:gray_valley")
	engine.commit_player_intent(world_combat, PlayerIntent.create_accept_quest(world_combat.player.npc_id, quest_id))
	world_combat.player.inventory.set_amount("water", 10)
	world_combat.player.inventory.set_amount("food", 10)
	engine.commit_player_intent(world_combat, PlayerIntent.create_travel(world_combat.player.npc_id, dest_id))
	check(world_combat.active_encounter != null, "G3: Combat test encounter active")
	var fight_res: Dictionary = engine.commit_encounter_choice(world_combat, &"FIGHT")
	check(fight_res.success, "G3: Committed FIGHT")
	check(not world_combat.field_state.battle.is_empty(), "G3: Battle started")
	check(world_combat.field_state.battle.get("bounty_job_id") == quest_id, "G3: Battle holds bounty_job_id")

	# Player flees combat
	var flee_combat_res: Dictionary = engine.commit_player_intent(world_combat, PlayerIntent.create_field_action(world_combat.player.npc_id, {
		"command": "FLEE", "battle_id": world_combat.field_state.battle.id, "turn": world_combat.field_state.battle.turn
	}))
	check(flee_combat_res.success, "G3: Fled from combat")
	check(not QuestEngine.evaluate_objectives(world_combat, quest_id), "G3: Escaped combat does not satisfy bounty objective")

	# Test 3: Victory against wrong enemy does NOT satisfy bounty
	WorldState.Field.begin_road_battle(world, {
		"encounter_type": "BANDIT_AMBUSH",
		"origin": "settlement:gray_valley", "destination": "settlement:dry_well",
		"travel_day_index": 0, "target_enemy": "bandit", "bounty_job_id": "other_job"
	})
	world.field_state.enemy_hp = 0
	WorldState.Field.finish(world, "VICTORY", {}, {}, "road", 0, {})
	check(not QuestEngine.evaluate_objectives(world, quest_id), "G3: Victory against wrong enemy/job does NOT satisfy bounty objective")

	# Test 4: Exact Victory against designated target satisfies bounty!
	WorldState.Field.begin_road_battle(world, {
		"encounter_type": "BANDIT_AMBUSH",
		"origin": "settlement:gray_valley", "destination": "settlement:dry_well",
		"travel_day_index": 0, "target_enemy": "feral_dog", "bounty_job_id": quest_id
	})
	world.record_event(EventRecord.new(
		world.current_day, "ROAD_COMBAT_BEGAN", world.player.npc_id, &"settlement:dry_well",
		{"origin": "settlement:gray_valley", "destination": "settlement:dry_well", "target_enemy": "feral_dog", "bounty_job_id": quest_id}
	))
	world.field_state.enemy_hp = 0
	WorldState.Field.finish(world, "VICTORY", {}, {}, "road", 0, {})
	var last_event: EventRecord = world.event_log.back()
	check(last_event.type == "FIELD_RESULT", "G3: Recorded FIELD_RESULT event")
	check(last_event.payload.get("outcome") == "VICTORY", "G3: FIELD_RESULT outcome is VICTORY")
	check(last_event.payload.get("enemy") == "feral_dog", "G3: FIELD_RESULT payload has enemy feral_dog")
	check(last_event.payload.get("bounty_job_id") == quest_id, "G3: FIELD_RESULT payload has bounty_job_id")
	check(QuestEngine.evaluate_objectives(world, quest_id), "G3: Objective SATISFIED after exact victory!")

# ── Gate 4: Tactical Intel Knowledge Boundary ─────────────────────────────────
func test_gate_4_tactical_intel_boundary() -> void:
	print("\n--- [GATE 4] Tactical Intel Knowledge Boundary ---")
	var world := create_test_world("settlement:new_hope")
	var postings := Board.postings(world, &"settlement:new_hope")
	var bounty_entry: Dictionary = {}
	for p in postings:
		if p.get("archetype") == "BOUNTY": bounty_entry = p
	check(not bounty_entry.is_empty(), "G4: Found New Hope Heavy Raider bounty")

	# Case A: Ordinary survivor (no DEATH_TESTED)
	var intel_ordinary := Board.intel_for(world, bounty_entry)
	check(not intel_ordinary.is_empty(), "G4: Ordinary survivor receives intel")
	var has_forecast_numbers := false
	var has_qualitative_intel := false
	for line in intel_ordinary:
		var s := String(line)
		if s.contains("推估需") or s.contains("每擊") or s.contains("承受約"):
			has_forecast_numbers = true
		if s.contains("重裝掠奪者") and s.contains("威脅度"):
			has_qualitative_intel = true
	check(not has_forecast_numbers, "G4: Ordinary survivor sees NO exact mathematical forecast")
	check(has_qualitative_intel, "G4: Ordinary survivor sees qualitative risk and enemy threat")

	# Case B: Survivor with DEATH_TESTED trait
	world.player.acquired_trait_ids.append("DEATH_TESTED")
	var intel_veteran := Board.intel_for(world, bounty_entry)
	var has_exact_forecast := false
	for line in intel_veteran:
		var s := String(line)
		if s.contains("〔見過底的人〕") and s.contains("推估需") and s.contains("每擊") and s.contains("HP"):
			has_exact_forecast = true
	check(has_exact_forecast, "G4: DEATH_TESTED survivor receives exact mathematical combat forecast")

# ── Gate 5: Turn-in, Payout & Board Cleanup ────────────────────────────────────
func test_gate_5_turn_in_and_cleanup() -> void:
	print("\n--- [GATE 5] Turn-in, Payout & Board Cleanup ---")
	var world := create_test_world("settlement:gray_valley")
	var postings := Board.postings(world, &"settlement:gray_valley")
	var bounty_entry: Dictionary = {}
	for p in postings:
		if p.get("archetype") == "BOUNTY": bounty_entry = p
	var quest_id: String = bounty_entry.definition.id

	# Accept and fulfill objective
	engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, quest_id))
	world.record_event(EventRecord.new(
		world.current_day, "ROAD_COMBAT_BEGAN", world.player.npc_id, &"settlement:dry_well",
		{"origin": "settlement:gray_valley", "destination": "settlement:dry_well", "target_enemy": "feral_dog", "bounty_job_id": quest_id}
	))
	WorldState.Field.begin_road_battle(world, {
		"encounter_type": "BANDIT_AMBUSH",
		"origin": "settlement:gray_valley", "destination": "settlement:dry_well",
		"travel_day_index": 0, "target_enemy": "feral_dog", "bounty_job_id": quest_id
	})
	world.field_state.enemy_hp = 0
	WorldState.Field.finish(world, "VICTORY", {}, {}, "road", 0, {})
	var confirm_res := engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {
		"command": "CONFIRM", "receipt": world.field_state.receipt
	}))
	check(confirm_res.success, "G5: Confirmed combat result receipt")

	# Record starting currency and XP
	var start_money: int = world.player.money
	var start_xp: int = world.player.xp

	# Turn in quest
	var turn_in_res: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, quest_id))
	check(turn_in_res.success, "G5: Turn-in succeeded")

	# Payout received
	check(world.player.money > start_money, "G5: Caps awarded on bounty resolution")
	check(world.player.xp > start_xp, "G5: XP awarded on bounty resolution")

	# Job removed from active board list in projection
	var live_quests: Array = PlayerUiProjection.project(world).get("quests", [])
	var still_on_board := false
	for q in live_quests:
		if q.get("id") == quest_id: still_on_board = true
	check(not still_on_board, "G5: Completed bounty removed from live quest projection")

	# Completed history incremented
	var history: Dictionary = PlayerUiProjection._project_quest_history(world)
	check(history.get("completed", 0) >= 1, "G5: Quest history records completion")

# ── Gate 6: Combat Build Payoff Gate ──────────────────────────────────────────
func test_gate_6_combat_build_payoff() -> void:
	print("\n--- [GATE 6] Combat Build Payoff Gate ---")

	# Heavy Raider stats: HP 16, turns: T1 3 dmg, T2 3 dmg, T3 9 dmg (heavy strike!)
	# Max player HP: 12.

	# Scenario A: MELEE 0, unarmed (2 dmg/hit) -> dies to raider
	var world_a := create_test_world("settlement:gray_valley")
	world_a.player.field_kit.hp = 12
	world_a.player.capability._data.skill_ranks["MELEE"] = 0
	var dmg_a := FieldAdventure.attack_damage(world_a)
	check(dmg_a == 2, "G6: MELEE 0 unarmed deals 2 damage/hit")
	var fc_a := FieldAdventure.forecast_for_enemy(world_a, Enemies.HEAVY_RAIDER, true)
	check(fc_a.beaten == true, "G6: MELEE 0 unarmed forecast confirms player will be defeated")

	# Scenario B: MELEE 0 + scrap machete (5 dmg/hit) -> deals 15 dmg by T3, dies to T3 heavy blow
	var world_b := create_test_world("settlement:gray_valley")
	world_b.player.field_kit.hp = 12
	world_b.player.capability._data.skill_ranks["MELEE"] = 0
	world_b.player.item_inventory.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(world_b, PlayerIntent.create_equip_item(world_b.player.npc_id, &"scrap_machete", "main_hand"))
	var dmg_b := FieldAdventure.attack_damage(world_b)
	check(dmg_b == 5, "G6: MELEE 0 with scrap machete deals 5 damage/hit")
	var fc_b := FieldAdventure.forecast_for_enemy(world_b, Enemies.HEAVY_RAIDER, true)
	check(fc_b.turns == 4, "G6: 5 dmg/hit takes 4 turns to defeat 16 HP raider")
	check(fc_b.beaten == true, "G6: MELEE 0 with machete without defend is beaten on turn 3 before 4th hit")

	# Scenario C: MELEE 1 + scrap machete (6 dmg/hit) -> kills Raider on Turn 3 BEFORE heavy blow!
	var world_c := create_test_world("settlement:gray_valley")
	world_c.player.field_kit.hp = 12
	world_c.player.capability._data.skill_ranks["MELEE"] = 1
	world_c.player.item_inventory.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(world_c, PlayerIntent.create_equip_item(world_c.player.npc_id, &"scrap_machete", "main_hand"))
	var dmg_c := FieldAdventure.attack_damage(world_c)
	check(dmg_c == 6, "G6: MELEE 1 with scrap machete deals 6 damage/hit")
	var fc_c := FieldAdventure.forecast_for_enemy(world_c, Enemies.HEAVY_RAIDER, true)
	check(fc_c.turns == 3, "G6: 6 dmg/hit defeats 16 HP raider in exactly 3 turns")
	check(fc_c.beaten == false, "G6: MELEE 1 with machete WINS against Heavy Raider before heavy strike lands!")
	check(fc_c.hp_after == 6, "G6: Player survives with 6 HP remaining")

	# Verify through real simulated turns (player in transit on wilderness)
	world_c.npc_life_state_registry.begin_named_migration(
		world_c, world_c.player.npc_id, &"settlement:dry_well", &"refugee:test_p1", 4, world_c.current_day, &"WILDERNESS"
	)
	WorldState.Field.begin_road_battle(world_c, {"target_enemy": "heavy_raider", "route_type": "WILDERNESS"})
	# Turn 1
	var t1_res := engine.commit_player_intent(world_c, PlayerIntent.create_field_action(world_c.player.npc_id, {
		"command": "ATTACK", "battle_id": world_c.field_state.battle.id, "turn": 1
	}))
	check(t1_res.success, "G6: T1 Attack committed successfully")
	check(world_c.field_state.enemy_hp == 10, "G6: T1 Raider HP 16 -> 10")
	# Turn 2
	engine.commit_player_intent(world_c, PlayerIntent.create_field_action(world_c.player.npc_id, {
		"command": "ATTACK", "battle_id": world_c.field_state.battle.id, "turn": 2
	}))
	check(world_c.field_state.enemy_hp == 4, "G6: T2 Raider HP 10 -> 4")
	# Turn 3: Player strikes for 6 damage, killing raider before raider attacks!
	engine.commit_player_intent(world_c, PlayerIntent.create_field_action(world_c.player.npc_id, {
		"command": "ATTACK", "battle_id": world_c.field_state.battle.id, "turn": 3
	}))
	var result_evt: EventRecord = null
	for i in range(world_c.event_log.size() - 1, -1, -1):
		if world_c.event_log[i].type == "FIELD_RESULT":
			result_evt = world_c.event_log[i]
			break
	check(result_evt != null and result_evt.type == "FIELD_RESULT", "G6: T3 Battle ended with FIELD_RESULT")
	check(result_evt != null and result_evt.payload.get("outcome") == "VICTORY", "G6: T3 Result is VICTORY")
	check(world_c.player.field_kit.hp == 6, "G6: Player took no damage on turn 3, surviving with 6 HP!")

# ── Gate 7: Determinism & Invariants ──────────────────────────────────────────
func test_gate_7_determinism_and_invariants() -> void:
	print("\n--- [GATE 7] Save/Load Determinism & Invariants ---")
	var world := create_test_world("settlement:new_hope")

	# Verify simulation invariants
	var inv_err := engine.validate_invariants(world)
	check(inv_err == "", "G7: World invariants hold: %s" % inv_err)

	# Verify canonical JSON serialization
	var json_str := world.to_canonical_json()
	check(json_str.length() > 0, "G7: World serializes to canonical JSON")

	# Re-create world from duplicate
	var dup := world.duplicate_state()
	var dup_json := dup.to_canonical_json()
	check(json_str == dup_json, "G7: Duplicate state matches original JSON exactly")
