class_name S1WorldData
extends RefCounted

static func create_s1_world() -> WorldState:
	var world := WorldState.new()
	world.current_day = 0

	# 1. 新希望 (綠洲農業中心 - 產水/糧，缺廢料/燃料)
	# 淨產出: 水 +8, 糧 +5, 廢料 -3, 燃料 -2
	var new_hope := SettlementState.new(
		&"settlement:new_hope",
		"新希望 (New Hope)",
		ResourceState.new(100, 80, 60, 40),
		ResourceState.new(14, 9, 1, 0),
		ResourceState.new(6, 4, 4, 2),
		100, 80, 8.0, 10.0,
		60, 40, 16.0, 20.0
	)
	world.add_settlement(new_hope)

	# 2. 灰谷 (工業廢料中心 - 產廢料，缺水/糧/燃料)
	# 淨產出: 水 -5, 糧 -2, 廢料 +7, 燃料 -2
	var gray_valley := SettlementState.new(
		&"settlement:gray_valley",
		"灰谷 (Gray Valley)",
		ResourceState.new(80, 80, 100, 40),
		ResourceState.new(0, 2, 11, 0),
		ResourceState.new(5, 4, 4, 2),
		80, 80, 15.0, 12.0,
		100, 40, 8.0, 20.0
	)
	world.add_settlement(gray_valley)

	# 3. 乾井 (燃料精煉中心 - 產燃料，缺水/糧/廢料)
	# 淨產出: 水 -3, 糧 -3, 廢料 -1, 燃料 +5
	var dry_well := SettlementState.new(
		&"settlement:dry_well",
		"乾井 (Dry Well)",
		ResourceState.new(60, 60, 50, 100),
		ResourceState.new(1, 1, 1, 8),
		ResourceState.new(4, 4, 2, 3),
		60, 60, 15.0, 15.0,
		50, 100, 14.0, 10.0
	)
	world.add_settlement(dry_well)

	# 4. 三角互補商隊網絡
	# 商隊 1: 新希望 <-> 灰谷 (水糧換廢料)
	var c_hope_gray := CaravanState.new(
		&"caravan:c_hope_gray",
		"綠洲-灰谷商隊",
		&"settlement:new_hope",
		&"settlement:gray_valley",
		ResourceState.new(25, 10, 0, 0),
		40, 3, 3
	)
	world.add_caravan(c_hope_gray)

	# 商隊 2: 新希望 <-> 乾井 (水糧換燃料)
	var c_hope_dry := CaravanState.new(
		&"caravan:c_hope_dry",
		"綠洲-油井商隊",
		&"settlement:new_hope",
		&"settlement:dry_well",
		ResourceState.new(18, 15, 0, 0),
		40, 3, 3
	)
	world.add_caravan(c_hope_dry)

	# 商隊 3: 灰谷 <-> 乾井 (廢料換燃料)
	var c_gray_dry := CaravanState.new(
		&"caravan:c_gray_dry",
		"礦山-油井商隊",
		&"settlement:gray_valley",
		&"settlement:dry_well",
		ResourceState.new(0, 0, 15, 0),
		40, 3, 3
	)
	world.add_caravan(c_gray_dry)

	return world
