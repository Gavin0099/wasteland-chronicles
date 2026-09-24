extends SceneTree

# S5-C3: skill use changes only the owner's capability profile. These tests
# exercise real intent commits, refusal, persistence and two-track replay.
const Intent = preload("res://simulation/character_creation_intent.gd")
const Enc = preload("res://simulation/travel_encounter.gd")
const Profile = preload("res://simulation/capability_profile.gd")
const ORIGIN := &"settlement:gray_valley"
const DEST := &"settlement:new_hope"

var engine := SimulationEngine.new()
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
		print("FAIL: " + message)

func created(background: String = "CARAVAN_GUARD") -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": String(ORIGIN), "character_name": "Wanderer", "age": 25,
		"background_id": background, "trait_ids": [],
	}))
	check(result.success, "creation fixture")
	world.current_day = 1
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = 300
	return world

func stage(world: WorldState, kind: StringName) -> void:
	if world.player == null:
		return
	var life := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life.status == NpcLifeState.Status.SETTLED:
		var travel := engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, DEST))
		check(travel.success, "travel fixture")
	world.pending_encounter_result = -1
	world.active_encounter = TravelEncounterState.create(kind, world.current_day,
		ORIGIN, DEST, world.current_day, {"min_security": 40.0, "headcount": 12})

func resolve(world: WorldState, option: StringName) -> Dictionary:
	return engine.commit_player_intent(world,
		PlayerIntent.create_resolve_encounter(world.player.npc_id, option))

func sha(world: WorldState) -> String:
	return world.to_canonical_json().sha256_text()

func run_track() -> Dictionary:
	var world := created()
	var initial_xp: int = world.player.xp
	stage(world, Enc.WRECK)
	var first := resolve(world, &"SEARCH")
	check(first.success, "first search commits: " + String(first.get("error", "")))
	check(first.get("skill_practice", {}).get("points", -1) == 1, "first search grants one scavenging practice")
	var xp_after_first: int = world.player.xp
	check(world.player.capability.get_skill_rank("SCAVENGING").rank == 0, "first practice alone does not rank up")
	var after_first := sha(world)
	var loaded := WorldState.from_dict_checked(world.to_dict())
	check(loaded.success, "growth snapshot loads: " + String(loaded.get("error", "")))
	if loaded.success:
		check(sha(loaded.world) == after_first, "growth save/load is a canonical fixed point")
	var json_loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(json_loaded.success, "growth snapshot survives actual JSON decoding: " + String(json_loaded.get("error", "")))
	if json_loaded.success:
		check(sha(json_loaded.world) == after_first, "JSON growth load preserves world SHA")
	world.pending_encounter_result = -1
	stage(world, Enc.WRECK)
	var second := resolve(world, &"SEARCH")
	check(second.success and second.get("skill_practice", {}).get("rank_up", false), "another day ranks scavenging 0 to 1")
	check(world.player.capability.get_skill_rank("SCAVENGING").rank == 1, "owner profile holds rank 1")
	check(world.player.xp == xp_after_first and xp_after_first >= initial_xp, "second practice does not repeat first-salvage XP")
	check(engine.validate_invariants(world) == "", "global invariants hold after growth")
	return {"sha": sha(world), "world": world}

func _init() -> void:
	var old := created()
	var old_wire := old.to_canonical_json()
	check(not old.player.capability.to_dict().has("skill_practice"), "old profile omits optional growth schema")
	var old_load := WorldState.from_dict_checked(old.to_dict())
	check(old_load.success and old_load.world.to_canonical_json() == old_wire,
		"untouched profile remains byte-identical on load: " + String(old_load.get("error", "")))

	var a := run_track()
	var b := run_track()
	check(a.sha == b.sha, "two-track full-world SHA-256 replay")
	print("S5-C3 replay SHA-256: " + String(a.sha))

	var denied := created()
	stage(denied, Enc.WRECK)
	var before := sha(denied)
	var refusal := resolve(denied, &"STRIP_PARTS")
	check(not refusal.get("success", false) and sha(denied) == before, "refused skill action is atomic")

	var barter := created()
	var first_buy := engine.execute_player_buy(barter, &"water", 1)
	check(first_buy.success and first_buy.get("skill_practice", {}).get("skill_id", "") == "BARTER", "real market trade practices barter: " + String(first_buy.get("error", "")))
	var second_buy := engine.execute_player_buy(barter, &"water", 1)
	check(second_buy.success and not second_buy.has("skill_practice"), "splitting purchases cannot farm practice on the same day")
	check(barter.player.capability.get_practice_progress("BARTER").points == 1, "trade practice is capped daily")
	check(engine.validate_invariants(barter) == "", "global invariants hold after trade practice")
	var opening_day := created()
	opening_day.current_day = 0
	var opening_buy := engine.execute_player_buy(opening_day, &"water", 1)
	check(opening_buy.success and opening_buy.has("skill_practice"), "day-zero market action can start training")
	check(engine.validate_invariants(opening_day) == "", "day-zero practice respects global invariants")
	var legacy_wire: Dictionary = created().to_dict()
	legacy_wire.erase("progression_schema_version")
	legacy_wire.player.erase("capability")
	var legacy_loaded := WorldState.from_json_checked(JSON.stringify(legacy_wire))
	check(legacy_loaded.success, "pre-C1 player migrates into an explicit legacy profile")
	if legacy_loaded.success:
		var legacy_world: WorldState = legacy_loaded.world
		var legacy_buy := engine.execute_player_buy(legacy_world, &"water", 1)
		check(legacy_buy.success and not legacy_buy.has("skill_practice"), "legacy trade still works without minting practice")
		check(legacy_world.player.capability.get_skill_rank("BARTER").rank == 0 and not legacy_world.player.capability.to_dict().has("skill_practice"), "legacy ranks and wire shape remain inert")
		check(engine.validate_invariants(legacy_world) == "", "legacy world invariants survive an ordinary trade")
	var fighter := created()
	var battle_start := engine.commit_player_intent(fighter,
		PlayerIntent.create_field_action(fighter.player.npc_id, {"command": "START"}))
	check(battle_start.success, "existing field battle starts")
	if battle_start.success:
		var turn: Dictionary = fighter.field_state.battle
		var attack := engine.commit_player_intent(fighter, PlayerIntent.create_field_action(
			fighter.player.npc_id, {"command": "ATTACK", "battle_id": turn.id, "turn": turn.turn}))
		check(attack.success, "existing field attack commits")
		var practiced := false
		for event in fighter.event_log:
			if event.type == "FIELD_TURN" and event.payload.get("skill_practice", {}).get("skill_id", "") == "MELEE":
				practiced = true
		check(practiced, "damaging melee attack records practice in turn ledger")
		check(engine.validate_invariants(fighter) == "", "global invariants hold during practiced combat")

	var profile_wire: Dictionary = a.world.player.capability.to_dict()
	var bad: Dictionary = profile_wire.duplicate(true)
	bad.skill_practice.SCAVENGING.points = -1
	check(Profile.validate(bad) != "", "negative practice is refused")
	bad = profile_wire.duplicate(true)
	bad.skill_growth_schema_version = 1.5
	check(Profile.validate(bad) != "", "invalid growth schema version is refused")
	bad = profile_wire.duplicate(true)
	bad.skill_practice.SCAVENGING.last_day = -1
	check(Profile.validate(bad) != "", "invalid last practice day is refused")
	bad = profile_wire.duplicate(true)
	bad.skill_practice["UNKNOWN"] = {"points": 0, "last_day": 1}
	check(Profile.validate(bad) != "", "unknown practice skill is refused")
	var corrupt_receipt: Dictionary = a.world.to_dict()
	var receipt_index: int = int(corrupt_receipt.pending_encounter_result)
	for invalid in ["broken", {"skill_id": "SCAVENGING", "rank_up": true,
		"from_rank": 0, "to_rank": 999, "points": 0, "required": 0},
		{"skill_id": "BARTER", "rank_up": true,
		"from_rank": 0, "to_rank": 1, "points": 0, "required": 3}]:
		var tampered: Dictionary = corrupt_receipt.duplicate(true)
		tampered.events[receipt_index].payload.skill_practice = invalid
		check(not WorldState.from_dict_checked(tampered).success, "corrupt practice receipt is rejected before UI projection")
		check(not WorldState.from_json_checked(JSON.stringify(tampered)).success, "corrupt JSON receipt is rejected before UI projection")
	var future: WorldState = a.world.duplicate_state()
	var future_profile: Dictionary = future.player.capability.to_dict()
	future_profile.skill_practice.SCAVENGING.last_day = future.current_day + 1
	future.player.capability = Profile.from_dict_checked(future_profile).profile
	check(engine.validate_invariants(future) == "PRACTICE_DAY_IN_FUTURE", "future-dated practice is rejected by world invariant")

	var maxed := created("SCAVENGER")
	var cap := maxed.player.capability
	for day in range(1, 25):
		var awarded: Dictionary = cap.grant_practice("SCAVENGING", day)
		check(awarded.success, "valid practice grant succeeds")
	check(cap.get_skill_rank("SCAVENGING").rank == 5, "repeated real-day practice reaches max rank 5")
	check(not cap.grant_practice("SCAVENGING", 25).awarded, "max rank cannot advance or award practice")
	check(Profile.validate(cap.to_dict()) == "", "max rank profile remains valid")

	if failures > 0:
		print("S5-C3 FAILED: %d" % failures)
		quit(1)
	else:
		print("S5-C3 SKILL GROWTH PASS")
		quit(0)
