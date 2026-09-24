extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/c45-scavenger")

func _init() -> void:
	call_deferred("capture")

func _qualified_world() -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "老拾荒者",
		"age": 28, "background_id": "SCAVENGER", "trait_ids": [],
	}))
	if not created.success:
		return {}
	var id: StringName = world.player.npc_id
	var counted := 0
	for trip in range(12):
		if counted >= 3:
			break
		var origin: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
		var dest := &"settlement:new_hope" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
		world.player.inventory.water = 4
		world.player.inventory.food = 4
		world.player.inventory.scrap = 0
		world.player.inventory.fuel = 0
		engine.begin_player_travel(world, PlayerIntent.create_travel(id, dest))
		world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, origin, dest, 1)
		var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"SEARCH"))
		if not result.get("gained", {}).is_empty() or not result.get("items_gained", {}).is_empty():
			counted += 1
		for step in range(12):
			if world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED:
				break
			if world.pending_encounter_result >= 0:
				engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result))
			elif world.active_encounter != null:
				var escape: StringName = &"FLEE_ROAD" if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else (&"DETOUR" if world.active_encounter.encounter_type in [TravelEncounter.ROCKSLIDE, TravelEncounter.ROADBLOCK] else &"LEAVE")
				engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, escape))
			else:
				engine.tick(world)
	if counted < 3 or not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "SCAVENGER_INSTINCT")).success:
		return {}
	var origin: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var dest := &"settlement:new_hope" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	engine.begin_player_travel(world, PlayerIntent.create_travel(id, dest))
	world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, origin, dest, 1)
	return {"world": world, "engine": engine}

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var setup := _qualified_world()
		if setup.is_empty():
			quit(1)
			return
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(setup.world, setup.engine)
		for frame in range(12):
			await process_frame
		var path := "%s/preview_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) != OK:
			quit(1)
			return
		print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
	quit(0)
