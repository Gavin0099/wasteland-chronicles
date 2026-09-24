extends SceneTree

var engine := SimulationEngine.new()
var failures: int = 0
var assertions: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-6: " + message)

func fixture(kind: StringName) -> WorldState:
	var world := S1WorldData.create_s1_world()
	engine.materialize_player(world, &"settlement:gray_valley", "Item Approach Tester", 25)
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	world.active_encounter = TravelEncounterState.create(
		kind, 1, &"settlement:gray_valley", &"settlement:new_hope", 1)
	return world

func _init() -> void:
	var no_wrench := fixture(TravelEncounter.WRECK)
	var before := no_wrench.to_canonical_json()
	check(engine.authorize_encounter_option(no_wrench, &"USE_WRENCH").begins_with("ITEM_NOT_HELD"), "missing wrench refuses item approach")
	var projected: Array = PlayerUIProjection.project(no_wrench).active_encounter.options
	var wrench_option := {}
	for option in projected:
		if option.id == "USE_WRENCH":
			wrench_option = option
	check(not wrench_option.is_empty() and not wrench_option.enabled and wrench_option.requirement_label == "持有：扳手", "missing item remains visible with a readable requirement")
	check(no_wrench.to_canonical_json() == before, "refused item approach is mutation-free")

	var with_wrench := fixture(TravelEncounter.WRECK)
	check(with_wrench.player.pickup_item("wrench").success, "test player owns wrench")
	check(engine.authorize_encounter_option(with_wrench, &"USE_WRENCH") == "", "owned wrench unlocks approach")
	var wrench_result := engine.commit_player_intent(with_wrench, PlayerIntent.create_resolve_encounter(with_wrench.player.npc_id, &"USE_WRENCH"))
	check(wrench_result.success and wrench_result.elapsed_days == 1, "wrench approach resolves with the declared day cost")
	check(with_wrench.player.inspect_item("wrench").success, "using wrench does not destroy reusable tool")

	var no_rope := fixture(TravelEncounter.ROCKSLIDE)
	check(engine.authorize_encounter_option(no_rope, &"USE_ROPE").begins_with("ITEM_NOT_HELD"), "missing rope refuses item approach")
	var with_rope := fixture(TravelEncounter.ROCKSLIDE)
	check(with_rope.player.pickup_item("rope").success, "test player owns rope")
	check(engine.authorize_encounter_option(with_rope, &"USE_ROPE") == "", "owned rope unlocks approach")
	var rope_result := engine.commit_player_intent(with_rope, PlayerIntent.create_resolve_encounter(with_rope.player.npc_id, &"USE_ROPE"))
	check(rope_result.success and rope_result.elapsed_days == 0 and rope_result.spent.is_empty(), "rope avoids scrap and time without inventing a combat effect")
	check(with_rope.player.inspect_item("rope").success, "using rope does not destroy reusable tool")
	check(WorldState.from_json(with_rope.to_canonical_json()) != null, "item approach receipt saves and loads")
	check(engine.validate_invariants(with_wrench) == "" and engine.validate_invariants(with_rope) == "", "item approaches preserve invariants")
	print("ITEM-6 item approach gates: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
