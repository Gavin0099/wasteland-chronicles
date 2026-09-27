extends SceneTree

# PLACE-4 evidence, real renderer:
#   1. a place met on the road, with its decision (the fuel station)
#   2. the town taking over a place you marked, shown on arrival
#   3. the map: four places, the found ones named, the rest a "?"

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/place4-road-places")

func _init() -> void:
	call_deferred("capture")

func _world(origin: String) -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	if not engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "走路的人",
		"age": 29, "background_id": "SCAVENGER", "trait_ids": [],
	})).success:
		return {}
	world.player.inventory.set_amount("water", 6)
	world.player.inventory.set_amount("food", 6)
	return {"world": world, "engine": engine}

func _shell(setup: Dictionary) -> PlayableShell:
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(setup.world, setup.engine)
	return shell

func _save(label: String) -> void:
	for frame in range(8):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]
	if root.get_texture().get_image().save_png(path) == OK:
		print("CAPTURED ", path)

# Walk on through anything that is not the thing being captured.
func _walk_on(shell: PlayableShell, world: WorldState, engine: SimulationEngine) -> void:
	var guard := 0
	while guard < 12:
		guard += 1
		if world.pending_encounter_result >= 0:
			shell.on_encounter_continue_pressed(world.pending_encounter_result)
			continue
		if world.active_encounter == null:
			return
		var choice := "LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = "FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = "DETOUR"
			TravelEncounter.ROADBLOCK: choice = "PAY"
		shell.on_encounter_option_pressed(choice)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size

		# 1. the fuel station, met on the Gray Valley - New Hope road
		var s1 := _world("settlement:gray_valley")
		var shell1 := _shell(s1)
		shell1.select_settlement("settlement:new_hope")
		shell1.on_travel_pressed()
		await _save("1_fuel_station")
		shell1.queue_free()
		await process_frame

		# 2. mark the well for Gray Valley on the way to Dry Well, then walk back
		var s2 := _world("settlement:gray_valley")
		var world2: WorldState = s2.world
		var engine2: SimulationEngine = s2.engine
		var shell2 := _shell(s2)
		shell2.select_settlement("settlement:dry_well")
		shell2.on_travel_pressed()
		if world2.active_encounter != null and String(world2.active_encounter.context.get("place_id", "")) == "place:old_well":
			shell2.on_encounter_option_pressed("MARK_A")
		_walk_on(shell2, world2, engine2)
		world2.player.inventory.set_amount("water", 6)
		world2.player.inventory.set_amount("food", 6)
		shell2.select_settlement("settlement:gray_valley")
		shell2.on_travel_pressed()
		_walk_on(shell2, world2, engine2)
		await _save("2_report_on_arrival")
		for child in shell2.get_children():
			if child is AcceptDialog:
				child.queue_free()
		await process_frame

		# 3. the map after that: the well is Gray Valley's, the rest unfound
		shell2.refresh_ui()
		await _save("3_map")
		shell2.queue_free()
		await process_frame
	quit(0)
