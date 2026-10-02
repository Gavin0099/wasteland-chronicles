extends SceneTree

const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")
const TOWN: StringName = &"settlement:gray_valley"
const JOB: String = "job_gray_valley_item_request_rope_0"
var engine: SimulationEngine = SimulationEngine.new()
var failures: int = 0
var assertions: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ECON-1: " + label)

func fixture() -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": String(TOWN), "character_name": "Supplier", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "create player")
	world.player.money = 500
	return world

func snapshot(world: WorldState) -> String:
	return world.to_canonical_json().sha256_text()

func depleted(world: WorldState) -> void:
	var town: SettlementState = world.get_settlement(TOWN)
	town.item_market = ItemMarketState.seeded_for(TOWN)
	town.item_market.set_quantity("rope", 0)

func run_track(resume: bool) -> String:
	var world: WorldState = fixture()
	depleted(world)
	check(not Board.find_posting(world, JOB).is_empty(), "zero stock posts rope request")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, JOB)).success, "accept request")
	var contract: Dictionary = world.accepted_jobs[JOB].duplicate(true)
	# A real restock after acceptance ends advertising, but not the contract.
	world.get_settlement(TOWN).item_market.restock_for(TOWN, 1)
	check(Board.find_posting(world, JOB).is_empty(), "restock removes unaccepted offer")
	check(world.accepted_jobs[JOB] == contract, "accepted quantity and reward remain pinned")
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rope", 1)).success, "buy actual restocked rope even with an active request")
	check(world.get_settlement(TOWN).item_market.quantity("rope") == 0, "purchase actually empties stock")
	if resume:
		var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		check(loaded.success, "checked load between acquisition and delivery")
		if loaded.success:
			check(snapshot(loaded.world) == snapshot(world), "accepted request roundtrip")
			world = loaded.world
	var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB))
	check(result.success, "deliver")
	check(world.get_settlement(TOWN).item_market.quantity("rope") == 1, "exactly one rope enters town")
	check(not world.player.item_inventory.contains("rope", 1), "rope leaves player")
	check(Board.find_posting(world, JOB).is_empty(), "delivery ends demand")
	check(result.get("item_effects", []).size() == 1, "result carries one stock effect")
	var receipt: EventRecord = null
	for event: EventRecord in world.event_log:
		if event.type == "QUEST_RESOLVED" and String(event.payload.get("quest_id", "")) == JOB:
			receipt = event
	var effects: Array = receipt.payload.get("item_effects", []) if receipt != null else []
	check(effects.size() == 1 and String(effects[0].item_id) == "rope" and String(effects[0].settlement_id) == String(TOWN) and int(effects[0].stock_before) == 0 and int(effects[0].stock_after) == 1, "persistent receipt records actual item and stock change")
	check(int(result.item_effects[0].stock_before) == 0 and int(result.item_effects[0].stock_after) == 1, "receipt explains 0 to 1")
	var before: String = snapshot(world)
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB)).success, "duplicate delivery refused")
	check(snapshot(world) == before, "duplicate delivery mints no stock or reward")
	check(engine.validate_invariants(world) == "", "global invariants")
	var restored: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(restored.success and snapshot(restored.world) == before, "final save fixed point")
	return before

func run() -> void:
	var world: WorldState = fixture()
	var before: String = snapshot(world)
	check(not Board.wanted_items(world, TOWN).has("rope"), "six starting ropes are not a shortage")
	check(Board.find_posting(world, JOB).is_empty(), "stocked town has no rope request")
	Board.postings(world, TOWN)
	PlayerUIProjection.project(world)
	check(snapshot(world) == before and world.get_settlement(TOWN).item_market == null, "queries preserve lazy market and world")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, "job_gray_valley_salvage_0")).success, "ordinary recovery work exists without shortage")
	check(world.get_settlement(TOWN).item_market == null, "accept does not manufacture a stock change")
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rope", 1)).success, "accept does not block an in-stock item")
	var town: SettlementState = world.get_settlement(TOWN)
	check(town.item_market.quantity("rope") == 5, "actual purchase reduces six to five")
	depleted(world)
	check(Board.wanted_items(world, TOWN).has("rope"), "actual zero stock is wanted")
	before = snapshot(world)
	var buy: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rope", 1))
	check(not buy.success and String(buy.error).begins_with("INSUFFICIENT_ITEM_STOCK"), "out-of-stock rejection uses real stock")
	check(snapshot(world) == before, "failed buy is atomic")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, JOB)).success, "take shortage job")
	town.item_market.set_quantity("rope", ItemMarketState.MAX_STOCK)
	before = snapshot(world)
	var full: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, JOB))
	check(not full.success and String(full.error) == "MARKET_STOCK_LIMIT_EXCEEDED", "full destination rejects delivery")
	check(snapshot(world) == before, "full destination consumes neither item nor reward")
	var first: String = run_track(false)
	var second: String = run_track(true)
	check(first == second, "dual-track SHA-256 replay")
	print("ECON-1: assertions=%d failures=%d SHA256=%s" % [assertions, failures, first])
	quit(1 if failures else 0)
