extends SceneTree

const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combat_vis1_world.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/combat-vis1")
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
		var preparation := Screen.new()
		root.add_child(preparation)
		preparation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preparation.setup(Fixture.create("shed", false, engine, false), engine)
		await save_frame("preparation")
		preparation.queue_free()
		await process_frame
		for environment in ["shed", "highway", "wilderness", "camp"]:
			for firearm in [false, true]:
				var world := Fixture.create(environment, firearm, engine)
				var ui := Screen.new()
				root.add_child(ui)
				ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				ui.setup(world, engine)
				var label: String = environment + ("_gun" if firearm else "_melee")
				await save_frame(label)
				if environment == "camp" and firearm:
					ui.reduce_motion.button_pressed = true
					await ui.perform(ui.payload_for("SHOOT"))
					await ui.perform(ui.payload_for("SHOOT"))
					await save_frame("camp_empty")
					await ui.perform(ui.payload_for("FLEE"))
					await create_timer(0.7).timeout
					await save_frame("camp_result")
				ui.queue_free()
				await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
