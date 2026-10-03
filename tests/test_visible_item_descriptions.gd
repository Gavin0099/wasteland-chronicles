extends SceneTree

const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Description = preload("res://ui/item_description.gd")
const Character = preload("res://ui/character_presentation.gd")
const Field = preload("res://simulation/field_adventure.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-DESC: " + label)

func sheet_in(shell: PlayableShell) -> AcceptDialog:
	for child: Node in shell.get_children():
		if child.get_script() == Sheet: return child as AcceptDialog
	return null

func run() -> void:
	root.size = Vector2i(1152, 648)
	check(Description.text("unknown").is_empty(), "unknown item gains no invented description")
	# Independent reviewed gameplay facts, not a copy of the projection formula.
	for spec: Array in [["bandage", "恢復最多2", "戰鬥與待確認"], ["first_aid_kit", "恢復最多4", "消耗1"],
		["rusted_knife", "加成+1", "裝備到主手"], ["combat_knife", "加成+3", "使用後保留"],
		["police_revolver", "射擊傷害7", "左輪彈藥×1"], ["short_shotgun", "射擊傷害10", "霰彈槍彈藥×1"],
		["ballistic_vest", "防護3", "不能潛行"], ["travel_backpack", "容量+8", "公斤容量另外"],
		["repair_toolbox", "機械工具2", "技能等級"], ["simple_meter", "電子工具1", "材料成本"],
		["rope", "不耽誤行程", "繩索保留"], ["flashlight", "沒有額外", "探索加成"],
		["military_gas_mask", "追尋對應傳聞", "不提供戰鬥防護"],
		["balanced_combat_knife", "反擊傷害", "−1"], ["expedition_travel_backpack", "工具環", "水袋"]]:
		var text: String = Description.text(String(spec[0]))
		check(text.contains(String(spec[1])) and text.contains(String(spec[2])), "specified usable facts: " + String(spec[0]))
	var definitions: Array = Registry.all_definitions()
	check(definitions.size() == 45, "existing45 runtime definitions, no content expansion")
	for definition: Dictionary in definitions:
		var world: WorldState = Base.fresh()
		var id: String = definition.item_id
		check(world.player.item_inventory.pickup_item(id, 1).success, "one reviewed held-item fixture " + id)
		var unchanged: String = world.to_canonical_json()
		var sheet: AcceptDialog = Sheet.new()
		root.add_child(sheet)
		sheet.theme = load("res://ui/theme/survivor_pda_theme.tres")
		sheet.setup(Character.project(world), PlayerUIProjection.project(world).player)
		sheet.popup_centered(Vector2i(1036, 570))
		await process_frame
		check(sheet.item_descriptions.has(id), "all held items expose actual labels: " + id)
		var label: Label = sheet.item_descriptions[id]
		check(label.is_visible_in_tree() and label.text.contains("用途：") and label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "visible wrapping explanation " + id)
		check(sheet.detail_buttons[id].text == "詳細說明", "discoverable full explanation " + id)
		check(world.to_canonical_json() == unchanged and engine.validate_invariants(world) == "", "explanations preserve world/invariants " + id)
		var saved: Dictionary = WorldState.from_json_checked(unchanged)
		check(saved.success and saved.world.to_canonical_json().sha256_text() == unchanged.sha256_text(), "checked persistence " + id)
		sheet.hide()
		sheet.queue_free()
		await process_frame
		await process_frame
	var world: WorldState = Base.fresh()
	var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success, "actual market starting save")
	var twin: WorldState = loaded.world
	var shell: PlayableShell = PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	shell._show_local_market()
	await process_frame
	var market: AcceptDialog = shell.market_window
	var unchanged: String = world.to_canonical_json()
	market.row_buttons.bandage.pressed.emit()
	check(market.detail_text.text.contains("恢復最多2") and market.detail_text.text.contains("聚落休整"), "market exposes real bandage use and limits")
	check(world.to_canonical_json() == unchanged, "market inspection has no day/inventory/history effects")
	market.plus_button.pressed.emit()
	market.buy_button.pressed.emit()
	check(engine.commit_player_intent(twin, PlayerIntent.create_buy_item(twin.player.npc_id, &"bandage", 2)).success, "checked-load direct purchase")
	check(world.player.item_inventory.quantity("bandage") == 2, "real described buy action owns two bandages")
	parity(world, twin, "purchase")
	market.row_buttons.rusted_knife.pressed.emit()
	check(market.detail_text.text.contains("加成+1"), "market knife has actual effect beyond flavor")
	market.buy_button.pressed.emit()
	check(engine.commit_player_intent(twin, PlayerIntent.create_buy_item(twin.player.npc_id, &"rusted_knife", 1)).success, "direct knife purchase")
	parity(world, twin, "knife buy")
	market.confirmed.emit()
	await process_frame
	await process_frame
	shell._show_character()
	await process_frame
	var sheet: AcceptDialog = sheet_in(shell)
	check(sheet.item_descriptions.bandage.text.contains("最多2") and sheet.item_descriptions.rusted_knife.text.contains("加成+1"), "inventory facts survive real purchase")
	sheet.detail_buttons.rusted_knife.pressed.emit()
	await process_frame
	sheet.item_detail.confirmed.emit()
	await process_frame
	await process_frame
	check(engine.commit_player_intent(twin, PlayerIntent.create_equip_item(twin.player.npc_id, &"rusted_knife", "main_hand")).success, "direct matching equip")
	check(world.player.equipment.equipped_item("main_hand") == "rusted_knife", "real detailed action equips")
	parity(world, twin, "detail equip")
	sheet = sheet_in(shell)
	sheet.canceled.emit()
	await process_frame
	await process_frame
	for state: WorldState in [world, twin]:
		check(engine.commit_player_intent(state, PlayerIntent.create_field_action(state.player.npc_id, {"command": "START"})).success, "real injury start")
		for command: String in ["ATTACK", "FLEE"]:
			check(engine.commit_player_intent(state, PlayerIntent.create_field_action(state.player.npc_id, {"command": command, "battle_id": int(state.field_state.battle.id), "turn": int(state.field_state.battle.turn)})).success, "real injury turn")
		check(engine.commit_player_intent(state, PlayerIntent.create_field_action(state.player.npc_id, {"command": "CONFIRM", "receipt": int(state.field_state.receipt)})).success, "real injury confirmation")
	check(world.player.field_kit.hp == 8, "independent actual injury fixture8HP")
	shell.refresh_ui()
	shell._show_character()
	await process_frame
	for expected_hp: int in [10, 12]:
		sheet = sheet_in(shell)
		check(not sheet.item_use_buttons.bandage.disabled, "described heal available when injured")
		sheet.item_use_buttons.bandage.pressed.emit()
		await process_frame
		await process_frame
		check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, {"command": "TREAT", "item_id": "bandage"})).success, "direct described treatment")
		check(world.player.field_kit.hp == expected_hp, "actual promised two HP heal")
		parity(world, twin, "described treatment")
	sheet = sheet_in(shell)
	check(not sheet.item_descriptions.has("bandage"), "last consumed item's explanation disappears without stale action")
	shell.queue_free()
	await process_frame
	await process_frame
	print("Visible item descriptions: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)

func parity(world: WorldState, twin: WorldState, label: String) -> void:
	check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), label + " twin SHA-256")
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", label + " global invariants")
	var saved: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(saved.success and saved.world.to_canonical_json() == world.to_canonical_json(), label + " checked persistence")
