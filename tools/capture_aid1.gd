extends SceneTree
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/aid1")
func _init() -> void: call_deferred("capture")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1152,648)]:
		root.size = resolution
		for mode: String in ["injured","full_hp","empty","detail","market"]:
			var world: WorldState = Base.fresh()
			var engine: SimulationEngine = SimulationEngine.new()
			if mode != "empty":
				assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"bandage", 2)).success)
				assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"first_aid_kit", 1)).success)
			if mode == "injured": world.player.field_kit.hp = 8
			var before: String = world.to_canonical_json()
			var shell: PlayableShell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			if mode == "market":
				shell._show_local_market()
			else:
				shell._show_character()
			await process_frame
			if mode == "market":
				shell.market_window.tab_buttons.SUPPLY.button_pressed = true
				shell.market_window.tab_buttons.SUPPLY.pressed.emit()
				shell.market_window.row_buttons["bandage"].pressed.emit()
			for child: Node in shell.get_children():
				if child.get_script() != Sheet: continue
				child.inventory_category.select(5)
				child.inventory_search.text_changed.emit("")
				child.inventory_jump.pressed.emit()
				if mode == "detail": child.show_item_detail("bandage")
			for tick: int in range(12): await process_frame
			assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir,mode,root.size.x,root.size.y]) == OK)
			assert(world.to_canonical_json() == before)
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
