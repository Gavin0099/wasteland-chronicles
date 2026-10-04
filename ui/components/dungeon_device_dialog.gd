extends AcceptDialog

signal choice_requested(choice: String)
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const Icon = preload("res://ui/components/item_icon.gd")
var choice_buttons: Dictionary = {}
var detail: Label

static func explain(refusal: String) -> String:
	return {"DUNGEON_DEVICE_ALREADY_DECIDED": "去留已決定，不能再次取得改甲或廢料", "DUNGEON_NEED_CARGO_SPACE": "須空出4物資容量", "DUNGEON_NEED_ABBAN": "需要阿扳同行", "DUNGEON_NEED_DEVICE_SCRAP": "需要3廢料", "DUNGEON_NEED_LEATHER_JACKET": "需要持有1件普通皮甲", "UNIQUE_ITEM_DUPLICATE": "已持有強化皮甲，先處理這一件", "ITEM_CAPACITY_EXCEEDED": "道具容量不足，須多空出500g"}.get(refusal, "目前無法在這裡決定")

func setup(world: WorldState) -> void:
	title = "控制室 · 修復台的去留"
	theme_type_variation = "PdaMapDialog"
	ok_button_text = "暫不決定 · 返回探索"
	wrap_controls = true
	get_ok_button().custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = 620
	column.add_theme_constant_override("separation", Tokens.GAP)
	add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	row.add_child(Icon.make(Dungeon.DEVICE_REWARD, 64))
	detail = Label.new()
	detail.custom_minimum_size.x = 530
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.text = "阿扳想保留修復台。協助修復：皮甲1400g → 強化皮甲1900g，防護1 → 2；穿著的皮甲會保持穿著。拆解：帶走4廢料。這是一次決定，離開後仍會保留。"
	var checkpoint: Dictionary = Dungeon.state(world)
	if checkpoint.device_choice != "": detail.text = Dungeon.device_note(world)
	row.add_child(detail)
	for choice: String in ["PRESERVE", "SALVAGE"]:
		var button: Button = Button.new()
		button.theme_type_variation = "PdaCommand"
		button.custom_minimum_size.y = 72
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = "保留設備並改甲 · 阿扳同行／皮甲1件／廢料−3／道具重量+500g" if choice == "PRESERVE" else "拆解設備 · 廢料+4／須空出4物資容量／永久失去改甲機會"
		var refusal: String = Dungeon.device_requirement(world, choice)
		button.disabled = refusal != ""
		button.set_meta("refusal", refusal)
		button.tooltip_text = explain(refusal) if refusal != "" else ""
		if refusal != "": button.text += "\n" + explain(refusal)
		button.pressed.connect(func() -> void: choice_requested.emit(choice))
		column.add_child(button)
		choice_buttons[choice] = button
