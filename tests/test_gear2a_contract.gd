extends SceneTree

const Registry = preload("res://simulation/item_registry.gd")
const Gear = preload("res://simulation/item_gear.gd")
const Legacy = preload("res://tests/fixtures/gear2a_legacy_item_registry.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")
var failures := 0
var assertions := 0
var engine := SimulationEngine.new()

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-2A: " + label)

func _init() -> void:
	# Independent mapping fixture approved in docs/gear2a-tier-quality.md.
	var tiers := {"crowbar": "T1", "scrap_machete": "T2", "old_revolver": "T1",
		"old_world_saber": "T4", "travel_backpack": "T1", "military_backpack": "T3"}
	for id in tiers:
		var profile := Registry.gear_profile(id)
		check(profile.tier == tiers[id], "existing item mapped: " + id)
		check(profile.quality == ("UNIQUE" if id == "old_world_saber" else "COMMON"), "existing quality: " + id)
		check(Gear.validate(profile) == "", "existing profile valid: " + id)
	check(not Registry.resolve("crowbar").success, "legacy kit not silently promoted to formal inventory")
	check(Registry.gear_profile("unapproved_rifle").is_empty(), "unknown item has no profile")
	for previous in Legacy.rows():
		var current: Dictionary = Registry.resolve(previous.item_id).definition
		check(current.size() == previous.size() + 4, "exact four new metadata fields")
		for field in previous:
			check(current[field] == previous[field], "frozen pre-slice metadata unchanged: " + previous.item_id + "." + field)
	var fixtures := [
		{"tier": "T2", "quality": "COMMON", "properties": [], "unique_effect": ""},
		{"tier": "T2", "quality": "MODIFIED", "properties": ["quick_draw"], "unique_effect": ""},
		{"tier": "T2", "quality": "RARE", "properties": ["quick_draw", "balanced"], "unique_effect": ""},
		{"tier": "T4", "quality": "UNIQUE", "properties": [], "unique_effect": "old_world_edge"},
	]
	for fixture in fixtures:
		check(Gear.validate(fixture) == "", "quality pass fixture: " + fixture.quality)
		for field in fixture:
			var missing: Dictionary = fixture.duplicate(true)
			missing.erase(field)
			check(Gear.validate(missing) != "", "missing field refused: " + field)
		for count in range(4):
			var candidate: Dictionary = fixture.duplicate(true)
			candidate.properties = ["quick_draw", "balanced", "heavy_head"].slice(0, count)
			var expected_count: int = {"COMMON": 0, "MODIFIED": 1, "RARE": 2, "UNIQUE": 0}[fixture.quality]
			check((Gear.validate(candidate) == "") == (count == expected_count), "independent quality cardinality")
	for field in ["tier", "quality", "properties", "unique_effect"]:
		for invalid in [null, true, 2, 2.0, {}, &"T2"]:
			var row: Dictionary = fixtures[0].duplicate(true)
			row[field] = invalid
			check(Gear.validate(row) != "", "strict metadata type: " + field)
	for change in [{"tier": "T0"}, {"tier": "T5"}, {"quality": "rare"}, {"properties": ["quick_draw", "quick_draw"], "quality": "RARE"}, {"quality": "UNIQUE", "unique_effect": ""}, {"unique_effect": "old_world_edge"}, {"damage_multiplier": 2}]:
		var row: Dictionary = fixtures[0].duplicate(true)
		row.merge(change, true)
		check(Gear.validate(row) != "", "illegal gear fixture refused")
	var detached := Registry.gear_profile("old_world_saber")
	detached.tier = "T1"
	detached.properties.append("forged_property")
	check(Registry.gear_profile("old_world_saber").tier == "T4" and Registry.gear_profile("old_world_saber").properties.is_empty(), "deep detached gear lookup")
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "Gear legacy", "age": 30, "background_id": "MECHANIC", "trait_ids": []})).success, "character creation")
	world.player.inventory.set_amount("scrap", 3)
	for command in ["CRAFT", "EQUIP"]:
		check(engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": command})).success, "legacy crowbar authority unchanged")
	check(Field.attack_damage(world) == 3, "legacy crowbar still damage3")
	check(engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "UNEQUIP"})).success, "legacy unequip")
	var base_capacity: int = world.player.capacity_total
	for id in ["scrap_machete", "old_world_saber", "old_revolver", "revolver_round", "travel_backpack", "military_backpack"]:
		check(world.player.item_inventory.pickup_item(id, 1).success, "existing ownership")
	for id in ["scrap_machete", "old_world_saber", "old_revolver"]:
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), "main_hand")).success, "existing equip")
		check(Field.attack_damage(world) == {"scrap_machete": 5, "old_world_saber": 7, "old_revolver": 2}[id], "existing melee damage unchanged")
		check(Field.shot_damage(world) == 6, "quality never raises shot damage")
	for id in ["travel_backpack", "military_backpack"]:
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), "back")).success, "existing backpack equip")
		check(world.player.get_effective_capacity() == base_capacity + {"travel_backpack": 8, "military_backpack": 12}[id], "existing backpack capacity unchanged")
	var saved := world.to_canonical_json()
	check(not saved.contains('"tier"') and not saved.contains('"quality"') and not saved.contains('"properties"'), "old save format still stores IDs without gear metadata")
	var loaded := WorldState.from_json_checked(saved)
	check(loaded.success and loaded.world.to_canonical_json() == saved, "legacy ID-only save roundtrips")
	var twin: WorldState = loaded.world
	for day in range(8):
		var before := world.to_canonical_json()
		for definition in Registry.all_definitions():
			Registry.gear_profile(definition.item_id)
		check(world.to_canonical_json() == before, "metadata queries pure")
		engine.tick(world)
		engine.tick(twin)
		check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "dual-track SHA-256 continuity after save/load")
		check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "global invariants")
	print("GEAR-2A: %s assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
