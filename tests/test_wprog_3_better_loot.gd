extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
const ItemArtReferences = preload("res://game_data/item_art_references.gd")
const ItemMarketCatalogue = preload("res://simulation/item_market_catalogue.gd")
const PlayableShell = preload("res://ui/playable_shell.gd")
const ORIGIN := &"settlement:new_hope"
const DESTINATION := &"settlement:dry_well"
const RARE_ITEM := "military_backpack"

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("WPROG-3: " + message)

func created(day: int) -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": String(ORIGIN), "character_name": "SalvageTester",
		"age": 25, "background_id": "SCAVENGER", "trait_ids": [],
	}))
	check(result.success, "character created through authority")
	world.current_day = day
	world.player.inventory.water = 10
	world.player.inventory.food = 10
	return world

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var probe := created(1)
	var departure := engine.begin_player_travel(probe, PlayerIntent.create_travel(probe.player.npc_id, DESTINATION, &"WILDERNESS"))
	check(departure.success, "route probe departs")
	var facts := engine.gather_road_facts(probe, probe.get_refugee_party(departure.party_id))
	var rare_day := -1
	var ordinary_day := -1
	var highway_wreck_day := -1
	var highway_facts: Dictionary = facts.duplicate(true)
	highway_facts["route_type"] = "HIGHWAY"
	for day in range(1, 2000):
		if highway_wreck_day < 0 and TravelEncounter.select(highway_facts, ORIGIN, DESTINATION, day, 1) == TravelEncounter.WRECK and TravelEncounter.wreck_item_yield(day + 1, ORIGIN, DESTINATION, 1, &"SEARCH", "WILDERNESS").has(RARE_ITEM):
			highway_wreck_day = day
		if TravelEncounter.select(facts, ORIGIN, DESTINATION, day, 1) != TravelEncounter.WRECK:
			continue
		var loot := TravelEncounter.wreck_item_yield(day + 1, ORIGIN, DESTINATION, 1, &"SEARCH", "WILDERNESS")
		if loot.has(RARE_ITEM) and rare_day < 0:
			rare_day = day
		elif not loot.has(RARE_ITEM) and ordinary_day < 0:
			ordinary_day = day
		if rare_day >= 0 and ordinary_day >= 0 and highway_wreck_day >= 0:
			break
	check(rare_day >= 0 and ordinary_day >= 0 and highway_wreck_day >= 0, "both routes have matching rare-cache and ordinary wreck fixtures")
	if rare_day < 0:
		quit(1)
		return

	check(ItemRegistry.resolve(RARE_ITEM).success, "rare find is a canonical inspectable item")
	check(ItemArtReferences.resolve("item_military_backpack").success, "rare find has a real art binding")
	for settlement in [ORIGIN, &"settlement:gray_valley", DESTINATION]:
		check(not ItemMarketCatalogue.profile_for(RARE_ITEM, settlement).is_routinely_supplied, "rare find is not ordinary shop stock")
	check(not TravelEncounter.wreck_item_yield(rare_day + 1, ORIGIN, DESTINATION, 1, &"SEARCH", "HIGHWAY").has(RARE_ITEM), "highway wreck has no exclusive field kit")
	check(not TravelEncounter.wreck_item_yield(rare_day + 1, ORIGIN, DESTINATION, 1, &"SEARCH").has(RARE_ITEM), "legacy wreck has no exclusive field kit")
	check(not TravelEncounter.wreck_item_yield(rare_day + 1, ORIGIN, DESTINATION, 1, &"QUICK_PICK", "WILDERNESS").has(RARE_ITEM), "quick pick cannot reach sealed cache")
	check(TravelEncounter.wreck_item_yield(rare_day + 1, ORIGIN, DESTINATION, 1, &"STRIP_PARTS", "WILDERNESS").has(RARE_ITEM), "thorough alternate approach sees same physical cache")
	check(not TravelEncounter.wreck_item_yield(ordinary_day + 1, ORIGIN, DESTINATION, 1, &"SEARCH", "WILDERNESS").has(RARE_ITEM), "rare equipment is not guaranteed by route")

	var first := created(rare_day)
	var second := created(rare_day)
	for world in [first, second]:
		check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, DESTINATION, &"WILDERNESS")).success, "real wilderness trip starts")
		engine.tick(world)
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		engine._check_travel_encounter(world, life)
		check(world.active_encounter != null and world.active_encounter.encounter_type == TravelEncounter.WRECK, "real route finds selected wreck")
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual-track world SHA matches before loot")
	var receipt: Dictionary = {}
	for world in [first, second]:
		receipt = engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"SEARCH"))
		check(receipt.success, "search commits atomically")
		check(receipt.get("items_gained", {}).get(RARE_ITEM, 0) == 1, "receipt names the actual rare item")
		check(world.player.item_inventory.quantity(RARE_ITEM) == 1, "rare item is held, not merely printed")
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual-track full-world SHA matches after rare loot")
	if "--capture" in OS.get_cmdline_user_args():
		var before_ui := first.to_canonical_json().sha256_text()
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.setup(first, engine)
		var folder := OS.get_user_data_dir().path_join("captures/wprog-3")
		DirAccess.make_dir_recursive_absolute(folder)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
			root.size = viewport_size
			for frame in range(8):
				await process_frame
			var image_path := folder.path_join("rare_loot_%dx%d.png" % [viewport_size.x, viewport_size.y])
			check(root.get_texture().get_image().save_png(image_path) == OK, "real renderer captures rare-item receipt")
			print("CAPTURED " + image_path)
		check(first.to_canonical_json().sha256_text() == before_ui, "opening receipt UI does not mutate world")
		shell.queue_free()
		await process_frame
	var loaded := WorldState.from_dict_checked(second.to_dict())
	check(loaded.success and loaded.world.to_canonical_json() == second.to_canonical_json(), "rare loot and pending receipt survive checked save/load")
	check(engine.validate_invariants(first) == "" and engine.validate_invariants(second) == "", "loot preserves global invariants")

	# At settlement, the find changes carrying choices. Replacing it with the
	# first-tier bag must fail if that would silently overload the player.
	var equipped := created(1)
	check(equipped.player.pickup_item(RARE_ITEM).success, "rare bag can enter formal inventory")
	check(equipped.player.pickup_item("travel_backpack").success, "first-tier bag can coexist as an alternative")
	check(engine.commit_player_intent(equipped, PlayerIntent.create_equip_item(equipped.player.npc_id, RARE_ITEM, "back")).success, "rare bag equips in actual slot")
	check(equipped.player.get_effective_capacity() == 32, "rare bag raises cargo capacity to 32")
	equipped.player.inventory.scrap = 10
	var before_swap := equipped.to_canonical_json().sha256_text()
	check(not engine.commit_player_intent(equipped, PlayerIntent.create_equip_item(equipped.player.npc_id, "travel_backpack", "back")).success, "weaker bag cannot replace it while carrying 30")
	check(equipped.to_canonical_json().sha256_text() == before_swap, "failed bag swap leaves world unchanged")
	check(not engine.commit_player_intent(equipped, PlayerIntent.create_unequip_item(equipped.player.npc_id, "back")).success, "rare bag cannot be removed while overloaded")
	check(equipped.to_canonical_json().sha256_text() == before_swap, "failed unequip leaves world unchanged")
	check(WorldState.from_dict_checked(equipped.to_dict()).success and engine.validate_invariants(equipped) == "", "equipped find saves and preserves invariants")
	var sell_equipped := engine.commit_player_intent(equipped, PlayerIntent.create_sell_item(equipped.player.npc_id, &"military_backpack", 1))
	check(not sell_equipped.success and String(sell_equipped.error).begins_with("ITEM_EQUIPPED"), "equipped rare bag cannot be sold")
	check(equipped.to_canonical_json().sha256_text() == before_swap, "rejected equipped sale is atomic")
	check(WorldState.from_dict_checked(equipped.to_dict()).success, "rejected sale does not poison checked save")

	var highway := created(highway_wreck_day)
	check(engine.begin_player_travel(highway, PlayerIntent.create_travel(highway.player.npc_id, DESTINATION, &"HIGHWAY")).success, "actual highway journey starts")
	engine.tick(highway)
	engine._check_travel_encounter(highway, highway.npc_life_state_registry.get_life_state(highway.player.npc_id))
	check(highway.active_encounter != null and highway.active_encounter.encounter_type == TravelEncounter.WRECK, "highway trip finds a real wreck with matching rare-cache hash")
	var forged_save: Dictionary = highway.to_dict().duplicate(true)
	forged_save.active_encounter.context["route_type"] = "WILDERNESS"
	check(not WorldState.from_dict_checked(forged_save).success, "checked load rejects forged wilderness context on highway party")
	var forged_runtime := highway.duplicate_state()
	forged_runtime.active_encounter.context["route_type"] = "WILDERNESS"
	var forged_receipt := engine.commit_player_intent(forged_runtime, PlayerIntent.create_resolve_encounter(forged_runtime.player.npc_id, &"SEARCH"))
	check(forged_receipt.success and not forged_receipt.get("items_gained", {}).has(RARE_ITEM), "runtime loot reads actual party route, not forged context")
	check(engine.validate_invariants(forged_runtime) == "", "tampered context does not mint invalid inventory")

	print("WPROG-3 better loot: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
