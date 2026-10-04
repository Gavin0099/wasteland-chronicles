extends "res://tests/test_dungeon_entry.gd"

const Layout = preload("res://ui/components/dungeon_room_layout.gd")
const DungeonMap = preload("res://ui/components/dungeon_map_view.gd")
# Reviewed domain fixture; do not derive expected connectivity from production.
const EXPECTED: Dictionary = {
	"entrance": ["foyer"], "foyer": ["entrance", "guard", "maintenance", "parts_store"],
	"guard": ["foyer", "pump"], "maintenance": ["foyer", "pump"],
	"pump": ["guard", "maintenance", "control", "polluted_store"],
	"control": ["pump"], "parts_store": ["foyer"], "polluted_store": ["pump"]
}

func _init() -> void:
	store = Store.new("user://tests/dun2/journey.json")
	call_deferred("run_layout")

func layout_replay() -> void:
	clear_slot()
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var baseline: Dictionary = world.to_dict().duplicate(true)
	var twin: WorldState = disk_copy(world, "legacy town slot")
	check(Dungeon.ROOMS.size() == 8, "exact eight reviewed rooms")
	for source: String in EXPECTED:
		for destination: String in EXPECTED:
			check(Dungeon.adjacent(source, destination) == (destination in EXPECTED[source]), "independent closed-passage fixture " + source + "/" + destination)
	pair_intent(world, twin, dungeon_intent(world, "ENTER"), "waterworks arrival")
	var legacy_checkpoint: String = world.to_canonical_json()
	check(WorldState.from_json_checked(legacy_checkpoint).world.to_canonical_json() == legacy_checkpoint and world.to_dict().keys() == baseline.keys(), "DUN-1 entry facts still round-trip byte-identically without new snapshot fields")
	rejected(world, dungeon_intent(world, "MOVE", "entrance", "control"), "closed entrance shortcut")
	rejected(world, dungeon_intent(world, "OPEN_SHORTCUT"), "shortcut outside control")
	var first_map: Dictionary = DungeonMap.project(Dungeon.state(world))
	check(first_map.rooms.keys() == ["entrance", "foyer"] and first_map.rooms.foyer.label == "未探索", "initial map reveals only visited entrance and its unknown frontier")
	check(not first_map.rooms.has("control") and first_map.edges.size() == 1, "no deep topology or shortcut knowledge before exploring")
	for destination: String in ["foyer", "parts_store", "foyer", "maintenance", "pump", "polluted_store", "pump", "guard", "foyer", "guard", "pump", "control"]:
		var source: String = Dungeon.state(world).room_id
		pair_intent(world, twin, dungeon_intent(world, "MOVE", source, destination), "actual branch " + source + "/" + destination)
		twin = disk_copy(world, "actual explored-room slot " + destination)
	var checkpoint: Dictionary = Dungeon.state(world)
	check(checkpoint.visited == ["entrance", "foyer", "parts_store", "maintenance", "pump", "polluted_store", "guard", "control"], "discovery records actual first visits, not a predetermined completion checklist")
	check(world.current_day == 0 and world.player.inventory.to_dict() == baseline.player.inventory and world.to_dict().npc_life_state_registry == baseline.npc_life_state_registry, "eight-room walk preserves resources, day and population membership")
	rejected(world, dungeon_intent(world, "MOVE", "control", "entrance"), "closed control shortcut")
	rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "OPEN_SHORTCUT", "reward": 1}), "shortcut extra field")
	var emitted: Array[EventRecord] = []
	check(engine.commit_player_intent(world, dungeon_intent(world, "OPEN_SHORTCUT"), emitted).success, "actual control door latch opens")
	check(engine.commit_player_intent(twin, dungeon_intent(twin, "OPEN_SHORTCUT")).success, "twin actual latch")
	check(emitted.size() == 1 and emitted[0].type == "DUNGEON_SHORTCUT_OPENED" and emitted[0].payload == {"dungeon_id": Dungeon.SITE, "room_id": "control"}, "one reviewed shortcut fact without extra state or reward")
	parity(world, twin, "opened return")
	rejected(world, dungeon_intent(world, "OPEN_SHORTCUT"), "repeated latch")
	twin = disk_copy(world, "opened shortcut actual disk")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "control", "entrance"), "one-step home shortcut")
	pair_intent(world, twin, dungeon_intent(world, "EXIT"), "stairs after shortcut")
	check(Dungeon.state(world).visited.size() == 8 and Dungeon.state(world).shortcut_open, "knowledge and latch survive exit")
	pair_intent(world, twin, dungeon_intent(world, "ENTER"), "actual revisit")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "entrance", "control"), "opened shortcut works in reverse next visit")
	var before: String = world.to_canonical_json()
	var full_map: Dictionary = DungeonMap.project(Dungeon.state(world))
	check(full_map.rooms.size() == 8 and full_map.edges.size() == 9 and full_map.rooms.control.current and full_map.shortcut_open, "complete map shows explored names and ninth passage as opened return")
	check(world.to_canonical_json() == before, "map projection has zero world mutation")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "control", "entrance"), "revisit return")
	pair_intent(world, twin, dungeon_intent(world, "EXIT"), "revisit stairs")
	clear_slot()

func negative_shortcut_history() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	engine.commit_player_intent(world, dungeon_intent(world, "ENTER"))
	for destination: String in ["foyer", "guard", "pump", "control"]:
		check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, destination)).success, "real shortcut fixture route")
	check(engine.commit_player_intent(world, dungeon_intent(world, "OPEN_SHORTCUT")).success, "valid shortcut fixture")
	for mode: int in range(7):
		var data: Dictionary = world.to_dict().duplicate(true)
		var opening: Dictionary = data.events.back()
		match mode:
			0: opening.payload.room_id = "pump"
			1: opening.payload.extra = true
			2: data.events.append(opening.duplicate(true))
			3: data.events.remove_at(data.events.size() - 2)
			4:
				opening.type = "DUNGEON_ROOM_ENTERED"
				opening.payload = {"dungeon_id": Dungeon.SITE, "from_room_id": "control", "room_id": "entrance"}
			5: data.erase("player")
			6:
				var final_move: Dictionary = data.events[data.events.size() - 2]
				final_move.payload.from_room_id = "pump"
				final_move.payload.room_id = "parts_store"
		data.event_count = data.events.size()
		var checked: Dictionary = WorldState.from_json_checked(JSON.stringify(data))
		check(not checked.success and checked.world == null, "forged latch/connectivity persistence fixture " + str(mode))
		var raw_world: WorldState = WorldState.from_dict_unchecked(data)
		for fact: Dictionary in data.events: raw_world.event_log.append(EventRecord.from_dict(fact))
		check(Dungeon.validate_world(raw_world) != "", "same negative fixture executes domain validator " + str(mode))
	check(engine.validate_invariants(world) == "", "negative fixtures preserve real live world")

func physical_passages() -> void:
	var view: Control = RoomView.new()
	root.add_child(view)
	view.set_process(false)
	check(view.crate_texture != null, "original crate art loads for storage/guard/control scenery")
	for room: String in EXPECTED:
		for source: String in EXPECTED[room]:
			view.setup({"room_id": room, "from_room_id": source, "shortcut_open": false})
			check(view.walkable(view.actor_position), "safe arrival " + room + " from " + source)
			var actual: Array[String] = []
			for passage: Dictionary in view.doors:
				if passage.command == "MOVE": actual.append(passage.room_id)
			check(actual == EXPECTED[room], "physical doors match reviewed authority " + room)
			for passage: Dictionary in view.doors:
				view.setup({"room_id": room, "from_room_id": source, "shortcut_open": false})
				# Walk the authored central corridor from every source to every exit.
				view.guide_to(passage)
				for tick: int in range(120):
					view._process(0.08)
					if view.target_position.x < 0: break
				check(view.actor_position.distance_to(Layout.approach(passage)) <= 5 and view.target_position.x < 0, "actual slow-frame guide clears obstacles and stops at " + room + " from " + source + " toward " + passage.label)
				check(not view.nearest_door().is_empty() and view.nearest_door().command == passage.command, "walked route enables corresponding real interaction")
	for room: String in ["entrance", "control"]:
		view.setup({"room_id": room, "from_room_id": "control" if room == "entrance" else "entrance", "shortcut_open": true})
		check(view.walkable(view.actor_position) and view.actor_position == Vector2(820, 266), "safe opened-shortcut arrival at east door " + room)
	view.queue_free()

func layout_ui() -> void:
	clear_slot()
	var world: WorldState = fresh_towns("settlement:gray_valley")
	engine.commit_player_intent(world, dungeon_intent(world, "ENTER"))
	for destination: String in ["foyer", "maintenance", "pump", "control"]:
		engine.commit_player_intent(world, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, destination))
	check(store.save_game(world).success, "real control checkpoint slot")
	var main: Node = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and screen.view.room_id == "control" and screen.view.walkable(screen.view.actor_position), "real Continue reopens deep room safely")
	var before: String = main.world.to_canonical_json()
	screen.map_button.pressed.emit()
	await frames()
	check(screen.map_dialog.visible and not screen.view.enabled and screen.map_dialog.get_ok_button().has_focus(), "real map pauses movement with visible keyboard focus")
	check(main.world.to_canonical_json() == before, "map open is read-only")
	screen.map_dialog.get_ok_button().pressed.emit()
	await frames()
	check(screen.view.enabled and screen.view.has_focus(), "map close restores exploration focus")
	walk_to_door(screen, Vector2(500, 266))
	walk_to_door(screen, Vector2(868, 266))
	check(screen.interact_button.text.contains("解除門閂"), "closed return door offers actual latch command")
	screen.interact_button.pressed.emit()
	await frames()
	check(Dungeon.state(main.world).shortcut_open and screen.view.room_id == "control" and screen.view.actor_position == Vector2(500, 348), "latch commits once and safely keeps control checkpoint")
	walk_to_door(screen, Vector2(500, 266))
	walk_to_door(screen, Vector2(868, 266))
	screen.interact_button.pressed.emit()
	await frames()
	check(Dungeon.state(main.world).room_id == "entrance" and screen.view.actor_position == Vector2(820, 266), "actual opened door reaches entrance at correct doorway")
	find_command(screen, "存讀檔").pressed.emit()
	await frames()
	main.save_dialog.save_button.pressed.emit()
	check(store.load_game().world.to_canonical_json() == main.world.to_canonical_json(), "actual UI slot persists discovery and return latch")
	main.queue_free()
	await frames()
	main = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	screen = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and screen.view.doors.size() == 3 and Dungeon.state(main.world).shortcut_open, "restart Continue restores entrance return door")
	check(engine.validate_invariants(main.world) == "", "real restart global invariants")
	main.queue_free()
	await frames()
	clear_slot()

func run_layout() -> void:
	layout_replay()
	negative_shortcut_history()
	physical_passages()
	await layout_ui()
	print("DUN-2: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
