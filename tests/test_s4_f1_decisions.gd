extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-F1 AUTONOMOUS DECISION AUTHORITY (G2-lite)
# ==============================================================================
#   F1: Closed Action Space   (only STAY / MIGRATE; everything else fail-closed)
#   F2: Observation Boundary  (the engine sees a projection, never the world)
#   F3: Deterministic Decision(same observation -> same intent, always)
#   F4: No Direct Mutation    (deciding changes nothing by itself)
#   F5: Atomic Action Commit  (MIGRATE goes through the S4-B transaction)
#   F6: Batch Determinism     (canonical order; no interleaved observation)
#   F7: Structured Evidence   (auditable, no chain of thought)
#   F8: Replay / Independent Verification
#
# WHAT THIS SLICE IS FOR:
#   Mara looks at Gray Valley, sees that it is genuinely bad, and decides to
#   leave. Not an LLM hallucination. Not the macro engine quietly picking her.
#   Her own decision, on the physical road the world already had.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S4-F1 AUTONOMOUS DECISION AUTHORITY (G2-lite)        ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F1] Closed Action Space ---")

	if NpcDecisionEngine.AUTHORIZED_ACTIONS.size() != 2:
		print("FAIL F1: the S4-F1 action space must contain exactly STAY and MIGRATE")
		quit(1)
		return
	for a in [NpcDecisionEngine.Action.STAY, NpcDecisionEngine.Action.MIGRATE]:
		if not NpcDecisionEngine.is_authorized_action(a):
			print("FAIL F1: %s is not authorized!" % NpcDecisionEngine.action_name(a))
			quit(1)
			return
	# Anything outside the registry is refused. These are the verbs deliberately
	# NOT in S4-F1 because each would force a new authority into existence.
	for forbidden in [2, 3, 7, 99, -1]:
		if NpcDecisionEngine.is_authorized_action(forbidden):
			print("FAIL F1: action value %d was authorized!" % forbidden)
			quit(1)
			return
	print("  Action space is exactly [STAY, MIGRATE]; values 2,3,7,99,-1 all refused")

	# An intent carrying an out-of-space action cannot be authorized.
	var obs := make_observation(90.0, 10.0, 80.0, true)
	var bogus := NpcDecisionIntent.create(obs, [0, 1], 7, &"RULE_FAKE", &"settlement:new_hope")
	var auth := NpcDecisionEngine.authorize(bogus)
	if not auth.begins_with("UNAUTHORIZED_ACTION"):
		print("FAIL F1: out-of-space action was authorized: '%s'" % auth)
		quit(1)
		return
	print("  Authorization refuses an out-of-space action: %s" % auth.split(":")[0])

	# Selecting an action that was not eligible is also refused.
	var calm := make_observation(5.0, 5.0, 95.0, true)
	var ineligible := NpcDecisionIntent.create(calm, [0], NpcDecisionEngine.Action.MIGRATE, &"RULE_X", &"settlement:new_hope")
	if not NpcDecisionEngine.authorize(ineligible).begins_with("INELIGIBLE_ACTION"):
		print("FAIL F1: an ineligible action was authorized!")
		quit(1)
		return
	print("  Authorization refuses a selected-but-ineligible action")
	print("PASS GATE F1: Closed Action Space verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F2] Observation Boundary ---")

	# The decision functions take an observation, never a WorldState. Verified
	# structurally by reading the source: a world reference would have to appear
	# in a signature for the engine to reach settlements, events or other NPCs.
	var src := FileAccess.get_file_as_string("res://simulation/npc_decision_engine.gd")
	for leak in ["WorldState", "world.", "npc_registry", "event_log", "settlements"]:
		if src.findn("func ") != -1 and src.findn(leak) != -1:
			# Allow the word inside comments; flag it inside any signature.
			for line in src.split("\n"):
				var trimmed := line.strip_edges()
				if trimmed.begins_with("func ") and trimmed.findn(leak) != -1:
					print("FAIL F2: decision engine signature reaches '%s': %s" % [leak, trimmed])
					quit(1)
					return
	print("  No decision-engine function signature accepts WorldState or any registry")

	var fields := obs.to_dict()
	var allowed := ["npc_id", "day", "current_settlement_id", "water_pressure",
		"food_pressure", "security", "candidate_destinations"]
	for k in fields:
		if not allowed.has(String(k)):
			print("FAIL F2: observation exposes unexpected field '%s'" % String(k))
			quit(1)
			return
	print("  Observation exposes exactly: %s" % str(allowed))
	print("  (no world.settlements, no event ledger, no other NPC states, no future)")
	print("PASS GATE F2: Observation Boundary verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F3] Deterministic Decision ---")

	var severe := make_observation(82.0, 10.0, 18.0, true)
	var first := NpcDecisionEngine.decide(severe)
	for i in range(200):
		var again := NpcDecisionEngine.decide(make_observation(82.0, 10.0, 18.0, true))
		if again.action != first.action or again.rule_invoked != first.rule_invoked or again.destination_id != first.destination_id:
			print("FAIL F3: identical observations produced different intents!")
			quit(1)
			return
	print("  200 evaluations of one observation produced one identical intent")
	print("  %s -> %s (rule %s)" % [
		"water=82 food=10 security=18",
		NpcDecisionEngine.action_name(first.action),
		first.rule_invoked
	])

	# Rule coverage, each a distinct recorded reason.
	var cases := [
		[make_observation(5.0, 5.0, 95.0, true), NpcDecisionEngine.Action.STAY, NpcDecisionEngine.RULE_STAY_DEFAULT, "calm settlement"],
		[make_observation(82.0, 5.0, 95.0, true), NpcDecisionEngine.Action.MIGRATE, NpcDecisionEngine.RULE_SEVERE_LOCAL_DEPRIVATION, "water pressure 82"],
		[make_observation(5.0, 77.0, 95.0, true), NpcDecisionEngine.Action.MIGRATE, NpcDecisionEngine.RULE_SEVERE_LOCAL_DEPRIVATION, "food pressure 77"],
		[make_observation(5.0, 5.0, 12.0, true), NpcDecisionEngine.Action.MIGRATE, NpcDecisionEngine.RULE_LOCAL_SECURITY_COLLAPSE, "security 12"],
		[make_observation(90.0, 90.0, 5.0, false), NpcDecisionEngine.Action.STAY, NpcDecisionEngine.RULE_NO_VIABLE_DESTINATION, "nowhere to go"],
	]
	for case in cases:
		var intent := NpcDecisionEngine.decide(case[0])
		if intent.action != case[1] or intent.rule_invoked != case[2]:
			print("FAIL F3: %s -> %s/%s, expected %s/%s" % [
				case[3], NpcDecisionEngine.action_name(intent.action), intent.rule_invoked,
				NpcDecisionEngine.action_name(case[1]), case[2]
			])
			quit(1)
			return
		print("  %-22s -> %-7s (%s)" % [case[3], NpcDecisionEngine.action_name(intent.action), intent.rule_invoked])
	print("  A desperate NPC with nowhere to go STAYS, and the reason is recorded distinctly")
	print("PASS GATE F3: Deterministic Decision verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F4] No Direct Mutation ---")

	var w4 := build_world_with_npcs(3)
	run_days(w4, 1, true)
	var before_hash := w4.to_canonical_json().sha256_text()

	# Observing and deciding, on their own, must change nothing at all.
	var engine4 := SimulationEngine.new()
	var probe_obs := engine4.build_npc_observation(w4, &"npc:00000001", w4.current_day)
	for i in range(50):
		NpcDecisionEngine.decide(probe_obs)
		NpcDecisionEngine.eligible_actions(probe_obs)
		NpcDecisionEngine.authorize(NpcDecisionEngine.decide(probe_obs))
	if w4.to_canonical_json().sha256_text() != before_hash:
		print("FAIL F4: observing/deciding mutated the world!")
		quit(1)
		return
	print("  50 observe+decide+authorize cycles: world hash unchanged")
	print("  Decision layer holds no mutation path; committing belongs to the engine")
	print("PASS GATE F4: No Direct Mutation verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F5] Atomic Action Commit ---")

	var w5 := build_world_with_npcs(1)
	var gv: SettlementState = w5.get_settlement(&"settlement:gray_valley")
	var pop_before: int = gv.population
	var total_before := life_total(w5)

	# Starve Gray Valley until Mara decides for herself to leave.
	var migrated_day := -1
	for day in range(60):
		run_days(w5, 1, true)
		var ls: NpcLifeState = w5.npc_life_state_registry.get_life_state(&"npc:00000001")
		if ls.status == NpcLifeState.Status.IN_TRANSIT:
			migrated_day = w5.current_day
			break
	if migrated_day < 0:
		print("FAIL F5: Mara never decided to migrate under sustained deprivation!")
		quit(1)
		return

	var ls_after: NpcLifeState = w5.npc_life_state_registry.get_life_state(&"npc:00000001")
	if ls_after.population_container_type != NpcLifeState.ContainerType.REFUGEE_PARTY:
		print("FAIL F5: Mara is IN_TRANSIT but not inside a refugee party!")
		quit(1)
		return
	var party: RefugeePartyState = w5.get_refugee_party(ls_after.population_container_id)
	if party == null:
		print("FAIL F5: Mara references a party that does not exist!")
		quit(1)
		return
	if gv.population != pop_before - 1 + gv.cumulative_deaths * 0:
		pass  # population also moves for other reasons; conservation is the real check
	if life_total(w5) != total_before:
		print("FAIL F5: life conservation broken by an autonomous migration: %d != %d" % [
			life_total(w5), total_before
		])
		quit(1)
		return
	print("  Day %d: Mara decided to leave Gray Valley for %s" % [migrated_day, party.destination_id])
	print("  She is IN_TRANSIT inside party %s (headcount %d)" % [party.id, party.headcount])
	print("  Life conservation intact: %d == %d" % [life_total(w5), total_before])

	# The committed fact is in the ledger, and it is HER event.
	var found := false
	for evt in w5.event_log:
		if evt.type == "NAMED_NPC_MIGRATION_STARTED" and evt.actor_id == &"npc:00000001":
			found = true
			if not evt.payload.has("rule_invoked"):
				print("FAIL F5: committed event lacks the rule that produced it!")
				quit(1)
				return
	if not found:
		print("FAIL F5: no committed NAMED_NPC_MIGRATION_STARTED event for Mara!")
		quit(1)
		return
	print("  Committed event NAMED_NPC_MIGRATION_STARTED recorded with its rule")

	var engine5 := SimulationEngine.new()
	if engine5.validate_invariants(w5) != "":
		print("FAIL F5: invariants violated after an autonomous migration: %s" % engine5.validate_invariants(w5))
		quit(1)
		return
	print("  Engine invariants PASS after the autonomous departure")
	print("PASS GATE F5: Atomic Action Commit verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F6] Batch Determinism ---")

	# Several NPCs deciding on the same day must all see the SAME start-of-phase
	# world, not a world their neighbours have already changed.
	var w6a := build_world_with_npcs(3)
	var w6b := build_world_with_npcs(3)
	run_days(w6a, 40, true)
	run_days(w6b, 40, true)
	if w6a.to_canonical_json().sha256_text() != w6b.to_canonical_json().sha256_text():
		print("FAIL F6: two identical multi-NPC runs diverged!")
		quit(1)
		return
	print("  Two identical 3-NPC, 40-day runs produced identical worlds")

	var same_day_batch := 0
	var by_day := {}
	for ev in w6a.decision_audit_trail:
		by_day[ev.day] = by_day.get(ev.day, 0) + 1
		if by_day[ev.day] > 1:
			same_day_batch = maxi(same_day_batch, by_day[ev.day])
	if same_day_batch < 2:
		print("FAIL F6: no day had multiple NPCs deciding — the gate would be vacuous!")
		quit(1)
		return
	print("  At least %d NPCs decided on the same day (batch semantics exercised)" % same_day_batch)

	# Every NPC that decided on a given day observed the same settlement state.
	var per_day_view := {}
	for ev in w6a.decision_audit_trail:
		var key := "%d|%s" % [ev.day, String(ev.observed_state.get("current_settlement_id", ""))]
		var view := "%s|%s|%s" % [
			str(ev.observed_state.get("water_pressure", 0.0)),
			str(ev.observed_state.get("food_pressure", 0.0)),
			str(ev.observed_state.get("security", 0.0))
		]
		if per_day_view.has(key) and per_day_view[key] != view:
			print("FAIL F6: NPCs in the same settlement on day %d observed different worlds!" % ev.day)
			print("    %s vs %s" % [per_day_view[key], view])
			quit(1)
			return
		per_day_view[key] = view
	print("  NPCs in one settlement on one day all observed an identical snapshot")
	print("  (no interleaving: nobody saw a world an earlier decision had altered)")

	# Evaluation order is canonical npc_id order, never container order.
	var last_seen := ""
	var current_day_marker := -1
	for ev in w6a.decision_audit_trail:
		if ev.day != current_day_marker:
			current_day_marker = ev.day
			last_seen = ""
		if last_seen != "" and String(ev.npc_id) < last_seen:
			print("FAIL F6: decisions on day %d are not in canonical npc_id order!" % ev.day)
			quit(1)
			return
		last_seen = String(ev.npc_id)
	print("  Decisions are recorded in canonical npc_id order on every day")
	print("PASS GATE F6: Batch Determinism verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F7] Structured Evidence ---")

	if w6a.get_decision_count() == 0:
		print("FAIL F7: no decision evidence was recorded!")
		quit(1)
		return
	var committed := 0
	var no_ops := 0
	var rejected := 0
	for ev in w6a.decision_audit_trail:
		for field in [ev.phase, ev.selected_action, String(ev.rule_invoked)]:
			if field == "":
				print("FAIL F7: evidence has an empty required field!")
				quit(1)
				return
		if ev.eligible_actions.is_empty():
			print("FAIL F7: evidence records no eligible actions!")
			quit(1)
			return
		if not ev.eligible_actions.has(ev.selected_action):
			print("FAIL F7: selected action was not among the eligible ones!")
			quit(1)
			return
		match ev.result:
			NpcDecisionEvidence.Result.COMMITTED: committed += 1
			NpcDecisionEvidence.Result.NO_OP: no_ops += 1
			NpcDecisionEvidence.Result.REJECTED: rejected += 1
	print("  %d evidence records: %d COMMITTED, %d NO_OP, %d REJECTED" % [
		w6a.get_decision_count(), committed, no_ops, rejected
	])

	# A committed decision points at its event; a non-committed one points at none.
	for ev in w6a.decision_audit_trail:
		if ev.result == NpcDecisionEvidence.Result.COMMITTED:
			if ev.committed_event_index < 0 or ev.committed_event_index >= w6a.event_log.size():
				print("FAIL F7: COMMITTED evidence has no valid event reference!")
				quit(1)
				return
			var referenced: EventRecord = w6a.event_log[ev.committed_event_index]
			if referenced.actor_id != ev.npc_id:
				print("FAIL F7: evidence references an event belonging to someone else!")
				quit(1)
				return
		elif ev.committed_event_index != -1:
			print("FAIL F7: a non-committed decision references a world event!")
			quit(1)
			return
	print("  Every COMMITTED record resolves to that NPC's own ledger event")
	print("  No REJECTED or NO_OP record references a world event")

	# The trail is structured evidence, not a chain of thought.
	var trail_json := JSON.stringify(w6a.to_dict()["decision_audit_trail"])
	for cot in ["reasoning", "thought", "because I", "I think", "chain_of_thought", "explanation"]:
		if trail_json.findn(cot) != -1:
			print("FAIL F7: chain-of-thought text '%s' found in the audit trail!" % cot)
			quit(1)
			return
	print("  No chain-of-thought text anywhere in the trail")

	# A rejected intent must never read as a world fact.
	for ev in w6a.decision_audit_trail:
		if ev.result == NpcDecisionEvidence.Result.REJECTED:
			for evt in w6a.event_log:
				if evt.day == ev.day and evt.actor_id == ev.npc_id and evt.type == "NAMED_NPC_MIGRATION_STARTED":
					print("FAIL F7: a REJECTED intent also produced a world event!")
					quit(1)
					return
	print("  Rejected intents left no trace in the committed event ledger")
	print("PASS GATE F7: Structured Evidence verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE F8] Replay / Independent Verification ---")

	var restored := WorldState.from_json(JSON.stringify(w6a.to_dict()))
	if restored == null:
		print("FAIL F8: loader refused a snapshot with a decision trail!")
		quit(1)
		return
	if restored.to_canonical_json().sha256_text() != w6a.to_canonical_json().sha256_text():
		print("FAIL F8: round-trip hash mismatch with decisions present!")
		quit(1)
		return
	if restored.get_decision_count() != w6a.get_decision_count():
		print("FAIL F8: decision trail lost across persistence!")
		quit(1)
		return
	print("  Round-trip SHA identical; %d decision records preserved" % restored.get_decision_count())

	# Continuing a reloaded world must produce the same decisions as never saving.
	var cont_a := build_world_with_npcs(3)
	run_days(cont_a, 30, true)
	var cont_b := WorldState.from_json(JSON.stringify(cont_a.to_dict()))
	run_days(cont_a, 30, true)
	run_days(cont_b, 30, true)
	if cont_a.to_canonical_json().sha256_text() != cont_b.to_canonical_json().sha256_text():
		print("FAIL F8: save/load changed later autonomous decisions!")
		quit(1)
		return
	var trail_a := JSON.stringify(cont_a.to_dict()["decision_audit_trail"]).sha256_text()
	var trail_b := JSON.stringify(cont_b.to_dict()["decision_audit_trail"]).sha256_text()
	if trail_a != trail_b:
		print("FAIL F8: decision trails diverged after a save/load!")
		quit(1)
		return
	print("  Interrupted and uninterrupted runs made the SAME decisions to Day 60")
	print("  Decision trail SHA: %s" % trail_a)

	var f := FileAccess.open("res://artifacts/world_snapshot_s4f1.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(w6a.to_dict(), "\t", true))
		f.close()
		print("  Exported artifacts/world_snapshot_s4f1.json for independent validation.")
	print("PASS GATE F8: Replay / Independent Verification verified.")

	print("\n================================================================================")
	print("ALL S4-F1 AUTONOMOUS DECISION GATES (F1 ~ F8) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Helpers
# ==============================================================================

func make_observation(water: float, food: float, security: float, has_destination: bool) -> NpcDecisionObservation:
	var candidates: Array = []
	if has_destination:
		candidates.append({
			"settlement_id": "settlement:new_hope",
			"route_days": 3,
			"water_pressure": 0.0,
			"food_pressure": 0.0,
			"security": 90.0,
		})
	return NpcDecisionObservation.create(
		&"npc:00000001", 1, &"settlement:gray_valley", water, food, security, candidates
	)

func life_total(w: WorldState) -> int:
	var total := 0
	for s_id in w.settlements:
		var s: SettlementState = w.settlements[s_id]
		total += s.population + s.cumulative_deaths
	for r_id in w.refugees:
		var r: RefugeePartyState = w.refugees[r_id]
		if r.is_active and not r.is_arrived:
			total += r.headcount
	return total

func build_world_with_npcs(count: int) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var names := ["Mara", "Eli", "Jon", "Tess", "Bram"]
	for i in range(count):
		var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 28 + i)
		var nid: StringName = res["npc"].id
		w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
		w.npc_profile_registry.assign_background(w, nid, NpcProfile.Background.CARAVAN_GUARD)
	return w

# Drives the world forward, optionally squeezing Gray Valley so that living
# there genuinely becomes untenable and the decision is about the real world.
func run_days(w: WorldState, days: int, squeeze: bool) -> void:
	var engine := SimulationEngine.new()
	var gv: SettlementState = w.get_settlement(&"settlement:gray_valley")
	for i in range(days):
		engine.tick(w)
		if squeeze:
			gv.inventory.water = maxi(0, gv.inventory.water - 8)
			gv.inventory.food = maxi(0, gv.inventory.food - 6)
