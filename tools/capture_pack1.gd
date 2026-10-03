extends SceneTree
const Fixture = preload("res://tests/fixtures/char2_world.gd")
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/pack1")

func _init() -> void: call_deferred("capture")
func frame(name_text: String) -> void:
	for tick: int in range(12): await process_frame
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, name_text, root.size.x, root.size.y]) == OK)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for mode: String in ["all", "weapon", "consumable", "empty_search", "empty_bag"]:
			var world: WorldState = Base.fresh() if mode == "empty_bag" else Fixture.geared()
			if mode == "consumable":
				assert(SimulationEngine.new().commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"first_aid_kit", 1)).success)
			var before: String = world.to_canonical_json()
			var shell: PlayableShell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, SimulationEngine.new())
			shell._show_character()
			await process_frame
			for child: Node in shell.get_children():
				if child.get_script() != Sheet: continue
				child.inventory_category.select(1 if mode == "weapon" else (5 if mode == "consumable" else 0))
				child.inventory_order.select(1)
				child.inventory_search.text = "不存在" if mode == "empty_search" else ""
				child.inventory_search.text_changed.emit(child.inventory_search.text)
				child.inventory_jump.pressed.emit()
				await frame(mode)
			assert(world.to_canonical_json() == before)
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
