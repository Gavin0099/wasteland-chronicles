extends SceneTree

# Diagnostic only: compare the approved live factory against the old missing-road fixture.
const Worlds = preload("res://game_data/playable_world.gd")

func _init() -> void:
	var engine := SimulationEngine.new()
	for with_supply_road: bool in [false, true]:
		var world: WorldState = Worlds.create_world()
		if not with_supply_road:
			world.caravans.erase(&"caravan:c_spring_iron")
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
			print("with_supply_road=%s town=%s population=%d deaths=%d water=%d food=%d pressures=%.1f/%.1f" % [with_supply_road, town.id, town.population, town.cumulative_deaths, town.inventory.water, town.inventory.food, town.water_pressure, town.food_pressure])
		print("Diagnostic day180: with_supply_road=%s living=%d deaths=%d initial=%d twin_sha256=%s" % [with_supply_road, living, deaths, world.total_initial_population, world.to_canonical_json().sha256_text()])
	print("Diagnostic replay/invariants passed; approved road is in the live factory.")
	quit(0)
