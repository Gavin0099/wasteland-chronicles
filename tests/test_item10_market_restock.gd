extends SceneTree

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-10: " + message)

func _init() -> void:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	engine.materialize_player(world, &"settlement:gray_valley", "Restock Tester", 29)
	world.player.money = 1000
	engine.execute_player_buy_item(world, &"wrench", 1)
	var gray := world.get_settlement(&"settlement:gray_valley")
	check(gray.item_market != null and gray.item_market.quantity("wrench") == 5, "buy creates a persisted regional market state")
	var desert_robe_before: int = gray.item_market.quantity("desert_robe")
	gray.item_market.restock_for(gray.id, 1)
	check(gray.item_market.quantity("wrench") == 6, "high-supply item restocks daily")
	check(gray.item_market.quantity("desert_robe") == desert_robe_before, "medium-supply item does not restock on off-day")
	gray.item_market.set_quantity("caravan_coat", 2)
	gray.item_market.restock_for(gray.id, 1)
	check(gray.item_market.quantity("caravan_coat") == 2, "medium-supply item does not restock on off-day")
	gray.item_market.restock_for(gray.id, 2)
	check(gray.item_market.quantity("caravan_coat") == 3, "medium-supply item restocks every two days")
	var untouched := S1WorldData.create_s1_world()
	var untouched_before := untouched.to_canonical_json()
	engine.tick(untouched)
	check(untouched.to_canonical_json() != untouched_before, "normal world tick still advances the world")
	for settlement_id in untouched.settlements:
		check(untouched.settlements[settlement_id].item_market == null, "untouched settlement does not create market state")
	check(engine.validate_invariants(world) == "", "restocking preserves invariants")
	print("ITEM-10 market restock: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
