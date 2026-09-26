class_name DesktopWindow
extends PanelContainer

signal close_requested

var body: VBoxContainer
var title_label: Label
var close_button: Button
var title_bar: PanelContainer
var draggable := false
var dragging := false

const Tokens = preload("res://ui/theme/pda_tokens.gd")

# The window chrome used to hardcode four colours that are in no token table:
# a #496AA8 title bar, a 2px #B8B6AF frame, a near-ELEVATED body and pure white
# title text. Together they read as a pale desktop window pasted over a dark
# industrial PDA, which is the loudest thing on every screen and none of the
# project's own palette. The design contract asks for charcoal panels, thin
# 1px borders and restrained amber, so the chrome uses the tokens now.
func _init(title_text: String = "") -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Tokens.PANEL
	frame.border_color = Tokens.BORDER_STRONG
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(2)
	frame.content_margin_left = 4
	frame.content_margin_right = 4
	frame.content_margin_top = 4
	frame.content_margin_bottom = 4
	add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	title_bar = PanelContainer.new()
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Tokens.ELEVATED
	# One amber hairline under the title carries "this is the active window"
	# without repainting a quarter of the screen to say it.
	title_style.border_color = Tokens.AMBER
	title_style.border_width_bottom = 1
	title_style.content_margin_left = Tokens.GAP
	title_style.content_margin_right = Tokens.GAP
	title_style.content_margin_top = 4
	title_style.content_margin_bottom = 4
	title_bar.add_theme_stylebox_override("panel", title_style)
	column.add_child(title_bar)
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_PASS
	title_bar.add_child(title_row)
	title_label = Label.new()
	title_label.text = title_text
	title_label.add_theme_color_override("font_color", Tokens.AMBER)
	title_label.add_theme_font_size_override("font_size", Tokens.SMALL)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title_label)
	close_button = Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "關閉視窗"
	close_button.custom_minimum_size = Vector2(32, 28)
	close_button.visible = false
	close_button.pressed.connect(func(): close_requested.emit())
	title_row.add_child(close_button)
	title_bar.gui_input.connect(_on_title_input)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(body)

func enable_floating(can_close: bool = true) -> void:
	draggable = true
	close_button.visible = can_close
	title_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE

func _on_title_input(event: InputEvent) -> void:
	if not draggable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		var desired: Vector2 = position + (event as InputEventMouseMotion).relative
		var bounds: Vector2 = (get_parent() as Control).size
		position = Vector2(
			clampf(desired.x, 0.0, maxf(0.0, bounds.x - size.x)),
			clampf(desired.y, 48.0, maxf(48.0, bounds.y - size.y)))

static func toolbar_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	# Same reason as the window chrome: a pale grey toolbar with dark text is a
	# desktop widget, not this game. Tokens, and amber only where it means
	# "this is what you are about to touch".
	button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	button.add_theme_color_override("font_color", Tokens.TEXT)
	button.add_theme_color_override("font_hover_color", Tokens.AMBER)
	button.add_theme_color_override("font_pressed_color", Tokens.AMBER)
	button.add_theme_color_override("font_disabled_color", Tokens.DIM)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Tokens.ELEVATED
	normal.border_color = Tokens.BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Tokens.BORDER
	hover.border_color = Tokens.AMBER
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Tokens.BORDER_STRONG
	pressed.border_color = Tokens.AMBER
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Tokens.PANEL
	disabled.border_color = Tokens.BORDER
	button.add_theme_stylebox_override("disabled", disabled)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.draw_center = false
	focus.border_color = Tokens.AMBER
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button
