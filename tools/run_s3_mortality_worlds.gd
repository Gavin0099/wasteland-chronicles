extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("   WASTELAND CHRONICLES - S3-D MORTALITY & HUMAN ECOLOGY DYNAMICS REPORT        ")
	print("================================================================================")
	print("Tracking Gray Valley Crisis, Flight, Retention, Mortality & New Hope Influx (Day 0~100):")
	print("--------------------------------------------------------------------------------")

	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()

	print("Day | GV Pop | Exposure | Deaths (Tot) | In-Transit | NH Pop | NH Demand | DW Pop | Key Events")
	print("----+--------+----------+--------------+------------+--------+-----------+--------+----------------------------")

	for day in range(1, 101):
		var event_notes: Array[String] = []
		if day == 30:
			engine.destroy_caravan(world, &"caravan:c_hope_gray", day)
			event_notes.append("⚡ Day 30 商路中斷")

		var tick_evts := engine.tick(world)
		for evt in tick_evts:
			if evt.type == "REFUGEES_DEPARTED":
				event_notes.append("🏃 難民外移: %d 人出發 -> 新希望" % evt.payload["headcount"])
			elif evt.type == "REFUGEES_ARRIVED":
				event_notes.append("🤝 難民抵達: %d 人入籍新希望" % evt.payload["headcount"])
			elif evt.type == "SETTLEMENT_MORTALITY":
				event_notes.append("☠ 聚落死亡: %d 人因 [%s] 喪生" % [
					evt.payload["deaths"],
					", ".join(evt.payload["causes"])
				])

		var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
		var nh: SettlementState = world.get_settlement(&"settlement:new_hope")
		var dw: SettlementState = world.get_settlement(&"settlement:dry_well")

		var in_transit := 0
		for r_id in world.refugees:
			var r: RefugeePartyState = world.refugees[r_id]
			if r.is_active and not r.is_arrived:
				in_transit += r.headcount

		var should_print := (
			event_notes.size() > 0 or
			day in [1, 29, 30, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 60, 70, 80, 90, 100]
		)

		if should_print:
			var note_str := ", ".join(event_notes)
			print("%3d | %6d | %8.1f | %12d | %10d | %6d | %9d | %6d | %s" % [
				day,
				gv.population,
				gv.water_exposure,
				gv.cumulative_deaths,
				in_transit,
				nh.population,
				nh.consumption.water,
				dw.population,
				note_str
			])

	print("================================================================================")
	print("Summary of Human Ecology at Day 100:")
	var final_gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var final_nh: SettlementState = world.get_settlement(&"settlement:new_hope")
	var final_dw: SettlementState = world.get_settlement(&"settlement:dry_well")
	var final_in_transit := 0
	for r_id in world.refugees:
		var r: RefugeePartyState = world.refugees[r_id]
		if r.is_active and not r.is_arrived:
			final_in_transit += r.headcount

	var total_living := final_gv.population + final_nh.population + final_dw.population + final_in_transit
	var total_deaths := final_gv.cumulative_deaths + final_nh.cumulative_deaths + final_dw.cumulative_deaths

	print("  Living in Settlements:")
	print("    - Gray Valley (Crisis Origin): %d (Started: 100, Fled: %d, Died: %d)" % [
		final_gv.population, 100 - final_gv.population - final_gv.cumulative_deaths, final_gv.cumulative_deaths
	])
	print("    - New Hope (Refugee Haven):    %d (Started: 120, Absorbed Refugees: +%d)" % [
		final_nh.population, final_nh.population - 120
	])
	print("    - Dry Well (Parched Outpost):  %d (Started: 80, Isolated & Stable)" % final_dw.population)
	print("  Living in Transit (Refugees):    %d" % final_in_transit)
	print("  Cumulative Total Deaths:         %d" % total_deaths)
	print("  Total Accounted:                 %d (Initial: 300, Conserved: %s)" % [
		total_living + total_deaths,
		str(total_living + total_deaths == 300)
	])
	print("================================================================================")
	quit(0)
