extends Control

signal world_changed
signal save_menu_requested
signal closed

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const RoomView = preload("res://ui/components/dungeon_room_view.gd")
const MapView = preload("res://ui/components/dungeon_map_view.gd")
const Layout = preload("res://ui/components/dungeon_room_layout.gd")
const Field = preload("res://simulation/field_adventure.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
var combat_screen: Control
var world: WorldState
var engine: SimulationEngine
var view: Control
var title_label: Label
var message: Label
var interact_button: Button
var guide_button: Button
var reduce_motion: CheckButton
var route_choice: OptionButton
var map_button: Button
var map_dialog: AcceptDialog
var maintenance_actions: HBoxContainer
var maintenance_buttons: Dictionary = {}

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	var background: Panel = Panel.new()
	background.theme_type_variation = "PdaPanel"
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, Tokens.PAD)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	margin.add_child(column)
	var toolbar: HBoxContainer = HBoxContainer.new()
	column.add_child(toolbar)
	title_label = Label.new()
	title_label.theme_type_variation = "PdaSection"
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	toolbar.add_child(title_label)
	reduce_motion = CheckButton.new()
	reduce_motion.text = "減少動態"
	reduce_motion.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	reduce_motion.toggled.connect(func(value: bool) -> void: view.reduced_motion = value)
	toolbar.add_child(reduce_motion)
	map_button = Button.new()
	map_button.text = "探索地圖 · M"
	map_button.theme_type_variation = "PdaCommand"
	map_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	map_button.pressed.connect(_show_map)
	toolbar.add_child(map_button)
	var save_button: Button = Button.new()
	save_button.text = "存讀檔"
	save_button.theme_type_variation = "PdaCommand"
	save_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	save_button.pressed.connect(func() -> void: save_menu_requested.emit())
	toolbar.add_child(save_button)
	view = RoomView.new()
	column.add_child(view)
	view.interaction_changed.connect(refresh_interaction)
	view.interaction_requested.connect(interact)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.theme_type_variation = "PdaMuted"
	column.add_child(message)
	maintenance_actions = HBoxContainer.new()
	maintenance_actions.add_theme_constant_override("separation", Tokens.GAP)
	column.add_child(maintenance_actions)
	var commands: HBoxContainer = HBoxContainer.new()
	column.add_child(commands)
	route_choice = OptionButton.new()
	route_choice.theme_type_variation = "PdaCommand"
	route_choice.custom_minimum_size = Vector2(220, Tokens.COMMAND_HEIGHT)
	commands.add_child(route_choice)
	route_choice.item_selected.connect(func(_index: int) -> void: _refresh_guide_label())
	guide_button = Button.new()
	guide_button.theme_type_variation = "PdaCommand"
	guide_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	guide_button.size_flags_horizontal = SIZE_EXPAND_FILL
	guide_button.pressed.connect(_guide)
	commands.add_child(guide_button)
	interact_button = Button.new()
	interact_button.theme_type_variation = "PdaPrimary"
	interact_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	interact_button.size_flags_horizontal = SIZE_EXPAND_FILL
	interact_button.pressed.connect(interact)
	commands.add_child(interact_button)
	var instructions: Label = Label.new()
	instructions.text = "點地面／WASD／方向鍵　·　靠近門後 E／Enter　·　M 探索地圖　·　Esc 存讀檔"
	instructions.theme_type_variation = "PdaMuted"
	column.add_child(instructions)
	refresh_room()
	if Field.is_dungeon_activity(world):
		_open_combat()

func refresh_room() -> void:
	var checkpoint: Dictionary = Dungeon.state(world)
	if not checkpoint.active:
		return
	title_label.text = "封存地下水廠 / " + String(Dungeon.ROOMS[checkpoint.room_id])
	var enemy: String = "" if checkpoint.room_id in checkpoint.cleared else String(Dungeon.ROOM_ENEMIES.get(checkpoint.room_id, ""))
	checkpoint.enemy = enemy
	view.setup(checkpoint)
	route_choice.clear()
	for door: Dictionary in view.doors:
		route_choice.add_item(door.label)
	_refresh_guide_label()
	message.text = Layout.HINTS[checkpoint.room_id]
	if checkpoint.shortcut_open and checkpoint.room_id in ["control", "entrance"]:
		message.text = "返回門已開啟，入口與控制室可以直接往返。"
	if not enemy.is_empty():
		message.text += "　·　" + Field.Enemies.display_name(enemy) + "仍在這裡；靠近後可選擇迎戰。"
	elif checkpoint.room_id in checkpoint.cleared:
		message.text += "　·　威脅已排除，戰利品已結算。"
	_refresh_maintenance(checkpoint)
	if checkpoint.room_id == "guard" and checkpoint.route_rules == 1 and checkpoint.room_id not in checkpoint.cleared:
		message.text += "　·　北門由劫匪看守；可迎戰，或返回前廳走維修廊。"
	if checkpoint.maintenance_open and checkpoint.room_id in ["maintenance", "pump"]:
		message.text += "　·　維修門已開啟（%s · 已付 %d 廢料）。" % [method_name(checkpoint.maintenance_method), Dungeon.MAINTENANCE_COSTS[checkpoint.maintenance_method]]
	if not is_instance_valid(combat_screen): view.grab_focus()
	refresh_interaction()

func refresh_interaction() -> void:
	if interact_button == null:
		return
	var door: Dictionary = view.nearest_door()
	interact_button.disabled = door.is_empty() or not view.enabled or door.get("refusal", "") != ""
	interact_button.text = "靠近出口以互動" if door.is_empty() else door.label + " · E / Enter"
	interact_button.tooltip_text = refusal_text(door.get("refusal", ""))
	var near_gate: bool = not door.is_empty() and door.get("room_id", "") == "pump" and door.command == "MOVE"
	for method: String in maintenance_buttons:
		var button: Button = maintenance_buttons[method]
		var refusal: String = button.get_meta("refusal")
		button.disabled = not view.enabled or not near_gate or refusal != ""
		button.tooltip_text = refusal_text(refusal) if refusal != "" else ("靠近北側維修門後使用。" if not near_gate else "開門後可從維修廊往返泵房。")

func method_name(method: String) -> String:
	return {"SKILL": "機械熟練", "TOOL": "工具開門", "ABBAN": "阿扳協助"}.get(method, "維修門")

func refusal_text(refusal: String) -> String:
	return {"": "", "DUNGEON_GUARD_BLOCKS_ROUTE": "先排除警衛，或返回前廳走維修廊。", "DUNGEON_MAINTENANCE_CLOSED": "維修門尚未開啟，請在維修廊選擇開門方式。", "DUNGEON_NEED_MECHANICS_2": "需要自己的機械技能 ≥2。", "DUNGEON_NEED_TOOL": "需要撬棍或扳手。", "DUNGEON_NEED_ABBAN": "需要阿扳同行。", "DUNGEON_NEED_SCRAP": "背包中的廢料不足。"}.get(refusal, "目前條件已改變，請重新選擇可用行動。")

func _refresh_maintenance(checkpoint: Dictionary) -> void:
	for child: Node in maintenance_actions.get_children():
		maintenance_actions.remove_child(child)
		child.queue_free()
	maintenance_buttons.clear()
	maintenance_actions.visible = checkpoint.room_id == "maintenance" and checkpoint.route_rules == 1 and not checkpoint.maintenance_open
	if not maintenance_actions.visible: return
	message.text += "　·　北側維修門需要開啟；先走近門，再選擇方式。"
	for method: String in ["SKILL", "TOOL", "ABBAN"]:
		var button: Button = Button.new()
		button.theme_type_variation = "PdaCommand"
		button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		var refusal: String = Dungeon.maintenance_requirement(world, method)
		button.text = "%s · 廢料 −%d" % [method_name(method), Dungeon.MAINTENANCE_COSTS[method]]
		button.text += "\n" + ("機械 ≥2" if method == "SKILL" else ("撬棍／扳手" if method == "TOOL" else "阿扳同行"))
		if refusal != "": button.text += " · " + refusal_text(refusal)
		button.set_meta("refusal", refusal)
		button.pressed.connect(open_maintenance.bind(method))
		maintenance_actions.add_child(button)
		maintenance_buttons[method] = button

func open_maintenance(method: String) -> void:
	var door: Dictionary = view.nearest_door()
	if not view.enabled or door.is_empty() or door.get("room_id", "") != "pump" or door.command != "MOVE": return
	var actor_position: Vector2 = view.actor_position
	var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "OPEN_MAINTENANCE", "method": method}))
	if not result.success:
		message.text = refusal_text(result.error)
		return
	world_changed.emit()
	refresh_room()
	if view.walkable(actor_position): view.actor_position = actor_position
	view.queue_redraw()
	refresh_interaction()

func _guide() -> void:
	if route_choice.selected >= 0:
		view.guide_to(view.doors[route_choice.selected])

func _refresh_guide_label() -> void:
	guide_button.text = "走向選取的互動點"
	guide_button.tooltip_text = "經過房間中間的通道，走到「%s」附近。" % route_choice.get_item_text(route_choice.selected) if route_choice.selected >= 0 else ""

func _show_map() -> void:
	if not view.enabled or is_instance_valid(map_dialog): return
	map_dialog = AcceptDialog.new()
	map_dialog.theme_type_variation = "PdaMapDialog"
	map_dialog.title = "封存地下水廠 · 探索地圖"
	map_dialog.ok_button_text = "返回探索"
	map_dialog.wrap_controls = true
	add_child(map_dialog)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", Tokens.GAP)
	map_dialog.add_child(column)
	var legend: Label = Label.new()
	legend.text = "● 目前房間 · 未探索：門外房間 · 橙線：捷徑 · 紅線：門未開"
	legend.theme_type_variation = "PdaMuted"
	column.add_child(legend)
	var map_view: Control = MapView.new()
	column.add_child(map_view)
	map_view.setup(Dungeon.state(world))
	map_dialog.confirmed.connect(_close_map)
	map_dialog.canceled.connect(_close_map)
	set_paused(true)
	map_dialog.popup_centered(Vector2i(720, 440))
	map_dialog.get_ok_button().grab_focus()

func _close_map() -> void:
	map_dialog.hide()
	map_dialog.queue_free()
	map_dialog = null
	set_paused(false)

func interact() -> void:
	if not view.enabled:
		return
	var door: Dictionary = view.nearest_door()
	if door.is_empty():
		return
	var payload: Dictionary = {"command": door.command}
	if door.command == "FIGHT":
		payload.room_id = view.room_id
	elif door.command == "MOVE":
		payload.from_room_id = view.room_id
		payload.room_id = door.room_id
	var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload))
	if not result.success:
		message.text = refusal_text(result.error)
		return
	world_changed.emit()
	if Field.is_dungeon_activity(world):
		_open_combat()
		return
	if not Dungeon.state(world).active:
		view.enabled = false
		closed.emit()
		queue_free()
	else:
		refresh_room()

func _open_combat() -> void:
	if is_instance_valid(combat_screen): return
	combat_screen = FieldScreen.new()
	combat_screen.name = "DungeonCombat"
	combat_screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(combat_screen)
	combat_screen.world_changed.connect(func() -> void: world_changed.emit())
	combat_screen.save_menu_requested.connect(func() -> void: save_menu_requested.emit())
	combat_screen.closed.connect(func() -> void: call_deferred("_resume_exploration"))
	combat_screen.setup(world, engine)
	set_paused(true)
	view.release_focus()

func _resume_exploration() -> void:
	combat_screen = null
	if not Dungeon.state(world).active:
		closed.emit()
		queue_free()
		return
	refresh_room()
	set_paused(false)

func set_paused(value: bool) -> void:
	value = value or is_instance_valid(combat_screen)
	view.enabled = not value
	view.target_position = Vector2(-1, -1)
	view.guide_path.clear()
	guide_button.disabled = value
	route_choice.disabled = value
	map_button.disabled = value
	refresh_interaction()
	if not value and view.is_inside_tree():
		view.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not view.enabled:
		return
	if event.keycode == KEY_ESCAPE:
		save_menu_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_M:
		_show_map()
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_E, KEY_ENTER] and view.has_focus():
		interact()
		get_viewport().set_input_as_handled()
