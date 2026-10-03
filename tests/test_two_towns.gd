extends "res://tests/test_creature_hunts.gd"

const PlayableWorld = preload("res://game_data/playable_world.gd")
const Factions = preload("res://game_data/faction_catalogue.gd")
const Roads = preload("res://simulation/town_roads.gd")
const Markets = preload("res://simulation/item_market_catalogue.gd")
const MapView = preload("res://ui/components/world_map_view.gd")
const Definition = preload("res://simulation/quest_definition.gd")
const TOWN_SPECS := [
	{"id": "settlement:iron_pass", "hub": "settlement:gray_valley", "population": 80, "item": "rebar_club", "faction": "熔爐協約"},
	{"id": "settlement:spring_ford", "hub": "settlement:new_hope", "population": 90, "item": "rusted_knife", "faction": "綠洲同盟"},
]

func fresh_towns(origin: String) -> WorldState:
	var world: WorldState = PlayableWorld.create_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": origin, "character_name": "城鎮旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "five-town actual creation")
	world.player.inventory.set_amount("water", 7)
	world.player.inventory.set_amount("food", 7)
	return world

func pair_intent(world: WorldState, twin: WorldState, intent: PlayerIntent, label: String) -> Dictionary:
	var result: Dictionary = engine.commit_player_intent(world, intent)
	var other: Dictionary = engine.commit_player_intent(twin, intent)
	check(result.success and other.success, label + " succeeds")
	parity(world, twin, label)
	return result

func walk_pair(world: WorldState, twin: WorldState, destination: String) -> void:
	pair_intent(world, twin, PlayerIntent.create_travel(world.player.npc_id, StringName(destination)), "real neighbouring road")
	for stop: int in range(18):
		if world.pending_encounter_result >= 0:
			pair_intent(world, twin, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result), "confirm actual road receipt")
		elif world.active_encounter != null:
			var choice: StringName = &"LEAVE"
			match world.active_encounter.encounter_type:
				TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
				TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
				TravelEncounter.ROADBLOCK: choice = &"PAY"
			pair_intent(world, twin, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice), "real road choice")
		else: break
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	check(life.status == NpcLifeState.Status.SETTLED and String(life.population_container_id) == destination, "arrival in actual new town")
	for event: EventRecord in world.event_log:
		if event.type == "PLAYER_TRAVEL_STARTED" and String(event.target_id) == destination:
			check(int(event.payload.route_days) == 2, "authored spur exactly two days")

func town_trip(spec: Dictionary) -> void:
	var world: WorldState = fresh_towns(spec.hub)
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	var projection: Dictionary = UiProjection.project(world, false)
	var source: String = world.to_canonical_json()
	for dest: Dictionary in projection.destinations:
		check(not dest.has("water") and not dest.has("quote_buy_water") and not dest.has("item_market"), "remote economics withheld")
		if dest.id == spec.id:
			check(dest.can_travel and dest.route_days == 2 and dest.faction_name == spec.faction, "reachable public affiliation and distance")
	check(world.to_canonical_json() == source, "queries cannot mutate world")
	walk_pair(world, twin, spec.id)
	projection = UiProjection.project(world, false)
	check(projection.current_settlement.id == spec.id and projection.trust.has(spec.id), "new town live projection/trust")
	var shop: RefCounted = ItemMarketState.seeded_for(spec.id)
	var profile: Dictionary = Markets.profile_for(spec.item, spec.id)
	check(profile.success and profile.settlement_id == spec.id and shop.quantity(spec.item) == 6, "regional profile preserves actual town and authored high stock")
	var before: int = world.player.item_inventory.quantity(spec.item)
	var money: int = world.player.money
	var town: SettlementState = world.get_settlement(StringName(spec.id))
	var price: int = SimulationEngine.get_item_buy_quote(town, StringName(spec.item), shop)
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, StringName(spec.item), 1), "actual new-town purchase")
	check(world.player.item_inventory.quantity(spec.item) == before + 1 and world.player.money == money - price, "real ownership and quoted caps debit")
	check(town.item_market.quantity(spec.item) == 5, "actual regional stock decremented")
	pair_intent(world, twin, PlayerIntent.create_equip_item(world.player.npc_id, StringName(spec.item), "main_hand"), "equip purchased item")
	var salvage: Dictionary = {}
	for entry: Dictionary in Board.postings(world, StringName(spec.id)):
		check(Definition.validate_definition(entry.definition) == "", "new board validates actual definition")
		if entry.archetype == "SALVAGE": salvage = entry
		if entry.archetype == "CONSIGNMENT":
			check("settlement:" + String(entry.definition.consign_to) == spec.hub and entry.route_days == 2, "new town ships real surplus along its physical road")
	check(not salvage.is_empty() and "settlement:" + String(salvage.target_route_destination) == spec.hub and salvage.route_days == 2, "reachable salvage work at new town")
	if salvage.is_empty(): return
	var item: String = salvage.target_item_id
	# Independent fixture for obtaining a work part; delivery itself uses authority.
	check(world.player.item_inventory.pickup_item(item, 1).success and twin.player.item_inventory.pickup_item(item, 1).success, "owned part fixture")
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, salvage.definition.id), "accept actual new-town contract")
	var accepted_pay: int = 0
	for reward: Dictionary in salvage.definition.outcomes.resolved.rewards:
		if reward.type == "CURRENCY": accepted_pay = int(reward.amount)
	money = world.player.money
	pair_intent(world, twin, PlayerIntent.create_turn_in_quest(world.player.npc_id, salvage.definition.id), "deliver actual new-town part")
	check(world.player.money == money + accepted_pay and world.quest_state.get_quest(salvage.definition.id).status == "RESOLVED", "accepted payout and persisted resolution")
	var saved: String = world.to_canonical_json()
	var refused: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, salvage.definition.id))
	check(not refused.success and world.to_canonical_json() == saved, "duplicate payment refuses atomically")

func boundaries() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var original: String = world.to_canonical_json()
	var rejected: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:spring_ford"))
	check(not rejected.success and String(rejected.error).contains("INVALID_DESTINATION") and world.to_canonical_json() == original, "forged cross-town shortcut refuses atomically")
	check(not engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:spring_ford")).success and world.to_canonical_json() == original, "direct travel entry also refuses missing road")
	var shell: PlayableShell = Shell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	shell.select_settlement("settlement:spring_ford")
	check(shell.btn_travel.disabled and shell.lbl_settlement_details.text.contains("新希望"), "actual UI locks shortcut and names intermediate hub")
	check(world.to_canonical_json() == original, "opening locked map is read-only")
	var map: WorldMapView = MapView.new()
	map.size = Vector2(500, 350)
	map.update_map_data(UiProjection.project(world, false).destinations, {}, "")
	check(map._get_node_at_position(map._get_pixel_pos(MapView.NODE_POSITIONS["settlement:spring_ford"])) == "settlement:spring_ford", "new node selectable")
	var old: WorldState = S1WorldData.create_s1_world()
	check(old.settlements.size() == 3 and old.caravans.size() == 3, "historical fixture intact")
	var old_json: String = old.to_canonical_json()
	check(WorldState.from_json_checked(old_json).world.to_canonical_json() == old_json, "legacy save exact fixed point")
	map.update_map_data([{"id": "settlement:gray_valley"}, {"id": "settlement:dry_well"}, {"id": "settlement:new_hope"}], {}, "")
	check(map._get_node_at_position(map._get_pixel_pos(MapView.NODE_POSITIONS["settlement:spring_ford"])) == "", "legacy map has no ghost town")
	check(not Markets.profile_for("rusted_knife", "settlement:unknown").success and Markets.validate_catalogue() == "", "market negative and catalogue fixtures")
	var startup: Node = load("res://main.tscn").instantiate()
	root.add_child(startup)
	check(startup.world.settlements.size() == 5 and startup.world.player == null, "actual main scene starts five-town creation")
	startup.queue_free()
	map.free()
	shell.queue_free()
	await process_frame

func stability() -> void:
	var world: WorldState = PlayableWorld.create_world()
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	check(world.settlements.size() == 5 and world.caravans.size() == 5, "five authored towns/five physical roads")
	for spec: Dictionary in TOWN_SPECS:
		check(world.get_settlement(StringName(spec.id)).population == spec.population, "authored initial population")
	for day: int in range(180):
		engine.tick(world)
		engine.tick(twin)
		check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "180-day twin replay day%d" % day)
		check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "180-day global invariants day%d" % day)
	check(world.total_initial_population == 470, "authored470 conserved without named inflation")
	var living: int = 0
	var deaths: int = 0
	for town: SettlementState in world.settlements.values():
		living += town.population
		deaths += town.cumulative_deaths
		print("Town day180: %s population=%d deaths=%d water=%d food=%d pressures=%.1f/%.1f" % [town.id, town.population, town.cumulative_deaths, town.inventory.water, town.inventory.food, town.water_pressure, town.food_pressure])
		check(town.population > 0, "no settlement extinction: " + String(town.id))
	print("Town stability day180: living=%d deaths=%d refugee_parties=%d" % [living, deaths, world.refugees.size()])
	check(living > 0, "no total extinction")
	check(WorldState.from_json_checked(world.to_canonical_json()).success, "extended180-day checked save")

func run() -> void:
	for spec: Dictionary in TOWN_SPECS: town_trip(spec)
	await boundaries()
	stability()
	print("Two towns: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
