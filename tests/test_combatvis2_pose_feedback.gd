extends SceneTree

const Screen = preload("res://ui/field_screen.gd")
const Stage = preload("res://ui/components/battle_stage.gd")
const Poses = preload("res://ui/components/battle_pose_library.gd")
const Fixture = preload("res://tests/fixtures/combatvis2_world.gd")
var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("POSE-FEEDBACK: " + message)

func _init() -> void:
	call_deferred("run")

func screen(world: WorldState, reduced: bool = false) -> Control:
	var ui := Screen.new()
	root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.setup(world, engine)
	ui.reduce_motion.button_pressed = reduced
	return ui

func run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := Stage.new()
	root.add_child(stage)
	stage.size = Vector2(900, 460)
	stage.configure("bandit", "scrap_machete", true)
	await process_frame
	for actor_id in ["drifter", "feral_dog", "bandit", "heavy_raider"]:
		var actor = stage.hero_actor if actor_id == "drifter" else stage.enemy_actor
		if actor_id != "drifter":
			stage.configure(actor_id, "scrap_machete", true)
		for pose in Poses.FRAMES[actor_id]:
			var original: Texture2D = actor.body.texture
			actor.hold_pose(pose)
			check(actor.body.texture is AtlasTexture, actor_id + "/" + pose + ": a true texture frame")
			check(actor.body.texture != original, actor_id + "/" + pose + ": different image")
			check(actor.get_local_foot_anchor().length() < 0.01, actor_id + "/" + pose + ": grounded frame")
			check(actor.shadow.position == Vector2.ZERO, "shadow stays at ground origin")
			if actor.is_hero and pose not in ["kneel", "fall"]:
				var size_px: Vector2 = actor.body.texture.get_size()
				var hand: Vector2 = actor.body.get_global_transform() * (actor.body.offset + size_px * actor.hand_uv)
				var grip: Vector2 = actor.weapon.get_global_transform() * Vector2.ZERO
				check(hand.distance_to(grip) < 0.01, "pose-specific grip stays in fist")
	stage.free()
	var styles: Array[String] = []
	for weapon in Fixture.Weapons:
		var style: Dictionary = Poses.weapon_style(weapon)
		styles.append(style.name)
		var normal_hash := ""
		for reduced in [false, true]:
			var world := Fixture.create(weapon, engine)
			var ui := screen(world, reduced)
			await process_frame
			await process_frame
			var phases: Array[String] = []
			var actual_poses: Array[String] = []
			ui.stage.hero_actor.pose_changed.connect(func(value: String): actual_poses.append(value))
			ui.stage.feedback_phase.connect(func(phase: String): phases.append(phase))
			var command := "SHOOT" if weapon in ["old_revolver", "short_shotgun"] else "ATTACK"
			var payload: Dictionary = ui.payload_for(command)
			var reference := world.duplicate_state()
			check(engine.commit_player_intent(reference, PlayerIntent.create_field_action(reference.player.npc_id, payload)).success, "independent engine track")
			var playback_hashes: Array[String] = []
			ui.stage.feedback_phase.connect(func(_phase: String): playback_hashes.append(world.to_canonical_json().sha256_text()))
			await ui.perform(payload)
			check(world.to_canonical_json().sha256_text() == reference.to_canonical_json().sha256_text(), weapon + ": UI/headless SHA-256 replay")
			check(not playback_hashes.is_empty() and playback_hashes.all(func(value: String): return value == reference.to_canonical_json().sha256_text()), "pose/effect playback cannot mutate committed world")
			check(engine.validate_invariants(world) == "", "global invariants")
			var saved := WorldState.from_json_checked(world.to_canonical_json())
			check(saved.success and saved.world.to_canonical_json() == world.to_canonical_json(), "checked persistence")
			if reduced:
				check(phases.has("reduced"), "reduced feedback completed")
				check(normal_hash == world.to_canonical_json().sha256_text(), "normal/reduced SHA-256 parity")
			else:
				normal_hash = world.to_canonical_json().sha256_text()
				check(phases.has(style.name + ("_aim" if command == "SHOOT" else "_windup")), weapon + ": authored anticipation")
				check(phases.has(style.name + ("_flash" if command == "SHOOT" else "_strike")), weapon + ": distinct weapon impact")
				check(phases.has("enemy_hit"), "receipt damage drives enemy hurt")
				var poses: Array[String] = Poses.attack_poses(style)
				check(actual_poses.has(Poses.gun_pose(style)) if command == "SHOOT" else actual_poses.has(poses[0]) and actual_poses.has(poses[1]), "actual playback changes articulated texture poses")
			check(ui.stage.hero_actor.position == ui.stage.hero_origin, "rest after feedback")
			check(Engine.time_scale == 1.0, "no global time scaling")
			ui.queue_free()
			await process_frame
	check(styles.size() == 6 and styles.count("hammer") == 1 and styles.count("shotgun") == 1, "six requested weapon presentations")
	# Real defense followed by another defense: visible non-stacking bonus with history collapsed.
	var world := Fixture.create("old_revolver", engine)
	var ui := screen(world, true)
	await process_frame
	await ui.perform(ui.payload_for("DEFEND"))
	check(not ui.history_toggle.button_pressed and ui.status_label.text.contains("已蓄勢 +2") and ui.buttons.DEFEND.text.contains("不累加"), "prepared +2 visible outside collapsed history")
	var prepared_damage: int = preload("res://simulation/field_adventure.gd").shot_damage(world)
	await ui.perform(ui.payload_for("DEFEND"))
	check(preload("res://simulation/field_adventure.gd").shot_damage(world) == prepared_damage, "actual repeated defense does not stack")
	ui.queue_free()
	await process_frame
	world = Fixture.create("old_revolver", engine)
	ui = screen(world, true)
	await process_frame
	# Real two-round gun depletion plus rejected third shot: no fabricated turn or flash.
	while not world.field_state.battle.is_empty() and world.player.item_inventory.quantity("revolver_round") > 0:
		await ui.perform(ui.payload_for("SHOOT"))
	if not world.field_state.battle.is_empty():
		var before := world.to_canonical_json()
		await ui.perform(ui.payload_for("SHOOT"))
		check(world.to_canonical_json() == before, "empty shot rejection is atomic")
		check(ui.stage.floating.visible and ui.stage.floating.text.contains("彈藥不足"), "empty gun feedback visible")
	ui.queue_free()
	await process_frame
	# Terminal victory and defeat use real result receipts; no implied road death.
	for victory in [true, false]:
		world = Fixture.create("sledgehammer" if victory else "crowbar", engine, "highway")
		if not victory:
			world = Fixture.create("old_revolver", engine)
			world.player.field_kit.hp = 2
		ui = screen(world, true)
		await process_frame
		while not world.field_state.battle.is_empty():
			await ui.perform(ui.payload_for("ATTACK"))
		var outcome: String = String(world.event_log[world.field_state.receipt].payload.outcome)
		for tick in range(5): await process_frame
		check(outcome == ("VICTORY" if victory else "DEFEAT"), "real terminal result fixture")
		check(ui.stage.enemy_actor.pose == "fall" if victory else ui.stage.hero_actor.pose == "fall", "terminal collapse held after refresh")
		check(ui.stage.enemy.visible if victory else world.player.field_kit.hp == 1, "victory floor sprite / surviving defeat truth")
		check(engine.validate_invariants(world) == "", "terminal global invariants")
		if victory:
			await ui.perform(ui.payload_for("CONFIRM"))
			check(ui.is_queued_for_deletion() and world.field_state.receipt < 0, "confirming a road victory closes its stage and clears its receipt")
		ui.queue_free()
		await process_frame
	# Interrupt actual committed UI playback by resize and removal. Re-entry remains usable.
	world = Fixture.create("scrap_machete", engine)
	ui = screen(world)
	await process_frame
	var reference := world.duplicate_state()
	var payload: Dictionary = ui.payload_for("ATTACK")
	engine.commit_player_intent(reference, PlayerIntent.create_field_action(reference.player.npc_id, payload))
	ui.perform(payload)
	await ui.stage.feedback_phase
	check(ui.stage.active_motion != null and ui.busy, "resize interrupts active playback")
	root.size = Vector2i(1152, 648)
	ui.stage.arrange() # Exercise the same layout callback in the headless harness.
	for tick in range(5): await process_frame
	check(not ui.busy, "resize releases waiting action")
	check(world.to_canonical_json().sha256_text() == reference.to_canonical_json().sha256_text(), "resize cannot undo or repeat committed action")
	var after := world.to_canonical_json()
	ui.queue_free()
	await process_frame
	ui = screen(world, true)
	await process_frame
	check(world.to_canonical_json() == after, "screen re-entry is read-only")
	ui.perform(ui.payload_for("DEFEND"))
	await ui.stage.feedback_phase
	ui.queue_free()
	await create_timer(0.3).timeout
	check(engine.validate_invariants(world) == "", "removed playback retains invariants")
	print("COMBAT-VIS-2 pose feedback: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
