extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S1 LIVING ECONOMY 100-DAY STABILITY TEST          ")
	print("================================================================================")

	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()

	var settlements := [&"settlement:new_hope", &"settlement:gray_valley", &"settlement:dry_well"]
	var commodities := ["water", "food", "scrap", "fuel"]

	var total_deliveries: int = 0
	var min_stocks: Dictionary = {}
	var max_stocks: Dictionary = {}

	for s_id in settlements:
		min_stocks[s_id] = {}
		max_stocks[s_id] = {}
		for res in commodities:
			min_stocks[s_id][res] = 999999
			max_stocks[s_id][res] = 0

	# --------------------------------------------------------------------------
	# 執行 100 天自主模擬
	# --------------------------------------------------------------------------
	for day in range(1, 101):
		var events := engine.tick(world)

		for evt in events:
			if evt.type == "CARAVAN_ARRIVED":
				var unloaded: Dictionary = evt.payload.get("unloaded", {})
				if unloaded.size() > 0:
					total_deliveries += 1

		# 檢驗各聚落狀態與記錄極值
		for s_id in settlements:
			var s: SettlementState = world.get_settlement(s_id)
			for res in commodities:
				var stock := s.inventory.get_amount(res)
				var target := s.get_target(res)
				var price := s.get_current_price(res)

				if stock < min_stocks[s_id][res]:
					min_stocks[s_id][res] = stock
				if stock > max_stocks[s_id][res]:
					max_stocks[s_id][res] = stock

				# 斷言 1: 存活不滅 (庫存 >= 0)
				if stock < 0:
					print("FAIL: Settlement %s depleted %s to negative (%d) at Day %d!" % [s.name, res, stock, day])
					quit(1)
					return

				# 斷言 2: 無無限爆倉 (庫存 <= 3.5 倍目標庫存)
				var max_allowed := int(target * 3.5)
				if stock > max_allowed:
					print("FAIL: Settlement %s over-inflated %s (%d > %d) at Day %d!" % [s.name, res, stock, max_allowed, day])
					quit(1)
					return

				# 斷言 3: 價格合法且有界
				var min_p := s.get_base_price(res) * 0.2
				var max_p := s.get_base_price(res) * 5.0
				if price < min_p - 0.01 or price > max_p + 0.01:
					print("FAIL: Settlement %s %s price ($%.2f) out of bounds [$%.2f, $%.2f] at Day %d!" % [
						s.name, res, price, min_p, max_p, day
					])
					quit(1)
					return

	# 斷言 4: 雙向貨運活躍 (100 天內必須有充沛的貨物流轉)
	print("\n[Logistics Activity]")
	print("Total successful cargo deliveries across 100 days: %d" % total_deliveries)
	if total_deliveries < 30:
		print("FAIL: Logistics grid stalled! Only %d deliveries completed." % total_deliveries)
		quit(1)
		return

	# --------------------------------------------------------------------------
	# 斷言 5: 100 天決定論驗證 (Determinism Replay)
	# --------------------------------------------------------------------------
	print("\n[Determinism Replay Check]")
	var world_replay := S1WorldData.create_s1_world()
	for day in range(1, 101):
		engine.tick(world_replay)

	var json_1 := world.to_canonical_json()
	var json_2 := world_replay.to_canonical_json()
	var hash_1 := json_1.sha256_text()
	var hash_2 := json_2.sha256_text()

	print("Run 1 SHA-256 (Day 100): %s" % hash_1)
	print("Run 2 SHA-256 (Day 100): %s" % hash_2)

	if hash_1 != hash_2:
		print("FAIL: Determinism mismatch at Day 100!")
		quit(1)
		return

	# --------------------------------------------------------------------------
	# 印出 100 天極值範圍表
	# --------------------------------------------------------------------------
	print("\n================================================================================")
	print("100-DAY COMMODITY STABILITY SUMMARY (MIN ~ MAX STOCKS vs TARGET)")
	print("================================================================================")
	for s_id in settlements:
		var s: SettlementState = world.get_settlement(s_id)
		print("[%s]" % s.name)
		for res in commodities:
			var cur := s.inventory.get_amount(res)
			var tgt := s.get_target(res)
			var mn: int = min_stocks[s_id][res]
			var mx: int = max_stocks[s_id][res]
			var pr := s.get_current_price(res)
			print("  - %-6s: Current = %3d | Range = [%3d ~ %3d] | Target = %3d | Price = $%5.2f" % [
				res.capitalize(), cur, mn, mx, tgt, pr
			])

	print("================================================================================")
	print("ALL S1 ACCEPTANCE CRITERIA PASSED! The 3 settlements sustainably co-exist for 100 days.")
	print("================================================================================")
	quit(0)
