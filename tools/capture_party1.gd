extends SceneTree

# PARTY-1 evidence, real renderer: the 找人 window with teachers and the
# companion for hire, and the main screen once someone walks with you.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/party1-companions")

func _init() -> void:
	call_deferred("capture")

func _save(label: String) -> void:
	for frame in range(10):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]
	if root.get_texture().get_image().save_png(path) == OK:
		print("CAPTURED ", path)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		engine.commit_character_creation(world, Creation.new({
			"source_settlement_id": "settlement:gray_valley", "character_name": "領隊",
			"age": 29, "background_id": "SCAVENGER", "trait_ids": [],
		}))
		world.player.money = 150
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_training()
		await _save("1_find_people")
		shell.companion_buttons["companion:abban"].pressed.emit()
		await _save("2_walking_together")
		shell.queue_free()
		await process_frame
	quit(0)
