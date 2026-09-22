extends SceneTree

const Player = preload("res://simulation/player_state.gd")
const Inventory = preload("res://simulation/item_inventory_state.gd")
const Registry = preload("res://simulation/item_registry.gd")

var failures: int = 0
var assertions: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-3: " + message)

func _init() -> void:
	var inventory := Inventory.new()
	check(inventory.is_empty(), "new inventory is empty")
	var added := inventory.pickup_item("rope")
	check(added.success and inventory.quantity("rope") == 1, "pickup stores one unique item")
	check(inventory.total_weight_g() == 2500, "weight uses canonical registry grams")
	check(not inventory.pickup_item("rope").success and inventory.quantity("rope") == 1, "unique item cannot duplicate")
	check(inventory.pickup_item("first_aid_kit", 3).success and inventory.quantity("first_aid_kit") == 3, "stackable item stores quantity")
	check(inventory.inspect_item("first_aid_kit").definition.item_id == "first_aid_kit", "inspect returns canonical definition")
	var detached := inventory.inspect_item("first_aid_kit")
	detached.definition.tags.append("forged")
	check(not inventory.inspect_item("first_aid_kit").definition.tags.has("forged"), "inspect result is detached")
	check(inventory.drop_item("first_aid_kit", 2).success and inventory.quantity("first_aid_kit") == 1, "drop removes requested quantity")
	check(not inventory.drop_item("first_aid_kit", 2).success and inventory.quantity("first_aid_kit") == 1, "drop refuses insufficient quantity atomically")
	check(not inventory.pickup_item("unknown_item").success and not inventory.is_empty(), "unknown item fails closed")
	var full := Inventory.new()
	check(full.pickup_item("first_aid_kit", 15).success, "capacity accepts exact twelve kilogram load")
	check(not full.pickup_item("first_aid_kit", 6).success and full.quantity("first_aid_kit") == 15, "capacity rejection is atomic")
	var encoded := inventory.to_dict()
	var decoded := Inventory.from_dict_checked(encoded)
	check(decoded.success and JSON.stringify(decoded.inventory.to_dict(), "", true) == JSON.stringify(encoded, "", true), "save/load is canonical fixed point")
	check(Inventory.validate_serialized({"items": [{"item_id": "unknown_item", "quantity": 1}]}) == "UNKNOWN_ITEM_ID", "unknown serialized ID fails closed")
	check(Inventory.validate_serialized({"items": [{"item_id": "rope", "quantity": 2}]}) == "INVALID_ITEM_STACK", "unique serialized duplicate is rejected")
	check(Inventory.validate_serialized({"items": [{"item_id": "first_aid_kit", "quantity": 0}]}) == "INVALID_ITEM_QUANTITY", "zero serialized quantity is rejected")
	var player := Player.new(&"player-1")
	check(player.pickup_item("wrench").success and player.get("item_inventory").quantity("wrench") == 1, "player owns item inventory")
	var player_copy := player.duplicate_state()
	player_copy.drop_item("wrench")
	check(player.get("item_inventory").quantity("wrench") == 1 and player_copy.get("item_inventory").is_empty(), "player duplication detaches item holdings")
	var empty_player := Player.new(&"player-2")
	check(not empty_player.to_dict().has("item_inventory"), "empty item inventory preserves legacy player wire shape")
	var identity := Registry.resolve("wrench")
	check(identity.success and identity.definition.base_weight == 700, "inventory resolves through ITEM-2 authority")
	print("ITEM-3 inventory gates: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
