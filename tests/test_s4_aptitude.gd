extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-E APTITUDE TEST SUITE (Governance Fast Lane)
# ==============================================================================
#   E1: Closed Domain Set      (unknown aptitude -> fail-closed, zero mutation)
#   E2: Profile Integrity      (living NPC, existing profile, real identity)
#   E3: Set Semantics          (no duplicates; assignment order is not world state)
#   E4: Zero Gameplay Authority(no actions, stats, traits, background, life state)
#   E5: Simulation Inertness   (aptitudes vs none -> identical projection SHA)
#   E6: Persistence            (save/load/duplicate keep aptitudes, deterministic)
#
# THESIS: an aptitude names a domain someone may find easier to learn in.
# It is not a rating, a multiplier, or a growth curve — and today it does nothing.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S4-E APTITUDE TEST SUITE (Fast Lane)              ")
	print("================================================================================")

	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	var names := ["Mara", "Joel", "Tess"]
	var npc_ids: Array[StringName] = []
	for i in range(names.size()):
		var res: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", names[i], 28 + i)
		var nid: StringName = res["npc"].id
		npc_ids.append(nid)
		world.npc_life_state_registry.register_life_state(world, nid, &"settlement:gray_valley")
		world.npc_profile_registry.assign_background(world, nid, NpcProfile.Background.MECHANIC)
		world.npc_profile_registry.assign_trait(world, nid, NpcProfile.Trait.CAUTIOUS)

	# --------------------------------------------------------------------------
	print("\n--- [GATE E1] Closed Domain Set ---")
	var pre_hash := world.to_canonical_json().sha256_text()
	for bad in [-1, 5, 42, 9999]:
		var r: Dictionary = world.npc_profile_registry.assign_aptitude(world, npc_ids[0], bad)
		if r["success"] or not String(r.get("error", "")).begins_with("INVALID_APTITUDE"):
			print("FAIL E1: aptitude %d accepted or wrong error: %s" % [bad, r.get("error", "")])
			quit(1)
			return
	if world.to_canonical_json().sha256_text() != pre_hash:
		print("FAIL E1: rejected aptitude mutated world state!")
		quit(1)
		return
	print("  Rejected out-of-domain values [-1, 5, 42, 9999]; world hash unchanged")

	for a in [NpcProfile.Aptitude.SURVIVAL, NpcProfile.Aptitude.TECHNICAL]:
		var ok: Dictionary = world.npc_profile_registry.assign_aptitude(world, npc_ids[0], a)
		if not ok["success"]:
			print("FAIL E1: legal aptitude rejected: %s" % ok.get("error", ""))
			quit(1)
			return
	print("  Mara -> %s (SURVIVAL, TECHNICAL)" % str(world.npc_profile_registry.get_aptitudes(npc_ids[0])))
	print("PASS GATE E1: Closed Domain Set verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E2] Profile Integrity ---")

	var r_unknown: Dictionary = world.npc_profile_registry.assign_aptitude(world, &"npc:99999999", NpcProfile.Aptitude.TRADE)
	if r_unknown["success"] or not String(r_unknown["error"]).begins_with("INVALID_NPC"):
		print("FAIL E2: unknown NPC accepted")
		quit(1)
		return
	print("  Unknown NPC rejected")

	var res_bare: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Bare", 44)
	var bare_id: StringName = res_bare["npc"].id
	world.npc_life_state_registry.register_life_state(world, bare_id, &"settlement:gray_valley")
	var r_bare: Dictionary = world.npc_profile_registry.assign_aptitude(world, bare_id, NpcProfile.Aptitude.SOCIAL)
	if r_bare["success"] or not String(r_bare["error"]).begins_with("NO_PROFILE"):
		print("FAIL E2: NPC without a profile accepted: %s" % r_bare.get("error", ""))
		quit(1)
		return
	print("  NPC without a profile rejected: %s" % r_bare["error"])

	var res_doomed: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Doomed", 57)
	var doomed_id: StringName = res_doomed["npc"].id
	world.npc_life_state_registry.register_life_state(world, doomed_id, &"settlement:gray_valley")
	world.npc_profile_registry.assign_background(world, doomed_id, NpcProfile.Background.FARMER)
	world.npc_profile_registry.assign_aptitude(world, doomed_id, NpcProfile.Aptitude.COMBAT)
	world.npc_life_state_registry.commit_named_death(world, doomed_id)
	var r_dead: Dictionary = world.npc_profile_registry.assign_aptitude(world, doomed_id, NpcProfile.Aptitude.SOCIAL)
	if r_dead["success"] or not String(r_dead["error"]).begins_with("DECEASED_NPC"):
		print("FAIL E2: post-mortem aptitude authoring allowed: %s" % r_dead.get("error", ""))
		quit(1)
		return
	if world.npc_profile_registry.get_aptitudes(doomed_id) != [NpcProfile.Aptitude.COMBAT]:
		print("FAIL E2: death altered existing aptitudes!")
		quit(1)
		return
	print("  Post-mortem authoring rejected; pre-mortem COMBAT aptitude preserved after death")
	print("PASS GATE E2: Profile Integrity verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E3] Set Semantics ---")

	var dup_hash := world.to_canonical_json().sha256_text()
	var r_dup: Dictionary = world.npc_profile_registry.assign_aptitude(world, npc_ids[0], NpcProfile.Aptitude.SURVIVAL)
	if r_dup["success"] or not String(r_dup["error"]).begins_with("DUPLICATE_APTITUDE"):
		print("FAIL E3: duplicate aptitude accepted: %s" % r_dup.get("error", ""))
		quit(1)
		return
	if world.to_canonical_json().sha256_text() != dup_hash:
		print("FAIL E3: rejected duplicate mutated world state!")
		quit(1)
		return
	print("  Duplicate rejected with zero mutation: %s" % r_dup["error"])

	var order_a := build_aptitude_world([NpcProfile.Aptitude.SOCIAL, NpcProfile.Aptitude.COMBAT, NpcProfile.Aptitude.TRADE])
	var order_b := build_aptitude_world([NpcProfile.Aptitude.TRADE, NpcProfile.Aptitude.SOCIAL, NpcProfile.Aptitude.COMBAT])
	if order_a.to_canonical_json().sha256_text() != order_b.to_canonical_json().sha256_text():
		print("FAIL E3: assignment order changed the world!")
		quit(1)
		return
	print("  [SOCIAL, COMBAT, TRADE] and [TRADE, SOCIAL, COMBAT] produce the same world")
	print("  Canonical (enum) order: %s" % str(order_a.npc_profile_registry.get_aptitudes(&"npc:00000001")))
	print("PASS GATE E3: Set Semantics verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E4] Zero Gameplay Authority ---")

	var auth_hash := world.to_canonical_json().sha256_text()
	for nid in npc_ids:
		if world.npc_profile_registry.get_authorized_actions(nid).size() != 0:
			print("FAIL E4: aptitudes granted authorized actions!")
			quit(1)
			return
	for act in [&"REPAIR", &"SCAVENGE", &"TRADE", &"FIGHT", &"PERSUADE", &"MIGRATE"]:
		var r_act: Dictionary = world.npc_profile_registry.attempt_background_action(world, npc_ids[0], act)
		if r_act["success"] or r_act.get("state_changed", true):
			print("FAIL E4: action %s executed on aptitude authority!" % act)
			quit(1)
			return
	print("  TECHNICAL denied REPAIR; SURVIVAL denied SCAVENGE; all 6 attempts refused")

	# Aptitudes must not disturb the other two profile layers or the life state.
	var mara: NpcProfile = world.npc_profile_registry.get_profile(npc_ids[0])
	if mara.background != NpcProfile.Background.MECHANIC:
		print("FAIL E4: aptitude assignment changed the background!")
		quit(1)
		return
	if mara.traits != [NpcProfile.Trait.CAUTIOUS]:
		print("FAIL E4: aptitude assignment changed the traits! %s" % str(mara.traits))
		quit(1)
		return
	var mara_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(npc_ids[0])
	if mara_ls.status != NpcLifeState.Status.SETTLED:
		print("FAIL E4: aptitude assignment changed the life state!")
		quit(1)
		return
	if world.to_canonical_json().sha256_text() != auth_hash:
		print("FAIL E4: refused action attempts mutated world state!")
		quit(1)
		return
	print("  Background, traits, life state and world hash all unchanged")

	# Scope scan: no rating / progression vocabulary may exist in runtime schema.
	var serialized := world.to_canonical_json()
	var profile_src := FileAccess.get_file_as_string("res://simulation/npc_profile.gd")
	var forbidden := ["xp_multiplier", "learning_rate", "skill_bonus", "skill_cap",
		"modifier", "growth_rate", "attribute_bonus", "rating", "stars"]
	for word in forbidden:
		if serialized.findn(word) != -1:
			print("FAIL E4: forbidden key '%s' leaked into serialized profile data!" % word)
			quit(1)
			return
		# The source may only mention these words inside comments explaining why
		# they are absent; a declared field would show up as `var <word>`.
		if profile_src.findn("var %s" % word) != -1:
			print("FAIL E4: forbidden field 'var %s' declared in NpcProfile!" % word)
			quit(1)
			return
	print("  No xp_multiplier / learning_rate / skill_bonus / skill_cap / growth_rate")
	print("  / attribute_bonus / rating / stars in the schema or serialization")
	print("PASS GATE E4: Zero Gameplay Authority verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E5] Simulation Inertness (30-day counterfactual) ---")

	var w_apt := S1WorldData.create_s1_world()
	var w_bare := S1WorldData.create_s1_world()
	for w in [w_apt, w_bare]:
		for i in range(names.size()):
			var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 28 + i)
			var nid: StringName = res["npc"].id
			w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
			w.npc_profile_registry.assign_background(w, nid, NpcProfile.Background.SCAVENGER)
			w.npc_profile_registry.assign_trait(w, nid, NpcProfile.Trait.LOYAL)

	for a in [NpcProfile.Aptitude.SURVIVAL, NpcProfile.Aptitude.TECHNICAL]:
		w_apt.npc_profile_registry.assign_aptitude(w_apt, &"npc:00000001", a)
	for a in [NpcProfile.Aptitude.COMBAT, NpcProfile.Aptitude.TRADE, NpcProfile.Aptitude.SOCIAL]:
		w_apt.npc_profile_registry.assign_aptitude(w_apt, &"npc:00000002", a)
	w_apt.npc_profile_registry.assign_aptitude(w_apt, &"npc:00000003", NpcProfile.Aptitude.SOCIAL)

	var e_apt := SimulationEngine.new()
	var e_bare := SimulationEngine.new()
	for day in range(30):
		e_apt.tick(w_apt)
		e_bare.tick(w_bare)

	var proj_apt := w_apt.to_simulation_projection_json().sha256_text()
	var proj_bare := w_bare.to_simulation_projection_json().sha256_text()
	if proj_apt != proj_bare:
		print("FAIL E5: APTITUDES ARE NOT INERT — projections diverged after 30 days!")
		print("  aptitudes = %s" % proj_apt)
		print("  bare      = %s" % proj_bare)
		quit(1)
		return
	print("  30 ticks, 6 aptitudes across 3 NPCs vs none -> identical projection SHA-256:")
	print("    %s" % proj_apt)
	if w_apt.to_canonical_json().sha256_text() == w_bare.to_canonical_json().sha256_text():
		print("FAIL E5: full hashes identical — the aptitudes were never stored!")
		quit(1)
		return
	print("  Full-state hashes DO differ (aptitudes are present and persisted)")
	print("  => The world records what Mara could learn easily; it changes nothing yet.")
	print("PASS GATE E5: Simulation Inertness verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E6] Persistence / Determinism ---")

	var restored := WorldState.from_json(JSON.stringify(w_apt.to_dict()))
	if restored == null:
		print("FAIL E6: loader refused a snapshot it had just produced!")
		quit(1)
		return
	if restored.to_canonical_json().sha256_text() != w_apt.to_canonical_json().sha256_text():
		print("FAIL E6: round-trip hash mismatch!")
		quit(1)
		return
	for nid in [&"npc:00000001", &"npc:00000002", &"npc:00000003"]:
		if w_apt.npc_profile_registry.get_aptitudes(nid) != restored.npc_profile_registry.get_aptitudes(nid):
			print("FAIL E6: %s aptitudes changed across persistence!" % nid)
			quit(1)
			return
		if w_apt.npc_profile_registry.get_traits(nid) != restored.npc_profile_registry.get_traits(nid):
			print("FAIL E6: %s traits changed across persistence!" % nid)
			quit(1)
			return
	print("  Round-trip SHA identical; all aptitudes and traits restored exactly")

	var copied := w_apt.duplicate_state()
	copied.npc_profile_registry.assign_aptitude(copied, &"npc:00000003", NpcProfile.Aptitude.COMBAT)
	if w_apt.npc_profile_registry.get_aptitudes(&"npc:00000003").size() != 1:
		print("FAIL E6: duplicate_state() shares aptitude storage with the original!")
		quit(1)
		return
	print("  duplicate_state() deep-copies aptitudes")

	if engine.validate_invariants(w_apt) != "":
		print("FAIL E6: invariants violated with aptitudes present!")
		quit(1)
		return
	var corrupt := w_apt.duplicate_state()
	corrupt.npc_profile_registry.get_profile(&"npc:00000001").aptitudes = [42]
	if engine.validate_invariants(corrupt) == "":
		print("FAIL E6: invariant missed an out-of-enum aptitude!")
		quit(1)
		return
	var dup_world := w_apt.duplicate_state()
	dup_world.npc_profile_registry.get_profile(&"npc:00000001").aptitudes = [1, 1]
	if engine.validate_invariants(dup_world) == "":
		print("FAIL E6: invariant missed a duplicate aptitude!")
		quit(1)
		return
	var unordered := w_apt.duplicate_state()
	unordered.npc_profile_registry.get_profile(&"npc:00000001").aptitudes = [3, 1]
	if engine.validate_invariants(unordered) == "":
		print("FAIL E6: invariant missed non-canonical aptitude order!")
		quit(1)
		return
	print("  Negative tests: out-of-enum, duplicate and unordered aptitudes all detected")

	var f := FileAccess.open("res://artifacts/world_snapshot_s4e.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(w_apt.to_dict(), "\t", true))
		f.close()
		print("  Exported artifacts/world_snapshot_s4e.json for independent validation.")
	print("PASS GATE E6: Persistence / Determinism verified.")

	print("\n================================================================================")
	print("ALL S4-E APTITUDE GATES (E1 ~ E6) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

func build_aptitude_world(order: Array) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", "Mara", 28)
	var nid: StringName = res["npc"].id
	w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
	w.npc_profile_registry.assign_background(w, nid, NpcProfile.Background.CARAVAN_GUARD)
	for a in order:
		w.npc_profile_registry.assign_aptitude(w, nid, a)
	return w
