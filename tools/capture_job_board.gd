extends SceneTree

# Real-renderer capture of the FUN-1 job board at both supported viewports.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/fun1-job-board")

func _init() -> void:
	call_deferred("capture")

func _world() -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	if not engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "跑活的人",
		"age": 29, "background_id": "SCAVENGER", "trait_ids": [],
	})).success:
		return {}
	# Let the world run long enough for a real shortage to reach the board.
	for day in range(20):
		engine.tick(world)
	return {"world": world, "engine": engine}

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var setup := _world()
		if setup.is_empty():
			quit(1)
			return
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(setup.world, setup.engine)
		for frame in range(6):
			await process_frame
		shell.quest_access_button.pressed.emit()
		for frame in range(4):
			await process_frame
		# Show a GENERATED job rather than the first authored one, so the
		# capture actually evidences the new presentation.
		for index in shell.quest_selector.item_count:
			if String(shell.quest_selector.get_item_metadata(index)).begins_with("job_"):
				shell.quest_selector.select(index)
				shell.quest_selector.item_selected.emit(index)
				break
		for frame in range(6):
			await process_frame
		var path := "%s/board_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) != OK:
			quit(1)
			return
		print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
	quit(0)
