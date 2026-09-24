class_name QuestRegistry
extends RefCounted

# ==============================================================================
# QUEST-1B: QUEST REGISTRY
# ==============================================================================
# Static registry of QuestDefinitions — the authored catalog.
# QUEST-2/3 add bounded authored delivery quests to the QUEST-1 foundation.
#
# Pattern mirrors ItemRegistry: static methods only, definitions validated on
# read, fail-closed on any malformed entry.
# ==============================================================================

const Definition = preload("res://simulation/quest_definition.gd")

# ── Internal catalog ──────────────────────────────────────────────────────────
static func _catalog() -> Array:
	return [{
		"id": "gray_valley_wrench_run",
		"title_zh": "送一把扳手到乾井",
		"description_zh": "灰谷的商路告示板有人託付：乾井水泵工棚缺一把可調扳手。帶著扳手到乾井交付；路上仍要自己準備水糧。",
		"settlement_id": "gray_valley",
		"issuer_npc_id": "",
		"availability": {"required_day": 0, "required_flags": []},
		"deadline_days": 8,
		"objectives": [{"id": "deliver_wrench", "type": "DELIVER_ITEM", "item_id": "wrench", "quantity": 1, "settlement_id": "dry_well"}],
		"outcomes": {
			"resolved": {"rewards": [{"type": "CURRENCY", "amount": 75}, {"type": "XP", "amount": 25}], "world_effects": [{"type": "SET_FLAG", "flag": "dry_well_wrench_delivered"}]},
			"failed": {"rewards": [], "world_effects": []},
			"expired": {"rewards": [], "world_effects": []},
		},
	}, {
		"id": "gray_valley_rope_run",
		"title_zh": "送一條繩索到乾井",
		"description_zh": "灰谷的商路告示板列出乾井的求貨單：帶一條繩索到乾井交付。繩索也是荒野工具，交出去後就不能再用它處理路上的狀況。",
		"settlement_id": "gray_valley",
		"issuer_npc_id": "",
		"availability": {"required_day": 0, "required_flags": []},
		"deadline_days": 5,
		"objectives": [{"id": "deliver_rope", "type": "DELIVER_ITEM", "item_id": "rope", "quantity": 1, "settlement_id": "dry_well"}],
		"outcomes": {
			"resolved": {"rewards": [{"type": "CURRENCY", "amount": 65}, {"type": "XP", "amount": 20}], "world_effects": [{"type": "SET_FLAG", "flag": "dry_well_rope_delivered"}]},
			"failed": {"rewards": [], "world_effects": []},
			"expired": {"rewards": [], "world_effects": []},
		},
	}]

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
