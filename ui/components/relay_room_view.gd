extends "res://ui/components/dungeon_room_view.gd"

const Relay = preload("res://simulation/relay_exploration.gd")
const POINTS: Dictionary = {
	"relay_entrance": {"relay_corridor": Vector2(500, 116), "relay_tunnel": Vector2(888, 266)},
	"relay_corridor": {"relay_entrance": Vector2(500, 416), "relay_records": Vector2(500, 116)},
	"relay_tunnel": {"relay_entrance": Vector2(112, 266), "relay_records": Vector2(500, 116)},
	"relay_records": {"relay_corridor": Vector2(500, 416), "relay_tunnel": Vector2(112, 266), "relay_vault": Vector2(888, 266)},
	"relay_vault": {"relay_records": Vector2(112, 266)}
}
var checkpoint: Dictionary = {}

func _init() -> void:
	super()
	floor_texture = Poses.load_atlas("res://ui/assets/combat/buried-relay.png")
	tool_texture = Icon.texture_for(Relay.PRIZE)

func setup(s: Dictionary) -> void:
	checkpoint = s.duplicate(true)
	room_id = s.room_id
	target_position = Vector2(-1, -1)
	guide_path.clear()
	animation_time = 0.0
	walking = false
	current_pose = "recover"
	doors.clear()
	for target: String in POINTS[room_id]:
		if target == "relay_tunnel" and not s.tunnel_found: continue
		doors.append({"command": "MOVE", "room_id": target, "point": POINTS[room_id][target], "label": Relay.ROOMS[target], "refusal": Relay.gate(room_id, target, s)})
	if room_id == "relay_entrance":
		doors.append({"command": "EXIT", "label": "樓梯 · 返回灰谷", "point": Layout.SOUTH})
		if not s.tunnel_found: doors.append({"command": "SEARCH", "label": "查看牆邊的拖痕", "point": Vector2(650, 266)})
	if room_id == "relay_tunnel" and not s.tunnel_open: doors.append({"command": "OPEN_TUNNEL", "label": "撬開內門 · 工具＋2廢料", "point": Vector2(650, 266)})
	if room_id == "relay_records" and not s.card_found: doors.append({"command": "FIND_CARD", "label": "檢查值勤文件 · 取門禁卡", "point": Vector2(650, 266)})
	if room_id == "relay_vault" and not s.prize_taken: doors.append({"command": "TAKE_PRIZE", "label": "取軍用背包 · 2.4kg", "point": Vector2(650, 266)})
	enemy_id = "feral_dog" if room_id == "relay_corridor" and room_id not in s.cleared else ""
	enemy_pose = Poses.frame(enemy_id, "recover")
	if enemy_id != "": doors.append({"command": "FIGHT", "label": "迎戰守路野犬", "point": ENEMY_POINT})
	actor_position = Layout.arrival(doors, s.from_room_id)
	obstacles = [Rect2(200, 170, 150, 70), Rect2(710, 330, 110, 60)]
	queue_redraw()
	interaction_changed.emit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.BASE)
	var zoom: float = canvas_scale()
	if zoom <= 0: return
	draw_set_transform(canvas_origin(), 0, Vector2.ONE * zoom)
	var room: Rect2 = Rect2(64, 40, 872, 424)
	if floor_texture != null: draw_texture_rect(floor_texture, room, false)
	draw_rect(room, Tokens.BORDER_STRONG, false, 2)
	for obstacle: Rect2 in obstacles:
		if crate_texture != null: draw_texture_rect(crate_texture, obstacle, false)
	for door: Dictionary in doors:
		var point: Vector2 = door.point
		if door.command == "FIGHT":
			_draw_enemy()
			continue
		var marker: Rect2 = Rect2(point - Vector2(30, 15), Vector2(60, 30))
		draw_rect(marker, Tokens.PANEL)
		draw_rect(marker, Tokens.AMBER, false, 2)
		if door.command == "TAKE_PRIZE" and tool_texture != null: draw_texture_rect(tool_texture, Rect2(point - Vector2(26, 66), Vector2(52, 52)), false)
		var caption: Vector2 = point + Vector2(-120, -25)
		if point == Layout.WEST: caption.x = point.x + 20
		if point == Layout.EAST: caption.x = point.x - 260
		draw_rect(Rect2(caption - Vector2(0, 20), Vector2(240, 27)), Tokens.PANEL)
		draw_string(get_theme_default_font(), caption, door.label, HORIZONTAL_ALIGNMENT_CENTER, 240, 16, Tokens.TEXT)
	if target_position.x >= 0: draw_arc(target_position, 12, 0, TAU, 24, Tokens.AMBER, 2, true)
	var pose: Dictionary = Poses.frame("drifter", current_pose)
	if not pose.is_empty():
		var texture: Texture2D = pose.texture
		var draw_size: Vector2 = texture.get_size() * (76.0 / float(pose.reference_height))
		draw_set_transform(actor_canvas_position(), 0, (Vector2(-1, 1) if facing_left else Vector2.ONE) * zoom)
		draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.3))
		draw_texture_rect(texture, Rect2(-pose.foot * draw_size, draw_size), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
