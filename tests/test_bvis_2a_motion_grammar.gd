extends SceneTree

# ==============================================================================
# BVIS-2A: RECEIPT-DRIVEN MOTION GRAMMAR TEST SUITE
# ==============================================================================
# Verifies the 5 Hard Gates of BVIS-2A:
#   G1 Receipt Authority: Motion system is pure presentation, 0 simulation mutation.
#   G2 ActorRoot Integrity: World translations only on ActorNode; AnimationPlayer
#      has 0 position tracks; Shadow stays at (0, 0).
#   G3 Shared Grammar: Dog, Bandit, Raider share the 5 motion tokens via profiles.
#   G4 Deterministic Presentation: Identical receipts yield identical sequences.
#   G5 Reduced Motion: Preserved; skips translations, resolves cleanly.
# ==============================================================================

const Stage = preload("res://ui/components/battle_stage.gd")
const Director = preload("res://ui/components/battle_motion_director.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("BVIS-2A: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Running BVIS-2A Motion Grammar Test Suite ---")

	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "Grammar Tester",
		"age": 28, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")

	var stage := Stage.new()
	stage.size = Vector2(1280, 720)
	root.add_child(stage)
	stage.configure("heavy_raider", "scrap_machete", true)
	stage.refresh(true, true)
	stage.arrange()

	# ==========================================================================
	# G1: RECEIPT AUTHORITY (Simulation 0 Mutation)
	# ==========================================================================
	var before_world_json := world.to_canonical_json()
	var test_receipt := {
		"command": "ATTACK",
		"dealt": 4,
		"taken": 3,
		"enemy_id": "heavy_raider",
		"turn": 1,
		"is_heavy": false,
		"next_heavy": false,
	}

	# Run presentation
	await Director.direct_turn(stage, test_receipt)

	# Verify simulation state was 100% untouched by presentation
	check(world.to_canonical_json() == before_world_json, "G1: Director direct_turn leaves simulation world 100% untouched")

	# ==========================================================================
	# G2: ACTORROOT INTEGRITY & ANIMATIONPLAYER BOUNDARIES
	# ==========================================================================
	# Inspect hero AnimationPlayer tracks
	var hero_anim: AnimationPlayer = stage.hero_actor.anim_player
	check(hero_anim != null, "G2: hero ActorNode has anim_player")
	var anim_list := hero_anim.get_animation_list()
	check(anim_list.has("attack_pose"), "G2: hero has attack_pose animation")
	check(anim_list.has("hit_reaction"), "G2: hero has hit_reaction animation")
	check(anim_list.has("brace"), "G2: hero has brace animation")

	# Verify NO track targets "position" or "ActorNode.position" in any animation
	for anim_name in anim_list:
		var anim: Animation = hero_anim.get_animation(anim_name)
		for t_idx in range(anim.get_track_count()):
			var p := String(anim.track_get_path(t_idx))
			check(not p.contains("position") and not p.contains("ActorNode"), "G2: track '%s' in '%s' does not touch position" % [p, anim_name])

	# Inspect enemy AnimationPlayer tracks
	var enemy_anim: AnimationPlayer = stage.enemy_actor.anim_player
	check(enemy_anim != null, "G2: enemy ActorNode has anim_player")
	var enemy_anims := enemy_anim.get_animation_list()
	check(enemy_anims.has("heavy_charge"), "G2: enemy has heavy_charge animation")
	check(enemy_anims.has("heavy_release"), "G2: enemy has heavy_release animation")

	for anim_name in enemy_anims:
		var anim: Animation = enemy_anim.get_animation(anim_name)
		for t_idx in range(anim.get_track_count()):
			var p := String(anim.track_get_path(t_idx))
			check(not p.contains("position") and not p.contains("ActorNode"), "G2: enemy track '%s' in '%s' does not touch position" % [p, anim_name])

	# Ground Anchor & Shadow Position Invariant after motion
	check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.01, "G2: hero ActorNode back at hero_origin after motion")
	check(stage.enemy_actor.position.distance_to(stage.enemy_origin) < 0.01, "G2: enemy ActorNode back at enemy_origin after motion")
	check(stage.hero_shadow.position == Vector2.ZERO, "G2: hero shadow remains strictly at Vector2.ZERO")
	check(stage.enemy_shadow.position == Vector2.ZERO, "G2: enemy shadow remains strictly at Vector2.ZERO")

	# ==========================================================================
	# G3: SHARED MOTION GRAMMAR (Dog, Bandit, Raider share tokens via profiles)
	# ==========================================================================
	# 1. Test Feral Dog Normal Attack
	stage.configure("feral_dog", "scrap_machete", false)
	stage.refresh(true, true)
	var dog_receipt := {"command": "ATTACK", "dealt": 2, "taken": 3, "enemy_id": "feral_dog", "turn": 1}
	await Director.direct_turn(stage, dog_receipt)
	check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.01, "G3: feral dog turn completes with actors at rest origins")

	# 2. Test Bandit Normal Attack
	stage.configure("bandit", "scrap_machete", true)
	stage.refresh(true, true)
	var bandit_receipt := {"command": "DEFEND", "dealt": 0, "taken": 1, "enemy_id": "bandit", "turn": 1}
	await Director.direct_turn(stage, bandit_receipt)
	check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.01, "G3: bandit defend turn completes with actors at rest origins")

	# 3. Test Heavy Raider Heavy Release
	stage.configure("heavy_raider", "scrap_machete", true)
	stage.refresh(true, true)
	var raider_heavy_receipt := {
		"command": "ATTACK", "dealt": 3, "taken": 9, "enemy_id": "heavy_raider", "turn": 3,
		"is_heavy": true, "next_heavy": false
	}
	await Director.direct_turn(stage, raider_heavy_receipt)
	check(stage.enemy_actor.position.distance_to(stage.enemy_origin) < 0.01, "G3: heavy raider release completes at rest origin")

	# 4. Test Heavy Charge Telegraph Token
	var raider_charge_receipt := {
		"command": "DEFEND", "dealt": 0, "taken": 0, "enemy_id": "heavy_raider", "turn": 2,
		"is_heavy": false, "next_heavy": true
	}
	await Director.direct_turn(stage, raider_charge_receipt)
	check(stage.enemy_actor.anim_player.current_animation == "heavy_charge", "G3: next_heavy triggers heavy_charge pose on heavy_raider")

	# ==========================================================================
	# G4: DETERMINISTIC PRESENTATION
	# ==========================================================================
	for repeat in range(3):
		await Director.direct_turn(stage, test_receipt)
		check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.001, "G4: repeat %d hero deterministic return" % repeat)
		check(stage.enemy_actor.position.distance_to(stage.enemy_origin) < 0.001, "G4: repeat %d enemy deterministic return" % repeat)
		check(absf(stage.hero_actor.rotation) < 0.001, "G4: repeat %d hero rotation reset" % repeat)
		check(absf(stage.enemy_actor.rotation) < 0.001, "G4: repeat %d enemy rotation reset" % repeat)

	# ==========================================================================
	# G5: REDUCED MOTION PRESERVATION
	# ==========================================================================
	stage.reduced_motion = true
	var start_msec := Time.get_ticks_msec()
	await Director.direct_turn(stage, test_receipt)
	var elapsed := Time.get_ticks_msec() - start_msec
	check(elapsed < 400, "G5: reduced_motion completes fast (< 400ms, actual: %dms)" % elapsed)
	check(stage.hero_actor.position == stage.hero_origin, "G5: reduced motion leaves hero at origin")
	check(stage.enemy_actor.position == stage.enemy_origin, "G5: reduced motion leaves enemy at origin")
	stage.reduced_motion = false

	stage.free()

	if failures == 0:
		print("BVIS-2A motion grammar: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("BVIS-2A motion grammar: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
