extends "res://tests/test_open_cache_road_combat.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/open-cache-road-combat")
var captures: int = 0

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)
	captures += 1

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var world: WorldState = opened_camp()
		assert(failures == 0 and engine.validate_invariants(world) == "")
		var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		assert(loaded.success)
		var twin: WorldState = loaded.world
		var ui: Control = Screen.new()
		root.add_child(ui)
		ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.setup(world, engine)
		for tick: int in range(8): await process_frame
		assert(not ui.buttons.ATTACK.disabled and not ui.buttons.DEFEND.disabled and not ui.buttons.FLEE.disabled)
		await save_frame("opened_cache_enabled")
		for command: String in ["ATTACK", "FLEE"]:
			ui.reduce_motion.button_pressed = command == "FLEE"
			var intent: Dictionary = ui.payload_for(command)
			assert(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, intent)).success)
			await ui.perform(intent)
			parity(world, twin, "rendered road " + command)
			assert(failures == 0)
			await save_frame("after_" + command.to_lower())
		var confirm: Dictionary = ui.payload_for("CONFIRM")
		assert(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, confirm)).success)
		await ui.perform(confirm)
		parity(world, twin, "rendered restored home")
		assert(failures == 0 and world.field_state.opened and world.field_state.enemy_hp == 0)
		await process_frame
	print("CACHE-ROAD CAPTURE: %d actual frames -> %s" % [captures, output_dir])
	quit(0)
