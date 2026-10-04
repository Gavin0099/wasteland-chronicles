extends "res://tests/test_dungeon_device_choice.gd"

const Trust = preload("res://simulation/local_trust.gd")

func _init() -> void:
	store = Store.new("user://tests/dun8/journey.json")
	call_deferred("run_return")

func report_intent(world: WorldState) -> PlayerIntent:
	return dungeon_intent(world, "REPORT")

func return_fixture() -> WorldState:
	var world: WorldState = deep_fixture()
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success, "actual last-slice town preparation")
	world.player.money = 500 # Reviewed initial bankroll; all later costs use actual intents.
	check(world.player.pickup_item("rope").success, "reviewed owned existing rope; actual timed route choices use it")
	check(engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Dungeon.Party.ABBAN)).success, "actual paid Abban preparation")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "actual prepared last-slice entry")
	return world

func return_act(world: WorldState, twin: WorldState, intent: PlayerIntent, label: String) -> void:
	if twin == null:
		check(engine.commit_player_intent(world, intent).success, label)
		check(engine.validate_invariants(world) == "", label + " global invariants")
	else:
		var result: Dictionary = pair_intent(world, twin, intent, label)
		if not result.success: print("RETURN FAILURE ", label, " ", result, " day", world.current_day, " life", world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id)

func returned_world(choice: String, replay: bool = true) -> WorldState:
	var world: WorldState = return_fixture()
	var twin: WorldState = disk_copy(world, "whole journey prepared entry") if replay else null
	to_pump(world, twin)
	if twin != null: fight_pair(world, twin, "pump")
	else:
		return_act(world, null, fight_intent(world, "pump"), "actual optional pump fight")
		win(world)
		return_act(world, null, combat_intent(world, "CONFIRM"), "actual pump confirmation")
	return_act(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "TREAT", "item_id": "bandage"}), "actual owned expedition treatment")
	return_act(world, twin, dungeon_intent(world, "MOVE", "pump", "polluted_store"), "actual masked entry/supply day")
	if twin != null: fight_pair(world, twin, "polluted_store")
	else:
		return_act(world, null, fight_intent(world, "polluted_store"), "actual deep fight")
		win(world)
		return_act(world, null, combat_intent(world, "CONFIRM"), "actual deep confirmation")
	return_act(world, twin, recover_intent(world), "actual once-only useful reward")
	for target: String in ["pump", "control"]:
		return_act(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual deep return route")
	return_act(world, twin, device_intent(world, choice), "actual permanent device choice")
	rejected(world, report_intent(world), "must exit stairs after actual device choice")
	leave_control(world, twin)
	check(world.current_day == 1 and world.player.inventory.water == 4 and world.player.inventory.food == 4, "independent one dungeon day/two owned rations each")
	check(world.player.inventory.scrap == (5 if choice == "PRESERVE" else 12) and world.player.money == 460, "independent battle/gate/device scrap and hire/caps accounting")
	check(world.player.item_inventory.contains("fieldrepair_precision_kit") and Dungeon.state(world).returned and not Dungeon.state(world).reported, "actual owned useful reward and optional unreported return")
	check(Trust.score(world, String(Dungeon.HOME)) == 0, "exit alone never reports or grants trust")
	return disk_copy(world, "complete actual returned journey checkpoint")

func finish_road(world: WorldState, twin: WorldState = null) -> void:
	for step: int in range(24):
		if world.pending_encounter_result >= 0:
			return_act(world, twin, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result), "actual receipt continuation")
			continue
		if world.active_encounter == null:
			return
		var option: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: option = &"BRIBE"
			TravelEncounter.ROCKSLIDE: option = &"USE_ROPE"
			TravelEncounter.ROADBLOCK: option = &"PAY"
		return_act(world, twin, PlayerIntent.create_resolve_encounter(world.player.npc_id, option), "actual other road choice")
	check(false, "bounded real journey terminates")

func buy_rations(world: WorldState, twin: WorldState, quantity: int) -> void:
	for commodity: StringName in [&"water", &"food"]:
		return_act(world, twin, PlayerIntent.create_buy(world.player.npc_id, commodity, quantity), "actual market-funded trip rations")

func repair_visit(world: WorldState, twin: WorldState = null) -> String:
	return_act(world, twin, PlayerIntent.create_sell(world.player.npc_id, &"scrap", 1), "actual retained-tool branch sells one spare scrap")
	buy_rations(world, twin, 3)
	return_act(world, twin, PlayerIntent.create_track_rumor(world.player.npc_id, "rumor:old_well"), "actual old-well pursuit")
	return_act(world, twin, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well"), "actual journey to unclaimed well")
	check(world.active_encounter != null and world.active_encounter.context.get("place_id") == Well.PLACE, "actual old-well encounter")
	return_act(world, twin, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"MARK_A"), "actual Gray Valley claim")
	finish_road(world, twin)
	buy_rations(world, twin, 3)
	return_act(world, twin, PlayerIntent.create_travel(world.player.npc_id, Dungeon.HOME), "actual return to owner town")
	finish_road(world, twin)
	var job: String = ""
	for entry: Dictionary in Board.postings(world, Dungeon.HOME):
		if Well.is_contract(entry.definition): job = entry.definition.id
	check(job != "", "actual owner repair contract posted")
	return_act(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, job), "actual owned repair contract acceptance")
	rejected(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, job), "owned loot alone does not repair a well")
	buy_rations(world, twin, 5)
	return_act(world, twin, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well"), "actual contracted well visit")
	check(world.active_encounter != null and world.active_encounter.context.get("repair_visit", false), "actual contract reopens physical well")
	var before_day: int = world.current_day
	var before_production: int = world.get_settlement(Dungeon.HOME).production.water
	return_act(world, twin, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"REPAIR_PUMP"), "actual useful recovered-tool repair")
	check(world.current_day == before_day + 1 and world.player.inventory.scrap == 2 and world.player.item_inventory.contains("fieldrepair_precision_kit"), "independent actual one-day/two-scrap repair with retained tool")
	check(Well.state(world).status == "WORKING" and world.get_settlement(Dungeon.HOME).production.water == before_production + 1, "actual existing repaired town production")
	check(world.event_log[world.pending_encounter_result].payload.spent.scrap == 2 and QuestEngine.evaluate_objectives(world, job), "actual receipt/tool discount/contract effect")
	check(String(PlayerUIProjection.project(world).encounter_result.place_note).contains("故障 → 運轉"), "actual useful loot receipt projects working pump")
	return job

func return_replay() -> void:
	for choice: String in ["PRESERVE", "SALVAGE"]:
		var world: WorldState = returned_world(choice)
		var twin: WorldState = disk_copy(world, "actual optional return twin")
		var before: Dictionary = world.player.to_dict()
		var day: int = world.current_day
		return_act(world, twin, report_intent(world), "actual voluntary report twin")
		var standing: int = 3 if choice == "PRESERVE" else -3
		check(Trust.score(world, String(Dungeon.HOME)) == standing and Trust.faction_score(world, "forge") == standing and Trust.score(world, "settlement:iron_pass") == 0, "independent exact local/shared forge reaction")
		check(Trust.faction_score(world, "free_wells") == 0 and world.player.to_dict() == before and world.current_day == day, "report does not grant cash/XP/items/day or another faction")
		rejected(world, report_intent(world), "once-only actual report")
		twin = disk_copy(world, "actual reported Continue twin")
		if choice == "PRESERVE":
			var job: String = repair_visit(world, twin)
			twin = disk_copy(world, "actual repaired world/resolution persistence")
			finish_road(world, twin)
			buy_rations(world, twin, 4)
			return_act(world, twin, PlayerIntent.create_travel(world.player.npc_id, Dungeon.HOME), "actual return for repair payment")
			finish_road(world, twin)
			var cash: int = world.player.money
			var xp: int = world.player.xp
			return_act(world, twin, PlayerIntent.create_turn_in_quest(world.player.npc_id, job), "actual existing repair contract paid")
			check(world.player.money == cash + 88 and int(world.accepted_jobs[job].outcomes.resolved.rewards[0].amount) == 88 and world.player.xp == xp + 12, "immutable accepted repair payout and authored XP12")
			check(Trust.score(world, String(Dungeon.HOME)) == 8 and Trust.faction_score(world, "forge") == 8 and Trust.faction_tier(world, "forge") == Trust.FACTION_COOPERATE, "report3 + existing well claim3 + quest2 gives real cooperation")
			check(Trust.reward_multiplier(world, "settlement:iron_pass") == 1.05 and Trust.reward_multiplier(world, String(Dungeon.HOME)) == 1.1, "existing peer service/local bonuses do not compound")
			rejected(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, job), "no duplicate repair payout")
		else:
			var cash: int = world.player.money
			return_act(world, twin, PlayerIntent.create_sell_item(world.player.npc_id, &"fieldrepair_precision_kit", 1), "actual alternative loot sale")
			check(not world.player.item_inventory.contains("fieldrepair_precision_kit") and world.player.money > cash and Dungeon.state(world).tools_recovered, "actual sale pays and preserves once-only cache")
		return_act(world, twin, dungeon_intent(world, "ENTER"), "actual post-return revisit")
		for target: String in ["control", "pump", "polluted_store"]:
			return_act(world, twin, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, target), "actual saved shortcut/clearance revisit")
		rejected(world, recover_intent(world), "sold or kept loot cannot respawn")
		rejected(world, device_intent(world, "SALVAGE"), "returned device choice cannot repeat")
		rejected(world, report_intent(world), "revisit cannot repeat standing")
		parity(world, twin, "full return/use/sale/revisit SHA256")
	clear_slot()

func report_refusals_and_history() -> void:
	var undecided: WorldState = return_fixture()
	rejected(undecided, report_intent(undecided), "no device report before choice")
	var world: WorldState = returned_world("PRESERVE", false)
	var extra: PlayerIntent = report_intent(world)
	extra.payload.choice = "SALVAGE"
	rejected(world, extra, "closed report payload cannot choose a false outcome")
	var wrong: PlayerIntent = report_intent(world)
	wrong.player_id = &"npc:unknown"
	rejected(world, wrong, "report requires actual actor")
	var road: WorldState = disk_copy(world, "pre-report real road seed")
	return_act(road, null, PlayerIntent.create_travel(road.player.npc_id, &"settlement:dry_well"), "real out-of-town pending report fixture")
	rejected(road, report_intent(road), "real travel/pending encounter forbids report")
	finish_road(road)
	rejected(road, report_intent(road), "other town cannot report")
	check(engine.commit_player_intent(world, report_intent(world)).success and engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "actual report live/checked positive control")
	for key: String in ["dungeon_id", "room_id", "choice", "decision_index", "settlement_id", "faction_id", "standing_delta"]:
		for invalid: Variant in [null, false, {}, "forged", 9]:
			var data: Dictionary = world.to_dict().duplicate(true)
			last_fact(data, "DUNGEON_REPORTED").payload[key] = invalid
			reject_global_fixture(data, "typed exact report " + key)
	for mode: int in range(11):
		var data: Dictionary = world.to_dict().duplicate(true)
		var fact: Dictionary = last_fact(data, "DUNGEON_REPORTED")
		match mode:
			0: fact.actor_id = "npc:unknown"
			1: fact.target_id = "dungeon:other"
			2: fact.payload.standing_delta = -3
			3: fact.payload.decision_index -= 1
			4: fact.payload.choice = "SALVAGE"
			5: fact.payload.extra = true
			6: data.events.append(fact.duplicate(true))
			7: fact.day = world.current_day + 1
			8: fact.payload.settlement_id = "settlement:iron_pass"
			9: fact.payload.faction_id = "free"
			10:
				data.events.erase(fact)
				data.events.insert(int(fact.payload.decision_index) + 1, fact)
		data.event_count = data.events.size()
		reject_global_fixture(data, "report ownership/context/once proof%d" % mode)
	var forged_road: Dictionary = road.to_dict().duplicate(true)
	var report_fact: Dictionary = last_fact(world.to_dict(), "DUNGEON_REPORTED").duplicate(true)
	report_fact.day = road.current_day
	forged_road.events.append(report_fact)
	forged_road.event_count = forged_road.events.size()
	reject_global_fixture(forged_road, "plausible report after real travel cannot forge outside-home prefix")
	buy_rations(road, null, 4)
	return_act(road, null, PlayerIntent.create_travel(road.player.npc_id, Dungeon.HOME), "actual deferred report return from another town")
	finish_road(road)
	return_act(road, null, report_intent(road), "actual deferred report after home arrival")
	check(Trust.score(road, String(Dungeon.HOME)) == 3 and WorldState.from_json_checked(road.to_canonical_json()).success, "actual migration prefix permits deferred home report")
	var fatal: WorldState = returned_world("SALVAGE", false)
	return_act(fatal, null, dungeon_intent(fatal, "ENTER"), "actual report-refusal revisit")
	for target: String in ["foyer", "guard"]:
		return_act(fatal, null, dungeon_intent(fatal, "MOVE", Dungeon.state(fatal).room_id, target), "actual uncleared guard approach")
	fatal.player.field_kit.hp = 1 # Reviewed injury; death must come from actual guard counterattack.
	return_act(fatal, null, fight_intent(fatal, "guard"), "actual injured guard fight")
	rejected(fatal, report_intent(fatal), "pending battle cannot report")
	return_act(fatal, null, combat_intent(fatal, "ATTACK"), "actual fatal guard counterattack")
	check(fatal.player.field_kit.hp == 0, "actual death without changing lifecycle rules")
	rejected(fatal, report_intent(fatal), "unconfirmed fatal receipt cannot report")
	return_act(fatal, null, combat_intent(fatal, "CONFIRM"), "actual death confirmation")
	rejected(fatal, report_intent(fatal), "actual deceased returned actor cannot report")
	clear_slot()

func observe_return(label: String, main: Node) -> void:
	await observe_device(label, main)
	if is_instance_valid(main.shell.waterworks_return_dialog):
		var dialog: AcceptDialog = main.shell.waterworks_return_dialog
		check(dialog.size.x <= root.size.x and dialog.size.y <= root.size.y, "actual return dialog fits viewport")
		check(dialog.get_ok_button().size.y >= 40, "actual return defer40px")
		for button: Button in dialog.action_buttons.values():
			check(button.size.y >= 40 and Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()), "actual return action visible40px")

func return_ui() -> void:
	for choice: String in ["PRESERVE", "SALVAGE"]:
		clear_slot()
		check(store.save_game(returned_world(choice, false)).success, "actual returned UI save")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		check(main.shell.waterworks_return_button.visible and main.shell.waterworks_return_button.size.y >= 40, "actual town return record command40px")
		main.shell.waterworks_return_button.pressed.emit()
		await observe_return("before_report_" + choice, main)
		var before: String = main.world.to_canonical_json()
		main.shell.waterworks_return_dialog.get_ok_button().pressed.emit()
		await frames()
		check(main.world.to_canonical_json() == before, "actual optional defer is read-only")
		main.shell.waterworks_return_button.pressed.emit()
		await frames()
		main.shell.waterworks_return_dialog.action_buttons.REPORT.pressed.emit()
		await observe_return("reported_" + choice, main)
		check(Dungeon.state(main.world).reported and main.shell.waterworks_return_dialog.action_buttons.REPORT.disabled, "actual report and visible once-only refusal")
		main.shell.waterworks_return_dialog.action_buttons.MARKET.pressed.emit()
		await frames()
		var market: AcceptDialog = main.shell.market_window
		check(market != null and market.visible, "actual existing market opened")
		market.tab_buttons.OWNED.pressed.emit()
		await frames()
		market.row_buttons.fieldrepair_precision_kit.pressed.emit()
		await observe_return("owned_loot_market_" + choice, main)
		if choice == "SALVAGE":
			var cash: int = main.world.player.money
			market.sell_button.pressed.emit()
			await frames()
			check(not main.world.player.item_inventory.contains("fieldrepair_precision_kit") and main.world.player.money > cash and Dungeon.state(main.world).tools_recovered, "actual market button sells owned unique loot")
			await observe_return("actual_sale", main)
		market.get_ok_button().pressed.emit()
		await frames()
		main.shell.waterworks_return_button.pressed.emit()
		await frames()
		main.shell.waterworks_return_dialog.action_buttons.WELL.pressed.emit()
		await frames()
		check(Rumors.tracked(main.world) == "rumor:old_well" and main.shell.rumor_window.visible, "actual old-well pursuit button commits existing tracked rumor")
		await observe_return("old_well_pursuit_" + choice, main)
		main.shell.rumor_window.get_ok_button().pressed.emit()
		await frames()
		check(store.save_game(main.world).success, "actual return/report/trade/pursuit save")
		before = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		check(main.world.to_canonical_json() == before, "actual startup Continue persists optional report and sold/kept item")
		main.shell.waterworks_return_button.pressed.emit()
		await observe_return("continued_return_" + choice, main)
		main.shell.waterworks_return_dialog.action_buttons.REVISIT.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("DungeonScreen", false, false)
		check(screen != null and Dungeon.state(main.world).room_id == "entrance", "actual return revisit command enters existing dungeon")
		await guide_route(screen, "control")
		screen.interact_button.pressed.emit()
		await frames()
		await guide_deep_command(screen, "DEVICE")
		screen.interact_button.pressed.emit()
		await observe_return("revisited_once_only_" + choice, main)
		check(screen.device_dialog.choice_buttons.PRESERVE.disabled and screen.device_dialog.choice_buttons.SALVAGE.disabled, "actual revisit cannot repeat device")
		main.queue_free()
		await frames()
		clear_slot()
	var repaired: WorldState = returned_world("PRESERVE", false)
	return_act(repaired, null, report_intent(repaired), "actual receipt UI reported preparation")
	repair_visit(repaired)
	check(store.save_game(repaired).success, "actual existing repair receipt UI save")
	var receipt_main: Node = new_main()
	await frames()
	receipt_main.save_dialog.load_button.pressed.emit()
	await frames()
	await observe_return("actual_tool_discount_repair_receipt", receipt_main)
	check(String(receipt_main.shell.current_projection.encounter_result.place_note).contains("故障 → 運轉"), "actual Continue shows successful useful-loot repair")
	receipt_main.queue_free()
	await frames()
	clear_slot()

func run_return() -> void:
	root.size = Vector2i(1280, 720)
	return_replay()
	report_refusals_and_history()
	await return_ui()
	print("DUN-8: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
