extends SceneTree

# PLAY-3A rendered evidence. Uses the real entry scene and character creation,
# then commits acceptance, travel and salvage through the simulation authority.
# Screenshots prove presentation only; integration tests own replay/correctness.
const MainScene = preload("res://main.tscn")
const Board = preload("res://simulation/job_board.gd")
const OUT_DIR := "res://artifacts/play3a-salvage"

var failures := 0

func _init() -> void:
	call_deferred("capture")

func _check(ok: bool, label: String) -> bool:
	if not ok:
		failures += 1
		push_error("PLAY-3A CAPTURE: " + label)
	return ok

func _world_hash(world: WorldState) -> String:
	return JSON.stringify(world.to_dict(), "", true).sha256_text()

func _refresh_without_mutation(shell: PlayableShell) -> bool:
	var before := _world_hash(shell.world)
	shell.refresh_ui()
	return _check(_world_hash(shell.world) == before, "UI projection or refresh mutated world")

func _save_view(shell: PlayableShell, viewport_size: Vector2i, label: String) -> bool:
	var before := _world_hash(shell.world)
	for frame in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s_%dx%d.png" % [OUT_DIR, label, viewport_size.x, viewport_size.y]
	var capture_image: Image = root.get_texture().get_image()
	if not _check(capture_image.get_size() == viewport_size, "unexpected screenshot size: " + str(capture_image.get_size())):
		return false
	if not _check(capture_image.save_png(ProjectSettings.globalize_path(path)) == OK, "failed to write " + path):
		return false
	if not _check(_world_hash(shell.world) == before, "render mutated world: " + label):
		return false
	print("CAPTURED ", ProjectSettings.globalize_path(path))
	return true

func _select_job(shell: PlayableShell, job_id: String) -> bool:
	if not shell.quest_journal_open:
		shell.quest_access_button.pressed.emit()
	for index in shell.quest_selector.item_count:
		if String(shell.quest_selector.get_item_metadata(index)) == job_id:
			shell.quest_selector.select(index)
			shell.quest_selector.item_selected.emit(index)
			return true
	return _check(false, "salvage work order absent from real quest selector")

func _capture_size(viewport_size: Vector2i) -> bool:
	root.size = viewport_size
	var main = MainScene.instantiate()
	root.add_child(main)
	main.creation.name_input.text = "灰谷修理工"
	main.creation.age_input.text = "28"
	main.creation.select_background("MECHANIC")
	if not _check(main.creation.submit().success, "mechanic creation rejected"):
		main.queue_free()
		return false
	main.creation.enter_button.pressed.emit()
	var shell: PlayableShell = main.shell
	var world: WorldState = main.world
	var engine: SimulationEngine = main.engine
	if not _check(shell != null, "main scene did not enter playable shell"):
		main.queue_free()
		return false
	var entry: Dictionary = {}
	for posting in Board.postings(world, &"settlement:gray_valley"):
		if posting.get("archetype", "") == "SALVAGE":
			entry = posting
			break
	if not _check(not entry.is_empty(), "day-zero salvage job missing"):
		main.queue_free()
		return false
	var job_id := String(entry.definition.id)
	var before_ui := _world_hash(world)
	if not _select_job(shell, job_id):
		main.queue_free()
		return false
	if not await _save_view(shell, viewport_size, "job_detail"):
		main.queue_free()
		return false
	var quest_scroll := shell.quest_description.get_parent().get_parent() as ScrollContainer
	quest_scroll.scroll_vertical = 10000
	if not await _save_view(shell, viewport_size, "job_detail_scrolled"):
		main.queue_free()
		return false
	shell.quest_close_button.pressed.emit()
	if not _check(_world_hash(world) == before_ui, "opening, selecting, scrolling or closing work order mutated world"):
		main.queue_free()
		return false
	if not _check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job_id)).success, "acceptance rejected"):
		main.queue_free()
		return false
	# Buy real supplies before the journey instead of changing fixture inventory.
	for resource in [&"water", &"food"]:
		var needed := maxi(0, 5 - int(world.player.inventory.get_amount(String(resource))))
		if needed > 0 and not _check(engine.commit_player_intent(world, PlayerIntent.create_buy(world.player.npc_id, resource, needed)).success, "supply purchase rejected"):
			main.queue_free()
			return false
	var destination := StringName("settlement:" + String(entry.definition.target_route_destination))
	if not _check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, destination)).success, "target route travel rejected"):
		main.queue_free()
		return false
	if not _check(world.active_encounter != null and String(world.active_encounter.context.get("salvage_job_id", "")) == job_id, "real travel did not produce contract wreck"):
		main.queue_free()
		return false
	if not _refresh_without_mutation(shell):
		main.queue_free()
		return false
	if not await _save_view(shell, viewport_size, "target_encounter"):
		main.queue_free()
		return false
	print("VISIBLE TITLE ", shell.lbl_encounter_title.text)
	if not _check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"STRIP_PARTS")).success, "mechanic salvage rejected"):
		main.queue_free()
		return false
	if not _refresh_without_mutation(shell):
		main.queue_free()
		return false
	if not await _save_view(shell, viewport_size, "salvage_receipt"):
		main.queue_free()
		return false
	if not _check(engine.validate_invariants(world) == "", "invariant failure after captured salvage"):
		main.queue_free()
		return false
	print("VERIFIED real main scene, day-zero mechanic, accepted target, canonical travel, STRIP_PARTS, receipt, read-only UI at ", viewport_size)
	main.queue_free()
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	return true

func capture() -> void:
	if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR)) == OK, "cannot create capture output directory"):
		quit(1)
		return
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		if not await _capture_size(viewport_size):
			quit(1)
			return
	quit(0 if failures == 0 else 1)
