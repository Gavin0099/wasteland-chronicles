extends Control

signal world_changed
signal save_menu_requested
signal closed
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Relay = preload("res://simulation/relay_exploration.gd")
const Target = preload("res://simulation/relay_target.gd")
const Capture = preload("res://simulation/relay_custody.gd")
const PowerDialog = preload("res://ui/components/relay_power_dialog.gd")
const Field = preload("res://simulation/field_adventure.gd")
const RoomView = preload("res://ui/components/relay_room_view.gd")
const Supplies = preload("res://ui/components/dungeon_supplies_dialog.gd")
const HINTS: Dictionary = {
	"relay_entrance": "居民說軍用背包還在地下保管室。正門走廊有野犬；牆邊拖痕可能藏著側道。可隨時沿樓梯回灰谷準備。",
	"relay_corridor": "野犬守住檔案室的門。迎戰後必須確認戰果；也可返回入口尋找維修道。",
	"relay_tunnel": "內門鏽死了：持有扳手或撬棍，再花2廢料撬開。開過便可往返；工具不消耗。",
	"relay_records": "兩條路在此匯合。檢查值勤文件可找到這座保管室的門禁卡；卡片會保存在旅途紀錄。",
	"relay_vault": "軍用背包重2.4kg，裝備後物資容量32；道具仍另計12kg。取走前需要道具空間；回灰谷可在人物頁裝備。"
}
var world: WorldState
var engine: SimulationEngine
var view: Control
var title_label: Label
var status_label: Label
var message: Label
var route_choice: OptionButton
var interact_button: Button
var guide_button: Button
var combat_screen: Control
var capture_screen: Control
var disposition_dialog: AcceptDialog
var supplies_dialog: AcceptDialog
var map_dialog: AcceptDialog
var power_dialog: AcceptDialog

static func explain(error: String) -> String:
	if error.begins_with("PURSUIT_"): return preload("res://ui/relay_capture_screen.gd").explain(error)
	if error.begins_with("TARGET_"): return preload("res://ui/components/relay_target_dialog.gd").explain(error)
	if error.begins_with("POWER_"): return PowerDialog.explain(error)
	return {"": "", "RELAY_FIND_TUNNEL": "先在入口查看拖痕", "RELAY_DOG_BLOCKS_ROUTE": "先排除走廊野犬並確認戰果", "RELAY_OPEN_TUNNEL": "先用工具與2廢料撬開內門", "RELAY_FIND_CARD": "先檢查檔案室的值勤文件", "RELAY_NEED_TOOL": "缺扳手或撬棍；可回灰谷買工具", "RELAY_NEED_SCRAP": "需要2廢料", "ITEM_CAPACITY_EXCEEDED": "道具空間不足；先回城整理再來取", "RELAY_PRIZE_ALREADY_OWNED": "已持有軍用背包；先回城整理", "RELAY_ACTIVITY_PENDING": "先完成並確認目前的戰鬥或遭遇", "RELAY_REQUIRES_GRAY_VALLEY": "請先到灰谷", "RELAY_PLAYER_DEAD": "這段旅程已結束"}.get(error, "目前無法執行；請確認位置與所需物資")

func button(row: HBoxContainer, caption: String, callback: Callable) -> Button:
	var b: Button = Button.new()
	b.text = caption
	b.theme_type_variation = "PdaCommand"
	b.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	b.pressed.connect(callback)
	row.add_child(b)
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
	margin.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	title_label = Label.new()
	title_label.theme_type_variation = "PdaSection"
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(title_label)
	var reduce: CheckButton = CheckButton.new()
	reduce.text = "減少動態"
	reduce.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	reduce.toggled.connect(func(value: bool) -> void: view.reduced_motion = value)
	row.add_child(reduce)
	button(row, "探索地圖 · M", show_map)
	button(row, "背包 · B", show_supplies)
	button(row, "存讀檔", func() -> void: save_menu_requested.emit())
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.theme_type_variation = "PdaMuted"
	column.add_child(status_label)
	view = RoomView.new()
	column.add_child(view)
	view.interaction_changed.connect(refresh_interaction)
	view.interaction_requested.connect(interact)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	var commands: HBoxContainer = HBoxContainer.new()
	column.add_child(commands)
	route_choice = OptionButton.new()
	route_choice.theme_type_variation = "PdaCommand"
	route_choice.custom_minimum_size = Vector2(240, 40)
	commands.add_child(route_choice)
	guide_button = button(commands, "走到所選位置", guide)
	guide_button.size_flags_horizontal = SIZE_EXPAND_FILL
	interact_button = button(commands, "靠近後互動 · E", interact)
	interact_button.theme_type_variation = "PdaPrimary"
	interact_button.size_flags_horizontal = SIZE_EXPAND_FILL
	var instructions: Label = Label.new()
	instructions.theme_type_variation = "PdaMuted"
	instructions.text = "點地面／WASD／方向鍵 · 靠近後 E／Enter · M 地圖 · B 背包 · Esc 存讀檔"
	column.add_child(instructions)
	refresh_room()
	if Field.is_dungeon_activity(world): open_combat()
	elif Capture.pending(world): open_capture()

func refresh_room() -> void:
	var s: Dictionary = Relay.state(world)
	if not s.active: return
	title_label.text = "舊中繼站 / " + Relay.ROOMS[s.room_id]
	status_label.text = "生命%d/12 · %s · 水%d／食物%d · 再換房%d次過一天%s" % [world.player.field_kit.hp, Supplies.load_text(world.player), world.player.inventory.water, world.player.inventory.food, 4 - int(s.work_units), " · 持有保管室門禁卡" if s.card_found else ""]
	s["target"] = Target.state(world)
	s["target_present"] = Target.present_at_relay(world)
	s["capture"] = Capture.state(world)
	s["held"] = Capture.held_target(world) != &""
	view.setup(s)
	route_choice.clear()
	for door: Dictionary in view.doors: route_choice.add_item(door.label)
	message.text = HINTS[s.room_id]
	if s.room_id == "relay_tunnel": message.text += " 供電盤可接管砲塔或啟動貨梯；兩者需擇一。"
	if s.room_id == "relay_entrance" and s.tunnel_found: message.text = "牆邊的維修道已找到。正門野犬仍在時，可帶工具與2廢料走側道；南側樓梯回灰谷。"
	if s.room_id == "relay_vault" and s.prize_taken: message.text = "保管室已取空；原路返回。裝備軍用背包後，可準備帶更多物資的旅程。"
	if s.target.accepted and s.room_id == "relay_records":
		message.text = "灰鴉在此；先堵維修出口可當面問話。直接露面，他會從商路逃往新希望。" if s.target_present and not s.target.interviewed and not s.target.escaped else Target.describe(world)
		if s.capture.captured or s.capture.killed: message.text = Capture.describe(world)
		elif s.target.interviewed: message.text = "你已當面問過灰鴉，尚未拘捕。可再靠近制伏；需要另一條繩索，封出口那條已消耗。"
		elif s.target.escaped: message.text = "灰鴉已從維修出口逃上商路。回灰谷可回報，或追到新希望當面確認。"
	refresh_interaction()
	view.grab_focus()

func intent_for(door: Dictionary) -> PlayerIntent:
	var payload: Dictionary = {"command": door.command, "site_id": Relay.SITE}
	if door.command == "MOVE":
		payload.from_room_id = Relay.state(world).room_id
		payload.room_id = door.room_id
	return PlayerIntent.create_dungeon_action(world.player.npc_id, payload)

func refresh_interaction() -> void:
	if not is_instance_valid(interact_button): return
	var door: Dictionary = view.nearest_door()
	interact_button.disabled = door.is_empty() or not view.enabled
	interact_button.text = "靠近所選位置後互動 · E"
	if door.is_empty(): return
	var error: String = "" if door.command == "INSPECT_CAPTIVE" else engine.authorize_player_intent(world, intent_for(door))
	interact_button.disabled = error != "" or not view.enabled
	interact_button.text = door.label + (" · " + explain(error) if error != "" else " · E")
	interact_button.tooltip_text = explain(error)

func guide() -> void:
	if view.enabled and route_choice.selected >= 0: view.guide_to(view.doors[route_choice.selected])

func interact() -> void:
	if not view.enabled: return
	var door: Dictionary = view.nearest_door()
	if door.is_empty(): return
	if door.command == "INSPECT_CAPTIVE": show_disposition(); return
	var result: Dictionary = engine.commit_player_intent(world, intent_for(door))
	if not result.success:
		message.text = explain(result.error)
		return
	world_changed.emit()
	if not Relay.state(world).active:
		closed.emit()
		queue_free()
	elif door.command == "FIGHT": open_combat()
	elif door.command == "CHALLENGE_TARGET": open_capture()
	elif door.command == "INSPECT_POWER":
		refresh_room()
		show_power()
	else: refresh_room()

func show_disposition() -> void:
	if is_instance_valid(disposition_dialog): return
	set_paused(true)
	disposition_dialog = preload("res://ui/components/relay_disposition_dialog.gd").new()
	add_child(disposition_dialog)
	disposition_dialog.setup(world, engine)
	disposition_dialog.world_changed.connect(func() -> void: world_changed.emit(); refresh_room(); set_paused(true))
	disposition_dialog.confirmed.connect(close_disposition)
	disposition_dialog.canceled.connect(close_disposition)
	disposition_dialog.popup_centered(Vector2i(735, 525))
	disposition_dialog.get_ok_button().grab_focus()

func close_disposition() -> void:
	disposition_dialog.queue_free(); disposition_dialog = null
	set_paused(false); refresh_room()

func show_power() -> void:
	if is_instance_valid(power_dialog): return
	set_paused(true)
	power_dialog = PowerDialog.new()
	add_child(power_dialog)
	power_dialog.setup(world, engine)
	power_dialog.world_changed.connect(func() -> void: world_changed.emit(); refresh_room(); set_paused(true))
	power_dialog.confirmed.connect(close_power)
	power_dialog.canceled.connect(close_power)
	power_dialog.popup_centered(Vector2i(720, 520))
	power_dialog.get_ok_button().grab_focus()

func close_power() -> void:
	power_dialog.queue_free()
	power_dialog = null
	set_paused(false)
	refresh_room()

func open_combat() -> void:
	if is_instance_valid(combat_screen): return
	set_paused(true)
	combat_screen = preload("res://ui/field_screen.gd").new()
	combat_screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(combat_screen)
	combat_screen.setup(world, engine)
	combat_screen.world_changed.connect(func() -> void: world_changed.emit())
	combat_screen.save_menu_requested.connect(func() -> void: save_menu_requested.emit())
	combat_screen.closed.connect(func() -> void:
		combat_screen = null
		if Relay.state(world).active:
			set_paused(false)
			refresh_room()
		else:
			closed.emit()
			queue_free())

func open_capture() -> void:
	if is_instance_valid(capture_screen): return
	set_paused(true)
	capture_screen = preload("res://ui/relay_capture_screen.gd").new()
	capture_screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(capture_screen)
	capture_screen.setup(world, engine)
	capture_screen.world_changed.connect(func() -> void: world_changed.emit())
	capture_screen.save_menu_requested.connect(func() -> void: save_menu_requested.emit())
	capture_screen.closed.connect(func() -> void:
		capture_screen = null
		if Relay.state(world).active:
			set_paused(false); refresh_room()
		else:
			closed.emit(); queue_free())

func show_supplies() -> void:
	if is_instance_valid(combat_screen) or is_instance_valid(capture_screen) or is_instance_valid(supplies_dialog) or is_instance_valid(map_dialog) or is_instance_valid(power_dialog) or is_instance_valid(disposition_dialog): return
	set_paused(true)
	supplies_dialog = Supplies.new()
	add_child(supplies_dialog)
	supplies_dialog.setup(world, engine)
	supplies_dialog.world_changed.connect(func() -> void: world_changed.emit(); refresh_room(); set_paused(true))
	supplies_dialog.confirmed.connect(close_supplies)
	supplies_dialog.canceled.connect(close_supplies)
	supplies_dialog.popup_centered(Vector2i(740, 510))
	supplies_dialog.get_ok_button().grab_focus()

func close_supplies() -> void:
	supplies_dialog.queue_free()
	supplies_dialog = null
	set_paused(false)
	refresh_room()

func show_map() -> void:
	if is_instance_valid(combat_screen) or is_instance_valid(capture_screen) or is_instance_valid(supplies_dialog) or is_instance_valid(map_dialog) or is_instance_valid(power_dialog) or is_instance_valid(disposition_dialog): return
	var s: Dictionary = Relay.state(world)
	var lines: PackedStringArray = ["記錄已走過的房間與眼前通路；地圖不會移動角色。"]
	for room: String in s.visited:
		lines.append("● " + Relay.ROOMS[room] + (" · 目前位置" if room == s.room_id else ""))
	for door: Dictionary in view.doors:
		if door.command == "MOVE" and door.room_id not in s.visited: lines.append("→ " + door.label + (" · " + explain(door.get("refusal", "")) if door.get("refusal", "") != "" else " · 尚未探索"))
	set_paused(true)
	map_dialog = AcceptDialog.new()
	map_dialog.title = "中繼站探索紀錄"
	map_dialog.theme_type_variation = "PdaMapDialog"
	map_dialog.dialog_text = "\n".join(lines)
	map_dialog.ok_button_text = "返回探索"
	add_child(map_dialog)
	map_dialog.confirmed.connect(close_map)
	map_dialog.canceled.connect(close_map)
	map_dialog.popup_centered(Vector2i(640, 360))
	map_dialog.get_ok_button().grab_focus()

func close_map() -> void:
	map_dialog.queue_free()
	map_dialog = null
	set_paused(false)

func set_paused(value: bool) -> void:
	view.enabled = not value and not is_instance_valid(combat_screen) and not is_instance_valid(capture_screen) and not is_instance_valid(supplies_dialog) and not is_instance_valid(map_dialog) and not is_instance_valid(power_dialog) and not is_instance_valid(disposition_dialog)
	if view.enabled: view.grab_focus()
	refresh_interaction()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo: return
	if is_instance_valid(combat_screen) or is_instance_valid(capture_screen) or is_instance_valid(supplies_dialog) or is_instance_valid(map_dialog) or is_instance_valid(power_dialog) or is_instance_valid(disposition_dialog): return
	match event.keycode:
		KEY_M: show_map()
		KEY_B: show_supplies()
		KEY_ESCAPE: save_menu_requested.emit()
		_: return
	get_viewport().set_input_as_handled()
