extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S3-E LABOR FEEDBACK TEST SUITE                    ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE E1: Baseline Equivalence (When Pop == RefPop, 100% Bitwise Match)
	# --------------------------------------------------------------------------
	print("\n--- [GATE E1] Baseline Equivalence ---")
	var world_e1_labor := S1WorldData.create_s1_world()
	var world_e1_nolabor := S1WorldData.create_s1_world()

	var engine_nolabor := SimulationEngine.new()
	engine_nolabor.enable_labor = false

	# 執行 30 天未受衝擊之常態世界
	for day in range(1, 31):
		engine.tick(world_e1_labor)
		engine_nolabor.tick(world_e1_nolabor)

		for s_id in world_e1_labor.settlements:
			var s_lab: SettlementState = world_e1_labor.settlements[s_id]
			var s_nolab: SettlementState = world_e1_nolabor.settlements[s_id]

			for res in engine.COMMODITIES:
				var inv_lab := s_lab.inventory.get_amount(res)
				var inv_nolab := s_nolab.inventory.get_amount(res)
				if inv_lab != inv_nolab:
					print("FAIL E1: Stock diverged on Day %d, %s (%s): Labor=%d vs NoLabor=%d" % [
						day, s_id, res, inv_lab, inv_nolab
					])
					quit(1)
					return

	print("  Across 30 baseline days, all settlements inventories are 100% identical.")
	print("PASS GATE E1: Baseline Equivalence verified.")

	# -------------------------------------------------------------
	# GATE E2: Population Sensitivity (Scrap Drops Proportionately with Labor Deficit)
	# -------------------------------------------------------------
	print("\n--- [GATE E2] Population Sensitivity ---")
	var world_e2 := S1WorldData.create_s1_world()
	var gv_e2: SettlementState = world_e2.get_settlement(&"settlement:gray_valley")
	# 設定灰谷人口為 50 (基準人口 100，勞動力因子 0.5)
	# 基礎 scrap 產能為 11，半產能為 5.5 / 日
	gv_e2.population = 50
	gv_e2.inventory.scrap = 0
	# 清空其他干擾，僅觀察生產累加 (停用商隊與消耗)
	world_e2.caravans.clear()
	gv_e2.maintenance_scrap = 0
	gv_e2.consumption.scrap = 0

	for day in range(1, 11):
		engine.tick(world_e2)

	# 10 天累計產出：10 * 5.5 = 55 scrap
	if gv_e2.inventory.scrap != 55:
		print("FAIL E2: Population 50 (50%% labor) scrap production mismatch! Expected 55, got %d" % gv_e2.inventory.scrap)
		quit(1)
		return

	print("  Gray Valley Pop 50 / RefPop 100 (Labor Factor 0.5): 10 Days Scrap = %d (Exact 55)" % gv_e2.inventory.scrap)
	print("PASS GATE E2: Population Sensitivity verified.")

	# -------------------------------------------------------------
	# GATE E3: Capacity Ceiling (Pop > RefPop Does NOT Expand Production Beyond 1.0)
	# -------------------------------------------------------------
	print("\n--- [GATE E3] Capacity Ceiling ---")
	var world_e3 := S1WorldData.create_s1_world()
	var nh_e3: SettlementState = world_e3.get_settlement(&"settlement:new_hope")
	# 模擬新希望吸收難民，人口增至 200 (基準人口 120)
	nh_e3.population = 200
	nh_e3.inventory.water = 0
	nh_e3.inventory.food = 0
	world_e3.caravans.clear()
	# 暫時歸零代謝率以單純比對產能
	nh_e3.metabolism_water_rate = 0.0
	nh_e3.metabolism_food_rate = 0.0
	nh_e3.consumption.water = 0
	nh_e3.consumption.food = 0

	for day in range(1, 11):
		engine.tick(world_e3)

	# 基礎產能：water = 14, food = 9
	# 10 天應嚴格產出 140 water, 90 food (絕不因人口暴增而超出上限)
	if nh_e3.inventory.water != 140 or nh_e3.inventory.food != 90:
		print("FAIL E3: Capacity ceiling violated! Expected W:140, F:90, got W:%d, F:%d" % [
			nh_e3.inventory.water, nh_e3.inventory.food
		])
		quit(1)
		return

	print("  New Hope Pop 200 / RefPop 120: 10 Days Water = %d (Cap 140), Food = %d (Cap 90)" % [
		nh_e3.inventory.water, nh_e3.inventory.food
	])
	print("PASS GATE E3: Capacity Ceiling strictly enforced (No infinite scaling).")

	# -------------------------------------------------------------
	# GATE E4: Zero Population Depletion (Pop == 0 Means Zero Industrial Output)
	# -------------------------------------------------------------
	print("\n--- [GATE E4] Zero Population Output Collapse ---")
	var world_e4 := S1WorldData.create_s1_world()
	var gv_e4: SettlementState = world_e4.get_settlement(&"settlement:gray_valley")
	gv_e4.population = 0
	gv_e4.inventory.scrap = 0
	world_e4.caravans.clear()
	gv_e4.maintenance_scrap = 0
	gv_e4.consumption.scrap = 0

	for day in range(1, 11):
		engine.tick(world_e4)

	if gv_e4.inventory.scrap != 0:
		print("FAIL E4: Abandoned settlement produced scrap! Expected 0, got %d" % gv_e4.inventory.scrap)
		quit(1)
		return

	print("  Abandoned Gray Valley (Pop 0): 10 Days Scrap = %d" % gv_e4.inventory.scrap)
	print("PASS GATE E4: Zero Population Output Collapse verified.")

	# -------------------------------------------------------------
	# GATE E5: Deterministic Fractional Credit Accumulator
	# -------------------------------------------------------------
	print("\n--- [GATE E5] Deterministic Fractional Credit Accumulator ---")
	var world_e5 := S1WorldData.create_s1_world()
	var gv_e5: SettlementState = world_e5.get_settlement(&"settlement:gray_valley")
	# 模擬極限殘存 9 人 (labor_factor = 0.09)
	# 基礎產能 11，每日產出 11 * 0.09 = 0.99
	# 若為純 integer floor，每日 0 產出，100 天後為 0
	# 透過小數累加器，100 天產出 99 單位
	gv_e5.population = 9
	gv_e5.inventory.scrap = 0
	world_e5.caravans.clear()
	gv_e5.maintenance_scrap = 0
	gv_e5.consumption.scrap = 0

	for day in range(1, 101):
		engine.tick(world_e5)

	if gv_e5.inventory.scrap != 99:
		print("FAIL E5: Fractional accumulation error! Expected 99 scrap across 100 days, got %d" % gv_e5.inventory.scrap)
		quit(1)
		return

	# 驗證雙軌重跑決定論
	var world_e5_rep := S1WorldData.create_s1_world()
	var gv_e5_rep: SettlementState = world_e5_rep.get_settlement(&"settlement:gray_valley")
	gv_e5_rep.population = 9
	gv_e5_rep.inventory.scrap = 0
	world_e5_rep.caravans.clear()
	gv_e5_rep.maintenance_scrap = 0
	gv_e5_rep.consumption.scrap = 0
	for day in range(1, 101):
		engine.tick(world_e5_rep)

	var hash_e5_a := world_e5.to_canonical_json().sha256_text()
	var hash_e5_b := world_e5_rep.to_canonical_json().sha256_text()
	if hash_e5_a != hash_e5_b:
		print("FAIL E5: Determinism replay mismatch for fractional accumulator!")
		quit(1)
		return

	print("  Pop 9 (0.99 scrap/day): 100 Days Scrap = %d (Exact 99) | Remainder Credit: %.4f" % [
		gv_e5.inventory.scrap, gv_e5.production_credits.get("scrap", 0.0)
	])
	print("PASS GATE E5: Deterministic Fractional Credit Accumulator verified.")

	# --------------------------------------------------------------------------
	# GATE E6: Regional Ripple (Gray Valley Depopulation Starves Regional Scrap)
	# --------------------------------------------------------------------------
	print("\n--- [GATE E6] Regional Supply Chain Ripple ---")
	var world_shock_labor := S1WorldData.create_s1_world()
	var world_shock_nolabor := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_shock_labor, &"caravan:c_hope_gray", day)
			engine_nolabor.destroy_caravan(world_shock_nolabor, &"caravan:c_hope_gray", day)

		engine.tick(world_shock_labor)
		engine_nolabor.tick(world_shock_nolabor)

	var gv_lab: SettlementState = world_shock_labor.get_settlement(&"settlement:gray_valley")
	var gv_nolab: SettlementState = world_shock_nolabor.get_settlement(&"settlement:gray_valley")
	var nh_lab: SettlementState = world_shock_labor.get_settlement(&"settlement:new_hope")
	var nh_nolab: SettlementState = world_shock_nolabor.get_settlement(&"settlement:new_hope")

	print("  Day 100 Gray Valley Population: Labor World = %d | No-Labor World = %d" % [gv_lab.population, gv_nolab.population])
	print("  Day 100 Gray Valley Scrap Stock: Labor World = %d vs No-Labor World = %d" % [gv_lab.inventory.scrap, gv_nolab.inventory.scrap])
	print("  Day 100 New Hope Scrap Stock: Labor World = %d vs No-Labor World = %d" % [nh_lab.inventory.scrap, nh_nolab.inventory.scrap])
	print("  Day 100 New Hope Scrap Price: Labor World = $%.2f vs No-Labor World = $%.2f" % [nh_lab.price_scrap, nh_nolab.price_scrap])

	# 驗證灰谷因人口衰退（剩 9 人）廢料累積大幅減少
	if gv_lab.inventory.scrap >= gv_nolab.inventory.scrap:
		print("FAIL E6: Gray Valley scrap did not drop despite losing 91% of workforce!")
		quit(1)
		return

	# 驗證新希望在勞動力反饋下廢料供應更吃緊，價格更高或庫存更低
	if nh_lab.inventory.scrap > nh_nolab.inventory.scrap:
		print("FAIL E6: New Hope scrap inventory higher under labor shock!")
		quit(1)
		return

	print("PASS GATE E6: Regional Supply Chain Ripple verified (Population collapse backfires on industry).")

	# --------------------------------------------------------------------------
	# GATE E7: Full Invariant & Regression Verification
	# --------------------------------------------------------------------------
	print("\n--- [GATE E7] Full Invariant & Regression Verification ---")
	var inv_err := engine.validate_invariants(world_shock_labor)
	if inv_err != "":
		print("FAIL E7: Invariant violation: %s" % inv_err)
		quit(1)
		return

	# 驗證 100 天重播決定論
	var world_shock_labor_rep := S1WorldData.create_s1_world()
	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_shock_labor_rep, &"caravan:c_hope_gray", day)
		engine.tick(world_shock_labor_rep)

	var hash_main := world_shock_labor.to_canonical_json().sha256_text()
	var hash_rep := world_shock_labor_rep.to_canonical_json().sha256_text()
	if hash_main != hash_rep:
		print("FAIL E7: Replay hash mismatch in labor world!")
		quit(1)
		return

	print("  World B Day 100 SHA-256 with Labor Feedback: %s" % hash_main)
	print("PASS GATE E7: Full Invariant & Determinism Replay verified.")

	print("\n================================================================================")
	print("ALL S3-E ACCEPTANCE GATES (E1 ~ E7) PASSED!")
	print("================================================================================")
	quit(0)
