extends "res://tests/test_dungeon_entry.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/dun1")
var captures: int = 0

func _init() -> void:
	store = Store.new("user://tests/dun1-renderer/journey.json")
	call_deferred("capture_dungeon")

func frame(label: String, main: Node) -> void:
	var before: String = main.world.to_canonical_json()
	for tick: int in range(6): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK, "actual Vulkan image saved")
	captures += 1
	check(main.world.to_canonical_json() == before and engine.validate_invariants(main.world) == "", "actual rendered projection is read-only with global invariants")
	var screen: Control = main.shell.find_child("DungeonScreen", false, false) if main.shell != null else null
	if screen != null:
		for command_button: Button in [screen.interact_button, screen.guide_button, find_command(screen, "存讀檔")]:
			var bounds: Rect2 = command_button.get_global_rect()
			check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y and bounds.size.y >= 40, "actual commands fit viewport and touch height")
		check(screen.view.walkable(screen.view.actor_position) and screen.view.size.y >= 340, "actual actor is on playable floor and arena gets sufficient height")

func click_ground(screen: Control, point: Vector2) -> void:
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = screen.view.global_position + screen.view.canvas_origin() + point * screen.view.canvas_scale()
	Input.parse_input_event(click)
	await frames()
	click.pressed = false
	Input.parse_input_event(click)
	for frame_index: int in range(480):
		if screen.view.actor_position.distance_to(point) < 6: break
		await process_frame
	check(screen.view.actor_position.distance_to(point) < 6, "actual pointer input and process loop walk to door")

func press_key(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func capture_dungeon() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var fixture: WorldState = PlayableWorld.create_world()
		check(engine.commit_character_creation(fixture, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "背著工具再次尋找地下水源的旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "actual long-name creation")
		check(store.save_game(fixture).success, "actual renderer seed slot")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		await frame("town_waterworks_command", main)
		find_command(main.shell, "水廠").pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("DungeonScreen", false, false)
		await frame("entrance", main)
		var before: String = main.world.to_canonical_json()
		await click_ground(screen, Vector2(500, 132))
		check(main.world.to_canonical_json() == before and not screen.interact_button.disabled, "real mouse movement enables doorway without world mutations")
		await frame("entrance_door_ready", main)
		screen.interact_button.grab_focus()
		check(screen.interact_button.has_focus(), "real visible keyboard command focus")
		await frame("door_keyboard_focus", main)
		await press_key(KEY_ENTER)
		await frames()
		check(Dungeon.state(main.world).room_id == "foyer", "actual focused Enter key enters foyer exactly once")
		await frame("foyer", main)
		screen.view.set_process(false)
		screen.view.actor_position = Vector2(500, 305)
		screen.view.move_actor(Vector2.RIGHT, 0.04)
		await frame("walk_step_a", main)
		screen.view.move_actor(Vector2.RIGHT, 0.16)
		await frame("walk_step_b", main)
		screen.reduce_motion.button_pressed = true
		screen.view.move_actor(Vector2.LEFT, 0.04)
		await frame("reduced_motion_left", main)
		screen.view.set_process(true)
		find_command(screen, "存讀檔").pressed.emit()
		await frames()
		screen.view.move_actor(Vector2.RIGHT, 0.08)
		check(not screen.view.enabled, "actual save window prevents walking")
		main.save_dialog.save_button.pressed.emit()
		await frame("foyer_saved", main)
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		await frame("continue_foyer_start", main)
		main.save_dialog.load_button.pressed.emit()
		await frames()
		await frame("continued_foyer", main)
		screen = main.shell.find_child("DungeonScreen", false, false)
		await click_ground(screen, Vector2(500, 395))
		await press_key(KEY_E)
		await frames()
		check(Dungeon.state(main.world).room_id == "entrance", "actual arena E key backtracks exactly once")
		await frame("backtrack_north_door", main)
		await click_ground(screen, Vector2(500, 395))
		screen.interact_button.pressed.emit()
		await frames()
		check(not Dungeon.state(main.world).active, "actual rendered stairs return town")
		await frame("returned_town", main)
		main.queue_free()
		await frames()
		clear_slot()
	print("DUN-1 Vulkan: %d screenshots, %d assertions, %d failures" % [captures, assertions, failures])
	quit(0 if failures == 0 else 1)
