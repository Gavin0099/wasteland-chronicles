extends SceneTree
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/gear-balance1")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1152,648)]:
		root.size = resolution
		for id: String in ["combat_knife", "sledgehammer", "police_revolver", "short_shotgun"]:
			var world: WorldState = Base.fresh("settlement:new_hope")
			var engine: SimulationEngine = SimulationEngine.new()
			assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"hunting_knife", 1)).success)
			assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"hunting_knife", "main_hand")).success)
			assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success)
			var before: String = world.to_canonical_json()
			var shell: PlayableShell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			shell._show_character()
			await process_frame
			for child: Node in shell.get_children():
				if child.get_script() == Sheet: child.show_item_detail(id)
			for tick: int in range(12): await process_frame
			assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir,id,root.size.x,root.size.y]) == OK)
			assert(world.to_canonical_json() == before)
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
