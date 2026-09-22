extends AcceptDialog

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Presentation = preload("res://ui/character_presentation.gd")
const SkillRow = preload("res://ui/components/skill_rank_row.gd")
var skill_rows: Dictionary = {}
var resource_values: Dictionary = {}
var capacity_label: Label
var identity_label: Label
var trait_label: Label

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

func setup(character: Dictionary, player: Dictionary) -> void:
	title = "人物與補給"
	theme_type_variation = "PdaDialog"
	ok_button_text = "返回旅程"
	get_ok_button().custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	get_ok_button().theme_type_variation = "PdaPrimary"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(816, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var columns := HBoxContainer.new()
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
	label_in(left, "瓶蓋　%d" % player.money)
	label_in(left, "撬棍　" + ("已裝備" if character.field_kit.equipped else ("持有 · 負重 2" if character.field_kit.crowbar else "未持有")))
	var bp: Dictionary = player.backpack
	for id in ["water", "food", "scrap", "fuel"]:
		var row := HBoxContainer.new()
		left.add_child(row)
		var names := {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}
		label_in(row, names[id])
		var count := Label.new()
		count.text = str(bp[id])
		row.add_child(count)
		resource_values[id] = count
	capacity_label = label_in(left, "背包容量　%d / %d" % [bp.load, bp.capacity])
	label_in(left, "查看人物與補給不消耗時間。", "PdaMuted")
	var right := panel_in(columns)
	label_in(right, "能力", "PdaSection")
	label_in(right, "0 外行 → 5 大師", "PdaMuted")
	for id in Presentation.Profile.SKILLS:
		var row := SkillRow.new()
		right.add_child(row)
		row.setup(id, character.ranks[id])
		skill_rows[id] = row
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
