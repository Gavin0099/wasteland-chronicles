extends SceneTree

# ASP-2 evidence, real renderer: the sheet's rumours with their chase buttons,
# and the chosen aim on the main screen.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/asp2-rumors")

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
			"source_settlement_id": "settlement:dry_well", "character_name": "聽消息的人",
			"age": 29, "background_id": "SCAVENGER", "trait_ids": [],
		}))
		engine.commit_player_intent(world, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:armory"))
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		await _save("1_aim_on_main_screen")
		shell._show_character()
		await _save("2_sheet_rumors")
		shell.queue_free()
		await process_frame
	quit(0)
