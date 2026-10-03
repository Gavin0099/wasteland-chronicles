extends "res://tests/test_two_towns.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/two-towns")
var captures: int = 0

func _init() -> void:
	call_deferred("capture")

func frame(label: String, world: WorldState, twin: WorldState) -> void:
	var before: String = world.to_canonical_json()
	for tick: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)
	captures += 1
	assert(world.to_canonical_json() == before)
	parity(world, twin, label + " rendered read-only")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for spec: Dictionary in TOWN_SPECS:
			var world: WorldState = fresh_towns(spec.hub)
			var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
			walk_pair(world, twin, spec.id)
			var shell: PlayableShell = Shell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			await frame(String(spec.id).trim_prefix("settlement:") + "_scene", world, twin)
			assert(shell.desktop_scene_art.get_meta("scene_file") == String(Factions.TOWNS[spec.id].scene))
			assert(shell.desktop_scene_art.texture != null)
			shell._show_local_market()
			await frame(String(spec.id).trim_prefix("settlement:") + "_market", world, twin)
			shell.market_window.canceled.emit()
			await process_frame
			var entry: Dictionary = Board.postings(world, StringName(spec.id))[0]
			shell.quest_id_shown = entry.definition.id
			shell._on_quest_access_pressed()
			await frame(String(spec.id).trim_prefix("settlement:") + "_board", world, twin)
			shell.queue_free()
			await process_frame
		var world: WorldState = fresh_towns("settlement:gray_valley")
		var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
		var shell: PlayableShell = Shell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_desktop_details()
		shell.select_settlement("settlement:spring_ford")
		await frame("five_town_map_locked_route", world, twin)
		assert(shell.btn_travel.disabled and shell.lbl_settlement_details.text.contains("新希望"))
		shell.queue_free()
		await process_frame
		world = fresh_towns("settlement:spring_ford")
		twin = WorldState.from_json_checked(world.to_canonical_json()).world
		shell = Shell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_desktop_details()
		shell.select_settlement("settlement:iron_pass")
		assert(not shell.btn_travel.disabled and shell.btn_travel.text.contains("3 天"))
		await frame("cross_faction_supply_route", world, twin)
		shell.queue_free()
		await process_frame
		walk_pair(world, twin, "settlement:iron_pass", 3)
		shell = Shell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		await frame("cross_faction_arrival", world, twin)
		shell.queue_free()
		await process_frame
	print("Town captures: saves=%d assertions=%d failures=%d" % [captures, assertions, failures])
	quit(0 if failures == 0 else 1)
