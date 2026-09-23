extends Control

signal journey_requested
const Intent = preload("res://simulation/character_creation_intent.gd")
const Presentation = preload("res://ui/character_presentation.gd")
var world: WorldState
var engine: SimulationEngine
var name_input: LineEdit
var age_input: LineEdit
var background_id := "SCAVENGER"
var selected_traits: Array = []
var trait_buttons: Dictionary = {}
var background_buttons: Dictionary = {}
var preview: Label
var effect_label: Label
var trait_effect_label: Label
var trait_count: Label
var error_label: Label
var submit_button: Button
var enter_button: Button
var form: VBoxContainer
var summary: VBoxContainer
var summary_label: Label
var committed := false

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	build()

func label_in(parent: Node, text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("121316")
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 12)
	margin.add_child(form)
	label_in(form, "荒原編年史  /  建立角色", 24)
	label_in(form, "你從哪裡來，決定最初會做什麼。之後的故事，由旅途留下。", 16)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form.add_child(scroll)
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	scroll.add_child(columns)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = SIZE_EXPAND_FILL
	fields.size_flags_stretch_ratio = 1.35
	fields.add_theme_constant_override("separation", 8)
	columns.add_child(fields)
	var identity := HBoxContainer.new()
	fields.add_child(identity)
	label_in(identity, "姓名")
	name_input = LineEdit.new()
	name_input.placeholder_text = "輸入角色姓名"
	name_input.size_flags_horizontal = SIZE_EXPAND_FILL
	name_input.accessibility_name = "角色姓名"
	identity.add_child(name_input)
	label_in(identity, "年齡")
	age_input = LineEdit.new()
	age_input.text = "23"
	age_input.custom_minimum_size.x = 80
	age_input.accessibility_name = "角色年齡"
	identity.add_child(age_input)
	label_in(fields, "背景  /  選擇一項", 18)
	var backgrounds := GridContainer.new()
	backgrounds.columns = 2
	fields.add_child(backgrounds)
	for id in Presentation.BACKGROUNDS:
		var button := Button.new()
		button.text = Presentation.background_name(id)
		button.toggle_mode = true
		button.custom_minimum_size.y = 40
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(select_background.bind(id))
		backgrounds.add_child(button)
		background_buttons[id] = button
	trait_count = label_in(fields, "人物特質  /  0–2 項", 18)
	var note := label_in(fields, "部分特質會提供不同的遭遇處理方式。標示 ★ 的特質目前有專屬選項；其餘只影響敘事。", 14)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("96938B"))
	var traits := GridContainer.new()
	traits.columns = 2
	traits.add_theme_constant_override("h_separation", 16)
	fields.add_child(traits)
	# CHAR-INFO: a trait used to be a bare word with the explanation buried in a
	# tooltip, so the player was choosing blind. The description sits under the
	# name now, and traits that actually open a roadside approach say so - the
	# marker is derived from the encounter catalogue, never hand-maintained.
	for id in Presentation.Profile.CORE_TRAITS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 0)
		traits.add_child(cell)

		var button := CheckBox.new()
		var unlocks: Array = Presentation.trait_unlocks(id)
		button.text = "%s%s" % [Presentation.TRAITS[id][0], "　★" if not unlocks.is_empty() else ""]
		button.tooltip_text = Presentation.trait_effect_text(id)
		button.add_theme_color_override("font_disabled_color", Color("96938B"))
		button.accessibility_description = Presentation.TRAITS[id][1]
		button.custom_minimum_size.y = 30
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.toggled.connect(toggle_trait.bind(id))
		cell.add_child(button)

		var blurb := Label.new()
		blurb.text = "　　%s" % Presentation.TRAITS[id][1]
		blurb.add_theme_font_size_override("font_size", 12)
		blurb.add_theme_color_override("font_color", Color("8B877E"))
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.size_flags_horizontal = SIZE_EXPAND_FILL
		cell.add_child(blurb)
		trait_buttons[id] = button
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.2
	columns.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	label_in(box, "初始能力", 20).add_theme_color_override("font_color", Color("D9822B"))
	preview = label_in(box, "", 16)
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_theme_constant_override("line_spacing", 9)
	preview.size_flags_horizontal = SIZE_EXPAND_FILL
	var initial_note := label_in(box, "背景只決定初始能力，並非永久加成。", 14)
	initial_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	initial_note.add_theme_color_override("font_color", Color("96938B"))

	# CHAR-INFO: ranks alone never told the player what a background MEANS. This
	# section says what it can already do on the road and what it gives up, both
	# read back from the encounter catalogue rather than described here.
	var effect_head := label_in(box, "這個背景實際上的差別", 16)
	effect_head.add_theme_color_override("font_color", Color("D9822B"))
	effect_label = label_in(box, "", 13)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.size_flags_horizontal = SIZE_EXPAND_FILL
	effect_label.add_theme_constant_override("line_spacing", 4)

	var trait_head := label_in(box, "已選特質", 16)
	trait_head.add_theme_color_override("font_color", Color("D9822B"))
	trait_effect_label = label_in(box, "", 13)
	trait_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trait_effect_label.size_flags_horizontal = SIZE_EXPAND_FILL
	trait_effect_label.add_theme_constant_override("line_spacing", 4)
	error_label = label_in(form, "", 16)
	error_label.hide()
	error_label.add_theme_color_override("font_color", Color("D9822B"))
	submit_button = Button.new()
	submit_button.text = "開始旅程"
	submit_button.custom_minimum_size.y = 44
	submit_button.pressed.connect(submit)
	form.add_child(submit_button)
	summary = VBoxContainer.new()
	summary.add_theme_constant_override("separation", 12)
	summary.size_flags_horizontal = SIZE_SHRINK_CENTER
	summary.custom_minimum_size.x = 640
	margin.add_child(summary)
	summary.hide()
	label_in(summary, "角色已建立", 24)
	var summary_scroll := ScrollContainer.new()
	summary_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary.add_child(summary_scroll)
	summary_label = label_in(summary_scroll, "", 18)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.size_flags_horizontal = SIZE_EXPAND_FILL
	summary_label.add_theme_constant_override("line_spacing", 8)
	label_in(summary, "你只是一個無名的流浪者。世界不會等你。", 18)
	enter_button = Button.new()
	enter_button.text = "進入荒原"
	enter_button.custom_minimum_size.y = 44
	enter_button.pressed.connect(func(): journey_requested.emit())
	summary.add_child(enter_button)
	select_background(background_id)

func select_background(id: String) -> void:
	if committed:
		return
	background_id = id
	for key in background_buttons:
		background_buttons[key].set_pressed_no_signal(key == id)
	var package: Dictionary = Presentation.Catalogue.resolve(id)
	if package.success:
		preview.text = "%s\n%s\n\n%s" % [Presentation.background_name(id), Presentation.BACKGROUNDS[id][1], Presentation.starting_skill_text(package.ranks)]
		if effect_label != null:
			effect_label.text = Presentation.background_effect_text(id, package.ranks)
	else:
		preview.text = "無效背景"
		if effect_label != null:
			effect_label.text = ""
	_refresh_trait_effects()

# Traits change what you would THINK of doing, not what you are capable of, so
# the panel says that outright rather than showing an empty stat block.
func _refresh_trait_effects() -> void:
	if trait_effect_label == null:
		return
	if selected_traits.is_empty():
		trait_effect_label.text = "尚未選擇。特質不影響數值，只改變你在路上想得到的做法。"
		return
	var blocks := PackedStringArray()
	for id in selected_traits:
		blocks.append(Presentation.trait_effect_text(id))
	trait_effect_label.text = "\n\n".join(blocks)

func toggle_trait(enabled: bool, id: String) -> void:
	if committed:
		return
	if enabled and id not in selected_traits and selected_traits.size() < 2:
		selected_traits.append(id)
	elif not enabled:
		selected_traits.erase(id)
	for key in trait_buttons:
		trait_buttons[key].set_pressed_no_signal(key in selected_traits)
		trait_buttons[key].disabled = selected_traits.size() == 2 and key not in selected_traits
	trait_count.text = "人物特質  /  %d / 2（可不選）" % selected_traits.size()
	_refresh_trait_effects()

func submit() -> Dictionary:
	if committed:
		return {"success": false, "error": "CHARACTER_ALREADY_CREATED"}
	# Invalid text stays invalid; the authority decides, with no UI clamping.
	var age: Variant = int(age_input.text) if age_input.text.is_valid_int() else age_input.text
	var result := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": name_input.text,
		"age": age, "background_id": background_id, "trait_ids": selected_traits.duplicate()}))
	if not result.success:
		error_label.show()
		error_label.text = "無法建立角色。請檢查姓名、年齡、背景與特質選擇。"
		return result
	committed = true
	submit_button.disabled = true
	summary_label.text = Presentation.creation_summary(Presentation.project(world))
	form.hide()
	summary.show()
	enter_button.grab_focus()
	return result
