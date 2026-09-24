extends SceneTree

# Real-renderer capture of the KNOWN_HELPER knowledge line, at both supported
# viewports. The identity is earned through the production intents, never set
# directly, so the screenshot shows a state the game can actually reach.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/c45-known-helper")

func _init() -> void:
	call_deferred("capture")

func _drive_home(world: WorldState, engine: SimulationEngine, id: StringName) -> void:
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

func _stage(world: WorldState, engine: SimulationEngine, id: StringName, encounter_type: StringName) -> void:
	var origin: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var dest := &"settlement:new_hope" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	world.player.inventory.scrap = 0
	world.player.inventory.fuel = 0
	engine.begin_player_travel(world, PlayerIntent.create_travel(id, dest))
	world.active_encounter = TravelEncounterState.create(encounter_type, world.current_day, origin, dest, 1)

func _qualified_world() -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	if not engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "分水的人",
		"age": 31, "background_id": "FARMER", "trait_ids": [],
	})).success:
		return {}
	var id: StringName = world.player.npc_id

	# Two distinct days of really giving something away.
	_stage(world, engine, id, TravelEncounter.DEHYDRATED_TRAVELLER)
	engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"GIVE_WATER"))
	_drive_home(world, engine, id)
	_stage(world, engine, id, TravelEncounter.REFUGEE_COLUMN)
	engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"SHARE_FOOD"))
	_drive_home(world, engine, id)

	if not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "KNOWN_HELPER")).success:
		return {}
	_stage(world, engine, id, TravelEncounter.DEHYDRATED_TRAVELLER)
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
