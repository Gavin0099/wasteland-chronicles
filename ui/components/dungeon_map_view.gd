extends Control

const Dungeon = preload("res://simulation/dungeon_exploration.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const POINTS: Dictionary = {"entrance": Vector2(90, 270), "foyer": Vector2(230, 190), "parts_store": Vector2(90, 120), "guard": Vector2(370, 75), "maintenance": Vector2(390, 270), "pump": Vector2(505, 170), "control": Vector2(590, 60), "polluted_store": Vector2(590, 285)}
var projected: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(680, 330)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

static func project(checkpoint: Dictionary) -> Dictionary:
	var rooms: Dictionary = {}
	var edges: Array[Array] = []
	var locked: Array[Array] = []
	for room: String in checkpoint.visited:
		rooms[room] = {"label": Dungeon.ROOMS[room], "visited": true, "current": checkpoint.active and checkpoint.room_id == room}
	for room: String in checkpoint.visited:
		for neighbour: String in Dungeon.PASSAGES[room]:
			if not rooms.has(neighbour): rooms[neighbour] = {"label": "未探索", "visited": false, "current": false}
			if room < neighbour or neighbour not in checkpoint.visited:
				edges.append([room, neighbour])
				if Dungeon.passage_refusal(room, neighbour, int(checkpoint.get("route_rules", 0)), checkpoint.get("cleared", []), checkpoint.get("maintenance_open", false), int(checkpoint.get("deep_rules", 0)), checkpoint.get("has_mask", false)) != "": locked.append([room, neighbour])
	if checkpoint.shortcut_open:
		edges.append(["control", "entrance"])
	return {"rooms": rooms, "edges": edges, "shortcut_open": checkpoint.shortcut_open, "locked": locked}

func setup(checkpoint: Dictionary) -> void:
	projected = project(checkpoint)
	queue_redraw()

func _draw() -> void:
	if projected.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.BASE)
	var scale_value: float = minf(size.x / 680.0, size.y / 330.0)
	draw_set_transform((size - Vector2(680, 330) * scale_value) * 0.5, 0, Vector2.ONE * scale_value)
	for edge: Array in projected.edges:
		var shortcut: bool = edge[0] == "control" and edge[1] == "entrance"
		if shortcut:
			# Route the separate return passage around ordinary room nodes.
			var line: PackedVector2Array = PackedVector2Array([POINTS.entrance, Vector2(20, 270), Vector2(20, 30), Vector2(590, 30), POINTS.control])
			draw_polyline(line, Tokens.AMBER, 3, true)
			draw_string(get_theme_default_font(), Vector2(230, 24), "已開啟的返回捷徑", HORIZONTAL_ALIGNMENT_CENTER, 240, Tokens.SMALL, Tokens.TEXT)
		else:
			draw_line(POINTS[edge[0]], POINTS[edge[1]], Tokens.CRITICAL if edge in projected.locked else Tokens.BORDER_STRONG, 2, true)
	for room: String in projected.rooms:
		var entry: Dictionary = projected.rooms[room]
		var point: Vector2 = POINTS[room]
		var bounds: Rect2 = Rect2(point - Vector2(62, 20), Vector2(124, 40))
		draw_rect(bounds, Tokens.ELEVATED if entry.visited else Tokens.PANEL)
		draw_rect(bounds, Tokens.AMBER if entry.current else Tokens.BORDER_STRONG, false, 2 if entry.current else 1)
		draw_string(get_theme_default_font(), point + Vector2(-60, 6), ("● " if entry.current else "") + entry.label, HORIZONTAL_ALIGNMENT_CENTER, 120, Tokens.BODY, Tokens.TEXT)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
