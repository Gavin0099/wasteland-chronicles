extends AcceptDialog

signal world_changed
signal board_requested
const ReturnRules = preload("res://simulation/relay_return.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
var world: WorldState
var engine: SimulationEngine
var detail: Label
var notice: Label
var agreement_button: Button
var board_button: Button

static func explain(error: String) -> String:
	return {"": "", "RETURN_PLAYER_DEAD": "旅程已結束", "RETURN_REQUIRES_GRAY": "先抵達灰谷", "RETURN_ACTIVITY_PENDING": "先完成並確認目前行動", "RETURN_ALREADY_FRIEND": "再雇用已是25瓶蓋；不再折價或退款", "RETURN_NEED_ABBAN": "需要阿扳正在同行；可到人物頁雇用", "RETURN_NO_SHARED_OPERATION": "先與阿扳一起修復中繼站設備，並平安返城", "RETURN_STALE_SOURCE": "經歷已更新，請重新選擇"}.get(error, "目前無法操作，請確認位置與共同經歷")

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world; engine = p_engine
	title = "回城見聞 · 灰谷"
	theme_type_variation = "PdaMapDialog"; ok_button_text = "返回"; wrap_controls = true
	var column: VBoxContainer = VBoxContainer.new(); column.custom_minimum_size = Vector2(680, 420)
	column.add_theme_constant_override("separation", Tokens.GAP); add_child(column)
	var scroll: ScrollContainer = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(680, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	detail = Label.new(); detail.custom_minimum_size.x = 652; detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; scroll.add_child(detail)
	notice = Label.new(); notice.custom_minimum_size.x = 680; notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(notice)
	agreement_button = Button.new(); agreement_button.theme_type_variation = "PdaPrimary"; agreement_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	agreement_button.pressed.connect(perform); column.add_child(agreement_button)
	board_button = Button.new(); board_button.theme_type_variation = "PdaCommand"; board_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	board_button.text = "查看現在的委託 · 自己決定接哪一件"; board_button.pressed.connect(func() -> void: board_requested.emit()); column.add_child(board_button)
	refresh()

func refresh() -> void:
	var p: Dictionary = ReturnRules.project(world)
	var lines: PackedStringArray = ["上次中繼站往返", p.trip, "", "你離開期間 · 有來源的灰谷消息"]
	if not p.available: lines.append(explain(p.refusal))
	elif p.news.is_empty(): lines.append("這趟期間沒有記錄到灰谷消息。")
	else:
		for row: Dictionary in p.news: lines.append("第%d天 · %s" % [row.day, row.text])
	lines.append("\n現在的儲備與市場 · 到貨不代表庫存此刻仍相同")
	for row: String in p.stocks: lines.append(row)
	lines.append("\n現在可接的工作")
	for job: Dictionary in p.jobs: lines.append(job.title + " · " + job.summary)
	lines.append("\n阿扳 · 下一趟的約定\n" + p.abban)
	detail.text = "\n".join(lines)
	var refusal: String = engine.authorize_player_intent(world, ReturnRules.intent(world))
	agreement_button.disabled = refusal != ""; agreement_button.tooltip_text = explain(refusal)
	agreement_button.text = "與阿扳談下一趟 · 未來再雇用50→25瓶蓋" + ("\n" + explain(refusal) if refusal != "" else "")
	board_button.disabled = not p.available

func perform() -> void:
	var result: Dictionary = engine.commit_player_intent(world, ReturnRules.intent(world))
	notice.text = "阿扳願意再同行。未來再雇用25瓶蓋；這次沒有扣款、退款或增加聲望。" if result.success else explain(result.error)
	if result.success: world_changed.emit()
	refresh()
