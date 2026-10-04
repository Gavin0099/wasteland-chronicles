extends "res://tests/test_dungeon_route_choice.gd"

func _init() -> void:
	store = Store.new("user://tests/dun5/journey.json")
	call_deferred("run_supplies")

func pack_fixture(method: String = "SKILL", injured: bool = false) -> WorldState:
	var world: WorldState = route_fixture(method)
	world.player.inventory.scrap = 4
	if injured:
		world.player.field_kit.hp = 5 # Reviewed surviving injury, not a combat shortcut.
		check(world.player.item_inventory.pickup_item("bandage", 2).success and world.player.item_inventory.pickup_item("first_aid_kit", 1).success, "owned treatment fixture")
	check(Dungeon.state(world).trip_rules == 1 and engine.validate_invariants(world) == "", "actual current trip/pack fixture validates")
	return world

func safe_cycle(world: WorldState, twin: WorldState = null) -> void:
	for target: String in ["foyer", "parts_store", "foyer", "entrance"]:
		var intent: PlayerIntent = dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target)
		if twin == null: check(engine.commit_player_intent(world, intent).success, "actual safe room transition")
		else: pair_intent(world, twin, intent, "actual safe route/time replay")

func clock_replay() -> void:
	clear_slot()
	var world: WorldState = pack_fixture()
	var twin: WorldState = disk_copy(world, "before expedition clock")
	for target: String in ["foyer", "parts_store", "foyer"]:
		pair_intent(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "subday movement twin")
		check(world.current_day == 0 and world.player.inventory.water == 3 and world.player.inventory.food == 3, "independent three-transition no-full-day fixture")
	check(Dungeon.state(world).work_units == 3, "independent three accumulated work units")
	var before: String = world.to_canonical_json()
	check(not Dungeon.commit(world, {"command": "MOVE", "from_room_id": "foyer", "room_id": "entrance"}, []).success and world.to_canonical_json() == before, "direct fourth transition needs authorized clock and stays atomic")
	var emitted: Array[EventRecord] = []
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "foyer", "entrance"), emitted).success, "real fourth transition advances clock")
	check(engine.commit_player_intent(twin, dungeon_intent(twin, "MOVE", "foyer", "entrance")).success, "real twin fourth transition")
	parity(world, twin, "full actual dungeon day twin SHA")
	check(world.current_day == 1 and world.player.inventory.water == 2 and world.player.inventory.food == 2 and Dungeon.state(world).work_units == 0 and Dungeon.state(world).trip_days == 1, "reviewed solo day:3/3 ->2/2, four moves -> one day")
	var day_count: int = 0
	for event: EventRecord in emitted:
		if event.type == "DUNGEON_DAY_SPENT": day_count += 1
	check(day_count == 1, "returned transition events include exactly one committed day receipt")
	twin = disk_copy(world, "spent day actual disk")
	for target: String in ["foyer", "entrance"]: pair_intent(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual partial return")
	pair_intent(world, twin, dungeon_intent(world, "EXIT"), "actual costed trip exit")
	pair_intent(world, twin, dungeon_intent(world, "ENTER"), "actual partial-time revisit")
	check(Dungeon.state(world).work_units == 2 and Dungeon.state(world).trip_moves == 0 and Dungeon.state(world).trip_days == 0, "partial work persists while per-trip counters reset")
	for target: String in ["foyer", "parts_store"]: pair_intent(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual carry-over day")
	check(world.current_day == 2 and world.player.inventory.water == 1 and world.player.inventory.food == 1, "revisit cannot reset away the second actual day")
	twin = disk_copy(world, "carry-over actual disk")
	check(engine.validate_invariants(world) == "", "actual day world population/global invariants")
	clear_slot()

func companions_and_death() -> void:
	var fed: WorldState = pack_fixture("ABBAN")
	safe_cycle(fed)
	check(fed.player.inventory.water == 1 and fed.player.inventory.food == 1 and Dungeon.Party.current(fed) == Dungeon.Party.ABBAN, "reviewed Abban day:3/3 ->1/1, remains fed")
	fed = disk_copy(fed, "actual fed companion day")
	safe_cycle(fed)
	check(fed.player.inventory.water == 0 and fed.player.inventory.food == 0 and Dungeon.Party.current(fed) == "", "player eats first and hungry companion actually leaves")
	fed = disk_copy(fed, "actual hungry companion departure")
	var guide: WorldState = pack_fixture()
	# Reviewed existing party-history fixture: no new NPC or hire lifecycle.
	guide.record_event(EventRecord.new(0, "COMPANION_JOINED", guide.player.npc_id, &"character", {"companion_id": "companion:shahu", "fee": 50}))
	guide.player.money -= 50
	check(engine.validate_invariants(guide) == "", "existing guide history fixture valid")
	safe_cycle(guide)
	check(guide.player.inventory.water == 2 and guide.player.inventory.food == 1, "underground guide does not waive player water; authored companion allowance0/1")
	guide = disk_copy(guide, "actual guide underground day")
	var dry: WorldState = pack_fixture()
	dry.player.inventory.water = 0
	safe_cycle(dry)
	check(dry.current_day == 1 and dry.player.water_exposure == 1.0 and Dungeon.state(dry).active and dry.player.inventory.food == 2, "rich town does not feed expedition; one dry day uses existing grace")
	safe_cycle(dry)
	check(dry.player.water_exposure == 2.0 and Dungeon.state(dry).active, "actual zero-water backtrack remains allowed")
	var fatal: WorldState = pack_fixture()
	fatal.player.inventory.water = 0
	fatal.player.water_exposure = 6.0 # Existing reviewed six-day grace boundary.
	var population_before: int = fatal.get_settlement(Dungeon.HOME).population
	var deaths_before: int = fatal.get_settlement(Dungeon.HOME).cumulative_deaths
	safe_cycle(fatal)
	check(not fatal.npc_life_state_registry.get_life_state(fatal.player.npc_id).is_alive() and not Dungeon.state(fatal).active and fatal.get_settlement(Dungeon.HOME).population == population_before - 1 and fatal.get_settlement(Dungeon.HOME).cumulative_deaths == deaths_before + 1 and engine.validate_invariants(fatal) == "", "actual deprivation death removes one living/adds one death and preserves global life conservation")
	check(fatal.event_log.back().type == "DUNGEON_TRIP_ENDED" and fatal.event_log.back().payload.cause == "dehydration", "trip end binds preceding existing death")
	fatal = disk_copy(fatal, "actual ended deprivation trip")
	rejected(fatal, dungeon_intent(fatal, "ENTER"), "dead traveller cannot revive at entrance")
	clear_slot()

func treatment_contract() -> void:
	var world: WorldState = pack_fixture("SKILL", true)
	var twin: WorldState = disk_copy(world, "owned injured pack disk")
	for item_id: String in ["bandage", "first_aid_kit", "bandage"]:
		pair_intent(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": item_id}), "actual between-fights owned treatment")
	check(world.player.field_kit.hp == 12 and world.player.item_inventory.quantity("bandage") == 0 and world.player.item_inventory.quantity("first_aid_kit") == 0 and world.current_day == 0 and world.player.money == 200, "reviewed healing5 ->7 ->11 ->12 consumes2bandages/1kit, no day/caps")
	rejected(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": "bandage"}), "full health refuses treatment")
	world.player.field_kit.hp = 5
	for payload: Dictionary in [{"command": "TREAT", "item_id": "bandage"}, {"command": "TREAT", "item_id": false}, {"command": "TREAT", "item_id": "scrap"}, {"command": "TREAT", "item_id": "first_aid_kit", "healed": 99}, {"command": "REST"}, {"command": "CRAFT"}]: rejected(world, PlayerIntent.create_field_action(world.player.npc_id, payload), "missing/forged treatment or unrelated field command")
	var fighting: WorldState = pack_fixture("SKILL", true)
	approach_room(fighting, "guard")
	check(engine.commit_player_intent(fighting, fight_intent(fighting, "guard")).success, "actual pending fight treatment fixture")
	var before: String = fighting.to_canonical_json()
	check(engine.tick(fighting).is_empty() and fighting.to_canonical_json() == before, "clock cannot mutate pending dungeon fight")
	rejected(fighting, PlayerIntent.create_field_action(fighting.player.npc_id, {"command": "TREAT", "item_id": "bandage"}), "pending fight forbids potion")
	check(engine.commit_player_intent(fighting, combat_intent(fighting, "FLEE")).success, "actual result pending treatment fixture")
	before = fighting.to_canonical_json()
	check(engine.tick(fighting).is_empty() and fighting.to_canonical_json() == before, "clock cannot mutate pending dungeon result")
	rejected(fighting, PlayerIntent.create_field_action(fighting.player.npc_id, {"command": "TREAT", "item_id": "bandage"}), "pending result forbids potion")
	clear_slot()

func supplies_history() -> void:
	var valid: WorldState = pack_fixture()
	safe_cycle(valid)
	check(WorldState.from_json_checked(valid.to_canonical_json()).success, "actual valid day history control")
	for mode: int in range(13):
		var data: Dictionary = valid.to_dict().duplicate(true)
		var day: Dictionary = last_fact(data, "DUNGEON_DAY_SPENT")
		match mode:
			0: day.payload.water_after = 3
			1: day.payload.food_before = false
			2: day.payload.companion_id = false
			3: day.payload.companion_fed = 1
			4: day.payload.dungeon_id = false
			5: day.payload.room_id = "parts_store"
			6: day.payload.extra = "free"
			7: day.actor_id = "npc:unknown"
			8: day.day += 1
			9: data.events.erase(day)
			10: data.events.append(day.duplicate(true))
			11: last_fact(data, "DUNGEON_ENTERED").payload.trip_rules = 0
			12: day.payload.water_after = "2"
		data.event_count = data.events.size()
		reject_fixture(data, "malformed actual day history %d" % mode)
	var left: WorldState = pack_fixture("ABBAN")
	left.player.inventory.water = 1
	left.player.inventory.food = 1
	safe_cycle(left)
	var missing: Dictionary = left.to_dict().duplicate(true)
	missing.events.erase(last_fact(missing, "COMPANION_LEFT"))
	missing.event_count = missing.events.size()
	reject_fixture(missing, "unfed companion requires actual hunger departure")
	var legacy: WorldState = fresh_towns("settlement:gray_valley")
	enter_legacy_graph(legacy)
	safe_cycle(legacy)
	check(legacy.current_day == 0 and Dungeon.state(legacy).trip_rules == 0, "valid old exploration remains cost-free")
	check(engine.commit_player_intent(legacy, dungeon_intent(legacy, "EXIT")).success and engine.commit_player_intent(legacy, dungeon_intent(legacy, "ENTER")).success, "actual old-trip exit/current-trip entry")
	safe_cycle(legacy)
	check(legacy.current_day == 1 and Dungeon.state(legacy).trip_rules == 1, "next real trip activates clock")
	clear_slot()

func reject_global_fixture(data: Dictionary, label: String) -> void:
	data.event_count = data.events.size()
	var checked: Dictionary = WorldState.from_json_checked(JSON.stringify(data))
	check(not checked.success and checked.world == null, label + " actual checked loader rejects")
	var raw: WorldState = WorldState.from_dict_unchecked(data)
	for event: Dictionary in data.events: raw.event_log.append(EventRecord.from_dict(event))
	check(engine.validate_invariants(raw) != "", label + " actual full live invariants reject")

func need_and_end_history() -> void:
	var dry: WorldState = pack_fixture()
	dry.player.inventory.water = 0
	safe_cycle(dry)
	check(engine.validate_invariants(dry) == "" and WorldState.from_json_checked(dry.to_canonical_json()).success, "actual dry-day positive live/checked controls")
	for mode: int in range(8):
		var data: Dictionary = dry.to_dict().duplicate(true)
		var need: Dictionary = last_fact(data, "PLAYER_NEED_UNMET")
		match mode:
			0: need.target_id = "dungeon:unknown"
			1: data.events.erase(last_fact(data, "DUNGEON_DAY_SPENT"))
			2: need.payload.water_unmet = 0.0
			3: need.payload.water_unmet = false
			4: need.payload.food_unmet = 1.0
			5: need.day = 0
			6: data.events.append(need.duplicate(true))
			7: last_fact(data, "DUNGEON_DAY_SPENT").payload.water_before = 1 # Plausible deduction1->0 contradicts claimed unmet water.
		reject_global_fixture(data, "dry-day need-context corruption %d" % mode)
	var fatal: WorldState = pack_fixture()
	fatal.player.inventory.water = 0
	fatal.player.water_exposure = 6.0
	safe_cycle(fatal)
	check(engine.validate_invariants(fatal) == "" and WorldState.from_json_checked(fatal.to_canonical_json()).success, "actual ended-trip positive live/checked controls")
	for mode: int in range(7):
		var data: Dictionary = fatal.to_dict().duplicate(true)
		var ending: Dictionary = last_fact(data, "DUNGEON_TRIP_ENDED")
		match mode:
			0: data.events.erase(ending)
			1: ending.payload.cause = false
			2: ending.payload.cause = "combat"
			3: ending.payload.room_id = "foyer"
			4: ending.payload.extra = "revive"
			5: ending.actor_id = "npc:unknown"
			6: last_fact(data, "PLAYER_DIED").payload.cause = "starvation"
		reject_global_fixture(data, "actual deprivation-ending corruption %d" % mode)
	var revisit: WorldState = pack_fixture()
	check(engine.commit_player_intent(revisit, dungeon_intent(revisit, "EXIT")).success and engine.commit_player_intent(revisit, dungeon_intent(revisit, "ENTER")).success, "actual trip-version revisit")
	var downgrade: Dictionary = revisit.to_dict().duplicate(true)
	last_fact(downgrade, "DUNGEON_ENTERED").payload.erase("trip_rules")
	reject_global_fixture(downgrade, "activated trip clock cannot downgrade")
	clear_slot()

func full_pack_fixture() -> WorldState:
	var world: WorldState = pack_fixture("TOOL")
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success, "actual town return before equipping")
	check(engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "EQUIP"})).success, "actual existing crowbar equip in town")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "actual equipped revisit")
	world.player.inventory.scrap += world.player.get_effective_capacity() - world.player.get_total_inventory_load()
	# Reviewed registry fixture:15 existing medical kits at800g each =12000g.
	check(world.player.item_inventory.pickup_item("first_aid_kit", 15).success and world.player.item_inventory.total_weight_g() == 12000, "real owned item budget exactly full")
	check(world.player.get_total_inventory_load() == world.player.get_effective_capacity() and engine.validate_invariants(world) == "", "independent full aggregate/item budgets validate")
	return world

func capacity_receipts() -> void:
	var world: WorldState = full_pack_fixture()
	var scrap_before: int = world.player.inventory.scrap
	var money_before: int = world.player.money
	safe_cycle(world)
	check(world.player.get_total_inventory_load() == world.player.get_effective_capacity() - 2, "owned water/food consumption frees exactly two aggregate units")
	approach_room(world, "guard")
	check(engine.commit_player_intent(world, fight_intent(world, "guard")).success, "actual freed-capacity guard fight")
	win(world)
	var receipt: Dictionary = world.event_log[world.field_state.receipt].payload
	check(world.player.inventory.scrap == scrap_before + 2 and world.player.money == money_before + 5 and receipt.gained.size() == 1 and receipt.gained.get("scrap") == 2 and receipt.left_behind.is_empty(), "actual five-cap/two-scrap reward fits consumed-ration room:before%d/%d after%d/%d receipt%s" % [scrap_before, money_before, world.player.inventory.scrap, world.player.money, receipt])
	check(world.player.item_inventory.total_weight_g() == 12000 and not world.player.item_inventory.pickup_item("bandage", 1).success, "aggregate free space does not bypass separately full item budget")
	world = disk_copy(world, "actual full-pack victory receipt")
	clear_slot()

func observe_supplies(label: String, main: Node) -> void:
	if not Dungeon.state(main.world).active:
		await frames()
		check(main.shell.find_child("DungeonScreen", false, false) == null and engine.validate_invariants(main.world) == "", label + " actual closed trip and full invariants")
		return
	await observe_route(label, main)
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	check(screen.supplies_button.get_global_rect().end.x <= root.size.x and screen.supplies_status.get_global_rect().end.y <= root.size.y, "actual pack/time controls fit viewport")
	if is_instance_valid(screen.supplies_dialog):
		var dialog: AcceptDialog = screen.supplies_dialog
		check(not screen.view.enabled and dialog.position.x >= 0 and dialog.position.y >= 0 and dialog.position.x + dialog.size.x <= root.size.x and dialog.position.y + dialog.size.y <= root.size.y, "actual pack dialog fits and pauses:pos%s size%s view_enabled%s" % [dialog.position, dialog.size, screen.view.enabled])
		for button: Button in dialog.treatment_buttons.values(): check(button.size.y >= 40, "actual treatment command touch size")
		check(dialog.get_ok_button().size.y >= 40, "actual pack return touch size")

func guide_trip_exit(screen: Control) -> void:
	for index: int in range(screen.view.doors.size()):
		if screen.view.doors[index].command != "EXIT": continue
		screen.route_choice.select(index)
		screen.guide_button.pressed.emit()
		screen.view.set_process(false)
		for tick: int in range(480):
			if screen.view.target_position.x < 0: break
			screen.view._process(0.08)
			await process_frame
		screen.view.set_process(true)
		check(screen.view.nearest_door().get("command", "") == "EXIT", "actual local walking reaches trip exit")
		screen.interact_button.pressed.emit()
		await frames()
		return
	check(false, "actual exit door required")

func guide_route(screen: Control, destination: String) -> void:
	var selected: int = -1
	for index: int in range(screen.view.doors.size()):
		if screen.view.doors[index].get("room_id", "") == destination and screen.view.doors[index].command == "MOVE": selected = index
	check(selected >= 0, "actual supply route door exists " + destination)
	if selected < 0: return
	var before: String = screen.world.to_canonical_json()
	screen.route_choice.select(selected)
	screen.guide_button.pressed.emit()
	# Exercise the same controller with its supported maximum step. This keeps
	# slow/fast headless machines bounded without setting a world checkpoint.
	screen.view.set_process(false)
	for tick: int in range(160):
		if screen.view.target_position.x < 0: break
		screen.view._process(0.08)
		await process_frame
	screen.view.set_process(true)
	check(screen.view.nearest_door().get("room_id", "") == destination and screen.world.to_canonical_json() == before, "actual pack route walking reaches door without time/resource mutation")

func supply_variants_ui() -> void:
	for variant: String in ["companion", "low", "fatal", "full", "legacy"]:
		clear_slot()
		var world: WorldState = full_pack_fixture() if variant == "full" else pack_fixture("ABBAN" if variant == "companion" else "SKILL", variant == "legacy")
		if variant in ["low", "fatal"]: world.player.inventory.water = 0
		if variant == "fatal": world.player.water_exposure = 6.0
		if variant == "legacy":
			world.event_log.back().payload.erase("trip_rules") # Reviewed DUN-4 three-key checkpoint.
			world.event_log.back().payload.erase("deep_rules")
			world.event_log.back().payload.erase("device_rules")
		check(store.save_game(world).success, "actual variant UI slot " + variant)
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("DungeonScreen", false, false)
		screen.supplies_button.pressed.emit()
		await observe_supplies(variant + "_pack", main)
		if variant == "full": check(screen.supplies_dialog.summary.text.contains("道具12.0/12.0kg") and screen.supplies_dialog.summary.text.contains("物資20/20"), "both real full-capacity budgets displayed")
		if variant == "legacy":
			check(screen.supplies_dialog.summary.text.contains("舊旅程不計日") and not screen.supplies_dialog.treatment_buttons.bandage.disabled, "valid older trip truthful cost and owned treatment")
			screen.supplies_dialog.treatment_buttons.bandage.pressed.emit()
			await observe_supplies("legacy_actual_bandage", main)
			check(main.world.player.field_kit.hp == 7 and main.world.current_day == 0, "actual legacy trip treatment remains valid")
		screen.supplies_dialog.get_ok_button().pressed.emit()
		await frames()
		for target: String in ["foyer", "parts_store", "foyer", "entrance"]:
			await guide_route(screen, target)
			screen.interact_button.pressed.emit()
			await frames()
		await observe_supplies(variant + "_day", main)
		if variant == "companion":
			check(main.world.player.inventory.water == 1 and main.world.player.inventory.food == 1, "actual UI Abban consumes owned companion rations")
			for target: String in ["foyer", "parts_store", "foyer", "entrance"]:
				await guide_route(screen, target)
				screen.interact_button.pressed.emit()
				await frames()
			screen.supplies_button.pressed.emit()
			await observe_supplies("companion_hunger_departure", main)
			check(Dungeon.Party.current(main.world) == "" and screen.supplies_dialog.summary.text.contains("獨行"), "actual UI shows lost hungry companion")
			screen.supplies_dialog.get_ok_button().pressed.emit()
			await frames()
		elif variant == "low":
			await guide_trip_exit(screen)
			await observe_supplies("low_actual_retreat", main)
			check(main.world.current_day == 1 and main.world.player.water_exposure == 1.0 and not Dungeon.state(main.world).active, "actual empty-water retreat preserves paid day and exposure")
		elif variant == "fatal": check(main.shell.death_banner.visible and not main.world.npc_life_state_registry.get_life_state(main.world.player.npc_id).is_alive(), "actual deprivation death banner after closed trip")
		elif variant == "legacy": check(main.world.current_day == 0, "actual four-door old trip keeps original clock")
		main.queue_free()
		await frames()
		clear_slot()

func supplies_ui() -> void:
	clear_slot()
	var world: WorldState = pack_fixture("SKILL", true)
	check(store.save_game(world).success, "actual injured supplies UI save")
	var main: Node = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	await observe_supplies("injured_exploration", main)
	var before: String = main.world.to_canonical_json()
	screen.supplies_button.pressed.emit()
	await observe_supplies("owned_pack", main)
	check(main.world.to_canonical_json() == before and not screen.supplies_dialog.treatment_buttons.bandage.disabled, "pack browsing read-only and owned treatment available")
	var local_position: Vector2 = screen.view.actor_position
	screen.supplies_dialog.treatment_buttons.bandage.pressed.emit()
	await observe_supplies("actual_bandage", main)
	check(main.world.player.field_kit.hp == 7 and main.world.player.item_inventory.quantity("bandage") == 1 and main.world.current_day == 0 and screen.view.actor_position == local_position and screen.supplies_dialog.notice.text.contains("恢復2"), "actual pack button heals/spends once and retains room position")
	screen.supplies_dialog.get_ok_button().pressed.emit()
	await frames()
	for target: String in ["foyer", "parts_store", "foyer", "entrance"]:
		await guide_route(screen, target)
		screen.interact_button.pressed.emit()
		await frames()
	await observe_supplies("actual_spent_day", main)
	check(main.world.current_day == 1 and main.world.player.inventory.water == 2 and screen.supplies_status.text.contains("已過1日"), "real UI fourth door displays consumed day/supplies")
	screen.supplies_button.pressed.emit()
	await observe_supplies("spent_day_pack", main)
	screen.supplies_dialog.get_ok_button().pressed.emit()
	await frames()
	find_command(screen, "存讀檔").pressed.emit()
	await frames()
	main.save_dialog.save_button.pressed.emit()
	before = main.world.to_canonical_json()
	main.queue_free()
	await frames()
	main = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	await observe_supplies("continued_time_pack", main)
	check(main.world.to_canonical_json() == before, "actual startup Continue preserves supplies and paid time")
	main.queue_free()
	await frames()
	clear_slot()

func run_supplies() -> void:
	root.size = Vector2i(1280, 720)
	clock_replay()
	companions_and_death()
	treatment_contract()
	supplies_history()
	need_and_end_history()
	capacity_receipts()
	await supplies_ui()
	await supply_variants_ui()
	print("DUN-5: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
