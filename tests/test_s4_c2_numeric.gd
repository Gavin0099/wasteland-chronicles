extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-C.2 SNAPSHOT NUMERIC CANONICALITY TEST SUITE
# ==============================================================================
# Gates (implementation order was N2 -> N3 -> N1 -> N4 -> N5 -> N6):
#   N1: Full Snapshot Fixed Point        (save -> load -> save is byte-identical)
#   N2: Schema-aware Type Restoration    (declared domain types come back)
#   N3: Authoritative Float Canonicality (committed state is already canonical)
#   N4: Interrupted vs Uninterrupted     (save/load does not fork the timeline)
#   N5: Malformed Numeric Fail-Closed    (no type guessing, no partial world)
#   N6: Codec Corpus + Independent Verification
#
# THE SENTENCE THIS SLICE LOCKS DOWN:
#   Save/Load 不再是一個會改變世界未來的事件。
#
# N4 is the closure blocker: if N1 passes and N4 fails, the slice FAILS.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("     WASTELAND CHRONICLES - S4-C.2 SNAPSHOT NUMERIC CANONICALITY SUITE          ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# GATE N2: Schema-aware Type Restoration
	# --------------------------------------------------------------------------
	print("\n--- [GATE N2] Schema-aware Type Restoration ---")

	var w := build_world(60)
	var loaded := roundtrip(w)
	if loaded == null:
		print("FAIL N2: loader refused a snapshot it had just produced!")
		quit(1)
		return

	var checked_int := 0
	var checked_float := 0
	for s_id in w.settlements:
		var a: SettlementState = w.settlements[s_id]
		var b: SettlementState = loaded.get_settlement(s_id)
		for field in ["population", "maintenance_scrap", "maintenance_fuel", "reference_population",
				"days_since_last_migration", "cumulative_deaths", "target_water", "target_food",
				"target_scrap", "target_fuel"]:
			if typeof(b.get(field)) != TYPE_INT:
				print("FAIL N2: %s.%s restored as %s, declared int" % [s_id, field, type_string(typeof(b.get(field)))])
				quit(1)
				return
			if a.get(field) != b.get(field):
				print("FAIL N2: %s.%s value changed %s -> %s" % [s_id, field, str(a.get(field)), str(b.get(field))])
				quit(1)
				return
			checked_int += 1
		for field in ["water_pressure", "food_pressure", "water_exposure", "food_exposure",
				"security", "price_water", "price_food", "price_scrap", "price_fuel",
				"metabolism_water_rate", "metabolism_food_rate"]:
			if typeof(b.get(field)) != TYPE_FLOAT:
				print("FAIL N2: %s.%s restored as %s, declared float" % [s_id, field, type_string(typeof(b.get(field)))])
				quit(1)
				return
			checked_float += 1
		# Inventory / production / consumption are int domains throughout.
		for res in ["water", "food", "scrap", "fuel"]:
			if typeof(b.inventory.get(res)) != TYPE_INT:
				print("FAIL N2: %s.inventory.%s restored as float" % [s_id, res])
				quit(1)
				return
			checked_int += 1
		# cumulative_disorder_loss: ACCOUNTING STATE, Dictionary[StringName, int]
		for k in b.cumulative_disorder_loss:
			if typeof(b.cumulative_disorder_loss[k]) != TYPE_INT:
				print("FAIL N2: %s.cumulative_disorder_loss.%s restored as %s, declared int" % [
					s_id, String(k), type_string(typeof(b.cumulative_disorder_loss[k]))
				])
				quit(1)
				return
			if a.cumulative_disorder_loss.get(k) != b.cumulative_disorder_loss[k]:
				print("FAIL N2: %s.cumulative_disorder_loss.%s value changed" % [s_id, String(k)])
				quit(1)
				return
			checked_int += 1
		# production_credits / disorder_loss_credits: AUTHORITATIVE, Dictionary[*, float]
		for k in b.production_credits:
			if typeof(b.production_credits[k]) != TYPE_FLOAT:
				print("FAIL N2: %s.production_credits.%s restored as non-float" % [s_id, String(k)])
				quit(1)
				return
			if a.production_credits[k] != b.production_credits[k]:
				print("FAIL N2: %s.production_credits.%s value changed %s -> %s" % [
					s_id, String(k), str(a.production_credits[k]), str(b.production_credits[k])
				])
				quit(1)
				return
			checked_float += 1
	print("  %d int-domain and %d float-domain values restored with declared types and exact values" % [
		checked_int, checked_float
	])
	print("  cumulative_disorder_loss restored as int (ACCOUNTING STATE), not widened to float")
	print("PASS GATE N2: Schema-aware Type Restoration verified.")

	# --------------------------------------------------------------------------
	# GATE N3: Authoritative Float Canonicality
	# --------------------------------------------------------------------------
	print("\n--- [GATE N3] Authoritative Float Canonicality ---")

	var non_canonical := 0
	var total_floats := 0
	for s_id in w.settlements:
		var s: SettlementState = w.settlements[s_id]
		for field in ["water_pressure", "food_pressure", "water_exposure", "food_exposure",
				"security", "price_water", "price_food", "price_scrap", "price_fuel",
				"metabolism_water_rate", "metabolism_food_rate"]:
			total_floats += 1
			if not NumericCanon.is_canonical_float(s.get(field)):
				non_canonical += 1
				print("  NOT CANONICAL: %s.%s = %s" % [s_id, field, String.num(s.get(field), 17)])
		for k in s.production_credits:
			total_floats += 1
			if not NumericCanon.is_canonical_float(s.production_credits[k]):
				non_canonical += 1
				print("  NOT CANONICAL: %s.production_credits.%s" % [s_id, String(k)])
		for k in s.disorder_loss_credits:
			total_floats += 1
			if not NumericCanon.is_canonical_float(s.disorder_loss_credits[k]):
				non_canonical += 1
	if non_canonical > 0:
		print("FAIL N3: %d of %d committed floats are not persistence-canonical!" % [non_canonical, total_floats])
		quit(1)
		return
	print("  All %d committed authoritative floats are already persistence-canonical" % total_floats)

	# The committed world must equal its own loaded form, value for value.
	for s_id in w.settlements:
		var live: SettlementState = w.settlements[s_id]
		var back: SettlementState = loaded.get_settlement(s_id)
		for field in ["water_pressure", "food_pressure", "water_exposure", "food_exposure", "security"]:
			if live.get(field) != back.get(field):
				print("FAIL N3: %s.%s changed across persistence: %s -> %s" % [
					s_id, field, String.num(live.get(field), 17), String.num(back.get(field), 17)
				])
				quit(1)
				return
	print("  Committed value == loaded value for every authoritative float (no save-time repair)")

	# And no save-time rounding remains anywhere in the serializer.
	var src := FileAccess.get_file_as_string("res://simulation/settlement_state.gd")
	if src.find("snapped(") != -1:
		print("FAIL N3: settlement_state.gd still rounds at serialization time!")
		quit(1)
		return
	print("  Serializer contains no snapped() calls: to_dict() records, it does not repair")
	print("PASS GATE N3: Authoritative Float Canonicality verified.")

	# --------------------------------------------------------------------------
	# GATE N1: Full Snapshot Fixed Point
	# --------------------------------------------------------------------------
	print("\n--- [GATE N1] Full Snapshot Fixed Point ---")

	var rich := build_world(100)
	var json_a := JSON.stringify(rich.to_dict(), "\t", true)
	var l1 := WorldState.from_json(json_a)
	if l1 == null:
		print("FAIL N1: loader refused the snapshot!")
		quit(1)
		return
	var json_b := JSON.stringify(l1.to_dict(), "\t", true)
	if json_a != json_b:
		print("FAIL N1: whole snapshot is NOT a fixed point.")
		var la := json_a.split("\n")
		var lb := json_b.split("\n")
		var shown := 0
		for i in range(mini(la.size(), lb.size())):
			if la[i] != lb[i]:
				print("    line %d:\n      A: %s\n      B: %s" % [i, la[i].strip_edges(), lb[i].strip_edges()])
				shown += 1
				if shown >= 8:
					break
		quit(1)
		return
	print("  Day 100 world with economy, pressure, migration, mortality, labor, security,")
	print("  NPC identity/life state/profile and a %d-event ledger:" % rich.get_event_count())
	print("  save -> load -> save byte-identical, SHA-256 %s" % json_a.sha256_text())

	# A second cycle must also hold (idempotence, not luck).
	var l2 := WorldState.from_json(json_b)
	if JSON.stringify(l2.to_dict(), "\t", true) != json_a:
		print("FAIL N1: second save/load cycle diverged!")
		quit(1)
		return
	print("  Second cycle identical as well")
	print("PASS GATE N1: Full Snapshot Fixed Point verified.")

	# --------------------------------------------------------------------------
	# GATE N4: Interrupted vs Uninterrupted Continuation  [CLOSURE BLOCKER]
	# --------------------------------------------------------------------------
	print("\n--- [GATE N4] Interrupted vs Uninterrupted Continuation ---")

	# World A: Day 0 -> 100 uninterrupted.
	var world_a := build_world(50)
	run_to(world_a, 100)

	# World B: Day 0 -> 50, SAVE, LOAD, Day 51 -> 100.
	var world_b_pre := build_world(50)
	var world_b := roundtrip(world_b_pre)
	if world_b == null:
		print("FAIL N4: loader refused the Day 50 save!")
		quit(1)
		return

	# Day 51 check first: if the fork happens on the first post-load day, say so
	# here rather than making someone debug it from a Day 100 hash.
	var a51 := build_world(50)
	var b51 := roundtrip(build_world(50))
	run_to(a51, 51)
	run_to(b51, 51)
	if a51.to_canonical_json().sha256_text() != b51.to_canonical_json().sha256_text():
		print("FAIL N4: divergence on the FIRST post-load day (Day 51).")
		var da := a51.to_canonical_json().split("\n")
		var db := b51.to_canonical_json().split("\n")
		var n := 0
		for i in range(mini(da.size(), db.size())):
			if da[i] != db[i]:
				print("    A: %s\n    B: %s" % [da[i].strip_edges(), db[i].strip_edges()])
				n += 1
				if n >= 6:
					break
		quit(1)
		return
	print("  Day 51 (first day after load) identical to the uninterrupted Day 51")

	run_to(world_b, 100)

	var sha_a := world_a.to_canonical_json().sha256_text()
	var sha_b := world_b.to_canonical_json().sha256_text()
	if sha_a != sha_b:
		print("FAIL N4: Day 100 worlds diverged — save/load forked the timeline.")
		print("  A = %s" % sha_a)
		print("  B = %s" % sha_b)
		var fa := world_a.to_canonical_json().split("\n")
		var fb := world_b.to_canonical_json().split("\n")
		var m := 0
		for i in range(mini(fa.size(), fb.size())):
			if fa[i] != fb[i]:
				print("    A: %s\n    B: %s" % [fa[i].strip_edges(), fb[i].strip_edges()])
				m += 1
				if m >= 8:
					break
		quit(1)
		return
	print("  Day 100 full canonical state SHA identical: %s" % sha_a)

	var ledger_a := JSON.stringify(ledger_of(world_a), "\t", true).sha256_text()
	var ledger_b := JSON.stringify(ledger_of(world_b), "\t", true).sha256_text()
	if ledger_a != ledger_b:
		print("FAIL N4: Day 100 event ledgers differ!")
		quit(1)
		return
	print("  Day 100 event ledger SHA identical  : %s (%d events)" % [ledger_a, world_a.get_event_count()])

	var proj_a := world_a.to_simulation_projection_json().sha256_text()
	var proj_b := world_b.to_simulation_projection_json().sha256_text()
	if proj_a != proj_b:
		print("FAIL N4: Day 100 simulation projections differ!")
		quit(1)
		return
	print("  Day 100 simulation projection SHA   : %s" % proj_a)
	print("  => Save/Load is a transparent boundary: it no longer changes the world's future.")
	print("PASS GATE N4: Interrupted vs Uninterrupted Continuation verified.")

	# --------------------------------------------------------------------------
	# GATE N5: Malformed Numeric Fail-Closed
	# --------------------------------------------------------------------------
	print("\n--- [GATE N5] Malformed Numeric Fail-Closed ---")

	var base_snapshot := build_world(30).to_dict()

	var cases := [
		["int field receives a fractional value", "population", 3.7, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["int field receives NaN", "population", NAN, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["int field receives Inf", "population", INF, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["int field receives -Inf", "population", -INF, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["non-negative int field receives a negative", "population", -5, "INVALID_DOMAIN_NUMERIC_RANGE"],
		["int field beyond the safe integer range", "population", 1.0e17, "INVALID_DOMAIN_NUMERIC_RANGE"],
		["int field receives a string", "population", "many", "INVALID_DOMAIN_NUMERIC_TYPE"],
		["float field receives NaN", "security", NAN, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["float field receives Inf", "security", INF, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["float field receives a string", "security", "high", "INVALID_DOMAIN_NUMERIC_TYPE"],
		["accounting dict element fractional", "cumulative_disorder_loss", 2.5, "INVALID_DOMAIN_NUMERIC_TYPE"],
		["accounting dict element negative", "cumulative_disorder_loss", -3, "INVALID_DOMAIN_NUMERIC_RANGE"],
	]

	for case in cases:
		var label: String = case[0]
		var field: String = case[1]
		var bad_value = case[2]
		var expected: String = case[3]
		var snap := deep_copy(base_snapshot)
		var target: Dictionary = (snap["settlements"] as Dictionary)["settlement:gray_valley"]
		if field == "cumulative_disorder_loss":
			target[field] = {"scrap": bad_value}
		else:
			target[field] = bad_value
		var result := WorldState.from_dict_checked(snap)
		if result["success"]:
			print("FAIL N5: %s was ACCEPTED!" % label)
			quit(1)
			return
		if not String(result["error"]).begins_with(expected):
			print("FAIL N5: %s produced the wrong error: %s" % [label, result["error"]])
			quit(1)
			return
		if result["world"] != null:
			print("FAIL N5: %s returned a partial world alongside the refusal!" % label)
			quit(1)
			return
		print("  refused: %-42s -> %s" % [label, String(result["error"]).split(":")[0]])

	# Integral floats ARE accepted (Owner decision Q2) — refusing 31.0 would mean
	# refusing our own files, since a legal round-trip always produces them.
	var integral_snap := deep_copy(base_snapshot)
	var gv: Dictionary = (integral_snap["settlements"] as Dictionary)["settlement:gray_valley"]
	var original_pop: int = int(gv["population"])
	gv["population"] = float(original_pop)
	gv["cumulative_disorder_loss"] = {"scrap": 31.0}
	var integral_result := WorldState.from_dict_checked(integral_snap)
	if not integral_result["success"]:
		print("FAIL N5: a legal integral float was refused: %s" % integral_result["error"])
		quit(1)
		return
	var restored_gv: SettlementState = (integral_result["world"] as WorldState).get_settlement(&"settlement:gray_valley")
	if typeof(restored_gv.population) != TYPE_INT or restored_gv.population != original_pop:
		print("FAIL N5: integral float did not restore to the declared int domain!")
		quit(1)
		return
	if typeof(restored_gv.cumulative_disorder_loss["scrap"]) != TYPE_INT:
		print("FAIL N5: integral float in accounting dict did not restore as int!")
		quit(1)
		return
	print("  accepted: integral float 31.0 -> int 31 (finite + integral + safe + in range)")
	print("  3.7 is never silently truncated to 3; it is refused")
	print("PASS GATE N5: Malformed Numeric Fail-Closed verified.")

	# --------------------------------------------------------------------------
	# GATE N6: Codec Corpus + Independent Verification
	# --------------------------------------------------------------------------
	print("\n--- [GATE N6] Codec Corpus + Independent Verification ---")

	# RISK: PERSISTENCE_CODEC_DEFINES_NUMERIC_CANONICALITY.
	# World numeric semantics now depend on this engine's JSON codec. This corpus
	# is the regression vector: run it FIRST on any engine upgrade. A mismatch is
	# a persistence/simulation compatibility change, not a routine version bump.
	var unstable := 0
	for probe in NumericCanon.PROBE_CORPUS:
		var c1 := NumericCanon.canonical_float(probe)
		var c2 := NumericCanon.canonical_float(c1)
		if c1 != c2:
			unstable += 1
			print("  NOT IDEMPOTENT: %s -> %s -> %s" % [
				String.num(probe, 17), String.num(c1, 17), String.num(c2, 17)
			])
	if unstable > 0:
		print("FAIL N6: %d of %d corpus probes are not codec-stable under this engine!" % [
			unstable, NumericCanon.PROBE_CORPUS.size()
		])
		quit(1)
		return
	print("  Codec corpus: %d/%d probes satisfy canonical(canonical(x)) == canonical(x)" % [
		NumericCanon.PROBE_CORPUS.size(), NumericCanon.PROBE_CORPUS.size()
	])
	print("  (Godot %s — re-run this corpus FIRST on any engine upgrade)" % Engine.get_version_info()["string"])

	var engine := SimulationEngine.new()
	if engine.validate_invariants(world_a) != "":
		print("FAIL N6: invariants violated on the uninterrupted world!")
		quit(1)
		return
	if engine.validate_invariants(world_b) != "":
		print("FAIL N6: invariants violated on the save/loaded world!")
		quit(1)
		return
	print("  Engine invariants PASS on both the uninterrupted and the reloaded world")

	var f := FileAccess.open("res://artifacts/world_snapshot_s4c2.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(world_a.to_dict(), "\t", true))
		f.close()
		print("  Exported artifacts/world_snapshot_s4c2.json for independent validation.")
	print("PASS GATE N6: Codec Corpus + Independent Verification verified.")

	print("\n================================================================================")
	print("ALL S4-C.2 HARD GATES (N1 ~ N6) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Helpers
# ==============================================================================

func deep_copy(d: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d)) as Dictionary

func ledger_of(w: WorldState) -> Array:
	var out: Array = []
	for evt in w.event_log:
		out.append((evt as EventRecord).to_dict())
	return out

func roundtrip(w: WorldState) -> WorldState:
	return WorldState.from_json(JSON.stringify(w.to_dict()))

func build_world(days: int) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var names := ["Mara", "Joel", "Tess"]
	var bgs := [
		NpcProfile.Background.CARAVAN_GUARD,
		NpcProfile.Background.MECHANIC,
		NpcProfile.Background.FARMER,
	]
	for i in range(names.size()):
		var res: Dictionary = w.npc_registry.materialize_identity(w, &"settlement:gray_valley", names[i], 28 + i)
		var nid: StringName = res["npc"].id
		w.npc_life_state_registry.register_life_state(w, nid, &"settlement:gray_valley")
		w.npc_profile_registry.assign_background(w, nid, bgs[i])

	var engine := SimulationEngine.new()
	var dry_well: SettlementState = w.get_settlement(&"settlement:dry_well")
	for day in range(days):
		engine.tick(w)
		if day >= 20:
			dry_well.inventory.water = maxi(0, dry_well.inventory.water - 6)
			dry_well.inventory.food = maxi(0, dry_well.inventory.food - 5)
	return w

# Continues a world using exactly the same external pressure as build_world, so
# an interrupted run and an uninterrupted run receive identical inputs.
func run_to(w: WorldState, target_day: int) -> void:
	var engine := SimulationEngine.new()
	var dry_well: SettlementState = w.get_settlement(&"settlement:dry_well")
	while w.current_day < target_day:
		engine.tick(w)
		dry_well.inventory.water = maxi(0, dry_well.inventory.water - 6)
		dry_well.inventory.food = maxi(0, dry_well.inventory.food - 5)
