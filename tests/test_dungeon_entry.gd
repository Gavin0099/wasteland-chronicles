extends "res://tests/test_player_save_load.gd"

const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const DungeonScreen = preload("res://ui/dungeon_screen.gd")
const RoomView = preload("res://ui/components/dungeon_room_view.gd")

func _init() -> void:
	store = Store.new("user://tests/dun1/journey.json")
	call_deferred("run_dungeon")

func dungeon_intent(world: WorldState, command_name: String, from_room: String = "", room: String = "") -> PlayerIntent:
	var payload: Dictionary = {"command": command_name}
	if command_name == "MOVE":
		payload.from_room_id = from_room
		payload.room_id = room
	return PlayerIntent.create_dungeon_action(world.player.npc_id, payload)

func rejected(world: WorldState, intent: PlayerIntent, label: String) -> void:
	var before: String = world.to_canonical_json()
	var result: Dictionary = engine.commit_player_intent(world, intent)
	check(not result.success and world.to_canonical_json() == before, label + " atomic refusal")
	check(engine.validate_invariants(world) == "", label + " global invariants")

func dungeon_replay() -> void:
	clear_slot()
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var original: String = world.to_canonical_json()
	check(not Dungeon.state(world).active and Dungeon.validate_world(world) == "", "legacy world has no dungeon state or extra snapshot fields")
	var twin: WorldState = disk_copy(world, "pre-dungeon legacy snapshot")
	var baseline: Dictionary = world.to_dict()
	var emitted: Array[EventRecord] = []
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER"), emitted).success, "real entrance intent")
	check(engine.commit_player_intent(twin, dungeon_intent(twin, "ENTER")).success, "twin real entrance intent")
	check(emitted.size() == 1 and emitted[0].type == "DUNGEON_ENTERED", "one committed entrance fact in returned events")
	parity(world, twin, "entry checkpoint")
	check(Dungeon.state(world).room_id == "entrance", "reviewed entry fixture is entrance")
	check(world.current_day == 0 and world.player.money == baseline.player.money and world.player.inventory.to_dict() == baseline.player.inventory, "entry spends no day or supplies in DUN-1")
	check(world.total_initial_population == baseline.total_initial_population and world.to_dict().npc_life_state_registry == baseline.npc_life_state_registry, "local exploration does not create a population container or lifecycle")
	twin = disk_copy(world, "inside entrance actual disk")
	rejected(world, dungeon_intent(world, "ENTER"), "duplicate entry")
	for payload: Dictionary in [{}, {"command": 7}, {"command": "BREAK"}, {"command": "ENTER", "dungeon_id": "other"}, {"command": "MOVE", "from_room_id": "entrance", "room_id": "unknown"}, {"command": "MOVE", "from_room_id": "foyer", "room_id": "entrance"}, {"command": "MOVE", "from_room_id": "entrance", "room_id": 1}, {"command": "MOVE", "from_room_id": "entrance", "room_id": "foyer", "reward": 99}]:
		rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload), "invalid/forged intent")
	rejected(world, PlayerIntent.create_dungeon_action(&"npc:unknown", {"command": "EXIT"}), "wrong actor")
	for intent: PlayerIntent in [PlayerIntent.create_wait(world.player.npc_id), PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"), PlayerIntent.create_buy(world.player.npc_id, &"water", 1), PlayerIntent.create_field_action(world.player.npc_id, {"command": "REST"})]:
		rejected(world, intent, "unrelated town/travel/field activity")
	var before: String = world.to_canonical_json()
	check(not engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success and world.to_canonical_json() == before, "direct journey entry cannot bypass dungeon lock")
	check(not Field.commit(world, engine, {"command": "REST"}).success and world.to_canonical_json() == before, "direct field entry cannot bypass dungeon lock")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "entrance", "foyer"), "real front-room door")
	check(Dungeon.state(world).room_id == "foyer" and Dungeon.state(world).from_room_id == "entrance", "reviewed foyer checkpoint and source doorway")
	twin = disk_copy(world, "foyer actual disk")
	check(SaveDialog.describe(twin).contains("設備前廳"), "save slot names actual dungeon room")
	rejected(world, dungeon_intent(world, "EXIT"), "exit requires actual entrance")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "foyer", "entrance"), "real backtrack")
	twin = disk_copy(world, "backtracked entrance actual disk")
	pair_intent(world, twin, dungeon_intent(world, "EXIT"), "actual stairs to town")
	check(not Dungeon.state(world).active and world.current_day == 0, "exit clears derived local context without time")
	rejected(world, dungeon_intent(world, "EXIT"), "duplicate exit")
	check(world.to_canonical_json() != original and world.event_log.size() == int(baseline.event_count) + 4, "exact four durable facts, no presentation records")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"water", 1), "real town trading restored after exit")
	pair_intent(world, twin, dungeon_intent(world, "ENTER"), "actual second visit")
	pair_intent(world, twin, dungeon_intent(world, "EXIT"), "second visit exit")
	var elsewhere: WorldState = fresh_towns("settlement:new_hope")
	rejected(elsewhere, dungeon_intent(elsewhere, "ENTER"), "wrong settlement")
	var travelling: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(travelling, PlayerIntent.create_travel(travelling.player.npc_id, &"settlement:new_hope")).success, "real active road fixture")
	rejected(travelling, dungeon_intent(travelling, "ENTER"), "travelling/road encounter cannot enter")
	var fighting: WorldState = field_world()
	rejected(fighting, dungeon_intent(fighting, "ENTER"), "active field battle cannot enter")
	clear_slot()

func forged_history() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var legacy: String = world.to_canonical_json()
	check(WorldState.from_json_checked(legacy).world.to_canonical_json() == legacy, "old saves remain byte-identical")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "valid independent ledger seed")
	var seeds: Array[Dictionary] = []
	for mode: int in range(11):
		var data: Dictionary = world.to_dict().duplicate(true)
		var event: Dictionary = data.events.back()
		match mode:
			0: event.actor_id = "npc:unknown"
			1: event.target_id = "dungeon:other"
			2: event.payload.dungeon_id = "dungeon:other"
			3: event.payload.room_id = "foyer"
			4: event.payload.room_id = 1
			5: event.payload.reward = 10
			6: event.day = world.current_day + 1
			7: event.type = "DUNGEON_UNKNOWN"
			8:
				data.events.append(event.duplicate(true))
				data.event_count = data.events.size()
			9:
				event.type = "DUNGEON_ROOM_ENTERED"
				event.payload.from_room_id = "entrance"
				event.payload.room_id = "foyer"
			10: data.erase("player")
		seeds.append(data)
	for data: Dictionary in seeds:
		var checked: Dictionary = WorldState.from_json_checked(JSON.stringify(data))
		check(not checked.success and checked.world == null, "malformed dungeon history fails checked persistence")
		var raw_world: WorldState = WorldState.from_dict_unchecked(data)
		for event: Dictionary in data.events:
			raw_world.event_log.append(EventRecord.from_dict(event))
		check(Dungeon.validate_world(raw_world) != "", "same malformed fixture executes live dungeon validator")
	check(engine.validate_invariants(world) == "", "negative load tests preserve valid live world")

func local_movement() -> void:
	var view: Control = RoomView.new()
	root.add_child(view)
	view.setup({"room_id": "entrance", "from_room_id": "outside"})
	check(view.actor_position == Vector2(500, 348) and view.walkable(view.actor_position), "authored safe entrance spawn")
	var before: Vector2 = view.actor_position
	view.move_actor(Vector2.RIGHT, 0.05)
	check(view.actor_position == before + Vector2(9, 0) and view.current_pose == "step_a", "real movement and stride frame")
	view.actor_position = Vector2(110, 300)
	for step: int in range(30): view.move_actor(Vector2.LEFT, 0.08)
	check(view.actor_position.x >= 96, "outer wall blocks movement")
	view.actor_position = Vector2(350, 200)
	for step: int in range(30): view.move_actor(Vector2.LEFT, 0.08)
	check(view.actor_position.x >= 320, "pump obstacle blocks player feet")
	view.enabled = false
	before = view.actor_position
	view.move_actor(Vector2.RIGHT, 0.08)
	check(view.actor_position == before, "modal pause blocks movement")
	view.enabled = true
	view.reduced_motion = true
	view.move_actor(Vector2.RIGHT, 0.08)
	check(view.actor_position != before and view.current_pose == "recover", "reduced animation preserves movement")
	view.setup({"room_id": "entrance", "from_room_id": "foyer"})
	check(view.actor_position == Vector2(500, 150) and view.nearest_door().room_id == "foyer", "backtrack respawns inside north door")
	view.setup({"room_id": "foyer", "from_room_id": "entrance"})
	check(view.actor_position == Vector2(500, 348) and view.walkable(view.actor_position), "safe foyer checkpoint")
	check(view.floor_texture != null, "production floor resource loaded")
	check(view.pump_texture != null, "production pump resource loaded")
	view.size = Vector2(1200, 500)
	check(view.actor_canvas_position() == Vector2(600, 348), "independent wide-canvas fixture projects feet onto doorway coordinate space")
	view.size = Vector2(1000, 600)
	check(view.actor_canvas_position() == Vector2(500, 398), "independent tall-canvas fixture preserves centered room transform")
	view.queue_free()

func walk_to_door(screen: Control, point: Vector2) -> void:
	screen.view.walk_to(point)
	for frame_index: int in range(240):
		if screen.view.actor_position.distance_to(point) < 6:
			break
		screen.view.move_actor(screen.view.actor_position.direction_to(point), 0.04)
	check(screen.view.actor_position.distance_to(point) < 6, "actual movement reaches doorway")
	screen.refresh_interaction()

func dungeon_ui() -> void:
	clear_slot()
	var fixture: WorldState = fresh_towns("settlement:gray_valley")
	check(store.save_game(fixture).success, "actual initial UI slot")
	var main: Node = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	find_command(main.shell, "水廠").pressed.emit()
	await frames()
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and Dungeon.state(main.world).room_id == "entrance", "real town toolbar opens actual exploration")
	var before: String = main.world.to_canonical_json()
	for movement_key: Key in [KEY_W, KEY_UP]:
		var movement: InputEventKey = InputEventKey.new()
		movement.keycode = movement_key
		movement.physical_keycode = movement_key
		movement.pressed = true
		var position_before: Vector2 = screen.view.actor_position
		Input.parse_input_event(movement)
		await create_timer(0.08).timeout
		movement.pressed = false
		Input.parse_input_event(movement)
		await frames()
		check(screen.view.actor_position.y < position_before.y and screen.view.has_focus(), "actual WASD/arrow input moves while retaining arena focus")
		check(main.world.to_canonical_json() == before, "actual keyboard input cannot mutate world/time")
	screen.view.actor_position = Vector2(500, 260)
	screen.refresh_interaction()
	check(screen.interact_button.disabled, "far doorway interaction is visibly locked")
	walk_to_door(screen, Vector2(500, 132))
	check(main.world.to_canonical_json() == before, "in-room walking leaves world and time unchanged")
	screen.interact_button.pressed.emit()
	await frames()
	check(Dungeon.state(main.world).room_id == "foyer" and screen.title_label.text.contains("設備前廳"), "actual door button commits new room")
	before = main.world.to_canonical_json()
	find_command(screen, "存讀檔").pressed.emit()
	await frames()
	check(not screen.view.enabled and main.world.to_canonical_json() == before, "save menu pauses actual exploration without ticking")
	main.save_dialog.save_button.pressed.emit()
	check(FileAccess.get_file_as_string(store.path) == before, "UI actual disk save keeps room checkpoint")
	main.save_dialog.get_ok_button().pressed.emit()
	await frames()
	check(screen.view.enabled and screen.view.has_focus(), "closing save restores movement focus")
	walk_to_door(screen, Vector2(500, 395))
	screen.interact_button.pressed.emit()
	await frames()
	check(Dungeon.state(main.world).room_id == "entrance", "actual backtracking button")
	find_command(screen, "存讀檔").pressed.emit()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	main.save_dialog.confirmation.get_ok_button().pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == before, "actual confirmed load restores exact foyer world")
	screen = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and screen.view.room_id == "foyer" and screen.view.actor_position == Vector2(500, 348), "loaded exploration automatically opens at safe room entry")
	main.queue_free()
	await frames()
	main = new_main()
	await frames()
	check(main.save_dialog.summary.text.contains("設備前廳"), "new process startup names saved room")
	main.save_dialog.load_button.pressed.emit()
	await frames()
	screen = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and main.world.to_canonical_json() == before, "restart Continue opens exact committed dungeon")
	walk_to_door(screen, Vector2(500, 395))
	screen.interact_button.pressed.emit()
	await frames()
	walk_to_door(screen, Vector2(500, 395))
	screen.interact_button.pressed.emit()
	await frames()
	check(not Dungeon.state(main.world).active and main.shell.find_child("DungeonScreen", false, false) == null, "real stairs close exploration and return town")
	check(engine.validate_invariants(main.world) == "", "UI exit preserves global invariants")
	main.queue_free()
	await frames()
	clear_slot()

func run_dungeon() -> void:
	dungeon_replay()
	forged_history()
	local_movement()
	await dungeon_ui()
	print("DUN-1: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
