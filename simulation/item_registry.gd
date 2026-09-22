class_name ItemRegistry
extends RefCounted

const Source = preload("res://game_data/item_registry.gd")
const Catalogue = preload("res://simulation/item_catalogue.gd")
const ID_FIELDS := ["item_id", "display_name_zh", "category", "subtype", "base_weight", "base_value", "stackable", "max_stack", "condition", "max_condition", "equip_slots", "actions", "tags", "origin_tags", "loot_sources", "settlement_supply", "settlement_demand", "description_zh", "asset_id"]
const CATEGORIES := ["WEAPON", "APPAREL", "CONTAINER", "TOOL", "CONSUMABLE"]
const MARKETS := ["new_hope", "gray_valley", "dry_well"]
const LEVELS := ["none", "low", "medium", "high"]

static func all_definitions() -> Array:
	var result: Array = []
	for raw in Source.rows():
		var checked := _validate(raw)
		if not checked.success:
			return []
		result.append(checked.definition)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.item_id < b.item_id)
	return result

static func resolve(item_id: Variant) -> Dictionary:
	if typeof(item_id) != TYPE_STRING:
		return _failure("UNKNOWN_ITEM_ID")
	for definition in all_definitions():
		if definition.item_id == item_id:
			return {"success": true, "definition": definition, "error": ""}
	return _failure("UNKNOWN_ITEM_ID")

static func validate(raw: Variant) -> String:
	var checked := _validate(raw)
	return "" if checked.success else checked.error

static func _validate(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or raw.size() != ID_FIELDS.size():
		return _failure("INVALID_ITEM_REGISTRY_FIELDS")
	for field in ID_FIELDS:
		if not raw.has(field):
			return _failure("INVALID_ITEM_REGISTRY_FIELDS")
	if not _stable_id(raw.item_id) or typeof(raw.display_name_zh) != TYPE_STRING or raw.display_name_zh.strip_edges().is_empty():
		return _failure("INVALID_ITEM_IDENTITY")
	if typeof(raw.category) != TYPE_STRING or not raw.category in CATEGORIES or not _stable_id(raw.subtype):
		return _failure("INVALID_ITEM_CLASSIFICATION")
	if typeof(raw.base_weight) != TYPE_INT or raw.base_weight <= 0 or typeof(raw.base_value) != TYPE_INT or raw.base_value <= 0:
		return _failure("INVALID_ITEM_NUMERIC_METADATA")
	if typeof(raw.stackable) != TYPE_BOOL or typeof(raw.max_stack) != TYPE_INT or raw.max_stack <= 0 or (raw.stackable and raw.max_stack <= 1) or (not raw.stackable and raw.max_stack != 1):
		return _failure("INVALID_ITEM_STACK_METADATA")
	if raw.condition != null or raw.max_condition != null:
		return _failure("UNAUTHORIZED_CONDITION_AUTHORITY")
	for field in ["equip_slots", "actions", "tags", "origin_tags", "loot_sources"]:
		if not _token_array(raw[field], field == "tags"):
			return _failure("INVALID_ITEM_" + field.to_upper())
	if not raw.stackable and raw.equip_slots.is_empty() and raw.category in ["WEAPON", "APPAREL", "CONTAINER"]:
		return _failure("INVALID_ITEM_EQUIP_SLOT")
	for market in MARKETS:
		if typeof(raw.settlement_supply) != TYPE_DICTIONARY or typeof(raw.settlement_demand) != TYPE_DICTIONARY or not raw.settlement_supply.has(market) or not raw.settlement_demand.has(market) or raw.settlement_supply[market] not in LEVELS or raw.settlement_demand[market] not in LEVELS:
			return _failure("INVALID_ITEM_MARKETS")
	if typeof(raw.description_zh) != TYPE_STRING or raw.description_zh.strip_edges().length() < 8 or not _stable_id(raw.asset_id):
		return _failure("INVALID_ITEM_DESCRIPTION")
	var identity := Catalogue.resolve(raw.item_id)
	if not identity.success or identity.definition.asset_id != raw.asset_id or identity.definition.base_weight != raw.base_weight or identity.definition.category != raw.category or identity.definition.stack_mode != ("STACKABLE" if raw.stackable else "UNIQUE"):
		return _failure("ITEM1_IDENTITY_MISMATCH")
	return {"success": true, "definition": raw.duplicate(true), "error": ""}

static func _token_array(value: Variant, require_nonempty: bool) -> bool:
	if typeof(value) != TYPE_ARRAY or (require_nonempty and value.is_empty()):
		return false
	var seen := {}
	for token in value:
		if not _stable_id(token) or seen.has(token):
			return false
		seen[token] = true
	return true

static func _stable_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.is_empty():
		return false
	for index in range(value.length()):
		var code: int = value.unicode_at(index)
		if not ((code >= 97 and code <= 122) or (index > 0 and (code == 95 or (code >= 48 and code <= 57)))):
			return false
	return true

static func _failure(error: String) -> Dictionary:
	return {"success": false, "definition": null, "error": error}
