class_name MarketRowView
extends PanelContainer

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")

# ==============================================================================
# SURVIVOR PDA MARKET ROW VIEW
# ==============================================================================
# Renders a table row in the marketplace:
# [Icon + Name] | [Stock] | [Buy $] | [Sell $] | [Trend] | [You: Qty] | [BUY] [SELL]
# ==============================================================================

signal buy_requested(commodity: String)
signal sell_requested(commodity: String)

var commodity_key: String = ""
var lbl_name: Label
var lbl_stock: Label
var lbl_buy: Label
var lbl_sell: Label
var lbl_trend: Label
var lbl_player_qty: Label
var btn_buy: Button
var btn_sell: Button

func _init(p_key: String = "water", p_display_name: String = "WATER") -> void:
	commodity_key = p_key
	size_flags_horizontal = SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Tokens.PANEL
	style.border_color = Tokens.BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 10
	style.content_margin_top = 5
	style.content_margin_right = 10
	style.content_margin_bottom = 5
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	add_child(hbox)

	# Name + Icon
	var identity := HBoxContainer.new()
	identity.custom_minimum_size = Vector2(105, 0)
	identity.add_theme_constant_override("separation", Tokens.GAP)
	hbox.add_child(identity)
	identity.add_child(ItemIcon.new(p_key, 32))
	lbl_name = Label.new()
	lbl_name.text = p_display_name
	lbl_name.add_theme_color_override("font_color", Tokens.TEXT)
	identity.add_child(lbl_name)

	# Stock
	lbl_stock = Label.new()
	lbl_stock.text = "庫存: 0"
	lbl_stock.custom_minimum_size = Vector2(65, 0)
	lbl_stock.add_theme_color_override("font_color", Color("#8B949E"))
	hbox.add_child(lbl_stock)

	# Buy Price + Trend
	lbl_buy = Label.new()
	lbl_buy.text = "買入 $0"
	lbl_buy.custom_minimum_size = Vector2(65, 0)
	lbl_buy.add_theme_color_override("font_color", Color("#D9822B"))
	hbox.add_child(lbl_buy)

	# Sell Price
	lbl_sell = Label.new()
	lbl_sell.text = "賣出 $0"
	lbl_sell.custom_minimum_size = Vector2(65, 0)
	lbl_sell.add_theme_color_override("font_color", Color("#D8D3C8"))
	hbox.add_child(lbl_sell)

	# Trend Indicator
	lbl_trend = Label.new()
	lbl_trend.text = "—"
	lbl_trend.custom_minimum_size = Vector2(25, 0)
	lbl_trend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_trend.add_theme_color_override("font_color", Color("#8B949E"))
	hbox.add_child(lbl_trend)

	# Player Qty
	lbl_player_qty = Label.new()
	lbl_player_qty.text = "你有: 0"
	lbl_player_qty.custom_minimum_size = Vector2(65, 0)
	lbl_player_qty.add_theme_color_override("font_color", Color("#58A6FF"))
	hbox.add_child(lbl_player_qty)

	# Action Buttons
	btn_buy = Button.new()
	btn_buy.text = "[ 買入 1 ]"
	btn_buy.pressed.connect(func(): buy_requested.emit(commodity_key))
	hbox.add_child(btn_buy)

	btn_sell = Button.new()
	btn_sell.text = "[ 賣出 1 ]"
	btn_sell.pressed.connect(func(): sell_requested.emit(commodity_key))
	hbox.add_child(btn_sell)

func update_row(stock: int, buy_price: float, sell_price: float, player_qty: int, trend_str: String = "—", buy_allowed: bool = true, sell_allowed: bool = true) -> void:
	if lbl_stock != null:
		lbl_stock.text = "庫存: %d" % stock
	if lbl_buy != null:
		lbl_buy.text = "買入 $%d" % int(round(buy_price))
	if lbl_sell != null:
		lbl_sell.text = "賣出 $%d" % int(round(sell_price))
	if lbl_player_qty != null:
		lbl_player_qty.text = "你有: %d" % player_qty

	if lbl_trend != null:
		lbl_trend.text = trend_str
		if trend_str == "▲" or trend_str == "↑":
			lbl_trend.add_theme_color_override("font_color", Color("#E05252")) # price up
		elif trend_str == "▼" or trend_str == "↓":
			lbl_trend.add_theme_color_override("font_color", Color("#39D353")) # price down
		else:
			lbl_trend.add_theme_color_override("font_color", Color("#96938B"))

	if btn_buy != null:
		btn_buy.disabled = not buy_allowed or stock <= 0
	if btn_sell != null:
		btn_sell.disabled = not sell_allowed or player_qty <= 0
