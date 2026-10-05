extends AcceptDialog

signal world_changed
const Power = preload("res://simulation/relay_power.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
var world: WorldState
var engine: SimulationEngine
var detail: Label
var notice: Label
var action_buttons: Dictionary = {}

static func explain(error: String) -> String:
	return {"": "", "POWER_LIFT_OFF": "貨梯未供電；到維修道改接貨梯", "POWER_INSPECT_FIRST": "先查看維修道供電盤", "POWER_ALREADY_OFF": "已斷電", "POWER_ALREADY_READY": "已供電；目前不需補充", "POWER_NEED_ELECTRONICS": "需本人電子1；可回灰谷找老師", "POWER_NEED_MECHANICS_OR_TOOL": "需本人機械1或持有扳手／撬棍", "POWER_NEED_FUEL": "缺燃料1；可回城購買", "POWER_NEED_SCRAP": "缺廢料1", "POWER_REQUIRES_PANEL": "需靠近維修道供電盤", "POWER_ACTIVITY_PENDING": "先完成並確認目前戰果", "POWER_PLAYER_DEAD": "這段旅程已結束"}.get(error, "目前無法供電；請確認位置與準備")

func intent(command_id: String) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"site_id": Power.SITE, "command": command_id})

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	title = "中繼站供電盤"
	theme_type_variation = "PdaMapDialog"
	ok_button_text = "返回探索"
	wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(640, 360)
	column.add_theme_constant_override("separation", Tokens.GAP)
	add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var portrait: TextureRect = TextureRect.new()
	portrait.texture = preload("res://ui/components/battle_pose_library.gd").load_atlas("res://ui/assets/combat/relay-turret.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(150, 220)
	row.add_child(portrait)
	detail = Label.new()
	detail.custom_minimum_size.x = 470
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(detail)
	notice = Label.new()
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(notice)
	for entry: Dictionary in [{"command": "POWER_TURRET", "label": "接管砲塔 · 2次支援 · 燃料1＋廢料1"}, {"command": "POWER_LIFT", "label": "供電貨梯 · 入口↔檔案室 · 燃料1＋廢料1"}, {"command": "POWER_OFF", "label": "斷電 · 丟棄未用支援 · 不退款"}]:
		var b: Button = Button.new()
		b.theme_type_variation = "PdaCommand"
		b.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		b.text = entry.label
		b.pressed.connect(perform.bind(String(entry.command)))
		column.add_child(b)
		action_buttons[entry.command] = b
	refresh()

func refresh() -> void:
	detail.text = Power.describe(world) + "\n\n本人電子%d／機械%d · 持有燃料%d／廢料%d" % [world.player.capability.get_rank("ELECTRONICS"), world.player.capability.get_rank("MECHANICS"), world.player.inventory.fuel, world.player.inventory.scrap]
	for command_id: String in action_buttons:
		var error: String = engine.authorize_player_intent(world, intent(command_id))
		var b: Button = action_buttons[command_id]
		b.disabled = error != ""
		b.tooltip_text = explain(error)
		# Requirements are readable without relying on a disabled-button tooltip.
		b.text = {"POWER_TURRET": "接管砲塔 · 2次支援 · 燃料1＋廢料1", "POWER_LIFT": "供電貨梯 · 入口↔檔案室 · 燃料1＋廢料1", "POWER_OFF": "斷電 · 丟棄未用支援 · 不退款"}[command_id] + ("\n" + explain(error) if error != "" else "")

func perform(command_id: String) -> void:
	var result: Dictionary = engine.commit_player_intent(world, intent(command_id))
	notice.text = "供電已切換，狀態與耗材已記錄。" if result.success else explain(result.error)
	if result.success: world_changed.emit()
	refresh()
