extends Node2D

const Poses = preload("res://ui/components/battle_pose_library.gd")
const PATH: String = "res://ui/assets/combat/poses/relay-hound-poses.png"
var body: Sprite2D
var idle: AtlasTexture
var work: AtlasTexture
var motion: Tween
var base_position: Vector2 = Vector2.ZERO

func _init() -> void:
	var atlas: Texture2D = Poses.load_atlas(PATH)
	idle = AtlasTexture.new(); idle.atlas = atlas; idle.region = Rect2(0, 0, 887, 887)
	work = AtlasTexture.new(); work.atlas = atlas; work.region = Rect2(887, 0, 887, 887)
	body = Sprite2D.new(); body.centered = false; body.texture = idle; body.position = -Vector2(570, 805)
	add_child(body)

func configure(height: float, broken: bool = false) -> void:
	scale = Vector2.ONE * height / 700.0
	body.modulate = Color(0.45, 0.45, 0.45, 1) if broken else Color.WHITE

func cancel() -> void:
	if motion != null and motion.is_valid(): motion.kill()
	motion = null
	position = base_position
	body.texture = idle; body.position = -Vector2(570, 805)

func assist(reduced: bool, destination: Vector2) -> void:
	cancel()
	body.texture = work; body.position = -Vector2(710, 821)
	if reduced: return
	motion = create_tween()
	motion.tween_property(self, "position", base_position.lerp(destination, 0.55), 0.17)
	motion.tween_interval(0.12)
	motion.tween_property(self, "position", base_position, 0.20)
	motion.tween_callback(cancel)

func _exit_tree() -> void:
	if motion != null and motion.is_valid(): motion.kill()
