extends SceneTree

const ItemMarketState = preload("res://simulation/item_market_state.gd")

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-8: " + message)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	engine.materialize_player(world, &"settlement:gray_valley", "Market Tester", 28)
	world.player.money = 1000
	return world

func _init() -> void:
	var world := fixture()
	var gray := world.get_settlement(&"settlement:gray_valley")
	check(gray.item_market == null, "fresh settlement keeps lazy item market state")
	var before := world.to_canonical_json()
	var buy_intent := PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1)
	check(engine.authorize_player_intent(world, buy_intent) == "", "owned item market accepts a supplied item")
	check(world.to_canonical_json() == before, "item trade authorization is mutation-free")
	var bought := engine.commit_player_intent(world, buy_intent)
	check(bought.success and bought.action == "BUY" and bought.item_id == "wrench", "item buy commits through PlayerIntent")
	check(world.player.inspect_item("wrench").success and world.player.money == 975, "buy transfers item and uses base-value caps")
	check(gray.item_market != null and gray.item_market.quantity("wrench") == 5, "buy seeds and decrements regional shop stock")
	check(world.event_log.back().type == "ITEM_TRADE_COMPLETED", "item trade writes a distinct ledger event")

	var saved := world.to_canonical_json()
	var loaded_result := WorldState.from_json_checked(saved)
	check(loaded_result.success, "item market state saves and loads")
	check(loaded_result.world.to_canonical_json() == saved, "item market save/load is byte-stable")

	var sold := engine.commit_player_intent(world, PlayerIntent.create_sell_item(world.player.npc_id, &"wrench", 1))
	check(sold.success and sold.action == "SELL" and sold.total_amount == 12, "item sell uses fixed spread and commits")
	check(not world.player.inspect_item("wrench").success and gray.item_market.quantity("wrench") == 6, "sell removes ownership and returns stock")

	var absent := fixture()
	var absent_before := absent.to_canonical_json()
	var absent_result := engine.commit_player_intent(absent, PlayerIntent.create_sell_item(absent.player.npc_id, &"rope", 1))
	check(not absent_result.success and absent_result.error.begins_with("INSUFFICIENT_PLAYER_ITEM"), "selling an unowned item refuses")
	check(absent.to_canonical_json() == absent_before, "refused item sale is mutation-free")

	var unique := fixture()
	check(engine.commit_player_intent(unique, PlayerIntent.create_buy_item(unique.player.npc_id, &"rusted_knife", 1)).success, "unique item can be bought once")
	var duplicate := engine.commit_player_intent(unique, PlayerIntent.create_buy_item(unique.player.npc_id, &"rusted_knife", 1))
	check(not duplicate.success and duplicate.error == "UNIQUE_ITEM_DUPLICATE", "unique item duplicate is refused before mutation")

	var intent_roundtrip := PlayerIntent.from_dict(buy_intent.to_dict())
	check(intent_roundtrip.item_id == &"wrench" and intent_roundtrip.commodity == &"", "item intent round-trips with aggregate commodity empty")
	var malformed := world.to_dict()
	malformed.settlements["settlement:gray_valley"].item_market.items.append({"item_id": "forged", "quantity": 1})
	check(not WorldState.from_dict_checked(malformed).success, "unknown market item save fails closed")
	var malformed_duplicate := world.to_dict()
	malformed_duplicate.settlements["settlement:gray_valley"].item_market.items.append({"item_id": "wrench", "quantity": 1})
	check(not WorldState.from_dict_checked(malformed_duplicate).success, "duplicate market item save fails closed")
	check(engine.validate_invariants(world) == "", "item market trades preserve world invariants")
	check(ItemMarketState.buy_quote("wrench", "gray_valley") == 25 and ItemMarketState.sell_quote("wrench", "gray_valley") == 12, "quote authority is deterministic")

	print("ITEM-8 item market transactions: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
