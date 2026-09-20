class_name TopStatusBar
extends PanelContainer

# ==============================================================================
# SURVIVOR PDA TOP STATUS BAR
# ==============================================================================
# Displays authoritative global header status:
# DAY %d | IDENTITY %s | MONEY $%d CAPS | BACKPACK %d / %d
# ==============================================================================

var lbl_day: Label
var lbl_identity: Label
var lbl_money: Label
var lbl_backpack: Label

func _init() -> void:
	custom_minimum_size = Vector2(0, 36)
	size_flags_horizontal = SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#181A1F")
	style.border_color = Color("#2A2D35")
	style.set_border_width_all(1)
	style.content_margin_left = 12
	style.content_margin_top = 6
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	add_child(hbox)

	var logo_lbl := Label.new()
	logo_lbl.text = "荒原編年史  WASTELAND CHRONICLES"
	logo_lbl.add_theme_color_override("font_color", Color("#D8D3C8"))
	logo_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(logo_lbl)

	# Separator
	_add_vsep(hbox)

	lbl_day = Label.new()
	lbl_day.text = "DAY 0"
	lbl_day.add_theme_color_override("font_color", Color("#D9822B")) # Amber
	hbox.add_child(lbl_day)

	_add_vsep(hbox)

	lbl_identity = Label.new()
	lbl_identity.text = "身份 VAGRANT"
	lbl_identity.add_theme_color_override("font_color", Color("#D8D3C8"))
	hbox.add_child(lbl_identity)

	_add_vsep(hbox)

	lbl_money = Label.new()
	lbl_money.text = "金錢 $0 CAPS"
	lbl_money.add_theme_color_override("font_color", Color("#D9822B"))
	hbox.add_child(lbl_money)

	_add_vsep(hbox)

	lbl_backpack = Label.new()
	lbl_backpack.text = "背包 0 / 20"
	lbl_backpack.add_theme_color_override("font_color", Color("#D8D3C8"))
	hbox.add_child(lbl_backpack)

	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var slogan := Label.new()
	slogan.text = "仍有路可走..."
	slogan.add_theme_color_override("font_color", Color("#686A70"))
	slogan.add_theme_font_size_override("font_size", 11)
	hbox.add_child(slogan)

func _add_vsep(parent: HBoxContainer) -> void:
	var sep := VSeparator.new()
	sep.add_theme_color_override("separator_color", Color("#2A2D35"))
	parent.add_child(sep)

func update_status(day: int, identity_name: String, money: int, load_val: int, cap_val: int) -> void:
	if lbl_day != null:
		lbl_day.text = "第 %d 天 DAY %d" % [day, day]
	if lbl_identity != null:
		var zh_id := "流浪者"
		if identity_name == "Vagrant" or identity_name == "Drifter":
			zh_id = "流浪者"
		elif identity_name != "":
			zh_id = identity_name
		lbl_identity.text = zh_id
	if lbl_money != null:
		lbl_money.text = "$%d CAPS" % money
	if lbl_backpack != null:
		lbl_backpack.text = "負重 %d / %d" % [load_val, cap_val]
