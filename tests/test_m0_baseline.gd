extends SceneTree

func _init() -> void:
	print("--- Running M0-A Baseline Economy Test ---")
	var engine := SimulationEngine.new()
	var world := M0WorldData.create_m0_world()

	var gray_valley: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var new_hope: SettlementState = world.get_settlement(&"settlement:new_hope")
	var dry_well: SettlementState = world.get_settlement(&"settlement:dry_well")
	var caravan: CaravanState = world.get_caravan(&"caravan:c001")

	var arrival_count: int = 0
	var min_gray_valley_water: int = 999999
	var max_gray_valley_water: int = 0

	for day in range(1, 31):
		var events := engine.tick(world)
		for evt in events:
			if evt.type == "CARAVAN_ARRIVED" and evt.target_id == &"settlement:gray_valley":
				arrival_count += 1
				print("  [Day %d] Caravan C001 arrived at Gray Valley! Unloaded %d water." % [day, evt.payload.get("unloaded_water", 0)])

		var g_water := gray_valley.inventory.water
		if g_water < min_gray_valley_water:
			min_gray_valley_water = g_water
		if g_water > max_gray_valley_water:
			max_gray_valley_water = g_water

		# 控制組斷言：乾井必須嚴格持平
		if dry_well.inventory.water != 50 or dry_well.inventory.food != 50:
			print("FAIL: Dry Well baseline altered at Day %d (W:%d, F:%d)" % [day, dry_well.inventory.water, dry_well.inventory.food])
			quit(1)
			return

		if absf(dry_well.price_water - 12.0) > 0.01 or absf(dry_well.price_food - 12.0) > 0.01:
			print("FAIL: Dry Well price drifted at Day %d" % day)
			quit(1)
			return

	# 驗證灰谷沒有斷水枯竭
	if min_gray_valley_water <= 0:
		print("FAIL: Gray Valley water collapsed to 0 during normal baseline!")
		quit(1)
		return

	# 驗證商隊在 30 天內至少抵達灰谷 4 次 (每 6 天一趟往返)
	if arrival_count < 4:
		print("FAIL: Insufficient caravan arrivals: %d (expected at least 4)" % arrival_count)
		quit(1)
		return

	print("  Gray Valley water min: %d, max: %d" % [min_gray_valley_water, max_gray_valley_water])
	print("  Caravan arrivals at Gray Valley: %d" % arrival_count)
	print("PASS: M0-A Baseline Economy Test (All checks passed)")
	quit(0)
