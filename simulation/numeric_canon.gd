class_name NumericCanon
extends RefCounted

# ==============================================================================
# S4-C.2: PERSISTENCE-CODEC NUMERIC CANONICALITY
# ==============================================================================
# Decided by Owner after N0 evidence (artifacts/s4c2_n0_evidence.txt):
#
#   canonical_float(x) := JSON.parse_string(JSON.stringify(x))
#
# WHY NOT A DIGIT COUNT:
#   N0 measured that Godot's JSON.stringify writes 15 significant digits, so
#   7 of 8 full-precision doubles did NOT survive a round-trip exactly — and
#   neither did already-quantized values (snapped(99.994, 0.01) = 99.990000000000009
#   writes as "99.99" and parses back as 99.989999999999995). "Round to N places"
#   would have looked tidy and still diverged. Passing the value through the
#   persistence codec itself was idempotent for 17 of 17 probes, so canonical
#   precision is DEFINED BY THE FORMAT THE STATE IS STORED IN, not invented.
#
# WHERE IT IS APPLIED:
#   At the END-OF-DAY state commit boundary, once per tick, after the day's
#   physics and before invariant validation. Every committed day is therefore
#   already persistence-canonical, and the next day always starts from a
#   canonical value. Save is then a faithful recording, never a repair:
#
#     Phase 0..N physics -> Canonical Numeric Commit -> Invariants -> committed day
#
#   NOT this (the pattern N0 caught and Owner rejected):
#     runtime 5.666666... -> save-time snapped() -> 5.67   [two truths]
#
# WHAT THIS IS NOT:
#   It is not a domain rule. The old snapped(0.01)/snapped(0.0001) calls in
#   to_dict() were serialization tidiness and were NOT promoted to world physics:
#   there is no evidence that water pressure or security are inherently 2-decimal
#   quantities. How a number is DISPLAYED is a UI concern; how it SURVIVES
#   save/load is a persistence concern; what it MEANS is a domain rule. Three
#   separate layers.
#
# RISK (recorded, not a blocker): PERSISTENCE_CODEC_DEFINES_NUMERIC_CANONICALITY
#   World numeric semantics now depend on Godot 4.7.2's JSON codec. If a future
#   engine upgrade changes its formatting, the world's numeric trajectory can
#   change too. PROBE_CORPUS below is the regression vector for that: run it
#   FIRST on any engine upgrade. A mismatch is not a routine dependency bump —
#   it is a persistence/simulation compatibility change.
# ==============================================================================

# Beyond 2^53 - 1 a JSON number cannot round-trip as an exact integer.
const MAX_SAFE_INT: int = 9007199254740991

# Codec-stability regression corpus. These are the N0 probe values; every one of
# them must satisfy canonical(canonical(x)) == canonical(x) under the engine's
# JSON codec. See test_s4_c2_numeric.gd (Gate N6).
const PROBE_CORPUS: Array[float] = [
	0.3333333333333333,
	0.6666666666666666,
	5.666666666666667,
	0.30000000000000004,
	4.88498130835069e-15,
	0.6299999999999999,
	14.285714285714286,
	1e-16,
	99.994,
	99.99000000000001,
	1e20,
	-7.7777777777,
	0.0,
	123456.78901234568,
	2.857142857142857e-09,
	-0.5,
	1.0,
]

# ── Canonicalization ──────────────────────────────────────────────────────────

# The authoritative canonical form of a float: what the persistence codec will
# faithfully store and return. Non-finite values are NOT canonicalizable and are
# returned unchanged so that validation can reject them explicitly rather than
# having them silently become 0.
static func canonical_float(x: float) -> float:
	if is_nan(x) or is_inf(x):
		return x
	var parsed = JSON.parse_string(JSON.stringify(x))
	if parsed == null:
		return x
	return float(parsed)

static func is_canonical_float(x: float) -> bool:
	if is_nan(x) or is_inf(x):
		return false
	return canonical_float(x) == x

# Canonicalize every float inside a Dictionary[*, float], preserving keys.
static func canonical_float_dict(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d:
		var v = d[k]
		if typeof(v) == TYPE_FLOAT:
			out[k] = canonical_float(v)
		elif typeof(v) == TYPE_INT:
			out[k] = canonical_float(float(v))
		else:
			out[k] = v
	return out

# ── Schema-aware restoration (fail-closed) ────────────────────────────────────
# Owner decision Q2: a legal round-trip of an int field necessarily yields an
# integral float (31 -> 31.0), so refusing it would mean refusing our own files.
# It is accepted ONLY under all four conditions:
#     finite AND mathematically integral AND within safe-integer range
#     AND within the domain range
# 3.7 is never silently truncated to 3; it is refused.

static func restore_int(raw: Variant, path: String, min_value: int = -MAX_SAFE_INT, max_value: int = MAX_SAFE_INT) -> Dictionary:
	match typeof(raw):
		TYPE_INT:
			if raw < min_value or raw > max_value:
				return _err("INVALID_DOMAIN_NUMERIC_RANGE: %s = %d is outside [%d, %d]" % [path, raw, min_value, max_value])
			return {"ok": true, "value": int(raw), "error": ""}
		TYPE_FLOAT:
			if is_nan(raw):
				return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is NaN" % path)
			if is_inf(raw):
				return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is infinite" % path)
			if raw != floor(raw):
				return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s = %s is declared int but is fractional" % [path, str(raw)])
			if absf(raw) > float(MAX_SAFE_INT):
				return _err("INVALID_DOMAIN_NUMERIC_RANGE: %s = %s exceeds the safe integer range" % [path, str(raw)])
			var as_int := int(raw)
			if as_int < min_value or as_int > max_value:
				return _err("INVALID_DOMAIN_NUMERIC_RANGE: %s = %d is outside [%d, %d]" % [path, as_int, min_value, max_value])
			return {"ok": true, "value": as_int, "error": ""}
		_:
			return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is declared int but is %s" % [path, type_string(typeof(raw))])

static func restore_float(raw: Variant, path: String) -> Dictionary:
	match typeof(raw):
		TYPE_INT:
			return {"ok": true, "value": canonical_float(float(raw)), "error": ""}
		TYPE_FLOAT:
			if is_nan(raw):
				return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is NaN" % path)
			if is_inf(raw):
				return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is infinite" % path)
			return {"ok": true, "value": canonical_float(raw), "error": ""}
		_:
			return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is declared float but is %s" % [path, type_string(typeof(raw))])

# Dictionary[StringName, int] — e.g. cumulative_disorder_loss (ACCOUNTING STATE).
static func restore_int_dict(raw: Variant, path: String, min_value: int = -MAX_SAFE_INT) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is declared a dictionary but is %s" % [path, type_string(typeof(raw))])
	var out: Dictionary = {}
	for k in raw:
		var r := restore_int(raw[k], "%s.%s" % [path, String(k)], min_value)
		if not r["ok"]:
			return r
		out[k] = r["value"]
	return {"ok": true, "value": out, "error": ""}

# Dictionary[StringName, float] — e.g. production_credits (AUTHORITATIVE STATE).
static func restore_float_dict(raw: Variant, path: String) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return _err("INVALID_DOMAIN_NUMERIC_TYPE: %s is declared a dictionary but is %s" % [path, type_string(typeof(raw))])
	var out: Dictionary = {}
	for k in raw:
		var r := restore_float(raw[k], "%s.%s" % [path, String(k)])
		if not r["ok"]:
			return r
		out[k] = r["value"]
	return {"ok": true, "value": out, "error": ""}

static func _err(message: String) -> Dictionary:
	return {"ok": false, "value": null, "error": message}

# ── Snapshot numeric schema (validate-before-commit) ──────────────────────────
# Declared domain types for every authoritative numeric field. Restoration is
# driven by THIS declaration, never by what a serialized value happens to look
# like. A generic "recursive_fix_all_numbers()" that treated 3.0 as an int would
# overwrite domain truth with a guess, so it does not exist here.
#
# Validation runs over the RAW snapshot BEFORE any object is constructed, so an
# invalid snapshot yields no partial world (project Axiom 13).

const SETTLEMENT_INT_FIELDS := {
	"population": 0,
	"maintenance_scrap": 0,
	"maintenance_fuel": 0,
	"reference_population": 0,
	"days_since_last_migration": 0,
	"cumulative_deaths": 0,
	"target_water": 0,
	"target_food": 0,
	"target_scrap": 0,
	"target_fuel": 0,
}

const SETTLEMENT_FLOAT_FIELDS := [
	"metabolism_water_rate", "metabolism_food_rate",
	"water_pressure", "food_pressure",
	"water_exposure", "food_exposure",
	"security",
	"base_price_water", "base_price_food", "base_price_scrap", "base_price_fuel",
	"price_water", "price_food", "price_scrap", "price_fuel",
]

const RESOURCE_FIELDS := ["water", "food", "scrap", "fuel"]

const CARAVAN_INT_FIELDS := {
	"capacity_total": 0,
	"capacity_water": 0,
	"route_days": 0,
	"days_remaining": -MAX_SAFE_INT,
}

const REFUGEE_INT_FIELDS := {
	"headcount": -MAX_SAFE_INT,
	"route_days": 0,
	"days_remaining": -MAX_SAFE_INT,
	"departure_day": 0,
}

const WORLD_INT_FIELDS := {
	"current_day": 0,
	"next_npc_sequence": 1,
	"event_count": 0,
}

# Returns "" when every declared numeric field is restorable, else the first error.
static func validate_world_numerics(data: Dictionary) -> String:
	for field in WORLD_INT_FIELDS:
		if data.has(field):
			var r := restore_int(data[field], "world.%s" % field, WORLD_INT_FIELDS[field])
			if not r["ok"]:
				return r["error"]

	if data.has("settlements"):
		if typeof(data["settlements"]) != TYPE_DICTIONARY:
			return "INVALID_DOMAIN_NUMERIC_TYPE: world.settlements is not an object"
		for s_id in data["settlements"]:
			var err := _validate_settlement(data["settlements"][s_id], "settlements.%s" % String(s_id))
			if err != "":
				return err

	if data.has("caravans"):
		for c_id in data["caravans"]:
			var err_c := _validate_fields(data["caravans"][c_id], "caravans.%s" % String(c_id), CARAVAN_INT_FIELDS, [], ["cargo"])
			if err_c != "":
				return err_c

	if data.has("refugees"):
		for r_id in data["refugees"]:
			var err_r := _validate_fields(data["refugees"][r_id], "refugees.%s" % String(r_id), REFUGEE_INT_FIELDS, [], [])
			if err_r != "":
				return err_r

	if data.has("npc_registry"):
		for n_id in data["npc_registry"]:
			var npc = data["npc_registry"][n_id]
			if typeof(npc) == TYPE_DICTIONARY and npc.has("age_at_materialization"):
				var r_age := restore_int(npc["age_at_materialization"], "npc_registry.%s.age_at_materialization" % String(n_id), 0)
				if not r_age["ok"]:
					return r_age["error"]

	# QUEST-1: validate player progression int fields (xp, growth_points)
	if data.has("player") and typeof(data["player"]) == TYPE_DICTIONARY:
		var p_data: Dictionary = data["player"]
		for prog_field in ["xp", "growth_points"]:
			if p_data.has(prog_field):
				var r_p := restore_int(p_data[prog_field], "player.%s" % prog_field, 0)
				if not r_p["ok"]:
					return r_p["error"]

	return ""


static func _validate_settlement(s: Variant, path: String) -> String:
	if typeof(s) != TYPE_DICTIONARY:
		return "INVALID_DOMAIN_NUMERIC_TYPE: %s is not an object" % path

	var err := _validate_fields(s, path, SETTLEMENT_INT_FIELDS, SETTLEMENT_FLOAT_FIELDS, ["inventory", "production", "consumption"])
	if err != "":
		return err

	# production_credits / disorder_loss_credits: Dictionary[StringName, float]
	#   AUTHORITATIVE SIMULATION STATE (carry accumulation read by later ticks).
	for credit_field in ["production_credits", "disorder_loss_credits"]:
		if s.has(credit_field):
			var rc := restore_float_dict(s[credit_field], "%s.%s" % [path, credit_field])
			if not rc["ok"]:
				return rc["error"]

	# cumulative_disorder_loss: Dictionary[StringName, int]
	#   ACCOUNTING STATE — no simulation-control authority (N0 Q3, Owner-confirmed).
	#   Potential future normalization: may be derivable from the authoritative
	#   event ledger. No action in S4-C.2.
	if s.has("cumulative_disorder_loss"):
		var rd := restore_int_dict(s["cumulative_disorder_loss"], "%s.cumulative_disorder_loss" % path, 0)
		if not rd["ok"]:
			return rd["error"]

	return ""

static func _validate_fields(obj: Variant, path: String, int_fields: Dictionary, float_fields: Array, resource_fields: Array) -> String:
	if typeof(obj) != TYPE_DICTIONARY:
		return "INVALID_DOMAIN_NUMERIC_TYPE: %s is not an object" % path
	for field in int_fields:
		if obj.has(field):
			var r := restore_int(obj[field], "%s.%s" % [path, field], int_fields[field])
			if not r["ok"]:
				return r["error"]
	for field in float_fields:
		if obj.has(field):
			var rf := restore_float(obj[field], "%s.%s" % [path, field])
			if not rf["ok"]:
				return rf["error"]
	for field in resource_fields:
		if obj.has(field):
			var res = obj[field]
			if typeof(res) != TYPE_DICTIONARY:
				return "INVALID_DOMAIN_NUMERIC_TYPE: %s.%s is not an object" % [path, field]
			for r_name in RESOURCE_FIELDS:
				if res.has(r_name):
					var rr := restore_int(res[r_name], "%s.%s.%s" % [path, field, r_name], 0)
					if not rr["ok"]:
						return rr["error"]
	return ""
