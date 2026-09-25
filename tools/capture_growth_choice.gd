extends SceneTree

# PLAY-2 evidence: the moment a level asks the player who they are becoming.

const Creation = preload("res://simulation/character_creation_intent.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/play2-growth-choice")

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		if not engine.commit_character_creation(world, Creation.new({
			"source_settlement_id": "settlement:gray_valley", "character_name": "選擇的人",
			"age": 27, "background_id": "SCAVENGER", "trait_ids": [],
		})).success:
			quit(1)
			return
		# Two levels' worth of experience, earned the way the game grants it.
		world.player.xp = Perks.xp_for_level(3)
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		for frame in range(6):
			await process_frame
		shell._show_character()
		for frame in range(8):
			await process_frame
		# The growth section lives beside the skills, further down the sheet.
		for node in shell.get_children():
			if node.has_method("setup") and "growth_buttons" in node:
				for scroller in node.find_children("*", "ScrollContainer", true, false):
					scroller.scroll_vertical = 10000
		for frame in range(8):
			await process_frame
		var path := "%s/growth_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) == OK:
			print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
	quit(0)
