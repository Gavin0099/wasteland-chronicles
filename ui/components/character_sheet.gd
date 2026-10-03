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
const Field = preload("res://simulation/field_adventure.gd")
const Presentation = preload("res://ui/character_presentation.gd")
const SkillRow = preload("res://ui/components/skill_rank_row.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Acquired = preload("res://simulation/acquired_traits.gd")
const GearPresentation = preload("res://ui/gear_presentation.gd")
const InventoryPresentation = preload("res://ui/inventory_presentation.gd")
const ItemDescription = preload("res://ui/item_description.gd")
const PORTRAIT := "res://ui/assets/combat/drifter.png"

var skill_rows: Dictionary = {}
var growth_buttons: Dictionary = {}
# Kept for compatibility; rumours now live in rumor_window.gd.
var rumor_buttons: Dictionary = {}
var growth_points_available: int = 0
var resource_values: Dictionary = {}
var item_labels: Dictionary = {}
var item_descriptions: Dictionary = {}
var equipment_labels: Dictionary = {}
var item_use_buttons: Dictionary = {}
var action_notice_label: Label
var capacity_label: Label
var identity_label: Label
var trait_label: Label
var equipment_action: Callable
var equipment_unequip_action: Callable
var item_use_action: Callable
var item_rumor_action: Callable
var item_guide_label: Label
var item_rumor_button: Button
var perk_action: Callable
var acquired_action: Callable
var perk_choice_buttons: Dictionary = {}
var detail_buttons: Dictionary = {}
var tool_labels: Dictionary = {}
var experience_labels: Array[Label] = []
var aspiration_label: Label
var gear_data: Dictionary = {}
var item_detail: AcceptDialog
var inventory_category: OptionButton
var inventory_order: OptionButton
var inventory_search: LineEdit
var inventory_summary: Label
var inventory_empty: Label
var inventory_list: VBoxContainer
var inventory_scroll: ScrollContainer
var inventory_jump: Button
var inventory_items: Array = []
var inventory_state: Dictionary = {}
var inventory_use_reason: String = ""
var inventory_use_reasons: Dictionary = {}
var inventory_requested: bool = false
signal inventory_view_changed(state: Dictionary)

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

func setup(character: Dictionary, player: Dictionary, p_equipment_action: Callable = Callable(), p_unequip_action: Callable = Callable(), p_item_use_action: Callable = Callable(), p_item_use_disabled_reason: String = "", p_action_notice: String = "", p_perk_action: Callable = Callable(), p_acquired_action: Callable = Callable(), p_growth_action: Callable = Callable(), _p_rumor_action: Callable = Callable(), p_inventory_state: Dictionary = {}, p_item_use_reasons: Dictionary = {}) -> void:
	equipment_action = p_equipment_action
	equipment_unequip_action = p_unequip_action
	item_use_action = p_item_use_action
	inventory_use_reasons = p_item_use_reasons.duplicate(true)
	item_rumor_action = _p_rumor_action
	perk_action = p_perk_action
	acquired_action = p_acquired_action
	gear_data = character.get("gear", {}).duplicate(true)
	inventory_state = InventoryPresentation.normalize(p_inventory_state)
	inventory_requested = bool(p_inventory_state.get("show_inventory", false))
	title = "人物與行囊"
	theme_type_variation = "PdaDialog"
	ok_button_text = "返回旅程"
	wrap_controls = false
	get_ok_button().custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	get_ok_button().theme_type_variation = "PdaPrimary"
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", Tokens.GAP)
	columns.custom_minimum_size = Vector2(920, 440)
	add_child(columns)
	_build_person(column_in(columns, "人物", 1.0), character, player)
	_build_gear(column_in(columns, "裝備與行囊", 1.4), character, player, p_item_use_disabled_reason)
	_build_skills(column_in(columns, "能力", 1.15), character, p_growth_action)
	show_notice(p_action_notice)
	if inventory_requested: call_deferred("_show_inventory")
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
	identity_label = label_in(who, String(character.name), "PdaTitle")
	label_in(who, "%d 歲 · %s" % [int(character.age), Presentation.background_name(character.background_id)], "PdaMuted")
	label_in(who, "Lv.%d" % int(character.level))
	label_in(who, "瓶蓋 %d" % int(player.money))
	bar_in(left, "生命", int(character.field_kit.hp), 12, Tokens.CRITICAL)
	bar_in(left, "歷練", int(character.xp), int(character.next_level_xp), Tokens.AMBER)
	var bp: Dictionary = player.backpack
	capacity_label = bar_in(left, "負重", int(bp.load), int(bp.capacity), Tokens.AMBER)
	var party: Dictionary = player.get("party", {})
	if String(party.get("summary", "")) != "":
		label_in(left, "同行夥伴", "PdaSection")
		label_in(left, String(party.summary).replace("同行：", ""))
	action_notice_label = label_in(left, "", "PdaSection")
	action_notice_label.visible = false
	label_in(left, "正在追尋", "PdaSection")
	var aim: Dictionary = gear_data.get("aspiration", {})
	aspiration_label = label_in(left, String(aim.get("title", "尚未選擇目標；可到傳聞頁選擇。")))
	if not aim.is_empty():
		label_in(left, ("已達成 · " if bool(aim.get("done", false)) else "下一步 · ") + String(aim.get("next", "")), "PdaMuted")
	label_in(left, "經歷", "PdaSection")
	for line: String in gear_data.get("experiences", []):
		experience_labels.append(label_in(left, "· " + line))
	if experience_labels.is_empty():
		label_in(left, "還沒有留下聚落或同行的經歷。", "PdaMuted")
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
			var inspect := _detail_button(equipped_id)
			equipped_row.add_child(inspect)
		else:
			var empty_slot := Control.new()
			empty_slot.custom_minimum_size = Vector2(40, 40)
			equipped_row.add_child(empty_slot)
		var equipment_label := label_in(equipped_row, "%s　%s" % [slot_names[slot], _item_display_name(equipped_id)])
		equipment_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if equipped_id == "":
			equipment_label.add_theme_color_override("font_color", Tokens.SECONDARY)
		equipment_labels[slot] = equipment_label
		if not equipped_id.is_empty() and equipment_unequip_action.is_valid():
			var unequip_button := Button.new()
			unequip_button.text = "卸下"
			unequip_button.theme_type_variation = "PdaCommand"
			unequip_button.custom_minimum_size = Vector2(56, Tokens.COMMAND_HEIGHT)
			unequip_button.pressed.connect(func(): equipment_unequip_action.call(slot))
			equipped_row.add_child(unequip_button)
	label_in(middle, "隨身工具 · 持有即可用", "PdaSection")
	for tool: Dictionary in gear_data.get("tools", []):
		var row := item_row(middle, String(tool.item_id))
		var tool_label := label_in(row, "%s知識 %d · 工具 %d\n%s" % ["機械" if tool.skill == "MECHANICS" else "電子", int(tool.rank), int(tool.grade), String(tool.name)])
		tool_labels[tool.skill] = tool_label
		if tool.item_id != "": row.add_child(_detail_button(String(tool.item_id)))
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
	label_in(middle, "水／食物：旅途每天消耗。廢料：製作與維修。燃料：交易與運補。撬棍：裝備後強化近戰，可開灰谷補給箱。", "PdaMuted")
	label_in(middle, "行囊", "PdaSection")
	label_in(middle, "正式物品 %.2f / %.2f 公斤" % [float(player.get("item_load_g", 0)) / 1000.0, float(player.get("item_capacity_g", 12000)) / 1000.0], "PdaMuted")
	inventory_items = player.get("items", []).duplicate(true)
	inventory_use_reason = item_use_disabled_reason
	inventory_scroll = middle.get_parent() as ScrollContainer
	inventory_jump = Button.new()
	inventory_jump.text = "整理行囊 · %d 種物品" % inventory_items.size()
	inventory_jump.theme_type_variation = "PdaCommand"
	inventory_jump.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	var panel_outer: VBoxContainer = inventory_scroll.get_parent() as VBoxContainer
	panel_outer.add_child(inventory_jump)
	panel_outer.move_child(inventory_jump, 2)
	inventory_jump.pressed.connect(_show_inventory)
	var filters: HBoxContainer = HBoxContainer.new()
	filters.add_theme_constant_override("separation", Tokens.GAP)
	middle.add_child(filters)
	inventory_category = OptionButton.new()
	inventory_category.accessibility_name = "物品分類"
	inventory_order = OptionButton.new()
	inventory_order.accessibility_name = "物品排序"
	for name_text: String in InventoryPresentation.CATEGORY_NAMES: inventory_category.add_item(name_text)
	for name_text: String in InventoryPresentation.ORDER_NAMES: inventory_order.add_item(name_text)
	for selector: OptionButton in [inventory_category, inventory_order]:
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		filters.add_child(selector)
	inventory_category.select(InventoryPresentation.CATEGORIES.find(inventory_state.category))
	inventory_order.select(InventoryPresentation.ORDERS.find(inventory_state.order))
	inventory_search = LineEdit.new()
	inventory_search.placeholder_text = "搜尋物品名稱或用途"
	inventory_search.accessibility_name = "搜尋行囊中的物品名稱或用途"
	inventory_search.clear_button_enabled = true
	inventory_search.add_theme_stylebox_override("normal", get_theme_stylebox("normal", "Button"))
	inventory_search.add_theme_stylebox_override("focus", get_theme_stylebox("focus", "Button"))
	inventory_search.add_theme_color_override("font_color", Tokens.TEXT)
	inventory_search.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	inventory_search.text = inventory_state.query
	middle.add_child(inventory_search)
	inventory_summary = label_in(middle, "", "PdaMuted")
	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", Tokens.PAD)
	middle.add_child(inventory_list)
	inventory_empty = label_in(middle, "", "PdaMuted")
	inventory_category.item_selected.connect(func(_index: int): _refresh_inventory())
	inventory_order.item_selected.connect(func(_index: int): _refresh_inventory())
	inventory_search.text_changed.connect(func(_text: String): _refresh_inventory())
	_refresh_inventory(false)
	label_in(middle, "查看人物與行囊不消耗時間。", "PdaMuted")

func _show_inventory() -> void:
	inventory_requested = true
	# Align the filter row at the viewport top so results are visible too.
	inventory_scroll.scroll_vertical = int((inventory_category.get_parent() as Control).position.y)
	inventory_search.grab_focus()
	_publish_inventory_view()

func _publish_inventory_view() -> void:
	var state: Dictionary = inventory_state.duplicate(true)
	state["show_inventory"] = inventory_requested
	inventory_view_changed.emit(state)

func _refresh_inventory(user_changed: bool = true) -> void:
	if user_changed: inventory_requested = true
	inventory_state = {"category": InventoryPresentation.CATEGORIES[inventory_category.selected],
		"order": InventoryPresentation.ORDERS[inventory_order.selected], "query": inventory_search.text}
	for child: Node in inventory_list.get_children(): child.free()
	item_labels.clear()
	item_descriptions.clear()
	item_use_buttons.clear()
	detail_buttons.clear()
	var visible_items: Array[Dictionary] = InventoryPresentation.rows(inventory_items, inventory_state)
	var selected_weight: int = 0
	for entry: Dictionary in visible_items: selected_weight += int(entry.weight_g)
	inventory_summary.text = "顯示 %d / %d 種 · 此篩選 %.2f 公斤" % [visible_items.size(), inventory_items.size(), float(selected_weight) / 1000.0]
	inventory_empty.visible = visible_items.is_empty()
	inventory_empty.text = "目前沒有額外物品。" if inventory_items.is_empty() else "沒有符合分類與搜尋的物品；可清除搜尋或選擇全部物品。"
	for entry: Dictionary in visible_items:
		var item_id: String = entry.item_id
		var definition: Dictionary = entry.definition
		var block: VBoxContainer = VBoxContainer.new()
		block.add_theme_constant_override("separation", Tokens.GAP)
		inventory_list.add_child(block)
		var row_node: HBoxContainer = item_row(block, item_id)
		var item_label: Label = label_in(row_node, "%s ×%d · %.2f 公斤\n%s · %s" % [entry.name, entry.quantity, float(entry.weight_g) / 1000.0, definition.tier, {"COMMON": "普通", "MODIFIED": "改良", "RARE": "稀有", "UNIQUE": "獨特"}[definition.quality]])
		item_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_labels[item_id] = item_label
		item_label.tooltip_text = String(definition.description_zh)
		item_descriptions[item_id] = label_in(block, ItemDescription.text(item_id), "PdaMuted")
		var actions: HBoxContainer = HBoxContainer.new()
		actions.add_theme_constant_override("separation", Tokens.GAP)
		block.add_child(actions)
		var inspect: Button = _detail_button(item_id)
		actions.add_child(inspect)
		detail_buttons[item_id] = inspect
		if Field.TREATMENT_HEALING.has(item_id) and item_use_action.is_valid():
			var use_reason: String = String(inventory_use_reasons.get(item_id, inventory_use_reason))
			var use_button := Button.new()
			use_button.text = "使用 · 生命最多 +%d" % int(Field.TREATMENT_HEALING[item_id]) if use_reason.is_empty() else _item_display_name(item_id) + " · " + use_reason
			use_button.theme_type_variation = "PdaCommand"
			use_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
			use_button.disabled = not use_reason.is_empty()
			use_button.tooltip_text = use_reason
			use_button.pressed.connect(func(): item_use_action.call(item_id))
			actions.add_child(use_button)
			item_use_buttons[item_id] = use_button
		if equipment_action.is_valid():
			for slot in definition.equip_slots:
				var equip_button := Button.new()
				equip_button.text = "裝備到%s" % _slot_name(String(slot))
				equip_button.theme_type_variation = "PdaCommand"
				equip_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
				equip_button.pressed.connect(func(): equipment_action.call(item_id, String(slot)))
				actions.add_child(equip_button)
	_publish_inventory_view()

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

func _detail_button(id: String) -> Button:
	var button := Button.new()
	button.text = "詳細說明"
	button.theme_type_variation = "PdaCommand"
	button.custom_minimum_size = Vector2(56, Tokens.COMMAND_HEIGHT)
	button.accessibility_name = "查看" + _item_display_name(id) + "的用途與比較"
	button.pressed.connect(func(): show_item_detail(id))
	return button

func _comparison_column(parent: Node, heading: String, name_text: String, stats: Dictionary) -> void:
	# The complete detail body already scrolls; nested column scrolls collapse here.
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = "PdaPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", Tokens.GAP)
	panel.add_child(column)
	var title_label: Label = label_in(column, heading, "PdaMuted")
	title_label.add_theme_color_override("font_color", Tokens.AMBER)
	column.add_child(HSeparator.new())
	label_in(column, name_text, "PdaSection")
	for line: String in stats.get("lines", []):
		label_in(column, line)
	for property: String in stats.get("properties", []):
		label_in(column, property, "PdaMuted")

func show_item_detail(id: String) -> void:
	if not gear_data.get("details", {}).has(id):
		return
	if is_instance_valid(item_detail):
		item_detail.queue_free()
	var data: Dictionary = gear_data.details[id]
	item_detail = AcceptDialog.new()
	item_detail.title = "裝備詳情 · " + String(data.name)
	item_detail.theme_type_variation = "PdaDialog"
	item_detail.wrap_controls = false
	add_child(item_detail)
	var outer := VBoxContainer.new()
	outer.custom_minimum_size = Vector2(640, 360)
	outer.add_theme_constant_override("separation", Tokens.GAP)
	item_detail.add_child(outer)
	var head := item_row(outer, id)
	head.add_child(label_in_unparented("%s · %s · %s" % [data.name, data.tier, data.quality], "PdaTitle"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", Tokens.GAP)
	scroll.add_child(content)
	var compared := HBoxContainer.new()
	compared.size_flags_vertical = Control.SIZE_EXPAND_FILL
	compared.add_theme_constant_override("separation", Tokens.PAD)
	content.add_child(compared)
	if String(data.current_id) != id and (String(data.slot) != "" or String(data.current_id) != ""):
		_comparison_column(compared, "目前裝備" if String(data.slot) != "" else "目前最佳工具", String(data.current_name), data.current)
	_comparison_column(compared, "已裝備" if bool(data.equipped) else "選取物品", String(data.name), data.candidate)
	if String(data.slot) == "main_hand":
		var legend := label_in_unparented("常態傷害含技巧與同行支援；架勢、快拔另依時機生效。", "PdaMuted")
		legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(legend)
	var guidance: Dictionary = data.get("guidance", {})
	item_guide_label = label_in(content, "%s\n%s\n%s" % [guidance.get("source", ""), guidance.get("use", ""), guidance.get("pursuit", "")])
	item_rumor_button = null
	if bool(guidance.get("rumor_entry", false)) and item_rumor_action.is_valid():
		item_rumor_button = Button.new()
		item_rumor_button.text = "打開傳聞 · 自行選擇追尋目標"
		item_rumor_button.theme_type_variation = "PdaCommand"
		item_rumor_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		outer.add_child(item_rumor_button)
		item_rumor_button.pressed.connect(item_rumor_action)
	var can_equip: bool = String(data.slot) != "" and not bool(data.equipped) and equipment_action.is_valid()
	item_detail.ok_button_text = "裝備到" + _slot_name(String(data.slot)) if can_equip else "返回人物"
	item_detail.get_ok_button().custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	item_detail.get_ok_button().theme_type_variation = "PdaPrimary"
	var detail: AcceptDialog = item_detail
	detail.confirmed.connect(func():
		if can_equip: equipment_action.call(id, String(data.slot))
		detail.queue_free())
	detail.canceled.connect(detail.queue_free)
	var viewport_size: Vector2 = Vector2(get_tree().root.size)
	detail.popup_centered(Vector2i(int(viewport_size.x * 0.7), int(viewport_size.y * 0.7)))
	detail.get_ok_button().grab_focus()

func label_in_unparented(text: String, variant: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

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
