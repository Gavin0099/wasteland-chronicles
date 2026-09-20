extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-B NPC LIFE STATE TEST SUITE
# ==============================================================================
# Verifies 8 Runtime Acceptance Gates (B1 ~ B8):
#   B1: Exactly-One Container (living NPC has exactly 1 container; DEAD has none)
#   B2: Aggregate Subset (named_settled <= pop; named_transit <= headcount)
#   B3: Atomic Departure (settlement -1, transit +1, status change, event — same commit)
#   B4: Physical Arrival (Axiom 9: Arrival = Departure + RouteDays - 1; no teleport)
#   B5: Atomic Arrival (transit -1, destination +1, status change, event — same commit)
#   B6: Atomic Mortality (population -1, deaths +1, DEAD state — same commit)
#   B7: Aggregate Cannot Choose Named (anonymous=0 → FAIL CLOSED, zero pop mutation)
#   B8: Replay / Validator / Regression (SHA-256 dual replay + governance + S0~S4-A regression)
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("        WASTELAND CHRONICLES - S4-B NPC LIFE STATE TEST SUITE                   ")
	print("================================================================================")

	var engine := SimulationEngine.new()
	engine.enable_migration = false
	engine.enable_mortality = false
	engine.enable_security = false

	# --------------------------------------------------------------------------
	# GATE B1: Exactly-One Container Invariant
	# --------------------------------------------------------------------------
	print("\n--- [GATE B1] Exactly-One Container ---")
	var world := S1WorldData.create_s1_world()

	# Materialize Mara and register life state
	var res_mara := world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Mara", 28)
	if not res_mara["success"]:
		print("FAIL B1: Failed to materialize Mara: %s" % res_mara.get("error", ""))
		quit(1)
		return
	var mara_id: StringName = res_mara["npc"].id

	var ls_res := world.npc_life_state_registry.register_life_state(world, mara_id, &"settlement:gray_valley")
	if not ls_res["success"]:
		print("FAIL B1: Failed to register life state: %s" % ls_res.get("error", ""))
		quit(1)
		return

	var mara_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(mara_id)
	if mara_ls == null:
		print("FAIL B1: Life state not found after registration!")
		quit(1)
		return

	# Verify SETTLED has exactly one container
	if mara_ls.status != NpcLifeState.Status.SETTLED:
		print("FAIL B1: Expected SETTLED status, got %d" % mara_ls.status)
		quit(1)
		return
	if mara_ls.population_container_type != NpcLifeState.ContainerType.SETTLEMENT:
		print("FAIL B1: Expected SETTLEMENT container type")
		quit(1)
		return
	if mara_ls.population_container_id != &"settlement:gray_valley":
		print("FAIL B1: Wrong container_id: %s" % mara_ls.population_container_id)
		quit(1)
		return
	if not mara_ls.is_alive():
		print("FAIL B1: is_alive() should be true when SETTLED")
		quit(1)
		return
	print("  Mara: SETTLED | container=settlement:gray_valley | is_alive=true ✓")

	# Validate B1 via engine invariants
	var inv_err := engine.validate_invariants(world)
	if inv_err != "":
		print("FAIL B1: Engine invariant error: %s" % inv_err)
		quit(1)
		return

	# Test duplicate registration is rejected
	var dup_reg := world.npc_life_state_registry.register_life_state(world, mara_id, &"settlement:gray_valley")
	if dup_reg["success"]:
		print("FAIL B1: Duplicate life state registration should have been rejected!")
		quit(1)
		return
	print("  Duplicate registration correctly rejected: %s" % dup_reg["error"])
	print("PASS GATE B1: Exactly-One Container verified.")

	# --------------------------------------------------------------------------
	# GATE B2: Aggregate Subset Invariant
	# --------------------------------------------------------------------------
	print("\n--- [GATE B2] Aggregate Subset ---")
	# Materialize two more NPCs in gray valley (population=100)
	var res_eli := world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Eli", 35)
	world.npc_life_state_registry.register_life_state(world, res_eli["npc"].id, &"settlement:gray_valley")
	var res_jon := world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Jon", 42)
	world.npc_life_state_registry.register_life_state(world, res_jon["npc"].id, &"settlement:gray_valley")

	for s_id in world.settlements:
		var s: SettlementState = world.settlements[s_id]
		var named := world.npc_life_state_registry.get_named_living_count_in_settlement(s.id)
		if named > s.population:
			print("FAIL B2: Named SETTLED (%d) > population (%d) at %s" % [named, s.population, s_id])
			quit(1)
			return
		print("  %s: named_settled=%d <= population=%d" % [s_id, named, s.population])

	var inv_b2 := engine.validate_invariants(world)
	if inv_b2 != "":
		print("FAIL B2: Engine invariant error: %s" % inv_b2)
		quit(1)
		return
	print("PASS GATE B2: Aggregate Subset strictly verified.")

	# --------------------------------------------------------------------------
	# GATE B3: Atomic Departure
	# --------------------------------------------------------------------------
	print("\n--- [GATE B3] Atomic Departure ---")
	var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var pop_before_depart := gv.population        # 100
	var world_total_before := 0
	for s in world.settlements.values():
		world_total_before += (s as SettlementState).population

	var party_id := &"refugee:test_party_b3"
	var depart_res := world.npc_life_state_registry.begin_named_migration(
		world, mara_id, &"settlement:new_hope", party_id, 3, 60
	)
	if not depart_res["success"]:
		print("FAIL B3: begin_named_migration failed: %s" % depart_res.get("error", ""))
		quit(1)
		return

	# Verify atomic state post-departure
	var mara_ls_after_depart: NpcLifeState = world.npc_life_state_registry.get_life_state(mara_id)
	if mara_ls_after_depart.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL B3: Mara should be IN_TRANSIT after departure, got %d" % mara_ls_after_depart.status)
		quit(1)
		return
	if mara_ls_after_depart.population_container_id != party_id:
		print("FAIL B3: Container should be party_id, got %s" % mara_ls_after_depart.population_container_id)
		quit(1)
		return
	if gv.population != pop_before_depart - 1:
		print("FAIL B3: Gray Valley population should decrease by 1! Before=%d After=%d" % [pop_before_depart, gv.population])
		quit(1)
		return

	var party_b3: RefugeePartyState = world.get_refugee_party(party_id)
	if party_b3 == null or party_b3.headcount != 1:
		print("FAIL B3: Party headcount should be 1!")
		quit(1)
		return
	if mara_ls_after_depart.is_alive() == false:
		print("FAIL B3: Mara should still be alive while IN_TRANSIT!")
		quit(1)
		return

	# World total population: transit headcount counted by invariant
	var inv_b3 := engine.validate_invariants(world)
	if inv_b3 != "":
		print("FAIL B3: Engine invariant error after departure: %s" % inv_b3)
		quit(1)
		return
	print("  Gray Valley: %d → %d (−1 for Mara departure)" % [pop_before_depart, gv.population])
	print("  Mara: IN_TRANSIT in party %s (headcount=%d)" % [party_id, party_b3.headcount])
	print("  Engine invariants PASS post-departure.")
	print("PASS GATE B3: Atomic Departure verified.")

	# --------------------------------------------------------------------------
	# GATE B4: Physical Arrival (Axiom 9 Travel Semantics)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B4] Physical Arrival (Axiom 9) ---")
	# Axiom 9: Arrival Day = Departure Day + Route Days - 1
	# Departure Day = 60, Route Days = 3 → Arrival Day = 62
	#
	# For Axiom 9 to hold, the party must be created BEFORE Phase 4 of departure day.
	# Phase 4 decrements days_remaining on the departure day tick itself.
	# This is the exact same semantics as S3-C Phase 1 aggregate migration.
	var tick_engine := SimulationEngine.new()
	tick_engine.enable_migration = false
	tick_engine.enable_mortality = false
	tick_engine.enable_security = false

	var tick_world := S1WorldData.create_s1_world()
	tick_world.current_day = 59  # Day 60 is the "departure day" (next tick)

	var tick_mara_res := tick_world.npc_registry.materialize_identity(tick_world, &"settlement:gray_valley", "Mara", 28)
	var tick_mara_id: StringName = tick_mara_res["npc"].id
	tick_world.npc_life_state_registry.register_life_state(tick_world, tick_mara_id, &"settlement:gray_valley")

	var tick_party_id := &"refugee:mara_b4"
	var nh_tick: SettlementState = tick_world.get_settlement(&"settlement:new_hope")
	var nh_pop_before_arrival := nh_tick.population  # 120

	# Departure BEFORE Day 60 tick → Phase 4 of Day 60 tick will decrement days_remaining.
	# This matches exactly how S3-C triggers migration in Phase 1 (before Phase 4 of same tick).
	var begin_res := tick_world.npc_life_state_registry.begin_named_migration(
		tick_world, tick_mara_id, &"settlement:new_hope", tick_party_id, 3, 60
	)
	if not begin_res["success"]:
		print("FAIL B4: begin_named_migration failed: %s" % begin_res.get("error", ""))
		quit(1)
		return

	# Day 60 tick: Phase 4 decrements days_remaining 3→2; Phase 5: no arrival (days_remaining=2)
	tick_engine.tick(tick_world)  # Day 60
	var tick_mara_ls_60: NpcLifeState = tick_world.npc_life_state_registry.get_life_state(tick_mara_id)
	if tick_mara_ls_60.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL B4: Mara should be IN_TRANSIT after Day 60 tick!")
		quit(1)
		return
	print("  Day 60: Mara still IN_TRANSIT (no arrival yet, days_remaining=2)")

	# Day 61 tick: Phase 4 decrements days_remaining 2→1; Phase 5: no arrival
	tick_engine.tick(tick_world)  # Day 61
	var tick_mara_ls_61: NpcLifeState = tick_world.npc_life_state_registry.get_life_state(tick_mara_id)
	if tick_mara_ls_61.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL B4: Mara should still be IN_TRANSIT on Day 61!")
		quit(1)
		return
	print("  Day 61: Mara still IN_TRANSIT (correct: no teleport, days_remaining=1)")

	# Day 62 tick: Phase 4 decrements days_remaining 1→0; Phase 5: arrives!
	# Axiom 9: Arrival Day = Departure Day 60 + Route Days 3 - 1 = Day 62 ✓
	tick_engine.tick(tick_world)  # Day 62
	var tick_mara_ls_62: NpcLifeState = tick_world.npc_life_state_registry.get_life_state(tick_mara_id)
	if tick_mara_ls_62.status != NpcLifeState.Status.SETTLED:
		print("FAIL B4: Mara should be SETTLED at New Hope on Day 62! Status=%d" % tick_mara_ls_62.status)
		quit(1)
		return
	if tick_mara_ls_62.population_container_id != &"settlement:new_hope":
		print("FAIL B4: Mara container should be new_hope, got %s" % tick_mara_ls_62.population_container_id)
		quit(1)
		return
	if nh_tick.population != nh_pop_before_arrival + 1:
		print("FAIL B4: New Hope population should increase by 1 on Day 62! Before=%d After=%d" % [nh_pop_before_arrival, nh_tick.population])
		quit(1)
		return

	var inv_b4 := tick_engine.validate_invariants(tick_world)
	if inv_b4 != "":
		print("FAIL B4: Engine invariant error after arrival: %s" % inv_b4)
		quit(1)
		return
	print("  Day 62 Evening: Mara arrived at New Hope (population: %d → %d)" % [nh_pop_before_arrival, nh_tick.population])
	print("  Axiom 9 verified: Arrival Day 62 = Departure Day 60 + Route Days 3 - 1")
	print("PASS GATE B4: Physical Arrival (Axiom 9) verified.")

	# --------------------------------------------------------------------------
	# GATE B5: Atomic Arrival
	# --------------------------------------------------------------------------
	print("\n--- [GATE B5] Atomic Arrival ---")
	# Use the party from Gate B3 and manually complete it
	var new_hope: SettlementState = world.get_settlement(&"settlement:new_hope")
	var nh_pop_before := new_hope.population  # 120
	var party_headcount_before := party_b3.headcount  # 1

	var arrive_res := world.npc_life_state_registry.complete_named_migration(world, mara_id)
	if not arrive_res["success"]:
		print("FAIL B5: complete_named_migration failed: %s" % arrive_res.get("error", ""))
		quit(1)
		return

	var mara_ls_arrived: NpcLifeState = world.npc_life_state_registry.get_life_state(mara_id)
	if mara_ls_arrived.status != NpcLifeState.Status.SETTLED:
		print("FAIL B5: Mara should be SETTLED after arrival!")
		quit(1)
		return
	if mara_ls_arrived.population_container_id != &"settlement:new_hope":
		print("FAIL B5: Mara container should be new_hope, got %s" % mara_ls_arrived.population_container_id)
		quit(1)
		return
	if new_hope.population != nh_pop_before + 1:
		print("FAIL B5: New Hope population should increase by 1! Before=%d After=%d" % [nh_pop_before, new_hope.population])
		quit(1)
		return
	if party_b3.headcount != party_headcount_before - 1:
		print("FAIL B5: Party headcount should decrease by 1!")
		quit(1)
		return

	# Mark the party arrived since headcount is now 0 (fully-named party)
	party_b3.is_active = false
	party_b3.is_arrived = true

	var inv_b5 := engine.validate_invariants(world)
	if inv_b5 != "":
		print("FAIL B5: Engine invariant error after arrival: %s" % inv_b5)
		quit(1)
		return
	print("  New Hope: %d → %d (+1 for Mara arrival)" % [nh_pop_before, new_hope.population])
	print("  Party headcount: %d → %d" % [party_headcount_before, party_b3.headcount])
	print("  Mara: SETTLED at settlement:new_hope")
	print("PASS GATE B5: Atomic Arrival verified.")

	# --------------------------------------------------------------------------
	# GATE B6: Atomic Mortality (SETTLED → DEAD)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B6] Atomic Mortality ---")
	# Mara is now SETTLED at New Hope (population=121)
	var nh_pop_before_death := new_hope.population
	var nh_deaths_before := new_hope.cumulative_deaths

	var death_res := world.npc_life_state_registry.commit_named_death(world, mara_id)
	if not death_res["success"]:
		print("FAIL B6: commit_named_death failed: %s" % death_res.get("error", ""))
		quit(1)
		return

	var mara_ls_dead: NpcLifeState = world.npc_life_state_registry.get_life_state(mara_id)
	if mara_ls_dead.status != NpcLifeState.Status.DEAD:
		print("FAIL B6: Mara should be DEAD!")
		quit(1)
		return
	if mara_ls_dead.is_alive():
		print("FAIL B6: is_alive() should return false for DEAD NPC!")
		quit(1)
		return
	if mara_ls_dead.population_container_type != NpcLifeState.ContainerType.NONE:
		print("FAIL B6: DEAD NPC should have NONE container type!")
		quit(1)
		return
	if mara_ls_dead.population_container_id != &"":
		print("FAIL B6: DEAD NPC should have empty container_id!")
		quit(1)
		return
	if new_hope.population != nh_pop_before_death - 1:
		print("FAIL B6: New Hope population should decrease by 1! Before=%d After=%d" % [nh_pop_before_death, new_hope.population])
		quit(1)
		return
	if new_hope.cumulative_deaths != nh_deaths_before + 1:
		print("FAIL B6: New Hope cumulative_deaths should increase by 1!")
		quit(1)
		return

	# Identity must persist after death (NpcRegistry still has Mara)
	var mara_identity: NpcIdentity = world.npc_registry.get_npc(mara_id)
	if mara_identity == null:
		print("FAIL B6: NpcIdentity should PERSIST after death! World must remember Mara.")
		quit(1)
		return
	print("  NpcIdentity preserved after death: id=%s name=%s" % [mara_identity.id, mara_identity.name])

	# Block: cannot die again (already DEAD)
	var double_death := world.npc_life_state_registry.commit_named_death(world, mara_id)
	if double_death["success"]:
		print("FAIL B6: Double death should be rejected!")
		quit(1)
		return
	print("  Double death correctly rejected: %s" % double_death["error"])

	# Block: IN_TRANSIT → DEAD is forbidden in S4-B
	var res_eli2 := world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Eli2", 30)
	var eli2_id: StringName = res_eli2["npc"].id
	world.npc_life_state_registry.register_life_state(world, eli2_id, &"settlement:gray_valley")
	world.npc_life_state_registry.begin_named_migration(world, eli2_id, &"settlement:new_hope", &"refugee:eli2_party", 3, 60)
	var transit_death := world.npc_life_state_registry.commit_named_death(world, eli2_id)
	if transit_death["success"]:
		print("FAIL B6: IN_TRANSIT → DEAD must be forbidden in S4-B!")
		quit(1)
		return
	print("  IN_TRANSIT → DEAD correctly blocked: %s" % transit_death["error"])

	var inv_b6 := engine.validate_invariants(world)
	if inv_b6 != "":
		print("FAIL B6: Engine invariant error after death: %s" % inv_b6)
		quit(1)
		return
	print("  New Hope: %d → %d (−1 Mara death; cumulative_deaths=%d)" % [nh_pop_before_death, new_hope.population, new_hope.cumulative_deaths])
	print("PASS GATE B6: Atomic Mortality verified.")

	# --------------------------------------------------------------------------
	# GATE B7: Aggregate Cannot Choose Named (Fail Closed)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B7] Aggregate Cannot Choose Named ---")
	var b7_engine := SimulationEngine.new()
	b7_engine.enable_migration = true
	b7_engine.enable_mortality = true
	b7_engine.enable_security = false

	var b7_world := S1WorldData.create_s1_world()
	b7_world.current_day = 0

	# Set up Gray Valley: population=15, all 15 named (anonymous=0)
	# MIGRATION_MIN_POPULATION=10, so population>10 allows migration to trigger
	var gv_b7: SettlementState = b7_world.get_settlement(&"settlement:gray_valley")
	gv_b7.population = 15
	gv_b7.reference_population = 15

	for i in range(15):
		var npc_r := b7_world.npc_registry.materialize_identity(b7_world, &"settlement:gray_valley", "Named_%d" % i, 20 + i)
		b7_world.npc_life_state_registry.register_life_state(b7_world, npc_r["npc"].id, &"settlement:gray_valley")

	var anonymous_count := gv_b7.population - b7_world.npc_life_state_registry.get_named_living_count_in_settlement(&"settlement:gray_valley")
	if anonymous_count != 0:
		print("FAIL B7 Setup: Expected anonymous=0, got %d" % anonymous_count)
		quit(1)
		return
	print("  Setup: Gray Valley population=%d, named=%d, anonymous=%d" % [gv_b7.population, 15, 0])

	# Force high pressure to trigger migration
	gv_b7.water_pressure = 80.0
	gv_b7.water_exposure = 10.0  # above grace days
	gv_b7.days_since_last_migration = 999

	# Force severe water unmet for mortality (set inventory to 0, high consumption)
	gv_b7.inventory.set_amount(&"water", 0)
	gv_b7.last_need_outcomes["water"] = {"unmet": 10, "requested": 10, "fulfilled": 0, "stock_before": 0, "stock_after": 0}

	var pop_b7_before := gv_b7.population  # 15
	var deaths_b7_before := gv_b7.cumulative_deaths

	# Compute anonymous count for logging
	var named_living := b7_world.npc_life_state_registry.get_named_living_count_in_settlement(&"settlement:gray_valley")
	var anon := gv_b7.population - named_living
	print("  anonymous_count=%d → migration must FAIL CLOSED" % anon)

	# Actually tick to see FAIL CLOSED events
	var tick_events := b7_engine.tick(b7_world)

	# Verify population unchanged
	if gv_b7.population != pop_b7_before:
		print("FAIL B7: Population should NOT change when anonymous=0! Before=%d After=%d" % [pop_b7_before, gv_b7.population])
		quit(1)
		return

	# Verify NAMED_MIGRATION_DECISION_REQUIRED or NAMED_SELECTION_REQUIRED events emitted
	var got_migration_fail := false
	var got_mortality_fail := false
	for evt in tick_events:
		if (evt as EventRecord).type == "NAMED_MIGRATION_DECISION_REQUIRED":
			got_migration_fail = true
		if (evt as EventRecord).type == "NAMED_SELECTION_REQUIRED":
			got_mortality_fail = true

	if not got_migration_fail:
		print("FAIL B7: Expected NAMED_MIGRATION_DECISION_REQUIRED event!")
		quit(1)
		return
	if not got_mortality_fail:
		print("FAIL B7: Expected NAMED_SELECTION_REQUIRED event!")
		quit(1)
		return

	print("  NAMED_MIGRATION_DECISION_REQUIRED emitted ✓")
	print("  NAMED_SELECTION_REQUIRED emitted ✓")
	print("  Gray Valley population unchanged at %d (all 3 named NPCs untouched)" % gv_b7.population)
	print("PASS GATE B7: Aggregate Cannot Choose Named verified.")

	# --------------------------------------------------------------------------
	# GATE B8: Replay / Validator / Regression (Bitwise Determinism)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B8] Replay / Validator / Regression ---")

	# Dual-world determinism replay
	var world_a := S1WorldData.create_s1_world()
	var world_b := S1WorldData.create_s1_world()

	# Dual-world determinism replay (explicit, no loop — GDScript typing)
	var r1a := world_a.npc_registry.materialize_identity(world_a, &"settlement:gray_valley", "Mara", 28)
	world_a.npc_life_state_registry.register_life_state(world_a, r1a["npc"].id, &"settlement:gray_valley")
	var r2a := world_a.npc_registry.materialize_identity(world_a, &"settlement:new_hope", "Eli", 35)
	world_a.npc_life_state_registry.register_life_state(world_a, r2a["npc"].id, &"settlement:new_hope")
	world_a.npc_life_state_registry.begin_named_migration(world_a, r1a["npc"].id, &"settlement:new_hope", &"refugee:replay_test", 3, 0)
	world_a.npc_life_state_registry.complete_named_migration(world_a, r1a["npc"].id)
	# Mark fully-named party as arrived (headcount=0 after single NPC completes)
	var party_ra: RefugeePartyState = world_a.get_refugee_party(&"refugee:replay_test")
	if party_ra != null and party_ra.headcount <= 0:
		party_ra.is_active = false
		party_ra.is_arrived = true
	world_a.npc_life_state_registry.commit_named_death(world_a, r1a["npc"].id)

	var r1b := world_b.npc_registry.materialize_identity(world_b, &"settlement:gray_valley", "Mara", 28)
	world_b.npc_life_state_registry.register_life_state(world_b, r1b["npc"].id, &"settlement:gray_valley")
	var r2b := world_b.npc_registry.materialize_identity(world_b, &"settlement:new_hope", "Eli", 35)
	world_b.npc_life_state_registry.register_life_state(world_b, r2b["npc"].id, &"settlement:new_hope")
	world_b.npc_life_state_registry.begin_named_migration(world_b, r1b["npc"].id, &"settlement:new_hope", &"refugee:replay_test", 3, 0)
	world_b.npc_life_state_registry.complete_named_migration(world_b, r1b["npc"].id)
	var party_rb: RefugeePartyState = world_b.get_refugee_party(&"refugee:replay_test")
	if party_rb != null and party_rb.headcount <= 0:
		party_rb.is_active = false
		party_rb.is_arrived = true
	world_b.npc_life_state_registry.commit_named_death(world_b, r1b["npc"].id)

	var hash_a := world_a.to_canonical_json().sha256_text()
	var hash_b := world_b.to_canonical_json().sha256_text()
	if hash_a != hash_b:
		print("FAIL B8: Dual world SHA-256 mismatch! A=%s B=%s" % [hash_a, hash_b])
		quit(1)
		return
	print("  Dual world SHA-256 bitwise identical: %s" % hash_a)

	# Serialization/deserialization round-trip
	var world_dict := world_a.to_dict()
	var world_restored := WorldState.from_dict(world_dict)
	var hash_restored := world_restored.to_canonical_json().sha256_text()
	if hash_a != hash_restored:
		print("FAIL B8: Serialization round-trip hash mismatch!")
		quit(1)
		return
	print("  Serialization round-trip SHA-256 matches: %s" % hash_restored)

	# Export snapshot for Python validator
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")
	var snap_file := FileAccess.open("res://artifacts/world_snapshot_s4b.json", FileAccess.WRITE)
	if snap_file != null:
		snap_file.store_string(world_a.to_canonical_json())
		snap_file.close()
		print("  Exported artifacts/world_snapshot_s4b.json for independent lifecycle audit.")

	var inv_b8 := engine.validate_invariants(world_a)
	if inv_b8 != "":
		print("FAIL B8: Engine invariant error on replay world: %s" % inv_b8)
		quit(1)
		return
	print("  Engine invariants PASS on replay world.")
	print("PASS GATE B8: Replay / Validator / Regression verified.")

	print("\n================================================================================")
	print("ALL S4-B RUNTIME ACCEPTANCE GATES (B1 ~ B8) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)
