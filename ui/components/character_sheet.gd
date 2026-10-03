extends AcceptDialog

# ==============================================================================
# CHARACTER SHEET — 人物與行囊
# ==============================================================================
# Hand-play: "人物裝備欄和設備欄可以參考RPG相關設定 不應該是這樣設定的",
# pointing at Lunatic Dawn's character window. That window reads at a glance
# because it is laid out, not listed: a portrait with bars, abilities as a grid
# of bars, equipment as slots. So this sheet is three panels side by side:
#
#   人物        portrait, name, bars (life, experience, load), money, the
#               companion walking with you, traits, life experience, perks
#   裝備與行囊   the three slots as boxes, supplies as counts, carried items
#               with their equip / use actions
#   能力        the ten skills as a two-column grid of bars, and growth points
#               spent right beside the skill they raise
#
# Rumours are no longer here ("在這邊做提示感覺有點怪"): what you have heard is
# not part of who you are, so it has its own window (rumor_window.gd).
#
# The members the rest of the game and the tests read (skill_rows, item_labels,
# equipment_labels, growth_buttons, item_use_buttons, ...) keep their meaning.
# ==============================================================================

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Presentation = preload("res://ui/character_presentation.gd")
const SkillRow = preload("res://ui/components/skill_rank_row.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Acquired = preload("res://simulation/acquired_traits.gd")
const PORTRAIT := "res://ui/assets/combat/drifter.png"

var skill_rows: Dictionary = {}
var growth_buttons: Dictionary = {}
# Kept for compatibility; rumours now live in rumor_window.gd.
var rumor_buttons: Dictionary = {}
var growth_points_available: int = 0
var resource_values: Dictionary = {}
var item_labels: Dictionary = {}
var equipment_labels: Dictionary = {}
var item_use_buttons: Dictionary = {}
var action_notice_label: Label
var capacity_label: Label
var identity_label: Label
var trait_label: Label
var equipment_action: Callable
var equipment_unequip_action: Callable
var item_use_action: Callable
var perk_action: Callable
var acquired_action: Callable
var perk_choice_buttons: Dictionary = {}

func label_in(parent: Node, text: String, variant: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

# One of the three side-by-side windows: a titled panel that scrolls on its own.
func column_in(parent: Node, heading: String, stretch: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "PdaPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch
	parent.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", Tokens.GAP)
	panel.add_child(outer)
	var title_label := Label.new()
	title_label.text = heading
	title_label.add_theme_color_override("font_color", Tokens.AMBER)
	title_label.add_theme_font_size_override("font_size", Tokens.SMALL)
	outer.add_child(title_label)
	outer.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", Tokens.GAP)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column

func bar_in(parent: Node, caption: String, value: int, maximum: int, fill: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = caption
	name_label.custom_minimum_size.x = 36
	name_label.add_theme_color_override("font_color", Tokens.SECONDARY)
	row.add_child(name_label)
	var bar := ProgressBar.new()
	bar.max_value = float(maxi(1, maximum))
	bar.value = float(clampi(value, 0, maximum))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(60, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := StyleBoxFlat.new()
	back.bg_color = Tokens.BASE
	back.border_color = Tokens.BORDER_STRONG
	back.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", back)
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	bar.add_theme_stylebox_override("fill", front)
	row.add_child(bar)
	var number := Label.new()
	number.text = "%d / %d" % [value, maximum]
	number.custom_minimum_size.x = 58
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(number)
	return number

func item_row(parent: Node, id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	row.add_child(ItemIcon.new(id, 32))
	return row

func setup(character: Dictionary, player: Dictionary, p_equipment_action: Callable = Callable(), p_unequip_action: Callable = Callable(), p_item_use_action: Callable = Callable(), p_item_use_disabled_reason: String = "", p_action_notice: String = "", p_perk_action: Callable = Callable(), p_acquired_action: Callable = Callable(), p_growth_action: Callable = Callable(), _p_rumor_action: Callable = Callable()) -> void:
	equipment_action = p_equipment_action
	equipment_unequip_action = p_unequip_action
	item_use_action = p_item_use_action
	perk_action = p_perk_action
	acquired_action = p_acquired_action
	title = "人物與行囊"
	theme_type_variation = "PdaDialog"
	ok_button_text = "返回旅程"
	wrap_controls = false
	get_ok_button().custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	get_ok_button().theme_type_variation = "PdaPrimary"
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", Tokens.GAP)
	columns.custom_minimum_size = Vector2(760, 440)
	add_child(columns)
	_build_person(column_in(columns, "人物", 1.0), character, player)
	_build_gear(column_in(columns, "裝備與行囊", 1.05), character, player, p_item_use_disabled_reason)
	_build_skills(column_in(columns, "能力", 1.15), character, p_growth_action)
	show_notice(p_action_notice)
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

# ── 人物 ───────────────────────────────────────────────────────────────────────
func _build_person(left: VBoxContainer, character: Dictionary, player: Dictionary) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", Tokens.PAD)
	left.add_child(head)
	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Tokens.BASE
	frame_style.border_color = Tokens.BORDER_STRONG
	frame_style.set_border_width_all(1)
	frame.add_theme_stylebox_override("panel", frame_style)
	head.add_child(frame)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(52, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = preload("res://ui/components/battle_stage.gd").TextureHelper.load_texture_safe(PORTRAIT)
	frame.add_child(portrait)
	var who := VBoxContainer.new()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(who)
	identity_label = label_in(who, "%s · %d 歲" % [character.name, character.age], "PdaTitle")
	identity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	identity_label.clip_text = true
	label_in(who, Presentation.background_name(character.background_id), "PdaMuted")
	label_in(who, "Lv.%d" % int(character.level))
	label_in(who, "瓶蓋 %d" % int(player.money))
	bar_in(left, "生命", int(character.field_kit.hp), 12, Tokens.CRITICAL)
	bar_in(left, "歷練", int(character.xp), int(character.next_level_xp), Tokens.AMBER)
	var bp: Dictionary = player.backpack
	capacity_label = bar_in(left, "負重", int(bp.load), int(bp.capacity), Color("#6B8F71"))
	var party: Dictionary = player.get("party", {})
	if String(party.get("summary", "")) != "":
		label_in(left, "同行夥伴", "PdaSection")
		label_in(left, String(party.summary).replace("同行：", ""))
	action_notice_label = label_in(left, "", "PdaSection")
	action_notice_label.visible = false
	label_in(left, "人物特質", "PdaSection")
	trait_label = label_in(left, Presentation.trait_text(character.traits))
	label_in(left, "部分特質會提供不同的遭遇處理方式。", "PdaMuted")
	if not character.acquired_traits.is_empty() or not character.acquired_candidates.is_empty():
		label_in(left, "人生經歷", "PdaSection")
		for trait_id in character.acquired_traits:
			label_in(left, "%s　%s" % [Acquired.TRAITS[trait_id].name_zh, Acquired.TRAITS[trait_id].description_zh])
		for trait_id in character.acquired_candidates:
			label_in(left, "你的經歷讓「%s」成為可能：%s" % [Acquired.TRAITS[trait_id].name_zh, Acquired.TRAITS[trait_id].description_zh])
			var accept_button := Button.new()
			accept_button.text = "接受　%s" % Acquired.TRAITS[trait_id].name_zh
			accept_button.theme_type_variation = "PdaCommand"
			accept_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
			accept_button.disabled = not acquired_action.is_valid() or String(player.status) != "SETTLED"
			accept_button.pressed.connect(func(): acquired_action.call(String(trait_id)))
			left.add_child(accept_button)
		label_in(left, "現在不選也可以；這段經歷仍會留在你的人生裡。", "PdaMuted")
	label_in(left, "特長", "PdaSection")
	if character.perks.is_empty():
		label_in(left, "尚未選擇特長。", "PdaMuted")
	else:
		for perk_id in character.perks:
			label_in(left, "%s　%s" % [Perks.PERKS[perk_id].name_zh, Perks.PERKS[perk_id].description_zh])
	if not character.perk_choices.is_empty():
		label_in(left, "里程碑已到：選擇一項專長", "PdaSection")
		for choice in character.perk_choices:
			label_in(left, "%s　%s" % [choice.name_zh, choice.description_zh])
			var perk_button := Button.new()
			perk_button.text = "選擇　%s" % choice.name_zh
			perk_button.theme_type_variation = "PdaCommand"
			perk_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
			perk_button.disabled = not perk_action.is_valid() or String(player.status) != "SETTLED"
			perk_button.pressed.connect(func(): perk_action.call(String(choice.id)))
			left.add_child(perk_button)
			perk_choice_buttons[String(choice.id)] = perk_button

# ── 裝備與行囊 ─────────────────────────────────────────────────────────────────
func _build_gear(middle: VBoxContainer, character: Dictionary, player: Dictionary, item_use_disabled_reason: String) -> void:
	label_in(middle, "裝備", "PdaSection")
	var slot_names := {"main_hand": "主手", "body": "身體", "back": "背包"}
	var equipped_by_slot := {}
	for entry in player.get("equipment", {}).get("slots", []):
		equipped_by_slot[String(entry.get("slot", ""))] = String(entry.get("item_id", ""))
	for slot in ["main_hand", "body", "back"]:
		var equipped_id: String = String(equipped_by_slot.get(slot, ""))
		var box := PanelContainer.new()
		var box_style := StyleBoxFlat.new()
		box_style.bg_color = Tokens.ELEVATED if equipped_id != "" else Tokens.BASE
		box_style.border_color = Tokens.AMBER if equipped_id != "" else Tokens.BORDER_STRONG
		box_style.set_border_width_all(1)
		box_style.content_margin_left = 6
		box_style.content_margin_right = 6
		box_style.content_margin_top = 4
		box_style.content_margin_bottom = 4
		box.add_theme_stylebox_override("panel", box_style)
		middle.add_child(box)
		var equipped_row := HBoxContainer.new()
		equipped_row.add_theme_constant_override("separation", Tokens.GAP)
		box.add_child(equipped_row)
		if equipped_id != "":
			equipped_row.add_child(ItemIcon.new(equipped_id, 40))
		else:
			var empty_slot := Control.new()
			empty_slot.custom_minimum_size = Vector2(40, 40)
			equipped_row.add_child(empty_slot)
		var equipment_label := label_in(equipped_row, "%s　%s" % [slot_names[slot], _item_display_name(equipped_id)])
		equipment_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if equipped_id == "":
			equipment_label.add_theme_color_override("font_color", Tokens.DIM)
		equipment_labels[slot] = equipment_label
		if not equipped_id.is_empty() and equipment_unequip_action.is_valid():
			var unequip_button := Button.new()
			unequip_button.text = "卸下"
			unequip_button.theme_type_variation = "PdaCommand"
			unequip_button.custom_minimum_size = Vector2(56, Tokens.COMMAND_HEIGHT)
			unequip_button.pressed.connect(func(): equipment_unequip_action.call(slot))
			equipped_row.add_child(unequip_button)
	label_in(middle, "隨身補給", "PdaSection")
	var bp: Dictionary = player.backpack
	var supplies := GridContainer.new()
	supplies.columns = 3
	supplies.add_theme_constant_override("h_separation", Tokens.PAD)
	supplies.add_theme_constant_override("v_separation", Tokens.GAP)
	middle.add_child(supplies)
	var names := {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}
	for id in ["water", "food", "scrap", "fuel"]:
		var row := item_row(supplies, id)
		var named := Label.new()
		named.text = names[id]
		row.add_child(named)
		var count := Label.new()
		count.text = str(bp[id])
		count.add_theme_color_override("font_color", Tokens.TEXT)
		row.add_child(count)
		resource_values[id] = count
	var crowbar_row := item_row(supplies, "crowbar")
	var crowbar := Label.new()
	crowbar.text = "撬棍 " + ("已裝備" if character.field_kit.equipped else ("持有" if character.field_kit.crowbar else "—"))
	crowbar_row.add_child(crowbar)
	label_in(middle, "行囊", "PdaSection")
	var owned_items: Array = player.get("items", [])
	if owned_items.is_empty():
		label_in(middle, "目前沒有額外物品。", "PdaMuted")
	for entry in owned_items:
		var item_id := String(entry.get("item_id", ""))
		var resolved := ItemRegistry.resolve(item_id)
		if not resolved.success:
			continue
		var row_node := item_row(middle, item_id)
		var item_label := label_in(row_node, "%s ×%d" % [resolved.definition.display_name_zh, int(entry.get("quantity", 0))])
		item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_labels[item_id] = item_label
		item_label.tooltip_text = String(resolved.definition.description_zh)
		if Gear.PROTECTION.has(item_id) or Gear.PACK_CARGO.has(item_id) or Gear.MECHANICAL_TOOLS.has(item_id) or Gear.ELECTRONIC_TOOLS.has(item_id):
			label_in(middle, String(resolved.definition.description_zh), "PdaMuted")
		if item_id == "first_aid_kit" and item_use_action.is_valid():
			var use_button := Button.new()
			use_button.text = "使用 · 生命最多 +4" if item_use_disabled_reason.is_empty() else "急救包 · " + item_use_disabled_reason
			use_button.theme_type_variation = "PdaCommand"
			use_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
			use_button.disabled = not item_use_disabled_reason.is_empty()
			use_button.tooltip_text = item_use_disabled_reason
			use_button.pressed.connect(func(): item_use_action.call("first_aid_kit"))
			row_node.add_child(use_button)
			item_use_buttons["first_aid_kit"] = use_button
		if equipment_action.is_valid():
			for slot in resolved.definition.equip_slots:
				var equip_button := Button.new()
				equip_button.text = "裝備到%s" % _slot_name(String(slot))
				equip_button.theme_type_variation = "PdaCommand"
				equip_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
				equip_button.pressed.connect(func(): equipment_action.call(item_id, String(slot)))
				row_node.add_child(equip_button)
	label_in(middle, "查看人物與行囊不消耗時間。", "PdaMuted")

# ── 能力 ───────────────────────────────────────────────────────────────────────
func _build_skills(right: VBoxContainer, character: Dictionary, p_growth_action: Callable) -> void:
	label_in(right, "0 外行 → 5 大師", "PdaMuted")
	# PLAY-2: a level hands the player a decision, shown where the skills are.
	var growth_rows: Array = character.get("growth_choices", [])
	growth_points_available = int(character.get("growth_points", 0))
	if growth_points_available > 0:
		var banner := label_in(right, "可用成長點：%d" % growth_points_available, "PdaTitle")
		banner.add_theme_color_override("font_color", Tokens.AMBER)
		label_in(right, "你這一路換來的。要把自己練成什麼，由你決定。", "PdaMuted")
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(list)
	for id in Presentation.Profile.SKILLS:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", Tokens.GAP)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(cell)
		var row := SkillRow.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(row)
		row.setup(id, character.ranks[id], character.get("practice", {}).get(id, {}))
		skill_rows[id] = row
		if growth_points_available <= 0:
			continue
		var choice := {}
		for candidate in growth_rows:
			if String(candidate.skill_id) == id:
				choice = candidate
		# The growth point sits at the end of the skill it raises, like a stat
		# "+" in any RPG. A closed one stays visible, greyed, with its reason -
		# a locked door with a reason on it teaches the player something.
		var spend := Button.new()
		spend.text = "＋1"
		spend.theme_type_variation = "PdaCommand"
		spend.custom_minimum_size = Vector2(52, 30)
		spend.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not choice.is_empty() and bool(choice.can_spend) and p_growth_action.is_valid():
			spend.tooltip_text = "投入 1 點　%s +1" % Presentation.SKILL_NAMES[id]
			spend.pressed.connect(func(): p_growth_action.call(id))
			growth_buttons[id] = spend
		else:
			spend.disabled = true
			spend.tooltip_text = String(choice.get("reason", "")) if not choice.is_empty() else ""
		cell.add_child(spend)
	if growth_points_available > 0:
		label_in(right, "灰色的「＋1」是現在還用不到的能力，滑鼠停在上面看原因。", "PdaMuted")

func show_notice(text: String) -> void:
	if action_notice_label == null:
		return
	action_notice_label.text = text
	action_notice_label.visible = not text.is_empty()

func _item_display_name(item_id: String) -> String:
	if item_id == "":
		return "空"
	var resolved := ItemRegistry.resolve(item_id)
	return String(resolved.definition.display_name_zh) if resolved.success else "未知物品"

func _slot_name(slot: String) -> String:
	return {"main_hand": "主手", "body": "身體", "back": "背包"}.get(slot, slot)
