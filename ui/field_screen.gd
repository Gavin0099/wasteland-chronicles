extends Control

signal closed
signal world_changed
const Field = preload("res://simulation/field_adventure.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Stage = preload("res://ui/components/battle_stage.gd")
var world: WorldState
var engine: SimulationEngine
var stage: Control
var status_label: Label
var log_label: Label
var error_label: Label
var actions_box: GridContainer
var close_button: Button
var buttons: Dictionary = {}
var busy := false
var reduce_motion: CheckBox

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
	label_in(heading, "灰谷近郊 / 舊補給棚", "PdaTitle")
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
	label_in(root, "攻擊、防禦與逃跑逐回合結算；休養才會經過一天。", "PdaMuted")
	actions_box = GridContainer.new()
	actions_box.columns = 3
	actions_box.add_theme_constant_override("h_separation", Tokens.GAP)
	actions_box.add_theme_constant_override("v_separation", Tokens.GAP)
	root.add_child(actions_box)
	error_label = label_in(root, "")
	error_label.hide()
	refresh()

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
	var names := {"NEED_SCRAP_3": "需要 3 廢料", "NEED_CROWBAR": "需要撬棍", "CROWBAR_ALREADY_OWNED": "已持有", "DOG_GUARDS_CACHE": "野犬仍在看守", "CACHE_ALREADY_OPENED": "已取走", "SITE_ALREADY_CLEARED": "已排除威脅", "RETURN_TO_GRAY_VALLEY": "需返回灰谷", "HEALTH_FULL": "生命已滿", "FIELD_REQUIRES_LIVING_SETTLED_PLAYER": "需存活並停留在聚落", "ROAD_ENCOUNTER_PENDING": "先完成路上遭遇", "PACK_FULL": "背包容量不足", "STALE_FIELD_TURN": "回合已改變，請重新選擇"}
	return names.get(error, "目前無法執行，請先完成當前行動")

func goods_text(goods: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in goods:
		parts.append("%s %d" % [{"water": "水", "food": "食物"}.get(key, key), goods[key]])
	return "、".join(parts) if not parts.is_empty() else "無"

func refresh() -> void:
	for child in actions_box.get_children():
		actions_box.remove_child(child)
		child.queue_free()
	buttons.clear()
	var state := world.field_state
	var kit := world.player.field_kit
	close_button.disabled = not state.battle.is_empty() or state.receipt >= 0
	close_button.tooltip_text = "請先完成戰鬥或逃跑，並確認結果。" if close_button.disabled else ""
	stage.refresh(kit.equipped, state.enemy_hp > 0)
	var weapon := "撬棍" if kit.equipped else "徒手"
	var alive := world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive()
	status_label.text = "你　生命 %d / 12\n野犬　生命 %d / 8\n\n武器　%s\n負重　%d / %d" % [kit.hp, state.enemy_hp, weapon, world.player.get_total_inventory_load(), world.player.capacity_total]
	if not alive:
		status_label.text = "角色已死亡\n" + status_label.text
	if state.receipt >= 0:
		var receipt: Dictionary = world.event_log[state.receipt].payload
		var outcome: String = {"VICTORY": "野犬倒下了。補給棚的門仍鎖著。", "ESCAPED": "你退出了戰鬥，野犬仍守在這裡。", "DEAD": "你倒在了補給棚前。旅程到此結束。", "CACHE": "你用撬棍打開了補給棚。"}[receipt.outcome]
		log_label.text = "%s\n\n獲得：%s\n留下：%s\n經過時間：0 天\n\n生命剩餘：%d / 12" % [outcome, goods_text(receipt.gained), goods_text(receipt.left_behind), kit.hp]
		add_action("CONFIRM", "確認結果")
	elif not state.battle.is_empty():
		var turn: int = state.battle.turn
		status_label.text += "\n\n第 %d 回合 · 你的行動" % turn
		var damage := Field.enemy_damage(turn)
		log_label.text = "野犬準備%s，將造成 %d 傷害。\n防禦可減少 3 傷害，並讓下次攻擊增加 2 傷害（不累加）。" % ["猛撲" if damage == 4 else "撕咬", damage]
		for event in world.event_log:
			if event.type == "FIELD_TURN" and int(event.payload.battle_id) == int(state.battle.id) and event.payload.turn >= turn - 3:
				log_label.text += "\n\n第 %d 回合：造成 %d / 承受 %d" % [event.payload.turn, event.payload.dealt, event.payload.taken]
		add_action("ATTACK", "攻擊 · 傷害 %d" % Field.attack_damage(world))
		add_action("DEFEND", "防禦 · 減傷 3，準備反擊")
		add_action("FLEE", "逃跑 · 承受 1 傷害")
	else:
		log_label.text = "野犬守著灰谷外圍的舊補給棚。\n\n棚門需要撬棍才能打開；裡面只有一批補給：水 4、食物 2。\n\n撬棍：3 廢料組裝，負重 2。可開鎖住的棚門，也能裝備作近戰武器。\n\n休養：經過 1 天，恢復 4 生命；仍受世界供應與缺水缺糧影響。"
		add_action("START", "接近補給棚 · 開始戰鬥")
		add_action("CRAFT", "組裝撬棍 · 廢料 −3")
		add_action("UNEQUIP" if kit.equipped else "EQUIP", "卸下撬棍" if kit.equipped else "裝備撬棍")
		add_action("OPEN", "使用撬棍 · 打開補給棚")
		add_action("REST", "休養 1 天 · 生命 +4")

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
	if not buttons.is_empty():
		for button in buttons.values():
			if not button.disabled:
				button.grab_focus()
				break
