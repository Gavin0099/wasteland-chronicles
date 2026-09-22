extends SceneTree
func _init() -> void:
	call_deferred("run")
func shot(file: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/field-combat/" + file)
func run() -> void:
	root.size = Vector2i(1280, 720)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.creation.name_input.text = "阿灰"
	main.creation.select_background("MECHANIC")
	main.creation.submit()
	main.creation.enter_button.pressed.emit()
	main.engine.commit_player_intent(main.world, PlayerIntent.create_buy(main.world.player.npc_id, &"scrap", 3))
	main.shell._show_field()
	var screen = main.shell.get_node("FieldScreen")
	await screen.perform({"command": "CRAFT"})
	await screen.perform({"command": "EQUIP"})
	await shot("preparation.png")
	await screen.perform({"command": "START"})
	await shot("battle.png")
	await screen.perform(screen.payload_for("ATTACK"))
	await shot("battle-after-attack.png")
	root.size = Vector2i(1152, 648)
	await shot("battle-small.png")
	await screen.perform(screen.payload_for("DEFEND"))
	await screen.perform(screen.payload_for("ATTACK"))
	await shot("victory.png")
	await screen.perform(screen.payload_for("CONFIRM"))
	await screen.perform({"command": "OPEN"})
	await shot("cache-result.png")
	await screen.perform(screen.payload_for("CONFIRM"))
	screen.close()
	await process_frame
	main.shell._show_character()
	await shot("character-small.png")
	quit()
