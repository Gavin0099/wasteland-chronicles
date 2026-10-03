extends RefCounted

# Definition metadata, never an item instance, multiplier or gameplay writer.
const FIELDS := ["tier", "quality", "properties", "unique_effect"]
const TIERS := ["T1", "T2", "T3", "T4"]
const QUALITIES := ["COMMON", "MODIFIED", "RARE", "UNIQUE"]
const PROPERTY_COUNTS := {"COMMON": 0, "MODIFIED": 1, "RARE": 2, "UNIQUE": 0}
const Properties = preload("res://game_data/gear_property_profiles.gd")
const Identity = preload("res://simulation/item_definition.gd")

static func validate(raw: Variant) -> String:
	if typeof(raw) != TYPE_DICTIONARY or raw.size() != FIELDS.size():
		return "INVALID_GEAR_FIELDS"
	for field in FIELDS:
		if not raw.has(field):
			return "INVALID_GEAR_FIELDS"
	if typeof(raw.tier) != TYPE_STRING or raw.tier not in TIERS:
		return "INVALID_GEAR_TIER"
	if typeof(raw.quality) != TYPE_STRING or raw.quality not in QUALITIES:
		return "INVALID_GEAR_QUALITY"
	if typeof(raw.properties) != TYPE_ARRAY or raw.properties.size() != PROPERTY_COUNTS[raw.quality]:
		return "INVALID_GEAR_PROPERTIES"
	var seen := {}
	for property in raw.properties:
		if not Identity.is_stable_id(property) or not Properties.DESCRIPTIONS.has(property) or seen.has(property):
			return "INVALID_GEAR_PROPERTIES"
		seen[property] = true
	if typeof(raw.unique_effect) != TYPE_STRING:
		return "INVALID_GEAR_UNIQUE_EFFECT"
	if raw.quality == "UNIQUE":
		if not Identity.is_stable_id(raw.unique_effect):
			return "INVALID_GEAR_UNIQUE_EFFECT"
	elif not raw.unique_effect.is_empty():
		return "INVALID_GEAR_UNIQUE_EFFECT"
	return ""

static func project(definition: Dictionary) -> Dictionary:
	var result := {}
	for field in FIELDS:
		if not definition.has(field):
			return {}
		result[field] = definition[field]
	return result.duplicate(true)
