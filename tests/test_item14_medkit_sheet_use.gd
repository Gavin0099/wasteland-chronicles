extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")

var engine := SimulationEngine.new()
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
		print("FAIL: " + message)

func fixture(injured: bool = true) -> WorldState:
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:new_hope", "character_name": "遠城醫療測試者",
		"age": 26, "background_id": "FARMER", "trait_ids": [],
	}))
	check(created.success, "character is created in New Hope through authority")
	world.player.money = 200 # Controlled market funding.
	var bought := engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"first_aid_kit", 1))
	check(bought.success, "medkit is bought from New Hope's real market")
	if injured:
		world.player.field_kit.hp = 8 # HP authority path is exercised by the C3 treatment suite.
	check(engine.validate_invariants(world) == "", "fixture preserves global invariants")
	return world

func find_sheet(shell: Node) -> AcceptDialog:
	for child in shell.get_children():
		if child is Sheet:
			return child
	return null

func capture(name: String) -> void:
	var folder := OS.get_user_data_dir().path_join("captures/item14-medkit-sheet")
	DirAccess.make_dir_recursive_absolute(folder)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		for frame in range(8):
			await process_frame
		var image_path := folder.path_join("%s_%dx%d.png" % [name, viewport_size.x, viewport_size.y])
		check(root.get_texture().get_image().save_png(image_path) == OK, "renderer captures %s at %dx%d" % [name, viewport_size.x, viewport_size.y])
		print("CAPTURED " + image_path)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var world := fixture()
	var replay := WorldState.from_json(world.to_canonical_json())
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, engine)
	var before_open := world.to_canonical_json()
	shell._show_character()
	await process_frame
	var sheet := find_sheet(shell)
	check(sheet != null and world.to_canonical_json() == before_open, "opening the real character sheet is read-only")
	check(sheet != null and sheet.item_use_buttons.has("first_aid_kit") and not sheet.item_use_buttons.first_aid_kit.disabled, "injured New Hope player sees enabled kit use")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("before_use")
	var day_before: int = world.current_day
	var xp_before: int = world.player.xp
	sheet.item_use_buttons.first_aid_kit.pressed.emit()
	for frame in range(4):
		await process_frame
	var used_sheet := find_sheet(shell)
	check(world.player.field_kit.hp == 12 and world.player.item_inventory.quantity("first_aid_kit") == 0, "sheet button commits real HP heal and kit consumption")
	check(world.current_day == day_before and world.player.xp == xp_before, "sheet treatment advances neither day nor Level XP")
	check(world.player.capability.get_practice_progress("MEDICINE").points == 1, "sheet use practices Medicine through the same authority")
	check(used_sheet != null and used_sheet.action_notice_label.visible and used_sheet.action_notice_label.text.contains("生命 +4") and used_sheet.action_notice_label.text.contains("醫療練習 +1"), "reopened sheet visibly reports actual result")
	check(used_sheet != null and not used_sheet.item_use_buttons.has("first_aid_kit"), "consumed kit no longer offers another use")
	if "--capture" in OS.get_cmdline_user_args():
		await capture("after_use")
	var direct := engine.commit_player_intent(replay, PlayerIntent.create_field_action(replay.player.npc_id, {"command": "TREAT"}))
	check(direct.success and replay.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text(), "UI and direct authority have identical full-world SHA-256")
	print("ITEM-14 sheet-use replay SHA-256: " + world.to_canonical_json().sha256_text())
	var loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success and loaded.world.to_canonical_json() == world.to_canonical_json(), "sheet-used item and Medicine progress persist")
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(replay) == "", "both tracks preserve global invariants")
	shell.queue_free()
	await process_frame
	var full := fixture(false)
	var full_shell := PlayableShell.new()
	root.add_child(full_shell)
	full_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	full_shell.setup(full, engine)
	var full_before := full.to_canonical_json()
	full_shell._show_character()
	await process_frame
	var full_sheet := find_sheet(full_shell)
	check(full_sheet != null and full_sheet.item_use_buttons.has("first_aid_kit") and full_sheet.item_use_buttons.first_aid_kit.disabled and full_sheet.item_use_buttons.first_aid_kit.text.contains("生命已滿"), "full health shows visible reason and disables use")
	check(full.to_canonical_json() == full_before, "locked character view changes no world state")
	full_shell.queue_free()
	await process_frame
	print("ITEM-14 medkit sheet use: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
