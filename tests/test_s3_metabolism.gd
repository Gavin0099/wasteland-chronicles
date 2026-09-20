extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S3-A POPULATION METABOLISM TEST SUITE             ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE A1: Legacy Consumption Equivalence (需求唯一來源驗證)
	# --------------------------------------------------------------------------
	print("\n--- [GATE A1] Legacy Consumption Equivalence ---")
	var world_calibrated := S1WorldData.create_s1_world()

	var nh: SettlementState = world_calibrated.get_settlement(&"settlement:new_hope")
	var gv: SettlementState = world_calibrated.get_settlement(&"settlement:gray_valley")
	var dw: SettlementState = world_calibrated.get_settlement(&"settlement:dry_well")

	# 驗證新希望 (Pop 120, water_rate 0.05, food_rate 1/30)
	if nh.consumption.water != 6 or nh.consumption.food != 4:
		print("FAIL A1: New Hope consumption mismatch! Water: %d (exp 6), Food: %d (exp 4)" % [nh.consumption.water, nh.consumption.food])
		quit(1)
		return

	# 驗證灰谷 (Pop 100, water_rate 0.05, food_rate 0.04)
	if gv.consumption.water != 5 or gv.consumption.food != 4:
		print("FAIL A1: Gray Valley consumption mismatch! Water: %d (exp 5), Food: %d (exp 4)" % [gv.consumption.water, gv.consumption.food])
		quit(1)
		return

	# 驗證乾井 (Pop 80, water_rate 0.05, food_rate 0.05)
	if dw.consumption.water != 4 or dw.consumption.food != 4:
		print("FAIL A1: Dry Well consumption mismatch! Water: %d (exp 4), Food: %d (exp 4)" % [dw.consumption.water, dw.consumption.food])
		quit(1)
		return

	# 驗證無聚落身份特判 (Architectural Invariant: 任意聚落更動人口皆按同一公式推導)
	var test_custom_settlement := SettlementState.new(&"settlement:custom", "Custom Camp")
	test_custom_settlement.set_population_and_rates(200, 0.05, 0.04, 0, 0)
	if test_custom_settlement.consumption.water != 10 or test_custom_settlement.consumption.food != 8:
		print("FAIL A1: Custom settlement failed dynamic demand calculation! Water: %d, Food: %d" % [
			test_custom_settlement.consumption.water, test_custom_settlement.consumption.food
		])
		quit(1)
		return

	print("PASS GATE A1: Legacy Consumption Equivalence Verified across all settlements.")

	# --------------------------------------------------------------------------
	# GATE A2: 100-Day Shadow Run (經濟投影完全一致性)
	# --------------------------------------------------------------------------
	print("\n--- [GATE A2] 100-Day Shadow Run (Legacy vs Population) ---")
	# 建立純硬編碼世界 (Legacy: population = 0, 保持原始寫死 consumption)
	var world_legacy := S1WorldData.create_s1_world()
	for s_id in world_legacy.settlements:
		var s: SettlementState = world_legacy.settlements[s_id]
		s.population = 0 # 不使用人口計算，維持硬編碼消費 (NH 6/4, GV 5/4, DW 4/4)
		s.reference_population = 0

	# 建立人口推導世界 (Population: calibrated)
	var world_pop := S1WorldData.create_s1_world()

	for day in range(1, 101):
		engine.tick(world_legacy)
		engine.tick(world_pop)

		# 比較每日經濟投影 (庫存與價格完全一致)
		for s_id in [&"settlement:new_hope", &"settlement:gray_valley", &"settlement:dry_well"]:
			var s_leg: SettlementState = world_legacy.get_settlement(s_id)
			var s_pop: SettlementState = world_pop.get_settlement(s_id)

			for res in [&"water", &"food", &"scrap", &"fuel"]:
				var stock_leg := s_leg.inventory.get_amount(res)
				var stock_pop := s_pop.inventory.get_amount(res)
				if stock_leg != stock_pop:
					print("FAIL A2: Stock diverged at Day %d on %s (%s): Legacy=%d, Pop=%d" % [day, s_id, res, stock_leg, stock_pop])
					quit(1)
					return

				var price_leg := s_leg.get_current_price(res)
				var price_pop := s_pop.get_current_price(res)
				if absf(price_leg - price_pop) > 0.0001:
					print("FAIL A2: Price diverged at Day %d on %s (%s): Legacy=%f, Pop=%f" % [day, s_id, res, price_leg, price_pop])
					quit(1)
					return

		# 比較商隊狀態
		for c_id in [&"caravan:c_hope_gray", &"caravan:c_hope_dry", &"caravan:c_gray_dry"]:
			var c_leg: CaravanState = world_legacy.caravans[c_id]
			var c_pop: CaravanState = world_pop.caravans[c_id]
			if c_leg.days_remaining != c_pop.days_remaining or c_leg.origin_id != c_pop.origin_id or c_leg.destination_id != c_pop.destination_id:
				print("FAIL A2: Caravan %s position diverged at Day %d!" % [c_id, day])
				quit(1)
				return
			for res in [&"water", &"food", &"scrap", &"fuel"]:
				if c_leg.cargo.get_amount(res) != c_pop.cargo.get_amount(res):
					print("FAIL A2: Caravan %s cargo diverged at Day %d!" % [c_id, day])
					quit(1)
					return

	print("PASS GATE A2: 100-Day Shadow Run 100% Bitwise Identical to Legacy World.")

	# --------------------------------------------------------------------------
	# GATE A3: Population Sensitivity (Up: 灰谷人口調增至 120, +20%)
	# --------------------------------------------------------------------------
	print("\n--- [GATE A3] Population Sensitivity Up (+20%) ---")
	var world_up := S1WorldData.create_s1_world()
	var gv_up: SettlementState = world_up.get_settlement(&"settlement:gray_valley")
	gv_up.set_population_and_rates(120, 0.05, 0.04, 4, 2)
	# 水需求應自 5 增至 6
	if gv_up.consumption.water != 6:
		print("FAIL A3: Demand did not scale up proportionally! Water demand: %d (exp 6)" % gv_up.consumption.water)
		quit(1)
		return

	for day in range(1, 41):
		engine.tick(world_up)

	# 比較灰谷水庫存：需求增加 20%，庫存應低於或等於基準組
	var gv_base_30: SettlementState = world_pop.get_settlement(&"settlement:gray_valley")
	print("  Day 40 Gray Valley Water (Base Pop 100): %d | (Pop 120 Up): %d" % [gv_base_30.inventory.water, gv_up.inventory.water])
	if gv_up.inventory.water > gv_base_30.inventory.water:
		print("FAIL A3: Increased population unexpectedly resulted in higher stock!")
		quit(1)
		return
	print("PASS GATE A3: Population Sensitivity Up Verified (Water demand scaled 5 -> 6, faster depletion).")

	# --------------------------------------------------------------------------
	# GATE A4: Population Sensitivity Down (-20%)
	# --------------------------------------------------------------------------
	print("\n--- [GATE A4] Population Sensitivity Down (-20%) ---")
	var world_down := S1WorldData.create_s1_world()
	var gv_down: SettlementState = world_down.get_settlement(&"settlement:gray_valley")
	gv_down.set_population_and_rates(80, 0.05, 0.04, 4, 2)
	# 水需求應自 5 降至 4，糧食自 4 降至 3 (80 * 0.04 = 3.2 -> 3)
	if gv_down.consumption.water != 4 or gv_down.consumption.food != 3:
		print("FAIL A4: Demand did not scale down! Water: %d (exp 4), Food: %d (exp 3)" % [gv_down.consumption.water, gv_down.consumption.food])
		quit(1)
		return

	for day in range(1, 41):
		engine.tick(world_down)

	print("  Day 40 Gray Valley Water (Base Pop 100): %d | (Pop 80 Down): %d" % [gv_base_30.inventory.water, gv_down.inventory.water])
	if gv_down.inventory.water < gv_base_30.inventory.water:
		print("FAIL A4: Decreased population unexpectedly resulted in lower stock!")
		quit(1)
		return
	print("PASS GATE A4: Population Sensitivity Down Verified (Water demand scaled 5 -> 4, Food 4 -> 3, pressure relieved).")

	# --------------------------------------------------------------------------
	# GATE A5: Determinism Replay & Invariants Check
	# --------------------------------------------------------------------------
	print("\n--- [GATE A5] Determinism & Invariants ---")
	var world_replay_1 := S1WorldData.create_s1_world()
	var world_replay_2 := S1WorldData.create_s1_world()

	for day in range(1, 101):
		engine.tick(world_replay_1)
		engine.tick(world_replay_2)

	var hash_1 := world_replay_1.to_canonical_json().sha256_text()
	var hash_2 := world_replay_2.to_canonical_json().sha256_text()

	if hash_1 != hash_2:
		print("FAIL A5: Determinism replay failed! Hash 1: %s, Hash 2: %s" % [hash_1, hash_2])
		quit(1)
		return
	print("  SHA-256 (Day 100 with Population): %s" % hash_1)

	var inv_err := engine.validate_invariants(world_replay_1)
	if inv_err != "":
		print("FAIL A5: Invariant violated: ", inv_err)
		quit(1)
		return
	print("PASS GATE A5: Determinism Replay & Invariants 100% Verified.")

	print("\n================================================================================")
	print("ALL S3-A ACCEPTANCE GATES (A1 ~ A5) PASSED!")
	print("================================================================================")
	quit(0)
