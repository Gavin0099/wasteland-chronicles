extends SceneTree

const Catalogue = preload("res://simulation/item_catalogue.gd")
const Definition = preload("res://simulation/item_definition.gd")
const Source = preload("res://game_data/item_definitions.gd")
const Art = preload("res://game_data/item_art_references.gd")
var checks := 0
var failures: Array[String] = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func _initialize() -> void:
	var baseline: Dictionary = Catalogue.canonicalize(Source.rows())
	expect(baseline.success and baseline.definitions.size() == 12, "fixed twelve valid")
	var original_json: String = baseline.canonical_json
	for definition in baseline.definitions:
		var asset := Art.resolve(definition.asset_id)
		expect(asset.success and FileAccess.file_exists(asset.path), "existing asset " + definition.item_id)
	for invalid in [null, false, 12, 1.0, "bad", &"item_id", Vector2(1, 2), [], RefCounted.new()]:
		expect(Definition.validate(invalid) != "", "malformed row " + str(typeof(invalid)))
		expect(not Catalogue.canonicalize(invalid).success, "malformed catalogue " + str(typeof(invalid)))
		expect(not Catalogue.resolve(invalid).success, "unknown lookup " + str(typeof(invalid)))
		expect(not Art.resolve(invalid).success, "unknown asset " + str(typeof(invalid)))
	var invalid_fields := {
		"item_id": [null, true, 1, 1.0, &"rusted_knife", "", "Rusted_knife", "_knife", "1knife", "rusted-knife", "生鏽小刀", "a\nb"],
		"display_name_zh": [null, true, 1, &"刀", "", " ", "刀 ", " 刀"],
		"category": [null, true, 1, &"WEAPON", "weapon", "HEAVY_WEAPON"],
		"stack_mode": [null, true, 1, &"UNIQUE", "STACK", "unique"],
		"base_weight": [null, true, false, 0, -1, 2.0, "2", INF, NAN],
		"asset_id": [null, true, 1, &"item_rusted_knife", "", "ITEM_RUSTED_KNIFE", "../knife.png"],
		"tags": [null, {}, PackedStringArray(["blade"]), "blade", [null], [1], [true], [&"blade"], ["Blade"], ["blade", "blade"]]
	}
	for field in invalid_fields:
		for value in invalid_fields[field]:
			var candidate := Source.rows()
			candidate[0][field] = value
			var checked := Catalogue.canonicalize(candidate)
			expect(not checked.success and checked.definitions.is_empty() and checked.canonical_json.is_empty(), "atomic reject " + field + ":" + str(value))
	var immutable_input := Source.rows()
	for row in immutable_input:
		row.tags.make_read_only()
		row.make_read_only()
	immutable_input.make_read_only()
	var readonly_result := Catalogue.canonicalize(immutable_input)
	expect(readonly_result.success and readonly_result.canonical_json == original_json, "readonly candidate canonicalizes")
	readonly_result.definitions[0].tags.append("changed")
	readonly_result.definitions[0].display_name_zh = "變更"
	expect(Catalogue.canonicalize(Source.rows()).canonical_json == original_json, "readonly deep clone isolated")
	var candidate := Source.rows()
	var canonical := Catalogue.canonicalize(candidate)
	candidate[0].tags.clear()
	expect(canonical.canonical_json == original_json and canonical.definitions[0].tags.size() > 0, "candidate mutation isolated")
	var altered := Source.rows()
	altered[0].display_name_zh = "示例"
	altered[0].base_weight = 999
	var pure_result := Catalogue.canonicalize(altered)
	expect(pure_result.success, "pure valid candidate accepted")
	expect(Catalogue.resolve("rusted_knife").definition.base_weight == 250, "pure validation never installs")
	var flipped := Source.rows()
	flipped.reverse()
	var reordered: Array = []
	for row in flipped:
		var result := {}
		var fields: Array = row.keys()
		fields.reverse()
		for field in fields:
			result[field] = row[field]
		result.tags.reverse()
		reordered.append(result)
	expect(Catalogue.canonicalize(reordered).canonical_json == original_json, "row key tag order invariant")
	print(JSON.stringify({"checks": checks, "failures": failures, "canonical_sha256": original_json.sha256_text()}))
	quit(0 if failures.is_empty() else 1)
