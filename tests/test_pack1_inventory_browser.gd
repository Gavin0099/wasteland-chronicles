extends SceneTree
const Fixture = preload("res://tests/fixtures/char2_world.gd")
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const View = preload("res://ui/inventory_presentation.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PACK-1: " + message)

func sheet_in(shell: Node) -> AcceptDialog:
	for child: Node in shell.get_children():
		if child.get_script() == Sheet: return child as AcceptDialog
	return null

func filter_sheet(sheet: AcceptDialog, category: int, query: String, order: int = 0) -> void:
	sheet.inventory_category.select(category)
	sheet.inventory_order.select(order)
	sheet.inventory_search.text = query
	sheet.inventory_search.text_changed.emit(query)

func run() -> void:
	root.size = Vector2i(1280, 720)
	check(View.normalize({"category": "UNKNOWN", "order": "UNKNOWN"}) == {"category": "ALL", "order": "NAME", "query": ""}, "invalid local selection has safe defaults")
	var sample: Array = [{"item_id": "shotgun_shell", "quantity": 3}, {"item_id": "revolver_round", "quantity": 2}, {"item_id": "unknown", "quantity": 1}]
	var sorted: Array[Dictionary] = View.rows(sample, {"order": "WEIGHT"})
	check(sorted.size() == 2 and sorted[0].item_id == "shotgun_shell" and sorted[0].weight_g == 150 and sorted[1].weight_g == 40, "actual stack weights150/40 and unknown item not invented")
	check(View.rows(sample, {"category": "WEAPON"}).is_empty(), "ammunition belongs to consumables rather than weapon category")
	check(View.rows(sample, {"query": " 左輪 "}).size() == 1, "trimmed Chinese name search")
	check(View.rows([], {}).is_empty(), "empty bag projection")
	sorted[0].definition.description_zh = "tampered"
	check(View.rows(sample, {"order": "WEIGHT"})[0].definition.description_zh != "tampered", "results detached from authored registry")
	var a: WorldState = Fixture.geared()
	check(engine.commit_player_intent(a, PlayerIntent.create_buy_item(a.player.npc_id, &"first_aid_kit", 1)).success, "real medical purchase with capacity")
	a.player.field_kit.hp = 8
	var loaded: Dictionary = WorldState.from_json_checked(a.to_canonical_json())
	check(loaded.success, "checked starting save")
	var b: WorldState = loaded.world
	var before: String = a.to_canonical_json()
	var shell: PlayableShell = PlayableShell.new()
	root.add_child(shell)
	shell.setup(a, engine)
	shell._show_character()
	await process_frame
	var sheet: AcceptDialog = sheet_in(shell)
	check(sheet.item_labels.size() == 9, "all nine held identities visible by default")
	sheet.inventory_jump.pressed.emit()
	await process_frame
	check(sheet.inventory_search.has_focus(), "direct bag entry gives keyboard focus to search")
	check(sheet.inventory_scroll.scroll_vertical > 0 and sheet.inventory_summary.get_global_rect().end.y < sheet.inventory_scroll.get_global_rect().end.y, "direct entry leaves results room below search")
	filter_sheet(sheet, 1, "霰彈")
	check(sheet.item_labels.keys() == ["short_shotgun"] and sheet.inventory_summary.text.contains("1 / 9"), "category/search selects only held shotgun")
	check(sheet.item_labels.short_shotgun.text.contains("2.80 公斤"), "held weapon weight visible")
	filter_sheet(sheet, 0, "", 1)
	check(sheet.item_labels.keys()[0] == "short_shotgun", "weight order uses2800g before other held items")
	filter_sheet(sheet, 0, "", 2)
	check(sheet.item_labels.keys()[0] == "expedition_travel_backpack", "reviewed rare bag sorts above modified/common gear")
	var reversed_items: Array = sheet.inventory_items.duplicate(true)
	reversed_items.reverse()
	check(View.rows(reversed_items, sheet.inventory_state) == View.rows(sheet.inventory_items, sheet.inventory_state), "ordering independent of input insertion order")
	filter_sheet(sheet, 2, "不存在")
	check(sheet.item_labels.is_empty() and sheet.inventory_empty.visible and sheet.inventory_empty.text.contains("沒有符合"), "empty search is distinguished from empty bag")
	check(a.to_canonical_json() == before and engine.validate_invariants(a) == "", "browse/filter/sort/focus preserve complete world")
	filter_sheet(sheet, 1, "霰彈", 1)
	sheet.detail_buttons.short_shotgun.pressed.emit()
	await process_frame
	sheet.item_detail.confirmed.emit()
	check(not sheet.visible, "successful equip releases old exclusive window before reopening")
	await process_frame
	await process_frame
	sheet = sheet_in(shell)
	check(a.player.equipment.equipped_item("main_hand") == "short_shotgun", "real detail equip commits through shell")
	check(sheet.inventory_state == {"category": "WEAPON", "order": "WEIGHT", "query": "霰彈"} and sheet.item_labels.keys() == ["short_shotgun"], "successful equip retains search/category/order")
	check(sheet.inventory_requested and sheet.inventory_scroll.scroll_vertical > 0, "reopened sheet returns to inventory section")
	check(engine.commit_player_intent(b, PlayerIntent.create_equip_item(b.player.npc_id, &"short_shotgun", "main_hand")).success, "reloaded direct-engine equip")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "UI/direct-engine twin SHA after equip")
	filter_sheet(sheet, 5, "急救")
	sheet.item_use_buttons.first_aid_kit.pressed.emit()
	await process_frame
	await process_frame
	sheet = sheet_in(shell)
	check(a.player.field_kit.hp == 12 and a.player.item_inventory.quantity("first_aid_kit") == 0, "actual use consumes one kit and heals4")
	check(sheet.inventory_state.query == "急救" and sheet.inventory_state.category == "CONSUMABLE" and sheet.inventory_empty.visible, "consuming last match retains context with truthful empty search")
	check(engine.commit_player_intent(b, PlayerIntent.create_field_action(b.player.npc_id, {"command": "TREAT"})).success, "direct-engine twin treatment")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "dual-track SHA after consumption")
	check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants")
	var roundtrip: Dictionary = WorldState.from_json_checked(a.to_canonical_json())
	check(roundtrip.success and roundtrip.world.to_canonical_json() == a.to_canonical_json(), "checked persisted action result")
	shell.queue_free()
	await process_frame
	var empty: WorldState = Base.fresh()
	var empty_shell: PlayableShell = PlayableShell.new()
	root.add_child(empty_shell)
	empty_shell.setup(empty, engine)
	empty_shell._show_character()
	await process_frame
	var empty_sheet: AcceptDialog = sheet_in(empty_shell)
	check(empty_sheet.inventory_empty.visible and empty_sheet.inventory_empty.text == "目前沒有額外物品。", "actual empty inventory message")
	empty_shell.queue_free()
	await process_frame
	print("PACK-1: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
