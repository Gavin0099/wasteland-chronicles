extends AcceptDialog

signal action_requested(action: String)
const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Icon = preload("res://ui/components/item_icon.gd")
const Trust = preload("res://simulation/local_trust.gd")
var action_buttons: Dictionary = {}
var detail: Label

static func explain(refusal: String) -> String:
	return {"DUNGEON_ALREADY_REPORTED": "已回報，往來不會重複增加或減少", "DUNGEON_DECISION_REQUIRED": "先在控制室決定修復台去留；可準備後再訪", "DUNGEON_RETURN_REQUIRED": "決定後先從入口樓梯返回灰谷", "DUNGEON_REQUIRES_GRAY_VALLEY": "需要本人停留灰谷", "DUNGEON_ACTIVITY_PENDING": "先確認目前遭遇或戰果", "DUNGEON_PLAYER_NOT_ALIVE": "需要存活的旅人"}.get(refusal, "目前無法回報，請查看旅程狀態")

func setup(world: WorldState) -> void:
	title = "水廠紀錄 · 帶回城裡的收穫"
	theme_type_variation = "PdaMapDialog"
	ok_button_text = "暫不回報 · 返回城鎮"
	wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = 660
	column.add_theme_constant_override("separation", Tokens.GAP)
	add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	row.add_child(Icon.make(Dungeon.DEEP_REWARD, 56))
	detail = Label.new()
	detail.custom_minimum_size.x = 580
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var checkpoint: Dictionary = Dungeon.state(world)
	detail.text = "已探索%d/8房；捷徑%s；深層精密組%s。\n%s\n熔爐協約往來%d。可自願回報：保留+3／拆解−3；暫不回報不改變往來。\n精密組機械3，機械修井少耗1廢料；仍需找到舊井、回報歸屬、接下修井委託並備妥技能、材料與旅程補給。" % [checkpoint.visited.size(), "已開" if checkpoint.shortcut_open else "未開", "已取走（不會再生）" if checkpoint.tools_recovered else "尚未取走（需面具、迎戰與容量）", Dungeon.device_note(world) if checkpoint.device_choice != "" else "修復台去留尚未決定，可經控制室查看。", Trust.faction_score(world, "forge")]
	row.add_child(detail)
	for action: String in ["REPORT", "MARKET", "WELL", "REVISIT"]:
		var button: Button = Button.new()
		button.theme_type_variation = "PdaCommand"
		button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = {"REPORT": "回報設備去留 · 往來%s3（一次／不花一天）" % ("+" if checkpoint.device_choice == "PRESERVE" else "−"), "MARKET": "前往本地市場 · 自己選擇保留或出售收穫", "WELL": "追尋枯河舊井 · 使用精密組繼續做修井工作", "REVISIT": "再訪水廠 · 已探索、已清場、捷徑與一次收穫保留"}[action]
		if action == "REPORT":
			var refusal: String = Dungeon.report_requirement(world)
			button.disabled = refusal != ""
			button.tooltip_text = explain(refusal) if refusal != "" else "回報會留下持續的地方與陣營往來。也可以暫不回報。"
			if refusal != "": button.text += "\n" + explain(refusal)
		button.pressed.connect(func() -> void: action_requested.emit(action))
		column.add_child(button)
		action_buttons[action] = button
