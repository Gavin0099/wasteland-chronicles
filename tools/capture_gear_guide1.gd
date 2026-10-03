extends SceneTree
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Journey = preload("res://tests/fixtures/gear2e_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/gear-guide1")
func _init() -> void: call_deferred("capture")
func frame(label: String) -> void:
	for tick: int in range(12): await process_frame
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var world: WorldState = Journey.checkpoint()
	assert(Base.answer(world, &"RECOVER_GAS_MASK").success)
	Journey.finish(world)
	for id: String in ["first_aid_kit", "old_revolver", "revolver_round"]:
		assert(SimulationEngine.new().commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success)
	var before: String = world.to_canonical_json()
	for resolution: Vector2i in [Vector2i(1280,720), Vector2i(1152,648)]:
		root.size = resolution
		for id: String in ["military_gas_mask", "repair_toolbox", "first_aid_kit", "old_revolver", "revolver_round"]:
			var shell: PlayableShell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, SimulationEngine.new())
			shell._show_character()
			await process_frame
			for child: Node in shell.get_children():
				if child.get_script() == Sheet: child.show_item_detail(id)
			await frame(id)
			if id == "military_gas_mask":
				for child: Node in shell.get_children():
					if child.get_script() == Sheet:
						var scroll: ScrollContainer = child.item_guide_label.get_parent().get_parent() as ScrollContainer
						scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
				await frame(id + "_guide")
			assert(world.to_canonical_json() == before)
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
