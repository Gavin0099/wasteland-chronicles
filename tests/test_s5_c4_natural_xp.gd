extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const ProgressionXp = preload("res://simulation/progression_xp.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("S5-C4 natural XP: " + message)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "XP Tester",
		"age": 25, "background_id": "MECHANIC", "trait_ids": [],
	})).success, "created character through production authority")
	world.player.inventory.water = 8
	world.player.inventory.food = 8
	return world

func field_action(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command == "ATTACK":
		payload["battle_id"] = world.field_state.battle.id
		payload["turn"] = world.field_state.battle.turn
	elif command == "CONFIRM":
		payload["receipt"] = world.field_state.receipt
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))

func first_victory(world: WorldState) -> void:
	check(field_action(world, "START").success, "field fight starts")
	var turns := 0
	while not world.field_state.battle.is_empty() and turns < 8:
		check(field_action(world, "ATTACK").success, "combat turn commits")
		turns += 1
	check(world.field_state.receipt >= 0, "combat ends with receipt")
	var payload: Dictionary = world.event_log[world.field_state.receipt].payload
	check(payload.outcome == "VICTORY" and payload.get("xp_gained", 0) == 15 and payload.get("xp_source", "") == ProgressionXp.FIRST_FIELD_VICTORY, "first victory awards 15 XP in result event")
	check(field_action(world, "CONFIRM").success, "victory waits for confirmation")

func first_wreck(world: WorldState) -> void:
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, &"settlement:gray_valley", &"settlement:new_hope", 1)
	var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"SEARCH"))
	check(result.success, "wreck search commits")
	check(not result.get("gained", {}).is_empty() or not result.get("items_gained", {}).is_empty(), "fixture wreck yields actual carried loot")
	check(result.get("xp_gained", 0) == 10 and result.get("xp_source", "") == ProgressionXp.FIRST_WRECK_SALVAGE, "actual salvage awards 10 XP")
	check(world.event_log[world.pending_encounter_result].payload.get("xp_gained", 0) == 10, "XP is recorded on resolution receipt")

func _init() -> void:
	var first := fixture()
	var replay: WorldState = WorldState.from_json_checked(first.to_canonical_json()).world
	for world_variant in [first, replay]:
		var world: WorldState = world_variant
		first_victory(world)
		check(world.player.xp == 15, "combat XP persists after confirmation")
		first_wreck(world)
		check(world.player.xp == 25 and world.player.level() == 2, "distinct experiences combine without skill rank authority")
		check(ProgressionXp.award_once(world, "FIELD_RESULT", ProgressionXp.FIRST_FIELD_VICTORY, 15) == 0 and ProgressionXp.award_once(world, "TRAVEL_ENCOUNTER_RESOLVED", ProgressionXp.FIRST_WRECK_SALVAGE, 10) == 0 and world.player.xp == 25, "repeated sources do not farm XP")
		check(engine.validate_invariants(world) == "", "global invariants hold")
		check(WorldState.from_json_checked(world.to_canonical_json()).success, "earned XP survives checked save/load")
	check(first.to_canonical_json().sha256_text() == replay.to_canonical_json().sha256_text(), "full-world dual-track SHA matches")

	var empty := fixture()
	check(engine.begin_player_travel(empty, PlayerIntent.create_travel(empty.player.npc_id, &"settlement:new_hope")).success, "picked-clean travel starts")
	empty.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, 6, &"settlement:gray_valley", &"settlement:new_hope", 1)
	var nothing := engine.commit_player_intent(empty, PlayerIntent.create_resolve_encounter(empty.player.npc_id, &"SEARCH"))
	check(nothing.success and nothing.get("gained", {}).is_empty() and nothing.get("items_gained", {}).is_empty(), "fixed picked-clean wreck grants no loot")
	check(nothing.get("xp_gained", 0) == 0 and empty.player.xp == 0, "empty search grants no XP")
	check(engine.validate_invariants(empty) == "", "empty-search path preserves invariants")
	print("S5-C4 natural XP: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
