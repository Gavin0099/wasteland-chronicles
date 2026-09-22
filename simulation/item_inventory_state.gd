class_name ItemInventoryState
extends RefCounted

## ITEM-3: authored-item holdings, separate from aggregate survival cargo.
## Stored values are only stable item IDs and quantities; every definition is
## resolved through ItemRegistry at the authority boundary.

const Registry = preload("res://simulation/item_registry.gd")
const DEFAULT_CAPACITY_GRAMS: int = 12000

var _quantities: Dictionary = {}

func is_empty() -> bool:
	return _quantities.is_empty()

func quantity(item_id: Variant) -> int:
	if typeof(item_id) != TYPE_STRING:
		return 0
	return int(_quantities.get(item_id, 0))

func contains(item_id: Variant, requested: int = 1) -> bool:
	return requested > 0 and quantity(item_id) >= requested

func total_weight_g() -> int:
	var total: int = 0
	for item_id in _quantities:
		var resolved := Registry.resolve(item_id)
		if not resolved.success:
			return -1
		total += int(resolved.definition.base_weight) * int(_quantities[item_id])
	return total

func capacity_grams() -> int:
	return DEFAULT_CAPACITY_GRAMS

func has_capacity_for(item_id: Variant, requested: int = 1) -> bool:
	if requested <= 0:
		return false
	var resolved := Registry.resolve(item_id)
	if not resolved.success:
		return false
	return total_weight_g() + int(resolved.definition.base_weight) * requested <= capacity_grams()

func add_item(item_id: Variant, requested: int = 1) -> Dictionary:
	var resolved := Registry.resolve(item_id)
	if not resolved.success:
		return _failure("UNKNOWN_ITEM_ID")
	if typeof(requested) != TYPE_INT or requested <= 0:
		return _failure("INVALID_ITEM_QUANTITY")
	var definition: Dictionary = resolved.definition
	var current: int = quantity(item_id)
	var next_quantity: int = current + requested
	if definition.stackable:
		if next_quantity > int(definition.max_stack):
			return _failure("STACK_LIMIT_EXCEEDED")
	else:
		if current > 0 or requested != 1:
			return _failure("UNIQUE_ITEM_DUPLICATE")
	if not has_capacity_for(item_id, requested):
		return _failure("ITEM_CAPACITY_EXCEEDED")
	_quantities[item_id] = next_quantity
	return _success(item_id)

func remove_item(item_id: Variant, requested: int = 1) -> Dictionary:
	if typeof(item_id) != TYPE_STRING or not Registry.resolve(item_id).success:
		return _failure("UNKNOWN_ITEM_ID")
	if typeof(requested) != TYPE_INT or requested <= 0:
		return _failure("INVALID_ITEM_QUANTITY")
	var current: int = quantity(item_id)
	if current < requested:
		return _failure("INSUFFICIENT_ITEM_QUANTITY")
	var next_quantity: int = current - requested
	if next_quantity == 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = next_quantity
	return _success(item_id)

func pickup_item(item_id: Variant, requested: int = 1) -> Dictionary:
	return add_item(item_id, requested)

func drop_item(item_id: Variant, requested: int = 1) -> Dictionary:
	return remove_item(item_id, requested)

func inspect_item(item_id: Variant) -> Dictionary:
	var resolved := Registry.resolve(item_id)
	if not resolved.success or quantity(item_id) <= 0:
		return _failure("ITEM_NOT_HELD")
	var definition: Dictionary = resolved.definition.duplicate(true)
	return {
		"success": true,
		"error": "",
		"item_id": item_id,
		"quantity": quantity(item_id),
		"total_weight_g": int(definition.base_weight) * quantity(item_id),
		"definition": definition,
	}

func to_dict() -> Dictionary:
	var entries: Array = []
	var ids: Array = _quantities.keys()
	ids.sort()
	for item_id in ids:
		entries.append({"item_id": item_id, "quantity": int(_quantities[item_id])})
	return {"items": entries}

func duplicate_state() -> RefCounted:
	var copy := new()
	copy._quantities = _quantities.duplicate(true)
	return copy

static func validate_serialized(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY or data.size() != 1 or not data.has("items") or typeof(data.items) != TYPE_ARRAY:
		return "INVALID_ITEM_INVENTORY"
	var seen := {}
	for entry in data.items:
		if typeof(entry) != TYPE_DICTIONARY or entry.size() != 2 or not entry.has("item_id") or not entry.has("quantity"):
			return "INVALID_ITEM_INVENTORY_ENTRY"
		if typeof(entry.item_id) != TYPE_STRING or seen.has(entry.item_id):
			return "INVALID_ITEM_INVENTORY_ID"
		var resolved := Registry.resolve(entry.item_id)
		if not resolved.success:
			return "UNKNOWN_ITEM_ID"
		if typeof(entry.quantity) != TYPE_INT or entry.quantity <= 0:
			return "INVALID_ITEM_QUANTITY"
		var definition: Dictionary = resolved.definition
		if (not definition.stackable and entry.quantity != 1) or (definition.stackable and entry.quantity > int(definition.max_stack)):
			return "INVALID_ITEM_STACK"
		seen[entry.item_id] = true
	var candidate := new()
	for entry in data.items:
		candidate._quantities[entry.item_id] = entry.quantity
	if candidate.total_weight_g() > candidate.capacity_grams():
		return "ITEM_CAPACITY_EXCEEDED"
	return ""

static func from_dict_checked(data: Variant) -> Dictionary:
	var error := validate_serialized(data)
	if error != "":
		return {"success": false, "inventory": null, "error": error}
	var inventory := new()
	for entry in data.items:
		inventory._quantities[entry.item_id] = entry.quantity
	return {"success": true, "inventory": inventory, "error": ""}

static func from_dict(data: Variant) -> RefCounted:
	var checked := from_dict_checked(data)
	return checked.inventory if checked.success else new()

func _success(item_id: String) -> Dictionary:
	return {"success": true, "error": "", "item_id": item_id, "quantity": quantity(item_id), "total_weight_g": total_weight_g()}

func _failure(error: String) -> Dictionary:
	return {"success": false, "error": error, "item_id": "", "quantity": 0, "total_weight_g": total_weight_g()}
