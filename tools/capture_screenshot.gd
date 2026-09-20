extends SceneTree

var frame_count := 0

func _init() -> void:
	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	frame_count += 1
	if frame_count >= 10:
		var img: Image = root.get_texture().get_image()
		if img != null:
			var target_path := "C:/Users/daish/.gemini/antigravity/brain/8c535034-f695-4643-94c4-87d72ea7310c/godot_runtime_screenshot.png"
			var err := img.save_png(target_path)
			print("CAPTURE_RESULT: %d" % err)
		else:
			print("CAPTURE_RESULT: null image")
		quit(0)
