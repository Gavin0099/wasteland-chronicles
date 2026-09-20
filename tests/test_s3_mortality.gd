extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S3-D MORTALITY TEST SUITE                         ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE D1: No Instant Death on First Unmet Day
	# --------------------------------------------------------------------------
	print("\n--- [GATE D1] No Instant Death on First Unmet Day ---")
	var world_d1 := S1WorldData.create_s1_world()
	var gv_d42_deaths := 0
	var gv_d42_exposure := 0.0

	for day in range(1, 43):
		if day == 30:
			engine.destroy_caravan(world_d1, &"caravan:c_hope_gray", day)
		var evts := engine.tick(world_d1)
		if day == 42:
			var gv: SettlementState = world_d1.get_settlement(&"settlement:gray_valley")
			gv_d42_deaths = gv.cumulative_deaths
			gv_d42_exposure = gv.water_exposure

	if gv_d42_deaths != 0:
		print("FAIL D1: Deaths occurred immediately on first unmet day (Day 42)! Deaths: %d" % gv_d42_deaths)
		quit(1)
		return

	print("  Day 42 (First Water Shortage): Exposure = %.2f, Cumulative Deaths = %d" % [gv_d42_exposure, gv_d42_deaths])
	print("PASS GATE D1: No Instant Death on first unmet day verified.")

	# --------------------------------------------------------------------------
	# GATE D2: Duration Matters (Grace Period Protects Transient Shortages)
	# --------------------------------------------------------------------------
	print("\n--- [GATE D2] Duration Matters & Grace Period ---")
	var world_d2 := S1WorldData.create_s1_world()
	var deaths_before_grace := 0

	for day in range(1, 48):
		if day == 30:
			engine.destroy_caravan(world_d2, &"caravan:c_hope_gray", day)
		engine.tick(world_d2)
		var gv: SettlementState = world_d2.get_settlement(&"settlement:gray_valley")
		if gv.water_exposure <= engine.WATER_EXPOSURE_GRACE_DAYS:
			deaths_before_grace += gv.cumulative_deaths

	if deaths_before_grace != 0:
		print("FAIL D2: Deaths occurred while exposure <= grace period (%f)! Deaths: %d" % [
			engine.WATER_EXPOSURE_GRACE_DAYS, deaths_before_grace
		])
		quit(1)
		return

	print("  Through Day 47 (Water Exposure <= 6.0 Grace Days): Cumulative Deaths = 0")
	print("PASS GATE D2: Duration Matters (Grace period protects transient shortages).")

	# --------------------------------------------------------------------------
	# GATE D3: Migration First (Flight Precedes Death)
	# --------------------------------------------------------------------------
	print("\n--- [GATE D3] Migration First Precedence ---")
	var world_d3 := S1WorldData.create_s1_world()
	var wave1_departed := false
	var deaths_at_wave1 := -1

	for day in range(1, 46):
		if day == 30:
			engine.destroy_caravan(world_d3, &"caravan:c_hope_gray", day)
		var evts := engine.tick(world_d3)
		for evt in evts:
			if evt.type == "REFUGEES_DEPARTED":
				wave1_departed = true
				var gv: SettlementState = world_d3.get_settlement(&"settlement:gray_valley")
				deaths_at_wave1 = gv.cumulative_deaths

	if not wave1_departed or deaths_at_wave1 != 0:
		print("FAIL D3: Migration did not precede mortality! Wave departed: %s, Deaths: %d" % [
			wave1_departed, deaths_at_wave1
		])
		quit(1)
		return

	print("  Day 44 Migration Wave 1 Departed | Deaths at Departure: %d (Flight strictly preceded death)" % deaths_at_wave1)
	print("PASS GATE D3: Migration First precedence strictly verified.")

	# --------------------------------------------------------------------------
	# GATE D4: Migration Floor != Immortality Floor
	# --------------------------------------------------------------------------
	print("\n--- [GATE D4] Migration Floor != Immortality Floor ---")
	var world_d4 := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_d4, &"caravan:c_hope_gray", day)
		engine.tick(world_d4)

	var gv_final: SettlementState = world_d4.get_settlement(&"settlement:gray_valley")
	if gv_final.population >= 10:
		print("FAIL D4: Gray Valley population remained >= 10 despite permanent drought! Pop: %d" % gv_final.population)
		quit(1)
		return

	if gv_final.cumulative_deaths <= 0:
		print("FAIL D4: Zero cumulative deaths despite extreme drought! Deaths: %d" % gv_final.cumulative_deaths)
		quit(1)
		return

	print("  Day 100 Gray Valley Population: %d (< 10 migration floor) | Cumulative Deaths: %d" % [
		gv_final.population, gv_final.cumulative_deaths
	])
	print("PASS GATE D4: Migration Floor != Immortality Floor verified (remaining population can die).")

	# --------------------------------------------------------------------------
	# GATE D5: Population Accounting Invariant (Living + Transit + Deaths == 300)
	# --------------------------------------------------------------------------
	print("\n--- [GATE D5] Population Accounting Invariant Verification ---")
	var world_d5 := S1WorldData.create_s1_world()
	var living_settlements := 0
	var living_transit := 0
	var total_deaths := 0

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_d5, &"caravan:c_hope_gray", day)
		engine.tick(world_d5)

		living_settlements = 0
		total_deaths = 0
		for s_id in world_d5.settlements:
			var s: SettlementState = world_d5.settlements[s_id]
			living_settlements += s.population
			total_deaths += s.cumulative_deaths
		living_transit = 0
		for r_id in world_d5.refugees:
			var r: RefugeePartyState = world_d5.refugees[r_id]
			if r.is_active and not r.is_arrived:
				living_transit += r.headcount

		var total_pop := living_settlements + living_transit + total_deaths
		if total_pop != 300:
			print("FAIL D5: Population accounting broken at Day %d! Settlements: %d, Transit: %d, Deaths: %d, Total: %d" % [
				day, living_settlements, living_transit, total_deaths, total_pop
			])
			quit(1)
			return

	print("  100-Day Population Equation strictly held on EVERY tick: Living (%d) + Transit (%d) + Deaths (%d) == 300" % [
		living_settlements, living_transit, total_deaths
	])
	print("PASS GATE D5: Population Accounting Invariant verified.")

	# --------------------------------------------------------------------------
	# GATE D6: Immediate Recovery Stops Mortality (Day 62 Arrival Semantics)
	# --------------------------------------------------------------------------
	print("\n--- [GATE D6] Immediate Recovery Stops Mortality ---")
	var world_d6 := S1WorldData.create_s1_world()
	var deaths_at_recovery := -1
	var deaths_at_day_100 := -1

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_d6, &"caravan:c_hope_gray", day)
		elif day == 60:
			engine.restore_caravan(world_d6, &"caravan:c_hope_gray", day, &"settlement:new_hope", &"settlement:gray_valley")
		engine.tick(world_d6)

		if day == 62:
			# Day 62 傍晚實體水車到貨入庫 (Axiom 9: 60 + 3 - 1 = 62)
			var gv: SettlementState = world_d6.get_settlement(&"settlement:gray_valley")
			if gv.inventory.water <= 0:
				print("FAIL D6: Caravan did not arrive at Gray Valley on Day 62 evening!")
				quit(1)
				return
		elif day == 63:
			# Day 63 晨間喝水 (unmet == 0)；此時 exposure 仍高達 ~15.0 > 6.0，但因 unmet == 0，死亡立即終止！
			var gv: SettlementState = world_d6.get_settlement(&"settlement:gray_valley")
			var w_out: Dictionary = gv.last_need_outcomes["water"]
			if w_out["unmet"] != 0:
				print("FAIL D6: Water need unmet on Day 63 after delivery! Unmet: %d" % w_out["unmet"])
				quit(1)
				return
			deaths_at_recovery = gv.cumulative_deaths
			# 驗證此時 exposure 確實高於寬限期，證明是 unmet == 0 發揮了救贖阻斷
			if gv.water_exposure <= engine.WATER_EXPOSURE_GRACE_DAYS:
				print("FAIL D6: Exposure was not above grace period to test unmet == 0 protection! Exposure: %f" % gv.water_exposure)
				quit(1)
				return
		elif day == 100:
			var gv: SettlementState = world_d6.get_settlement(&"settlement:gray_valley")
			deaths_at_day_100 = gv.cumulative_deaths

	if deaths_at_day_100 != deaths_at_recovery:
		print("FAIL D6: Deaths continued after supply recovery! At Recovery: %d, Day 100: %d" % [
			deaths_at_recovery, deaths_at_day_100
		])
		quit(1)
		return

	print("  Day 62 Evening Arrival (Axiom 9 Verified)")
	print("  Day 63 Water Unmet = 0 while Exposure = High | Deaths: %d" % deaths_at_recovery)
	print("  Day 100 Post-Recovery Deaths: %d (Zero new deaths after recovery!)" % deaths_at_day_100)
	print("PASS GATE D6: Immediate Recovery Stops Mortality strictly verified.")

	# --------------------------------------------------------------------------
	# GATE D7: Determinism Replay & Invariants
	# --------------------------------------------------------------------------
	print("\n--- [GATE D7] Determinism Replay & Invariants ---")
	var eng_a := SimulationEngine.new()
	var eng_b := SimulationEngine.new()
	var run_a := S1WorldData.create_s1_world()
	var run_b := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			eng_a.destroy_caravan(run_a, &"caravan:c_hope_gray", day)
			eng_b.destroy_caravan(run_b, &"caravan:c_hope_gray", day)
		eng_a.tick(run_a)
		eng_b.tick(run_b)

	var sha_a := run_a.to_canonical_json().sha256_text()
	var sha_b := run_b.to_canonical_json().sha256_text()

	if sha_a != sha_b:
		print("FAIL D7: Determinism mismatch! A: %s, B: %s" % [sha_a, sha_b])
		quit(1)
		return

	print("  World B Day 100 SHA-256 with Mortality: %s" % sha_a)
	print("PASS GATE D7: Bitwise Determinism Replay verified.")

	print("\n================================================================================")
	print("ALL S3-D ACCEPTANCE GATES (D1 ~ D7) PASSED!")
	print("================================================================================")
	quit(0)
