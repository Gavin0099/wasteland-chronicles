extends SceneTree

# ==============================================================================
# PLACE-4: FOUR ROAD PLACES THAT ARE PART OF THE WORLD
# ==============================================================================
# Owner rule for this slice: a place only counts if it can change the player's
# route AND feeds a settlement's economy, work or danger. "Arrive -> search ->
# take -> leave" does not count. So the gates are about consequences:
#
#   G1 Four places, three different verbs, and every resource place feeds towns
#      that are really short of that resource (by the world's own numbers)
#   G2 A place is met on its road, on its day, and offers its own decision
#   G3 TAKE: the goods are yours and the place is gone for everyone
#   G4 MARK -> ROUTE -> REPORT: marking for a town you are not heading to means
#      walking there; the report raises that town's production for good
#   G5 CAMP: raiding it silences the wilderness and stops raider bounties until
#      it re-forms
#   G6 WRECK: the world refills it - a caravan lost on that road leaves scrap
#   G7 Walking past is an answer: it is not asked again for a while
#   G8 The map shows all four, names only what was found; saves round-trip
# ==============================================================================

const RoadPlaces = preload("res://simulation/road_places.gd")
const Board = preload("res://simulation/job_board.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLACE-4: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(origin: String = "settlement:gray_valley") -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "Walker",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 10)
	world.player.inventory.set_amount("food", 10)
	world.player.money = 100
	return world

func id_of(world: WorldState) -> StringName:
	return world.player.npc_id

# Travel and stop at the first encounter or arrival.
func travel(world: WorldState, destination: String, route: String = "") -> Dictionary:
	world.player.inventory.set_amount("water", 10)
	world.player.inventory.set_amount("food", 10)
	return engine.commit_player_intent(world, PlayerIntent.create_travel(id_of(world), StringName(destination), route))

func answer(world: WorldState, option: StringName) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id_of(world), option))

func carry_on(world: WorldState) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id_of(world), world.pending_encounter_result))

# Answer everything that is not the place under test by walking on, until the
# journey ends. Returns the place encounters met on the way.
func finish_journey(world: WorldState) -> void:
	var guard := 0
	while guard < 20:
		guard += 1
		if world.pending_encounter_result >= 0:
			carry_on(world)
			continue
		if not world.field_state.battle.is_empty():
			engine.commit_player_intent(world, PlayerIntent.create_field_action(id_of(world), {
				"command": "FLEE", "battle_id": world.field_state.battle.id, "turn": world.field_state.battle.turn}))
			continue
		if world.field_state.receipt >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_field_action(id_of(world), {"command": "CONFIRM", "receipt": world.field_state.receipt}))
			continue
		if world.active_encounter == null:
			return
		var choice := &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		answer(world, choice)

func settled_at(world: WorldState) -> String:
	return String(world.npc_life_state_registry.get_life_state(id_of(world)).population_container_id)

func run() -> void:
	# ---- G1 four places, three verbs, real shortages ----
	# ASP-1 added a secret; PLACE-4 is about the four road places.
	var road_ids: Array = RoadPlaces.ids().filter(func(id): return String(RoadPlaces.info(id).kind) != RoadPlaces.SECRET)
	check(road_ids.size() == 4, "G1: exactly four road places")
	var kinds := {}
	for place_id in road_ids:
		var p := RoadPlaces.info(place_id)
		kinds[String(p.kind)] = true
		check(TravelRoute.get_route_days(StringName(p.a), StringName(p.b), StringName(p.route)) > 0 or String(p.route) == "HIGHWAY",
			"G1: %s sits on a real road" % place_id)
	check(kinds.size() == 3, "G1: three different verbs, not four skins")
	var probe := fresh_world()
	for place_id in RoadPlaces.ids():
		var p := RoadPlaces.info(place_id)
		if String(p.kind) != RoadPlaces.RESOURCE:
			continue
		for town_id in RoadPlaces.towns(place_id):
			var town: SettlementState = probe.get_settlement(StringName(town_id))
			var net := town.production.get_amount(String(p.resource)) - town.consumption.get_amount(String(p.resource))
			check(net < 0, "G1: %s feeds %s, which really is short of %s (net %d/day)" % [place_id, town_id, p.resource, net])

	# ---- G2 met on its road and day, with its own decision ----
	var w := fresh_world()
	travel(w, "settlement:dry_well")
	check(w.active_encounter != null and w.active_encounter.encounter_type == TravelEncounter.PLACE_VISIT, "G2: the Gray Valley - Dry Well road stops at a place")
	check(String(w.active_encounter.context.get("place_id", "")) == "place:old_well", "G2: it is the old well")
	check(w.active_encounter.travel_day_index == 1, "G2: on the first day")
	var ids: Array = []
	for o in TravelEncounter.options(w.active_encounter.encounter_type, w.active_encounter.context):
		ids.append(String(o.id))
	check(ids == ["TAKE_RESOURCE", "MARK_A", "MARK_B", "LEAVE"], "G2: take it, give it to either town, or leave it: %s" % [ids])
	var labels := ""
	for o in TravelEncounter.options(w.active_encounter.encounter_type, w.active_encounter.context):
		labels += String(o.label)
	check(labels.contains("灰谷") and labels.contains("乾井"), "G2: the two towns are named")

	# ---- G3 TAKE ----
	var take_world := fresh_world()
	travel(take_world, "settlement:dry_well")
	# Leave room in the pack: this is about the place, not about capacity.
	take_world.player.inventory.set_amount("water", 4)
	take_world.player.inventory.set_amount("food", 4)
	var water_before := take_world.player.inventory.get_amount("water")
	var taken := answer(take_world, &"TAKE_RESOURCE")
	check(taken.success, "G3: take commits")
	check(take_world.player.inventory.get_amount("water") == water_before + 3, "G3: three water in the pack")
	check(String(RoadPlaces.state(take_world, "place:old_well").status) == "STRIPPED", "G3: the well is stripped")
	check(String(PlayerUIProjection.project(take_world).encounter_result.get("place_note", "")).contains("搬空"), "G3: the result says it is gone")
	finish_journey(take_world)
	check(settled_at(take_world) == "settlement:dry_well", "G3: arrived")
	travel(take_world, "settlement:gray_valley")
	var met_again := take_world.active_encounter != null and String(take_world.active_encounter.context.get("place_id", "")) == "place:old_well"
	check(not met_again, "G3: a stripped well is never offered again")
	finish_journey(take_world)

	# ---- G4 MARK -> ROUTE -> REPORT ----
	var mark := fresh_world()
	travel(mark, "settlement:dry_well")
	var marked := answer(mark, &"MARK_A")
	check(marked.success and String(marked.get("marked_for", "")) == "settlement:gray_valley", "G4: marked for Gray Valley while walking to Dry Well")
	check(String(PlayerUIProjection.project(mark).encounter_result.get("place_note", "")).contains("灰谷"), "G4: the result says where to take it")
	finish_journey(mark)
	check(settled_at(mark) == "settlement:dry_well", "G4: arrived at Dry Well")
	var gv: SettlementState = mark.get_settlement(&"settlement:gray_valley")
	var production_before := gv.production.get_amount("water")
	check(String(RoadPlaces.state(mark, "place:old_well").status) == "MARKED", "G4: arriving at the wrong town reports nothing")
	var money_before := mark.player.money
	var xp_before := mark.player.xp
	var home := travel(mark, "settlement:gray_valley")
	finish_journey(mark)
	check(settled_at(mark) == "settlement:gray_valley", "G4: walked back to Gray Valley to report")
	check(gv.production.get_amount("water") == production_before + 2, "G4: Gray Valley now produces 2 more water a day")
	check(String(RoadPlaces.state(mark, "place:old_well").status) == "CLAIMED" and String(RoadPlaces.state(mark, "place:old_well").claimed_by) == "settlement:gray_valley", "G4: the well is Gray Valley's")
	var report: EventRecord = null
	for event in mark.event_log:
		if event.type == "PLACE_REPORTED":
			report = event
	check(report != null, "G4: a PLACE_REPORTED receipt exists")
	if report != null:
		check(int(report.payload.production_after) - int(report.payload.production_before) == 2, "G4: the receipt carries the production change")
		check(int(report.payload.net_after) == int(report.payload.net_before) + 2, "G4: and the net change")
		check(mark.player.money >= money_before + 20 - 30 and mark.player.xp >= xp_before + 6, "G4: the finder's fee was paid")
		var text := PlayerUIProjection.place_report_text(mark, report.payload)
		check(text.contains("灰谷") and text.contains("→"), "G4: the report reads as a change to the town: %s" % text)
	# The world keeps the effect: over days the extra water shows in the stores.
	var later := mark.duplicate_state()
	var twin := fresh_world()
	for day in range(10):
		engine.tick(later)
		engine.tick(twin)
	check(later.get_settlement(&"settlement:gray_valley").inventory.get_amount("water") > twin.get_settlement(&"settlement:gray_valley").inventory.get_amount("water"),
		"G4: ten days on, Gray Valley holds more water than a world where nobody reported the well")

	# ---- G5 CAMP ----
	var camp := fresh_world("settlement:dry_well")
	camp.player.capability._data.skill_ranks["MELEE"] = 1
	camp.player.item_inventory.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(camp, PlayerIntent.create_equip_item(id_of(camp), &"scrap_machete", "main_hand"))
	travel(camp, "settlement:new_hope", "WILDERNESS")
	var guard := 0
	while guard < 5 and camp.active_encounter != null and String(camp.active_encounter.context.get("place_id", "")) != "place:hammer_camp":
		guard += 1
		var skip := &"FLEE_ROAD" if camp.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else &"LEAVE"
		if camp.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE:
			skip = &"DETOUR"
		answer(camp, skip)
		carry_on(camp)
	check(camp.active_encounter != null and String(camp.active_encounter.context.get("place_id", "")) == "place:hammer_camp", "G5: the wilderness road passes the camp")
	check(camp.active_encounter != null and camp.active_encounter.travel_day_index == 2, "G5: deep in, on day two")
	check(answer(camp, &"FIGHT").success, "G5: raiding the camp starts a fight")
	check(Field.battle_enemy(camp.field_state) == Enemies.HEAVY_RAIDER, "G5: against the heavy raider")
	check(String(camp.field_state.battle.get("place_id", "")) == "place:hammer_camp", "G5: the fight knows it is the camp")
	var turns := 0
	while not camp.field_state.battle.is_empty() and turns < 10:
		turns += 1
		engine.commit_player_intent(camp, PlayerIntent.create_field_action(id_of(camp), {
			"command": "ATTACK", "battle_id": camp.field_state.battle.id, "turn": camp.field_state.battle.turn}))
	var won := false
	for event in camp.event_log:
		if event.type == "FIELD_RESULT" and String(event.payload.get("place_id", "")) == "place:hammer_camp" and String(event.payload.outcome) == "VICTORY":
			won = true
	check(won, "G5: the raid is won and the receipt names the camp")
	check(RoadPlaces.camp_cleared(camp), "G5: the camp is cleared")
	var calm_facts := {"min_security": 100.0, "route_type": "WILDERNESS", "camp_cleared": true}
	for c in TravelEncounter.candidates(calm_facts):
		if c.type == TravelEncounter.BANDIT_AMBUSH:
			check(int(c.weight) == 0, "G5: with the camp gone the wilderness has no ambush")
	var raider_posted := false
	for day_offset in range(0, 6, 3):
		for settlement_id in ["settlement:new_hope", "settlement:dry_well"]:
			for entry in Board.postings(camp, StringName(settlement_id)):
				if String(entry.get("target_enemy", "")) == Enemies.HEAVY_RAIDER:
					raider_posted = true
		engine.tick(camp)
		engine.tick(camp)
		engine.tick(camp)
	check(not raider_posted, "G5: nobody posts the raider while his camp is burned out")
	check(String(RoadPlaces.status_text(camp, "place:hammer_camp")).contains("已清除"), "G5: the map says it is cleared")
	while camp.current_day <= int(RoadPlaces.state(camp, "place:hammer_camp").cleared_until):
		engine.tick(camp)
	check(not RoadPlaces.camp_cleared(camp), "G5: it re-forms after %d days" % RoadPlaces.CAMP_CLEARED_DAYS)

	# ---- G6 WRECK refilled by the world ----
	var wreck := fresh_world()
	travel(wreck, "settlement:new_hope")
	guard = 0
	while guard < 5 and wreck.active_encounter != null and String(wreck.active_encounter.context.get("place_id", "")) != "place:convoy_wreck":
		guard += 1
		answer(wreck, &"LEAVE" if wreck.active_encounter.encounter_type == TravelEncounter.PLACE_VISIT else (&"FLEE_ROAD" if wreck.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else &"LEAVE"))
		carry_on(wreck)
	check(wreck.active_encounter != null and String(wreck.active_encounter.context.get("place_id", "")) == "place:convoy_wreck", "G6: the Gray Valley - New Hope road passes the convoy wreck")
	wreck.player.inventory.set_amount("water", 4)
	wreck.player.inventory.set_amount("food", 4)
	var scrap_before := wreck.player.inventory.get_amount("scrap")
	var expected: int = RoadPlaces.WRECK_BASE_SCRAP + int(wreck.player.capability.get_rank("SCAVENGING"))
	check(answer(wreck, &"SEARCH_SITE").success, "G6: searching commits")
	check(wreck.player.inventory.get_amount("scrap") == scrap_before + expected, "G6: base scrap plus scavenging skill (%d)" % expected)
	check(int(RoadPlaces.state(wreck, "place:convoy_wreck").scrap) == 0, "G6: the wreck is picked clean")
	check(not RoadPlaces.is_live(wreck, "place:convoy_wreck"), "G6: and not worth stopping at")
	wreck.record_event(EventRecord.new(wreck.current_day, "CARAVAN_DESTROYED", &"caravan:c_hope_gray", &"settlement:new_hope",
		{"origin": "settlement:gray_valley", "destination": "settlement:new_hope"}))
	check(int(RoadPlaces.state(wreck, "place:convoy_wreck").scrap) == RoadPlaces.WRECK_SCRAP_PER_LOSS, "G6: a caravan lost on that road leaves scrap on the wreck")
	check(RoadPlaces.is_live(wreck, "place:convoy_wreck"), "G6: so it is worth stopping again")
	finish_journey(wreck)

	# ---- G7 leaving is an answer ----
	var leave := fresh_world()
	travel(leave, "settlement:dry_well")
	check(answer(leave, &"LEAVE").success, "G7: leave commits")
	finish_journey(leave)
	travel(leave, "settlement:gray_valley")
	var asked_again := leave.active_encounter != null and String(leave.active_encounter.context.get("place_id", "")) == "place:old_well"
	check(not asked_again, "G7: the well is not asked about again straight away")
	finish_journey(leave)
	check(String(RoadPlaces.state(leave, "place:old_well").status) == "UNTOUCHED", "G7: it is still there for later")

	# ---- G8 map and saves ----
	var map_rows: Array = PlayerUIProjection.project(mark).get("road_places", [])
	check(map_rows.size() == RoadPlaces.ids().size(), "G8: the map carries every place")
	var named := 0
	for row in map_rows:
		if bool(row.discovered):
			named += 1
			check(String(row.name) != "？", "G8: a found place is named")
		else:
			check(String(row.name) == "？", "G8: an unfound place is not")
	check(named >= 1, "G8: the reported well is on the map")
	for row in map_rows:
		if String(row.id) == "place:old_well":
			check(String(row.status).contains("灰谷"), "G8: the map says whose well it is: %s" % row.status)
	for saved in [mark, camp, wreck]:
		var loaded := WorldState.from_json_checked(saved.to_canonical_json())
		check(loaded.success, "G8: a world with place receipts loads: %s" % String(loaded.get("error", "")))
		if loaded.success:
			check(loaded.world.to_canonical_json() == saved.to_canonical_json(), "G8: byte-identical after save/load")
		check(engine.validate_invariants(saved) == "", "G8: invariants hold")

	print("PLACE-4 road places: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
