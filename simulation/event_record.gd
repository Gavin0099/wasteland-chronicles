class_name EventRecord
extends RefCounted

# ==============================================================================
# COMMITTED WORLD FACT
# ==============================================================================
# An EventRecord is a fact that HAS HAPPENED. The ordered ledger of these
# records is the single authority for historical world facts (S4-C.1).
#
# S4-C.1 SCOPE LOCK — this record stays minimal, deliberately:
#   NO event_id, NO sequence_number, NO parent_event_id,
#   NO NPC memory links, NO narrative text, NO index.
# If event identity later proves genuinely necessary, it opens a new slice
# backed by evidence — it is not added speculatively here.
#
# PAYLOAD VALUE MODEL (S4-C.1):
#   The ledger persists as JSON, whose value model has exactly ONE numeric
#   type. Godot writes int 4 as `4` but JSON.parse_string returns 4.0, so an
#   un-normalized ledger is not a serialization fixed point: save → load → save
#   produces a DIFFERENT file than the first save. For an audit ledger that is
#   unacceptable, so payloads are canonicalized to the JSON value model at the
#   moment of commit. In-memory and persisted forms are then identical, and
#   round-tripping is idempotent.
#
#   Canonical payload value types: float, bool, String, Array, Dictionary, null.
#   int and StringName are converted at commit; anything else is left untouched
#   and reported by the ledger invariant rather than silently mangled.
# ==============================================================================

# Integers beyond 2^53 cannot survive the JSON number model exactly. Converting
# one would silently corrupt a committed fact, so such a value is left as-is and
# flagged by validation instead.
const MAX_EXACT_JSON_INT: int = 9007199254740992  # 2^53

var day: int = 0
var type: String = ""
var actor_id: StringName = &""
var target_id: StringName = &""
var payload: Dictionary = {}

func _init(
	p_day: int = 0,
	p_type: String = "",
	p_actor_id: StringName = &"",
	p_target_id: StringName = &"",
	p_payload: Dictionary = {}
) -> void:
	day = p_day
	type = p_type
	actor_id = p_actor_id
	target_id = p_target_id
	payload = p_payload

func duplicate_record() -> EventRecord:
	return EventRecord.new(day, type, actor_id, target_id, payload.duplicate(true))

# ── Canonical payload value model ─────────────────────────────────────────────

# Recursively convert a payload value into the JSON value model so that the
# committed form and the reloaded form are identical. Structure, ordering of
# array elements, and dictionary keys are preserved exactly.
static func canonicalize_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_INT:
			# Out-of-range integers are NOT converted: a lossy conversion would
			# corrupt a committed fact. Validation reports them instead.
			if absi(value) > MAX_EXACT_JSON_INT:
				return value
			return float(value)
		TYPE_FLOAT:
			# S4-C.2: a payload float is a recorded observation of world state, so
			# it is stored in the same canonical form the world itself commits.
			return NumericCanon.canonical_float(value)
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY:
			var out_d: Dictionary = {}
			for k in value:
				var key_str: Variant = String(k) if typeof(k) == TYPE_STRING_NAME else k
				out_d[key_str] = canonicalize_value(value[k])
			return out_d
		TYPE_ARRAY:
			var out_a: Array = []
			for item in value:
				out_a.append(canonicalize_value(item))
			return out_a
		_:
			return value

static func canonicalize_payload(p: Dictionary) -> Dictionary:
	return canonicalize_value(p) as Dictionary

# Apply the canonical value model to this record in place. Called once, when the
# record enters the ledger.
func canonicalize() -> void:
	payload = canonicalize_payload(payload)

# ── Validation (fail-closed, used by both the engine invariant and loading) ───

# Returns "" when the value is representable in the ledger's persisted model.
static func validate_value(value: Variant, path: String) -> String:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_FLOAT, TYPE_STRING:
			return ""
		TYPE_INT:
			if absi(value) > MAX_EXACT_JSON_INT:
				return "payload value at %s is an integer beyond the exact JSON range (%d)" % [path, value]
			return ""
		TYPE_DICTIONARY:
			for k in value:
				if typeof(k) != TYPE_STRING and typeof(k) != TYPE_STRING_NAME:
					return "payload key at %s is not a string" % path
				var err := validate_value(value[k], "%s.%s" % [path, String(k)])
				if err != "":
					return err
			return ""
		TYPE_ARRAY:
			for i in range(value.size()):
				var err_a := validate_value(value[i], "%s[%d]" % [path, i])
				if err_a != "":
					return err_a
			return ""
		_:
			return "payload value at %s has unsupported type %d" % [path, typeof(value)]

func validate() -> String:
	if type == "":
		return "EventRecord has an empty type"
	return validate_value(payload, "payload")

# Structural check of a SERIALIZED record, before it is trusted enough to load.
static func validate_dict(data: Variant, index: int) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "events[%d] is not an object" % index
	for field in ["day", "type", "actor_id", "target_id", "payload"]:
		if not data.has(field):
			return "events[%d] is missing required field '%s'" % [index, field]
	if typeof(data["payload"]) != TYPE_DICTIONARY:
		return "events[%d].payload is not an object" % index
	if String(data["type"]) == "":
		return "events[%d] has an empty type" % index
	return ""

# ── Serialization ──────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"day": day,
		"type": type,
		"actor_id": String(actor_id),
		"target_id": String(target_id),
		"payload": payload
	}

static func from_dict(data: Dictionary) -> EventRecord:
	var rec := EventRecord.new(
		int(data.get("day", 0)),
		String(data.get("type", "")),
		StringName(data.get("actor_id", "")),
		StringName(data.get("target_id", "")),
		(data.get("payload", {}) as Dictionary).duplicate(true)
	)
	rec.canonicalize()
	return rec
