extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const TravelRoute = preload("res://simulation/travel_route.gd")
const PlayableShell = preload("res://ui/playable_shell.gd")
const UIProjection = preload("res://ui/player_ui_projection.gd")

const ORIGIN := &"settlement:new_hope"
const DESTINATION := &"settlement:dry_well"

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("WPROG-2: " + message)

func created() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": String(ORIGIN), "character_name": "RouteTester",
		"age": 25, "background_id": "SCAVENGER", "trait_ids": [],
	}))
	check(result.success, "character created through authority")
	world.player.inventory.water = 10
	world.player.inventory.food = 10
	return world

func route_info(routes: Array, route_id: String) -> Dictionary:
	for route in routes:
		if String(route.get("id", "")) == route_id:
			return route
	return {}

func first_day(world: WorldState) -> void:
	engine.tick(world)
	var life := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life.status == NpcLifeState.Status.IN_TRANSIT:
		engine._check_travel_encounter(world, life)

func answer_if_needed(world: WorldState) -> void:
	if world.active_encounter == null:
		return
	var options := TravelEncounter.options(world.active_encounter.encounter_type, world.active_encounter.context)
	var choice: StringName = options.back().id
	var answer := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice))
	check(answer.success, "encounter answer commits")
	if world.pending_encounter_result >= 0:
		var confirmation := engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
		check(confirmation.success, "result confirmation resumes journey")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var world := created()
	var before_ui := world.to_canonical_json().sha256_text()
	var destinations: Array = UIProjection.project(world).get("destinations", [])
	var selected: Dictionary = {}
	for destination in destinations:
		if String(destination.get("id", "")) == String(DESTINATION):
			selected = destination
	var routes: Array = selected.get("routes", [])
	check(routes.size() == 2, "two routes exposed on New Hope–Dry Well corridor")
	check(route_info(routes, "HIGHWAY").get("days") == 2, "highway is two days")
	check(route_info(routes, "WILDERNESS").get("days") == 4, "wilderness is four days")
	check(TravelRoute.get_available_routes(ORIGIN, &"settlement:gray_valley").is_empty(), "other corridors keep their existing single route")

	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	shell.select_settlement(String(DESTINATION))
	check(shell.route_choice_row.is_visible_in_tree() and shell.route_highway_button.is_visible_in_tree() and shell.route_wilderness_button.is_visible_in_tree(), "both route choices are player-visible")
	shell.route_wilderness_button.pressed.emit()
	check(shell.selected_route_type == "WILDERNESS", "wilderness button selects the route")
	check(shell.btn_travel.text.contains("4 天"), "departure command shows selected duration")
	check(shell.lbl_settlement_details.text.contains("耗時"), "selected route explains its cost")
	check(world.to_canonical_json().sha256_text() == before_ui, "opening and changing route selection does not mutate world")
	world.player.inventory.water = 3
	world.player.inventory.food = 3
	shell.refresh_ui()
	check(shell.lbl_supply_warning.visible and shell.lbl_supply_warning.text.contains("4 天"), "pre-departure supply warning uses selected route length")
	world.player.inventory.water = 10
	world.player.inventory.food = 10
	shell.refresh_ui()
	if "--capture" in OS.get_cmdline_user_args():
		var folder := OS.get_user_data_dir().path_join("captures/wprog-2")
		DirAccess.make_dir_recursive_absolute(folder)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
			root.size = viewport_size
			for frame in range(8):
				await process_frame
			var image_path := folder.path_join("risky_route_%dx%d.png" % [viewport_size.x, viewport_size.y])
			check(root.get_texture().get_image().save_png(image_path) == OK, "real renderer captures selected route")
			print("CAPTURED " + image_path)
	var ui_departure := shell.on_travel_pressed()
	check(ui_departure.success, "player-facing departure commits")
	var started: Dictionary = {}
	for event in world.event_log:
		if event.type == "PLAYER_TRAVEL_STARTED":
			started = event.payload
	check(started.get("route_type", "") == "WILDERNESS" and int(started.get("route_days", 0)) == 4, "visible route choice reaches travel authority")
	shell.queue_free()
	await process_frame

	var invalid := created()
	var before_invalid := invalid.to_canonical_json().sha256_text()
	check(not engine.begin_player_travel(invalid, PlayerIntent.create_travel(invalid.player.npc_id, DESTINATION, &"INVENTED")).success, "invented route rejected")
	check(invalid.to_canonical_json().sha256_text() == before_invalid, "invented route fails atomically")
	check(not engine.begin_player_travel(invalid, PlayerIntent.create_travel(invalid.player.npc_id, &"settlement:gray_valley", &"WILDERNESS")).success, "route cannot be applied to another corridor")
	check(invalid.to_canonical_json().sha256_text() == before_invalid, "unsupported corridor fails atomically")

	var legacy := created()
	var legacy_departure := engine.begin_player_travel(legacy, PlayerIntent.create_travel(legacy.player.npc_id, DESTINATION))
	check(legacy_departure.success and legacy_departure.route_days == 3, "existing travel intent retains three-day route")
	var legacy_party := legacy.get_refugee_party(legacy_departure.party_id)
	check(legacy_party.route_type == &"" and not legacy_party.to_dict().has("route_type"), "legacy party remains untyped in canonical save")
	check(engine.validate_invariants(legacy) == "", "legacy route retains global invariants")

	var highway := created()
	var highway_departure := engine.begin_player_travel(highway, PlayerIntent.create_travel(highway.player.npc_id, DESTINATION, &"HIGHWAY"))
	check(highway_departure.success and highway_departure.route_days == 2, "highway departure uses its own time")
	var wilderness := created()
	var wilderness_departure := engine.begin_player_travel(wilderness, PlayerIntent.create_travel(wilderness.player.npc_id, DESTINATION, &"WILDERNESS"))
	check(wilderness_departure.success and wilderness_departure.route_days == 4, "wilderness departure uses its own time")
	var loaded := WorldState.from_dict_checked(wilderness.to_dict())
	check(loaded.success and loaded.world.to_canonical_json() == wilderness.to_canonical_json(), "selected route survives checked save/load")
	check(loaded.world.get_refugee_party(wilderness_departure.party_id).route_type == &"WILDERNESS", "loaded party retains route choice")
	var corrupt: Dictionary = wilderness.to_dict().duplicate(true)
	corrupt.refugees[String(wilderness_departure.party_id)].route_type = "INVENTED"
	check(not WorldState.from_dict_checked(corrupt).success, "unknown saved route fails closed")
	corrupt = wilderness.to_dict().duplicate(true)
	corrupt.refugees[String(wilderness_departure.party_id)].route_days = 2
	check(not WorldState.from_dict_checked(corrupt).success, "saved route duration cannot contradict route definition")

	var highway_facts := engine.gather_road_facts(highway, highway.get_refugee_party(highway_departure.party_id))
	var wilderness_facts := engine.gather_road_facts(wilderness, wilderness.get_refugee_party(wilderness_departure.party_id))
	var highway_bandits := 0
	var wilderness_bandits := 0
	var highway_wrecks := 0
	var wilderness_wrecks := 0
	var empty_highway := 0
	var empty_wilderness := 0
	var ambush_day := -1
	for day in range(1, 121):
		var road_event := TravelEncounter.select(highway_facts, ORIGIN, DESTINATION, day, 1)
		var wild_event := TravelEncounter.select(wilderness_facts, ORIGIN, DESTINATION, day, 1)
		if road_event == TravelEncounter.BANDIT_AMBUSH:
			highway_bandits += 1
			if ambush_day < 0: ambush_day = day
		if wild_event == TravelEncounter.BANDIT_AMBUSH: wilderness_bandits += 1
		if road_event == TravelEncounter.WRECK: highway_wrecks += 1
		if wild_event == TravelEncounter.WRECK: wilderness_wrecks += 1
		if road_event == &"": empty_highway += 1
		if wild_event == &"": empty_wilderness += 1
	check(highway_bandits > wilderness_bandits, "highway raises bandit exposure without forcing an event")
	check(wilderness_wrecks > highway_wrecks, "wilderness raises wreck exposure without guaranteed loot")
	check(empty_highway > 0 and empty_wilderness > 0, "both routes still have uneventful travel days")
	check(engine.validate_invariants(highway) == "" and engine.validate_invariants(wilderness) == "", "both route departures conserve world invariants")

	var armed := created()
	var unarmed := created()
	armed.current_day = ambush_day
	unarmed.current_day = ambush_day
	armed.player.pickup_item("scrap_machete", 1)
	check(engine.commit_player_intent(armed, PlayerIntent.create_equip_item(armed.player.npc_id, "scrap_machete", "main_hand")).success, "earned-style weapon can be equipped before high-risk route")
	check(engine.begin_player_travel(armed, PlayerIntent.create_travel(armed.player.npc_id, DESTINATION, &"HIGHWAY")).success, "armed traveller takes highway")
	check(engine.begin_player_travel(unarmed, PlayerIntent.create_travel(unarmed.player.npc_id, DESTINATION, &"HIGHWAY")).success, "unarmed traveller takes same highway")
	first_day(armed)
	first_day(unarmed)
	check(armed.active_encounter != null and unarmed.active_encounter != null and armed.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH and unarmed.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH, "both builds meet the same selected ambush")
	check(engine.commit_player_intent(armed, PlayerIntent.create_resolve_encounter(armed.player.npc_id, &"FIGHT")).success, "armed fight begins")
	check(engine.commit_player_intent(unarmed, PlayerIntent.create_resolve_encounter(unarmed.player.npc_id, &"FIGHT")).success, "unarmed fight begins")
	for turn in range(2):
		for fighter in [armed, unarmed]:
			var battle: Dictionary = fighter.field_state.battle
			check(engine.commit_player_intent(fighter, PlayerIntent.create_field_action(fighter.player.npc_id, {"command": "ATTACK", "battle_id": battle.id, "turn": battle.turn})).success, "real combat turn commits")
	check(armed.field_state.battle.is_empty() and not unarmed.field_state.battle.is_empty(), "machete resolves high-risk ambush in two turns while bare hands do not")
	check(armed.player.field_kit.hp > unarmed.player.field_kit.hp, "weapon choice preserves more HP on the same route")
	check(engine.validate_invariants(armed) == "" and engine.validate_invariants(unarmed) == "", "combat payoff preserves global invariants")

	var first := created()
	var second := created()
	var first_departure := engine.begin_player_travel(first, PlayerIntent.create_travel(first.player.npc_id, DESTINATION, &"WILDERNESS"))
	var second_departure := engine.begin_player_travel(second, PlayerIntent.create_travel(second.player.npc_id, DESTINATION, &"WILDERNESS"))
	check(first_departure.success and second_departure.success, "dual tracks depart")
	first_day(first)
	first_day(second)
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual tracks match after real travel day and encounter selection")
	answer_if_needed(first)
	answer_if_needed(second)
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual tracks match after committed encounter answer")
	var resumed := WorldState.from_dict_checked(second.to_dict())
	check(resumed.success, "wilderness journey can be saved and loaded after encounter resolution")
	if resumed.success:
		second = resumed.world
	for step in range(12):
		var first_life := first.npc_life_state_registry.get_life_state(first.player.npc_id)
		var second_life := second.npc_life_state_registry.get_life_state(second.player.npc_id)
		check(first_life.status == second_life.status, "replayed route has the same transit state")
		if first_life.status != NpcLifeState.Status.IN_TRANSIT:
			break
		if first.active_encounter == null and first.pending_encounter_result < 0:
			engine.advance_player_travel(first, first.player.npc_id, first.get_refugee_party(first_life.population_container_id).days_remaining)
		if second.active_encounter == null and second.pending_encounter_result < 0:
			engine.advance_player_travel(second, second.player.npc_id, second.get_refugee_party(second_life.population_container_id).days_remaining)
		check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "full-world replay matches while finishing chosen route")
		answer_if_needed(first)
		answer_if_needed(second)
		check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "full-world replay matches after route interruption")
	var arrived_life := first.npc_life_state_registry.get_life_state(first.player.npc_id)
	check(arrived_life.status == NpcLifeState.Status.SETTLED and arrived_life.population_container_id == DESTINATION, "four-day wilderness route reaches Dry Well")
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "save-resumed complete journey has same world SHA")
	check(engine.validate_invariants(first) == "" and engine.validate_invariants(second) == "", "global invariants hold after chosen route and encounter")
	print("WPROG-2 risky route: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
