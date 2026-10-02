extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://ui/field_screen.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/gun1")

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String) -> void:
	for frame: int in range(12):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y])

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		var world: WorldState = S1WorldData.create_s1_world()
		var engine: SimulationEngine = SimulationEngine.new()
		engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:new_hope", "character_name": "持槍旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": []}))
		world.player.money = 500
		engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"old_revolver", 1))
		engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"revolver_round", 1))
		engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"old_revolver", "main_hand"))
		engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well"))
		world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:new_hope", &"settlement:dry_well", 1, {"target_enemy": "heavy_raider"})
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT"))
		var screen: Control = Field.new()
		root.add_child(screen)
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		screen.setup(world, engine)
		await save_frame("loaded")
		engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "SHOOT", "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)}))
		screen.refresh()
		await save_frame("empty")
		screen.queue_free()
		await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
