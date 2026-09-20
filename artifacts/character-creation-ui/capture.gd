extends SceneTree

func _init() -> void:
	call_deferred("capture")

func shot(file: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/character-creation-ui/" + file)

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.creation.name_input.text = "吳某某"
	main.creation.select_background("MECHANIC")
	main.creation.trait_buttons.CAUTIOUS.button_pressed = true
	main.creation.trait_buttons.CURIOUS.button_pressed = true
	await shot("creation.png")
	root.size = Vector2i(1152, 648)
	await shot("creation-small.png")
	root.size = Vector2i(1280, 720)
	main.creation.submit_button.pressed.emit()
	await shot("summary.png")
	main.creation.enter_button.pressed.emit()
	main.shell._show_character()
	await shot("capabilities.png")
	quit()
