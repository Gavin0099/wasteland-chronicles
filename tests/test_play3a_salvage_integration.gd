extends SceneTree

# PLAY-3A integration: committed actions, physical stock and complete histories.
# Fixed S1/day-0 fixture: Gray Valley buys rope for 50 caps / 5 XP; its marked
# wreck contains one rope via STRIP_PARTS, plus two scrap. Rope's authored market
# value is 30 caps and Gray Valley's HIGH supply starts at six. These expected
# values are deliberately not computed by production loot or pricing code.
const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")
const JOB_ID: String = "job_gray_valley_salvage_0"
const SOURCE_ID: String = "salvage:job_gray_valley_salvage_0:gray_valley_dry_well:2"
const ORIGIN: StringName = &"settlement:gray_valley"
const DESTINATION: StringName = &"settlement:dry_well"
const TARGET_FIELDS: Array[String] = ["target_site", "target_route_origin", "target_route_destination", "target_item_id", "route_days", "source_wreck_id"]

var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-3A INTEGRATION: " + label)

func fixture(background: String = "MECHANIC") -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	var created: Dictionary = engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": String(ORIGIN), "character_name": "Salvage Integration",
		"age": 28, "background_id": background, "trait_ids": [],
	}))
	check(bool(created.success), "fixture uses normal character creation")
	# Explicit initial-ration fixture only. No loot, market stock, skill ranks,
	# encounter states, settlements or successful receipts are injected.
	world.player.inventory.water = 10
	world.player.inventory.food = 10
	return world

func commit(world: WorldState, intent: PlayerIntent, label: String) -> Dictionary:
	var result: Dictionary = engine.commit_player_intent(world, intent)
	check(bool(result.get("success", false)), label + ": " + String(result.get("error", "")))
	check(engine.validate_invariants(world) == "", label + " preserves global invariants")
	return result

func sha(world: WorldState) -> String:
	return world.to_canonical_json().sha256_text()

func checkpoint(world: WorldState, label: String) -> void:
	check(engine.validate_invariants(world) == "", label + " global invariants")
	var restored: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(bool(restored.success), label + " checked load: " + String(restored.get("error", "")))
	if restored.success:
		check(sha(restored.world) == sha(world), label + " full canonical SHA-256 save fixed point")
		if sha(restored.world) != sha(world):
			var original_json: String = world.to_canonical_json()
			var restored_json: String = restored.world.to_canonical_json()
			for index: int in range(mini(original_json.length(), restored_json.length())):
				if original_json[index] != restored_json[index]:
					print("FIRST SNAPSHOT DIFFERENCE before=", original_json.substr(maxi(0, index - 45), 140).c_escape(), " after=", restored_json.substr(maxi(0, index - 45), 140).c_escape())
					break

func resume(world: WorldState, label: String) -> WorldState:
	var restored: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(bool(restored.success), label + " resumes through checked JSON loader")
	return restored.world if restored.success else world

func accept(world: WorldState) -> bool:
	var posting: Dictionary = Board.find_posting(world, JOB_ID)
	check(not posting.is_empty() and posting.get("target_item_id") == "rope" and posting.get("source_wreck_id") == SOURCE_ID,
		"fixed day-zero posting retains reviewed rope/source identity")
	var result: Dictionary = commit(world, PlayerIntent.create_accept_quest(world.player.npc_id, JOB_ID), "accept salvage contract")
	checkpoint(world, "accepted contract")
	return bool(result.success)

func target_event_count(world: WorldState, event_type: String) -> int:
	var count: int = 0
	for event: EventRecord in world.event_log:
		if event.type == event_type and String(event.payload.get("salvage_job_id", "")) == JOB_ID:
			count += 1
	return count

func passive_option(world: WorldState) -> StringName:
	# Fixed policies never dynamically search for a loot-producing answer.
	match world.active_encounter.encounter_type:
		TravelEncounter.WRECK, TravelEncounter.DEHYDRATED_TRAVELLER, TravelEncounter.REFUGEE_COLUMN:
			return &"LEAVE"
		TravelEncounter.ROCKSLIDE:
			if engine.authorize_encounter_option(world, &"USE_ROPE") == "":
				return &"USE_ROPE"
			return &"CLEAR" if engine.authorize_encounter_option(world, &"CLEAR") == "" else &"DETOUR"
		TravelEncounter.ROADBLOCK:
			return &"PAY"
		TravelEncounter.BANDIT_AMBUSH:
			return &"BRIBE"
	return &""

func finish_journey(world: WorldState, destination: StringName, label: String) -> bool:
	for step: int in range(20):
		if world.active_encounter != null:
			check(not world.active_encounter.context.has("salvage_job_id"), label + " does not respawn a consumed target")
			var resolved: Dictionary = commit(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, passive_option(world)), label + " answer ordinary road encounter")
			if not resolved.success:
				return false
		elif world.pending_encounter_result >= 0:
			var continued: Dictionary = commit(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result), label + " acknowledge receipt and continue")
			if not continued.success:
				return false
		else:
			var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
			if life.status == NpcLifeState.Status.SETTLED:
				check(life.population_container_id == destination, label + " arrives at intended settlement")
				return life.population_container_id == destination
			check(false, label + " travel stopped without encounter or receipt")
			return false
	check(false, label + " journey exceeds bounded fixture")
	return false

func reject_atomically(world: WorldState, intent: PlayerIntent, label: String) -> void:
	var before: String = sha(world)
	var result: Dictionary = engine.commit_player_intent(world, intent)
	check(not result.success and sha(world) == before, label + " is refused without state, loot or XP changes")

func market_track(save_resume: bool) -> WorldState:
	var world: WorldState = fixture()
	if not accept(world):
		return world
	var settlement: SettlementState = world.get_settlement(ORIGIN)
	var initial_cash: int = settlement.market_cash
	var bought: Dictionary = commit(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rope", 1), "buy target rope from real market")
	check(bought.get("total_amount", -1) == 30 and world.player.money == 20, "market path actually spends 30 caps")
	check(settlement.market_cash == initial_cash + 30 and settlement.item_market != null and settlement.item_market.quantity("rope") == 5,
		"market receives payment and decrements six-rope stock to five")
	check(world.player.item_inventory.quantity("rope") == 1, "purchased rope physically enters inventory")
	checkpoint(world, "market purchase")
	if save_resume:
		world = resume(world, "market purchase")
	var turnin: Dictionary = commit(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB_ID), "deliver purchased rope")
	check(turnin.get("delivered", []) == [{"item_id": "rope", "quantity": 1}], "turn-in receipt records one actual rope")
	check(world.player.item_inventory.quantity("rope") == 0 and world.player.money == 70 and world.player.xp == 5,
		"market route consumes rope and pays exactly 50 caps / 5 quest XP")
	check(target_event_count(world, "TRAVEL_ENCOUNTER_RESOLVED") == 0 and world.current_day == 0, "market fulfillment requires no fabricated wreck or travel")
	reject_atomically(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB_ID), "duplicate market turn-in")
	checkpoint(world, "completed market route")
	return world

func salvage_track(save_resume: bool) -> Dictionary:
	var world: WorldState = fixture()
	var hashes: Array[String] = []
	if not accept(world):
		return {"world": world, "hashes": hashes}
	hashes.append(sha(world))
	var departed: Dictionary = commit(world, PlayerIntent.create_travel(world.player.npc_id, DESTINATION), "travel to marked road")
	if not departed.success or world.active_encounter == null:
		check(false, "real departure stops at marked wreck")
		return {"world": world, "hashes": hashes}
	check(world.active_encounter.encounter_type == TravelEncounter.WRECK and world.active_encounter.context.get("source_wreck_id") == SOURCE_ID,
		"real road encounter binds accepted source identity")
	check(world.active_encounter.context.get("salvage_job_id") == JOB_ID and world.active_encounter.context.get("salvage_target_item") == "rope",
		"marked encounter binds accepted contract and physical target item")
	check(departed.get("route_days", -1) == 3 and world.accepted_jobs[JOB_ID].route_days == 3,
		"published three-day journey matches actual committed legacy route")
	reject_atomically(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"QUICK_PICK"), "mechanic without scavenging rank two")
	reject_atomically(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"USE_WRENCH"), "mechanic without owned wrench")
	checkpoint(world, "active marked wreck")
	hashes.append(sha(world))
	if save_resume:
		world = resume(world, "active marked wreck")
	var before_day: int = world.current_day
	var before_water: int = world.player.inventory.water
	var before_food: int = world.player.inventory.food
	var resolved: Dictionary = commit(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"STRIP_PARTS"), "mechanic strips marked wreck")
	check(resolved.get("items_gained", {}) == {"rope": 1} and resolved.get("gained", {}) == {"scrap": 2},
		"reviewed fixture yields one rope and two scrap without target injection")
	check(world.player.item_inventory.quantity("rope") == 1 and world.player.inventory.scrap == 2, "salvage receipt matches physical inventory")
	check(world.current_day == before_day + 1 and world.player.inventory.water == before_water - 1 and world.player.inventory.food == before_food - 1,
		"one salvage day uses canonical time and exactly one ration of water / food")
	check(resolved.get("source_wreck_id") == SOURCE_ID and resolved.get("salvage_job_id") == JOB_ID, "resolved receipt preserves accepted source identity")
	check(resolved.get("xp_gained", 0) == 10 and world.player.xp == 10, "marked wreck grants only the existing first-wreck XP award")
	check(world.player.capability.get_practice_progress("MECHANICS").points == 1 and world.player.capability.get_rank("MECHANICS") == 2,
		"committed stripping grants one mechanics practice point without inventing a rank-up")
	check(world.active_encounter == null and world.pending_encounter_result >= 0, "resolution leaves a pending continuation receipt")
	reject_atomically(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"STRIP_PARTS"), "repeat target answer")
	checkpoint(world, "pending salvage receipt")
	hashes.append(sha(world))
	if save_resume:
		world = resume(world, "pending salvage receipt")
	if not finish_journey(world, DESTINATION, "outbound"):
		return {"world": world, "hashes": hashes}
	reject_atomically(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB_ID), "turn-in at wrong town")
	hashes.append(sha(world))
	var return_trip: Dictionary = commit(world, PlayerIntent.create_travel(world.player.npc_id, ORIGIN), "return to issuing workshop")
	if not return_trip.success or not finish_journey(world, ORIGIN, "return"):
		return {"world": world, "hashes": hashes}
	check(target_event_count(world, "TRAVEL_ENCOUNTER") == 1 and target_event_count(world, "TRAVEL_ENCOUNTER_RESOLVED") == 1,
		"roundtrip visits and resolves accepted target only once")
	var money_before: int = world.player.money
	var xp_before: int = world.player.xp
	var turnin: Dictionary = commit(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB_ID), "deliver recovered rope at original workshop")
	check(turnin.get("delivered", []) == [{"item_id": "rope", "quantity": 1}] and world.player.item_inventory.quantity("rope") == 0,
		"actual return and turn-in consume the recovered rope")
	check(world.player.money == money_before + 50 and world.player.xp == xp_before + 5, "salvage turn-in grants committed contract reward exactly once")
	check(world.quest_state.get_quest(JOB_ID).status == &"RESOLVED", "real salvage roundtrip closes contract before deadline")
	reject_atomically(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB_ID), "duplicate salvage turn-in")
	checkpoint(world, "completed salvage route")
	hashes.append(sha(world))
	return {"world": world, "hashes": hashes}

func test_skipped_target() -> void:
	var world: WorldState = fixture()
	if not accept(world):
		return
	commit(world, PlayerIntent.create_travel(world.player.npc_id, DESTINATION), "skip fixture departs")
	if world.active_encounter == null:
		check(false, "skip fixture reaches target")
		return
	var before_day: int = world.current_day
	var before_xp: int = world.player.xp
	var skipped: Dictionary = commit(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"LEAVE"), "skip marked wreck")
	check(skipped.get("source_wreck_id") == SOURCE_ID and skipped.get("items_gained", {}).is_empty() and world.player.item_inventory.quantity("rope") == 0,
		"skipping records source but grants no target item")
	check(world.current_day == before_day and world.player.xp == before_xp, "skipping costs no extra day and earns no XP")
	if not finish_journey(world, DESTINATION, "skip outbound"):
		return
	commit(world, PlayerIntent.create_travel(world.player.npc_id, ORIGIN), "skip return departs")
	if not finish_journey(world, ORIGIN, "skip return"):
		return
	check(world.quest_state.get_quest(JOB_ID).status == &"ACTIVE", "skipped contract still active on return")
	check(target_event_count(world, "TRAVEL_ENCOUNTER") == 1, "skipped target cannot be farmed on reverse route")
	reject_atomically(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB_ID), "skipped target without purchased replacement")
	checkpoint(world, "skipped target return")

func test_unproductive_approaches() -> void:
	# Same real target, two naturally created builds. The contract's rope belongs
	# to mechanical dismantling; neither SEARCH nor QUICK_PICK may inject it.
	for option: StringName in [&"SEARCH", &"QUICK_PICK"]:
		var world: WorldState = fixture("SCAVENGER")
		if not accept(world):
			return
		commit(world, PlayerIntent.create_travel(world.player.npc_id, DESTINATION), "scavenger reaches marked road")
		if world.active_encounter == null:
			check(false, "scavenger reaches actual target")
			return
		reject_atomically(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"STRIP_PARTS"), "scavenger without mechanics rank two")
		var before_day: int = world.current_day
		var before_water: int = world.player.inventory.water
		var before_food: int = world.player.inventory.food
		var result: Dictionary = commit(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option), "resolve fixed target with " + String(option))
		check(not result.get("items_gained", {}).has("rope") and world.player.item_inventory.quantity("rope") == 0,
			String(option) + " cannot fabricate the contract rope")
		if option == &"SEARCH":
			check(world.current_day == before_day + 1 and world.player.inventory.water == before_water - 1 and world.player.inventory.food == before_food - 1,
				"SEARCH still spends one canonical day and rations when target item is not recovered")
		else:
			check(world.current_day == before_day and world.player.inventory.water == before_water and world.player.inventory.food == before_food,
				"QUICK_PICK uses the scavenger's skill to avoid day and ration costs")
		reject_atomically(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option), "repeat " + String(option))
		checkpoint(world, "unproductive " + String(option) + " receipt")

func test_expired_and_legacy() -> void:
	var expired: WorldState = fixture()
	if not accept(expired):
		return
	for day: int in range(8):
		commit(expired, PlayerIntent.create_wait(expired.player.npc_id), "wait through accepted deadline")
	check(expired.quest_state.get_quest(JOB_ID).status == &"EXPIRED", "normal daily ticks expire accepted contract")
	commit(expired, PlayerIntent.create_travel(expired.player.npc_id, DESTINATION), "travel after expiration")
	check(expired.active_encounter == null or not expired.active_encounter.context.has("salvage_job_id"), "expired contract does not manufacture target encounter")
	check(target_event_count(expired, "TRAVEL_ENCOUNTER") == 0, "expired target has no encounter ledger entry")
	checkpoint(expired, "expired contract on road")

	var legacy: WorldState = fixture()
	if not accept(legacy):
		return
	# A pre-PLAY-3A accepted delivery contract has none of the new target fields.
	var legacy_data: Dictionary = legacy.to_dict()
	for field: String in TARGET_FIELDS:
		legacy_data.accepted_jobs[JOB_ID].erase(field)
	for event: Dictionary in legacy_data.events:
		if event.type == "QUEST_ACCEPTED":
			event.payload.erase("source_wreck_id")
	var loaded: Dictionary = WorldState.from_dict_checked(legacy_data)
	check(bool(loaded.success), "legacy accepted delivery job remains loadable")
	if not loaded.success:
		return
	legacy = loaded.world
	commit(legacy, PlayerIntent.create_travel(legacy.player.npc_id, DESTINATION), "legacy job travels normally")
	check(legacy.active_encounter == null or not legacy.active_encounter.context.has("salvage_job_id"), "legacy job does not acquire an invented target")
	check(target_event_count(legacy, "TRAVEL_ENCOUNTER") == 0, "legacy travel has no marked-target ledger record")
	checkpoint(legacy, "legacy accepted contract on road")

func reject_save(data: Dictionary, label: String) -> void:
	var result: Dictionary = WorldState.from_dict_checked(data)
	check(not result.success and result.get("world") == null and not String(result.get("error", "")).is_empty(), label + " fails checked load without partial world")

func test_corrupt_target_metadata() -> void:
	var world: WorldState = fixture()
	if not accept(world):
		return
	var accepted: Dictionary = world.to_dict()
	for field: String in TARGET_FIELDS:
		var missing: Dictionary = accepted.duplicate(true)
		missing.accepted_jobs[JOB_ID].erase(field)
		reject_save(missing, "partial metadata missing " + field)
	var invalid_fields: Array[Dictionary] = [
		{"field": "target_site", "value": []},
		{"field": "target_site", "value": ""},
		{"field": "target_route_origin", "value": "dry_well"},
		{"field": "target_route_destination", "value": "gray_valley"},
		{"field": "target_item_id", "value": "wrench"},
		{"field": "source_wreck_id", "value": "salvage:unaccepted:gray_valley_dry_well:2"},
		{"field": "route_days", "value": 0},
		{"field": "route_days", "value": 1.5},
		{"field": "route_days", "value": "2"},
	]
	for invalid: Dictionary in invalid_fields:
		var bad: Dictionary = accepted.duplicate(true)
		bad.accepted_jobs[JOB_ID][invalid.field] = invalid.value
		reject_save(bad, "malformed accepted " + String(invalid.field) + "=" + str(invalid.value))
	var unknown_route: Dictionary = accepted.duplicate(true)
	unknown_route.accepted_jobs[JOB_ID].target_route_destination = "unknown_town"
	unknown_route.accepted_jobs[JOB_ID].source_wreck_id = "salvage:" + JOB_ID + ":gray_valley_unknown_town:2"
	reject_save(unknown_route, "structurally matched source on nonexistent route")
	commit(world, PlayerIntent.create_travel(world.player.npc_id, DESTINATION), "corruption fixture reaches genuine target")
	if world.active_encounter == null:
		check(false, "corruption fixture has active target")
		return
	var active: Dictionary = world.to_dict()
	for field: String in ["source_wreck_id", "salvage_job_id", "salvage_target_item", "site_name"]:
		var forged: Dictionary = active.duplicate(true)
		forged.active_encounter.context[field] = "forged"
		reject_save(forged, "active target forged " + field)
	var stripped: Dictionary = active.duplicate(true)
	for field: String in ["source_wreck_id", "salvage_job_id", "salvage_target_item", "site_name"]:
		stripped.active_encounter.context.erase(field)
	reject_save(stripped, "active target metadata completely stripped despite committed encounter")
	commit(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"STRIP_PARTS"), "corruption fixture resolves genuine target")
	var pending: Dictionary = world.to_dict()
	for field: String in ["source_wreck_id", "salvage_job_id"]:
		var forged: Dictionary = pending.duplicate(true)
		forged.events[world.pending_encounter_result].payload[field] = "forged"
		reject_save(forged, "pending receipt forged " + field)
	checkpoint(world, "unchanged genuine target after rejected snapshots")

func run() -> void:
	var market_first: WorldState = market_track(false)
	var market_resumed: WorldState = market_track(true)
	check(sha(market_first) == sha(market_resumed), "market dual-track full canonical SHA-256 matches after resumed turn-in")
	var salvage_first: Dictionary = salvage_track(false)
	var salvage_resumed: Dictionary = salvage_track(true)
	check(salvage_first.hashes.size() == 5 and salvage_first.hashes == salvage_resumed.hashes,
		"salvage dual-track full canonical SHA-256 matches acceptance, encounter, receipt, arrival and final state")
	test_skipped_target()
	test_unproductive_approaches()
	test_expired_and_legacy()
	test_corrupt_target_metadata()
	print("PLAY-3A salvage integration: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
