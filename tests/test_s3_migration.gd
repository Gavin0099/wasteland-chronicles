extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S3-C REFUGEE MIGRATION TEST SUITE                 ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE C1: Conservation of Population (全域人口在每一 Tick 嚴格守恆)
	# --------------------------------------------------------------------------
	print("\n--- [GATE C1] Conservation of World Population ---")
	var world_c1 := S1WorldData.create_s1_world()
	var initial_total_pop := 0
	for s_id in world_c1.settlements:
		initial_total_pop += world_c1.settlements[s_id].population

	var conservation_passed := true
	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_c1, &"caravan:c_hope_gray", day)
		engine.tick(world_c1)

		var current_total := 0
		for s_id in world_c1.settlements:
			current_total += world_c1.settlements[s_id].population
		for r_id in world_c1.refugees:
			var r: RefugeePartyState = world_c1.refugees[r_id]
			if r.is_active and not r.is_arrived:
				current_total += r.headcount

		if current_total != initial_total_pop:
			print("FAIL C1: Population conservation broken on Day %d! Current: %d, Expected: %d" % [
				day, current_total, initial_total_pop
			])
			conservation_passed = false
			quit(1)
			return

	print("  Initial World Population: %d | Day 100 World Population: %d" % [initial_total_pop, initial_total_pop])
	print("PASS GATE C1: Conservation of Population strictly maintained across all 100 days.")

	# --------------------------------------------------------------------------
	# GATE C2: Migration Trigger Sensitivity & Cooldown
	# --------------------------------------------------------------------------
	print("\n--- [GATE C2] Migration Trigger Sensitivity & Cooldown ---")
	var world_c2 := S1WorldData.create_s1_world()
	var gv_history: Dictionary = {}

	for day in range(1, 55):
		if day == 30:
			engine.destroy_caravan(world_c2, &"caravan:c_hope_gray", day)
		engine.tick(world_c2)
		var gv: SettlementState = world_c2.get_settlement(&"settlement:gray_valley")
		gv_history[day] = {
			"pressure": gv.water_pressure,
			"population": gv.population,
			"refugees_count": world_c2.refugees.size(),
			"cooldown": gv.days_since_last_migration
		}

	# 驗證 Day 43 (壓力 40.0 < 60.0) 前絕對不外移，人口維持 100
	if gv_history[43]["refugees_count"] != 0 or gv_history[43]["population"] != 100:
		print("FAIL C2: Premature migration before threshold! Day 43 refugees: %d, pop: %d" % [
			gv_history[43]["refugees_count"], gv_history[43]["population"]
		])
		quit(1)
		return

	# 驗證 Day 44 (壓力 65.0 >= 60.0) 觸發外移，人口扣減 10% (100 -> 90)，產生第 1 支難民隊
	if gv_history[44]["refugees_count"] != 1 or gv_history[44]["population"] != 90:
		print("FAIL C2: Migration did not trigger on Day 44! Refugees: %d, Pop: %d" % [
			gv_history[44]["refugees_count"], gv_history[44]["population"]
		])
		quit(1)
		return

	# 驗證冷卻：Day 45 (壓力 90.0) 與 Day 46 (壓力 100.0) 雖高於閥值，但在 3 天冷卻期內不得外移
	if gv_history[45]["refugees_count"] != 1 or gv_history[46]["refugees_count"] != 1:
		print("FAIL C2: Migration cooldown violated! Day 45 count: %d, Day 46 count: %d" % [
			gv_history[45]["refugees_count"], gv_history[46]["refugees_count"]
		])
		quit(1)
		return

	# 驗證 Day 47 冷卻屆滿，第 2 次外移觸發 (90 -> 81，外移 9 人，累計 2 支難民隊)
	if gv_history[47]["refugees_count"] != 2 or gv_history[47]["population"] != 81:
		print("FAIL C2: Second wave did not trigger after cooldown on Day 47! Refugees: %d, Pop: %d" % [
			gv_history[47]["refugees_count"], gv_history[47]["population"]
		])
		quit(1)
		return

	print("  Day 43 (Pressure 40.0 < 60.0): Pop = %d, Refugees = %d" % [gv_history[43]["population"], gv_history[43]["refugees_count"]])
	print("  Day 44 (Pressure 65.0 >= 60.0): Pop = %d, Refugees = %d (Wave 1 Departed!)" % [gv_history[44]["population"], gv_history[44]["refugees_count"]])
	print("  Day 45~46 (Cooldown Active): Pop = %d, Refugees = %d (Cooldown Respected)" % [gv_history[46]["population"], gv_history[46]["refugees_count"]])
	print("  Day 47 (Cooldown Expired): Pop = %d, Refugees = %d (Wave 2 Departed!)" % [gv_history[47]["population"], gv_history[47]["refugees_count"]])
	print("PASS GATE C2: Migration Trigger Sensitivity & Cooldown strictly verified.")

	# --------------------------------------------------------------------------
	# GATE C3: Physical In-Transit Travel Semantics (Axiom 9: N + D - 1)
	# --------------------------------------------------------------------------
	print("\n--- [GATE C3] Physical In-Transit Travel Semantics ---")
	var world_c3 := S1WorldData.create_s1_world()
	var party_found: RefugeePartyState = null

	for day in range(1, 48):
		if day == 30:
			engine.destroy_caravan(world_c3, &"caravan:c_hope_gray", day)
		engine.tick(world_c3)

		if day == 44:
			# Day 44: 難民出發，歷經 Phase 4 行進，days_remaining 自 3 -> 2
			var p := world_c3.get_refugee_party(&"refugee:settlement:gray_valley:settlement:new_hope:d44")
			if p == null or p.days_remaining != 2 or not p.is_active or p.is_arrived:
				print("FAIL C3: Party state anomaly on Day 44 departure! Remaining: %d" % (p.days_remaining if p else -1))
				quit(1)
				return
			party_found = p
		elif day == 45:
			# Day 45: 荒原行進第二天，days_remaining 自 2 -> 1
			if party_found.days_remaining != 1 or not party_found.is_active or party_found.is_arrived:
				print("FAIL C3: Party state anomaly on Day 45 in-transit! Remaining: %d" % party_found.days_remaining)
				quit(1)
				return
		elif day == 46:
			# Day 46: 荒原行進第三天，傍晚抵達！Arrival Day = 44 + 3 - 1 = 46!
			if party_found.days_remaining != 0 or party_found.is_active or not party_found.is_arrived:
				print("FAIL C3: Party did not arrive on Day 46! Remaining: %d, Active: %s, Arrived: %s" % [
					party_found.days_remaining, party_found.is_active, party_found.is_arrived
				])
				quit(1)
				return
			# 目的地新希望人口應即刻增長 (120 + 10 = 130)
			var nh: SettlementState = world_c3.get_settlement(&"settlement:new_hope")
			if nh.population != 130:
				print("FAIL C3: Destination population not updated upon arrival! New Hope pop: %d" % nh.population)
				quit(1)
				return

	print("  Departure Day: 44 | Route Days: 3 | Arrival Day: 46 (Exact match: 44 + 3 - 1 = 46)")
	print("  Day 44 Remaining: 2 | Day 45 Remaining: 1 | Day 46 Arrived: true, New Hope Pop: 130")
	print("PASS GATE C3: Axiom 9 Physical Travel Semantics strictly verified.")

	# --------------------------------------------------------------------------
	# GATE C4: Closed-Loop Demand Ripple Effect
	# --------------------------------------------------------------------------
	print("\n--- [GATE C4] Closed-Loop Demand Ripple Effect ---")
	# 抵達新希望後，次日 Day 47 Phase 1 需求重新以新人口 (130) 結算：
	# 原本消耗: round(120 * 0.05) = 6
	# 新消耗:   round(130 * 0.05) = 7 (增長 16.7%)
	var nh47: SettlementState = world_c3.get_settlement(&"settlement:new_hope")
	var water_outcome: Dictionary = nh47.last_need_outcomes["water"]
	if water_outcome["requested"] != 7:
		print("FAIL C4: New Hope water demand did not scale with refugee population! Requested: %d, Expected: 7" % water_outcome["requested"])
		quit(1)
		return

	# 灰谷外移 2 次後 (100 -> 90 -> 81)，Day 48 需求自 5 降至 4
	engine.tick(world_c3) # Day 48
	var gv48: SettlementState = world_c3.get_settlement(&"settlement:gray_valley")
	var gv_water_outcome: Dictionary = gv48.last_need_outcomes["water"]
	if gv_water_outcome["requested"] != 4:
		print("FAIL C4: Gray Valley water demand did not scale down! Requested: %d, Expected: 4" % gv_water_outcome["requested"])
		quit(1)
		return

	print("  New Hope Pop 120 -> 130: Water Demand 6 -> %d (+16.7%%)" % water_outcome["requested"])
	print("  Gray Valley Pop 100 -> 81: Water Demand 5 -> %d (-20.0%%)" % gv_water_outcome["requested"])
	print("PASS GATE C4: Closed-Loop Demand Ripple Effect strictly verified.")

	# --------------------------------------------------------------------------
	# GATE C5: Rational Destination Selection
	# --------------------------------------------------------------------------
	print("\n--- [GATE C5] Rational Destination Selection ---")
	# 灰谷難民評估新希望與乾井：
	# 新希望淨產能水+8/糧+5 (+13)，庫存充足，無壓力
	# 乾井淨產能水-3/糧-3 (-6)，缺水，無盈餘
	# 難民自發湧向綠洲新希望，而非缺水的乾井
	var first_party: RefugeePartyState = world_c3.get_refugee_party(&"refugee:settlement:gray_valley:settlement:new_hope:d44")
	if first_party.destination_id != &"settlement:new_hope":
		print("FAIL C5: Refugees chose irrational destination: %s" % first_party.destination_id)
		quit(1)
		return
	print("  Gray Valley refugees selected destination: %s (Oasis chosen over arid oil well)" % first_party.destination_id)
	print("PASS GATE C5: Rational Destination Selection verified.")

	# --------------------------------------------------------------------------
	# GATE C6: Invariant & State Serialization Consistency
	# --------------------------------------------------------------------------
	print("\n--- [GATE C6] Invariant & State Serialization Consistency ---")
	var copy_world := world_c3.duplicate_state()
	var json_orig := world_c3.to_canonical_json()
	var json_copy := copy_world.to_canonical_json()

	if json_orig != json_copy:
		print("FAIL C6: Canonical JSON mismatch between original and duplicate world!")
		quit(1)
		return

	var inv_msg := engine.validate_invariants(world_c3)
	if inv_msg != "":
		print("FAIL C6: Invariant failure: %s" % inv_msg)
		quit(1)
		return

	print("  State serialization and duplicate identical (Length: %d chars)" % json_orig.length())
	print("PASS GATE C6: Invariant and Serialization consistency 100% verified.")

	# --------------------------------------------------------------------------
	# GATE C7: Determinism Replay & Full Regression Pass
	# --------------------------------------------------------------------------
	print("\n--- [GATE C7] Determinism Replay & Regression Pass ---")
	var engine_a := SimulationEngine.new()
	var engine_b := SimulationEngine.new()
	var run_a := S1WorldData.create_s1_world()
	var run_b := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			engine_a.destroy_caravan(run_a, &"caravan:c_hope_gray", day)
			engine_b.destroy_caravan(run_b, &"caravan:c_hope_gray", day)
		engine_a.tick(run_a)
		engine_b.tick(run_b)

	var sha_a := run_a.to_canonical_json().sha256_text()
	var sha_b := run_b.to_canonical_json().sha256_text()

	if sha_a != sha_b:
		print("FAIL C7: Determinism replay mismatch! A: %s, B: %s" % [sha_a, sha_b])
		quit(1)
		return

	print("  World B Day 100 SHA-256 with Refugee Migration: %s" % sha_a)
	print("PASS GATE C7: Bitwise Determinism Replay 100% verified.")

	print("\n================================================================================")
	print("ALL S3-C ACCEPTANCE GATES (C1 ~ C7) PASSED!")
	print("================================================================================")
	quit(0)
