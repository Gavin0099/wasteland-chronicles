extends Node2D

# Small original vector effects. Local stage feedback only.
var kind := "slash"
var direction := Vector2.RIGHT
var extent := 30.0

func _draw() -> void:
	var amber := preload("res://ui/theme/pda_tokens.gd").AMBER
	if kind in ["revolver", "shotgun"]:
		var width := 12.0 if kind == "revolver" else 20.0
		var points := PackedVector2Array([Vector2.ZERO, Vector2(extent * 0.35, -width),
			Vector2(extent * 0.50, -width * 0.25), Vector2(extent, 0),
			Vector2(extent * 0.45, width * 0.3), Vector2(extent * 0.25, width)])
		draw_colored_polygon(points, amber)
		draw_line(Vector2.ZERO, Vector2(extent * 0.65, 0), Color.WHITE, 3.0, true)
	elif kind == "brace":
		draw_arc(Vector2.ZERO, extent, -1.1, 1.1, 16, amber, 3.0, true)
	else:
		var sweep := 1.8 if kind == "machete" else 1.0
		draw_arc(Vector2.ZERO, extent, -sweep, 0.3, 16, amber, 3.0, true)
		draw_arc(Vector2.ZERO, extent * 0.85, -sweep, 0.3, 16, Color(amber, 0.5), 2.0, true)
