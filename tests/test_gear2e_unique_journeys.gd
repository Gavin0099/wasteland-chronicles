extends SceneTree
const Fixture = preload("res://tests/fixtures/gear2e_world.gd")
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Unique = preload("res://simulation/unique_gear.gd")
const Well = preload("res://simulation/well_repair.gd")
const Rumors = preload("res://simulation/rumors.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Market = preload("res://simulation/item_market_catalogue.gd")
var engine := SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-2E: " + label)

func checked(world: WorldState) -> WorldState:
	var raw: String = world.to_canonical_json()
	var load: Dictionary = WorldState.from_json_checked(raw)
	check(load.success, "checked save " + String(load.get("error", "")))
	if not load.success:
		return world
	check(load.world.to_canonical_json() == raw and engine.validate_invariants(load.world) == "", "fixed point and global invariants")
	return load.world

func equal(a: WorldState, b: WorldState) -> void:
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "dual SHA-256 replay")
	check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants")

func reject(world: WorldState, method: String, prefix: String) -> void:
	var before: String = world.to_canonical_json()
	var result: Dictionary = Base.answer(world, StringName(method))
	check(not result.success and String(result.get("error", "")).begins_with(prefix), "refuse " + method + " " + prefix + ": " + String(result.get("error", "")))
	check(world.to_canonical_json() == before, "refusal preserves all state/cost/day/receipt")

func forged_retrieval(world: WorldState, method: String) -> void:
	for fault: String in ["cost", "prize", "day", "route", "site", "duplicate", "spent_type", "tracking"]:
		var wire: Dictionary = world.to_dict().duplicate(true)
		var found: Dictionary = {}
		for event: Dictionary in wire.events:
			if fault == "tracking" and event.type == "RUMOR_TRACKED":
				event.payload.rumor_id = "rumor:old_well"
			if fault == "route" and event.type == "PLAYER_TRAVEL_STARTED":
				event.payload.route_type = "WILDERNESS" if event.payload.route_type == "HIGHWAY" else "HIGHWAY"
			if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.payload.get("option") == method:
				found = event
				match fault:
					"cost": event.payload.spent.scrap = 1
					"prize": event.payload.items_gained = {"old_world_saber": 1}
					"day": event.day += 1
					"site": event.payload.place_id = "place:old_armory"
					"spent_type": event.payload.spent = []
		if fault == "duplicate":
			wire.events.append(found.duplicate(true))
			wire.event_count = wire.events.size()
		check(not WorldState.from_json_checked(JSON.stringify(wire)).success, "checked loader rejects forged retrieval " + fault)

func run() -> void:
	check(Registry.all_definitions().size() == 44, "44 authored identities")
	for id: String in ["military_gas_mask", "engineer_precision_tools", "old_world_saber"]:
		var definition: Dictionary = Registry.resolve(id).definition
		check(definition.quality == "UNIQUE" and definition.properties == [] and definition.unique_effect != "", "unique fixed single effect " + id)
		for town: String in ["gray_valley", "new_hope", "dry_well"]:
			var offered: bool = false
			for offer: Dictionary in Market.offers_for(town).offers:
				offered = offered or offer.item_id == id
			check(not offered, "no ordinary shop unique " + id + " " + town)
	check(Registry.resolve("military_gas_mask").definition.base_weight == 800 and Registry.resolve("engineer_precision_tools").definition.base_weight == 1600, "specified weights")
	check(Registry.resolve("military_gas_mask").definition.equip_slots == [], "mask used on entry, no new equipment slot")
	var world: WorldState = Fixture.checkpoint()
	check(Rumors.heard(world, "rumor:gas_mask") and Rumors.heard(world, "rumor:engineer_tools"), "heard in actual Dry Well")
	
	var twin: WorldState = checked(world)
	var day: int = world.current_day
	var water: int = world.player.inventory.water
	var food: int = world.player.inventory.food
	var remaining: int = world.get_refugee_party(world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id).days_remaining
	check(Base.answer(world, &"RECOVER_GAS_MASK").success and Base.answer(twin, &"RECOVER_GAS_MASK").success, "retrieve both tracks")
	check(world.current_day == day + 1 and world.player.inventory.scrap == 2 and world.player.inventory.water == water - 1 and world.player.inventory.food == food - 1, "one actual extra day, materials and metabolism")
	check(world.get_refugee_party(world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id).days_remaining == remaining, "retrieval does not advance road progress")
	check(world.player.item_inventory.contains("military_gas_mask") and world.player.item_inventory.contains("repair_toolbox"), "real mask and retained tool")
	check(Rumors.progress(world, "rumor:gas_mask").done and Rumors.progress(world, "rumor:gas_mask").next.contains("污染工坊"), "receipt settles rumor and opens next place")
	equal(world, twin)
	checked(world)
	forged_retrieval(world, "RECOVER_GAS_MASK")
	reject(world, "RECOVER_GAS_MASK", "ENCOUNTER_RESULT_PENDING")
	Fixture.finish(world)
	Fixture.finish(twin)
	Base.resupply(world)
	Base.resupply(twin)
	check(engine.commit_player_intent(world, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:engineer_tools")).success and engine.commit_player_intent(twin, PlayerIntent.create_track_rumor(twin.player.npc_id, "rumor:engineer_tools")).success, "track heard rumor in town")
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well", "WILDERNESS")).success and engine.commit_player_intent(twin, PlayerIntent.create_travel(twin.player.npc_id, &"settlement:dry_well", "WILDERNESS")).success, "prepared return via wilderness")
	Fixture.seek(world, "place:toxic_workshop")
	Fixture.seek(twin, "place:toxic_workshop")
	check(Base.answer(world, &"ENTER_TOXIC_WORKSHOP").success and Base.answer(twin, &"ENTER_TOXIC_WORKSHOP").success, "mask opens real workshop")
	check(world.player.item_inventory.contains("military_gas_mask") and world.player.item_inventory.contains("engineer_precision_tools") and world.player.inventory.scrap == 1, "tools acquired, mask retained, two more scrap spent")
	check(Rumors.progress(world, "rumor:engineer_tools").done and Rumors.progress(world, "rumor:engineer_tools").next.contains("井泵"), "new repair method clearly projected")
	equal(world, twin)
	checked(world)
	forged_retrieval(world, "ENTER_TOXIC_WORKSHOP")
	check(Unique.taken(world, "RECOVER_GAS_MASK") and Unique.taken(world, "ENTER_TOXIC_WORKSHOP"), "one-time ledger facts")
	var wrong: WorldState = Fixture.checkpoint("wrench")
	reject(wrong, "RECOVER_GAS_MASK", "TOOL_REQUIRED")
	check(Rumors.progress(wrong, "rumor:gas_mask").next.contains("工具"), "missing tool visible in rumor")
	wrong = Fixture.checkpoint()
	wrong.player.capability._data.skill_ranks.MECHANICS = 0
	reject(wrong, "RECOVER_GAS_MASK", "CAPABILITY_NOT_MET")
	wrong = Fixture.checkpoint()
	wrong.player.inventory.scrap = 1
	reject(wrong, "RECOVER_GAS_MASK", "INSUFFICIENT_SCRAP")
	wrong = Fixture.checkpoint()
	wrong.active_encounter.travel_day_index = 3
	reject(wrong, "RECOVER_GAS_MASK", "UNIQUE_SITE_REQUIRED")
	wrong = Fixture.checkpoint()
	for id: String in ["sledgehammer", "ballistic_vest", "precision_repair_kit"]:
		check(wrong.player.pickup_item(id).success, "bounded capacity fixture " + id)
	check(wrong.player.item_inventory.total_weight_g() == 11300, "independent weight fixture")
	check(wrong.player.pickup_item("flashlight").success, "fill remaining capacity")
	reject(wrong, "RECOVER_GAS_MASK", "ITEM_CAPACITY_EXCEEDED")
	wrong = Fixture.workshop(false)
	reject(wrong, "ENTER_TOXIC_WORKSHOP", "ITEM_NOT_HELD")
	check(Rumors.progress(wrong, "rumor:engineer_tools").next.contains("缺軍規"), "mask requirement visible")
	wrong = Fixture.workshop()
	wrong.player.inventory.scrap = 1
	reject(wrong, "ENTER_TOXIC_WORKSHOP", "INSUFFICIENT_SCRAP")
	var repair: WorldState = Fixture.engineer_site()
	var accepted: Dictionary = repair.accepted_jobs[Well.active_job(repair)]
	check(accepted.deadline_days == 9, "two-day procedure grants one extra contract day when accepted carrying unique")
	check(Gear.tool_grade(repair.player, "MECHANICS") == 3 and repair.player.capability.get_rank("MECHANICS") == 2, "unique supplies tool, never skill")
	reject(repair, "OVERHAUL_PUMP", "CAPABILITY_NOT_MET")
	var ready: Dictionary = PlayerUIProjection.project(repair)
	var before_projection: String = repair.to_canonical_json()
	ready = PlayerUIProjection.project(repair)
	var enabled: Dictionary = {}
	for option: Dictionary in ready.active_encounter.options:
		enabled[option.id] = option.enabled
	check(enabled.get("ENGINEER_OVERHAUL") == true and enabled.get("OVERHAUL_PUMP") == false, "projection shows unique method and real skill block")
	check(repair.to_canonical_json() == before_projection, "read-only projection")
	twin = checked(repair)
	day = repair.current_day
	water = repair.player.inventory.water
	food = repair.player.inventory.food
	var town: SettlementState = repair.get_settlement(&"settlement:gray_valley")
	var production: int = town.production.water
	check(Base.answer(repair, &"ENGINEER_OVERHAUL").success and Base.answer(twin, &"ENGINEER_OVERHAUL").success, "unique-specific method, both tracks")
	check(repair.current_day == day + 2 and repair.player.inventory.scrap == 0 and repair.player.inventory.water == water - 2 and repair.player.inventory.food == food - 2, "two real days and metabolism, three scrap")
	check(town.production.water == production + 2 and repair.player.item_inventory.contains("engineer_precision_tools"), "two permanent production, retained unique")
	check(repair.event_log[repair.pending_encounter_result].payload.elapsed_days == 2, "receipt proves actual two days")
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(repair, engine)
	check(shell.lbl_encounter_body.text.begins_with("抽水泵已修復：故障 → 運轉") and shell.lbl_encounter_body.text.contains("每日產水"), "actual UI leads with production effect")
	shell.free()
	equal(repair, twin)
	checked(repair)
	for fault: String in ["method", "tool", "duration", "effect"]:
		var wire: Dictionary = repair.to_dict().duplicate(true)
		for event: Dictionary in wire.events:
			if event.type == "EQUIPMENT_REPAIRED":
				if fault == "method": event.payload.method = "REPAIR_PUMP"
				if fault == "tool": event.payload.tool_id = "precision_repair_kit"
				if fault == "effect": event.payload.production_after += 1
			if fault == "duration" and event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.payload.option == "ENGINEER_OVERHAUL":
				event.payload.elapsed_days = 1
		check(not WorldState.from_json_checked(JSON.stringify(wire)).success, "checked loader rejects forged engineer " + fault)
	Fixture.finish(repair)
	Base.resupply(repair)
	check(engine.commit_player_intent(repair, PlayerIntent.create_travel(repair.player.npc_id, &"settlement:gray_valley")).success, "return to real issuer")
	Fixture.finish(repair)
	var money: int = repair.player.money
	var turn_in: Dictionary = engine.commit_player_intent(repair, PlayerIntent.create_turn_in_quest(repair.player.npc_id, Well.state(repair).quest_id))
	check(turn_in.success and repair.player.money == money + 80, "real once-paid repair contract: %s / money %d -> %d / day %d" % [turn_in, money, repair.player.money, repair.current_day])
	checked(repair)
	wrong = Fixture.engineer_site()
	wrong.player.item_inventory.remove_item("engineer_precision_tools", 1)
	reject(wrong, "ENGINEER_OVERHAUL", "ITEM_NOT_HELD")
	wrong = Fixture.engineer_site()
	wrong.quest_state.get_quest(Well.active_job(wrong)).deadline_day = wrong.current_day + 1
	reject(wrong, "ENGINEER_OVERHAUL", "REPAIR_DEADLINE_TOO_CLOSE")
	print("GEAR-2E: assertions=%d failures=%d" % [assertions, failures])
	quit(1 if failures else 0)
