class_name ResourceChip
extends PanelContainer

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")

# ==============================================================================
# SURVIVOR PDA RESOURCE CHIP
# ==============================================================================
# Renders a survival resource card (Icon + Quantity + Label)
# according to wc-survivor-pda-design-system specifications.
# ==============================================================================

var item_icon: TextureRect
var lbl_name: Label
var lbl_val: Label

func _init(item_id: String = "water", name_str: String = "WATER", initial_val: int = 0) -> void:
	custom_minimum_size = Vector2(80, 56)
	size_flags_horizontal = SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Tokens.PANEL
	style.border_color = Tokens.BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8
	style.content_margin_top = 4
	style.content_margin_right = 8
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)

	item_icon = ItemIcon.new(item_id, 32)
	hbox.add_child(item_icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	lbl_name = Label.new()
	lbl_name.text = name_str
	lbl_name.add_theme_color_override("font_color", Tokens.SECONDARY)
	lbl_name.add_theme_font_size_override("font_size", Tokens.SMALL)
	vbox.add_child(lbl_name)

	lbl_val = Label.new()
	lbl_val.text = str(initial_val)
	lbl_val.add_theme_color_override("font_color", Tokens.TEXT)
	lbl_val.add_theme_font_size_override("font_size", Tokens.BODY)
	vbox.add_child(lbl_val)

func set_value(val: int) -> void:
	if lbl_val != null:
		lbl_val.text = str(val)
