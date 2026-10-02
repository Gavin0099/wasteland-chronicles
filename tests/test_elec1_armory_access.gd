extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Places = preload("res://simulation/road_places.gd")
const Training = preload("res://simulation/training.gd")
var engine: SimulationEngine = SimulationEngine.new()
var failures: int = 0
var assertions: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ELEC-1: " + label)

func fixture() -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "Circuit", "age": 28, "background_id": "SCAVENGER", "trait_ids": []})).success, "create novice")
	world.player.money = 500
	return world

func answer(world: WorldState, option: StringName) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))

func resupply(world: WorldState) -> void:
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.inventory.set_amount("scrap", 2)
	world.player.inventory.set_amount("fuel", 0)

func travel(world: WorldState, destination: StringName, route: String, stop_at: String = "") -> bool:
	resupply(world)
	if not engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, destination, route)).success:
		return false
	for step: int in range(24):
		if world.active_encounter != null and stop_at != "" and world.active_encounter.context.get("place_id", "") == stop_at:
			return true
		if world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
			continue
		if world.active_encounter == null:
			return stop_at == "" and world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id == destination
		var choice: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		if not answer(world, choice).success:
			return false
	return false

func reload(world: WorldState) -> WorldState:
	var raw: String = world.to_canonical_json()
	var loaded: Dictionary = WorldState.from_json_checked(raw)
	check(loaded.success, "checked save loads")
	if not loaded.success:
		return world
	check(loaded.world.to_canonical_json() == raw and engine.validate_invariants(loaded.world) == "", "save fixed point and global invariants")
	return loaded.world

func track(resume: bool) -> String:
	var world: WorldState = fixture()
	resupply(world)
	check(world.player.capability.get_rank("ELECTRONICS") == 0, "learning starts at zero")
	for lesson: int in range(2):
		check(engine.commit_player_intent(world, PlayerIntent.create_train_skill(world.player.npc_id, "ELECTRONICS")).success, "actual lesson succeeds")
		if resume:
			world = reload(world)
	check(world.current_day == 4 and world.player.money == 320 and world.player.capability.get_rank("ELECTRONICS") == 2, "two lessons cost180 caps and4 days")
	check(world.player.capability.get_rank("MECHANICS") == 0, "electronic path needs no mechanics")
	check(travel(world, &"settlement:dry_well", ""), "reach Dry Well via actual road")
	if resume:
		world = reload(world)
	check(travel(world, &"settlement:new_hope", "WILDERNESS", "place:old_armory"), "actual wilderness day3 offers armory")
	if world.active_encounter == null:
		return "FAILED"
	world.player.inventory.set_amount("water", 4)
	world.player.inventory.set_amount("food", 4)
	world.player.inventory.set_amount("scrap", 2)
	var before: String = world.to_canonical_json()
	var shown: Dictionary = PlayerUIProjection.project(world).active_encounter
	var electronic: Dictionary = {}
	for option: Dictionary in shown.options:
		if option.id == "BRIDGE_ARMORY":
			electronic = option
	check(electronic.get("enabled", false) and String(electronic.get("requirement_label", "")).contains("廢料 2"), "UI offers skill and material route")
	check(world.to_canonical_json() == before, "projection is read-only")
	var day: int = world.current_day
	check(answer(world, &"BRIDGE_ARMORY").success, "bridge controller commits")
	check(world.current_day == day + 1 and world.player.item_inventory.quantity("old_world_saber") == 1, "one day and one shared saber")
	var receipt: Dictionary = world.event_log[world.pending_encounter_result].payload
	check(receipt.spent.scrap == 2 and receipt.gained.scrap == 3 and world.player.inventory.scrap == 3, "real material cost separate from recovered cache scrap")
	check(receipt.skill_practice.skill_id == "ELECTRONICS" and world.player.capability.get_practice_progress("ELECTRONICS").points == 1, "actual electronics practice")
	check(Places.state(world, "place:old_armory").prize_taken and not Places.is_live(world, "place:old_armory"), "both entries close after shared prize")
	before = world.to_canonical_json()
	check(not answer(world, &"OPEN_ARMORY").success and not answer(world, &"BRIDGE_ARMORY").success and world.to_canonical_json() == before, "repeat and alternate intents cannot duplicate prize")
	if resume:
		world = reload(world)
	var forged: Dictionary = JSON.parse_string(world.to_canonical_json())
	forged.events[world.pending_encounter_result].payload.spent.scrap = 1
	check(not WorldState.from_json_checked(JSON.stringify(forged)).success, "corrupt controller cost receipt rejected")
	check(engine.validate_invariants(world) == "", "final global invariants")
	return world.to_canonical_json().sha256_text()

func run() -> void:
	var a: String = track(false)
	var b: String = track(true)
	check(a == b and a != "FAILED", "continuous/resumed SHA256 " + a)
	var world: WorldState = fixture()
	check(travel(world, &"settlement:dry_well", "") and travel(world, &"settlement:new_hope", "WILDERNESS", "place:old_armory"), "reach locked gate")
	var before: String = world.to_canonical_json()
	var denied: Dictionary = answer(world, &"BRIDGE_ARMORY")
	check(not denied.success and String(denied.error).begins_with("CAPABILITY_NOT_MET") and world.to_canonical_json() == before, "insufficient electronics refuses without state change")
	world.player.capability.raise_rank_by_point("ELECTRONICS")
	world.player.capability.raise_rank_by_point("ELECTRONICS")
	world.player.inventory.set_amount("scrap", 1)
	before = world.to_canonical_json()
	denied = answer(world, &"BRIDGE_ARMORY")
	check(not denied.success and String(denied.error).begins_with("INSUFFICIENT_SCRAP") and world.to_canonical_json() == before, "missing material refuses without time or practice")
	check(GrowthPoints.is_spendable("ELECTRONICS") and Training.town_for("ELECTRONICS") == "settlement:gray_valley", "two reachable learning routes")
	print("ELEC-1: assertions=%d failures=%d SHA256=%s" % [assertions, failures, a])
	quit(1 if failures else 0)
