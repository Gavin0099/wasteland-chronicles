extends SceneTree

var engine := SimulationEngine.new()
var failures: int = 0
var assertions: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-4: " + message)

func fixture(encounter_day: int, existing_item: String = "") -> WorldState:
	var world := S1WorldData.create_s1_world()
	engine.materialize_player(world, &"settlement:gray_valley", "Item Tester", 25)
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	if existing_item != "":
		world.player.pickup_item(existing_item)
	world.active_encounter = TravelEncounterState.create(
		TravelEncounter.WRECK, encounter_day, &"settlement:gray_valley",
		&"settlement:new_hope", 1
	)
	return world

func _init() -> void:
	var chosen_day: int = -1
	var expected: Dictionary = {}
	for day in range(1, 500):
		var candidate := TravelEncounter.wreck_item_yield(
			day, &"settlement:gray_valley", &"settlement:new_hope", 1, &"SEARCH")
		if not candidate.is_empty():
			chosen_day = day
			expected = candidate
			break
	check(chosen_day >= 1, "deterministic wreck corpus contains an item-yield case")
	if chosen_day < 1:
		print("ITEM-4 encounter item gates: FAIL; assertions=", assertions, "; failures=", failures)
		quit(1)
		return

	var world := fixture(chosen_day)
	var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"SEARCH"))
	check(result.success, "search with formal item loot resolves")
	check(result.get("items_gained", {}) == expected, "receipt records deterministic item yield")
	for item_id in expected:
		check(world.player.inspect_item(item_id).success, "player owns yielded item: " + item_id)
	check(TravelEncounter.valid_resolution(result), "item receipt is a valid encounter resolution")
	check(world.event_log[world.pending_encounter_result].payload.has("items_gained"), "ledger persists item gains")

	var saved := world.to_dict()
	var loaded_result := WorldState.from_dict_checked(saved)
	check(loaded_result.success, "pending item receipt loads")
	check(loaded_result.world.to_canonical_json() == world.to_canonical_json(), "item receipt save/load is byte-stable")

	var duplicate := fixture(chosen_day, String(expected.keys()[0]))
	var duplicate_result := engine.commit_player_intent(duplicate, PlayerIntent.create_resolve_encounter(duplicate.player.npc_id, &"SEARCH"))
	check(duplicate_result.success, "duplicate unique item does not abort encounter")
	check(duplicate_result.get("items_gained", {}).is_empty(), "duplicate unique item is not added twice")
	check(duplicate_result.get("items_left_behind", {}) == expected, "duplicate item is explicit leftover")

	var malformed := result.duplicate(true)
	malformed["items_gained"] = {"unknown_item": 1}
	check(not TravelEncounter.valid_resolution(malformed), "unknown item in receipt fails closed")
	malformed = result.duplicate(true)
	malformed["items_gained"] = {String(expected.keys()[0]): 2}
	check(not TravelEncounter.valid_resolution(malformed), "unique quantity greater than one fails closed")
	var old_receipt := result.duplicate(true)
	old_receipt.erase("items_gained")
	old_receipt.erase("items_left_behind")
	check(TravelEncounter.valid_resolution(old_receipt), "pre-ITEM-4 receipts remain loadable")

	print("ITEM-4 encounter item gates: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
