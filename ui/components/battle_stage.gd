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

var hero: TextureRect
var enemy: TextureRect
var hero_shadow: GroundShadow
var enemy_shadow: GroundShadow
var weapon: Sprite2D
var floating: Label
var hero_origin := Vector2.ZERO
var enemy_origin := Vector2.ZERO
var reduced_motion := false
var enemy_alive := true

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
	var background := TextureRect.new()
	background.texture = texture("res://ui/assets/combat/supply-shed.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
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

func refresh(equipped: bool, alive: bool) -> void:
	weapon.visible = equipped
	enemy_alive = alive
	enemy.visible = alive
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
