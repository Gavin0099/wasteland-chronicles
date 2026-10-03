extends SceneTree

const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combatvis2_world.gd")
var engine: SimulationEngine = SimulationEngine.new()
var output_dir: String = OS.get_user_data_dir().path_join("captures/combat-idle-continuity")
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
		for environment: String in ["shed", "highway", "camp"]:
			var world: WorldState = Fixture.create("crowbar" if environment == "shed" else "scrap_machete", engine, environment)
			var unchanged: String = world.to_canonical_json()
			var ui: Control = Screen.new()
			root.add_child(ui)
			ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ui.setup(world, engine)
			for tick: int in range(8): await process_frame
			for actor: Node2D in [ui.stage.hero_actor, ui.stage.enemy_actor]:
				actor.play_pose("idle")
				actor.anim_player.pause()
			for phase: int in range(3):
				for actor: Node2D in [ui.stage.hero_actor, ui.stage.enemy_actor]:
					actor.anim_player.seek(float(phase) * 0.75, true)
				await save_frame(environment + "_idle_" + str(phase))
			assert(world.to_canonical_json() == unchanged)
			ui.reduce_motion.button_pressed = true
			await save_frame(environment + "_reduced")
			assert(world.to_canonical_json() == unchanged)
			ui.reduce_motion.button_pressed = false
			var twin: WorldState = world.duplicate_state()
			var payload: Dictionary = ui.payload_for("DEFEND")
			assert(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, payload)).success)
			await ui.perform(payload)
			assert(twin.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text())
			assert(engine.validate_invariants(world) == "")
			await save_frame(environment + "_after_defend")
			ui.queue_free()
			await process_frame
	print("IDLE-CONTINUITY CAPTURE: %d actual frames -> %s" % [captures, output_dir])
	quit(0)
