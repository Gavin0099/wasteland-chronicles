extends Control

const Tokens = preload("res://ui/theme/pda_tokens.gd")
var hero: TextureRect
var enemy: TextureRect
var weapon: Line2D
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
	hero = TextureRect.new()
	hero.texture = texture("res://ui/assets/combat/drifter.png")
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.size = Vector2(116, 174)
	add_child(hero)
	weapon = Line2D.new()
	weapon.points = PackedVector2Array([Vector2(81, 77), Vector2(106, 40), Vector2(104, 33), Vector2(99, 34)])
	weapon.width = 3
	weapon.default_color = Tokens.SECONDARY
	hero.add_child(weapon)
	enemy = TextureRect.new()
	enemy.texture = texture("res://ui/assets/combat/feral-dog.png")
	enemy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy.size = Vector2(128, 136)
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

func refresh(equipped: bool, alive: bool) -> void:
	weapon.visible = equipped
	enemy_alive = alive
	enemy.visible = alive
	hero.modulate = Color.WHITE
	enemy.modulate = Color.WHITE
	arrange()

func animate_turn(command: String, dealt: int, taken: int) -> void:
	if reduced_motion:
		return
	arrange()
	var motion := create_tween()
	if command == "ATTACK":
		motion.tween_property(hero, "position", hero_origin.lerp(enemy_origin, 0.55), 0.16)
		motion.tween_callback(func(): enemy.modulate = Color(2, 2, 2))
		motion.tween_interval(0.08)
		motion.tween_property(hero, "position", hero_origin, 0.16)
		motion.tween_callback(func(): enemy.modulate = Color.WHITE)
	elif command == "DEFEND":
		motion.tween_property(hero, "modulate", Tokens.AMBER, 0.12)
		motion.tween_property(hero, "modulate", Color.WHITE, 0.12)
	if (taken > 0 or command == "DEFEND") and command != "FLEE":
		motion.tween_property(enemy, "position", enemy_origin.lerp(hero_origin, 0.4), 0.16)
		motion.tween_callback(func(): hero.modulate = Color(2, 2, 2))
		motion.tween_property(enemy, "position", enemy_origin, 0.16)
		motion.tween_callback(func(): hero.modulate = Color.WHITE)
	if command == "FLEE":
		motion.tween_property(hero, "position", hero_origin + Vector2(-100, 35), 0.25)
		motion.parallel().tween_property(hero, "modulate:a", 0.0, 0.25)
	floating.text = "造成 %d　承受 %d" % [dealt, taken]
	floating.position = Vector2(size.x * 0.35, 24)
	floating.show()
	motion.tween_interval(0.22)
	await motion.finished
	floating.hide()
