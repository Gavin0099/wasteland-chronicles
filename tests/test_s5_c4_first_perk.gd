extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
const Registry = preload("res://simulation/quest_registry.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("S5-C4: " + message)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "PerkTester",
		"age": 25, "background_id": "MECHANIC", "trait_ids": [],
	}))
	check(result.success, "normal character creation succeeds")
	world.player.inventory.water = 6
	world.player.inventory.food = 6
	return world

func find_sheet(shell: Node) -> Node:
	for child in shell.get_children():
		if child is AcceptDialog and child.has_method("setup") and child.get("perk_choice_buttons") != null:
			return child
	return null

func start_encounter(world: WorldState, kind: StringName) -> void:
	var started := engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"))
	check(started.success, "travel starts before encounter")
	world.active_encounter = TravelEncounterState.create(kind, world.current_day, &"settlement:gray_valley", &"settlement:new_hope", 1)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	check(Perks.xp_for_level(2) == 20 and Perks.xp_for_level(3) == 45 and Perks.xp_for_level(4) == 75, "first three XP thresholds are fixed")
	var delivery_xp := 0
	for id in ["gray_valley_wrench_run", "gray_valley_rope_run"]:
		for reward in Registry.get_definition(id).definition.outcomes.resolved.rewards:
			if String(reward.type) == "XP":
				delivery_xp += int(reward.amount)
	check(delivery_xp == Perks.xp_for_level(3), "two existing ordinary commissions reach the first perk milestone")
	var locked := fixture()
	check(locked.player.level() == 1 and locked.player.perk_ids.is_empty(), "new character starts level one without perk")
	locked.player.xp = 44
	var before_lock := locked.to_canonical_json()
	check(not engine.commit_player_intent(locked, PlayerIntent.create_select_perk(locked.player.npc_id, "ROAD_RUNNER")).success and locked.to_canonical_json() == before_lock, "level-two selection fails atomically")
	check(Perks.level_for_xp(45) == 3 and Perks.level_for_xp(90) == 4, "level follows lifetime XP without changing skills")
	start_encounter(locked, TravelEncounter.WRECK)
	var unowned_before := locked.to_canonical_json()
	check(not engine.commit_player_intent(locked, PlayerIntent.create_resolve_encounter(locked.player.npc_id, &"SORT_WRECK")).success and locked.to_canonical_json() == unowned_before, "forged perk approach fails atomically before it is owned")

	var first := fixture()
	var replay := fixture()
	for world_variant in [first, replay]:
		var world: WorldState = world_variant
		world.player.xp = 45
		var ranks_before: Dictionary = world.player.capability.to_dict().skill_ranks
		var selected := engine.commit_player_intent(world, PlayerIntent.create_select_perk(world.player.npc_id, "CAREFUL_SALVAGER"))
		check(selected.success and world.player.has_perk("CAREFUL_SALVAGER"), "level-three choice commits to player owner")
		check(world.player.capability.to_dict().skill_ranks == ranks_before and world.player.growth_points == 0, "perk does not raise every skill or mint growth points")
		check(world.event_log.back().type == "PERK_SELECTED" and world.event_log.back().payload.perk_id == "CAREFUL_SALVAGER", "choice writes committed identity fact")
		var after_select := world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_select_perk(world.player.npc_id, "ROAD_RUNNER")).success and world.to_canonical_json() == after_select, "one milestone cannot buy both perks")
		check(WorldState.from_json_checked(after_select).success and engine.validate_invariants(world) == "", "selected perk survives checked save and global invariants")
	check(first.to_canonical_json().sha256_text() == replay.to_canonical_json().sha256_text(), "dual-track full-world SHA matches after milestone choice")
	var forged: Dictionary = first.to_dict().duplicate(true)
	forged.player.perk_ids = ["UNKNOWN"]
	check(not WorldState.from_dict_checked(forged).success, "unknown saved perk fails closed")
	forged = first.to_dict().duplicate(true)
	forged.player.xp = 0
	check(not WorldState.from_dict_checked(forged).success, "perk without earned XP fails closed")
	forged = first.to_dict().duplicate(true)
	forged.player.perk_ids = ["ROAD_RUNNER", "CAREFUL_SALVAGER"]
	check(not WorldState.from_dict_checked(forged).success, "multiple or unsorted picks fail closed")
	for world_variant in [first, replay]:
		var world: WorldState = world_variant
		start_encounter(world, TravelEncounter.WRECK)
		var options: Array = PlayerUIProjection.project(world).active_encounter.options
		check(options.any(func(o: Dictionary) -> bool: return String(o.id) == "SORT_WRECK" and o.enabled), "salvager sees its own approach")
		check(not options.any(func(o: Dictionary) -> bool: return String(o.id) == "CUT_AROUND"), "other perk approach stays hidden")
		var resolution := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"SORT_WRECK"))
		check(resolution.success and resolution.gained.get("scrap", 0) == 1 and resolution.get("items_gained", {}).is_empty(), "careful sorting finds one scrap, never sealed rare kit")
		check(engine.validate_invariants(world) == "", "perk encounter preserves global invariants")
	check(first.to_canonical_json().sha256_text() == replay.to_canonical_json().sha256_text(), "dual-track full-world SHA matches after new encounter action")

	var runner := fixture()
	runner.player.xp = 45
	check(engine.commit_player_intent(runner, PlayerIntent.create_select_perk(runner.player.npc_id, "ROAD_RUNNER")).success, "second build chooses alternate specialization")
	start_encounter(runner, TravelEncounter.ROADBLOCK)
	var runner_before := runner.to_canonical_json()
	check(not engine.commit_player_intent(runner, PlayerIntent.create_resolve_encounter(runner.player.npc_id, &"SORT_WRECK")).success and runner.to_canonical_json() == runner_before, "wrong encounter approach cannot be forged")
	var money_before := runner.player.money
	var day_before := runner.current_day
	var bypass := engine.commit_player_intent(runner, PlayerIntent.create_resolve_encounter(runner.player.npc_id, &"CUT_AROUND"))
	check(bypass.success and runner.player.money == money_before and runner.current_day == day_before, "road runner bypasses toll without delay")
	check(engine.validate_invariants(runner) == "", "alternate build preserves invariants")

	var ui_world := fixture()
	ui_world.player.xp = 45
	var ui_replay: WorldState = WorldState.from_json_checked(ui_world.to_canonical_json()).world
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(ui_world, engine)
	var ui_before := ui_world.to_canonical_json()
	shell._show_character()
	await process_frame
	var sheet := find_sheet(shell)
	check(sheet != null and sheet.perk_choice_buttons.size() == 2 and ui_world.to_canonical_json() == ui_before, "read-only character sheet offers two visible choices")
	if "--capture" in OS.get_cmdline_user_args():
		var folder := OS.get_user_data_dir().path_join("captures/s5-c4")
		DirAccess.make_dir_recursive_absolute(folder)
		for size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
			root.size = size
			for frame in range(8):
				await process_frame
			var path := folder.path_join("perk_choice_%dx%d.png" % [size.x, size.y])
			check(root.get_texture().get_image().save_png(path) == OK, "real renderer captures milestone choice")
			print("CAPTURED " + path)
	sheet.perk_choice_buttons.ROAD_RUNNER.pressed.emit()
	for frame in range(4):
		await process_frame
	check(ui_world.player.has_perk("ROAD_RUNNER") and ui_world.player.perk_ids.size() == 1, "player-facing button commits exactly one perk")
	check(engine.commit_player_intent(ui_replay, PlayerIntent.create_select_perk(ui_replay.player.npc_id, "ROAD_RUNNER")).success and ui_world.to_canonical_json().sha256_text() == ui_replay.to_canonical_json().sha256_text(), "UI and direct authority full-world SHA match")
	check(find_sheet(shell) != null and find_sheet(shell).perk_choice_buttons.is_empty(), "chosen perk replaces choice buttons")
	check(engine.validate_invariants(ui_world) == "" and engine.validate_invariants(ui_replay) == "", "UI/direct tracks preserve invariants")
	shell.queue_free()
	await process_frame
	await process_frame
	var salvager_ui := fixture()
	salvager_ui.player.xp = 45
	var salvager_replay: WorldState = WorldState.from_json_checked(salvager_ui.to_canonical_json()).world
	var second_shell := PlayableShell.new()
	root.add_child(second_shell)
	second_shell.setup(salvager_ui, engine)
	second_shell._show_character()
	await process_frame
	var second_sheet := find_sheet(second_shell)
	check(second_sheet != null and second_sheet.perk_choice_buttons.has("CAREFUL_SALVAGER"), "first perk is offered through the same player-facing sheet")
	second_sheet.perk_choice_buttons.CAREFUL_SALVAGER.pressed.emit()
	for frame in range(4):
		await process_frame
	check(salvager_ui.player.has_perk("CAREFUL_SALVAGER") and not salvager_ui.player.has_perk("ROAD_RUNNER"), "first perk button selects its own id, not the final loop choice")
	check(engine.commit_player_intent(salvager_replay, PlayerIntent.create_select_perk(salvager_replay.player.npc_id, "CAREFUL_SALVAGER")).success and salvager_ui.to_canonical_json().sha256_text() == salvager_replay.to_canonical_json().sha256_text(), "first perk UI and direct authority full-world SHA match")
	second_shell.queue_free()
	await process_frame
	await process_frame
	print("S5-C4 first perk: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
