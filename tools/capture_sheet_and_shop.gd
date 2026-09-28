extends SceneTree

# Real-renderer check of the RPG-style character window, the rumour window and
# the pick-then-act trade window.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/sheet-and-shop")

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
			"source_settlement_id": "settlement:gray_valley", "character_name": "阿澤",
			"age": 23, "background_id": "SCAVENGER", "trait_ids": [],
		}))
		world.player.money = 190
		world.player.xp = 59
		world.player.item_inventory.pickup_item("scrap_machete", 1)
		world.player.item_inventory.pickup_item("first_aid_kit", 1)
		engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"scrap_machete", "main_hand"))
		engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, "companion:abban"))
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_character()
		await _save("1_character")
		for child in shell.get_children():
			if child is AcceptDialog:
				child.queue_free()
		await process_frame
		shell._show_rumors()
		await _save("2_rumors")
		shell.rumor_window.queue_free()
		await process_frame
		shell._show_local_market()
		await process_frame
		shell.market_window.row_buttons["scrap_machete"].pressed.emit()
		await _save("3_shop")
		shell.queue_free()
		await process_frame
	quit(0)
