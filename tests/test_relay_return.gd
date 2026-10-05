extends "res://tests/test_relay_hound.gd"

const ReturnRules = preload("res://simulation/relay_return.gd")
const ReturnWindow = preload("res://ui/components/relay_return_dialog.gd")

func _init() -> void:
	store = Store.new("user://tests/rly7/journey.json")
	call_deferred("run_return")

func return_prepared(with_abban: bool = true) -> WorldState:
	var world: WorldState = normal_relay_start()
	check(world.player.money == 50 and SimulationEngine.Party.hire_fee(world, ReturnRules.ABBAN) == 50, "ordinary initial budget and first Abban fee remain50")
	world.player.money = 500 # Explicit paid-device/companion boundary; RLY8 tests earning from ordinary50.
	var twin: WorldState = disk_copy(world, "explicit preparation budget")
	if with_abban:
		pair_intent(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, ReturnRules.ABBAN), "real first hire50")
		check(world.player.money == 450 and last_fact(world.to_dict(), "COMPANION_JOINED").payload.fee == 50, "first50 actually paid with no advance friendship")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "real shared-operation fuel")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 1), "real shared-operation scrap")
	panel(world, twin)
	relay_pair(world, twin, "POWER_LIFT")
	check(ReturnRules.state(world).operation_index == -1, "source operation alone is not a completed return")
	twin = disk_copy(world, "paid technical operation before return")
	for cycle: int in range(2):
		for destination: String in ["relay_entrance", "relay_corridor", "relay_entrance", "relay_tunnel"]: relay_pair(world, twin, "MOVE", destination)
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "EXIT")
	check(world.current_day == 2 and engine.validate_invariants(world) == "", "real two world days and living exit; no manual world news injection")
	check((ReturnRules.state(world).operation_index >= 0) == with_abban, "only continuous actual Abban sharing paid work gets candidate")
	return disk_copy(world, "actual source-backed return checkpoint")

func return_agreement(world: WorldState) -> void:
	var twin: WorldState = disk_copy(world, "agreement before actual commit")
	var money: int = world.player.money
	var inventory: String = JSON.stringify(world.player.inventory.to_dict())
	var day: int = world.current_day
	var identities: Array = world.npc_life_state_registry.life_states.keys()
	var sequence: int = world.next_npc_sequence
	pair_intent(world, twin, ReturnRules.intent(world), "explicit shared return agreement")
	check(ReturnRules.state(world).friend and SimulationEngine.Party.hire_fee(world, ReturnRules.ABBAN) == 25, "real future rehire50->25")
	check(world.player.money == money and JSON.stringify(world.player.inventory.to_dict()) == inventory and world.current_day == day and world.next_npc_sequence == sequence and world.npc_life_state_registry.life_states.keys() == identities, "agreement no refund, day, goods or human identity change")
	rejected(world, ReturnRules.intent(world), "agreement cannot stack")
	twin = disk_copy(world, "actual agreement Continue")
	pair_intent(world, twin, PlayerIntent.create_dismiss_companion(world.player.npc_id), "dismiss after agreement")
	pair_intent(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, ReturnRules.ABBAN), "actual future paid25 hire")
	check(world.player.money == money - 25 and last_fact(world.to_dict(), "COMPANION_JOINED").payload.fee == 25, "reduced fee actually charged and recorded")
	disk_copy(world, "actual paid rehire persisted")
	# A later solo trip must not invalidate a valid earlier historical agreement.
	pair_intent(world, twin, PlayerIntent.create_dismiss_companion(world.player.npc_id), "later solo journey")
	relay_pair(world, twin, "ENTER"); relay_pair(world, twin, "EXIT")
	check(ReturnRules.validate_world(world) == "" and SimulationEngine.Party.hire_fee(world, ReturnRules.ABBAN) == 25, "historical agreement remains valid after later trip")
	disk_copy(world, "later trip preserves historical friendship")

func return_projection(world: WorldState) -> void:
	var before: String = world.to_canonical_json()
	var p: Dictionary = ReturnRules.project(world)
	check(p.available and p.trip.contains("第0～2天") and not p.news.is_empty(), "real interval has readable sourced news")
	check(world.to_canonical_json() == before, "news, stock, jobs and companion projection read only")
	var delivery: bool = false
	for row: Dictionary in p.news:
		var source: EventRecord = world.event_log[row.source_index]
		check(row.source_index > ReturnRules.state(world).trip.enter_index and row.source_index < ReturnRules.state(world).trip.return_index, "news uses actual trip event interval")
		check(source.target_id == ReturnRules.HOME or source.payload.get("origin") == String(ReturnRules.HOME), "each visible event has real Gray receipt location")
		if source.type == "CARAVAN_ARRIVED" and source.payload.unloaded.get("scrap") == 20 and source.payload.unloaded.get("fuel") == 15:
			delivery = row.text.contains("廢料20") and row.text.contains("燃料15")
	check(delivery, "reviewed actual Iron->Gray arrival20scrap15fuel remains visible after caravan reverses route")
	check(p.stocks.size() == 4 and p.abban.contains("下一趟"), "current four real stocks and next companion plan")
	for job: Dictionary in p.jobs: check(not Board.find_posting(world, job.id).is_empty(), "every displayed job exists now")
	var town: SettlementState = world.get_settlement(ReturnRules.HOME)
	town.inventory.water = 0 # Explicit shortage boundary, not a claim that the caravan caused it.
	var dry: Dictionary = ReturnRules.project(world)
	check(dry.abban.contains("補給吃緊") and dry.stocks[0].contains("水0／"), "real current shortage changes Abban next plan and readable stock")
	var offered: Dictionary = dry.jobs[0]
	var twin: WorldState = disk_copy(world, "actual shortage posting acceptance boundary")
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, offered.id), "real board action from return opportunity")
	town.inventory.water = town.get_target("water") + 20
	world.get_settlement(ReturnRules.HOME).inventory.food = town.get_target("food") + 20
	var restored: Dictionary = ReturnRules.project(world)
	check(not restored.abban.contains("補給吃緊") and restored.news == dry.news, "resolved current needs change plan; historical news remains historical")
	check(engine.validate_invariants(world) == "", "explicit current-stock boundary still global invariant safe")
	var no_trip: WorldState = normal_relay_start()
	check(ReturnRules.project(no_trip).news.is_empty() and ReturnRules.project(no_trip).trip.contains("還沒有"), "no completed trip invents no news")
	var no_twin: WorldState = disk_copy(no_trip, "real same-day empty trip")
	relay_pair(no_trip, no_twin, "ENTER"); relay_pair(no_trip, no_twin, "EXIT")
	check(ReturnRules.project(no_trip).news.is_empty(), "actual same-day no-world-tick trip explicitly empty")

func return_wrench_journey(world: WorldState, twin: WorldState, destination: StringName) -> void:
	world.player.inventory.water = 8; world.player.inventory.food = 8
	twin.player.inventory.water = 8; twin.player.inventory.food = 8 # Explicit original-request travel ration boundary.
	pair_intent(world, twin, PlayerIntent.create_travel(world.player.npc_id, destination), "actual old request road travel")
	for step: int in range(24):
		if world.pending_encounter_result >= 0:
			pair_intent(world, twin, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result), "actual road receipt Continue")
		elif world.active_encounter != null:
			var option: StringName = &"LEAVE"
			match world.active_encounter.encounter_type:
				TravelEncounter.BANDIT_AMBUSH: option = &"FLEE_ROAD"
				TravelEncounter.ROCKSLIDE: option = &"DETOUR"
				TravelEncounter.ROADBLOCK: option = &"PAY"
				TravelEncounter.PLACE_VISIT:
					if world.active_encounter.context.get("companion_request", false): option = &"RECOVER_ABBAN_TOOL"
			pair_intent(world, twin, PlayerIntent.create_resolve_encounter(world.player.npc_id, option), "actual request detour/source")
		else: break
	check(world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id == destination and engine.validate_invariants(world) == "", "real road arrival/global conservation")

func return_nonstack() -> void:
	for relay_first: bool in [true, false]:
		var world: WorldState = return_prepared()
		var twin: WorldState = disk_copy(world, "two original relationship routes")
		if relay_first: pair_intent(world, twin, ReturnRules.intent(world), "shared-device friendship first")
		pair_intent(world, twin, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT"), "original wrench request still available")
		return_wrench_journey(world, twin, &"settlement:new_hope")
		check(world.player.item_inventory.quantity("wrench") == 1, "original real recovered tool exists")
		var money: int = world.player.money
		pair_intent(world, twin, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "actually hand original wrench over")
		var receipt: Dictionary = last_fact(world.to_dict(), "COMPANION_REQUEST_COMPLETED")
		check(receipt.payload.fee_before == (25 if relay_first else 50) and receipt.payload.fee_after == 25 and world.player.money == money and world.player.item_inventory.quantity("wrench") == 0, "independent before-fee accurate; no false second discount/refund")
		twin = disk_copy(world, "original wrench plus relay route checked history")
		return_wrench_journey(world, twin, ReturnRules.HOME)
		rejected(world, ReturnRules.intent(world), "wrench friendship refuses extra relay discount")
		pair_intent(world, twin, PlayerIntent.create_dismiss_companion(world.player.npc_id), "nonstack dismissal")
		money = world.player.money
		pair_intent(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, ReturnRules.ABBAN), "both routes actual25 rehire")
		check(world.player.money == money - 25, "both ordering variants charge exactly25")
		disk_copy(world, "both route orders persisted")

func return_negatives(world: WorldState) -> void:
	for variation: int in range(12):
		var data: Dictionary = world.to_dict().duplicate(true)
		var receipt: Dictionary = last_fact(data, ReturnRules.EVENT)
		match variation:
			0: receipt.actor_id = "npc:foreign"
			1: receipt.target_id = "companion:shahu"
			2: receipt.payload.site_id = Dungeon.SITE
			3: receipt.payload.operation_index = receipt.payload.return_index
			4: receipt.payload.return_index = -1
			5: receipt.payload.fee_before = 25
			6: receipt.payload.fee_after = 0
			7: receipt.payload.extra = true
			8: data.events.append(receipt.duplicate(true))
			9: data.events.erase(last_fact(data, "STATION_POWER_CONFIGURED"))
			10: receipt.payload.operation_index = "0"
			11: receipt.type = "ABBAN_RELAY_UNKNOWN"
		relay_reject_fixture(data, "return agreement malformed/false source " + str(variation))
	var candidate: WorldState = return_prepared()
	for p: Dictionary in [{"site_id": ReturnRules.SITE, "command": "ACK_ABBAN_RELAY", "operation_index": "0", "return_index": 0}, {"site_id": ReturnRules.SITE, "command": "ACK_ABBAN_RELAY", "operation_index": -1, "return_index": -1}, {"site_id": ReturnRules.SITE, "command": "ACK_ABBAN_RELAY", "operation_index": ReturnRules.state(candidate).operation_index, "return_index": ReturnRules.state(candidate).return_index, "extra": true}]:
		rejected(candidate, PlayerIntent.create_dungeon_action(candidate.player.npc_id, p), "typed exact-source live rejection")
	var twin: WorldState = disk_copy(candidate, "pending return acknowledgement")
	var stale: PlayerIntent = ReturnRules.intent(candidate)
	relay_pair(candidate, twin, "ENTER")
	rejected(candidate, stale, "active relay acknowledgement refuses atomically")
	relay_pair(candidate, twin, "EXIT")
	pair_intent(candidate, twin, PlayerIntent.create_dismiss_companion(candidate.player.npc_id), "actual absent companion")
	rejected(candidate, ReturnRules.intent(candidate), "absent companion refuses agreement")
	var solo: WorldState = return_prepared(false)
	twin = disk_copy(solo, "hiring after solo operation")
	pair_intent(solo, twin, PlayerIntent.create_hire_companion(solo.player.npc_id, ReturnRules.ABBAN), "late actual50 hire")
	rejected(solo, ReturnRules.intent(solo), "late hire invents no shared work")
	var away: WorldState = return_prepared()
	twin = disk_copy(away, "real remote-town lock")
	return_wrench_journey(away, twin, &"settlement:new_hope")
	rejected(away, ReturnRules.intent(away), "actual other town refuses agreement")
	check(not ReturnRules.project(away).available and ReturnRules.project(away).stocks.is_empty(), "remote visit does not reveal current Gray stocks")
	var fatal: WorldState = return_prepared()
	fatal.player.field_kit.hp = 1 # Explicit fatal-risk boundary, then actual mortality authority.
	twin = disk_copy(fatal, "actual fatal risk after source-backed return")
	pair_intent(fatal, twin, PlayerIntent.create_field_action(fatal.player.npc_id, {"command": "START"}), "real pending field battle")
	rejected(fatal, ReturnRules.intent(fatal), "pending battle cannot acknowledge")
	pair_intent(fatal, twin, combat_intent(fatal, "FLEE"), "actual fatal escape")
	pair_intent(fatal, twin, combat_intent(fatal, "CONFIRM"), "real fatal result confirmation")
	rejected(fatal, ReturnRules.intent(fatal), "death cannot acknowledge old shared memory")
	disk_copy(fatal, "death and unchanged agreement history")
	# Actual ration failure removes Abban between repair and exit; rehiring cannot recreate that operation.
	var hungry: WorldState = normal_relay_start(); hungry.player.money = 500; hungry.player.inventory.water = 1; hungry.player.inventory.food = 1
	twin = disk_copy(hungry, "reviewed hunger continuity boundary")
	pair_intent(hungry, twin, PlayerIntent.create_hire_companion(hungry.player.npc_id, ReturnRules.ABBAN), "actual before-work companion")
	pair_intent(hungry, twin, PlayerIntent.create_buy(hungry.player.npc_id, &"fuel", 1), "real hungry-trip fuel")
	pair_intent(hungry, twin, PlayerIntent.create_buy(hungry.player.npc_id, &"scrap", 1), "real hungry-trip scrap")
	panel(hungry, twin); relay_pair(hungry, twin, "POWER_LIFT")
	for destination: String in ["relay_entrance", "relay_corridor", "relay_entrance"]: relay_pair(hungry, twin, "MOVE", destination)
	relay_pair(hungry, twin, "EXIT")
	check(SimulationEngine.Party.current(hungry) == "" and ReturnRules.state(hungry).operation_index == -1, "real Abban hunger departure discards incomplete memory")
	pair_intent(hungry, twin, PlayerIntent.create_hire_companion(hungry.player.npc_id, ReturnRules.ABBAN), "actual rejoin after failed continuity")
	rejected(hungry, ReturnRules.intent(hungry), "leaving and rejoining does not recreate memory")
	disk_copy(hungry, "hunger discontinuity persists")
	var dog: WorldState = normal_relay_start(); dog.player.money = 500 # Explicit original repair plus first-hire cost boundary.
	twin = disk_copy(dog, "actual alternative shared machine repair")
	pair_intent(dog, twin, PlayerIntent.create_hire_companion(dog.player.npc_id, ReturnRules.ABBAN), "actual machine-repair companion50")
	pair_intent(dog, twin, PlayerIntent.create_buy(dog.player.npc_id, &"fuel", 1), "actual machine repair fuel")
	pair_intent(dog, twin, PlayerIntent.create_buy(dog.player.npc_id, &"scrap", 3), "actual machine repair scrap3")
	relay_pair(dog, twin, "ENTER"); hound_pair(dog, twin, "INSPECT_HOUND"); hound_pair(dog, twin, "REPAIR_HOUND"); relay_pair(dog, twin, "EXIT")
	pair_intent(dog, twin, ReturnRules.intent(dog), "actual shared machine repair also qualifies")
	check(ReturnRules.state(dog).friend and Hound.state(dog).energy == 4, "agreement never refunds or changes repaired machine energy")
	disk_copy(dog, "alternative shared source checked disk")

func return_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var world: WorldState = normal_relay_start()
		check(store.save_game(world).success, "native no-return save")
		var main: Node = new_main(); await frames(); main.save_dialog.load_button.pressed.emit(); await frames()
		find_command(main.shell, "回城見聞").pressed.emit(); await frames()
		var dialog: AcceptDialog
		for child: Node in main.shell.get_children():
			if child is ReturnWindow: dialog = child
		check(dialog != null and dialog.agreement_button.disabled and dialog.detail.text.contains("沒有記錄"), "native no-source and readable locked agreement")
		hound_geometry_return(dialog); await relay_observe("return_no_source")
		var before: String = main.world.to_canonical_json(); dialog.refresh(); dialog.confirmed.emit(); await frames()
		check(main.world.to_canonical_json() == before, "native open refresh close read only")
		main.queue_free(); await frames()
		world = return_prepared(); check(store.save_game(world).success, "native real shared trip Continue")
		main = new_main(); await frames(); main.save_dialog.load_button.pressed.emit(); await frames()
		find_command(main.shell, "回城見聞").pressed.emit(); await frames()
		for child: Node in main.shell.get_children():
			if child is ReturnWindow: dialog = child
		hound_geometry_return(dialog); check(not dialog.agreement_button.disabled and dialog.detail.text.contains("廢料20"), "native actual delivery and available agreement")
		await relay_observe("return_news_agreement")
		dialog.agreement_button.pressed.emit(); await frames()
		check(ReturnRules.state(main.world).friend and dialog.agreement_button.disabled and dialog.notice.text.contains("沒有扣款"), "native authoritative agreement then no-stack lock")
		await relay_observe("return_agreed")
		before = main.world.to_canonical_json(); dialog.board_button.pressed.emit(); await frames()
		check(main.world.to_canonical_json() == before and not is_instance_valid(dialog), "real board shortcut closes modal without accepting work")
		await relay_observe("return_existing_board")
		main.queue_free(); await frames()
	clear_slot()

func hound_geometry_return(dialog: AcceptDialog) -> void:
	check(dialog.position.x >= 0 and dialog.position.y >= 0 and dialog.position.x + dialog.size.x <= root.size.x and dialog.position.y + dialog.size.y <= root.size.y, "return panel fits actual viewport")
	for button: Button in [dialog.agreement_button, dialog.board_button, dialog.get_ok_button()]: check(button.size.y >= 40, "return commands visible40px")

func run_return() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	var world: WorldState = return_prepared()
	return_agreement(world)
	return_negatives(world)
	return_nonstack()
	return_projection(return_prepared())
	await return_ui()
	clear_slot()
	print("RLY-7: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
