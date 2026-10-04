extends "res://tests/test_dungeon_supplies.gd"

const Rumors = preload("res://simulation/rumors.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Well = preload("res://simulation/well_repair.gd")

func _init() -> void:
	store = Store.new("user://tests/dun6/journey.json")
	call_deferred("run_deep")

func deep_fixture(protected: bool = true, chase: bool = false) -> WorldState:
	var world: WorldState = route_fixture("SKILL")
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success, "actual town preparation before deep trip")
	world.player.inventory.water = 6
	world.player.inventory.food = 6
	world.player.inventory.scrap = 4
	# Reviewed existing registry-owned equipment fixture. Mask acquisition is
	# independently exercised by the real GEAR-2E road retrieval suite.
	for item_id: String in ["combat_knife", "leather_jacket", "bandage"]:
		check(world.player.pickup_item(item_id).success, "reviewed owned deep equipment " + item_id)
	if protected: check(world.player.pickup_item("military_gas_mask").success, "reviewed existing mask ownership")
	for pair: Array in [["combat_knife", "main_hand"], ["leather_jacket", "body"]]:
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(pair[0]), pair[1])).success, "actual pretrip equipment intent")
	if chase: check(engine.commit_player_intent(world, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:waterworks_tools")).success, "actual optional heard waterworks pursuit")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success and Dungeon.state(world).deep_rules == 1, "actual current deep entry")
	check(engine.validate_invariants(world) == "", "actual deep preparation invariants")
	return world

func recover_intent(world: WorldState) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "RECOVER_TOOLS"})

func to_pump(world: WorldState, twin: WorldState = null) -> void:
	for destination: String in ["foyer", "maintenance"]:
		var intent: PlayerIntent = dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, destination)
		if twin == null: check(engine.commit_player_intent(world, intent).success, "actual prepared bypass approach")
		else: pair_intent(world, twin, intent, "actual prepared bypass twin")
	var opening: PlayerIntent = maintenance_intent(world, "SKILL")
	if twin == null: check(engine.commit_player_intent(world, opening).success, "actual once-paid bypass")
	else: pair_intent(world, twin, opening, "actual once-paid bypass twin")
	var move: PlayerIntent = dungeon_intent(world, "MOVE", "maintenance", "pump")
	if twin == null: check(engine.commit_player_intent(world, move).success, "actual prepared pump arrival")
	else: pair_intent(world, twin, move, "actual prepared pump twin")

func fight_pair(world: WorldState, twin: WorldState, room: String) -> void:
	pair_intent(world, twin, fight_intent(world, room), "actual chosen deep battle")
	for turn_index: int in range(12):
		if world.field_state.battle.is_empty(): break
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "actual deep battle strike twin")
	check(world.field_state.receipt >= 0 and world.event_log[world.field_state.receipt].payload.outcome == "VICTORY", "prepared equipment survives actual deep opponent")
	rejected(world, recover_intent(world), "unconfirmed deep result cannot recover")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "actual confirmed deep battle")

func cleared_deep() -> WorldState:
	var world: WorldState = deep_fixture()
	to_pump(world)
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "pump", "polluted_store")).success, "actual masked entry before clearance")
	check(engine.commit_player_intent(world, fight_intent(world, "polluted_store")).success, "actual ghoul for recovery fixture")
	win(world)
	check(engine.commit_player_intent(world, combat_intent(world, "CONFIRM")).success, "actual clearance confirmation")
	return world

func prepared_replay() -> void:
	clear_slot()
	var world: WorldState = deep_fixture()
	var twin: WorldState = disk_copy(world, "prepared optional-no-rumor entry")
	to_pump(world, twin)
	fight_pair(world, twin, "pump")
	if world.player.field_kit.hp < 12:
		pair_intent(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": "bandage"}), "actual expedition injury treatment")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "pump", "polluted_store"), "actual mask-authorized four-door day")
	check(world.current_day == 1 and world.player.inventory.water == 5 and world.player.inventory.food == 5 and world.player.item_inventory.contains("military_gas_mask"), "reviewed prepared first day5/5, retained mask")
	rejected(world, recover_intent(world), "real uncleared cache refuses")
	fight_pair(world, twin, "polluted_store")
	var before_day: int = world.current_day
	var before_money: int = world.player.money
	pair_intent(world, twin, recover_intent(world), "actual owned tool recovery twin")
	check(world.player.item_inventory.quantity("fieldrepair_precision_kit") == 1 and Dungeon.state(world).tools_recovered and world.current_day == before_day and world.player.money == before_money, "one actual existing tool, no recovery day/caps")
	check(Gear.tool_grade(world.player, "MECHANICS") == 3 and Well.material_cost(world, "REPAIR_PUMP") == 2 and Well.material_cost(world, "REWIRE_PUMP") == 3, "independent authored tool3/mechanical-only 3->2 scrap benefit")
	check(Rumors.progress(world, "rumor:waterworks_tools").done and Rumors.tracked(world) == "", "actual recovery settles optional untracked rumor")
	twin = disk_copy(world, "actual recovered tool day disk")
	rejected(world, recover_intent(world), "once-only same-room recovery")
	for target: String in ["pump", "control"]: pair_intent(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual rewarded return")
	pair_intent(world, twin, dungeon_intent(world, "OPEN_SHORTCUT"), "actual prepared return shortcut")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "control", "entrance"), "actual shortcut return")
	pair_intent(world, twin, dungeon_intent(world, "EXIT"), "actual complete single visit")
	check(world.current_day == 1 and Dungeon.state(world).trip_moves == 7 and not Dungeon.state(world).active, "reviewed single prepared visit seven moves/one full day")
	twin = disk_copy(world, "actual useful reward returned town")
	check(world.player.drop_item("fieldrepair_precision_kit").success and twin.player.drop_item("fieldrepair_precision_kit").success, "reviewed later owned tool drop fixture")
	pair_intent(world, twin, dungeon_intent(world, "ENTER"), "actual reward-empty revisit")
	for target: String in ["control", "pump", "polluted_store"]: pair_intent(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual cleared revisit")
	rejected(world, recover_intent(world), "dropping owned prize cannot reset cache")
	parity(world, twin, "actual once-only empty-pack revisit SHA")
	clear_slot()

func first_visit_and_legacy() -> void:
	var world: WorldState = deep_fixture(false, true)
	to_pump(world)
	rejected(world, dungeon_intent(world, "MOVE", "pump", "polluted_store"), "actual first trip mask gate")
	check(Rumors.progress(world, "rumor:waterworks_tools").next.contains("缺軍規防毒面具"), "actual pursuit names concrete missing equipment/source")
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "pump", "control")).success and engine.commit_player_intent(world, dungeon_intent(world, "OPEN_SHORTCUT")).success, "unprepared traveller opens useful actual shortcut")
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "control", "entrance")).success and engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success, "actual first trip costed retreat")
	var first_scrap: int = world.player.inventory.scrap
	world = disk_copy(world, "actual first mask refusal/shortcut returned town")
	check(world.player.pickup_item("military_gas_mask").success, "reviewed later equipment obtained before revisit")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "actual capability-changed revisit")
	for destination: String in ["control", "pump", "polluted_store"]: check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, destination)).success, "actual retained shortcut masked revisit")
	check(world.player.inventory.scrap == first_scrap and Dungeon.state(world).maintenance_open, "prepared revisit does not recharge opened bypass")
	check(engine.commit_player_intent(world, fight_intent(world, "polluted_store")).success, "actual revisit ghoul")
	win(world)
	check(engine.commit_player_intent(world, combat_intent(world, "CONFIRM")).success and engine.commit_player_intent(world, recover_intent(world)).success, "actual second visit reward")
	world = disk_copy(world, "actual changed-capability reward disk")
	var legacy: WorldState = deep_fixture(false)
	for event: EventRecord in legacy.event_log:
		if event.type == "DUNGEON_ENTERED":
			event.payload.erase("deep_rules") # Reviewed valid four-key DUN-5 checkpoint.
			event.payload.erase("device_rules")
	to_pump(legacy)
	check(engine.commit_player_intent(legacy, dungeon_intent(legacy, "MOVE", "pump", "polluted_store")).success and legacy.current_day == 1, "old costed trip keeps original wing access without new mask requirement")
	legacy = disk_copy(legacy, "actual valid old polluted-room checkpoint")
	rejected(legacy, recover_intent(legacy), "legacy wing cannot create current-rule prize")
	check(legacy.player.drop_item("bandage").success and engine.commit_player_intent(legacy, dungeon_intent(legacy, "MOVE", "polluted_store", "pump")).success, "old wing backtracks normally")
	clear_slot()

func reward_refusals_history() -> void:
	var world: WorldState = cleared_deep()
	var baseline: Dictionary = world.to_dict().duplicate(true)
	for payload: Dictionary in [{"command": "RECOVER_TOOLS", "quantity": 2}, {"command": false}, {"command": "RECOVER_TOOLS", "item_id": "fieldrepair_precision_kit"}, {"command": "ENTER", "deep_rules": 0}]: rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload), "forged reward/version selector")
	rejected(world, PlayerIntent.create_dungeon_action(&"npc:unknown", {"command": "RECOVER_TOOLS"}), "wrong recovery actor")
	check(world.player.pickup_item("first_aid_kit", 11).success and engine.validate_invariants(world) == "", "reviewed valid item budget with less than1.8kg free")
	rejected(world, recover_intent(world), "actual owned item capacity blocks recovery atomically")
	check(not Dungeon.state(world).tools_recovered and world.player.drop_item("first_aid_kit", 11).success, "failed pickup leaves actual cache available")
	check(world.player.pickup_item("fieldrepair_precision_kit").success, "reviewed previously-owned identical tool")
	rejected(world, recover_intent(world), "nonstackable owned tool refuses without marking reward taken")
	check(world.player.drop_item("fieldrepair_precision_kit").success and engine.commit_player_intent(world, recover_intent(world)).success, "actual cleaned pack can recover once")
	check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "actual valid recovered-history live/checked controls")
	for mode: int in range(11):
		var data: Dictionary = world.to_dict().duplicate(true)
		var reward: Dictionary = last_fact(data, "DUNGEON_TOOLS_RECOVERED")
		match mode:
			0: reward.payload.quantity = false
			1: reward.payload.quantity = 2
			2: reward.payload.item_id = "wrench"
			3: reward.payload.item_id = false
			4: reward.payload.room_id = "pump"
			5: reward.payload.dungeon_id = false
			6: reward.actor_id = "npc:unknown"
			7: reward.payload.extra = "bonus"
			8: data.events.append(reward.duplicate(true))
			9: reward.day += 1
			10: last_fact(data, "DUNGEON_ENTERED").payload.erase("deep_rules")
		reject_global_fixture(data, "actual reward history corruption %d" % mode)
	for invalid: Variant in [false, "wrench", 1, null]:
		var data: Dictionary = baseline.duplicate(true)
		last_fact(data, "DUNGEON_ROOM_ENTERED").payload.protection_item = invalid
		reject_global_fixture(data, "actual pollution proof malformed type/value")
	var missing: Dictionary = baseline.duplicate(true)
	last_fact(missing, "DUNGEON_ROOM_ENTERED").payload.erase("protection_item")
	reject_global_fixture(missing, "actual current wing entry requires typed proof")
	for invalid: Variant in [false, "1", 0, 2, null, {}]:
		var data: Dictionary = baseline.duplicate(true)
		last_fact(data, "DUNGEON_ENTERED").payload.deep_rules = invalid
		reject_global_fixture(data, "current deep-entry version rejects malformed type/value")
	# Preserve valid state by selecting the real pre-fight checkpoint separately.
	var before_fight: WorldState = deep_fixture()
	to_pump(before_fight)
	check(engine.commit_player_intent(before_fight, dungeon_intent(before_fight, "MOVE", "pump", "polluted_store")).success, "actual uncleared history seed")
	var no_clearance: Dictionary = before_fight.to_dict().duplicate(true)
	no_clearance.events.append(world.event_log.back().to_dict())
	reject_global_fixture(no_clearance, "plausible exact prize without actual ghoul clearance")
	check(world.player.drop_item("military_gas_mask").success and engine.validate_invariants(world) == "", "reviewed missing-current-mask snapshot retains valid prior protection proof")
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "polluted_store", "pump")).success, "actual backtrack cannot trap a traveller without current mask")
	rejected(world, dungeon_intent(world, "MOVE", "pump", "polluted_store"), "new reentry still checks actual current ownership")
	clear_slot()

func observe_deep(label: String, main: Node) -> void:
	await observe_supplies(label, main)
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	if screen != null and is_instance_valid(screen.combat_screen):
		await observe(label, main)
	if is_instance_valid(main.shell.rumor_window):
		var dialog: AcceptDialog = main.shell.rumor_window
		check(dialog.position.x >= 0 and dialog.position.y >= 0 and dialog.position.x + dialog.size.x <= root.size.x and dialog.position.y + dialog.size.y <= root.size.y, "actual waterworks rumor window fits")

func waterworks_title(node: Node) -> Label:
	if node is Label and node.text == "水廠深處的維修精密組": return node
	for child: Node in node.get_children():
		var found: Label = waterworks_title(child)
		if found != null: return found
	return null

func show_waterworks_card(main: Node) -> void:
	await frames()
	var dialog: AcceptDialog = main.shell.rumor_window
	# Dummy DisplayServer ignores popup_centered's size for this existing
	# non-wrapping window. Materialize its requested viewport for CPU layout QA;
	# real Vulkan captures exercise the unmodified production popup sizing.
	if DisplayServer.get_name() == "headless":
		dialog.size = Vector2i(mini(640, root.size.x - 40), int(root.size.y * 0.8))
		await frames()
	var title: Label = waterworks_title(dialog)
	check(title != null, "actual heard waterworks rumor card exists")
	if title == null: return
	var card: Control = title.get_parent().get_parent().get_parent()
	var scroll: ScrollContainer
	for child: Node in dialog.get_children():
		if child is ScrollContainer: scroll = child
	check(scroll != null, "actual rumor scroll required")
	if scroll == null: return
	scroll.ensure_control_visible(card)
	await frames()
	check(scroll.get_global_rect().encloses(card.get_global_rect()), "actual whole waterworks card/choice scrolled into visible area:card%s scroll%s" % [card.get_global_rect(), scroll.get_global_rect()])

func guide_deep_command(screen: Control, command_name: String) -> void:
	var selected: int = -1
	for index: int in range(screen.view.doors.size()):
		if screen.view.doors[index].command == command_name: selected = index
	check(selected >= 0, "actual deep interaction exists " + command_name)
	if selected < 0: return
	var before: String = screen.world.to_canonical_json()
	screen.route_choice.select(selected)
	screen.guide_button.pressed.emit()
	screen.view.set_process(false)
	for tick: int in range(160):
		if screen.view.target_position.x < 0: break
		screen.view._process(0.08)
		await process_frame
	screen.view.set_process(true)
	check(screen.view.nearest_door().get("command", "") == command_name and screen.world.to_canonical_json() == before, "actual cache/enemy walking remains read-only")

func show_owned_pack_item(dialog: AcceptDialog, name_zh: String) -> Label:
	for row: Node in dialog.items_column.get_children():
		var description: Label = row.get_child(1)
		if not description.text.begins_with(name_zh): continue
		var scroll: ScrollContainer = dialog.items_column.get_parent()
		scroll.ensure_control_visible(row)
		await frames()
		check(scroll.get_global_rect().encloses(row.get_global_rect()), "actual owned item description scrolled into pack " + name_zh)
		return description
	check(false, "actual owned pack item required " + name_zh)
	return null

func deep_ui() -> void:
	clear_slot()
	var world: WorldState = deep_fixture(false)
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success and store.save_game(world).success, "actual untracked rumor town UI save")
	var main: Node = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	find_command(main.shell, "傳聞").pressed.emit()
	await show_waterworks_card(main)
	await observe_deep("heard_waterworks_rumor", main)
	var chase: Button = main.shell.rumor_window.rumor_buttons["rumor:waterworks_tools"]
	check(chase.size.y >= 40, "actual rumor pursuit touch height")
	chase.pressed.emit()
	await frames()
	await show_waterworks_card(main)
	await observe_deep("tracked_waterworks_rumor", main)
	check(Rumors.tracked(main.world) == "rumor:waterworks_tools", "actual town rumor button commits chosen pursuit")
	main.queue_free()
	await frames()
	clear_slot()
	world = deep_fixture(false, true)
	to_pump(world)
	check(store.save_game(world).success, "actual unprepared pump UI save")
	main = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	await observe_deep("unprepared_pump", main)
	await guide_route(screen, "polluted_store")
	await observe_deep("unprepared_mask_gate", main)
	check(screen.interact_button.disabled and screen.interact_button.tooltip_text.contains("軍規防毒面具"), "actual physical pollution gate shows missing owned protection")
	var before: String = main.world.to_canonical_json()
	screen.interact_button.pressed.emit()
	check(main.world.to_canonical_json() == before, "disabled/forged UI pollution click cannot bypass actual mask")
	screen.map_button.pressed.emit()
	await observe_deep("unprepared_pollution_map", main)
	screen.map_dialog.get_ok_button().pressed.emit()
	await frames()
	main.queue_free()
	await frames()
	clear_slot()
	world = deep_fixture()
	to_pump(world)
	check(store.save_game(world).success, "actual prepared pump UI save")
	main = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	screen = main.shell.find_child("DungeonScreen", false, false)
	screen.supplies_button.pressed.emit()
	await frames()
	var mask_description: Label = await show_owned_pack_item(screen.supplies_dialog, "軍規防毒面具")
	await observe_deep("prepared_mask_description", main)
	check(mask_description != null and mask_description.text.contains("水廠污染庫房"), "actual protection item explains newly available wing")
	screen.supplies_dialog.get_ok_button().pressed.emit()
	await frames()
	await guide_route(screen, "polluted_store")
	await observe_deep("prepared_pollution_gate", main)
	check(not screen.interact_button.disabled, "actual owned mask opens physical interaction")
	screen.interact_button.pressed.emit()
	await observe_deep("polluted_threat_and_cache", main)
	await guide_deep_command(screen, "RECOVER_TOOLS")
	await observe_deep("uncleared_cache_refusal", main)
	check(screen.interact_button.disabled, "actual cache waits for confirmed ghoul clearance")
	await guide_deep_command(screen, "FIGHT")
	screen.interact_button.pressed.emit()
	await frames()
	await observe_deep("actual_polluted_ghoul_battle", main)
	var battle: Control = screen.combat_screen
	battle.reduce_motion.button_pressed = true
	for index: int in range(12):
		if main.world.field_state.battle.is_empty(): break
		await battle_command(battle, "ATTACK")
	await observe_deep("actual_polluted_ghoul_victory", main)
	await battle_command(battle, "CONFIRM")
	await frames()
	await guide_deep_command(screen, "RECOVER_TOOLS")
	await observe_deep("cleared_cache_ready", main)
	var position_before: Vector2 = screen.view.actor_position
	screen.interact_button.pressed.emit()
	await observe_deep("actual_tools_recovered", main)
	check(main.world.player.item_inventory.quantity("fieldrepair_precision_kit") == 1 and screen.view.actor_position == position_before, "actual UI pickup retains feet and commits one owned tool")
	screen.supplies_button.pressed.emit()
	await frames()
	var tool_description: Label = await show_owned_pack_item(screen.supplies_dialog, "現地維修精密組")
	await observe_deep("actual_recovered_pack", main)
	check(main.world.player.item_inventory.total_weight_g() == 4650 and screen.supplies_dialog.summary.text.contains("4.7/12.0kg"), "reviewed mask800/knife450/armor1400/bandage200/tool1800g totals4650g, displayed to one decimal")
	check(tool_description != null and tool_description.text.contains("少耗 1 廢料"), "actual recovered tool description names its existing material benefit")
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
	screen = main.shell.find_child("DungeonScreen", false, false)
	await observe_deep("continued_recovered_room", main)
	check(main.world.to_canonical_json() == before, "actual startup Continue preserves one-time deep reward")
	for target: String in ["pump", "control"]:
		await guide_route(screen, target)
		screen.interact_button.pressed.emit()
		await frames()
	await guide_deep_command(screen, "OPEN_SHORTCUT")
	screen.interact_button.pressed.emit()
	await frames()
	await guide_route(screen, "entrance")
	screen.interact_button.pressed.emit()
	await frames()
	await guide_trip_exit(screen)
	await observe_deep("actual_tool_returned_town", main)
	find_command(main.shell, "傳聞").pressed.emit()
	await show_waterworks_card(main)
	await observe_deep("actual_waterworks_rumor_done", main)
	check(Rumors.progress(main.world, "rumor:waterworks_tools").done, "actual returned rumor shows persistent recovery completion")
	main.queue_free()
	await frames()
	clear_slot()
	for variant: String in ["full", "legacy"]:
		world = cleared_deep() if variant == "full" else deep_fixture(false)
		if variant == "full": check(world.player.pickup_item("first_aid_kit", 11).success, "actual full-cache UI fixture")
		else:
			for event: EventRecord in world.event_log:
				if event.type == "DUNGEON_ENTERED":
					event.payload.erase("deep_rules")
					event.payload.erase("device_rules")
			to_pump(world)
		check(store.save_game(world).success, "actual variant deep UI save " + variant)
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("DungeonScreen", false, false)
		if variant == "full":
			await guide_deep_command(screen, "RECOVER_TOOLS")
			await observe_deep("full_item_cache_refusal", main)
			check(screen.interact_button.disabled and screen.interact_button.tooltip_text.contains("1.8公斤"), "actual full cache explains real item space")
		else:
			await guide_route(screen, "polluted_store")
			screen.interact_button.pressed.emit()
			await frames()
			await observe_deep("legacy_polluted_room", main)
			for door: Dictionary in screen.view.doors: check(door.command != "RECOVER_TOOLS", "valid old wing has no new unsupported prize")
		main.queue_free()
		await frames()
		clear_slot()

func run_deep() -> void:
	root.size = Vector2i(1280, 720)
	prepared_replay()
	first_visit_and_legacy()
	reward_refusals_history()
	await deep_ui()
	print("DUN-6: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
