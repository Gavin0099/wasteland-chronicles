extends SceneTree

# ==============================================================================
# TRAIN-1: MONEY INTO GROWTH
# ==============================================================================
# Lunatic Dawn pillar 6: money has to become strength, or earning it stops
# meaning anything once the few weapons are bought.
#
#   K1 Each town teaches what it lives by - two skills, no overlaps, no STEALTH
#   K2 A lesson costs caps and days and raises the rank; teachers stop at 熟練
#   K3 Refused in the wrong town, on the road, without the money, or where the
#      town has turned on you - by the engine, not only the screen
#   K4 It opens things: two lessons in Gray Valley open the armory door, and
#      the rumour says where the skill is taught
#   K5 Growth points and practice are untouched: this is a third road, not a
#      replacement
#   K6 The player sees it: a 找師傅 button in town, prices and reasons; saves
# ==============================================================================

const Training = preload("res://simulation/training.gd")
const RoadPlaces = preload("res://simulation/road_places.gd")
const Rumors = preload("res://simulation/rumors.gd")
const GrowthPoints = preload("res://simulation/growth_points.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("TRAIN-1: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(origin: String = "settlement:gray_valley") -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "Pupil",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = 300
	return world

func train(world: WorldState, skill: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_train_skill(world.player.npc_id, skill))

func run() -> void:
	# ---- K1 what each town teaches ----
	var taught := {}
	for town in Training.TEACHERS:
		check(Training.TEACHERS[town].size() == (3 if town == "settlement:gray_valley" else 2), "K1: industrial Gray Valley adds electronics; other towns retain two skills")
		for skill in Training.TEACHERS[town]:
			check(not taught.has(skill), "K1: %s is taught in only one town" % skill)
			check(GrowthPoints.is_spendable(skill), "K1: %s is a skill the world asks for" % skill)
			taught[skill] = town
	check(not taught.has("STEALTH"), "K1: stealth is learned by doing, not taught")

	# ---- K2 a lesson ----
	var world := fresh_world()
	world.player.capability._data.skill_ranks["MECHANICS"] = 0
	var day0 := world.current_day
	var money0 := world.player.money
	var first := train(world, "MECHANICS")
	check(first.success, "K2: learn mechanics from the old welder: %s" % first.get("error", ""))
	check(world.player.capability.get_rank("MECHANICS") == 1, "K2: mechanics is now 1")
	check(money0 - world.player.money == Training.price(1), "K2: it cost %d caps" % Training.price(1))
	check(world.current_day == day0 + Training.LESSON_DAYS, "K2: and %d days" % Training.LESSON_DAYS)
	var receipt: EventRecord = null
	for event in world.event_log:
		if event.type == "SKILL_TRAINED":
			receipt = event
	check(receipt != null and String(receipt.payload.skill_id) == "MECHANICS" and int(receipt.payload.to_rank) == 1, "K2: a SKILL_TRAINED receipt names it")
	check(train(world, "MECHANICS").success and world.player.capability.get_rank("MECHANICS") == 2, "K2: the second lesson reaches 熟練")
	var third := train(world, "MECHANICS")
	check(not third.success and String(third.error) == "BEYOND_TEACHER", "K2: the teacher stops at 熟練: %s" % third.get("error", ""))

	# ---- K3 refusals ----
	var elsewhere := fresh_world("settlement:dry_well")
	var wrong := train(elsewhere, "MECHANICS")
	check(not wrong.success and String(wrong.error) == "NOT_TAUGHT_HERE", "K3: Dry Well does not teach mechanics")
	var poor := fresh_world()
	poor.player.money = 10
	poor.player.capability._data.skill_ranks["MECHANICS"] = 0
	var broke := train(poor, "MECHANICS")
	check(not broke.success and String(broke.error) == "INSUFFICIENT_FUNDS", "K3: not without the money")
	check(poor.player.money == 10 and poor.current_day == 0, "K3: a refused lesson costs nothing")
	var road := fresh_world()
	engine.commit_player_intent(road, PlayerIntent.create_travel(road.player.npc_id, &"settlement:dry_well"))
	if road.active_encounter == null and road.pending_encounter_result < 0:
		pass
	var moving := train(road, "MECHANICS")
	check(not moving.success, "K3: not while on the road or answering it: %s" % moving.get("error", ""))
	var shunned := fresh_world()
	shunned.record_event(EventRecord.new(shunned.current_day, "JOB_BETRAYED", shunned.player.npc_id, &"settlement:gray_valley",
		{"quest_id": "job_gray_valley_consign_0", "settlement_id": "settlement:gray_valley", "resource": "scrap", "quantity": 2}))
	var shut := train(shunned, "MECHANICS")
	check(not shut.success and String(shut.error) == "TOWN_DISTRUSTS_YOU", "K3: a town that has turned on you will not teach you")

	# ---- K4 it opens things ----
	var seeker := fresh_world()
	seeker.player.capability._data.skill_ranks["MECHANICS"] = 0
	check(Rumors.progress(seeker, "rumor:armory").next.contains("老焊工") or not Rumors.heard(seeker, "rumor:armory"), "K4: the armory rumour says who teaches mechanics")
	check(String(Rumors.progress(seeker, "rumor:armory").next).contains("灰谷的老焊工"), "K4: it names the teacher's town")
	train(seeker, "MECHANICS")
	train(seeker, "MECHANICS")
	var gate: Dictionary = seeker.player.capability.meets_skill_requirement("MECHANICS", RoadPlaces.ARMORY_MECHANICS)
	check(gate.success and gate.met, "K4: two lessons meet the armory door's requirement")
	check(String(Rumors.progress(seeker, "rumor:armory").next).contains("荒野路"), "K4: and the rumour now says which road to take")

	# ---- K5 the other roads are untouched ----
	check(GrowthPoints.available(world) == GrowthPoints.earned_for_xp(int(world.player.xp)), "K5: no growth point was spent on a lesson")
	var spent := 0
	for event in world.event_log:
		if event.type == "SKILL_POINT_SPENT":
			spent += 1
	check(spent == 0, "K5: lessons are not SKILL_POINT_SPENT receipts")

	# ---- K6 the player sees it ----
	var shown := fresh_world()
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(shown, engine)
	await process_frame
	check(shell.btn_local_train != null and shell.btn_local_train.visible, "K6: a 找師傅 button in town")
	shell._show_training()
	await process_frame
	check(shell.training_buttons.has("MECHANICS") and shell.training_buttons.has("SCAVENGING"), "K6: Gray Valley's two teachers are listed")
	check(String(shell.training_buttons["MECHANICS"].text).contains("%d 瓶蓋" % Training.price(1)), "K6: with the price: %s" % shell.training_buttons["MECHANICS"].text)
	check(not shell.training_buttons["MECHANICS"].disabled, "K6: and open to a player who can pay")
	shell.training_buttons["MECHANICS"].pressed.emit()
	check(shown.player.capability.get_rank("MECHANICS") >= 1, "K6: pressing it takes the lesson")
	shell.queue_free()
	var loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success, "K6: a world with lessons loads: %s" % String(loaded.get("error", "")))
	if loaded.success:
		check(loaded.world.to_canonical_json() == world.to_canonical_json(), "K6: byte-identical")
		check(loaded.world.player.capability.get_rank("MECHANICS") == 2, "K6: the trained rank survives")

	print("TRAIN-1 teachers: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
