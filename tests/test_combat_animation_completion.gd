extends SceneTree

const Stage = preload("res://ui/components/battle_stage.gd")
const Poses = preload("res://ui/components/battle_pose_library.gd")
const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combatvis2_world.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ANIMATION-COMPLETE: " + message)

func _init() -> void:
	call_deferred("run")

func screen(world: WorldState, reduced: bool = false) -> Control:
	var ui: Control = Screen.new()
	root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.setup(world, engine)
	ui.reduce_motion.button_pressed = reduced
	return ui

func run() -> void:
	root.size = Vector2i(1280, 720)
	check(Poses.load_atlas("res://ui/assets/combat/poses/missing.png") == null, "missing art fails closed") # lint:ignore res_path
	check(Poses.frame("unknown", "step_a").is_empty() and Poses.frame("drifter", "unknown").is_empty(), "unknown pose fails closed")
	var new_frames: int = 0
	var packed: bool = "--packed-assets" in OS.get_cmdline_user_args()
	for actor_id in Poses.FRAMES:
		for pose in Poses.FRAMES[actor_id]:
			var spec: Array = Poses.FRAMES[actor_id][pose]
			var frame: Dictionary = Poses.frame(actor_id, pose)
			check(not frame.is_empty() and frame.texture.get_width() > 0, actor_id + "/" + pose + " loadable frame")
			if frame.is_empty():
				continue
			var texture: AtlasTexture = frame.texture
			check(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region), "atlas region inside actual image")
			if spec.size() > 4:
				new_frames += 1
				var path: String = "res://ui/assets/combat/poses/%s.png" % spec[4]
				check(ResourceLoader.exists(path), "imported resource exists")
				if packed:
					check(not FileAccess.file_exists(path), "packed run uses remapped texture, no raw source PNG")
	check(new_frames == 36, "reviewed six atlases supply exactly 36 new poses")
	var gun_stage: Control = Stage.new()
	root.add_child(gun_stage)
	gun_stage.size = Vector2(900, 460)
	gun_stage.configure("bandit", "short_shotgun", true)
	await process_frame
	gun_stage.hero_actor.hold_pose("shotgun_aim")
	var body: Sprite2D = gun_stage.hero_actor.body
	# Independently measured forward support fist on the reviewed original PNG.
	var support: Vector2 = body.to_global(body.offset + Vector2(1390, 145) - Vector2(1079, 52))
	var muzzle: Vector2 = gun_stage.weapon.to_global(gun_stage.hero_actor.muzzle_local())
	check(muzzle.x > support.x + gun_stage.hero_actor.target_height * 0.04, "shotgun muzzle clears the forward support hand")
	gun_stage.free()
	var world: WorldState = Fixture.create("scrap_machete", engine)
	var before: String = world.to_canonical_json()
	var ui: Control = screen(world)
	await process_frame
	ui.stage.hero_actor.anim_player.advance(0.8)
	check(ui.stage.hero_actor.body.texture == ui.stage.hero_actor.texture_ref and ui.stage.hero_actor.idle_breath_amount > 0.0, "waiting hero breathes without changing its resting identity")
	check(world.to_canonical_json() == before, "idle is read-only")
	ui.reduce_motion.button_pressed = true
	check(not ui.stage.hero_actor.anim_player.is_playing() and ui.stage.hero_actor.pose == "rest", "reduced motion stops idle immediately")
	ui.queue_free()
	await process_frame
	for weapon in Fixture.Weapons:
		var normal: String = ""
		for reduced in [false, true]:
			world = Fixture.create(weapon, engine)
			ui = screen(world, reduced)
			await process_frame
			var poses: Array[String] = []
			var phases: Array[String] = []
			ui.stage.hero_actor.pose_changed.connect(func(value: String): poses.append(value))
			ui.stage.feedback_phase.connect(func(value: String): phases.append(value))
			var command: String = "SHOOT" if weapon in ["old_revolver", "short_shotgun"] else "ATTACK"
			var payload: Dictionary = ui.payload_for(command)
			var reference: WorldState = world.duplicate_state()
			check(engine.commit_player_intent(reference, PlayerIntent.create_field_action(reference.player.npc_id, payload)).success, "real direct-engine action")
			await ui.perform(payload)
			check(reference.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text(), "UI/direct-engine SHA-256 parity")
			check(engine.validate_invariants(world) == "", "global invariants")
			var restored: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
			check(restored.success and restored.world.to_canonical_json() == world.to_canonical_json(), "checked persistence")
			if reduced:
				check(world.to_canonical_json().sha256_text() == normal, "normal/reduced SHA-256 parity")
				check(not phases.has("hero_approach") and not phases.has("hero_recover"), "reduced motion skips travelling transitions")
			else:
				normal = world.to_canonical_json().sha256_text()
				if command == "ATTACK":
					check(poses.has("step_a") and poses.has("step_b"), "real articulated approach stride")
					check(phases.find("hero_approach") < phases.find(Poses.weapon_style(weapon).name + "_strike"), "approach precedes impact")
					check(poses.has(Poses.attack_poses(Poses.weapon_style(weapon))[2]), "weapon-specific recovery texture")
				else:
					check(poses.has(Poses.gun_pose(Poses.weapon_style(weapon), true)) and poses.has("gun_recover"), "gun-specific recoil and recovery textures")
				if not world.field_state.battle.is_empty():
					check(ui.stage.hero_actor.anim_player.is_playing(), "nonterminal turn returns to breathing idle")
			ui.queue_free()
			await process_frame
	# Real FLEE receipts must never display an attack in either motion setting.
	for reduced in [false, true]:
		world = Fixture.create("scrap_machete", engine)
		ui = screen(world, reduced)
		await process_frame
		var poses: Array[String] = []
		ui.stage.hero_actor.pose_changed.connect(func(value: String): poses.append(value))
		var reference: WorldState = world.duplicate_state()
		var payload: Dictionary = ui.payload_for("FLEE")
		check(engine.commit_player_intent(reference, PlayerIntent.create_field_action(reference.player.npc_id, payload)).success, "real flee fixture")
		await ui.perform(payload)
		check(poses.has("retreat_a") and not poses.has("strike") and not poses.has("slash_strike"), "flee uses a retreat key pose")
		check(reduced or poses.has("retreat_b"), "normal flee alternates retreat feet")
		check(not ui.stage.hero_actor.visible and not ui.stage.hero_actor.anim_player.is_playing(), "escaped fighter remains offstage after result refresh")
		check(reference.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text(), "flee replay")
		check(engine.validate_invariants(world) == "", "flee invariants")
		ui.queue_free()
		await process_frame
	# Zero ammunition rejects without turn, recoil, flash or loss of HP.
	world = Fixture.create("old_revolver", engine, "camp")
	ui = screen(world)
	await process_frame
	await ui.perform(ui.payload_for("SHOOT"))
	await ui.perform(ui.payload_for("SHOOT"))
	before = world.to_canonical_json()
	var empty_phases: Array[String] = []
	ui.stage.feedback_phase.connect(func(value: String): empty_phases.append(value))
	await ui.perform(ui.payload_for("SHOOT"))
	check(world.to_canonical_json() == before and ui.stage.hero_actor.pose == "empty_gun", "rejected gun lowers via a true pose without a turn")
	check(not empty_phases.has("revolver_flash") and empty_phases.has("empty_weapon"), "empty gun has no fabricated flash")
	ui.queue_free()
	await process_frame
	# Every enemy's new half-collapse must precede the existing fallen result.
	for environment in ["shed", "highway", "camp"]:
		world = Fixture.create("crowbar" if environment == "shed" else "sledgehammer", engine, environment)
		ui = screen(world)
		await process_frame
		var enemy_poses: Array[String] = []
		ui.stage.enemy_actor.pose_changed.connect(func(value: String): enemy_poses.append(value))
		while not world.field_state.battle.is_empty():
			await ui.perform(ui.payload_for("ATTACK"))
		check(enemy_poses.has("kneel") and enemy_poses.find("kneel") < enemy_poses.find("fall"), "half-collapse precedes fallen enemy")
		check(ui.stage.enemy_actor.pose == "fall" and not ui.stage.enemy_actor.anim_player.is_playing(), "terminal enemy never resumes breathing")
		check(engine.validate_invariants(world) == "", "terminal invariants")
		ui.queue_free()
		await process_frame
	print("Combat animation completion: %s; assertions=%d failures=%d packed=%s" % ["PASS" if failures == 0 else "FAIL", assertions, failures, packed])
	quit(0 if failures == 0 else 1)
