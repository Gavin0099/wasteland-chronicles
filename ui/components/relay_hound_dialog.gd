extends AcceptDialog

signal world_changed
const Hound = preload("res://simulation/relay_hound.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const HoundSprite = preload("res://ui/components/relay_hound_sprite.gd")
const LABELS: Dictionary = {"REPAIR_HOUND": "修復 · 燃料1＋廢料3 · 能源4", "CHARGE_HOUND": "補滿能源至4 · 燃料1 · 剩餘不折抵", "HOUND_SUPPORT_ON": "開啟戰鬥支援 · 每次補攻耗能源1", "HOUND_SUPPORT_OFF": "暫停支援 · 能源留給開門", "HOUND_OPEN_TUNNEL": "機械犬開維修內門 · 能源2"}
var world: WorldState
var engine: SimulationEngine
var detail: Label
var notice: Label
var action_buttons: Dictionary = {}
var portrait: HoundSprite

static func explain(error: String) -> String:
	return {"": "", "HOUND_PLAYER_DEAD": "旅程已結束", "HOUND_REQUIRES_SETTLED": "先抵達城鎮", "HOUND_ACTIVITY_PENDING": "先完成並確認目前行動", "HOUND_REQUIRES_ENTRANCE": "需回中繼站入口", "HOUND_INSPECT_FIRST": "先到中繼站入口查看機械犬", "HOUND_ALREADY_REPAIRED": "已修好，不必重付耗材", "HOUND_NEED_ELECTRONICS": "需本人電子1；可回城找老師", "HOUND_NEED_MECHANICAL_HELP": "需機械1／扳手或撬棍／阿扳協助", "HOUND_NEED_FUEL": "缺燃料1；可在城鎮市場購買", "HOUND_NEED_SCRAP": "缺廢料3；可拾荒或購買", "HOUND_REPAIR_FIRST": "先修復機械犬", "HOUND_ALREADY_FULL": "能源已滿", "HOUND_MODE_UNCHANGED": "已是這個模式", "HOUND_REQUIRES_DOOR": "需到中繼站維修道內門", "HOUND_DOOR_ALREADY_OPEN": "內門已開啟", "HOUND_NEED_ENERGY_2": "需能源2；燃料1可補滿", "HOUND_STALE_REVISION": "狀態已改變，請重新選擇"}.get(error, "目前無法操作；請確認位置與準備")

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world; engine = p_engine
	title = "機械犬 · 修復與能源"
	theme_type_variation = "PdaMapDialog"; ok_button_text = "返回"; wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(680, 420); column.add_theme_constant_override("separation", Tokens.GAP); add_child(column)
	var row: HBoxContainer = HBoxContainer.new(); column.add_child(row)
	var picture: Control = Control.new(); picture.custom_minimum_size = Vector2(160, 170); row.add_child(picture)
	portrait = HoundSprite.new(); portrait.position = Vector2(92, 164); portrait.base_position = portrait.position; picture.add_child(portrait)
	detail = Label.new(); detail.custom_minimum_size = Vector2(512, 170); detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(detail)
	notice = Label.new(); notice.custom_minimum_size.x = 680; notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(notice)
	var actions: GridContainer = GridContainer.new(); actions.columns = 2
	actions.add_theme_constant_override("h_separation", Tokens.GAP); actions.add_theme_constant_override("v_separation", Tokens.GAP); column.add_child(actions)
	for command_id: String in LABELS:
		var button: Button = Button.new(); button.theme_type_variation = "PdaCommand"; button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(perform.bind(command_id)); actions.add_child(button); action_buttons[command_id] = button
	refresh()

func refresh() -> void:
	detail.text = Hound.describe(world) + "\n持有燃料%d／廢料%d" % [world.player.inventory.fuel, world.player.inventory.scrap]
	portrait.configure(135, not Hound.state(world).repaired)
	for command_id: String in action_buttons:
		var button: Button = action_buttons[command_id]
		var refusal: String = engine.authorize_player_intent(world, Hound.intent(world, command_id))
		button.disabled = refusal != ""; button.tooltip_text = explain(refusal)
		button.text = LABELS[command_id] + ("\n" + explain(refusal) if refusal != "" else "")

func perform(command_id: String) -> void:
	var result: Dictionary = engine.commit_player_intent(world, Hound.intent(world, command_id))
	notice.text = "操作完成，耗材與能源已記錄。" if result.success else explain(result.error)
	if result.success: world_changed.emit()
	refresh()
