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
		push_error("S5-C4.5 scavenger: " + label)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Wreck Reader",
		"age": 28, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "normal character creation succeeds")
	world.player.inventory.water = 8
	world.player.inventory.food = 8
	return world

func search_three_wrecks(world: WorldState) -> void:
	var id: StringName = world.player.npc_id
	var counted := 0
	var trips := 0
	while counted < 3 and trips < 12:
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(id)
		var origin: StringName = life.population_container_id
		var destination := &"settlement:new_hope" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
		# Rations and bag space are fixture setup, not an in-game reward.
		world.player.inventory.water = 4
		world.player.inventory.food = 4
		world.player.inventory.scrap = 0
		world.player.inventory.fuel = 0
		check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, destination)).success, "travel starts")
		world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, origin, destination, 1)
		var projected: Dictionary = PlayerUIProjection.project(world).active_encounter
		check(projected.get("search_preview", {}).is_empty(), "unowned trait reveals no wreck contents")
		var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"SEARCH"))
		check(result.success, "real search action commits")
		if not result.get("gained", {}).is_empty() or not result.get("items_gained", {}).is_empty():
			counted += 1
		var steps := 0
		while world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.IN_TRANSIT and steps < 12:
			steps += 1
			if world.pending_encounter_result >= 0:
				check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result)).success, "receipt is confirmed")
			elif world.active_encounter != null:
				var escape_option: StringName = &"FLEE_ROAD" if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else (&"DETOUR" if world.active_encounter.encounter_type in [TravelEncounter.ROCKSLIDE, TravelEncounter.ROADBLOCK] else &"LEAVE")
				check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, escape_option)).success, "incidental road event resolves")
			else:
				engine.tick(world)
		check(steps < 12 and world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED, "journey returns to settlement")
		trips += 1
	check(counted == 3, "all three fixture wrecks actually yielded carried loot")
	check(Acquired.candidates(world.event_log, id, world.current_day).has("SCAVENGER_INSTINCT"), "three different real wrecks create candidate")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "SCAVENGER_INSTINCT")).success, "qualified survivor opts in at settlement")
	check(world.player.has_acquired_trait("SCAVENGER_INSTINCT"), "trait is owned separately from creation traits")
	var next_origin: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var next_destination := &"settlement:new_hope" if next_origin == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	world.player.inventory.scrap = 0
	world.player.inventory.fuel = 0
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, next_destination)).success, "experienced scavenger travels again")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, next_origin, next_destination, 1)
	var before_projection := world.to_canonical_json()
	var preview: Dictionary = PlayerUIProjection.project(world).active_encounter.search_preview
	check(world.to_canonical_json() == before_projection, "reading a wreck does not mutate world state")
	check(preview.get("goods", {}) == TravelEncounter.wreck_yield(world.current_day, next_origin, next_destination, 1), "trait reveals true SEARCH resource offer")
	check(preview.get("items", {}) == TravelEncounter.wreck_item_yield(world.current_day, next_origin, next_destination, 1, &"SEARCH"), "trait reveals true SEARCH item offer")
	var search_result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"SEARCH"))
	check(search_result.success and search_result.gained == preview.goods, "previewed resources match actual search when bag has room")

func _init() -> void:
	var first := fixture()
	var replay: WorldState = WorldState.from_json_checked(first.to_canonical_json()).world
	for world in [first, replay]:
		search_three_wrecks(world)
		check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "checked save and global invariants hold")
	check(first.to_canonical_json().sha256_text() == replay.to_canonical_json().sha256_text(), "two full-world replays have identical SHA-256")
	var forged: Dictionary = first.to_dict().duplicate(true)
	for event in forged.events:
		if event.type == "ACQUIRED_TRAIT_ACCEPTED" and event.payload.get("trait_id") == "SCAVENGER_INSTINCT":
			event.day = 0
	check(String(WorldState.from_dict_checked(forged).error).begins_with("ACQUIRED_TRAIT_LEDGER"), "future wrecks cannot qualify an earlier acceptance")
	print("S5-C4.5 scavenger instinct: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
