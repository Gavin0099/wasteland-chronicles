extends SceneTree

# ==============================================================================
# Finished work must leave the board
# ==============================================================================
# Hand-play: "任務結束應該直接不見 而不是還在那邊". An accepted job's definition
# is committed for ever - it has to be, so a rotating board cannot cancel a
# contract already taken - but nothing ever removed the finished contract from
# what the player READS. After a few jobs the notice board was mostly a list of
# work already settled, with fresh work buried underneath.
#
#   G1  a generated job disappears from the board once it is over
#   G2  its history is NOT destroyed to achieve that
#   G3  an authored commission keeps its completion line, because QUEST-UI
#       added that deliberately after an earlier playtest
#   G4  but a settled commission can never sit above available work
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("BOARD: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Board Reader",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")
	for day in range(20):
		engine.tick(world)
	var id: StringName = world.player.npc_id

	var courier := {}
	for entry in Board.postings(world, &"settlement:gray_valley"):
		if entry.archetype == "COURIER":
			courier = entry
	check(not courier.is_empty(), "a courier job is posted")
	var job_id := String(courier.definition.id)
	var resource := String(courier.definition.objectives[0].resource)
	var needed := int(courier.definition.objectives[0].quantity)

	var on_board := func() -> bool:
		for row in PlayerUIProjection.project(world).quests:
			if String(row.id) == job_id:
				return true
		return false

	check(on_board.call(), "the job is readable before it is taken")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(id, job_id)).success, "accept")
	check(on_board.call(), "an ACTIVE job stays readable")

	world.player.inventory.set_amount(resource, needed + 1)
	check(engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(id, job_id)).success, "turn in")

	# ---- G1 ----
	check(not on_board.call(), "G1: a finished job leaves the board")

	# ---- G2 the record survives where history belongs ----
	check(world.accepted_jobs.has(job_id), "G2: the committed contract is not destroyed")
	var receipt := false
	for event in world.event_log:
		if event.type == "QUEST_RESOLVED" and String(event.payload.get("quest_id", "")) == job_id:
			receipt = true
	check(receipt, "G2: the completion receipt remains in the ledger")
	check(engine.validate_invariants(world) == "", "G2: invariants still hold")
	check(WorldState.from_json_checked(world.to_canonical_json()).success, "G2: the world still loads")

	# ---- G3 / G4 authored commissions keep their line, at the bottom ----
	var rows: Array = PlayerUIProjection.project(world).quests
	var first_terminal := -1
	var last_live := -1
	for i in rows.size():
		var terminal: bool = String(rows[i].status) in ["RESOLVED", "EXPIRED", "FAILED"]
		if terminal and first_terminal < 0:
			first_terminal = i
		if not terminal:
			last_live = i
		check(not (terminal and String(rows[i].id).begins_with("job_")), "G1: no finished generated job survives anywhere in the list")
	if first_terminal >= 0 and last_live >= 0:
		check(first_terminal > last_live, "G4: settled work never sits above work still available")

	if failures == 0:
		print("BOARD cleanup: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("BOARD cleanup: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
