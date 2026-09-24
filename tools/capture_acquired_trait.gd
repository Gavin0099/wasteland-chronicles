extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")

var output_dir := OS.get_user_data_dir().path_join("captures/c45-acquired")

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		var created := engine.commit_character_creation(world, Creation.new({
			"source_settlement_id": "settlement:gray_valley", "character_name": "荒野旅人",
			"age": 26, "background_id": "FARMER", "trait_ids": [],
		}))
		if not created.success:
			quit(1)
			return
		world.player.inventory.water = 0
		world.player.inventory.food = 6
		engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"))
		for day in range(3):
			engine.tick(world)
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_character()
		for frame in range(12):
			await process_frame
		var path := "%s/candidate_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) != OK:
			quit(1)
			return
		print("CAPTURED ", path)
		for scroll in shell.find_children("*", "ScrollContainer", true, false):
			if scroll.get_parent() is AcceptDialog:
				scroll.scroll_vertical = 320
		for frame in range(4):
			await process_frame
		var scrolled_path := "%s/choice_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(scrolled_path) != OK:
			quit(1)
			return
		print("CAPTURED ", scrolled_path)
		shell.queue_free()
		await process_frame
	quit(0)
