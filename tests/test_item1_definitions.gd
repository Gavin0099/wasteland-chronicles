extends SceneTree

const Definition = preload("res://simulation/item_definition.gd")
const Catalogue = preload("res://simulation/item_catalogue.gd")
const Authored = preload("res://game_data/item_definitions.gd")
const Art = preload("res://game_data/item_art_references.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0
var evidence: Array = []

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-1: " + message)

# Independent acceptance fixture from docs/item-1-data-contract.md's fixed table.
# Do not derive expected fields, values or asset paths from the implementation.
func fixtures() -> Array:
	return [
		{"item_id": "rusted_knife", "display_name_zh": "生鏽小刀", "category": "WEAPON", "stack_mode": "UNIQUE", "base_weight": 250, "asset_id": "item_rusted_knife", "tags": ["blade", "tool"]},
		{"item_id": "hunting_knife", "display_name_zh": "獵刀", "category": "WEAPON", "stack_mode": "UNIQUE", "base_weight": 400, "asset_id": "item_hunting_knife", "tags": ["blade", "hunting", "tool"]},
		{"item_id": "rebar_club", "display_name_zh": "鋼筋棍", "category": "WEAPON", "stack_mode": "UNIQUE", "base_weight": 1800, "asset_id": "item_rebar_club", "tags": ["blunt", "metal"]},
		{"item_id": "scrap_machete", "display_name_zh": "廢鐵砍刀", "category": "WEAPON", "stack_mode": "UNIQUE", "base_weight": 1200, "asset_id": "item_scrap_machete", "tags": ["blade", "salvaged"]},
		{"item_id": "work_clothes", "display_name_zh": "舊工作服", "category": "APPAREL", "stack_mode": "UNIQUE", "base_weight": 1200, "asset_id": "item_work_clothes", "tags": ["clothing", "workwear"]},
		{"item_id": "desert_robe", "display_name_zh": "沙地長袍", "category": "APPAREL", "stack_mode": "UNIQUE", "base_weight": 900, "asset_id": "item_desert_robe", "tags": ["clothing", "desert"]},
		{"item_id": "caravan_coat", "display_name_zh": "商隊外套", "category": "APPAREL", "stack_mode": "UNIQUE", "base_weight": 1500, "asset_id": "item_caravan_coat", "tags": ["clothing", "travel"]},
		{"item_id": "travel_backpack", "display_name_zh": "舊旅行包", "category": "CONTAINER", "stack_mode": "UNIQUE", "base_weight": 1100, "asset_id": "item_travel_backpack", "tags": ["bag", "travel"]},
		{"item_id": "rope", "display_name_zh": "繩索", "category": "TOOL", "stack_mode": "UNIQUE", "base_weight": 2500, "asset_id": "item_rope", "tags": ["rope", "travel"]},
		{"item_id": "flashlight", "display_name_zh": "手電筒", "category": "TOOL", "stack_mode": "UNIQUE", "base_weight": 400, "asset_id": "item_flashlight", "tags": ["lighting", "tool"]},
		{"item_id": "wrench", "display_name_zh": "扳手", "category": "TOOL", "stack_mode": "UNIQUE", "base_weight": 700, "asset_id": "item_wrench", "tags": ["hand_tool", "metal"]},
		{"item_id": "first_aid_kit", "display_name_zh": "急救包", "category": "CONSUMABLE", "stack_mode": "STACKABLE", "base_weight": 800, "asset_id": "item_first_aid_kit", "tags": ["medical"]},
	]

func sorted_fixtures() -> Array:
	var rows := fixtures()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.item_id < b.item_id)
	return rows

func _init() -> void:
	check_definitions()
	check_refusals()
	check_detachment_and_canonicalization()
	run_world_replay()
	DirAccess.make_dir_recursive_absolute("res://artifacts/item-1")
	var file := FileAccess.open("res://artifacts/item-1/replay-evidence.json", FileAccess.WRITE)
	check(file != null, "open dedicated evidence output")
	if file != null:
		var output := {"suite": "ITEM-1", "assertions": assertions, "failures": failures, "checkpoints": evidence}
		file.store_string(JSON.stringify(output, "\t", true) + "\n")
	print("ITEM-1 definition gates: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)

func check_definitions() -> void:
	var rows: Array = Catalogue.all_definitions()
	check(rows == sorted_fixtures(), "exact twelve approved records, integer grams and sorted identities")
	check(rows.size() == 12, "185 images must not create 185 authoritative definitions")
	var authored: Array = Authored.rows()
	check(authored.size() == 12, "single authored source contains twelve records")
	var paths := {
		"item_rusted_knife": "rusty_knife", "item_hunting_knife": "hunting_knife",
		"item_rebar_club": "rebar_club", "item_scrap_machete": "scrap_machete",
		"item_work_clothes": "work_clothes", "item_desert_robe": "desert_robe",
		"item_caravan_coat": "caravan_coat", "item_travel_backpack": "travel_backpack",
		"item_rope": "rope", "item_flashlight": "flashlight", "item_wrench": "wrench",
		"item_first_aid_kit": "medkit",
	}
	for row in fixtures():
		check(Definition.validate(row) == "", "approved fixture validates: " + row.item_id)
		var result: Dictionary = Catalogue.resolve(row.item_id)
		check(result.success and result.definition == row and result.error == "", "exact ID lookup: " + row.item_id)
		check(typeof(result.definition.base_weight) == TYPE_INT, "weight remains int: " + row.item_id)
		var art: Dictionary = Art.resolve(row.asset_id)
		var expected_path: String = "res://ui/assets/items/candidates/%s.png" % paths[row.asset_id]
		check(art.success and art.path == expected_path and art.error == "", "explicit stable asset binding: " + row.item_id)
		check(FileAccess.file_exists(expected_path), "asset physically exists: " + expected_path)
		var found := false
		for authored_row in authored:
			if authored_row == row:
				found = true
		check(found, "authored source agrees with independent fixture: " + row.item_id)

func reject_catalogue(raw: Variant, label: String) -> void:
	var result: Dictionary = Catalogue.canonicalize(raw)
	check(not result.success and result.error is String and not result.error.is_empty(), label + " returns refusal")
	check(result.has("definitions") and result.definitions == [] and result.has("canonical_json") and result.canonical_json == "", label + " exposes no partial catalogue")
	check(Catalogue.all_definitions() == sorted_fixtures(), label + " cannot replace source")

func check_refusals() -> void:
	for invalid in [null, 1, true, &"rusted_knife", "", "生鏽小刀", "rusty_knife", "medkit", "crowbar", "water", "fuel", "old_revolver", "RUSTED_KNIFE", " rusted_knife", "rusted_knife "]:
		var result: Dictionary = Catalogue.resolve(invalid)
		check(not result.success and result.has("definition") and result.definition == null and not result.error.is_empty(), "invalid/unknown lookup is not a fallback: " + str(invalid))
		if typeof(invalid) == TYPE_STRING:
			check(result.error == "UNKNOWN_ITEM_ID", "unknown exact String ID uses stable refusal")
	for invalid in [null, true, 2, &"item_rusted_knife", "", "rusted_knife", "item_crowbar", "item_old_revolver", "../../water.png"]:
		var result: Dictionary = Art.resolve(invalid)
		check(not result.success and result.path == "" and not result.error.is_empty(), "unknown art key exposes no usable path")
	for raw in [null, 2, true, "rusted_knife", [], {}]:
		check(Definition.validate(raw) != "", "non-definition fails schema validation")
	for field in fixtures()[0]:
		var missing: Dictionary = fixtures()[0]
		missing.erase(field)
		check(Definition.validate(missing) != "", "required field cannot default: " + field)
	for field in ["damage", "armor", "accuracy", "durability", "rarity", "level_requirement", "skill_bonus", "sell_price", "repair_cost", "special_effect", "perk_requirement", "crafting_recipe", "heal", "capacity_bonus", "actions", "settlement_supply", "loot_sources"]:
		var extra: Dictionary = fixtures()[0]
		extra[field] = 1
		check(Definition.validate(extra) != "", "deferred authority field rejected: " + field)
		var candidate := fixtures()
		candidate[0] = extra
		reject_catalogue(candidate, "deferred " + field)
	var invalid_values := {
		"item_id": [null, 1, true, &"rusted_knife", "", "Rusted_knife", "2knife", "生鏽小刀", "rusted-knife", "rusted knife", "../knife"],
		"display_name_zh": [null, 1, true, &"生鏽小刀", "", " ", " 生鏽小刀", "生鏽小刀\n"],
		"category": [null, 1, true, &"WEAPON", "", "weapon", "MISC", "LIGHTING_EQUIPMENT"],
		"stack_mode": [null, 1, true, &"UNIQUE", "", "unique", "NONE"],
		"base_weight": [null, true, false, "250", 0, -1, 250.0, 250.5, NAN, INF],
		"asset_id": [null, 1, true, &"item_rusted_knife", "", "../rusty_knife.png", "item-Rusted-knife"],
		"tags": [null, true, "blade", PackedStringArray(["blade"]), ["blade", "blade"], ["Blade"], [""], [" hand_tool"], [1], [null], [&"blade"], ["blade", ["tool"]]],
	}
	for field in invalid_values:
		for value in invalid_values[field]:
			var row: Dictionary = fixtures()[0]
			row[field] = value
			check(Definition.validate(row) != "", "strict field/type refusal: " + field + " = " + str(value))
			var candidate := fixtures()
			candidate[0] = row
			reject_catalogue(candidate, "malformed " + field)
	for raw in [null, {}, 12, "items", []]:
		reject_catalogue(raw, "invalid complete-catalogue container")
	var missing := fixtures()
	missing.remove_at(0)
	reject_catalogue(missing, "eleven rows")
	var duplicate := fixtures()
	duplicate[11] = duplicate[0].duplicate(true)
	reject_catalogue(duplicate, "duplicate ID with twelve rows")
	var thirteenth := fixtures()
	var new_row: Dictionary = fixtures()[0]
	new_row.item_id = "crowbar"
	thirteenth.append(new_row)
	reject_catalogue(thirteenth, "thirteenth item cannot become authority")
	var unknown := fixtures()
	unknown[0].item_id = "old_revolver"
	reject_catalogue(unknown, "unknown but syntactically valid ID")
	var rebound := fixtures()
	rebound[0].asset_id = "item_hunting_knife"
	reject_catalogue(rebound, "known item cannot bind another known asset")
	rebound[0].asset_id = "item_unknown"
	reject_catalogue(rebound, "known item cannot bind missing asset")

func check_detachment_and_canonicalization() -> void:
	var expected := sorted_fixtures()
	var canonical: Dictionary = Catalogue.canonicalize(fixtures())
	check(canonical.success and canonical.error == "" and canonical.definitions == expected, "complete fixture canonicalizes")
	if not canonical.success:
		return
	var fingerprint: String = canonical.canonical_json.sha256_text()
	# Compare wire text against independent fixture: native JSON parsing turns all
	# numbers into floats, so Dictionary equality would incorrectly reject ints.
	var expected_json := JSON.stringify({"schema_version": 1, "items": expected}, "", true)
	check(canonical.canonical_json == expected_json, "canonical document has sorted keys, schema 1 and exact independent fixture")
	check(not canonical.canonical_json.contains("250.0"), "canonical grams do not become floats")
	var source := fixtures()
	var source_before := JSON.stringify(source)
	for rotation in range(12):
		var reordered: Array = []
		for offset in range(12):
			var original: Dictionary = source[(rotation + offset) % 12]
			var keys := original.keys()
			keys.reverse()
			var row := {}
			for key in keys:
				row[key] = original[key].duplicate() if original[key] is Array else original[key]
			row.tags.reverse()
			reordered.push_front(row)
		var input_before := JSON.stringify(reordered, "", false)
		var actual: Dictionary = Catalogue.canonicalize(reordered)
		check(actual.success and actual.canonical_json == canonical.canonical_json and actual.canonical_json.sha256_text() == fingerprint, "item/tag/field order invariant, rotation " + str(rotation))
		check(JSON.stringify(reordered, "", false) == input_before, "canonicalizer does not sort caller-owned arrays or fields")
	check(JSON.stringify(source) == source_before, "input fixtures remain detached")
	var lookup: Dictionary = Catalogue.resolve("rusted_knife")
	lookup.definition.tags.append("forged_power")
	lookup.definition.base_weight = 1
	lookup.definition.asset_id = "item_hunting_knife"
	check(Catalogue.resolve("rusted_knife").definition == fixtures()[0], "nested lookup mutation cannot change source")
	var all: Array = Catalogue.all_definitions()
	all[0].tags.clear()
	all[0].display_name_zh = "changed"
	all.clear()
	var authored: Array = Authored.rows()
	authored[0].tags.clear()
	authored.clear()
	check(Catalogue.all_definitions() == expected, "enumeration and authored factory return deep detached values")
	var candidate := fixtures()
	var result: Dictionary = Catalogue.canonicalize(candidate)
	result.definitions[0].tags.append("changed")
	check(candidate == fixtures(), "canonical result does not alias caller input")
	candidate[0].tags.clear()
	check(Catalogue.canonicalize(fixtures()).canonical_json.sha256_text() == fingerprint, "mutating canonical input/output cannot change future fingerprint")
	var renamed := fixtures()
	renamed[0].display_name_zh = "中文展示文字改名"
	var renamed_result: Dictionary = Catalogue.canonicalize(renamed)
	check(renamed_result.success, "display name is presentation, not identity")
	check(Catalogue.resolve("rusted_knife").definition == fixtures()[0], "pure candidate validation cannot install changed metadata")
	evidence.append({"stage": "definition_fingerprint", "sha256": fingerprint, "definition_count": expected.size(), "permutations": 12})

func query_noise(world: WorldState, reverse: bool) -> void:
	var before := world.to_canonical_json()
	var rows := fixtures()
	if reverse:
		rows.reverse()
	for row in rows:
		var result: Dictionary = Catalogue.resolve(row.item_id)
		check(result.success, "interleaved real lookup succeeds")
		result.definition.tags.append("caller_only")
		result.definition.base_weight = 1
		Art.resolve(row.asset_id)
	Catalogue.canonicalize(rows)
	Catalogue.resolve("crowbar")
	check(world.to_canonical_json() == before, "definition reads cannot alter inventory/capacity/HP/time/world")

func no_definition_data(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			if str(key) in ["item_definitions", "item_catalogue", "item_schema_version", "item_id", "asset_id", "base_weight", "display_name_zh", "stack_mode"]:
				return false
			if not no_definition_data(value[key]):
				return false
	elif value is Array:
		for child in value:
			if not no_definition_data(child):
				return false
	return true

func checkpoint(a: WorldState, b: WorldState, stage: String) -> void:
	var sha_a := a.to_canonical_json().sha256_text()
	var sha_b := b.to_canonical_json().sha256_text()
	check(sha_a == sha_b, "uninterrupted vs restored world SHA: " + stage)
	for world in [a, b]:
		check(engine.validate_invariants(world) == "", "global life/resource/authority invariants: " + stage)
		check(no_definition_data(world.to_dict()), "world save has no copied item definitions: " + stage)
		check(world.player.capacity_total == 20, "container definition cannot grant capacity: " + stage)
		check(world.player.inventory.to_dict().keys().size() == 4, "resource inventory remains four aggregates: " + stage)
		check(world.to_dict().progression_schema_version == 1 and world.to_dict().field_schema_version == 1, "existing persistence schema versions unchanged")
	evidence.append({"stage": stage, "day": a.current_day, "sha256_a": sha_a, "sha256_b": sha_b})

func restore(world: WorldState) -> WorldState:
	var before := world.to_canonical_json()
	var result := WorldState.from_json_checked(before)
	check(result.success and not result.migrated, "modern full world reloads without migration")
	if not result.success:
		return world
	check(result.world.to_canonical_json() == before, "world save/load/save fixed point")
	return result.world

func new_world() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "物品契約測試", "age": 25, "background_id": "MECHANIC", "trait_ids": ["CAUTIOUS"]}))
	check(result.success, "replay uses real CharacterCreationIntent")
	return world

func run_world_replay() -> void:
	var a := new_world()
	var b := new_world()
	query_noise(a, false)
	query_noise(b, true)
	checkpoint(a, b, "created")
	for world in [a, b]:
		var town: SettlementState = world.get_settlement(&"settlement:gray_valley")
		var water_before: int = town.inventory.water + world.player.inventory.water
		var money_before: int = town.market_cash + world.player.money
		check(engine.execute_player_buy(world, &"water", 1).success, "real resource BUY succeeds")
		check(engine.execute_player_sell(world, &"water", 1).success, "real resource SELL succeeds")
		check(town.inventory.water + world.player.inventory.water == water_before and town.market_cash + world.player.money == money_before, "trade conserves commodity and currency")
		check(world.current_day == 0 and world.player.inventory.water == 5 and world.player.inventory.food == 5, "trade is timeless and returns backpack to initial aggregate amounts")
	query_noise(a, true)
	b = restore(b)
	checkpoint(a, b, "traded_and_reloaded")
	# Approved encounter fixture: day 1 / index 1 wreck pays 5 scrap and 2 fuel.
	# Only encounter placement is fixed; all population, time, costs and receipts use
	# the real authorities, including pause until confirmation and continuation.
	for world in [a, b]:
		check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success, "real departure succeeds")
		world.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, 1, &"settlement:gray_valley", &"settlement:new_hope", 1)
	checkpoint(a, b, "departed_at_wreck")
	query_noise(b, false)
	for world in [a, b]:
		var result := engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"SEARCH"))
		check(result.success and result.gained == {"scrap": 5, "fuel": 2} and result.spent == {"water": 1, "food": 1} and result.elapsed_days == 1, "search preserves independent payout/time/metabolism fixture")
		check(world.current_day == 1 and world.player.inventory.water == 4 and world.player.inventory.food == 4 and world.pending_encounter_result >= 0, "search waits for result confirmation")
	b = restore(b)
	checkpoint(a, b, "pending_receipt_reloaded")
	for world in [a, b]:
		var before: String = world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_wait(world.player.npc_id)).success, "receipt blocks unrelated wait")
		check(world.to_canonical_json() == before, "blocked wait cannot tick or mutate")
	for step in range(10):
		query_noise(a, step % 2 == 0)
		query_noise(b, step % 2 != 0)
		if a.pending_encounter_result >= 0:
			for world in [a, b]:
				check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success, "explicit receipt confirmation succeeds")
		elif a.active_encounter != null:
			var options := TravelEncounter.options(a.active_encounter.encounter_type)
			var option: StringName = options[-1].id
			for world in [a, b]:
				check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option)).success, "later encounter resolves via existing option")
		else:
			break
		b = restore(b)
		checkpoint(a, b, "journey_step_" + str(step))
	var life := a.npc_life_state_registry.get_life_state(a.player.npc_id)
	check(life.status == NpcLifeState.Status.SETTLED and life.population_container_id == &"settlement:new_hope", "confirmation really arrives at destination")
	check(a.current_day > 1 and a.active_encounter == null and a.pending_encounter_result == -1, "journey advanced and cleared pending state")
	# Real empty-supply deprivation on a fresh pair, including mid-exposure save
	# and actual death. Environmental scarcity is a symmetric test fixture only.
	a = new_world()
	b = new_world()
	for world in [a, b]:
		world.player.inventory.water = 0
		world.player.inventory.food = 15
	var saw_deprivation := false
	var saw_death := false
	for day in range(1, 30):
		query_noise(a, false)
		query_noise(b, true)
		for world in [a, b]:
			var town: SettlementState = world.get_settlement(&"settlement:gray_valley")
			town.inventory.water = 0
			town.production.water = 0
			check(engine.execute_player_wait(world).success, "deprivation uses real WAIT lifecycle")
		if a.player.water_exposure > 0.0:
			saw_deprivation = true
		if day == 3:
			b = restore(b)
		checkpoint(a, b, "deprivation_day_" + str(day))
		life = a.npc_life_state_registry.get_life_state(a.player.npc_id)
		if not life.is_alive():
			saw_death = true
			break
	check(saw_deprivation and saw_death, "survival test actually reaches both exposure and death")
	var dehydration_recorded := false
	for event in a.event_log:
		if event.type == "PLAYER_DIED" and event.payload.get("cause") == "dehydration":
			dehydration_recorded = true
	check(dehydration_recorded, "death recorded by survival authority as dehydration")
	b = restore(b)
	for world in [a, b]:
		var before: String = world.to_canonical_json()
		query_noise(world, false)
		check(not engine.execute_player_wait(world).success and world.to_canonical_json() == before, "medkit definition does not heal/revive or permit dead-player actions")
	checkpoint(a, b, "death_reloaded_and_action_refused")
	print("ITEM-1 world replay SHA-256: ", a.to_canonical_json().sha256_text())
