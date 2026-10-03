extends SceneTree

const Fixture = preload("res://tests/fixtures/gear2c_world.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/gear2c")

func _init() -> void:
	call_deferred("capture")

func frame(label: String) -> void:
	for step: int in range(12):
		await process_frame
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var engine: SimulationEngine = SimulationEngine.new()
		var world: WorldState = Fixture.fresh()
		for id: String in ["ballistic_vest", "reinforced_travel_backpack", "repair_toolbox", "simple_meter"]:
			assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success)
		assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"ballistic_vest", "body")).success)
		assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"reinforced_travel_backpack", "back")).success)
		var shell: PlayableShell = PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_character()
		await frame("equipped_sheet")
		shell.queue_free()
		await process_frame
		Fixture.road_battle(world)
		var field: Control = FieldScreen.new()
		root.add_child(field)
		field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		field.setup(world, engine)
		await frame("armored_battle")
		field.queue_free()
		await process_frame
		for mode: String in ["armory_tool_missing", "armory_calibration", "pump_methods", "pump_repaired"]:
			world = Fixture.armory("wrench") if mode.begins_with("armory") else Fixture.repair_site("precision_repair_kit")
			if mode == "armory_calibration":
				world.player.pickup_item("military_electronic_tools")
				world.player.capability._data.skill_ranks.ELECTRONICS = 3
			if mode.begins_with("pump"):
				world.player.capability._data.skill_ranks.MECHANICS = 3
				world.player.capability._data.skill_ranks.ELECTRONICS = 2
				world.player.pickup_item("electronic_repair_kit")
			if mode == "pump_repaired":
				assert(Fixture.answer(world, &"OVERHAUL_PUMP").success)
			shell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			await frame(mode)
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
