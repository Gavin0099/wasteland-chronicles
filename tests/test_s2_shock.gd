extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S2 SUPPLY SHOCK & COUNTERFACTUAL TEST             ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# 1. 執行 World A (Baseline - 正常運轉 100 天)
	# --------------------------------------------------------------------------
	var world_a := S1WorldData.create_s1_world()
	var base_records: Dictionary = {} # day -> {gv_water, gv_price, dw_water, dw_price}

	for day in range(1, 101):
		engine.tick(world_a)
		var gv_a: SettlementState = world_a.get_settlement(&"settlement:gray_valley")
		var dw_a: SettlementState = world_a.get_settlement(&"settlement:dry_well")
		base_records[day] = {
			"gv_water": gv_a.inventory.water,
			"gv_water_price": gv_a.price_water,
			"gv_food": gv_a.inventory.food,
			"gv_scrap": gv_a.inventory.scrap,
			"dw_water": dw_a.inventory.water,
			"dw_fuel": dw_a.inventory.fuel
		}

	# --------------------------------------------------------------------------
	# 2. 執行 World B (Shock - Day 30 摧毀商隊 c_hope_gray)
	# --------------------------------------------------------------------------
	var world_b := S1WorldData.create_s1_world()
	var shock_records: Dictionary = {}
	var post_shock_c_hope_gray_arrivals: int = 0
	var cargo_at_destruction: ResourceState = null

	for day in range(1, 101):
		if day == 30:
			var target_c: CaravanState = world_b.get_caravan(&"caravan:c_hope_gray")
			cargo_at_destruction = target_c.cargo.duplicate_state()
			engine.destroy_caravan(world_b, target_c.id, day)
			print(">>> [SHOCK APPLIED] Day 30: Caravan c_hope_gray destroyed!")

		var events := engine.tick(world_b)
		for evt in events:
			if evt.type == "CARAVAN_ARRIVED" and evt.actor_id == &"caravan:c_hope_gray":
				if day > 30:
					post_shock_c_hope_gray_arrivals += 1

		var gv_b: SettlementState = world_b.get_settlement(&"settlement:gray_valley")
		var dw_b: SettlementState = world_b.get_settlement(&"settlement:dry_well")
		shock_records[day] = {
			"gv_water": gv_b.inventory.water,
			"gv_water_price": gv_b.price_water,
			"gv_food": gv_b.inventory.food,
			"gv_scrap": gv_b.inventory.scrap,
			"dw_water": dw_b.inventory.water,
			"dw_fuel": dw_b.inventory.fuel
		}

	# --------------------------------------------------------------------------
	# 檢驗 1: 決定論驗證 (Determinism Replay)
	# --------------------------------------------------------------------------
	var world_b_replay := S1WorldData.create_s1_world()
	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_b_replay, &"caravan:c_hope_gray", day)
		engine.tick(world_b_replay)

	var hash_b1 := world_b.to_canonical_json().sha256_text()
	var hash_b2 := world_b_replay.to_canonical_json().sha256_text()

	if hash_b1 != hash_b2:
		print("FAIL: Shock replay determinism failed!")
		quit(1)
		return
	print("PASS 1: Determinism Replay (World B SHA-256: %s)" % hash_b1)

	# --------------------------------------------------------------------------
	# 檢驗 2: 無幽靈商隊 (No Phantom Arrivals)
	# --------------------------------------------------------------------------
	if post_shock_c_hope_gray_arrivals > 0:
		print("FAIL: Phantom arrivals detected for c_hope_gray: %d" % post_shock_c_hope_gray_arrivals)
		quit(1)
		return
	print("PASS 2: No Phantom Arrivals (Post-shock c_hope_gray arrivals == 0)")

	# --------------------------------------------------------------------------
	# 檢驗 3: 傳導延遲性 (Latency / No Instant Teleport Jump)
	# --------------------------------------------------------------------------
	# Day 30 當日結束時，衝擊剛發生，灰谷價格不應瞬間跳至最高上限
	var gv_p30_base: float = base_records[30]["gv_water_price"]
	var gv_p30_shock: float = shock_records[30]["gv_water_price"]
	if absf(gv_p30_shock - gv_p30_base) > 0.01:
		print("FAIL: Unrealistic instantaneous price jump at Day 30 (%f vs %f)" % [gv_p30_shock, gv_p30_base])
		quit(1)
		return
	print("PASS 3: Latency Verified (Day 30 price matches baseline $%.2f, no instant jump)" % gv_p30_shock)

	# --------------------------------------------------------------------------
	# 檢驗 4: 因果方向 (Causal Direction - 灰谷水資源走向衰竭)
	# --------------------------------------------------------------------------
	var min_water_after_shock := 999999
	for day in range(31, 101):
		var w: int = shock_records[day]["gv_water"]
		if w < min_water_after_shock:
			min_water_after_shock = w

	if min_water_after_shock > 0:
		print("FAIL: Gray Valley never depleted water after losing lifeline! Min: %d" % min_water_after_shock)
		quit(1)
		return

	# 檢驗價格是否顯著高於 Baseline
	var p_base_100: float = base_records[100]["gv_water_price"]
	var p_shock_100: float = shock_records[100]["gv_water_price"]
	if p_shock_100 <= p_base_100:
		print("FAIL: Shock price at Day 100 ($%.2f) not higher than baseline ($%.2f)!" % [p_shock_100, p_base_100])
		quit(1)
		return
	print("PASS 4: Causal Direction (Water depleted to 0, Day 100 price rose from $%.2f to $%.2f)" % [
		p_base_100, p_shock_100
	])

	# --------------------------------------------------------------------------
	# 檢驗 5: 局部性 (Locality - 乾井在衝擊初期不受直接波及)
	# --------------------------------------------------------------------------
	# Day 40 (衝擊發生 10 天後)，乾井的水與燃料依然運作
	var dw_w40: int = shock_records[40]["dw_water"]
	var dw_f40: int = shock_records[40]["dw_fuel"]
	if dw_w40 < 20 or dw_f40 < 40:
		print("FAIL: Dry Well collapsed prematurely from non-local shock at Day 40!")
		quit(1)
		return
	print("PASS 5: Locality Verified (Dry Well sustained at Day 40: Water %d, Fuel %d)" % [dw_w40, dw_f40])

	print("================================================================================")
	print("ALL S2-A / S2-B ACCEPTANCE CHECKS PASSED!")
	print("================================================================================")
	quit(0)
