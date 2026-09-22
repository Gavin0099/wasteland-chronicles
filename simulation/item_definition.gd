class_name ItemDefinition
extends RefCounted

const FIELDS := ["item_id", "display_name_zh", "category", "stack_mode", "base_weight", "asset_id", "tags"]
const CATEGORIES := ["WEAPON", "APPAREL", "CONTAINER", "TOOL", "CONSUMABLE"]
const STACK_MODES := ["UNIQUE", "STACKABLE"]

# Schema validation only. Neither category nor tags authorize an action.
static func validate(raw: Variant) -> String:
	if typeof(raw) != TYPE_DICTIONARY:
		return "INVALID_ITEM_DEFINITION"
	if raw.size() != FIELDS.size():
		return "INVALID_ITEM_FIELDS"
	for field in FIELDS:
		if not raw.has(field):
			return "INVALID_ITEM_FIELDS"
	if not is_stable_id(raw.item_id):
		return "INVALID_ITEM_ID"
	if typeof(raw.display_name_zh) != TYPE_STRING or raw.display_name_zh.strip_edges().is_empty() or raw.display_name_zh != raw.display_name_zh.strip_edges():
		return "INVALID_ITEM_DISPLAY_NAME"
	if typeof(raw.category) != TYPE_STRING or raw.category not in CATEGORIES:
		return "INVALID_ITEM_CATEGORY"
	if typeof(raw.stack_mode) != TYPE_STRING or raw.stack_mode not in STACK_MODES:
		return "INVALID_ITEM_STACK_MODE"
	if typeof(raw.base_weight) != TYPE_INT or raw.base_weight <= 0:
		return "INVALID_ITEM_WEIGHT"
	if not is_stable_id(raw.asset_id):
		return "INVALID_ITEM_ASSET_ID"
	if typeof(raw.tags) != TYPE_ARRAY:
		return "INVALID_ITEM_TAGS"
	var seen := {}
	for tag in raw.tags:
		if not is_stable_id(tag) or seen.has(tag):
			return "INVALID_ITEM_TAGS"
		seen[tag] = true
	return ""

static func is_stable_id(raw: Variant) -> bool:
	if typeof(raw) != TYPE_STRING or raw.is_empty():
		return false
	var value: String = raw
	for index in range(value.length()):
		var code := value.unicode_at(index)
		var letter := code >= 97 and code <= 122
		var suffix := index > 0 and (code == 95 or (code >= 48 and code <= 57))
		if not letter and not suffix:
			return false
	return true
