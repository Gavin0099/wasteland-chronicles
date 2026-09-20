extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S3-B BASIC NEEDS PRESSURE TEST SUITE             ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE B1: Demand Accounting (requested == fulfilled + unmet, all >= 0)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B1] Demand Accounting Equation Verification ---")
	var world_b1 := S1WorldData.create_s1_world()
	for day in range(1, 31):
		engine.tick(world_b1)
		for s_id in world_b1.settlements:
			var s: SettlementState = world_b1.settlements[s_id]
			for res in ["water", "food"]:
				var o: Dictionary = s.last_need_outcomes[res]
				var req: int = o["requested"]
				var ful: int = o["fulfilled"]
				var unm: int = o["unmet"]
				if req < 0 or ful < 0 or unm < 0:
					print("FAIL B1: Negative accounting values at Day %d on %s (%s): req=%d, ful=%d, unm=%d" % [day, s.id, res, req, ful, unm])
					quit(1)
					return
				if req != ful + unm:
					print("FAIL B1: Accounting broken at Day %d on %s (%s): %d != %d + %d" % [day, s.id, res, req, ful, unm])
					quit(1)
					return
	print("PASS GATE B1: Demand Accounting strictly holds across all settlements (requested == fulfilled + unmet, all >= 0).")

	# --------------------------------------------------------------------------
	# GATE B2: No False Pressure on Stock == 0 (零庫存無偽短缺壓力)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B2] No False Pressure When Needs Are Fully Met ---")
	var world_b2 := WorldState.new()
	var test_camp := SettlementState.new(&"settlement:camp", "Isolated Camp")
	test_camp.set_population_and_rates(100, 0.05, 0.04, 0, 0)
	# 初始庫存恰好等於今日消耗量：水 5, 糧 4
	test_camp.inventory.water = 5
	test_camp.inventory.food = 4
	test_camp.water_pressure = 0.0
	test_camp.food_pressure = 0.0
	world_b2.add_settlement(test_camp)

	engine.tick(world_b2)

	# 消耗後庫存均為 0，但全數滿足 (fulfilled == 5, unmet == 0)
	if test_camp.inventory.water != 0 or test_camp.inventory.food != 0:
		print("FAIL B2: Inventory was not fully consumed! Water: %d, Food: %d" % [test_camp.inventory.water, test_camp.inventory.food])
		quit(1)
		return
	var w_out: Dictionary = test_camp.last_need_outcomes["water"]
	var f_out: Dictionary = test_camp.last_need_outcomes["food"]
	if w_out["unmet"] != 0 or f_out["unmet"] != 0:
		print("FAIL B2: Unmet recorded unexpectedly! Unmet water: %d, food: %d" % [w_out["unmet"], f_out["unmet"]])
		quit(1)
		return
	if test_camp.water_pressure > 0.0 or test_camp.food_pressure > 0.0:
		print("FAIL B2: False pressure accumulated when all needs were met! Water press: %f, Food press: %f" % [
			test_camp.water_pressure, test_camp.food_pressure
		])
		quit(1)
		return
	print("PASS GATE B2: No False Pressure on Stock == 0 (Inventory = 0, fulfilled = 100%, unmet = 0, pressure = 0.0).")

	# --------------------------------------------------------------------------
	# GATE B3: Accumulation Under Sustained Shortage (持續短缺壓力單調不減)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B3] Pressure Accumulation Under Supply Shock ---")
	var world_b3 := S1WorldData.create_s1_world()
	var prev_pressure: float = 0.0
	var began_unmet: bool = false

	for day in range(1, 61):
		if day == 30:
			engine.destroy_caravan(world_b3, &"caravan:c_hope_gray", day)
		engine.tick(world_b3)
		var gv: SettlementState = world_b3.get_settlement(&"settlement:gray_valley")
		var o: Dictionary = gv.last_need_outcomes["water"]

		if o["unmet"] > 0:
			began_unmet = true
			if gv.water_pressure < prev_pressure:
				print("FAIL B3: Water pressure decreased despite unmet > 0 at Day %d! (%f < %f)" % [day, gv.water_pressure, prev_pressure])
				quit(1)
				return
		prev_pressure = gv.water_pressure

	var gv_final: SettlementState = world_b3.get_settlement(&"settlement:gray_valley")
	print("  Gray Valley Day 60 Water Pressure: %f (began_unmet: %s)" % [gv_final.water_pressure, began_unmet])
	if not began_unmet or gv_final.water_pressure != 100.0:
		print("FAIL B3: Pressure did not reach 100 ceiling under sustained unmet! Got: %f" % gv_final.water_pressure)
		quit(1)
		return
	print("PASS GATE B3: Pressure Accumulation Verified (Monotonically non-decreasing under unmet > 0, reached 100.0).")

	# --------------------------------------------------------------------------
	# GATE B4: Severity Sensitivity (嚴重度敏感性: 100% unmet vs 40% unmet)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B4] Severity Sensitivity (100% vs 40% Unmet) ---")
	var camp_severe := SettlementState.new(&"settlement:severe", "Severe Camp")
	camp_severe.set_population_and_rates(100, 0.05, 0.04, 0, 0)
	camp_severe.inventory.water = 0 # 0% fulfilled, 100% unmet

	var camp_mild := SettlementState.new(&"settlement:mild", "Mild Camp")
	camp_mild.set_population_and_rates(100, 0.05, 0.04, 0, 0)
	camp_mild.inventory.water = 3 # 3 fulfilled, 2 unmet (40% unmet)

	var world_b4 := WorldState.new()
	world_b4.add_settlement(camp_severe)
	world_b4.add_settlement(camp_mild)

	engine.tick(world_b4)

	print("  Severe Camp (100%% unmet) Day 1 Water Pressure: %f" % camp_severe.water_pressure)
	print("  Mild Camp   ( 40%% unmet) Day 1 Water Pressure: %f" % camp_mild.water_pressure)

	if absf(camp_severe.water_pressure - 25.0) > 0.01:
		print("FAIL B4: Severe camp did not gain expected 25.0 pressure! Got: %f" % camp_severe.water_pressure)
		quit(1)
		return
	if absf(camp_mild.water_pressure - 10.0) > 0.01:
		print("FAIL B4: Mild camp did not gain expected 10.0 pressure! Got: %f" % camp_mild.water_pressure)
		quit(1)
		return
	print("PASS GATE B4: Severity Sensitivity Verified (100% unmet gains 25.0 vs 40% unmet gains 10.0).")

	# --------------------------------------------------------------------------
	# GATE B5: Physical Recovery (唯有實體到貨滿足需求後壓力才下降)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B5] Physical Recovery Latency Verification ---")
	var world_b5 := S1WorldData.create_s1_world()
	var gv_history: Dictionary = {}

	for day in range(1, 75):
		if day == 30:
			engine.destroy_caravan(world_b5, &"caravan:c_hope_gray", day)
		elif day == 60:
			engine.restore_caravan(world_b5, &"caravan:c_hope_gray", day, &"settlement:new_hope", &"settlement:gray_valley")
		engine.tick(world_b5)
		var gv: SettlementState = world_b5.get_settlement(&"settlement:gray_valley")
		var w_o: Dictionary = gv.last_need_outcomes["water"]
		gv_history[day] = {
			"pressure": gv.water_pressure,
			"stock_before": w_o["stock_before"],
			"stock_after": w_o["stock_after"],
			"requested": w_o["requested"],
			"fulfilled": w_o["fulfilled"],
			"unmet": w_o["unmet"],
			"evening_stock": gv.inventory.water
		}

	# Day 60: 修路指令下達，但車隊在途，當天 Phase 1 依然 unmet，日末壓力依然 100.0
	if gv_history[60]["pressure"] < 100.0:
		print("FAIL B5: Pressure dropped prematurely on Day 60 when route was only repaired! Got: %f" % gv_history[60]["pressure"])
		quit(1)
		return

	# Day 61: 車隊在途，日末壓力依然 100.0
	if gv_history[61]["pressure"] < 100.0:
		print("FAIL B5: Pressure dropped prematurely on Day 61 in transit! Got: %f" % gv_history[61]["pressure"])
		quit(1)
		return

	# Day 62: 車隊於 Phase 5 傍晚進城 (入庫 23 單位水)。但當天清晨 Phase 1 依然 unmet，壓力依然 100.0
	if gv_history[62]["pressure"] < 100.0 or gv_history[62]["evening_stock"] <= 0:
		print("FAIL B5: Day 62 delivery anomaly! Stock: %d, Pressure: %f" % [gv_history[62]["evening_stock"], gv_history[62]["pressure"]])
		quit(1)
		return

	# Day 63: Phase 1 清晨有水！fulfilled = 5, unmet = 0！壓力首次自 100.0 下降！
	var p63: float = gv_history[63]["pressure"]
	if p63 >= 100.0 or absf(p63 - 85.0) > 0.01:
		print("FAIL B5: Pressure did not recover after first physical fulfillment on Day 63! Got: %f" % p63)
		quit(1)
		return

	print("  Day 60 Repair Day: Stock = 0, Pressure = %.2f (Repair != Water)" % gv_history[60]["pressure"])
	print("  Day 62 Arrival Day: Evening Stock = %d, Pressure = %.2f" % [gv_history[62]["evening_stock"], gv_history[62]["pressure"]])
	print("  Day 63 First Morning Drunk: Fulfilled = %d, Pressure = %.2f (Recovered by 15.0!)" % [
		gv_history[63]["fulfilled"], p63
	])
	print("PASS GATE B5: Physical Recovery Verified (Pressure drops ONLY upon actual physical fulfillment).")

	# --------------------------------------------------------------------------
	# GATE B6: Shadow Non-Interference (壓力僅為觀測量，經濟投影 100% 等價)
	# --------------------------------------------------------------------------
	print("\n--- [GATE B6] Shadow Non-Interference Verification ---")
	# 運行雙軌世界：World 1 正常計算壓力；World 2 在 Phase 1 結束後強制清零壓力
	# 檢驗無論 pressure 為何值，100 天內所有經濟投影 (庫存、價格、商隊負載、位置、生產) 完全 bitwise identical!
	var world_p1 := S1WorldData.create_s1_world()
	var world_p2 := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_p1, &"caravan:c_hope_gray", day)
			engine.destroy_caravan(world_p2, &"caravan:c_hope_gray", day)

		engine.tick(world_p1)

		# 在 world_p2 中手動隨機或強制清零壓力，證明壓力不對世界產生任何回饋
		for s_id in world_p2.settlements:
			var s: SettlementState = world_p2.settlements[s_id]
			s.water_pressure = 0.0
			s.food_pressure = 0.0
		engine.tick(world_p2)

		# 比較所有聚落之庫存與價格
		for s_id in world_p1.settlements:
			var s1: SettlementState = world_p1.settlements[s_id]
			var s2: SettlementState = world_p2.settlements[s_id]
			for res in ["water", "food", "scrap", "fuel"]:
				if s1.inventory.get_amount(res) != s2.inventory.get_amount(res):
					print("FAIL B6: Stock diverged on Day %d, %s %s!" % [day, s_id, res])
					quit(1)
					return
				if absf(s1.get_current_price(res) - s2.get_current_price(res)) > 0.0001:
					print("FAIL B6: Price diverged on Day %d, %s %s!" % [day, s_id, res])
					quit(1)
					return
			if s1.population != s2.population:
				print("FAIL B6: Population diverged on Day %d!" % day)
				quit(1)
				return

		# 比較所有商隊之在途位置與貨物
		for c_id in world_p1.caravans:
			var c1: CaravanState = world_p1.caravans[c_id]
			var c2: CaravanState = world_p2.caravans[c_id]
			if c1.days_remaining != c2.days_remaining or c1.origin_id != c2.origin_id or c1.destination_id != c2.destination_id:
				print("FAIL B6: Caravan %s trajectory diverged on Day %d!" % [c_id, day])
				quit(1)
				return
			for res in ["water", "food", "scrap", "fuel"]:
				if c1.cargo.get_amount(res) != c2.cargo.get_amount(res):
					print("FAIL B6: Caravan %s cargo diverged on Day %d!" % [c_id, day])
					quit(1)
					return

	print("PASS GATE B6: Shadow Non-Interference Verified (Economic projection bitwise identical regardless of pressure).")

	# --------------------------------------------------------------------------
	# GATE B7: Determinism Replay & Invariants
	# --------------------------------------------------------------------------
	print("\n--- [GATE B7] Determinism & Invariants Replay ---")
	var replay_a := S1WorldData.create_s1_world()
	var replay_b := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(replay_a, &"caravan:c_hope_gray", day)
			engine.destroy_caravan(replay_b, &"caravan:c_hope_gray", day)
		engine.tick(replay_a)
		engine.tick(replay_b)

	var h_a := replay_a.to_canonical_json().sha256_text()
	var h_b := replay_b.to_canonical_json().sha256_text()

	if h_a != h_b:
		print("FAIL B7: Determinism replay failed! A: %s, B: %s" % [h_a, h_b])
		quit(1)
		return
	print("  SHA-256 (World B Day 100 with Pressure): %s" % h_a)

	var inv_err := engine.validate_invariants(replay_a)
	if inv_err != "":
		print("FAIL B7: Invariant error: ", inv_err)
		quit(1)
		return
	print("PASS GATE B7: Determinism Replay & Invariants 100% Verified.")

	print("\n================================================================================")
	print("ALL S3-B ACCEPTANCE GATES (B1 ~ B7) PASSED!")
	print("================================================================================")
	quit(0)
