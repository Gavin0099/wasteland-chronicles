extends Node2D

# Presentation-only 2:1 projection. No cells, movement, hitboxes or world state.
# The existing painted environment supplies ground texture; its cropped terrain
# is mapped onto a raised diamond, with an opaque front edge and a quiet grid.
var surface := Polygon2D.new()
var right_edge := Polygon2D.new()
var left_edge := Polygon2D.new()
var center := Vector2.ZERO
var span := 400.0
var depth := 12.0
var environment := "shed"
var corners := PackedVector2Array()

func _init() -> void:
	add_child(left_edge)
	add_child(right_edge)
	add_child(surface)
	surface.show_behind_parent = true
	left_edge.show_behind_parent = true
	right_edge.show_behind_parent = true

func project(point: Vector2) -> Vector2:
	return center + Vector2((point.x - point.y) * span / 4.0, (point.x + point.y) * span / 8.0)

func configure(canvas_size: Vector2, terrain: Texture2D, id: String) -> void:
	environment = id
	span = minf(canvas_size.x * 0.94, canvas_size.y * 1.80)
	center = Vector2(canvas_size.x * 0.5, canvas_size.y * 0.50)
	depth = maxf(8.0, canvas_size.y * 0.035)
	corners = PackedVector2Array([project(Vector2(-1, -1)), project(Vector2(1, -1)), project(Vector2(1, 1)), project(Vector2(-1, 1))])
	surface.polygon = corners
	surface.texture = terrain
	surface.color = Color(0.86, 0.81, 0.70) if terrain != null else Color(0.40, 0.33, 0.25)
	if terrain != null:
		var pixels := Vector2(terrain.get_width(), terrain.get_height())
		surface.uv = PackedVector2Array([pixels * Vector2(0.30, 0.66), pixels * Vector2(0.70, 0.66), pixels * Vector2(0.70, 0.94), pixels * Vector2(0.30, 0.94)])
	var down := Vector2(0, depth)
	right_edge.polygon = PackedVector2Array([corners[1], corners[2], corners[2] + down, corners[1] + down])
	left_edge.polygon = PackedVector2Array([corners[2], corners[3], corners[3] + down, corners[2] + down])
	right_edge.color = Color(0.16, 0.13, 0.10)
	left_edge.color = Color(0.24, 0.20, 0.15)
	queue_redraw()

func _draw() -> void:
	if corners.size() != 4:
		return
	# A fixed visual grid evokes the reference floor; it has no tactical meaning.
	var grid := Color(0.13, 0.11, 0.08, 0.22)
	for index in range(1, 8):
		var step := -1.0 + float(index) / 4.0
		draw_line(project(Vector2(step, -1)), project(Vector2(step, 1)), grid, 1.0, true)
		draw_line(project(Vector2(-1, step)), project(Vector2(1, step)), grid, 1.0, true)
	var border := PackedVector2Array(corners)
	border.append(corners[0])
	draw_polyline(border, Color(0.61, 0.53, 0.39, 0.68), 1.5, true)
