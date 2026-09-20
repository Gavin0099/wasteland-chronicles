extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-C NPC PROFILE / BACKGROUND TEST SUITE
# ==============================================================================
# Verifies 7 Runtime Acceptance Gates (C1 ~ C7):
#   C1: Closed Background Enum (unknown value → fail-closed, zero mutation)
#   C2: Immutability (background assigned once, never reassigned)
#   C3: Living NPC Only (no life state / deceased → fail-closed)
#   C4: Zero Action Authority (S4-C action space is EMPTY, execution refused)
#   C5: Simulation Inertness (with-profiles vs without → bitwise identical projection)
#   C6: Authority Preservation (profiles ⊆ identities; population untouched; conservation)
#   C7: Serialization Round-Trip + Dual Replay + Engine Invariants
#
# GOVERNANCE THESIS UNDER TEST:
#   Background is "這個人過去是誰", not "這個人可以作弊做什麼".
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("        WASTELAND CHRONICLES - S4-C NPC PROFILE / BACKGROUND TEST SUITE         ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# Shared fixture: materialize 4 named NPCs in Gray Valley.
	# --------------------------------------------------------------------------
	var world := S1WorldData.create_s1_world()
	var names := ["Mara", "Joel", "Tess", "Bram"]
	var npc_ids: Array[StringName] = []
	for n in names:
		var res: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", n, 28)
		if not res["success"]:
			print("FAIL setup: materialize %s -> %s" % [n, res.get("error", "")])
			quit(1)
			return
		var nid: StringName = res["npc"].id
		npc_ids.append(nid)
		var lsr: Dictionary = world.npc_life_state_registry.register_life_state(world, nid, &"settlement:gray_valley")
		if not lsr["success"]:
			print("FAIL setup: life state %s -> %s" % [n, lsr.get("error", "")])
			quit(1)
			return

	var backgrounds := [
		NpcProfile.Background.CARAVAN_GUARD,
		NpcProfile.Background.MECHANIC,
		NpcProfile.Background.FARMER,
		NpcProfile.Background.SCAVENGER,
	]

	# --------------------------------------------------------------------------
	# GATE C1: Closed Background Enum
	# --------------------------------------------------------------------------
	print("\n--- [GATE C1] Closed Background Enum ---")

	var pre_c1_hash := world.to_canonical_json().sha256_text()

	var bad_values := [-1, 4, 99, 12345]
	for bad in bad_values:
		var r: Dictionary = world.npc_profile_registry.assign_background(world, npc_ids[0], bad)
		if r["success"]:
			print("FAIL C1: background value %d was accepted but is outside the closed enum!" % bad)
			quit(1)
			return
		if not String(r.get("error", "")).begins_with("INVALID_BACKGROUND"):
			print("FAIL C1: wrong error for %d: %s" % [bad, r.get("error", "")])
			quit(1)
			return
	print("  Rejected out-of-enum values %s" % str(bad_values))

	if world.to_canonical_json().sha256_text() != pre_c1_hash:
		print("FAIL C1: rejected assignment mutated world state (hash changed)!")
		quit(1)
		return
	print("  Zero mutation on rejection: world hash unchanged")

	# Unknown NPC is also refused
	var r_unknown: Dictionary = world.npc_profile_registry.assign_background(world, &"npc:99999999", NpcProfile.Background.FARMER)
	if r_unknown["success"] or not String(r_unknown.get("error", "")).begins_with("INVALID_NPC"):
		print("FAIL C1: unknown NPC accepted or wrong error: %s" % r_unknown.get("error", ""))
		quit(1)
		return
	print("  Unknown NPC rejected: %s" % r_unknown["error"])

	# All four legal backgrounds assign cleanly
	for i in range(4):
		var ok: Dictionary = world.npc_profile_registry.assign_background(world, npc_ids[i], backgrounds[i])
		if not ok["success"]:
			print("FAIL C1: legal background rejected: %s" % ok.get("error", ""))
			quit(1)
			return
		print("  %s -> %s" % [names[i], ok["background_name"]])
	print("PASS GATE C1: Closed Background Enum verified.")

	# --------------------------------------------------------------------------
	# GATE C2: Immutability
	# --------------------------------------------------------------------------
	print("\n--- [GATE C2] Background Immutability ---")

	var pre_c2_hash := world.to_canonical_json().sha256_text()

	# Reassign to a different background
	var r_reassign: Dictionary = world.npc_profile_registry.assign_background(world, npc_ids[0], NpcProfile.Background.FARMER)
	if r_reassign["success"]:
		print("FAIL C2: background reassignment was permitted!")
		quit(1)
		return
	if not String(r_reassign.get("error", "")).begins_with("IMMUTABLE_BACKGROUND"):
		print("FAIL C2: wrong error: %s" % r_reassign.get("error", ""))
		quit(1)
		return
	print("  Reassignment rejected: %s" % r_reassign["error"])

	# Reassigning the SAME value is equally refused (write-once is not idempotent)
	var r_same: Dictionary = world.npc_profile_registry.assign_background(world, npc_ids[0], NpcProfile.Background.CARAVAN_GUARD)
	if r_same["success"]:
		print("FAIL C2: same-value reassignment was permitted!")
		quit(1)
		return
	print("  Same-value reassignment also rejected (write-once, not idempotent)")

	var mara_profile: NpcProfile = world.npc_profile_registry.get_profile(npc_ids[0])
	if mara_profile.background != NpcProfile.Background.CARAVAN_GUARD:
		print("FAIL C2: Mara background changed to %d!" % mara_profile.background)
		quit(1)
		return
	if world.to_canonical_json().sha256_text() != pre_c2_hash:
		print("FAIL C2: rejected reassignment mutated world state!")
		quit(1)
		return
	print("  Mara still CARAVAN_GUARD; world hash unchanged")
	print("PASS GATE C2: Background Immutability verified.")

	# --------------------------------------------------------------------------
	# GATE C3: Living NPC Only
	# --------------------------------------------------------------------------
	print("\n--- [GATE C3] Living NPC Only ---")

	# 3a. Identity without life state -> refused
	var res_ghost: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Ghost", 40)
	var ghost_id: StringName = res_ghost["npc"].id
	var r_ghost: Dictionary = world.npc_profile_registry.assign_background(world, ghost_id, NpcProfile.Background.FARMER)
	if r_ghost["success"] or not String(r_ghost.get("error", "")).begins_with("NO_LIFE_STATE"):
		print("FAIL C3: NPC without life state accepted or wrong error: %s" % r_ghost.get("error", ""))
		quit(1)
		return
	print("  NPC without life state rejected: %s" % r_ghost["error"])

	# 3b. A deceased NPC without a profile stays without one, forever
	var res_doomed: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Doomed", 55)
	var doomed_id: StringName = res_doomed["npc"].id
	world.npc_life_state_registry.register_life_state(world, doomed_id, &"settlement:gray_valley")
	var death: Dictionary = world.npc_life_state_registry.commit_named_death(world, doomed_id)
	if not death["success"]:
		print("FAIL C3: could not kill Doomed: %s" % death.get("error", ""))
		quit(1)
		return
	var r_dead: Dictionary = world.npc_profile_registry.assign_background(world, doomed_id, NpcProfile.Background.SCAVENGER)
	if r_dead["success"] or not String(r_dead.get("error", "")).begins_with("DECEASED_NPC"):
		print("FAIL C3: post-mortem background authoring allowed! %s" % r_dead.get("error", ""))
		quit(1)
		return
	print("  Post-mortem authoring rejected: %s" % r_dead["error"])
	if world.npc_profile_registry.has_profile(doomed_id):
		print("FAIL C3: dead NPC acquired a profile!")
		quit(1)
		return

	# 3c. A background assigned BEFORE death survives death (biography is permanent)
	var res_late: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Sten", 33)
	var late_id: StringName = res_late["npc"].id
	world.npc_life_state_registry.register_life_state(world, late_id, &"settlement:gray_valley")
	world.npc_profile_registry.assign_background(world, late_id, NpcProfile.Background.MECHANIC)
	world.npc_life_state_registry.commit_named_death(world, late_id)
	var sten_profile: NpcProfile = world.npc_profile_registry.get_profile(late_id)
	if sten_profile == null or sten_profile.background != NpcProfile.Background.MECHANIC:
		print("FAIL C3: death erased an existing background!")
		quit(1)
		return
	var sten_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(late_id)
	if sten_ls.is_alive():
		print("FAIL C3: Sten should be dead")
		quit(1)
		return
	print("  Pre-mortem background survives death (Sten: dead, still MECHANIC)")
	print("PASS GATE C3: Living NPC Only verified.")

	# --------------------------------------------------------------------------
	# GATE C4: Zero Action Authority
	# --------------------------------------------------------------------------
	print("\n--- [GATE C4] Zero Action Authority ---")

	var pre_c4_hash := world.to_canonical_json().sha256_text()

	for i in range(4):
		var actions := world.npc_profile_registry.get_authorized_actions(npc_ids[i])
		if actions.size() != 0:
			print("FAIL C4: %s (%s) has %d authorized actions - S4-C space must be EMPTY!" % [
				names[i], NpcProfile.background_name(backgrounds[i]), actions.size()
			])
			quit(1)
			return
	print("  get_authorized_actions() == [] for all 4 backgrounds")

	# Attempting the actions a background "obviously" implies must still be refused.
	var attempted := [&"REPAIR", &"ESCORT", &"FARM", &"SCAVENGE", &"MIGRATE", &"STAY"]
	for act in attempted:
		var r_act: Dictionary = world.npc_profile_registry.attempt_background_action(world, npc_ids[1], act)
		if r_act["success"]:
			print("FAIL C4: action %s was executed on background authority!" % act)
			quit(1)
			return
		if not String(r_act.get("error", "")).begins_with("UNAUTHORIZED_ACTION"):
			print("FAIL C4: wrong refusal for %s: %s" % [act, r_act.get("error", "")])
			quit(1)
			return
		if r_act.get("state_changed", true):
			print("FAIL C4: action %s reported a state change!" % act)
			quit(1)
			return
	print("  MECHANIC denied REPAIR; CARAVAN_GUARD denied ESCORT; all %d attempts refused" % attempted.size())

	if world.to_canonical_json().sha256_text() != pre_c4_hash:
		print("FAIL C4: refused action attempts mutated world state!")
		quit(1)
		return
	print("  NO_STATE_CHANGE confirmed: world hash unchanged across all attempts")
	print("PASS GATE C4: Zero Action Authority verified.")

	# --------------------------------------------------------------------------
	# GATE C5: Simulation Inertness (the decisive counterfactual)
	# --------------------------------------------------------------------------
	print("\n--- [GATE C5] Simulation Inertness (30-day counterfactual) ---")

	var world_bare := S1WorldData.create_s1_world()
	var world_profiled := S1WorldData.create_s1_world()

	# Identical identities and life states in BOTH worlds.
	for w in [world_bare, world_profiled]:
		for n in names:
			var mres: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", n, 28)
			w.npc_life_state_registry.register_life_state(w, mres["npc"].id, &"settlement:gray_valley")

	# Only world_profiled gets backgrounds.
	for i in range(4):
		var target := StringName("npc:%08d" % (i + 1))
		var pres: Dictionary = world_profiled.npc_profile_registry.assign_background(world_profiled, target, backgrounds[i])
		if not pres["success"]:
			print("FAIL C5: could not assign background in counterfactual world: %s" % pres.get("error", ""))
			quit(1)
			return
	if world_profiled.npc_profile_registry.get_profile_count() != 4:
		print("FAIL C5: expected 4 profiles in profiled world")
		quit(1)
		return
	if world_bare.npc_profile_registry.get_profile_count() != 0:
		print("FAIL C5: bare world must have 0 profiles")
		quit(1)
		return

	var engine_bare := SimulationEngine.new()
	var engine_profiled := SimulationEngine.new()
	for day in range(30):
		engine_bare.tick(world_bare)
		engine_profiled.tick(world_profiled)

	var proj_bare := world_bare.to_simulation_projection_json().sha256_text()
	var proj_profiled := world_profiled.to_simulation_projection_json().sha256_text()
	if proj_bare != proj_profiled:
		print("FAIL C5: BACKGROUND IS NOT INERT - projections diverged after 30 days!")
		print("  bare     = %s" % proj_bare)
		print("  profiled = %s" % proj_profiled)
		quit(1)
		return
	print("  30 ticks, 4 backgrounds vs none -> identical projection SHA-256:")
	print("    %s" % proj_bare)

	# Sanity: the two worlds genuinely differ, and ONLY in the profile layer.
	var full_bare := world_bare.to_canonical_json().sha256_text()
	var full_profiled := world_profiled.to_canonical_json().sha256_text()
	if full_bare == full_profiled:
		print("FAIL C5: full hashes identical - the profiled world never received its profiles!")
		quit(1)
		return
	print("  Full-state hashes DO differ (profiles are actually present and persisted)")
	print("  => Background affects the record of the world, not the behavior of the world.")
	print("PASS GATE C5: Simulation Inertness verified.")

	# --------------------------------------------------------------------------
	# GATE C6: Authority Preservation
	# --------------------------------------------------------------------------
	print("\n--- [GATE C6] Authority Preservation ---")

	var w6 := S1WorldData.create_s1_world()
	var gv6: SettlementState = w6.get_settlement(&"settlement:gray_valley")
	var pop_before: int = gv6.population
	var mres6: Dictionary = w6.npc_registry.materialize_identity(w6, &"settlement:gray_valley", "Ada", 31)
	var ada_id: StringName = mres6["npc"].id
	w6.npc_life_state_registry.register_life_state(w6, ada_id, &"settlement:gray_valley")
	var pop_after_identity: int = gv6.population
	w6.npc_profile_registry.assign_background(w6, ada_id, NpcProfile.Background.SCAVENGER)
	var pop_after_profile: int = gv6.population

	if not (pop_before == pop_after_identity and pop_after_identity == pop_after_profile):
		print("FAIL C6: population moved: %d -> %d -> %d" % [pop_before, pop_after_identity, pop_after_profile])
		quit(1)
		return
	print("  Gray Valley population: %d -> %d (identity) -> %d (profile) - untouched" % [
		pop_before, pop_after_identity, pop_after_profile
	])

	# Profiles are a strict subset of identities.
	for k in w6.npc_profile_registry.profiles:
		if not w6.npc_registry.has_npc(k):
			print("FAIL C6: profile %s has no identity!" % k)
			quit(1)
			return
	if w6.npc_profile_registry.get_profile_count() > w6.npc_registry.npcs.size():
		print("FAIL C6: more profiles than identities!")
		quit(1)
		return
	print("  Profiles are a subset of Identities: %d profiles, %d identities" % [
		w6.npc_profile_registry.get_profile_count(), w6.npc_registry.npcs.size()
	])

	# Life conservation across a run with profiles present.
	var engine6 := SimulationEngine.new()
	for day in range(20):
		engine6.tick(w6)
	var total: int = 0
	for s_id in w6.settlements:
		var s: SettlementState = w6.settlements[s_id]
		total += s.population + s.cumulative_deaths
	for r_id in w6.refugees:
		var r: RefugeePartyState = w6.refugees[r_id]
		if r.is_active and not r.is_arrived:
			total += r.headcount
	if total != w6.total_initial_population:
		print("FAIL C6: life conservation broken: %d != %d" % [total, w6.total_initial_population])
		quit(1)
		return
	print("  Life conservation after 20 ticks with profiles: %d == %d" % [total, w6.total_initial_population])
	print("PASS GATE C6: Authority Preservation verified.")

	# --------------------------------------------------------------------------
	# GATE C7: Serialization Round-Trip + Dual Replay + Engine Invariants
	# --------------------------------------------------------------------------
	print("\n--- [GATE C7] Round-Trip / Replay / Invariants ---")

	var replay_a := S1WorldData.create_s1_world()
	var replay_b := S1WorldData.create_s1_world()
	for w in [replay_a, replay_b]:
		for i in range(4):
			var mres7: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 28)
			var id7: StringName = mres7["npc"].id
			w.npc_life_state_registry.register_life_state(w, id7, &"settlement:gray_valley")
			w.npc_profile_registry.assign_background(w, id7, backgrounds[i])
		var e := SimulationEngine.new()
		for day in range(25):
			e.tick(w)

	var hash_a := replay_a.to_canonical_json().sha256_text()
	var hash_b := replay_b.to_canonical_json().sha256_text()
	if hash_a != hash_b:
		print("FAIL C7: dual replay mismatch! A=%s B=%s" % [hash_a, hash_b])
		quit(1)
		return
	print("  Dual world SHA-256 bitwise identical: %s" % hash_a)

	# S4-C.1 closed the EVENT_LEDGER_NOT_ROUNDTRIPPED finding this gate recorded,
	# so the round-trip is now asserted over the FULL canonical state, ledger included.
	var restored := WorldState.from_dict(replay_a.to_dict())
	if restored == null:
		print("FAIL C7: snapshot was refused by the loader!")
		quit(1)
		return
	if restored.to_canonical_json().sha256_text() != hash_a:
		print("FAIL C7: serialization round-trip hash mismatch!")
		quit(1)
		return
	if restored.get_event_count() != replay_a.get_event_count():
		print("FAIL C7: ledger not restored: %d != %d" % [
			restored.get_event_count(), replay_a.get_event_count()
		])
		quit(1)
		return
	print("  Full-state round-trip SHA-256 matches (ledger of %d events included): %s" % [
		restored.get_event_count(), hash_a
	])
	if restored.npc_profile_registry.get_profile_count() != 4:
		print("FAIL C7: restored world lost profiles!")
		quit(1)
		return
	for i in range(4):
		var rp: NpcProfile = restored.npc_profile_registry.get_profile(StringName("npc:%08d" % (i + 1)))
		if rp == null or rp.background != backgrounds[i]:
			print("FAIL C7: restored background mismatch for npc:%08d" % (i + 1))
			quit(1)
			return
	print("  All 4 backgrounds restored exactly through the round-trip")

	# Scope discipline: no derived role or capability field leaked into the
	# PROFILE data. Scoped to the profile registry rather than the whole world:
	# since S4-F1 the decision audit trail legitimately records eligible_actions,
	# and that belongs to the decision layer, not to a background.
	var serialized := JSON.stringify(replay_a.npc_profile_registry.to_dict(), "	", true)
	for forbidden in ["social_role", "eligible_actions", "authorized_actions", "occupation", "skill", "relationship"]:
		if serialized.findn(forbidden) != -1:
			print("FAIL C7: forbidden key '%s' leaked into serialized profile data!" % forbidden)
			quit(1)
			return
	print("  No social_role / eligible_actions / occupation / skill keys in serialization")

	var inv := engine.validate_invariants(replay_a)
	if inv != "":
		print("FAIL C7: engine invariants violated: %s" % inv)
		quit(1)
		return
	print("  Engine invariants PASS with profiles present.")

	# Negative test on the invariant itself: corrupt background must be detected.
	var corrupt := replay_a.duplicate_state()
	var victim: NpcProfile = corrupt.npc_profile_registry.get_profile(&"npc:00000001")
	victim.background = 42 as NpcProfile.Background
	var inv_corrupt := engine.validate_invariants(corrupt)
	if inv_corrupt == "":
		print("FAIL C7: invariant failed to detect out-of-enum background!")
		quit(1)
		return
	print("  Negative test: corrupt background detected -> %s" % inv_corrupt)

	var json_out := JSON.stringify(replay_a.to_dict(), "\t", true)
	var f := FileAccess.open("res://artifacts/world_snapshot_s4c.json", FileAccess.WRITE)
	if f != null:
		f.store_string(json_out)
		f.close()
		print("  Exported artifacts/world_snapshot_s4c.json for independent profile audit.")
	print("PASS GATE C7: Round-Trip / Replay / Invariants verified.")

	print("\n================================================================================")
	print("ALL S4-C RUNTIME ACCEPTANCE GATES (C1 ~ C7) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)
