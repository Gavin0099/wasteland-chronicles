extends AcceptDialog

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Presentation = preload("res://ui/character_presentation.gd")
const SkillRow = preload("res://ui/components/skill_rank_row.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
var skill_rows: Dictionary = {}
var resource_values: Dictionary = {}
var item_labels: Dictionary = {}
var equipment_labels: Dictionary = {}
var capacity_label: Label
var identity_label: Label
var trait_label: Label
var equipment_action: Callable
var equipment_unequip_action: Callable

func label_in(parent: Node, text: String, variant: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func panel_in(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "PdaPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", Tokens.GAP)
	panel.add_child(column)
	return column

func item_row(parent: Node, id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	row.add_child(ItemIcon.new(id, 32))
	return row

func setup(character: Dictionary, player: Dictionary, p_equipment_action: Callable = Callable(), p_unequip_action: Callable = Callable()) -> void:
	equipment_action = p_equipment_action
	equipment_unequip_action = p_unequip_action
	title = "人物與補給"
	theme_type_variation = "PdaDialog"
	ok_button_text = "返回旅程"
	get_ok_button().custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	get_ok_button().theme_type_variation = "PdaPrimary"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var columns := VBoxContainer.new()
	columns.add_theme_constant_override("separation", Tokens.PAD)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(columns)
	var left := panel_in(columns)
	identity_label = label_in(left, "%s · %d 歲" % [character.name, character.age], "PdaTitle")
	label_in(left, "生命　%d / 12" % character.field_kit.hp)
	label_in(left, "背景", "PdaSection")
	label_in(left, Presentation.background_name(character.background_id))
	label_in(left, "人物特質", "PdaSection")
	trait_label = label_in(left, Presentation.trait_text(character.traits))
	label_in(left, "部分特質會提供不同的遭遇處理方式。", "PdaMuted")
	left.add_child(HSeparator.new())
	label_in(left, "隨身補給", "PdaSection")
	var bp: Dictionary = player.backpack
	capacity_label = label_in(left, "背包容量　%d / %d" % [bp.load, bp.capacity])
	var supplies := GridContainer.new()
	supplies.columns = 2
	supplies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supplies.add_theme_constant_override("h_separation", Tokens.PAD)
	supplies.add_theme_constant_override("v_separation", Tokens.GAP)
	left.add_child(supplies)
	label_in(item_row(supplies, "caps"), "瓶蓋　%d" % player.money)
	label_in(item_row(supplies, "crowbar"), "撬棍　" + ("已裝備" if character.field_kit.equipped else ("持有 · 負重 2" if character.field_kit.crowbar else "未持有")))
	for id in ["water", "food", "scrap", "fuel"]:
		var row := item_row(supplies, id)
		var names := {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}
		label_in(row, names[id])
		var count := Label.new()
		count.text = str(bp[id])
		row.add_child(count)
		resource_values[id] = count
	label_in(left, "查看人物與補給不消耗時間。", "PdaMuted")
	left.add_child(HSeparator.new())
	label_in(left, "物品", "PdaSection")
	var item_rows := VBoxContainer.new()
	item_rows.add_theme_constant_override("separation", Tokens.GAP)
	left.add_child(item_rows)
	var owned_items: Array = player.get("items", [])
	if owned_items.is_empty():
		label_in(item_rows, "目前沒有額外物品。", "PdaMuted")
	else:
		for entry in owned_items:
			var item_id := String(entry.get("item_id", ""))
			var resolved := ItemRegistry.resolve(item_id)
			if not resolved.success:
				continue
			var item_row_node := item_row(item_rows, item_id)
			var item_label := label_in(item_row_node, "%s　×%d　%d g" % [resolved.definition.display_name_zh, int(entry.get("quantity", 0)), int(resolved.definition.base_weight) * int(entry.get("quantity", 0))])
			item_labels[item_id] = item_label
			if equipment_action.is_valid():
				for slot in resolved.definition.equip_slots:
					var equip_button := Button.new()
					equip_button.text = "裝備%s" % _slot_name(String(slot))
					equip_button.theme_type_variation = "PdaCommand"
					equip_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
					equip_button.pressed.connect(func(): equipment_action.call(item_id, String(slot)))
					item_row_node.add_child(equip_button)
	label_in(left, "裝備", "PdaSection")
	var equipped_rows := VBoxContainer.new()
	equipped_rows.add_theme_constant_override("separation", Tokens.GAP)
	left.add_child(equipped_rows)
	var slot_names := {"main_hand": "主手", "body": "身體", "back": "背包"}
	var equipped_by_slot := {}
	for entry in player.get("equipment", {}).get("slots", []):
		equipped_by_slot[String(entry.get("slot", ""))] = String(entry.get("item_id", ""))
	for slot in ["main_hand", "body", "back"]:
		var equipped_id: String = String(equipped_by_slot.get(slot, ""))
		var equipped_row := HBoxContainer.new()
		equipped_row.add_theme_constant_override("separation", Tokens.GAP)
		equipped_rows.add_child(equipped_row)
		var equipment_label := label_in(equipped_row, "%s　%s" % [slot_names[slot], _item_display_name(equipped_id)])
		equipment_labels[slot] = equipment_label
		if not equipped_id.is_empty() and equipment_unequip_action.is_valid():
			var unequip_button := Button.new()
			unequip_button.text = "卸下"
			unequip_button.theme_type_variation = "PdaCommand"
			unequip_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
			unequip_button.pressed.connect(func(): equipment_unequip_action.call(slot))
			equipped_row.add_child(unequip_button)
	var right := panel_in(columns)
	label_in(right, "能力", "PdaSection")
	label_in(right, "0 外行 → 5 大師", "PdaMuted")
	for id in Presentation.Profile.SKILLS:
		var row := SkillRow.new()
		right.add_child(row)
		row.setup(id, character.ranks[id], character.get("practice", {}).get(id, {}))
		skill_rows[id] = row
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

func _item_display_name(item_id: String) -> String:
	if item_id == "":
		return "空"
	var resolved := ItemRegistry.resolve(item_id)
	return String(resolved.definition.display_name_zh) if resolved.success else "未知物品"

func _slot_name(slot: String) -> String:
	return {"main_hand": "主手", "body": "身體", "back": "背包"}.get(slot, slot)
