extends Control
class_name BattleStage

const ItemIcon = preload("res://ui/components/item_icon.gd")
const MotionDirector = preload("res://ui/components/battle_motion_director.gd")
const PoseLibrary = preload("res://ui/components/battle_pose_library.gd")
const WeaponFx = preload("res://ui/components/battle_weapon_fx.gd")
const IsometricGround = preload("res://ui/components/isometric_battle_ground.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
var support_turret: TextureRect

# ==============================================================================
# BVIS-1B: BATTLE STAGE CONTRACT & ASSET INTEGRATION
# ==============================================================================
# 16:9 AspectRatioContainer ensures the virtual camera perspective remains
# constant across varying window sizes.
#
# Ground Actor Contract:
#   1. ActorNode.position is the ground coordinate on the 16:9 canvas.
#   2. GroundShadow is anchored strictly at local Vector2.ZERO.
#   3. Sprites are positioned via authored foot_anchor_uv.
#   4. VISUAL_PROFILES is the single source of visual truth.
# ==============================================================================

const KNOWN_ENEMIES := ["feral_dog", "bandit", "heavy_raider", "feral_boar", "desert_scorpion", "ash_ghoul", "grey_crow"]

# Hand-play, twice: the weapon floated beside the fighter instead of being held.
# Each weapon has an authored grip (uv on the source icon) and length relative
# to the fighter. Left-facing source art is mirrored before its grip is pinned.
# This supplies WHERE ITS HANDLE IS and HOW LONG it
# is next to the fighter (icon width / fighter height). The grip is pinned to
# the fist and the weapon is drawn behind the body, so the fist covers it.
const WEAPON_GRIPS := {
	"sledgehammer": {"grip": Vector2(0.17, 0.83), "size": 0.44},
	"combat_knife": {"grip": Vector2(0.26, 0.77), "size": 0.22},
	"reinforced_saber": {"grip": Vector2(0.15, 0.84), "size": 0.38},
	"police_revolver": {"grip": Vector2(0.86, 0.73), "muzzle": Vector2(0.06, 0.23), "size": 0.22, "flip_h": true},
	"short_shotgun": {"grip": Vector2(0.70, 0.56), "muzzle": Vector2(0.06, 0.20), "size": 0.40, "flip_h": true},
	"old_revolver": {"grip": Vector2(0.22, 0.73), "muzzle": Vector2(0.94, 0.23), "size": 0.20},
	"crowbar": {"grip": Vector2(0.20, 0.82), "size": 0.34},
	"rusted_knife": {"grip": Vector2(0.26, 0.77), "size": 0.20},
	"hunting_knife": {"grip": Vector2(0.26, 0.77), "size": 0.22},
	"rebar_club": {"grip": Vector2(0.18, 0.86), "size": 0.32},
	"scrap_machete": {"grip": Vector2(0.20, 0.83), "size": 0.30},
	"old_world_saber": {"grip": Vector2(0.15, 0.84), "size": 0.40},
}
const DEFAULT_GRIP := {"grip": Vector2(0.24, 0.80), "size": 0.26}

const VISUAL_PROFILES := {
	"grey_crow": {
		"actor_id": "grey_crow", "texture_path": "res://ui/assets/combat/relay-grey-crow.png",
		"foot_anchor_uv": Vector2(0.47, 0.963), "height_ratio": 0.41, "shadow_radius_ratio": 0.22,
		"modulate": Color.WHITE, "attack_speed": 1.0, "lunge_ratio": 0.38, "recoil_strength": 6.0, "heavy_capable": false,
	},
	"feral_boar": {
		"actor_id": "feral_boar", "texture_path": "res://ui/assets/combat/feral-boar.png",
		"foot_anchor_uv": Vector2(0.50, 0.98), "height_ratio": 0.29, "shadow_radius_ratio": 0.34,
		"modulate": Color.WHITE, "attack_speed": 0.90, "lunge_ratio": 0.46, "recoil_strength": 5.0, "heavy_capable": true,
	},
	"desert_scorpion": {
		"actor_id": "desert_scorpion", "texture_path": "res://ui/assets/combat/desert-scorpion.png",
		"foot_anchor_uv": Vector2(0.50, 0.94), "height_ratio": 0.26, "shadow_radius_ratio": 0.40,
		"modulate": Color.WHITE, "attack_speed": 1.10, "lunge_ratio": 0.32, "recoil_strength": 7.0, "heavy_capable": false,
	},
	"ash_ghoul": {
		"actor_id": "ash_ghoul", "texture_path": "res://ui/assets/combat/ash-ghoul.png",
		# Ground midpoint between the two generated feet, not the canvas center.
		"foot_anchor_uv": Vector2(0.60, 0.94), "height_ratio": 0.43, "shadow_radius_ratio": 0.22,
		"modulate": Color.WHITE, "attack_speed": 1.20, "lunge_ratio": 0.42, "recoil_strength": 8.0, "heavy_capable": true,
	},
	"drifter": {
		"texture_path": "res://ui/assets/combat/drifter.png",
		"foot_anchor_uv": Vector2(0.50, 0.98),
		# The front (lower) fist, measured on the 462x1243 art. The weapon's
		# grip is pinned here so the hand actually closes on the handle.
		"hand_uv": Vector2(0.89, 0.295),
		"height_ratio": 0.42,
		"shadow_radius_ratio": 0.22,
		"modulate": Color.WHITE,
		"attack_speed": 1.0,
		"lunge_ratio": 0.52,
		"recoil_strength": 6.0,
		"heavy_capable": false,
	},
	"feral_dog": {
		"texture_path": "res://ui/assets/combat/feral-dog.png",
		"foot_anchor_uv": Vector2(0.50, 0.98),
		"height_ratio": 0.25,
		"shadow_radius_ratio": 0.38,
		"modulate": Color.WHITE,
		"attack_speed": 1.25,
		"lunge_ratio": 0.44,
		"recoil_strength": 9.0,
		"heavy_capable": false,
	},
	"bandit": {
		"texture_path": "res://ui/assets/combat/road-bandit.png",
		"foot_anchor_uv": Vector2(0.50, 0.98),
		"height_ratio": 0.41,
		"shadow_radius_ratio": 0.24,
		"modulate": Color(0.96, 0.94, 0.90),
		"attack_speed": 1.0,
		"lunge_ratio": 0.38,
		"recoil_strength": 7.0,
		"heavy_capable": false,
	},
	"heavy_raider": {
		"texture_path": "res://ui/assets/combat/heavy-raider.png",
		"foot_anchor_uv": Vector2(0.50, 0.98),
		"height_ratio": 0.47,
		"shadow_radius_ratio": 0.28,
		"modulate": Color(0.94, 0.92, 0.88),
		"attack_speed": 0.85,
		"lunge_ratio": 0.32,
		"recoil_strength": 3.0,
		"heavy_capable": true,
	},
}

class TextureHelper:
	static func load_texture_safe(path: String) -> Texture2D:
		if ResourceLoader.exists(path):
			var imported := load(path)
			if imported is Texture2D:
				return imported
		if FileAccess.file_exists(path):
			var bitmap := Image.load_from_file(path)
			if bitmap != null and not bitmap.is_empty():
				return ImageTexture.create_from_image(bitmap)
		return null

class GroundShadow extends Node2D:
	var radius := 40.0
	var squashed_ratio := 0.22

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, squashed_ratio))
		draw_circle(Vector2.ZERO, radius * 1.25, Color(0.08, 0.06, 0.04, 0.07))
		draw_circle(Vector2.ZERO, radius, Color(0.08, 0.06, 0.04, 0.14))
		draw_circle(Vector2.ZERO, radius * 0.65, Color(0.08, 0.06, 0.04, 0.24))
		draw_set_transform(Vector2.ZERO)

class PlaceholderFigure extends Node2D:
	var figure_size := Vector2(128, 136)
	var body := Color(0.34, 0.30, 0.28)
	var trim := Color(0.72, 0.60, 0.32)
	var bulk := 1.0

	func _draw() -> void:
		var w := figure_size.x * bulk
		var h := figure_size.y
		var lit := Color(body).lightened(0.38)
		var dark := Color(body).darkened(0.55)

		draw_line(Vector2(w * 0.455, h * 0.66), Vector2(w * 0.40, h * 0.98), dark, w * 0.085, true)
		draw_line(Vector2(w * 0.555, h * 0.66), Vector2(w * 0.62, h * 0.98), dark, w * 0.085, true)

		var coat := PackedVector2Array([
			Vector2(w * 0.36, h * 0.30), Vector2(w * 0.50, h * 0.255), Vector2(w * 0.64, h * 0.30),
			Vector2(w * 0.70, h * 0.50), Vector2(w * 0.74, h * 0.70), Vector2(w * 0.62, h * 0.68),
			Vector2(w * 0.55, h * 0.74), Vector2(w * 0.45, h * 0.74), Vector2(w * 0.38, h * 0.68),
			Vector2(w * 0.26, h * 0.70), Vector2(w * 0.30, h * 0.50),
		])
		var coat_colors := PackedColorArray([
			lit, lit, body, body, dark, dark, dark, dark, dark, dark, body,
		])
		draw_polygon(coat, coat_colors)
		draw_polyline(PackedVector2Array([
			Vector2(w * 0.36, h * 0.30), Vector2(w * 0.30, h * 0.50), Vector2(w * 0.26, h * 0.70),
		]), Color(lit).lightened(0.25), 1.5, true)

		draw_circle(Vector2(w * 0.5, h * 0.185), w * 0.105, dark)
		draw_circle(Vector2(w * 0.475, h * 0.17), w * 0.085, body)
		draw_line(Vector2(w * 0.36, h * 0.30), Vector2(w * 0.64, h * 0.30), dark, w * 0.05, true)

		draw_line(Vector2(w * 0.63, h * 0.35), Vector2(w * 0.82, h * 0.22), body, w * 0.065, true)
		draw_line(Vector2(w * 0.80, h * 0.25), Vector2(w * 0.90, h * 0.04), trim, w * 0.045, true)
		draw_line(Vector2(w * 0.37, h * 0.36), Vector2(w * 0.23, h * 0.54), body, w * 0.06, true)

class PlaceholderBackdrop extends Control:
	const HORIZON := 0.46

	func _band(points: Array, colors: Array) -> void:
		draw_polygon(PackedVector2Array(points), PackedColorArray(colors))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var sky_top := Color(0.30, 0.25, 0.22)
		var sky_low := Color(0.62, 0.47, 0.33)
		_band([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * HORIZON), Vector2(0, h * HORIZON)],
			[sky_top, sky_top, sky_low, sky_low])
		var ridges := [
			{"y": 0.40, "amp": 0.075, "color": Color(0.47, 0.38, 0.31), "seed": 3},
			{"y": 0.44, "amp": 0.055, "color": Color(0.37, 0.30, 0.25), "seed": 7},
			{"y": 0.47, "amp": 0.035, "color": Color(0.28, 0.23, 0.20), "seed": 11},
		]
		for ridge in ridges:
			var points: Array = []
			var colors: Array = []
			var steps := 14
			for i in range(steps + 1):
				var t := float(i) / float(steps)
				var bump := sin(t * float(ridge.seed) * 1.7) * 0.5 + sin(t * float(ridge.seed) * 0.6) * 0.5
				points.append(Vector2(w * t, h * (float(ridge.y) - float(ridge.amp) * bump)))
				colors.append(Color(ridge.color))
			points.append(Vector2(w, h))
			colors.append(Color(ridge.color))
			points.append(Vector2(0, h))
			colors.append(Color(ridge.color))
			draw_polygon(PackedVector2Array(points), PackedColorArray(colors))

		var road_color := Color(0.22, 0.19, 0.16)
		draw_polygon(PackedVector2Array([
			Vector2(w * 0.44, h * HORIZON), Vector2(w * 0.56, h * HORIZON),
			Vector2(w * 0.88, h), Vector2(w * 0.08, h),
		]), PackedColorArray([road_color, road_color, road_color, road_color]))

class ActorNode extends Node2D:
	var shadow: GroundShadow
	var body: Sprite2D
	var placeholder: PlaceholderFigure
	var weapon: Sprite2D
	var is_hero := false
	var foot_anchor_uv := Vector2(0.5, 1.0)
	var hand_uv := Vector2(0.75, 0.40)
	var weapon_id := ""
	var target_height := 160.0
	var texture_ref: Texture2D = null
	var anim_player: AnimationPlayer
	var actor_id := ""
	var disarmed: bool = false
	var cutout_motion := false
	var rest_foot := Vector2(0.5, 1.0)
	var rest_hand := Vector2(0.75, 0.40)
	var idle_breath_amount: float = 0.0:
		set(value):
			idle_breath_amount = clampf(value, 0.0, 1.0)
			_apply_pose()
	var pose := "rest":
		set(value):
			pose = value
			_apply_pose()
			pose_changed.emit(value)
	signal pose_changed(value: String)

	func _init(p_is_hero: bool = false) -> void:
		is_hero = p_is_hero
		shadow = GroundShadow.new()
		shadow.name = "Shadow"
		shadow.position = Vector2.ZERO
		add_child(shadow)
		body = Sprite2D.new()
		body.name = "Body"
		body.position = Vector2.ZERO
		body.centered = false
		add_child(body)
		if not is_hero:
			placeholder = PlaceholderFigure.new()
			placeholder.name = "Placeholder"
			placeholder.visible = false
			add_child(placeholder)
		if is_hero:
			weapon = Sprite2D.new()
			weapon.name = "Weapon"
			weapon.visible = false
			# A child of the body, drawn behind it: it follows every body pose and
			# the fist sits over the handle.
			weapon.centered = false
			weapon.show_behind_parent = true
			body.add_child(weapon)
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimPlayer"
		add_child(anim_player)
		_setup_animations()

	func _setup_animations() -> void:
		var lib := AnimationLibrary.new()

		# 1. rest
		var a_rest := Animation.new()
		a_rest.length = 0.1
		var t_rest_rot := a_rest.add_track(Animation.TYPE_VALUE)
		a_rest.track_set_path(t_rest_rot, NodePath("Body:rotation"))
		a_rest.track_insert_key(t_rest_rot, 0.0, 0.0)
		lib.add_animation("rest", a_rest)

		# 2. attack_pose
		var a_atk := Animation.new()
		a_atk.length = 0.35
		var t_atk_rot := a_atk.add_track(Animation.TYPE_VALUE)
		a_atk.track_set_path(t_atk_rot, NodePath("Body:rotation"))
		a_atk.track_insert_key(t_atk_rot, 0.0, 0.0)
		a_atk.track_insert_key(t_atk_rot, 0.10, -0.06)
		a_atk.track_insert_key(t_atk_rot, 0.22, 0.12)
		a_atk.track_insert_key(t_atk_rot, 0.35, 0.0)
		if is_hero and weapon != null:
			var t_w_rot := a_atk.add_track(Animation.TYPE_VALUE)
			a_atk.track_set_path(t_w_rot, NodePath("Body/Weapon:rotation"))
			a_atk.track_insert_key(t_w_rot, 0.0, 0.0)
			a_atk.track_insert_key(t_w_rot, 0.10, -0.25)
			a_atk.track_insert_key(t_w_rot, 0.22, 0.35)
			a_atk.track_insert_key(t_w_rot, 0.35, 0.0)
		lib.add_animation("attack_pose", a_atk)

		# 3. hit_reaction
		var a_hit := Animation.new()
		a_hit.length = 0.25
		var t_hit_rot := a_hit.add_track(Animation.TYPE_VALUE)
		a_hit.track_set_path(t_hit_rot, NodePath("Body:rotation"))
		a_hit.track_insert_key(t_hit_rot, 0.0, 0.0)
		a_hit.track_insert_key(t_hit_rot, 0.06, -0.08)
		a_hit.track_insert_key(t_hit_rot, 0.25, 0.0)
		var t_hit_mod := a_hit.add_track(Animation.TYPE_VALUE)
		a_hit.track_set_path(t_hit_mod, NodePath("Body:modulate"))
		a_hit.track_insert_key(t_hit_mod, 0.0, Color.WHITE)
		a_hit.track_insert_key(t_hit_mod, 0.06, Color(1.7, 1.6, 1.4))
		a_hit.track_insert_key(t_hit_mod, 0.25, Color.WHITE)
		lib.add_animation("hit_reaction", a_hit)

		# 4. brace
		var a_brace := Animation.new()
		a_brace.length = 0.30
		var t_br_rot := a_brace.add_track(Animation.TYPE_VALUE)
		a_brace.track_set_path(t_br_rot, NodePath("Body:rotation"))
		a_brace.track_insert_key(t_br_rot, 0.0, 0.0)
		a_brace.track_insert_key(t_br_rot, 0.15, -0.06)
		a_brace.track_insert_key(t_br_rot, 0.30, 0.0)
		var t_br_mod := a_brace.add_track(Animation.TYPE_VALUE)
		a_brace.track_set_path(t_br_mod, NodePath("Body:modulate"))
		a_brace.track_insert_key(t_br_mod, 0.0, Color.WHITE)
		a_brace.track_insert_key(t_br_mod, 0.15, Color(1.15, 1.05, 0.75))
		a_brace.track_insert_key(t_br_mod, 0.30, Color.WHITE)
		if is_hero and weapon != null:
			var t_bw_rot := a_brace.add_track(Animation.TYPE_VALUE)
			a_brace.track_set_path(t_bw_rot, NodePath("Body/Weapon:rotation"))
			a_brace.track_insert_key(t_bw_rot, 0.0, 0.0)
			a_brace.track_insert_key(t_bw_rot, 0.15, -0.22)
			a_brace.track_insert_key(t_bw_rot, 0.30, 0.0)
		lib.add_animation("brace", a_brace)

		# 5. heavy_charge (Telegraph Pose: arched back, raised tension, sustained until release)
		var a_chg := Animation.new()
		a_chg.length = 0.50
		a_chg.loop_mode = Animation.LOOP_LINEAR
		var t_chg_rot := a_chg.add_track(Animation.TYPE_VALUE)
		a_chg.track_set_path(t_chg_rot, NodePath("Body:rotation"))
		a_chg.track_insert_key(t_chg_rot, 0.0, 0.0)
		a_chg.track_insert_key(t_chg_rot, 0.25, 0.22)
		a_chg.track_insert_key(t_chg_rot, 0.50, 0.19)
		var t_chg_mod := a_chg.add_track(Animation.TYPE_VALUE)
		a_chg.track_set_path(t_chg_mod, NodePath("Body:modulate"))
		a_chg.track_insert_key(t_chg_mod, 0.0, Color.WHITE)
		a_chg.track_insert_key(t_chg_mod, 0.25, Color(1.15, 0.92, 0.70))
		a_chg.track_insert_key(t_chg_mod, 0.50, Color(1.08, 0.96, 0.82))
		lib.add_animation("heavy_charge", a_chg)

		# 6. heavy_release (Violent release from arched charge stance to forward smash)
		var a_rel := Animation.new()
		a_rel.length = 0.40
		var t_rel_rot := a_rel.add_track(Animation.TYPE_VALUE)
		a_rel.track_set_path(t_rel_rot, NodePath("Body:rotation"))
		a_rel.track_insert_key(t_rel_rot, 0.0, 0.19)
		a_rel.track_insert_key(t_rel_rot, 0.12, -0.22)
		a_rel.track_insert_key(t_rel_rot, 0.28, -0.06)
		a_rel.track_insert_key(t_rel_rot, 0.40, 0.0)
		var t_rel_mod := a_rel.add_track(Animation.TYPE_VALUE)
		a_rel.track_set_path(t_rel_mod, NodePath("Body:modulate"))
		a_rel.track_insert_key(t_rel_mod, 0.0, Color(1.10, 0.95, 0.80))
		a_rel.track_insert_key(t_rel_mod, 0.12, Color(1.25, 1.10, 0.90))
		a_rel.track_insert_key(t_rel_mod, 0.40, Color.WHITE)
		lib.add_animation("heavy_release", a_rel)

		# Discrete texture poses share AnimationPlayer authority with local rotation.
		for clip in ["rest", "attack_pose", "hit_reaction", "brace", "heavy_charge", "heavy_release"]:
			var animation: Animation = lib.get_animation(clip)
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track, NodePath(".:pose"))
			animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
			match clip:
				"rest": animation.track_insert_key(track, 0.0, "rest")
				"attack_pose", "heavy_release":
					animation.track_insert_key(track, 0.0, "windup")
					animation.track_insert_key(track, animation.length * 0.3, "strike")
					animation.track_insert_key(track, animation.length, "rest")
				"hit_reaction":
					animation.track_insert_key(track, 0.0, "hurt")
					animation.track_insert_key(track, animation.length, "rest")
				"brace": animation.track_insert_key(track, 0.0, "brace")
				"heavy_charge":
					animation.track_insert_key(track, 0.0, "charge")
					animation.track_insert_key(track, 0.25, "windup")
		anim_player.add_animation_library("", lib)
		# Separate generated poses do not preserve the resting silhouette/camera.
		# Breathe with the original cutout around its planted foot instead.
		_add_pose_clip(lib, "idle", ["rest"], [0.0], 1.5, true)
		var idle: Animation = lib.get_animation("idle")
		var breath_track: int = idle.add_track(Animation.TYPE_VALUE)
		idle.track_set_path(breath_track, NodePath(".:idle_breath_amount"))
		idle.track_set_interpolation_type(breath_track, Animation.INTERPOLATION_CUBIC)
		idle.track_insert_key(breath_track, 0.0, 0.0)
		idle.track_insert_key(breath_track, 0.75, 1.0)
		idle.track_insert_key(breath_track, 1.5, 0.0)
		_add_pose_clip(lib, "approach", ["step_a", "step_b"], [0.0, 0.09], 0.18, true)
		_add_pose_clip(lib, "retreat", ["retreat_a", "retreat_b"], [0.0, 0.10], 0.20, true)

	func _add_pose_clip(lib: AnimationLibrary, clip: String, poses: Array, times: Array, duration: float, looped: bool) -> void:
		var animation: Animation = Animation.new()
		animation.length = duration
		animation.loop_mode = Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(".:pose"))
		animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
		for index in range(poses.size()):
			animation.track_insert_key(track, float(times[index]), String(poses[index]))
		lib.add_animation(clip, animation)

	func _apply_pose() -> void:
		if body == null or texture_ref == null:
			return
		var selected_pose: String = pose
		if actor_id == "grey_crow":
			if pose in ["rest", "recover", "settle", "idle_breath", "step_a", "step_b", "brace"]: selected_pose = "unarmed" if disarmed else "armed"
			elif disarmed and pose in ["windup", "strike"]: selected_pose = "unarmed"
		var frame: Dictionary = PoseLibrary.frame(actor_id, selected_pose) if selected_pose != "rest" else {}
		body.texture = frame.get("texture", texture_ref)
		foot_anchor_uv = frame.get("foot", rest_foot)
		hand_uv = frame.get("hand", rest_hand)
		var source_h: float = float(frame.get("reference_height", texture_ref.get_height()))
		body.scale = Vector2.ONE * target_height / maxf(1.0, source_h)
		# New creatures retain one authored silhouette through every pose. Bounded
		# cutout posture belongs to AnimationPlayer's sampled pose; root motion
		# remains the receipt-driven director's responsibility.
		if cutout_motion:
			body.rotation = {"windup": 0.06, "charge": 0.10, "strike": -0.08, "hurt": 0.07, "brace": 0.03, "recover": 0.04, "kneel": -0.35, "fall": -1.10}.get(pose, 0.0)
		if pose == "rest":
			body.scale.y *= 1.0 + idle_breath_amount * 0.006
		body.offset = -body.texture.get_size() * foot_anchor_uv
		fit_weapon()
		if weapon != null:
			weapon.visible = weapon.texture != null and weapon_id != "" and pose not in ["kneel", "fall"]
			if pose in ["revolver_aim", "revolver_recoil", "shotgun_aim", "shotgun_recoil"]:
				aim_weapon()
			elif pose in ["empty_gun", "gun_recover"]:
				aim_weapon(0.65)

	func hold_pose(value: String) -> void:
		anim_player.stop()
		idle_breath_amount = 0.0
		body.rotation = 0.0
		body.modulate = Color.WHITE
		if weapon != null:
			weapon.rotation = 0.0
		pose = value

	func play_pose(clip: String, speed: float = 1.0) -> void:
		idle_breath_amount = 0.0
		anim_player.play(clip, -1, speed)
		anim_player.advance(0.0) # Sample the authored first frame immediately.


	func play_attack(style: Dictionary) -> void:
		var clip: Animation = anim_player.get_animation("attack_pose")
		var poses: Array[String] = PoseLibrary.attack_poses(style)
		var total: float = float(style.windup) + float(style.strike) + float(style.recover)
		clip.length = total
		for track in range(clip.get_track_count()):
			if String(clip.track_get_path(track)) == ".:pose":
				# Rebuild keys so every weapon receives windup, strike and recovery.
				while clip.track_get_key_count(track) > 0:
					clip.track_remove_key(track, 0)
				clip.track_insert_key(track, 0.0, poses[0])
				clip.track_insert_key(track, float(style.windup), poses[1])
				clip.track_insert_key(track, float(style.windup) + float(style.strike), poses[2])
				clip.track_insert_key(track, total, "rest")
			elif String(clip.track_get_path(track)) == "Body/Weapon:rotation":
				clip.track_set_key_time(track, 1, float(style.windup) * 0.7)
				clip.track_set_key_time(track, 2, float(style.windup) + float(style.strike))
				clip.track_set_key_time(track, 3, total)
				clip.track_set_key_value(track, 1, -0.65)
				clip.track_set_key_value(track, 2, float(style.angle))
		play_pose("attack_pose")

	func aim_weapon(direction: float = -0.12) -> void:
		if weapon == null or weapon.texture == null:
			return
		var base: String = preload("res://game_data/gear_property_profiles.gd").base_item(weapon_id)
		var fit: Dictionary = WEAPON_GRIPS.get(base, {})
		if not fit.has("muzzle"):
			return
		var barrel: Vector2 = (fit.muzzle - fit.grip) * weapon.texture.get_size()
		if weapon.flip_h:
			barrel.x = -barrel.x
		weapon.rotation = direction - barrel.angle()

	func muzzle_local() -> Vector2:
		var base: String = preload("res://game_data/gear_property_profiles.gd").base_item(weapon_id)
		var point: Vector2 = WEAPON_GRIPS.get(base, {}).get("muzzle", Vector2.ONE * 0.5)
		if weapon.flip_h:
			point.x = 1.0 - point.x
		return weapon.offset + point * weapon.texture.get_size()

	func apply_profile(profile: Dictionary, canvas_h: float) -> void:
		var tex_path: String = profile.get("texture_path", "")
		var tex: Texture2D = TextureHelper.load_texture_safe(tex_path)
		texture_ref = tex
		actor_id = "drifter" if is_hero else String(profile.get("actor_id", {"feral-dog.png": "feral_dog", "road-bandit.png": "bandit", "heavy-raider.png": "heavy_raider"}.get(tex_path.get_file(), "")))
		cutout_motion = actor_id in ["feral_boar", "desert_scorpion", "ash_ghoul"]
		rest_foot = profile.get("foot_anchor_uv", Vector2(0.5, 1.0))
		rest_hand = profile.get("hand_uv", Vector2(0.75, 0.40))
		foot_anchor_uv = profile.get("foot_anchor_uv", Vector2(0.5, 1.0))
		var h_ratio: float = float(profile.get("height_ratio", 0.40))
		target_height = canvas_h * h_ratio
		body.texture = tex
		shadow.position = Vector2.ZERO
		var rad_ratio: float = float(profile.get("shadow_radius_ratio", 0.25))
		shadow.radius = target_height * rad_ratio
		shadow.queue_redraw()

		if tex != null:
			var tex_h: float = maxf(1.0, float(tex.get_height()))
			var scale_f: float = target_height / tex_h
			body.scale = Vector2.ONE * scale_f
			body.offset = -Vector2(float(tex.get_width()) * foot_anchor_uv.x, float(tex.get_height()) * foot_anchor_uv.y)
			body.modulate = profile.get("modulate", Color.WHITE)

			hand_uv = profile.get("hand_uv", Vector2(0.75, 0.40))
			_apply_pose()

	# Pins the weapon's grip to the fist. Body-local coordinates are the body
	# texture's pixels shifted by its offset; the weapon's own scale is divided
	# by the body's so its size is set against the fighter on screen.
	func fit_weapon() -> void:
		if weapon == null or weapon.texture == null or body.texture == null:
			return
		var fit: Dictionary = WEAPON_GRIPS.get(preload("res://game_data/gear_property_profiles.gd").base_item(weapon_id), DEFAULT_GRIP)
		var w_tex: Texture2D = weapon.texture
		var w_size := Vector2(float(w_tex.get_width()), float(w_tex.get_height()))
		# The new broadside two-handed pose needs a longer projected silhouette
		# than the original resting pose; its forward support fist must clear the
		# barrel. Keep the hand-played original rest proportions intact.
		var projected_size: float = 0.60 if pose in ["shotgun_aim", "shotgun_recoil"] else float(fit.size)
		var on_screen: float = target_height * projected_size / maxf(1.0, w_size.x)
		weapon.scale = Vector2.ONE * (on_screen / maxf(0.0001, body.scale.x))
		weapon.flip_h = bool(fit.get("flip_h", false))
		var grip: Vector2 = fit.grip
		if weapon.flip_h:
			grip.x = 1.0 - grip.x
		weapon.offset = -w_size * grip
		var b_size := Vector2(float(body.texture.get_width()), float(body.texture.get_height()))
		weapon.position = body.offset + b_size * hand_uv

	func apply_placeholder(p_bulk: float, body_col: Color, trim_col: Color, p_height: float, shadow_rad: float) -> void:
		if placeholder == null:
			return
		target_height = p_height
		placeholder.bulk = p_bulk
		placeholder.body = body_col
		placeholder.trim = trim_col
		placeholder.figure_size = Vector2(p_height * 0.75, p_height)
		placeholder.position = Vector2(-p_height * 0.375 * p_bulk, -p_height)
		placeholder.queue_redraw()
		shadow.position = Vector2.ZERO
		shadow.radius = shadow_rad
		shadow.queue_redraw()

	func get_local_foot_anchor() -> Vector2:
		if body.texture == null:
			return Vector2.ZERO
		var unscaled_anchor := Vector2(float(body.texture.get_width()) * foot_anchor_uv.x, float(body.texture.get_height()) * foot_anchor_uv.y)
		return (body.offset + unscaled_anchor) * body.scale

# ==============================================================================
# BATTLE STAGE CLASS
# ==============================================================================

var aspect_frame: AspectRatioContainer
var stage_canvas: Control

var shed_background: TextureRect
var road_background: TextureRect
var wilderness_background: TextureRect
var camp_background: TextureRect
var waterworks_background: TextureRect
var relay_background: TextureRect
var environment_id := "shed"
var isometric := false
var isometric_ground: Node2D
var road_fallback: PlaceholderBackdrop
var actor_layer: Node2D
var fx_layer: Control
var hero_actor: ActorNode
var enemy_actor: ActorNode

# Backward-compatible references
var hero: Sprite2D
var enemy: Sprite2D
var weapon: Sprite2D
var enemy_placeholder: PlaceholderFigure
var hero_shadow: GroundShadow
var enemy_shadow: GroundShadow
var placeholder_note: Label
var floating: Label

var hero_origin := Vector2.ZERO
var enemy_origin := Vector2.ZERO
var reduced_motion := false:
	set(value):
		reduced_motion = value
		if is_inside_tree() and is_instance_valid(hero_actor):
			cancel_motion()
			present_outcome(terminal_outcome)
var enemy_alive := true
var armed := false
var showing_placeholder := false
var current_enemy_id := ""
var current_weapon_id := ""
var is_road_stage := false
var active_motion: Tween
var motion_generation := 0
var terminal_outcome := ""
signal feedback_phase(phase: String)

func cancel_motion(reset: bool = true) -> void:
	motion_generation += 1
	if active_motion != null and active_motion.is_valid():
		active_motion.kill()
	active_motion = null
	if not reset:
		return
	for actor in [hero_actor, enemy_actor]:
		if is_instance_valid(actor):
			actor.hold_pose("rest")
			actor.rotation = 0.0
			actor.modulate = Color.WHITE
	if is_instance_valid(hero_actor):
		hero_actor.position = hero_origin
	if is_instance_valid(enemy_actor):
		enemy_actor.position = enemy_origin
	if is_instance_valid(fx_layer):
		for child in fx_layer.get_children():
			child.queue_free()

func _exit_tree() -> void:
	cancel_motion()

func present_outcome(outcome: String) -> void:
	terminal_outcome = outcome
	hero_actor.visible = outcome != "ESCAPED"
	enemy.visible = (enemy_alive or outcome == "VICTORY") and not showing_placeholder
	enemy_shadow.visible = enemy_alive or outcome == "VICTORY"
	if outcome == "VICTORY":
		enemy_actor.hold_pose("fall")
		enemy.visible = not showing_placeholder
		enemy_shadow.visible = true
	elif outcome in ["DEFEAT", "DEAD"]:
		hero_actor.hold_pose("fall")
	elif outcome == "ESCAPED":
		hero_actor.hold_pose("retreat_a")
		enemy_actor.hold_pose("rest")
	elif outcome == "CAPTURED":
		enemy_actor.hold_pose("kneel")
	elif outcome == "":
		resume_idle()

func resume_idle() -> void:
	for actor in [hero_actor, enemy_actor]:
		actor.hold_pose("rest")
		if not reduced_motion and terminal_outcome == "" and (actor == hero_actor or enemy_alive):
			actor.play_pose("idle")

func emit_weapon_fx(kind: String, target: ActorNode) -> void:
	if reduced_motion:
		return
	var effect := WeaponFx.new()
	effect.kind = kind
	effect.extent = 22.0 if kind == "revolver" else 35.0
	if kind in ["revolver", "shotgun"] and target.weapon != null:
		var muzzle: Vector2 = target.weapon.to_global(target.muzzle_local())
		effect.position = muzzle - fx_layer.global_position
		var grip: Vector2 = target.weapon.to_global(Vector2.ZERO)
		effect.rotation = (muzzle - grip).angle()
	else:
		effect.position = target.position + Vector2(24, -target.target_height * 0.65)
	fx_layer.add_child(effect)
	var fade := effect.create_tween()
	fade.tween_interval(0.07 if kind == "revolver" else 0.12)
	fade.tween_callback(effect.queue_free)

func show_empty_weapon() -> void:
	# Rejection feedback has no FIELD_TURN and cannot consume a turn or ammo.
	hero_actor.hold_pose("empty_gun")
	floating.text = "彈藥不足 · 補給後才能射擊"
	floating.position = hero_origin + Vector2(-110, -hero_actor.target_height - 24)
	floating.show()
	feedback_phase.emit("empty_weapon")


static func load_texture_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path)
		if imported is Texture2D:
			return imported
	if FileAccess.file_exists(path):
		var bitmap := Image.load_from_file(path)
		if bitmap != null and not bitmap.is_empty():
			return ImageTexture.create_from_image(bitmap)
	return null

func _init() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(0, 240)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

	# 1. AspectRatioContainer maintains 16:9 framing for the virtual camera
	aspect_frame = AspectRatioContainer.new()
	aspect_frame.ratio = 16.0 / 9.0
	aspect_frame.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect_frame.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	aspect_frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(aspect_frame)

	# 2. Stage Canvas (the actual 16:9 rendering viewport)
	stage_canvas = Control.new()
	stage_canvas.clip_contents = true
	aspect_frame.add_child(stage_canvas)

	# Road Background (TextureRect with 16:9 abandoned-road.png)
	road_background = TextureRect.new()
	var road_tex := load_texture_safe("res://ui/assets/combat/abandoned-road.png")
	if road_tex != null:
		road_background.texture = road_tex
	road_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	road_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	road_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	road_background.visible = false
	stage_canvas.add_child(road_background)

	# Procedural fallback for road
	road_fallback = PlaceholderBackdrop.new()
	road_fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	road_fallback.visible = false
	stage_canvas.add_child(road_fallback)

	# Shed Background
	shed_background = TextureRect.new()
	var shed_tex := load_texture_safe("res://ui/assets/combat/supply-shed.png")
	if shed_tex != null:
		shed_background.texture = shed_tex
	shed_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shed_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	shed_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shed_background.visible = true
	stage_canvas.add_child(shed_background)
	wilderness_background = _environment_texture("res://ui/assets/combat/wilderness.png")
	camp_background = _environment_texture("res://ui/assets/combat/raider-camp.png")
	waterworks_background = _environment_texture("res://ui/assets/combat/waterworks.png")
	relay_background = _environment_texture("res://ui/assets/combat/buried-relay.png")
	isometric_ground = IsometricGround.new()
	isometric_ground.hide()
	stage_canvas.add_child(isometric_ground)

	# 3. Actor Layer with native Y-sorting
	actor_layer = Node2D.new()
	actor_layer.y_sort_enabled = true
	stage_canvas.add_child(actor_layer)

	# 4. FX / Damage Popup Layer (drawn above actors)
	fx_layer = Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stage_canvas.add_child(fx_layer)

	# Hero Actor
	hero_actor = ActorNode.new(true)
	actor_layer.add_child(hero_actor)
	hero = hero_actor.body
	hero_shadow = hero_actor.shadow
	weapon = hero_actor.weapon

	# Enemy Actor
	enemy_actor = ActorNode.new(false)
	actor_layer.add_child(enemy_actor)
	enemy = enemy_actor.body
	enemy_shadow = enemy_actor.shadow
	enemy_placeholder = enemy_actor.placeholder

	# 4. HUD / Floating labels inside stage_canvas
	placeholder_note = Label.new()
	placeholder_note.text = "（敵方為暫用示意圖）"
	placeholder_note.add_theme_font_size_override("font_size", 10)
	placeholder_note.add_theme_color_override("font_color", Color(0.75, 0.70, 0.62, 0.75))
	placeholder_note.visible = false
	stage_canvas.add_child(placeholder_note)

	floating = Label.new()
	floating.theme_type_variation = "PdaTitle"
	floating.add_theme_color_override("font_shadow_color", Color.BLACK)
	floating.add_theme_constant_override("shadow_offset_x", 2)
	floating.add_theme_constant_override("shadow_offset_y", 2)
	floating.hide()
	stage_canvas.add_child(floating)
	support_turret = TextureRect.new()
	support_turret.texture = load_texture_safe("res://ui/assets/combat/relay-turret.png")
	support_turret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	support_turret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	support_turret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	support_turret.hide()
	stage_canvas.add_child(support_turret)

	stage_canvas.resized.connect(arrange)
	resized.connect(arrange)

func arrange() -> void:
	if active_motion != null and active_motion.is_valid() and active_motion.is_running():
		cancel_motion()
	if isometric and size.x > 0.0 and size.y > 0.0:
		# The ground has its own 2:1 projection; let the container follow the
		# available arena instead of letterboxing it to a fixed camera ratio.
		var arena_ratio := size.x / size.y
		if not is_equal_approx(aspect_frame.ratio, arena_ratio):
			aspect_frame.ratio = arena_ratio
	# Use stage_canvas size if available; fallback to size
	var cw: float = stage_canvas.size.x if stage_canvas != null and stage_canvas.size.x > 0.0 else size.x
	var ch: float = stage_canvas.size.y if stage_canvas != null and stage_canvas.size.y > 0.0 else size.y
	if cw <= 0.0 or ch <= 0.0:
		return

	# BVIS-1B NORMALIZED DUEL ZONE:
	# Hero ground position: (cw * 0.35, ch * 0.76)
	# Enemy ground position: (cw * 0.64, ch * 0.68)
	# Vertical delta is 8% of canvas height (intimate duel band on open road).
	# Both authored feet rest on the same ground line; left/right never swap.
	hero_origin = Vector2(cw * 0.28, ch * 0.92)
	enemy_origin = Vector2(cw * 0.72, ch * 0.92)
	if isometric:
		var terrain: Texture2D = {"shed": shed_background, "highway": road_background, "wilderness": wilderness_background, "camp": camp_background, "waterworks": waterworks_background, "relay": relay_background}[environment_id].texture
		isometric_ground.configure(Vector2(cw, ch), terrain, environment_id)
		hero_origin = isometric_ground.project(Vector2(0.20, 0.95))
		enemy_origin = isometric_ground.project(Vector2(0.70, -0.40))

	hero_actor.position = hero_origin
	enemy_actor.position = enemy_origin

	# Apply Drifter profile
	if VISUAL_PROFILES.has("drifter"):
		hero_actor.apply_profile(VISUAL_PROFILES["drifter"], ch)

	_update_enemy_visuals(ch)
	if support_turret != null:
		support_turret.size = Vector2.ONE * ch * 0.23
		support_turret.position = Vector2(cw * 0.31, ch * 0.38) - support_turret.size * 0.5

	if placeholder_note != null:
		placeholder_note.position = Vector2(8, ch - 18)

func _update_enemy_visuals(canvas_h: float) -> void:
	var has_profile := VISUAL_PROFILES.has(current_enemy_id)
	var has_art := false

	if has_profile:
		var profile: Dictionary = VISUAL_PROFILES[current_enemy_id]
		var tex_path: String = profile.get("texture_path", "")
		var tex := load_texture_safe(tex_path)
		has_art = tex != null
		if has_art:
			enemy_actor.apply_profile(profile, canvas_h)

	showing_placeholder = not has_art
	enemy.visible = (enemy_alive or terminal_outcome == "VICTORY") and has_art
	enemy_placeholder.visible = enemy_alive and showing_placeholder
	enemy_shadow.visible = enemy_alive or terminal_outcome == "VICTORY"

	if not has_art:
		var enemy_h := canvas_h * 0.40
		var shadow_r := enemy_h * 0.25
		var bulk := 1.35 if current_enemy_id == "heavy_raider" else 1.0
		var body_col := Color(0.40, 0.41, 0.44) if current_enemy_id == "heavy_raider" else Color(0.34, 0.30, 0.28)
		var trim_col := Color(0.78, 0.55, 0.24) if current_enemy_id == "heavy_raider" else Color(0.72, 0.60, 0.32)
		enemy_actor.apply_placeholder(bulk, body_col, trim_col, enemy_h, shadow_r)

	if placeholder_note != null:
		placeholder_note.visible = showing_placeholder

func _environment_texture(path: String) -> TextureRect:
	var backdrop := TextureRect.new()
	backdrop.texture = load_texture_safe(path)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.hide()
	stage_canvas.add_child(backdrop)
	return backdrop

func configure_environment(id: String) -> bool:
	if id not in ["shed", "highway", "wilderness", "camp", "waterworks", "relay"]:
		return false
	environment_id = id
	shed_background.visible = id == "shed"
	road_background.visible = id == "highway" and road_background.texture != null
	wilderness_background.visible = id == "wilderness"
	camp_background.visible = id == "camp"
	waterworks_background.visible = id == "waterworks"
	relay_background.visible = id == "relay"
	road_fallback.visible = id == "highway" and road_background.texture == null
	arrange()
	return true

func configure_isometric(enabled: bool) -> void:
	isometric = enabled
	if not enabled:
		aspect_frame.ratio = 16.0 / 9.0
	isometric_ground.visible = enabled
	for background in [shed_background, road_background, wilderness_background, camp_background, waterworks_background, relay_background]:
		background.modulate = Color(0.38, 0.38, 0.38) if enabled else Color.WHITE
	arrange()

func configure(enemy_id: String, weapon_item_id: String, is_road: bool) -> bool:
	# FAIL-CLOSED: Unregistered enemy IDs are rejected
	if not enemy_id in KNOWN_ENEMIES:
		push_error("BVIS-1B: unregistered enemy_id '%s' rejected" % enemy_id)
		return false

	if current_enemy_id != enemy_id or current_weapon_id != weapon_item_id:
		cancel_motion()
		terminal_outcome = ""
	current_enemy_id = enemy_id
	current_weapon_id = weapon_item_id
	is_road_stage = is_road

	configure_environment("highway" if is_road else "shed")

	# Weapon display
	var art: Texture2D = null
	if weapon_item_id != "":
		art = ItemIcon.texture_for(weapon_item_id)
	if art == null and weapon_item_id == "crowbar":
		art = ItemIcon.texture_for("crowbar")
	weapon.texture = art
	hero_actor.weapon_id = weapon_item_id
	armed = art != null
	weapon.visible = armed

	arrange()
	return true

func refresh(equipped: bool, alive: bool) -> void:
	enemy_alive = alive
	weapon.visible = armed or (equipped and weapon.texture != null)
	enemy.visible = alive and not showing_placeholder
	enemy_placeholder.visible = alive and showing_placeholder
	enemy_shadow.visible = alive
	hero.modulate = Color.WHITE
	hero_actor.rotation = 0.0
	enemy_actor.rotation = 0.0
	hero_actor.modulate.a = 1.0
	arrange()
	present_outcome(terminal_outcome)

func configure_captive(disarmed: bool) -> void:
	enemy_actor.disarmed = disarmed
	enemy_actor.hold_pose("rest")

func animate_turn(command: String, dealt: int, taken: int, context: Dictionary = {}) -> void:
	var receipt := context.duplicate()
	receipt["command"] = command
	receipt["dealt"] = dealt
	receipt["taken"] = taken
	if not receipt.has("enemy_id"):
		receipt["enemy_id"] = current_enemy_id
	await MotionDirector.direct_turn(self, receipt)

func configure_support(enabled: bool) -> void:
	support_turret.visible = enabled and environment_id == "relay"

func emit_turret_support(amount: int) -> void:
	# A committed receipt supplies the amount; this effect has no simulation access.
	spawn_damage_popup(enemy_actor, amount, false, false).text = "砲塔 −%d" % amount
	feedback_phase.emit("turret_support")
	if reduced_motion: return
	var beam: Line2D = Line2D.new()
	beam.width = 2
	beam.default_color = Tokens.AMBER
	beam.points = PackedVector2Array([support_turret.position + support_turret.size * Vector2(0.70, 0.38), enemy_origin - Vector2(0, enemy_actor.target_height * 0.5)])
	fx_layer.add_child(beam)
	var fade: Tween = beam.create_tween()
	fade.tween_interval(0.12)
	fade.tween_callback(beam.queue_free)

func spawn_damage_popup(target_actor: ActorNode, amount: int, is_heavy: bool, is_defended: bool) -> Label:
	if target_actor == null:
		return null
	var label := Label.new()
	label.theme_type_variation = "PdaTitle"
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if is_defended:
		label.text = "-%d (格擋)" % amount if amount > 0 else "0 (格擋)"
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	elif is_heavy:
		label.text = "-%d 重創!" % amount
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.20))
	elif amount > 0:
		label.text = "-%d" % amount
		label.add_theme_font_size_override("font_size", 20)
		if target_actor == enemy_actor:
			label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.44, 0.30))
	else:
		label.text = "MISS"
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))

	label.custom_minimum_size = Vector2(140, 30)
	var spawn_pos := Vector2(
		target_actor.position.x - 70.0,
		target_actor.position.y - target_actor.target_height - 25.0
	)
	label.position = spawn_pos

	var target_parent: Node = fx_layer if fx_layer != null else stage_canvas
	target_parent.add_child(label)

	var popup_tween := label.create_tween()
	if not reduced_motion:
		popup_tween.tween_property(label, "position:y", spawn_pos.y - 28.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		popup_tween.tween_interval(0.55)
	popup_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.40).set_delay(0.20)
	popup_tween.tween_callback(label.queue_free)

	return label
