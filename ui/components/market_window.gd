extends AcceptDialog

# ==============================================================================
# MARKET WINDOW — the local trade screen
# ==============================================================================
# Hand-play: "UI 還是設計得不好 下方的物品太短 導致很難找東西". The market was a
# panel stacked under other panels in a narrow column, with the item shop
# collapsed into a 150 px strip. Trade screens in other RPGs agree on a few
# things, and this follows them:
#
#   - it takes most of the screen: trading is a task, not a sidebar
#   - money, pack load and how this town treats you are always in view
#   - category tabs, so a weapon is not hunted for among water and rope
#   - one aligned row per thing: stock, what you have, buy, sell, and the
#     actions, in the same columns every time
#   - what this town does not sell does not clutter the list, unless you
#     own one and could sell it
#
# It only ever calls the shell's existing trade handlers, so every rule, price
# and refusal is the engine's.
# ==============================================================================

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")

const COMMODITIES := [
	{"key": "water", "name": "水"},
	{"key": "food", "name": "食物"},
	{"key": "scrap", "name": "廢料"},
	{"key": "fuel", "name": "燃料"},
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

var shell = null
var tab := "ALL"
var header_label: Label
var notice_label: Label
var rows_box: VBoxContainer
var tab_buttons: Dictionary = {}
# key -> {"buy": Button, "buy5": Button, "sell": Button, "sell_all": Button}
var row_buttons: Dictionary = {}

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
	popup_centered(Vector2i(int(viewport.x * 0.86), int(viewport.y * 0.86)))

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", Tokens.GAP)
	add_child(root)
	header_label = Label.new()
	header_label.add_theme_font_size_override("font_size", Tokens.SECTION)
	header_label.add_theme_color_override("font_color", Tokens.TEXT)
	root.add_child(header_label)
	notice_label = Label.new()
	notice_label.add_theme_color_override("font_color", Tokens.AMBER)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_label.visible = false
	root.add_child(notice_label)
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
	root.add_child(_row_shell(null, "", "店內", "你有", "買入", "賣出", true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	rows_box = VBoxContainer.new()
	rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_box.add_theme_constant_override("separation", 2)
	scroll.add_child(rows_box)

# Everything this town trades with this player, as one list.
func entries() -> Array:
	var proj: Dictionary = shell.current_projection
	var town: Dictionary = proj.get("current_settlement", {})
	var player: Dictionary = proj.get("player", {})
	var pack: Dictionary = player.get("backpack", {})
	var money := int(player.get("money", 0))
	var out: Array = []
	for c in COMMODITIES:
		var key := String(c.key)
		var buy := int(town.get("quote_buy_" + key, 0))
		out.append({
			"key": key, "name": String(c.name), "item": false, "tab": "SUPPLY",
			"stock": int(town.get(key, 0)), "owned": int(pack.get(key, 0)),
			"buy": buy, "sell": int(town.get("quote_sell_" + key, 0)),
			"can_buy": money >= buy and int(town.get(key, 0)) > 0,
			"can_buy5": money >= buy * 5 and int(town.get(key, 0)) >= 5,
			"can_sell": int(pack.get(key, 0)) > 0,
		})
	for offer in town.get("item_market", []):
		var sold_here := String(offer.get("supply", "none")) != "none"
		if not sold_here and int(offer.get("owned", 0)) <= 0:
			continue
		out.append({
			"key": String(offer.item_id), "name": String(offer.display_name_zh), "item": true,
			"tab": String(CATEGORY_TAB.get(String(offer.category), "TOOL")),
			"stock": int(offer.stock), "owned": int(offer.owned),
			"buy": int(offer.quote_buy) if sold_here else 0, "sell": int(offer.quote_sell),
			"can_buy": sold_here and bool(offer.can_buy), "can_buy5": false,
			"can_sell": bool(offer.can_sell),
		})
	return out

func visible_entries() -> Array:
	var out: Array = []
	for e in entries():
		if tab == "ALL" or (tab == "OWNED" and int(e.owned) > 0) or String(e.tab) == tab:
			out.append(e)
	return out

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
	notice_label.visible = shell.market_practice_label != null and shell.market_practice_label.visible
	if notice_label.visible:
		notice_label.text = shell.market_practice_label.text
	for child in rows_box.get_children():
		child.queue_free()
	row_buttons.clear()
	var shown := visible_entries()
	if shown.is_empty():
		var none := Label.new()
		none.text = "這一類這裡沒有東西可以買賣。"
		none.theme_type_variation = "PdaMuted"
		rows_box.add_child(none)
	for e in shown:
		rows_box.add_child(_entry_row(e))

func _cell(text: String, width: float, color: Color = Tokens.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = width
	l.add_theme_color_override("font_color", color)
	l.clip_text = true
	return l

func _row_shell(icon_id, name: String, stock: String, owned: String, buy: String, sell: String, header: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	var icon_slot := Control.new()
	icon_slot.custom_minimum_size = Vector2(28, 28)
	if icon_id != null:
		var tex: Texture2D = ItemIcon.texture_for(String(icon_id))
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(28, 28)
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon_slot.add_child(icon)
	row.add_child(icon_slot)
	var muted := Tokens.SECONDARY if header else Tokens.TEXT
	var name_cell := _cell(name, 150, muted)
	name_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_cell)
	row.add_child(_cell(stock, 64, Tokens.SECONDARY))
	row.add_child(_cell(owned, 64, Tokens.SECONDARY if header else Color("#79B8FF")))
	row.add_child(_cell(buy, 70, Tokens.SECONDARY if header else Tokens.AMBER))
	row.add_child(_cell(sell, 70, muted))
	if header:
		row.add_child(_cell("", 4 * 64 + 3 * Tokens.GAP))
	return row

func _entry_row(e: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Tokens.PANEL
	style.border_color = Tokens.BORDER
	style.set_border_width_all(1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	var row := _row_shell(e.key, String(e.name), str(int(e.stock)), str(int(e.owned)),
		("$%d" % int(e.buy)) if int(e.buy) > 0 else "—", ("$%d" % int(e.sell)) if int(e.sell) > 0 else "—")
	panel.add_child(row)
	var key := String(e.key)
	var is_item := bool(e.item)
	var buttons := {}
	buttons["buy"] = _action(row, "買 1", bool(e.can_buy), func(): _trade(key, is_item, true, 1))
	buttons["buy5"] = _action(row, "買 5", bool(e.can_buy5), func(): _trade(key, is_item, true, 5), not is_item)
	buttons["sell"] = _action(row, "賣 1", bool(e.can_sell), func(): _trade(key, is_item, false, 1))
	buttons["sell_all"] = _action(row, "全賣", bool(e.can_sell) and int(e.owned) > 1, func(): _trade(key, is_item, false, int(e.owned)))
	row_buttons[key] = buttons
	return panel

func _action(row: HBoxContainer, label: String, enabled: bool, act: Callable, shown: bool = true) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(64, 32)
	b.theme_type_variation = "PdaCommand"
	b.disabled = not enabled
	b.visible = shown
	b.pressed.connect(act)
	if not shown:
		# Keep the columns aligned where a thing cannot be bought in fives.
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(64, 32)
		row.add_child(spacer)
	row.add_child(b)
	return b

const REFUSALS := {
	"INSUFFICIENT_FUNDS": "瓶蓋不夠。", "INSUFFICIENT_STOCK": "店裡沒那麼多貨。", "INSUFFICIENT_ITEM_STOCK": "店裡沒那麼多貨。",
	"INSUFFICIENT_MARKET_CASH": "店家現在沒錢收你的貨。", "INSUFFICIENT_PLAYER_STOCK": "你身上沒那麼多。",
	"BACKPACK_FULL": "背包裝不下了。", "CAPACITY_EXCEEDED": "背包裝不下了。",
}

func _trade(key: String, is_item: bool, buying: bool, quantity: int) -> void:
	var result: Dictionary
	if is_item:
		result = shell.on_buy_item_pressed(key, quantity) if buying else shell.on_sell_item_pressed(key, quantity)
	else:
		result = shell.on_buy_pressed(key, quantity) if buying else shell.on_sell_pressed(key, quantity)
	refresh()
	if not bool(result.get("success", false)):
		var error := String(result.get("error", ""))
		var why := "沒有成交。"
		for code in REFUSALS:
			if error.begins_with(code):
				why = String(REFUSALS[code])
		notice_label.text = why
		notice_label.visible = true
