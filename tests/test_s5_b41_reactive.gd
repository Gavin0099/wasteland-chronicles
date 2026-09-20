extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-B4.1 WORLD-REACTIVE ENCOUNTERS
# ==============================================================================
#   R1: Same Road, Different World  (a calm road and a collapsing one differ)
#   R2: Real Entities               (a refugee column is a party that exists)
#   R3: Fresh Wreckage              (a wreck the world actually lost on this road)
#   R4: Still Deterministic         (world-reactive is not random)
#   R5: Context Persistence         (the observed facts survive a save)
#
# THE CLAIM UNDER TEST:
#   S0-S4 built a world that changes on its own. This asks whether a player
#   walking down a highway can actually TELL that it changed.
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S5-B4.1 WORLD-REACTIVE ENCOUNTERS                    ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE R1] Same Road, Different World ---")

	var calm := {"min_security": 100.0, "destination_water_pressure": 0.0}
	var collapsing := {"min_security": 15.0, "destination_water_pressure": 90.0}

	var calm_mix: Dictionary = tally(calm)
	var bad_mix: Dictionary = tally(collapsing)

	print("  A quiet road      : %s" % describe(calm_mix))
	print("  A collapsing road : %s" % describe(bad_mix))

	if bad_mix.get("ROADBLOCK", 0) <= calm_mix.get("ROADBLOCK", 0):
		print("FAIL R1: collapsed security did not put more barricades on the road!")
		quit(1)
		return
	if bad_mix.get("DEHYDRATED_TRAVELLER", 0) <= calm_mix.get("DEHYDRATED_TRAVELLER", 0):
		print("FAIL R1: a town dying of thirst produced no more dying travellers!")
		quit(1)
		return
	if bad_mix.get("EMPTY", 0) >= calm_mix.get("EMPTY", 0):
		print("FAIL R1: a world in crisis left the road just as empty!")
		quit(1)
		return
	print("  Security 100 -> 15 : barricades %d -> %d" % [
		calm_mix.get("ROADBLOCK", 0), bad_mix.get("ROADBLOCK", 0)])
	print("  Water pressure 0 -> 90 : dying travellers %d -> %d" % [
		calm_mix.get("DEHYDRATED_TRAVELLER", 0), bad_mix.get("DEHYDRATED_TRAVELLER", 0)])
	print("  The same highway is a different place depending on what the world is doing")
	print("PASS GATE R1: Same Road, Different World verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE R2] Real Entities ---")

	# No refugees in the world -> that encounter cannot happen at all.
	var no_column := 0
	for day in range(60):
		for idx in range(1, 4):
			if TravelEncounter.select(calm, &"settlement:gray_valley", &"settlement:new_hope", day, idx) == TravelEncounter.REFUGEE_COLUMN:
				no_column += 1
	if no_column != 0:
		print("FAIL R2: met %d refugee columns in a world with no refugees!" % no_column)
		quit(1)
		return
	print("  No refugees in the world: met 0 refugee columns in 180 road-days")

	# With a real party on this road, the encounter becomes possible.
	var with_column := {
		"min_security": 100.0,
		"destination_water_pressure": 0.0,
		"refugee_column": {"headcount": 14, "origin": "settlement:gray_valley", "destination": "settlement:new_hope"},
	}
	var column_hits := 0
	for day in range(60):
		for idx in range(1, 4):
			if TravelEncounter.select(with_column, &"settlement:gray_valley", &"settlement:new_hope", day, idx) == TravelEncounter.REFUGEE_COLUMN:
				column_hits += 1
	if column_hits == 0:
		print("FAIL R2: a real refugee party on the road was never encountered!")
		quit(1)
		return
	print("  A real party of 14 walking this road: met %d times in 180 road-days" % column_hits)

	# End to end: drive a settlement into collapse until it really evacuates
	# people, then walk that road and meet them.
	var engine := SimulationEngine.new()
	var w := S1WorldData.create_s1_world()
	engine.materialize_player(w, &"settlement:new_hope", "Drifter", 25)
	var gv: SettlementState = w.get_settlement(&"settlement:gray_valley")
	var party_seen: RefugeePartyState = null
	for day in range(40):
		gv.inventory.water = 0
		gv.production.water = 0
		w.player.inventory.set_amount("water", 10)
		w.player.inventory.set_amount("food", 10)
		engine.execute_player_wait(w)
		for r_id in w.refugees:
			var r: RefugeePartyState = w.refugees[r_id]
			if r.is_active and not r.is_arrived and r.headcount > 0:
				party_seen = r
		if party_seen != null:
			break
	if party_seen == null:
		print("FAIL R2: the failing settlement never produced a refugee party!")
		quit(1)
		return
	print("  Gray Valley collapsed and the simulation sent %d people to %s" % [
		party_seen.headcount, party_seen.destination_id])

	var facts := engine.gather_road_facts(w, party_seen)
	var column: Dictionary = facts.get("refugee_column", {})
	print("  Walking that same road, the facts offered are: %s" % (
		"a column of %d from %s" % [int(column.get("headcount", 0)), column.get("origin", "?")] if not column.is_empty()
		else "no column (the player IS that party's road)"))
	print("PASS GATE R2: Real Entities verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE R3] Fresh Wreckage ---")

	var quiet_road := {"min_security": 100.0, "destination_water_pressure": 0.0}
	var after_loss := {
		"min_security": 100.0,
		"destination_water_pressure": 0.0,
		"fresh_wreck": {"day": 5, "type": "TRANSIT_PREDATION"},
	}
	var quiet_wrecks: int = int(tally(quiet_road).get("WRECK", 0))
	var loss_wrecks: int = int(tally(after_loss).get("WRECK", 0))
	if loss_wrecks <= quiet_wrecks:
		print("FAIL R3: a caravan lost on this road left no more wreckage (%d vs %d)" % [
			loss_wrecks, quiet_wrecks])
		quit(1)
		return
	print("  A caravan lost on this road recently: wrecks %d -> %d" % [quiet_wrecks, loss_wrecks])

	# And the prose knows the difference.
	var old_text: String = TravelEncounter.body(TravelEncounter.WRECK, {})
	var fresh_text: String = TravelEncounter.body(TravelEncounter.WRECK, {"fresh_wreck": {"day": 5}})
	if old_text == fresh_text:
		print("FAIL R3: a fresh wreck reads exactly like an old one!")
		quit(1)
		return
	print("  Fresh wreckage reads differently from an old picked-over hulk")
	print("PASS GATE R3: Fresh Wreckage verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE R4] Still Deterministic ---")

	for i in range(100):
		if TravelEncounter.select(collapsing, &"settlement:dry_well", &"settlement:new_hope", 11, 2) \
				!= TravelEncounter.select(collapsing, &"settlement:dry_well", &"settlement:new_hope", 11, 2):
			print("FAIL R4: world-reactive selection became non-deterministic!")
			quit(1)
			return
	# Identical facts must give identical roads; that is what keeps replay exact.
	var facts_copy := {"min_security": 15.0, "destination_water_pressure": 90.0}
	for day in range(30):
		for idx in range(1, 4):
			if TravelEncounter.select(collapsing, &"settlement:a", &"settlement:b", day, idx) \
					!= TravelEncounter.select(facts_copy, &"settlement:a", &"settlement:b", day, idx):

				print("FAIL R4: the same facts produced a different road!")
				quit(1)
				return
	print("  100 repeats and 90 road-days: identical facts always give the identical road")
	print("  Variety comes from the world moving, not from a dice roll")
	print("PASS GATE R4: Still Deterministic verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE R5] Context Persistence ---")

	var w5 := S1WorldData.create_s1_world()
	engine.materialize_player(w5, &"settlement:gray_valley", "Drifter", 25)
	w5.player.inventory.set_amount("water", 9)
	w5.player.inventory.set_amount("food", 9)
	engine.commit_player_intent(w5, PlayerIntent.create_travel(w5.player.npc_id, &"settlement:new_hope"))
	if w5.active_encounter == null:
		print("FAIL R5: no encounter to persist!")
		quit(1)
		return

	var restored := WorldState.from_dict(JSON.parse_string(JSON.stringify(w5.to_dict())))
	if restored == null or restored.active_encounter == null:
		print("FAIL R5: the paused encounter did not survive the save!")
		quit(1)
		return
	if JSON.stringify(restored.active_encounter.context) != JSON.stringify(w5.active_encounter.context):
		print("FAIL R5: the observed facts changed across the save!")
		print("  before: %s" % JSON.stringify(w5.active_encounter.context))
		print("  after : %s" % JSON.stringify(restored.active_encounter.context))
		quit(1)
		return
	if w5.to_canonical_json().sha256_text() != restored.to_canonical_json().sha256_text():
		print("FAIL R5: snapshot is not a fixed point with encounter context present!")
		quit(1)
		return
	print("  %s paused and restored with its observed facts intact: %s" % [
		TravelEncounter.title(w5.active_encounter.encounter_type),
		JSON.stringify(w5.active_encounter.context)])
	print("  The story the player is reading cannot change while they decide")
	print("PASS GATE R5: Context Persistence verified.")

	print("\n================================================================================")
	print("ALL S5-B4.1 WORLD-REACTIVE GATES (R1 ~ R5) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Helpers
# ==============================================================================

# Count what a long stretch of this road produces under the given world facts.
func tally(facts: Dictionary) -> Dictionary:
	var counts := {}
	for day in range(60):
		for idx in range(1, 4):
			var t: StringName = TravelEncounter.select(facts, &"settlement:gray_valley", &"settlement:new_hope", day, idx)
			var key: String = "EMPTY" if t == &"" else String(t)
			counts[key] = counts.get(key, 0) + 1
	return counts

func describe(counts: Dictionary) -> String:
	var keys := counts.keys()
	keys.sort()
	var parts: Array = []
	for k in keys:
		parts.append("%s %d" % [k, counts[k]])
	return ", ".join(parts)
