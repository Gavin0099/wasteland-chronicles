class_name ResourceChip
extends PanelContainer

# ==============================================================================
# SURVIVOR PDA RESOURCE CHIP
# ==============================================================================
# Renders a survival resource card (Icon + Quantity + Label)
# according to wc-survivor-pda-design-system specifications.
# ==============================================================================

var lbl_icon: Label
var lbl_name: Label
var lbl_val: Label

func _init(icon_str: String = "💧", name_str: String = "WATER", initial_val: int = 0) -> void:
	custom_minimum_size = Vector2(80, 56)
	size_flags_horizontal = SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#181A1F")
	style.border_color = Color("#2A2D35")
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

	lbl_icon = Label.new()
	lbl_icon.text = icon_str
	lbl_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_icon.add_theme_font_size_override("font_size", 20)
	hbox.add_child(lbl_icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	lbl_name = Label.new()
	lbl_name.text = name_str
	lbl_name.add_theme_color_override("font_color", Color("#96938B"))
	lbl_name.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_name)

	lbl_val = Label.new()
	lbl_val.text = str(initial_val)
	lbl_val.add_theme_color_override("font_color", Color("#D8D3C8"))
	lbl_val.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl_val)

func set_value(val: int) -> void:
	if lbl_val != null:
		lbl_val.text = str(val)
