extends "res://ui/components/relay_target_dialog.gd"

const Disposition = preload("res://simulation/relay_disposition.gd")
var release_confirmation: ConfirmationDialog
var pending_release: PlayerIntent
var captions: Dictionary = {}

static func custody_explain(error: String) -> String:
	return {"": "", "CUSTODY_STALE_EVIDENCE": "沒有可交差的親見紀錄，或紀錄已改變", "CUSTODY_ALREADY_REPORTED": "懸賞已結案，不能再處置或重領", "CUSTODY_ACTIVITY_PENDING": "先結束並確認目前交戰或探索戰果", "CUSTODY_CONFIRM_FIRST": "先確認交戰結果", "CUSTODY_RETURN_GRAY_VALLEY": "從中繼站入口回灰谷交差", "CUSTODY_REQUIRES_RECORDS": "需回值勤檔案室當面處理", "CUSTODY_NOT_YOURS": "沒有仍由你看管的活人", "CUSTODY_NO_DEATH_TO_WITNESS": "沒有尚未檢視、且死亡時仍由你看管的目標", "CUSTODY_NO_DEATH_PROOF": "需親見擊殺，或當面檢視拘留中的死者", "CUSTODY_NO_RELEASE_PROOF": "沒有親自放人的紀錄", "CUSTODY_PLAYER_DEAD": "這段旅程已結束"}.get(error, "目前無法執行，請確認人物與親見紀錄")

func intent(command_id: String) -> PlayerIntent:
	return Disposition.intent(world, command_id) if command_id in Disposition.COMMANDS else super(command_id)

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world; engine = p_engine
	title = "灰鴉 · 看管與懸賞"
	theme_type_variation = "PdaMapDialog"
	ok_button_text = "返回探索" if engine.Relay.state(world).active else "返回城鎮"
	wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(700, 400)
	column.add_theme_constant_override("separation", Tokens.GAP)
	add_child(column)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 190
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = Poses.load_atlas("res://ui/assets/combat/relay-grey-crow.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(120, 220)
	row.add_child(portrait)
	detail = Label.new()
	detail.custom_minimum_size.x = 545
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(detail)
	notice = Label.new()
	notice.custom_minimum_size.x = 700
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(notice)
	var actions: GridContainer = GridContainer.new()
	actions.columns = 2
	column.add_child(actions)
	for entry: Array in [["HAND_OVER_TARGET", "活人移交 · 80瓶蓋／信任＋4"], ["REPORT_TARGET_DEATH", "回報死訊 · 30瓶蓋／信任＋1"], ["RELEASE_TARGET", "放人 · 永久解除看管"], ["WITNESS_CAPTIVE_DEATH", "當面檢視拘留中的死者"], ["REPORT_TARGET_RELEASE", "坦白放人 · 0瓶蓋／信任−3"], ["REPORT_TARGET", "回報親見動向 · 偵查費12"]]:
		var b: Button = Button.new()
		b.text = entry[1]
		b.theme_type_variation = "PdaCommand"
		b.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(perform.bind(String(entry[0])))
		captions[entry[0]] = entry[1]
		actions.add_child(b); action_buttons[entry[0]] = b
	refresh()

func refresh() -> void:
	detail.text = Disposition.describe(world) + "\n\n" + Target.describe(world)
	for command_id: String in action_buttons:
		var error: String = engine.authorize_player_intent(world, intent(command_id))
		action_buttons[command_id].disabled = error != "" or is_instance_valid(release_confirmation)
		var explanation: String = custody_explain(error) if command_id in Disposition.COMMANDS else explain(error)
		action_buttons[command_id].tooltip_text = explanation
		var lock: String = {"CUSTODY_STALE_EVIDENCE": "缺親見紀錄", "CUSTODY_ALREADY_REPORTED": "已結案", "CUSTODY_RETURN_GRAY_VALLEY": "需回灰谷", "CUSTODY_REQUIRES_RECORDS": "需回檔案室", "CUSTODY_NOT_YOURS": "無可看管的活人", "CUSTODY_NO_DEATH_TO_WITNESS": "無可檢視死者", "CUSTODY_NO_DEATH_PROOF": "缺親見死訊", "CUSTODY_NO_RELEASE_PROOF": "尚未放人", "TARGET_REPORT_UNAVAILABLE": "缺紀錄或已領費"}.get(error, "先完成目前行動")
		action_buttons[command_id].text = captions[command_id] + ("\n鎖定 · " + lock if error != "" else "")
	notice.text = "放人／檢視須到檔案室；領賞／坦白須回灰谷。\n僅依你的親見紀錄交差；活人、死訊、放人只能結案一次。"

func perform(command_id: String) -> void:
	if is_instance_valid(release_confirmation): return
	if command_id == "RELEASE_TARGET":
		pending_release = intent(command_id)
		release_confirmation = ConfirmationDialog.new()
		release_confirmation.title = "確定放灰鴉自由？"
		release_confirmation.dialog_text = "解除看管後不能重新活捉，也不退繩索。\n不領賞金；可回灰谷自願坦白，地方信任−3。"
		release_confirmation.ok_button_text = "放人"
		release_confirmation.cancel_button_text = "繼續看管"
		release_confirmation.theme_type_variation = "PdaMapDialog"
		add_child(release_confirmation)
		release_confirmation.confirmed.connect(confirm_release)
		release_confirmation.canceled.connect(cancel_release)
		release_confirmation.popup_centered(Vector2i(550, 190))
		release_confirmation.get_cancel_button().grab_focus()
		refresh(); return
	commit_disposition(intent(command_id))

func commit_disposition(requested: PlayerIntent) -> void:
	var result: Dictionary = engine.commit_player_intent(world, requested)
	if result.success: world_changed.emit()
	refresh()
	if not result.success: notice.text = custody_explain(result.error) if requested.payload.command in Disposition.COMMANDS else explain(result.error)

func confirm_release() -> void:
	var requested: PlayerIntent = pending_release
	cancel_release()
	commit_disposition(requested)

func cancel_release() -> void:
	if is_instance_valid(release_confirmation): release_confirmation.queue_free()
	release_confirmation = null; pending_release = null
	refresh()
