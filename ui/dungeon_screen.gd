extends Control

signal world_changed
signal save_menu_requested
signal closed

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const RoomView = preload("res://ui/components/dungeon_room_view.gd")
var world: WorldState
var engine: SimulationEngine
var view: Control
var title_label: Label
var message: Label
var interact_button: Button
var guide_button: Button
var reduce_motion: CheckButton

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
	var commands: HBoxContainer = HBoxContainer.new()
	column.add_child(commands)
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
	instructions.text = "點地面移動／WASD／方向鍵　·　靠近出口後按 E 或 Enter　·　Esc 開啟存讀檔"
	instructions.theme_type_variation = "PdaMuted"
	column.add_child(instructions)
	refresh_room()

func refresh_room() -> void:
	var checkpoint: Dictionary = Dungeon.state(world)
	if not checkpoint.active:
		return
	title_label.text = "封存地下水廠 / " + String(Dungeon.ROOMS[checkpoint.room_id])
	guide_button.text = "走向設備前廳" if checkpoint.room_id == "entrance" else "走回入口"
	message.text = "樓梯仍通往灰谷；穿過北側門可查看設備前廳。" if checkpoint.room_id == "entrance" else "廢棄水泵占據兩側。返回入口的樓梯在南側。"
	view.setup(checkpoint)
	view.grab_focus()
	refresh_interaction()

func refresh_interaction() -> void:
	if interact_button == null:
		return
	var door: Dictionary = view.nearest_door()
	interact_button.disabled = door.is_empty() or not view.enabled
	interact_button.text = "靠近出口以互動" if door.is_empty() else door.label + " · E / Enter"

func _guide() -> void:
	view.walk_to(Vector2(500, 132) if view.room_id == "entrance" else Vector2(500, 395))

func interact() -> void:
	if not view.enabled:
		return
	var door: Dictionary = view.nearest_door()
	if door.is_empty():
		return
	var payload: Dictionary = {"command": door.command}
	if door.command == "MOVE":
		payload.from_room_id = view.room_id
		payload.room_id = door.room_id
	var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload))
	if not result.success:
		message.text = "目前無法通過出口。請存檔後重新讀取，或從可用樓梯返回。"
		return
	world_changed.emit()
	if not Dungeon.state(world).active:
		view.enabled = false
		closed.emit()
		queue_free()
	else:
		refresh_room()

func set_paused(value: bool) -> void:
	view.enabled = not value
	view.target_position = Vector2(-1, -1)
	guide_button.disabled = value
	refresh_interaction()
	if not value and view.is_inside_tree():
		view.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not view.enabled:
		return
	if event.keycode == KEY_ESCAPE:
		save_menu_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_E, KEY_ENTER] and view.has_focus():
		interact()
		get_viewport().set_input_as_handled()
