class_name BattleMotionDirector
extends RefCounted

# ==============================================================================
# BVIS-2A: BATTLE MOTION DIRECTOR (Receipt-driven Motion Grammar)
# ==============================================================================
# Pure presentation director.
#
# HARD GATES & INVARIANTS:
#   1. Receipt Authority: Reads submitted simulation receipt. 0 damage calculation,
#      0 state modification.
#   2. ActorRoot Integrity: World translations operate strictly on ActorNode.position;
#      AnimationPlayer manages local Body/Weapon posture only.
#   3. Shared Grammar: Dog, Bandit, and Heavy Raider share the 5 motion tokens.
#   4. Deterministic Presentation: Identical receipt -> identical motion sequence.
#   5. No global Engine.time_scale: All pauses are local Tweener intervals.
# ==============================================================================

const EnemyCatalogue = preload("res://simulation/enemy_catalogue.gd")

const TOKEN_PLAYER_ATTACK := "PLAYER_ATTACK"
const TOKEN_PLAYER_BRACE := "PLAYER_BRACE"
const TOKEN_ENEMY_ATTACK := "ENEMY_ATTACK"
const TOKEN_ENEMY_HEAVY_CHARGE := "ENEMY_HEAVY_CHARGE"
const TOKEN_ENEMY_HEAVY_RELEASE := "ENEMY_HEAVY_RELEASE"
const TOKEN_FLEE := "FLEE"

static func direct_turn(stage: Control, receipt: Dictionary) -> void:
	if stage == null or not is_instance_valid(stage):
		return

	var command: String = receipt.get("command", "ATTACK")
	var dealt: int = int(receipt.get("dealt", 0))
	var taken: int = int(receipt.get("taken", 0))
	var enemy_id: String = receipt.get("enemy_id", stage.current_enemy_id)
	var turn: int = int(receipt.get("turn", 1))

	# Determine if enemy attack this turn is heavy
	var is_heavy: bool = receipt.get("is_heavy", false)
	if not receipt.has("is_heavy") and enemy_id != "":
		var action: Dictionary = EnemyCatalogue.action_for(enemy_id, turn)
		is_heavy = bool(action.get("heavy", false))

	# Determine if next turn is heavy telegraph
	var next_heavy: bool = receipt.get("next_heavy", false)
	if not receipt.has("next_heavy") and enemy_id != "":
		var next_act: Dictionary = EnemyCatalogue.action_for(enemy_id, turn + 1)
		next_heavy = bool(next_act.get("heavy", false))

	# Profile retrieval
	var profiles: Dictionary = stage.VISUAL_PROFILES
	var enemy_prof: Dictionary = profiles.get(enemy_id, {})
	var hero_prof: Dictionary = profiles.get("drifter", {})

	var enemy_speed: float = float(enemy_prof.get("attack_speed", 1.0))
	var enemy_lunge_ratio: float = float(enemy_prof.get("lunge_ratio", 0.38))
	var hero_recoil_strength: float = float(enemy_prof.get("recoil_strength", 6.0))
	var enemy_heavy_capable: bool = bool(enemy_prof.get("heavy_capable", false))

	# Reduced motion path: skip lunges & big translations, resolve cleanly
	if stage.reduced_motion:
		if command == "DEFEND":
			stage.spawn_damage_popup(stage.hero_actor, taken, is_heavy, true)
		elif taken > 0:
			stage.spawn_damage_popup(stage.hero_actor, taken, is_heavy, false)
		if dealt > 0:
			stage.spawn_damage_popup(stage.enemy_actor, dealt, false, false)
		var quick_tween := stage.create_tween()
		if command == "DEFEND":
			quick_tween.tween_property(stage.hero, "modulate", Color(1.10, 1.05, 0.82), 0.08)
			quick_tween.tween_property(stage.hero, "modulate", Color.WHITE, 0.08)
		elif command == "ATTACK" and dealt > 0:
			quick_tween.tween_property(stage.enemy, "modulate", Color(0.76, 0.68, 0.60), 0.06)
			quick_tween.tween_property(stage.enemy, "modulate", Color.WHITE, 0.08)
		quick_tween.tween_interval(0.12)
		await quick_tween.finished
		return

	stage.arrange()
	var motion := stage.create_tween()

	# --------------------------------------------------------------------------
	# 1. PLAYER ACTION TOKEN
	# --------------------------------------------------------------------------
	if command == "ATTACK":
		# TOKEN: PLAYER_ATTACK
		var recoil := Vector2(-12, 3)
		var lunge: Vector2 = stage.hero_origin.lerp(stage.enemy_origin, 0.52)

		# Step 1a: Recoil
		motion.tween_property(stage.hero_actor, "position", stage.hero_origin + recoil, 0.09)
		motion.parallel().tween_property(stage.hero_actor, "rotation", -0.04, 0.09)
		if stage.hero_actor.anim_player != null and stage.hero_actor.anim_player.has_animation("attack_pose"):
			stage.hero_actor.anim_player.play("attack_pose")

		# Step 1b: Lunge forward
		motion.tween_property(stage.hero_actor, "position", lunge, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		motion.parallel().tween_property(stage.hero_actor, "rotation", 0.07, 0.13)

		# Step 1c: Impact on enemy
		if dealt > 0:
			motion.tween_property(stage.enemy, "modulate", Color(0.76, 0.68, 0.60), 0.06)
			motion.parallel().tween_property(stage.enemy_actor, "position", stage.enemy_origin + Vector2(7, -3), 0.06)
			if stage.enemy_actor.anim_player != null and stage.enemy_actor.anim_player.has_animation("hit_reaction"):
				stage.enemy_actor.anim_player.play("hit_reaction")
			# G2: Damage ownership - spawn gold popup directly over enemy
			motion.tween_callback(func(): stage.spawn_damage_popup(stage.enemy_actor, dealt, false, false))
			# G3: Impact hit stop interval (0.04s)
			motion.tween_interval(0.04)

		# Step 1d: Return to origin
		motion.tween_property(stage.hero_actor, "position", stage.hero_origin, 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		motion.parallel().tween_property(stage.hero_actor, "rotation", 0.0, 0.19)
		motion.parallel().tween_property(stage.enemy_actor, "position", stage.enemy_origin, 0.19)
		motion.parallel().tween_property(stage.enemy, "modulate", Color.WHITE, 0.19)

	elif command == "DEFEND":
		# TOKEN: PLAYER_BRACE
		if stage.hero_actor.anim_player != null and stage.hero_actor.anim_player.has_animation("brace"):
			stage.hero_actor.anim_player.play("brace")
		motion.tween_property(stage.hero, "modulate", Color(1.12, 1.04, 0.80), 0.12)
		motion.tween_property(stage.hero, "modulate", Color.WHITE, 0.12)

	# --------------------------------------------------------------------------
	# 2. ENEMY COUNTER-ACTION TOKEN
	# --------------------------------------------------------------------------
	if (taken > 0 or command == "DEFEND") and command != "FLEE":
		var is_defending := (command == "DEFEND")

		if is_heavy and enemy_heavy_capable:
			# TOKEN: ENEMY_HEAVY_RELEASE
			var pounce_heavy: Vector2 = stage.enemy_origin.lerp(stage.hero_origin, 0.44)
			var heavy_impact_recoil: Vector2 = Vector2(-hero_recoil_strength * 3.0, 6) if not is_defending else Vector2(-hero_recoil_strength * 0.45, 1)

			if stage.enemy_actor.anim_player != null and stage.enemy_actor.anim_player.has_animation("heavy_release"):
				stage.enemy_actor.anim_player.play("heavy_release")

			motion.tween_property(stage.enemy_actor, "position", pounce_heavy, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			motion.parallel().tween_property(stage.enemy_actor, "rotation", -0.10, 0.15)

			# Impact on hero with G4 DEFEND Contrast
			if is_defending:
				# Defended heavy hit: subtle recoil, shield flash, maintain brace pose
				motion.tween_property(stage.hero, "modulate", Color(1.15, 1.08, 0.85), 0.07)
				motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin + heavy_impact_recoil, 0.07)
				if stage.hero_actor.anim_player != null and stage.hero_actor.anim_player.has_animation("brace"):
					stage.hero_actor.anim_player.play("brace")
				# G2: Damage popup over hero with blunted defend indicator
				motion.tween_callback(func(): stage.spawn_damage_popup(stage.hero_actor, taken, true, true))
				# G3: Hit stop interval (0.04s)
				motion.tween_interval(0.04)
			else:
				# Unbraced heavy hit: violent recoil (-18px), damage flash, staggered hit_reaction
				motion.tween_property(stage.hero, "modulate", Color(0.85, 0.38, 0.32), 0.07)
				motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin + heavy_impact_recoil, 0.07)
				if stage.hero_actor.anim_player != null and stage.hero_actor.anim_player.has_animation("hit_reaction"):
					stage.hero_actor.anim_player.play("hit_reaction")
				# G2: Critical damage popup over hero
				motion.tween_callback(func(): stage.spawn_damage_popup(stage.hero_actor, taken, true, false))
				# G3: Heavy impact hit stop interval (0.06s)
				motion.tween_interval(0.06)

			# Return to origin
			motion.tween_property(stage.enemy_actor, "position", stage.enemy_origin, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			motion.parallel().tween_property(stage.enemy_actor, "rotation", 0.0, 0.22)
			motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin, 0.22)
			motion.parallel().tween_property(stage.hero, "modulate", Color.WHITE, 0.22)

		else:
			# TOKEN: ENEMY_ATTACK (Normal Attack)
			var pounce_dur: float = 0.13 / enemy_speed
			var ret_dur: float = 0.18 / enemy_speed
			var pounce: Vector2 = stage.enemy_origin.lerp(stage.hero_origin, enemy_lunge_ratio)
			var normal_recoil: Vector2 = Vector2(-hero_recoil_strength, 3) if not is_defending else Vector2(-hero_recoil_strength * 0.35, 1)

			if stage.enemy_actor.anim_player != null and stage.enemy_actor.anim_player.has_animation("attack_pose"):
				stage.enemy_actor.anim_player.play("attack_pose")

			motion.tween_property(stage.enemy_actor, "position", pounce, pounce_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			motion.parallel().tween_property(stage.enemy_actor, "rotation", -0.07, pounce_dur)

			# Impact on hero
			if is_defending:
				motion.tween_property(stage.hero, "modulate", Color(1.10, 1.05, 0.82), 0.06)
				motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin + normal_recoil, 0.06)
				if stage.hero_actor.anim_player != null and stage.hero_actor.anim_player.has_animation("brace"):
					stage.hero_actor.anim_player.play("brace")
				motion.tween_callback(func(): stage.spawn_damage_popup(stage.hero_actor, taken, false, true))
				motion.tween_interval(0.03)
			else:
				motion.tween_property(stage.hero, "modulate", Color(0.76, 0.68, 0.60), 0.06)
				motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin + normal_recoil, 0.06)
				if stage.hero_actor.anim_player != null and stage.hero_actor.anim_player.has_animation("hit_reaction"):
					stage.hero_actor.anim_player.play("hit_reaction")
				motion.tween_callback(func(): stage.spawn_damage_popup(stage.hero_actor, taken, false, false))
				motion.tween_interval(0.04)

			# Return to origin
			motion.tween_property(stage.enemy_actor, "position", stage.enemy_origin, ret_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			motion.parallel().tween_property(stage.enemy_actor, "rotation", 0.0, ret_dur)
			motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin, ret_dur)
			motion.parallel().tween_property(stage.hero, "modulate", Color.WHITE, ret_dur)

	# --------------------------------------------------------------------------
	# 3. TELEGRAPH TOKEN (If next turn is heavy attack)
	# --------------------------------------------------------------------------
	if next_heavy and enemy_heavy_capable and stage.enemy_alive:
		# TOKEN: ENEMY_HEAVY_CHARGE
		if stage.enemy_actor.anim_player != null and stage.enemy_actor.anim_player.has_animation("heavy_charge"):
			stage.enemy_actor.anim_player.play("heavy_charge")

	# --------------------------------------------------------------------------
	# 4. FLEE TOKEN
	# --------------------------------------------------------------------------
	if command == "FLEE":
		# TOKEN: FLEE
		motion.tween_property(stage.hero_actor, "position", stage.hero_origin + Vector2(-100, 35), 0.25)
		motion.parallel().tween_property(stage.hero_actor, "modulate:a", 0.0, 0.25)

	# --------------------------------------------------------------------------
	# 5. COMPLETION
	# --------------------------------------------------------------------------
	motion.tween_interval(0.12)
	await motion.finished

	# Invariant safety: Ensure actors return to exact rest positions
	stage.hero_actor.position = stage.hero_origin
	stage.enemy_actor.position = stage.enemy_origin
	stage.hero_actor.rotation = 0.0
	stage.enemy_actor.rotation = 0.0
