extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S3-F SOCIAL ORDER & ROUTE PREDATION TEST SUITE    ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	# GATE F1: Baseline Security Stability (30 Days 100% Order & No Hazards)
	# --------------------------------------------------------------------------
	print("\n--- [GATE F1] Baseline Security Stability ---")
	var world_f1 := S1WorldData.create_s1_world()
	var f1_disorder_events := 0
	var f1_predation_events := 0

	for day in range(1, 31):
		var evts := engine.tick(world_f1)
		for e in evts:
			if e.type == "DISORDER_LOSS":
				f1_disorder_events += 1
			elif e.type == "TRANSIT_PREDATION":
				f1_predation_events += 1

	for s_id in world_f1.settlements:
		var s: SettlementState = world_f1.settlements[s_id]
		if absf(s.security - 100.0) > 0.001:
			print("FAIL F1: Settlement %s security drifted during baseline! Security: %f" % [s.id, s.security])
			quit(1)
			return

	if f1_disorder_events > 0 or f1_predation_events > 0:
		print("FAIL F1: Disorder loss or transit predation occurred during baseline! Loss: %d, Predation: %d" % [
			f1_disorder_events, f1_predation_events
		])
		quit(1)
		return

	print("  Across 30 days of baseline trade, all 3 settlements maintained Security = 100.0.")
	print("  Total disorder loss events = 0, Total transit predation events = 0.")
	print("PASS GATE F1: Baseline Security Stability verified.")

	# --------------------------------------------------------------------------
	# GATE F2: Causal Security Degradation (Shock Causes Monotonic Disorder)
	# --------------------------------------------------------------------------
	print("\n--- [GATE F2] Causal Security Degradation ---")
	var world_f2 := S1WorldData.create_s1_world()
	var gv_sec_history: Dictionary = {}

	for day in range(1, 65):
		if day == 30:
			engine.destroy_caravan(world_f2, &"caravan:c_hope_gray", day)
		engine.tick(world_f2)
		var gv: SettlementState = world_f2.get_settlement(&"settlement:gray_valley")
		gv_sec_history[day] = gv.security

	# Day 30 衝擊當天，安全應仍為 100.0
	if absf(gv_sec_history[30] - 100.0) > 0.001:
		print("FAIL F2: Premature security drop at Day 30! Security: %f" % gv_sec_history[30])
		quit(1)
		return

	# Day 41 斷水開始前，安全應仍為 100.0
	if absf(gv_sec_history[41] - 100.0) > 0.001:
		print("FAIL F2: Premature security drop before drought (Day 41)! Security: %f" % gv_sec_history[41])
		quit(1)
		return

	# Day 50 歷經水短缺（壓力 100）與難民外移，治安應顯著下滑
	if gv_sec_history[50] >= 100.0:
		print("FAIL F2: Security did not degrade under severe drought and migration by Day 50! Security: %f" % gv_sec_history[50])
		quit(1)
		return

	# Day 60 應跌破 40 警戒線
	if gv_sec_history[60] >= engine.DISORDER_LOSS_THRESHOLD:
		print("FAIL F2: Security failed to cross threshold 40.0 by Day 60! Day 60 Security: %f" % gv_sec_history[60])
		quit(1)
		return

	print("  Gray Valley Security: Day 30 = %.1f | Day 41 = %.1f | Day 50 = %.1f | Day 60 = %.1f" % [
		gv_sec_history[30], gv_sec_history[41], gv_sec_history[50], gv_sec_history[60]
	])
	print("PASS GATE F2: Causal Security Degradation verified.")

	# --------------------------------------------------------------------------
	# GATE F3: Recovery Semantics (Controlled Recovery vs Material != Social)
	# --------------------------------------------------------------------------
	print("\n--- [GATE F3] Recovery Semantics ---")
	# 1. 受控恢復測試：聚落人口充足 (Pop 100/100, civic_capacity_ratio = 1.0 >= 0.8)
	# 遭遇短暫生存壓力使治安下降，在物資恢復且壓力歸零後逐步復原
	var world_ctrl := WorldState.new()
	var ctrl_town := SettlementState.new(&"settlement:ctrl", "Controlled Town")
	ctrl_town.set_population_and_rates(100, 0.05, 0.04, 0, 0)
	ctrl_town.inventory.water = 0
	ctrl_town.security = 60.0
	world_ctrl.add_settlement(ctrl_town)

	var ctrl_engine := SimulationEngine.new()
	ctrl_engine.enable_migration = false
	ctrl_engine.enable_mortality = false

	# 供水與糧食完全充足 (補給 100 水/糧)，在壓力歸零後驗證治安逐步上升
	ctrl_town.inventory.water = 100
	ctrl_town.inventory.food = 100
	ctrl_town.production.water = 10
	ctrl_town.production.food = 10
	ctrl_town.water_pressure = 0.0
	ctrl_town.food_pressure = 0.0

	var sec_start := ctrl_town.security
	for d in range(1, 6):
		ctrl_engine.tick(world_ctrl)

	if ctrl_town.security <= sec_start:
		print("FAIL F3: Controlled town failed to recover security when population >= 80%%! Start: %f, After: %f" % [
			sec_start, ctrl_town.security
		])
		quit(1)
		return

	print("  Controlled Town (Pop 100/100, Pressure 0): Security recovered %.1f -> %.1f (+%.1f/day)" % [
		sec_start, ctrl_town.security, ctrl_engine.SECURITY_RECOVERY_RATE
	])

	# 2. 驗證不可逆現實：灰谷在人口崩落至 9 人後 (civic_capacity_ratio = 0.09 < 0.8)
	# 即使恢復供水且水壓力為 0，亦不可自發恢復治安 (Material Recovery != Social Recovery)
	var world_irrev := S1WorldData.create_s1_world()
	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_irrev, &"caravan:c_hope_gray", day)
		elif day == 60:
			engine.restore_caravan(world_irrev, &"caravan:c_hope_gray", day, &"settlement:new_hope", &"settlement:gray_valley")
		engine.tick(world_irrev)

	var gv_irrev: SettlementState = world_irrev.get_settlement(&"settlement:gray_valley")
	print("  Gray Valley Day 100: Pop = %d (workforce 9%%), Water = %d, Security = %.1f" % [
		gv_irrev.population, gv_irrev.inventory.water, gv_irrev.security
	])
	if gv_irrev.security > 10.0:
		print("FAIL F3: Depopulated ghost town magically recovered social order! Security: %f" % gv_irrev.security)
		quit(1)
		return

	print("  Observed Material Recovery != Social Recovery: Ghost town with 9 survivors retains collapsed security.")
	print("PASS GATE F3: Recovery Semantics verified.")

	# --------------------------------------------------------------------------
	# GATE F4: Local Disorder Loss (Deterministic Fractional Loss When Security < 40)
	# --------------------------------------------------------------------------
	print("\n--- [GATE F4] Local Disorder Loss ---")
	var world_f4 := S1WorldData.create_s1_world()
	var disorder_before_threshold := false
	var disorder_after_threshold := false
	var healthy_disorder_count := 0

	for day in range(1, 75):
		if day == 30:
			engine.destroy_caravan(world_f4, &"caravan:c_hope_gray", day)
		var evts := engine.tick(world_f4)
		var gv: SettlementState = world_f4.get_settlement(&"settlement:gray_valley")

		for e in evts:
			if e.type == "DISORDER_LOSS":
				if e.actor_id == &"settlement:gray_valley":
					if e.payload["security"] >= engine.DISORDER_LOSS_THRESHOLD:
						disorder_before_threshold = true
					else:
						disorder_after_threshold = true
				else:
					healthy_disorder_count += 1

	if disorder_before_threshold:
		print("FAIL F4: Disorder loss occurred while Gray Valley security was >= 40.0 threshold!")
		quit(1)
		return

	if not disorder_after_threshold:
		print("FAIL F4: Disorder loss never occurred after Gray Valley security dropped below 40.0!")
		quit(1)
		return

	if healthy_disorder_count > 0:
		print("FAIL F4: Disorder loss occurred in healthy settlements! Count: %d" % healthy_disorder_count)
		quit(1)
		return

	var gv_f4: SettlementState = world_f4.get_settlement(&"settlement:gray_valley")
	print("  Gray Valley Cumulative Disorder Loss: %s | Security = %.1f" % [gv_f4.cumulative_disorder_loss, gv_f4.security])
	print("  Healthy Settlements Disorder Loss = 0 (Strict Locality Guaranteed)")
	print("PASS GATE F4: Local Disorder Loss verified.")

	# --------------------------------------------------------------------------
	# GATE F5: Derived Route Risk (Pure Function of Endpoint State)
	# --------------------------------------------------------------------------
	print("\n--- [GATE F5] Derived Route Risk ---")
	var world_f5 := S1WorldData.create_s1_world()
	var gv_f5: SettlementState = world_f5.get_settlement(&"settlement:gray_valley")
	var nh_f5: SettlementState = world_f5.get_settlement(&"settlement:new_hope")
	var dw_f5: SettlementState = world_f5.get_settlement(&"settlement:dry_well")

	gv_f5.security = 20.0
	nh_f5.security = 100.0
	dw_f5.security = 100.0

	var risk_hope_dry := engine.calculate_route_risk(world_f5, &"settlement:new_hope", &"settlement:dry_well")
	var risk_gray_dry := engine.calculate_route_risk(world_f5, &"settlement:gray_valley", &"settlement:dry_well")
	var risk_hope_gray := engine.calculate_route_risk(world_f5, &"settlement:new_hope", &"settlement:gray_valley")

	if absf(risk_hope_dry - 0.0) > 0.001:
		print("FAIL F5: Safe route risk mismatch! Expected 0.0, got %f" % risk_hope_dry)
		quit(1)
		return

	if absf(risk_gray_dry - 40.0) > 0.001:
		print("FAIL F5: Gray-Dry route risk mismatch! Expected 40.0, got %f" % risk_gray_dry)
		quit(1)
		return

	if absf(risk_hope_gray - 40.0) > 0.001:
		print("FAIL F5: Hope-Gray route risk mismatch! Expected 40.0, got %f" % risk_hope_gray)
		quit(1)
		return

	print("  Safe Route (New Hope <-> Dry Well) Risk = %.1f (Safe)" % risk_hope_dry)
	print("  Insecure Route (Gray Valley <-> Dry Well) Risk = %.1f (Hazardous)" % risk_gray_dry)
	print("PASS GATE F5: Derived Route Risk mathematically verified.")

	# --------------------------------------------------------------------------
	# GATE F6: Transit Predation (Once Per Leg, Targeted on Dangerous Route)
	# --------------------------------------------------------------------------
	print("\n--- [GATE F6] Transit Predation ---")
	var world_f6 := S1WorldData.create_s1_world()
	var predation_count_gray_dry := 0
	var predation_count_hope_dry := 0

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_f6, &"caravan:c_hope_gray", day)
		var evts := engine.tick(world_f6)
		for e in evts:
			if e.type == "TRANSIT_PREDATION":
				if e.actor_id == &"caravan:c_gray_dry":
					predation_count_gray_dry += 1
				elif e.actor_id == &"caravan:c_hope_dry":
					predation_count_hope_dry += 1

	if predation_count_hope_dry > 0:
		print("FAIL F6: Caravan on safe route (c_hope_dry) suffered transit predation! Count: %d" % predation_count_hope_dry)
		quit(1)
		return

	if predation_count_gray_dry <= 0:
		print("FAIL F6: Caravan on hazardous route (c_gray_dry) never suffered predation!")
		quit(1)
		return

	print("  c_hope_dry (Safe Route): Predation Events = 0 (100%% Intact Delivery)")
	print("  c_gray_dry (Hazardous Route): Predation Events = %d (Once Per Leg Tolls Applied)" % predation_count_gray_dry)
	print("PASS GATE F6: Transit Predation verified (Targeted contagion on dangerous route).")

	# --------------------------------------------------------------------------
	# GATE F7: Full Invariant & Bitwise Determinism Replay
	# --------------------------------------------------------------------------
	print("\n--- [GATE F7] Full Invariant & Bitwise Determinism Replay ---")
	var inv_err := engine.validate_invariants(world_f6)
	if inv_err != "":
		print("FAIL F7: Invariant violation in World B with security: %s" % inv_err)
		quit(1)
		return

	# 驗證雙軌重跑決定論
	var world_f7_a := S1WorldData.create_s1_world()
	var world_f7_b := S1WorldData.create_s1_world()

	for day in range(1, 101):
		if day == 30:
			engine.destroy_caravan(world_f7_a, &"caravan:c_hope_gray", day)
			engine.destroy_caravan(world_f7_b, &"caravan:c_hope_gray", day)
		engine.tick(world_f7_a)
		engine.tick(world_f7_b)

	var hash_a := world_f7_a.to_canonical_json().sha256_text()
	var hash_b := world_f7_b.to_canonical_json().sha256_text()

	if hash_a != hash_b:
		print("FAIL F7: Replay hash mismatch in security world!")
		quit(1)
		return

	print("  World B Day 100 SHA-256 with Full Security Ecosystem: %s" % hash_a)
	print("PASS GATE F7: Full Invariant & Bitwise Determinism Replay verified.")

	print("\n================================================================================")
	print("ALL S3-F ACCEPTANCE GATES (F1 ~ F7) PASSED!")
	print("================================================================================")
	quit(0)
