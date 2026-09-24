class_name QuestState
extends RefCounted

# ==============================================================================
# QUEST-1C: QUEST RUNTIME STATE (one instance per accepted/discovered quest)
# ==============================================================================
# Stores only WHAT HAS HAPPENED for a single quest: status, when accepted,
# when it expires, per-objective progress, and the reward-granted idempotency
# guard. Everything the player reads (title, objectives text, reward amounts)
# is looked up from QuestRegistry — never stored here.
#
# Only discovered / accepted / ended quests appear in QuestStateRegistry.
# Unknown quests are not serialized at all.
#
# Schema version: tracked at the registry level (quest_schema_version in world).
# ==============================================================================

const VALID_STATUSES: Array[StringName] = [
	&"LOCKED",
	&"AVAILABLE",
	&"ACTIVE",
	&"RESOLVED",
	&"FAILED",
	&"EXPIRED",
]

var quest_id: String = ""
var status: StringName = &"LOCKED"
var accepted_day: int = -1    # -1 = never accepted
var deadline_day: int = -1    # -1 = no deadline set yet
var progress: Dictionary = {} # objective_id -> completion value (type-dependent)
var reward_granted: bool = false  # idempotency guard — reward applied exactly once

func _init(id: String = "") -> void:
	quest_id = id

# ── Serialization ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var result := {
		"status": String(status),
		"accepted_day": accepted_day,
		"deadline_day": deadline_day,
		"reward_granted": reward_granted,
	}
	if not progress.is_empty():
		result["progress"] = progress.duplicate(true)
	return result

static func from_dict(id: String, data: Dictionary) -> RefCounted:
	var qs = load("res://simulation/quest_state.gd").new(id)
	var raw_status: Variant = data.get("status", "LOCKED")
	qs.status = StringName(raw_status) if typeof(raw_status) == TYPE_STRING else &"LOCKED"
	qs.accepted_day = int(data.get("accepted_day", -1))
	qs.deadline_day = int(data.get("deadline_day", -1))
	qs.reward_granted = bool(data.get("reward_granted", false))
	if data.has("progress") and typeof(data["progress"]) == TYPE_DICTIONARY:
		qs.progress = data["progress"].duplicate(true)
	return qs

# Validate the serialized data shape before constructing anything.
static func validate_dict(id: Variant, data: Variant) -> String:
	if typeof(id) != TYPE_STRING or id.is_empty():
		return "QUEST_STATE_INVALID_ID"
	if typeof(data) != TYPE_DICTIONARY:
		return "QUEST_STATE_NOT_DICT: %s" % str(id)
	var raw_status: Variant = data.get("status", "LOCKED")
	if typeof(raw_status) != TYPE_STRING or StringName(raw_status) not in VALID_STATUSES:
		return "QUEST_STATE_INVALID_STATUS: %s" % str(id)
	for ifield in ["accepted_day", "deadline_day"]:
		var iv: Variant = data.get(ifield, -1)
		if typeof(iv) not in [TYPE_INT, TYPE_FLOAT] or iv != floor(float(iv)) or float(iv) < -1.0:
			return "QUEST_STATE_INVALID_%s: %s" % [ifield.to_upper(), str(id)]
	if typeof(data.get("reward_granted", false)) != TYPE_BOOL:
		return "QUEST_STATE_INVALID_REWARD_GRANTED: %s" % str(id)
	return ""

# ── Duplication ───────────────────────────────────────────────────────────────

func duplicate_state() -> RefCounted:
	var copy = get_script().new(quest_id)
	copy.status = status
	copy.accepted_day = accepted_day
	copy.deadline_day = deadline_day
	copy.reward_granted = reward_granted
	copy.progress = progress.duplicate(true)
	return copy
