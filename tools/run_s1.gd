extends SceneTree

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S1 LIVING ECONOMY 100-DAY INSPECTION LOG          ")
	print("================================================================================")

	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()

	var nh: SettlementState = world.get_settlement(&"settlement:new_hope")
	var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var dw: SettlementState = world.get_settlement(&"settlement:dry_well")

	for day in range(1, 101):
		var events := engine.tick(world)

		# 取樣印出關鍵日期：Day 1~5, Day 20, 40, 60, 80, 100
		if day <= 5 or day % 20 == 0:
			print("--- DAY %03d ---" % day)
			print("  [新希望 New Hope]   💧Water: %3d ($%4.1f) | ▣Food: %3d ($%4.1f) | ⚙Scrap: %3d ($%4.1f) | ⛽Fuel: %3d ($%4.1f)" % [
				nh.inventory.water, nh.price_water, nh.inventory.food, nh.price_food, nh.inventory.scrap, nh.price_scrap, nh.inventory.fuel, nh.price_fuel
			])
			print("  [灰谷   Gray Valley] 💧Water: %3d ($%4.1f) | ▣Food: %3d ($%4.1f) | ⚙Scrap: %3d ($%4.1f) | ⛽Fuel: %3d ($%4.1f)" % [
				gv.inventory.water, gv.price_water, gv.inventory.food, gv.price_food, gv.inventory.scrap, gv.price_scrap, gv.inventory.fuel, gv.price_fuel
			])
			print("  [乾井   Dry Well]   💧Water: %3d ($%4.1f) | ▣Food: %3d ($%4.1f) | ⚙Scrap: %3d ($%4.1f) | ⛽Fuel: %3d ($%4.1f)" % [
				dw.inventory.water, dw.price_water, dw.inventory.food, dw.price_food, dw.inventory.scrap, dw.price_scrap, dw.inventory.fuel, dw.price_fuel
			])

			for evt in events:
				if evt.type == "CARAVAN_ARRIVED":
					var unloaded: Dictionary = evt.payload.get("unloaded", {})
					if unloaded.size() > 0:
						print("  >>> [ARRIVED] %s arrived at %s with: %s" % [evt.actor_id, evt.target_id, JSON.stringify(unloaded)])
				elif evt.type == "CARAVAN_LOADED":
					var loaded: Dictionary = evt.payload.get("loaded", {})
					if loaded.size() > 0:
						print("  >>> [LOADED]  %s loaded at %s for %s: %s" % [
							evt.actor_id, evt.target_id, evt.payload.get("destination", ""), JSON.stringify(loaded)
						])
			print("")

	print("================================================================================")
	print("DAY 100 FINAL REGIONAL STATUS")
	print("================================================================================")
	print("New Hope:    W:%3d, F:%3d, S:%3d, F:%3d" % [nh.inventory.water, nh.inventory.food, nh.inventory.scrap, nh.inventory.fuel])
	print("Gray Valley: W:%3d, F:%3d, S:%3d, F:%3d" % [gv.inventory.water, gv.inventory.food, gv.inventory.scrap, gv.inventory.fuel])
	print("Dry Well:    W:%3d, F:%3d, S:%3d, F:%3d" % [dw.inventory.water, dw.inventory.food, dw.inventory.scrap, dw.inventory.fuel])
	print("Total Logged Events: %d" % world.event_log.size())
	print("Final State SHA-256: %s" % world.to_canonical_json().sha256_text())
	print("================================================================================")
	quit(0)
