extends AcceptDialog

# ==============================================================================
# MARKET WINDOW — the local trade screen
# ==============================================================================
# Hand-play, twice: first "下方的物品太短 導致很難找東西", then, of a one-row-
# four-buttons table, "這邊還是設計得不好 感覺不好點". On a wide screen the name
# sat far from its numbers and every row carried four small targets.
#
# So this follows the shop pattern most RPGs settle on - pick, then act:
#
#   left   the list, one large clickable row per thing (icon, name, what you
#          have, the price), filtered by category tabs
#   right  the chosen thing: a large icon, what it is, stock and prices, a
#          quantity stepper, and two large buttons - 買入 N and 賣出 N - that
#          say exactly what they will cost or pay
#
# Money, pack load and how this town treats you stay in the header. A refusal
# is said in words. What the town is asking for in its jobs shows as 正缺 and
# cannot be bought here. Every rule, price and refusal is still the engine's:
# this window only calls the shell's trade handlers.
# ==============================================================================

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")

const COMMODITIES := [
	{"key": "water", "name": "水", "text": "喝的。路上每天一份，沒有就撐不久。"},
	{"key": "food", "name": "食物", "text": "吃的。路上每天一份。"},
	{"key": "scrap", "name": "廢料", "text": "拆下來的金屬和零件。可以組裝工具，也有鎮在收。"},
	{"key": "fuel", "name": "燃料", "text": "油。缺燃料的鎮會高價收購。"},
]
const TABS := [
	{"id": "ALL", "label": "全部"},
	{"id": "SUPPLY", "label": "補給"},
	{"id": "WEAPON", "label": "武器"},
	{"id": "WEAR", "label": "衣物與背包"},
	{"id": "TOOL", "label": "工具"},
	{"id": "OWNED", "label": "你身上的"},
]
const CATEGORY_TAB := {"WEAPON": "WEAPON", "APPAREL": "WEAR", "CONTAINER": "WEAR", "TOOL": "TOOL", "CONSUMABLE": "SUPPLY"}
const REFUSALS := {
	"INSUFFICIENT_FUNDS": "瓶蓋不夠。", "INSUFFICIENT_STOCK": "店裡沒那麼多貨。", "INSUFFICIENT_ITEM_STOCK": "店裡沒那麼多貨。",
	"INSUFFICIENT_MARKET_CASH": "店家現在沒錢收你的貨。", "INSUFFICIENT_PLAYER_STOCK": "你身上沒那麼多。",
	"BACKPACK_FULL": "背包裝不下了。", "CAPACITY_EXCEEDED": "背包裝不下了。", "INVENTORY_FULL": "背包裝不下了。",
	"ITEM_WANTED_HERE": "這裡正缺這個，所以才發委託收購——去別的鎮買，或自己找。",
	"ITEM_NOT_SOLD_HERE": "這個鎮不賣這個。", "ITEM_EQUIPPED": "先把它卸下來才能賣。",
}

var shell = null
var tab := "ALL"
var selected_key := ""
var quantity := 1
var header_label: Label
var notice_label: Label
var rows_box: VBoxContainer
var tab_buttons: Dictionary = {}
# key -> the list row button that selects it
var row_buttons: Dictionary = {}
var detail_icon: TextureRect
var detail_name: Label
var detail_text: Label
var detail_numbers: Label
var qty_label: Label
var minus_button: Button
var plus_button: Button
var buy_button: Button
var sell_button: Button

func _init() -> void:
	theme_type_variation = "PdaDialog"
	title = "交易"
	ok_button_text = "離開市場"
	wrap_controls = false
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

func open(p_shell) -> void:
	shell = p_shell
	_build()
	refresh()
	var viewport: Vector2 = shell.get_viewport_rect().size
	popup_centered(Vector2i(mini(1100, int(viewport.x * 0.9)), int(viewport.y * 0.86)))

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", Tokens.GAP)
	add_child(root)
	header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", Tokens.SECTION)
	root.add_child(header_label)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	root.add_child(tabs)
	var group := ButtonGroup.new()
	for t in TABS:
		var b := Button.new()
		b.text = String(t.label)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = String(t.id) == tab
		b.custom_minimum_size = Vector2(96, Tokens.COMMAND_HEIGHT)
		b.theme_type_variation = "PdaCommand"
		var tab_id := String(t.id)
		b.pressed.connect(func():
			tab = tab_id
			refresh())
		tabs.add_child(b)
		tab_buttons[tab_id] = b
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", Tokens.PAD)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.1
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	rows_box = VBoxContainer.new()
	rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_box.add_theme_constant_override("separation", 4)
	scroll.add_child(rows_box)
	body.add_child(_build_detail())

func _build_detail() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "PdaPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", Tokens.GAP)
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", Tokens.PAD)
	box.add_child(top)
	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(88, 88)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(detail_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(names)
	detail_name = Label.new()
	detail_name.add_theme_font_size_override("font_size", Tokens.TITLE)
	names.add_child(detail_name)
	detail_numbers = Label.new()
	detail_numbers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# An autowrapped label with no width asks for a very tall minimum height.
	detail_numbers.custom_minimum_size.x = 260
	detail_numbers.add_theme_color_override("font_color", Tokens.SECONDARY)
	names.add_child(detail_numbers)
	detail_text = Label.new()
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.custom_minimum_size.x = 360
	detail_text.add_theme_color_override("font_color", Tokens.SECONDARY)
	box.add_child(detail_text)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	notice_label = Label.new()
	notice_label.add_theme_color_override("font_color", Tokens.AMBER)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.custom_minimum_size.x = 360
	notice_label.visible = false
	box.add_child(notice_label)
	var stepper := HBoxContainer.new()
	stepper.add_theme_constant_override("separation", Tokens.GAP)
	stepper.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(stepper)
	minus_button = _big("－", func(): _step(-1), Vector2(56, 48))
	stepper.add_child(minus_button)
	qty_label = Label.new()
	qty_label.custom_minimum_size = Vector2(80, 48)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qty_label.add_theme_font_size_override("font_size", Tokens.TITLE)
	stepper.add_child(qty_label)
	plus_button = _big("＋", func(): _step(1), Vector2(56, 48))
	stepper.add_child(plus_button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", Tokens.GAP)
	box.add_child(actions)
	buy_button = _big("買入", func(): _act(true), Vector2(0, 52))
	buy_button.theme_type_variation = "PdaPrimary"
	buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(buy_button)
	sell_button = _big("賣出", func(): _act(false), Vector2(0, 52))
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(sell_button)
	return panel

func _big(text: String, act: Callable, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.theme_type_variation = "PdaCommand"
	b.add_theme_font_size_override("font_size", Tokens.SECTION)
	b.pressed.connect(act)
	return b

# Everything this town trades with this player, as one list.
func entries() -> Array:
	var proj: Dictionary = shell.current_projection
	var town: Dictionary = proj.get("current_settlement", {})
	var player: Dictionary = proj.get("player", {})
	var pack: Dictionary = player.get("backpack", {})
	var out: Array = []
	for c in COMMODITIES:
		var key := String(c.key)
		out.append({
			"key": key, "name": String(c.name), "item": false, "tab": "SUPPLY", "text": String(c.text),
			"stock": int(town.get(key, 0)), "owned": int(pack.get(key, 0)),
			"buy": int(town.get("quote_buy_" + key, 0)), "sell": int(town.get("quote_sell_" + key, 0)),
			"sold_here": true, "wanted": false, "stackable": true,
		})
	for offer in town.get("item_market", []):
		var sold_here := String(offer.get("supply", "none")) != "none"
		var wanted := bool(offer.get("wanted", false))
		if not sold_here and int(offer.get("owned", 0)) <= 0:
			continue
		var resolved := ItemRegistry.resolve(String(offer.item_id))
		out.append({
			"key": String(offer.item_id), "name": String(offer.display_name_zh), "item": true,
			"tab": String(CATEGORY_TAB.get(String(offer.category), "TOOL")),
			"text": String(resolved.definition.description_zh) if resolved.success else "",
			"stock": int(offer.stock), "owned": int(offer.owned),
			"buy": int(offer.quote_buy) if sold_here else 0, "sell": int(offer.quote_sell),
			"sold_here": sold_here, "wanted": wanted,
			"stackable": resolved.success and bool(resolved.definition.get("stackable", false)),
		})
	return out

func visible_entries() -> Array:
	var out: Array = []
	for e in entries():
		if tab == "ALL" or (tab == "OWNED" and int(e.owned) > 0) or String(e.tab) == tab:
			out.append(e)
	return out

func entry(key: String) -> Dictionary:
	for e in entries():
		if String(e.key) == key:
			return e
	return {}

func refresh() -> void:
	if shell == null or header_label == null:
		return
	var proj: Dictionary = shell.current_projection
	var player: Dictionary = proj.get("player", {})
	var pack: Dictionary = player.get("backpack", {})
	var here := String(player.get("current_container_id", ""))
	var town_name: String = shell._short_town(shell._get_settlement_name(here)) if here != "" else ""
	var trust: Dictionary = proj.get("trust", {}).get(here, {})
	header_label.text = "%s　·　瓶蓋 %d　·　背包 %d / %d%s" % [
		town_name, int(player.get("money", 0)), int(pack.get("load", 0)), int(pack.get("capacity", 0)),
		("　·　" + String(trust.get("name", ""))) if not trust.is_empty() else ""]
	for child in rows_box.get_children():
		child.queue_free()
	row_buttons.clear()
	var shown := visible_entries()
	if shown.is_empty():
		var none := Label.new()
		none.text = "這一類這裡沒有東西可以買賣。"
		none.theme_type_variation = "PdaMuted"
		rows_box.add_child(none)
	var keys: Array = []
	for e in shown:
		keys.append(String(e.key))
	if not keys.has(selected_key):
		selected_key = String(keys[0]) if not keys.is_empty() else ""
		quantity = 1
	for e in shown:
		rows_box.add_child(_list_row(e))
	_render_detail()

func _list_row(e: Dictionary) -> Button:
	var row := Button.new()
	row.toggle_mode = true
	row.button_pressed = String(e.key) == selected_key
	row.custom_minimum_size = Vector2(0, 46)
	row.theme_type_variation = "PdaCommand"
	var key := String(e.key)
	row.pressed.connect(func(): select(key))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", Tokens.GAP)
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 8
	line.offset_right = -10
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var icon := TextureRect.new()
	icon.texture = ItemIcon.texture_for(key)
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(icon)
	var name_label := Label.new()
	name_label.text = String(e.name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(name_label)
	var tag := Label.new()
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bool(e.wanted):
		tag.text = "正缺"
		tag.add_theme_color_override("font_color", Tokens.CRITICAL)
	elif int(e.owned) > 0:
		tag.text = "你有 %d" % int(e.owned)
		tag.add_theme_color_override("font_color", Color("#79B8FF"))
	line.add_child(tag)
	var price := Label.new()
	price.text = ("$%d" % int(e.buy)) if int(e.buy) > 0 and not bool(e.wanted) else "—"
	price.custom_minimum_size.x = 56
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price.add_theme_color_override("font_color", Tokens.AMBER)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(price)
	row_buttons[key] = row
	return row

func select(key: String) -> void:
	if key != selected_key:
		quantity = 1
		notice_label.visible = false
	selected_key = key
	for k in row_buttons:
		row_buttons[k].button_pressed = k == key
	_render_detail()

func _max_buy(e: Dictionary) -> int:
	if e.is_empty() or bool(e.wanted) or not bool(e.sold_here) or int(e.buy) <= 0:
		return 0
	var money := int(shell.current_projection.get("player", {}).get("money", 0))
	var most := mini(int(e.stock), int(money / int(e.buy)))
	return most if bool(e.stackable) or not bool(e.item) else mini(most, 1)

func _step(delta: int) -> void:
	var e := entry(selected_key)
	var cap := maxi(1, maxi(_max_buy(e), int(e.get("owned", 0))))
	quantity = clampi(quantity + delta, 1, cap)
	_render_detail()

func _render_detail() -> void:
	var e := entry(selected_key)
	var has := not e.is_empty()
	detail_icon.texture = ItemIcon.texture_for(selected_key) if has else null
	detail_name.text = String(e.get("name", ""))
	detail_text.text = String(e.get("text", ""))
	if has and bool(e.wanted):
		detail_text.text += "\n這裡正缺這個——所以才發委託收購。去別的鎮買，或自己找。"
	if has:
		detail_numbers.text = "店內 %s　·　你有 %d　·　買入 %s　·　賣出 %s" % [
			str(int(e.stock)) if bool(e.sold_here) else "—", int(e.owned),
			("$%d" % int(e.buy)) if int(e.buy) > 0 and not bool(e.wanted) else "—",
			("$%d" % int(e.sell)) if int(e.sell) > 0 else "—"]
	else:
		detail_numbers.text = ""
	var max_buy := _max_buy(e)
	var owned := int(e.get("owned", 0))
	quantity = clampi(quantity, 1, maxi(1, maxi(max_buy, owned)))
	qty_label.text = str(quantity)
	var multi: bool = has and (not bool(e.item) or bool(e.stackable))
	minus_button.disabled = not multi or quantity <= 1
	plus_button.disabled = not multi or quantity >= maxi(max_buy, owned)
	buy_button.text = "買入 %d（$%d）" % [quantity, quantity * int(e.get("buy", 0))] if has and int(e.get("buy", 0)) > 0 and not bool(e.get("wanted", false)) else "買入"
	buy_button.disabled = not has or quantity > max_buy
	sell_button.text = "賣出 %d（$%d）" % [quantity, quantity * int(e.get("sell", 0))] if has and int(e.get("sell", 0)) > 0 else "賣出"
	sell_button.disabled = not has or owned < quantity or int(e.get("sell", 0)) <= 0

func _act(buying: bool) -> void:
	var e := entry(selected_key)
	if e.is_empty():
		return
	_trade(selected_key, bool(e.item), buying, quantity)

func _trade(key: String, is_item: bool, buying: bool, amount: int) -> void:
	var result: Dictionary
	if is_item:
		result = shell.on_buy_item_pressed(key, amount) if buying else shell.on_sell_item_pressed(key, amount)
	else:
		result = shell.on_buy_pressed(key, amount) if buying else shell.on_sell_pressed(key, amount)
	refresh()
	if bool(result.get("success", false)):
		notice_label.text = ("買入" if buying else "賣出") + " %s ×%d。" % [String(entry(key).get("name", key)), amount]
		if shell.market_practice_label != null and shell.market_practice_label.visible:
			notice_label.text += "　" + shell.market_practice_label.text
		notice_label.visible = true
		return
	var error := String(result.get("error", ""))
	var why := ""
	for code in REFUSALS:
		if error.begins_with(code):
			why = String(REFUSALS[code])
	if why == "":
		why = "沒有成交：" + error.get_slice(":", 0)
	notice_label.text = why
	notice_label.visible = true
