extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")

var output_dir := OS.get_user_data_dir().path_join("captures/c3-growth")

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		var created := engine.commit_character_creation(world, Intent.new({
			"source_settlement_id": "settlement:gray_valley", "character_name": "試玩旅人",
			"age": 25, "background_id": "CARAVAN_GUARD", "trait_ids": [],
		}))
		if not created.success:
			push_error("C3 capture creation failed")
			quit(1)
			return
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_local_market()
		var bought := shell.on_buy_pressed("water", 1)
		if not bought.success or not bought.has("skill_practice"):
			push_error("C3 capture practice source failed")
			quit(1)
			return
		for frame in range(6):
			await process_frame
		var market_path := "%s/market_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(market_path) != OK:
			push_error("C3 market capture failed")
			quit(1)
			return
		print("CAPTURED ", market_path)
		shell._show_character()
		for frame in range(8):
			await process_frame
		for scroll in shell.find_children("*", "ScrollContainer", true, false):
			if scroll.get_parent() is AcceptDialog:
				scroll.scroll_vertical = 750
		for frame in range(4):
			await process_frame
		var path := "%s/character_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) != OK:
			push_error("C3 capture failed: " + path)
			quit(1)
			return
		print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
	quit(0)
