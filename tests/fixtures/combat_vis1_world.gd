extends RefCounted

const Creation = preload("res://simulation/character_creation_intent.gd")

# Fixtures use real intents. Only road ambush selection is pinned, as in GUN-1.
static func create(environment: String, firearm: bool, engine: SimulationEngine, start_battle: bool = true) -> WorldState:
	var world := S1WorldData.create_s1_world()
	engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley" if environment == "shed" else "settlement:dry_well",
		"character_name": "荒原旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": [],
	}))
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.item_inventory.pickup_item("old_revolver" if firearm else "scrap_machete", 1)
	if firearm:
		world.player.item_inventory.pickup_item("revolver_round", 2)
	engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id,
		&"old_revolver" if firearm else &"scrap_machete", "main_hand"))
	if environment == "shed":
		if start_battle:
			engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}))
	elif environment == "camp":
		engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope", "WILDERNESS"))
		for stop in range(8):
			if world.active_encounter == null:
				break
			if String(world.active_encounter.context.get("place_id", "")) == "place:hammer_camp":
				engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT"))
				break
			var skip := &"LEAVE"
			if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH:
				skip = &"FLEE_ROAD"
			elif world.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE:
				skip = &"DETOUR"
			engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, skip))
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
	else:
		var route := "WILDERNESS" if environment == "wilderness" else "HIGHWAY"
		engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope", route))
		world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH,
			world.current_day, &"settlement:dry_well", &"settlement:new_hope", 1,
			{"target_enemy": "heavy_raider" if environment == "wilderness" else "bandit", "route_type": route})
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT"))
	return world
