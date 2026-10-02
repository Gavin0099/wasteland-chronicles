extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/econ1")

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String) -> void:
	for frame: int in range(10):
		await process_frame
	var path: String = "%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]
	root.get_texture().get_image().save_png(path)
	print("CAPTURED " + path)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		var world: WorldState = S1WorldData.create_s1_world()
		var engine: SimulationEngine = SimulationEngine.new()
		engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "補貨人", "age": 28, "background_id": "MECHANIC", "trait_ids": []}))
		var town: SettlementState = world.get_settlement(&"settlement:gray_valley")
		town.item_market = ItemMarketState.seeded_for(town.id)
		town.item_market.set_quantity("rope", 0)
		var shell: PlayableShell = PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_local_market()
		await process_frame
		shell.market_window.row_buttons["rope"].pressed.emit()
		await save_frame("shortage")
		shell.market_window.hide()
		var job_id: String = "job_gray_valley_item_request_rope_0"
		engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job_id))
		world.player.item_inventory.pickup_item("rope", 1)
		shell.refresh_ui()
		shell.quest_id_shown = job_id
		shell._render_quests(PlayerUIProjection.project(world).quests)
		shell._on_quest_pressed()
		await save_frame("delivery")
		shell.queue_free()
		await process_frame
	quit(0)
