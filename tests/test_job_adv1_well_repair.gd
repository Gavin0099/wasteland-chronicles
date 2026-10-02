extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Well = preload("res://simulation/well_repair.gd")
const Places = preload("res://simulation/road_places.gd")
var engine: SimulationEngine = SimulationEngine.new()
var failures: int = 0
var assertions: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("JOB-ADV-1: " + label)

func resupply(world: WorldState) -> void:
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.inventory.set_amount("scrap", 3)
	world.player.inventory.set_amount("fuel", 0)

func answer(world: WorldState, option: StringName) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))

func finish(world: WorldState) -> void:
	for step: int in range(24):
		if world.pending_encounter_result >= 0:
			check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success, "continue committed journey")
			continue
		if world.active_encounter == null:
			return
		var option: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: option = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: option = &"DETOUR"
			TravelEncounter.ROADBLOCK: option = &"PAY"
		check(answer(world, option).success, "pass other encounter")
	check(false, "journey must terminate")

func claim() -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "井泵技師", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "create mechanic")
	world.player.money = 500
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1)).success, "buy real tool")
	resupply(world)
	check(Well.state(world).owner == "" and repair_job(world, &"settlement:gray_valley") == "", "unclaimed well posts no repair work")
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success, "travel to well")
	check(world.active_encounter != null and world.active_encounter.context.get("place_id") == Well.PLACE, "actual road offers well")
	check(answer(world, &"MARK_B").success, "mark well for Dry Well")
	finish(world)
	check(Well.state(world).owner == "settlement:dry_well" and Well.state(world).status == "BROKEN", "reported well has real owner and broken pump")
	return world

func repair_job(world: WorldState, town: StringName) -> String:
	for entry: Dictionary in JobBoard.postings(world, town):
		if Well.is_contract(entry.definition):
			return entry.definition.id
	return ""

func accept_and_visit(world: WorldState) -> String:
	var job: String = repair_job(world, &"settlement:dry_well")
	check(job != "", "owner posts repair contract")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job)).success, "accept actual contract")
	check(repair_job(world, &"settlement:dry_well") == "", "one active repair contract")
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, job)).success, "wrench ownership alone cannot fulfill repair")
	resupply(world)
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:gray_valley")).success, "return to site")
	check(world.active_encounter != null and world.active_encounter.context.get("repair_visit", false), "claimed site reopens for contracted repair")
	return job

func reload(world: WorldState) -> WorldState:
	var raw: String = world.to_canonical_json()
	var loaded: Dictionary = WorldState.from_json_checked(raw)
	check(loaded.success, "checked persistence")
	if not loaded.success:
		return world
	check(loaded.world.to_canonical_json() == raw and engine.validate_invariants(loaded.world) == "", "fixed point and invariants")
	return loaded.world

func track(resume: bool) -> String:
	var world: WorldState = claim()
	if resume:
		world = reload(world)
	var job: String = accept_and_visit(world)
	if resume:
		world = reload(world)
	var old_production: int = world.get_settlement(&"settlement:dry_well").production.water
	var day: int = world.current_day
	check(answer(world, &"REPAIR_PUMP").success, "repair commits")
	check(world.current_day == day + 1 and world.player.inventory.scrap == 0 and world.player.item_inventory.contains("wrench"), "one day, three consumed scrap, retained wrench")
	check(Well.state(world).status == "WORKING" and world.get_settlement(&"settlement:dry_well").production.water == old_production + 1, "bounded real production and working state")
	check(QuestEngine.evaluate_objectives(world, job), "only matching repair fulfills contract")
	var receipt: Dictionary = world.event_log[world.pending_encounter_result].payload
	check(receipt.spent.scrap == 3 and receipt.skill_practice.skill_id == "MECHANICS", "cost and skill receipt")
	check(String(PlayerUIProjection.project(world).encounter_result.place_note).contains("故障 → 運轉"), "UI shows actual equipment effect")
	var before: String = world.to_canonical_json()
	check(not answer(world, &"REPAIR_PUMP").success and world.to_canonical_json() == before, "duplicate repair atomically refused")
	if resume:
		world = reload(world)
	finish(world)
	resupply(world)
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success, "return for payment")
	finish(world)
	var money: int = world.player.money
	var xp: int = world.player.xp
	check(engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, job)).success, "owner pays completed repair")
	check(world.player.money == money + 80 and world.player.xp == xp + 12, "authored repair reward once")
	before = world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, job)).success and world.to_canonical_json() == before, "no second reward")
	check(repair_job(world, &"settlement:dry_well") == "" and world.get_settlement(&"settlement:dry_well").production.water == old_production + 1, "working pump never reposts or stacks production")
	if resume:
		world = reload(world)
	var bad: Dictionary = JSON.parse_string(world.to_canonical_json())
	for event: Dictionary in bad.events:
		if event.type == "EQUIPMENT_REPAIRED":
			event.payload.production_after += 1
	check(not WorldState.from_json_checked(JSON.stringify(bad)).success, "historical forged production receipt rejected")
	check(engine.validate_invariants(world) == "", "final global invariants")
	return world.to_canonical_json().sha256_text()

func run() -> void:
	var a: String = track(false)
	check(a == track(true), "dual-track SHA " + a)
	var base: WorldState = claim()
	var job: String = accept_and_visit(base)
	for fault: String in ["skill", "tool", "scrap", "deadline", "place", "unknown_place", "contract"]:
		var world: WorldState = reload(base)
		match fault:
			"skill": world.player.capability._data.skill_ranks.MECHANICS = 0
			"tool": world.player.item_inventory.remove_item("wrench", 1)
			"scrap": world.player.inventory.set_amount("scrap", 2)
			"deadline": world.quest_state.get_quest(job).deadline_day = world.current_day
			"place": world.active_encounter.context.place_id = "place:fuel_station"
			"unknown_place": world.active_encounter.context.place_id = "place:forged"
			"contract": world.quest_state.get_quest(job).status = &"EXPIRED"
		var before: String = world.to_canonical_json()
		check(not answer(world, &"REPAIR_PUMP").success and world.to_canonical_json() == before, "atomic refusal " + fault)
	var malformed: Dictionary = base.accepted_jobs[job].duplicate(true)
	malformed.objectives[0].equipment_id = "unknown_pump"
	check(QuestDefinition.validate_definition(malformed) == "QUEST_OBJ_INVALID_EQUIPMENT", "unknown equipment fails definition validation")
	check(answer(base, &"REPAIR_PUMP").success, "receipt rejection fixture")
	finish(base)
	var bad: Dictionary = JSON.parse_string(base.to_canonical_json())
	for event: Dictionary in bad.events:
		if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.payload.option == "REPAIR_PUMP":
			event.payload.spent = "forged"
	check(not WorldState.from_json_checked(JSON.stringify(bad)).success, "malformed historical resolution fails closed without script error")
	print("JOB-ADV-1: assertions=%d failures=%d SHA256=%s" % [assertions, failures, a])
	quit(1 if failures else 0)
