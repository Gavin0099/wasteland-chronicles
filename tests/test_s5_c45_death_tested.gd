extends SceneTree

# ==============================================================================
# S5-C4.5 DEATH_TESTED — 見過底的人
# ==============================================================================
# The third source of emergent identity, after salvage and helping: danger.
#
# OWNER CONSTRAINT, and the whole point of this slice: no combat stat bonus.
# "Got hurt N times -> +5% defence" is the traditional RPG answer and it turns
# an identity back into a passive buff. What experience actually buys here is
# JUDGEMENT: a survivor who has really been beaten to their last point of
# health can do the arithmetic of the next fight before committing to it. It
# changes decision quality, never success rate - the same knowledge-perk model
# as SCAVENGER_INSTINCT and KNOWN_HELPER.
#
#   G1  the predicate rests only on committed FIELD_TURN / FIELD_RESULT facts
#   G2  distinct days, not distinct turns or battles
#   G3  a comfortable win, an unhurt turn, and dying do not qualify
#   G4  qualification alone changes nothing; the survivor opts in
#   G5  the knowledge appears only once owned, and only before a fight
#   G6  NOTHING about combat changes: same damage, same turns, same outcome
#   G7  the forecast is true - what it predicted is what the fight did
#   G8  checked persistence, invariants and dual-track replay
#   G9  an acceptance cannot be backdated ahead of its evidence
# ==============================================================================

const Creation = preload("res://simulation/character_creation_intent.gd")
const Acquired = preload("res://simulation/acquired_traits.gd")
const Field = preload("res://simulation/field_adventure.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("S5-C4.5 death tested: " + label)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Edge Walker",
		"age": 34, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "normal character creation succeeds")
	return world

func fields(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload.battle_id = world.field_state.battle.id
		payload.turn = world.field_state.battle.turn
	if command == "CONFIRM":
		payload.receipt = world.field_state.receipt
	return payload

func act(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, fields(world, command)))

func drive_home(world: WorldState, id: StringName) -> void:
	for step in range(14):
		if world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED:
			break
		if world.field_state.receipt >= 0:
			act(world, "CONFIRM")
		elif not world.field_state.battle.is_empty():
			act(world, "FLEE")
		elif world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result))
		elif world.active_encounter != null:
			var escape: StringName = &"FLEE_ROAD" if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else (&"DETOUR" if world.active_encounter.encounter_type in [TravelEncounter.ROCKSLIDE, TravelEncounter.ROADBLOCK] else &"LEAVE")
			engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, escape))
		else:
			engine.tick(world)
	check(world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED, "journey returns to settlement")

# Stage one ambush. `hp` is fixture setup - the point is to reach the edge, not
# to prove that a fresh caravan guard can be beaten by one bandit.
func ambush(world: WorldState, hp: int) -> StringName:
	var id: StringName = world.player.npc_id
	var origin: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var dest := &"settlement:dry_well" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = 50
	world.player.field_kit.hp = hp
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, dest)).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, origin, dest, 1)
	return dest

# Fight all out until the battle ends, and report what really happened.
func fight_to_the_end(world: WorldState) -> Dictionary:
	var id: StringName = world.player.npc_id
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"FIGHT")).get("success", false), "FIGHT hands off to combat")
	var turns := 0
	var lowest := Field.MAX_HP
	while not world.field_state.battle.is_empty() and turns < 12:
		turns += 1
		check(act(world, "ATTACK").success, "attack commits")
		lowest = mini(lowest, int(world.player.field_kit.hp))
	var receipt: EventRecord = world.event_log[world.field_state.receipt] if world.field_state.receipt >= 0 else null
	return {
		"turns": turns,
		"lowest": lowest,
		"outcome": String(receipt.payload.get("outcome", "")) if receipt != null else "",
		"hp": int(world.player.field_kit.hp),
	}

# Every FIELD_TURN / FIELD_RESULT fact, as the combat really produced it.
func combat_trace(world: WorldState, id: StringName) -> Array:
	var trace: Array = []
	for event in world.event_log:
		if event.actor_id != id:
			continue
		if event.type == "FIELD_TURN":
			trace.append([event.day, "TURN", int(event.payload.get("dealt", -1)), int(event.payload.get("taken", -1)),
				int(event.payload.get("hp", -1)), int(event.payload.get("enemy_hp", -1))])
		elif event.type == "FIELD_RESULT":
			trace.append([event.day, "RESULT", String(event.payload.get("outcome", "")), int(event.payload.get("hp", -1))])
	return trace

func run_life(world: WorldState) -> void:
	var id: StringName = world.player.npc_id

	# ---- G5 (negative) the knowledge is not there before it is earned ----
	ambush(world, 3)
	check(PlayerUIProjection.project(world).active_encounter.get("risk_preview", {}).is_empty(),
		"G5: an unearned identity forecasts nothing")

	# ---- G7 the forecast must be TRUE, so take it before the fight ----
	var predicted: Dictionary = WorldState.Field.forecast(world, true)
	check(not predicted.is_empty(), "a forecast can be computed")
	var before_forecast := world.to_canonical_json()
	WorldState.Field.forecast(world, true)
	check(world.to_canonical_json() == before_forecast, "G5: forecasting mutates nothing")

	var first := fight_to_the_end(world)
	check(first.lowest == 1 and first.outcome == "DEFEAT", "G1: the fixture really reaches the last point of health")
	check(int(predicted.hp_after) == first.hp,
		"G7: the forecast predicted the ending health exactly (said %d, was %d)" % [int(predicted.hp_after), first.hp])
	check(bool(predicted.beaten), "G7: the forecast said this fight would end badly, and it did")
	check(not Acquired.candidates(world.event_log, id, world.current_day).has("DEATH_TESTED"),
		"G2: one day at the edge is not yet the identity")
	drive_home(world, id)

	# ---- G2 a second, separate day ----
	ambush(world, 3)
	var second := fight_to_the_end(world)
	check(second.lowest == 1, "the second fixture also reaches the edge")
	drive_home(world, id)
	check(Acquired.candidates(world.event_log, id, world.current_day).has("DEATH_TESTED"),
		"G2: two distinct days at the edge create the candidate")

	# ---- G1/G2/G3 boundaries on forged ledgers, not on the live world ----
	var edge_turn: EventRecord = null
	var survived: EventRecord = null
	for event in world.event_log:
		if event.actor_id != id:
			continue
		if event.type == "FIELD_TURN" and int(event.payload.get("hp", -1)) == 1 and int(event.payload.get("taken", 0)) >= 1:
			edge_turn = event
		elif event.type == "FIELD_RESULT":
			survived = event
	check(edge_turn != null and survived != null, "real edge and result receipts exist for the boundary checks")
	if edge_turn != null and survived != null:
		var one_day: Array[EventRecord] = []
		for _i in range(5):
			one_day.append(EventRecord.new(9, edge_turn.type, id, edge_turn.target_id, edge_turn.payload.duplicate(true)))
		one_day.append(EventRecord.new(9, survived.type, id, survived.target_id, survived.payload.duplicate(true)))
		check(not Acquired.candidates(one_day, id, 12).has("DEATH_TESTED"),
			"G2: five desperate turns in one battle are one day at the edge, not five")

		var two_days: Array[EventRecord] = []
		for day in [9, 10]:
			two_days.append(EventRecord.new(day, edge_turn.type, id, edge_turn.target_id, edge_turn.payload.duplicate(true)))
			two_days.append(EventRecord.new(day, survived.type, id, survived.target_id, survived.payload.duplicate(true)))
		check(Acquired.candidates(two_days, id, 12).has("DEATH_TESTED"), "G2: two distinct days qualify")

		# Standing on 1 HP without being hit is not being beaten to the edge.
		var unhurt: Array[EventRecord] = []
		for day in [9, 10]:
			var payload: Dictionary = edge_turn.payload.duplicate(true)
			payload["taken"] = 0
			unhurt.append(EventRecord.new(day, edge_turn.type, id, edge_turn.target_id, payload))
			unhurt.append(EventRecord.new(day, survived.type, id, survived.target_id, survived.payload.duplicate(true)))
		check(not Acquired.candidates(unhurt, id, 12).has("DEATH_TESTED"),
			"G3: a turn that took no damage is not a brush with the end")

		# A comfortable fight never reaches the edge at all.
		var comfortable: Array[EventRecord] = []
		for day in [9, 10]:
			var payload2: Dictionary = edge_turn.payload.duplicate(true)
			payload2["hp"] = 7
			comfortable.append(EventRecord.new(day, edge_turn.type, id, edge_turn.target_id, payload2))
			comfortable.append(EventRecord.new(day, survived.type, id, survived.target_id, survived.payload.duplicate(true)))
		check(not Acquired.candidates(comfortable, id, 12).has("DEATH_TESTED"),
			"G3: winning comfortably teaches this nothing")

		# Reaching the edge and NOT walking away is not surviving it.
		var died: Array[EventRecord] = []
		for day in [9, 10]:
			var payload3: Dictionary = survived.payload.duplicate(true)
			payload3["outcome"] = "DEAD"
			died.append(EventRecord.new(day, edge_turn.type, id, edge_turn.target_id, edge_turn.payload.duplicate(true)))
			died.append(EventRecord.new(day, survived.type, id, survived.target_id, payload3))
		check(not Acquired.candidates(died, id, 12).has("DEATH_TESTED"),
			"G3: the identity is surviving the edge, not reaching it")

	# ---- G4 opt-in, and G6 measured across the exact moment of acceptance ----
	check(not world.player.has_acquired_trait("DEATH_TESTED"), "G4: qualifying does not auto-grant the identity")
	# The identity cannot be injected: a trait without its receipt fails the
	# ledger invariant. So the honest way to prove it moves no combat number is
	# to read the combat functions either side of the acceptance itself, with
	# nothing else about the character changed.
	var damage_before: int = Field.attack_damage(world)
	var hp_before: int = world.player.field_kit.hp
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DEATH_TESTED")).success,
		"G4: the qualified survivor opts in at a settlement")
	check(Field.attack_damage(world) == damage_before,
		"G6: accepting the identity did not change what the character hits for")
	check(world.player.field_kit.hp == hp_before, "G6: accepting the identity did not heal anyone")
	check(Field.MAX_HP == 12 and Field.ENEMY_HP == 8, "G6: the identity did not move the combat constants")
	check(world.player.has_acquired_trait("DEATH_TESTED"), "G4: the identity is owned")
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "DEATH_TESTED")).success,
		"G4: the same identity cannot be taken twice")

	# ---- G5 the knowledge, and only where it belongs ----
	ambush(world, 9)
	var projected: Dictionary = PlayerUIProjection.project(world).active_encounter
	var risk: Dictionary = projected.get("risk_preview", {})
	check(not risk.is_empty(), "G5: the identity forecasts the fight in front of it")
	check(int(risk.turns) == int(ceil(float(Field.ENEMY_HP) / float(Field.attack_damage(world)))),
		"G5: the forecast counts turns from the real attack function")
	check(int(risk.hp) == int(world.player.field_kit.hp), "G5: the forecast states the real current health")
	check(projected.get("search_preview", {}).is_empty() and projected.get("help_preview", {}).is_empty(),
		"G5: reading a fight says nothing about wrecks or people")

	# ---- G7 again, this time on a fight that is survivable ----
	var forecast_before: Dictionary = WorldState.Field.forecast(world, true)
	var third := fight_to_the_end(world)
	check(third.outcome == "VICTORY", "the healthier fixture wins")
	check(int(forecast_before.turns) == third.turns,
		"G7: the forecast predicted the number of turns exactly (said %d, took %d)" % [int(forecast_before.turns), third.turns])
	check(int(forecast_before.hp_after) == third.hp,
		"G7: the forecast predicted the ending health exactly (said %d, was %d)" % [int(forecast_before.hp_after), third.hp])
	check(not bool(forecast_before.beaten), "G7: the forecast said this one was winnable, and it was")
	drive_home(world, id)

	# ---- G5 the knowledge does not leak into encounters it has no claim on ----
	var from_id: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var to_id := &"settlement:dry_well" if from_id == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.set_amount("water", 6)
	world.player.inventory.set_amount("food", 6)
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, to_id)).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, from_id, to_id, 1)
	check(PlayerUIProjection.project(world).active_encounter.get("risk_preview", {}).is_empty(),
		"G5: a wreck is not a fight and gets no forecast")
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"LEAVE")).success, "wreck is left alone")
	drive_home(world, id)

func _init() -> void:
	# ---- G6 every blow must come from the trait-free combat functions ----
	# An identity that secretly nudged a number would show up here as a turn
	# whose damage does not match what the public functions say it should be.
	var audited := fixture()
	ambush(audited, 9)
	var per_hit: int = Field.attack_damage(audited)
	fight_to_the_end(audited)
	var turn_index := 0
	var enemy_left: int = Field.ENEMY_HP
	for entry in combat_trace(audited, audited.player.npc_id):
		if entry[1] != "TURN":
			continue
		turn_index += 1
		# The killing blow is clamped to what the enemy has left, so the last
		# turn deals less than a full hit. Anything else would be a hidden bonus.
		var expected_dealt: int = mini(per_hit, enemy_left)
		check(entry[2] == expected_dealt,
			"G6: turn %d dealt exactly what attack_damage() allows (%d, expected %d)" % [turn_index, entry[2], expected_dealt])
		enemy_left -= entry[2]
		check(entry[5] == enemy_left, "G6: turn %d leaves the enemy where the arithmetic says" % turn_index)
		var expected_taken: int = Field.enemy_damage(turn_index) if entry[5] > 0 else 0
		check(entry[3] == expected_taken,
			"G6: turn %d took exactly what enemy_damage() says (%d, expected %d)" % [turn_index, entry[3], expected_taken])
	check(turn_index > 0, "G6: the audited fight actually happened")

	# ---- the real life, run twice for G8 ----
	var first := fixture()
	var replay: WorldState = WorldState.from_json_checked(first.to_canonical_json()).world
	for world in [first, replay]:
		run_life(world)
		check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success,
			"G8: checked save and global invariants hold")
	check(first.to_canonical_json().sha256_text() == replay.to_canonical_json().sha256_text(),
		"G8: two full-world replays have identical SHA-256")

	var forged: Dictionary = first.to_dict().duplicate(true)
	for event in forged.events:
		if event.type == "ACQUIRED_TRAIT_ACCEPTED" and event.payload.get("trait_id") == "DEATH_TESTED":
			event.day = 0
	check(String(WorldState.from_dict_checked(forged).error).begins_with("ACQUIRED_TRAIT_LEDGER"),
		"G9: an acceptance cannot be backdated ahead of the danger that earned it")

	print("S5-C4.5 death tested: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
