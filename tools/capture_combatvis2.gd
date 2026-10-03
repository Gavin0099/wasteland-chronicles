extends SceneTree

const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combatvis2_world.gd")
var engine := SimulationEngine.new()
var output_dir := OS.get_user_data_dir().path_join("captures/combatvis2-poses")
var pending_frames := 0
var count := 0

func _init() -> void:
	call_deferred("capture")

func phase_frame(phase: String, prefix: String) -> void:
	if phase not in ["crowbar_windup", "crowbar_strike", "machete_windup", "machete_strike", "saber_windup", "saber_strike", "hammer_windup", "hammer_strike", "revolver_aim", "revolver_flash", "shotgun_aim", "shotgun_flash", "brace", "enemy_hit", "hero_hit", "blocked", "enemy_windup", "enemy_fall", "hero_fall", "victory", "defeat"]:
		return
	pending_frames += 1
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%s_%dx%d.png" % [output_dir, prefix, phase, root.size.x, root.size.y]
	assert(root.get_texture().get_image().save_png(path) == OK)
	count += 1
	pending_frames -= 1

func pose_frame(value: String, actor: Node2D, prefix: String) -> void:
	if value == "rest":
		return
	pending_frames += 1
	await RenderingServer.frame_post_draw
	if is_instance_valid(actor) and actor.pose == value:
		assert(root.get_texture().get_image().save_png("%s/%s_pose_%s_%dx%d.png" % [output_dir, prefix, value, root.size.x, root.size.y]) == OK)
		count += 1
	pending_frames -= 1

func still_frame(label: String) -> void:
	for tick in range(5): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)
	count += 1

func make_screen(world: WorldState, prefix: String) -> Control:
	var ui := Screen.new()
	root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.setup(world, engine)
	ui.stage.feedback_phase.connect(phase_frame.bind(prefix))
	ui.stage.hero_actor.pose_changed.connect(pose_frame.bind(ui.stage.hero_actor, prefix + "_hero"))
	ui.stage.enemy_actor.pose_changed.connect(pose_frame.bind(ui.stage.enemy_actor, prefix + "_enemy"))
	return ui

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for weapon in Fixture.Weapons:
			var world := Fixture.create(weapon, engine)
			var ui := make_screen(world, weapon)
			await still_frame(weapon + "_idle")
			var twin := world.duplicate_state()
			var payload: Dictionary = ui.payload_for("SHOOT" if weapon in ["old_revolver", "short_shotgun"] else "ATTACK")
			assert(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, payload)).success)
			await ui.perform(payload)
			assert(twin.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text())
			if weapon == "crowbar":
				await ui.perform(ui.payload_for("ATTACK"))
				await still_frame("dog_victory_result")
				await ui.perform(ui.payload_for("CONFIRM"))
				await still_frame("confirmed_victory")
			for button in ui.buttons.values():
				assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()))
			ui.queue_free()
			await process_frame
		var world := Fixture.create("sledgehammer", engine, "camp")
		var ui := make_screen(world, "heavy")
		await still_frame("heavy_idle")
		await ui.perform(ui.payload_for("DEFEND"))
		await ui.perform(ui.payload_for("DEFEND"))
		await still_frame("prepared_heavy_charge")
		await ui.perform(ui.payload_for("DEFEND"))
		await still_frame("heavy_blocked")
		ui.queue_free()
		await process_frame
		world = Fixture.create("sledgehammer", engine)
		ui = make_screen(world, "victory")
		await still_frame("victory_before")
		while not world.field_state.battle.is_empty():
			await ui.perform(ui.payload_for("ATTACK"))
		await still_frame("victory_result")
		ui.queue_free()
		await process_frame
		world = Fixture.create("old_revolver", engine)
		world.player.field_kit.hp = 2
		ui = make_screen(world, "defeat")
		await still_frame("defeat_before")
		await ui.perform(ui.payload_for("ATTACK"))
		await still_frame("defeat_alive_result")
		ui.queue_free()
		await process_frame
		world = Fixture.create("old_revolver", engine, "camp")
		ui = make_screen(world, "empty")
		await still_frame("gun_before")
		await ui.perform(ui.payload_for("SHOOT"))
		await ui.perform(ui.payload_for("SHOOT"))
		await still_frame("empty_gun")
		ui.reduce_motion.button_pressed = true
		await ui.perform(ui.payload_for("DEFEND"))
		await still_frame("reduced_brace")
		ui.queue_free()
		await process_frame
	while pending_frames > 0: await process_frame
	print("CAPTURED %d actual frames: %s" % [count, output_dir])
	quit(0)
