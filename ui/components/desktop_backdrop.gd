class_name DesktopBackdrop
extends Control

# A quiet brick workbench, visible only between real game windows.
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#241D1B"))
	var brick_height := 24.0
	var brick_width := 72.0
	var rows := int(ceil(size.y / brick_height))
	var columns := int(ceil(size.x / brick_width)) + 2
	for row in rows:
		var y := float(row) * brick_height
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("#59443B"), 1.0)
		var offset := brick_width * 0.5 if row % 2 == 1 else 0.0
		for col in columns:
			var x := float(col) * brick_width + offset
			draw_line(Vector2(x, y), Vector2(x, y + brick_height), Color("#4C3932"), 1.0)
