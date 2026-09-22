extends SceneTree

# ==============================================================================
# DEATH FEEDBACK — the run has to END VISIBLY
# ==============================================================================
# Found by hand-play, not by a suite: a player who died of thirst on day 21 saw
# no message at all. The engine was already correct — every intent from a dead
# player is refused — but the shell dropped the refusal on the floor and left
# every button lit, so death was indistinguishable from a frozen UI.
#
#   G1  the projection reports the death as a fact, read from the receipt
#   G2  the shell shows the ending and disables the controls
#   G3  a refused intent reaches the player instead of being swallowed
#   G4  a living player sees none of it
#   G5  running out of supplies is warned about BEFORE it is fatal
#
# Deliberately NOT here: respawn, save-slot handling, or any change to the
# mortality rules themselves.
# ==============================================================================

const Shell = preload("res://ui/playable_shell.gd")
const CreationIntent = preload("res://simulation/character_creation_intent.gd")

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("DEATH-UI: " + message)

func _init() -> void:
	call_deferred("run")

func make_world(engine: SimulationEngine, water: int, food: int) -> WorldState:
	var w := S1WorldData.create_s1_world()
	engine.commit_character_creation(w, CreationIntent.new({
		"source_settlement_id": "settlement:gray_valley",
		"character_name": "Thirsty Walker", "age": 27,
		"background_id": "SCAVENGER", "trait_ids": []}))
	w.player.inventory.set_amount("water", water)
	w.player.inventory.set_amount("food", food)
	return w

func run() -> void:
	var engine := SimulationEngine.new()

	# ---- G4 first: a living player must see nothing of any of this ----
	var alive_world := make_world(engine, 9, 9)
	var alive_proj := PlayerUIProjection.project(alive_world)
	check(alive_proj.death.is_empty(), "a living player projects no death block")
	check(bool(alive_proj.player.is_alive), "a living player is reported alive")

	var alive_shell = Shell.new()
	root.add_child(alive_shell)
	alive_shell.setup(alive_world, engine)
	check(not alive_shell.death_banner.visible, "no ending banner while alive")
	check(not alive_shell.btn_wait.disabled, "a living player can still act")

	# ---- drive a real death: on the road with an empty pack ----
	var w := make_world(engine, 0, 0)
	var p: PlayerState = w.player
	engine.begin_player_travel(w, PlayerIntent.create_travel(p.npc_id, &"settlement:new_hope"))
	var guard := 0
	while guard < 40:
		guard += 1
		var ls: NpcLifeState = w.npc_life_state_registry.get_life_state(p.npc_id)
		if ls == null or not ls.is_alive():
			break
		if ls.status != NpcLifeState.Status.IN_TRANSIT:
			engine.begin_player_travel(w, PlayerIntent.create_travel(p.npc_id, &"settlement:gray_valley"))
		engine.execute_player_wait(w)
	check(guard < 40, "the empty-pack traveller actually died within the grace window")

	# ---- G1 the death is a projected fact, sourced from the receipt ----
	var proj := PlayerUIProjection.project(w)
	check(not proj.death.is_empty(), "G1: a dead player projects a death block")
	check(String(proj.death.cause) == "dehydration", "G1: cause comes from the receipt, got '%s'" % String(proj.death.cause))
	check(not bool(proj.player.is_alive), "G1: the player is reported dead")
	var receipt_day := -1
	for evt in w.event_log:
		if evt.type == "PLAYER_DIED":
			receipt_day = evt.day
	check(receipt_day >= 0, "G1: a PLAYER_DIED receipt exists")
	check(int(proj.death.day) == receipt_day, "G1: the screen agrees with the receipt about the day")
	check(int(proj.death.days_survived) > 0, "G1: days survived is reported")

	# ---- G2 the shell shows the ending and stops accepting input ----
	var shell = Shell.new()
	root.add_child(shell)
	shell.setup(w, engine)
	check(shell.death_banner.visible, "G2: the ending banner is shown")
	check(shell.lbl_death_title.text.find("旅程結束") >= 0, "G2: the banner names the ending")
	check(shell.lbl_death_body.text.find(str(int(proj.death.days_survived))) >= 0, "G2: the banner states how long the run lasted")
	check(shell.btn_wait.disabled, "G2: waiting is disabled after death")
	check(shell.btn_travel.disabled, "G2: travelling is disabled after death")
	check(shell.field_button.disabled, "G2: the field screen is closed after death")

	# ---- G3 a refused intent is reported, not swallowed ----
	var before := w.to_canonical_json()
	var res: Dictionary = shell.on_wait_pressed()
	check(not res.get("success", false), "G3: the engine still refuses the dead player's intent")
	check(w.to_canonical_json() == before, "G3: a refused intent changes nothing in the world")
	check(shell.lbl_action_error.visible, "G3: the refusal is shown on screen")
	check(shell.lbl_action_error.text.find("已經死了") >= 0,
		"G3: the refusal is stated in plain language, got '%s'" % shell.lbl_action_error.text)
	check(shell.death_banner.visible, "G3: the ending stays on screen after a refused action")

	# ---- G5 the warning arrives BEFORE the death, not after ----
	var warn_world := make_world(engine, 0, 0)
	var wp: PlayerState = warn_world.player
	engine.begin_player_travel(warn_world, PlayerIntent.create_travel(wp.npc_id, &"settlement:new_hope"))
	engine.execute_player_wait(warn_world)
	engine.execute_player_wait(warn_world)
	var warn_shell = Shell.new()
	root.add_child(warn_shell)
	warn_shell.setup(warn_world, engine)
	check(wp.water_exposure > 0.0, "G5: the traveller is genuinely in deficit")
	check(warn_shell.lbl_supply_warning.visible, "G5: a thirsty traveller is warned")
	check(warn_shell.lbl_supply_warning.text.find("脫水") >= 0,
		"G5: the warning names the consequence, got '%s'" % warn_shell.lbl_supply_warning.text)
	check(not warn_shell.death_banner.visible, "G5: warning is not the same thing as death")

	# a well-supplied traveller is not nagged
	var ok_world := make_world(engine, 9, 9)
	var ok_shell = Shell.new()
	root.add_child(ok_shell)
	ok_shell.setup(ok_world, engine)
	check(not ok_shell.lbl_supply_warning.visible, "G5: a well-supplied player gets no warning")

	if failures == 0:
		print("DEATH FEEDBACK UI: PASS; assertions=%d; failures=0" % assertions)
		quit(0)
	else:
		print("DEATH FEEDBACK UI: FAIL; assertions=%d; failures=%d" % [assertions, failures])
		quit(1)
