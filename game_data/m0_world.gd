class_name M0WorldData
extends RefCounted

static func create_m0_world() -> WorldState:
	var world := WorldState.new()
	world.current_day = 0

	# 1. 新希望 (產水中心)
	var new_hope := SettlementState.new(
		&"settlement:new_hope",
		"新希望 (New Hope)",
		ResourceState.new(120, 80),
		ResourceState.new(15, 6),
		ResourceState.new(5, 6),
		100,
		80,
		10.0,
		12.0
	)
	world.add_settlement(new_hope)

	# 2. 灰谷 (缺水礦鎮，日消耗 5 水，與商隊 6 天 30 水完全平衡)
	var gray_valley := SettlementState.new(
		&"settlement:gray_valley",
		"灰谷 (Gray Valley)",
		ResourceState.new(80, 100),
		ResourceState.new(0, 10),
		ResourceState.new(5, 8),
		80,
		100,
		15.0,
		10.0
	)
	world.add_settlement(gray_valley)

	# 3. 乾井 (對照組 - 自給自足)
	var dry_well := SettlementState.new(
		&"settlement:dry_well",
		"乾井 (Dry Well)",
		ResourceState.new(50, 50),
		ResourceState.new(5, 5),
		ResourceState.new(5, 5),
		50,
		50,
		12.0,
		12.0
	)
	world.add_settlement(dry_well)

	# 4. 商隊 C001 (新希望 -> 灰谷，3 天單程)
	var caravan := CaravanState.new(
		&"caravan:c001",
		"C001 水車",
		&"settlement:new_hope",
		&"settlement:gray_valley",
		ResourceState.new(30, 0),
		30,
		3,
		3
	)
	world.add_caravan(caravan)

	return world
