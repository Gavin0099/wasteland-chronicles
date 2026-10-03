extends "res://tests/test_shared_factions.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/shared-factions")
var captures: int = 0

func _init() -> void:
	call_deferred("capture")

func frame(label: String, world: WorldState, twin: WorldState) -> void:
	var before: String = world.to_canonical_json()
	for tick: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK, "actual Vulkan image saved")
	captures += 1
	check(world.to_canonical_json() == before, "render does not mutate authority")
	parity(world, twin, label + " rendered read-only")

func show_dialog(world: WorldState, twin: WorldState, label: String, bottom: bool = false) -> void:
	var shell: PlayableShell = Shell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, engine)
	var button: Button = find_button(shell, "陣營")
	check(button != null, "real toolbar entry rendered")
	button.pressed.emit()
	for tick: int in range(4): await process_frame
	var dialog: AcceptDialog = shell.faction_window
	check(dialog.get_ok_button().has_focus() and dialog.size.x <= root.size.x and dialog.size.y <= root.size.y, "visible close keyboard focus and viewport-fit dialog")
	if bottom:
		check(dialog.scroll.get_v_scroll_bar().max_value > dialog.scroll.get_v_scroll_bar().page, "real overflow is scrollable")
		dialog.scroll.scroll_vertical = int(dialog.scroll.get_v_scroll_bar().max_value)
	await frame(label, world, twin)
	# Actual keyboard Escape closes the embedded Godot window.
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	for tick: int in range(4): await process_frame
	check(not is_instance_valid(shell.faction_window), "actual Escape closes dialog")
	shell.queue_free()
	await process_frame

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var world: WorldState = fresh_towns("settlement:new_hope")
		var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
		await show_dialog(world, twin, "neutral_public_members")
		await show_dialog(world, twin, "neutral_rules_scrolled", true)
		deliver_pair(world, twin, work_at(world, "settlement:new_hope", "SALVAGE"))
		deliver_pair(world, twin, work_at(world, "settlement:new_hope", "COURIER"))
		walk_pair(world, twin, "settlement:spring_ford")
		await show_dialog(world, twin, "cooperative_peer5_local0", true)
		var shell: PlayableShell = Shell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell.quest_id_shown = work_at(world, "settlement:spring_ford", "SALVAGE").definition.id
		shell._on_quest_access_pressed()
		await frame("actual_cooperative_peer_job", world, twin)
		var job_scroll: ScrollContainer = shell.quest_description.get_parent().get_parent()
		job_scroll.scroll_vertical = int(job_scroll.get_v_scroll_bar().max_value)
		await frame("actual_cooperative_peer_pay_scrolled", world, twin)
		shell.queue_free()
		await process_frame
		world = fresh_towns("settlement:new_hope")
		twin = WorldState.from_json_checked(world.to_canonical_json()).world
		for index: int in range(5):
			if index > 0: wait_pair(world, twin, 3)
			deliver_pair(world, twin, work_at(world, "settlement:new_hope", "SALVAGE"))
		await show_dialog(world, twin, "ally10_local20_no_compound", true)
		world = fresh_towns("settlement:iron_pass")
		twin = WorldState.from_json_checked(world.to_canonical_json()).world
		betray_pair(world, twin, "settlement:iron_pass")
		walk_pair(world, twin, "settlement:gray_valley")
		await show_dialog(world, twin, "resisted_peer15_issuer25")
		shell = Shell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell.quest_id_shown = work_at(world, "settlement:gray_valley", "SALVAGE").definition.id
		shell._on_quest_access_pressed()
		await frame("actual_peer_work_locked", world, twin)
		shell.queue_free()
		await process_frame
		shell = Shell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_local_market()
		await frame("actual_peer_market_markup", world, twin)
		shell.queue_free()
		await process_frame
		wait_pair(world, twin, 20 - world.current_day)
		await show_dialog(world, twin, "day20_peer_reopened")
	print("Faction captures: saves=%d assertions=%d failures=%d" % [captures, assertions, failures])
	quit(0 if failures == 0 else 1)
