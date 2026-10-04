extends "res://tests/test_dungeon_deep_reward.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/dun6")
var captures: int = 0

func _init() -> void:
	store = Store.new("user://tests/dun6-renderer/journey.json")
	call_deferred("capture_deep")

func observe_deep(label: String, main: Node) -> void:
	await super.observe_deep(label, main)
	var before: String = main.world.to_canonical_json()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK, "real Vulkan deep screenshot saved")
	captures += 1
	check(main.world.to_canonical_json() == before, "actual deep rendering remains read-only")

func capture_deep() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		await deep_ui()
	print("DUN-6 Vulkan: %d screenshots, %d assertions, %d failures" % [captures, assertions, failures])
	quit(0 if failures == 0 else 1)
