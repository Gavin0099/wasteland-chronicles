extends SceneTree

# PLAY-1 evidence. Three shots that have to differ from each other:
#   1. the shed fight, crowbar in hand
#   2. the same shed fight with a machete equipped - the hand must change
#   3. a road ambush - a different enemy in a different place
# If any two of these look the same, the screen is still lying.

const Creation = preload("res://simulation/character_creation_intent.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/play1-battle-truth")

func _init() -> void:
	call_deferred("capture")

func _base() -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	if not engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "打手",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success:
		return {}
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	return {"world": world, "engine": engine}

func _shed_fight(with_machete: bool) -> Dictionary:
	var setup := _base()
	if setup.is_empty():
		return {}
	var world: WorldState = setup.world
	var engine: SimulationEngine = setup.engine
	var id: StringName = world.player.npc_id
	if with_machete:
		world.player.pickup_item("scrap_machete")
		engine.commit_player_intent(world, PlayerIntent.create_equip_item(id, &"scrap_machete", "main_hand"))
	else:
		world.player.field_kit.crowbar = true
		world.player.field_kit.equipped = true
	engine.commit_player_intent(world, PlayerIntent.create_field_action(id, {"command": "START"}))
	return setup

func _road_fight() -> Dictionary:
	var setup := _base()
	if setup.is_empty():
		return {}
	var world: WorldState = setup.world
	var engine: SimulationEngine = setup.engine
	var id: StringName = world.player.npc_id
	world.player.pickup_item("hunting_knife")
	engine.commit_player_intent(world, PlayerIntent.create_equip_item(id, &"hunting_knife", "main_hand"))
	engine.begin_player_travel(world, PlayerIntent.create_travel(id, &"settlement:dry_well"))
	world.active_encounter = TravelEncounterState.create(
		TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"FIGHT"))
	return setup

func _shoot(setup: Dictionary, label: String) -> void:
	var screen = FieldScreen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.setup(setup.world, setup.engine)
	for frame in range(14):
		await process_frame
	var path := "%s/%s.png" % [output_dir, label]
	if root.get_texture().get_image().save_png(path) == OK:
		print("CAPTURED ", path)
	screen.queue_free()
	await process_frame

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280, 720)
	await _shoot(_shed_fight(false), "1_shed_crowbar")
	await _shoot(_shed_fight(true), "2_shed_machete")
	await _shoot(_road_fight(), "3_road_bandit")
	quit(0)
