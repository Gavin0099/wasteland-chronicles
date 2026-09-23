extends SceneTree

const OUT := "res://artifacts/lunatic-desktop-ui"

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.creation.name_input.text = "灰谷信差"
	main.creation.submit()
	main.creation.enter_button.pressed.emit()
	main.engine.commit_player_intent(main.world, PlayerIntent.create_buy(main.world.player.npc_id, &"scrap", 3))
	main.shell._show_field()
	var field = main.shell.get_node("FieldScreen")
	await field.perform({"command": "START"})
	for dimension in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = dimension
		for i in 6:
			await process_frame
		var filename := "%s/battle_%dx%d.png" % [OUT, dimension.x, dimension.y]
		if root.get_texture().get_image().save_png(ProjectSettings.globalize_path(filename)) != OK:
			push_error("Battle capture failed: " + filename)
			quit(1)
			return
		print("CAPTURED ", filename)
	main.queue_free()
	await process_frame
	quit(0)
