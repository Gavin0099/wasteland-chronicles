extends SceneTree

const Fixture = preload("res://tests/fixtures/combat_vis1_world.gd")
const Screen = preload("res://ui/field_screen.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/gear2b")
var engine := SimulationEngine.new()

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String) -> void:
	for frame in range(12):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y])

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for weapon in ["sledgehammer", "combat_knife", "reinforced_saber", "police_revolver", "short_shotgun"]:
			var world := Fixture.create("camp", false, engine, true, weapon)
			var ui := Screen.new()
			root.add_child(ui)
			ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ui.setup(world, engine)
			await save_frame(weapon)
			ui.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
