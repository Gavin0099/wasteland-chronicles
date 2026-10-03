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
# The window around battle_map_label: "這一回合" during a turn, "對手" otherwise.
var turn_window: Control
var player_card: Control
var enemy_card: Control
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var intent_label: Label
var intent_detail_label: Label
var history_toggle: CheckBox
var history_window: Control

# One combatant, one row: who, how much is left, and a bar wide enough to feel
# at a glance. The number stays beside the bar, so nothing essential is carried
# by colour or length alone.
func _make_bar(parent: Node, fill: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Tokens.GAP)
	row.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(row)
	var caption := Label.new()
	caption.add_theme_font_size_override("font_size", Tokens.BODY)
	caption.add_theme_color_override("font_color", Tokens.TEXT)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	caption.size_flags_stretch_ratio = 2.0
	row.add_child(caption)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(120, 10)
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	var background := StyleBoxFlat.new()
	background.bg_color = Tokens.BASE
	background.border_color = Tokens.BORDER_STRONG
	background.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", background)
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	bar.add_theme_stylebox_override("fill", foreground)
	row.add_child(bar)
	bar.set_meta("caption", caption)
	return bar

func _set_bar(bar: ProgressBar, label: String, current: int, maximum: int) -> void:
	if bar == null:
		return
	bar.max_value = float(maxi(1, maximum))
	bar.value = float(clampi(current, 0, maximum))
	var caption = bar.get_meta("caption", null)
	if caption != null:
		caption.text = "%s　%d / %d" % [label, current, maximum]

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
	history_toggle = CheckBox.new()
	history_toggle.text = "戰鬥紀錄"
	history_toggle.toggled.connect(func(_value: bool): _refresh_history_visibility())
	heading.add_child(history_toggle)
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

# A clear isometric arena; status and commands remain in a fixed bottom dock.
func _install_desktop_layout(root: VBoxContainer, heading: HBoxContainer, old_body: HBoxContainer, battle_stage: Control, status: Label, log: Label, receipts: VBoxContainer, actions: GridContainer, errors: Label, note: Label) -> void:
	var backdrop := DesktopBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 1)
	var toolbar := PanelContainer.new()
	var toolbar_style := StyleBoxFlat.new()
	toolbar_style.bg_color = Tokens.ELEVATED
	toolbar_style.border_color = Tokens.BORDER_STRONG
	toolbar_style.set_border_width_all(1)
	toolbar_style.content_margin_left = 8
	toolbar_style.content_margin_right = 8
	toolbar_style.content_margin_top = 4
	toolbar_style.content_margin_bottom = 4
	toolbar.add_theme_stylebox_override("panel", toolbar_style)
	root.add_child(toolbar)
	root.move_child(toolbar, 0)
	heading.reparent(toolbar)
	heading_label.add_theme_color_override("font_color", Tokens.TEXT)
	var arena := Control.new()
	arena.custom_minimum_size.y = 200
	arena.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(arena)
	root.move_child(arena, 1)
	battle_stage.reparent(arena)
	battle_stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	battle_stage.custom_minimum_size.y = 200
	# Isometric projection owns its ground ratio; the scene fills the arena.
	battle_stage.configure_isometric(true)
	var combatant_dock := HBoxContainer.new()
	combatant_dock.add_theme_constant_override("separation", Tokens.GAP)
	root.add_child(combatant_dock)
	player_card = _combatant_card(combatant_dock, false)
	player_bar = _make_bar(player_card.body, Tokens.AMBER)
	status.reparent(player_card.body)
	status.add_theme_font_size_override("font_size", Tokens.BODY)
	enemy_card = _combatant_card(combatant_dock, true)
	turn_window = enemy_card
	enemy_bar = _make_bar(enemy_card.body, Tokens.CRITICAL)
	intent_label = label_in(enemy_card.body, "", "PdaSection")
	intent_label.add_theme_font_size_override("font_size", Tokens.BODY)
	intent_detail_label = label_in(enemy_card.body, "", "PdaMuted")
	battle_map_label = label_in(enemy_card.body, "", "PdaMuted")
	# The narrated posture is redundant during a turn: actual action and numbers
	# remain visible directly under the opponent's HP, rather than in history.
	actions.reparent(root)
	root.move_child(actions, root.get_child_count() - 1)
	actions.columns = 4
	var message_window := DesktopWindow.new("戰鬥訊息")
	message_window.custom_minimum_size.y = 72
	history_window = message_window
	root.add_child(message_window)
	growth_notice_label = label_in(message_window.body, "", "PdaSection")
	growth_notice_label.hide()
	growth_notice_label.reparent(root)
	root.move_child(growth_notice_label, actions.get_index())
	var message_scroll := ScrollContainer.new()
	message_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	message_scroll.custom_minimum_size.y = 26
	message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	message_window.body.add_child(message_scroll)
	var message_lines := VBoxContainer.new()
	message_lines.size_flags_horizontal = SIZE_EXPAND_FILL
	message_scroll.add_child(message_lines)
	log.reparent(message_lines)
	receipts.reparent(message_lines)
	errors.reparent(message_window.body)
	note.reparent(message_lines)
	old_body.queue_free()

func _refresh_history_visibility() -> void:
	if history_window != null:
		# Decisions stay beside commands. History can expand on demand; preparation
		# and committed results always show their explanations and receipts.
		history_window.visible = world.field_state.battle.is_empty() or history_toggle.button_pressed or error_label.visible

func _combatant_card(canvas: Control, on_right: bool) -> Control:
	var card := DesktopWindow.new("對手" if on_right else "你的角色")
	# Identity is already the HP caption. Avoid a duplicate header consuming
	# the headroom needed by the tallest fighter at 648p.
	card.title_bar.hide()
	canvas.add_child(card)
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	return card

static func environment_for(current_world: WorldState) -> String:
	var context: Dictionary = current_world.field_state.battle
	if context.is_empty() and current_world.field_state.receipt >= 0:
		context = current_world.event_log[current_world.field_state.receipt].payload
	if String(context.get("place_id", "")) == "place:hammer_camp":
		return "camp"
	if String(context.get("route_type", "")) == "WILDERNESS":
		return "wilderness"
	return "highway" if String(context.get("source", "field")) == "road" else "shed"

# Once battle state is cleared, the committed result still names the opponent.
func _display_enemy() -> String:
	var state := world.field_state
	if state.battle.is_empty() and state.receipt >= 0 and state.receipt < world.event_log.size():
		var id: String = String(world.event_log[state.receipt].payload.get("enemy", ""))
		if Field.Enemies.exists(id):
			return id
	return Field.battle_enemy(state)

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
	if command in ["ATTACK", "SHOOT", "DEFEND", "FLEE"]:
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
		button.text += "\n" + reason_text(error)
		button.tooltip_text = reason_text(error)
	button.pressed.connect(perform.bind(payload))
	actions_box.add_child(button)
	buttons[command] = button

func reason_text(error: String) -> String:
	if error == "NEED_EQUIPPED_FIREARM":
		return "需裝備槍械（新希望有售）"
	if error == "NEED_AMMUNITION":
		var firearm := Field.firearm_for(world)
		var ammo: String = String(firearm.get("ammo_item_id", "revolver_round"))
		return "%s不足（新希望補給）" % String(ItemRegistry.resolve(ammo).definition.display_name_zh)
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
	actions_box.columns = 3 if state.battle.is_empty() and state.receipt < 0 else 4
	var kit := world.player.field_kit
	var is_road: bool = false
	if not state.battle.is_empty():
		is_road = String(state.battle.get("source", "field")) == "road"
	elif state.receipt >= 0 and state.receipt < world.event_log.size():
		is_road = String(world.event_log[state.receipt].payload.get("source", "field")) == "road"

	if heading_label != null:
		heading_label.text = "%s / %s" % [{"highway": "廢棄公路", "wilderness": "荒野路", "camp": "鐵鎚幫營地", "shed": "灰谷近郊"}[environment_for(world)], Field.Enemies.display_name(_display_enemy())]
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
	stage.configure(Field.Enemies.resolve(_display_enemy()).art, weapon_item, is_road)
	stage.configure_environment(environment_for(world))
	stage.refresh(kit.equipped, state.enemy_hp > 0)
	var alive := world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive()
	# PLAY-4: the name and the health bar come from whoever is actually there.
	var current_foe := _display_enemy()
	var enemy_name := Field.Enemies.display_name(current_foe)
	if growth_notice_label != null:
		growth_notice_label.visible = false
	_set_bar(player_bar, "你 · " + String(world.npc_registry.get_npc(world.player.npc_id).name), int(kit.hp), Field.MAX_HP)
	_set_bar(enemy_bar, enemy_name, int(state.enemy_hp), Field.Enemies.max_hp(current_foe))
	_show_intent(Field.intent_preview(world))
	battle_map_label.visible = state.battle.is_empty()
	if battle_map_label != null:
		# Overwritten below when a turn is actually waiting on the player. This
		# panel is about the decision in front of you, not a standing diagram.
		# Hand-play: a "this turn" heading over a description of the enemy read
		# as nonsense. Outside a turn this panel is about who you face.
		battle_map_label.add_theme_color_override("font_color", Tokens.SECONDARY)
		battle_map_label.text = "%s：%s" % [enemy_name, Field.Enemies.resolve(current_foe).note_zh]
		if turn_window != null:
			turn_window.title_label.text = "對手"
	# Both health values are on the bars above now; repeating them here was the
	# same fact three times in one panel.
	status_label.text = "武器　%s　· 防護 %d" % [weapon, Field.Gear.protection(world.player)]
	if not alive:
		status_label.text = "角色已死亡\n" + status_label.text
	if state.receipt >= 0:
		var receipt: Dictionary = world.event_log[state.receipt].payload
		var outcome: String = ""
		if is_road:
			match String(receipt.outcome):
				"VICTORY":
					outcome = "戰鬥勝利！%s已被擊退。" % enemy_name
					if receipt.has("attribution") and String(receipt.attribution) != "":
						outcome += "\n" + String(receipt.attribution)
					outcome += "\n你在現場收集了遺留的物資。\n\n你仍可以繼續行動。"
				"DEFEAT": outcome = "你被%s擊倒，身受重傷（生命剩餘 1）。\n你的物資在混亂中被搶走或散落。\n\n你仍可以繼續行動。" % enemy_name
				"ESCAPED": outcome = "你擺脫了%s，成功逃離了戰場。\n\n你仍可以繼續行動。" % enemy_name
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
		status_label.text += "　／　第 %d 回合 · 你的行動" % turn
		# PLAY-4: the telegraph is the whole reason bracing is a decision, so it
		# comes from the enemy catalogue and states exactly what this turn's
		# blow will be and what bracing against it would actually save.
		var foe := _display_enemy()
		var incoming: Dictionary = Field.Enemies.action_for(foe, turn)
		# The single fact that decides this turn sits beside the commands, and
		# takes the danger colour only when it really is one.
		if battle_map_label != null:
			# The numbers now live on the intent line above; this stays the
			# picture of what the enemy is doing.
			battle_map_label.text = Field.Enemies.telegraph(foe, turn)
			if turn_window != null:
				turn_window.title_label.text = "這一回合"
			battle_map_label.add_theme_color_override(
				"font_color", Tokens.CRITICAL if bool(incoming.heavy) else Tokens.TEXT)
		log_label.text = "架勢防禦也讓你下次攻擊增加 2 傷害（不累加）。"
		for event in world.event_log:
			if event.type == "FIELD_TURN" and int(event.payload.battle_id) == int(state.battle.id) and event.payload.turn >= turn - 3:
				log_label.text += "\n\n第 %d 回合：造成 %d / 承受 %d" % [event.payload.turn, event.payload.dealt, event.payload.taken]
				var practice: Dictionary = event.payload.get("skill_practice", {})
				if not practice.is_empty():
					log_label.text += " · " + practice_text(practice)
		add_action("ATTACK", "近身攻擊 · 傷害 %d" % Field.attack_damage(world))
		var firearm := Field.firearm_for(world)
		var ammo_id: String = String(firearm.get("ammo_item_id", "revolver_round"))
		add_action("SHOOT", "射擊 · 傷害 %d · 彈藥 −%d（剩 %d）" % [Field.shot_damage(world), int(firearm.get("ammo_spent", 1)), world.player.item_inventory.quantity(ammo_id)])
		add_action("DEFEND", "架勢防禦 · 減傷 %d，準備反擊" % Field.Enemies.brace_reduction(_display_enemy(), turn))
		add_action("FLEE", "逃跑 · 承受 %d 傷害%s" % [Field.flee_damage(world), "（鐵鎚笨重）" if Field.flee_damage(world) > 1 else ""])
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
	_refresh_history_visibility()

func _show_intent(preview: Dictionary) -> void:
	if intent_label == null:
		return
	intent_label.visible = not preview.is_empty()
	intent_detail_label.visible = not preview.is_empty()
	if preview.is_empty():
		return
	var head := "下一步：%s　%d 傷害" % [String(preview.label_zh), int(preview.damage)]
	if bool(preview.knocks_down):
		head += "（會把你擊倒）"
	intent_label.text = head
	intent_label.add_theme_color_override("font_color", Tokens.CRITICAL if bool(preview.heavy) or bool(preview.knocks_down) else Tokens.AMBER)
	var lines: Array[String] = []
	lines.append("架勢防禦 → 承受 %d%s" % [int(preview.braced_damage), "（仍會倒下）" if bool(preview.knocks_down_braced) else ""])
	if bool(preview.attack_kills):
		lines.append("近身攻擊 %d → 可擊倒它，它不會出手" % int(preview.attack_damage))
	else:
		lines.append("近身攻擊 %d → 它還會出手" % int(preview.attack_damage))
	intent_detail_label.text = "　／　".join(lines)

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
	# Hand-play: "打輸後跑到這邊" - once a road result was confirmed, nothing
	# said it had been a road fight any more, so the screen fell back to the
	# Gray Valley shed with every command refused. A confirmed road result
	# ends the road fight: go back to the journey.
	var confirming_road: bool = String(payload.get("command", "")) == "CONFIRM" and world.field_state.receipt >= 0 \
		and String(world.event_log[world.field_state.receipt].payload.get("source", "field")) == "road"
	var result := engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))
	if result.success and confirming_road:
		busy = false
		world_changed.emit()
		close()
		return
	if result.success:
		if payload.command in ["ATTACK", "SHOOT", "DEFEND", "FLEE"]:
			for i in range(world.event_log.size() - 1, -1, -1):
				var event := world.event_log[i]
				if event.type == "FIELD_TURN":
					var ctx: Dictionary = event.payload.duplicate()
					ctx["enemy_id"] = _display_enemy()
					await stage.animate_turn(payload.command, int(event.payload.dealt), int(event.payload.taken), ctx)
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
