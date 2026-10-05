extends Control

# Code-drawn stand-in art for the three MIN-1 rooms. It draws only what the world
# state says: observed facts are marked, nothing here decides a rule. Colors come
# from the shared PDA tokens; no external image is used or implied.
const Tokens = preload("res://ui/theme/pda_tokens.gd")
var room_id: String = "mine_entrance"
var observed: Array = []

func setup(p_room_id: String, p_observed: Array) -> void:
	room_id = p_room_id
	observed = p_observed.duplicate()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: queue_redraw()

func _p(x: float, y: float) -> Vector2:
	return Vector2(size.x * x, size.y * y)

func _poly(points: Array, color: Color) -> void:
	var out: PackedVector2Array = PackedVector2Array()
	for point: Array in points: out.append(_p(point[0], point[1]))
	draw_colored_polygon(out, color)

func _line(a: Array, b: Array, color: Color, width: float = 2.0) -> void:
	draw_line(_p(a[0], a[1]), _p(b[0], b[1]), color, width)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.BASE)
	match room_id:
		"mine_entrance": _draw_entrance()
		"mine_gallery": _draw_gallery()
		"mine_pumphall": _draw_pumphall()
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.BORDER_STRONG, false, 1.0)

func _floor_and_rock(horizon: float) -> void:
	_poly([[0.0, 0.0], [1.0, 0.0], [1.0, horizon], [0.0, horizon]], Tokens.PANEL)
	_poly([[0.0, horizon], [1.0, horizon], [1.0, 1.0], [0.0, 1.0]], Tokens.ELEVATED)
	_line([0.0, horizon], [1.0, horizon], Tokens.BORDER, 1.0)

func _draw_entrance() -> void:
	_floor_and_rock(0.78)
	# Mine mouth: dark arch in the rock face with a timber frame.
	_poly([[0.30, 0.78], [0.30, 0.34], [0.38, 0.20], [0.62, 0.20], [0.70, 0.34], [0.70, 0.78]], Tokens.BASE)
	_line([0.30, 0.78], [0.30, 0.34], Tokens.BORDER_STRONG, 6.0)
	_line([0.70, 0.78], [0.70, 0.34], Tokens.BORDER_STRONG, 6.0)
	_line([0.28, 0.34], [0.72, 0.34], Tokens.BORDER_STRONG, 7.0)
	# Rails run into the dark.
	_line([0.44, 1.0], [0.48, 0.62], Tokens.SECONDARY, 2.0)
	_line([0.56, 1.0], [0.52, 0.62], Tokens.SECONDARY, 2.0)
	for t: int in range(5):
		var y: float = 0.95 - float(t) * 0.07
		_line([0.45 - 0.01 * t, y], [0.55 + 0.01 * t, y], Tokens.DIM, 2.0)
	# Rock fall on the right of the mouth.
	_poly([[0.72, 0.78], [0.78, 0.66], [0.86, 0.70], [0.92, 0.78]], Tokens.BORDER_STRONG)
	_poly([[0.80, 0.78], [0.84, 0.70], [0.90, 0.74], [0.94, 0.78]], Tokens.BORDER)
	# A hung lantern, unlit.
	draw_circle(_p(0.22, 0.42), 5.0, Tokens.DIM)
	_line([0.22, 0.30], [0.22, 0.40], Tokens.DIM, 1.5)

func _draw_gallery() -> void:
	_floor_and_rock(0.74)
	# Tunnel receding to a vanishing point.
	_poly([[0.0, 0.0], [0.30, 0.30], [0.30, 0.66], [0.0, 0.92]], Tokens.PANEL)
	_poly([[1.0, 0.0], [0.70, 0.30], [0.70, 0.66], [1.0, 0.92]], Tokens.PANEL)
	_poly([[0.30, 0.30], [0.70, 0.30], [0.70, 0.66], [0.30, 0.66]], Tokens.BASE)
	_line([0.0, 0.0], [0.30, 0.30], Tokens.BORDER, 1.0)
	_line([1.0, 0.0], [0.70, 0.30], Tokens.BORDER, 1.0)
	_line([0.0, 0.92], [0.30, 0.66], Tokens.BORDER, 1.0)
	_line([1.0, 0.92], [0.70, 0.66], Tokens.BORDER, 1.0)
	# Props: three timber supports, the middle one splintered.
	for index: int in range(3):
		var depth: float = 0.12 + 0.09 * float(index)
		var left: float = 0.30 - depth
		var right: float = 0.70 + depth
		var top: float = 0.30 - depth * 0.9
		var bottom: float = 0.66 + depth * 0.8
		var color: Color = Tokens.BORDER_STRONG
		_line([left, top], [left, bottom], color, 5.0 - float(index))
		_line([right, top], [right, bottom], color, 5.0 - float(index))
		_line([left, top], [right, top], color, 5.0 - float(index))
	# The cracks: always faintly visible, picked out in amber once the player has looked.
	var crack: Color = Tokens.AMBER if "cracked_supports" in observed else Tokens.DIM
	var width: float = 3.0 if "cracked_supports" in observed else 1.5
	_line([0.18, 0.12], [0.21, 0.20], crack, width)
	_line([0.21, 0.20], [0.19, 0.27], crack, width)
	_line([0.19, 0.27], [0.23, 0.35], crack, width)
	_line([0.78, 0.15], [0.80, 0.24], crack, width)
	_line([0.80, 0.24], [0.77, 0.31], crack, width)
	# Debris at the foot of the walls; the passage ahead stays open.
	_poly([[0.04, 0.88], [0.10, 0.80], [0.18, 0.84], [0.22, 0.90]], Tokens.BORDER_STRONG)
	_poly([[0.80, 0.90], [0.86, 0.82], [0.94, 0.86], [0.97, 0.92]], Tokens.BORDER_STRONG)

func _draw_pumphall() -> void:
	_floor_and_rock(0.80)
	var ok: Color = Tokens.BORDER_STRONG
	# Pump body: a squat drum with flanges, plus pipes into the wall.
	draw_rect(Rect2(_p(0.16, 0.42), Vector2(size.x * 0.20, size.y * 0.38)), Tokens.ELEVATED)
	draw_rect(Rect2(_p(0.16, 0.42), Vector2(size.x * 0.20, size.y * 0.38)), ok, false, 2.0)
	draw_rect(Rect2(_p(0.14, 0.40), Vector2(size.x * 0.24, size.y * 0.05)), ok)
	draw_rect(Rect2(_p(0.14, 0.77), Vector2(size.x * 0.24, size.y * 0.05)), ok)
	draw_circle(_p(0.26, 0.61), size.y * 0.07, Tokens.PANEL)
	draw_circle(_p(0.26, 0.61), size.y * 0.07, ok, false, 2.0)
	var pump_color: Color = Tokens.AMBER if "stalled_pump" in observed else Tokens.SECONDARY
	_line([0.36, 0.52], [0.50, 0.52], pump_color, 6.0)
	_line([0.50, 0.52], [0.50, 0.18], pump_color, 6.0)
	_line([0.50, 0.18], [0.64, 0.18], pump_color, 6.0)
	# Control post: the socket is empty, dark, with a cut cable.
	draw_rect(Rect2(_p(0.58, 0.36), Vector2(size.x * 0.12, size.y * 0.30)), Tokens.PANEL)
	draw_rect(Rect2(_p(0.58, 0.36), Vector2(size.x * 0.12, size.y * 0.30)), ok, false, 2.0)
	draw_rect(Rect2(_p(0.605, 0.42), Vector2(size.x * 0.07, size.y * 0.12)), Tokens.BASE)
	var socket: Color = Tokens.AMBER if "controller_missing" in observed else Tokens.DIM
	draw_rect(Rect2(_p(0.605, 0.42), Vector2(size.x * 0.07, size.y * 0.12)), socket, false, 2.0)
	_line([0.64, 0.54], [0.66, 0.66], socket, 2.0)
	_line([0.66, 0.70], [0.68, 0.80], socket, 2.0)
	# Sealed deeper passage: a collapse filling the arch at the right.
	_poly([[0.80, 0.80], [0.80, 0.34], [0.86, 0.26], [0.94, 0.34], [0.94, 0.80]], Tokens.BASE)
	_poly([[0.80, 0.80], [0.82, 0.58], [0.88, 0.50], [0.94, 0.62], [0.94, 0.80]], Tokens.BORDER_STRONG)
	_poly([[0.82, 0.80], [0.86, 0.66], [0.91, 0.72], [0.94, 0.80]], Tokens.BORDER)
