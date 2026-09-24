extends SceneTree

const Sheet = preload("res://ui/components/character_sheet.gd")
const Presentation = preload("res://ui/character_presentation.gd")
const Intent = preload("res://simulation/character_creation_intent.gd")

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-13: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	engine.commit_character_creation(world, Intent.new({"source_settlement_id": "settlement:gray_valley", "character_name": "Equipment UI Tester", "age": 24, "background_id": "MECHANIC", "trait_ids": []}))
	world.player.pickup_item("rusted_knife")
	var before := world.to_canonical_json()
	var denied := engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"hunting_knife", "main_hand"))
	check(not denied.success and world.to_canonical_json() == before, "PDA-equivalent equip intent refuses an unowned item atomically")

	var equip_requests: Array = []
	var unequip_requests: Array = []
	var equip_action := func(item_id: String, slot: String):
		equip_requests.append({"item_id": item_id, "slot": slot})
		return engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(item_id), slot))
	var unequip_action := func(slot: String):
		unequip_requests.append(slot)
		return engine.commit_player_intent(world, PlayerIntent.create_unequip_item(world.player.npc_id, slot))
	var sheet := Sheet.new()
	root.add_child(sheet)
	sheet.setup(Presentation.project(world), PlayerUIProjection.project(world).player, equip_action, unequip_action)
	check(sheet.item_labels.has("rusted_knife"), "character sheet still presents the owned item")
	var item_row: HBoxContainer = sheet.item_labels.rusted_knife.get_parent()
	check(item_row.get_child_count() >= 3, "owned equippable item exposes an equipment action")
	var equip_button: Button = item_row.get_child(item_row.get_child_count() - 1)
	equip_button.pressed.emit()
	check(equip_requests == [{"item_id": "rusted_knife", "slot": "main_hand"}], "equipment button sends the declared slot and item")
	check(world.player.equipment.equipped_item("main_hand") == "rusted_knife", "equipment intent commits through the authority")
	check(world.event_log.back().type == "EQUIPMENT_CHANGED", "equipment commit writes an auditable ledger receipt")

	var loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success and loaded.world.player.equipment.equipped_item("main_hand") == "rusted_knife", "PDA equipment change survives save/load")
	var equipped_sheet := Sheet.new()
	root.add_child(equipped_sheet)
	equipped_sheet.setup(Presentation.project(world), PlayerUIProjection.project(world).player, equip_action, unequip_action)
	var equipped_row: HBoxContainer = equipped_sheet.equipment_labels.main_hand.get_parent()
	check(equipped_row.get_child_count() >= 2, "equipped slot exposes an unequip action")
	var unequip_button: Button = equipped_row.get_child(equipped_row.get_child_count() - 1)
	unequip_button.pressed.emit()
	check(unequip_requests == ["main_hand"] and world.player.equipment.equipped_item("main_hand") == "", "unequip button clears the authority slot")
	check(engine.validate_invariants(world) == "", "equipment UI actions preserve invariants")
	sheet.queue_free()
	equipped_sheet.queue_free()
	await process_frame
	print("ITEM-13 equipment UI: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
