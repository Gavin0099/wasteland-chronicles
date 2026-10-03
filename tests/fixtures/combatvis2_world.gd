extends RefCounted

const Base = preload("res://tests/fixtures/combat_vis1_world.gd")
const Weapons = ["crowbar", "scrap_machete", "old_world_saber", "sledgehammer", "old_revolver", "short_shotgun"]

static func create(weapon: String, engine: SimulationEngine, environment: String = "highway") -> WorldState:
	if weapon != "crowbar":
		return Base.create(environment, weapon in ["old_revolver", "short_shotgun"], engine, true, weapon)
	var world := Base.create("shed", false, engine, false)
	engine.commit_player_intent(world, PlayerIntent.create_unequip_item(world.player.npc_id, "main_hand"))
	world.player.inventory.set_amount("scrap", 3)
	engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "CRAFT"}))
	engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "EQUIP"}))
	engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}))
	return world
