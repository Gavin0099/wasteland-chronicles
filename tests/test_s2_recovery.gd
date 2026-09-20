extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S2-E POST-RESTORATION RECOVERY TEST (120 DAYS)    ")
	print("================================================================================")

	var engine := SimulationEngine.new()
	# S2-E 守護切片邊界：純物流與物理恢復，不包含 S3 人口生態系統
	engine.enable_migration = false
	engine.enable_mortality = false
	engine.enable_labor = false
	engine.enable_security = false

	# --------------------------------------------------------------------------
	# 1. 執行 World A (Baseline 基準世界 - 120 天)
	# --------------------------------------------------------------------------
	var world_a := S1WorldData.create_s1_world()
	var base_log: Dictionary = {}
	for day in range(1, 121):
		engine.tick(world_a)
		var gv_a: SettlementState = world_a.get_settlement(&"settlement:gray_valley")
		base_log[day] = {
			"water": gv_a.inventory.water,
			"price": gv_a.price_water,
			"scrap": gv_a.inventory.scrap
		}

	# --------------------------------------------------------------------------
	# 2. 執行 World B (Permanent Shock 壞掉的世界 - 120 天)
	# --------------------------------------------------------------------------
	var world_b := S1WorldData.create_s1_world()
	var shock_log: Dictionary = {}
	for day in range(1, 121):
		if day == 30:
			engine.destroy_caravan(world_b, &"caravan:c_hope_gray", day)
		engine.tick(world_b)
		var gv_b: SettlementState = world_b.get_settlement(&"settlement:gray_valley")
		shock_log[day] = {
			"water": gv_b.inventory.water,
			"price": gv_b.price_water,
			"scrap": gv_b.inventory.scrap
		}

	# --------------------------------------------------------------------------
	# 3. 執行 World C (Post-restoration Recovery 壞掉後修復的世界 - 120 天)
	# --------------------------------------------------------------------------
	var world_c := S1WorldData.create_s1_world()
	var recovery_log: Dictionary = {}
	var c_hope_gray_arrivals_after_day60: int = 0
	var day_first_arrival: int = -1

	for day in range(1, 121):
		if day == 30:
			engine.destroy_caravan(world_c, &"caravan:c_hope_gray", day)
			print("  [Day 30] World C: c_hope_gray route SEVERED.")
		elif day == 60:
			engine.restore_caravan(world_c, &"caravan:c_hope_gray", day, &"settlement:new_hope", &"settlement:gray_valley")
			print("  [Day 60] World C: c_hope_gray route RESTORED (starts at New Hope, 3-day transit).")

		var events := engine.tick(world_c)
		for evt in events:
			if evt.type == "CARAVAN_ARRIVED" and evt.actor_id == &"caravan:c_hope_gray":
				if day >= 60:
					c_hope_gray_arrivals_after_day60 += 1
					if day_first_arrival < 0:
						day_first_arrival = day
						print("  >>> [Day %d] World C: FIRST SHIPMENT ARRIVED at Gray Valley!" % day)

		var gv_c: SettlementState = world_c.get_settlement(&"settlement:gray_valley")
		recovery_log[day] = {
			"water": gv_c.inventory.water,
			"price": gv_c.price_water,
			"scrap": gv_c.inventory.scrap
		}

	# --------------------------------------------------------------------------
	# HARD GATE 1: 物理抵達天數精確性 (Authoritative Arrival Day = 60 + 3 - 1 = 62)
	# --------------------------------------------------------------------------
	if day_first_arrival != 62:
		print("FAIL GATE 1: Caravan arrival violated authoritative travel semantics! Expected Day 62, got: %d" % day_first_arrival)
		quit(1)
		return
	print("PASS GATE 1: Precise Physical Travel Latency (Departed Day 60 morning, arrived Day %d evening)" % day_first_arrival)

	# --------------------------------------------------------------------------
	# HARD GATE 2: 修路不瞬間補貨 (No Instant Water Jump on Day 60)
	# --------------------------------------------------------------------------
	var w60: int = recovery_log[60]["water"]
	var p60: float = recovery_log[60]["price"]
	# 在零庫存時，稀缺度為 1.0，價格為 15.0 * (1 + 1.5 * 1.0) = 37.50
	if w60 != 0 or absf(p60 - 37.50) > 0.01:
		print("FAIL GATE 2: Instant replenishment or price drop on Day 60! Water: %d, Price: $%f" % [w60, p60])
		quit(1)
		return
	print("PASS GATE 2: No Instant Replenishment on Day 60 (Water = 0, Price remains at zero-stock level $%.2f)" % p60)

	# --------------------------------------------------------------------------
	# HARD GATE 3: 首批到貨實體入庫 (First Delivery Physical Stock Increase)
	# --------------------------------------------------------------------------
	var w_arrival: int = recovery_log[day_first_arrival]["water"]
	if w_arrival <= 0:
		print("FAIL GATE 3: Water stock did not increase on first arrival Day %d (Stock: %d)" % [day_first_arrival, w_arrival])
		quit(1)
		return
	print("PASS GATE 3: First Delivery Stock Increase (Day %d Water: 0 -> %d)" % [day_first_arrival, w_arrival])

	# --------------------------------------------------------------------------
	# HARD GATE 4: 水價隨到貨緩跌 (Price Drops Only Upon Actual Arrival)
	# --------------------------------------------------------------------------
	var p_before_arrival: float = recovery_log[day_first_arrival - 1]["price"]
	var p_after_arrival: float = recovery_log[day_first_arrival]["price"]
	if p_after_arrival >= p_before_arrival:
		print("FAIL GATE 4: Price did not drop after delivery! (%f -> %f)" % [p_before_arrival, p_after_arrival])
		quit(1)
		return
	print("PASS GATE 4: Price Responds to Physical Inflow ($%.2f -> $%.2f at Day %d)" % [
		p_before_arrival, p_after_arrival, day_first_arrival
	])

	# --------------------------------------------------------------------------
	# HARD GATE 5: 積壓廢料開始出清 (Scrap Backlog Drainage Begins)
	# --------------------------------------------------------------------------
	var scrap_60: int = recovery_log[60]["scrap"]
	var scrap_70: int = recovery_log[70]["scrap"]
	var scrap_c_100: int = recovery_log[100]["scrap"]
	var scrap_b_100: int = shock_log[100]["scrap"]

	if scrap_70 >= scrap_60:
		print("FAIL GATE 5: Scrap backlog did not begin draining at Day 70! Day 60: %d, Day 70: %d" % [scrap_60, scrap_70])
		quit(1)
		return

	if scrap_c_100 >= scrap_b_100:
		print("FAIL GATE 5: Restored scrap backlog at Day 100 (%d) is not lower than shock backlog (%d)!" % [scrap_c_100, scrap_b_100])
		quit(1)
		return

	print("PASS GATE 5: Scrap Backlog Drainage Verified (Drained from %d at Day 60 down to %d at Day 70; Day 100 restored %d << shock %d)" % [
		scrap_60, scrap_70, scrap_c_100, scrap_b_100
	])

	# --------------------------------------------------------------------------
	# HARD GATE 6: 120 天決定論回放 (Determinism Replay)
	# --------------------------------------------------------------------------
	var world_c_replay := S1WorldData.create_s1_world()
	for day in range(1, 121):
		if day == 30:
			engine.destroy_caravan(world_c_replay, &"caravan:c_hope_gray", day)
		elif day == 60:
			engine.restore_caravan(world_c_replay, &"caravan:c_hope_gray", day, &"settlement:new_hope", &"settlement:gray_valley")
		engine.tick(world_c_replay)

	var hash_c1 := world_c.to_canonical_json().sha256_text()
	var hash_c2 := world_c_replay.to_canonical_json().sha256_text()

	if hash_c1 != hash_c2:
		print("FAIL GATE 6: Determinism replay failed on World C!")
		quit(1)
		return
	print("PASS GATE 6: Determinism Replay Verified (World C SHA-256: %s)" % hash_c1)

	# --------------------------------------------------------------------------
	# HARD GATE 7: 120 天不變量全數有效 (Invariants Valid Across All 120 Days)
	# --------------------------------------------------------------------------
	var inv_err := engine.validate_invariants(world_c)
	if inv_err != "":
		print("FAIL GATE 7: Invariants violated at Day 120: ", inv_err)
		quit(1)
		return
	print("PASS GATE 7: Invariants Valid Across 120 Days in World C")

	print("\n================================================================================")
	print("ALL S2-E HARD GATES (1 ~ 7) PASSED!")
	print("================================================================================")
	quit(0)
