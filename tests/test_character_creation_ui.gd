extends SceneTree

const Screen = preload("res://ui/character_creation_screen.gd")
const Presentation = preload("res://ui/character_presentation.gd")
var failed := 0
var engine := SimulationEngine.new()

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)

func screen() -> Control:
	var ui := Screen.new()
	root.add_child(ui)
	ui.setup(S1WorldData.create_s1_world(), engine)
	ui.name_input.text = "吳某某"
	return ui

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var ui := screen()
	var baseline: String = ui.world.to_canonical_json()
	# Independent owner-approved package fixtures, including zero-rank skills.
	var expected := {
		"CARAVAN_GUARD": {"FIREARMS": 2, "MELEE": 1, "SURVIVAL": 1},
		"MECHANIC": {"MECHANICS": 2, "ELECTRONICS": 1, "SCAVENGING": 1},
		"FARMER": {"SURVIVAL": 2, "MECHANICS": 1, "BARTER": 1},
		"SCAVENGER": {"SCAVENGING": 2, "SURVIVAL": 1, "STEALTH": 1}}
	for id in expected:
		ui.background_buttons[id].pressed.emit()
		check(ui.background_id == id, "background button selects its package")
		# CHAR-INFO changed the SHAPE of this preview, not its guarantee. A
		# trained skill still shows its own rank row; the untrained ones, which
		# are always seven identical "0 外行" rows for a 2/1/1 package, are named
		# together on one line instead of pushing the rest below the fold. Every
		# skill must still be visible, and no rank may be misstated.
		for skill in Presentation.Profile.SKILLS:
			var rank: int = expected[id].get(skill, 0)
			var skill_name: String = Presentation.SKILL_NAMES[skill]
			check(skill_name in ui.preview.text, "every skill stays visible: " + id + "/" + skill)
			if rank > 0:
				var row := "%s    %s%s    %d  %s" % [skill_name, "■".repeat(rank), "□".repeat(5 - rank), rank, ["外行", "略懂", "熟練"][rank]]
				check(row in ui.preview.text, "visible preview: " + id + "/" + skill)
			else:
				var untrained_row := "%s    %s    0  外行" % [skill_name, "□".repeat(5)]
				check(not (untrained_row in ui.preview.text), "untrained skills do not each take a row: " + id + "/" + skill)
	check(ui.world.to_canonical_json() == baseline, "previews cannot mutate world")
	ui.trait_buttons.CAUTIOUS.button_pressed = true
	ui.trait_buttons.CURIOUS.button_pressed = true
	check(ui.trait_buttons.GREEDY.disabled, "third checkbox must be disabled")
	ui.toggle_trait(true, "GREEDY")
	check(ui.selected_traits == ["CAUTIOUS", "CURIOUS"], "third trait cannot enter intent")
	ui.trait_buttons.CAUTIOUS.button_pressed = false
	check(not ui.trait_buttons.GREEDY.disabled, "deselect restores other choices")
	ui.selected_traits = ["CAUTIOUS", "CURIOUS", "GREEDY"]
	check(not ui.submit().success, "authority rejects injected third trait")
	ui.selected_traits = []
	for text in ["-1", "23.5", "not an age", ""]:
		ui.age_input.text = text
		check(not ui.submit().success, "invalid age rejected: " + text)
		check(ui.world.to_canonical_json() == baseline, "rejected age is atomic")
	ui.age_input.text = "23"
	ui.name_input.text = "  "
	check(not ui.submit().success, "blank name rejected by authority")
	ui.name_input.text = "吳某某"
	ui.select_background("UNKNOWN")
	check(not ui.submit().success, "invalid background rejected by authority")
	check(not ui.error_label.text.is_empty() and ui.form.visible and not ui.summary.visible, "failure remains visible in form")
	check(ui.world.to_canonical_json() == baseline, "invalid forms do not repair or mutate world")
	ui.free()
	var tracks: Array = []
	for traits in [[], ["CAUTIOUS"], ["CAUTIOUS", "CURIOUS"], ["CURIOUS", "CAUTIOUS"]]:
		ui = screen()
		ui.selected_traits = traits.duplicate()
		var population: int = ui.world.get_settlement(&"settlement:gray_valley").population
		var named: int = ui.world.npc_registry.get_named_count_at(&"settlement:gray_valley")
		var sequence: int = ui.world.next_npc_sequence
		ui.submit_button.pressed.emit()
		check(ui.committed and ui.summary.visible and not ui.form.visible, "0/1/2 traits create then stop at summary")
		check(ui.world.get_settlement(&"settlement:gray_valley").population == population, "creation cannot increase population")
		check(ui.world.npc_registry.get_named_count_at(&"settlement:gray_valley") == named + 1 and ui.world.next_npc_sequence == sequence + 1, "exactly one existing resident is named")
		check("吳某某" in ui.summary_label.text and "廢墟拾荒者" in ui.summary_label.text and "搜刮" in ui.summary_label.text, "summary projects committed identity and skills")
		check(engine.validate_invariants(ui.world) == "", "global invariants after UI commit")
		var snapshot: String = ui.world.to_canonical_json()
		check(not ui.submit().success and snapshot == ui.world.to_canonical_json(), "double submit cannot create another character")
		var projected: Dictionary = Presentation.project(ui.world)
		projected.ranks.SCAVENGING = 5
		projected.traits.clear()
		check(ui.world.to_canonical_json() == snapshot, "capability projection is a defensive copy")
		if traits.size() == 2:
			tracks.append(ui.world)
		ui.free()
	check(tracks[0].to_canonical_json().sha256_text() == tracks[1].to_canonical_json().sha256_text(), "UI trait ordering has canonical world SHA")
	tracks[1] = WorldState.from_json(tracks[1].to_canonical_json())
	for w in tracks:
		engine.commit_player_intent(w, PlayerIntent.create_travel(w.player.npc_id, &"settlement:new_hope"))
	for step in range(8):
		if tracks[0].active_encounter == null:
			break
		var options := TravelEncounter.options(tracks[0].active_encounter.encounter_type)
		for w in tracks:
			engine.commit_player_intent(w, PlayerIntent.create_resolve_encounter(w.player.npc_id, options[-1].id))
		tracks[1] = WorldState.from_json(tracks[1].to_canonical_json())
		for w in tracks:
			engine.commit_player_intent(w, PlayerIntent.create_continue_journey(w.player.npc_id, w.pending_encounter_result))
	check(tracks[0].to_canonical_json().sha256_text() == tracks[1].to_canonical_json().sha256_text(), "UI-to-travel/save/load/receipt replay SHA-256")
	for w in tracks:
		check(engine.validate_invariants(w) == "", "replay global invariants")
	print("Character UI replay SHA-256: ", tracks[0].to_canonical_json().sha256_text())
	# Exercise actual production entry and signal connections, not a test-only path.
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	check(main.world.player == null and main.shell == null, "New Game starts without a player or shell")
	main._enter_wasteland()
	check(main.shell == null, "cannot bypass creation by entering directly")
	main.creation.name_input.text = "Production"
	main.creation.submit_button.pressed.emit()
	check(main.shell == null and main.creation.summary.visible, "commit requires separate summary confirmation")
	main.creation.enter_button.pressed.emit()
	check(main.shell != null and main.shell.world.player.capability.to_dict().creation_origin == "CHARACTER_CREATION", "normal New Game uses authoritative intent")
	var production_hash: String = main.world.to_canonical_json()
	main.shell._show_character()
	check(main.world.to_canonical_json() == production_hash, "in-game character sheet is read-only")
	main.creation.enter_button.pressed.emit()
	check(main.world.to_canonical_json() == production_hash, "summary confirm cannot advance time or recreate player")
	main.queue_free()
	await process_frame
	print("Character creation UI gates: ", "PASS" if failed == 0 else "FAIL", "; failures=", failed)
	quit(0 if failed == 0 else 1)
