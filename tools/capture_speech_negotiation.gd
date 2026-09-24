extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")
const Enc = preload("res://simulation/travel_encounter.gd")

var output_dir := OS.get_user_data_dir().path_join("captures/s5-c3b-speech")

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		var created := engine.commit_character_creation(world, Intent.new({
			"source_settlement_id": "settlement:gray_valley", "character_name": "演說者",
			"age": 25, "background_id": "CARAVAN_GUARD", "trait_ids": [],
		}))
		if not created.success:
			push_error("Creation failed")
			quit(1)
			return
		world.player.inventory.set_amount("water", 8)
		world.player.inventory.set_amount("food", 8)
		world.player.money = 100
		var travel := engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"))
		if not travel.success:
			push_error("Travel failed")
			quit(1)
			return
		world.pending_encounter_result = -1
		world.active_encounter = TravelEncounterState.create(
			Enc.ROADBLOCK, 1, &"settlement:gray_valley", &"settlement:new_hope", 1,
			{"min_security": 50.0, "headcount": 10, "origin_name": "Gray Valley", "destination_name": "New Hope"})
		
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		for frame in range(6):
			await process_frame
		
		# Capture encounter options showing "跟他們談談"
		var opt_path := "%s/roadblock_options_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(opt_path) != OK:
			push_error("Option capture failed")
			quit(1)
			return
		print("CAPTURED ", opt_path)
		
		# Now resolve with PERSUADE and capture result panel
		var res := shell.on_encounter_option_pressed("PERSUADE")
		if not res.success:
			push_error("Persuade failed: " + String(res.get("error", "")))
			quit(1)
			return
		for frame in range(6):
			await process_frame
		
		var res_path := "%s/roadblock_result_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(res_path) != OK:
			push_error("Result capture failed")
			quit(1)
			return
		print("CAPTURED ", res_path)
		
		shell.queue_free()
		await process_frame
	quit(0)
