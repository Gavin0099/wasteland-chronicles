class_name EquipmentState
extends RefCounted

## ITEM-5: slot ownership only. Equipping an item changes its presentation
## state, not damage, armor, capacity, durability or any combat result.

const Registry = preload("res://simulation/item_registry.gd")
const SLOTS := ["main_hand", "body", "back"]

var _slots: Dictionary = {}

func is_empty() -> bool:
	return _slots.is_empty()

func equipped_item(slot: Variant) -> String:
	if typeof(slot) != TYPE_STRING:
		return ""
	return String(_slots.get(slot, ""))

func equip(item_id: Variant, slot: Variant, inventory: RefCounted) -> Dictionary:
	if typeof(item_id) != TYPE_STRING:
		return _failure("UNKNOWN_ITEM_ID")
	if typeof(slot) != TYPE_STRING or slot not in SLOTS:
		return _failure("INVALID_EQUIPMENT_SLOT")
	var resolved := Registry.resolve(item_id)
	if not resolved.success:
		return _failure("UNKNOWN_ITEM_ID")
	if inventory == null or int(inventory.call("quantity", item_id)) <= 0:
		return _failure("ITEM_NOT_HELD")
	var definition: Dictionary = resolved.definition
	if slot not in definition.equip_slots:
		return _failure("ITEM_SLOT_UNAVAILABLE")
	for occupied_slot in _slots:
		if _slots[occupied_slot] == item_id and occupied_slot != slot:
			return _failure("ITEM_ALREADY_EQUIPPED")
	var replaced: String = String(_slots.get(slot, ""))
	_slots[slot] = item_id
	return {"success": true, "error": "", "slot": slot, "item_id": item_id, "replaced_item_id": replaced}

func unequip(slot: Variant) -> Dictionary:
	if typeof(slot) != TYPE_STRING or slot not in SLOTS:
		return _failure("INVALID_EQUIPMENT_SLOT")
	if not _slots.has(slot):
		return _failure("SLOT_EMPTY")
	var item_id: String = String(_slots[slot])
	_slots.erase(slot)
	return {"success": true, "error": "", "slot": slot, "item_id": item_id, "replaced_item_id": ""}

func to_dict() -> Dictionary:
	var entries: Array = []
	var slots: Array = _slots.keys()
	slots.sort()
	for slot in slots:
		entries.append({"slot": slot, "item_id": _slots[slot]})
	return {"slots": entries}

func duplicate_state() -> RefCounted:
	var copy := new()
	copy._slots = _slots.duplicate(true)
	return copy

static func validate_serialized(data: Variant, inventory: RefCounted) -> String:
	if typeof(data) != TYPE_DICTIONARY or data.size() != 1 or not data.has("slots") or typeof(data.slots) != TYPE_ARRAY:
		return "INVALID_EQUIPMENT"
	var seen_slots := {}
	var seen_items := {}
	for entry in data.slots:
		if typeof(entry) != TYPE_DICTIONARY or entry.size() != 2 or not entry.has("slot") or not entry.has("item_id"):
			return "INVALID_EQUIPMENT_ENTRY"
		if typeof(entry.slot) != TYPE_STRING or entry.slot not in SLOTS or seen_slots.has(entry.slot):
			return "INVALID_EQUIPMENT_SLOT"
		if typeof(entry.item_id) != TYPE_STRING or seen_items.has(entry.item_id):
			return "INVALID_EQUIPMENT_ITEM"
		var resolved := Registry.resolve(entry.item_id)
		if not resolved.success:
			return "UNKNOWN_ITEM_ID"
		if inventory == null or int(inventory.call("quantity", entry.item_id)) <= 0:
			return "EQUIPMENT_ITEM_NOT_HELD"
		if entry.slot not in resolved.definition.equip_slots:
			return "ITEM_SLOT_UNAVAILABLE"
		seen_slots[entry.slot] = true
		seen_items[entry.item_id] = true
	return ""

static func from_dict_checked(data: Variant, inventory: RefCounted) -> Dictionary:
	var error := validate_serialized(data, inventory)
	if error != "":
		return {"success": false, "equipment": null, "error": error}
	var equipment := new()
	for entry in data.slots:
		equipment._slots[entry.slot] = entry.item_id
	return {"success": true, "equipment": equipment, "error": ""}

static func from_dict(data: Variant, inventory: RefCounted) -> RefCounted:
	var checked := from_dict_checked(data, inventory)
	return checked.equipment if checked.success else new()

func _failure(error: String) -> Dictionary:
	return {"success": false, "error": error, "slot": "", "item_id": "", "replaced_item_id": ""}
