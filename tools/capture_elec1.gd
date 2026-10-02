extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/elec1")

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String) -> void:
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y])

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		for mode: String in ["teacher", "gate", "receipt"]:
			var world: WorldState = S1WorldData.create_s1_world()
			var engine: SimulationEngine = SimulationEngine.new()
			var town: String = "settlement:gray_valley" if mode == "teacher" else "settlement:dry_well"
			engine.commit_character_creation(world, Creation.new({"source_settlement_id": town, "character_name": "電器學徒", "age": 28, "background_id": "SCAVENGER", "trait_ids": []}))
			world.player.money = 500
			if mode != "teacher":
				world.player.capability.raise_rank_by_point("ELECTRONICS")
				world.player.capability.raise_rank_by_point("ELECTRONICS")
				world.player.inventory.set_amount("scrap", 2)
				engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope", "WILDERNESS"))
				world.active_encounter = TravelEncounterState.create(TravelEncounter.PLACE_VISIT, world.current_day, &"settlement:dry_well", &"settlement:new_hope", 3, {"place_id": "place:old_armory"})
				if mode == "receipt":
					engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"BRIDGE_ARMORY"))
			var shell: PlayableShell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			if mode == "teacher":
				shell._show_training()
			await save_frame(mode)
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
