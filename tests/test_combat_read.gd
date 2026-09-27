extends SceneTree

# ==============================================================================
# COMBAT-READ — the enemy's next move and its damage, before you choose
# ==============================================================================
# Owner ruling (2026-09-27): not a full intent system. Two facts - the next move
# and the damage it will deal - shown where the turn is decided. Everything else
# is a way of making those two facts true:
#
#   G1 Every enemy move has a name, and the heavy blow is the one called heavy
#   G2 THE HARD GATE: the preview is a promise. For every enemy, every command,
#      every turn, the damage shown is the damage the next FIELD_TURN takes -
#      including bracing, the road floor, and an enemy that dies before it swings
#   G3 "It will knock you down" is shown exactly when the turn ends in DEFEAT
#   G4 The battle screen shows it under the enemy bar, and names the real enemy
#      instead of calling every road opponent a bandit
#   G5 No preview outside a battle, and reading it changes nothing
# ==============================================================================

const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Screen = preload("res://ui/field_screen.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("COMBAT-READ: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "Reader",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 9)
	world.player.inventory.set_amount("food", 9)
	return world

func road_battle(world: WorldState, enemy_id: String) -> void:
	var id: StringName = world.player.npc_id
	var route := "WILDERNESS" if enemy_id == Enemies.HEAVY_RAIDER else "HIGHWAY"
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, &"settlement:new_hope", route)).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(
		TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:dry_well", &"settlement:new_hope", 1,
		{"target_enemy": enemy_id})
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"FIGHT")).success, "FIGHT starts the battle")
	check(Field.battle_enemy(world.field_state) == enemy_id, "the battle is against %s" % enemy_id)

func act(world: WorldState, command: String) -> bool:
	var payload := {"command": command, "battle_id": world.field_state.battle.id, "turn": world.field_state.battle.turn}
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload)).success

func last_event(world: WorldState, type: String) -> EventRecord:
	for i in range(world.event_log.size() - 1, -1, -1):
		if world.event_log[i].type == type:
			return world.event_log[i]
	return null

# Plays one scripted fight and holds every preview against the turn it predicted.
func play_script(enemy_id: String, script: Array, start_hp: int, label: String) -> void:
	var world := fresh_world()
	world.player.field_kit.hp = start_hp
	road_battle(world, enemy_id)
	var step := 0
	while not world.field_state.battle.is_empty() and step < 30:
		var command: String = String(script[step % script.size()])
		var preview := Field.intent_preview(world)
		var before := JSON.stringify(world.field_state)
		check(JSON.stringify(Field.intent_preview(world)) == JSON.stringify(preview) and JSON.stringify(world.field_state) == before,
			"G5 %s: reading the preview changes nothing" % label)
		check(act(world, command), "%s turn %d: %s commits" % [label, int(preview.turn), command])
		var turn_event := last_event(world, "FIELD_TURN")
		var taken := int(turn_event.payload.taken)
		var expected := 0
		match command:
			"ATTACK":
				check(int(turn_event.payload.dealt) == mini(int(preview.attack_damage), int(turn_event.payload.enemy_hp) + int(turn_event.payload.dealt)),
					"G2 %s turn %d: attack damage shown is attack damage dealt" % [label, int(preview.turn)])
				expected = 0 if bool(preview.attack_kills) else int(preview.taken)
			"DEFEND":
				expected = int(preview.braced_taken)
		if command != "FLEE":
			check(taken == expected, "G2 %s turn %d %s: shown %d, taken %d" % [label, int(preview.turn), command, expected, taken])
			var ended := last_event(world, "FIELD_RESULT")
			var defeated: bool = world.field_state.battle.is_empty() and ended != null and String(ended.payload.outcome) == "DEFEAT"
			var warned: bool = bool(preview.knocks_down_braced) if command == "DEFEND" else (bool(preview.knocks_down) and not bool(preview.attack_kills))
			check(defeated == warned, "G3 %s turn %d %s: knock-down warning %s, defeat %s" % [label, int(preview.turn), command, warned, defeated])
		step += 1
	# Bracing every turn never ends a fight (against the dog it costs nothing at
	# all) - that is PLAY-4's balance, not this slice's to change.
	if script.has("ATTACK"):
		check(world.field_state.battle.is_empty(), "%s: the fight ended" % label)

func run() -> void:
	# ---- G1 moves are named, and heavy means heavy ----
	for enemy_id in [Enemies.FERAL_DOG, Enemies.BANDIT, Enemies.HEAVY_RAIDER]:
		var heaviest := 0
		for turn in range(1, 10):
			var action := Enemies.action_for(enemy_id, turn)
			check(String(action.get("label_zh", "")) != "", "G1: %s turn %d move has a name" % [enemy_id, turn])
			heaviest = maxi(heaviest, int(action.damage))
			if bool(action.heavy):
				check(int(action.damage) == heaviest, "G1: %s's heavy move is its hardest blow" % enemy_id)
	check(Enemies.action_for(Enemies.HEAVY_RAIDER, 3).label_zh != Enemies.action_for(Enemies.HEAVY_RAIDER, 1).label_zh,
		"G1: the hammer blow is named differently from an ordinary swing")

	# ---- G2/G3 the preview is a promise, across enemies, commands and health ----
	for enemy_id in [Enemies.FERAL_DOG, Enemies.BANDIT, Enemies.HEAVY_RAIDER]:
		play_script(enemy_id, ["ATTACK"], 12, "%s all-in" % enemy_id)
		play_script(enemy_id, ["DEFEND", "ATTACK"], 12, "%s brace-and-hit" % enemy_id)
		play_script(enemy_id, ["DEFEND"], 12, "%s turtle" % enemy_id)
		play_script(enemy_id, ["ATTACK"], 4, "%s low-hp" % enemy_id)
		play_script(enemy_id, ["DEFEND", "ATTACK"], 2, "%s near-dead" % enemy_id)

	# The raider's third turn is the one that matters: the preview must say so
	# in numbers before the player chooses.
	var raider := fresh_world()
	road_battle(raider, Enemies.HEAVY_RAIDER)
	act(raider, "DEFEND")
	act(raider, "DEFEND")
	var hammer := Field.intent_preview(raider)
	check(int(hammer.turn) == 3 and bool(hammer.heavy), "G1: turn 3 previews the hammer blow")
	check(int(hammer.damage) == 9 and int(hammer.damage) - int(hammer.braced_damage) == Enemies.BRACE_REDUCTION_HEAVY,
		"G2: the hammer is shown at its full weight, and bracing it saves the heavy reduction")
	# The blow shown is the blow, even when the road floor means it takes less
	# off you; hiding a 9 behind a 5 is what made the first capture contradict itself.
	raider.player.field_kit.hp = 6
	var floored := Field.intent_preview(raider)
	check(int(floored.damage) == 9 and int(floored.taken) == 5 and bool(floored.knocks_down),
		"G2: at 6 HP the hammer still reads 9 and warns it will knock you down")

	# ---- G5 no battle, no preview ----
	check(Field.intent_preview(fresh_world()).is_empty(), "G5: no preview outside a battle")

	# ---- G4 the screen shows it where the turn is decided ----
	var screen_world := fresh_world()
	road_battle(screen_world, Enemies.HEAVY_RAIDER)
	var screen := Screen.new()
	root.add_child(screen)
	screen.setup(screen_world, engine)
	await process_frame
	check(screen.intent_label != null and screen.intent_label.visible, "G4: the intent line is visible during a battle")
	check(screen.intent_label.text.contains("下一步") and screen.intent_label.text.contains("揮擊") and screen.intent_label.text.contains("3 傷害"),
		"G4: the intent line names the move and its damage: %s" % screen.intent_label.text)
	check(screen.intent_detail_label.text.contains("架勢防禦") and screen.intent_detail_label.text.contains("攻擊"),
		"G4: bracing and attacking are both priced")
	check(screen.intent_label.get_parent() == screen.enemy_bar.get_parent().get_parent(), "G4: the intent line sits with the enemy bar")
	check(screen.heading_label.text.contains("重裝掠奪者"), "G4: the heading names the raider, not a bandit")
	act(screen_world, "FLEE")
	screen.refresh()
	await process_frame
	check(not screen.intent_label.visible, "G4: the intent line hides once the battle is over")
	check(not screen.log_label.text.contains("劫匪"), "G4: the result does not call the raider a bandit: %s" % screen.log_label.text)
	screen.queue_free()

	print("COMBAT-READ: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
