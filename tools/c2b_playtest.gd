extends SceneTree

# A disposable, controlled C2-B playtest entry point. It uses the real creation
# authority, encounter projection, and playable shell, but never writes a save.
# It is deliberately not a substitute for a player's experience report.
const CreationIntent = preload("res://simulation/character_creation_intent.gd")
const BACKGROUNDS := ["CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER"]
const ENCOUNTERS := ["WRECK", "ROCKSLIDE", "ROADBLOCK", "DEHYDRATED_TRAVELLER", "REFUGEE_COLUMN"]
const TRAITS := ["GREEDY", "RECKLESS"]
const ORIGIN := &"settlement:gray_valley"
const DESTINATION := &"settlement:new_hope"

func _init() -> void:
	call_deferred("_start")

func _args() -> Dictionary:
	var parsed := {"background": "MECHANIC", "encounter": "WRECK", "traits": [],
		"verify": false, "capture": false, "viewport": Vector2i(1280, 720)}
	for arg in OS.get_cmdline_user_args():
		if arg == "--verify":
			parsed.verify = true
		elif arg == "--capture":
			parsed.capture = true
		elif arg == "--size=1152x648":
			parsed.viewport = Vector2i(1152, 648)
		elif arg == "--size=1280x720":
			parsed.viewport = Vector2i(1280, 720)
		elif arg.begins_with("--background="):
			parsed.background = arg.trim_prefix("--background=")
		elif arg.begins_with("--encounter="):
			parsed.encounter = arg.trim_prefix("--encounter=")
		elif arg.begins_with("--traits="):
			var raw := arg.trim_prefix("--traits=")
			parsed.traits = Array(raw.split(",", false)) if raw != "" else []
		else:
			push_error("Unknown playtest argument: " + arg)
			return {}
	if not BACKGROUNDS.has(parsed.background) or not ENCOUNTERS.has(parsed.encounter):
		push_error("Use a known --background and --encounter. See docs/c2b-playtest.md")
		return {}
	if parsed.traits.size() > 2:
		push_error("At most two distinct traits are allowed")
		return {}
	var seen := {}
	for trait_id in parsed.traits:
		if not TRAITS.has(trait_id) or seen.has(trait_id):
			push_error("This playtest supports distinct GREEDY and RECKLESS traits only")
			return {}
		seen[trait_id] = true
	return parsed

func _stage(background: String, traits: Array, encounter_name: String) -> Dictionary:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, CreationIntent.new({
		"source_settlement_id": String(ORIGIN), "character_name": "試玩旅人", "age": 25,
		"background_id": background, "trait_ids": traits,
	}))
	if not created.success:
		return {"error": "Creation failed: %s" % created}
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.inventory.set_amount("scrap", 2)
	world.player.inventory.set_amount("fuel", 0)
	world.player.money = 200
	var travel := engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, DESTINATION))
	if not travel.success:
		return {"error": "Travel failed: %s" % travel}
	# Replace the generated roadside stop only in this throwaway world. All builds
	# retain the same road, supplies, context and encounter index.
	world.pending_encounter_result = -1
	world.active_encounter = TravelEncounterState.create(
		StringName(encounter_name), world.current_day, ORIGIN, DESTINATION, 1,
		{"min_security": 40.0, "headcount": 12,
		"origin_name": "Gray Valley", "destination_name": "New Hope"})
	return {"world": world, "engine": engine}

func _verify() -> bool:
	var expected := {
		"MECHANIC/WRECK": "STRIP_PARTS",
		"SCAVENGER/WRECK": "QUICK_PICK",
		"FARMER/ROCKSLIDE": "SCOUT_PATH",
	}
	for background in BACKGROUNDS:
		for encounter_name in ENCOUNTERS:
			var staged := _stage(background, [], encounter_name)
			if staged.has("error"):
				push_error(staged.error)
				return false
			var world: WorldState = staged.world
			var before := world.to_canonical_json().sha256_text()
			var projected: Dictionary = PlayerUIProjection.project(world).active_encounter
			if projected.is_empty() or world.to_canonical_json().sha256_text() != before:
				push_error("Projection missing or changed world: %s/%s" % [background, encounter_name])
				return false
			var open_ids := []
			for option in projected.options:
				if option.enabled and not option.get("locked", false):
					open_ids.append(String(option.id))
			var key := "%s/%s" % [background, encounter_name]
			if expected.has(key) and not open_ids.has(expected[key]):
				push_error("Expected option absent: " + key)
				return false
	var no_trait: WorldState = _stage("MECHANIC", [], "DEHYDRATED_TRAVELLER").world
	var with_greedy: WorldState = _stage("MECHANIC", ["GREEDY"], "DEHYDRATED_TRAVELLER").world
	if _has_option(no_trait, "TAKE_PACK") or not _has_option(with_greedy, "TAKE_PACK"):
		push_error("GREEDY trait comparison is invalid")
		return false
	var no_reckless: WorldState = _stage("MECHANIC", [], "ROCKSLIDE").world
	var with_reckless: WorldState = _stage("MECHANIC", ["RECKLESS"], "ROCKSLIDE").world
	if _has_option(no_reckless, "FORCE_THROUGH") or not _has_option(with_reckless, "FORCE_THROUGH"):
		push_error("RECKLESS trait comparison is invalid")
		return false
	print("C2-B PLAYTEST HARNESS PASS: 20 background/encounter views, two trait pairs")
	return true

func _has_option(world: WorldState, id: String) -> bool:
	for option in PlayerUIProjection.project(world).active_encounter.options:
		if String(option.id) == id and option.enabled:
			return true
	return false

func _start() -> void:
	var args := _args()
	if args.is_empty():
		quit(2)
		return
	if args.verify:
		quit(0 if _verify() else 1)
		return
	var staged := _stage(args.background, args.traits, args.encounter)
	if staged.has("error"):
		push_error(staged.error)
		quit(1)
		return
	root.size = args.viewport
	var world: WorldState = staged.world
	var before := world.to_canonical_json().sha256_text()
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, staged.engine)
	for frame in range(6):
		await process_frame
	if shell.current_projection.active_encounter.is_empty() or not shell.encounter_panel.visible:
		push_error("The staged encounter is not visible in the real shell")
		quit(1)
		return
	var details := shell.desktop_details_window
	if details.position.x < 0.0 or details.position.x + details.size.x > root.size.x + 1.0:
		push_error("Encounter window extends past the viewport")
		quit(1)
		return
	if world.to_canonical_json().sha256_text() != before:
		push_error("Opening the playtest screen changed the world")
		quit(1)
		return
	if args.capture:
		var dir := "res://artifacts/c2b-playtest"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var filename := "%s_%s_%dx%d.png" % [args.background.to_lower(),
			args.encounter.to_lower(), args.viewport.x, args.viewport.y]
		var path := ProjectSettings.globalize_path(dir.path_join(filename))
		var image: Image = root.get_texture().get_image()
		if image == null or image.save_png(path) != OK:
			push_error("Could not capture " + path)
			quit(1)
			return
		print("CAPTURED ", path)
		shell.queue_free()
		await process_frame
		quit(0)
		return
	print("C2-B PLAYTEST: %s / %s / %s" % [args.background, args.encounter, args.traits])
	print("Close the Godot window to discard this disposable world. No save is written.")
