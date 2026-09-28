extends AcceptDialog

# ==============================================================================
# RUMOR WINDOW — 傳聞
# ==============================================================================
# ASP-2's rumours used to sit at the top of the character sheet. Hand-play:
# "在這邊做提示感覺有點怪" - what you have heard in the towns is not part of who
# you are. In Lunatic Dawn it is what the inn tells you. So it has its own
# window, opened from the tools row: what you have heard, what still stands
# between you and it, and which one you are chasing.
# ==============================================================================

const Tokens = preload("res://ui/theme/pda_tokens.gd")

var rumor_buttons: Dictionary = {}

func _init() -> void:
	theme_type_variation = "PdaDialog"
	title = "傳聞"
	ok_button_text = "收起"
	wrap_controls = false
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

func label_in(parent: Node, text: String, variant: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

# rumors: Rumors.project(world); on_chase(rumor_id) - "" lets the aim go.
func setup(rumors: Array, on_chase: Callable) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", Tokens.PAD)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	label_in(list, "在城鎮裡聽來的事。只有世界上真的存在的東西，才會出現在這裡；要追哪一個，由你決定。", "PdaMuted")
	if rumors.is_empty():
		label_in(list, "你還沒聽說什麼值得專程去找的事。多走幾個城鎮吧。")
	for rumor in rumors:
		var card := PanelContainer.new()
		card.theme_type_variation = "PdaPanel"
		list.add_child(card)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", Tokens.GAP)
		card.add_child(body)
		var head := HBoxContainer.new()
		body.add_child(head)
		var name_label := label_in(head, String(rumor.title), "PdaSection")
		name_label.add_theme_color_override("font_color", Tokens.AMBER if bool(rumor.tracked) else (Tokens.DIM if bool(rumor.done) else Tokens.TEXT))
		var state := Label.new()
		state.text = "已了結" if bool(rumor.done) else ("◆ 追尋中" if bool(rumor.tracked) else "")
		state.add_theme_color_override("font_color", Tokens.AMBER if bool(rumor.tracked) else Tokens.DIM)
		head.add_child(state)
		label_in(body, "「%s」" % String(rumor.text), "PdaMuted")
		label_in(body, "→ " + String(rumor.next))
		if not bool(rumor.done) and on_chase.is_valid():
			var chase := Button.new()
			var rumor_id := String(rumor.id)
			chase.text = "不追了" if bool(rumor.tracked) else "追這個"
			chase.theme_type_variation = "PdaCommand"
			chase.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
			chase.pressed.connect(func(): on_chase.call("" if bool(rumor.tracked) else rumor_id))
			body.add_child(chase)
			rumor_buttons[rumor_id] = chase
