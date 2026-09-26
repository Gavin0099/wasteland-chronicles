extends Control
class_name BattleStage

const ItemIcon = preload("res://ui/components/item_icon.gd")
const MotionDirector = preload("res://ui/components/battle_motion_director.gd")

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

const KNOWN_ENEMIES := ["feral_dog", "bandit", "heavy_raider"]

const VISUAL_PROFILES := {
	"drifter": {
		"texture_path": "res://ui/assets/combat/drifter.png",
		"foot_anchor_uv": Vector2(0.50, 0.98),
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
			if bitmap != null:
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
	var target_height := 160.0
	var texture_ref: Texture2D = null
	var anim_player: AnimationPlayer

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
			add_child(weapon)
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
			a_atk.track_set_path(t_w_rot, NodePath("Weapon:rotation"))
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
		a_hit.track_insert_key(t_hit_mod, 0.06, Color(0.76, 0.68, 0.60))
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
			a_brace.track_set_path(t_bw_rot, NodePath("Weapon:rotation"))
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

		anim_player.add_animation_library("", lib)

	func apply_profile(profile: Dictionary, canvas_h: float) -> void:
		var tex_path: String = profile.get("texture_path", "")
		var tex: Texture2D = TextureHelper.load_texture_safe(tex_path)
		texture_ref = tex
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

			if weapon != null and weapon.texture != null:
				var w_tex: Texture2D = weapon.texture
				weapon.scale = Vector2.ONE * (58.0 / maxf(1.0, float(w_tex.get_width())))
				weapon.position = Vector2(target_height * 0.18, -target_height * 0.52)

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
var reduced_motion := false
var enemy_alive := true
var armed := false
var showing_placeholder := false
var current_enemy_id := ""
var current_weapon_id := ""
var is_road_stage := false

static func load_texture_safe(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path)
		if imported is Texture2D:
			return imported
	if FileAccess.file_exists(path):
		var bitmap := Image.load_from_file(path)
		if bitmap != null:
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

	stage_canvas.resized.connect(arrange)
	resized.connect(arrange)

func arrange() -> void:
	# Use stage_canvas size if available; fallback to size
	var cw: float = stage_canvas.size.x if stage_canvas != null and stage_canvas.size.x > 0.0 else size.x
	var ch: float = stage_canvas.size.y if stage_canvas != null and stage_canvas.size.y > 0.0 else size.y
	if cw <= 0.0 or ch <= 0.0:
		return

	# BVIS-1B NORMALIZED DUEL ZONE:
	# Hero ground position: (cw * 0.35, ch * 0.76)
	# Enemy ground position: (cw * 0.64, ch * 0.68)
	# Vertical delta is 8% of canvas height (intimate duel band on open road).
	hero_origin = Vector2(cw * 0.35, ch * 0.76)
	enemy_origin = Vector2(cw * 0.64, ch * 0.68)

	hero_actor.position = hero_origin
	enemy_actor.position = enemy_origin

	# Apply Drifter profile
	if VISUAL_PROFILES.has("drifter"):
		hero_actor.apply_profile(VISUAL_PROFILES["drifter"], ch)

	_update_enemy_visuals(ch)

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
	enemy.visible = enemy_alive and has_art
	enemy_placeholder.visible = enemy_alive and showing_placeholder
	enemy_shadow.visible = enemy_alive

	if not has_art:
		var enemy_h := canvas_h * 0.40
		var shadow_r := enemy_h * 0.25
		var bulk := 1.35 if current_enemy_id == "heavy_raider" else 1.0
		var body_col := Color(0.40, 0.41, 0.44) if current_enemy_id == "heavy_raider" else Color(0.34, 0.30, 0.28)
		var trim_col := Color(0.78, 0.55, 0.24) if current_enemy_id == "heavy_raider" else Color(0.72, 0.60, 0.32)
		enemy_actor.apply_placeholder(bulk, body_col, trim_col, enemy_h, shadow_r)

	if placeholder_note != null:
		placeholder_note.visible = showing_placeholder

func configure(enemy_id: String, weapon_item_id: String, is_road: bool) -> bool:
	# FAIL-CLOSED: Unregistered enemy IDs are rejected
	if not enemy_id in KNOWN_ENEMIES:
		push_error("BVIS-1B: unregistered enemy_id '%s' rejected" % enemy_id)
		return false

	current_enemy_id = enemy_id
	current_weapon_id = weapon_item_id
	is_road_stage = is_road

	# Background switching
	if shed_background != null:
		shed_background.visible = not is_road
	if road_background != null:
		var has_road_tex := road_background.texture != null
		road_background.visible = is_road and has_road_tex
		if road_fallback != null:
			road_fallback.visible = is_road and not has_road_tex

	# Weapon display
	var art: Texture2D = null
	if weapon_item_id != "":
		art = ItemIcon.texture_for(weapon_item_id)
	if art == null and weapon_item_id == "crowbar":
		art = ItemIcon.texture_for("crowbar")
	if art != null:
		weapon.texture = art
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

func animate_turn(command: String, dealt: int, taken: int, context: Dictionary = {}) -> void:
	var receipt := context.duplicate()
	receipt["command"] = command
	receipt["dealt"] = dealt
	receipt["taken"] = taken
	if not receipt.has("enemy_id"):
		receipt["enemy_id"] = current_enemy_id
	await MotionDirector.direct_turn(self, receipt)

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

	var popup_tween := create_tween()
	popup_tween.tween_property(label, "position:y", spawn_pos.y - 28.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	popup_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.40).set_delay(0.20)
	popup_tween.tween_callback(label.queue_free)

	return label
