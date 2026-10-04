extends "res://tests/test_player_save_load.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/save1")
var captures: int = 0

func _init() -> void:
	# Separate slot from regression runs and the player's actual save.
	store = Store.new("user://tests/save1-renderer/journey.json")
	call_deferred("capture")

func frame(label: String, main: Node) -> void:
	var before: String = main.world.to_canonical_json()
	for tick: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK, "actual Vulkan screenshot saved")
	captures += 1
	check(main.world.to_canonical_json() == before, "render/menu does not tick or mutate world")
	check(engine.validate_invariants(main.world) == "", "rendered world global invariants")
	if is_instance_valid(main.save_dialog):
		check(main.save_dialog.size.x <= root.size.x and main.save_dialog.size.y <= root.size.y, "save window fits actual viewport")
		for button: Button in [main.save_dialog.get_ok_button(), main.save_dialog.load_button]:
			check(button.get_global_rect().end.y <= main.save_dialog.size.y, "commands remain inside save window")

func escape() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await frames()

func await_command(screen: Control) -> void:
	for tick: int in range(240):
		if not screen.busy: break
		await process_frame
	check(not screen.busy, "real animation completes before next command")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var main: Node = new_main()
		await frame("empty_start", main)
		main.save_dialog.get_ok_button().pressed.emit()
		await frames()
		main.creation.name_input.text = "風沙裡尋找回家路的荒原旅人"
		main.creation.select_background("MECHANIC")
		check(main.creation.submit().success, "actual long-name creation")
		main.creation.enter_button.pressed.emit()
		await frames()
		await frame("map_toolbar", main)
		var original: String = main.world.to_canonical_json()
		find_command(main.shell, "存讀檔").pressed.emit()
		await frame("empty_in_game", main)
		main.save_dialog.save_button.pressed.emit()
		await frame("saved_in_game", main)
		check(FileAccess.get_file_as_string(store.path) == original, "actual menu writes exact world")
		check(DirAccess.make_dir_absolute(store.path + ".tmp") == OK, "actual rendered save failure fixture")
		main.save_dialog.save_button.pressed.emit()
		await frame("write_failure_keeps_slot", main)
		check(FileAccess.get_file_as_string(store.path) == original, "failed rendered save retains old exact slot")
		check(DirAccess.remove_absolute(store.path + ".tmp") == OK, "owned renderer staging fixture removed")
		await escape()
		check(not is_instance_valid(main.save_dialog) and main.world.to_canonical_json() == original, "actual Escape closes without mutation")
		check(engine.commit_player_intent(main.world, PlayerIntent.create_wait(main.world.player.npc_id)).success, "real unsaved day")
		main.shell.refresh_ui()
		find_command(main.shell, "存讀檔").pressed.emit()
		main.save_dialog.load_button.pressed.emit()
		await frame("load_confirmation", main)
		check(main.save_dialog.confirmation.get_cancel_button().has_focus(), "confirmation safe keyboard focus")
		var unsaved: String = main.world.to_canonical_json()
		write_raw("{")
		main.save_dialog.confirmation.get_ok_button().pressed.emit()
		await frames()
		await frame("corrupt_load_keeps_progress", main)
		check(main.world.to_canonical_json() == unsaved, "failed load preserves actual current day")
		write_raw(original)
		main._request_load()
		await frames()
		main.save_dialog.confirmation.get_ok_button().pressed.emit()
		await frames()
		check(main.world.to_canonical_json() == original, "actual confirmed load restores original progress")
		main.queue_free()
		await frames()
		check(DirAccess.rename_absolute(store.path, store.path + ".bak") == OK, "actual renderer interrupted-replacement fixture")
		main = new_main()
		await frame("recovered_start", main)
		main.save_dialog.load_button.pressed.emit()
		await frames()
		check(main.world.to_canonical_json() == original, "recovered startup Continue exact snapshot")
		main.queue_free()
		await frames()
		var battle: WorldState = field_world()
		check(store.save_game(battle).success, "real turn-two slot")
		main = new_main()
		await frame("battle_continue_start", main)
		main.save_dialog.load_button.pressed.emit()
		await frames()
		await frame("continued_battle", main)
		check(main.world.to_canonical_json() == battle.to_canonical_json(), "real Continue preserves battle identity and turn")
		var screen: Control = main.shell.get_node("FieldScreen")
		find_command(screen, "存讀檔").pressed.emit()
		await frame("battle_save_menu", main)
		main.save_dialog.save_button.pressed.emit()
		await escape()
		# Real UI combat buttons, reduced motion so frame timing cannot gate input.
		screen.reduce_motion.button_pressed = true
		screen.buttons.DEFEND.pressed.emit()
		await await_command(screen)
		screen.buttons.ATTACK.pressed.emit()
		await await_command(screen)
		check(main.world.field_state.receipt >= 0, "real UI battle produces unconfirmed victory")
		find_command(screen, "存讀檔").pressed.emit()
		main.save_dialog.save_button.pressed.emit()
		await frame("victory_saved_menu", main)
		var receipt_world: String = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		var road: WorldState = fresh_towns("settlement:gray_valley")
		check(engine.commit_player_intent(road, PlayerIntent.create_travel(road.player.npc_id, &"settlement:new_hope")).success and road.active_encounter != null, "real renderer road interruption")
		var choice: StringName = &"LEAVE"
		match road.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		check(engine.commit_player_intent(road, PlayerIntent.create_resolve_encounter(road.player.npc_id, choice)).success and road.pending_encounter_result >= 0, "real road result fixture")
		check(store.save_game(road).success, "road result actual disk slot")
		main = new_main()
		await frame("road_result_continue_start", main)
		main.save_dialog.load_button.pressed.emit()
		await frames()
		await frame("continued_road_result", main)
		check(main.world.to_canonical_json() == road.to_canonical_json(), "road receipt remains unconfirmed after Continue")
		main.queue_free()
		await frames()
		write_raw(receipt_world)
		main = new_main()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		await frame("continued_victory", main)
		check(main.world.to_canonical_json() == receipt_world, "restart does not acknowledge/reward victory twice")
		main.queue_free()
		await frames()
		write_raw("{")
		main = new_main()
		await frame("corrupt_start", main)
		check(main.save_dialog.load_button.disabled, "corrupt slot cannot Continue")
		main.queue_free()
		await frames()
		clear_slot()
	print("Save renderer: captures=%d assertions=%d failures=%d output=%s" % [captures, assertions, failures, output_dir])
	quit(1 if failures > 0 else 0)
