extends SceneTree

const ItemMarketState = preload("res://simulation/item_market_state.gd")

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-11: " + message)

func _init() -> void:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	engine.materialize_player(world, &"settlement:gray_valley", "Price Tester", 31)
	world.player.money = 1000
	engine.execute_player_buy_item(world, &"wrench", 1)
	var gray := world.get_settlement(&"settlement:gray_valley")
	check(gray.item_market.quantity("wrench") == 5, "fixture leaves one wrench below the high-supply target")
	check(ItemMarketState.buy_quote("wrench", gray.id, gray.item_market) == 28, "short stock raises the next wrench buy quote")
	check(ItemMarketState.buy_quote("wrench", gray.id) == 25, "fresh catalogue quote uses the regional target")
	check(ItemMarketState.sell_quote("wrench", gray.id) == 12, "medium demand keeps the declared half-value sell quote")
	check(ItemMarketState.sell_quote("desert_robe", "settlement:dry_well") == 33, "high demand improves the desert robe sell quote")
	gray.item_market.restock_for(gray.id, 1)
	check(ItemMarketState.buy_quote("wrench", gray.id, gray.item_market) == 25, "restock removes the stock shortage premium")
	var projected: Dictionary = PlayerUIProjection.project(world).current_settlement
	var projected_wrench: Dictionary = {}
	for offer in projected.item_market:
		if offer.item_id == "wrench":
			projected_wrench = offer
	check(projected_wrench.quote_buy == 25 and projected_wrench.stock == 6, "PDA projection uses current market stock for quotes")
	var saved := world.to_canonical_json()
	var loaded := WorldState.from_json_checked(saved)
	check(loaded.success and loaded.world.to_canonical_json() == saved, "dynamic item quotes survive save/load exactly")
	check(SimulationEngine.new().validate_invariants(world) == "", "dynamic item pricing preserves invariants")
	print("ITEM-11 dynamic item pricing: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
