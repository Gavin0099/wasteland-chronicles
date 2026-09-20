class_name WorldMapView
extends Control

# ==============================================================================
# SURVIVOR PDA - WORLD MAP VIEW (CANVASITEM _DRAW) — UX-P1
# ==============================================================================
# Resolves Label Collisions & Decouples 3 Locations:
#   1. CURRENT LOCATION (綠環 ● 目前位置)
#   2. TRAVEL TARGET (琥珀雙環 ◎ 目的地)
#   3. SELECTED INSPECTION (象牙白環 ○ 查看中)
#   4. Strict Fixed Offsets: Name ABOVE node, Status BELOW node.
#   5. All labels have solid translucent backplates with 1px borders.
# ==============================================================================

signal node_selected(settlement_id: String)

const SETTLEMENT_NAMES := {
	"settlement:gray_valley": {"zh": "灰谷", "en": "Gray Valley"},
	"settlement:dry_well": {"zh": "乾井", "en": "Dry Well"},
	"settlement:new_hope": {"zh": "新希望", "en": "New Hope"}
}

# Aligned with wasteland sector illustration landmarks
const NODE_POSITIONS := {
	"settlement:gray_valley": Vector2(0.28, 0.28),
	"settlement:dry_well": Vector2(0.68, 0.36),
	"settlement:new_hope": Vector2(0.86, 0.69)
}

const ROUTES := [
	{
		"from": "settlement:gray_valley",
		"to": "settlement:dry_well",
		"days": 2,
		"label": "2 天"
	},
	{
		"from": "settlement:gray_valley",
		"to": "settlement:new_hope",
		"days": 3,
		"label": "舊公路 (3 天)"
	},
	{
		"from": "settlement:dry_well",
		"to": "settlement:new_hope",
		"days": 2,
		"label": "2 天"
	}
]

var map_texture: Texture2D = null

var destinations: Array = []
var player_info: Dictionary = {}
var selected_settlement_id: String = "settlement:gray_valley"
var hovered_settlement_id: String = ""

func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 320)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_load_map_texture()

func _load_map_texture() -> void:
	var path := "res://ui/assets/wasteland_map_bg.jpg"
	var global_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		var img := Image.load_from_file(global_path)
		if img != null:
			map_texture = ImageTexture.create_from_image(img)

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
		if pos.distance_to(node_pos) <= 28.0:
			return node_id
	return ""

func _get_pixel_pos(norm: Vector2) -> Vector2:
	var pad := 36.0
	var w := size.x - (pad * 2.0)
	var h := size.y - (pad * 2.0)
	return Vector2(pad + norm.x * w, pad + norm.y * h)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 10 or h < 10:
		return

	# 1. Base Wasteland Map Artwork
	if map_texture != null:
		draw_texture_rect(map_texture, Rect2(0, 0, w, h), false)
		# Vignette overlay for visual contrast
		draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.05, 0.07, 0.18))
	else:
		draw_rect(Rect2(0, 0, w, h), Color("#121316"))

	# Tactical Outer Frame
	draw_rect(Rect2(0, 0, w, h), Color("#2A2D35"), false, 1.0)

	var default_font := ThemeDB.fallback_font

	# 2. Location Decoupling Variables
	var is_in_transit: bool = player_info.get("is_in_transit", false)
	var cur_loc_id: String = ""
	var dest_loc_id: String = ""
	if is_in_transit:
		cur_loc_id = player_info.get("origin_id", "")
		dest_loc_id = player_info.get("destination_id", "")
	else:
		cur_loc_id = player_info.get("current_container_id", "")

	# 3. Draw Routes (Roads)
	for r_variant in ROUTES:
		var route: Dictionary = r_variant
		var p1 := _get_pixel_pos(NODE_POSITIONS[route["from"]])
		var p2 := _get_pixel_pos(NODE_POSITIONS[route["to"]])

		var is_active_route := false
		if is_in_transit and dest_loc_id != "":
			if (cur_loc_id == route["from"] and dest_loc_id == route["to"]) or (cur_loc_id == route["to"] and dest_loc_id == route["from"]):
				is_active_route = true

		# Road casing
		draw_line(p1, p2, Color(0.08, 0.09, 0.11, 0.9), 6.0)

		# Road line
		if is_active_route:
			# High-contrast amber road
			draw_line(p1, p2, Color("#D9822B"), 3.0)
		else:
			# Non-target routes: de-emphasized
			draw_line(p1, p2, Color(0.55, 0.58, 0.65, 0.7), 2.0)

		# Route label at midpoint (Distance pill)
		var mid := (p1 + p2) * 0.5
		var label_text: String = route["label"]
		var label_size := default_font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		var badge_rect := Rect2(mid.x - (label_size.x * 0.5) - 6, mid.y - 10, label_size.x + 12, 18)
		draw_rect(badge_rect, Color(0.08, 0.09, 0.12, 0.92))
		draw_rect(badge_rect, Color("#363D4E"), false, 1.0)
		draw_string(default_font, Vector2(mid.x - (label_size.x * 0.5), mid.y + 3), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#C4BFB6"))

	# 4. Draw Settlement Nodes
	for node_key in NODE_POSITIONS:
		var node_id := String(node_key)
		var node_pos := _get_pixel_pos(NODE_POSITIONS[node_id])

		var is_here: bool = (node_id == cur_loc_id and not is_in_transit)
		var is_destination: bool = (node_id == dest_loc_id and is_in_transit)
		var is_selected: bool = (node_id == selected_settlement_id)
		var is_hovered: bool = (node_id == hovered_settlement_id)

		# --- A. Node Rings ---
		if is_here:
			# ● Current Location: Vibrant Green Ring
			draw_circle(node_pos, 13.0, Color(0.09, 0.15, 0.11, 0.95))
			draw_arc(node_pos, 13.0, 0, TAU, 28, Color("#39D353"), 2.5)
			draw_circle(node_pos, 5.0, Color("#39D353"))
		elif is_destination:
			# ◎ Destination: Amber Double-Ring
			draw_circle(node_pos, 15.0, Color(0.18, 0.12, 0.08, 0.95))
			draw_arc(node_pos, 15.0, 0, TAU, 32, Color("#D9822B"), 2.0)
			draw_arc(node_pos, 10.0, 0, TAU, 24, Color("#D9822B"), 1.5)
			draw_circle(node_pos, 4.0, Color("#D9822B"))
		elif is_selected:
			# ○ Selected / Inspected: Ivory Outer Ring
			draw_circle(node_pos, 12.0, Color(0.12, 0.13, 0.16, 0.95))
			draw_arc(node_pos, 14.0, 0, TAU, 28, Color("#D8D3C8"), 2.0)
			draw_circle(node_pos, 4.0, Color("#D8D3C8"))
		else:
			# Normal Node
			draw_circle(node_pos, 10.0, Color(0.10, 0.11, 0.14, 0.9))
			draw_arc(node_pos, 10.0, 0, TAU, 20, Color("#6C7280"), 1.5)
			draw_circle(node_pos, 3.0, Color("#8B949E"))

		if is_hovered and not is_selected:
			draw_arc(node_pos, 17.0, 0, TAU, 28, Color("#8B949E"), 1.0)

		# --- B. Node Name (Fixed ABOVE node: node_pos.y - 28) ---
		var names: Dictionary = SETTLEMENT_NAMES.get(node_id, {"zh": node_id, "en": ""})
		var zh_name: String = names["zh"]
		var en_name: String = names["en"]
		var display_title := "%s %s" % [zh_name, en_name] if en_name != "" else zh_name

		var n_size := default_font.get_string_size(display_title, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		var name_rect := Rect2(node_pos.x - (n_size.x * 0.5) - 6, node_pos.y - 32, n_size.x + 12, 18)
		draw_rect(name_rect, Color(0.08, 0.09, 0.12, 0.92))
		var border_color := Color("#39D353") if is_here else (Color("#D9822B") if is_destination else (Color("#D8D3C8") if is_selected else Color("#363D4E")))
		draw_rect(name_rect, border_color, false, 1.0)
		draw_string(default_font, Vector2(node_pos.x - (n_size.x * 0.5), node_pos.y - 18), display_title, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color("#F0ECE1"))

		# --- C. Status Badge (Fixed BELOW node: node_pos.y + 14) ---
		var status_tag := ""
		var tag_color := Color("#8B949E")
		if is_here:
			status_tag = "目前位置"
			tag_color = Color("#39D353")
		elif is_destination:
			status_tag = "目的地"
			tag_color = Color("#D9822B")
		elif is_selected:
			status_tag = "查看中"
			tag_color = Color("#D8D3C8")

		if status_tag != "":
			var s_size := default_font.get_string_size(status_tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
			var status_rect := Rect2(node_pos.x - (s_size.x * 0.5) - 5, node_pos.y + 14, s_size.x + 10, 16)
			draw_rect(status_rect, Color(0.08, 0.09, 0.12, 0.92))
			draw_rect(status_rect, tag_color, false, 1.0)
			draw_string(default_font, Vector2(node_pos.x - (s_size.x * 0.5), node_pos.y + 26), status_tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, tag_color)

	# 5. In-Transit Player Marker (Clear Vehicle Wedge + Progress Badge)
	if is_in_transit and cur_loc_id != "" and dest_loc_id != "":
		_draw_in_transit_player(default_font, cur_loc_id, dest_loc_id)

func _draw_in_transit_player(font: Font, origin_id: String, destination_id: String) -> void:
	if not NODE_POSITIONS.has(origin_id) or not NODE_POSITIONS.has(destination_id):
		return

	var p_from := _get_pixel_pos(NODE_POSITIONS[origin_id])
	var p_to := _get_pixel_pos(NODE_POSITIONS[destination_id])

	var total_days: float = float(player_info.get("total_route_days", 3))
	var days_rem: float = float(player_info.get("days_remaining", 1))
	var current_step := int(round(total_days - days_rem + 1.0))
	var progress := clampf(1.0 - (days_rem / maxf(total_days, 1.0)), 0.18, 0.82)

	var marker_pos := p_from.lerp(p_to, progress)

	# Cyan Vehicle Wedge Marker
	var pts := PackedVector2Array([
		marker_pos + Vector2(0, -7),
		marker_pos + Vector2(7, 5),
		marker_pos + Vector2(-7, 5)
	])
	draw_colored_polygon(pts, Color("#58A6FF"))
	draw_polyline(pts, Color("#F0ECE1"), 1.5)

	# Neat Player Progress Badge
	var label_str := "你 (第 %d/%d 天)" % [current_step, int(total_days)]
	var l_size := font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	var badge_rect := Rect2(marker_pos.x - (l_size.x * 0.5) - 6, marker_pos.y - 25, l_size.x + 12, 17)
	draw_rect(badge_rect, Color(0.06, 0.10, 0.16, 0.95))
	draw_rect(badge_rect, Color("#58A6FF"), false, 1.0)
	draw_string(font, Vector2(marker_pos.x - (l_size.x * 0.5), marker_pos.y - 12), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#58A6FF"))
