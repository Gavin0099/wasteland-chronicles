extends SceneTree
const Fixture = preload("res://tests/fixtures/char2_world.gd")
const Unique = preload("res://tests/fixtures/gear2e_world.gd")
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/char2")

func _init() -> void: call_deferred("capture")
func frame(label: String) -> void:
	for step: int in range(12): await process_frame
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for mode: String in ["empty", "geared", "gun_comparison", "rare_detail", "armor_detail", "tool_detail", "unique_detail", "shared_experience", "long_name"]:
			var world: WorldState = Unique.engineer_site() if mode == "unique_detail" else (Fixture.shared_journey() if mode == "shared_experience" else (Base.fresh() if mode == "empty" else Fixture.geared()))
			if mode == "long_name":
				world.npc_registry.get_npc(world.player.npc_id).name = "從灰谷一路走到新希望的修理師"
			var before: String = world.to_canonical_json()
			var shell := PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, SimulationEngine.new())
			shell._show_character()
			await process_frame
			for child in shell.get_children():
				if child.get_script() != Sheet: continue
				if mode == "geared":
					await frame(mode)
					var scrolls: Array[Node] = child.find_children("*", "ScrollContainer", true, false)
					scrolls[1].scroll_vertical = 330
					await frame("inventory")
				elif mode.ends_with("_detail") or mode == "gun_comparison":
					var id: String = {"gun_comparison": "short_shotgun", "rare_detail": "expedition_travel_backpack", "armor_detail": "plated_leather_jacket", "tool_detail": "precision_repair_toolbox", "unique_detail": "engineer_precision_tools"}[mode]
					child.show_item_detail(id)
					await frame(mode)
					for body in child.item_detail.get_children():
						if body is VBoxContainer:
							assert(body.position.y + body.size.y <= child.item_detail.size.y - 40, "detail body stays above confirmation")
					if mode == "gun_comparison":
						for scroll in child.item_detail.find_children("*", "ScrollContainer", true, false): scroll.scroll_vertical = 240
						await frame("gun_properties")
				else:
					await frame(mode)
					if mode == "shared_experience":
						child.find_children("*", "ScrollContainer", true, false)[0].scroll_vertical = 300
						await frame("shared_history")
			assert(world.to_canonical_json() == before, "capture changes no authority")
			shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
