extends SceneTree

# Real-renderer capture of the DEATH_TESTED forecast, at both supported
# viewports. The identity is earned by really being beaten to the last point of
# health on two separate days, through the production intents, so the
# screenshot shows a state the game can actually reach.

const Creation = preload("res://simulation/character_creation_intent.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/c45-death-tested")

func _init() -> void:
	call_deferred("capture")

func _fields(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload.battle_id = world.field_state.battle.id
		payload.turn = world.field_state.battle.turn
	if command == "CONFIRM":
		payload.receipt = world.field_state.receipt
	return payload

func _act(world: WorldState, engine: SimulationEngine, command: String) -> void:
	engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, _fields(world, command)))

func _ambush(world: WorldState, engine: SimulationEngine, hp: int) -> void:
	var id: StringName = world.player.npc_id
	var origin: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var dest := &"settlement:dry_well" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = 50
	world.player.field_kit.hp = hp
	engine.begin_player_travel(world, PlayerIntent.create_travel(id, dest))
	world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, origin, dest, 1)

func _drive_home(world: WorldState, engine: SimulationEngine) -> void:
	var id: StringName = world.player.npc_id
	for step in range(14):
		if world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED:
			break
		if world.field_state.receipt >= 0:
			_act(world, engine, "CONFIRM")
		elif not world.field_state.battle.is_empty():
			_act(world, engine, "FLEE")
		elif world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result))
		elif world.active_encounter != null:
			var escape: StringName = &"FLEE_ROAD" if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else (&"DETOUR" if world.active_encounter.encounter_type in [TravelEncounter.ROCKSLIDE, TravelEncounter.ROADBLOCK] else &"LEAVE")
			engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, escape))
		else:
			engine.tick(world)

func _qualified_world() -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	if not engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "見過底的人",
		"age": 34, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success:
		return {}
	var id: StringName = world.player.npc_id

	# Two separate days beaten down to the last point of health.
	for _round in range(2):
		_ambush(world, engine, 3)
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"FIGHT"))
		for turn in range(12):
			if world.field_state.battle.is_empty():
				break
			_act(world, engine, "ATTACK")
		_drive_home(world, engine)

	if not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DEATH_TESTED")).success:
		return {}
	_ambush(world, engine, 9)
	return {"world": world, "engine": engine}

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var setup := _qualified_world()
		if setup.is_empty():
			quit(1)
			return
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(setup.world, setup.engine)
		for frame in range(12):
			await process_frame
		var path := "%s/forecast_%dx%d.png" % [output_dir, viewport_size.x, viewport_size.y]
		if root.get_texture().get_image().save_png(path) != OK:
			quit(1)
			return
		print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
	quit(0)
