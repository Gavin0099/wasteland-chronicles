extends AcceptDialog

signal world_changed

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Inventory = preload("res://ui/inventory_presentation.gd")
const Description = preload("res://ui/item_description.gd")
const Icon = preload("res://ui/components/item_icon.gd")
var world: WorldState
var engine: SimulationEngine
var summary: Label
var notice: Label
var items_column: VBoxContainer
var treatment_buttons: Dictionary = {}

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	title = "背包與補給"
	theme_type_variation = "PdaMapDialog"
	ok_button_text = "返回探索"
	wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = 720
	column.size.x = 720
	column.add_theme_constant_override("separation", Tokens.GAP)
	add_child(column)
	summary = Label.new()
	summary.custom_minimum_size.x = 720
	summary.size.x = 720
	summary.theme_type_variation = "PdaMuted"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	items_column = VBoxContainer.new()
	items_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_column.add_theme_constant_override("separation", Tokens.GAP)
	scroll.add_child(items_column)
	notice = Label.new()
	notice.custom_minimum_size.x = 720
	notice.size.x = 720
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.text = "迷宮中使用隨身補給；補買與整理裝備請沿原路回灰谷。"
	column.add_child(notice)
	var actions: HBoxContainer = HBoxContainer.new()
	column.add_child(actions)
	for item_id: String in Field.TREATMENT_HEALING:
		var button: Button = Button.new()
		button.theme_type_variation = "PdaCommand"
		button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(treat.bind(item_id))
		actions.add_child(button)
		treatment_buttons[item_id] = button
	refresh()

static func refusal_text(error: String) -> String:
	return {"": "", "HEALTH_FULL": "生命已滿", "NEED_FIRST_AID_KIT": "沒有急救包", "NEED_BANDAGE": "沒有繃帶", "BATTLE_PENDING": "先完成戰鬥", "FIELD_RESULT_PENDING": "先確認戰果", "DUNGEON_EXPLORATION_PENDING": "先完成戰鬥並確認戰果", "FIELD_REQUIRES_LIVING_SETTLED_PLAYER": "角色已無法行動"}.get(error, "目前無法使用這件道具")

static func load_text(player: PlayerState) -> String:
	return "物資%d/%d · 道具%.1f/%.1fkg" % [player.get_total_inventory_load(), player.get_effective_capacity(), float(player.item_inventory.total_weight_g()) / 1000.0, float(player.item_inventory.capacity_grams(player.equipment.equipped_item("back"))) / 1000.0]

func item_row(item_id: String, caption: String, description: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	items_column.add_child(row)
	row.add_child(Icon.make(item_id, 40))
	var text: Label = Label.new()
	text.custom_minimum_size.x = 640
	text.size.x = 640
	text.text = caption + "\n" + description
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)

func refresh() -> void:
	var checkpoint: Dictionary = Dungeon.current_checkpoint(world)
	var companion: String = Dungeon.Party.current(world)
	var allowance: String = "獨行：每天水1、食物1。"
	if companion != "":
		var info: Dictionary = Dungeon.Party.info(companion)
		allowance += "%s另需水%d、食物%d；地下不免除玩家飲水。" % [info.name_zh, int(info.road_water), int(info.road_food)]
	if checkpoint.trip_rules == 1:
		summary.text = "生命%d/12 · %s · 本次換房%d次、已過%d日\n再換房%d次會過一日；不足一日的耗時會保留到下次探訪。\n%s" % [world.player.field_kit.hp, load_text(world.player), checkpoint.trip_moves, checkpoint.trip_days, Dungeon.MOVES_PER_DAY - int(checkpoint.work_units), allowance]
	else:
		summary.text = "生命%d/12 · %s\n這趟舊旅程不計日；返回灰谷後再進入才開始消耗隨身補給。\n再次探訪時：%s" % [world.player.field_kit.hp, load_text(world.player), allowance]
	for child: Node in items_column.get_children():
		items_column.remove_child(child)
		child.queue_free()
	for item_id: String in ["water", "food", "scrap", "fuel"]:
		var name_zh: String = {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}[item_id]
		item_row(item_id, "%s ×%d" % [name_zh, world.player.inventory.get_amount(item_id)], Description.text(item_id))
	if world.player.field_kit.crowbar:
		item_row("crowbar", "撬棍 ×1", "原有隨身工具；可開維修門，持有重量已計入負重。")
	for row: Dictionary in Inventory.rows(world.player.item_inventory.to_dict().items, {}):
		item_row(row.item_id, "%s ×%d · %.1fkg" % [row.name, int(row.quantity), float(row.weight_g) / 1000.0], Description.text(row.item_id))
	for item_id: String in treatment_buttons:
		var button: Button = treatment_buttons[item_id]
		var error: String = engine.authorize_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": item_id}))
		var name_zh: String = "急救包" if item_id == "first_aid_kit" else "繃帶"
		button.text = "%s −1 · 生命 +%d（持有%d）" % [name_zh, int(Field.TREATMENT_HEALING[item_id]), world.player.item_inventory.quantity(item_id)]
		button.disabled = error != ""
		button.tooltip_text = refusal_text(error)

func treat(item_id: String) -> void:
	var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": item_id}))
	if not result.success:
		notice.text = refusal_text(result.error)
		refresh()
		return
	var healed: int = int(world.event_log.back().payload.healed)
	notice.text = "%s −1 · 已恢復%d生命。" % ["急救包" if item_id == "first_aid_kit" else "繃帶", healed]
	refresh()
	world_changed.emit()
