extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-D TRAITS TEST SUITE (Governance Fast Lane)
# ==============================================================================
#   D1: Closed Enum            (unknown trait -> fail-closed, zero mutation)
#   D2: Profile Integrity      (living NPC, existing profile, real identity)
#   D3: Set Semantics          (no duplicates; assignment order is not world state)
#   D4: Zero Authority         (no actions, no stats, no background/life mutation)
#   D5: Simulation Inertness   (traits vs none -> identical projection SHA)
#   D6: Persistence            (save/load/duplicate/replay keep traits)
#
# THESIS: a trait says what kind of person someone is. It grants nothing.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("        WASTELAND CHRONICLES - S4-D TRAITS TEST SUITE (Fast Lane)               ")
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
		world.npc_profile_registry.assign_background(world, nid, NpcProfile.Background.CARAVAN_GUARD)

	# --------------------------------------------------------------------------
	print("\n--- [GATE D1] Closed Enum ---")
	var pre_hash := world.to_canonical_json().sha256_text()
	for bad in [-1, 6, 99, 4242]:
		var r: Dictionary = world.npc_profile_registry.assign_trait(world, npc_ids[0], bad)
		if r["success"] or not String(r.get("error", "")).begins_with("INVALID_TRAIT"):
			print("FAIL D1: trait value %d accepted or wrong error: %s" % [bad, r.get("error", "")])
			quit(1)
			return
	if world.to_canonical_json().sha256_text() != pre_hash:
		print("FAIL D1: rejected trait mutated world state!")
		quit(1)
		return
	print("  Rejected out-of-enum trait values [-1, 6, 99, 4242]; world hash unchanged")

	for t in [NpcProfile.Trait.CAUTIOUS, NpcProfile.Trait.LOYAL]:
		var ok: Dictionary = world.npc_profile_registry.assign_trait(world, npc_ids[0], t)
		if not ok["success"]:
			print("FAIL D1: legal trait rejected: %s" % ok.get("error", ""))
			quit(1)
			return
	print("  Mara -> %s" % str(world.npc_profile_registry.get_traits(npc_ids[0])))
	print("PASS GATE D1: Closed Enum verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE D2] Profile Integrity ---")

	# Unknown identity
	var r_unknown: Dictionary = world.npc_profile_registry.assign_trait(world, &"npc:99999999", NpcProfile.Trait.GREEDY)
	if r_unknown["success"] or not String(r_unknown["error"]).begins_with("INVALID_NPC"):
		print("FAIL D2: unknown NPC accepted: %s" % r_unknown.get("error", ""))
		quit(1)
		return
	print("  Unknown NPC rejected")

	# Identity with a life state but no profile: traits are profile metadata
	var res_bare: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Bare", 41)
	var bare_id: StringName = res_bare["npc"].id
	world.npc_life_state_registry.register_life_state(world, bare_id, &"settlement:gray_valley")
	var r_bare: Dictionary = world.npc_profile_registry.assign_trait(world, bare_id, NpcProfile.Trait.LOYAL)
	if r_bare["success"] or not String(r_bare["error"]).begins_with("NO_PROFILE"):
		print("FAIL D2: NPC without a profile accepted: %s" % r_bare.get("error", ""))
		quit(1)
		return
	print("  NPC without a profile rejected: %s" % r_bare["error"])

	# Deceased NPC cannot gain traits, but keeps the ones held in life
	var res_doomed: Dictionary = world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Doomed", 52)
	var doomed_id: StringName = res_doomed["npc"].id
	world.npc_life_state_registry.register_life_state(world, doomed_id, &"settlement:gray_valley")
	world.npc_profile_registry.assign_background(world, doomed_id, NpcProfile.Background.FARMER)
	world.npc_profile_registry.assign_trait(world, doomed_id, NpcProfile.Trait.STUBBORN)
	world.npc_life_state_registry.commit_named_death(world, doomed_id)
	var r_dead: Dictionary = world.npc_profile_registry.assign_trait(world, doomed_id, NpcProfile.Trait.GREEDY)
	if r_dead["success"] or not String(r_dead["error"]).begins_with("DECEASED_NPC"):
		print("FAIL D2: post-mortem trait authoring allowed: %s" % r_dead.get("error", ""))
		quit(1)
		return
	var doomed_traits := world.npc_profile_registry.get_traits(doomed_id)
	if doomed_traits != [NpcProfile.Trait.STUBBORN]:
		print("FAIL D2: death altered existing traits: %s" % str(doomed_traits))
		quit(1)
		return
	print("  Post-mortem authoring rejected; pre-mortem trait STUBBORN preserved after death")
	print("PASS GATE D2: Profile Integrity verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE D3] Set Semantics ---")

	var dup_hash := world.to_canonical_json().sha256_text()
	var r_dup: Dictionary = world.npc_profile_registry.assign_trait(world, npc_ids[0], NpcProfile.Trait.CAUTIOUS)
	if r_dup["success"] or not String(r_dup["error"]).begins_with("DUPLICATE_TRAIT"):
		print("FAIL D3: duplicate trait accepted: %s" % r_dup.get("error", ""))
		quit(1)
		return
	if world.to_canonical_json().sha256_text() != dup_hash:
		print("FAIL D3: rejected duplicate mutated world state!")
		quit(1)
		return
	print("  Duplicate rejected with zero mutation: %s" % r_dup["error"])

	# Assignment ORDER must not be world state.
	var order_a := build_trait_world([NpcProfile.Trait.LOYAL, NpcProfile.Trait.CAUTIOUS, NpcProfile.Trait.STUBBORN])
	var order_b := build_trait_world([NpcProfile.Trait.STUBBORN, NpcProfile.Trait.CAUTIOUS, NpcProfile.Trait.LOYAL])
	var sha_a := order_a.to_canonical_json().sha256_text()
	var sha_b := order_b.to_canonical_json().sha256_text()
	if sha_a != sha_b:
		print("FAIL D3: assignment order changed the world! %s vs %s" % [sha_a, sha_b])
		quit(1)
		return
	print("  [LOYAL, CAUTIOUS, STUBBORN] and [STUBBORN, CAUTIOUS, LOYAL] produce the same world")
	print("  Canonical (enum) order: %s" % str(order_a.npc_profile_registry.get_traits(&"npc:00000001")))
	print("PASS GATE D3: Set Semantics verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE D4] Zero Authority ---")

	var auth_hash := world.to_canonical_json().sha256_text()
	for nid in npc_ids:
		if world.npc_profile_registry.get_authorized_actions(nid).size() != 0:
			print("FAIL D4: traits granted authorized actions!")
			quit(1)
			return
	for act in [&"FLEE", &"ATTACK", &"TRADE", &"STAY", &"MIGRATE", &"HOARD"]:
		var r_act: Dictionary = world.npc_profile_registry.attempt_background_action(world, npc_ids[0], act)
		if r_act["success"] or r_act.get("state_changed", true):
			print("FAIL D4: action %s executed on trait authority!" % act)
			quit(1)
			return
	print("  CAUTIOUS denied FLEE; AGGRESSIVE would be denied ATTACK; all 6 attempts refused")

	# Traits must not touch background or life state.
	var mara_profile: NpcProfile = world.npc_profile_registry.get_profile(npc_ids[0])
	if mara_profile.background != NpcProfile.Background.CARAVAN_GUARD:
		print("FAIL D4: trait assignment changed the background!")
		quit(1)
		return
	var mara_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(npc_ids[0])
	if mara_ls.status != NpcLifeState.Status.SETTLED or mara_ls.population_container_id != &"settlement:gray_valley":
		print("FAIL D4: trait assignment changed the life state!")
		quit(1)
		return
	if world.to_canonical_json().sha256_text() != auth_hash:
		print("FAIL D4: refused action attempts mutated world state!")
		quit(1)
		return
	print("  Background, life state and world hash all unchanged by traits and refused actions")

	# No numeric modifier surface leaked into serialization.
	var serialized := world.to_canonical_json()
	for forbidden in ["modifier", "bonus", "weight", "combat", "conflict", "score", "positive", "negative"]:
		if serialized.findn(forbidden) != -1:
			print("FAIL D4: forbidden key '%s' leaked into serialized trait data!" % forbidden)
			quit(1)
			return
	print("  No modifier / bonus / weight / conflict / score keys anywhere in serialization")
	print("PASS GATE D4: Zero Authority verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE D5] Simulation Inertness (30-day counterfactual) ---")

	var w_traits := S1WorldData.create_s1_world()
	var w_bare := S1WorldData.create_s1_world()
	for w in [w_traits, w_bare]:
		for i in range(names.size()):
			var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 28 + i)
			var nid: StringName = res["npc"].id
			w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
			w.npc_profile_registry.assign_background(w, nid, NpcProfile.Background.MECHANIC)

	# Only w_traits receives personalities.
	for t in [NpcProfile.Trait.CAUTIOUS, NpcProfile.Trait.LOYAL]:
		w_traits.npc_profile_registry.assign_trait(w_traits, &"npc:00000001", t)
	for t in [NpcProfile.Trait.GREEDY, NpcProfile.Trait.AGGRESSIVE, NpcProfile.Trait.STUBBORN]:
		w_traits.npc_profile_registry.assign_trait(w_traits, &"npc:00000002", t)
	w_traits.npc_profile_registry.assign_trait(w_traits, &"npc:00000003", NpcProfile.Trait.COMPASSIONATE)

	var e_traits := SimulationEngine.new()
	var e_bare := SimulationEngine.new()
	for day in range(30):
		e_traits.tick(w_traits)
		e_bare.tick(w_bare)

	var proj_traits := w_traits.to_simulation_projection_json().sha256_text()
	var proj_bare := w_bare.to_simulation_projection_json().sha256_text()
	if proj_traits != proj_bare:
		print("FAIL D5: TRAITS ARE NOT INERT — projections diverged after 30 days!")
		print("  traits = %s" % proj_traits)
		print("  bare   = %s" % proj_bare)
		quit(1)
		return
	print("  30 ticks, 6 traits across 3 NPCs vs none -> identical projection SHA-256:")
	print("    %s" % proj_traits)

	if w_traits.to_canonical_json().sha256_text() == w_bare.to_canonical_json().sha256_text():
		print("FAIL D5: full hashes identical — the traits were never actually stored!")
		quit(1)
		return
	print("  Full-state hashes DO differ (traits are present and persisted)")
	print("  => Traits describe who someone is; they do not change what the world does.")
	print("PASS GATE D5: Simulation Inertness verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE D6] Persistence / Determinism ---")

	var restored := WorldState.from_json(JSON.stringify(w_traits.to_dict()))
	if restored == null:
		print("FAIL D6: loader refused a snapshot it had just produced!")
		quit(1)
		return
	if restored.to_canonical_json().sha256_text() != w_traits.to_canonical_json().sha256_text():
		print("FAIL D6: round-trip hash mismatch!")
		quit(1)
		return
	for nid in [&"npc:00000001", &"npc:00000002", &"npc:00000003"]:
		var before := w_traits.npc_profile_registry.get_traits(nid)
		var after := restored.npc_profile_registry.get_traits(nid)
		if before != after:
			print("FAIL D6: %s traits changed across persistence: %s -> %s" % [nid, str(before), str(after)])
			quit(1)
			return
	print("  Round-trip SHA identical; all traits restored exactly")

	var copied := w_traits.duplicate_state()
	copied.npc_profile_registry.assign_trait(copied, &"npc:00000003", NpcProfile.Trait.STUBBORN)
	if w_traits.npc_profile_registry.get_traits(&"npc:00000003").size() != 1:
		print("FAIL D6: duplicate_state() shares trait storage with the original!")
		quit(1)
		return
	print("  duplicate_state() deep-copies traits (mutating the copy left the original alone)")

	var inv := engine.validate_invariants(w_traits)
	if inv != "":
		print("FAIL D6: invariants violated with traits present: %s" % inv)
		quit(1)
		return

	# Negative tests on the invariant itself.
	var corrupt := w_traits.duplicate_state()
	corrupt.npc_profile_registry.get_profile(&"npc:00000001").traits = [99]
	if engine.validate_invariants(corrupt) == "":
		print("FAIL D6: invariant missed an out-of-enum trait!")
		quit(1)
		return
	var dup_world := w_traits.duplicate_state()
	dup_world.npc_profile_registry.get_profile(&"npc:00000001").traits = [0, 0]
	if engine.validate_invariants(dup_world) == "":
		print("FAIL D6: invariant missed a duplicate trait!")
		quit(1)
		return
	var unordered := w_traits.duplicate_state()
	unordered.npc_profile_registry.get_profile(&"npc:00000001").traits = [1, 0]
	if engine.validate_invariants(unordered) == "":
		print("FAIL D6: invariant missed non-canonical trait order!")
		quit(1)
		return
	print("  Negative tests: out-of-enum, duplicate and unordered traits all detected")

	var f := FileAccess.open("res://artifacts/world_snapshot_s4d.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(w_traits.to_dict(), "\t", true))
		f.close()
		print("  Exported artifacts/world_snapshot_s4d.json for independent validation.")
	print("PASS GATE D6: Persistence / Determinism verified.")

	print("\n================================================================================")
	print("ALL S4-D TRAIT GATES (D1 ~ D6) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# Build a world whose single NPC receives traits in the given order.
func build_trait_world(order: Array) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", "Mara", 28)
	var nid: StringName = res["npc"].id
	w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
	w.npc_profile_registry.assign_background(w, nid, NpcProfile.Background.SCAVENGER)
	for t in order:
		w.npc_profile_registry.assign_trait(w, nid, t)
	return w
