class_name WorldMapView
extends Control

# ==============================================================================
# SURVIVOR PDA - WORLD MAP VIEW (CANVASITEM _DRAW)
# ==============================================================================
# Renders the authoritative tactical sector map using CanvasItem 2D drawing.
# Conforms to wc-survivor-pda-design-system specifications:
#   1. WorldMapPanel: Custom Control + _draw() (no simple button stacks).
#   2. SettlementNode: Distinct states (Current, Reachable, Selected, Remote).
#   3. RouteLine: Tactical connecting lines with distance markers.
#   4. PlayerMapMarker: Distinct marker for Settled vs In-Transit along route.
# ==============================================================================

signal node_selected(settlement_id: String)

# Node normalized positions (relative to panel bounds)
const NODE_POSITIONS := {
	"settlement:gray_valley": Vector2(0.26, 0.42),
	"settlement:dry_well": Vector2(0.62, 0.36),
	"settlement:new_hope": Vector2(0.76, 0.75)
}

const ROUTES := [
	{
		"from": "settlement:gray_valley",
		"to": "settlement:dry_well",
		"days": 2,
		"label": "2d"
	},
	{
		"from": "settlement:gray_valley",
		"to": "settlement:new_hope",
		"days": 3,
		"label": "舊公路 (3d)"
	},
	{
		"from": "settlement:dry_well",
		"to": "settlement:new_hope",
		"days": 2,
		"label": "2d"
	}
]

var destinations: Array = []
var player_info: Dictionary = {}
var selected_settlement_id: String = "settlement:gray_valley"
var hovered_settlement_id: String = ""

func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 320)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

func update_map_data(p_destinations: Array, p_player: Dictionary, p_selected_id: String) -> void:
	destinations = p_destinations
	player_info = p_player
	selected_settlement_id = p_selected_id
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_id := _get_node_at_position(event.position)
		if clicked_id != "":
			selected_settlement_id = clicked_id
			node_selected.emit(clicked_id)
			queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		var hovered := _get_node_at_position(event.position)
		if hovered != hovered_settlement_id:
			hovered_settlement_id = hovered
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hovered != "" else Control.CURSOR_ARROW
			queue_redraw()

func _get_node_at_position(pos: Vector2) -> String:
	for node_id in NODE_POSITIONS:
		var node_pos := _get_pixel_pos(NODE_POSITIONS[node_id])
		if pos.distance_to(node_pos) <= 26.0:
			return node_id
	return ""

func _get_pixel_pos(norm: Vector2) -> Vector2:
	var pad := 32.0
	var w := size.x - (pad * 2.0)
	var h := size.y - (pad * 2.0)
	return Vector2(pad + norm.x * w, pad + norm.y * h)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10 or h < 10:
		return

	# 1. Base Substrate & Grid (#121316 base, #181A1F grid)
	draw_rect(Rect2(0, 0, w, h), Color("#121316"))

	var grid_step := 32.0
	var grid_color := Color("#191B20")
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, 0), Vector2(x, h), grid_color, 1.0)
		x += grid_step
	var y := 0.0
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), grid_color, 1.0)
		y += grid_step

	# Tactical Outer Frame & Compass Rose (Top Left)
	draw_rect(Rect2(0, 0, w, h), Color("#2A2D35"), false, 1.0)
	_draw_compass(Vector2(40, 40))

	# Tactical Subtitle
	var default_font := ThemeDB.fallback_font
	draw_string(default_font, Vector2(16, h - 14), "SECTOR TACTICAL MAP — S5 EXPLORATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#686A70"))

	# 2. Draw Routes (Roads)
	for r_variant in ROUTES:
		var route: Dictionary = r_variant
		var p1 := _get_pixel_pos(NODE_POSITIONS[route["from"]])
		var p2 := _get_pixel_pos(NODE_POSITIONS[route["to"]])

		var is_route_active: bool = false
		if player_info.get("is_in_transit", false):
			var cur_cont: String = player_info.get("current_container_id", "")
			if cur_cont.contains(route["from"]) and cur_cont.contains(route["to"]):
				is_route_active = true

		# Road casing
		draw_line(p1, p2, Color("#15171C"), 5.0)
		# Road core line
		var line_color := Color("#D9822B") if is_route_active else Color("#3A3F4B")
		draw_line(p1, p2, line_color, 2.0)

		# Route label at midpoint
		var mid := (p1 + p2) * 0.5
		var label_text: String = route["label"]
		var label_size := default_font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		var badge_rect := Rect2(mid.x - (label_size.x * 0.5) - 4, mid.y - 14, label_size.x + 8, 16)
		draw_rect(badge_rect, Color("#181A1F"))
		draw_rect(badge_rect, Color("#2A2D35"), false, 1.0)
		draw_string(default_font, Vector2(mid.x - (label_size.x * 0.5), mid.y - 2), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#96938B"))

	# 3. Draw Settlement Nodes
	var cur_cont_id: String = player_info.get("current_container_id", "")
	var is_in_transit: bool = player_info.get("is_in_transit", false)

	for node_key in NODE_POSITIONS:
		var node_id := String(node_key)
		var node_pos := _get_pixel_pos(NODE_POSITIONS[node_id])
		var is_selected: bool = (node_id == selected_settlement_id)
		var is_here: bool = (node_id == cur_cont_id and not is_in_transit)
		var is_hovered: bool = (node_id == hovered_settlement_id)

		# Outer highlight ring if selected or hovered
		if is_selected:
			draw_arc(node_pos, 18.0, 0, TAU, 32, Color("#D9822B"), 2.0)
		elif is_hovered:
			draw_arc(node_pos, 16.0, 0, TAU, 24, Color("#454A55"), 1.5)

		# Main node circle
		var base_border := Color("#39D353") if is_here else (Color("#D9822B") if is_selected else Color("#D8D3C8"))
		var base_fill := Color("#18261E") if is_here else Color("#1B1D22")
		draw_circle(node_pos, 11.0, base_fill)
		draw_arc(node_pos, 11.0, 0, TAU, 24, base_border, 2.0)
		draw_circle(node_pos, 4.0, base_border)

		# Node Name & Status Tag
		var clean_name: String = node_id.replace("settlement:", "").replace("_", " ").capitalize()
		var name_str := clean_name
		if is_here:
			name_str += " [LIVE]"
		var name_color := Color("#39D353") if is_here else (Color("#D9822B") if is_selected else Color("#D8D3C8"))
		var n_size := default_font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		draw_string(default_font, Vector2(node_pos.x - (n_size.x * 0.5), node_pos.y + 24), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, name_color)

	# 4. Draw Player Marker (Settled vs In-Transit)
	if is_in_transit:
		_draw_in_transit_marker(default_font)
	else:
		_draw_settled_marker(default_font, cur_cont_id)

func _draw_settled_marker(font: Font, node_id: String) -> void:
	if not NODE_POSITIONS.has(node_id):
		return
	var node_pos := _get_pixel_pos(NODE_POSITIONS[node_id])
	var marker_pos := Vector2(node_pos.x, node_pos.y - 20)

	# Cyan diamond marker
	var pts := PackedVector2Array([
		marker_pos + Vector2(0, -6),
		marker_pos + Vector2(6, 0),
		marker_pos + Vector2(0, 6),
		marker_pos + Vector2(-6, 0)
	])
	draw_colored_polygon(pts, Color("#58A6FF"))
	draw_polyline(pts, Color("#D8D3C8"), 1.0)

	var label_str := "YOU (HERE)"
	var l_size := font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	draw_string(font, Vector2(marker_pos.x - (l_size.x * 0.5), marker_pos.y - 8), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#58A6FF"))

func _draw_in_transit_marker(font: Font) -> void:
	var route_key: String = player_info.get("current_container_id", "")
	var days_rem: int = player_info.get("days_remaining", 1)

	# Find active route matching container
	var active_route: Dictionary = {}
	for r in ROUTES:
		if route_key.contains(r["from"]) and route_key.contains(r["to"]):
			active_route = r
			break

	var marker_pos := Vector2(size.x * 0.5, size.y * 0.5)
	if active_route.size() > 0:
		var p_from := _get_pixel_pos(NODE_POSITIONS[active_route["from"]])
		var p_to := _get_pixel_pos(NODE_POSITIONS[active_route["to"]])
		var total_days: float = float(active_route.get("days", 3))
		var progress: float = clampf(1.0 - (float(days_rem) / total_days), 0.15, 0.85)
		marker_pos = p_from.lerp(p_to, progress)

	# Moving caravan marker (amber-cyan vehicle wedge)
	var pts := PackedVector2Array([
		marker_pos + Vector2(0, -7),
		marker_pos + Vector2(7, 4),
		marker_pos + Vector2(-7, 4)
	])
	draw_colored_polygon(pts, Color("#58A6FF"))
	draw_polyline(pts, Color("#D8D3C8"), 1.5)

	var label_str := "YOU (IN TRANSIT - %dd)" % days_rem
	var l_size := font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	draw_string(font, Vector2(marker_pos.x - (l_size.x * 0.5), marker_pos.y - 10), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#58A6FF"))

func _draw_compass(pos: Vector2) -> void:
	var r := 16.0
	draw_arc(pos, r, 0, TAU, 16, Color("#2A2D35"), 1.0)
	draw_line(pos + Vector2(0, -r - 4), pos + Vector2(0, r + 4), Color("#454A55"), 1.0)
	draw_line(pos + Vector2(-r - 4, 0), pos + Vector2(r + 4, 0), Color("#454A55"), 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(-3, -r - 5), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color("#96938B"))
