extends SceneTree

# TRAIN-1 evidence, real renderer: Gray Valley's teachers, with prices and the
# reason a lesson is closed.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/train1-teachers")

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		engine.commit_character_creation(world, Creation.new({
			"source_settlement_id": "settlement:gray_valley", "character_name": "學徒",
			"age": 29, "background_id": "SCAVENGER", "trait_ids": [],
		}))
		world.player.money = 90
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_training()
		for frame in range(10):
			await process_frame
		var path := "%s/teachers_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) == OK:
			print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
	quit(0)
