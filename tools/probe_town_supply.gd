extends SceneTree

# Diagnostic only: the proposed extra road is never part of create_world/main.
const Worlds = preload("res://game_data/playable_world.gd")

func _init() -> void:
	var engine := SimulationEngine.new()
	for proposed_bridge: bool in [false, true]:
		var world: WorldState = Worlds.create_world()
		if proposed_bridge:
			world.add_caravan(CaravanState.new(&"caravan:proposal_spring_iron", "診斷用跨陣營商路",
				&"settlement:spring_ford", &"settlement:iron_pass", ResourceState.new(25, 15, 0, 0), 40, 3, 3))
		var restored: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		assert(restored.success)
		var twin: WorldState = restored.world
		for day: int in range(180):
			engine.tick(world)
			engine.tick(twin)
			assert(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "")
			assert(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text())
		var living := 0
		var deaths := 0
		for town: SettlementState in world.settlements.values():
			living += town.population
			deaths += town.cumulative_deaths
			print("proposed_bridge=%s town=%s population=%d deaths=%d water=%d food=%d pressures=%.1f/%.1f" % [proposed_bridge, town.id, town.population, town.cumulative_deaths, town.inventory.water, town.inventory.food, town.water_pressure, town.food_pressure])
		print("Diagnostic day180: proposed_bridge=%s living=%d deaths=%d initial=%d twin_sha256=%s" % [proposed_bridge, living, deaths, world.total_initial_population, world.to_canonical_json().sha256_text()])
	print("Diagnostic replay/invariants passed; supply acceptance requires owner decision.")
	quit(0)
