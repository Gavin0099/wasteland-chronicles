extends RefCounted
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Party = preload("res://simulation/party.gd")
const Request = preload("res://simulation/companion_request.gd")

static func geared() -> WorldState:
	var world: WorldState = Base.fresh("settlement:new_hope")
	world.player.money = 5000
	var engine := SimulationEngine.new()
	for id: String in ["quickdraw_police_revolver", "short_shotgun", "expedition_travel_backpack", "plated_leather_jacket", "precision_repair_toolbox", "simple_meter"]:
		assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success)
	for spec: Array in [["quickdraw_police_revolver", "main_hand"], ["expedition_travel_backpack", "back"], ["plated_leather_jacket", "body"]]:
		assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(spec[0]), spec[1])).success)
	for ammo: String in ["revolver_round", "shotgun_shell"]:
		assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(ammo), 2)).success)
	assert(engine.commit_player_intent(world, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:armory")).success)
	return world

static func shared_journey() -> WorldState:
	var world: WorldState = Base.fresh()
	var engine := SimulationEngine.new()
	assert(engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Party.ABBAN)).success)
	assert(engine.commit_player_intent(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT")).success)
	Base.resupply(world)
	assert(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success)
	for step: int in range(30):
		if world.pending_encounter_result >= 0:
			assert(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success)
			continue
		if world.active_encounter == null:
			break
		var option: StringName = &"RECOVER_ABBAN_TOOL" if world.active_encounter.context.get("companion_request", false) else &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.ROCKSLIDE: option = &"DETOUR"
			TravelEncounter.ROADBLOCK: option = &"PAY"
			TravelEncounter.BANDIT_AMBUSH: option = &"FLEE_ROAD"
		assert(Base.answer(world, option).success)
	assert(not Request.state(world).shared.is_empty())
	assert(engine.commit_player_intent(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id)).success)
	return world
