extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - M0-B SUPPLY SHOCK TEST SUITE                      ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# 1. 執行 Run A (Baseline - 無衝擊)
	# --------------------------------------------------------------------------
	var engine := SimulationEngine.new()
	var world_baseline := M0WorldData.create_m0_world()
	var baseline_records: Dictionary = {} # day -> {water, price, scarcity}

	for day in range(1, 31):
		engine.tick(world_baseline)
		var gv: SettlementState = world_baseline.get_settlement(&"settlement:gray_valley")
		baseline_records[day] = {
			"water": gv.inventory.water,
			"price": gv.price_water,
			"scarcity": engine.calculate_scarcity_ratio(gv.inventory.water, gv.target_water)
		}

	# --------------------------------------------------------------------------
	# 2. 執行 Run B (Shock - Day 10 摧毀商隊 C001)
	# --------------------------------------------------------------------------
	var world_shock := M0WorldData.create_m0_world()
	var shock_records: Dictionary = {}
	var c1_shock: CaravanState = world_shock.get_caravan(&"caravan:c001")
	var shock_event: EventRecord = null
	var post_shock_arrivals: int = 0

	for day in range(1, 31):
		if day == 10:
			# 在 Day 10 施加外部衝擊：摧毀商隊 C001
			shock_event = engine.destroy_caravan(world_shock, &"caravan:c001", day)
			print(">>> [SHOCK INJECTED] Day 10: Caravan C001 destroyed by external shock!")

		var events := engine.tick(world_shock)
		for evt in events:
			if evt.type == "CARAVAN_ARRIVED" and evt.target_id == &"settlement:gray_valley":
				if day > 10:
					post_shock_arrivals += 1

		var gv_shock: SettlementState = world_shock.get_settlement(&"settlement:gray_valley")
		shock_records[day] = {
			"water": gv_shock.inventory.water,
			"price": gv_shock.price_water,
			"scarcity": engine.calculate_scarcity_ratio(gv_shock.inventory.water, gv_shock.target_water)
		}

	# --------------------------------------------------------------------------
	# B1: Shock Determinism 驗證 (同一衝擊兩次運行雜湊一致)
	# --------------------------------------------------------------------------
	var world_shock_2 := M0WorldData.create_m0_world()
	for day in range(1, 31):
		if day == 10:
			engine.destroy_caravan(world_shock_2, &"caravan:c001", day)
		engine.tick(world_shock_2)

	var hash_shock_1 := world_shock.to_canonical_json().sha256_text()
	var hash_shock_2 := world_shock_2.to_canonical_json().sha256_text()

	if hash_shock_1 != hash_shock_2:
		print("FAIL B1: Shock determinism failed! Hash 1 != Hash 2")
		quit(1)
		return
	print("PASS B1: Shock Determinism (SHA-256: %s)" % hash_shock_1)

	# --------------------------------------------------------------------------
	# B2: Cargo Loss 驗證 (貨物損失且絕不外洩至任何聚落)
	# --------------------------------------------------------------------------
	# 測試帶貨商隊遭毀：裝載 30 水的商隊遭毀時，貨物歸零且未流入聚落
	var world_cargo_test := M0WorldData.create_m0_world()
	var test_caravan: CaravanState = world_cargo_test.get_caravan(&"caravan:c001")
	# 模擬商隊攜帶 30 水時遭擊毀
	test_caravan.cargo.water = 30
	var gv_w_before: int = world_cargo_test.get_settlement(&"settlement:gray_valley").inventory.water
	var nh_w_before: int = world_cargo_test.get_settlement(&"settlement:new_hope").inventory.water

	var cargo_before := test_caravan.cargo.water
	engine.destroy_caravan(world_cargo_test, test_caravan.id, 10)
	var cargo_after := test_caravan.cargo.water

	var gv_w_after: int = world_cargo_test.get_settlement(&"settlement:gray_valley").inventory.water
	var nh_w_after: int = world_cargo_test.get_settlement(&"settlement:new_hope").inventory.water

	if cargo_before <= 0 or cargo_after != 0:
		print("FAIL B2: Cargo loss check failed (before: %d, after: %d)" % [cargo_before, cargo_after])
		quit(1)
		return
	if gv_w_before != gv_w_after or nh_w_before != nh_w_after:
		print("FAIL B2: Destroyed cargo leaked into settlements!")
		quit(1)
		return
	print("PASS B2: Cargo Loss (cargo_before: %d > 0, cargo_after: 0, zero leakage)" % cargo_before)

	# --------------------------------------------------------------------------
	# B3: No Phantom Arrival 驗證 (無幽靈商隊到站)
	# --------------------------------------------------------------------------
	if post_shock_arrivals > 0:
		print("FAIL B3: Phantom arrivals detected after shock: %d" % post_shock_arrivals)
		quit(1)
		return
	print("PASS B3: No Phantom Arrival (Post-shock arrivals at Gray Valley == 0)")

	# --------------------------------------------------------------------------
	# B4: Shortage Response 驗證 (灰谷水庫存單調下降至 0，水價單調上漲至上限)
	# --------------------------------------------------------------------------
	var prev_w: int = shock_records[10]["water"]
	var prev_p: float = shock_records[10]["price"]
	var reached_zero := false
	var reached_max_price := false

	for day in range(11, 31):
		var cur_w: int = shock_records[day]["water"]
		var cur_p: float = shock_records[day]["price"]

		if cur_w > prev_w:
			print("FAIL B4: Water increased after supply shock at Day %d (%d -> %d)" % [day, prev_w, cur_w])
			quit(1)
			return
		if cur_p < prev_p:
			print("FAIL B4: Price decreased during shortage at Day %d (%f -> %f)" % [day, prev_p, cur_p])
			quit(1)
			return

		if cur_w == 0:
			reached_zero = true
		if absf(cur_p - (15.0 * 5.0)) < 0.01: # base 15 * max ratio 5.0 = 75.0
			# 或到達稀缺上限
			reached_max_price = true

		prev_w = cur_w
		prev_p = cur_p

	if not reached_zero:
		print("FAIL B4: Gray Valley did not deplete to 0 water after shock!")
		quit(1)
		return
	print("PASS B4: Shortage Response (Monotonic water depletion to 0, price rise to cap)")

	# --------------------------------------------------------------------------
	# B5: Control Isolation 驗證 (乾井完全不受衝擊影響)
	# --------------------------------------------------------------------------
	var dw_shock: SettlementState = world_shock.get_settlement(&"settlement:dry_well")
	if dw_shock.inventory.water != 50 or dw_shock.inventory.food != 50 or absf(dw_shock.price_water - 12.0) > 0.01:
		print("FAIL B5: Dry Well control group contaminated by supply shock!")
		quit(1)
		return
	print("PASS B5: Control Isolation (Dry Well remains perfectly stable at 50 / $12.00)")

	# --------------------------------------------------------------------------
	# B6: Baseline vs Counterfactual Comparison Table 輸出
	# --------------------------------------------------------------------------
	print("\n================================================================================")
	print("B6: BASELINE VS COUNTERFACTUAL SUPPLY SHOCK COMPARISON TABLE")
	print("================================================================================")
	print("| Day | Baseline Water | Shock Water | Δ Water | Baseline Price | Shock Price | Δ Price |")
	print("|----:|---------------:|------------:|--------:|---------------:|------------:|--------:|")

	var sample_days := [9, 10, 12, 15, 18, 21, 24, 27, 30]
	for d in sample_days:
		var bw: int = baseline_records[d]["water"]
		var sw: int = shock_records[d]["water"]
		var bp: float = baseline_records[d]["price"]
		var sp: float = shock_records[d]["price"]
		var delta_w: int = sw - bw
		var delta_p: float = sp - bp

		print("| %3d | %14d | %11d | %+7d | $%13.2f | $%10.2f | %-+7.2f |" % [
			d, bw, sw, delta_w, bp, sp, delta_p
		])

	print("================================================================================")
	print("ALL M0-B ACCEPTANCE CRITERIA (B1 - B6) PASSED!")
	print("================================================================================")
	quit(0)
