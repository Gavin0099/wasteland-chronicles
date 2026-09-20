extends SceneTree

const Profile = preload("res://simulation/capability_profile.gd")
const Intent = preload("res://simulation/character_creation_intent.gd")
const Catalogue = preload("res://simulation/background_catalogue.gd")
var engine := SimulationEngine.new()
var failed := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)

func request(background: String = "MECHANIC", traits: Array = []) -> Dictionary:
	return {"source_settlement_id": "settlement:gray_valley", "character_name": "Tester", "age": 25, "background_id": background, "trait_ids": traits}

func created(background: String = "MECHANIC", traits: Array = []) -> WorldState:
	var world := S1WorldData.create_s1_world()
	var before_population: int = world.get_settlement(&"settlement:gray_valley").population
	var sequence := world.next_npc_sequence
	var res := engine.commit_character_creation(world, Intent.new(request(background, traits)))
	check(res.success, "valid creation must succeed: " + background)
	check(world.get_settlement(&"settlement:gray_valley").population == before_population, "creation cannot add population")
	check(world.next_npc_sequence == sequence + 1, "creation must consume exactly one monotonic ID")
	check(engine.validate_invariants(world) == "", "global invariants after creation")
	return world

func _init() -> void:
	# Expected packages are the owner-reviewed decision table, not Catalogue.resolve.
	var expected := {
		"CARAVAN_GUARD": {"FIREARMS": 2, "MELEE": 1, "SURVIVAL": 1},
		"MECHANIC": {"MECHANICS": 2, "ELECTRONICS": 1, "SCAVENGING": 1},
		"FARMER": {"SURVIVAL": 2, "MECHANICS": 1, "BARTER": 1},
		"SCAVENGER": {"SCAVENGING": 2, "SURVIVAL": 1, "STEALTH": 1},
	}
	for background in expected:
		var world := created(background)
		var ranks: Dictionary = world.player.capability.to_dict().skill_ranks
		check(ranks.size() == 10, "all ten skills must be present")
		for skill in Profile.SKILLS:
			check(typeof(ranks[skill]) == TYPE_INT and ranks[skill] == expected[background].get(skill, 0), "independent package vector: " + background + "/" + skill)
		check(world.player.capability.to_dict().creation_origin == "CHARACTER_CREATION", "new creation has explicit provenance")
		var with_traits := created(background, ["CAUTIOUS", "RECKLESS"])
		check(with_traits.player.capability.to_dict().skill_ranks == ranks, "traits cannot add ranks")

	# Every pair in the approved catalogue is valid; pair semantics are not C0.
	for first in Profile.CORE_TRAITS:
		check(Profile.validate_traits([first]) == "", "single Core Trait allowed")
		for second in Profile.CORE_TRAITS:
			check((Profile.validate_traits([first, second]) == "") == (first != second), "only duplicate pairs are invalid")
	var a := created("MECHANIC", ["CAUTIOUS", "RECKLESS"])
	var b := created("MECHANIC", ["RECKLESS", "CAUTIOUS"])
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "trait input order must not alter world or history")
	check(created("MECHANIC", ["AGGRESSIVE", "PACIFIST"]).player != null, "contradictory trait names are legal")
	var malformed_requests: Array = []
	for change in [{"trait_ids": ["CAUTIOUS", "CAUTIOUS"]}, {"trait_ids": ["CAUTIOUS", "GREEDY", "LOYAL"]}, {"trait_ids": ["UNKNOWN"]}, {"background_id": "UNKNOWN"}, {"source_settlement_id": "missing"}, {"character_name": "  "}, {"age": -1}, {"age": 25.0}, {"skill_ranks": {}}, {"trait_ids": null}]:
		var raw := request()
		raw.merge(change, true)
		malformed_requests.append(raw)
	var missing := request()
	missing.erase("background_id")
	malformed_requests.append(missing)
	for raw in malformed_requests:
		var w := S1WorldData.create_s1_world()
		var before := w.to_canonical_json().sha256_text()
		check(not engine.commit_character_creation(w, Intent.new(raw)).success, "invalid creation must be rejected")
		check(w.to_canonical_json().sha256_text() == before, "invalid creation must not allocate identity, mutate registry or history")
	var existing_hash := a.to_canonical_json().sha256_text()
	check(not engine.commit_character_creation(a, Intent.new(request())).success and a.to_canonical_json().sha256_text() == existing_hash, "second player rejected atomically")
	var packed := S1WorldData.create_s1_world()
	var town := packed.get_settlement(&"settlement:gray_valley")
	town.population = packed.npc_registry.get_named_count_at(town.id)
	packed.total_initial_population = -1 # Fixture re-establishes its accounting baseline.
	var packed_hash := packed.to_canonical_json().sha256_text()
	var no_slot := engine.commit_character_creation(packed, Intent.new(request()))
	check(not no_slot.success and String(no_slot.error).begins_with("CAPACITY_OVERFLOW") and packed.to_canonical_json().sha256_text() == packed_hash, "no anonymous population must reject without mutation")

	# Strict domain and predicates, including invalid suffix after a false clause.
	var profile: RefCounted = a.player.capability
	for value in [-1, 6, 2.0, 2.5, true, "2", null, NAN, INF]:
		var invalid: Dictionary = profile.to_dict()
		invalid.skill_ranks.MECHANICS = value
		check(not Profile.from_dict_checked(invalid).success, "invalid rank must never clamp/coerce")
	for value in [0, 5]:
		var valid: Dictionary = profile.to_dict()
		valid.skill_ranks.MECHANICS = value
		check(Profile.from_dict_checked(valid).success, "inclusive rank boundaries")
	var unknown: Dictionary = profile.to_dict()
	unknown.skill_ranks.UNKNOWN = 3
	check(not Profile.from_dict_checked(unknown).success and not profile.get_skill_rank("UNKNOWN").success, "unknown ID is not rank zero")
	unknown = profile.to_dict()
	unknown.skill_ranks.erase("MECHANICS")
	check(not Profile.from_dict_checked(unknown).success, "missing rank cannot default")
	for threshold in [1, 2, 3]:
		var eligibility: Dictionary = profile.meets_skill_requirement("MECHANICS", threshold)
		check(eligibility.success and eligibility.met == (threshold <= 2), "below/equal/above threshold")
	check(profile.meets_requirements({"all": []}).met, "empty AND is no requirement")
	var requirements := {"all": [{"kind": "skill", "skill_id": "MECHANICS", "min_rank": 2}, {"kind": "skill", "skill_id": "ELECTRONICS", "min_rank": 1}]}
	check(profile.meets_requirements(requirements).met, "combined requirements must all pass")
	requirements.all.reverse()
	check(profile.meets_requirements(requirements).met, "AND order is irrelevant")
	requirements.all[0].min_rank = 5
	requirements.all.append({"kind": "perk", "perk": "FIELD_REPAIR"})
	check(not profile.meets_requirements(requirements).success, "false prefix cannot hide unsupported authority")
	for bad in [{}, {"all": null}, {"all": [{"kind": "skill", "skill_id": "MECHANICS", "min_rank": 2.0}]}, {"all": [], "any": []}]:
		check(not profile.meets_requirements(bad).success, "malformed requirement set fails closed")
	check(a.to_canonical_json().sha256_text() == existing_hash, "queries are pure")

	# New-schema save/load preserves original token distinctions and full world.
	var raw_json := a.to_canonical_json()
	var loaded := WorldState.from_json_checked(raw_json)
	check(loaded.success and not loaded.migrated, "new snapshot loads without migration")
	if not loaded.success:
		print(loaded.error)
		quit(1)
		return
	b = loaded.world
	check(a.to_canonical_json() == b.to_canonical_json(), "save/load/save canonical fixed point")
	check(a.duplicate_state().to_canonical_json() == raw_json, "world copy preserves capability")
	for token in ["2.0", "2e0"]:
		var corrupt := raw_json.replace('"MECHANICS": 2', '"MECHANICS": ' + token)
		check(corrupt != raw_json and not WorldState.from_json_checked(corrupt).success, "raw fractional/exponent token rejected")
	check(not WorldState.from_dict_checked(JSON.parse_string(raw_json)).success, "already-lossy Dictionary cannot prove integer rank tokens")
	for change in [{"progression_schema_version": 2}, {"progression_schema_version": null}]:
		var corrupt := a.to_dict()
		corrupt.merge(change, true)
		check(not WorldState.from_dict_checked(corrupt).success, "unknown schema cannot migrate")
	var corrupt := a.to_dict()
	corrupt.player.erase("capability")
	check(not WorldState.from_dict_checked(corrupt).success, "modern partial profile cannot migrate")

	# Authentic legacy shape: old metadata remains inert, no package inferred.
	var legacy := a.to_dict()
	legacy.erase("progression_schema_version")
	legacy.player.erase("capability")
	legacy.npc_profile_registry[String(a.player.npc_id)].traits = [NpcProfile.Trait.CAUTIOUS, NpcProfile.Trait.GREEDY]
	legacy.npc_profile_registry[String(a.player.npc_id)].aptitudes = [NpcProfile.Aptitude.TECHNICAL]
	var old_profile: Dictionary = legacy.npc_profile_registry.duplicate(true)
	for invalid_biography in [{"background": 1.5}, {"traits": [0, 0]}, {"aptitudes": [99]}]:
		var broken := legacy.duplicate(true)
		broken.npc_profile_registry[String(a.player.npc_id)].merge(invalid_biography, true)
		check(not WorldState.from_json_checked(JSON.stringify(broken)).success, "legacy migration must not silently repair invalid biography")
	var migrated := WorldState.from_json_checked(JSON.stringify(legacy))
	check(migrated.success and migrated.migrated, "valid pre-C1 save migrates explicitly")
	if migrated.success:
		var mw: WorldState = migrated.world
		check(mw.npc_profile_registry.to_dict() == old_profile, "legacy metadata retained verbatim")
		var metadata: Dictionary = mw.player.capability.to_dict()
		check(metadata.creation_origin == "LEGACY_MIGRATION" and metadata.selected_creation_traits.is_empty(), "legacy provenance and empty Core")
		for rank in metadata.skill_ranks.values():
			check(typeof(rank) == TYPE_INT and rank == 0, "legacy Background/Aptitude cannot grant ranks")
		var original_without_new := mw.to_dict()
		original_without_new.erase("progression_schema_version")
		original_without_new.player.erase("capability")
		check(JSON.stringify(original_without_new) == JSON.stringify(legacy), "migration changes only declared new data")
		var reload := WorldState.from_json_checked(mw.to_canonical_json())
		check(reload.success and not reload.migrated and reload.world.to_canonical_json() == mw.to_canonical_json(), "migration is idempotent")

	# Dual-track replay, with no capability effects on the existing road.
	var other := a.duplicate_state()
	var changed: Dictionary = other.player.capability.to_dict()
	changed.skill_ranks.MECHANICS = 5
	changed.selected_creation_traits = ["AGGRESSIVE", "PACIFIST"]
	other.player.capability = Profile.from_dict_checked(changed).profile
	for world in [a, b, other]:
		engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"))
	for step in range(8):
		if a.active_encounter == null:
			break
		var options := TravelEncounter.options(a.active_encounter.encounter_type)
		var option: StringName = options[-1].id
		for world in [a, b, other]:
			engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))
		check(a.to_canonical_json() == b.to_canonical_json(), "replay match with pending result")
		b = WorldState.from_json(b.to_canonical_json())
		for world in [a, b, other]:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "dual-track replay SHA-256")
	var physical_a := a.to_dict()
	var physical_other := other.to_dict()
	physical_a.player.erase("capability")
	physical_other.player.erase("capability")
	check(JSON.stringify(physical_a) == JSON.stringify(physical_other), "capability changes cannot change pre-C2 world effects")
	for world in [a, b, other]:
		check(engine.validate_invariants(world) == "", "global invariants after complete replay")
	print("C0/C1 replay SHA-256: ", a.to_canonical_json().sha256_text())
	print("C0/C1 headless gates: ", "PASS" if failed == 0 else "FAIL", "; failures=", failed)
	quit(0 if failed == 0 else 1)
