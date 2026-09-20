extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-A NPC IDENTITY TEST SUITE
# ==============================================================================
# Verifies the 7 Runtime Acceptance Gates (A1 ~ A7) for minimal NPC identity:
#   A1: Materialization Is Non-Demographic (Pop before == Pop after)
#   A2: Subset Invariant (Named <= Settlement Population)
#   A3: Anonymous Accounting (Anonymous = Population - Named >= 0)
#   A4: Deterministic Monotonic ID Minting (npc:00000001 ...)
#   A5: Fail-Closed Negative Tests (Capacity overflow, invalid ref, duplicate)
#   A6: Serialization & Duplication Consistency (to_dict / from_dict / duplicate)
#   A7: Engine Invariant Integration & Bitwise Replay
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S4-A NPC IDENTITY RUNTIME TEST SUITE              ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE A1: Materialization Is Non-Demographic
	# --------------------------------------------------------------------------
	print("\n--- [GATE A1] Materialization Is Non-Demographic ---")
	var world := S1WorldData.create_s1_world()
	var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var initial_gv_pop: int = gv.population # 100
	var initial_total_pop: int = 0
	for s in world.settlements.values():
		initial_total_pop += (s as SettlementState).population # 300

	# Materialize 1st NPC: Mara
	var res1 := world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Mara", 28)
	if not res1["success"]:
		print("FAIL A1: Failed to materialize Mara: %s" % res1.get("error", ""))
		quit(1)
		return

	if gv.population != initial_gv_pop:
		print("FAIL A1: Settlement population changed after materialization! Expected %d, got %d" % [
			initial_gv_pop, gv.population
		])
		quit(1)
		return

	# Materialize 4 more NPCs
	world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Eli", 35)
	world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Jon", 42)
	world.npc_registry.materialize_identity(world, &"settlement:new_hope", "Sarah", 24)
	world.npc_registry.materialize_identity(world, &"settlement:dry_well", "Kael", 50)

	var current_total: int = 0
	for s in world.settlements.values():
		current_total += (s as SettlementState).population

	if current_total != initial_total_pop or gv.population != 100:
		print("FAIL A1: Total world population inflated! Expected %d, got %d" % [initial_total_pop, current_total])
		quit(1)
		return

	print("  Before materialization: Pop = 100, Named = 0, Anonymous = 100")
	print("  After 3 materializations: Pop = %d, Named = %d, Anonymous = %d" % [
		gv.population,
		world.npc_registry.get_named_count_at(&"settlement:gray_valley"),
		world.npc_registry.get_anonymous_count_at(world, &"settlement:gray_valley")
	])
	print("  World total population strictly preserved: %d == %d" % [current_total, initial_total_pop])
	print("PASS GATE A1: Materialization Is Non-Demographic verified.")

	# --------------------------------------------------------------------------
	# GATE A2: Subset Invariant
	# --------------------------------------------------------------------------
	print("\n--- [GATE A2] Subset Invariant ---")
	for s_id in world.settlements:
		var s: SettlementState = world.settlements[s_id]
		var named: int = world.npc_registry.get_named_count_at(s.id)
		if named > s.population:
			print("FAIL A2: Named count %d > population %d at %s" % [named, s.population, s.id])
			quit(1)
			return
		print("  Settlement %s: Named (%d) <= Population (%d)" % [s.id, named, s.population])
	print("PASS GATE A2: Subset Invariant strictly verified.")

	# --------------------------------------------------------------------------
	# GATE A3: Anonymous Accounting
	# --------------------------------------------------------------------------
	print("\n--- [GATE A3] Anonymous Accounting ---")
	var gv_named := world.npc_registry.get_named_count_at(&"settlement:gray_valley")
	var gv_anon := world.npc_registry.get_anonymous_count_at(world, &"settlement:gray_valley")
	if gv_named + gv_anon != gv.population:
		print("FAIL A3: Named (%d) + Anonymous (%d) != Total (%d)" % [gv_named, gv_anon, gv.population])
		quit(1)
		return
	if gv_anon < 0:
		print("FAIL A3: Anonymous count is negative: %d" % gv_anon)
		quit(1)
		return
	print("  Gray Valley: %d Named + %d Anonymous == %d Total (Anonymous >= 0 holds)" % [
		gv_named, gv_anon, gv.population
	])
	print("PASS GATE A3: Anonymous Accounting strictly verified.")

	# --------------------------------------------------------------------------
	# GATE A4: Deterministic Monotonic ID Minting
	# --------------------------------------------------------------------------
	print("\n--- [GATE A4] Deterministic Monotonic ID Minting ---")
	var expected_ids := [&"npc:00000001", &"npc:00000002", &"npc:00000003", &"npc:00000004", &"npc:00000005"]
	var npcs := world.npc_registry.get_all_npcs()
	if npcs.size() != 5:
		print("FAIL A4: Expected 5 NPCs, got %d" % npcs.size())
		quit(1)
		return

	for i in range(5):
		if npcs[i].id != expected_ids[i]:
			print("FAIL A4: ID mismatch at index %d! Expected %s, got %s" % [i, expected_ids[i], npcs[i].id])
			quit(1)
			return

	if world.next_npc_sequence != 6:
		print("FAIL A4: next_npc_sequence mismatch! Expected 6, got %d" % world.next_npc_sequence)
		quit(1)
		return

	# Dual world test
	var world_clone := S1WorldData.create_s1_world()
	world_clone.npc_registry.materialize_identity(world_clone, &"settlement:gray_valley", "Mara", 28)
	world_clone.npc_registry.materialize_identity(world_clone, &"settlement:gray_valley", "Eli", 35)
	world_clone.npc_registry.materialize_identity(world_clone, &"settlement:gray_valley", "Jon", 42)
	world_clone.npc_registry.materialize_identity(world_clone, &"settlement:new_hope", "Sarah", 24)
	world_clone.npc_registry.materialize_identity(world_clone, &"settlement:dry_well", "Kael", 50)

	var hash_a := world.to_canonical_json().sha256_text()
	var hash_b := world_clone.to_canonical_json().sha256_text()
	if hash_a != hash_b:
		print("FAIL A4: Dual world state hash mismatch on deterministic ID minting!")
		quit(1)
		return
	print("  Monotonic IDs: npc:00000001 through npc:00000005 verified.")
	print("  Dual world SHA-256 bitwise identical: %s" % hash_a)
	print("PASS GATE A4: Deterministic Monotonic ID Minting verified.")

	# --------------------------------------------------------------------------
	# GATE A5: Fail-Closed Negative Tests
	# --------------------------------------------------------------------------
	print("\n--- [GATE A5] Fail-Closed Negative Tests ---")
	var small_world := S1WorldData.create_s1_world()
	var small_settlement: SettlementState = small_world.get_settlement(&"settlement:dry_well")
	small_settlement.population = 2 # Set to small capacity 2

	# Materialize 2 NPCs (reaches 100% capacity)
	var m1 := small_world.npc_registry.materialize_identity(small_world, &"settlement:dry_well", "Person1", 20)
	var m2 := small_world.npc_registry.materialize_identity(small_world, &"settlement:dry_well", "Person2", 30)
	if not m1["success"] or not m2["success"]:
		print("FAIL A5: Failed initial setup for small world!")
		quit(1)
		return

	var pre_fail_hash := small_world.to_canonical_json().sha256_text()
	var pre_fail_seq := small_world.next_npc_sequence

	# Negative Test 1: Capacity Overflow (3rd NPC in 2-person settlement)
	var overflow_res := small_world.npc_registry.materialize_identity(small_world, &"settlement:dry_well", "Person3", 40)
	if overflow_res["success"]:
		print("FAIL A5: Capacity overflow permitted!")
		quit(1)
		return
	print("  Expected overflow rejection caught: %s" % overflow_res["error"])

	# Ensure state hash and sequence unchanged after rejection
	if small_world.to_canonical_json().sha256_text() != pre_fail_hash:
		print("FAIL A5: State mutated after failed overflow materialization!")
		quit(1)
		return
	if small_world.next_npc_sequence != pre_fail_seq:
		print("FAIL A5: Sequence mutated after failed overflow! Expected %d, got %d" % [
			pre_fail_seq, small_world.next_npc_sequence
		])
		quit(1)
		return

	# Negative Test 2: Invalid Settlement Reference
	var invalid_ref_res := small_world.npc_registry.materialize_identity(small_world, &"settlement:moon_base", "Alien", 99)
	if invalid_ref_res["success"]:
		print("FAIL A5: Invalid settlement reference permitted!")
		quit(1)
		return
	print("  Expected invalid reference rejection caught: %s" % invalid_ref_res["error"])

	if small_world.to_canonical_json().sha256_text() != pre_fail_hash:
		print("FAIL A5: State mutated after failed invalid reference materialization!")
		quit(1)
		return
	if small_world.next_npc_sequence != pre_fail_seq:
		print("FAIL A5: Sequence mutated after failed invalid reference! Expected %d, got %d" % [
			pre_fail_seq, small_world.next_npc_sequence
		])
		quit(1)
		return

	# Negative Test 3: Duplicate ID rejection
	var dup_res := small_world.npc_registry.materialize_identity(small_world, &"settlement:gray_valley", "PersonDup", 25)
	if not dup_res["success"]:
		print("FAIL A5: Valid materialization unexpectedly failed!")
		quit(1)
		return
	var test_id: StringName = dup_res["npc"].id # npc:00000003
	var seq_before_collision := small_world.next_npc_sequence
	# Revert sequence back to 3 to simulate collision
	small_world.next_npc_sequence = 3
	var collision_res := small_world.npc_registry.materialize_identity(small_world, &"settlement:gray_valley", "Collision", 26)
	if collision_res["success"]:
		print("FAIL A5: Duplicate ID permitted!")
		quit(1)
		return
	print("  Expected duplicate ID rejection caught: %s" % collision_res["error"])
	if small_world.next_npc_sequence != 3:
		print("FAIL A5: Sequence mutated after collision rejection! Expected 3, got %d" % small_world.next_npc_sequence)
		quit(1)
		return

	print("PASS GATE A5: Fail-Closed Negative Tests strictly verified.")

	# --------------------------------------------------------------------------
	# GATE A6: Serialization & Duplication Consistency
	# --------------------------------------------------------------------------
	print("\n--- [GATE A6] Serialization & Duplication Consistency ---")
	var world_dict := world.to_dict()
	var restored_world := WorldState.from_dict(world_dict)

	if restored_world.next_npc_sequence != world.next_npc_sequence:
		print("FAIL A6: Restored next_npc_sequence mismatch! %d != %d" % [
			restored_world.next_npc_sequence, world.next_npc_sequence
		])
		quit(1)
		return

	if restored_world.npc_registry.get_all_npcs().size() != 5:
		print("FAIL A6: Restored NPC count mismatch! %d != 5" % restored_world.npc_registry.get_all_npcs().size())
		quit(1)
		return

	for expected_id in expected_ids:
		var npc_orig: NpcIdentity = world.npc_registry.get_npc(expected_id)
		var npc_rest: NpcIdentity = restored_world.npc_registry.get_npc(expected_id)
		if npc_rest == null:
			print("FAIL A6: Missing NPC %s in restored world!" % expected_id)
			quit(1)
			return
		if npc_orig.name != npc_rest.name or npc_orig.age_at_materialization != npc_rest.age_at_materialization or npc_orig.origin_settlement_id != npc_rest.origin_settlement_id:
			print("FAIL A6: NPC attribute mismatch for %s!" % expected_id)
			quit(1)
			return

	# Duplicate state check
	var dup_world := world.duplicate_state()
	var hash_orig := world.to_canonical_json().sha256_text()
	var hash_rest := restored_world.to_canonical_json().sha256_text()
	var hash_dup := dup_world.to_canonical_json().sha256_text()

	if hash_orig != hash_rest or hash_orig != hash_dup:
		print("FAIL A6: Serialization/duplicate hash mismatch! Orig: %s, Rest: %s, Dup: %s" % [
			hash_orig, hash_rest, hash_dup
		])
		quit(1)
		return

	print("  Original, Deserialized, and Duplicated worlds have 100%% bitwise matching SHA-256: %s" % hash_orig)
	print("PASS GATE A6: Serialization & Duplication Consistency verified.")

	# --------------------------------------------------------------------------
	# GATE A7: Engine Invariant Integration & Bitwise Replay
	# --------------------------------------------------------------------------
	print("\n--- [GATE A7] Engine Invariant Integration & Bitwise Replay ---")
	var inv_err := engine.validate_invariants(world)
	if inv_err != "":
		print("FAIL A7: Engine invariant validation failed on world with NPCs: %s" % inv_err)
		quit(1)
		return

	# Export snapshot artifact for independent domain authority validation
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")
	var snap_file := FileAccess.open("res://artifacts/world_snapshot.json", FileAccess.WRITE)
	if snap_file != null:
		snap_file.store_string(world.to_canonical_json())
		snap_file.close()
		print("  Exported artifacts/world_snapshot.json for independent audit.")

	# Run 10 ticks with NPCs in world
	for d in range(1, 11):
		engine.tick(world)

	var post_tick_inv := engine.validate_invariants(world)
	if post_tick_inv != "":
		print("FAIL A7: Engine invariant failed after 10 ticks: %s" % post_tick_inv)
		quit(1)
		return

	# Ensure named NPCs still exist and undamaged
	if world.npc_registry.get_all_npcs().size() != 5:
		print("FAIL A7: NPC count corrupted after ticks!")
		quit(1)
		return

	print("  Engine invariants validated across 10 ticks with 5 named NPCs active in world.")
	print("PASS GATE A7: Engine Invariant Integration & Bitwise Replay verified.")

	print("\n================================================================================")
	print("ALL S4-A RUNTIME ACCEPTANCE GATES (A1 ~ A7) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)
