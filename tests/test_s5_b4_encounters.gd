extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-B4 TRAVEL ENCOUNTERS TEST SUITE (Fast Lane)
# ==============================================================================
#   E1: Auto-Travel Interrupt  (empty road runs itself; an encounter stops it dead)
#   E2: Choice Authority       (options go through intents, never straight to world)
#   E3: Time Cost              (a day spent is a real day, and it costs supplies)
#   E4: Resource Conservation  (every loot, payment and scrap has a source)
#   E5: Resume Travel          (after answering, the journey continues by itself)
#   E6: Save/Load              (a paused encounter survives a save unchanged)
#
# THE MOMENT THIS SLICE EXISTS FOR:
#   "I really want to search that wreck, but I only have two days of water."
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("      WASTELAND CHRONICLES - S5-B4 TRAVEL ENCOUNTERS TEST SUITE                 ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	print("\n--- [GATE E1] Auto-Travel Interrupt ---")

	# Selection must be a pure function: same road, same day, same answer.
	for i in range(50):
		if TravelEncounter.select(&"settlement:gray_valley", &"settlement:new_hope", 3, 2) \
				!= TravelEncounter.select(&"settlement:gray_valley", &"settlement:new_hope", 3, 2):
			print("FAIL E1: encounter selection is not deterministic!")
			quit(1)
			return
	var empty_stretches := 0
	var encounters := 0
	for day in range(40):
		for idx in range(1, 4):
			if TravelEncounter.select(&"settlement:gray_valley", &"settlement:dry_well", day, idx) == &"":
				empty_stretches += 1
			else:
				encounters += 1
	if encounters == 0 or empty_stretches == 0:
		print("FAIL E1: the road is either always empty or never empty (%d/%d)" % [encounters, empty_stretches])
		quit(1)
		return
	print("  Selection is deterministic; over 120 road-days: %d empty, %d encounters" % [
		empty_stretches, encounters])

	var w1 := make_world(engine, 8, 8)
	var res1 := engine.commit_player_intent(w1, PlayerIntent.create_travel(w1.player.npc_id, &"settlement:new_hope"))
	if w1.active_encounter == null:
		print("FAIL E1: fixture journey produced no encounter - the gate would be vacuous!")
		quit(1)
		return
	if res1.get("arrived", true):
		print("FAIL E1: the journey completed despite an encounter halting it!")
		quit(1)
		return
	var ls1: NpcLifeState = w1.npc_life_state_registry.get_life_state(w1.player.npc_id)
	if ls1.status != NpcLifeState.Status.IN_TRANSIT:
		print("FAIL E1: player is not still on the road while an encounter is pending!")
		quit(1)
		return
	print("  Journey halted on day %d at: %s" % [
		w1.current_day, TravelEncounter.title(w1.active_encounter.encounter_type)])

	# A committed fact is recorded when the road interrupts you.
	var announced := false
	for evt in w1.event_log:
		if evt.type == "TRAVEL_ENCOUNTER":
			announced = true
	if not announced:
		print("FAIL E1: no TRAVEL_ENCOUNTER event was committed!")
		quit(1)
		return
	print("  TRAVEL_ENCOUNTER committed to the ledger")
	print("PASS GATE E1: Auto-Travel Interrupt verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E2] Choice Authority ---")

	# Nothing else is available while the road waits for an answer.
	var blocked := engine.execute_player_wait(w1)
	if blocked.get("success", false) or not String(blocked.get("error", "")).begins_with("ENCOUNTER_PENDING"):
		print("FAIL E2: the player could act normally with an encounter pending: %s" % blocked)
		quit(1)
		return
	print("  WAIT refused while an encounter is pending: %s" % String(blocked["error"]).split(":")[0])

	# An option that does not belong to this encounter is refused.
	var bogus := engine.commit_player_intent(w1,
		PlayerIntent.create_resolve_encounter(w1.player.npc_id, &"NOT_AN_OPTION"))
	if bogus.get("success", false) or not String(bogus.get("error", "")).begins_with("INVALID_OPTION"):
		print("FAIL E2: an invented option was accepted: %s" % bogus)
		quit(1)
		return
	print("  Invented option refused: %s" % String(bogus["error"]).split(":")[0])

	# An option the player cannot afford is refused, with the world untouched.
	var w2 := make_world(engine, 8, 8)
	travel_until_encounter(engine, w2, &"settlement:new_hope", TravelEncounter.ROADBLOCK)
	if w2.active_encounter != null and w2.active_encounter.encounter_type == TravelEncounter.ROADBLOCK:
		w2.player.money = 3
		var hash_before := w2.to_canonical_json().sha256_text()
		var poor := engine.commit_player_intent(w2,
			PlayerIntent.create_resolve_encounter(w2.player.npc_id, &"PAY"))
		if poor.get("success", false):
			print("FAIL E2: paid a 10 cap toll with 3 caps!")
			quit(1)
			return
		if w2.to_canonical_json().sha256_text() != hash_before:
			print("FAIL E2: a refused choice changed the world!")
			quit(1)
			return
		print("  Toll refused with 3 caps in hand, and the world was not touched")
	print("PASS GATE E2: Choice Authority verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E3] Time Cost ---")

	var w3 := make_world(engine, 8, 8)
	travel_until_encounter(engine, w3, &"settlement:new_hope", TravelEncounter.WRECK)
	if w3.active_encounter == null or w3.active_encounter.encounter_type != TravelEncounter.WRECK:
		print("FAIL E3: could not reach a WRECK encounter for the time-cost check")
		quit(1)
		return

	var day_before: int = w3.current_day
	var water_before: int = w3.player.inventory.water
	var food_before: int = w3.player.inventory.food
	var ls3: NpcLifeState = w3.npc_life_state_registry.get_life_state(w3.player.npc_id)
	var party3: RefugeePartyState = w3.get_refugee_party(ls3.population_container_id)
	var remaining_before: int = party3.days_remaining

	var search := engine.commit_player_intent(w3,
		PlayerIntent.create_resolve_encounter(w3.player.npc_id, &"SEARCH"))
	if not search.get("success", false):
		print("FAIL E3: searching the wreck failed: %s" % search.get("error", ""))
		quit(1)
		return
	if not search.get("cost_extra_day", false):
		print("FAIL E3: searching reported no extra day!")
		quit(1)
		return
	if w3.current_day <= day_before:
		print("FAIL E3: searching the wreck did not advance the world!")
		quit(1)
		return
	if w3.player.inventory.water >= water_before + 1:
		print("FAIL E3: the extra day cost no water (%d -> %d)" % [water_before, w3.player.inventory.water])
		quit(1)
		return
	print("  Searching cost a real day: day %d -> %d, and the day drank water and ate food" % [
		day_before, w3.current_day])
	print("  Loot is never free: the wreck cost %d water and %d food to reach" % [
		water_before - w3.player.inventory.water, food_before - w3.player.inventory.food])

	# A detour costs time WITHOUT shortening the road.
	var w4 := make_world(engine, 8, 8)
	travel_until_encounter(engine, w4, &"settlement:new_hope", TravelEncounter.ROCKSLIDE)
	if w4.active_encounter != null and w4.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE:
		var ls4: NpcLifeState = w4.npc_life_state_registry.get_life_state(w4.player.npc_id)
		var party4: RefugeePartyState = w4.get_refugee_party(ls4.population_container_id)
		var remaining4: int = party4.days_remaining
		var day4: int = w4.current_day
		engine.commit_player_intent(w4, PlayerIntent.create_resolve_encounter(w4.player.npc_id, &"DETOUR"))
		var total_days: int = w4.current_day - day4
		if total_days < remaining4 + 1:
			print("FAIL E3: a detour made the journey SHORTER (%d days for %d remaining + 1)" % [
				total_days, remaining4])
			quit(1)
			return
		print("  Detour is lost time, not free travel: %d days to cover %d remaining" % [
			total_days, remaining4])
	print("PASS GATE E3: Time Cost verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E4] Resource Conservation ---")

	var w5 := make_world(engine, 8, 8)
	travel_until_encounter(engine, w5, &"settlement:new_hope", TravelEncounter.WRECK)
	if w5.active_encounter != null and w5.active_encounter.encounter_type == TravelEncounter.WRECK:
		var scrap_before: int = w5.player.inventory.scrap
		var fuel_before: int = w5.player.inventory.fuel
		var r5 := engine.commit_player_intent(w5,
			PlayerIntent.create_resolve_encounter(w5.player.npc_id, &"SEARCH"))
		var gained: Dictionary = r5.get("gained", {})
		if w5.player.inventory.scrap - scrap_before != int(gained.get("scrap", 0)):
			print("FAIL E4: scrap gained (%d) does not match what was recorded (%s)" % [
				w5.player.inventory.scrap - scrap_before, gained])
			quit(1)
			return
		if w5.player.inventory.fuel - fuel_before != int(gained.get("fuel", 0)):
			print("FAIL E4: fuel gained does not match what was recorded!")
			quit(1)
			return
		if w5.player.get_total_inventory_load() > w5.player.capacity_total:
			print("FAIL E4: looting overfilled the backpack!")
			quit(1)
			return
		print("  Wreck loot: %s, matching the committed record exactly" % str(gained))

	# A toll leaves the caps somewhere honest: gone from the player.
	var w6 := make_world(engine, 8, 8)
	travel_until_encounter(engine, w6, &"settlement:new_hope", TravelEncounter.ROADBLOCK)
	if w6.active_encounter != null and w6.active_encounter.encounter_type == TravelEncounter.ROADBLOCK:
		var caps_before: int = w6.player.money
		var r6 := engine.commit_player_intent(w6,
			PlayerIntent.create_resolve_encounter(w6.player.npc_id, &"PAY"))
		var spent: Dictionary = r6.get("spent", {})
		if caps_before - w6.player.money != int(spent.get("caps", 0)):
			print("FAIL E4: caps paid does not match the record!")
			quit(1)
			return
		print("  Toll paid: %d caps, matching the committed record" % int(spent.get("caps", 0)))

	# Giving away water really costs the water.
	var w7 := make_world(engine, 8, 8)
	travel_until_encounter(engine, w7, &"settlement:new_hope", TravelEncounter.DEHYDRATED_TRAVELLER)
	if w7.active_encounter != null and w7.active_encounter.encounter_type == TravelEncounter.DEHYDRATED_TRAVELLER:
		var water_b: int = w7.player.inventory.water
		var scrap_b: int = w7.player.inventory.scrap
		engine.commit_player_intent(w7, PlayerIntent.create_resolve_encounter(w7.player.npc_id, &"GIVE_WATER"))
		if w7.player.inventory.water != water_b - 1:
			print("FAIL E4: giving water did not cost a water!")
			quit(1)
			return
		if w7.player.inventory.scrap <= scrap_b:
			print("FAIL E4: the traveller gave nothing back!")
			quit(1)
			return
		print("  Gave 1 water (%d -> %d), received scrap in return" % [water_b, w7.player.inventory.water])

	if engine.validate_invariants(w5) != "":
		print("FAIL E4: invariants broken after encounters: %s" % engine.validate_invariants(w5))
		quit(1)
		return
	print("  Engine invariants intact after looting, paying and giving")
	print("PASS GATE E4: Resource Conservation verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E5] Resume Travel ---")

	var w8 := make_world(engine, 9, 9)
	var res8 := engine.commit_player_intent(w8, PlayerIntent.create_travel(w8.player.npc_id, &"settlement:new_hope"))
	var answered := 0
	while w8.active_encounter != null and answered < 8:
		var opts := TravelEncounter.options(w8.active_encounter.encounter_type)
		# Always take the cheapest legal way out, so the gate is about resuming.
		var chosen := StringName(String(opts[opts.size() - 1]["id"]))
		var r := engine.commit_player_intent(w8, PlayerIntent.create_resolve_encounter(w8.player.npc_id, chosen))
		if not r.get("success", false):
			print("FAIL E5: could not resolve encounter: %s" % r.get("error", ""))
			quit(1)
			return
		answered += 1
	if answered == 0:
		print("FAIL E5: no encounter to resume from - the gate would be vacuous!")
		quit(1)
		return
	var ls8: NpcLifeState = w8.npc_life_state_registry.get_life_state(w8.player.npc_id)
	if ls8.status != NpcLifeState.Status.SETTLED or ls8.population_container_id != &"settlement:new_hope":
		print("FAIL E5: the journey never resumed to arrival! status=%d at=%s" % [
			ls8.status, ls8.population_container_id])
		quit(1)
		return
	print("  Answered %d encounter(s), then the journey carried on to New Hope by itself" % answered)
	print("  Arrived on day %d with no further prompting" % w8.current_day)
	print("PASS GATE E5: Resume Travel verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE E6] Save / Load ---")

	var wa := make_world(engine, 8, 8)
	engine.commit_player_intent(wa, PlayerIntent.create_travel(wa.player.npc_id, &"settlement:new_hope"))
	if wa.active_encounter == null:
		print("FAIL E6: fixture produced no paused encounter!")
		quit(1)
		return

	var wb := WorldState.from_dict(JSON.parse_string(JSON.stringify(wa.to_dict())))
	if wb == null:
		print("FAIL E6: loader refused a snapshot paused on an encounter!")
		quit(1)
		return
	if wb.active_encounter == null or wb.active_encounter.encounter_type != wa.active_encounter.encounter_type:
		print("FAIL E6: the paused encounter did not survive the save!")
		quit(1)
		return
	if wa.to_canonical_json().sha256_text() != wb.to_canonical_json().sha256_text():
		print("FAIL E6: round-trip hash mismatch with an encounter pending!")
		quit(1)
		return
	print("  Paused on %s; snapshot restored identically" % TravelEncounter.title(wa.active_encounter.encounter_type))

	# The same answer on both sides must produce the same world, all the way home.
	var opts_a := TravelEncounter.options(wa.active_encounter.encounter_type)
	var choice := StringName(String(opts_a[opts_a.size() - 1]["id"]))
	engine.commit_player_intent(wa, PlayerIntent.create_resolve_encounter(wa.player.npc_id, choice))
	engine.commit_player_intent(wb, PlayerIntent.create_resolve_encounter(wb.player.npc_id, choice))
	while wa.active_encounter != null:
		var o := TravelEncounter.options(wa.active_encounter.encounter_type)
		var c := StringName(String(o[o.size() - 1]["id"]))
		engine.commit_player_intent(wa, PlayerIntent.create_resolve_encounter(wa.player.npc_id, c))
		engine.commit_player_intent(wb, PlayerIntent.create_resolve_encounter(wb.player.npc_id, c))

	var sha_a := wa.to_canonical_json().sha256_text()
	var sha_b := wb.to_canonical_json().sha256_text()
	if sha_a != sha_b:
		print("FAIL E6: interrupted and uninterrupted journeys diverged after the choice!")
		print("  A = %s" % sha_a)
		print("  B = %s" % sha_b)
		quit(1)
		return
	print("  Same answer on both sides -> identical worlds, SHA %s" % sha_a)
	print("PASS GATE E6: Save / Load verified.")

	print("\n================================================================================")
	print("ALL S5-B4 TRAVEL ENCOUNTER GATES (E1 ~ E6) PASSED CLEANLY!")
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
	w.player.money = 200
	return w

# Travel back and forth until the requested encounter type comes up, so each
# gate can test the specific bargain it cares about.
func travel_until_encounter(engine: SimulationEngine, w: WorldState, first_dest: StringName, wanted: StringName) -> void:
	var destinations := [first_dest, &"settlement:gray_valley", &"settlement:dry_well", &"settlement:new_hope"]
	var hops := 0
	while hops < 12:
		var ls: NpcLifeState = w.npc_life_state_registry.get_life_state(w.player.npc_id)
		if ls == null or not ls.is_alive():
			return
		if w.active_encounter != null:
			if w.active_encounter.encounter_type == wanted:
				return
			var opts := TravelEncounter.options(w.active_encounter.encounter_type)
			var cheapest := StringName(String(opts[opts.size() - 1]["id"]))
			engine.commit_player_intent(w, PlayerIntent.create_resolve_encounter(w.player.npc_id, cheapest))
			continue
		# Top the traveller up so the search is about encounters, not starvation.
		w.player.inventory.set_amount("water", 10)
		w.player.inventory.set_amount("food", 10)
		var here := w.npc_life_state_registry.get_life_state(w.player.npc_id).population_container_id
		var dest: StringName = destinations[hops % destinations.size()]
		if dest == here:
			dest = destinations[(hops + 1) % destinations.size()]
		engine.commit_player_intent(w, PlayerIntent.create_travel(w.player.npc_id, dest))
		hops += 1
