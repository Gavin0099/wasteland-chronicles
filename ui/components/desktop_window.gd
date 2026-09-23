class_name DesktopWindow
extends PanelContainer

signal close_requested

var body: VBoxContainer
var title_label: Label
var close_button: Button
var title_bar: PanelContainer
var draggable := false
var dragging := false

func _init(title_text: String = "") -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#202126")
	frame.border_color = Color("#B8B6AF")
	frame.set_border_width_all(2)
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
	title_style.bg_color = Color("#496AA8")
	title_style.content_margin_left = 8
	title_style.content_margin_right = 8
	title_style.content_margin_top = 4
	title_style.content_margin_bottom = 4
	title_bar.add_theme_stylebox_override("panel", title_style)
	column.add_child(title_bar)
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_PASS
	title_bar.add_child(title_row)
	title_label = Label.new()
	title_label.text = title_text
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 14)
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
	button.custom_minimum_size.y = 40
	button.add_theme_color_override("font_color", Color("#20242C"))
	button.add_theme_color_override("font_hover_color", Color("#111820"))
	button.add_theme_color_override("font_pressed_color", Color("#111820"))
	button.add_theme_color_override("font_disabled_color", Color("#767878"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#D1D0C9")
	normal.border_color = Color("#60646B")
	normal.set_border_width_all(1)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#F1EFE7")
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("#B5B9C5")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color("#AAA9A3")
	button.add_theme_stylebox_override("disabled", disabled)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.draw_center = false
	focus.border_color = Color("#2E4D90")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button
