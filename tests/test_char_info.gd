extends SceneTree

# ==============================================================================
# CHAR-INFO — the creation screen must state what a choice actually DOES
# ==============================================================================
# Hand-play: "資訊也太少可以選了". Backgrounds showed rank bars with no meaning
# attached, and a Trait was a bare word whose one-line explanation was buried in
# a tooltip. The player was choosing blind.
#
#   G1  effects are DERIVED from the encounter catalogue, not written by hand
#   G2  a background states its ranks, what it opens, and what it gives up
#   G3  a trait with no mechanical effect says so instead of implying one
#   G4  a trait with an effect names the exact approach the catalogue declares
#   G5  the screen shows it and keeps up with the player's selection
#   G6  none of this touches the character numeric model
#
# Deliberately NOT here: free point allocation. That would change the frozen
# C0/C1 "2/1/1, no free points" contract and is deferred as CHAR-POINTS.
# ==============================================================================

const Presentation = preload("res://ui/character_presentation.gd")
const Creation = preload("res://ui/character_creation_screen.gd")
const Encounter = preload("res://simulation/travel_encounter.gd")

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("CHAR-INFO: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	# ---- G1 derivation: the index must agree with the catalogue itself ----
	# Independently recount trait-gated options straight from the catalogue, so
	# this expectation does not come from the code under test.
	var expected_trait_options := {}
	for t in [Encounter.WRECK, Encounter.ROCKSLIDE, Encounter.ROADBLOCK,
			Encounter.DEHYDRATED_TRAVELLER, Encounter.REFUGEE_COLUMN]:
		for o in Encounter.options(t):
			for clause in (o.get("requires", {}) as Dictionary).get("all", []):
				if String(clause.get("kind", "")) == "trait_present":
					var tid := String(clause.get("trait_id", ""))
					if not expected_trait_options.has(tid):
						expected_trait_options[tid] = []
					expected_trait_options[tid].append(String(o["label"]))

	check(expected_trait_options.size() > 0, "G1: the catalogue really does gate some options on traits")
	for tid in Presentation.Profile.CORE_TRAITS:
		var derived: Array = Presentation.trait_unlocks(tid)
		var expected: Array = expected_trait_options.get(tid, [])
		check(derived.size() == expected.size(),
			"G1: %s should unlock %d approach(es), derived %d" % [tid, expected.size(), derived.size()])
		for a in derived:
			check(String(a.label) in expected, "G1: %s must not claim an approach the catalogue does not gate on it" % tid)

	# ---- G2 every background states ranks, gains and costs ----
	for bg in Presentation.BACKGROUNDS:
		var pkg: Dictionary = Presentation.Catalogue.resolve(bg)
		check(pkg.success, "G2: %s resolves" % bg)
		var text: String = Presentation.background_effect_text(bg, pkg.ranks)
		check(text.find("起始加成") >= 0, "G2: %s states its starting ranks" % bg)
		check(text.find("玩法") >= 0, "G2: %s states how it plays" % bg)
		check(text.find("路上已經做得到") >= 0, "G2: %s states what it can already do" % bg)
		check(text.find("戰鬥、物品與交易另有規則") >= 0, "G2: %s admits what it does not cover" % bg)
		# the ranks named must be the ranks the authority handed out
		for skill in Presentation.Profile.SKILLS:
			var rank: int = int(pkg.ranks[skill])
			var line := "%s +%d" % [Presentation.SKILL_NAMES[skill], rank]
			if rank > 0:
				check(text.find(line) >= 0, "G2: %s must state %s" % [bg, line])
			else:
				check(text.find("%s +" % Presentation.SKILL_NAMES[skill]) < 0,
					"G2: %s must not claim a bonus in %s" % [bg, skill])

	# A 2/1/1 package cannot reach every approach; the cost has to be visible.
	var guard_pkg: Dictionary = Presentation.Catalogue.resolve("CARAVAN_GUARD")
	var guard_text: String = Presentation.background_effect_text("CARAVAN_GUARD", guard_pkg.ranks)
	check(guard_text.find("代價：這些還做不到") >= 0, "G2: a background with locked doors shows them")

	# ---- G3/G4 traits: honest about doing nothing, exact when doing something ----
	var silent := 0
	var effective := 0
	for tid in Presentation.Profile.CORE_TRAITS:
		var text: String = Presentation.trait_effect_text(tid)
		check(text.find(Presentation.TRAITS[tid][0]) >= 0, "G3: %s names itself" % tid)
		check(text.find(Presentation.TRAITS[tid][1]) >= 0, "G3: %s carries its description" % tid)
		if Presentation.trait_unlocks(tid).is_empty():
			silent += 1
			check(text.find("還沒有專屬的遭遇選項") >= 0,
				"G3: %s has no effect and must say so rather than imply one" % tid)
		else:
			effective += 1
			check(text.find("只有你想得到的做法") >= 0, "G4: %s presents its exclusive approaches" % tid)
			for a in Presentation.trait_unlocks(tid):
				check(text.find(String(a.label)) >= 0, "G4: %s names the approach" % tid)
	check(silent > 0 and effective > 0, "G3/G4: both kinds of trait exist and are covered")

	# ---- G6 first: capture the world before the screen touches anything ----
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	var baseline := world.to_canonical_json()

	# ---- G5 the screen shows it and follows the selection ----
	var ui = Creation.new()
	root.add_child(ui)
	ui.setup(world, engine)

	check(ui.effect_label != null and ui.effect_label.text != "", "G5: the background effect panel is populated on open")
	check(ui.trait_effect_label.text.find("尚未選擇") >= 0, "G5: with no trait chosen the panel says so")

	for bg in Presentation.BACKGROUNDS:
		ui.background_buttons[bg].pressed.emit()
		var pkg2: Dictionary = Presentation.Catalogue.resolve(bg)
		check(ui.effect_label.text == Presentation.background_effect_text(bg, pkg2.ranks),
			"G5: selecting %s shows that background's effects" % bg)

	ui.trait_buttons.RECKLESS.button_pressed = true
	check(ui.trait_effect_label.text.find("直接翻過去") >= 0,
		"G5: choosing the reckless trait shows the approach it unlocks")
	ui.trait_buttons.CAUTIOUS.button_pressed = true
	check(ui.trait_effect_label.text.find("還沒有專屬的遭遇選項") >= 0,
		"G5: a second, effect-less trait is reported honestly alongside the first")
	ui.trait_buttons.RECKLESS.button_pressed = false
	check(ui.trait_effect_label.text.find("直接翻過去") < 0, "G5: deselecting removes that trait's effects")

	# the star marker must mean exactly "this trait has an exclusive approach"
	for tid in Presentation.Profile.CORE_TRAITS:
		var marked: bool = String(ui.trait_buttons[tid].text).find("★") >= 0
		check(marked == (not Presentation.trait_unlocks(tid).is_empty()),
			"G5: the marker on %s must match whether it really unlocks anything" % tid)
		check(String(ui.trait_buttons[tid].text).find(Presentation.TRAITS[tid][0]) >= 0,
			"G5: %s still shows its name" % tid)

	# ---- G6 nothing about the character model moved ----
	check(world.to_canonical_json() == baseline,
		"G6: browsing every background and trait must not touch world state")
	check(world.player == null, "G6: previewing a character does not create one")
	for bg in Presentation.BACKGROUNDS:
		var pkg3: Dictionary = Presentation.Catalogue.resolve(bg)
		var total := 0
		for skill in Presentation.Profile.SKILLS:
			total += int(pkg3.ranks[skill])
		check(total == 4, "G6: %s is still the frozen 2/1/1 package, total %d" % [bg, total])

	if failures == 0:
		print("CHAR-INFO: PASS; assertions=%d; failures=0" % assertions)
		quit(0)
	else:
		print("CHAR-INFO: FAIL; assertions=%d; failures=%d" % [assertions, failures])
		quit(1)
