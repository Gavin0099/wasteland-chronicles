extends "res://ui/field_screen.gd"

const Capture = preload("res://simulation/relay_custody.gd")
var last_turn: Dictionary = {}

static func explain(error: String) -> String:
	if error == "PURSUIT_NEED_FIREARM": return "需裝備持有的槍械"
	if error == "PURSUIT_NEED_AMMO": return "缺相容彈藥；回城補給"
	return {"": "", "PURSUIT_BLOCK_EXIT_FIRST": "先封住維修出口", "PURSUIT_REQUIRES_RECORDS": "需到值勤檔案室", "PURSUIT_TARGET_NOT_HERE": "灰鴉目前不在站內", "PURSUIT_ALREADY_CAPTURED": "已活捉，不能重複拘捕", "PURSUIT_ACTIVITY_PENDING": "先完成並確認這次交戰", "PURSUIT_WEAKEN_OR_MELEE": "需本人近戰1，或先削弱至3生命", "PURSUIT_ALREADY_DISARMED": "灰鴉已放下刀", "PURSUIT_DISARM_AND_WEAKEN": "需先繳械，並削弱至3生命", "PURSUIT_NEED_SECOND_ROPE": "缺另一條繩索：退出交戰、回灰谷補買", "PURSUIT_STALE_TURN": "回合已變，請重新選擇", "PURSUIT_STALE_RESULT": "結果已確認或已變", "PURSUIT_PLAYER_DEAD": "旅程已結束"}.get(error, "目前無法執行，請確認交戰與人物狀態")

func _install_desktop_layout(column: VBoxContainer, heading: HBoxContainer, old_body: HBoxContainer, battle_stage: Control, status: Label, history_label: Label, receipts: VBoxContainer, actions: GridContainer, errors: Label, note: Label) -> void:
	super(column, heading, old_body, battle_stage, status, history_label, receipts, actions, errors, note)
	note.text = "制伏保留1生命；致命攻擊／射擊可殺人。活人賞金80，親見死訊30；需回灰谷交差。"
	reduce_motion.custom_minimum_size.y = 40
	history_toggle.custom_minimum_size.y = 40

func _display_enemy() -> String: return "grey_crow"

func _refresh_history_visibility() -> void:
	if history_window != null: history_window.visible = not Capture.state(world).active or history_toggle.button_pressed or error_label.visible

func close() -> void:
	if busy or Capture.pending(world): return
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		save_menu_requested.emit()
		get_viewport().set_input_as_handled()

func add_action(command: String, caption: String) -> void:
	var b: Button = Button.new()
	b.theme_type_variation = "PdaCommand"
	b.custom_minimum_size.y = 40
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	var requested: PlayerIntent = Capture.intent(world, command)
	var error: String = engine.authorize_player_intent(world, requested)
	b.text = caption + ("\n" + explain(error) if error != "" else "")
	b.disabled = error != "" or busy
	b.tooltip_text = explain(error)
	b.pressed.connect(perform.bind(requested.payload))
	actions_box.add_child(b)
	buttons[command] = b

func refresh() -> void:
	for child: Node in actions_box.get_children():
		actions_box.remove_child(child); child.queue_free()
	buttons.clear()
	actions_box.columns = 4
	var s: Dictionary = Capture.state(world)
	heading_label.text = "舊中繼站 / 灰鴉 · 追獵"
	stage.configure("grey_crow", world.player.equipment.equipped_item("main_hand"), false)
	stage.configure_environment("relay")
	stage.configure_support(false)
	stage.configure_captive(s.disarmed)
	stage.refresh(world.player.field_kit.equipped, true)
	stage.present_outcome("VICTORY" if s.outcome == "TARGET_DEAD" else s.outcome)
	_set_bar(player_bar, "你 · " + world.npc_registry.get_npc(world.player.npc_id).name, world.player.field_kit.hp, 12)
	_set_bar(enemy_bar, "灰鴉 · 已繳械" if s.disarmed else "灰鴉 · 持刀", s.target_hp, 8)
	status_label.text = "防護%d · 繩索%d\n第%d回合 · %s" % [Field.Gear.protection(world.player), world.player.item_inventory.quantity("rope"), s.turn, "已架勢：下一擊＋2" if s.prepared else "尚未架勢"]
	intent_label.text = "反擊%d傷害 · 不推進世界時間" % (1 if s.disarmed else 3)
	intent_detail_label.text = "綁縛不受反擊；退出交戰承受最多1傷害。"
	battle_map_label.text = "活捉後可交灰谷看管，或回檔案室放人。"
	growth_notice_label.hide()
	receipt_items.hide()
	close_button.text = "返回探索"
	close_button.disabled = Capture.pending(world) or busy
	close_button.tooltip_text = "先退出交戰／活捉，並確認結果。" if close_button.disabled else ""
	if s.receipt >= 0:
		status_label.text = "結果待確認 · 防護%d · 繩索%d" % [Field.Gear.protection(world.player), world.player.item_inventory.quantity("rope")]
		intent_label.text = {"CAPTURED": "已活捉 · 等待確認", "TARGET_DEAD": "灰鴉已死亡 · 等待確認", "ESCAPED": "已退出交戰 · 等待確認", "DEAD": "旅程已結束 · 等待確認"}[s.outcome]
		intent_detail_label.text = Capture.describe(world) if s.outcome == "CAPTURED" else "確認後返回探索或查看旅程結束。"
		log_label.text = {"CAPTURED": Capture.describe(world) + "\n繩索−1，綁縛時沒有反擊。", "TARGET_DEAD": Capture.describe(world) + "\n最後一擊沒有受到反擊；沒有直接取得賞金。", "ESCAPED": "你退出交戰；灰鴉仍在，傷勢與繳械狀態保留。可回灰谷補買綁縛用的繩索。", "DEAD": "你在追獵灰鴉時倒下，旅程結束；他仍活著，沒有被捕。"}[s.outcome]
		add_action("CONFIRM_CAPTURE", "確認結果並返回")
	else:
		log_label.text = "堵退路只是準備；活捉需要繳械、削弱至3生命，再用另一條繩索綁縛。"
		var damage: int = min(int(s.target_hp) - 1, Field.attack_damage(world) + (2 if s.prepared else 0))
		add_action("SUBDUE_TARGET", "非致命制伏 · 傷害%d" % damage)
		add_action("LETHAL_TARGET", "致命攻擊 · 傷害%d" % min(int(s.target_hp), Field.attack_damage(world) + (2 if s.prepared else 0)))
		var gun: Dictionary = Field.firearm_for(world)
		var ammo: int = world.player.item_inventory.quantity(gun.get("ammo_item_id", ""))
		add_action("SHOOT_TARGET", "致命射擊 · %d傷害\n彈藥−1（剩%d）" % [min(int(s.target_hp), Capture.shot_damage(world, s) + (2 if s.prepared else 0)), ammo])
		add_action("DISARM_TARGET", "繳械 · 反擊降至1")
		add_action("BRACE_TARGET", "架勢 · 減傷3／下一擊＋2")
		add_action("BIND_TARGET", "綁縛活捉 · 繩索−1")
		add_action("RETREAT_TARGET", "退出交戰 · 最多承受1")
	if not last_turn.is_empty():
		log_label.text += "\n上次：制伏%d · 承受%d · 目標剩%d生命" % [last_turn.dealt, last_turn.taken, last_turn.target_hp]
		if not last_turn.practice.is_empty(): growth_notice_label.text = practice_text(last_turn.practice); growth_notice_label.show()
	_refresh_history_visibility()

func perform(payload: Dictionary) -> void:
	if busy: return
	busy = true
	close_button.disabled = true
	for b: Button in buttons.values(): b.disabled = true
	var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload))
	if result.success:
		world_changed.emit()
		if payload.command == "CONFIRM_CAPTURE":
			busy = false; close(); return
		var s: Dictionary = Capture.state(world)
		stage.configure_captive(s.disarmed)
		for i: int in range(world.event_log.size() - 1, -1, -1):
			var event: EventRecord = world.event_log[i]
			if event.type != "PURSUIT_TURN": continue
			last_turn = event.payload.duplicate(true)
			var ctx: Dictionary = {"enemy_id": "grey_crow", "turn": last_turn.turn, "is_heavy": false, "next_heavy": false, "outcome": "VICTORY" if s.outcome == "TARGET_DEAD" else s.outcome}
			var animation_command: String = {"SUBDUE_TARGET": "ATTACK", "LETHAL_TARGET": "ATTACK", "SHOOT_TARGET": "SHOOT", "RETREAT_TARGET": "FLEE", "BRACE_TARGET": "DEFEND", "DISARM_TARGET": "DEFEND", "BIND_TARGET": "BIND"}[payload.command]
			await stage.animate_turn(animation_command, last_turn.dealt, last_turn.taken, ctx)
			if not is_instance_valid(self) or not is_inside_tree(): return
			break
		error_label.hide()
	else:
		error_label.text = explain(result.error); error_label.show()
	busy = false
	refresh()
	for b: Button in buttons.values():
		if not b.disabled: b.grab_focus(); break
