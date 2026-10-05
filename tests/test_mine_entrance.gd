extends "res://tests/test_relay_exploration.gd"

# MIN-1: collapsed-mine entrance. Simulation authority, replay validation, daily
# supplies, persistence and the disclosed trip forecast. No combat, loot, machine
# or controller exists in this slice; the tests assert their absence.

const Mine = preload("res://simulation/mine_exploration.gd")
const IRON: StringName = &"settlement:iron_pass"
const GRAY: StringName = &"settlement:gray_valley"
var mine_render_dir: String = ""

func _init() -> void:
	store = Store.new("user://tests/min1/journey.json")
	call_deferred("run_mine")

func mine_intent(world: WorldState, command_name: String, arg: String = "") -> PlayerIntent:
	var payload: Dictionary = {"command": command_name, "site_id": Mine.SITE}
	if command_name == "MOVE":
		payload.from_room_id = Mine.state(world).room_id
		payload.room_id = arg
	elif command_name == "OBSERVE":
		payload.fact_id = arg
	return PlayerIntent.create_dungeon_action(world.player.npc_id, payload)

func mine_pair(world: WorldState, twin: WorldState, command_name: String, arg: String = "") -> void:
	var result: Dictionary = pair_intent(world, twin, mine_intent(world, command_name, arg), "mine " + command_name + " " + arg)
	if not result.success: print("MINE FAILURE ", result)
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "mine actual global invariants")

func iron_start() -> WorldState:
	return fresh_towns("settlement:iron_pass")

func fact_count(world: WorldState, kind: String, key: String = "", value: String = "") -> int:
	var n: int = 0
	for e: EventRecord in world.event_log:
		if e.type == kind and (key == "" or String(e.payload.get(key, "")) == value): n += 1
	return n

func refused_with(world: WorldState, intent: PlayerIntent, code: String, label: String) -> void:
	var before: String = world.to_canonical_json()
	var result: Dictionary = engine.commit_player_intent(world, intent)
	check(not result.success and String(result.get("error", "")).begins_with(code) and world.to_canonical_json() == before, label + " refuses with " + code)

# --- the full three-room visit -------------------------------------------------

func mine_visit() -> WorldState:
	var world: WorldState = iron_start()
	check(String(world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id) == String(IRON), "settled in the real Iron Pass fixture")
	var twin: WorldState = disk_copy(world, "iron start")
	var items_before: Dictionary = world.player.item_inventory.to_dict()
	var caps: int = world.player.money
	var scrap: int = world.player.inventory.scrap
	var sequence: int = world.next_npc_sequence
	for command_name: String in ["MOVE", "OBSERVE", "EXIT"]:
		refused_with(world, mine_intent(world, command_name, "mine_gallery" if command_name == "MOVE" else "cracked_supports"), "MINE_NOT_INSIDE", command_name + " before entering")
	mine_pair(world, twin, "ENTER")
	check(Mine.state(world).active and Mine.state(world).room_id == "mine_entrance" and world.current_day == 0, "entering is free and records the entrance")
	refused_with(world, mine_intent(world, "ENTER"), "MINE_ALREADY_INSIDE", "second entry")
	refused_with(world, mine_intent(world, "MOVE", "mine_pumphall"), "MINE_INVALID_PASSAGE", "no passage entrance to hall")
	refused_with(world, mine_intent(world, "OBSERVE", "cracked_supports"), "MINE_OBSERVATION_UNAVAILABLE", "supports are seen in the gallery")
	refused_with(world, mine_intent(world, "OBSERVE", "controller_missing"), "MINE_OBSERVATION_UNAVAILABLE", "controller socket is in the hall")
	mine_pair(world, twin, "MOVE", "mine_gallery")
	mine_pair(world, twin, "OBSERVE", "cracked_supports")
	refused_with(world, mine_intent(world, "OBSERVE", "cracked_supports"), "MINE_ALREADY_OBSERVED", "supports observed once")
	refused_with(world, mine_intent(world, "EXIT"), "MINE_EXIT_REQUIRES_ENTRANCE", "cannot leave from the gallery")
	mine_pair(world, twin, "MOVE", "mine_pumphall")
	refused_with(world, mine_intent(world, "OBSERVE", "controller_missing"), "MINE_OBSERVE_FIRST", "socket needs the stalled pump seen first")
	mine_pair(world, twin, "OBSERVE", "stalled_pump")
	check(not Mine.state(world).discovered, "no discovery before the last observation")
	twin = disk_copy(world, "mid-visit in the pump hall")
	check(Mine.state(twin).room_id == "mine_pumphall" and Mine.state(twin).work_units == 2 and Mine.state(twin).observed == ["cracked_supports", "stalled_pump"], "Continue resumes in the correct room with the same facts")
	mine_pair(world, twin, "OBSERVE", "controller_missing")
	check(Mine.state(world).discovered and fact_count(world, "MINE_OBSERVED", "fact_id", "controller_missing") == 1, "last observation is the permanent discovery, recorded once")
	refused_with(world, mine_intent(world, "OBSERVE", "controller_missing"), "MINE_ALREADY_OBSERVED", "discovery is one-time")
	var water: int = world.player.inventory.water
	var food: int = world.player.inventory.food
	mine_pair(world, twin, "MOVE", "mine_gallery")
	check(world.current_day == 0 and Mine.state(world).work_units == 3, "three moves do not yet advance the day")
	mine_pair(world, twin, "MOVE", "mine_entrance")
	check(world.current_day == 1 and Mine.state(world).work_units == 0 and Mine.state(world).trip_days == 1, "fourth move advances one real world day")
	check(world.player.inventory.water == water - 1 and world.player.inventory.food == food - 1, "the mine day really costs one water and one food")
	var spent: EventRecord = null
	for e: EventRecord in world.event_log:
		if e.type == "MINE_DAY_SPENT": spent = e
	check(spent != null and spent.payload.water_before == water and spent.payload.water_after == water - 1 and spent.payload.food_after == food - 1 and spent.target_id == StringName(Mine.SITE), "day receipt records before and after supplies")
	mine_pair(world, twin, "EXIT")
	check(not Mine.state(world).active and Mine.state(world).discovered, "leaving keeps the discovery")
	check(world.player.money == caps and world.player.inventory.scrap == scrap and world.player.item_inventory.to_dict() == items_before, "MIN-1 grants no caps, scrap or item, and no controller")
	check(world.next_npc_sequence == sequence, "no new human identity")
	check(fact_count(world, "MINE_OBSERVED") == 3 and fact_count(world, "MINE_ENTERED") == 1, "exactly three observations and one entry")
	mine_pair(world, twin, "ENTER")
	refused_with(world, mine_intent(world, "OBSERVE", "cracked_supports"), "MINE_ALREADY_OBSERVED", "revisit entrance cannot re-observe")
	mine_pair(world, twin, "MOVE", "mine_gallery")
	refused_with(world, mine_intent(world, "OBSERVE", "cracked_supports"), "MINE_ALREADY_OBSERVED", "revisit never duplicates facts")
	check(Mine.state(world).entries == 2 and Mine.state(world).discovered and fact_count(world, "MINE_OBSERVED") == 3, "revisit keeps the discovery without a second one")
	mine_pair(world, twin, "MOVE", "mine_entrance")
	mine_pair(world, twin, "EXIT")
	parity(world, twin, "full three-room visit final SHA")
	return world

# --- refusals ------------------------------------------------------------------

func mine_refusals() -> void:
	var gray: WorldState = fresh_towns("settlement:gray_valley")
	refused_with(gray, mine_intent(gray, "ENTER"), "MINE_REQUIRES_IRON_PASS", "entry away from Iron Pass")
	var world: WorldState = iron_start()
	for bad: Dictionary in [{"command": "ENTER", "site_id": Mine.SITE, "extra": 1}, {"command": "ENTER"}, {"command": "ENTER", "site_id": "dungeon:other"}, {"command": "EXPLODE", "site_id": Mine.SITE}, {"command": "MOVE", "site_id": Mine.SITE, "room_id": "mine_gallery"}, {"command": "OBSERVE", "site_id": Mine.SITE}, {"command": 7, "site_id": Mine.SITE}]:
		var before: String = world.to_canonical_json()
		var result: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_dungeon_action(world.player.npc_id, bad))
		check(not result.success and world.to_canonical_json() == before, "malformed or foreign payload fails closed " + JSON.stringify(bad))
	check(engine.commit_player_intent(world, mine_intent(world, "ENTER")).success, "valid entry after refusals")
	refused_with(world, PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "ENTER"}), "DUNGEON_EXPLORATION_PENDING", "waterworks entry while inside the mine")
	refused_with(world, PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "ENTER", "site_id": Relay.SITE}), "RELAY_", "relay entry while inside the mine")
	refused_with(world, PlayerIntent.create_travel(world.player.npc_id, GRAY), "DUNGEON_EXPLORATION_PENDING", "no travel from inside the mine")
	refused_with(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "REST"}), "DUNGEON_EXPLORATION_PENDING", "no hidden rest inside the mine")
	check(engine.validate_invariants(world) == "", "refusals leave invariants intact")

# --- supplies, companions and deprivation -------------------------------------------

func visit_days(world: WorldState, days: int) -> void:
	# Whole days inside the mine: four moves each (entrance <-> gallery).
	for d: int in range(days):
		for step: int in range(4):
			var target: String = "mine_gallery" if Mine.state(world).room_id == "mine_entrance" else "mine_entrance"
			check(engine.commit_player_intent(world, mine_intent(world, "MOVE", target)).success, "mine move %d of day %d" % [step, d])

func mine_supplies() -> void:
	# Hungry day: no water to begin with.
	var world: WorldState = iron_start()
	world.player.inventory.set_amount("water", 0)
	check(engine.commit_player_intent(world, mine_intent(world, "ENTER")).success, "enter with no water")
	visit_days(world, 1)
	check(fact_count(world, "PLAYER_NEED_UNMET") == 1 and engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "an unmet mine day is ledgered and valid, live and checked")
	var unmet: EventRecord = null
	for e: EventRecord in world.event_log:
		if e.type == "PLAYER_NEED_UNMET": unmet = e
	check(unmet.target_id == StringName(Mine.SITE) and float(unmet.payload.water_unmet) == 1.0 and float(unmet.payload.food_unmet) == 0.0, "need receipt names the mine site and only the missing water")
	# Real death by deprivation inside the mine.
	var fatal: WorldState = iron_start()
	fatal.player.inventory.set_amount("water", 0)
	fatal.player.water_exposure = 5.9
	var population: int = fatal.get_settlement(IRON).population
	var deaths: int = fatal.get_settlement(IRON).cumulative_deaths
	check(engine.commit_player_intent(fatal, mine_intent(fatal, "ENTER")).success, "enter fatal fixture")
	visit_days(fatal, 1)
	check(not Mine.state(fatal).active and fact_count(fatal, "MINE_TRIP_ENDED") == 1 and fact_count(fatal, "PLAYER_DIED") == 1, "dehydration ends the trip with a death receipt")
	check(fatal.get_settlement(IRON).population == population - 1 and fatal.get_settlement(IRON).cumulative_deaths == deaths + 1, "death keeps global human conservation")
	check(engine.validate_invariants(fatal) == "" and WorldState.from_json_checked(fatal.to_canonical_json()).success, "fatal mine history is valid live and checked")
	check(not engine.commit_player_intent(fatal, mine_intent(fatal, "ENTER")).success, "the dead cannot re-enter")
	# Companion rations: Abban joins in Gray Valley, then eats in the mine.
	var gray: WorldState = fresh_towns("settlement:gray_valley")
	gray.player.money = 200
	check(engine.commit_player_intent(gray, PlayerIntent.create_hire_companion(gray.player.npc_id, SimulationEngine.Party.ABBAN)).success, "hire Abban")
	var hired_json: String = gray.to_canonical_json()
	var party: WorldState = walk_to(WorldState.from_json_checked(hired_json).world, IRON, "abban").world
	check(SimulationEngine.Party.current(party) == SimulationEngine.Party.ABBAN, "Abban arrived with the player")
	var water: int = party.player.inventory.water
	var food: int = party.player.inventory.food
	check(engine.commit_player_intent(party, mine_intent(party, "ENTER")).success, "enter with companion")
	visit_days(party, 1)
	check(party.player.inventory.water == water - 2 and party.player.inventory.food == food - 2 and SimulationEngine.Party.current(party) == SimulationEngine.Party.ABBAN, "the mine day feeds player and companion")
	check(engine.validate_invariants(party) == "", "companion mine day invariants")
	# Hunger departure: only one food left.
	var hungry: WorldState = walk_to(WorldState.from_json_checked(hired_json).world, IRON, "abban2").world
	hungry.player.inventory.set_amount("food", 1)
	check(engine.commit_player_intent(hungry, mine_intent(hungry, "ENTER")).success, "enter hungry party")
	visit_days(hungry, 1)
	check(SimulationEngine.Party.current(hungry) == "" and fact_count(hungry, "COMPANION_LEFT") >= 1 and engine.validate_invariants(hungry) == "", "unfed companion leaves with a ledgered hunger departure")

func walk_to(world: WorldState, destination: StringName, label: String) -> Dictionary:
	var start_day: int = world.current_day
	var seen: Array = []
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, destination)).success, label + " begins the real road")
	for stop: int in range(24):
		if world.pending_encounter_result >= 0:
			check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success, label + " confirms road receipt")
		elif world.active_encounter != null:
			var choice: StringName = &"LEAVE"
			match world.active_encounter.encounter_type:
				TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
				TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
				TravelEncounter.ROADBLOCK: choice = &"PAY"
			seen.append(String(world.active_encounter.encounter_type))
			check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice)).success, label + " resolves the road encounter")
		else: break
	return {"world": world, "days": world.current_day - start_day, "encounters": seen}

# --- forecast pinned to the real engine ------------------------------------------

func mine_forecast() -> void:
	var solo: Dictionary = Mine.forecast(2, "")
	check(solo.water == 3 and solo.food == 3 and solo.scrap == 1 and solo.mine_days == 1 and solo.transit_days == 2 and solo.bribe_caps == TravelEncounter.BANDIT_BRIBE_CAPS, "reviewed solo forecast: round trip 2 + mine day 1, one scrap, bribe from the encounter catalogue")
	check(solo.extra_day_water == 1 and solo.extra_day_food == 1, "an extra road day costs one water and one food")
	var abban: Dictionary = Mine.forecast(2, SimulationEngine.Party.ABBAN)
	check(abban.water == 6 and abban.food == 6 and abban.extra_day_water == 2, "reviewed companion forecast doubles the rations")
	var guide: Dictionary = Mine.forecast(2, "companion:shahu")
	check(guide.water == 1 and guide.food == 6 and guide.extra_day_water == 0 and guide.extra_day_food == 2, "a water-finding guide changes the disclosed numbers through Party.info")
	check(Mine.forecast(3, "").water == 3 + 2 and Mine.forecast_lines(solo).size() == 3, "route length feeds the forecast; three lines are disclosed")
	# Real road, no companion: measure what the engine actually charges.
	var world: WorldState = fresh_towns("settlement:gray_valley")
	world.player.inventory.set_amount("water", 9)
	world.player.inventory.set_amount("food", 9)
	var start: Dictionary = {"water": 9, "food": 9}
	var road: Dictionary = walk_to(world, IRON, "solo road")
	var nominal: int = 2
	var extra_days: int = road.days - nominal
	var charged_ticks: int = nominal - 1 + extra_days
	check(start.water - world.player.inventory.water == charged_ticks * solo.extra_day_water and start.food - world.player.inventory.food == charged_ticks * solo.extra_day_food, "the engine charges exactly the forecast per-tick rate on the real road (%d ticks, %d encounters)" % [charged_ticks, road.encounters.size()])
	var party_world: WorldState = fresh_towns("settlement:gray_valley")
	party_world.player.money = 200
	party_world.player.inventory.set_amount("water", 12)
	party_world.player.inventory.set_amount("food", 12)
	check(engine.commit_player_intent(party_world, PlayerIntent.create_hire_companion(party_world.player.npc_id, SimulationEngine.Party.ABBAN)).success, "hire for forecast check")
	var party_road: Dictionary = walk_to(party_world, IRON, "party road")
	var party_ticks: int = nominal - 1 + (party_road.days - nominal)
	check(12 - party_world.player.inventory.water == party_ticks * abban.extra_day_water and 12 - party_world.player.inventory.food == party_ticks * abban.extra_day_food, "companion road rate matches the forecast")
	# One scrap clears a rockslide: scan departure days for a deterministic rockslide.
	var found: bool = false
	for day: int in range(0, 40):
		var probe: WorldState = fresh_towns("settlement:gray_valley")
		probe.player.inventory.set_amount("scrap", 1)
		while probe.current_day < day: engine.tick(probe)
		if not engine.commit_player_intent(probe, PlayerIntent.create_travel(probe.player.npc_id, IRON)).success: continue
		if probe.active_encounter != null and probe.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE:
			var scrap: int = probe.player.inventory.scrap
			check(engine.commit_player_intent(probe, PlayerIntent.create_resolve_encounter(probe.player.npc_id, &"CLEAR")).success and scrap - probe.player.inventory.scrap == Mine.ROAD_CLEAR_SCRAP, "clearing the road really costs the disclosed scrap")
			found = true
			break
	check(found, "a deterministic rockslide departure day exists to pin the scrap number")

# --- the accepted negative trip: minimum preparation, ambush, short a ration ----------

func mine_negative_trip() -> void:
	var f: Dictionary = Mine.forecast(2, "")
	var ambush_day: int = -1
	for day: int in range(0, 60):
		var probe: WorldState = fresh_towns("settlement:gray_valley")
		while probe.current_day < day: engine.tick(probe)
		if engine.commit_player_intent(probe, PlayerIntent.create_travel(probe.player.npc_id, IRON)).success and probe.active_encounter != null and probe.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH:
			ambush_day = day
			break
	check(ambush_day >= 0, "a deterministic outbound ambush exists in the first sixty days")
	if ambush_day < 0: return
	var world: WorldState = fresh_towns("settlement:gray_valley")
	while world.current_day < ambush_day: engine.tick(world)
	world.player.inventory.set_amount("water", f.water)
	world.player.inventory.set_amount("food", f.food)
	world.player.inventory.set_amount("scrap", f.scrap)
	var out: Dictionary = walk_to(world, IRON, "minimum-prep outbound")
	check(out.encounters.has("BANDIT_AMBUSH") and out.days == 3, "the ambush cost an extra road day")
	check(engine.commit_player_intent(world, mine_intent(world, "ENTER")).success, "enter the mine on the minimum preparation")
	visit_days(world, 1)
	check(Mine.state(world).active and world.player.inventory.water == 0 and world.player.inventory.food == 0, "the mine day used the last rations")
	check(engine.commit_player_intent(world, mine_intent(world, "EXIT")).success, "leave")
	walk_to(world, GRAY, "minimum-prep return")
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	check(life.is_alive() and String(life.population_container_id) == String(GRAY), "alive and back in Gray Valley")
	check(fact_count(world, "PLAYER_NEED_UNMET") >= 1, "short a ration on the way back, honestly ledgered")
	check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "no corrupted state after the shortfall")
	check(engine.commit_player_intent(world, PlayerIntent.create_buy(world.player.npc_id, &"water", 1)).success or world.player.money < 1, "ordinary play continues: Gray Valley shop reachable")
	check(Mine.state(world).discovered == false and world.player.item_inventory.to_dict().items.is_empty(), "the negative trip needed no reward and left no controller")

# --- forged histories --------------------------------------------------------------

func swap_fact(data: Dictionary, from_fact: String, to_fact: String) -> void:
	for e: Dictionary in data.events:
		if e.type == "MINE_OBSERVED" and e.payload.fact_id == from_fact: e.payload.fact_id = to_fact

func mine_negative_history() -> void:
	var world: WorldState = mine_visit()
	for mode: int in range(20):
		var data: Dictionary = world.to_dict().duplicate(true)
		var event: Dictionary = last_fact(data, "MINE_OBSERVED")
		match mode:
			0: event.actor_id = "npc:unknown"
			1: event.target_id = "dungeon:buried_relay"
			2: event.payload.dungeon_id = "dungeon:sealed_waterworks"
			3: event.payload.room_id = "mine_entrance"
			4: event.payload.fact_id = "gold_cache"
			5: event.payload.reward = 100
			6: data.events.erase(last_fact(data, "MINE_ENTERED"))
			7: data.events.insert(data.events.find(event), event.duplicate(true))
			8: last_fact(data, "MINE_MOVED").payload.room_id = "mine_pumphall"
			9: last_fact(data, "MINE_MOVED").payload.from_room_id = false
			10: last_fact(data, "MINE_DAY_SPENT").payload.water_after = 999
			11: last_fact(data, "MINE_DAY_SPENT").payload.companion_id = "companion:abban"
			12: last_fact(data, "MINE_LEFT").payload.room_id = "mine_gallery"
			13: event.type = "MINE_UNKNOWN"
			14: last_fact(data, "MINE_DAY_SPENT").day = 99
			15: data.events.erase(last_fact(data, "MINE_DAY_SPENT"))
			16: swap_fact(data, "controller_missing", "stalled_pump")
			17: swap_fact(data, "stalled_pump", "controller_missing")
			18: last_fact(data, "MINE_ENTERED").payload.room_id = "mine_gallery"
			19: last_fact(data, "MINE_MOVED").payload.erase("from_room_id")
		relay_reject_fixture(data, "independent MINE malformed fixture " + str(mode))
	# Cross-site overlap: a relay or waterworks entry forged while the mine is active.
	var active: WorldState = iron_start()
	check(engine.commit_player_intent(active, mine_intent(active, "ENTER")).success and engine.validate_invariants(active) == "", "active mine positive live control")
	check(WorldState.from_json_checked(active.to_canonical_json()).success, "active mine positive checked control")
	for mode: int in range(4):
		var data: Dictionary = active.to_dict().duplicate(true)
		var forged: Dictionary = last_fact(data, "MINE_ENTERED").duplicate(true)
		match mode:
			0:
				forged.type = "RELAY_ENTERED"
				forged.target_id = Relay.SITE
				forged.payload = {"dungeon_id": Relay.SITE, "room_id": "relay_entrance"}
				data.events.append(forged)
			1:
				forged.type = "DUNGEON_ENTERED"
				forged.target_id = Dungeon.SITE
				forged.payload = {"dungeon_id": Dungeon.SITE, "room_id": "entrance", "route_rules": 1, "trip_rules": 1, "deep_rules": 1, "device_rules": 1}
				data.events.append(forged)
			2:
				forged.type = "MINE_ENTERED"
				data.events.append(forged)
			3:
				forged.type = "PLAYER_TRAVEL_STARTED"
				forged.target_id = String(GRAY)
				forged.payload = {"origin": String(IRON), "route_days": 2}
				data.events.append(forged)
		relay_reject_fixture(data, "mine overlap forgery " + str(mode))
	clear_slot()

# --- the real screens ------------------------------------------------------------

func mine_observe(label: String) -> void:
	await frames()
	if mine_render_dir != "":
		await RenderingServer.frame_post_draw
		var path: String = mine_render_dir.path_join(label + "_%dx%d.png" % [root.size.x, root.size.y])
		check(root.get_texture().get_image().save_png(path) == OK, "actual native renderer capture " + label)

func mine_button(screen: Control, prefix: String) -> Button:
	for b: Button in screen.command_buttons:
		if is_instance_valid(b) and b.text.begins_with(prefix): return b
	check(false, "actual visible mine command " + prefix)
	return null

func mine_geometry(screen: Control) -> void:
	for control: Control in [screen.title_label, screen.status_label, screen.room_view, screen.message, screen.facts_label, screen.commands]:
		var rect: Rect2 = control.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x + 0.1 and rect.end.y <= root.size.y + 0.1, "actual mine layout fits " + control.get_class() + " at %dx%d" % [root.size.x, root.size.y])
	for b: Button in screen.command_buttons:
		var rect: Rect2 = b.get_global_rect()
		check(b.size.y >= 40 and rect.end.x <= root.size.x + 0.1 and rect.end.y <= root.size.y + 0.1, "actual mine command %s meets 40px and fits" % b.text)

func press_mine(screen: Control, prefix: String) -> void:
	var b: Button = mine_button(screen, prefix)
	if b == null: return
	check(not b.disabled, "mine command enabled: " + prefix)
	b.pressed.emit()
	await frames()

func mine_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var world: WorldState = iron_start()
		check(store.save_game(world).success, "real mine UI initial save")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var before: String = main.world.to_canonical_json()
		var toolbar_button: Button = find_command(main.shell, "礦道")
		check(toolbar_button != null and toolbar_button.get_global_rect().end.x <= root.size.x, "the town toolbar offers the mine")
		toolbar_button.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("MineScreen", false, false)
		check(screen != null and screen.title_label.text.contains("礦道入口"), "actual Iron Pass entry opens the mine")
		if screen == null: continue
		mine_geometry(screen)
		var expected: Dictionary = Mine.entrance_forecast(main.engine.get_route_days_between(main.world, Mine.HOME, GRAY), "")
		check(screen.forecast_label.visible and screen.forecast_label.text.contains("%d 水、%d 糧" % [expected.water, expected.food]) and screen.forecast_label.text.contains("%d 瓶蓋" % expected.bribe_caps), "entrance discloses the derived remaining preparation")
		await mine_observe("entrance")
		before = main.world.to_canonical_json()
		screen.show_supplies()
		await mine_observe("supplies")
		check(screen.supplies_dialog.summary.text.contains("再換房4次") and main.world.to_canonical_json() == before, "supplies opens with the mine clock and mutates nothing")
		screen.supplies_dialog.get_ok_button().pressed.emit()
		await frames()
		await press_mine(screen, "前往 外段坑道")
		check(screen.title_label.text.contains("外段坑道") and not screen.forecast_label.visible, "moving shows the gallery without the entrance forecast")
		mine_geometry(screen)
		await mine_observe("gallery")
		await press_mine(screen, "查看 裂開的支柱")
		check(screen.facts_label.text.contains("● 外段坑道"), "the observed fact is shown")
		await mine_observe("gallery_observed")
		await press_mine(screen, "前往 舊集水廳")
		var locked: Button = mine_button(screen, "查看 控制座")
		check(locked != null and locked.disabled and locked.text.contains("先看看停擺的泵"), "the controller socket stays locked and readable until the pump is seen")
		mine_geometry(screen)
		await mine_observe("pumphall")
		await press_mine(screen, "查看 停擺的泵")
		await press_mine(screen, "查看 控制座")
		check(screen.facts_label.text.contains("新目標") and Mine.state(main.world).discovered, "the last observation shows the permanent new goal")
		await mine_observe("discovery")
		check(main.world.player.item_inventory.to_dict().items.is_empty() and fact_count(main.world, "MINE_OBSERVED") == 3, "no controller or loot appears")
		find_command(screen, "存讀檔").pressed.emit()
		await frames()
		before = main.world.to_canonical_json()
		main.save_dialog.save_button.pressed.emit()
		check(FileAccess.get_file_as_string(store.path) == before, "actual mine UI save bytes")
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("MineScreen", false, false)
		check(screen != null and Mine.state(main.world).room_id == "mine_pumphall" and main.world.to_canonical_json() == before and screen.facts_label.text.contains("新目標"), "real Continue restores the pump hall with its discovery")
		await mine_observe("continue_pumphall")
		for destination: String in ["返回 外段坑道", "返回 礦道入口"]:
			await press_mine(screen, destination)
		check(main.world.current_day == 1 and screen.message.text.contains("一天過去"), "the fourth move spends a real day and says so")
		await press_mine(screen, "離開礦道")
		check(not Mine.state(main.world).active and main.shell.find_child("MineScreen", false, false) == null, "leaving the mine returns to town")
		main.queue_free()
		await frames()
		# Refusal: away from Iron Pass the entry explains where to go.
		world = fresh_towns("settlement:gray_valley")
		check(store.save_game(world).success, "wrong-town UI fixture")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		before = main.world.to_canonical_json()
		find_command(main.shell, "礦道").pressed.emit()
		await frames()
		var refusal: AcceptDialog
		for child: Node in main.shell.get_children():
			if child is AcceptDialog and child.title == "鐵關舊礦道": refusal = child
		check(refusal != null and refusal.get_ok_button().size.y >= 40 and refusal.dialog_text.contains("鐵關"), "refused entry names the town and its return meets 40px")
		check(main.world.to_canonical_json() == before and not Mine.state(main.world).active, "refusal preserves the authoritative world")
		await mine_observe("wrong_town_refusal")
		refusal.get_ok_button().pressed.emit()
		await frames()
		# Pre-departure disclosure on the real travel panel.
		main.shell.select_settlement("settlement:iron_pass")
		await frames()
		var details: String = main.shell.lbl_settlement_details.text
		var route_days: int = main.engine.get_route_days_between(main.world, GRAY, IRON)
		var f: Dictionary = Mine.forecast(route_days, "")
		var disclosed: bool = true
		for line: String in Mine.forecast_lines(f): disclosed = disclosed and details.contains(line)
		check(disclosed and details.contains("%d 水、%d 糧" % [f.water, f.food]), "the departure panel shows the derived forecast before leaving Gray Valley")
		check(main.world.to_canonical_json() == before, "reading the departure panel is read-only")
		await mine_observe("departure_forecast")
		main.queue_free()
		await frames()
	clear_slot()

func run_mine() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): mine_render_dir = arg.trim_prefix("--render-dir=")
	clear_slot()
	mine_visit()
	mine_refusals()
	mine_supplies()
	mine_forecast()
	mine_negative_trip()
	mine_negative_history()
	root.size = Vector2i(1280, 720)
	if mine_render_dir != "": DirAccess.make_dir_recursive_absolute(mine_render_dir)
	await mine_ui()
	print("MIN-1: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
