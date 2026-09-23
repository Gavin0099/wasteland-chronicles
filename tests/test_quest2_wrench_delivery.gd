extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Quests = preload("res://simulation/quest_registry.gd")
const TrackedQuest = preload("res://simulation/quest_state.gd")
const QUEST_ID := "gray_valley_wrench_run"

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("QUEST-2: " + message)

func fixture(start: String = "settlement:gray_valley") -> WorldState:
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": start, "character_name": "Courier", "age": 25,
		"background_id": "SCAVENGER", "trait_ids": []}))
	check(created.success, "character creation succeeds")
	world.player.money = 200
	world.player.inventory.water = 8
	world.player.inventory.food = 8
	return world

func finish_delivery(world: WorldState) -> bool:
	if not engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1)).success:
		return false
	if not engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success:
		return false
	for turn in range(12):
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life.status == NpcLifeState.Status.SETTLED:
			return engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID)).success
		if world.pending_encounter_result >= 0:
			if not engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success:
				return false
		elif world.active_encounter != null:
			var selected := &""
			for option in TravelEncounter.options(world.active_encounter.encounter_type):
				if engine.authorize_encounter_option(world, option.id) == "":
					selected = option.id
					break
			if selected == &"" or not engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, selected)).success:
				return false
		else:
			return false
	return false

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var definitions: Array = Quests.all_definitions()
	check(definitions.size() == 1 and definitions[0].id == QUEST_ID, "one authored quest is registered")
	var world := fixture()
	var baseline := world.to_canonical_json()
	var projected: Array = PlayerUIProjection.project(world).quests
	check(projected.size() == 1 and projected[0].status == "AVAILABLE", "local board shows available quest")
	check(world.to_canonical_json() == baseline, "quest projection does not mutate world")
	var remote := fixture("settlement:new_hope")
	check(PlayerUIProjection.project(remote).quests.is_empty(), "remote board does not leak quest")
	var remote_before := remote.to_canonical_json()
	var refused := engine.commit_player_intent(remote, PlayerIntent.create_accept_quest(remote.player.npc_id, QUEST_ID))
	check(not refused.success and remote.to_canonical_json() == remote_before, "remote acceptance fails atomically")
	var discovered := fixture()
	var available := TrackedQuest.new(QUEST_ID)
	available.status = &"AVAILABLE"
	discovered.quest_state.set_quest(available)
	check(engine.commit_player_intent(discovered, PlayerIntent.create_accept_quest(discovered.player.npc_id, QUEST_ID)).success, "tracked AVAILABLE quest can transition to ACTIVE")
	var unknown_before := world.to_canonical_json()
	var unknown := engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, "forged"))
	check(not unknown.success and world.to_canonical_json() == unknown_before, "unknown quest fails atomically")

	var accepted := engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, QUEST_ID))
	check(accepted.success and world.quest_state.get_quest(QUEST_ID).status == &"ACTIVE", "accept records active quest")
	check(world.event_log.back().type == "QUEST_ACCEPTED", "acceptance writes one ledger fact")
	var deadline: int = world.quest_state.get_quest(QUEST_ID).deadline_day
	check(deadline == world.current_day + 7, "eight-day deadline is inclusive")
	var accepted_json := world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == accepted_json, "duplicate acceptance fails without mutation")
	var active_loaded: Dictionary = WorldState.from_json_checked(accepted_json)
	check(active_loaded.success, "active quest loads: %s" % String(active_loaded.error))
	if not active_loaded.success:
		quit(1)
		return
	check(active_loaded.world.to_canonical_json() == accepted_json, "active quest save/load is byte-stable")
	var early := engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID))
	check(not early.success and world.to_canonical_json() == accepted_json, "early turn-in fails atomically")
	var bought := engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1))
	check(bought.success and world.player.item_inventory.contains("wrench"), "wrench acquired through real market")
	var wrong_place := world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == wrong_place, "holding the item at issuer town cannot deliver it")

	var travel := engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well"))
	check(travel.success, "real travel starts toward dry well")
	var safety := 0
	while safety < 12:
		safety += 1
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life.status == NpcLifeState.Status.SETTLED:
			break
		if world.pending_encounter_result >= 0:
			var continued := engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
			check(continued.success, "encounter receipt can be confirmed")
		elif world.active_encounter != null:
			var selected := &""
			for option in TravelEncounter.options(world.active_encounter.encounter_type):
				if engine.authorize_encounter_option(world, option.id) == "":
					selected = option.id
					break
			check(selected != &"", "road encounter has a legal response")
			if selected != &"":
				check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, selected)).success, "road response commits")
		else:
			break
	var arrived: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	check(arrived.status == NpcLifeState.Status.SETTLED and String(arrived.population_container_id) == "settlement:dry_well", "courier reaches dry well")
	check(world.quest_state.get_quest(QUEST_ID).status == &"ACTIVE", "quest remains active on arrival")
	var before_caps := world.player.money
	var before_xp := world.player.xp
	var ranks_before: Dictionary = world.player.capability.to_dict()
	var completed := engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID))
	check(completed.success and not world.player.item_inventory.contains("wrench"), "turn-in transfers one physical wrench")
	check(world.player.money == before_caps + 75 and world.player.xp == before_xp + 25, "caps and XP granted exactly as authored")
	check(world.player.capability.to_dict() == ranks_before and world.player.growth_points == 0, "quest XP does not change ranks or growth points")
	check(world.quest_flags.get("dry_well_wrench_delivered", false) and world.event_log.back().type == "QUEST_RESOLVED", "world flag and receipt record delivery")
	var complete_json := world.to_canonical_json()
	check(WorldState.from_json_checked(complete_json).world.to_canonical_json() == complete_json, "completed quest save/load is byte-stable")
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == complete_json, "second turn-in cannot duplicate reward")
	check(engine.validate_invariants(world) == "", "delivery preserves world invariants")

	var replay: WorldState = WorldState.from_json_checked(accepted_json).world
	check(replay.to_canonical_json() == accepted_json, "independent replay begins from identical accepted state")
	check(finish_delivery(replay), "independent journey and delivery complete")
	check(replay.to_canonical_json().sha256_text() == complete_json.sha256_text(), "independent replay reproduces full world SHA-256")
	var expiring := fixture()
	check(engine.commit_player_intent(expiring, PlayerIntent.create_accept_quest(expiring.player.npc_id, QUEST_ID)).success, "expiry fixture accepts")
	for i in range(8):
		engine.commit_player_intent(expiring, PlayerIntent.create_wait(expiring.player.npc_id))
	check(expiring.quest_state.get_quest(QUEST_ID).status == &"EXPIRED", "quest expires after inclusive deadline")
	check(not expiring.quest_flags.has("dry_well_wrench_delivered"), "expiry does not fake delivery")

	var ui_world := fixture()
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(ui_world, engine)
	check(shell.quest_panel.visible and shell.quest_button.text == "接受委託", "PDA presents local quest action")
	var ui_before := ui_world.to_canonical_json()
	shell.refresh_ui()
	check(ui_world.to_canonical_json() == ui_before, "opening quest PDA is read-only")
	shell.quest_button.pressed.emit()
	check(ui_world.quest_state.get_quest(QUEST_ID) != null and ui_world.quest_state.get_quest(QUEST_ID).status == &"ACTIVE", "PDA button sends authority-backed accept intent")
	check(shell.quest_button.text == "交付物品" and shell.quest_button.disabled, "accepted quest remains visible but cannot be delivered at issuer")
	shell.queue_free()
	await process_frame
	print("QUEST-2 wrench delivery: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
