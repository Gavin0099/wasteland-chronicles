extends "res://tests/test_dungeon_combat.gd"

func _init() -> void:
	store = Store.new("user://tests/dun4/journey.json")
	call_deferred("run_routes")

func maintenance_intent(world: WorldState, method: String) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "OPEN_MAINTENANCE", "method": method})

func route_fixture(method: String) -> WorldState:
	var world: WorldState = PlayableWorld.create_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "維修旅人", "age": 28, "background_id": "MECHANIC" if method == "SKILL" else "SCAVENGER", "trait_ids": []})).success, "actual route background creation")
	world.player.inventory.water = 3
	world.player.inventory.food = 3
	world.player.inventory.scrap = 8 # Reviewed materials fixture; spending uses real intents.
	world.player.money = 200
	if method == "TOOL":
		check(engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "CRAFT"})).success, "actual town crowbar craft before route")
	elif method == "ABBAN":
		check(engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Dungeon.Party.ABBAN)).success, "actual Abban hire before route")
	check(engine.validate_invariants(world) == "", "route preparation full invariants")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success and Dungeon.state(world).route_rules == 1, "current entry always records rules1")
	return world

func approach_room(world: WorldState, target: String) -> void:
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "entrance", "foyer")).success, "actual route foyer")
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "foyer", target)).success, "actual chosen route room")

func route_replay() -> void:
	clear_slot()
	for method: String in ["SKILL", "TOOL", "ABBAN"]:
		var world: WorldState = route_fixture(method)
		approach_room(world, "maintenance")
		var baseline: Dictionary = world.to_dict().duplicate(true)
		var twin: WorldState = disk_copy(world, method + " closed gate actual disk")
		rejected(world, dungeon_intent(world, "MOVE", "maintenance", "pump"), "closed maintenance gate")
		pair_intent(world, twin, maintenance_intent(world, method), method + " explicit actual opening")
		var cost: int = 2 if method == "TOOL" else 1 # Reviewed independent cost fixture.
		check(world.player.inventory.scrap == int(baseline.player.inventory.scrap) - cost and world.player.money == int(baseline.player.money), method + " exact scrap spending and no implicit fee")
		check(world.current_day == int(baseline.current_day) and world.to_dict().npc_life_state_registry == baseline.npc_life_state_registry and world.player.xp == int(baseline.player.get("xp", 0)), "opening changes no day/population/XP")
		check(Dungeon.state(world).maintenance_open and Dungeon.state(world).maintenance_method == method, "actual selected method persisted in gate fact")
		twin = disk_copy(world, method + " opened gate actual disk")
		rejected(world, maintenance_intent(world, method), "gate cannot charge twice")
		pair_intent(world, twin, dungeon_intent(world, "MOVE", "maintenance", "pump"), "opened bypass reaches pump")
		rejected(world, dungeon_intent(world, "MOVE", "pump", "guard"), "uncleared front remains blocked from far side")
		pair_intent(world, twin, dungeon_intent(world, "MOVE", "pump", "maintenance"), "opened bypass permits safe backtrack")
		for target: String in ["foyer", "entrance"]:
			pair_intent(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual return to entrance")
		pair_intent(world, twin, dungeon_intent(world, "EXIT"), "actual route trip exit")
		if method == "ABBAN":
			pair_intent(world, twin, PlayerIntent.create_dismiss_companion(world.player.npc_id), "actual later companion dismissal")
		pair_intent(world, twin, dungeon_intent(world, "ENTER"), "current-rules revisit")
		pair_intent(world, twin, dungeon_intent(world, "MOVE", "entrance", "foyer"), "revisit foyer")
		pair_intent(world, twin, dungeon_intent(world, "MOVE", "foyer", "maintenance"), "revisit bypass")
		pair_intent(world, twin, dungeon_intent(world, "MOVE", "maintenance", "pump"), "permanent opening survives revisit/dismissal")
		twin = disk_copy(world, method + " permanent gate actual disk")
	var front: WorldState = route_fixture("SKILL")
	approach_room(front, "guard")
	rejected(front, dungeon_intent(front, "MOVE", "guard", "pump"), "unfought front gate")
	check(engine.commit_player_intent(front, fight_intent(front, "guard")).success, "actual front fight")
	check(engine.commit_player_intent(front, combat_intent(front, "FLEE")).success, "actual front retreat")
	check(engine.commit_player_intent(front, combat_intent(front, "CONFIRM")).success, "actual retreat acknowledgement")
	rejected(front, dungeon_intent(front, "MOVE", "guard", "pump"), "escape does not open front gate")
	check(engine.commit_player_intent(front, fight_intent(front, "guard")).success, "actual front rechallenge")
	win(front)
	check(engine.commit_player_intent(front, combat_intent(front, "CONFIRM")).success, "actual front victory acknowledgement")
	check(engine.commit_player_intent(front, dungeon_intent(front, "MOVE", "guard", "pump")).success, "verified victory opens actual front route")
	check(engine.commit_player_intent(front, dungeon_intent(front, "MOVE", "pump", "guard")).success, "cleared front route also permits return")
	clear_slot()

func route_refusals() -> void:
	var world: WorldState = route_fixture("NONE")
	approach_room(world, "maintenance")
	for method: String in ["SKILL", "TOOL", "ABBAN", "UNKNOWN"]: rejected(world, maintenance_intent(world, method), "missing explicit method requirements " + method)
	for payload: Dictionary in [{"command": "OPEN_MAINTENANCE"}, {"command": "OPEN_MAINTENANCE", "method": 1}, {"command": "OPEN_MAINTENANCE", "method": "SKILL", "scrap_spent": 0}, {"command": "ENTER", "route_rules": 0}]: rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload), "forged opening/rule selector")
	rejected(world, PlayerIntent.create_dungeon_action(&"npc:unknown", {"command": "OPEN_MAINTENANCE", "method": "TOOL"}), "wrong route actor")
	var real_tool: WorldState = route_fixture("NONE")
	check(real_tool.player.item_inventory.pickup_item("wrench", 1).success, "reviewed real-item wrench fixture")
	approach_room(real_tool, "maintenance")
	check(engine.commit_player_intent(real_tool, maintenance_intent(real_tool, "TOOL")).success, "real-item ownership permits tool method without legacy kit")
	var poor: WorldState = route_fixture("SKILL")
	poor.player.inventory.scrap = 0
	approach_room(poor, "maintenance")
	rejected(poor, maintenance_intent(poor, "SKILL"), "valid skill still requires actual materials")
	var wrong_room: WorldState = route_fixture("SKILL")
	approach_room(wrong_room, "guard")
	rejected(wrong_room, maintenance_intent(wrong_room, "SKILL"), "opening from wrong room")
	var closed: Dictionary = world.to_dict().duplicate(true)
	closed.events.append({"day": world.current_day, "type": "DUNGEON_ROOM_ENTERED", "actor_id": String(world.player.npc_id), "target_id": Dungeon.SITE, "payload": {"dungeon_id": Dungeon.SITE, "from_room_id": "maintenance", "room_id": "pump"}})
	closed.event_count = closed.events.size()
	reject_fixture(closed, "plausible exact closed-gate transition")
	for method: String in ["SKILL", "TOOL", "ABBAN"]:
		var valid: WorldState = route_fixture(method)
		approach_room(valid, "maintenance")
		check(engine.commit_player_intent(valid, maintenance_intent(valid, method)).success, "real opening seed for method validator")
		for mode: int in range(8):
			var data: Dictionary = valid.to_dict().duplicate(true)
			var opening: Dictionary = last_fact(data, "DUNGEON_MAINTENANCE_OPENED")
			match mode:
				0: opening.payload.scrap_spent = 0
				1: opening.payload.method = "UNKNOWN"
				2: opening.payload.proof = false
				3: opening.payload.room_id = "pump"
				4: opening.payload.extra = "reward"
				5: opening.actor_id = "npc:unknown"
				6: last_fact(data, "DUNGEON_ENTERED").payload.erase("route_rules")
				7: data.events.append(opening.duplicate(true))
			data.event_count = data.events.size()
			reject_fixture(data, method + " malformed opening %d" % mode)

func legacy_rules() -> void:
	clear_slot()
	var world: WorldState = fresh_towns("settlement:gray_valley")
	enter_legacy_graph(world)
	world = disk_copy(world, "actual legacy two-key entry")
	for target: String in ["foyer", "guard", "pump", "maintenance", "foyer", "entrance"]:
		check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target)).success, "valid legacy graph stays open before exit")
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success, "actual legacy trip exits")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "next real entry records current rules")
	approach_room(world, "guard")
	rejected(world, dungeon_intent(world, "MOVE", "guard", "pump"), "reentered legacy journey obeys new front gate")
	for target: String in ["foyer", "entrance"]:
		check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target)).success, "blocked front can still backtrack")
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success and engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "second current-rules actual entry")
	var downgrade: Dictionary = world.to_dict().duplicate(true)
	last_fact(downgrade, "DUNGEON_ENTERED").payload.erase("route_rules")
	reject_fixture(downgrade, "history cannot downgrade activated route rules")
	clear_slot()

func run_routes() -> void:
	root.size = Vector2i(1280, 720)
	route_replay()
	route_refusals()
	legacy_rules()
	typed_combat_history()
	await route_ui()
	print("DUN-4: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)

func typed_combat_history() -> void:
	var world: WorldState = route_fixture("SKILL")
	approach_room(world, "guard")
	check(engine.commit_player_intent(world, fight_intent(world, "guard")).success, "typed history actual battle start")
	var start_data: Dictionary = world.to_dict().duplicate(true)
	check(engine.commit_player_intent(world, combat_intent(world, "DEFEND")).success, "typed history actual defend turn")
	var turn_data: Dictionary = world.to_dict().duplicate(true)
	check(engine.commit_player_intent(world, combat_intent(world, "FLEE")).success, "typed history actual flee result")
	var result_data: Dictionary = world.to_dict().duplicate(true)
	check(engine.commit_player_intent(world, combat_intent(world, "CONFIRM")).success, "typed history actual confirmation")
	var confirmed_data: Dictionary = world.to_dict().duplicate(true)
	var seeds: Array[Dictionary] = [start_data, turn_data, result_data, confirmed_data]
	var kinds: Array[String] = ["DUNGEON_BATTLE_STARTED", "FIELD_TURN", "FIELD_RESULT", "DUNGEON_BATTLE_CONFIRMED"]
	# Reviewed schema types, independent of production validation helpers.
	var text_keys: Array[Array] = [["dungeon_id", "room_id", "enemy"], ["source", "dungeon_id", "room_id", "command"], ["source", "dungeon_id", "room_id", "outcome", "enemy"], ["dungeon_id", "room_id"]]
	var number_keys: Array[Array] = [["battle_id", "hp", "site_enemy_hp"], ["battle_id", "turn", "dealt", "taken", "hp", "enemy_hp"], ["battle_id", "hp", "site_enemy_hp", "caps_gained"], ["battle_id", "result_index"]]
	for index: int in range(seeds.size()):
		check(WorldState.from_json_checked(JSON.stringify(seeds[index])).success, "valid actual typed history control " + kinds[index])
		for key: String in text_keys[index]:
			for invalid: Variant in [false, 17, {}, []]:
				var data: Dictionary = seeds[index].duplicate(true)
				last_fact(data, kinds[index]).payload[key] = invalid
				reject_fixture(data, "%s.%s rejects type %d" % [kinds[index], key, typeof(invalid)])
		for key: String in number_keys[index]:
			for invalid: Variant in [false, "1", {}, null]:
				var data: Dictionary = seeds[index].duplicate(true)
				last_fact(data, kinds[index]).payload[key] = invalid
				reject_fixture(data, "%s.%s rejects type %d" % [kinds[index], key, typeof(invalid)])
	for key: String in ["source", "dungeon_id", "room_id", "enemy"]:
		for invalid: Variant in [false, 17, {}, []]:
			var data: Dictionary = turn_data.duplicate(true)
			data.field_state.battle[key] = invalid
			reject_fixture(data, "active battle snapshot.%s rejects type %d" % [key, typeof(invalid)])
	for key: String in ["id", "turn", "site_enemy_hp"]:
		for invalid: Variant in [false, "1", {}, null]:
			var data: Dictionary = turn_data.duplicate(true)
			data.field_state.battle[key] = invalid
			reject_fixture(data, "active battle snapshot.%s rejects type %d" % [key, typeof(invalid)])
	for invalid: Variant in [1, "true", {}, null]:
		var data: Dictionary = turn_data.duplicate(true)
		data.field_state.battle.prepared = invalid
		reject_fixture(data, "active battle snapshot.prepared rejects type %d" % typeof(invalid))
	check(world.to_dict() == confirmed_data and engine.validate_invariants(world) == "", "negative history probes never mutate actual valid world")

func guide_route(screen: Control, destination: String) -> void:
	var selected: int = -1
	for index: int in range(screen.view.doors.size()):
		if screen.view.doors[index].get("room_id", "") == destination and screen.view.doors[index].command == "MOVE": selected = index
	check(selected >= 0, "actual requested route door exists " + destination)
	if selected < 0: return
	var before: String = screen.world.to_canonical_json()
	screen.route_choice.select(selected)
	screen.guide_button.pressed.emit()
	for tick: int in range(480):
		if screen.view.target_position.x < 0: break
		await process_frame
	check(screen.view.nearest_door().get("room_id", "") == destination and screen.world.to_canonical_json() == before, "actual guide arrives at route without world mutation")

func observe_route(label: String, main: Node) -> void:
	await frames()
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and engine.validate_invariants(main.world) == "", label + " actual screen and full invariants")
	var controls: Array[Control] = [screen.guide_button, screen.interact_button, screen.route_choice, screen.map_button]
	for button: Button in screen.maintenance_buttons.values(): controls.append(button)
	for button: Control in controls:
		var bounds: Rect2 = button.get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y and bounds.size.y >= 40, label + " actual route command fits viewport and touch size")
	check(screen.view.size.y >= 340 and screen.view.walkable(screen.view.actor_position), label + " actual arena and restored actor remain usable")
	if is_instance_valid(screen.map_dialog):
		var bounds: Rect2i = Rect2i(screen.map_dialog.position, screen.map_dialog.size)
		check(not screen.view.enabled and bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y, label + " actual map fits and pauses walking")
		check(screen.map_dialog.get_ok_button().size.y >= 40, label + " actual map return touch height")

func route_ui() -> void:
	for method: String in ["SKILL", "TOOL", "ABBAN", "NONE"]:
		clear_slot()
		var world: WorldState = route_fixture(method)
		approach_room(world, "maintenance")
		check(store.save_game(world).success, "actual route UI slot " + method)
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("DungeonScreen", false, false)
		check(screen.maintenance_buttons.size() == 3 and screen.maintenance_actions.visible, "all actual choices/costs exposed")
		for button: Button in screen.maintenance_buttons.values(): check(button.disabled, "actual opening requires walking to gate")
		var before: String = main.world.to_canonical_json()
		screen.open_maintenance("SKILL")
		check(main.world.to_canonical_json() == before, "direct UI opening cannot bypass physical proximity")
		await observe_route(method.to_lower() + "_far_gate", main)
		await guide_route(screen, "pump")
		check(screen.interact_button.disabled and screen.interact_button.text.contains("鎖住"), "actual locked door cannot move before opening")
		for selected_method: String in ["SKILL", "TOOL", "ABBAN"]:
			check(screen.maintenance_buttons[selected_method].disabled == (selected_method != method), "actual method availability matches independent fixture")
		await observe_route(method.to_lower() + "_gate_ready", main)
		screen.map_button.pressed.emit()
		await observe_route(method.to_lower() + "_closed_map", main)
		check(not screen.map_dialog.get_child(0).get_children().is_empty(), "actual map content exists")
		screen.map_dialog.get_ok_button().pressed.emit()
		await frames()
		if method != "NONE":
			var scrap: int = main.world.player.inventory.scrap
			var position_before: Vector2 = screen.view.actor_position
			screen.maintenance_buttons[method].pressed.emit()
			await frames()
			check(Dungeon.state(main.world).maintenance_open and main.world.player.inventory.scrap == scrap - (2 if method == "TOOL" else 1), "actual chosen button spends reviewed cost")
			check(not screen.interact_button.disabled and not screen.maintenance_actions.visible and screen.view.actor_position == position_before and screen.message.text.contains("已付"), "opened gate keeps local position and displays paid cost")
			await observe_route(method.to_lower() + "_gate_open", main)
			screen.map_button.pressed.emit()
			await observe_route(method.to_lower() + "_opened_map", main)
			screen.map_dialog.get_ok_button().pressed.emit()
			await frames()
			find_command(screen, "存讀檔").pressed.emit()
			await frames()
			main.save_dialog.save_button.pressed.emit()
			before = main.world.to_canonical_json()
			main.queue_free()
			await frames()
			main = new_main()
			await frames()
			main.save_dialog.load_button.pressed.emit()
			await frames()
			screen = main.shell.find_child("DungeonScreen", false, false)
			check(main.world.to_canonical_json() == before and not screen.maintenance_actions.visible, "startup Continue keeps opened gate and no repeat cost")
			await observe_route(method.to_lower() + "_continued_gate", main)
			await guide_route(screen, "pump")
			screen.interact_button.pressed.emit()
			await observe_route(method.to_lower() + "_pump", main)
			check(Dungeon.state(main.world).room_id == "pump" and screen.view.enemy_id == "feral_dog", "actual opened bypass reaches real pump encounter")
		else:
			await guide_route(screen, "foyer")
			check(not screen.interact_button.disabled, "unprepared player has usable retreat")
			screen.interact_button.pressed.emit()
			await observe_route("unprepared_backtrack", main)
			check(Dungeon.state(main.world).room_id == "foyer", "actual failed preparation returns to foyer")
		main.queue_free()
		await frames()
	clear_slot()
	var front: WorldState = route_fixture("SKILL")
	approach_room(front, "guard")
	check(store.save_game(front).success, "actual front-gate UI slot")
	var front_main: Node = new_main()
	await frames()
	front_main.save_dialog.load_button.pressed.emit()
	await frames()
	var front_screen: Control = front_main.shell.find_child("DungeonScreen", false, false)
	await guide_route(front_screen, "pump")
	check(front_screen.interact_button.disabled and front_screen.message.text.contains("維修廊"), "front guard names real alternate route")
	await observe_route("front_guard_locked", front_main)
	front_screen.interact()
	check(front_screen.message.text.contains("排除警衛") and Dungeon.state(front_main.world).room_id == "guard", "blocked physical E shows actionable refusal and stays in room")
	await observe_route("front_guard_refusal", front_main)
	front_main.queue_free()
	await frames()
	clear_slot()
