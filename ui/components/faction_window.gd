extends AcceptDialog

const Tokens = preload("res://ui/theme/pda_tokens.gd")
var scroll: ScrollContainer

func _init() -> void:
	theme_type_variation = "PdaDialog"
	title = "陣營往來"
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

# Only public projection data reaches this view. It has no simulation authority.
func setup(factions: Array) -> void:
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", Tokens.PAD)
	scroll.add_child(list)
	label_in(list, "同盟記得你在成員城鎮的往來。新委託與本鎮優惠取較高值；已接單仍照原約付酬。", "PdaMuted")
	if factions.is_empty():
		label_in(list, "目前沒有已知的陣營城鎮。")
	for faction: Dictionary in factions:
		var card := PanelContainer.new()
		card.theme_type_variation = "PdaPanel"
		list.add_child(card)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", Tokens.GAP)
		card.add_child(body)
		label_in(body, "%s · %s · 往來 %d" % [faction.name, faction.standing, faction.score], "PdaSection")
		label_in(body, String(faction.purpose), "PdaMuted")
		label_in(body, "同盟新委託 +%d%% · 購買加價 +%d%% · %s" % [faction.pay_bonus, faction.buy_markup, "委託、教學與雇用照常" if faction.services_open else "暫停新委託、教學與雇用"])
		for member: Dictionary in faction.members:
			label_in(body, "%s：本鎮往來 %d · 新委託 +%d%% · 購買 +%d%% · %s" % [member.name, member.score, member.pay_bonus, member.buy_markup, "服務開放" if member.services_open else "服務暫停"], "PdaMuted")
	label_in(list, "往來規則", "PdaSection")
	label_in(list, "履約 +2；回報地點 +3；私吞貨物 -10；託運未送達 -5。背約與棄單在 20 天後留下 -3／-2 的紀錄。", "PdaMuted")
	label_in(list, "同盟往來達 4／10：新委託 +5%／+10%；-10 以下抵制：新委託、教學與雇用暫停，購買加價 15%。本鎮的 10%／20% 報酬與 25% 加價仍取較高值。旅行、買賣和已接委託交件照常。", "PdaMuted")
