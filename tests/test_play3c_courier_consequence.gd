extends SceneTree

# ==============================================================================
# PLAY-3C: COURIER — WORLD CONSEQUENCE
# ==============================================================================
# Until now a courier contract bought what was on your back and the cargo
# vanished: the town's shortfall, its prices and its next posting never knew
# you had come. Owner brief: cargo the player delivers must ENTER the
# settlement, so the shortfall, the prices and the next posting all recompute
# from it.
#
#   G1 The cargo arrives: the town's stock rises by exactly what was handed over
#   G2 Prices recompute at once from the new stock, not at the next tick
#   G3 The receipt carries before/after, and it matches the world
#   G4 THE CONSEQUENCE: ending a shortfall ends the urgent posting
#   G5 The player reads it: the delivery dialog text names stock, price and
#      the shortage that ended
#   G6 Nothing is added twice, and a saved world keeps the delivered stock
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-3C: " + label)

func _init() -> void:
	call_deferred("run")

func courier_at(world: WorldState, settlement_id: StringName) -> Dictionary:
	for entry in Board.postings(world, settlement_id):
		if entry.archetype == "COURIER":
			return entry
	return {}

func run() -> void:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Hauler",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")
	var id: StringName = world.player.npc_id
	var town: SettlementState = world.get_settlement(&"settlement:gray_valley")

	# Stage a shortfall just past the urgent line, so a small delivery can end it.
	var target := town.get_target("water")
	town.inventory.set_amount("water", target - Board.COURIER_URGENT_GAP - 1)
	engine.recalculate_prices(town)
	for other in ["food", "scrap", "fuel"]:
		town.inventory.set_amount(other, town.get_target(other))
	engine.recalculate_prices(town)

	var posting := courier_at(world, town.id)
	check(not posting.is_empty(), "a courier job is posted")
	check(bool(posting.urgent), "the staged shortfall is posted as urgent")
	var objective: Dictionary = posting.definition.objectives[0]
	check(String(objective.resource) == "water", "the posting asks for the short resource")
	var quantity := int(objective.quantity)
	check(target - (town.inventory.get_amount("water") + quantity) < Board.COURIER_URGENT_GAP, "this delivery is enough to end the shortfall")
	check(String(posting.definition.description_zh).contains("倉庫"), "the contract says the cargo goes into the stores")
	check(not String(posting.definition.description_zh).contains("不會因此把倉庫填滿"), "the old 'it will not fill the stores' line is gone")

	var job_id := String(posting.definition.id)
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(id, job_id)).success, "accept")
	world.player.inventory.set_amount("water", quantity + 2)

	var stock_before := town.inventory.get_amount("water")
	var price_before := town.get_current_price("water")
	var result := engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(id, job_id))
	check(result.success, "turn in")

	# ---- G1 ----
	check(town.inventory.get_amount("water") == stock_before + quantity, "G1: the town's water rose by exactly the delivered %d" % quantity)
	check(world.player.inventory.get_amount("water") == 2, "G1: it left the player's pack")

	# ---- G2 ----
	check(town.get_current_price("water") < price_before, "G2: water got cheaper the moment it arrived (%.2f -> %.2f)" % [price_before, town.get_current_price("water")])
	check(is_equal_approx(town.get_current_price("water"), engine.calculate_price(town.get_base_price("water"), town.inventory.get_amount("water"), target)),
		"G2: the price is the market's own formula on the new stock")

	# ---- G3 ----
	var receipt: EventRecord = null
	for event in world.event_log:
		if event.type == "QUEST_RESOLVED" and String(event.payload.quest_id) == job_id:
			receipt = event
	check(receipt != null, "G3: a QUEST_RESOLVED receipt exists")
	var effects: Array = receipt.payload.get("settlement_effects", []) if receipt != null else []
	check(effects.size() == 1, "G3: one settlement effect per delivered resource")
	if effects.size() == 1:
		var effect: Dictionary = effects[0]
		check(String(effect.settlement_id) == "settlement:gray_valley" and String(effect.resource) == "water", "G3: the effect names the town and resource")
		check(int(effect.stock_before) == stock_before and int(effect.stock_after) == town.inventory.get_amount("water"), "G3: stock before/after match the world")
		check(is_equal_approx(float(effect.price_before), price_before) and is_equal_approx(float(effect.price_after), town.get_current_price("water")), "G3: price before/after match the world")
		check(bool(effect.was_short) and not bool(effect.still_short), "G3: the receipt records that the shortfall ended")
		var shown: Array = result.get("settlement_effects", [])
		check(shown.size() == 1 and int(shown[0].stock_after) == int(effect.stock_after) and bool(shown[0].still_short) == bool(effect.still_short),
			"G3: the result handed to the UI says what the receipt says")

		# ---- G5 ----
		var text := PlayerUIProjection.delivery_effect_text(world, effect)
		check(text.contains("%d → %d" % [stock_before, town.inventory.get_amount("water")]), "G5: the dialog shows the stock change: %s" % text)
		check(text.contains("水價"), "G5: the dialog shows the price")
		check(text.contains("不再算急缺"), "G5: the dialog says the shortage is over")

	# ---- G4 THE CONSEQUENCE ----
	var after := courier_at(world, town.id)
	check(not bool(after.urgent), "G4: the board no longer posts this town's courier work as urgent")

	# A delivery that does not close the gap says so instead.
	var short_world := S1WorldData.create_s1_world()
	engine.commit_character_creation(short_world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Hauler",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	}))
	var deep: SettlementState = short_world.get_settlement(&"settlement:gray_valley")
	deep.inventory.set_amount("water", deep.get_target("water") - 40)
	engine.recalculate_prices(deep)
	var deep_posting := courier_at(short_world, deep.id)
	if String(deep_posting.definition.objectives[0].resource) == "water":
		var deep_id := String(deep_posting.definition.id)
		engine.commit_player_intent(short_world, PlayerIntent.create_accept_quest(short_world.player.npc_id, deep_id))
		short_world.player.inventory.set_amount("water", int(deep_posting.definition.objectives[0].quantity))
		var deep_result := engine.commit_player_intent(short_world, PlayerIntent.create_turn_in_quest(short_world.player.npc_id, deep_id))
		var deep_effect: Dictionary = deep_result.settlement_effects[0]
		check(bool(deep_effect.still_short), "G4: a partial delivery leaves the shortfall standing")
		check(PlayerUIProjection.delivery_effect_text(short_world, deep_effect).contains("仍缺"), "G5: and the dialog says how much is still missing")
		check(bool(courier_at(short_world, deep.id).urgent), "G4: a town still short keeps posting urgent work")
	else:
		check(false, "G4: the deep-shortfall world should post water")

	# ---- G6 ----
	var stock_now := town.inventory.get_amount("water")
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(id, job_id)).success, "G6: the job cannot be turned in twice")
	check(town.inventory.get_amount("water") == stock_now, "G6: a refused second turn-in adds nothing")
	var loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success, "G6: the world with a delivery receipt saves and loads: %s" % String(loaded.get("error", "")))
	if loaded.success:
		check(loaded.world.get_settlement(&"settlement:gray_valley").inventory.get_amount("water") == stock_now, "G6: a saved world keeps the delivered stock")
		check(loaded.world.to_canonical_json() == world.to_canonical_json(), "G6: save/load is byte-identical")
	check(engine.validate_invariants(world) == "", "G6: world invariants hold: %s" % engine.validate_invariants(world))

	print("PLAY-3C courier consequence: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
