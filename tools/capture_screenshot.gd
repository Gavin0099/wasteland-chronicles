extends SceneTree

var frame_count := 0

func _init() -> void:
	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)
	process_frame.connect(_on_frame)

func _get_shell() -> PlayableShell:
	for node in root.get_children():
		for c in node.get_children():
			if c is PlayableShell:
				return c
	return null

func _on_frame() -> void:
	frame_count += 1
	var shell := _get_shell()

	if frame_count == 10:
		var img: Image = root.get_texture().get_image()
		if img != null:
			var target_path := "C:/Users/daish/.gemini/antigravity/brain/8c535034-f695-4643-94c4-87d72ea7310c/godot_runtime_screenshot.png"
			img.save_png(target_path)
			print("CAPTURE_SETTLED: done")
		if shell != null:
			shell.select_settlement("settlement:new_hope")
			var res = shell.on_travel_pressed()
			print("TRIGGERED_TRAVEL result: ", res)
		else:
			print("SHELL NOT FOUND")

	elif frame_count == 25:
		var img: Image = root.get_texture().get_image()
		if img != null:
			var target_path := "C:/Users/daish/.gemini/antigravity/brain/8c535034-f695-4643-94c4-87d72ea7310c/godot_transit_screenshot.png"
			img.save_png(target_path)
			print("CAPTURE_TRANSIT: done")
		quit(0)
