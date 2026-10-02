extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Well = preload("res://simulation/well_repair.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/job-adv1")

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String) -> void:
	for frame: int in range(10):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y])

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		var world: WorldState = S1WorldData.create_s1_world()
		var engine: SimulationEngine = SimulationEngine.new()
		engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "井泵技師", "age": 28, "background_id": "MECHANIC", "trait_ids": []}))
		world.player.money = 500
		engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1))
		world.player.inventory.set_amount("water", 8)
		world.player.inventory.set_amount("food", 8)
		world.player.inventory.set_amount("scrap", 3)
		engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well"))
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"MARK_B"))
		for step: int in range(24):
			if world.pending_encounter_result >= 0:
				engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
				continue
			if world.active_encounter == null:
				break
			var option: StringName = &"LEAVE"
			match world.active_encounter.encounter_type:
				TravelEncounter.BANDIT_AMBUSH: option = &"FLEE_ROAD"
				TravelEncounter.ROCKSLIDE: option = &"DETOUR"
				TravelEncounter.ROADBLOCK: option = &"PAY"
			engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))
		var job: String = ""
		for entry: Dictionary in JobBoard.postings(world, &"settlement:dry_well"):
			if Well.is_contract(entry.definition):
				job = entry.definition.id
		var shell: PlayableShell = PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell.quest_id_shown = job
		shell._render_quests(PlayerUIProjection.project(world).quests)
		shell._on_quest_access_pressed()
		await save_frame("contract")
		engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job))
		world.player.inventory.set_amount("water", 8)
		world.player.inventory.set_amount("food", 8)
		engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:gray_valley"))
		shell.refresh_ui()
		await save_frame("site")
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"REPAIR_PUMP"))
		shell.refresh_ui()
		await save_frame("repaired")
		shell.queue_free()
		await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
