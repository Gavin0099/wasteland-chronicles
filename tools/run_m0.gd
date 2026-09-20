extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - M0-A DETERMINISTIC ECONOMY 30-DAY LOG             ")
	print("================================================================================")
	print("Initial State: 3 Settlements, 1 Caravan (C001), 2 Resources (Water, Food)")
	print("--------------------------------------------------------------------------------\n")

	var engine := SimulationEngine.new()
	var world := M0WorldData.create_m0_world()

	var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var nh: SettlementState = world.get_settlement(&"settlement:new_hope")
	var dw: SettlementState = world.get_settlement(&"settlement:dry_well")
	var c1: CaravanState = world.get_caravan(&"caravan:c001")

	for day in range(1, 31):
		var prev_gv_w := gv.inventory.water
		var prev_gv_p := gv.price_water
		var prev_nh_w := nh.inventory.water

		var events := engine.tick(world)

		print("DAY %02d" % day)
		print("  [灰谷 Gray Valley] Water: %3d -> %3d | Price: $%5.2f -> $%5.2f" % [
			prev_gv_w, gv.inventory.water, prev_gv_p, gv.price_water
		])
		print("  [新希望 New Hope]  Water: %3d -> %3d | Price: $%5.2f" % [
			prev_nh_w, nh.inventory.water, nh.price_water
		])
		print("  [乾井 Dry Well]    Water: %3d (Stable) | Price: $%5.2f" % [
			dw.inventory.water, dw.price_water
		])

		for evt in events:
			if evt.type == "CARAVAN_ARRIVED":
				print("  >>> [EVENT] Caravan %s arrived at %s! Unloaded %d Water. New Stock: %d" % [
					evt.actor_id, evt.target_id, evt.payload.get("unloaded_water", 0), evt.payload.get("dest_water_after", 0)
				])
			elif evt.type == "CARAVAN_LOADED":
				print("  >>> [EVENT] Caravan %s loaded %d Water at %s. Origin Remaining: %d" % [
					evt.actor_id, evt.payload.get("loaded_water", 0), evt.target_id, evt.payload.get("origin_water_after", 0)
				])

		print("  [Caravan C001] Route: %s -> %s | Days Left: %d | Cargo: %d Water" % [
			c1.origin_id, c1.destination_id, c1.days_remaining, c1.cargo.water
		])
		print("")

	print("================================================================================")
	print("FINAL 30-DAY STATUS SUMMARY")
	print("================================================================================")
	print("Gray Valley: Water = %d (Target: %d), Price = $%.2f" % [gv.inventory.water, gv.target_water, gv.price_water])
	print("New Hope:    Water = %d (Target: %d), Price = $%.2f" % [nh.inventory.water, nh.target_water, nh.price_water])
	print("Dry Well:    Water = %d (Target: %d), Price = $%.2f" % [dw.inventory.water, dw.target_water, dw.price_water])
	print("Total Logged Events: %d" % world.event_log.size())
	print("Final State SHA-256: %s" % world.to_canonical_json().sha256_text())
	print("================================================================================")
	quit(0)
