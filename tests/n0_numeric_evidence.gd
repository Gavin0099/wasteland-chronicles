extends SceneTree

# ==============================================================================
# S4-C.2 / N0 — NUMERIC AUTHORITY CLASSIFICATION (EVIDENCE HARNESS)
# ==============================================================================
# This is an INVESTIGATION TOOL, not an acceptance gate. It answers, with
# measurements rather than code-reading alone:
#
#   1. declared domain type
#   2. actual runtime value distribution
#   3. is it read by a LATER simulation tick?      (perturbation probe)
#   4. authoritative simulation state, or accounting/observational?
#   5. which arithmetic produces it
#   6. JSON representation before and after round-trip
#   7. does the round-trip difference cause Day N+1+ divergence?  (isolation probe)
#
# NOTHING is fixed here. No precision policy is chosen here.
# ==============================================================================

const FIELDS := ["production_credits", "disorder_loss_credits", "cumulative_disorder_loss", "last_need_outcomes"]

var report_lines: Array[String] = []

func say(line: String) -> void:
	print(line)
	report_lines.append(line)

func _init() -> void:
	say("================================================================================")
	say("   S4-C.2 / N0 — NUMERIC AUTHORITY CLASSIFICATION (EVIDENCE, NOT DECISIONS)")
	say("================================================================================")

	# --------------------------------------------------------------------------
	# STEP 1 — Does the persistence boundary change the world at all?
	# --------------------------------------------------------------------------
	say("\n## STEP 1 — Baseline: is save/load already a divergence event?")

	var a := build_world(50)
	var b_loaded := roundtrip(a)
	if b_loaded == null:
		say("  !! loader REFUSED the snapshot — cannot proceed")
		quit(1)
		return

	var hash_live := a.to_canonical_json().sha256_text()
	var hash_loaded := b_loaded.to_canonical_json().sha256_text()
	say("  Day 50 live   canonical SHA: %s" % hash_live)
	say("  Day 50 loaded canonical SHA: %s" % hash_loaded)
	say("  Snapshot fixed point at Day 50: %s" % ("YES" if hash_live == hash_loaded else "NO"))

	# Continue both and see whether the futures diverge, and when.
	var first_divergence := find_first_divergence(50, 100)
	if first_divergence < 0:
		say("  Continuation Day 50 -> 100: NO DIVERGENCE detected")
	else:
		say("  Continuation Day 50 -> 100: FIRST DIVERGENCE at Day %d" % first_divergence)

	# --------------------------------------------------------------------------
	# STEP 2 — Per-field observation: declared type, runtime values, JSON behavior
	# --------------------------------------------------------------------------
	say("\n## STEP 2 — Per-field runtime values and JSON round-trip behavior")

	var w := build_world(60)
	var w_json = JSON.parse_string(JSON.stringify(w.to_dict()))
	var w_loaded := roundtrip(w)

	for field in FIELDS:
		say("\n### %s" % field)
		var serialized_at_all := false
		for s_id in w.settlements:
			var s: SettlementState = w.settlements[s_id]
			var live_value: Dictionary = s.get(field)
			var raw_json = (w_json["settlements"][String(s_id)] as Dictionary).get(field, null)
			serialized_at_all = serialized_at_all or (raw_json != null)
			var loaded_s: SettlementState = w_loaded.get_settlement(s_id)
			var loaded_value: Dictionary = loaded_s.get(field)

			say("  [%s]" % s_id)
			if live_value.is_empty():
				say("    live   : (empty)")
			for k in live_value:
				var lv = live_value[k]
				var raw = null
				if raw_json != null and (raw_json as Dictionary).has(k):
					raw = (raw_json as Dictionary)[k]
				var loaded_v = loaded_value.get(k, null)
				say("    %-8s live=%s (%s) | json=%s (%s) | loaded=%s (%s)%s" % [
					String(k),
					fmt(lv), type_name(lv),
					fmt(raw), type_name(raw),
					fmt(loaded_v), type_name(loaded_v),
					"   <-- TYPE CHANGED" if type_name(lv) != type_name(loaded_v) else ""
				])
		if not serialized_at_all:
			say("    NOTE: field is NOT PRESENT in the serialized snapshot at all.")

	# --------------------------------------------------------------------------
	# STEP 3 — Authority probe: does a LATER tick read this field?
	# --------------------------------------------------------------------------
	say("\n## STEP 3 — Authority probe (perturb the field, then run 30 more days)")
	say("  Method: take an identical Day 60 world, perturb ONLY this field, continue")
	say("  to Day 90, and compare canonical hashes. A change in the future means the")
	say("  field is read by later simulation; no change means it is inert downstream.")

	for field in FIELDS:
		var control := build_world(60)
		var probe := build_world(60)
		perturb_field(probe, field)
		run_to(control, 90)
		run_to(probe, 90)
		var same := control.to_canonical_json().sha256_text() == probe.to_canonical_json().sha256_text()
		say("  %-26s perturbed -> Day 90 %s" % [
			field,
			"IDENTICAL  (not read by later ticks / inert)" if same else "DIVERGED   (authoritative simulation state)"
		])

	# --------------------------------------------------------------------------
	# STEP 4 — Causation probe: does THIS field's round-trip delta cause divergence?
	# --------------------------------------------------------------------------
	say("\n## STEP 4 — Causation probe (apply ONLY this field's round-trip delta)")
	say("  Method: at Day 60, copy the round-tripped value of a single field back into")
	say("  an otherwise-live world, run to Day 90, and compare with the untouched world.")

	for field in FIELDS:
		var control2 := build_world(60)
		var probe2 := build_world(60)
		var rt := roundtrip(probe2)
		if rt == null:
			say("  %-26s loader refused snapshot" % field)
			continue
		var applied := apply_field_from(probe2, rt, field)
		run_to(control2, 90)
		run_to(probe2, 90)
		var same2 := control2.to_canonical_json().sha256_text() == probe2.to_canonical_json().sha256_text()
		say("  %-26s delta applied=%s -> Day 90 %s" % [
			field,
			("yes" if applied else "no-op (identical values)"),
			"IDENTICAL  (round-trip delta is harmless)" if same2 else "DIVERGED   (round-trip delta changes the future)"
		])

	# --------------------------------------------------------------------------
	# STEP 5 — Whole-snapshot residual diff: what else is not a fixed point?
	# --------------------------------------------------------------------------
	say("\n## STEP 5 — Residual whole-snapshot differences (all fields, not just the four)")
	var w5 := build_world(100)
	var json_a := JSON.stringify(w5.to_dict(), "\t", true)
	var l5 := WorldState.from_dict(JSON.parse_string(json_a))
	var json_b := JSON.stringify(l5.to_dict(), "\t", true)
	var la := json_a.split("\n")
	var lb := json_b.split("\n")
	var diffs := 0
	var diff_keys := {}
	for i in range(mini(la.size(), lb.size())):
		if la[i] != lb[i]:
			diffs += 1
			var key := la[i].strip_edges().split(":")[0]
			diff_keys[key] = diff_keys.get(key, 0) + 1
			if diffs <= 12:
				say("  line %d:\n    A: %s\n    B: %s" % [i, la[i].strip_edges(), lb[i].strip_edges()])
	say("  TOTAL differing lines: %d (of %d)" % [diffs, la.size()])
	if diffs > 0:
		say("  Differing keys by frequency:")
		var keys := diff_keys.keys()
		keys.sort()
		for k in keys:
			say("    %-30s x%d" % [String(k), diff_keys[k]])

	# --------------------------------------------------------------------------
	# STEP 6 — Representation vs trajectory
	# --------------------------------------------------------------------------
	# STEP 3 and STEP 4 compare canonical TEXT, so `31` vs `31.0` registers as
	# "DIVERGED" even when the simulation behaved identically. That distinction
	# decides whether this slice needs a float precision policy at all, so it
	# must be measured, not assumed.
	say("\n## STEP 6 — Is the divergence representational, or a real trajectory split?")
	say("  Method: compare Day 100 worlds semantically — numbers compared BY VALUE,")
	say("  ignoring int/float representation. Textual difference with semantic equality")
	say("  means the world behaved identically and only its spelling changed.")

	var sem_a := build_world(50)
	var sem_b := roundtrip(build_world(50))
	run_to(sem_a, 100)
	run_to(sem_b, 100)

	var text_same := sem_a.to_canonical_json().sha256_text() == sem_b.to_canonical_json().sha256_text()
	var mismatch_path := semantic_diff(sem_a.to_dict(), sem_b.to_dict(), "world")
	say("  Day 100 canonical TEXT identical:      %s" % ("YES" if text_same else "NO"))
	say("  Day 100 SEMANTIC (by-value) identical: %s" % ("YES" if mismatch_path == "" else "NO"))
	if mismatch_path != "":
		say("  First semantic mismatch at: %s" % mismatch_path)
	else:
		say("  => The simulation trajectory is IDENTICAL. The difference is representational only.")

	# Ledger comparison on its own: history must not drift either.
	var ledger_a_sha := JSON.stringify(ledger_of(sem_a), "\t", true).sha256_text()
	var ledger_b_sha := JSON.stringify(ledger_of(sem_b), "\t", true).sha256_text()
	say("  Day 100 event ledger identical:        %s" % ("YES" if ledger_a_sha == ledger_b_sha else "NO"))
	say("    A = %s" % ledger_a_sha)
	say("    B = %s" % ledger_b_sha)

	# Does a loaded world break the engine's typed reads?
	say("\n## STEP 6b — Does a loaded world break typed reads in validate_invariants?")
	var engine6 := SimulationEngine.new()
	var inv_live := engine6.validate_invariants(sem_a)
	var inv_loaded := engine6.validate_invariants(sem_b)
	say("  invariants on live world  : %s" % ("PASS" if inv_live == "" else inv_live))
	say("  invariants on loaded world: %s" % ("PASS" if inv_loaded == "" else inv_loaded))

	# --------------------------------------------------------------------------
	# STEP 7 — Is quantization actually required, or could we persist full precision?
	# --------------------------------------------------------------------------
	# If full-precision doubles survive Godot's JSON round-trip exactly, the right
	# answer is to stop rounding at save time and persist exactly what runtime
	# holds — no precision policy needed at all. If they do NOT survive, then
	# quantization is forced, and the only question is where it happens.
	say("\n## STEP 7 — Does a full-precision double survive Godot JSON exactly?")
	var probes := [
		1.0 / 3.0,
		2.0 / 3.0,
		17.0 / 3.0,
		0.1 + 0.2,
		4.88498130835069e-15,
		0.6299999999999999,
		100.0 / 7.0,
		1e-16,
	]
	var lossy := 0
	for p in probes:
		var text := JSON.stringify(p)
		var back = JSON.parse_string(text)
		var exact: bool = (typeof(back) == TYPE_FLOAT or typeof(back) == TYPE_INT) and float(back) == p
		if not exact:
			lossy += 1
		say("    %-24s -> %-26s -> %-24s %s" % [
			String.num(p, 17), text, String.num(float(back), 17), "EXACT" if exact else "LOSSY"
		])
	say("  %d of %d full-precision probes did NOT survive exactly." % [lossy, probes.size()])

	# And the snapped values the codebase already persists:
	say("  Control — values already quantized to 0.01 by to_dict():")
	var snapped_probes := [snapped(1.0 / 3.0, 0.01), snapped(17.0 / 3.0, 0.01), snapped(99.994, 0.01)]
	var snapped_lossy := 0
	for p in snapped_probes:
		var back2 = JSON.parse_string(JSON.stringify(p))
		var exact2: bool = float(back2) == p
		if not exact2:
			snapped_lossy += 1
		say("    %-24s -> %-26s %s" % [String.num(p, 17), JSON.stringify(p), "EXACT" if exact2 else "LOSSY"])
	say("  %d of %d quantized probes did NOT survive exactly." % [snapped_lossy, snapped_probes.size()])

	# Candidate canonical operation: pass the value through the persistence codec
	# itself. If that is a fixed point, canonical precision needs no invented
	# digit count — it is defined by the format the state is stored in.
	say("  Candidate policy — canonical(x) := JSON.parse_string(JSON.stringify(x)):")
	var non_idempotent := 0
	for p in probes:
		var c1 := float(JSON.parse_string(JSON.stringify(p)))
		var c2 := float(JSON.parse_string(JSON.stringify(c1)))
		if c1 != c2:
			non_idempotent += 1
		say("    %-26s -> canonical %-26s %s" % [
			String.num(p, 17), String.num(c1, 17), "FIXED-POINT" if c1 == c2 else "NOT IDEMPOTENT"
		])
	say("  %d of %d canonicalized probes were NOT idempotent." % [non_idempotent, probes.size()])

	# Which authoritative fields are currently rounded AT SAVE TIME?
	say("\n## STEP 7b — Fields currently quantized inside to_dict() (save-time rounding)")
	say("  SettlementState.to_dict() applies snapped() to:")
	say("    metabolism_water_rate, metabolism_food_rate      (0.0001)")
	say("    water_pressure, food_pressure                    (0.01)")
	say("    water_exposure, food_exposure                    (0.01)")
	say("    security                                         (0.01)")
	say("    price_water, price_food, price_scrap, price_fuel (0.01)")
	say("  These are authoritative simulation state: the runtime world keeps the")
	say("  unrounded value while the snapshot keeps the rounded one, so a loaded")
	say("  world starts from a DIFFERENT number than the world that was saved.")

	# --------------------------------------------------------------------------
	say("\n================================================================================")
	say("N0 EVIDENCE COLLECTION COMPLETE — no policy chosen, no field modified.")
	say("================================================================================")

	var f := FileAccess.open("res://artifacts/s4c2_n0_evidence.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(report_lines))
		f.close()
		print("\n(evidence written to artifacts/s4c2_n0_evidence.txt)")
	quit(0)

# ==============================================================================
# Helpers
# ==============================================================================

func ledger_of(w: WorldState) -> Array:
	var out: Array = []
	for evt in w.event_log:
		out.append((evt as EventRecord).to_dict())
	return out

# Compare two serialized states by VALUE, treating 31 and 31.0 as equal.
# Returns "" when semantically identical, else the path of the first mismatch.
func semantic_diff(a, b, path: String) -> String:
	var ta := typeof(a)
	var tb := typeof(b)
	var a_num := ta == TYPE_INT or ta == TYPE_FLOAT
	var b_num := tb == TYPE_INT or tb == TYPE_FLOAT
	if a_num and b_num:
		if not is_equal_approx(float(a), float(b)) and float(a) != float(b):
			return "%s (%s vs %s)" % [path, str(a), str(b)]
		return ""
	if ta != tb:
		return "%s (type %s vs %s)" % [path, type_name(a), type_name(b)]
	if ta == TYPE_DICTIONARY:
		var keys_a := (a as Dictionary).keys()
		var keys_b := (b as Dictionary).keys()
		keys_a.sort()
		keys_b.sort()
		if keys_a != keys_b:
			return "%s (key sets differ)" % path
		for k in keys_a:
			var sub := semantic_diff(a[k], b[k], "%s.%s" % [path, String(k)])
			if sub != "":
				return sub
		return ""
	if ta == TYPE_ARRAY:
		if (a as Array).size() != (b as Array).size():
			return "%s (array size %d vs %d)" % [path, (a as Array).size(), (b as Array).size()]
		for i in range((a as Array).size()):
			var sub_a := semantic_diff(a[i], b[i], "%s[%d]" % [path, i])
			if sub_a != "":
				return sub_a
		return ""
	if a != b:
		return "%s (%s vs %s)" % [path, str(a), str(b)]
	return ""

func type_name(v) -> String:
	match typeof(v):
		TYPE_NIL: return "nil"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_BOOL: return "bool"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		_: return "type%d" % typeof(v)

func fmt(v) -> String:
	if v == null:
		return "-"
	if typeof(v) == TYPE_DICTIONARY or typeof(v) == TYPE_ARRAY:
		return JSON.stringify(v)
	return str(v)

func build_world(days: int) -> WorldState:
	var w := S1WorldData.create_s1_world()
	# Materialize named NPCs so identity / life state / profile layers participate.
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
	# Stress Dry Well so pressure, migration, mortality, security all engage.
	var dry_well: SettlementState = w.get_settlement(&"settlement:dry_well")
	for day in range(days):
		engine.tick(w)
		if day >= 20:
			dry_well.inventory.water = maxf(0.0, dry_well.inventory.water - 6.0)
			dry_well.inventory.food = maxf(0.0, dry_well.inventory.food - 5.0)
	return w

func run_to(w: WorldState, target_day: int) -> void:
	var engine := SimulationEngine.new()
	var dry_well: SettlementState = w.get_settlement(&"settlement:dry_well")
	while w.current_day < target_day:
		engine.tick(w)
		dry_well.inventory.water = maxf(0.0, dry_well.inventory.water - 6.0)
		dry_well.inventory.food = maxf(0.0, dry_well.inventory.food - 5.0)

func roundtrip(w: WorldState) -> WorldState:
	return WorldState.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))

# Run an uninterrupted world and a save/loaded world forward in lockstep,
# reporting the first day on which their canonical states differ.
func find_first_divergence(save_day: int, target_day: int) -> int:
	var uninterrupted := build_world(save_day)
	var interrupted := roundtrip(build_world(save_day))
	if interrupted == null:
		return save_day
	var engine_a := SimulationEngine.new()
	var engine_b := SimulationEngine.new()
	var dry_a: SettlementState = uninterrupted.get_settlement(&"settlement:dry_well")
	var dry_b: SettlementState = interrupted.get_settlement(&"settlement:dry_well")
	while uninterrupted.current_day < target_day:
		engine_a.tick(uninterrupted)
		dry_a.inventory.water = maxf(0.0, dry_a.inventory.water - 6.0)
		dry_a.inventory.food = maxf(0.0, dry_a.inventory.food - 5.0)
		engine_b.tick(interrupted)
		dry_b.inventory.water = maxf(0.0, dry_b.inventory.water - 6.0)
		dry_b.inventory.food = maxf(0.0, dry_b.inventory.food - 5.0)
		if uninterrupted.to_canonical_json().sha256_text() != interrupted.to_canonical_json().sha256_text():
			return uninterrupted.current_day
	return -1

# Nudge a field so we can see whether later ticks read it at all.
func perturb_field(w: WorldState, field: String) -> void:
	for s_id in w.settlements:
		var s: SettlementState = w.settlements[s_id]
		var d: Dictionary = s.get(field)
		for k in d.keys():
			var v = d[k]
			if typeof(v) == TYPE_FLOAT:
				d[k] = v + 0.25
			elif typeof(v) == TYPE_INT:
				d[k] = v + 7
			elif typeof(v) == TYPE_DICTIONARY:
				for k2 in (v as Dictionary).keys():
					if typeof(v[k2]) == TYPE_INT:
						v[k2] = v[k2] + 7
					elif typeof(v[k2]) == TYPE_FLOAT:
						v[k2] = v[k2] + 0.25

# Copy one field's round-tripped value back into the live world.
# Returns true when at least one value actually differed.
func apply_field_from(target: WorldState, source: WorldState, field: String) -> bool:
	var changed := false
	for s_id in target.settlements:
		var t: SettlementState = target.settlements[s_id]
		var src: SettlementState = source.get_settlement(s_id)
		if src == null:
			continue
		var before: Dictionary = t.get(field)
		var after: Dictionary = src.get(field)
		if not before.recursive_equal(after, 16):
			changed = true
		t.set(field, after.duplicate(true))
	return changed
