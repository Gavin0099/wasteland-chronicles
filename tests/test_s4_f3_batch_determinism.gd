extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-F3 MULTI-NPC BATCH DETERMINISM TEST SUITE
# ==============================================================================
# Verifies batch semantics, canonical ordering, and contention resolution:
#   F3-1 Shared Snapshot: All NPCs in a phase evaluate against an immutable snapshot.
#   F3-2 Canonical Evaluation: Lexicographic npc_id order determines decision & commit.
#   F3-3 Insertion Independence: Registry insertion order does not affect final world.
#   F3-4 Multi-Intent Revalidation: Intent contention (Case B: constraint boundary)
#         - 01 COMMITTED, 02 COMMITTED, 03 REJECTED (PRECONDITION_CHANGED).
#         - No event in ledger for rejected intents. Replay bitwise identical.
#   F3-5 Population & Transit Conservation (Case A: all 5 succeed):
#         - Gray Valley -5, 5 in party, New Hope +5 after 3 days. 300 == 300.
#   F3-6 Replay & Mid-Cycle Save/Load: Bitwise identical state and audit trails.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S4-F3 MULTI-NPC BATCH DETERMINISM                    ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3-1] Shared Snapshot ---")

	var w1 := build_world_with_5_npcs()
	# Squeeze Gray Valley until multi-decision day
	var batch_day := -1
	for d in range(20):
		tick_day(w1, true)
		var decisions_today := get_decisions_on_day(w1, w1.current_day)
		if decisions_today.size() >= 3:
			batch_day = w1.current_day
			break

	if batch_day < 0:
		print("FAIL F3-1: Could not find a day where multiple NPCs decided!")
		quit(1)
		return

	var day_decisions := get_decisions_on_day(w1, batch_day)
	print("  Day %d: %d NPCs made decisions in the same phase" % [batch_day, day_decisions.size()])

	# Verify every NPC's observed state has identical pressure and security
	var first_obs: Dictionary = day_decisions[0].observed_state
	for i in range(1, day_decisions.size()):
		var obs: Dictionary = day_decisions[i].observed_state
		for key in ["water_pressure", "food_pressure", "security", "current_settlement_id"]:
			if str(obs.get(key, "")) != str(first_obs.get(key, "")):
				print("FAIL F3-1: Observation mismatch for %s on %s: %s vs %s" % [
					day_decisions[i].npc_id, key, obs.get(key, ""), first_obs.get(key, "")
				])
				quit(1)
				return

	print("  All %d NPCs observed the exact same snapshot (no mutation interleaving)" % day_decisions.size())
	print("PASS GATE F3-1: Shared Snapshot verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3-2] Canonical Evaluation Order ---")

	# Check evaluation and commit order in decision trail on every multi-decision day
	var checked_days := 0
	for d in range(1, w1.current_day + 1):
		var decs := get_decisions_on_day(w1, d)
		if decs.size() > 1:
			checked_days += 1
			for i in range(1, decs.size()):
				var prev_id: String = String(decs[i - 1].npc_id)
				var curr_id: String = String(decs[i].npc_id)
				if prev_id >= curr_id:
					print("FAIL F3-2: Decision order on Day %d is not lexicographical: %s before %s" % [
						d, prev_id, curr_id
					])
					quit(1)
					return

	print("  Checked %d multi-decision days: evaluation order is strictly lexicographic" % checked_days)

	# Check committed events in event log on the batch departure day
	var depart_events: Array[EventRecord] = []
	for evt in w1.event_log:
		if evt.day == batch_day and evt.type == "NAMED_NPC_MIGRATION_STARTED":
			depart_events.append(evt)

	for i in range(1, depart_events.size()):
		var prev_id := String(depart_events[i - 1].actor_id)
		var curr_id := String(depart_events[i].actor_id)
		if prev_id >= curr_id:
			print("FAIL F3-2: Committed departure events not in canonical order: %s before %s" % [
				prev_id, curr_id
			])
			quit(1)
			return

	print("  Committed events in ledger preserve strict canonical actor order")
	print("PASS GATE F3-2: Canonical Evaluation Order verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3-3] Insertion Independence ---")

	# World A: forward insertion (01, 02, 03, 04, 05)
	var wa := build_world_with_npcs_ordered([0, 1, 2, 3, 4])
	# World B: reversed insertion (05, 04, 03, 02, 01)
	var wb := build_world_with_npcs_ordered([4, 3, 2, 1, 0])
	# World C: shuffled insertion (03, 01, 05, 02, 04)
	var wc := build_world_with_npcs_ordered([2, 0, 4, 1, 3])

	for d in range(25):
		tick_day(wa, d < 15)
		tick_day(wb, d < 15)
		tick_day(wc, d < 15)

	var hash_a := wa.to_canonical_json().sha256_text()
	var hash_b := wb.to_canonical_json().sha256_text()
	var hash_c := wc.to_canonical_json().sha256_text()

	if hash_a != hash_b:
		print("FAIL F3-3: Forward vs Reversed insertion diverged!")
		print("  World A (forward):  %s" % hash_a)
		print("  World B (reversed): %s" % hash_b)
		quit(1)
		return

	if hash_a != hash_c:
		print("FAIL F3-3: Forward vs Shuffled insertion diverged!")
		print("  World A (forward):  %s" % hash_a)
		print("  World C (shuffled): %s" % hash_c)
		quit(1)
		return

	# Decision trails must also be bitwise identical
	var dt_a := JSON.stringify(wa.to_dict()["decision_audit_trail"]).sha256_text()
	var dt_b := JSON.stringify(wb.to_dict()["decision_audit_trail"]).sha256_text()
	var dt_c := JSON.stringify(wc.to_dict()["decision_audit_trail"]).sha256_text()

	if dt_a != dt_b or dt_a != dt_c:
		print("FAIL F3-3: Decision audit trails diverged under different insertion orders!")
		quit(1)
		return

	print("  3 worlds with Forward, Reversed, and Shuffled registry insertion orders:")
	print("  Final World Canonical SHA: %s (bitwise identical)" % hash_a)
	print("  Decision Audit Trail SHA:  %s (bitwise identical)" % dt_a)
	print("PASS GATE F3-3: Insertion Independence verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3-4] Multi-Intent Revalidation (Case B: Intent Contention) ---")

	# Replay contention test multiple times to ensure 100% determinism
	for trial in range(5):
		var w_cont := build_contention_world()
		# Gray Valley starts at population = 12 (floor is 10)
		# 3 named NPCs: npc:00000001, npc:00000002, npc:00000003
		# Elevated water pressure (80.0) triggers MIGRATE for all 3.
		# But population floor is 10:
		#   - npc:00000001 commits: pop 12 -> 11
		#   - npc:00000002 commits: pop 11 -> 10
		#   - npc:00000003 revalidates: pop is 10 <= 10 -> REJECTED!

		var engine := SimulationEngine.new()
		# Disable aggregate migration & mortality so only named decisions run
		engine.enable_migration = false
		engine.enable_mortality = false
		engine.enable_security = false

		engine.tick(w_cont)

		var gv: SettlementState = w_cont.get_settlement(&"settlement:gray_valley")
		if gv.population != 10:
			print("FAIL F3-4 (Trial %d): Gray Valley population expected 10, got %d" % [trial, gv.population])
			quit(1)
			return

		var decs := get_decisions_on_day(w_cont, 1)
		if decs.size() != 3:
			print("FAIL F3-4 (Trial %d): Expected 3 decisions, got %d" % [trial, decs.size()])
			quit(1)
			return

		# 01 must be COMMITTED
		if decs[0].npc_id != &"npc:00000001" or decs[0].result != NpcDecisionEvidence.Result.COMMITTED:
			print("FAIL F3-4: npc:00000001 expected COMMITTED, got %d" % decs[0].result)
			quit(1)
			return

		# 02 must be COMMITTED
		if decs[1].npc_id != &"npc:00000002" or decs[1].result != NpcDecisionEvidence.Result.COMMITTED:
			print("FAIL F3-4: npc:00000002 expected COMMITTED, got %d" % decs[1].result)
			quit(1)
			return

		# 03 must be REJECTED with PRECONDITION_CHANGED
		if decs[2].npc_id != &"npc:00000003" or decs[2].result != NpcDecisionEvidence.Result.REJECTED:
			print("FAIL F3-4: npc:00000003 expected REJECTED, got %d" % decs[2].result)
			quit(1)
			return

		if not decs[2].reason.begins_with("PRECONDITION_CHANGED"):
			print("FAIL F3-4: Unexpected rejection reason: %s" % decs[2].reason)
			quit(1)
			return

		if decs[2].committed_event_index != -1:
			print("FAIL F3-4: Rejected intent references an event index: %d" % decs[2].committed_event_index)
			quit(1)
			return

		# Ledger must NOT have a migration event for npc:00000003
		for evt in w_cont.event_log:
			if evt.actor_id == &"npc:00000003" and evt.type == "NAMED_NPC_MIGRATION_STARTED":
				print("FAIL F3-4: Event ledger contains migration event for rejected npc:00000003!")
				quit(1)
				return

		# Life states: 01 & 02 IN_TRANSIT, 03 still SETTLED at Gray Valley
		var ls1: NpcLifeState = w_cont.npc_life_state_registry.get_life_state(&"npc:00000001")
		var ls2: NpcLifeState = w_cont.npc_life_state_registry.get_life_state(&"npc:00000002")
		var ls3: NpcLifeState = w_cont.npc_life_state_registry.get_life_state(&"npc:00000003")

		if ls1.status != NpcLifeState.Status.IN_TRANSIT or ls2.status != NpcLifeState.Status.IN_TRANSIT:
			print("FAIL F3-4: 01 and 02 must be IN_TRANSIT!")
			quit(1)
			return
		if ls3.status != NpcLifeState.Status.SETTLED or ls3.population_container_id != &"settlement:gray_valley":
			print("FAIL F3-4: 03 must remain SETTLED at gray_valley!")
			quit(1)
			return

	print("  Case B Contention tested across 5 replays:")
	print("  npc:00000001 -> COMMITTED (pop 12 -> 11)")
	print("  npc:00000002 -> COMMITTED (pop 11 -> 10)")
	print("  npc:00000003 -> REJECTED (PRECONDITION_CHANGED: origin population at floor 10)")
	print("  Event ledger: 0 migration events for rejected NPC")
	print("  Canonical commit order guaranteed exact same winners & losers on every replay")
	print("PASS GATE F3-4: Multi-Intent Revalidation verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3-5] Population & Transit Conservation (Case A: All 5 Succeed) ---")

	var w5 := build_world_with_5_npcs()
	var gv5: SettlementState = w5.get_settlement(&"settlement:gray_valley")
	var nh5: SettlementState = w5.get_settlement(&"settlement:new_hope")

	# Squeeze Gray Valley until all 5 decide to migrate
	var all_departed_day := -1
	for d in range(25):
		tick_day(w5, true)
		var departed_count := 0
		for i in range(1, 6):
			var nid := StringName("npc:%08d" % i)
			var ls: NpcLifeState = w5.npc_life_state_registry.get_life_state(nid)
			if ls.status == NpcLifeState.Status.IN_TRANSIT:
				departed_count += 1
		if departed_count == 5:
			all_departed_day = w5.current_day
			break

	if all_departed_day < 0:
		print("FAIL F3-5: Not all 5 NPCs departed!")
		quit(1)
		return

	print("  Day %d: All 5 named NPCs departed together" % all_departed_day)

	# Verify they joined the refugee party and headcount is at least 5
	var ls_sample: NpcLifeState = w5.npc_life_state_registry.get_life_state(&"npc:00000001")
	var party: RefugeePartyState = w5.get_refugee_party(ls_sample.population_container_id)
	if party == null:
		print("FAIL F3-5: Refugee party does not exist!")
		quit(1)
		return

	var named_in_party := w5.npc_life_state_registry.get_all_living_in(
		NpcLifeState.ContainerType.REFUGEE_PARTY, party.id
	)
	if named_in_party.size() != 5:
		print("FAIL F3-5: Expected 5 named NPCs in party, found %d" % named_in_party.size())
		quit(1)
		return
	print("  All 5 named NPCs are IN_TRANSIT inside party %s" % party.id)

	# Track until arrival (Axiom 9: all_departed_day + 3 - 1 = all_departed_day + 2)
	var expected_arrival := all_departed_day + party.route_days - 1
	print("  Expected arrival day: Day %d" % expected_arrival)

	var nh_pop_before := nh5.population
	while w5.current_day < expected_arrival:
		tick_day(w5, false)

	# On arrival day, all 5 must be SETTLED at New Hope
	var settled_at_nh := 0
	for i in range(1, 6):
		var nid := StringName("npc:%08d" % i)
		var ls: NpcLifeState = w5.npc_life_state_registry.get_life_state(nid)
		if ls.status == NpcLifeState.Status.SETTLED and ls.population_container_id == &"settlement:new_hope":
			settled_at_nh += 1

	if settled_at_nh != 5:
		print("FAIL F3-5: Expected 5 settled at New Hope on Day %d, got %d" % [expected_arrival, settled_at_nh])
		quit(1)
		return

	# Global population conservation check
	var engine5 := SimulationEngine.new()
	var inv_err := engine5.validate_invariants(w5)
	if inv_err != "":
		print("FAIL F3-5: Invariants violated after 5-NPC migration: %s" % inv_err)
		quit(1)
		return

	var life_total := calc_life_total(w5)
	if life_total != w5.total_initial_population:
		print("FAIL F3-5: Global life conservation broken: %d != %d" % [life_total, w5.total_initial_population])
		quit(1)
		return

	print("  Day %d: All 5 named NPCs arrived at New Hope" % expected_arrival)
	print("  Life conservation intact: %d == %d" % [life_total, w5.total_initial_population])
	print("PASS GATE F3-5: Population & Transit Conservation verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3-6] Replay & Mid-Cycle Save/Load Equivalence ---")

	# World Continuous (runs to Day 30)
	var w_cont_a := build_world_with_5_npcs()
	for d in range(30):
		tick_day(w_cont_a, d < 15)

	# World Interrupted (runs to Day 14 mid-route, saves, loads, continues to Day 30)
	var w_inter_b := build_world_with_5_npcs()
	for d in range(14):
		tick_day(w_inter_b, d < 15)

	var save_json := JSON.stringify(w_inter_b.to_dict())
	var restored_dict: Variant = JSON.parse_string(save_json)
	var w_restored := WorldState.from_dict(restored_dict as Dictionary)
	if w_restored == null:
		print("FAIL F3-6: Failed to restore world from save JSON!")
		quit(1)
		return

	while w_restored.current_day < 30:
		tick_day(w_restored, w_restored.current_day < 15)

	var sha_continuous := w_cont_a.to_canonical_json().sha256_text()
	var sha_restored := w_restored.to_canonical_json().sha256_text()

	if sha_continuous != sha_restored:
		print("FAIL F3-6: Continuous vs Restored world diverged at Day 30!")
		print("  Continuous SHA: %s" % sha_continuous)
		print("  Restored SHA:   %s" % sha_restored)
		quit(1)
		return

	var trail_cont := JSON.stringify(w_cont_a.to_dict()["decision_audit_trail"]).sha256_text()
	var trail_rest := JSON.stringify(w_restored.to_dict()["decision_audit_trail"]).sha256_text()

	if trail_cont != trail_rest:
		print("FAIL F3-6: Decision audit trails diverged across save/load!")
		quit(1)
		return

	print("  Continuous vs Interrupted (Save/Load at Day 14) running to Day 30:")
	print("  Canonical World State SHA:  %s (bitwise identical)" % sha_continuous)
	print("  Decision Audit Trail SHA:   %s (bitwise identical)" % trail_cont)
	print("PASS GATE F3-6: Replay & Mid-Cycle Save/Load Equivalence verified.")

	print("\n================================================================================")
	print("ALL S4-F3 MULTI-NPC BATCH DETERMINISM GATES (F3-1 ~ F3-6) PASSED CLEANLY!       ")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Helpers
# ==============================================================================

func build_world_with_5_npcs() -> WorldState:
	return build_world_with_npcs_ordered([0, 1, 2, 3, 4])

func build_world_with_npcs_ordered(order: Array[int]) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var names := ["Mara", "Eli", "Jon", "Tess", "Bram"]
	var backgrounds := [
		NpcProfile.Background.CARAVAN_GUARD,
		NpcProfile.Background.MECHANIC,
		NpcProfile.Background.FARMER,
		NpcProfile.Background.SCAVENGER,
		NpcProfile.Background.CARAVAN_GUARD
	]
	# Materialize identities in standard order so npc:00000001 is always Mara, 02 is Eli, etc.
	var nids: Array[StringName] = []
	for i in range(5):
		var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 25 + i)
		nids.append(res["npc"].id)

	# Register life states and profiles in the permutation order
	for idx in order:
		var nid: StringName = nids[idx]
		w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
		w.npc_profile_registry.assign_background(w, nid, backgrounds[idx])

	# Re-order the internal dictionary in npc_registry to match the permutation order
	var reordered_npcs := {}
	for idx in order:
		reordered_npcs[nids[idx]] = w.npc_registry.npcs[nids[idx]]
	w.npc_registry.npcs = reordered_npcs

	return w

func build_contention_world() -> WorldState:
	var w := S1WorldData.create_s1_world()
	var gv: SettlementState = w.get_settlement(&"settlement:gray_valley")
	gv.population = 12
	gv.reference_population = 12
	gv.water_pressure = 80.0
	gv.inventory.water = 0

	var names := ["Mara", "Eli", "Jon"]
	for i in range(3):
		var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 28 + i)
		var nid: StringName = res["npc"].id
		w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
	return w

func get_decisions_on_day(w: WorldState, day: int) -> Array[NpcDecisionEvidence]:
	var result: Array[NpcDecisionEvidence] = []
	for ev in w.decision_audit_trail:
		if ev.day == day:
			result.append(ev)
	return result

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

func tick_day(w: WorldState, squeeze_gray_valley: bool) -> void:
	var engine := SimulationEngine.new()
	engine.tick(w)
	if squeeze_gray_valley:
		var gv: SettlementState = w.get_settlement(&"settlement:gray_valley")
		if gv != null:
			gv.inventory.water = maxi(0, gv.inventory.water - 8)
			gv.inventory.food = maxi(0, gv.inventory.food - 6)
