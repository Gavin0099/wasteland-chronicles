class_name QuestRegistry
extends RefCounted

# ==============================================================================
# QUEST-1B: QUEST REGISTRY
# ==============================================================================
# Static registry of QuestDefinitions — the authored catalog.
# QUEST-1 ships with an EMPTY catalog. Real quests are added in QUEST-2.
#
# Pattern mirrors ItemRegistry: static methods only, definitions validated on
# read, fail-closed on any malformed entry.
# ==============================================================================

const Definition = preload("res://simulation/quest_definition.gd")

# ── Internal catalog (EMPTY in QUEST-1; QUEST-2 will fill this) ───────────────
static func _catalog() -> Array:
	return []

# ── Public API ────────────────────────────────────────────────────────────────

static func all_definitions() -> Array:
	var result: Array = []
	for raw in _catalog():
		var err := Definition.validate_definition(raw)
		if err != "":
			push_error("QuestRegistry: catalog entry failed validation: %s" % err)
			return []
		result.append(raw.duplicate(true))
	# Sort by id for stable iteration order
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	return result

static func get_definition(id: Variant) -> Dictionary:
	if typeof(id) != TYPE_STRING:
		return _failure("UNKNOWN_QUEST_ID")
	for defn in all_definitions():
		if defn.id == id:
			return {"success": true, "definition": defn, "error": ""}
	return _failure("UNKNOWN_QUEST_ID")

static func has(id: Variant) -> bool:
	if typeof(id) != TYPE_STRING:
		return false
	for defn in all_definitions():
		if defn.id == id:
			return true
	return false

static func all_ids() -> Array:
	var ids: Array = []
	for defn in all_definitions():
		ids.append(defn.id)
	return ids

static func validate_definition(raw: Variant) -> String:
	return Definition.validate_definition(raw)

# ── Private ───────────────────────────────────────────────────────────────────

static func _failure(error: String) -> Dictionary:
	return {"success": false, "definition": null, "error": error}
