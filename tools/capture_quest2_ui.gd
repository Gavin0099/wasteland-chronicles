extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const OUT_DIR := "res://artifacts/quest-2"

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world := S1WorldData.create_s1_world()
	var created := SimulationEngine.new().commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "灰谷信差", "age": 24,
		"background_id": "SCAVENGER", "trait_ids": []}))
	if not created.success:
		push_error("QUEST-2 capture creation failed")
		quit(1)
		return
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, SimulationEngine.new())
	for size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		for frame in range(5):
			await process_frame
		var img: Image = root.get_texture().get_image()
		var filename := "%s/gray_valley_board_%dx%d.png" % [OUT_DIR, size.x, size.y]
		if img.save_png(ProjectSettings.globalize_path(filename)) != OK:
			push_error("QUEST-2 capture failed: " + filename)
			quit(1)
			return
		print("CAPTURED ", filename, " ", img.get_width(), "x", img.get_height())
	shell.queue_free()
	await process_frame
	quit(0)
