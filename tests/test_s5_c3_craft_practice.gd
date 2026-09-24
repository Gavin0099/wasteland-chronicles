extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Encounter = preload("res://simulation/travel_encounter.gd")

var engine := SimulationEngine.new()
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
		print("FAIL: " + message)

func created() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Craft Learner",
		"age": 24, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	}))
	check(result.success, "character is created through authority")
	world.player.inventory.set_amount("scrap", 3)
	return world

func craft(world: WorldState) -> Dictionary:
	return engine.commit_player_intent(world,
		PlayerIntent.create_field_action(world.player.npc_id, {"command": "CRAFT"}))

func track() -> Dictionary:
	var world := created()
	var initial_xp: int = world.player.xp
	var crafted := craft(world)
	check(crafted.success and world.player.field_kit.crowbar, "real craft spends scrap and creates crowbar")
	check(world.player.inventory.scrap == 0, "craft spends exactly three scrap")
	check(crafted.get("skill_practice", {}).get("skill_id", "") == "MECHANICS", "craft returns an actual mechanics award")
	check(crafted.get("skill_practice", {}).get("points", -1) == 1, "novice first craft earns one of two required practice days")
	check(world.player.capability.get_skill_rank("MECHANICS").rank == 0, "one craft does not silently grant rank")
	var craft_event: Dictionary = world.event_log.back().payload
	check(craft_event.get("skill_practice", {}) == crafted.get("skill_practice", {}), "ledger and result describe the same award")
	var loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success and loaded.world.to_canonical_json() == world.to_canonical_json(), "practiced craft survives save and load")
	check(engine.validate_invariants(world) == "", "craft respects global invariants")
	var denied_before := world.to_canonical_json().sha256_text()
	check(not craft(world).success and world.to_canonical_json().sha256_text() == denied_before, "second craft is atomically refused")
	check(engine.execute_player_wait(world).success, "real wait starts another practice day")
	var bought := engine.commit_player_intent(world,
		PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1))
	check(bought.success and world.player.inspect_item("wrench").success, "player obtains a real wrench from the regional market")
	var started := engine.begin_player_travel(world,
		PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"))
	check(started.success, "travel begins through authority")
	world.pending_encounter_result = -1
	world.active_encounter = TravelEncounterState.create(Encounter.WRECK, world.current_day,
		&"settlement:gray_valley", &"settlement:new_hope", 1, {})
	var used := engine.commit_player_intent(world,
		PlayerIntent.create_resolve_encounter(world.player.npc_id, &"USE_WRENCH"))
	check(used.success and used.get("skill_practice", {}).get("rank_up", false), "later wrench use advances mechanics 0 to 1")
	check(world.player.capability.get_skill_rank("MECHANICS").rank == 1, "owner profile holds earned rank")
	check(world.player.xp == initial_xp, "mechanics practice does not mint Level XP")
	check(engine.validate_invariants(world) == "", "full craft-to-wrench path preserves global invariants")
	return {"world": world, "sha": world.to_canonical_json().sha256_text()}

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var no_scrap := created()
	no_scrap.player.inventory.set_amount("scrap", 2)
	var before := no_scrap.to_canonical_json().sha256_text()
	check(not craft(no_scrap).success and no_scrap.to_canonical_json().sha256_text() == before,
		"unaffordable craft changes no world state or skill")

	var first := track()
	var second := track()
	check(first.sha == second.sha, "two-track full-world SHA-256 replay")
	print("S5-C3 craft replay SHA-256: " + String(first.sha))

	var practice_world := created()
	check(craft(practice_world).success, "tamper fixture creates actual practiced craft")
	for invalid in ["corrupt", {"skill_id": "MELEE", "rank_up": false,
		"from_rank": 0, "to_rank": 0, "points": 1, "required": 2}]:
		var tampered: Dictionary = practice_world.to_dict().duplicate(true)
		tampered.events[tampered.events.size() - 1].payload.skill_practice = invalid
		check(not WorldState.from_dict_checked(tampered).success, "invalid craft practice receipt fails dictionary load")
		check(not WorldState.from_json_checked(JSON.stringify(tampered)).success, "invalid craft practice receipt fails JSON load")
	var tampered: Dictionary = practice_world.to_dict().duplicate(true)
	tampered.events[tampered.events.size() - 1].payload.command = "REST"
	check(not WorldState.from_dict_checked(tampered).success, "practice cannot be attached to rest")

	var visual := created()
	var screen = preload("res://ui/field_screen.gd").new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var before_setup := visual.to_canonical_json().sha256_text()
	screen.setup(visual, engine)
	check(visual.to_canonical_json().sha256_text() == before_setup, "opening field screen leaves world unchanged")
	screen.perform({"command": "CRAFT"})
	await process_frame
	check(screen.growth_notice_label.visible and screen.growth_notice_label.text.contains("機械練習 +1"),
		"actual craft shows its mechanics award in the field screen")
	if "--capture" in OS.get_cmdline_user_args():
		var folder := OS.get_user_data_dir().path_join("captures/c3-growth")
		DirAccess.make_dir_recursive_absolute(folder)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
			root.size = viewport_size
			for frame in range(8):
				await process_frame
			var image_path := folder.path_join("craft_practice_%dx%d.png" % [viewport_size.x, viewport_size.y])
			check(root.get_texture().get_image().save_png(image_path) == OK, "real renderer saves craft feedback at %dx%d" % [viewport_size.x, viewport_size.y])
			print("CAPTURED " + image_path)
	screen.queue_free()
	await process_frame

	print("S5-C3 craft practice: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
