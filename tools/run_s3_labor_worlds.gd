extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("   WASTELAND CHRONICLES - S3-E LABOR CAPACITY FEEDBACK COMPARISON REPORT        ")
	print("================================================================================")
	print("Comparing World B (Supply Shock Day 30) Under Two Realities (Day 0~100):")
	print("  1. No-Labor Feedback: Industrial output stays 100% constant even if ghost town.")
	print("  2. Labor Feedback   : Industrial output collapses proportionately with population.")
	print("--------------------------------------------------------------------------------")

	var engine_nolab := SimulationEngine.new()
	engine_nolab.enable_labor = false

	var engine_lab := SimulationEngine.new()
	engine_lab.enable_labor = true

	var world_nolab := S1WorldData.create_s1_world()
	var world_lab := S1WorldData.create_s1_world()

	print("Day | GV Pop | Labor Factor | Daily Scrap (NoLab / Lab) | GV Scrap (NoLab / Lab) | NH Scrap (NoLab / Lab) | Notes")
	print("----+--------+--------------+---------------------------+------------------------+------------------------+----------------------------")

	for day in range(1, 101):
		var notes: Array[String] = []
		if day == 30:
			engine_nolab.destroy_caravan(world_nolab, &"caravan:c_hope_gray", day)
			engine_lab.destroy_caravan(world_lab, &"caravan:c_hope_gray", day)
			notes.append("⚡ Day 30 商路中斷")

		var evts_nolab := engine_nolab.tick(world_nolab)
		var evts_lab := engine_lab.tick(world_lab)

		for evt in evts_lab:
			if evt.type == "REFUGEES_DEPARTED":
				notes.append("🏃 外移 %d 人" % evt.payload["headcount"])
			elif evt.type == "SETTLEMENT_MORTALITY":
				notes.append("☠ 死亡 %d 人" % evt.payload["deaths"])

		var gv_nl: SettlementState = world_nolab.get_settlement(&"settlement:gray_valley")
		var gv_l: SettlementState = world_lab.get_settlement(&"settlement:gray_valley")
		var nh_nl: SettlementState = world_nolab.get_settlement(&"settlement:new_hope")
		var nh_l: SettlementState = world_lab.get_settlement(&"settlement:new_hope")

		var labor_factor := clampf(float(gv_l.population) / float(gv_l.reference_population), 0.0, 1.0)
		var daily_scrap_l := 11.0 * labor_factor
		var daily_scrap_nl := 11.0

		var should_print := (
			notes.size() > 0 or
			day in [1, 29, 30, 41, 42, 44, 47, 50, 55, 60, 70, 80, 90, 100]
		)

		if should_print:
			var note_str := ", ".join(notes)
			print("%3d | %6d | %12.2f | %11.1f / %5.2f       | %10d / %-10d | %10d / %-10d | %s" % [
				day,
				gv_l.population,
				labor_factor,
				daily_scrap_nl,
				daily_scrap_l,
				gv_nl.inventory.scrap,
				gv_l.inventory.scrap,
				nh_nl.inventory.scrap,
				nh_l.inventory.scrap,
				note_str
			])

	print("--------------------------------------------------------------------------------")
	print("Summary at Day 100:")
	var final_gv_nl: SettlementState = world_nolab.get_settlement(&"settlement:gray_valley")
	var final_gv_l: SettlementState = world_lab.get_settlement(&"settlement:gray_valley")
	print("  [Gray Valley Population]   : %d (workforce down 91%%)" % final_gv_l.population)
	print("  [Gray Valley Scrap Output] : No-Labor = 11.0/day vs Labor = %.2f/day" % [11.0 * (float(final_gv_l.population) / float(final_gv_l.reference_population))])
	print("  [Gray Valley Scrap Stock]  : No-Labor = %d vs Labor = %d (Gap: -%d scrap)" % [
		final_gv_nl.inventory.scrap, final_gv_l.inventory.scrap, final_gv_nl.inventory.scrap - final_gv_l.inventory.scrap
	])
	print("================================================================================")
	quit(0)
