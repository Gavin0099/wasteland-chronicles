class_name ItemCatalogue
extends RefCounted

const Definition = preload("res://simulation/item_definition.gd")
const Source = preload("res://game_data/item_definitions.gd")
const Art = preload("res://game_data/item_art_references.gd")
const VERSION := 1

static func resolve(item_id: Variant) -> Dictionary:
	if typeof(item_id) != TYPE_STRING:
		return {"success": false, "definition": null, "error": "UNKNOWN_ITEM_ID"}
	var checked := canonicalize(Source.rows())
	if not checked.success:
		return {"success": false, "definition": null, "error": checked.error}
	for definition in checked.definitions:
		if definition.item_id == item_id:
			return {"success": true, "definition": definition, "error": ""}
	return {"success": false, "definition": null, "error": "UNKNOWN_ITEM_ID"}

static func all_definitions() -> Array:
	var checked := canonicalize(Source.rows())
	return checked.definitions

# Pure candidate validation/fingerprinting, never a catalogue installer. The
# authored source remains the only lookup authority. Even a valid candidate
# cannot mutate it, and a rejected candidate publishes no partial definitions.
static func canonicalize(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_ARRAY:
		return _failure("INVALID_ITEM_CATALOGUE")
	var authored := Source.rows()
	if raw.size() != authored.size():
		return _failure("INVALID_ITEM_COUNT")
	var bindings := {}
	for definition in authored:
		bindings[definition.item_id] = definition.asset_id
	var found := {}
	var ordered: Array = []
	for definition in raw:
		var error := Definition.validate(definition)
		if error != "":
			return _failure(error)
		if not bindings.has(definition.item_id):
			return _failure("UNKNOWN_ITEM_ID")
		if found.has(definition.item_id):
			return _failure("DUPLICATE_ITEM_ID")
		if definition.asset_id != bindings[definition.item_id]:
			return _failure("ITEM_ASSET_MISMATCH")
		if not Art.resolve(definition.asset_id).success:
			return _failure("UNKNOWN_ITEM_ASSET")
		found[definition.item_id] = true
		var detached: Dictionary = definition.duplicate(true)
		detached.tags.sort()
		ordered.append(detached)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.item_id < b.item_id)
	var document := JSON.stringify({"schema_version": VERSION, "items": ordered}, "", true)
	return {"success": true, "definitions": ordered, "canonical_json": document, "error": ""}

static func _failure(error: String) -> Dictionary:
	return {"success": false, "definitions": [], "canonical_json": "", "error": error}
