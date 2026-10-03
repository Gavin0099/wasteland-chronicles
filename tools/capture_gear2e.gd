extends SceneTree
const Fixture = preload("res://tests/fixtures/gear2e_world.gd")
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Rumors = preload("res://simulation/rumors.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/gear2e")

func _init() -> void:
	call_deferred("capture")

func frame(label: String) -> void:
	for step: int in range(12):
		await process_frame
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for mode: String in ["rumors", "checkpoint_locked", "checkpoint_ready", "mask_receipt", "workshop_locked", "workshop_ready", "tools_receipt", "engineer_methods", "engineer_receipt"]:
			var world: WorldState
			if mode == "rumors":
				world = Base.fresh("settlement:dry_well")
			elif mode.begins_with("engineer"):
				world = Fixture.engineer_site()
				if mode.ends_with("receipt"):
					assert(Base.answer(world, &"ENGINEER_OVERHAUL").success)
			elif mode.begins_with("workshop") or mode == "tools_receipt":
				world = Fixture.workshop(mode != "workshop_locked")
				if mode == "tools_receipt":
					assert(Base.answer(world, &"ENTER_TOXIC_WORKSHOP").success)
			else:
				world = Fixture.checkpoint("wrench" if mode == "checkpoint_locked" else "repair_toolbox")
				if mode == "mask_receipt":
					assert(Base.answer(world, &"RECOVER_GAS_MASK").success)
			var before: String = world.to_canonical_json()
			var shell := PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, SimulationEngine.new())
			if mode == "rumors":
				shell._show_rumors()
			await frame(mode)
			if mode == "rumors":
				var scrolls: Array[Node] = shell.rumor_window.find_children("*", "ScrollContainer", true, false)
				assert(not scrolls.is_empty())
				scrolls[0].scroll_vertical = 420
				await frame("mask_rumor")
			assert(world.to_canonical_json() == before, "rendering must be read-only")
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
