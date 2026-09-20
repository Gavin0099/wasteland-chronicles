class_name StatusBadge
extends PanelContainer

# ==============================================================================
# SURVIVOR PDA STATUS BADGE
# ==============================================================================
# Renders compact status badges ([LIVE], [REMOTE], [IN TRANSIT], [CRITICAL])
# strictly adhering to wc-survivor-pda-design-system token rules.
# ==============================================================================

enum Variant {
	LIVE,
	REMOTE,
	IN_TRANSIT,
	LOW,
	WARNING,
	CRITICAL,
	DISABLED
}

var label: Label

func _init(text: String = "", variant: Variant = Variant.REMOTE) -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	set_badge(text, variant)

func set_badge(text: String, variant: Variant) -> void:
	label.text = text

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(2)
	style.set_border_width_all(1)
	style.content_margin_left = 6
	style.content_margin_top = 2
	style.content_margin_right = 6
	style.content_margin_bottom = 2

	match variant:
		Variant.LIVE:
			style.bg_color = Color("#18261E")
			style.border_color = Color("#39D353")
			label.add_theme_color_override("font_color", Color("#39D353"))
		Variant.REMOTE:
			style.bg_color = Color("#181A1F")
			style.border_color = Color("#454A55")
			label.add_theme_color_override("font_color", Color("#96938B"))
		Variant.IN_TRANSIT:
			style.bg_color = Color("#172333")
			style.border_color = Color("#58A6FF")
			label.add_theme_color_override("font_color", Color("#58A6FF"))
		Variant.WARNING, Variant.LOW:
			style.bg_color = Color("#2B2117")
			style.border_color = Color("#D9822B")
			label.add_theme_color_override("font_color", Color("#D9822B"))
		Variant.CRITICAL:
			style.bg_color = Color("#2D1616")
			style.border_color = Color("#A8382B")
			label.add_theme_color_override("font_color", Color("#E05252"))
		Variant.DISABLED:
			style.bg_color = Color("#141518")
			style.border_color = Color("#2A2D35")
			label.add_theme_color_override("font_color", Color("#686A70"))

	add_theme_stylebox_override("panel", style)
