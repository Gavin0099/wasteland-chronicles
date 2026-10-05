extends Control

signal world_changed
signal save_menu_requested
signal closed
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Mine = preload("res://simulation/mine_exploration.gd")
const RoomView = preload("res://ui/components/mine_room_view.gd")
const Supplies = preload("res://ui/components/dungeon_supplies_dialog.gd")
const HOME_TOWN: StringName = &"settlement:gray_valley"
const HINTS: Dictionary = {
	"mine_entrance": "舊礦道的入口：軌道伸進黑暗，右側的落石堆擋掉半邊路。往裡走一趟、看清楚、再回來，要花一天的水糧。隨時可以沿原路離開。",
	"mine_gallery": "外段坑道：頂板靠幾根木支柱撐著，有的已經裂開。路仍通到後面的集水廳。",
	"mine_pumphall": "舊集水廳：泵體與管路都在，只是沒有動靜。更深處的通道被塌方整個封住，現在過不去。",
}
const OBSERVATIONS: Dictionary = {
	"cracked_supports": {"room": "mine_gallery", "label": "查看 裂開的支柱", "tag": "外段坑道", "text": "外段頂板靠幾根裂開的支柱撐著，裂縫是從更深處那一段往外爬來的。這一段還能走，但經不起重物壓。"},
	"stalled_pump": {"room": "mine_pumphall", "label": "查看 停擺的泵", "tag": "集水廳 · 泵", "text": "泵體與管路大致完整，只是停擺了：沒有電路在轉，輸水管裡也聽不到水聲。"},
	"controller_missing": {"room": "mine_pumphall", "label": "查看 控制座", "tag": "集水廳 · 控制座", "text": "控制座的插槽空著，接線被整齊地剪開：控制模組被人拆走了，或是丟在塌方裡。設備本體還能修，缺的是控制模組。"},
}
var world: WorldState
var engine: SimulationEngine
var title_label: Label
var status_label: Label
var room_view: Control
var facts_label: Label
var forecast_label: Label
var message: Label
var commands: HFlowContainer
var supplies_dialog: AcceptDialog
var command_buttons: Array[Button] = []

static func explain(error: String) -> String:
	if error.begins_with("DUNGEON_EXPLORATION_PENDING"): return "先離開目前的探索"
	return {"": "", "MINE_REQUIRES_IRON_PASS": "請先抵達鐵關", "MINE_ACTIVITY_PENDING": "先完成並確認目前的戰鬥、遭遇或探索", "MINE_PLAYER_DEAD": "這段旅程已結束",
		"MINE_ALREADY_INSIDE": "你已在礦道裡", "MINE_NOT_INSIDE": "先走進礦道", "MINE_INVALID_PASSAGE": "這裡沒有通往那裡的路", "MINE_EXIT_REQUIRES_ENTRANCE": "先回到礦道入口",
		"MINE_ALREADY_OBSERVED": "已經看過了", "MINE_OBSERVATION_UNAVAILABLE": "這裡看不到", "MINE_OBSERVE_FIRST": "先看看停擺的泵",
		"MINE_INVALID_INTENT": "目前無法這樣做"}.get(error, "目前無法執行；請確認位置與尚未處理的事件")

func button(caption: String, callback: Callable, primary: bool = false) -> Button:
	var b: Button = Button.new()
	b.text = caption
	b.theme_type_variation = "PdaPrimary" if primary else "PdaCommand"
	b.custom_minimum_size = Vector2(0, Tokens.COMMAND_HEIGHT)
	b.pressed.connect(callback)
	return b

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	var panel: Panel = Panel.new()
	panel.theme_type_variation = "PdaPanel"
	panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, Tokens.PAD)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", Tokens.GAP)
	margin.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	column.add_child(row)
	title_label = Label.new()
	title_label.theme_type_variation = "PdaSection"
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(title_label)
	row.add_child(button("背包 · B", show_supplies))
	row.add_child(button("存讀檔", func() -> void: save_menu_requested.emit()))
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.theme_type_variation = "PdaMuted"
	column.add_child(status_label)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Tokens.PAD)
	column.add_child(body)
	room_view = RoomView.new()
	room_view.custom_minimum_size = Vector2(380, 200)
	room_view.size_flags_horizontal = SIZE_EXPAND_FILL
	room_view.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(room_view)
	var side_column: VBoxContainer = VBoxContainer.new()
	side_column.custom_minimum_size.x = 400
	side_column.add_theme_constant_override("separation", Tokens.GAP)
	body.add_child(side_column)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_column.add_child(message)
	facts_label = Label.new()
	facts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts_label.theme_type_variation = "PdaMuted"
	side_column.add_child(facts_label)
	forecast_label = Label.new()
	forecast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_column.add_child(forecast_label)
	commands = HFlowContainer.new()
	commands.add_theme_constant_override("h_separation", Tokens.GAP)
	commands.add_theme_constant_override("v_separation", Tokens.GAP)
	column.add_child(commands)
	var instructions: Label = Label.new()
	instructions.theme_type_variation = "PdaMuted"
	instructions.text = "每走四次換房過一天 · B 背包 · Esc 存讀檔"
	column.add_child(instructions)
	refresh()

func route_days_home() -> int:
	return engine.get_route_days_between(world, Mine.HOME, HOME_TOWN)

func intent_for(command_name: String, arg: String = "") -> PlayerIntent:
	var payload: Dictionary = {"command": command_name, "site_id": Mine.SITE}
	if command_name == "MOVE":
		payload.from_room_id = Mine.state(world).room_id
		payload.room_id = arg
	elif command_name == "OBSERVE": payload.fact_id = arg
	return PlayerIntent.create_dungeon_action(world.player.npc_id, payload)

func add_command(caption: String, command_name: String, arg: String = "", primary: bool = false) -> void:
	var refusal: String = engine.authorize_player_intent(world, intent_for(command_name, arg))
	var b: Button = button(caption + (" · " + explain(refusal) if refusal != "" else ""), func() -> void: perform(command_name, arg), primary)
	b.disabled = refusal != ""
	b.tooltip_text = explain(refusal)
	commands.add_child(b)
	command_buttons.append(b)

func refresh() -> void:
	var s: Dictionary = Mine.state(world)
	if not s.active: return
	title_label.text = "鐵關舊礦道 / " + Mine.ROOMS[s.room_id]
	status_label.text = "生命%d/12 · %s · 水%d／食物%d · 再換房%d次過一天" % [world.player.field_kit.hp, Supplies.load_text(world.player), world.player.inventory.water, world.player.inventory.food, Mine.MOVES_PER_DAY - int(s.work_units)]
	room_view.setup(s.room_id, s.observed)
	message.text = HINTS[s.room_id]
	var lines: PackedStringArray = []
	for fact: String in Mine.FACTS:
		var info: Dictionary = OBSERVATIONS[fact]
		lines.append(("● %s：%s" % [info.tag, info.text]) if fact in s.observed else "○ %s：尚未查看" % info.tag)
	if s.discovered: lines.append("◆ 新目標：找回集水設備的控制模組。礦道更深處被塌方封住，現在去不了。")
	facts_label.text = "\n".join(lines)
	forecast_label.visible = s.room_id == "mine_entrance"
	if forecast_label.visible:
		var forecast: Dictionary = Mine.entrance_forecast(route_days_home(), SimulationEngine.Party.current(world))
		var out: PackedStringArray = ["現在還需要（這一天＋回灰谷）：%d 水、%d 糧　目前攜帶：水%d／食物%d" % [forecast.water, forecast.food, world.player.inventory.water, world.player.inventory.food]]
		out.append("建議額外準備：%d 瓶蓋，或額外 %d 水＋%d 糧。路上事件可能延長行程。" % [forecast.bribe_caps, forecast.extra_day_water, forecast.extra_day_food])
		forecast_label.text = "\n".join(out)
	for child: Node in commands.get_children():
		commands.remove_child(child)
		child.queue_free()
	command_buttons.clear()
	match s.room_id:
		"mine_entrance":
			add_command("前往 外段坑道", "MOVE", "mine_gallery")
			add_command("離開礦道", "EXIT", "", true)
		"mine_gallery":
			add_command(OBSERVATIONS.cracked_supports.label, "OBSERVE", "cracked_supports")
			add_command("前往 舊集水廳", "MOVE", "mine_pumphall", true)
			add_command("返回 礦道入口", "MOVE", "mine_entrance")
		"mine_pumphall":
			add_command(OBSERVATIONS.stalled_pump.label, "OBSERVE", "stalled_pump")
			add_command(OBSERVATIONS.controller_missing.label, "OBSERVE", "controller_missing", true)
			add_command("返回 外段坑道", "MOVE", "mine_gallery")

func perform(command_name: String, arg: String) -> void:
	if is_instance_valid(supplies_dialog): return
	var days: int = world.current_day
	var result: Dictionary = engine.commit_player_intent(world, intent_for(command_name, arg))
	if not result.success:
		message.text = explain(result.error)
		return
	world_changed.emit()
	if not Mine.state(world).active:
		closed.emit()
		queue_free()
		return
	refresh()
	if command_name == "OBSERVE": message.text = OBSERVATIONS[arg].text
	if world.current_day > days: message.text += "　（這次換房讓一天過去了，補給已扣除。）"

func show_supplies() -> void:
	if is_instance_valid(supplies_dialog): return
	supplies_dialog = Supplies.new()
	add_child(supplies_dialog)
	supplies_dialog.setup(world, engine)
	supplies_dialog.world_changed.connect(func() -> void: world_changed.emit(); refresh())
	supplies_dialog.confirmed.connect(close_supplies)
	supplies_dialog.canceled.connect(close_supplies)
	supplies_dialog.popup_centered(Vector2i(740, 510))
	supplies_dialog.get_ok_button().grab_focus()

func close_supplies() -> void:
	supplies_dialog.queue_free()
	supplies_dialog = null
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo or is_instance_valid(supplies_dialog): return
	match event.keycode:
		KEY_B: show_supplies()
		KEY_ESCAPE: save_menu_requested.emit()
		_: return
	get_viewport().set_input_as_handled()
