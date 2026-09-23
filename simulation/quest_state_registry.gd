class_name QuestStateRegistry
extends RefCounted

# ==============================================================================
# QUEST-1C: QUEST STATE REGISTRY (container for all tracked quest instances)
# ==============================================================================
# Holds only quests that have been DISCOVERED, ACCEPTED, or ENDED.
# Unknown quests (still purely LOCKED and never seen by the player) are absent.
#
# is_empty() drives the omit-if-empty serialization in WorldState.to_dict(),
# so old saves without quest_state produce the same JSON bytes they always did.
# ==============================================================================

const QState = preload("res://simulation/quest_state.gd")

var _quests: Dictionary = {}  # String -> QuestState

# ── Query ─────────────────────────────────────────────────────────────────────

func has_quest(id: String) -> bool:
	return _quests.has(id)

func get_quest(id: String) -> RefCounted:
	return _quests.get(id, null)

func all_quest_ids() -> Array:
	var ids: Array = _quests.keys()
	ids.sort()
	return ids

func is_empty() -> bool:
	return _quests.is_empty()

# ── Mutation ──────────────────────────────────────────────────────────────────

func set_quest(qs: RefCounted) -> void:
	_quests[qs.quest_id] = qs

# ── Serialization ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for id in all_quest_ids():  # sorted for stability
		result[id] = (_quests[id] as RefCounted).to_dict()
	return result

static func from_dict(data: Dictionary) -> RefCounted:
	var reg = load("res://simulation/quest_state_registry.gd").new()
	for id in data:
		var entry: Variant = data[id]
		if typeof(entry) == TYPE_DICTIONARY:
			reg._quests[id] = QState.from_dict(id, entry)
	return reg

# Validate every entry before constructing anything (fail-closed load discipline).
static func validate_dict(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "QUEST_STATE_REGISTRY_NOT_DICT"
	for id in data:
		var err := QState.validate_dict(id, data[id])
		if err != "":
			return err
	return ""

# ── Duplication ───────────────────────────────────────────────────────────────

func duplicate_registry() -> RefCounted:
	var copy = get_script().new()
	for id in _quests:
		copy._quests[id] = (_quests[id] as RefCounted).duplicate_state()
	return copy
