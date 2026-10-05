extends "res://tests/test_relay_exploration.gd"

const TargetRules = preload("res://simulation/relay_target.gd")
const TargetWindow = preload("res://ui/components/relay_target_dialog.gd")

func _init() -> void:
	store = Store.new("user://tests/rly2/journey.json")
	call_deferred("run_target")

func target_pair(world: WorldState, twin: WorldState, command_id: String) -> void:
	relay_pair(world, twin, command_id)

func target_setup(world: WorldState, twin: WorldState) -> void:
	var population: int = world.get_settlement(TargetRules.HOME).population
	var sequence: int = world.next_npc_sequence
	var registered: int = world.npc_registry.npcs.size()
	target_pair(world, twin, "ACCEPT_TARGET")
	check(world.get_settlement(TargetRules.HOME).population == population and world.next_npc_sequence == sequence + 1 and world.npc_registry.npcs.size() == registered + 1, "one existing anonymous resident, one monotonic identity, no new population")
	check(TargetRules.state(world).npc_id == "npc:%08d" % sequence, "identity comes from prior sequence, not random/time")
	rejected(world, relay_intent(world, "ACCEPT_TARGET"), "cannot create second target")
	rejected(world, relay_intent(world, "WITNESS_TARGET"), "accepting in Gray cannot immediately earn fee")
	rejected(world, relay_intent(world, "REPORT_TARGET"), "no proof no fee")
	target_pair(world, twin, "ASK_TARGET")
	rejected(world, relay_intent(world, "ASK_TARGET"), "once-only town intelligence")

func target_enter(world: WorldState, twin: WorldState) -> void:
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "SEARCH")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	target_pair(world, twin, "INSPECT_EXIT")

func target_return(world: WorldState, twin: WorldState) -> void:
	for destination: String in ["relay_corridor", "relay_entrance"]: relay_pair(world, twin, "MOVE", destination)
	relay_pair(world, twin, "EXIT")

func target_blocked(report_fee: bool = true) -> WorldState:
	clear_slot()
	var world: WorldState = normal_relay_start()
	var twin: WorldState = disk_copy(world, "ordinary target start")
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "rope", 1), "normal50caps buys actual rope")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 1), "normal50caps buys actual exit scrap")
	check(world.player.money >= 0 and world.player.money < 50, "no preparation money/equipment gifted")
	target_setup(world, twin)
	target_enter(world, twin)
	var scrap: int = world.player.inventory.scrap
	target_pair(world, twin, "BLOCK_EXIT")
	check(not world.player.item_inventory.contains("rope") and world.player.inventory.scrap == scrap - 1 and not Relay.state(world).tunnel_open, "consume one real rope and scrap, do not open RLY1 passage")
	rejected(world, relay_intent(world, "BLOCK_EXIT"), "block cost cannot repeat")
	twin = disk_copy(world, "blocked exit and accepted identity")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	relay_pair(world, twin, "FIGHT")
	rejected(world, relay_intent(world, "CONFRONT_TARGET"), "battle locks pursuit")
	for turn_index: int in range(6):
		if world.field_state.battle.is_empty(): break
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "normal fighter real guard")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "confirm actual guard victory")
	relay_pair(world, twin, "MOVE", "relay_records")
	var population: int = world.get_settlement(TargetRules.HOME).population
	var caps: int = world.player.money
	target_pair(world, twin, "CONFRONT_TARGET")
	check(TargetRules.state(world).interviewed and not TargetRules.state(world).escaped and TargetRules.life(world).status == NpcLifeState.Status.SETTLED and world.get_settlement(TargetRules.HOME).population == population and world.player.money == caps, "blocked interview proves location without detention, migration or payment")
	rejected(world, relay_intent(world, "CONFRONT_TARGET"), "cannot repeat confrontation")
	twin = disk_copy(world, "actual interview checkpoint")
	target_return(world, twin)
	if not report_fee: return world
	target_pair(world, twin, "REPORT_TARGET")
	check(world.player.money == caps + 12 and TargetRules.state(world).reported, "reviewed scouting fee12 paid only back in Gray")
	rejected(world, relay_intent(world, "REPORT_TARGET"), "once-only fee even after continued play")
	twin = disk_copy(world, "paid report disk")
	parity(world, twin, "full ordinary blocked adventure SHA256")
	return world

func target_escape() -> WorldState:
	var world: WorldState = normal_relay_start()
	var twin: WorldState = disk_copy(world, "unblocked ordinary target")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 2), "normal side-route scrap")
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "wrench", 1), "normal side-route owned wrench")
	target_setup(world, twin)
	target_enter(world, twin)
	relay_pair(world, twin, "OPEN_TUNNEL")
	relay_pair(world, twin, "MOVE", "relay_records")
	var population: int = world.get_settlement(TargetRules.HOME).population
	var day: int = world.current_day
	target_pair(world, twin, "CONFRONT_TARGET")
	var npc_id: String = TargetRules.state(world).npc_id
	var party: RefugeePartyState = world.get_refugee_party(TargetRules.party_id(npc_id))
	check(world.get_settlement(TargetRules.HOME).population == population - 1 and party.headcount == 1 and party.origin_id == TargetRules.HOME and party.destination_id == TargetRules.DEST and party.route_days == 3 and party.departure_day == day + 1 and party.days_remaining == 3, "formal Gray-Hope road is three days; real human leaves population into one-person party, first full day next tick")
	check(TargetRules.life(world).status == NpcLifeState.Status.IN_TRANSIT and not TargetRules.present_at_relay(world), "no settled ghost or teleport")
	twin = disk_copy(world, "in-transit fugitive save")
	for destination: String in ["relay_tunnel", "relay_entrance"]: relay_pair(world, twin, "MOVE", destination)
	check(TargetRules.life(world).status == NpcLifeState.Status.IN_TRANSIT and world.get_refugee_party(party.id).days_remaining == 2 and world.current_day == day + 1, "first full world day advances one real day without early arrival")
	relay_pair(world, twin, "EXIT")
	rejected(world, relay_intent(world, "WITNESS_TARGET"), "in-transit target cannot be witnessed in Gray")
	pair_intent(world, twin, PlayerIntent.create_wait(world.player.npc_id), "second full road day")
	check(TargetRules.life(world).status == NpcLifeState.Status.IN_TRANSIT, "second of three days cannot arrive")
	pair_intent(world, twin, PlayerIntent.create_wait(world.player.npc_id), "third full road day")
	var arrival: EventRecord
	for event: EventRecord in world.event_log:
		if event.type == "NAMED_MIGRATION_COMPLETED" and String(event.actor_id) == npc_id: arrival = event
	check(arrival != null and arrival.day == day + 3 and arrival.day == party.departure_day + 3 - 1 and TargetRules.life(world).population_container_id == TargetRules.DEST, "arrival obeys reviewed departure + three days -1, real settled destination")
	twin = disk_copy(world, "arrived target save")
	walk_pair(world, twin, "settlement:new_hope", 3)
	target_pair(world, twin, "WITNESS_TARGET")
	check(TargetRules.state(world).evidence_index == world.event_log.size() - 1, "actual colocated target witnessed at destination")
	twin = disk_copy(world, "destination personal proof")
	walk_pair(world, twin, "settlement:gray_valley", 3)
	var caps: int = world.player.money
	target_pair(world, twin, "REPORT_TARGET")
	check(world.player.money == caps + 12, "followed target receives exact fee on return")
	rejected(world, relay_intent(world, "REPORT_TARGET"), "escaped target fee once")
	return world

func target_refusals() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	for command_id: String in ["ASK_TARGET", "INSPECT_EXIT", "BLOCK_EXIT", "CONFRONT_TARGET", "WITNESS_TARGET", "REPORT_TARGET"]: rejected(world, relay_intent(world, command_id), "no notice refuses " + command_id)
	for payload: Dictionary in [{"site_id": TargetRules.SITE, "command": "ACCEPT_TARGET", "reward": 12}, {"site_id": false, "command": "ACCEPT_TARGET"}, {"site_id": TargetRules.SITE, "command": 5}, {"site_id": TargetRules.SITE, "command": "KILL_TARGET"}]: rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload), "exact closed command space")
	rejected(world, PlayerIntent.create_dungeon_action(&"npc:unknown", {"site_id": TargetRules.SITE, "command": "ACCEPT_TARGET"}), "wrong target actor")
	var elsewhere: WorldState = fresh_towns("settlement:new_hope")
	rejected(elsewhere, relay_intent(elsewhere, "ACCEPT_TARGET"), "wrong city no target identity")
	var full: WorldState = fresh_towns("settlement:gray_valley")
	full.get_settlement(TargetRules.HOME).population = 1
	check(engine.validate_invariants(full) == "", "reviewed one-player population boundary")
	rejected(full, relay_intent(full, "ACCEPT_TARGET"), "no anonymous population remains no ID consumption")
	var twin: WorldState = disk_copy(world, "resource refusal start")
	target_setup(world, twin)
	target_enter(world, twin)
	rejected(world, relay_intent(world, "BLOCK_EXIT"), "missing real rope")
	check(world.player.pickup_item("rope").success, "explicit missing-scrap fixture actual rope")
	rejected(world, relay_intent(world, "BLOCK_EXIT"), "missing real scrap")
	check(TargetRules.state(world).blocked == false and world.player.item_inventory.contains("rope"), "refusal retains rope and identity")
	var water: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(water, dungeon_intent(water, "ENTER")).success, "legacy waterworks positive")
	rejected(water, relay_intent(water, "ACCEPT_TARGET"), "no target command during waterworks")
	check(WorldState.from_json_checked(water.to_canonical_json()).success, "old waterworks untouched checked loader")

func target_lifecycle_boundaries() -> void:
	# Existing lifecycle API, not an invented player kill command. Obtained
	# evidence survives a later death, but the identity cannot be rematerialized.
	var dead: WorldState = target_blocked(false)
	var npc_id: StringName = StringName(TargetRules.state(dead).npc_id)
	var population: int = dead.get_settlement(TargetRules.HOME).population
	check(dead.npc_life_state_registry.commit_named_death(dead, npc_id).success, "reviewed later-death fixture through actual atomic lifecycle")
	dead.record_event(EventRecord.new(dead.current_day, "NAMED_NPC_DIED", npc_id, TargetRules.HOME, {"npc_id": String(npc_id), "settlement_id": String(TargetRules.HOME)}))
	check(dead.get_settlement(TargetRules.HOME).population == population - 1 and not TargetRules.present_at_relay(dead) and TargetRules.describe(dead).contains("死亡"), "death removes actual population and ghost; sourced UI names death")
	var twin: WorldState = disk_copy(dead, "dead target identity and prior interview")
	var caps: int = dead.player.money
	target_pair(dead, twin, "REPORT_TARGET")
	check(dead.player.money == caps + 12 and not TargetRules.life(dead).is_alive(), "prior personal evidence paid without reviving dead target")
	rejected(dead, relay_intent(dead, "ACCEPT_TARGET"), "dead target cannot be recreated")
	rejected(dead, relay_intent(dead, "WITNESS_TARGET"), "dead target cannot be witnessed alive")
	# Ordinary named NPC decisions apply, even before the player reaches the ruin.
	var mobile: WorldState = fresh_towns("settlement:gray_valley")
	twin = disk_copy(mobile, "autonomy starting control")
	target_setup(mobile, twin)
	mobile.get_settlement(TargetRules.HOME).water_pressure = 80.0
	twin.get_settlement(TargetRules.HOME).water_pressure = 80.0
	engine.tick(mobile)
	engine.tick(twin)
	parity(mobile, twin, "real ordinary target migration SHA256")
	check(engine.validate_invariants(mobile) == "" and TargetRules.state(mobile).left_home and not TargetRules.present_at_relay(mobile) and TargetRules.life(mobile).status == NpcLifeState.Status.IN_TRANSIT, "target uses existing deprivation decision, not pinned to records room")
	twin = disk_copy(mobile, "autonomous migration checked disk")
	rejected(mobile, relay_intent(mobile, "WITNESS_TARGET"), "ordinary transit has no fake town witness")
	# Refuse an occupied party ID before unsafe join-capable lifecycle APIs.
	var occupied: WorldState = fresh_towns("settlement:gray_valley")
	check(occupied.player.pickup_item("wrench").success, "explicit collision fixture tool")
	occupied.player.inventory.scrap = 2
	twin = disk_copy(occupied, "collision fixture")
	target_setup(occupied, twin)
	target_enter(occupied, twin)
	relay_pair(occupied, twin, "OPEN_TUNNEL")
	relay_pair(occupied, twin, "MOVE", "relay_records")
	var pid: StringName = TargetRules.party_id(TargetRules.state(occupied).npc_id)
	var old: RefugeePartyState = RefugeePartyState.new(pid, TargetRules.HOME, TargetRules.DEST, 0, 3, 0, 0)
	old.is_active = false
	old.is_arrived = true
	occupied.refugees[pid] = old
	check(engine.validate_invariants(occupied) == "", "zero-person arrived party is existing valid lifecycle state")
	rejected(occupied, relay_intent(occupied, "CONFRONT_TARGET"), "identity-derived party collision refuses atomically")
	occupied.refugees.erase(pid)
	var remove_ids: Array[StringName] = []
	for route: CaravanState in occupied.caravans.values():
		if (route.origin_id == TargetRules.HOME and route.destination_id == TargetRules.DEST) or (route.origin_id == TargetRules.DEST and route.destination_id == TargetRules.HOME): remove_ids.append(route.id)
	for route_id: StringName in remove_ids: occupied.caravans.erase(route_id)
	var before: String = occupied.to_canonical_json()
	var result: Dictionary = engine.commit_player_intent(occupied, relay_intent(occupied, "CONFRONT_TARGET"))
	check(not result.success and result.error == "TARGET_ESCAPE_ROUTE_MISSING" and occupied.to_canonical_json() == before and TargetRules.life(occupied).status == NpcLifeState.Status.SETTLED, "missing actual road rejects detached staged migration, no default phantom road")

func target_negative_history(blocked: WorldState, escaped: WorldState) -> void:
	check(engine.validate_invariants(blocked) == "" and engine.validate_invariants(escaped) == "", "live validators accept both independent positive controls")
	for mode: int in range(23):
		var data: Dictionary = blocked.to_dict().duplicate(true)
		var acceptance: Dictionary = last_fact(data, "BOUNTY_TARGET_ACCEPTED")
		match mode:
			0: acceptance.actor_id = "npc:unknown"
			1: acceptance.payload.site_id = "dungeon:sealed_waterworks"
			2: acceptance.payload.age = 27
			3: acceptance.payload.name = "假名"
			4: acceptance.payload.background = NpcProfile.Background.MECHANIC
			5: acceptance.payload.reward = 12
			6: last_fact(data, "BOUNTY_TARGET_EXIT_BLOCKED").payload.rope_spent = 0
			7: last_fact(data, "BOUNTY_TARGET_EXIT_BLOCKED").payload.scrap_spent = 2
			8: last_fact(data, "BOUNTY_TARGET_EXIT_FOUND").payload.room_id = "relay_records"
			9: data.events.erase(last_fact(data, "BOUNTY_TARGET_EXIT_BLOCKED"))
			10: data.events.erase(last_fact(data, "BOUNTY_TARGET_EXIT_FOUND"))
			11: last_fact(data, "BOUNTY_TARGET_REPORTED").payload.caps_gained = 13
			12: last_fact(data, "BOUNTY_TARGET_REPORTED").payload.evidence_index = 0
			13: data.events.append(last_fact(data, "BOUNTY_TARGET_REPORTED").duplicate(true))
			14: acceptance.type = "BOUNTY_TARGET_UNKNOWN"
			15: last_fact(data, "BOUNTY_TARGET_INTERVIEW").target_id = data.player.npc_id
			16: last_fact(data, "BOUNTY_TARGET_INTERVIEW").day = -1
			17: data.events.insert(data.events.find(acceptance), acceptance.duplicate(true))
			18: data.npc_registry[acceptance.target_id].name = "偽裝的另一人"
			19: data.npc_registry[acceptance.target_id].age_at_materialization = 29
			20: data.npc_registry[acceptance.target_id].origin_settlement_id = "settlement:new_hope"
			21: data.npc_profile_registry[acceptance.target_id].background = NpcProfile.Background.MECHANIC
			22: data.npc_life_state_registry[acceptance.target_id].population_container_id = "settlement:new_hope"
		relay_reject_fixture(data, "target malformed acceptance/cost/order/proof/reward " + str(mode))
	for mode: int in range(6):
		var data: Dictionary = escaped.to_dict().duplicate(true)
		var departure: Dictionary = last_fact(data, "BOUNTY_TARGET_ESCAPED")
		match mode:
			0: departure.payload.route_days = 1
			1: departure.payload.party_id = "refugee:false"
			2: departure.payload.destination_id = "settlement:iron_pass"
			3: departure.payload.departure_day -= 1
			4:
				for event: Dictionary in data.events:
					if event.type == "NAMED_MIGRATION_COMPLETED" and event.actor_id == departure.target_id: event.day -= 1; break
			5: data.events.erase(departure)
		relay_reject_fixture(data, "target real migration history negative " + str(mode))
	var water: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(water, relay_intent(water, "ACCEPT_TARGET")).success and engine.commit_player_intent(water, dungeon_intent(water, "ENTER")).success, "accepted target with real legacy exploration positive control")
	check(engine.validate_invariants(water) == "" and WorldState.from_json_checked(water.to_canonical_json()).success, "unrelated waterworks and existing target coexist without target actions")
	var illicit: Dictionary = water.to_dict().duplicate(true)
	illicit.events.append({"day": water.current_day, "type": "BOUNTY_TARGET_INTEL", "actor_id": String(water.player.npc_id), "target_id": TargetRules.state(water).npc_id, "payload": {"site_id": TargetRules.SITE, "city_id": String(TargetRules.HOME)}})
	relay_reject_fixture(illicit, "valid-shaped target action inserted during waterworks fails activity authority")

func target_geometry(dialog: AcceptDialog) -> void:
	check(dialog.position.x >= 0 and dialog.position.y >= 0 and dialog.position.x + dialog.size.x <= root.size.x and dialog.position.y + dialog.size.y <= root.size.y, "actual target window fits native viewport")
	check(dialog.get_ok_button().size.y >= 40, "actual native target return40px")
	for command_id: String in dialog.action_buttons: check(dialog.action_buttons[command_id].size.y >= 40, "actual target action40px " + command_id)

func target_guide(screen: Control, command_id: String, destination: String = "") -> void:
	relay_guide(screen, command_id, destination)
	for step_index: int in range(260):
		screen.view._process(0.08)
		if screen.view.target_position.x < 0 and screen.view.guide_path.is_empty(): break
	screen.refresh_interaction()
	check(screen.view.nearest_door().get("command", "") == command_id, "completed real guide selects exact interaction " + command_id)

func target_notice(main: Node) -> AcceptDialog:
	find_command(main.shell, "追獵").pressed.emit()
	await frames()
	for child: Node in main.shell.get_children():
		if child is TargetWindow: return child
	check(false, "native target notice exists")
	return null

func target_absence_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var world: WorldState = fresh_towns("settlement:gray_valley")
		check(world.player.pickup_item("wrench").success, "explicit native escape tool")
		world.player.inventory.scrap = 2
		check(engine.commit_player_intent(world, relay_intent(world, "ACCEPT_TARGET")).success, "native target escape accepted")
		check(store.save_game(world).success, "native escape starting disk")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		find_command(main.shell, "中繼站").pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("RelayScreen", false, false)
		for entry: Dictionary in [{"command": "SEARCH"}, {"command": "MOVE", "to": "relay_tunnel"}, {"command": "OPEN_TUNNEL"}, {"command": "MOVE", "to": "relay_records"}]:
			target_guide(screen, entry.command, entry.get("to", ""))
			screen.interact_button.pressed.emit()
			await frames()
		var before: String = main.world.to_canonical_json()
		var idle: float = screen.view.target_animation_time
		await create_timer(0.17).timeout
		check(screen.view.target_animation_time > idle and main.world.to_canonical_json() == before, "target idle breathing advances without world mutation")
		await relay_observe("target_idle_motion")
		screen.view.reduced_motion = true
		idle = screen.view.target_animation_time
		await create_timer(0.12).timeout
		check(screen.view.target_animation_time == idle and main.world.to_canonical_json() == before, "reduced target motion freezes cosmetic clock, authority unchanged")
		await relay_observe("target_reduced_motion")
		target_guide(screen, "CONFRONT_TARGET")
		screen.interact_button.pressed.emit()
		await frames()
		check(TargetRules.state(main.world).escaped and not screen.view.checkpoint.target_present, "real UI confront triggers real flight and removes visible target")
		await relay_observe("target_escaped_room")
		check(store.save_game(main.world).success, "native fleeing target saved before road progress")
		before = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		check(main.world.to_canonical_json() == before and not screen.view.checkpoint.target_present, "actual Continue keeps target in transit and room empty")
		await relay_observe("target_escape_continue")
		for destination: String in ["relay_tunnel", "relay_entrance"]:
			target_guide(screen, "MOVE", destination)
			screen.interact_button.pressed.emit()
			await frames()
		target_guide(screen, "EXIT")
		screen.interact_button.pressed.emit()
		await frames()
		var dialog: AcceptDialog = await target_notice(main)
		check(dialog.detail.text.contains("在途") and dialog.detail.text.contains("2天") and dialog.action_buttons.WITNESS_TARGET.disabled, "native source-correct in-transit location and no witness")
		target_geometry(dialog)
		await relay_observe("target_in_transit")
		dialog.get_ok_button().pressed.emit()
		await frames()
		for day_index: int in range(2): check(engine.commit_player_intent(main.world, PlayerIntent.create_wait(main.world.player.npc_id)).success, "native world actual arrival days")
		main.shell.refresh_ui()
		dialog = await target_notice(main)
		check(dialog.detail.text.contains("新希望") and not dialog.detail.text.contains("在途") and dialog.action_buttons.WITNESS_TARGET.disabled, "native elsewhere actual settlement requires physical travel")
		await relay_observe("target_elsewhere")
		dialog.get_ok_button().pressed.emit()
		await frames()
		var npc_id: StringName = StringName(TargetRules.state(main.world).npc_id)
		check(main.world.npc_life_state_registry.commit_named_death(main.world, npc_id).success, "native actual later-death boundary")
		main.world.record_event(EventRecord.new(main.world.current_day, "NAMED_NPC_DIED", npc_id, TargetRules.DEST, {"npc_id": String(npc_id), "settlement_id": String(TargetRules.DEST)}))
		check(engine.validate_invariants(main.world) == "", "native mortality boundary retains actual invariants")
		main.shell.refresh_ui()
		dialog = await target_notice(main)
		check(dialog.detail.text.contains("死亡") and not dialog.action_buttons.REPORT_TARGET.disabled and dialog.action_buttons.WITNESS_TARGET.disabled, "native dead target distinct, historical escape proof remains reportable")
		target_geometry(dialog)
		await relay_observe("target_dead_with_proof")
		main.queue_free()
		await frames()
	clear_slot()

func target_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var world: WorldState = fresh_towns("settlement:gray_valley")
		check(world.player.pickup_item("wrench").success and world.player.pickup_item("rope").success, "explicit native owned-tools fixture")
		world.player.inventory.scrap = 3
		check(store.save_game(world).success, "native initial target save")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		find_command(main.shell, "追獵").pressed.emit()
		await frames()
		var dialog: AcceptDialog
		for child: Node in main.shell.get_children():
			if child is TargetWindow: dialog = child
		check(dialog != null, "real toolbar opens target notice")
		if dialog == null: return
		target_geometry(dialog)
		await relay_observe("target_notice")
		dialog.action_buttons.ACCEPT_TARGET.pressed.emit()
		dialog.action_buttons.ASK_TARGET.pressed.emit()
		await frames()
		check(dialog.action_buttons.WITNESS_TARGET.disabled and dialog.action_buttons.REPORT_TARGET.disabled and dialog.detail.text.contains("左靴"), "real notice has clue and disallows immediate fee")
		await relay_observe("target_intel")
		dialog.get_ok_button().pressed.emit()
		await frames()
		find_command(main.shell, "中繼站").pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("RelayScreen", false, false)
		for entry: Dictionary in [{"command": "SEARCH"}, {"command": "MOVE", "to": "relay_tunnel"}, {"command": "INSPECT_EXIT"}, {"command": "BLOCK_EXIT"}, {"command": "OPEN_TUNNEL"}, {"command": "MOVE", "to": "relay_records"}]:
			target_guide(screen, entry.command, entry.get("to", ""))
			screen.interact_button.pressed.emit()
			await frames()
		relay_geometry(screen)
		await relay_observe("target_in_records")
		check(TargetRules.present_at_relay(main.world) and screen.view.target_texture != null, "real settled target drawn from original cutout")
		target_guide(screen, "CONFRONT_TARGET")
		screen.interact_button.pressed.emit()
		await frames()
		check(TargetRules.state(main.world).interviewed and screen.message.text.contains("拘捕"), "actual walk and button produce interview not custody")
		await relay_observe("target_interview")
		check(store.save_game(main.world).success, "real local pursuit checkpoint save")
		var before: String = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		check(screen != null and main.world.to_canonical_json() == before and TargetRules.state(main.world).blocked, "real Continue restores target and sealed exit")
		await relay_observe("target_continue")
		for destination: String in ["relay_tunnel", "relay_entrance"]:
			target_guide(screen, "MOVE", destination)
			screen.interact_button.pressed.emit()
			await frames()
		target_guide(screen, "EXIT")
		screen.interact_button.pressed.emit()
		await frames()
		find_command(main.shell, "追獵").pressed.emit()
		await frames()
		for child: Node in main.shell.get_children():
			if child is TargetWindow: dialog = child
		var caps: int = main.world.player.money
		dialog.action_buttons.REPORT_TARGET.pressed.emit()
		await frames()
		check(main.world.player.money == caps + 12 and dialog.action_buttons.REPORT_TARGET.disabled and dialog.detail.text.contains("不能重領"), "real UI pays12 and disables repeat")
		target_geometry(dialog)
		await relay_observe("target_report_paid")
		main.queue_free()
		await frames()
	clear_slot()

func run_target() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	root.size = Vector2i(1280, 720)
	var blocked: WorldState = target_blocked()
	var escaped: WorldState = target_escape()
	target_refusals()
	target_lifecycle_boundaries()
	target_negative_history(blocked, escaped)
	await target_ui()
	await target_absence_ui()
	print("RLY-2: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
