extends SceneTree

const Tokens = preload("res://ui/theme/pda_tokens.gd")

# ==============================================================================
# SURVIVOR PDA THEME BUILDER
# ==============================================================================
# Generates res://ui/theme/survivor_pda_theme.tres conforming strictly to the
# wc-survivor-pda-design-system design tokens.
# ==============================================================================

func _init() -> void:
	var theme := Theme.new()

	# --- Color Tokens ---
	var c_base := Tokens.BASE        # surface/base
	var c_panel := Tokens.PANEL       # surface/panel
	var c_elevated := Tokens.ELEVATED    # surface/elevated
	var c_border := Tokens.BORDER      # border/default
	var c_border_strong := Tokens.BORDER_STRONG # border/strong
	var c_border_amber := Tokens.AMBER # border/accent (amber)

	var c_text_primary := Tokens.TEXT # dirty ivory
	var c_text_secondary := Tokens.SECONDARY # metadata
	var c_text_dim := Tokens.DIM     # dim
	var c_accent_amber := Tokens.AMBER # primary interactive highlight
	var c_critical_red := Tokens.CRITICAL # status/critical
	var c_live_green := Tokens.LIVE   # status/live

	# --- PanelContainer ---
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = c_panel
	panel_style.border_color = c_border
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(2)
	panel_style.content_margin_left = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_bottom = 8
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# --- Button Styles ---
	# Normal
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color("#181A1F")
	btn_normal.border_color = c_border
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(2)
	btn_normal.content_margin_left = 10
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_right = 10
	btn_normal.content_margin_bottom = 6
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_color("font_color", "Button", c_text_primary)

	# Hover
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = c_elevated
	btn_hover.border_color = c_border_amber
	btn_hover.set_border_width_all(1)
	btn_hover.set_corner_radius_all(2)
	btn_hover.content_margin_left = 10
	btn_hover.content_margin_top = 6
	btn_hover.content_margin_right = 10
	btn_hover.content_margin_bottom = 6
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_color("font_hover_color", "Button", c_accent_amber)

	# Pressed
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = c_base
	btn_pressed.border_color = c_border_amber
	btn_pressed.set_border_width_all(1)
	btn_pressed.set_corner_radius_all(2)
	btn_pressed.content_margin_left = 10
	btn_pressed.content_margin_top = 6
	btn_pressed.content_margin_right = 10
	btn_pressed.content_margin_bottom = 6
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_color("font_pressed_color", "Button", c_accent_amber)

	# Disabled
	var btn_disabled := StyleBoxFlat.new()
	btn_disabled.bg_color = Color("#141518")
	btn_disabled.border_color = Color("#1F2228")
	btn_disabled.set_border_width_all(1)
	btn_disabled.set_corner_radius_all(2)
	btn_disabled.content_margin_left = 10
	btn_disabled.content_margin_top = 6
	btn_disabled.content_margin_right = 10
	btn_disabled.content_margin_bottom = 6
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_disabled_color", "Button", Color("#555960"))

	# Focus
	var btn_focus := StyleBoxFlat.new()
	btn_focus.draw_center = false
	btn_focus.border_color = c_border_amber
	btn_focus.set_border_width_all(1)
	btn_focus.set_corner_radius_all(2)
	theme.set_stylebox("focus", "Button", btn_focus)

	# --- Label ---
	theme.set_color("font_color", "Label", c_text_primary)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))

	# --- ProgressBar ---
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color("#141518")
	pb_bg.border_color = c_border
	pb_bg.set_border_width_all(1)
	pb_bg.set_corner_radius_all(1)
	theme.set_stylebox("background", "ProgressBar", pb_bg)

	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = c_accent_amber
	pb_fill.set_corner_radius_all(1)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	# Shared semantic variants used by new screens; legacy base controls stay stable.
	for variant in ["PdaTitle", "PdaSection", "PdaMuted"]:
		theme.set_type_variation(variant, "Label")
	theme.set_font_size("font_size", "PdaTitle", Tokens.TITLE)
	theme.set_font_size("font_size", "PdaSection", Tokens.SECTION)
	theme.set_color("font_color", "PdaSection", Tokens.AMBER)
	theme.set_font_size("font_size", "PdaMuted", Tokens.SMALL)
	theme.set_color("font_color", "PdaMuted", Tokens.SECONDARY)
	theme.set_type_variation("PdaPanel", "PanelContainer")
	var padded: StyleBoxFlat = panel_style.duplicate()
	padded.content_margin_left = Tokens.PAD
	padded.content_margin_right = Tokens.PAD
	padded.content_margin_top = Tokens.PAD
	padded.content_margin_bottom = Tokens.PAD
	theme.set_stylebox("panel", "PdaPanel", padded)
	theme.set_type_variation("PdaPrimary", "Button")
	var primary: StyleBoxFlat = btn_normal.duplicate()
	primary.border_color = Tokens.AMBER
	theme.set_stylebox("normal", "PdaPrimary", primary)
	theme.set_type_variation("PdaDialog", "AcceptDialog")
	var frame: StyleBoxFlat = padded.duplicate()
	frame.border_color = Tokens.BORDER_STRONG
	frame.expand_margin_top = 32
	theme.set_stylebox("panel", "PdaDialog", frame)
	theme.set_stylebox("embedded_border", "PdaDialog", frame)

	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute("res://ui/theme")
	var err := ResourceSaver.save(theme, "res://ui/theme/survivor_pda_theme.tres")
	if err == OK:
		print("SUCCESS: survivor_pda_theme.tres generated cleanly!")
		quit(0)
	else:
		print("FAIL: Error saving survivor_pda_theme.tres: %d" % err)
		quit(1)
