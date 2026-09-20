extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-A PLAYER AVATAR TEST SUITE
# ==============================================================================
# Verifies that the player is an ordinary human within the wasteland:
#   P1: Materialization & Demographic Conservation (Subset representation, 300 == 300)
#   P2: Unified Intent Authorization (Fail-closed, no cheat APIs)
#   P3: Physical Movement via Existing Transaction (Axiom 9 travel semantics)
#   P4: Personal Inventory & Backpack Load Limits
#   P5: Full Snapshot Save/Load Round-Trip & Bitwise Determinism
#   P6: Full Invariants & Coexistence with NPC Ecosystem
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S5-A PLAYER AVATAR TEST SUITE                        ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	print("\n--- [GATE P1] Player Materialization & Demographic Conservation ---")

	var w1 := S1WorldData.create_s1_world()
	var gv1: SettlementState = w1.get_settlement(&"settlement:gray_valley")
	var initial_pop := gv1.population # 100
	var initial_total_life := calc_life_total(w1) # 300

	var res := engine.materialize_player(w1, &"settlement:gray_valley", "Vagrant", 27, NpcProfile.Background.SCAVENGER)
	if not res["success"]:
		print("FAIL P1: Player materialization failed: %s" % res.get("error", ""))
		quit(1)
		return

	var p: PlayerState = w1.player
	if p == null:
		print("FAIL P1: world.player is null after materialization!")
		quit(1)
		return

	# Player identity & life state checks
	var id: NpcIdentity = w1.npc_registry.get_npc(p.npc_id)
	if id == null or id.name != "Vagrant" or id.origin_settlement_id != &"settlement:gray_valley":
		print("FAIL P1: Player identity invalid!")
		quit(1)
		return

	var ls: NpcLifeState = w1.npc_life_state_registry.get_life_state(p.npc_id)
	if ls == null or ls.status != NpcLifeState.Status.SETTLED or ls.population_container_id != &"settlement:gray_valley":
		print("FAIL P1: Player life state invalid!")
		quit(1)
		return

	# Population check: materialization is representational (pop is still 100, anonymous is 99)
	if gv1.population != initial_pop:
		print("FAIL P1: Settlement population changed upon player materialization! %d != %d" % [gv1.population, initial_pop])
		quit(1)
		return

	var anon_count := gv1.population - w1.npc_life_state_registry.get_named_living_count_in_settlement(gv1.id)
	if anon_count != 99:
		print("FAIL P1: Expected anonymous count 99, got %d" % anon_count)
		quit(1)
		return

	# Global population conservation
	if calc_life_total(w1) != initial_total_life:
		print("FAIL P1: Total world life changed! %d != %d" % [calc_life_total(w1), initial_total_life])
		quit(1)
		return

	# Duplicate materialization must fail-closed
	var dup_res := engine.materialize_player(w1, &"settlement:new_hope", "Clone", 30)
	if dup_res["success"]:
		print("FAIL P1: Duplicate player materialization was permitted!")
		quit(1)
		return

	print("  Player materialized: %s (id: %s, age: %d, origin: %s)" % [id.name, p.npc_id, id.age_at_materialization, id.origin_settlement_id])
	print("  Gray Valley population: %d (anonymous: %d, named: 1)" % [gv1.population, anon_count])
	print("  Global life conservation: %d == %d" % [calc_life_total(w1), initial_total_life])
	print("  Duplicate player materialization refused: %s" % dup_res["error"].split(":")[0])
	print("PASS GATE P1: Player Materialization & Demographic Conservation verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE P2] Unified Intent Authorization ---")

	var before_hash := w1.to_canonical_json().sha256_text()

	# Out-of-space action
	var bogus_intent := PlayerIntent.new(99, p.npc_id, &"settlement:new_hope")
	var err1 := engine.authorize_player_intent(w1, bogus_intent)
	if not err1.begins_with("UNAUTHORIZED_ACTION"):
		print("FAIL P2: Out-of-space action authorized: %s" % err1)
		quit(1)
		return

	# Empty destination for TRAVEL
	var empty_dest_intent := PlayerIntent.create_travel(p.npc_id, &"")
	var err2 := engine.authorize_player_intent(w1, empty_dest_intent)
	if not err2.begins_with("INVALID_INTENT"):
		print("FAIL P2: Empty destination authorized: %s" % err2)
		quit(1)
		return

	# Travel to current settlement
	var self_travel := PlayerIntent.create_travel(p.npc_id, &"settlement:gray_valley")
	var err3 := engine.authorize_player_intent(w1, self_travel)
	if not err3.begins_with("INVALID_DESTINATION"):
		print("FAIL P2: Travel to same settlement authorized: %s" % err3)
		quit(1)
		return

	# Non-existent settlement
	var fake_travel := PlayerIntent.create_travel(p.npc_id, &"settlement:atlantis")
	var err4 := engine.authorize_player_intent(w1, fake_travel)
	if not err4.begins_with("INVALID_DESTINATION"):
		print("FAIL P2: Non-existent destination authorized: %s" % err4)
		quit(1)
		return

	# Zero mutation on authorization failure
	if w1.to_canonical_json().sha256_text() != before_hash:
		print("FAIL P2: World mutated during authorization checks!")
		quit(1)
		return

	# Valid TRAVEL intent
	var valid_travel := PlayerIntent.create_travel(p.npc_id, &"settlement:new_hope")
	var auth_ok := engine.authorize_player_intent(w1, valid_travel)
	if auth_ok != "":
		print("FAIL P2: Valid travel intent refused: %s" % auth_ok)
		quit(1)
		return

	# Valid WAIT intent
	var valid_wait := PlayerIntent.create_wait(p.npc_id)
	var wait_ok := engine.authorize_player_intent(w1, valid_wait)
	if wait_ok != "":
		print("FAIL P2: Valid wait intent refused: %s" % wait_ok)
		quit(1)
		return

	print("  Authorization refuses [out-of-space, empty-dest, same-dest, non-existent-dest]")
	print("  Zero mutation on rejection: world hash unchanged")
	print("  Valid WAIT and TRAVEL intents authorized successfully")
	print("PASS GATE P2: Unified Intent Authorization verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE P3] Physical Movement via Existing Transaction (Axiom 9) ---")

	var pop_gv_pre := gv1.population
	var pop_nh_pre := w1.get_settlement(&"settlement:new_hope").population

	var commit_res := engine.commit_player_intent(w1, valid_travel)
	if not commit_res["success"]:
		print("FAIL P3: Failed to commit valid travel intent: %s" % commit_res.get("error", ""))
		quit(1)
		return

	var party_id: StringName = commit_res["party_id"]
	var route_days: int = commit_res["route_days"]
	var departure_day := w1.current_day # 0

	# Immediate departure state:
	# Gray Valley population drops by 1
	if gv1.population != pop_gv_pre - 1:
		print("FAIL P3: Gray Valley population did not drop by 1 upon departure! %d -> %d" % [pop_gv_pre, gv1.population])
		quit(1)
		return

	# Player life state is IN_TRANSIT inside party
	var ls_travel := w1.npc_life_state_registry.get_life_state(p.npc_id)
	if ls_travel.status != NpcLifeState.Status.IN_TRANSIT or ls_travel.population_container_id != party_id:
		print("FAIL P3: Player life state not IN_TRANSIT inside party %s" % party_id)
		quit(1)
		return

	# Attempting another travel while in transit must fail-closed
	var double_travel := PlayerIntent.create_travel(p.npc_id, &"settlement:dry_well")
	var double_err := engine.authorize_player_intent(w1, double_travel)
	if not double_err.begins_with("INVALID_STATUS"):
		print("FAIL P3: Second travel allowed while already in transit!")
		quit(1)
		return
	print("  Double-travel while in transit correctly refused: %s" % double_err.split(":")[0])

	# Advance Day 0 tick: Phase 4 decrements days_remaining
	engine.tick(w1)
	var party: RefugeePartyState = w1.get_refugee_party(party_id)
	if party.days_remaining != route_days - 1:
		print("FAIL P3: End of Day 0 days_remaining: expected %d, got %d" % [route_days - 1, party.days_remaining])
		quit(1)
		return
	print("  Day 0 (Departure): Player in transit, party days_remaining=%d" % party.days_remaining)

	# Advance Day 1 tick: Mid-route
	engine.tick(w1)
	if ls_travel.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL P3: Player arrived prematurely on Day 1 (teleportation detected!)")
		quit(1)
		return
	print("  Day 1 (Mid-Route): Player still in transit, days_remaining=%d (no teleport)" % party.days_remaining)

	# Advance Day 2 tick: Axiom 9 Arrival Day = 0 + 3 - 1 = 2
	var expected_arrival_day := departure_day + route_days - 1
	engine.tick(w1)

	# After Day 2 finishes execution, current_day is expected_arrival_day + 1
	if w1.current_day != expected_arrival_day + 1:
		print("FAIL P3: Current day %d != expected post-arrival day %d" % [w1.current_day, expected_arrival_day + 1])
		quit(1)
		return

	# Player must now be SETTLED at New Hope
	if ls_travel.status != NpcLifeState.Status.SETTLED or ls_travel.population_container_id != &"settlement:new_hope":
		print("FAIL P3: Player not SETTLED at New Hope on Day 2! status=%d container=%s" % [
			ls_travel.status, ls_travel.population_container_id
		])
		quit(1)
		return

	# New Hope population increased by 1
	var nh_post := w1.get_settlement(&"settlement:new_hope")
	if nh_post.population != pop_nh_pre + 1:
		print("FAIL P3: New Hope population did not increase by 1! %d -> %d" % [pop_nh_pre, nh_post.population])
		quit(1)
		return

	# Global population conservation
	if calc_life_total(w1) != initial_total_life:
		print("FAIL P3: Life conservation broken on arrival: %d != %d" % [calc_life_total(w1), initial_total_life])
		quit(1)
		return

	print("  Day 2 (Arrival): Axiom 9 strictly verified (Arrival 2 = Departure 0 + Route 3 - 1)")
	print("  New Hope population: %d -> %d (+1 player)" % [pop_nh_pre, nh_post.population])
	print("  Global life conservation intact: %d == %d" % [calc_life_total(w1), initial_total_life])
	print("PASS GATE P3: Physical Movement via Existing Transaction verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE P4] Personal Inventory & Backpack Load Limits ---")

	# Capacity is 20
	if p.capacity_total != 20:
		print("FAIL P4: Expected capacity_total 20, got %d" % p.capacity_total)
		quit(1)
		return

	# Player started with 5 water, 5 food -> load is 10
	# During transit (Day 0, 1), player consumed 2 water and 2 food from backpack
	# Arrived on Day 2 at New Hope before Phase 5.4, so Day 2 consumed from settlement
	# Remaining: 5 - 2 = 3 water, 3 food -> load is 6
	var current_load := p.get_total_inventory_load()
	if current_load != 6:
		print("FAIL P4: Expected backpack load 6 after transit, got %d" % current_load)
		quit(1)
		return
	print("  Backpack consumption during transit: 10 -> %d (consumed 1 water & 1 food daily)" % current_load)

	# Capacity checks (capacity_total = 20)
	if not p.has_cargo_capacity(14): # 6 + 14 = 20 <= 20
		print("FAIL P4: has_cargo_capacity(14) should be true!")
		quit(1)
		return
	if p.has_cargo_capacity(15): # 6 + 15 = 21 > 20
		print("FAIL P4: has_cargo_capacity(15) should be false (capacity exceeded)!")
		quit(1)
		return

	# Test invariant check for overloaded backpack
	p.inventory.set_amount(&"scrap", 30) # Total 34 > 20
	var inv_err := engine.validate_invariants(w1)
	if not inv_err.contains("inventory exceeds capacity"):
		print("FAIL P4: Invariant validator failed to catch overloaded backpack: %s" % inv_err)
		quit(1)
		return
	p.inventory.set_amount(&"scrap", 0) # Restore to legal state

	print("  Backpack load limits strictly enforced: max 20 units")
	print("  Invariant validator catches capacity violations fail-closed")
	print("PASS GATE P4: Personal Inventory & Backpack Load Limits verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE P5] Full Snapshot Save/Load Round-Trip & Determinism ---")

	var snap_dict := w1.to_dict()
	if not snap_dict.has("player"):
		print("FAIL P5: Snapshot does not contain 'player' key!")
		quit(1)
		return

	var snap_json := JSON.stringify(snap_dict)
	var restored_dict: Variant = JSON.parse_string(snap_json)
	var w_restored := WorldState.from_dict(restored_dict as Dictionary)
	if w_restored == null:
		print("FAIL P5: WorldState.from_dict refused snapshot with player avatar!")
		quit(1)
		return

	var p_restored := w_restored.player
	if p_restored == null:
		print("FAIL P5: Restored world has null player!")
		quit(1)
		return

	if p_restored.npc_id != p.npc_id or p_restored.money != p.money or p_restored.capacity_total != p.capacity_total:
		print("FAIL P5: Restored player fields mismatch!")
		quit(1)
		return

	if p_restored.get_total_inventory_load() != p.get_total_inventory_load():
		print("FAIL P5: Restored player inventory load mismatch!")
		quit(1)
		return

	var hash_live := w1.to_canonical_json().sha256_text()
	var hash_restored := w_restored.to_canonical_json().sha256_text()
	if hash_live != hash_restored:
		print("FAIL P5: Save/load canonical JSON hash mismatch!")
		print("  Live:     %s" % hash_live)
		print("  Restored: %s" % hash_restored)
		quit(1)
		return

	print("  Player avatar round-trips through Save/Load as a strict fixed point")
	print("  Canonical JSON SHA-256 bitwise identical: %s" % hash_live)
	print("PASS GATE P5: Full Snapshot Save/Load Round-Trip & Determinism verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE P6] Coexistence with NPC Ecosystem ---")

	# Materialize Mara at Gray Valley and give her a background
	var mara_res := w1.npc_registry.materialize_identity(w1, &"settlement:gray_valley", "Mara", 28)
	w1.npc_life_state_registry.register_life_state(w1, mara_res["npc"].id, &"settlement:gray_valley")
	w1.npc_profile_registry.assign_background(w1, mara_res["npc"].id, NpcProfile.Background.CARAVAN_GUARD)

	# Run 10 ticks: Player is at New Hope, Mara is at Gray Valley
	for d in range(10):
		engine.tick(w1)

	var inv_check := engine.validate_invariants(w1)
	if inv_check != "":
		print("FAIL P6: Invariant failure during player + NPC coexistence: %s" % inv_check)
		quit(1)
		return

	if calc_life_total(w1) != initial_total_life:
		print("FAIL P6: Life conservation broken during coexistence: %d != %d" % [calc_life_total(w1), initial_total_life])
		quit(1)
		return

	print("  Player and NPCs run side-by-side across 10 ticks with 0 invariant violations")
	print("  Life conservation intact: %d == %d" % [calc_life_total(w1), initial_total_life])
	print("PASS GATE P6: Coexistence with NPC Ecosystem verified.")

	print("\n================================================================================")
	print("ALL S5-A PLAYER AVATAR GATES (P1 ~ P6) PASSED CLEANLY!                          ")
	print("================================================================================")
	quit(0)

func calc_life_total(w: WorldState) -> int:
	var total := 0
	for s_id in w.settlements:
		var s: SettlementState = w.settlements[s_id]
		total += s.population + s.cumulative_deaths
	for r_id in w.refugees:
		var r: RefugeePartyState = w.refugees[r_id]
		if r.is_active and not r.is_arrived:
			total += r.headcount
	return total
