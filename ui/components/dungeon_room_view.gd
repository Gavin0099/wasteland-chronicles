extends Control

# Uses the top-down controller template's normalized axes and remembered facing.
# Room-local movement stays outside WorldState; committed doors own checkpoints.
signal interaction_changed
signal interaction_requested

const Tokens = preload("res://ui/theme/pda_tokens.gd")
const Poses = preload("res://ui/components/battle_pose_library.gd")
const Layout = preload("res://ui/components/dungeon_room_layout.gd")
const Stage = preload("res://ui/components/battle_stage.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Icon = preload("res://ui/components/item_icon.gd")
const ENEMY_POINT: Vector2 = Vector2(650, 266)
const TOOL_POINT: Vector2 = Vector2(500, 266)
var enemy_id: String = ""
var enemy_pose: Dictionary = {}
var enemy_texture: Texture2D
var tool_texture: Texture2D
var device_texture: Texture2D
const FLOOR_PATH: String = "res://ui/assets/dungeon/waterworks-floor.png"
const WALK_AREA: Rect2 = Rect2(96, 112, 808, 310)
const SPEED: float = 180.0
var room_id: String = "entrance"
var actor_position: Vector2 = Vector2(500, 348)
var target_position: Vector2 = Vector2(-1, -1)
var guide_path: Array[Vector2] = []
var obstacles: Array[Rect2] = []
var doors: Array[Dictionary] = []
var enabled: bool = true
var reduced_motion: bool = false
var facing_left: bool = false
var walking: bool = false
var animation_time: float = 0.0
var floor_texture: Texture2D
var pump_texture: Texture2D
var crate_texture: Texture2D
var current_pose: String = "recover"

func _init() -> void:
	custom_minimum_size = Vector2(640, 340)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	focus_mode = FOCUS_ALL
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	floor_texture = Poses.load_atlas(FLOOR_PATH)
	pump_texture = Poses.load_atlas("res://ui/assets/dungeon/waterworks-pump.png")
	crate_texture = Poses.load_atlas("res://ui/assets/items/library/clothing/sealed_cargo_crate.png")
	tool_texture = Icon.texture_for("fieldrepair_precision_kit")

func setup(checkpoint: Dictionary) -> void:
	room_id = checkpoint.room_id
	target_position = Vector2(-1, -1)
	guide_path.clear()
	animation_time = 0.0
	walking = false
	current_pose = "recover"
	doors = Layout.doors(room_id, checkpoint.get("shortcut_open", false))
	for passage: Dictionary in doors:
		if passage.command != "MOVE": continue
		passage.refusal = SimulationEngine.Dungeon.passage_refusal(room_id, passage.room_id, int(checkpoint.get("route_rules", 0)), checkpoint.get("cleared", []), checkpoint.get("maintenance_open", false), int(checkpoint.get("deep_rules", 0)), checkpoint.get("has_mask", false))
		if passage.refusal != "":
			passage.label += " · " + {"DUNGEON_GUARD_BLOCKS_ROUTE": "先排除警衛", "DUNGEON_MAINTENANCE_CLOSED": "維修門鎖住", "DUNGEON_NEED_GAS_MASK": "需軍規面具"}.get(passage.refusal, "尚未開啟")
	enemy_id = String(checkpoint.get("enemy", ""))
	enemy_pose = Poses.frame(enemy_id, "recover")
	enemy_texture = null
	if not enemy_id.is_empty():
		if enemy_pose.is_empty(): enemy_texture = Poses.load_atlas(Stage.VISUAL_PROFILES[enemy_id].texture_path)
		doors.append({"command": "FIGHT", "room_id": room_id, "label": "迎戰 " + Enemies.display_name(enemy_id), "point": ENEMY_POINT})
	if room_id == "polluted_store" and checkpoint.get("deep_rules", 0) == 1 and not checkpoint.get("tools_recovered", false):
		doors.append({"command": "RECOVER_TOOLS", "label": "取走維修精密組", "point": TOOL_POINT, "refusal": checkpoint.get("recovery_refusal", "")})
	if room_id == "control" and checkpoint.get("device_rules", 0) == 1:
		device_texture = crate_texture if checkpoint.device_choice == "SALVAGE" else pump_texture
		doors.append({"command": "DEVICE", "label": "修復台 · 去留" if checkpoint.device_choice == "" else ("修復台 · 已保留" if checkpoint.device_choice == "PRESERVE" else "殘骸 · 已拆解"), "point": TOOL_POINT})
	actor_position = Layout.arrival(doors, checkpoint.from_room_id)
	obstacles = Layout.obstacles(room_id)
	queue_redraw()
	interaction_changed.emit()

func canvas_scale() -> float:
	return minf(size.x / 1000.0, size.y / 500.0)

func canvas_origin() -> Vector2:
	return (size - Vector2(1000, 500) * canvas_scale()) * 0.5

func actor_canvas_position() -> Vector2:
	return canvas_origin() + actor_position * canvas_scale()

func walkable(point: Vector2) -> bool:
	if not WALK_AREA.has_point(point):
		return false
	for obstacle: Rect2 in obstacles:
		if obstacle.grow(12).has_point(point):
			return false
	return true

func move_actor(direction: Vector2, delta: float) -> void:
	if not enabled:
		return
	var previous: Vector2 = actor_position
	var step: Vector2 = direction.limit_length() * SPEED * minf(delta, 0.08)
	var horizontal: Vector2 = actor_position + Vector2(step.x, 0)
	if walkable(horizontal):
		actor_position = horizontal
	var vertical: Vector2 = actor_position + Vector2(0, step.y)
	if walkable(vertical):
		actor_position = vertical
	walking = actor_position.distance_to(previous) > 0.01
	if walking and absf(step.x) > 0.01:
		facing_left = step.x < 0
	animation_time += delta if walking else 0.0
	current_pose = ("step_a" if int(animation_time * 7.0) % 2 == 0 else "step_b") if walking and not reduced_motion else "recover"
	interaction_changed.emit()
	queue_redraw()

func nearest_door() -> Dictionary:
	for door: Dictionary in doors:
		if actor_position.distance_to(door.point) <= 76.0:
			return door.duplicate(true)
	return {}

func walk_to(point: Vector2) -> void:
	if enabled and walkable(point):
		guide_path.clear()
		target_position = point
		grab_focus()
		queue_redraw()

func guide_to(passage: Dictionary) -> void:
	if enabled:
		guide_path = [Vector2(500, 266), Layout.approach(passage)]
		target_position = guide_path.pop_front()
		grab_focus()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		# Keep arrows from the Control's default focus navigation while walking.
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_ENTER]:
		interaction_requested.emit()
		accept_event()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and canvas_scale() > 0:
		walk_to((event.position - canvas_origin()) / canvas_scale())
		accept_event()

func _process(delta: float) -> void:
	if not enabled or not has_focus():
		return
	var direction: Vector2 = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if direction != Vector2.ZERO:
		target_position = Vector2(-1, -1)
		guide_path.clear()
	elif target_position.x >= 0:
		var remaining: float = actor_position.distance_to(target_position)
		direction = actor_position.direction_to(target_position) * minf(1.0, remaining / maxf(0.001, SPEED * minf(delta, 0.08))) if remaining > 5 else Vector2.ZERO
		if direction == Vector2.ZERO:
			target_position = guide_path.pop_front() if not guide_path.is_empty() else Vector2(-1, -1)
	move_actor(direction, delta)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.BASE)
	var zoom: float = canvas_scale()
	if zoom <= 0:
		return
	draw_set_transform(canvas_origin(), 0, Vector2.ONE * zoom)
	var room_rect: Rect2 = Rect2(64, 40, 872, 424)
	draw_rect(room_rect.grow(8), Tokens.BORDER_STRONG)
	if floor_texture != null:
		draw_texture_rect(floor_texture, room_rect, false, Color(0.8, 0.8, 0.8))
	draw_rect(Rect2(64, 40, 872, 64), Tokens.PANEL)
	draw_rect(Rect2(64, 432, 872, 32), Tokens.PANEL)
	draw_rect(Rect2(64, 40, 32, 424), Tokens.PANEL)
	draw_rect(Rect2(904, 40, 32, 424), Tokens.PANEL)
	for x: int in range(100, 900, 48):
		draw_line(Vector2(x, 48), Vector2(x, 96), Tokens.BORDER_STRONG, 2)
	# Wall pipe and pump geometry share the very same obstacle rectangles.
	for obstacle: Rect2 in obstacles:
		var texture: Texture2D = crate_texture if room_id in ["guard", "parts_store", "control"] else pump_texture
		if texture != null:
			draw_texture_rect(texture, obstacle, false)
	for door: Dictionary in doors:
		var point: Vector2 = door.point
		if door.command == "FIGHT":
			_draw_enemy()
			continue
		if door.command == "RECOVER_TOOLS":
			draw_arc(point, 30, 0, TAU, 32, Tokens.AMBER, 2, true)
			if tool_texture != null: draw_texture_rect(tool_texture, Rect2(point - Vector2(26, 50), Vector2(52, 52)), false)
			draw_string(get_theme_default_font(), point + Vector2(-125, -76), "現地維修精密組 · 1.8kg", HORIZONTAL_ALIGNMENT_CENTER, 250, 16, Tokens.TEXT)
			continue
		if door.command == "DEVICE":
			draw_arc(point, 34, 0, TAU, 32, Tokens.AMBER, 2, true)
			if device_texture != null: draw_texture_rect(device_texture, Rect2(point - Vector2(42, 67), Vector2(84, 68)), false)
			draw_string(get_theme_default_font(), point + Vector2(-130, -79), door.label, HORIZONTAL_ALIGNMENT_CENTER, 260, 16, Tokens.TEXT)
			continue
		if point == Layout.WEST or point == Layout.EAST:
			draw_rect(Rect2(point - Vector2(17, 56), Vector2(34, 112)), Tokens.BASE)
			draw_rect(Rect2(point - Vector2(17, 56), Vector2(34, 112)), Tokens.AMBER, false, 2)
			# Keep side-door destination text inside the room rather than the wall.
			var label_origin: Vector2 = point + Vector2(22 if point == Layout.WEST else -222, -70)
			draw_rect(Rect2(label_origin - Vector2(0, 20), Vector2(200, 28)), Tokens.PANEL)
			draw_string(get_theme_default_font(), label_origin, door.label, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Tokens.TEXT)
			continue
		draw_rect(Rect2(point - Vector2(56, 17), Vector2(112, 34)), Tokens.BASE)
		draw_rect(Rect2(point - Vector2(56, 17), Vector2(112, 34)), Tokens.AMBER, false, 2)
		for offset: int in [-9, 0, 9]:
			draw_line(point + Vector2(-44, offset), point + Vector2(44, offset), Tokens.BORDER_STRONG, 2)
		# Keep the longer gate requirement beside the north doorway, clear of the
		# traveller's head when its feet have reached the interaction point.
		var caption_offset: float = -280.0 if point == Layout.NORTH and door.get("refusal", "") != "" else -100.0
		draw_string(get_theme_default_font(), point + Vector2(caption_offset, -25), door.label, HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Tokens.TEXT)
	if target_position.x >= 0:
		draw_arc(target_position, 12, 0, TAU, 24, Tokens.AMBER, 2, true)
	var pose: Dictionary = Poses.frame("drifter", current_pose)
	if not pose.is_empty():
		var texture: Texture2D = pose.texture
		var draw_size: Vector2 = texture.get_size() * (76.0 / float(pose.reference_height))
		var foot: Vector2 = pose.foot * draw_size
		draw_set_transform(actor_canvas_position(), 0, (Vector2(-1, 1) if facing_left else Vector2.ONE) * zoom)
		draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.3))
		draw_texture_rect(texture, Rect2(-foot, draw_size), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_enemy() -> void:
	var pose: Dictionary = enemy_pose
	var texture: Texture2D
	var anchor: Vector2
	var height: float = 76.0
	if not pose.is_empty():
		texture = pose.texture
		anchor = pose.foot
		height = float(pose.reference_height)
	else:
		var profile: Dictionary = Stage.VISUAL_PROFILES[enemy_id]
		texture = enemy_texture
		anchor = profile.foot_anchor_uv
		if texture != null: height = texture.get_height()
	if texture != null:
		var draw_size: Vector2 = texture.get_size() * (76.0 / height)
		draw_circle(ENEMY_POINT, 17, Color(0, 0, 0, 0.35))
		draw_texture_rect(texture, Rect2(ENEMY_POINT - anchor * draw_size, draw_size), false)
	draw_arc(ENEMY_POINT, 24, 0, TAU, 32, Tokens.CRITICAL, 2, true)
	var caption: Vector2 = ENEMY_POINT + Vector2(-100, -102)
	draw_rect(Rect2(caption - Vector2(0, 20), Vector2(200, 28)), Tokens.PANEL)
	draw_string(get_theme_default_font(), caption, "迎戰 " + Enemies.display_name(enemy_id), HORIZONTAL_ALIGNMENT_CENTER, 200, 16, Tokens.TEXT)
