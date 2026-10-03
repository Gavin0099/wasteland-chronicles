extends RefCounted

const Creation = preload("res://simulation/character_creation_intent.gd")
const Well = preload("res://simulation/well_repair.gd")

static func fresh(town: String = "settlement:gray_valley") -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	var engine: SimulationEngine = SimulationEngine.new()
	assert(engine.commit_character_creation(world, Creation.new({"source_settlement_id": town, "character_name": "裝備技師", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success)
	world.player.money = 2000
	return world

static func resupply(world: WorldState) -> void:
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.inventory.set_amount("scrap", 3)
	world.player.inventory.set_amount("fuel", 0)

static func answer(world: WorldState, option: StringName) -> Dictionary:
	return SimulationEngine.new().commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))

static func finish(world: WorldState) -> void:
	var engine: SimulationEngine = SimulationEngine.new()
	for step: int in range(24):
		if world.pending_encounter_result >= 0:
			assert(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success)
			continue
		if world.active_encounter == null:
			return
		var choice: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		assert(answer(world, choice).success)
	assert(false, "journey must terminate")

static func repair_site(tool: String) -> WorldState:
	var world: WorldState = fresh()
	var engine: SimulationEngine = SimulationEngine.new()
	assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(tool), 1)).success)
	resupply(world)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success)
	assert(answer(world, &"MARK_B").success)
	finish(world)
	var job: String = ""
	for entry: Dictionary in JobBoard.postings(world, &"settlement:dry_well"):
		if Well.is_contract(entry.definition):
			job = entry.definition.id
	assert(job != "")
	assert(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job)).success)
	resupply(world)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:gray_valley")).success)
	assert(world.active_encounter.context.get("repair_visit", false))
	return world

static func armory(tool: String) -> WorldState:
	var world: WorldState = fresh("settlement:dry_well")
	var engine: SimulationEngine = SimulationEngine.new()
	assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(tool), 1)).success)
	resupply(world)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope", "WILDERNESS")).success)
	for step: int in range(24):
		if world.active_encounter != null and world.active_encounter.context.get("place_id") == "place:old_armory":
			return world
		if world.pending_encounter_result >= 0:
			assert(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success)
			continue
		assert(world.active_encounter != null)
		var choice: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		assert(answer(world, choice).success)
	assert(false, "armory journey must stop at real site")
	return world

static func road_battle(world: WorldState, enemy: String = "heavy_raider") -> void:
	var engine: SimulationEngine = SimulationEngine.new()
	assert(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success)
	world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1, {"target_enemy": enemy})
	assert(answer(world, &"FIGHT").success)
