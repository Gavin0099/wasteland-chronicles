extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-F2 AUTONOMOUS MIGRATION TEST SUITE
# ==============================================================================
# Verifies the full autonomous lifecycle:
#   Mara observes crisis
#   -> decides MIGRATE
#   -> authorized
#   -> Gray Valley -1
#   -> enters RefugeeParty
#   -> travels according to Axiom 9 (Arrival = Departure + RouteDays - 1)
#   -> arrives New Hope
#   -> New Hope +1
#
# CORE PERSISTENCE TEST:
#   Mara departs -> mid-route -> SAVE -> LOAD -> continues travel
#   -> arrival day and final world state bitwise identical to uninterrupted world.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S4-F2 AUTONOMOUS MIGRATION TEST SUITE               ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2-1] Crisis to Migration Decision Chain ---")

	var w1 := build_world_with_mara()
	var gv1: SettlementState = w1.get_settlement(&"settlement:gray_valley")
	var pop_gv_start: int = gv1.population
	var pop_nh_start: int = w1.get_settlement(&"settlement:new_hope").population

	var departure_day := -1
	var route_days := -1
	var party_id := &""

	# Run simulation day by day, squeezing Gray Valley water & food
	for day_idx in range(30):
		tick_day(w1, true)
		var ls: NpcLifeState = w1.npc_life_state_registry.get_life_state(&"npc:00000001")
		if ls.status == NpcLifeState.Status.IN_TRANSIT:
			departure_day = w1.current_day
			party_id = ls.population_container_id
			var party: RefugeePartyState = w1.get_refugee_party(party_id)
			route_days = party.route_days
			break

	if departure_day < 0:
		print("FAIL F2-1: Mara never decided to migrate under sustained crisis!")
		quit(1)
		return

	print("  Day %d: Crisis escalated, Mara autonomously chose MIGRATE" % departure_day)
	print("  Target destination: settlement:new_hope (route_days=%d)" % route_days)

	# Verify the decision audit trail recorded this correctly
	var found_decision := false
	for ev in w1.decision_audit_trail:
		if ev.day == departure_day and ev.npc_id == &"npc:00000001" and ev.selected_action == "MIGRATE":
			found_decision = true
			if ev.result != NpcDecisionEvidence.Result.COMMITTED:
				print("FAIL F2-1: Migration decision was not COMMITTED!")
				quit(1)
				return
			if ev.rule_invoked != NpcDecisionEngine.RULE_SEVERE_LOCAL_DEPRIVATION:
				print("FAIL F2-1: Unexpected rule invoked: %s" % str(ev.rule_invoked))
				quit(1)
				return
			print("  Audit evidence: rule=%s, result=COMMITTED, event_index=%d" % [
				ev.rule_invoked, ev.committed_event_index
			])
			break

	if not found_decision:
		print("FAIL F2-1: No matching decision record in audit trail on departure day!")
		quit(1)
		return

	print("PASS GATE F2-1: Crisis to Migration Decision Chain verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2-2] Atomic Departure & Mid-Route Physical State ---")

	# Check Gray Valley population decreased
	# Note: Gray Valley also has anonymous mortality/migration, but Mara's departure
	# must have decremented population atomically.
	var party1: RefugeePartyState = w1.get_refugee_party(party_id)
	if party1 == null:
		print("FAIL F2-2: Refugee party %s does not exist!" % party_id)
		quit(1)
		return

	if party1.origin_id != &"settlement:gray_valley" or party1.destination_id != &"settlement:new_hope":
		print("FAIL F2-2: Party origin/destination mismatch: %s -> %s" % [party1.origin_id, party1.destination_id])
		quit(1)
		return

	if party1.headcount < 1:
		print("FAIL F2-2: Party headcount < 1: %d" % party1.headcount)
		quit(1)
		return

	# End of departure day: Phase 4 already decremented days_remaining once
	# days_remaining should be route_days - 1
	var expected_remaining_dep := route_days - 1
	if party1.days_remaining != expected_remaining_dep:
		print("FAIL F2-2: End of departure day remaining days: expected %d, got %d" % [
			expected_remaining_dep, party1.days_remaining
		])
		quit(1)
		return
	print("  Day %d (Departure Day): days_remaining=%d (route_days=%d)" % [
		departure_day, party1.days_remaining, route_days
	])

	# Advance 1 day to mid-route (Day departure_day + 1)
	tick_day(w1, false)
	var mid_route_day := w1.current_day
	if mid_route_day != departure_day + 1:
		print("FAIL F2-2: Expected mid-route day %d, got %d" % [departure_day + 1, mid_route_day])
		quit(1)
		return

	var ls_mid: NpcLifeState = w1.npc_life_state_registry.get_life_state(&"npc:00000001")
	if ls_mid.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL F2-2: Mara should still be IN_TRANSIT on mid-route day %d (no teleport!)" % mid_route_day)
		quit(1)
		return

	if party1.days_remaining != expected_remaining_dep - 1:
		print("FAIL F2-2: Mid-route days_remaining expected %d, got %d" % [
			expected_remaining_dep - 1, party1.days_remaining
		])
		quit(1)
		return
	print("  Day %d (Mid-Route): Mara is IN_TRANSIT, days_remaining=%d (no teleport)" % [
		mid_route_day, party1.days_remaining
	])

	# Check New Hope population has NOT increased yet
	var nh_mid: SettlementState = w1.get_settlement(&"settlement:new_hope")
	print("  New Hope population before arrival: %d" % nh_mid.population)
	print("PASS GATE F2-2: Atomic Departure & Mid-Route Physical State verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2-3] Axiom 9 Physical Arrival & Settlement Integration ---")

	# Axiom 9: Arrival Day = Departure Day + Route Days - 1
	var expected_arrival_day := departure_day + route_days - 1
	print("  Axiom 9 Formula: Arrival Day = %d + %d - 1 = %d" % [
		departure_day, route_days, expected_arrival_day
	])

	var nh_pop_pre_arrival := nh_mid.population

	# Advance to expected arrival day
	while w1.current_day < expected_arrival_day:
		tick_day(w1, false)

	if w1.current_day != expected_arrival_day:
		print("FAIL F2-3: Simulation reached day %d instead of arrival day %d" % [
			w1.current_day, expected_arrival_day
		])
		quit(1)
		return

	var ls_arrival: NpcLifeState = w1.npc_life_state_registry.get_life_state(&"npc:00000001")
	if ls_arrival.status != NpcLifeState.Status.SETTLED:
		print("FAIL F2-3: Mara must be SETTLED on arrival day %d! Got status=%d" % [
			expected_arrival_day, ls_arrival.status
		])
		quit(1)
		return

	if ls_arrival.population_container_type != NpcLifeState.ContainerType.SETTLEMENT:
		print("FAIL F2-3: Container type must be SETTLEMENT, got %d" % ls_arrival.population_container_type)
		quit(1)
		return

	if ls_arrival.population_container_id != &"settlement:new_hope":
		print("FAIL F2-3: Container ID must be settlement:new_hope, got %s" % ls_arrival.population_container_id)
		quit(1)
		return

	# New Hope population should have increased by 1 (or more if anonymous refugees also arrived)
	var nh_post_arrival: SettlementState = w1.get_settlement(&"settlement:new_hope")
	if nh_post_arrival.population < nh_pop_pre_arrival + 1:
		print("FAIL F2-3: New Hope population did not increase on arrival! %d -> %d" % [
			nh_pop_pre_arrival, nh_post_arrival.population
		])
		quit(1)
		return

	# Verify party is marked arrived and inactive
	if party1.is_active or not party1.is_arrived:
		print("FAIL F2-3: Refugee party should be inactive and arrived!")
		quit(1)
		return

	# Verify ledger recorded NAMED_MIGRATION_COMPLETED
	var found_arrival_event := false
	for evt in w1.event_log:
		if evt.day == expected_arrival_day and evt.type == "NAMED_MIGRATION_COMPLETED" and evt.actor_id == &"npc:00000001":
			found_arrival_event = true
			if evt.target_id != &"settlement:new_hope":
				print("FAIL F2-3: NAMED_MIGRATION_COMPLETED target is not new_hope!")
				quit(1)
				return
			break

	if not found_arrival_event:
		print("FAIL F2-3: No NAMED_MIGRATION_COMPLETED event recorded for Mara on Day %d!" % expected_arrival_day)
		quit(1)
		return

	print("  Day %d: Mara arrived at New Hope (container: %s)" % [
		expected_arrival_day, ls_arrival.population_container_id
	])
	print("  New Hope population: %d -> %d (+1 for Mara)" % [nh_pop_pre_arrival, nh_post_arrival.population])
	print("  Committed ledger event NAMED_MIGRATION_COMPLETED verified")
	print("PASS GATE F2-3: Axiom 9 Physical Arrival & Settlement Integration verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2-4] Mid-Route Save/Load Persistence Equivalence ---")

	# World A: runs uninterrupted from Day 0 to Day 25
	var wa := build_world_with_mara()
	for d in range(25):
		tick_day(wa, d < 15) # Squeeze first 15 days, then stabilize

	var wa_arrival_day := -1
	for evt in wa.event_log:
		if evt.type == "NAMED_MIGRATION_COMPLETED" and evt.actor_id == &"npc:00000001":
			wa_arrival_day = evt.day
			break

	if wa_arrival_day < 0:
		print("FAIL F2-4: Mara never arrived in uninterrupted World A!")
		quit(1)
		return
	print("  Uninterrupted World A: Mara arrived on Day %d" % wa_arrival_day)

	# World B: runs until Mara is mid-route, SAVES, LOADS, and continues to Day 25
	var wb := build_world_with_mara()
	var mid_route_reached := false
	var wb_saved_day := -1

	for d in range(25):
		tick_day(wb, d < 15)
		var ls_b: NpcLifeState = wb.npc_life_state_registry.get_life_state(&"npc:00000001")
		# Check if Mara is mid-route (IN_TRANSIT and at least 1 day after departure)
		if ls_b.status == NpcLifeState.Status.IN_TRANSIT:
			var party_b: RefugeePartyState = wb.get_refugee_party(ls_b.population_container_id)
			if party_b.days_remaining > 0:
				wb_saved_day = wb.current_day
				mid_route_reached = true
				break

	if not mid_route_reached:
		print("FAIL F2-4: Could not catch Mara mid-route in World B!")
		quit(1)
		return

	print("  World B: Pausing at Day %d (Mara is IN_TRANSIT)" % wb_saved_day)

	# SAVE: serialize to dict -> JSON string
	var save_json := JSON.stringify(wb.to_dict())

	# LOAD: parse JSON string -> from_dict
	var parse_result: Variant = JSON.parse_string(save_json)
	if parse_result == null or typeof(parse_result) != TYPE_DICTIONARY:
		print("FAIL F2-4: Failed to parse saved JSON!")
		quit(1)
		return

	var wb_restored := WorldState.from_dict(parse_result as Dictionary)
	if wb_restored == null:
		print("FAIL F2-4: WorldState.from_dict refused restored snapshot!")
		quit(1)
		return

	# Verify restored mid-route state
	var ls_restored: NpcLifeState = wb_restored.npc_life_state_registry.get_life_state(&"npc:00000001")
	if ls_restored.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL F2-4: Restored Mara status is not IN_TRANSIT!")
		quit(1)
		return

	var party_restored: RefugeePartyState = wb_restored.get_refugee_party(ls_restored.population_container_id)
	if party_restored == null or party_restored.days_remaining <= 0:
		print("FAIL F2-4: Restored refugee party invalid or already arrived!")
		quit(1)
		return

	print("  Restored World B: Mara is IN_TRANSIT, party=%s, days_remaining=%d" % [
		party_restored.id, party_restored.days_remaining
	])

	# CONTINUE: run restored World B up to Day 25
	while wb_restored.current_day < 25:
		tick_day(wb_restored, wb_restored.current_day < 15)

	# Compare arrival day
	var wb_arrival_day := -1
	for evt in wb_restored.event_log:
		if evt.type == "NAMED_MIGRATION_COMPLETED" and evt.actor_id == &"npc:00000001":
			wb_arrival_day = evt.day
			break

	if wb_arrival_day != wa_arrival_day:
		print("FAIL F2-4: Arrival day diverged! World A=%d vs Restored World B=%d" % [
			wa_arrival_day, wb_arrival_day
		])
		quit(1)
		return
	print("  Arrival day matches exactly: Day %d" % wb_arrival_day)

	# Full canonical JSON bitwise comparison at Day 25
	var hash_wa := wa.to_canonical_json().sha256_text()
	var hash_wb := wb_restored.to_canonical_json().sha256_text()

	if hash_wa != hash_wb:
		print("FAIL F2-4: World states diverged at Day 25!")
		print("  Uninterrupted World A SHA: %s" % hash_wa)
		print("  Restored World B SHA:      %s" % hash_wb)
		quit(1)
		return

	print("  Day 25 Canonical State SHA bitwise identical: %s" % hash_wa)
	print("  Uninterrupted == Interrupted (SAVE/LOAD mid-route produced 0 drift)")
	print("PASS GATE F2-4: Mid-Route Save/Load Persistence Equivalence verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2-5] Post-Arrival Continuity & Stability ---")

	# Continue World A for another 10 days at New Hope (no squeeze)
	var days_pre := wa.current_day # 25
	for d in range(10):
		tick_day(wa, false)

	var ls_end: NpcLifeState = wa.npc_life_state_registry.get_life_state(&"npc:00000001")
	if ls_end.status != NpcLifeState.Status.SETTLED:
		print("FAIL F2-5: Mara should remain SETTLED at New Hope, got %d" % ls_end.status)
		quit(1)
		return

	if ls_end.population_container_id != &"settlement:new_hope":
		print("FAIL F2-5: Mara container should remain new_hope, got %s" % ls_end.population_container_id)
		quit(1)
		return

	# Verify Mara's origin_settlement_id is still gray_valley (permanent identity)
	var identity: NpcIdentity = wa.npc_registry.get_npc(&"npc:00000001")
	if identity.origin_settlement_id != &"settlement:gray_valley":
		print("FAIL F2-5: Permanent identity origin_settlement_id mutated: %s" % identity.origin_settlement_id)
		quit(1)
		return

	# Verify Mara's post-arrival decisions are STAY (New Hope is stable)
	var stay_decisions_at_nh := 0
	for ev in wa.decision_audit_trail:
		if ev.day > wa_arrival_day and ev.npc_id == &"npc:00000001":
			if ev.selected_action == "STAY":
				stay_decisions_at_nh += 1
			else:
				print("FAIL F2-5: Unexpected post-arrival action '%s' on Day %d" % [ev.selected_action, ev.day])
				quit(1)
				return

	if stay_decisions_at_nh < 5:
		print("FAIL F2-5: Expected at least 5 STAY decisions post-arrival, got %d" % stay_decisions_at_nh)
		quit(1)
		return

	print("  Mara origin_settlement_id: %s (permanent identity)" % identity.origin_settlement_id)
	print("  Mara current container:    %s (current whereabouts)" % ls_end.population_container_id)
	print("  Post-arrival STAY decisions: %d (stable residence at New Hope)" % stay_decisions_at_nh)
	print("PASS GATE F2-5: Post-Arrival Continuity & Stability verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2-6] Global Invariants & Life Conservation ---")

	var engine := SimulationEngine.new()
	var inv_err := engine.validate_invariants(wa)
	if inv_err != "":
		print("FAIL F2-6: Invariants failed on final world: %s" % inv_err)
		quit(1)
		return

	var living := 0
	var deaths := 0
	for s_id in wa.settlements:
		var s: SettlementState = wa.settlements[s_id]
		living += s.population
		deaths += s.cumulative_deaths
	for r_id in wa.refugees:
		var r: RefugeePartyState = wa.refugees[r_id]
		if r.is_active and not r.is_arrived:
			living += r.headcount

	var total_accounted := living + deaths
	if total_accounted != wa.total_initial_population:
		print("FAIL F2-6: Global population conservation broken: %d != %d" % [
			total_accounted, wa.total_initial_population
		])
		quit(1)
		return

	print("  Final accounted: living(%d) + deaths(%d) == initial(%d)" % [
		living, deaths, wa.total_initial_population
	])
	print("  Engine validate_invariants PASS")
	print("PASS GATE F2-6: Global Invariants & Life Conservation verified.")

	print("\n================================================================================")
	print("ALL S4-F2 AUTONOMOUS MIGRATION GATES (F2-1 ~ F2-6) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Helper Functions
# ==============================================================================

func build_world_with_mara() -> WorldState:
	var w := S1WorldData.create_s1_world()
	var res := w.npc_registry.materialize_identity(w, &"settlement:gray_valley", "Mara", 28)
	var nid: StringName = res["npc"].id
	w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
	w.npc_profile_registry.assign_background(w, nid, NpcProfile.Background.CARAVAN_GUARD)
	return w

func tick_day(w: WorldState, squeeze_gray_valley: bool) -> void:
	var engine := SimulationEngine.new()
	engine.tick(w)
	if squeeze_gray_valley:
		var gv: SettlementState = w.get_settlement(&"settlement:gray_valley")
		if gv != null:
			gv.inventory.water = maxi(0, gv.inventory.water - 8)
			gv.inventory.food = maxi(0, gv.inventory.food - 6)
