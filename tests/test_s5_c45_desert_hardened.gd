extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Acquired = preload("res://simulation/acquired_traits.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("S5-C4.5: " + label)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Desert Tester",
		"age": 26, "background_id": "FARMER", "trait_ids": [],
	})).success, "ordinary character creation succeeds")
	world.player.inventory.water = 0
	world.player.inventory.food = 6
	return world

func run_life(world: WorldState) -> void:
	var id: StringName = world.player.npc_id
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, &"settlement:new_hope")).success, "travel starts")
	var before := world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DESERT_HARDENED")).success and world.to_canonical_json() == before, "unearned trait cannot be forged on the road")
	engine.tick(world)
	check(Acquired.candidates(world.event_log, id, world.current_day).is_empty(), "one day of actual unmet water is insufficient")
	engine.tick(world)
	check(Acquired.candidates(world.event_log, id, world.current_day).has("DESERT_HARDENED"), "two committed deprivation days create candidate")
	before = world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DESERT_HARDENED")).success and world.to_canonical_json() == before, "candidate cannot be accepted in transit")
	engine.tick(world)
	check(world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED, "player arrives alive after three days")
	check(world.player.acquired_trait_ids.is_empty(), "qualification alone never applies trait")
	var choice := engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DESERT_HARDENED"))
	check(choice.success and world.player.has_acquired_trait("DESERT_HARDENED"), "player opt-in commits trait")
	check(world.event_log.back().type == "ACQUIRED_TRAIT_ACCEPTED", "acquisition is recorded in committed history")
	before = world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DESERT_HARDENED")).success and world.to_canonical_json() == before, "repeat selection fails atomically")
	check(WorldState.from_json_checked(before).success and engine.validate_invariants(world) == "", "checked save and global invariants hold")
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, &"settlement:gray_valley")).success, "return travel starts")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.ROCKSLIDE, world.current_day, &"settlement:new_hope", &"settlement:gray_valley", 1)
	var options: Array = PlayerUIProjection.project(world).active_encounter.options
	check(options.any(func(o: Dictionary) -> bool: return String(o.id) == "ENDURE_CROSSING" and o.enabled), "owned life trait exposes crossing choice")
	var hungry: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	hungry.player.inventory.food = 0
	var hungry_before := hungry.to_canonical_json()
	var hungry_options: Array = PlayerUIProjection.project(hungry).active_encounter.options
	check(hungry_options.any(func(o: Dictionary) -> bool: return String(o.id) == "ENDURE_CROSSING" and not o.enabled), "ration tradeoff remains visibly blocked when empty")
	check(not engine.commit_player_intent(hungry, PlayerIntent.create_resolve_encounter(id, &"ENDURE_CROSSING")).success and hungry.to_canonical_json() == hungry_before, "insufficient ration rejects atomically")
	var food_before := world.player.inventory.food
	var day_before := world.current_day
	var resolved := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"ENDURE_CROSSING"))
	check(resolved.success and world.player.inventory.food == food_before - 1 and world.current_day == day_before, "crossing costs one ration and no extra day")
	check(int(resolved.spent.get("food", 0)) == 1 and not resolved.cost_extra_day, "receipt tells the exact cost")
	check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "new option preserves whole-world invariants and checked save")
	check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result)).success, "receipt confirmation resumes the journey")

func _init() -> void:
	var first := fixture()
	var replay: WorldState = WorldState.from_json_checked(first.to_canonical_json()).world
	for world in [first, replay]:
		run_life(world)
	check(first.to_canonical_json().sha256_text() == replay.to_canonical_json().sha256_text(), "two complete histories replay to the same full-world SHA-256")
	var altered: Dictionary = first.to_dict().duplicate(true)
	altered.player.acquired_trait_ids = ["UNKNOWN"]
	check(not WorldState.from_dict_checked(altered).success, "unknown persisted acquired trait fails closed")
	altered = first.to_dict().duplicate(true)
	altered.player.acquired_trait_ids = []
	check(String(WorldState.from_dict_checked(altered).error).begins_with("ACQUIRED_TRAIT_LEDGER"), "trait cannot be removed from player owner while ledger retains acceptance")
	altered = first.to_dict().duplicate(true)
	for event in altered.events:
		if event.type == "ACQUIRED_TRAIT_ACCEPTED":
			event.payload.trait_id = "UNKNOWN"
	check(String(WorldState.from_dict_checked(altered).error).begins_with("ACQUIRED_TRAIT_LEDGER"), "forged acceptance event fails closed")
	altered = first.to_dict().duplicate(true)
	for event in altered.events:
		if event.type == "PLAYER_NEED_UNMET":
			event.payload.water_unmet = -1.0
			break
	check(String(WorldState.from_dict_checked(altered).error).begins_with("ACQUIRED_TRAIT_NEED_LEDGER"), "corrupt deprivation evidence fails closed")
	altered = first.to_dict().duplicate(true)
	for event in altered.events:
		if event.type == "PLAYER_NEED_UNMET":
			event.day = int(altered.current_day) + 1
			break
	check(String(WorldState.from_dict_checked(altered).error).begins_with("ACQUIRED_TRAIT_LEDGER_DAY"), "future deprivation evidence cannot authorize an acquired trait")
	altered = first.to_dict().duplicate(true)
	var acceptance_day := -1
	for event in altered.events:
		if event.type == "ACQUIRED_TRAIT_ACCEPTED":
			acceptance_day = int(event.day)
	for event in altered.events:
		if event.type == "PLAYER_NEED_UNMET":
			event.day = acceptance_day + 1
			break
	check(String(WorldState.from_dict_checked(altered).error).begins_with("ACQUIRED_TRAIT_LEDGER"), "post-acceptance evidence cannot retroactively qualify")
	var unqualified := fixture()
	check(engine.begin_player_travel(unqualified, PlayerIntent.create_travel(unqualified.player.npc_id, &"settlement:new_hope")).success, "unqualified comparison starts")
	unqualified.active_encounter = TravelEncounterState.create(TravelEncounter.ROCKSLIDE, unqualified.current_day, &"settlement:gray_valley", &"settlement:new_hope", 1)
	var unowned_options: Array = PlayerUIProjection.project(unqualified).active_encounter.options
	check(not unowned_options.any(func(o: Dictionary) -> bool: return String(o.id) == "ENDURE_CROSSING"), "unowned identity choice stays hidden")
	var unowned_before := unqualified.to_canonical_json()
	check(not engine.commit_player_intent(unqualified, PlayerIntent.create_resolve_encounter(unqualified.player.npc_id, &"ENDURE_CROSSING")).success and unqualified.to_canonical_json() == unowned_before, "forged crossing fails atomically")
	print("S5-C4.5 desert hardened: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
