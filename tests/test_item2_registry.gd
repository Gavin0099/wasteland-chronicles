extends SceneTree

const Registry = preload("res://simulation/item_registry.gd")
const Catalogue = preload("res://simulation/item_catalogue.gd")

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-2: " + message)

func _init() -> void:
	var rows := Registry.all_definitions()
	check(rows.size() == 13, "canonical registry contains exactly thirteen records")
	var ids := {}
	for row in rows:
		ids[row.item_id] = true
		check(Registry.validate(row) == "", "record validates: " + row.item_id)
		var identity := Catalogue.resolve(row.item_id)
		check(identity.success and identity.definition.asset_id == row.asset_id, "stable asset binding: " + row.item_id)
		check(identity.definition.base_weight == row.base_weight, "ITEM-1 weight preserved: " + row.item_id)
		check(row.settlement_supply.size() == 3 and row.settlement_demand.size() == 3, "three-market metadata: " + row.item_id)
		check(row.description_zh.length() >= 8, "description present: " + row.item_id)
	check(ids.size() == 13, "all IDs unique")
	for invalid in [null, 1, true, "crowbar", "RUSTED_KNIFE", "rusted-knife"]:
		check(not Registry.resolve(invalid).success, "unknown ID fails closed: " + str(invalid))
	var row: Dictionary = rows[0].duplicate(true)
	row.actions = ["BAD ACTION"]
	check(Registry.validate(row) != "", "invalid action token rejected")
	row = rows[0].duplicate(true)
	row.condition = 100
	check(Registry.validate(row) == "UNAUTHORIZED_CONDITION_AUTHORITY", "condition cannot silently become durability")
	row = rows[0].duplicate(true)
	row.settlement_supply.erase("dry_well")
	check(Registry.validate(row) != "", "incomplete market metadata rejected")
	var detached: Dictionary = Registry.resolve("rope").definition
	detached.actions.append("forged_action")
	detached.settlement_supply.new_hope = "high"
	check(not Registry.resolve("rope").definition.actions.has("forged_action"), "lookup is detached")
	check(Registry.resolve("rope").definition.settlement_supply.new_hope != "high", "nested market lookup is detached")
	var before := JSON.stringify(rows, "", true)
	rows.reverse()
	check(JSON.stringify(Registry.all_definitions(), "", true) == before, "registry order is deterministic")
	print("ITEM-2 registry gates: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
