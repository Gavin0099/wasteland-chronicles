extends SceneTree

# Hand-play fixes of 2026-09-28, real renderer:
#   1. the trade window (all, then weapons)
#   2. a consignment held in the wrong town says where to deliver
#   3. a won bounty away from its town says where to collect
#   4. the battle side panel outside a turn is about the opponent

const Creation = preload("res://simulation/character_creation_intent.gd")
const Board = preload("res://simulation/job_board.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/market-window")

func _init() -> void:
	call_deferred("capture")

func _save(label: String) -> void:
	for frame in range(10):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]
	if root.get_texture().get_image().save_png(path) == OK:
		print("CAPTURED ", path)

func _world(origin: String) -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "商人",
		"age": 29, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	}))
	world.player.money = 180
	world.player.inventory.set_amount("water", 3)
	world.player.inventory.set_amount("food", 3)
	return {"world": world, "engine": engine}

func _shell(setup: Dictionary) -> PlayableShell:
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(setup.world, setup.engine)
	return shell

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var a := _world("settlement:gray_valley")
		var shell := _shell(a)
		shell._show_local_market()
		await _save("1_market_all")
		shell.market_window.tab_buttons["WEAPON"].pressed.emit()
		await _save("1b_market_weapons")
		shell.queue_free()
		await process_frame

		var b := _world("settlement:gray_valley")
		var bw: WorldState = b.world
		var job := ""
		for entry in Board.postings(bw, &"settlement:gray_valley"):
			if entry.archetype == "CONSIGNMENT":
				job = String(entry.definition.id)
		b.engine.commit_player_intent(bw, PlayerIntent.create_accept_quest(bw.player.npc_id, job))
		var shell2 := _shell(b)
		shell2.quest_access_button.pressed.emit()
		for index in shell2.quest_selector.item_count:
			if String(shell2.quest_selector.get_item_metadata(index)) == job:
				shell2.quest_selector.select(index)
				shell2.quest_selector.item_selected.emit(index)
		await _save("2_deliver_elsewhere")
		shell2.queue_free()
		await process_frame

		var c := _world("settlement:gray_valley")
		var screen = FieldScreen.new()
		root.add_child(screen)
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		screen.setup(c.world, c.engine)
		await _save("4_opponent_panel")
		screen.queue_free()
		await process_frame
	quit(0)
