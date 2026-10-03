extends SceneTree

const Stage = preload("res://ui/components/battle_stage.gd")
const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combatvis2_world.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("IDLE-CONTINUITY: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for enemy_id: String in ["feral_dog", "bandit", "heavy_raider"]:
			var stage: Control = Stage.new()
			root.add_child(stage)
			stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			stage.configure_isometric(true)
			check(stage.configure(enemy_id, "short_shotgun", enemy_id != "feral_dog"), "registered cast setup")
			await process_frame
			for actor: Stage.ActorNode in [stage.hero_actor, stage.enemy_actor]:
				actor.hold_pose("rest")
				var resting_texture: Texture2D = actor.body.texture
				var resting_scale: Vector2 = actor.body.scale
				var resting_foot: Vector2 = actor.to_global(actor.get_local_foot_anchor())
				var greatest_height: float = resting_scale.y
				actor.play_pose("idle")
				# Sample both sides of the old 0.75s texture-swap boundary and several loops.
				for step: int in range(25):
					actor.anim_player.advance(0.125)
					check(actor.body.texture == resting_texture, "idle preserves the same silhouette and camera")
					check(is_equal_approx(actor.body.scale.x, resting_scale.x), "idle never changes body width")
					check(actor.body.scale.y >= resting_scale.y - 0.00001 and actor.body.scale.y <= resting_scale.y * 1.01, "breathing height stays within reviewed one-percent bound")
					check(actor.to_global(actor.get_local_foot_anchor()).distance_to(resting_foot) < 0.001 and actor.shadow.position == Vector2.ZERO, "feet and contact shadow stay planted")
					greatest_height = maxf(greatest_height, actor.body.scale.y)
				check(greatest_height > resting_scale.y, "idle retains observable breathing motion")
				actor.play_pose("hit_reaction")
				check(actor.body.texture != resting_texture, "real action texture remains available")
				actor.anim_player.advance(0.25)
				check(actor.body.texture == resting_texture and actor.body.scale.is_equal_approx(resting_scale), "action returns to exact resting proportions")
				actor.play_pose("idle")
				actor.anim_player.advance(0.75)
				actor.hold_pose("brace")
				var held_scale: Vector2 = actor.body.scale
				actor.anim_player.advance(1.0)
				check(not actor.anim_player.is_playing() and actor.body.scale.is_equal_approx(held_scale), "held pose cancels breathing immediately")
				actor.hold_pose("rest")
				check(actor.body.texture == resting_texture and actor.body.scale.is_equal_approx(resting_scale), "hold restores exact original dimensions")
			stage.resume_idle()
			stage.hero_actor.anim_player.advance(0.75)
			stage.enemy_actor.anim_player.advance(0.75)
			root.size = resolution - Vector2i(96, 54)
			await process_frame
			for actor: Stage.ActorNode in [stage.hero_actor, stage.enemy_actor]:
				check(actor.body.texture == actor.texture_ref and actor.body.scale.y <= actor.body.scale.x * 1.01, "live resize keeps original art and bounded proportions")
				check(actor.get_local_foot_anchor().length() < 0.001, "resize keeps feet planted during breathing")
				var resized_scale: Vector2 = actor.body.scale
				for arrange_repeat: int in range(3): stage.arrange()
				check(actor.body.scale.is_equal_approx(resized_scale), "repeated layout never accumulates breathing deformation")
			root.size = resolution
			await process_frame
			stage.reduced_motion = true
			for actor: Stage.ActorNode in [stage.hero_actor, stage.enemy_actor]:
				check(not actor.anim_player.is_playing() and actor.body.texture == actor.texture_ref, "reduced motion uses stationary original art")
				check(is_equal_approx(actor.body.scale.x, actor.body.scale.y), "reduced motion clears deformation")
			stage.free()
	# Real presentation/direct-engine and checked-load tracks remain deterministic.
	var normal_sha: String = ""
	for reduced: bool in [false, true]:
		var world: WorldState = Fixture.create("scrap_machete", engine)
		var initial: String = world.to_canonical_json()
		var restored: Dictionary = WorldState.from_json_checked(initial)
		check(restored.success, "checked-load starting track")
		var twin: WorldState = restored.world
		var ui: Control = Screen.new()
		root.add_child(ui)
		ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.setup(world, engine)
		ui.reduce_motion.button_pressed = reduced
		await process_frame
		ui.stage.hero_actor.anim_player.advance(0.8)
		check(world.to_canonical_json() == initial, "idle cannot change world state")
		var payload: Dictionary = ui.payload_for("DEFEND")
		check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, payload)).success, "real direct-engine defense")
		await ui.perform(payload)
		check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "UI/checked-load twin SHA-256 parity")
		if reduced:
			check(world.to_canonical_json().sha256_text() == normal_sha, "normal/reduced motion SHA-256 parity")
		else:
			normal_sha = world.to_canonical_json().sha256_text()
		check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "global invariants on both tracks")
		check(ui.stage.hero_actor.body.texture == ui.stage.hero_actor.texture_ref, "committed defense resumes the same resting identity")
		var saved: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		check(saved.success and saved.world.to_canonical_json() == world.to_canonical_json(), "result persists exactly")
		ui.queue_free()
		await process_frame
	print("Combat idle continuity: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
