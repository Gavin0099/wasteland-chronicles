extends SceneTree
const Screen = preload("res://ui/field_screen.gd")
var failed := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.creation.name_input.text = "UI Fighter"
	main.creation.submit()
	main.creation.enter_button.pressed.emit()
	main.engine.commit_player_intent(main.world, PlayerIntent.create_buy(main.world.player.npc_id, &"scrap", 3))
	var before: String = main.world.to_canonical_json()
	main.shell._show_field()
	var ui = main.shell.get_node("FieldScreen")
	check(before == main.world.to_canonical_json(), "opening field screen cannot start battle or change state")
	await ui.perform({"command": "CRAFT"})
	await ui.perform({"command": "EQUIP"})
	check(main.world.player.field_kit.equipped and ui.stage.weapon.visible, "equipped item shown in actual stage")
	await ui.perform({"command": "START"})
	ui.close()
	check(not ui.is_queued_for_deletion(), "cannot close an unresolved battle")
	var twin: WorldState = main.world.duplicate_state()
	var second := Screen.new()
	root.add_child(second)
	second.setup(twin, main.engine)
	second.reduce_motion.button_pressed = true
	var intent: Dictionary = ui.payload_for("ATTACK")
	ui.buttons.ATTACK.pressed.emit()
	check(ui.busy and ui.buttons.DEFEND.disabled and ui.close_button.disabled, "animation locks duplicate input")
	var after_commit: String = main.world.to_canonical_json()
	await ui.perform(intent)
	check(after_commit == main.world.to_canonical_json(), "double click during animation cannot replay damage")
	var loaded := WorldState.from_json_checked(after_commit)
	check(loaded.success and loaded.world.to_canonical_json() == after_commit, "saving during animation persists committed state")
	await second.perform(second.payload_for("ATTACK"))
	await create_timer(1.2).timeout
	check(not ui.busy and main.world.field_state.battle.turn == 2, "animation completes to next turn")
	check(main.world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "normal/reduced motion dual-track world SHA")
	check(main.engine.validate_invariants(main.world) == "", "UI action preserves world invariants")
	ui.reduce_motion.button_pressed = true
	await ui.perform(ui.payload_for("DEFEND"))
	await ui.perform(ui.payload_for("ATTACK"))
	check(main.world.field_state.receipt >= 0 and ui.buttons.has("CONFIRM") and not ui.stage.enemy.visible, "victory receipt and enemy removal")
	await ui.perform(ui.payload_for("CONFIRM"))
	await ui.perform({"command": "OPEN"})
	check(ui.log_label.text.contains("水 4") and ui.log_label.text.contains("食物 2"), "actual cache receipt visible")
	await ui.perform(ui.payload_for("CONFIRM"))
	check(ui.buttons.OPEN.disabled, "one-time loot button disabled")
	ui.close()
	check(ui.is_queued_for_deletion(), "can close after confirming result")
	second.queue_free()
	main.queue_free()
	await process_frame
	print("Field UI gates: ", "PASS" if failed == 0 else "FAIL")
	quit(0 if failed == 0 else 1)
