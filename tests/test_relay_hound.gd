extends "res://tests/test_relay_power.gd"

const Hound = preload("res://simulation/relay_hound.gd")
const HoundWindow = preload("res://ui/components/relay_hound_dialog.gd")
const Custody = preload("res://simulation/relay_custody.gd")

func _init() -> void:
	store = Store.new("user://tests/rly6/journey.json")
	call_deferred("run_hound")

func hound_pair(world: WorldState, twin: WorldState, command_id: String) -> void:
	pair_intent(world, twin, Hound.intent(world, command_id), "actual hound " + command_id)
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "hound actual global invariants")

func hound_prepared() -> WorldState:
	var world: WorldState = normal_relay_start()
	check(world.player.money == 50, "ordinary new mechanic actual50 budget")
	var twin: WorldState = disk_copy(world, "ordinary hound no gifts")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "actual affordable repair fuel")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 3), "actual affordable repair scrap3")
	var ids: Array = world.npc_life_state_registry.life_states.keys()
	var sequence: int = world.next_npc_sequence
	relay_pair(world, twin, "ENTER")
	rejected(world, Hound.intent(world, "REPAIR_HOUND"), "must discover actual broken machine")
	hound_pair(world, twin, "INSPECT_HOUND")
	var before: String = world.to_canonical_json()
	hound_pair(world, twin, "INSPECT_HOUND")
	check(world.to_canonical_json() == before, "repeat physical inspection is read only")
	var stale: PlayerIntent = Hound.intent(world, "REPAIR_HOUND")
	hound_pair(world, twin, "REPAIR_HOUND")
	check(Hound.state(world).energy == 4 and not Hound.state(world).support and world.player.inventory.fuel == 0 and world.player.inventory.scrap == 0, "reviewed actual repair1fuel3scrap gives4energy and modeOFF")
	check(world.npc_life_state_registry.life_states.keys() == ids and world.next_npc_sequence == sequence and world.current_day == 0 and world.total_initial_population == -1, "equipment introduces no human lifecycle or day/baseline")
	rejected(world, stale, "stale repair revision atomic refusal")
	rejected(world, Hound.intent(world, "REPAIR_HOUND"), "once-only repair")
	rejected(world, Hound.intent(world, "CHARGE_HOUND"), "full charge cannot consume fuel")
	disk_copy(world, "actual repaired machine checked persistence")
	return world

func hound_door() -> WorldState:
	var world: WorldState = hound_prepared()
	var twin: WorldState = disk_copy(world, "door energy choice")
	relay_pair(world, twin, "SEARCH")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	rejected(world, relay_intent(world, "OPEN_TUNNEL"), "manual still requires actual tool")
	hound_pair(world, twin, "HOUND_OPEN_TUNNEL")
	check(Relay.state(world).tunnel_open and Hound.state(world).energy == 2 and world.player.inventory.scrap == 0 and not world.player.field_kit.crowbar, "dog opens real inner gate for2energy without virtual tool/scrap")
	rejected(world, Hound.intent(world, "HOUND_OPEN_TUNNEL"), "machine cannot open twice")
	rejected(world, relay_intent(world, "OPEN_TUNNEL"), "manual cannot pay after dog opening")
	twin = disk_copy(world, "source door Continue")
	relay_pair(world, twin, "MOVE", "relay_records")
	rejected(world, relay_intent(world, "MOVE", "relay_vault"), "dog opening never gifts card")
	relay_pair(world, twin, "FIND_CARD")
	relay_pair(world, twin, "MOVE", "relay_vault")
	relay_pair(world, twin, "TAKE_PRIZE")
	check(world.player.item_inventory.quantity("military_backpack") == 1 and Hound.state(world).energy == 2 and Relay.state(world).cleared.is_empty(), "real exploration reward without free combat clear")
	return world

func hound_field() -> WorldState:
	var world: WorldState = hound_prepared()
	var twin: WorldState = disk_copy(world, "portable hound field source")
	hound_pair(world, twin, "HOUND_SUPPORT_ON")
	relay_pair(world, twin, "EXIT")
	pair_intent(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}), "ordinary shed battle")
	check(Field.intent_preview(world).attack_damage == 4 and Field.intent_preview(world).dog_support == 2, "actual ordinary2 plus mechanical2 preview")
	check(Field.forecast_for_enemy(world, "feral_dog", false).turns == 2 and Field.forecast_for_enemy(world, "feral_dog", false).incoming == 3, "independent6HP with two4damage attacks and one counter")
	rejected(world, Hound.intent(world, "HOUND_SUPPORT_OFF"), "cannot retoggle during battle")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "real paid portable assist")
	check(world.field_state.enemy_hp == 2 and world.player.field_kit.hp == 9 and Hound.state(world).energy == 3 and last_fact(world.to_dict(), "FIELD_TURN").payload.dog_dealt == 2, "independent6->2,12->9,4->3 paid mechanical strike")
	twin = disk_copy(world, "active field support checked disk")
	check(Field.intent_preview(world).dog_support == 0 and Field.intent_preview(world).attack_kills, "ordinary final blow preview consumes no energy")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "ordinary killing blow")
	check(Hound.state(world).energy == 3 and not last_fact(world.to_dict(), "FIELD_TURN").payload.has("dog_dealt") and world.player.field_kit.hp == 9, "ordinary kill no dog cost or terminal counter")
	rejected(world, Hound.intent(world, "CHARGE_HOUND"), "pending result cannot recharge")
	twin = disk_copy(world, "portable actual result checked disk")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "ordinary result confirmed")
	world.player.inventory.fuel = 1; twin.player.inventory.fuel = 1 # Explicit owned-fuel recharge boundary; ordinary50 repair uses its whole budget.
	hound_pair(world, twin, "CHARGE_HOUND")
	check(Hound.state(world).energy == 4 and world.player.inventory.fuel == 0, "partial3->4 pays one actual fuel; no refund")
	hound_pair(world, twin, "HOUND_SUPPORT_OFF")
	return world

func hound_turret() -> WorldState:
	var world: WorldState = hound_prepared()
	world.player.inventory.fuel = 1; world.player.inventory.scrap = 1 # Explicit additional-device boundary, not ordinary50 preparation.
	var twin: WorldState = disk_copy(world, "explicit extra power bundle")
	hound_pair(world, twin, "HOUND_SUPPORT_ON")
	relay_pair(world, twin, "SEARCH")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	relay_pair(world, twin, "INSPECT_POWER")
	relay_pair(world, twin, "POWER_TURRET")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	relay_pair(world, twin, "FIGHT")
	check(Field.intent_preview(world).attack_damage == 6 and Field.intent_preview(world).dog_support == 2 and Field.intent_preview(world).turret_support == 2 and Field.intent_preview(world).attack_kills, "ordinary2 dog2 turret2 kills actual six HP guard")
	check(Field.forecast_for_enemy(world, "feral_dog", false).turns == 1 and Field.forecast_for_enemy(world, "feral_dog", false).incoming == 0, "combined support forecast one turn no counter")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "atomic dog then turret then ordinary result")
	check(world.player.field_kit.hp == 12 and Hound.state(world).energy == 3 and PowerRules.state(world).charges == 1 and Relay.state(world).cleared == ["relay_corridor"], "independent6->0 no counter dog4->3 turret2->1")
	var events: Array = world.to_dict().events
	var turn_index: int = -1
	for index: int in range(events.size()):
		if events[index].type == "FIELD_TURN": turn_index = index
	check(events[turn_index - 1].type == "STATION_POWER_SHOT" and events[turn_index - 2].type == "DOG_ASSISTED", "existing turret immediately adjacent; own dog before turret")
	disk_copy(world, "actual combined supported victory checked disk")
	return world

func hound_other_contexts() -> WorldState:
	var water: WorldState = hound_prepared()
	var twin: WorldState = disk_copy(water, "waterworks portable equipment")
	hound_pair(water, twin, "HOUND_SUPPORT_ON")
	relay_pair(water, twin, "EXIT")
	pair_intent(water, twin, dungeon_intent(water, "ENTER"), "real legacy waterworks new entry")
	pair_intent(water, twin, dungeon_intent(water, "MOVE", "entrance", "foyer"), "waterworks foyer")
	pair_intent(water, twin, dungeon_intent(water, "MOVE", "foyer", "guard"), "waterworks actual guard route")
	pair_intent(water, twin, fight_intent(water, "guard"), "actual waterworks guard")
	pair_intent(water, twin, combat_intent(water, "ATTACK"), "actual portable dog waterworks support")
	check(water.field_state.enemy_hp == 4 and Hound.state(water).energy == 3 and last_fact(water.to_dict(), "DOG_ASSISTED").payload.dungeon_id == Dungeon.SITE, "actual8->4 guard and distinct waterworks source")
	twin = disk_copy(water, "actual waterworks midcombat support")
	pair_intent(water, twin, combat_intent(water, "ATTACK"), "actual waterworks dog kill")
	check(water.field_state.enemy_hp == 0 and Hound.state(water).energy == 2 and Dungeon.state(water).cleared == ["guard"] and Relay.state(water).cleared.is_empty(), "own waterworks result authority, no relay clear")
	disk_copy(water, "actual waterworks result checked disk")
	var road: WorldState = hound_prepared()
	twin = disk_copy(road, "road portable equipment")
	hound_pair(road, twin, "HOUND_SUPPORT_ON")
	relay_pair(road, twin, "EXIT")
	var travel: PlayerIntent = PlayerIntent.create_travel(road.player.npc_id, &"settlement:new_hope")
	check(engine.begin_player_travel(road, travel).success and engine.begin_player_travel(twin, travel).success, "real typed transit/lifecycle entry for explicit ambush boundary")
	road.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, road.current_day, &"settlement:gray_valley", &"settlement:new_hope", 1, {"target_enemy": "bandit"})
	twin.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, twin.current_day, &"settlement:gray_valley", &"settlement:new_hope", 1, {"target_enemy": "bandit"})
	parity(road, twin, "explicit ambush fixture, actual transit state")
	pair_intent(road, twin, PlayerIntent.create_resolve_encounter(road.player.npc_id, &"FIGHT"), "actual road ownership handoff")
	pair_intent(road, twin, combat_intent(road, "ATTACK"), "road dog assist with legacy source-less FIELD_TURN")
	var fact: Dictionary = last_fact(road.to_dict(), "FIELD_TURN")
	check(road.field_state.enemy_hp == 4 and Hound.state(road).energy == 3 and not fact.payload.has("source") and last_fact(road.to_dict(), "DOG_ASSISTED").payload.source == "road", "actual8->4 road proof resolves source from actual road battle begin")
	disk_copy(road, "actual source-less road turn checked disk")
	return road

func hound_boundaries() -> void:
	var world: WorldState = hound_prepared()
	var twin: WorldState = disk_copy(world, "energy retention boundary")
	hound_pair(world, twin, "HOUND_SUPPORT_ON")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	relay_pair(world, twin, "FIGHT")
	pair_intent(world, twin, combat_intent(world, "DEFEND"), "dog does not attack on brace")
	pair_intent(world, twin, combat_intent(world, "FLEE"), "dog does not attack on flee")
	check(Hound.state(world).energy == 4, "brace/flee retain all four charge")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "actual escaped guard result")
	pair_intent(world, twin, relay_intent(world, "FIGHT"), "real un-cleared guard fight")
	pair_intent(world, twin, combat_intent(world, "DEFEND"), "prepare makes attack4")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "ordinary4 plus dog2 kills guard")
	check(Hound.state(world).energy == 3, "one dog terminal hit spends exactly one")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "actual dog terminal confirm")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "EXIT")
	check(world.player.pickup_item("old_revolver").success and twin.player.pickup_item("old_revolver").success, "explicit actual firearm ownership, no bullets")
	pair_intent(world, twin, PlayerIntent.create_equip_item(world.player.npc_id, "old_revolver", "main_hand"), "actual equipped firearm")
	pair_intent(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}), "actual six HP shed gun boundary")
	rejected(world, combat_intent(world, "SHOOT"), "empty gun spends no dog charge")
	check(Hound.state(world).energy == 3, "empty ammunition retains charge")
	check(world.player.pickup_item("revolver_round").success and twin.player.pickup_item("revolver_round").success, "explicit one actual owned round")
	pair_intent(world, twin, combat_intent(world, "SHOOT"), "ordinary gun kills before dog")
	check(Hound.state(world).energy == 3 and world.player.item_inventory.quantity("revolver_round") == 0 and not last_fact(world.to_dict(), "FIELD_TURN").payload.has("dog_dealt"), "gun killing shot uses bullet but no energy")
	disk_copy(world, "actual gun result persistence")
	var manual: WorldState = side_replay()
	rejected(manual, Hound.intent(manual, "HOUND_OPEN_TUNNEL"), "unrepaired dog cannot bypass paid manual route")
	check(not Hound.state(manual).found and WorldState.from_json_checked(manual.to_canonical_json()).success, "legacy relay has no invented machine ownership")
	clear_slot()

func hound_limits() -> void:
	var world: WorldState = hound_prepared()
	check(engine.commit_player_intent(world, relay_intent(world, "EXIT")).success, "actual return before equipping depletion protection")
	check(world.player.pickup_item("ballistic_vest").success, "explicit protective equipment depletion boundary")
	check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, "ballistic_vest", "body")).success, "actual vest protects repeated counterattacks")
	var twin: WorldState = disk_copy(world, "real repeated encounters drain finite energy")
	hound_pair(world, twin, "HOUND_SUPPORT_ON")
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	for attempt: int in range(4):
		relay_pair(world, twin, "FIGHT")
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "actual energy depletion strike")
		pair_intent(world, twin, combat_intent(world, "FLEE"), "real retreat avoids clearing fixed guard")
		pair_intent(world, twin, combat_intent(world, "CONFIRM"), "actual escape confirmed")
	check(Hound.state(world).energy == 0 and world.player.field_kit.hp == 8, "four actual support strikes drain4; vest blocks counters but four retreats cost4HP")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "SEARCH")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	rejected(world, Hound.intent(world, "HOUND_OPEN_TUNNEL"), "empty machine cannot open real sealed door")
	rejected(world, Hound.intent(world, "CHARGE_HOUND"), "zero charge never manufactures fuel")
	world.player.inventory.fuel = 1; twin.player.inventory.fuel = 1 # Explicit owned-refill boundary after real depletion.
	hound_pair(world, twin, "CHARGE_HOUND")
	check(Hound.state(world).energy == 4 and world.player.inventory.fuel == 0, "safe exploration zero->4 paid fuel1")
	disk_copy(world, "empty-energy paid refill checked persistence")
	var dead: WorldState = hound_prepared()
	dead.player.field_kit.hp = 1 # Explicit fatal damage boundary, no claimed ordinary journey.
	twin = disk_copy(dead, "actual mechanical owner death boundary")
	relay_pair(dead, twin, "MOVE", "relay_corridor")
	relay_pair(dead, twin, "FIGHT")
	pair_intent(dead, twin, combat_intent(dead, "FLEE"), "actual fatal retreat")
	pair_intent(dead, twin, combat_intent(dead, "CONFIRM"), "actual dead owner confirm")
	rejected(dead, Hound.intent(dead, "HOUND_SUPPORT_ON"), "dead owner no machine operations")
	check(Hound.state(dead).repaired and Hound.state(dead).energy == 4, "equipment history survives actual owner death unchanged")
	clear_slot()

func hound_qualifications() -> void:
	for help: String in ["TOOL", "ABBAN"]:
		var world: WorldState = PlayableWorld.create_world()
		check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "電子學徒", "age": 28, "background_id": "SCAVENGER", "trait_ids": []})).success, "real untrained scavenger")
		world.player.money = 250 # Explicit teacher/help budget; ranks only acquired from actual teacher.
		var twin: WorldState = disk_copy(world, "qualification budget boundary")
		if help == "TOOL": pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "wrench", 1), "actual owned wrench")
		else: pair_intent(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, "companion:abban"), "actual current Abban")
		pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "qualification owned fuel")
		pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 3), "qualification owned scrap")
		relay_pair(world, twin, "ENTER"); hound_pair(world, twin, "INSPECT_HOUND")
		rejected(world, Hound.intent(world, "REPAIR_HOUND"), "tool or Abban never lends personal electronics")
		relay_pair(world, twin, "EXIT")
		pair_intent(world, twin, PlayerIntent.create_train_skill(world.player.npc_id, "ELECTRONICS"), "real teacher qualification")
		check(world.player.capability.get_rank("ELECTRONICS") == 1 and world.player.capability.get_rank("MECHANICS") == 0, "personal electronics learned; no personal mechanical rank invented")
		relay_pair(world, twin, "ENTER"); hound_pair(world, twin, "REPAIR_HOUND")
		check(last_fact(world.to_dict(), "DOG_REPAIRED").payload.method == help and Hound.state(world).energy == 4, "actual " + help + " mechanical alternative")
		disk_copy(world, "actual qualified " + help + " source persistence")
	var manual: WorldState = hound_prepared()
	check(manual.player.pickup_item("wrench").success, "explicit owned tool manual crossed route")
	manual.player.inventory.scrap = 2
	var manual_twin: WorldState = disk_copy(manual, "explicit manual materials boundary")
	relay_pair(manual, manual_twin, "SEARCH"); relay_pair(manual, manual_twin, "MOVE", "relay_tunnel"); relay_pair(manual, manual_twin, "OPEN_TUNNEL")
	rejected(manual, Hound.intent(manual, "HOUND_OPEN_TUNNEL"), "repaired dog never repays manual-opened door")
	check(Hound.state(manual).energy == 4, "manual route leaves actual machine energy4")
	clear_slot()

func hound_human_separation() -> void:
	var world: WorldState = hound_prepared()
	var twin: WorldState = disk_copy(world, "actual repaired machine before named pursuit")
	hound_pair(world, twin, "HOUND_SUPPORT_ON"); relay_pair(world, twin, "EXIT")
	world.player.money += 120; twin.player.money += 120 # Explicit named pursuit equipment boundary.
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "rope", 1), "real exit rope")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 1), "real exit scrap")
	target_setup(world, twin); target_enter(world, twin); target_pair(world, twin, "BLOCK_EXIT")
	hound_pair(world, twin, "HOUND_OPEN_TUNNEL"); relay_pair(world, twin, "MOVE", "relay_records")
	pair_intent(world, twin, Custody.intent(world, "CHALLENGE_TARGET"), "actual same-resident human duel")
	rejected(world, Hound.intent(world, "CHARGE_HOUND"), "pursuit locks machine work")
	pair_intent(world, twin, Custody.intent(world, "SUBDUE_TARGET"), "actual nonlethal human strike")
	check(Hound.state(world).energy == 2 and Custody.state(world).target_hp == 6 and not world.event_log.any(func(e: EventRecord) -> bool: return e.type == "DOG_ASSISTED"), "mechanical2 support never injures named human or consumes energy")
	pair_intent(world, twin, Custody.intent(world, "RETREAT_TARGET"), "actual human retreat")
	pair_intent(world, twin, Custody.intent(world, "CONFIRM_CAPTURE"), "actual human result confirmed")
	disk_copy(world, "actual named pursuit machine separation persisted")
	clear_slot()

func hound_wounded_restart() -> void:
	for acquire_first: bool in [true, false]:
		var world: WorldState = hound_prepared() if acquire_first else normal_relay_start()
		var twin: WorldState = disk_copy(world, "partial shed enemy before acquisition " + str(acquire_first))
		if acquire_first: relay_pair(world, twin, "EXIT")
		pair_intent(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}), "real initial ordinary shed fight")
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "real legacy ordinary2 wound")
		pair_intent(world, twin, combat_intent(world, "FLEE"), "actual wounded shed retreat")
		pair_intent(world, twin, combat_intent(world, "CONFIRM"), "actual wounded shed confirmation")
		check(world.field_state.enemy_hp == 4, "retreat preserves actual6->4 foe HP")
		twin = disk_copy(world, "actual wounded foe survives checked reload")
		if not acquire_first:
			pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "actual later repair fuel")
			pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 3), "actual later repair scrap3")
			relay_pair(world, twin, "ENTER"); hound_pair(world, twin, "INSPECT_HOUND"); hound_pair(world, twin, "REPAIR_HOUND"); relay_pair(world, twin, "EXIT")
		hound_pair(world, twin, "HOUND_SUPPORT_ON")
		pair_intent(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}), "actual wounded foe restart with machine")
		check(Field.intent_preview(world).attack_damage == 4 and Field.intent_preview(world).attack_kills, "real wounded4 ordinary2 plus dog2 terminal preview")
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "actual supported wounded foe kill")
		check(world.field_state.enemy_hp == 0 and world.player.field_kit.hp == 8 and Hound.state(world).energy == 3, "source HP4 accepted; dog costs1, no terminal counter")
		disk_copy(world, "wounded restart result with acquisition order " + str(acquire_first))
	clear_slot()

func hound_negatives(door: WorldState, combined: WorldState, field: WorldState, road: WorldState) -> void:
	for source: WorldState in [door, combined, field]:
		for kind: String in Hound.EVENTS:
			if not source.event_log.any(func(e: EventRecord) -> bool: return e.type == kind): continue
			var original: Dictionary = last_fact(source.to_dict(), kind)
			if original.is_empty(): continue
			for variation: int in range(8):
				var data: Dictionary = source.to_dict().duplicate(true)
				var fact: Dictionary = last_fact(data, kind)
				match variation:
					0: fact.actor_id = "npc:foreign"
					1: fact.target_id = "device:foreign"
					2: fact.payload.revision = []
					3: fact.payload.site_id = "dungeon:sealed_waterworks"
					4: fact.payload.extra = true
					5: fact.day = -1
					6: fact.payload.room_id = []
					7: data.events.append(fact.duplicate(true))
				relay_reject_fixture(data, "actual malformed hound " + kind + "/" + str(variation))
	for variation: int in range(4):
		var data: Dictionary = road.to_dict().duplicate(true)
		match variation:
			0: data.events.erase(last_fact(data, "ROAD_COMBAT_BEGAN"))
			1: last_fact(data, "ROAD_COMBAT_BEGAN").payload.battle_id = []
			2: last_fact(data, "DOG_ASSISTED").payload.source = "field"
			3: last_fact(data, "FIELD_TURN").target_id = "settlement:gray_valley"
		relay_reject_fixture(data, "actual road machine source mismatch " + str(variation))
	for variation: int in range(6):
		var data: Dictionary = combined.to_dict().duplicate(true)
		match variation:
			0: data.events.erase(last_fact(data, "DOG_ASSISTED"))
			1: last_fact(data, "DOG_ASSISTED").payload.energy_remaining = 4
			2: last_fact(data, "DOG_ASSISTED").payload.source = "road"
			3: last_fact(data, "FIELD_TURN").payload.dog_dealt = []
			4: last_fact(data, "DOG_ASSISTED").payload.battle_id = 999
			5: last_fact(data, "FIELD_TURN").payload.turret_dealt = []
		relay_reject_fixture(data, "actual crossed support proof " + str(variation))
	var fresh: WorldState = normal_relay_start()
	var twin: WorldState = disk_copy(fresh, "missing resources boundary")
	relay_pair(fresh, twin, "ENTER")
	hound_pair(fresh, twin, "INSPECT_HOUND")
	rejected(fresh, Hound.intent(fresh, "REPAIR_HOUND"), "no gifted fuel or scrap")
	for p: Dictionary in [{"site_id": Hound.SITE, "command": "REPAIR_HOUND", "revision": []}, {"site_id": Hound.SITE, "command": "REPAIR_HOUND", "revision": 0, "extra": true}]:
		rejected(fresh, PlayerIntent.create_dungeon_action(fresh.player.npc_id, p), "invalid typed mechanical intent")
	clear_slot()

func hound_geometry(dialog: AcceptDialog) -> void:
	check(dialog.position.x >= 0 and dialog.position.y >= 0 and dialog.position.x + dialog.size.x <= root.size.x and dialog.position.y + dialog.size.y <= root.size.y, "actual hound popup fits %s/%s in%s" % [dialog.position, dialog.size, root.size])
	check(dialog.get_ok_button().size.y >= 40, "native hound return40px")
	for command_id: String in dialog.action_buttons:
		var button: Button = dialog.action_buttons[command_id]
		check(button.size.y >= 40 and button.get_global_rect().end.x <= dialog.size.x and button.get_global_rect().end.y <= dialog.size.y, "native hound action fits40px " + command_id)

func hound_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var world: WorldState = normal_relay_start()
		check(store.save_game(world).success, "native ordinary50 hound discovery disk")
		var main: Node = new_main(); await frames()
		main.save_dialog.load_button.pressed.emit(); await frames()
		find_command(main.shell, "中繼站").pressed.emit(); await frames()
		var screen: Control = main.shell.find_child("RelayScreen", false, false)
		relay_geometry(screen)
		await relay_observe("hound_broken_room")
		target_guide(screen, "INSPECT_HOUND"); screen.interact_button.pressed.emit(); await frames()
		var dialog: AcceptDialog = screen.hound_dialog
		hound_geometry(dialog)
		check(dialog.action_buttons.REPAIR_HOUND.disabled and dialog.action_buttons.REPAIR_HOUND.text.contains("缺燃料1") and not screen.view.enabled, "native missing fuel visible and walker paused")
		var before: String = main.world.to_canonical_json()
		dialog.refresh(); check(main.world.to_canonical_json() == before, "dialog projection cannot repair or charge")
		await relay_observe("hound_repair_locked")
		dialog.confirmed.emit(); await frames()
		target_guide(screen, "EXIT"); screen.interact_button.pressed.emit(); await frames()
		check(engine.commit_player_intent(main.world, PlayerIntent.create_buy(main.world.player.npc_id, &"fuel", 1)).success and engine.commit_player_intent(main.world, PlayerIntent.create_buy(main.world.player.npc_id, &"scrap", 3)).success, "native genuine50 material purchases via actual engine")
		main.shell.refresh_ui(); find_command(main.shell, "中繼站").pressed.emit(); await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		target_guide(screen, "INSPECT_HOUND"); screen.interact_button.pressed.emit(); await frames()
		dialog = screen.hound_dialog
		check(not dialog.action_buttons.REPAIR_HOUND.disabled, "native purchased preparation opens real repair")
		dialog.action_buttons.REPAIR_HOUND.pressed.emit(); await frames()
		hound_geometry(dialog)
		check(Hound.state(main.world).energy == 4 and dialog.action_buttons.REPAIR_HOUND.disabled and dialog.action_buttons.CHARGE_HOUND.disabled and dialog.detail.text.contains("能源4"), "native real repair4 and paid locks")
		await relay_observe("hound_repaired")
		dialog.action_buttons.HOUND_SUPPORT_ON.pressed.emit(); await frames()
		dialog.confirmed.emit(); await frames()
		for entry: Dictionary in [{"command": "SEARCH"}, {"command": "MOVE", "to": "relay_tunnel"}, {"command": "HOUND_WINDOW"}]:
			target_guide(screen, entry.command, entry.get("to", "")); screen.interact_button.pressed.emit(); await frames()
		dialog = screen.hound_dialog
		check(not dialog.action_buttons.HOUND_OPEN_TUNNEL.disabled and dialog.action_buttons.CHARGE_HOUND.disabled, "native charged door available, full recharge refused")
		dialog.action_buttons.HOUND_OPEN_TUNNEL.pressed.emit(); await frames()
		hound_geometry(dialog)
		check(Relay.state(main.world).tunnel_open and Hound.state(main.world).energy == 2 and dialog.action_buttons.HOUND_OPEN_TUNNEL.disabled, "native same inner gate opens for2charge once")
		await relay_observe("hound_opened_door")
		dialog.confirmed.emit(); await frames()
		for destination: String in ["relay_entrance", "relay_corridor"]:
			target_guide(screen, "MOVE", destination); screen.interact_button.pressed.emit(); await frames()
		target_guide(screen, "FIGHT"); screen.interact_button.pressed.emit(); await frames()
		var combat: Control = screen.combat_screen
		check(combat.stage.hound_actor.visible and combat.buttons.ATTACK.text.contains("犬2") and combat.buttons.ATTACK.text.contains("能源−1"), "native original machine and actual charge choice visible")
		await relay_observe("hound_battle_ready")
		var phases: Array[String] = []
		combat.stage.feedback_phase.connect(func(value: String) -> void: phases.append(value))
		combat.buttons.ATTACK.pressed.emit()
		for step: int in range(150):
			if "hound_support" in phases: break
			await create_timer(0.02).timeout
		check("hound_support" in phases and combat.stage.hound_actor.body.texture == combat.stage.hound_actor.work, "committed support drives distinct lunge pose")
		await relay_observe("hound_support_motion")
		await relay_combat_ready(combat)
		check(Hound.state(main.world).energy == 1 and main.world.field_state.enemy_hp == 2 and main.world.player.field_kit.hp == 9, "native actual door2 then assist1 leaves1")
		await relay_observe("hound_after_support")
		check(store.save_game(main.world).success, "native real midcombat one-energy save")
		before = main.world.to_canonical_json(); main.queue_free(); await frames()
		main = new_main(); await frames(); main.save_dialog.load_button.pressed.emit(); await frames()
		screen = main.shell.find_child("RelayScreen", false, false); combat = screen.combat_screen
		check(main.world.to_canonical_json() == before and Hound.state(main.world).energy == 1 and combat.stage.hound_actor.visible, "native Continue restores real device and energy midbattle")
		await relay_observe("hound_continue")
		combat.stage.reduced_motion = true; combat.buttons.ATTACK.pressed.emit(); await relay_combat_ready(combat)
		check(Hound.state(main.world).energy == 1 and main.world.field_state.enemy_hp == 0, "native ordinary reduced-motion kill preserves charge")
		await relay_observe("hound_victory")
		combat.buttons.CONFIRM.pressed.emit(); await frames()
		target_guide(screen, "MOVE", "relay_entrance"); screen.interact_button.pressed.emit(); await frames()
		target_guide(screen, "EXIT"); screen.interact_button.pressed.emit(); await frames()
		find_command(main.shell, "機械犬").pressed.emit(); await frames()
		for child: Node in main.shell.get_children():
			if child is HoundWindow: dialog = child
		hound_geometry(dialog)
		check(dialog.action_buttons.CHARGE_HOUND.disabled and dialog.action_buttons.CHARGE_HOUND.text.contains("缺燃料1"), "native town charging exposes actual fuel need")
		await relay_observe("hound_town_empty_fuel")
		main.world.player.inventory.fuel = 1 # Explicit native owned-fuel charging boundary; no claim of ordinary50 full preparation.
		dialog.refresh(); dialog.action_buttons.CHARGE_HOUND.pressed.emit(); await frames()
		check(Hound.state(main.world).energy == 4 and main.world.player.inventory.fuel == 0, "native actual1->4 charge consumes owned fuel")
		await relay_observe("hound_town_charged")
		dialog.confirmed.emit(); await frames()
		find_command(main.shell, "水廠").pressed.emit(); await frames()
		var water: Control = main.shell.find_child("DungeonScreen", false, false)
		water.hound_button.pressed.emit(); await frames()
		hound_geometry(water.hound_dialog)
		check(not water.view.enabled and water.hound_dialog.action_buttons.HOUND_SUPPORT_OFF.disabled == false, "native safe waterworks machine mode accessible")
		water.hound_dialog.action_buttons.HOUND_SUPPORT_OFF.pressed.emit(); await frames()
		check(not Hound.state(main.world).support and Hound.state(main.world).energy == 4, "native waterworks safe toggle charges no energy")
		await relay_observe("hound_waterworks_control")
		main.queue_free(); await frames()
	clear_slot()

func run_hound() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	var door: WorldState = hound_door()
	var field: WorldState = hound_field()
	var combined: WorldState = hound_turret()
	var road: WorldState = hound_other_contexts()
	hound_boundaries()
	hound_limits()
	hound_qualifications()
	hound_human_separation()
	hound_wounded_restart()
	hound_negatives(door, combined, field, road)
	await hound_ui()
	print("RLY-6: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
