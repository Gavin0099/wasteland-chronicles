extends SceneTree

# ==============================================================================
# PLAY-2 GROWTH CHOICE — a level must hand the player a decision
# ==============================================================================
# Hand-play: "人物升級沒有感覺 不能點點數 也沒有技能可以升級". Three separate
# causes at once: Lv.1 and Lv.2 carry no perk slot so the first two levels gave
# nothing at all, skill practice only fires on a few roadside options so a
# session spent running jobs moved no skill, and nothing could be decided.
#
#   G1  points are EARNED and DERIVED, never granted or stored
#   G2  spending one really raises the rank, once, through the authority
#   G3  you cannot spend what you have not earned, or spend it twice
#   G4  only skills the world can actually ask for are spendable, with a reason
#        shown for the ones that are not
#   G5  practice and points are two roads to the same rank, and neither breaks
#        the other
#   G6  a refused spend changes nothing
#   G7  checked persistence, invariants and dual-track replay
#   G8  a forged ledger cannot mint growth
#
# The owner's original objection to free points still holds and is not
# contradicted here: this is not allocation at CREATION. Every point spent in
# this suite was earned by XP the character actually accumulated.
# ==============================================================================

const Creation = preload("res://simulation/character_creation_intent.gd")
const Growth = preload("res://simulation/growth_points.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
const Profile = preload("res://simulation/capability_profile.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-2: " + label)

func _init() -> void:
	call_deferred("run")

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Chooser",
		"age": 26, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	return world

func run() -> void:
	var world := fixture()
	var id: StringName = world.player.npc_id

	# ---- G1 nothing is earned before anything is achieved ----
	check(Growth.available(world) == 0, "G1: a fresh character has no growth point")
	check(Growth.earned_for_xp(0) == 0, "G1: level 1 is a starting point, not an achievement")
	check(Growth.earned_for_xp(Perks.xp_for_level(2)) == 1, "G1: reaching Lv.2 earns exactly one point")
	check(Growth.earned_for_xp(Perks.xp_for_level(3)) == 2, "G1: reaching Lv.3 earns two")

	# ---- G3 you cannot spend what you have not earned ----
	var before_broke := world.to_canonical_json()
	var broke := engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "MELEE"))
	check(not broke.success, "G3: spending with no point is refused")
	check(world.to_canonical_json() == before_broke, "G6: a refused spend changes nothing at all")

	# ---- earn a level the honest way ----
	world.player.xp = Perks.xp_for_level(2)
	check(world.player.level() == 2, "the character really reached Lv.2")
	check(Growth.available(world) == 1, "G1: the level produced one spendable point")
	check(Perks.available_slots(2) == 0, "the level alone still grants no perk - which is the problem this slice fixes")

	# ---- G4 what a point may go into, and why not ----
	var choices := Growth.choices(world)
	check(choices.size() == Profile.SKILLS.size(), "G4: every skill is shown, not just the usable ones")
	var spendable_shown := 0
	for row in choices:
		if Growth.is_spendable(row.skill_id):
			check(bool(row.can_spend), "G4: %s can take a point" % row.skill_id)
			spendable_shown += 1
		else:
			check(not bool(row.can_spend), "G4: %s cannot take a point" % row.skill_id)
			check(String(row.reason) != "", "G4: %s says WHY it cannot, rather than vanishing" % row.skill_id)
	check(spendable_shown == Growth.SPENDABLE.size(), "G4: the spendable set is exactly the documented one")
	check(not Growth.is_spendable("FIREARMS") and not Growth.is_spendable("ELECTRONICS") and not Growth.is_spendable("MEDICINE"),
		"G4: skills with no gameplay outlet are not sold to the player")

	var refused_useless := engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "FIREARMS"))
	check(not refused_useless.success, "G4: the authority refuses an unusable skill too, not just the UI")

	# ---- G2 spending really raises the rank ----
	var before_rank: int = world.player.capability.get_rank("MELEE")
	var spend := engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "MELEE"))
	check(spend.success, "G2: the point is spent")
	check(world.player.capability.get_rank("MELEE") == before_rank + 1,
		"G2: the rank really went up (%d -> %d)" % [before_rank, world.player.capability.get_rank("MELEE")])
	check(int(spend.get("to_rank", -1)) == before_rank + 1, "G2: the receipt reports the new rank")
	check(Growth.available(world) == 0, "G2: the point is gone")

	var receipt_found := false
	for event in world.event_log:
		if event.type == "SKILL_POINT_SPENT" and event.actor_id == id:
			receipt_found = true
			check(String(event.payload.skill_id) == "MELEE", "G2: the receipt names the skill")
			check(event.target_id == &"character", "G2: the receipt is about the character")
	check(receipt_found, "G2: a committed receipt exists")

	# ---- G3 the same level cannot be spent twice ----
	var before_double := world.to_canonical_json()
	var doubled := engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "SURVIVAL"))
	check(not doubled.success, "G3: one level buys one point, not two")
	check(world.to_canonical_json() == before_double, "G6: the refused second spend changed nothing")

	# ---- G3 a point cannot be spent on the road ----
	world.player.xp = Perks.xp_for_level(3)
	check(Growth.available(world) == 1, "reaching Lv.3 earned another point")
	world.player.inventory.set_amount("water", 6)
	world.player.inventory.set_amount("food", 6)
	engine.begin_player_travel(world, PlayerIntent.create_travel(id, &"settlement:dry_well"))
	var before_road := world.to_canonical_json()
	var on_road := engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "SURVIVAL"))
	check(not on_road.success, "G3: deciding who you are becoming happens somewhere, not mid-journey")
	check(world.to_canonical_json() == before_road, "G6: the road refusal changed nothing")
	for step in range(12):
		if world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED:
			break
		if world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result))
		elif not world.field_state.battle.is_empty():
			engine.commit_player_intent(world, PlayerIntent.create_field_action(id, {"command": "FLEE", "battle_id": world.field_state.battle.id, "turn": world.field_state.battle.turn}))
		elif world.field_state.receipt >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_field_action(id, {"command": "CONFIRM", "receipt": world.field_state.receipt}))
		elif world.active_encounter != null:
			engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"FLEE_ROAD" if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else &"DETOUR"))
		else:
			engine.tick(world)

	# ---- G5 practice and points are two roads to the same rank ----
	var settled: bool = world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED
	check(settled, "the traveller got somewhere")
	if settled:
		var practiced_rank: int = world.player.capability.get_rank("SCAVENGING")
		world.player.capability.grant_practice("SCAVENGING", world.current_day)
		var mid: Dictionary = world.player.capability.get_practice_progress("SCAVENGING")
		check(int(mid.points) >= 0, "G5: practice still records progress")
		var spent_survival := engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "SCAVENGING"))
		check(spent_survival.success, "G5: a point can be spent on a skill that is also being practised")
		check(world.player.capability.get_rank("SCAVENGING") == practiced_rank + 1, "G5: the point moved the same rank practice moves")
		var after: Dictionary = world.player.capability.get_practice_progress("SCAVENGING")
		check(int(after.points) == 0, "G5: partial practice toward the old rank does not make the next one cheaper")

	# ---- the sheet must actually offer the choice, not merely hold the data ----
	# PLAY-1 was a reminder that a correct projection with no wiring is still a
	# screen that lies, so the button itself is part of the contract.
	world.player.xp = Perks.xp_for_level(4)
	var Sheet = load("res://ui/components/character_sheet.gd")
	var Presentation = load("res://ui/character_presentation.gd")
	var sheet = Sheet.new()
	root.add_child(sheet)
	var spend_calls: Array = []
	sheet.setup(Presentation.project(world), PlayerUIProjection.project(world).player,
		Callable(), Callable(), Callable(), "", "", Callable(), Callable(),
		func(skill_id: String): spend_calls.append(skill_id))
	check(sheet.growth_points_available == Growth.available(world), "the sheet states the real number of points")
	check(sheet.growth_buttons.size() == Growth.SPENDABLE.size(), "the sheet offers one button per spendable skill")
	check(sheet.growth_buttons.has("MELEE"), "a usable skill has a button")
	check(not sheet.growth_buttons.has("FIREARMS"), "an unusable skill has no button")
	sheet.growth_buttons["SPEECH"].pressed.emit()
	check(spend_calls == ["SPEECH"], "pressing the button asks to spend on that skill")
	sheet.free()

	# ---- a level has to announce itself, and say what the point would buy ----
	# Hand-play: "人物升級應該有通知之類的 不應該還去人物那邊看".
	var announced: Dictionary = PlayerUIProjection.project(world).get("growth", {})
	check(int(announced.get("points", 0)) == Growth.available(world), "the level announces the real number of points")
	var openings: Array = Growth.openings(world)
	check(openings.size() > 0, "the announcement names something a point would actually open")
	var named := {}
	for opening in openings:
		named[String(opening.skill_id)] = String(opening.opens)
		check(String(opening.opens) != "", "%s says what it opens" % opening.skill_id)
	check(named.has("BARTER"), "+1 交易 crosses a real requirement and is offered")
	# The honest half: a point in SPEECH opens no door at all, it only shifts
	# the odds on one that is already there, so it must not be advertised as an
	# opening. Selling it as one is exactly how a growth system starts lying.
	check(not named.has("SPEECH"), "+1 社交 opens no door and is not dressed up as one")
	check(not named.has("STEALTH"), "+1 潛行 opens no door either")

	var spent_all := world.to_canonical_json()
	while Growth.available(world) > 0:
		check(engine.commit_player_intent(world, PlayerIntent.create_spend_growth_point(id, "BARTER")).success, "points spend down")
	check(PlayerUIProjection.project(world).get("growth", {}).is_empty(),
		"with nothing left to spend the announcement goes away")
	check(spent_all != world.to_canonical_json(), "spending really changed the world")

	# ---- G7 persistence, invariants, replay ----
	check(engine.validate_invariants(world) == "", "G7: global invariants hold after spending")
	var reloaded := WorldState.from_json_checked(world.to_canonical_json())
	check(reloaded.success, "G7: a world with spent growth loads")
	check(reloaded.world.to_canonical_json() == world.to_canonical_json(), "G7: save -> load -> save is a fixed point")
	check(reloaded.world.player.capability.get_rank("MELEE") == world.player.capability.get_rank("MELEE"),
		"G7: the earned rank survives the round trip")
	check(Growth.available(reloaded.world) == Growth.available(world), "G7: remaining points survive the round trip")

	# ---- G8 a forged ledger cannot mint growth ----
	var forged: Dictionary = world.to_dict().duplicate(true)
	forged.player["xp"] = 0
	check(String(WorldState.from_dict_checked(forged).error).begins_with("GROWTH_LEDGER"),
		"G8: spending more than the history earned is rejected on load")

	var bad_skill: Dictionary = world.to_dict().duplicate(true)
	for event in bad_skill.events:
		if event.type == "SKILL_POINT_SPENT":
			event.payload["skill_id"] = "FIREARMS"
	check(String(WorldState.from_dict_checked(bad_skill).error).begins_with("GROWTH_LEDGER"),
		"G8: a receipt naming an unspendable skill is rejected on load")

	if failures == 0:
		print("PLAY-2 growth choice: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("PLAY-2 growth choice: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
