extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Registry = preload("res://simulation/quest_registry.gd")
const ROPE_ID := "gray_valley_rope_run"
const WRENCH_ID := "gray_valley_wrench_run"

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("QUEST-3: " + message)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Courier", "age": 25,
		"background_id": "SCAVENGER", "trait_ids": []}))
	check(created.success, "baseline character can be created")
	return world

func reach_dry_well(world: WorldState) -> bool:
	var started := engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well"))
	if not started.success:
		return false
	for turn in range(12):
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life.status == NpcLifeState.Status.SETTLED:
			return String(life.population_container_id) == "settlement:dry_well"
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
	var definitions := Registry.all_definitions()
	check(definitions.size() == 3 and Registry.has(ROPE_ID) and Registry.has(WRENCH_ID), "two original commissions remain registered beside the survey")
	var world := fixture()
	var before_projection := world.to_canonical_json()
	var rows: Array = PlayerUIProjection.project(world).quests
	# FUN-1 shares this board with generated work, so check the two authored
	# commissions specifically rather than the first two rows of the list.
	var authored: Array = []
	for row in rows:
		if not String(row.id).begins_with("job_"):
			authored.append(row)
	check(authored.size() == 2 and authored[0].status == "AVAILABLE" and authored[1].status == "AVAILABLE", "both commissions appear at local notice board")
	check(world.to_canonical_json() == before_projection, "multi-quest projection is read-only")
	var rope_definition: Dictionary = Registry.get_definition(ROPE_ID).definition
	check(rope_definition.objectives[0].item_id == "rope" and rope_definition.deadline_days == 5, "rope contract uses canonical owned item and five-day window")

	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	check(shell.quest_access_button.visible and not shell.quest_panel.visible, "journal has a persistent entry outside the settlement scroll")
	shell.quest_access_button.pressed.emit()
	check(shell.quest_panel.visible and not shell.right_scroll.visible, "opening the journal gives the quest its own right-side view")
	shell.quest_close_button.pressed.emit()
	check(not shell.quest_panel.visible and shell.right_scroll.visible and shell.quest_access_button.visible, "closing journal restores settlement and keeps quest access")
	await process_frame
	shell.right_scroll.scroll_vertical = 180
	await process_frame
	var scrolled_position := shell.right_scroll.scroll_vertical
	shell.quest_access_button.pressed.emit()
	check(shell.quest_title.is_visible_in_tree() and shell.quest_button.is_visible_in_tree(), "quest title and action remain visible regardless of settlement scroll position")
	shell.quest_close_button.pressed.emit()
	check(scrolled_position > 0 and shell.right_scroll.scroll_vertical == scrolled_position, "journal does not reset the settlement and market reading position")
	shell.quest_access_button.pressed.emit()
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	check(not shell.quest_panel.visible and shell.right_scroll.visible, "Escape closes journal and restores settlement")
	shell.quest_access_button.pressed.emit()
	check(world.to_canonical_json() == before_projection, "opening and closing journal cannot mutate world")
	check(shell.quest_selector.visible and shell.quest_selector.item_count >= 2, "PDA exposes two selectable commissions")
	check(shell.quest_selector.focus_mode == Control.FOCUS_ALL, "commission selector is keyboard focusable")
	var rope_index := -1
	var wrench_index := -1
	for i in shell.quest_selector.item_count:
		if String(shell.quest_selector.get_item_metadata(i)) == ROPE_ID:
			rope_index = i
		elif String(shell.quest_selector.get_item_metadata(i)) == WRENCH_ID:
			wrench_index = i
	check(rope_index >= 0 and wrench_index >= 0 and rope_index != wrench_index, "selector binds distinct stable quest IDs")
	if rope_index >= 0:
		shell.quest_selector.item_selected.emit(rope_index)
	check(shell.quest_id_shown == ROPE_ID and shell.quest_progress.text.contains("繩索"), "selecting rope quest changes the visible requirement")
	check(world.to_canonical_json() == before_projection, "switching visible commission does not mutate world")
	shell.quest_button.pressed.emit()
	check(world.quest_state.get_quest(ROPE_ID) != null and world.quest_state.get_quest(ROPE_ID).status == &"ACTIVE", "rope accept button commits its own intent")
	check(shell.quest_id_shown == ROPE_ID and shell.quest_progress.text.contains("進行中"), "PDA retains the selected commission after refresh")
	check(world.quest_state.get_quest(WRENCH_ID) == null, "accepting rope does not accept wrench")
	var accepted_day := world.current_day
	check(world.quest_state.get_quest(ROPE_ID).deadline_day == accepted_day + 4, "rope deadline is inclusive")
	var accepted_json := world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, ROPE_ID)).success and world.to_canonical_json() == accepted_json, "duplicate rope acceptance is atomic")
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, ROPE_ID)).success and world.to_canonical_json() == accepted_json, "early rope turn-in is atomic")
	check(WorldState.from_json_checked(accepted_json).world.to_canonical_json() == accepted_json, "two-quest catalogue keeps active save byte-stable")

	var bought := engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rope", 1))
	check(bought.success and world.player.item_inventory.contains("rope"), "normal 50-Caps opening can buy rope")
	var at_issuer := world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, ROPE_ID)).success and world.to_canonical_json() == at_issuer, "held rope cannot be delivered in Gray Valley")
	check(reach_dry_well(world), "ordinary road journey reaches Dry Well before deadline")
	var before_caps := world.player.money
	var before_xp := world.player.xp
	var completed := engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, ROPE_ID))
	check(completed.success and not world.player.item_inventory.contains("rope"), "rope turn-in transfers exactly one physical item")
	shell.refresh_ui()
	check(shell.quest_panel.visible and shell.quest_progress.text.contains("已完成 · 已交付 繩索 ×1") and shell.quest_progress.text.contains("65 瓶蓋、20 XP"), "completed commission remains readable after receipt closes")
	check(world.player.money == before_caps + 65 and world.player.xp == before_xp + 20, "rope rewards are exactly once and separate from skill ranks")
	check(world.quest_flags.get("dry_well_rope_delivered", false) and not world.quest_flags.get("dry_well_wrench_delivered", false), "rope sets only its own world fact")
	check(world.event_log.back().type == "QUEST_RESOLVED" and world.event_log.back().payload.quest_id == ROPE_ID, "ledger identifies correct commission")
	var complete_json := world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, ROPE_ID)).success and world.to_canonical_json() == complete_json, "repeated rope turn-in cannot grant again")
	check(WorldState.from_json_checked(complete_json).world.to_canonical_json() == complete_json, "completed rope save is byte-stable")
	check(engine.validate_invariants(world) == "", "rope quest preserves world invariants")
	var replay: WorldState = WorldState.from_json_checked(accepted_json).world
	check(engine.commit_player_intent(replay, PlayerIntent.create_buy_item(replay.player.npc_id, &"rope", 1)).success, "replay buys same item")
	check(reach_dry_well(replay), "replay travels same route")
	check(engine.commit_player_intent(replay, PlayerIntent.create_turn_in_quest(replay.player.npc_id, ROPE_ID)).success, "replay delivers same rope")
	check(replay.to_canonical_json().sha256_text() == complete_json.sha256_text(), "two independent journeys produce full-world SHA-256 match")
	var concurrent := fixture()
	concurrent.player.money = 200
	check(engine.commit_player_intent(concurrent, PlayerIntent.create_accept_quest(concurrent.player.npc_id, ROPE_ID)).success, "concurrent fixture accepts rope")
	check(engine.commit_player_intent(concurrent, PlayerIntent.create_accept_quest(concurrent.player.npc_id, WRENCH_ID)).success, "concurrent fixture accepts wrench")
	var concurrent_accepted_json := concurrent.to_canonical_json()
	check(WorldState.from_json_checked(concurrent_accepted_json).world.to_canonical_json() == concurrent_accepted_json, "both active promises survive a byte-stable save/load")
	check(engine.commit_player_intent(concurrent, PlayerIntent.create_buy_item(concurrent.player.npc_id, &"rope", 1)).success, "concurrent fixture buys rope")
	check(engine.commit_player_intent(concurrent, PlayerIntent.create_buy_item(concurrent.player.npc_id, &"wrench", 1)).success, "concurrent fixture buys wrench")
	check(reach_dry_well(concurrent), "both promises travel in the same world")
	check(engine.commit_player_intent(concurrent, PlayerIntent.create_turn_in_quest(concurrent.player.npc_id, ROPE_ID)).success, "first delivery resolves rope")
	check(concurrent.player.item_inventory.contains("wrench") and concurrent.quest_state.get_quest(WRENCH_ID).status == &"ACTIVE", "first delivery preserves other item and active quest")
	check(engine.commit_player_intent(concurrent, PlayerIntent.create_turn_in_quest(concurrent.player.npc_id, WRENCH_ID)).success, "second delivery resolves wrench")
	check(concurrent.quest_flags.get("dry_well_rope_delivered", false) and concurrent.quest_flags.get("dry_well_wrench_delivered", false), "both independent world facts are committed")
	check(concurrent.player.xp == 45 and engine.validate_invariants(concurrent) == "", "both rewards accumulate without violating invariants")
	var concurrent_complete_json := concurrent.to_canonical_json()
	var concurrent_replay: WorldState = WorldState.from_json_checked(concurrent_accepted_json).world
	check(engine.commit_player_intent(concurrent_replay, PlayerIntent.create_buy_item(concurrent_replay.player.npc_id, &"rope", 1)).success, "two-quest replay buys rope")
	check(engine.commit_player_intent(concurrent_replay, PlayerIntent.create_buy_item(concurrent_replay.player.npc_id, &"wrench", 1)).success, "two-quest replay buys wrench")
	check(reach_dry_well(concurrent_replay), "two-quest replay travels with both promises")
	check(engine.commit_player_intent(concurrent_replay, PlayerIntent.create_turn_in_quest(concurrent_replay.player.npc_id, ROPE_ID)).success, "two-quest replay delivers rope")
	check(engine.commit_player_intent(concurrent_replay, PlayerIntent.create_turn_in_quest(concurrent_replay.player.npc_id, WRENCH_ID)).success, "two-quest replay delivers wrench")
	check(concurrent_replay.to_canonical_json().sha256_text() == concurrent_complete_json.sha256_text() and engine.validate_invariants(concurrent_replay) == "", "two independent dual-quest journeys match full-world SHA-256 and invariants")

	var expiring := fixture()
	check(engine.commit_player_intent(expiring, PlayerIntent.create_accept_quest(expiring.player.npc_id, ROPE_ID)).success, "expiry fixture accepts rope")
	for i in range(5):
		engine.commit_player_intent(expiring, PlayerIntent.create_wait(expiring.player.npc_id))
	check(expiring.quest_state.get_quest(ROPE_ID).status == &"EXPIRED" and not expiring.quest_flags.has("dry_well_rope_delivered"), "rope promise expires without fake delivery")
	var warning := fixture()
	warning.player.inventory.water = 0
	warning.player.inventory.food = 0
	shell.setup(warning, engine)
	var warning_json := warning.to_canonical_json()
	check(shell.supply_alert.visible and shell.lbl_supply_alert.text.contains("水、食物"), "zero water and food appear in persistent top warning")
	check(warning.to_canonical_json() == warning_json, "supply warning projection cannot mutate world")
	warning.player.inventory.food = 1
	shell.refresh_ui()
	var mixed_warning_json := warning.to_canonical_json()
	check(shell.supply_alert.visible and shell.lbl_supply_alert.text.contains("水") and shell.lbl_supply_warning.visible and shell.lbl_supply_warning.text.contains("食物 1"), "zero water never suppresses the independent low-food warning")
	check(warning.to_canonical_json() == mixed_warning_json, "mixed-supply warnings remain read-only")
	shell.queue_free()
	await process_frame
	print("QUEST-3 multiple commissions: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
