extends Control

const ItemIcon = preload("res://ui/components/item_icon.gd")

# The painted arena has a fixed camera. These layered contact marks keep the
# separately rendered fighters attached to that ground plane as they move.
class GroundShadow extends Node2D:
	var radius := 40.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, radius * 1.25, Color(0.10, 0.075, 0.05, 0.09))
		draw_circle(Vector2.ZERO, radius, Color(0.10, 0.075, 0.05, 0.17))
		draw_circle(Vector2.ZERO, radius * 0.68, Color(0.10, 0.075, 0.05, 0.12))
		draw_set_transform(Vector2.ZERO)

# PLAY-1 BATTLE TRUTH.
#
# The stage used to hardcode three things: a supply-shed background, a feral
# dog, and a crowbar. So a road ambush showed the label "荒原劫匪" over a
# picture of a dog standing in a shed, and equipping a machete changed the
# damage and the text while the hand still held a crowbar or nothing at all.
# The screen was telling the player something the game did not mean.
#
# Every one of those three now comes from the battle itself. Where real art
# exists it is used; where it does not, a PLACEHOLDER is drawn and labelled as
# one. A drawn silhouette that is honestly a stand-in beats a dog pretending to
# be a bandit.
class PlaceholderFigure extends Node2D:
	var figure_size := Vector2(128, 136)
	var body := Color(0.34, 0.30, 0.28)
	var trim := Color(0.72, 0.60, 0.32)
	# A heavier build for the raider. Two stand-ins that look the same would
	# repeat the exact mistake this class exists to fix.
	var bulk := 1.0

	func _draw() -> void:
		var w := figure_size.x * bulk
		var h := figure_size.y
		# Wide separation, because a figure whose light and shade differ by a few
		# percent is a silhouette no matter how many vertices it has.
		var lit := Color(body).lightened(0.38)
		var dark := Color(body).darkened(0.55)

		# Shadow first, so the figure stands on the ground rather than floating.
		draw_set_transform(Vector2(w * 0.5, h * 0.99), 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, w * 0.34, Color(0.08, 0.06, 0.05, 0.35))
		draw_set_transform(Vector2.ZERO)

		# Legs, slightly apart and braced.
		draw_line(Vector2(w * 0.455, h * 0.66), Vector2(w * 0.40, h * 0.98), dark, w * 0.085, true)
		draw_line(Vector2(w * 0.555, h * 0.66), Vector2(w * 0.62, h * 0.98), dark, w * 0.085, true)

		# Torso and coat, lit from the upper left. draw_polygon takes a colour
		# per vertex, which is what turns a flat cut-out into a form.
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
		# Rim light down the lit edge sells the volume more than any fill does.
		draw_polyline(PackedVector2Array([
			Vector2(w * 0.36, h * 0.30), Vector2(w * 0.30, h * 0.50), Vector2(w * 0.26, h * 0.70),
		]), Color(lit).lightened(0.25), 1.5, true)

		# Head and shoulders.
		draw_circle(Vector2(w * 0.5, h * 0.185), w * 0.105, dark)
		draw_circle(Vector2(w * 0.475, h * 0.17), w * 0.085, body)
		draw_line(Vector2(w * 0.36, h * 0.30), Vector2(w * 0.64, h * 0.30), dark, w * 0.05, true)

		# The weapon arm, raised. The trim colour is the only warm note, so the
		# eye goes to the thing that is about to hit you.
		draw_line(Vector2(w * 0.63, h * 0.35), Vector2(w * 0.82, h * 0.22), body, w * 0.065, true)
		draw_line(Vector2(w * 0.80, h * 0.25), Vector2(w * 0.90, h * 0.04), trim, w * 0.045, true)
		draw_line(Vector2(w * 0.37, h * 0.36), Vector2(w * 0.23, h * 0.54), body, w * 0.06, true)

# The road is not the supply shed, and until there is art for it saying so
# plainly is better than reusing the shed and hoping nobody notices.
class PlaceholderBackdrop extends Control:
	# The first version of this was three flat polygons and it looked like three
	# flat polygons. `draw_polygon` takes a colour PER VERTEX, which is the whole
	# difference between a fill and a sky; `draw_polyline` and `draw_line` take
	# an antialiased flag. Using them is what separates a stand-in that reads as
	# a place from one that reads as a debug shape.
	const HORIZON := 0.46

	func _band(points: Array, colors: Array) -> void:
		draw_polygon(PackedVector2Array(points), PackedColorArray(colors))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var sky_top := Color(0.30, 0.25, 0.22)
		var sky_low := Color(0.62, 0.47, 0.33)
		# Sky, hot and hazy toward the horizon rather than one flat brown.
		_band([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * HORIZON), Vector2(0, h * HORIZON)],
			[sky_top, sky_top, sky_low, sky_low])

		# Three ridge layers. Each nearer one is darker and sits lower, which is
		# the cheapest honest way to get depth out of flat shapes.
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
				# A fixed, repeatable profile: no RNG, so the road looks the
				# same every time the screen is drawn.
				var bump := sin(t * float(ridge.seed) * 1.7) * 0.5 + sin(t * float(ridge.seed) * 0.6) * 0.5
				points.append(Vector2(w * t, h * (float(ridge.y) - float(ridge.amp) * bump)))
				colors.append(ridge.color)
			points.append(Vector2(w, h))
			points.append(Vector2(0, h))
			colors.append(Color(ridge.color).darkened(0.25))
			colors.append(Color(ridge.color).darkened(0.25))
			_band(points, colors)

		# Ground, lighter where the light falls and darker at the player's feet.
		_band([Vector2(0, h * HORIZON), Vector2(w, h * HORIZON), Vector2(w, h), Vector2(0, h)],
			[Color(0.44, 0.35, 0.27), Color(0.44, 0.35, 0.27),
			 Color(0.24, 0.19, 0.16), Color(0.24, 0.19, 0.16)])

		# The road, widening toward the camera and catching more light near it.
		_band([Vector2(w * 0.455, h * HORIZON), Vector2(w * 0.545, h * HORIZON),
			Vector2(w * 0.92, h), Vector2(w * 0.04, h)],
			[Color(0.50, 0.42, 0.34), Color(0.50, 0.42, 0.34),
			 Color(0.33, 0.28, 0.24), Color(0.33, 0.28, 0.24)])

		# Worn edges and a broken centre line give the road a direction.
		draw_line(Vector2(w * 0.455, h * HORIZON), Vector2(w * 0.04, h), Color(0.22, 0.18, 0.15, 0.7), 2.0, true)
		draw_line(Vector2(w * 0.545, h * HORIZON), Vector2(w * 0.92, h), Color(0.22, 0.18, 0.15, 0.7), 2.0, true)
		var dashes := 6
		for i in range(dashes):
			var t0 := float(i) / float(dashes)
			var t1 := t0 + 0.055
			if t1 > 1.0:
				break
			# Perspective: dashes lengthen and widen as they approach.
			draw_line(
				Vector2(lerpf(w * 0.5, w * 0.48, t0), lerpf(h * HORIZON, h, t0 * t0)),
				Vector2(lerpf(w * 0.5, w * 0.48, t1), lerpf(h * HORIZON, h, t1 * t1)),
				Color(0.70, 0.62, 0.45, 0.45), 1.0 + 3.0 * t0, true)

		# A little wreckage on the shoulder, so the eye has something to land on.
		_silhouette(Vector2(w * 0.085, h * 0.60), w * 0.10, h * 0.055, Color(0.20, 0.17, 0.15))
		_silhouette(Vector2(w * 0.88, h * 0.55), w * 0.055, h * 0.032, Color(0.22, 0.18, 0.16))
		draw_line(Vector2(w * 0.735, h * 0.505), Vector2(w * 0.742, h * 0.40), Color(0.19, 0.16, 0.14), 2.0, true)
		draw_line(Vector2(w * 0.742, h * 0.40), Vector2(w * 0.775, h * 0.415), Color(0.19, 0.16, 0.14), 2.0, true)

	# A low hulk: something rusted that stopped here a long time ago.
	func _silhouette(base: Vector2, wide: float, tall: float, tint: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-wide * 0.5, 0.0),
			base + Vector2(-wide * 0.42, -tall * 0.75),
			base + Vector2(-wide * 0.05, -tall),
			base + Vector2(wide * 0.30, -tall * 0.92),
			base + Vector2(wide * 0.5, -tall * 0.35),
			base + Vector2(wide * 0.46, 0.0),
		]), tint)

var hero: TextureRect
var enemy: TextureRect
var enemy_placeholder: PlaceholderFigure
var shed_background: TextureRect
var road_background: PlaceholderBackdrop
var placeholder_note: Label
var hero_shadow: GroundShadow
var enemy_shadow: GroundShadow
var weapon: Sprite2D
var floating: Label
var hero_origin := Vector2.ZERO
var enemy_origin := Vector2.ZERO
var reduced_motion := false
var enemy_alive := true
var armed := false
var showing_bandit := false

func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path)
		if imported is Texture2D:
			return imported
	var bitmap := Image.load_from_file(path)
	return ImageTexture.create_from_image(bitmap)

func _init() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(0, 240)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	road_background = PlaceholderBackdrop.new()
	road_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	road_background.visible = false
	add_child(road_background)
	var background := TextureRect.new()
	background.texture = texture("res://ui/assets/combat/supply-shed.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shed_background = background
	add_child(background)
	hero_shadow = GroundShadow.new()
	hero_shadow.radius = 35.0
	add_child(hero_shadow)
	enemy_shadow = GroundShadow.new()
	enemy_shadow.radius = 47.0
	add_child(enemy_shadow)
	hero = TextureRect.new()
	hero.texture = texture("res://ui/assets/combat/drifter.png")
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.size = Vector2(116, 174)
	hero.pivot_offset = hero.size * 0.5
	add_child(hero)
	weapon = Sprite2D.new()
	weapon.texture = ItemIcon.texture_for("crowbar")
	if weapon.texture != null:
		weapon.scale = Vector2.ONE * (62.0 / weapon.texture.get_width())
	weapon.position = Vector2(97, 53)
	hero.add_child(weapon)
	enemy = TextureRect.new()
	enemy.texture = texture("res://ui/assets/combat/feral-dog.png")
	enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy.size = Vector2(128, 136)
	enemy.pivot_offset = enemy.size * 0.5
	add_child(enemy)
	enemy_placeholder = PlaceholderFigure.new()
	enemy_placeholder.visible = false
	add_child(enemy_placeholder)
	placeholder_note = Label.new()
	placeholder_note.text = "（劫匪與荒路為暫用示意圖）"
	placeholder_note.add_theme_font_size_override("font_size", 10)
	placeholder_note.add_theme_color_override("font_color", Color(0.75, 0.70, 0.62, 0.75))
	placeholder_note.visible = false
	add_child(placeholder_note)
	floating = Label.new()
	floating.theme_type_variation = "PdaTitle"
	floating.add_theme_color_override("font_shadow_color", Color.BLACK)
	floating.add_theme_constant_override("shadow_offset_x", 2)
	floating.add_theme_constant_override("shadow_offset_y", 2)
	floating.hide()
	add_child(floating)
	resized.connect(arrange)

func arrange() -> void:
	hero_origin = Vector2(size.x * 0.36 - 58, size.y * 0.72 - 174)
	enemy_origin = Vector2(size.x * 0.65 - 64, size.y * 0.48 - 68)
	hero.position = hero_origin
	enemy.position = enemy_origin
	hero_shadow.position = hero_origin + Vector2(58, 156)
	enemy_shadow.position = enemy_origin + Vector2(64, 123)
	if enemy_placeholder != null:
		enemy_placeholder.position = enemy_origin
		enemy_placeholder.queue_redraw()
	if placeholder_note != null:
		placeholder_note.position = Vector2(8, size.y - 18)

# PLAY-1: the battle tells the stage who is in it, what is in the player's hand
# and where it is happening. Everything below is presentation; no combat number
# is read or written here.
#
#   enemy_id       "feral_dog" (real art) or "bandit" (drawn placeholder)
#   weapon_item_id the item really equipped in main_hand, "" for none
#   is_road        a road ambush rather than the Gray Valley shed
func configure(enemy_id: String, weapon_item_id: String, is_road: bool) -> void:
	# Anything without real art gets the drawn stand-in. Checking for one
	# specific id was how the raider quietly ended up being drawn as a dog.
	var has_art := enemy_id == "feral_dog"
	var drawn := not has_art
	enemy.visible = enemy_alive and has_art
	enemy_placeholder.visible = enemy_alive and drawn
	enemy_placeholder.bulk = 1.35 if enemy_id == "heavy_raider" else 1.0
	# The raider is armour plate, the bandit is cloth and leather. Both must sit
	# clearly above the sand behind them or they read as holes in the picture.
	enemy_placeholder.body = Color(0.40, 0.41, 0.44) if enemy_id == "heavy_raider" else Color(0.34, 0.30, 0.28)
	enemy_placeholder.trim = Color(0.78, 0.55, 0.24) if enemy_id == "heavy_raider" else Color(0.72, 0.60, 0.32)
	enemy_placeholder.queue_redraw()
	if shed_background != null:
		shed_background.visible = not is_road
	if road_background != null:
		road_background.visible = is_road
	if placeholder_note != null:
		placeholder_note.visible = drawn or is_road

	# The hand shows what is actually equipped. The crowbar is only the fallback
	# for the legacy field kit, which predates the equipment slots.
	var art: Texture2D = null
	if weapon_item_id != "":
		art = ItemIcon.texture_for(weapon_item_id)
	if art == null and weapon_item_id == "crowbar":
		art = ItemIcon.texture_for("crowbar")
	if art != null:
		weapon.texture = art
		weapon.scale = Vector2.ONE * (62.0 / maxf(1.0, float(art.get_width())))
	armed = art != null
	weapon.visible = armed
	showing_bandit = drawn
	arrange()

func refresh(equipped: bool, alive: bool) -> void:
	# `equipped` is the legacy field-kit crowbar flag and is now only one way to
	# be armed; configure() has already decided what is in the hand.
	weapon.visible = armed or (equipped and weapon.texture != null)
	enemy_alive = alive
	enemy.visible = alive and not showing_bandit
	enemy_placeholder.visible = alive and showing_bandit
	enemy_shadow.visible = alive
	hero.modulate = Color.WHITE
	enemy.modulate = Color.WHITE
	hero.rotation = 0.0
	enemy.rotation = 0.0
	hero_shadow.modulate.a = 1.0
	arrange()

func animate_turn(command: String, dealt: int, taken: int) -> void:
	if reduced_motion:
		return
	arrange()
	var motion := create_tween()
	if command == "ATTACK":
		var recoil := Vector2(-12, 3)
		var lunge := hero_origin.lerp(enemy_origin, 0.55)
		motion.tween_property(hero, "position", hero_origin + recoil, 0.09)
		motion.parallel().tween_property(hero_shadow, "position", hero_shadow.position + recoil, 0.09)
		motion.parallel().tween_property(hero, "rotation", -0.04, 0.09)
		motion.tween_property(hero, "position", lunge, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		motion.parallel().tween_property(hero_shadow, "position", lunge + Vector2(58, 156), 0.13)
		motion.parallel().tween_property(hero, "rotation", 0.08, 0.13)
		motion.tween_property(enemy, "modulate", Color(0.76, 0.68, 0.60), 0.06)
		motion.parallel().tween_property(enemy, "position", enemy_origin + Vector2(7, -3), 0.06)
		motion.parallel().tween_property(enemy_shadow, "position", enemy_origin + Vector2(71, 120), 0.06)
		motion.tween_property(hero, "position", hero_origin, 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		motion.parallel().tween_property(hero_shadow, "position", hero_origin + Vector2(58, 156), 0.19)
		motion.parallel().tween_property(hero, "rotation", 0.0, 0.19)
		motion.parallel().tween_property(enemy, "position", enemy_origin, 0.19)
		motion.parallel().tween_property(enemy_shadow, "position", enemy_origin + Vector2(64, 123), 0.19)
		motion.parallel().tween_property(enemy, "modulate", Color.WHITE, 0.19)
	elif command == "DEFEND":
		motion.tween_property(hero, "modulate", Color(0.86, 0.76, 0.62), 0.12)
		motion.tween_property(hero, "modulate", Color.WHITE, 0.12)
	if (taken > 0 or command == "DEFEND") and command != "FLEE":
		var pounce := enemy_origin.lerp(hero_origin, 0.4)
		motion.tween_property(enemy, "position", pounce, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		motion.parallel().tween_property(enemy_shadow, "position", pounce + Vector2(64, 123), 0.13)
		motion.parallel().tween_property(enemy, "rotation", -0.07, 0.13)
		motion.tween_property(hero, "modulate", Color(0.76, 0.68, 0.60), 0.06)
		motion.parallel().tween_property(hero, "position", hero_origin + Vector2(-6, 3), 0.06)
		motion.parallel().tween_property(hero_shadow, "position", hero_origin + Vector2(52, 159), 0.06)
		motion.tween_property(enemy, "position", enemy_origin, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		motion.parallel().tween_property(enemy_shadow, "position", enemy_origin + Vector2(64, 123), 0.18)
		motion.parallel().tween_property(enemy, "rotation", 0.0, 0.18)
		motion.parallel().tween_property(hero, "position", hero_origin, 0.18)
		motion.parallel().tween_property(hero_shadow, "position", hero_origin + Vector2(58, 156), 0.18)
		motion.parallel().tween_property(hero, "modulate", Color.WHITE, 0.18)
	if command == "FLEE":
		motion.tween_property(hero, "position", hero_origin + Vector2(-100, 35), 0.25)
		motion.parallel().tween_property(hero, "modulate:a", 0.0, 0.25)
		motion.parallel().tween_property(hero_shadow, "position", hero_shadow.position + Vector2(-100, 35), 0.25)
		motion.parallel().tween_property(hero_shadow, "modulate:a", 0.0, 0.25)
	floating.text = "造成 %d　承受 %d" % [dealt, taken]
	floating.position = Vector2(size.x * 0.35, 24)
	floating.show()
	motion.tween_interval(0.22)
	await motion.finished
	floating.hide()
