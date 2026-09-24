extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const OUT_DIR := "res://artifacts/quest-3"

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world := S1WorldData.create_s1_world()
	var created := SimulationEngine.new().commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "灰谷信差", "age": 24,
		"background_id": "SCAVENGER", "trait_ids": []}))
	if not created.success:
		push_error("QUEST-3 capture creation failed")
		quit(1)
		return
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, SimulationEngine.new())
	var scenes := [
		{"size": Vector2i(1280, 720), "quest_id": "gray_valley_rope_run", "label": "rope"},
		{"size": Vector2i(1152, 648), "quest_id": "gray_valley_wrench_run", "label": "wrench"},
	]
	for scene in scenes:
		root.size = scene.size
		for i in shell.quest_selector.item_count:
			if String(shell.quest_selector.get_item_metadata(i)) == scene.quest_id:
				shell.quest_selector.item_selected.emit(i)
				break
		for frame in range(5):
			await process_frame
		var img: Image = root.get_texture().get_image()
		var filename := "%s/gray_valley_%s_%dx%d.png" % [OUT_DIR, scene.label, scene.size.x, scene.size.y]
		if img.save_png(ProjectSettings.globalize_path(filename)) != OK:
			push_error("QUEST-3 capture failed: " + filename)
			quit(1)
			return
		print("CAPTURED ", filename, " ", img.get_width(), "x", img.get_height())
	shell.queue_free()
	await process_frame
	quit(0)
