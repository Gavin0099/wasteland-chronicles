extends SceneTree

# ==============================================================================
# ASP-2: RUMORS & ASPIRATIONS
# ==============================================================================
# Owner ruling: not an achievement list. The world tells the player about
# things that really exist; the player decides which to chase.
#
#   R1 Heard where it is told: a rumour appears only after the player has been
#      in a town where people talk about it - nothing unheard is listed
#   R2 Every rumour points at something real in the world
#   R3 It says what stands between you and it now, from live state, and it is
#      settled when the world says so
#   R4 Chasing is a choice: only a heard rumour, the last choice wins, and it
#      can be let go
#   R5 The player sees it: the sheet lists what was heard with a chase button,
#      and the chosen aim stays in view on the main screen
#   R6 Saves round-trip
# ==============================================================================

const Rumors = preload("res://simulation/rumors.gd")
const RoadPlaces = preload("res://simulation/road_places.gd")
const Board = preload("res://simulation/job_board.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ASP-2: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(origin: String = "settlement:gray_valley") -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "Listener",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	return world

func heard_ids(world: WorldState) -> Array:
	var out: Array = []
	for row in Rumors.project(world):
		out.append(String(row.id))
	return out

func walk_to(world: WorldState, destination: String) -> void:
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, StringName(destination)))
	var guard := 0
	while guard < 12:
		guard += 1
		if world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
			continue
		if world.active_encounter == null:
			return
		var choice := &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice))

func progress_text(world: WorldState, rumor_id: String) -> String:
	return String(Rumors.progress(world, rumor_id).next)

func run() -> void:
	# ---- R1 heard where it is told ----
	var world := fresh_world("settlement:gray_valley")
	var at_start := heard_ids(world)
	check(at_start.has("rumor:old_well") and at_start.has("rumor:fuel_station"), "R1: Gray Valley talks about the well and the fuel station: %s" % [at_start])
	check(not at_start.has("rumor:raider") and not at_start.has("rumor:armory"), "R1: nobody in Gray Valley talks about the raider or the armory")
	walk_to(world, "settlement:dry_well")
	var after_dw := heard_ids(world)
	check(after_dw.has("rumor:raider") and after_dw.has("rumor:armory"), "R1: in Dry Well you hear of the raider and the armory: %s" % [after_dw])
	check(after_dw.size() <= Rumors.ids().size(), "R1: never more than the rumours that exist")

	# ---- R2 every rumour is real ----
	for rumor_id in Rumors.ids():
		var r: Dictionary = Rumors.RUMORS[rumor_id]
		if r.has("place_id"):
			check(RoadPlaces.exists(String(r.place_id)), "R2: %s points at a real place" % rumor_id)
	var standing_up := false
	for entry in Board.postings(world, &"settlement:new_hope"):
		if bool(entry.get("standing", false)):
			standing_up = true
	check(standing_up, "R2: the raider rumour's bounty is really on New Hope's board")

	# ---- R3 what stands in the way, and when it is settled ----
	world.player.capability._data.skill_ranks["MECHANICS"] = 0
	check(progress_text(world, "rumor:armory").contains("機械 2") and progress_text(world, "rumor:armory").contains("0"), "R3: the armory says it needs MECHANICS 2 and you have 0")
	world.player.capability._data.skill_ranks["MECHANICS"] = 2
	check(progress_text(world, "rumor:armory").contains("荒野路"), "R3: with MECHANICS 2 it says which road to take")
	world.player.capability._data.skill_ranks["MELEE"] = 0
	check(progress_text(world, "rumor:raider").contains("打不贏"), "R3: unarmed, the raider rumour says not yet")
	check(not bool(Rumors.progress(world, "rumor:raider").done), "R3: and it is not settled")
	world.record_event(EventRecord.new(world.current_day, "FIELD_RESULT", world.player.npc_id, &"settlement:dry_well",
		{"outcome": "VICTORY", "enemy": Enemies.HEAVY_RAIDER, "gained": {}, "left_behind": {}}))
	check(bool(Rumors.progress(world, "rumor:raider").done), "R3: beating him settles it")

	var well := fresh_world("settlement:gray_valley")
	check(progress_text(well, "rumor:old_well").contains("第一天"), "R3: the well rumour says where it is")
	well.player.inventory.set_amount("water", 8)
	well.player.inventory.set_amount("food", 8)
	engine.commit_player_intent(well, PlayerIntent.create_travel(well.player.npc_id, &"settlement:dry_well"))
	if well.active_encounter != null and String(well.active_encounter.context.get("place_id", "")) == "place:old_well":
		engine.commit_player_intent(well, PlayerIntent.create_resolve_encounter(well.player.npc_id, &"MARK_A"))
	check(progress_text(well, "rumor:old_well").contains("灰谷"), "R3: once marked it says where to report it")
	check(not bool(Rumors.progress(well, "rumor:old_well").done), "R3: marked is not settled")

	# ---- R4 chasing is a choice ----
	var chase := fresh_world("settlement:gray_valley")
	var id: StringName = chase.player.npc_id
	var refused := engine.commit_player_intent(chase, PlayerIntent.create_track_rumor(id, "rumor:armory"))
	check(not refused.success and String(refused.error) == "RUMOR_NOT_HEARD", "R4: you cannot chase what you have not heard")
	check(not engine.commit_player_intent(chase, PlayerIntent.create_track_rumor(id, "rumor:made_up")).success, "R4: or something that does not exist")
	check(engine.commit_player_intent(chase, PlayerIntent.create_track_rumor(id, "rumor:old_well")).success, "R4: chase the well")
	check(Rumors.tracked(chase) == "rumor:old_well", "R4: it is the aim")
	check(engine.commit_player_intent(chase, PlayerIntent.create_track_rumor(id, "rumor:fuel_station")).success, "R4: change your mind")
	check(Rumors.tracked(chase) == "rumor:fuel_station", "R4: the last choice wins")
	var tracked_rows := 0
	for row in Rumors.project(chase):
		if bool(row.tracked):
			tracked_rows += 1
	check(tracked_rows == 1, "R4: only one aim at a time")

	# ---- R5 the player sees it ----
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(chase, engine)
	await process_frame
	check(shell.desktop_aim_label != null and shell.desktop_aim_label.visible, "R5: the aim is on the main screen")
	check(shell.desktop_aim_label.text.contains("加油站"), "R5: it names what you chase: %s" % shell.desktop_aim_label.text)
	var sheet = preload("res://ui/components/rumor_window.gd").new()
	root.add_child(sheet)
	var chosen := [""]
	sheet.setup(Rumors.project(chase), func(rid: String): chosen[0] = rid)
	await process_frame
	check(sheet.rumor_buttons.has("rumor:old_well") and sheet.rumor_buttons.has("rumor:fuel_station"), "R5: each heard rumour has a chase button")
	check(not sheet.rumor_buttons.has("rumor:armory"), "R5: an unheard one is not listed at all")
	sheet.rumor_buttons["rumor:old_well"].pressed.emit()
	check(chosen[0] == "rumor:old_well", "R5: pressing it chooses that rumour")
	sheet.rumor_buttons["rumor:fuel_station"].pressed.emit()
	check(chosen[0] == "", "R5: pressing the one you chase lets it go")
	check(engine.commit_player_intent(chase, PlayerIntent.create_track_rumor(id, "")).success, "R4: letting go commits")
	check(Rumors.tracked(chase) == "", "R4: nothing is chased now")
	shell.refresh_ui()
	check(not shell.desktop_aim_label.visible, "R5: and the main screen stops showing an aim")
	sheet.queue_free()
	shell.queue_free()

	# ---- R6 saves ----
	engine.commit_player_intent(chase, PlayerIntent.create_track_rumor(id, "rumor:old_well"))
	var loaded := WorldState.from_json_checked(chase.to_canonical_json())
	check(loaded.success, "R6: a world with a chased rumour loads: %s" % String(loaded.get("error", "")))
	if loaded.success:
		check(loaded.world.to_canonical_json() == chase.to_canonical_json(), "R6: byte-identical")
		check(Rumors.tracked(loaded.world) == "rumor:old_well", "R6: the aim survives")

	print("ASP-2 rumors: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
