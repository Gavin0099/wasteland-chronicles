extends SceneTree

const Player = preload("res://simulation/player_state.gd")
const Equipment = preload("res://simulation/equipment_state.gd")

var failures: int = 0
var assertions: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-5: " + message)

func _init() -> void:
	var player := Player.new(&"equipment-tester")
	check(player.pickup_item("rusted_knife").success, "owned weapon can be picked up")
	check(player.pickup_item("work_clothes").success, "owned apparel can be picked up")
	check(player.pickup_item("travel_backpack").success, "owned container can be picked up")
	check(player.equip_item("rusted_knife", "main_hand").success, "weapon equips to declared slot")
	check(player.equip_item("work_clothes", "body").success, "apparel equips to declared slot")
	check(player.equip_item("travel_backpack", "back").success, "container equips to declared slot")
	check(player.get("equipment").equipped_item("main_hand") == "rusted_knife", "main hand reports equipped item")
	check(not player.equip_item("rusted_knife", "body").success, "item cannot occupy a second slot")
	check(not player.equip_item("work_clothes", "main_hand").success, "item cannot use undeclared slot")
	check(not player.equip_item("rope", "main_hand").success, "unowned item is refused")
	check(player.unequip_item("body").success and player.get("equipment").equipped_item("body") == "", "unequip clears slot")
	check(not player.unequip_item("body").success, "empty slot cannot be unequipped twice")
	var saved := player.to_dict()
	check(saved.has("item_inventory") and saved.has("equipment"), "non-empty item and equipment state is persisted")
	var restored := Player.from_dict(saved)
	check(restored.get("equipment").equipped_item("main_hand") == "rusted_knife", "equipment round-trips")
	check(restored.get("equipment").equipped_item("body") == "", "unequipped slot stays empty")
	check(restored.to_dict() == saved, "player equipment save/load is a fixed point")
	var detached := player.duplicate_state()
	detached.unequip_item("main_hand")
	check(player.get("equipment").equipped_item("main_hand") == "rusted_knife", "equipment duplication is detached")
	var malformed: Dictionary = saved.equipment.duplicate(true)
	malformed.slots[0].item_id = "unknown_item"
	check(Equipment.validate_serialized(malformed, player.get("item_inventory")) == "UNKNOWN_ITEM_ID", "unknown equipped item fails closed")
	malformed = saved.equipment.duplicate(true)
	malformed.slots[0].slot = "body"
	check(Equipment.validate_serialized(malformed, player.get("item_inventory")) == "ITEM_SLOT_UNAVAILABLE", "wrong slot fails closed")
	malformed = saved.equipment.duplicate(true)
	malformed.slots.append({"slot": "main_hand", "item_id": "work_clothes"})
	check(Equipment.validate_serialized(malformed, player.get("item_inventory")) == "INVALID_EQUIPMENT_SLOT", "duplicate slot fails closed")
	check(Equipment.validate_serialized({"slots": [{"slot": "main_hand", "item_id": "rusted_knife"}]}, player.get("item_inventory")) == "", "valid detached equipment record validates")
	var empty := Player.new(&"empty-equipment")
	check(not empty.to_dict().has("equipment"), "empty equipment preserves legacy wire shape")
	print("ITEM-5 equipment gates: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
