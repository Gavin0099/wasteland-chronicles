extends "res://tests/test_dungeon_combat.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/dun3")
var captures: int = 0

func _init() -> void:
	store = Store.new("user://tests/dun3-renderer/journey.json")
	call_deferred("capture_combat")

func observe(label: String, main: Node) -> void:
	await super.observe(label, main)
	var before: String = main.world.to_canonical_json()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK, "real Vulkan screenshot saved")
	captures += 1
	check(main.world.to_canonical_json() == before, "actual rendering remains read-only")

func capture_combat() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		await combat_ui()
	print("DUN-3 Vulkan: %d screenshots, %d assertions, %d failures" % [captures, assertions, failures])
	quit(0 if failures == 0 else 1)

func motion_observe(screen: Control, command_name: String) -> void:
	await super.motion_observe(screen, command_name)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/guard_%s_motion_%dx%d.png" % [output_dir, command_name.to_lower(), root.size.x, root.size.y]) == OK, "real committed motion screenshot saved")
	captures += 1
