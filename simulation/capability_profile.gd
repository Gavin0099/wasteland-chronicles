class_name CapabilityProfile
extends RefCounted

const SKILLS := ["BARTER", "ELECTRONICS", "FIREARMS", "MECHANICS", "MEDICINE", "MELEE", "SCAVENGING", "SPEECH", "STEALTH", "SURVIVAL"]
const CORE_TRAITS := ["AGGRESSIVE", "CAUTIOUS", "COMPASSIONATE", "CURIOUS", "GREEDY", "IRON_STOMACH", "LIGHT_SLEEPER", "LONER", "LOYAL", "PACIFIST", "RECKLESS", "STUBBORN", "SUSPICIOUS", "VIGILANT"]
# Practice required at ranks 0..4. A rank-5 skill cannot advance further.
const PRACTICE_TO_ADVANCE := [2, 3, 4, 5, 6]
var _data: Dictionary = {}

static func legacy(npc_id: StringName) -> RefCounted:
	var ranks := {}
	for skill in SKILLS:
		ranks[skill] = 0
	return from_dict_checked({"npc_id": String(npc_id), "creation_origin": "LEGACY_MIGRATION", "skill_ranks": ranks, "selected_creation_traits": [], "background_id": "", "package_version": 0}).profile

static func validate_traits(raw: Variant) -> String:
	if typeof(raw) != TYPE_ARRAY or raw.size() > 2:
		return "INVALID_CORE_TRAIT_COUNT"
	var seen := {}
	for trait_id in raw:
		if typeof(trait_id) != TYPE_STRING or trait_id not in CORE_TRAITS or seen.has(trait_id):
			return "INVALID_OR_DUPLICATE_CORE_TRAIT"
		seen[trait_id] = true
	return ""

static func from_dict_checked(raw: Variant) -> Dictionary:
	var error := validate(raw)
	if error != "":
		return {"success": false, "profile": null, "error": error}
	var profile = load("res://simulation/capability_profile.gd").new()
	profile._data = raw.duplicate(true)
	profile._data.selected_creation_traits.sort() # Validated String IDs only.
	profile._data.package_version = int(raw.package_version)
	if profile._data.has("skill_practice"):
		profile._data.skill_growth_schema_version = 1
		for skill in profile._data.skill_practice:
			profile._data.skill_practice[skill].points = int(profile._data.skill_practice[skill].points)
			profile._data.skill_practice[skill].last_day = int(profile._data.skill_practice[skill].last_day)
	return {"success": true, "profile": profile, "error": ""}

static func validate(raw: Variant) -> String:
	if typeof(raw) != TYPE_DICTIONARY:
		return "INVALID_CAPABILITY_PROFILE"
	var fields := ["npc_id", "creation_origin", "skill_ranks", "selected_creation_traits", "background_id", "package_version"]
	var has_growth: bool = raw.has("skill_practice") or raw.has("skill_growth_schema_version")
	if raw.size() != fields.size() + (2 if has_growth else 0):
		return "INVALID_CAPABILITY_FIELDS"
	for key in fields:
		if not raw.has(key):
			return "MISSING_CAPABILITY_FIELD: " + key
	if typeof(raw.npc_id) != TYPE_STRING or raw.npc_id.is_empty():
		return "INVALID_CAPABILITY_OWNER"
	if typeof(raw.creation_origin) != TYPE_STRING or raw.creation_origin not in ["CHARACTER_CREATION", "LEGACY_MIGRATION"]:
		return "INVALID_CREATION_ORIGIN"
	if typeof(raw.skill_ranks) != TYPE_DICTIONARY or raw.skill_ranks.size() != SKILLS.size():
		return "INVALID_SKILL_KEYS"
	for skill in SKILLS:
		if not raw.skill_ranks.has(skill):
			return "INVALID_SKILL_KEYS"
		var rank: Variant = raw.skill_ranks[skill]
		if typeof(rank) != TYPE_INT or rank < 0 or rank > 5:
			return "INVALID_SKILL_RANK: " + skill
	if has_growth:
		if raw.creation_origin == "LEGACY_MIGRATION":
			return "INVALID_LEGACY_PRACTICE"
		if not raw.has("skill_practice") or not raw.has("skill_growth_schema_version") or typeof(raw.skill_growth_schema_version) not in [TYPE_INT, TYPE_FLOAT] or raw.skill_growth_schema_version != 1 or typeof(raw.skill_practice) != TYPE_DICTIONARY:
			return "INVALID_SKILL_GROWTH_SCHEMA"
		for skill in raw.skill_practice:
			if typeof(skill) != TYPE_STRING or skill not in SKILLS:
				return "INVALID_PRACTICE_SKILL"
			var record: Variant = raw.skill_practice[skill]
			if typeof(record) != TYPE_DICTIONARY or record.size() != 2 or not record.has("points") or not record.has("last_day"):
				return "INVALID_PRACTICE_RECORD"
			for field in ["points", "last_day"]:
				var value: Variant = record[field]
				if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) != floor(float(value)):
					return "INVALID_PRACTICE_INTEGER"
			var current_rank: int = raw.skill_ranks[skill]
			var max_points: int = 0 if current_rank == 5 else PRACTICE_TO_ADVANCE[current_rank] - 1
			if record.points < 0 or record.points > max_points or record.last_day < 0 or record.last_day > NumericCanon.MAX_SAFE_INT:
				return "INVALID_PRACTICE_RANGE"
	var trait_error := validate_traits(raw.selected_creation_traits)
	if trait_error != "":
		return trait_error
	if typeof(raw.background_id) != TYPE_STRING:
		return "INVALID_BACKGROUND_SOURCE"
	var version: Variant = raw.package_version
	if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(version)):
		return "INVALID_PACKAGE_VERSION"
	if raw.creation_origin == "LEGACY_MIGRATION":
		if raw.background_id != "" or version != 0 or not raw.selected_creation_traits.is_empty():
			return "INVALID_LEGACY_PROVENANCE"
	else:
		if raw.background_id not in ["CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER"] or version != 1:
			return "INVALID_BACKGROUND_SOURCE"
	return ""

func to_dict() -> Dictionary:
	return _data.duplicate(true)

func duplicate_profile() -> RefCounted:
	return from_dict_checked(_data).profile

func get_skill_rank(skill_id: Variant) -> Dictionary:
	var error := validate(_data)
	if error != "":
		return {"success": false, "error": error}
	if typeof(skill_id) != TYPE_STRING or skill_id not in SKILLS:
		return {"success": false, "error": "UNKNOWN_SKILL"}
	return {"success": true, "rank": _data.skill_ranks[skill_id], "error": ""}

func get_practice_progress(skill_id: Variant) -> Dictionary:
	var rank_result := get_skill_rank(skill_id)
	if not rank_result.success:
		return rank_result
	var rank: int = rank_result.rank
	var record: Dictionary = _data.get("skill_practice", {}).get(skill_id, {})
	return {"success": true, "rank": rank, "points": int(record.get("points", 0)),
		"required": PRACTICE_TO_ADVANCE[rank] if rank < 5 else 0, "error": ""}

# Only the owning profile can advance a skill. The caller must first commit a
# real skill-use action; the same skill earns at most one practice point per day.
func grant_practice(skill_id: Variant, day: Variant) -> Dictionary:
	var progress := get_practice_progress(skill_id)
	if not progress.success:
		return {"success": false, "error": progress.error}
	if typeof(day) != TYPE_INT or day < 0 or day > NumericCanon.MAX_SAFE_INT:
		return {"success": false, "error": "INVALID_PRACTICE_DAY"}
	var result := {"success": true, "skill_id": skill_id, "awarded": false,
		"rank_up": false, "from_rank": progress.rank, "to_rank": progress.rank,
		"points": progress.points, "required": progress.required}
	if _data.creation_origin == "LEGACY_MIGRATION":
		return result
	if progress.rank == 5:
		return result
	var record: Dictionary = _data.get("skill_practice", {}).get(skill_id, {})
	if int(record.get("last_day", -1)) == day:
		return result
	var next_data: Dictionary = _data.duplicate(true)
	if not next_data.has("skill_practice"):
		next_data["skill_practice"] = {}
		next_data["skill_growth_schema_version"] = 1
	var points: int = progress.points + 1
	var rank: int = progress.rank
	if points >= progress.required:
		rank += 1
		points = 0
		next_data.skill_ranks[skill_id] = rank
		result.rank_up = true
	next_data.skill_practice[skill_id] = {"points": points, "last_day": day}
	_data = next_data
	result.awarded = true
	result.to_rank = rank
	result.points = points
	result.required = PRACTICE_TO_ADVANCE[rank] if rank < 5 else 0
	return result

func meets_skill_requirement(skill_id: Variant, rank: Variant) -> Dictionary:
	return meets_requirements({"all": [{"kind": "skill", "skill_id": skill_id, "min_rank": rank}]})

func has_trait(trait_id: Variant) -> Dictionary:
	var error := validate(_data)
	if error != "":
		return {"success": false, "error": error}
	if typeof(trait_id) != TYPE_STRING or trait_id not in CORE_TRAITS:
		return {"success": false, "error": "UNKNOWN_CORE_TRAIT"}
	return {"success": true, "has": trait_id in _data.selected_creation_traits, "error": ""}

# S5-C2 extends the clause vocabulary from skill-only to skill + Core Trait.
# The skill clause keeps its C1 shape and meaning exactly; trait clauses are a
# separate kind, so an existing caller cannot change behaviour by accident.
# A trait is a yes/no fact about who the character is, never a rank.
func meets_requirements(requirements: Variant) -> Dictionary:
	var error := validate(_data)
	if error != "":
		return {"success": false, "met": false, "error": error}
	if typeof(requirements) != TYPE_DICTIONARY or requirements.size() != 1 or typeof(requirements.get("all")) != TYPE_ARRAY:
		return {"success": false, "met": false, "error": "INVALID_REQUIREMENT_SET"}
	var met := true
	for clause in requirements.all:
		if typeof(clause) != TYPE_DICTIONARY:
			return {"success": false, "met": false, "error": "INVALID_SKILL_REQUIREMENT"}
		match clause.get("kind"):
			"skill":
				if clause.size() != 3 or typeof(clause.get("skill_id")) != TYPE_STRING or clause.skill_id not in SKILLS or typeof(clause.get("min_rank")) != TYPE_INT:
					return {"success": false, "met": false, "error": "INVALID_SKILL_REQUIREMENT"}
				if clause.min_rank < 0 or clause.min_rank > 5:
					return {"success": false, "met": false, "error": "INVALID_SKILL_THRESHOLD"}
				if _data.skill_ranks[clause.skill_id] < clause.min_rank:
					met = false # Continue validation, even if already ineligible.
			"trait_present", "trait_absent":
				if clause.size() != 2 or typeof(clause.get("trait_id")) != TYPE_STRING or clause.trait_id not in CORE_TRAITS:
					return {"success": false, "met": false, "error": "INVALID_TRAIT_REQUIREMENT"}
				var present: bool = clause.trait_id in _data.selected_creation_traits
				if present != (clause.kind == "trait_present"):
					met = false
			_:
				return {"success": false, "met": false, "error": "INVALID_SKILL_REQUIREMENT"}
	return {"success": true, "met": met, "error": ""}
