extends AcceptDialog

signal world_changed
const Target = preload("res://simulation/relay_target.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Poses = preload("res://ui/components/battle_pose_library.gd")
var world: WorldState
var engine: SimulationEngine
var detail: Label
var notice: Label
var action_buttons: Dictionary = {}

static func explain(error: String) -> String:
	return {"": "", "TARGET_ALREADY_ACCEPTED": "已接下追查", "TARGET_REQUIRES_GRAY_VALLEY": "需在灰谷接單或回報", "TARGET_NO_ANONYMOUS_SLOT": "灰谷沒有可具名化的居民", "TARGET_NOTICE_REQUIRED": "先在灰谷接下追查", "TARGET_INTEL_UNAVAILABLE": "已打聽過，或目前不在灰谷", "TARGET_REPORT_UNAVAILABLE": "需親見動向，返回灰谷且尚未領費", "TARGET_FOLLOW_MOVEMENT_FIRST": "先追查他離開灰谷後的動向", "TARGET_NOT_HERE": "目標目前不在這裡或已當面問過", "TARGET_REQUIRES_LIVING_TOWN": "需存活並停留城鎮", "TARGET_ACTIVITY_PENDING": "先完成目前探索或戰果", "TARGET_RETURN_TO_TOWN": "先從入口返回城鎮", "TARGET_NEED_ROPE": "缺繩索；封出口會消耗一條", "TARGET_NEED_SCRAP": "缺1廢料", "TARGET_PARTY_ID_OCCUPIED": "逃亡行程編號已有紀錄", "TARGET_ESCAPE_ROUTE_MISSING": "灰谷—新希望商路不存在"}.get(error, "目前無法執行，請確認位置與追查紀錄")

func intent(command_id: String) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"site_id": Target.SITE, "command": command_id})

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	title = "追查灰鴉 · 偵查委託"
	theme_type_variation = "PdaMapDialog"
	ok_button_text = "返回城鎮"
	wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(620, 390)
	column.add_theme_constant_override("separation", Tokens.GAP)
	add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = Poses.load_atlas("res://ui/assets/combat/relay-grey-crow.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(150, 260)
	row.add_child(portrait)
	var text_column: VBoxContainer = VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	var heading: Label = Label.new()
	heading.text = Target.NAME + " · 原拾荒者"
	heading.theme_type_variation = "PdaSection"
	text_column.add_child(heading)
	detail = Label.new()
	detail.custom_minimum_size.x = 430
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_child(detail)
	notice = Label.new()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(notice)
	var actions: GridContainer = GridContainer.new()
	actions.columns = 2
	column.add_child(actions)
	for entry: Dictionary in [{"command": "ACCEPT_TARGET", "label": "接下追查 · 回報12瓶蓋"}, {"command": "ASK_TARGET", "label": "打聽灰鴉的習慣"}, {"command": "WITNESS_TARGET", "label": "當面確認移居目標"}, {"command": "REPORT_TARGET", "label": "回報親見動向 · 領12瓶蓋"}]:
		var b: Button = Button.new()
		b.text = entry.label
		b.theme_type_variation = "PdaCommand"
		b.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(perform.bind(String(entry.command)))
		actions.add_child(b)
		action_buttons[entry.command] = b
	refresh()

func refresh() -> void:
	detail.text = Target.describe(world)
	for command_id: String in action_buttons:
		var error: String = engine.authorize_player_intent(world, intent(command_id))
		action_buttons[command_id].disabled = error != ""
		action_buttons[command_id].tooltip_text = explain(error)

func perform(command_id: String) -> void:
	var result: Dictionary = engine.commit_player_intent(world, intent(command_id))
	if result.success:
		notice.text = {"ACCEPT_TARGET": "已接下追查；可先打聽，再從中繼站入口前往。", "ASK_TARGET": "記下左靴與維修出口的線索；繩索＋1廢料可封出口。", "WITNESS_TARGET": "已親自確認他的移居位置；可回灰谷交差。", "REPORT_TARGET": "已回報親見動向，獲得12瓶蓋。"}[command_id]
		world_changed.emit()
	else: notice.text = explain(result.error)
	refresh()
