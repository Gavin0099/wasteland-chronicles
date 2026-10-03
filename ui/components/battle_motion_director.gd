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
	if not is_instance_valid(stage) or not stage.is_inside_tree():
		return
	stage.cancel_motion()
	var ticket: int = stage.motion_generation
	var tree: SceneTree = stage.get_tree()
	await tree.process_frame # Let first-frame container layout settle before motion.
	if not is_instance_valid(stage) or not stage.is_inside_tree() or ticket != stage.motion_generation:
		return
	stage.terminal_outcome = ""
	stage.floating.hide()
	stage.arrange()
	var command: String = String(receipt.get("command", "ATTACK"))
	var dealt: int = int(receipt.get("dealt", 0))
	var taken: int = int(receipt.get("taken", 0))
	var enemy_id: String = String(receipt.get("enemy_id", stage.current_enemy_id))
	var turn: int = int(receipt.get("turn", 1))
	var heavy: bool = bool(receipt.get("is_heavy", EnemyCatalogue.action_for(enemy_id, turn).get("heavy", false)))
	var next_heavy: bool = bool(receipt.get("next_heavy", EnemyCatalogue.action_for(enemy_id, turn + 1).get("heavy", false)))
	var outcome: String = String(receipt.get("outcome", ""))
	var style: Dictionary = stage.PoseLibrary.weapon_style(stage.current_weapon_id)
	var motion: Tween = stage.create_tween()
	stage.active_motion = motion
	if stage.reduced_motion:
		stage.hero_actor.hold_pose("brace" if command == "DEFEND" else ("aim" if command == "SHOOT" else "strike"))
		if dealt > 0:
			stage.spawn_damage_popup(stage.enemy_actor, dealt, false, false)
		if taken > 0 or command == "DEFEND":
			stage.spawn_damage_popup(stage.hero_actor, taken, heavy, command == "DEFEND")
		stage.feedback_phase.emit("reduced")
		motion.tween_interval(0.18)
	else:
		if command == "ATTACK":
			motion.tween_callback(func(): stage.hero_actor.play_attack(style); stage.feedback_phase.emit(style.name + "_windup"))
			motion.tween_property(stage.hero_actor, "position", stage.hero_origin + Vector2(-10, 2), float(style.windup))
			motion.tween_callback(func(): stage.feedback_phase.emit(style.name + "_strike"))
			motion.tween_property(stage.hero_actor, "position", stage.hero_origin.lerp(stage.enemy_origin, float(style.reach)), float(style.strike)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		elif command == "SHOOT":
			motion.tween_callback(func(): stage.hero_actor.hold_pose("aim"); stage.hero_actor.aim_weapon(); stage.feedback_phase.emit(style.name + "_aim"))
			motion.tween_interval(float(style.windup))
			motion.tween_callback(func(): stage.emit_weapon_fx(style.name, stage.hero_actor); stage.feedback_phase.emit(style.name + "_flash"))
			motion.tween_property(stage.hero_actor, "position", stage.hero_origin + Vector2(-12 if style.name == "shotgun" else -5, 0), float(style.strike))
		elif command == "DEFEND":
			motion.tween_callback(func(): stage.hero_actor.play_pose("brace"); stage.feedback_phase.emit("brace"))
			motion.tween_interval(0.18)
		if dealt > 0:
			motion.tween_callback(func():
				stage.enemy_actor.play_pose("hit_reaction")
				stage.spawn_damage_popup(stage.enemy_actor, dealt, false, false)
				if command == "ATTACK":
					stage.emit_weapon_fx(style.name, stage.enemy_actor)
				stage.feedback_phase.emit("enemy_hit"))
			motion.tween_property(stage.enemy_actor, "position", stage.enemy_origin + Vector2(7, -3), 0.04)
			motion.tween_interval(0.06 if style.name == "hammer" else 0.04)
		if command in ["ATTACK", "SHOOT"]:
			motion.tween_property(stage.hero_actor, "position", stage.hero_origin, float(style.recover))
			motion.parallel().tween_property(stage.enemy_actor, "position", stage.enemy_origin, float(style.recover))
			motion.tween_callback(func(): stage.hero_actor.hold_pose("rest"))
		# A killed opponent does not counterattack. Damage and terminal outcome
		# have already been committed by simulation before this presentation starts.
		if (taken > 0 or command == "DEFEND") and command != "FLEE" and outcome != "VICTORY":
			var profile: Dictionary = stage.VISUAL_PROFILES.get(enemy_id, {})
			var speed: float = float(profile.get("attack_speed", 1.0))
			var recoil: float = float(profile.get("recoil_strength", 6.0))
			var defending := command == "DEFEND"
			motion.tween_callback(func(): stage.enemy_actor.play_pose("heavy_release" if heavy else "attack_pose"); stage.feedback_phase.emit("enemy_windup"))
			motion.tween_interval(0.14 / speed)
			motion.tween_property(stage.enemy_actor, "position", stage.enemy_origin.lerp(stage.hero_origin, float(profile.get("lunge_ratio", 0.38))), 0.13 / speed)
			motion.tween_callback(func():
				stage.hero_actor.play_pose("brace" if defending else "hit_reaction")
				stage.spawn_damage_popup(stage.hero_actor, taken, heavy, defending)
				if defending:
					stage.emit_weapon_fx("brace", stage.hero_actor)
				stage.feedback_phase.emit("blocked" if defending else "hero_hit"))
			var offset := Vector2(-recoil * (0.45 if defending else (3.0 if heavy else 1.0)), 1 if defending else 4)
			motion.tween_property(stage.hero_actor, "position", stage.hero_origin + offset, 0.06)
			motion.tween_interval(0.06 if heavy else 0.04)
			motion.tween_property(stage.enemy_actor, "position", stage.enemy_origin, 0.20 / speed)
			motion.parallel().tween_property(stage.hero_actor, "position", stage.hero_origin, 0.20 / speed)
		if command == "FLEE":
			if taken > 0:
				motion.tween_callback(func(): stage.spawn_damage_popup(stage.hero_actor, taken, false, false))
			motion.tween_property(stage.hero_actor, "position", stage.hero_origin + Vector2(-100, 35), 0.25)
			motion.parallel().tween_property(stage.hero_actor, "modulate:a", 0.0, 0.25)
	if outcome in ["VICTORY", "DEFEAT", "DEAD"]:
		motion.tween_callback(func():
			var actor = stage.enemy_actor if outcome == "VICTORY" else stage.hero_actor
			actor.hold_pose("fall" if outcome == "VICTORY" or stage.reduced_motion else "kneel")
			stage.feedback_phase.emit("enemy_fall" if outcome == "VICTORY" else "hero_fall"))
		motion.tween_interval(0.08 if stage.reduced_motion else 0.18)
		motion.tween_callback(func(): stage.present_outcome(outcome); stage.feedback_phase.emit("victory" if outcome == "VICTORY" else "defeat"))
		motion.tween_interval(0.08 if stage.reduced_motion else 0.35)
	elif not stage.reduced_motion:
		motion.tween_interval(0.12)
	# Tween.kill() has no finished signal. A frame wait plus generation check
	# releases callers on resize, replacement or scene removal without hanging.
	while is_instance_valid(stage) and stage.is_inside_tree() and ticket == stage.motion_generation and motion.is_valid() and motion.is_running():
		await tree.process_frame
	if not is_instance_valid(stage) or not stage.is_inside_tree() or ticket != stage.motion_generation:
		return
	stage.active_motion = null
	stage.hero_actor.position = stage.hero_origin
	stage.enemy_actor.position = stage.enemy_origin
	stage.hero_actor.modulate = Color.WHITE
	stage.hero_actor.rotation = 0.0
	stage.enemy_actor.rotation = 0.0
	if outcome == "":
		stage.hero_actor.hold_pose("rest")
		if next_heavy and bool(stage.VISUAL_PROFILES.get(enemy_id, {}).get("heavy_capable", false)):
			if stage.reduced_motion:
				stage.enemy_actor.hold_pose("windup")
			else:
				stage.enemy_actor.play_pose("heavy_charge")
		else:
			stage.enemy_actor.hold_pose("rest")
