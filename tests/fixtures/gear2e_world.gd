extends RefCounted
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Well = preload("res://simulation/well_repair.gd")

static func finish(world: WorldState) -> void:
	var engine := SimulationEngine.new()
	for step: int in range(40):
		if world.pending_encounter_result >= 0:
			assert(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success)
			continue
		if world.active_encounter == null:
			return
		var choice: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH:
				choice = &"BRIBE" if TravelEncounter.has_option(world.active_encounter.encounter_type, &"BRIBE", world.active_encounter.context) else &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE:
				choice = &"CLEAR" if world.player.inventory.scrap > 0 else &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		assert(Base.answer(world, choice).success)
	assert(false, "bounded journey with real preparation costs")

static func checkpoint(tool: String = "repair_toolbox") -> WorldState:
	var world: WorldState = Base.fresh("settlement:dry_well")
	var engine := SimulationEngine.new()
	assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(tool), 1)).success)
	assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"travel_backpack", 1)).success)
	assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"travel_backpack", "back")).success)
	Base.resupply(world)
	world.player.inventory.set_amount("scrap", 4)
	assert(engine.commit_player_intent(world, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:gas_mask")).success)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope", "HIGHWAY")).success)
	assert(world.active_encounter.context.get("place_id") == "place:sealed_checkpoint")
	return world

static func seek(world: WorldState, place_id: String) -> void:
	var engine := SimulationEngine.new()
	for step: int in range(32):
		if world.active_encounter != null and world.active_encounter.context.get("place_id") == place_id:
			return
		if world.pending_encounter_result >= 0:
			assert(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success)
			continue
		assert(world.active_encounter != null, "requested place must occur before arrival")
		var choice: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		assert(Base.answer(world, choice).success)
	assert(false, "bounded real journey")

static func workshop(with_mask: bool = true) -> WorldState:
	var world: WorldState = checkpoint()
	assert(Base.answer(world, &"RECOVER_GAS_MASK" if with_mask else &"LEAVE").success)
	finish(world)
	Base.resupply(world)
	assert(SimulationEngine.new().commit_player_intent(world, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:engineer_tools")).success)
	assert(SimulationEngine.new().commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well", "WILDERNESS")).success)
	seek(world, "place:toxic_workshop")
	return world

static func engineer_site() -> WorldState:
	var world: WorldState = workshop()
	var engine := SimulationEngine.new()
	assert(Base.answer(world, &"ENTER_TOXIC_WORKSHOP").success)
	finish(world)
	Base.resupply(world)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:gray_valley")).success)
	assert(Base.answer(world, &"MARK_A").success)
	finish(world)
	var job := ""
	for entry: Dictionary in JobBoard.postings(world, &"settlement:gray_valley"):
		if Well.is_contract(entry.definition):
			job = entry.definition.id
	assert(job != "" and engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job)).success)
	Base.resupply(world)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success)
	assert(world.active_encounter.context.get("repair_visit", false))
	return world
