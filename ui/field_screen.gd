extends Control

signal closed
signal world_changed
const Field = preload("res://simulation/field_adventure.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
const DesktopWindow = preload("res://ui/components/desktop_window.gd")
const DesktopBackdrop = preload("res://ui/components/desktop_backdrop.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Stage = preload("res://ui/components/battle_stage.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")
const Presentation = preload("res://ui/character_presentation.gd")
var world: WorldState
var engine: SimulationEngine
var stage: Control
var heading_label: Label
var status_label: Label
var log_label: Label
var growth_notice_label: Label
var receipt_items: VBoxContainer
var gain_values: Dictionary = {}
var left_values: Dictionary = {}
var error_label: Label
var actions_box: GridContainer
var close_button: Button
var buttons: Dictionary = {}
var busy := false
var reduce_motion: CheckBox
var battle_map_label: Label

func practice_text(practice: Dictionary) -> String:
	if practice.is_empty():
		return ""
	var skill_name: String = Presentation.SKILL_NAMES.get(String(practice.skill_id), String(practice.skill_id))
	if practice.rank_up:
		return "%s能力提升：%d %s" % [skill_name, int(practice.to_rank), Presentation.RANK_NAMES[int(practice.to_rank)]]
	return "%s練習 +1（%d/%d）" % [skill_name, int(practice.points), int(practice.required)]

func label_in(parent: Node, text: String, variant: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func setup(p_world: WorldState, p_engine: SimulationEngine) -> void:
	world = p_world
	engine = p_engine
	var background := ColorRect.new()
	background.color = Tokens.BASE
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, Tokens.PAD)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", Tokens.GAP)
	margin.add_child(root)
	var heading := HBoxContainer.new()
	root.add_child(heading)
	heading_label = label_in(heading, "灰谷近郊 / 舊補給棚", "PdaTitle")
	reduce_motion = CheckBox.new()
	reduce_motion.text = "減少動態"
	reduce_motion.toggled.connect(func(value: bool): stage.reduced_motion = value)
	heading.add_child(reduce_motion)
	close_button = Button.new()
	close_button.text = "返回地圖"
	close_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	close_button.pressed.connect(close)
	heading.add_child(close_button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Tokens.PAD)
	root.add_child(body)
	stage = Stage.new()
	body.add_child(stage)
	var side := PanelContainer.new()
	side.theme_type_variation = "PdaPanel"
	side.custom_minimum_size.x = 320
	body.add_child(side)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", Tokens.PAD)
	scroll.add_child(info)
	status_label = label_in(info, "", "PdaSection")
	log_label = label_in(info, "")
	receipt_items = VBoxContainer.new()
	receipt_items.add_theme_constant_override("separation", Tokens.GAP)
	info.add_child(receipt_items)
	var note_label := label_in(root, "攻擊、防禦與逃跑逐回合結算；休養才會經過一天。", "PdaMuted")
	actions_box = GridContainer.new()
	actions_box.columns = 3
	actions_box.add_theme_constant_override("h_separation", Tokens.GAP)
	actions_box.add_theme_constant_override("v_separation", Tokens.GAP)
	root.add_child(actions_box)
	error_label = label_in(root, "")
	error_label.hide()
	_install_desktop_layout(root, heading, body, stage, status_label, log_label, receipt_items, actions_box, error_label, note_label)
	refresh()

func _install_desktop_layout(root: VBoxContainer, heading: HBoxContainer, old_body: HBoxContainer, battle_stage: Control, status: Label, log: Label, receipts: VBoxContainer, actions: GridContainer, errors: Label, note: Label) -> void:
	var backdrop := DesktopBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 1)
	var toolbar := PanelContainer.new()
	var toolbar_style := StyleBoxFlat.new()
	toolbar_style.bg_color = Color("#DCDAD2")
	toolbar_style.border_color = Color("#7E7E7C")
	toolbar_style.set_border_width_all(1)
	toolbar_style.content_margin_left = 8
	toolbar_style.content_margin_right = 8
	toolbar_style.content_margin_top = 4
	toolbar_style.content_margin_bottom = 4
	toolbar.add_theme_stylebox_override("panel", toolbar_style)
	root.add_child(toolbar)
	root.move_child(toolbar, 0)
	heading.reparent(toolbar)
	heading_label.add_theme_color_override("font_color", Color("#20242C"))
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	root.add_child(columns)
	root.move_child(columns, 1)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = SIZE_EXPAND_FILL
	main.size_flags_vertical = SIZE_EXPAND_FILL
	main.size_flags_stretch_ratio = 1.8
	main.add_theme_constant_override("separation", 8)
	columns.add_child(main)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = SIZE_EXPAND_FILL
	side.size_flags_vertical = SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 0.9
	side.add_theme_constant_override("separation", 8)
	columns.add_child(side)
	var scene_window := DesktopWindow.new("戰鬥場景")
	scene_window.size_flags_vertical = SIZE_EXPAND_FILL
	main.add_child(scene_window)
	battle_stage.reparent(scene_window.body)
	var message_window := DesktopWindow.new("戰鬥訊息")
	message_window.custom_minimum_size.y = 112
	main.add_child(message_window)
	growth_notice_label = label_in(message_window.body, "", "PdaSection")
	growth_notice_label.visible = false
	var message_scroll := ScrollContainer.new()
	message_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	message_window.body.add_child(message_scroll)
	var message_lines := VBoxContainer.new()
	message_lines.size_flags_horizontal = SIZE_EXPAND_FILL
	message_scroll.add_child(message_lines)
	log.reparent(message_lines)
	receipts.reparent(message_lines)
	errors.reparent(message_window.body)
	note.reparent(message_window.body)
	var person_window := DesktopWindow.new("人物與對手")
	side.add_child(person_window)
	status.reparent(person_window.body)
	var tools_window := DesktopWindow.new("行動指令")
	side.add_child(tools_window)
	actions.reparent(tools_window.body)
	actions.columns = 1
	var map_window := DesktopWindow.new("交戰位置")
	map_window.size_flags_vertical = SIZE_EXPAND_FILL
	side.add_child(map_window)
	battle_map_label = Label.new()
	battle_map_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_map_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battle_map_label.size_flags_vertical = SIZE_EXPAND_FILL
	map_window.body.add_child(battle_map_label)
	old_body.queue_free()

func close() -> void:
	if busy or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0:
		return
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not busy:
		close()
		get_viewport().set_input_as_handled()

func payload_for(command: String) -> Dictionary:
	var data := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		data.battle_id = world.field_state.battle.id
		data.turn = world.field_state.battle.turn
	elif command == "CONFIRM":
		data.receipt = world.field_state.receipt
	return data

func add_action(command: String, title: String) -> void:
	var button := Button.new()
	button.theme_type_variation = "PdaCommand"
	button.text = title
	button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	var payload := payload_for(command)
	var error := engine.authorize_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))
	button.disabled = error != ""
	if error != "":
		button.text += " · " + reason_text(error)
		button.tooltip_text = reason_text(error)
	button.pressed.connect(perform.bind(payload))
	actions_box.add_child(button)
	buttons[command] = button

func reason_text(error: String) -> String:
	if error == "EQUIPMENT_ALREADY_SET":
		return "裝備狀態已更新，請重新選擇"
	var names := {"NEED_SCRAP_3": "需要 3 廢料", "NEED_CROWBAR": "需要撬棍", "NEED_FIRST_AID_KIT": "需要急救包", "CROWBAR_ALREADY_OWNED": "已持有", "DOG_GUARDS_CACHE": "野犬仍在看守", "CACHE_ALREADY_OPENED": "已取走", "SITE_ALREADY_CLEARED": "已排除威脅", "RETURN_TO_GRAY_VALLEY": "需返回灰谷", "HEALTH_FULL": "生命已滿", "FIELD_REQUIRES_LIVING_SETTLED_PLAYER": "需存活並停留在聚落", "ROAD_ENCOUNTER_PENDING": "先完成路上遭遇", "PACK_FULL": "背包容量不足", "STALE_FIELD_TURN": "回合已改變，請重新選擇"}
	return names.get(error, "目前無法執行，請先完成當前行動")

func goods_text(goods: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in goods:
		parts.append("%s %d" % [{"water": "水", "food": "食物"}.get(key, key), goods[key]])
	return "、".join(parts) if not parts.is_empty() else "無"

func refresh() -> void:
	for child in receipt_items.get_children():
		receipt_items.remove_child(child)
		child.queue_free()
	gain_values.clear()
	left_values.clear()
	receipt_items.hide()
	for child in actions_box.get_children():
		actions_box.remove_child(child)
		child.queue_free()
	buttons.clear()
	var state := world.field_state
	var kit := world.player.field_kit
	var is_road: bool = false
	if not state.battle.is_empty():
		is_road = String(state.battle.get("source", "field")) == "road"
	elif state.receipt >= 0 and state.receipt < world.event_log.size():
		is_road = String(world.event_log[state.receipt].payload.get("source", "field")) == "road"

	if heading_label != null:
		heading_label.text = "荒原道路 / 劫匪伏擊" if is_road else "灰谷近郊 / 舊補給棚"
	close_button.text = "返回旅途" if is_road else "返回地圖"
	close_button.disabled = not state.battle.is_empty() or state.receipt >= 0
	close_button.tooltip_text = "請先完成戰鬥或逃跑，並確認結果。" if close_button.disabled else ""
	var weapon := "撬棍" if kit.equipped else "徒手"
	var weapon_item := "crowbar" if kit.equipped else ""
	if world.player.equipment != null:
		var main_hand: String = world.player.equipment.equipped_item("main_hand")
		if not main_hand.is_empty():
			var resolved := ItemRegistry.resolve(main_hand)
			if resolved.success:
				weapon = String(resolved.definition.display_name_zh)
				weapon_item = main_hand
	# PLAY-1: the stage is told what this battle actually is, instead of always
	# drawing a dog in a supply shed holding a crowbar.
	stage.configure("bandit" if is_road else "feral_dog", weapon_item, is_road)
	stage.refresh(kit.equipped, state.enemy_hp > 0)
	var alive := world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive()
	var enemy_name := "荒原劫匪" if is_road else "野犬"
	if growth_notice_label != null:
		growth_notice_label.visible = false
	if battle_map_label != null:
		battle_map_label.text = "交戰示意\n你　↔　%s" % enemy_name
	status_label.text = "你　生命 %d / 12\n%s　生命 %d / 8\n武器　%s　·　負重 %d / %d" % [kit.hp, enemy_name, state.enemy_hp, weapon, world.player.get_total_inventory_load(), world.player.get_effective_capacity()]
	if not alive:
		status_label.text = "角色已死亡\n" + status_label.text
	if state.receipt >= 0:
		var receipt: Dictionary = world.event_log[state.receipt].payload
		var outcome: String = ""
		if is_road:
			match String(receipt.outcome):
				"VICTORY":
					outcome = "戰鬥勝利！伏擊的劫匪已被擊退。"
					if receipt.has("attribution") and String(receipt.attribution) != "":
						outcome += "\n" + String(receipt.attribution)
					outcome += "\n你在現場收集了遺留的物資。\n\n你仍可以繼續行動。"
				"DEFEAT": outcome = "遭到劫匪伏擊！你身受重傷（生命剩餘 1）。\n劫匪搶走了你的物資後揚長而去。\n\n你仍可以繼續行動。"
				"ESCAPED": outcome = "你擺脫了劫匪的包夾，成功逃離了戰場。\n\n你仍可以繼續行動。"
				_: outcome = "戰鬥已結束。"
		else:
			outcome = {"VICTORY": "野犬倒下了。補給棚的門仍鎖著。", "ESCAPED": "你退出了戰鬥，野犬仍守在這裡。", "DEAD": "你倒在了補給棚前。旅程到此結束。", "CACHE": "你用撬棍打開了補給棚。"}.get(receipt.outcome, "")
		log_label.text = "%s\n\n經過時間：0 天\n生命剩餘：%d / 12" % [outcome, kit.hp]
		if int(receipt.get("xp_gained", 0)) > 0:
			log_label.text += "\n歷練：+%d XP" % int(receipt.xp_gained)
		var finishing_practice: Dictionary = receipt.get("skill_practice", {})
		if not finishing_practice.is_empty():
			growth_notice_label.text = practice_text(finishing_practice)
			growth_notice_label.visible = true
		receipt_items.show()
		if not receipt.gained.is_empty():
			show_receipt_goods("獲得物資", receipt.gained, "+", gain_values)
		if receipt.has("caps_gained") and int(receipt.caps_gained) > 0:
			show_receipt_goods("獲得", {"caps": int(receipt.caps_gained)}, "+", gain_values)
		if receipt.has("lost") and not receipt.lost.is_empty():
			show_receipt_goods("失去物資", receipt.lost, "−", left_values)
		if not receipt.left_behind.is_empty():
			show_receipt_goods("容量不足，未帶走", receipt.left_behind, "", left_values)
		var confirm_text := "確認結果並返回" if is_road else "確認結果"
		if int(receipt.get("xp_gained", 0)) > 0:
			confirm_text += " · 歷練 +%d XP" % int(receipt.xp_gained)
		add_action("CONFIRM", confirm_text)
	elif not state.battle.is_empty():
		var turn: int = state.battle.turn
		status_label.text += "\n第 %d 回合 · 你的行動" % turn
		var damage := Field.enemy_damage(turn)
		if is_road:
			log_label.text = "荒原劫匪準備%s，將造成 %d 傷害。\n防禦可減少 3 傷害，並讓下次攻擊增加 2 傷害（不累加）。" % ["狠毒猛擊" if damage == 4 else "揮砍", damage]
		else:
			log_label.text = "野犬準備%s，將造成 %d 傷害。\n防禦可減少 3 傷害，並讓下次攻擊增加 2 傷害（不累加）。" % ["猛撲" if damage == 4 else "撕咬", damage]
		for event in world.event_log:
			if event.type == "FIELD_TURN" and int(event.payload.battle_id) == int(state.battle.id) and event.payload.turn >= turn - 3:
				log_label.text += "\n\n第 %d 回合：造成 %d / 承受 %d" % [event.payload.turn, event.payload.dealt, event.payload.taken]
				var practice: Dictionary = event.payload.get("skill_practice", {})
				if not practice.is_empty():
					log_label.text += " · " + practice_text(practice)
		add_action("ATTACK", "攻擊 · 傷害 %d" % Field.attack_damage(world))
		add_action("DEFEND", "防禦 · 減傷 3，準備反擊")
		add_action("FLEE", "逃跑 · 承受 1 傷害")
	else:
		if is_road:
			log_label.text = "戰鬥已結束，可點擊「返回旅途」。"
		else:
			log_label.text = "野犬守著灰谷外圍的舊補給棚。\n\n棚門需要撬棍才能打開；裡面只有一批補給：水 4、食物 2。\n\n撬棍：3 廢料組裝，負重 2。可開鎖住的棚門，也能裝備作近戰武器。\n\n休養：經過 1 天，恢復 4 生命；仍受世界供應與缺水缺糧影響。急救包：消耗 1 件，立即恢復最多 4 生命。"
			add_action("START", "接近補給棚 · 開始戰鬥")
			add_action("CRAFT", "組裝撬棍 · 廢料 −3")
			add_action("UNEQUIP" if kit.equipped else "EQUIP", "卸下撬棍" if kit.equipped else "裝備撬棍")
			add_action("OPEN", "使用撬棍 · 打開補給棚")
			add_action("REST", "休養 1 天 · 生命 +4")
			add_action("TREAT", "使用急救包 · 生命最多 +4")

func show_receipt_goods(title: String, goods: Dictionary, prefix: String, values: Dictionary) -> void:
	label_in(receipt_items, title, "PdaSection")
	if goods.is_empty():
		label_in(receipt_items, "無")
	for id in ["water", "food", "scrap", "caps"]:
		if int(goods.get(id, 0)) <= 0:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", Tokens.GAP)
		receipt_items.add_child(row)
		row.add_child(ItemIcon.make(id))
		var zh_name: String = String({"water": "水", "food": "食物", "scrap": "廢料", "caps": "瓶蓋"}.get(id, id))
		values[id] = label_in(row, "%s %s%d" % [zh_name, prefix, goods[id]])

func perform(payload: Dictionary) -> void:
	if busy:
		return
	busy = true
	close_button.disabled = true
	for button in buttons.values():
		button.disabled = true
	var result := engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))
	if result.success:
		if payload.command in ["ATTACK", "DEFEND", "FLEE"]:
			for i in range(world.event_log.size() - 1, -1, -1):
				var event := world.event_log[i]
				if event.type == "FIELD_TURN":
					await stage.animate_turn(payload.command, int(event.payload.dealt), int(event.payload.taken))
					break
		error_label.hide()
		world_changed.emit()
	else:
		error_label.text = reason_text(result.error)
		error_label.show()
	busy = false
	close_button.disabled = false
	refresh()
	var practice: Dictionary = result.get("skill_practice", {})
	if result.success and payload.command == "TREAT":
		var healed: int = int(world.event_log.back().payload.get("healed", 0))
		growth_notice_label.text = "急救包 −1 · 生命 +%d" % healed
		if not practice.is_empty():
			growth_notice_label.text += " · " + practice_text(practice)
		growth_notice_label.visible = true
	elif result.success and not practice.is_empty():
		growth_notice_label.text = practice_text(practice)
		growth_notice_label.visible = true
	if not buttons.is_empty():
		for button in buttons.values():
			if not button.disabled:
				button.grab_focus()
				break
