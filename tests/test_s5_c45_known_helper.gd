extends SceneTree

# ==============================================================================
# S5-C4.5 KNOWN_HELPER — 救人手法
# ==============================================================================
# The third evidence-backed identity. A survivor who has twice really given
# their own water or food to someone on the road learns to read what the person
# in front of them still has to offer, BEFORE spending the ration.
#
#   G1  only a ration that actually left the pack counts as help
#   G2  distinct days, not distinct receipts
#   G3  refusing or robbing is not help
#   G4  qualification alone changes nothing; the survivor opts in
#   G5  the knowledge appears only once owned, for both helping encounters
#   G6  reading someone mutates nothing and promises nothing extra
#   G7  what was previewed is what the road actually pays
#   G8  checked persistence, invariants and dual-track replay
#   G9  an acceptance cannot be backdated ahead of its evidence
#
# Deliberately NOT here: reputation. The world does not remember the player;
# the CHARACTER learned something. No faction, standing or NPC memory exists.
# ==============================================================================

const Creation = preload("res://simulation/character_creation_intent.gd")
const Acquired = preload("res://simulation/acquired_traits.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("S5-C4.5 known helper: " + label)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Road Nurse",
		"age": 31, "background_id": "FARMER", "trait_ids": [],
	})).success, "normal character creation succeeds")
	world.player.inventory.water = 8
	world.player.inventory.food = 8
	return world

# Drive the player home from wherever the staged encounter left them, resolving
# whatever the real road puts in the way. Mirrors the scavenger fixture.
func return_home(world: WorldState, id: StringName) -> void:
	var steps := 0
	while world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.IN_TRANSIT and steps < 12:
		steps += 1
		if world.pending_encounter_result >= 0:
			check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(id, world.pending_encounter_result)).success, "receipt is confirmed")
		elif world.active_encounter != null:
			var escape: StringName = &"FLEE_ROAD" if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH else (&"DETOUR" if world.active_encounter.encounter_type in [TravelEncounter.ROCKSLIDE, TravelEncounter.ROADBLOCK] else &"LEAVE")
			check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, escape)).success, "incidental road event resolves")
		else:
			engine.tick(world)
	check(steps < 12 and world.npc_life_state_registry.get_life_state(id).status == NpcLifeState.Status.SETTLED, "journey returns to settlement")

# Stage one helping encounter and actually pay for it through the real intent.
func help_once(world: WorldState, encounter_type: StringName, option: StringName) -> Dictionary:
	var id: StringName = world.player.npc_id
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(id)
	var origin: StringName = life.population_container_id
	var destination := &"settlement:new_hope" if origin == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	world.player.inventory.scrap = 0
	world.player.inventory.fuel = 0
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, destination)).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(encounter_type, world.current_day, origin, destination, 1)
	var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, option))
	check(result.success, "helping commits through the real intent: " + String(option))
	return result

func run_life(world: WorldState) -> void:
	var id: StringName = world.player.npc_id

	# ---- G5 (negative) nothing is revealed before the identity is earned ----
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(id)
	var here: StringName = life.population_container_id
	var there := &"settlement:new_hope" if here == &"settlement:gray_valley" else &"settlement:gray_valley"
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, there)).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.DEHYDRATED_TRAVELLER, world.current_day, here, there, 1)
	check(PlayerUIProjection.project(world).active_encounter.get("help_preview", {}).is_empty(),
		"G5: an unearned identity reveals nothing about the traveller")

	# ---- G3 walking away is not help ----
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"LEAVE")).success, "leaving commits")
	check(not Acquired.candidates(world.event_log, id, world.current_day).has("KNOWN_HELPER"),
		"G3: walking away from a dying traveller is not help")
	return_home(world, id)

	# ---- G1/G2 two days of real cost ----
	var first := help_once(world, TravelEncounter.DEHYDRATED_TRAVELLER, &"GIVE_WATER")
	check(int(first.get("spent", {}).get("water", 0)) >= 1, "G1: the receipt records the water actually leaving the pack")
	check(not Acquired.candidates(world.event_log, id, world.current_day).has("KNOWN_HELPER"),
		"G2: one day of helping is not yet the identity")
	return_home(world, id)

	var second := help_once(world, TravelEncounter.REFUGEE_COLUMN, &"SHARE_FOOD")
	check(int(second.get("spent", {}).get("food", 0)) >= 1, "G1: sharing food records a real cost too")
	return_home(world, id)
	check(Acquired.candidates(world.event_log, id, world.current_day).has("KNOWN_HELPER"),
		"G2: two distinct days of paid help create the candidate")

	# ---- G1/G2/G3 boundaries, on forged ledgers rather than the live world ----
	var paid: EventRecord = null
	for event in world.event_log:
		if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.actor_id == id and String(event.payload.get("option", "")) == "GIVE_WATER":
			paid = event
			break
	check(paid != null, "a real paid helping receipt exists for the boundary checks")
	if paid != null:
		var same_day: Array[EventRecord] = []
		for _i in range(4):
			same_day.append(EventRecord.new(9, paid.type, id, paid.target_id, paid.payload.duplicate(true)))
		check(not Acquired.candidates(same_day, id, 12).has("KNOWN_HELPER"),
			"G2: four receipts stamped on one day are one day of practice, not four")

		var two_days: Array[EventRecord] = []
		for day in [9, 10]:
			two_days.append(EventRecord.new(day, paid.type, id, paid.target_id, paid.payload.duplicate(true)))
		check(Acquired.candidates(two_days, id, 12).has("KNOWN_HELPER"),
			"G2: two distinct days on the same road qualify")

		# An option selected without the ration actually leaving is not help.
		var unpaid: Array[EventRecord] = []
		for day in [9, 10]:
			var payload: Dictionary = paid.payload.duplicate(true)
			payload["spent"] = {}
			unpaid.append(EventRecord.new(day, paid.type, id, paid.target_id, payload))
		check(not Acquired.candidates(unpaid, id, 12).has("KNOWN_HELPER"),
			"G1: a receipt with no ration spent does not count as help")

		# Robbing the traveller is the opposite of helping.
		var robbed: Array[EventRecord] = []
		for day in [9, 10]:
			var payload2: Dictionary = paid.payload.duplicate(true)
			payload2["option"] = "TAKE_PACK"
			robbed.append(EventRecord.new(day, paid.type, id, paid.target_id, payload2))
		check(not Acquired.candidates(robbed, id, 12).has("KNOWN_HELPER"),
			"G3: taking the pack is not help")

	# ---- G4 qualification alone changes nothing ----
	check(not world.player.has_acquired_trait("KNOWN_HELPER"), "G4: qualifying does not auto-grant the identity")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "KNOWN_HELPER")).success,
		"G4: the qualified survivor opts in at a settlement")
	check(world.player.has_acquired_trait("KNOWN_HELPER"), "G4: the identity is owned")
	check(not engine.commit_player_intent(world, PlayerIntent.create_accept_acquired_trait(id, "KNOWN_HELPER")).success,
		"G4: the same identity cannot be taken twice")

	# ---- G5/G6/G7 the knowledge, for both helping encounters ----
	for staged in [
		{"type": TravelEncounter.DEHYDRATED_TRAVELLER, "option": &"GIVE_WATER"},
		{"type": TravelEncounter.REFUGEE_COLUMN, "option": &"SHARE_FOOD"},
	]:
		var from_id: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
		var to_id := &"settlement:new_hope" if from_id == &"settlement:gray_valley" else &"settlement:gray_valley"
		world.player.inventory.water = 4
		world.player.inventory.food = 4
		world.player.inventory.scrap = 0
		world.player.inventory.fuel = 0
		check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, to_id)).success, "experienced helper travels again")
		world.active_encounter = TravelEncounterState.create(staged.type, world.current_day, from_id, to_id, 1)

		var before := world.to_canonical_json()
		var preview: Dictionary = PlayerUIProjection.project(world).active_encounter.get("help_preview", {})
		check(world.to_canonical_json() == before, "G6: reading someone does not mutate world state")
		check(not preview.is_empty(), "G5: the identity reveals what this person can offer")
		check(String(preview.get("option", "")) == String(staged.option), "G5: the preview names the helping option it describes")

		var truth: Dictionary = (
			TravelEncounter.traveller_yield(world.current_day, from_id, to_id, 1)
			if staged.type == TravelEncounter.DEHYDRATED_TRAVELLER
			else TravelEncounter.refugee_yield(world.current_day, from_id, to_id, 1))
		check(preview.get("goods", {}) == truth, "G5: the preview is the road's real offer, not an estimate")

		var water_before: int = world.player.inventory.get_amount("water")
		var food_before: int = world.player.inventory.get_amount("food")
		var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, staged.option))
		check(result.success, "helping still commits normally")
		check(result.get("gained", {}) == preview.goods, "G7: what was previewed is what was actually received")
		# G6: the identity is knowledge, not a discount. The ration is still paid.
		if staged.type == TravelEncounter.DEHYDRATED_TRAVELLER:
			check(world.player.inventory.get_amount("water") == water_before - 1, "G6: the water is still spent")
		else:
			check(world.player.inventory.get_amount("food") == food_before - 1, "G6: the food is still spent")
		return_home(world, id)

	# ---- G5 the knowledge does not leak into encounters it has no claim on ----
	var wreck_from: StringName = world.npc_life_state_registry.get_life_state(id).population_container_id
	var wreck_to := &"settlement:new_hope" if wreck_from == &"settlement:gray_valley" else &"settlement:gray_valley"
	world.player.inventory.water = 4
	world.player.inventory.food = 4
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, wreck_to)).success, "travel starts")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, world.current_day, wreck_from, wreck_to, 1)
	check(PlayerUIProjection.project(world).active_encounter.get("help_preview", {}).is_empty(),
		"G5: reading people says nothing about a wreck")
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"LEAVE")).success, "wreck is left alone")
	return_home(world, id)

func _init() -> void:
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
		if event.type == "ACQUIRED_TRAIT_ACCEPTED" and event.payload.get("trait_id") == "KNOWN_HELPER":
			event.day = 0
	check(String(WorldState.from_dict_checked(forged).error).begins_with("ACQUIRED_TRAIT_LEDGER"),
		"G9: an acceptance cannot be backdated ahead of the help that earned it")

	print("S5-C4.5 known helper: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
