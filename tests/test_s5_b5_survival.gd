extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-B5 PLAYER SURVIVAL TEST SUITE (Fast Lane)
# ==============================================================================
#   S1: Transit Consumption          (each travel day really costs 1 water, 1 food)
#   S2: Unmet -> Pressure            (only shortfall hurts; carrying enough does not)
#   S3: Exposure / Grace             (a hard day is survivable; sustained thirst is not)
#   S4: Settlement No Double Metabolism (settled shares the town's fortune)
#   S5: Death Authority              (a dead player cannot act)
#   S6: Save/Load                    (deprivation survives a save unchanged)
#
# THE QUESTION THIS SLICE ANSWERS:
#   If you set out across the wasteland without enough water, does it cost you
#   anything? Until now the answer was no, and "water 3" was decoration.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("       WASTELAND CHRONICLES - S5-B5 PLAYER SURVIVAL TEST SUITE                  ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	print("\n--- [GATE S1] Transit Consumption ---")

	var w1 := make_world(engine, 5, 5)
	var p1: PlayerState = w1.player
	engine.begin_player_travel(w1, PlayerIntent.create_travel(p1.npc_id, &"settlement:new_hope"))

	engine.execute_player_wait(w1)
	if p1.inventory.water != 4 or p1.inventory.food != 4:
		print("FAIL S1: after one travel day expected water=4 food=4, got water=%d food=%d" % [
			p1.inventory.water, p1.inventory.food])
		quit(1)
		return
	engine.execute_player_wait(w1)
	if p1.inventory.water != 3 or p1.inventory.food != 3:
		print("FAIL S1: after two travel days expected water=3 food=3, got water=%d food=%d" % [
			p1.inventory.water, p1.inventory.food])
		quit(1)
		return
	print("  Two days on the road drank 2 water and ate 2 food from the backpack")
	print("PASS GATE S1: Transit Consumption verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE S2] Unmet -> Pressure ---")

	# Well supplied: travelling with enough must cost no suffering at all.
	var w2 := make_world(engine, 9, 9)
	var p2: PlayerState = w2.player
	engine.begin_player_travel(w2, PlayerIntent.create_travel(p2.npc_id, &"settlement:new_hope"))
	for i in range(3):
		engine.execute_player_wait(w2)
	if p2.water_pressure != 0.0 or p2.water_exposure != 0.0:
		print("FAIL S2: a well-supplied traveller suffered! pressure=%.2f exposure=%.2f" % [
			p2.water_pressure, p2.water_exposure])
		quit(1)
		return
	print("  Carrying enough water: pressure 0.0, exposure 0.0 after the whole journey")
	print("  (a low backpack is not suffering; going WITHOUT is)")

	# Empty handed: the same journey must bite.
	var w3 := make_world(engine, 0, 0)
	var p3: PlayerState = w3.player
	engine.begin_player_travel(w3, PlayerIntent.create_travel(p3.npc_id, &"settlement:new_hope"))
	engine.execute_player_wait(w3)
	if p3.water_pressure <= 0.0 or p3.water_exposure <= 0.0:
		print("FAIL S2: travelling with no water produced no pressure or exposure!")
		quit(1)
		return
	print("  Travelling with nothing: pressure %.1f, exposure %.2f after one day" % [
		p3.water_pressure, p3.water_exposure])
	print("PASS GATE S2: Unmet -> Pressure verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE S3] Exposure / Grace Period ---")

	# A couple of dry days must NOT be fatal.
	var w4 := make_world(engine, 0, 0)
	var p4: PlayerState = w4.player
	engine.begin_player_travel(w4, PlayerIntent.create_travel(p4.npc_id, &"settlement:new_hope"))
	engine.execute_player_wait(w4)
	engine.execute_player_wait(w4)
	if not is_alive(w4):
		print("FAIL S3: player died after only two dry days - no grace period!")
		quit(1)
		return
	print("  Two dry days: still alive (exposure %.2f of %.1f grace)" % [
		p4.water_exposure, SimulationEngine.WATER_EXPOSURE_GRACE_DAYS])

	# Sustained deprivation must kill, and thirst must arrive before hunger.
	# The player is settled in a town whose water keeps failing, so the shortfall
	# is the world's, not a backpack accounting trick.
	var w5 := make_world(engine, 0, 15)
	var p5: PlayerState = w5.player
	var gv5: SettlementState = w5.get_settlement(&"settlement:gray_valley")
	var died_on := -1
	for day in range(1, 30):
		gv5.inventory.water = 0
		gv5.production.water = 0
		engine.execute_player_wait(w5)
		if not is_alive(w5):
			died_on = w5.current_day
			break
	if died_on < 0:
		print("FAIL S3: player never died of thirst! exposure=%.2f" % p5.water_exposure)
		quit(1)
		return
	if died_on <= int(SimulationEngine.WATER_EXPOSURE_GRACE_DAYS):
		print("FAIL S3: died on day %d, inside the %d-day grace period!" % [
			died_on, int(SimulationEngine.WATER_EXPOSURE_GRACE_DAYS)])
		quit(1)
		return
	print("  A town that kept failing to find water killed the player on day %d (grace %d)" % [
		died_on, int(SimulationEngine.WATER_EXPOSURE_GRACE_DAYS)])

	var cause := death_cause(w5)
	if cause != "dehydration":
		print("FAIL S3: expected death by dehydration, got '%s'" % cause)
		quit(1)
		return
	print("  Recorded cause: %s (water grace %d < food grace %d, so thirst comes first)" % [
		cause, int(SimulationEngine.WATER_EXPOSURE_GRACE_DAYS), int(SimulationEngine.FOOD_EXPOSURE_GRACE_DAYS)])

	if engine.validate_invariants(w5) != "":
		print("FAIL S3: invariants broken after death: %s" % engine.validate_invariants(w5))
		quit(1)
		return
	print("  Life conservation and all invariants intact after the death")

	# And you must be able to die ON THE ROAD, which S4-B previously forbade.
	# This is the case the whole slice exists for: out of water, days from
	# anywhere, nobody coming.
	var w8 := make_world(engine, 0, 15)
	var gv8: SettlementState = w8.get_settlement(&"settlement:gray_valley")
	for i in range(5):
		gv8.inventory.water = 0
		gv8.production.water = 0
		engine.execute_player_wait(w8)
	if not is_alive(w8):
		print("FAIL S3: player died before even setting out!")
		quit(1)
		return
	engine.begin_player_travel(w8, PlayerIntent.create_travel(w8.player.npc_id, &"settlement:new_hope"))
	var road_death := -1
	for i in range(4):
		engine.execute_player_wait(w8)
		if not is_alive(w8):
			road_death = w8.current_day
			break
	if road_death < 0:
		print("FAIL S3: a player with no water survived the whole road! exposure=%.2f" % w8.player.water_exposure)
		quit(1)
		return
	var ls8: NpcLifeState = w8.npc_life_state_registry.get_life_state(w8.player.npc_id)
	if ls8.population_container_type != NpcLifeState.ContainerType.NONE:
		print("FAIL S3: a dead traveller is still inside a population container!")
		quit(1)
		return
	if engine.validate_invariants(w8) != "":
		print("FAIL S3: invariants broken after a death on the road: %s" % engine.validate_invariants(w8))
		quit(1)
		return
	print("  Died on the road on day %d; party headcount and life conservation both intact" % road_death)
	print("  (S4-B forbade IN_TRANSIT -> DEAD; S5-B5 makes the wasteland able to kill you)")
	print("PASS GATE S3: Exposure / Grace Period verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE S4] Settlement: No Double Metabolism ---")

	var w6 := make_world(engine, 5, 5)
	var p6: PlayerState = w6.player
	var bp_water: int = p6.inventory.water
	var bp_food: int = p6.inventory.food
	for i in range(5):
		engine.execute_player_wait(w6)
	if p6.inventory.water != bp_water or p6.inventory.food != bp_food:
		print("FAIL S4: settled player consumed the backpack! water %d->%d food %d->%d" % [
			bp_water, p6.inventory.water, bp_food, p6.inventory.food])
		quit(1)
		return
	print("  5 days settled in a healthy town: backpack untouched (%d water, %d food)" % [
		p6.inventory.water, p6.inventory.food])

	# In a town that cannot meet its own needs, the player suffers with it -
	# even with a full backpack, and without that backpack being consumed.
	var w7 := make_world(engine, 9, 9)
	var p7: PlayerState = w7.player
	var gv: SettlementState = w7.get_settlement(&"settlement:gray_valley")
	var bp7_water: int = p7.inventory.water
	for i in range(4):
		gv.inventory.water = 0
		gv.production.water = 0
		engine.execute_player_wait(w7)
	if p7.water_exposure <= 0.0:
		print("FAIL S4: the town ran dry but the player was personally immune!")
		quit(1)
		return
	if p7.inventory.water != bp7_water:
		print("FAIL S4: settled player consumed the backpack while the town was dry!")
		quit(1)
		return
	var town_ratio := engine._settlement_unmet_ratio(gv, "water")
	print("  Town ran dry: player exposure rose to %.2f while the backpack stayed at %d" % [
		p7.water_exposure, p7.inventory.water])
	print("  Player shares the settlement's fortune (today unmet ratio %.2f), never charged twice" % town_ratio)
	print("PASS GATE S4: Settlement No Double Metabolism verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE S5] Death Authority ---")

	var dead_world := w5
	var dead_id: StringName = dead_world.player.npc_id

	var refusals := 0
	var wait_res := engine.execute_player_wait(dead_world)
	if wait_res.get("success", false):
		print("FAIL S5: a dead player waited another day!")
		quit(1)
		return
	refusals += 1

	var travel_res := engine.commit_player_intent(
		dead_world, PlayerIntent.create_travel(dead_id, &"settlement:new_hope"))
	if travel_res.get("success", false):
		print("FAIL S5: a dead player travelled!")
		quit(1)
		return
	refusals += 1

	var buy_res := engine.execute_player_buy(dead_world, &"water", 1)
	if buy_res.get("success", false):
		print("FAIL S5: a dead player went shopping!")
		quit(1)
		return
	refusals += 1

	var sell_res := engine.execute_player_sell(dead_world, &"water", 1)
	if sell_res.get("success", false):
		print("FAIL S5: a dead player traded!")
		quit(1)
		return
	refusals += 1

	print("  %d intents refused after death: %s" % [refusals, String(wait_res.get("error", "")).split(":")[0]])
	print("  You cannot keep running caravans after you die in the sand")
	print("PASS GATE S5: Death Authority verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE S6] Save / Load ---")

	# Build a world mid-deprivation, then compare uninterrupted vs save/loaded.
	var wa := make_world(engine, 0, 15)
	var gva: SettlementState = wa.get_settlement(&"settlement:gray_valley")
	for i in range(4):
		gva.inventory.water = 0
		gva.production.water = 0
		engine.execute_player_wait(wa)
	if wa.player.water_exposure <= 0.0:
		print("FAIL S6: the fixture never became deprived - the gate would be vacuous!")
		quit(1)
		return
	var mid_exposure: float = wa.player.water_exposure

	var wb := WorldState.from_dict(JSON.parse_string(JSON.stringify(wa.to_dict())))
	if wb == null:
		print("FAIL S6: loader refused a snapshot containing a deprived player!")
		quit(1)
		return
	if wb.player.water_exposure != wa.player.water_exposure or wb.player.food_exposure != wa.player.food_exposure:
		print("FAIL S6: exposure changed across persistence: %.4f -> %.4f" % [
			wa.player.water_exposure, wb.player.water_exposure])
		quit(1)
		return
	print("  Mid-deprivation snapshot restored exactly (water exposure %.2f)" % mid_exposure)

	for i in range(6):
		engine.execute_player_wait(wa)
		engine.execute_player_wait(wb)
	var sha_a := wa.to_canonical_json().sha256_text()
	var sha_b := wb.to_canonical_json().sha256_text()
	if sha_a != sha_b:
		print("FAIL S6: interrupted and uninterrupted deprivation diverged!")
		print("  A = %s" % sha_a)
		print("  B = %s" % sha_b)
		quit(1)
		return
	print("  Six further days on both sides: identical worlds, SHA %s" % sha_a)
	print("  (including whether the player lived or died)")
	print("PASS GATE S6: Save / Load verified.")

	print("\n================================================================================")
	print("ALL S5-B5 PLAYER SURVIVAL GATES (S1 ~ S6) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Helpers
# ==============================================================================

func make_world(engine: SimulationEngine, water: int, food: int) -> WorldState:
	var w := S1WorldData.create_s1_world()
	engine.materialize_player(w, &"settlement:gray_valley", "Drifter", 25)
	w.player.inventory.set_amount("water", water)
	w.player.inventory.set_amount("food", food)
	return w

func is_alive(w: WorldState) -> bool:
	var ls: NpcLifeState = w.npc_life_state_registry.get_life_state(w.player.npc_id)
	return ls != null and ls.is_alive()

func death_cause(w: WorldState) -> String:
	for evt in w.event_log:
		if evt.type == "PLAYER_DIED":
			return String(evt.payload.get("cause", ""))
	return ""
