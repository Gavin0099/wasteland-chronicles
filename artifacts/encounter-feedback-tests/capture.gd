extends SceneTree

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var engine := SimulationEngine.new()
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.debug_world_feed_enabled = false
	for mode in ["gains", "empty", "full"]:
		var w := S1WorldData.create_s1_world()
		engine.materialize_player(w, &"settlement:gray_valley", "Drifter", 26)
		w.player.inventory.water = 3
		w.player.inventory.food = 3
		if mode == "full":
			w.player.capacity_total = 6
		engine.begin_player_travel(w, PlayerIntent.create_travel(w.player.npc_id, &"settlement:new_hope"))
		w.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, 6 if mode == "empty" else 1, &"settlement:gray_valley", &"settlement:new_hope", 1)
		shell.setup(w, engine)
		shell.on_encounter_option_pressed("SEARCH")
		for i in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://artifacts/encounter-feedback-tests/%s.png" % mode
		root.get_texture().get_image().save_png(path)
		print("CAPTURED ", mode, " panel=", shell.encounter_panel.get_global_rect(), " button=", shell.encounter_options_box.get_child(0).get_global_rect())
	quit()
