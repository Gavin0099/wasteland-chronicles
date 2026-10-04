extends "res://tests/test_dungeon_layout.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/dun2")
var captures: int = 0

func _init() -> void:
	store = Store.new("user://tests/dun2-renderer/journey.json")
	call_deferred("capture_layout")

func capture_frame(label: String, main: Node) -> void:
	var before: String = main.world.to_canonical_json()
	await frames()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK, "real Vulkan screenshot saved")
	captures += 1
	check(main.world.to_canonical_json() == before and engine.validate_invariants(main.world) == "", "rendering remains read-only with global invariants")
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	for command_button: Control in [screen.route_choice, screen.guide_button, screen.interact_button, screen.map_button]:
		var bounds: Rect2 = command_button.get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y and bounds.size.y >= 40, "real exploration commands fit viewport and touch size")
	check(screen.view.walkable(screen.view.actor_position) and screen.view.size.y >= 340, "actual restored actor and playable arena remain usable")
	if is_instance_valid(screen.map_dialog):
		var bounds: Rect2i = Rect2i(screen.map_dialog.position, screen.map_dialog.size)
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y, "actual map dialog fits required viewport")
		check(screen.map_dialog.get_ok_button().size.y >= 40, "actual map return command meets shared touch height")

func key_input(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func real_door(screen: Control, destination: String) -> void:
	var before: String = screen.world.to_canonical_json()
	var selection: int = -1
	for index: int in range(screen.view.doors.size()):
		if screen.view.doors[index].get("room_id", "") == destination: selection = index
	check(selection >= 0, "actual requested door exists")
	if selection < 0: return
	screen.route_choice.select(selection)
	screen.route_choice.item_selected.emit(selection)
	screen.guide_button.pressed.emit()
	for tick: int in range(480):
		if screen.view.target_position.x < 0: break
		await process_frame
	check(screen.world.to_canonical_json() == before and not screen.interact_button.disabled, "real process guide arrives without world mutation")
	await key_input(KEY_E)
	check(Dungeon.state(screen.world).room_id == destination, "real E interaction enters selected room")

func capture_layout() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var fixture: WorldState = fresh_towns("settlement:gray_valley")
		enter_legacy_graph(fixture) # Historical DUN-2 topology/checkpoint renderer.
		check(store.save_game(fixture).success, "renderer real legacy slot")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("DungeonScreen", false, false)
		await capture_frame("entrance", main)
		await key_input(KEY_M)
		check(is_instance_valid(screen.map_dialog) and screen.map_dialog.visible and not screen.view.enabled, "actual M opens paused discovery map")
		await capture_frame("map_initial", main)
		await key_input(KEY_ESCAPE)
		check(screen.view.enabled and screen.view.has_focus(), "actual Escape closes map and restores walking")
		for destination: String in ["foyer", "parts_store", "foyer", "maintenance", "pump", "polluted_store", "pump", "guard", "pump", "control"]:
			await real_door(screen, destination)
			if destination in ["foyer", "pump"] and Dungeon.state(main.world).visited.size() > 5: continue
			await capture_frame("foyer_after_store" if destination == "foyer" and Dungeon.state(main.world).visited.size() == 3 else destination, main)
			if destination == "foyer" and Dungeon.state(main.world).visited.size() == 2:
				await key_input(KEY_M)
				await capture_frame("map_forks", main)
				await key_input(KEY_ESCAPE)
		await key_input(KEY_M)
		await capture_frame("map_all_closed_return", main)
		await key_input(KEY_ESCAPE)
		screen.route_choice.select(1)
		screen.guide_button.pressed.emit()
		for tick: int in range(480):
			if screen.view.target_position.x < 0: break
			await process_frame
		await capture_frame("control_latch_ready", main)
		await key_input(KEY_E)
		check(Dungeon.state(main.world).shortcut_open, "real E opens control latch")
		await capture_frame("control_return_open", main)
		await key_input(KEY_M)
		await capture_frame("map_opened_return", main)
		await key_input(KEY_ESCAPE)
		await real_door(screen, "entrance")
		await capture_frame("shortcut_entrance", main)
		await real_door(screen, "control")
		find_command(screen, "存讀檔").pressed.emit()
		await frames()
		main.save_dialog.save_button.pressed.emit()
		var before: String = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		check(main.world.to_canonical_json() == before, "actual restart restores exact deep checkpoint/discovery/latch")
		await capture_frame("continued_control", main)
		main.queue_free()
		await frames()
		clear_slot()
	print("DUN-2 Vulkan: %d screenshots, %d assertions, %d failures" % [captures, assertions, failures])
	quit(0 if failures == 0 else 1)
