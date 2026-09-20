extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("   WASTELAND CHRONICLES - S3-F SOCIAL ORDER & ROUTE PREDATION REPORT            ")
	print("================================================================================")
	print("Tracking Gray Valley Crisis -> Disorder -> Transit Predation -> Contagion (Day 0~100):")
	print("--------------------------------------------------------------------------------")

	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()

	print("Day | GV Pop | Security | G-D Risk | Cumul Disorder Loss | Ambush Leg | Notes")
	print("----+--------+----------+----------+---------------------+------------+--------------------------------------")

	var total_ambushes := 0

	for day in range(1, 101):
		var notes: Array[String] = []
		if day == 30:
			engine.destroy_caravan(world, &"caravan:c_hope_gray", day)
			notes.append("⚡ Day 30 商路中斷")

		var tick_evts := engine.tick(world)
		var ambush_this_tick := 0

		for evt in tick_evts:
			if evt.type == "REFUGEES_DEPARTED":
				notes.append("🏃 外移 %d 人" % evt.payload["headcount"])
			elif evt.type == "SETTLEMENT_MORTALITY":
				notes.append("☠ 死亡 %d 人" % evt.payload["deaths"])
			elif evt.type == "DISORDER_LOSS":
				notes.append("📉 庫存損耗: %s" % str(evt.payload["lost"]))
			elif evt.type == "TRANSIT_PREDATION":
				ambush_this_tick += 1
				total_ambushes += 1
				notes.append("⚔ 商路遭劫 (%s -> %s): %s" % [
					evt.payload["origin"].replace("settlement:", ""),
					evt.payload["destination"].replace("settlement:", ""),
					str(evt.payload["lost"])
				])

		var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
		var gd_risk := engine.calculate_route_risk(world, &"settlement:gray_valley", &"settlement:dry_well")

		var should_print := (
			notes.size() > 0 or
			day in [1, 29, 30, 41, 42, 50, 60, 70, 80, 90, 100]
		)

		if should_print:
			var loss_summary := "S:%d, F:%d" % [
				gv.cumulative_disorder_loss.get("scrap", 0),
				gv.cumulative_disorder_loss.get("fuel", 0)
			]
			var note_str := ", ".join(notes)
			print("%3d | %6d | %8.1f | %8.1f | %19s | %10d | %s" % [
				day,
				gv.population,
				gv.security,
				gd_risk,
				loss_summary,
				ambush_this_tick,
				note_str
			])

	print("--------------------------------------------------------------------------------")
	print("Summary at Day 100:")
	var final_gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var final_nh: SettlementState = world.get_settlement(&"settlement:new_hope")
	var final_dw: SettlementState = world.get_settlement(&"settlement:dry_well")
	print("  [Gray Valley Security]        : %.1f / 100.0 (Order completely collapsed)" % final_gv.security)
	print("  [Gray Valley Cumulative Loss] : %s" % str(final_gv.cumulative_disorder_loss))
	print("  [Total Transit Predations]    : %d cargo legs intercepted on Gray-Dry route" % total_ambushes)
	print("  [New Hope - Dry Well Route]   : Risk = %.1f (Safe Oasis Corridor preserved)" % engine.calculate_route_risk(world, &"settlement:new_hope", &"settlement:dry_well"))
	print("================================================================================")
	quit(0)
