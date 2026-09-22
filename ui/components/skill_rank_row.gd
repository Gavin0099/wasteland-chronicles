extends HBoxContainer

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Presentation = preload("res://ui/character_presentation.gd")
var skill_id := ""
var rank := 0

func setup(id: String, value: int) -> void:
	skill_id = id
	rank = value
	add_theme_constant_override("separation", Tokens.GAP)
	custom_minimum_size.y = 32
	var title := Label.new()
	title.text = Presentation.SKILL_NAMES[id]
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(title)
	for index in range(5):
		var segment := ColorRect.new()
		segment.color = Tokens.AMBER if index < value else Tokens.BORDER_STRONG
		segment.custom_minimum_size = Vector2(12, 8)
		segment.size_flags_vertical = SIZE_SHRINK_CENTER
		segment.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(segment)
	var description := Label.new()
	description.text = "%d  %s" % [value, Presentation.RANK_NAMES[value]]
	description.custom_minimum_size.x = 80
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(description)
	accessibility_name = "%s %d %s" % [title.text, value, Presentation.RANK_NAMES[value]]
