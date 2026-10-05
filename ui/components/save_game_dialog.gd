extends AcceptDialog

signal save_requested
signal load_requested
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const UiProjection = preload("res://ui/player_ui_projection.gd")
var summary: Label
var message: Label
var save_button: Button
var load_button: Button
var confirmation: ConfirmationDialog
var opening: bool = false

func setup(is_opening: bool, stored: Dictionary) -> void:
	opening = is_opening
	theme_type_variation = "PdaDialog"
	title = "荒原編年史" if opening else "存檔／讀檔"
	ok_button_text = "開始新旅程" if opening else "返回遊戲"
	wrap_controls = false
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", Tokens.PAD)
	add_child(body)
	label_in(body, "繼續你的荒原旅程" if opening else "保留這段旅程", "PdaTitle")
	summary = label_in(body, "", "PdaSection")
	label_in(body, "一個手動存檔欄位。開始新旅程會保留原存檔，按下存檔才會覆寫。", "PdaMuted")
	label_in(body, "旅途、戰鬥回合與尚未確認的結果都會保留。離開遊戲前請手動存檔。", "PdaMuted")
	message = label_in(body, "")
	var commands: HBoxContainer = HBoxContainer.new()
	commands.add_theme_constant_override("separation", Tokens.GAP)
	body.add_child(commands)
	if not opening:
		save_button = button_in(commands, "存檔")
		save_button.pressed.connect(func() -> void: save_requested.emit())
	load_button = button_in(commands, "繼續遊戲" if opening else "讀檔")
	load_button.pressed.connect(func() -> void: load_requested.emit())
	update_slot(stored)

func label_in(parent: Node, text: String, variant: String = "") -> Label:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func button_in(parent: Node, text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.theme_type_variation = "PdaCommand"
	button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	return button

static func describe(world: WorldState) -> String:
	var projected: Dictionary = UiProjection.project(world, false)
	var player: Dictionary = projected.player
	var state: String = "旅途中" if player.get("is_in_transit", false) else "停留中"
	var relay: bool = SimulationEngine.Relay.state(world).active
	var exploration: Dictionary = SimulationEngine.Dungeon.current_checkpoint(world)
	if exploration.active:
		var continuation: String = "讀檔後從房間入口繼續。"
		var capture: Dictionary = SimulationEngine.RelayCustody.state(world)
		if capture.active:
			continuation = "制伏灰鴉中 · 第%d回合 · 目標%d生命 · %s" % [capture.turn, capture.target_hp, "已繳械" if capture.disarmed else "持刀"]
		elif capture.receipt >= 0:
			continuation = "制伏結果待確認 · 讀檔後查看結果。"
		elif not world.field_state.battle.is_empty():
			continuation = "戰鬥中 · 第 %d 回合 · 讀檔後繼續交戰。" % int(world.field_state.battle.turn)
		elif world.field_state.receipt >= 0:
			continuation = "戰鬥結果待確認 · 讀檔後查看結果。"
		var rooms: Dictionary = SimulationEngine.Relay.ROOMS if relay else SimulationEngine.Dungeon.ROOMS
		return "%s · 第 %d 天\n%s · %s\n%s" % [player.name, world.current_day, "舊中繼站" if relay else "封存地下水廠", rooms[exploration.room_id], continuation]
	if not world.field_state.battle.is_empty():
		state = "戰鬥中 · 第 %d 回合" % int(world.field_state.battle.turn)
	elif world.field_state.receipt >= 0 or world.pending_encounter_result >= 0:
		state = "結果待確認"
	if not projected.get("death", {}).is_empty():
		state = "旅程已結束"
	return "%s · 第 %d 天\n%s · %s" % [player.name, world.current_day, player.get("location_display", "荒原"), state]

func update_slot(stored: Dictionary) -> void:
	load_button.disabled = not stored.success
	if stored.success:
		summary.text = ("已復原先前存檔\n" if stored.get("recovered", false) else "已存旅程\n") + describe(stored.world)
	else:
		var errors: Dictionary = {"EMPTY": "尚無存檔。先開始新旅程，再手動存檔。", "INVALID": "存檔內容不完整，無法繼續。你仍可開始新旅程。", "UNREADABLE": "無法讀取存檔。請確認存檔資料夾可讀取後再試。"}
		summary.text = String(errors.get(stored.error, "無法讀取存檔，請稍後再試。"))

func show_load_confirmation(stored: Dictionary, action: Callable) -> void:
	if is_instance_valid(confirmation):
		return
	confirmation = ConfirmationDialog.new()
	confirmation.theme_type_variation = "PdaDialog"
	confirmation.title = "回到已存旅程？"
	confirmation.dialog_text = describe(stored.world) + "\n\n讀檔會取代目前未儲存的進度。"
	confirmation.ok_button_text = "確認讀檔"
	confirmation.cancel_button_text = "保留目前進度"
	add_child(confirmation)
	confirmation.confirmed.connect(action)
	confirmation.confirmed.connect(confirmation.queue_free)
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.popup_centered(Vector2i(520, 240))
	confirmation.get_cancel_button().grab_focus()
