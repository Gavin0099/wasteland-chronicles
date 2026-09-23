extends SceneTree

const Screen = preload("res://ui/character_creation_screen.gd")
const OUT_DIR := "res://artifacts/character-creation-window"

func _init() -> void:
	call_deferred("capture")

func _save(label: String, size: Vector2i) -> bool:
	for frame in range(6):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [OUT_DIR, label, size.x, size.y]
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("Creation capture failed: " + path)
		return false
	print("CAPTURED ", path)
	return true

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		var world := S1WorldData.create_s1_world()
		var ui := Screen.new()
		root.add_child(ui)
		ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.setup(world, SimulationEngine.new())
		ui.name_input.text = "灰谷旅人"
		ui.select_background("MECHANIC")
		ui.trait_buttons.CAUTIOUS.button_pressed = true
		ui.trait_buttons.CURIOUS.button_pressed = true
		if not await _save("creation", size):
			quit(1)
			return
		if not ui.submit().success or not await _save("summary", size):
			push_error("Creation summary capture failed")
			quit(1)
			return
		ui.queue_free()
		await process_frame
	quit(0)
