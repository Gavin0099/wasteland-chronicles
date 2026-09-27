extends SceneTree

# ==============================================================================
# PLAY-3B+: THE STANDING RAIDER BOUNTY
# ==============================================================================
# Owner ruling (2026-09-27): what PLAY-3B has to prove is whether a player
# remembers a job they cannot do yet and treats getting stronger as the way
# back to it. A raider bounty that rotates away in three days cannot test that.
#
#   S1 It stands: same job, same price, on New Hope's board every time you look
#   S2 The rotating boards no longer carry the raider
#   S3 "Not yet" is readable without numbers, and so is "now"
#   S4 Missing it does not lose it: an ended bounty puts the next one up
#   S5 Not posted while his camp is burned out
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const RoadPlaces = preload("res://simulation/road_places.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("STANDING-RAIDER: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:new_hope", "character_name": "Hunter",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 10)
	world.player.inventory.set_amount("food", 10)
	return world

func standing(world: WorldState) -> Dictionary:
	for entry in Board.postings(world, &"settlement:new_hope"):
		if bool(entry.get("standing", false)):
			return entry
	return {}

func intel_text(world: WorldState, entry: Dictionary) -> String:
	return "\n".join(Board.intel_for(world, entry))

func run() -> void:
	# ---- S1 it stands ----
	var world := fresh_world()
	var first := standing(world)
	check(not first.is_empty(), "S1: New Hope posts the standing raider bounty")
	check(String(first.get("target_enemy", "")) == Enemies.HEAVY_RAIDER and String(first.get("target_route_type", "")) == "WILDERNESS", "S1: it is the raider, on the wilderness route")
	var rewards: Array = first.definition.outcomes.resolved.rewards
	check(int(rewards[0].amount) == Board.STANDING_RAIDER_CAPS and int(rewards[1].amount) == Board.STANDING_RAIDER_XP, "S1: 150 caps / 18 XP")
	var first_id := String(first.definition.id)
	for day in range(12):
		engine.tick(world)
		var again := standing(world)
		check(String(again.get("definition", {}).get("id", "")) == first_id, "S1: day %d - the same bounty is still up" % world.current_day)
		check(int(again.definition.outcomes.resolved.rewards[0].amount) == Board.STANDING_RAIDER_CAPS, "S1: day %d - at the same price" % world.current_day)

	# ---- S2 rotating boards carry no raider ----
	var rot := fresh_world()
	for day in range(18):
		for settlement_id in ["settlement:new_hope", "settlement:dry_well", "settlement:gray_valley"]:
			for entry in Board.postings(rot, StringName(settlement_id)):
				if entry.archetype == "BOUNTY" and not bool(entry.get("standing", false)):
					check(String(entry.get("target_enemy", "")) != Enemies.HEAVY_RAIDER, "S2: day %d %s rotating bounty is not the raider" % [rot.current_day, settlement_id])
		engine.tick(rot)

	# ---- S3 not yet / now ----
	var weak := fresh_world()
	weak.player.capability._data.skill_ranks["MELEE"] = 0
	var weak_text := intel_text(weak, standing(weak))
	check(weak_text.contains("多半會被打倒"), "S3: unarmed at MELEE 0 reads 'not yet': %s" % weak_text)
	check(not weak_text.contains("推估需"), "S3: in words, not the DEATH_TESTED arithmetic")
	var strong := fresh_world()
	strong.player.capability._data.skill_ranks["MELEE"] = 1
	strong.player.item_inventory.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(strong, PlayerIntent.create_equip_item(strong.player.npc_id, &"scrap_machete", "main_hand"))
	var strong_text := intel_text(strong, standing(strong))
	check(strong_text.contains("打得贏"), "S3: MELEE 1 with a machete reads 'now': %s" % strong_text)

	# ---- S4 missing it does not lose it ----
	var miss := fresh_world()
	check(engine.commit_player_intent(miss, PlayerIntent.create_accept_quest(miss.player.npc_id, first_id)).success, "S4: accept the standing bounty")
	for day in range(Board.BOUNTY_DEADLINE_DAYS + 2):
		engine.tick(miss)
	check(String(miss.quest_state.get_quest(first_id).status) == "EXPIRED", "S4: left too long, it expires")
	var next := standing(miss)
	check(not next.is_empty() and String(next.definition.id) != first_id, "S4: the raider is posted again under a new job")
	check(Board.standing_raider_generation(miss) == 1, "S4: one ended generation")

	# ---- S5 camp cleared ----
	var cleared := fresh_world()
	cleared.record_event(EventRecord.new(cleared.current_day, "FIELD_RESULT", cleared.player.npc_id, &"settlement:new_hope",
		{"outcome": "VICTORY", "place_id": "place:hammer_camp", "gained": {}, "left_behind": {}}))
	check(RoadPlaces.camp_cleared(cleared), "S5: the camp is cleared")
	check(standing(cleared).is_empty(), "S5: nobody posts the raider while his camp is burned out")

	print("STANDING-RAIDER: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
