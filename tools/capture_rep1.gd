extends SceneTree

# REP-1 evidence, real renderer: an active consignment with the betrayal
# offered, the confirmation that names the price, and a town that has turned.

const Creation = preload("res://simulation/character_creation_intent.gd")
const Board = preload("res://simulation/job_board.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/rep1-local-trust")

func _init() -> void:
	call_deferred("capture")

func _save(label: String) -> void:
	for frame in range(10):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]
	if root.get_texture().get_image().save_png(path) == OK:
		print("CAPTURED ", path)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var world := S1WorldData.create_s1_world()
		var engine := SimulationEngine.new()
		engine.commit_character_creation(world, Creation.new({
			"source_settlement_id": "settlement:new_hope", "character_name": "挑夫",
			"age": 29, "background_id": "CARAVAN_GUARD", "trait_ids": [],
		}))
		world.player.inventory.set_amount("water", 4)
		world.player.inventory.set_amount("food", 4)
		var job_id := ""
		for entry in Board.postings(world, &"settlement:new_hope"):
			if entry.archetype == "CONSIGNMENT":
				job_id = String(entry.definition.id)
		engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job_id))
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell.quest_access_button.pressed.emit()
		for index in shell.quest_selector.item_count:
			if String(shell.quest_selector.get_item_metadata(index)) == job_id:
				shell.quest_selector.select(index)
				shell.quest_selector.item_selected.emit(index)
		await _save("1_consignment_active")
		shell._on_betray_pressed()
		await _save("2_betray_confirm")
		for child in shell.get_children():
			if child is ConfirmationDialog:
				child.confirmed.emit()
		shell.quest_access_button.pressed.emit()
		await _save("3_town_turned")
		shell.queue_free()
		await process_frame
	quit(0)
