extends RefCounted

# New games only. The historical S1 fixture and existing saves remain three towns.
static func create_world() -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	var spring := SettlementState.new(
		&"settlement:spring_ford", "泉渡 (Spring Ford)",
		ResourceState.new(100, 80, 50, 40), ResourceState.new(12, 10, 1, 0),
		ResourceState.new(5, 4, 2, 1), 100, 80, 7.0, 9.0, 50, 40, 18.0, 22.0)
	spring.set_population_and_rates(90, 0.05, 0.04, 2, 1)
	world.add_settlement(spring)
	var iron := SettlementState.new(
		&"settlement:iron_pass", "鐵關 (Iron Pass)",
		ResourceState.new(80, 80, 100, 80), ResourceState.new(0, 0, 9, 5),
		ResourceState.new(4, 4, 3, 2), 80, 80, 16.0, 15.0, 100, 80, 7.0, 12.0)
	iron.set_population_and_rates(80, 0.05, 0.05, 3, 2)
	world.add_settlement(iron)
	world.add_caravan(CaravanState.new(&"caravan:c_spring_hope", "渡口-綠洲商隊",
		&"settlement:spring_ford", &"settlement:new_hope", ResourceState.new(20, 15, 0, 0), 40, 2, 2))
	world.add_caravan(CaravanState.new(&"caravan:c_iron_gray", "山口-灰谷商隊",
		&"settlement:iron_pass", &"settlement:gray_valley", ResourceState.new(0, 0, 20, 15), 40, 2, 2))
	# Owner approved the physical cross-faction supply route after the collapse probe.
	world.add_caravan(CaravanState.new(&"caravan:c_spring_iron", "渡口-山口商隊",
		&"settlement:spring_ford", &"settlement:iron_pass", ResourceState.new(25, 15, 0, 0), 40, 3, 3))
	return world
