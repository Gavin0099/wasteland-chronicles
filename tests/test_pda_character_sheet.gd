extends SceneTree
const Sheet = preload("res://ui/components/character_sheet.gd")
const Presentation = preload("res://ui/character_presentation.gd")
const Intent = preload("res://simulation/character_creation_intent.gd")
var failed := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	engine.commit_character_creation(world, Intent.new({"source_settlement_id": "settlement:gray_valley", "character_name": "荒原長姓名測試角色", "age": 23, "background_id": "MECHANIC", "trait_ids": ["CURIOUS"]}))
	for amount in [0, 20]:
		world.player.inventory.water = amount
		world.player.inventory.food = 0
		if amount == 20:
			world.player.pickup_item("rusted_knife")
			world.player.equip_item("rusted_knife", "main_hand")
		var before := world.to_canonical_json().sha256_text()
		var sheet := Sheet.new()
		root.add_child(sheet)
		sheet.setup(Presentation.project(world), PlayerUIProjection.project(world).player)
		sheet.popup_centered()
		check(sheet.resource_values.water.text == str(amount) and sheet.resource_values.food.text == "0", "zero/full actual inventory")
		check(sheet.capacity_label.text.contains("%d / 20" % amount), "capacity derived from physical inventory")
		for skill in sheet.skill_rows:
			check(sheet.skill_rows[skill].rank == {"MECHANICS": 2, "ELECTRONICS": 1, "SCAVENGING": 1}.get(skill, 0), "owner-approved skill rank in row")
		check(sheet.skill_rows.size() == 10 and sheet.trait_label.text.contains("好奇"), "complete skills and selected Core Traits")
		if amount == 20:
			check(sheet.item_labels.has("rusted_knife") and sheet.item_labels.rusted_knife.text.contains("生鏽小刀"), "owned item is visible with its name")
			check(sheet.equipment_labels.main_hand.text.contains("生鏽小刀"), "equipped item is visible in its slot")
		sheet.confirmed.emit()
		await process_frame
		check(world.to_canonical_json().sha256_text() == before, "opening/closing sheet never spends a day or mutates world")
		check(engine.validate_invariants(world) == "", "global invariants preserved")
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	var locked := {"locked": true, "requirement_label": "機械 熟練", "blocked_reason": "CAPABILITY_NOT_MET: STRIP_PARTS requires 機械 熟練"}
	check(shell._encounter_blocked_text(locked).contains("機械 熟練") and not shell._encounter_blocked_text(locked).contains("CAPABILITY_"), "locked tooltip gives readable requirement")
	check(not shell._encounter_blocked_text({"blocked_reason": "INSUFFICIENT_WATER"}).contains("INSUFFICIENT_"), "resource failure does not expose internal code")
	var loaded := WorldState.from_json(world.to_canonical_json())
	check(loaded.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text(), "read-only UI/save-load SHA replay")
	print("PDA read-only replay SHA-256: ", world.to_canonical_json().sha256_text())
	shell.queue_free()
	await process_frame
	print("PDA sheet gates: ", "PASS" if failed == 0 else "FAIL")
	quit(0 if failed == 0 else 1)
