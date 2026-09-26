extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Registry = preload("res://simulation/quest_registry.gd")
const QUEST_ID := "dry_well_north_survey"

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("WPROG-4: " + message)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "NorthScout",
		"age": 25, "background_id": "SCAVENGER", "trait_ids": [],
	}))
	check(created.success, "character is created through normal authority")
	world.player.inventory.water = 10
	world.player.inventory.food = 10
	return world

func travel_to(world: WorldState, destination: StringName) -> bool:
	var started := engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, destination))
	if not started.success:
		return false
	for turn in range(30):
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life.status == NpcLifeState.Status.SETTLED:
			return life.population_container_id == destination
		if world.pending_encounter_result >= 0:
			if not engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success:
				return false
		elif world.active_encounter != null:
			var choice := &""
			for option in TravelEncounter.options(world.active_encounter.encounter_type):
				# These are delivery tests. Every road now carries bandits, so a courier
				# answers an ambush the way a courier would - not by starting a fight
				# this helper was never written to finish.
				if option.id == &"FIGHT":
					continue
				if engine.authorize_encounter_option(world, option.id) == "":
					choice = option.id
					break
			if choice == &"" or not engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice)).success:
				return false
		else:
			return false
	return false

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var definition: Dictionary = Registry.get_definition(QUEST_ID).definition
	check(Registry.all_definitions().size() == 3 and definition.objectives[1].type == "VISIT_LOCATION", "third contract uses visit instead of another delivery")
	var malformed: Dictionary = definition.duplicate(true)
	malformed.availability.required_equipped_item_id = "Military Backpack"
	check(Registry.validate_definition(malformed) == "QUEST_DEF_INVALID_EQUIPPED_ITEM_ID", "equipped-item gate validates stable ID")

	var first := fixture()
	var second := fixture()
	for world_variant in [first, second]:
		var world: WorldState = world_variant
		var before := world.to_canonical_json()
		var rows: Array = PlayerUIProjection.project(world).quests
		var contract := {}
		for row in rows:
			if String(row.id) == QUEST_ID:
				contract = row
		check(not contract.is_empty() and contract.status == "LOCKED" and not contract.can_act, "local board shows a readable locked higher-tier contract")
		check(world.to_canonical_json() == before, "locked projection is read-only")
		check(not engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == before, "accept without equipment fails atomically")
		check(world.player.pickup_item("military_backpack").success, "rare item enters inventory in earned-gear fixture")
		check(not engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, QUEST_ID)).success, "holding but not equipping backpack cannot accept")
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, "military_backpack", "back")).success, "rare pack equips via authority")
		check(PlayerUIProjection.project(world).quests[0].status == "AVAILABLE", "equipping unlocks local offer")
		# An earlier arrival is a ledger fact, but cannot satisfy a future commission.
		world.record_event(EventRecord.new(world.current_day, "NAMED_MIGRATION_COMPLETED", world.player.npc_id, &"settlement:new_hope", {}))
		check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, QUEST_ID)).success, "prepared character accepts survey")
		check(not load("res://simulation/quest_engine.gd").evaluate_objectives(world, QUEST_ID), "pre-acceptance arrival does not satisfy new work")
		var premature := world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == premature, "early report fails atomically")
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual-track SHA matches after unlocking and acceptance")

	var active_load := WorldState.from_json_checked(first.to_canonical_json())
	check(active_load.success and active_load.world.to_canonical_json() == first.to_canonical_json(), "active survey survives checked save/load")
	for world_variant in [first, second]:
		var world: WorldState = world_variant
		check(travel_to(world, &"settlement:new_hope"), "player makes actual journey to survey destination")
		check(engine.validate_invariants(world) == "", "outbound journey preserves global invariants")
		var wrong_place := world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == wrong_place, "survey cannot be reported at remote destination")
		world.player.inventory.water = 10
		world.player.inventory.food = 10
		check(travel_to(world, &"settlement:dry_well"), "player returns to issuer town")
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual-track full-world SHA matches after return journey")
	for world_variant in [first, second]:
		var world: WorldState = world_variant
		check(load("res://simulation/quest_engine.gd").evaluate_objectives(world, QUEST_ID), "post-acceptance arrival satisfies visit objective")
		var before_money := world.player.money
		if world == first:
			var report_shell := PlayableShell.new()
			root.add_child(report_shell)
			report_shell.setup(world, engine)
			report_shell.quest_access_button.pressed.emit()
			check(report_shell.quest_button.visible and not report_shell.quest_button.disabled, "completed survey has an enabled report command")
			report_shell.quest_button.pressed.emit()
			var receipt_text := ""
			for child in report_shell.get_children():
				if child is AcceptDialog and child.title == "委託結果":
					receipt_text = child.dialog_text
			check(receipt_text.contains("軍用背包仍由你持有") and not receipt_text.contains("已交付"), "report receipt describes retained gear truthfully")
			if "--capture" in OS.get_cmdline_user_args():
				var report_folder := OS.get_user_data_dir().path_join("captures/wprog-4")
				DirAccess.make_dir_recursive_absolute(report_folder)
				for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
					root.size = viewport_size
					for frame in range(8):
						await process_frame
					var report_path := report_folder.path_join("survey_report_%dx%d.png" % [viewport_size.x, viewport_size.y])
					check(root.get_texture().get_image().save_png(report_path) == OK, "real renderer captures survey report receipt")
					print("CAPTURED " + report_path)
			report_shell.queue_free()
			await process_frame
		else:
			var result := engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID))
			check(result.success and result.delivered.is_empty(), "report resolves without consuming backpack")
		check(world.player.item_inventory.quantity("military_backpack") == 1, "report keeps the military backpack")
		check(world.player.money == before_money + 150 and world.quest_flags.get("dry_well_north_surveyed", false), "reward and report flag commit once")
		check(world.quest_state.get_quest(QUEST_ID).status == &"RESOLVED", "quest closes after return")
		var final_json := world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, QUEST_ID)).success and world.to_canonical_json() == final_json, "duplicate report cannot pay twice")
		check(WorldState.from_json_checked(final_json).success and engine.validate_invariants(world) == "", "resolved survey loads and preserves invariants")
	check(first.to_canonical_json().sha256_text() == second.to_canonical_json().sha256_text(), "dual-track final SHA matches after reward")

	var shell := PlayableShell.new()
	root.add_child(shell)
	var locked := fixture()
	shell.setup(locked, engine)
	shell.quest_access_button.pressed.emit()
	check(shell.quest_access_button.text.contains("未解鎖 1") and shell.quest_progress.text.contains("軍用背包") and not shell.quest_button.visible, "locked requirement is visible and classified correctly")
	if "--capture" in OS.get_cmdline_user_args():
		var folder := OS.get_user_data_dir().path_join("captures/wprog-4")
		DirAccess.make_dir_recursive_absolute(folder)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
			root.size = viewport_size
			for frame in range(8):
				await process_frame
			var image_path := folder.path_join("next_contract_%dx%d.png" % [viewport_size.x, viewport_size.y])
			check(root.get_texture().get_image().save_png(image_path) == OK, "real renderer captures next-tier contract")
			print("CAPTURED " + image_path)
	shell.queue_free()
	print("WPROG-4 next contract: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
