class_name AcquiredTraits
extends RefCounted

# This-life identities are separate from creation traits and level perks.
# A candidate is derived from committed history; selecting it is a new fact.
const TRAITS := {
	"DESERT_HARDENED": {
		"name_zh": "荒野歷練",
		"description_zh": "曾在路上兩天缺水。遇到崩塌路段可消耗 1 份食物趕路，不延誤；沒有食物時無法使用。",
	}
}

static func candidates(events: Array[EventRecord], player_id: StringName, through_day: int) -> Array[String]:
	var water_days := {}
	for event in events:
		if event.actor_id != player_id or event.type != "PLAYER_NEED_UNMET" or event.day > through_day:
			continue
		if event.target_id != &"road" or typeof(event.payload.get("water_unmet")) not in [TYPE_FLOAT, TYPE_INT]:
			continue
		if float(event.payload.water_unmet) > 0.0 and float(event.payload.water_unmet) <= 1.0:
			water_days[event.day] = true
	return ["DESERT_HARDENED"] if water_days.size() >= 2 else []

static func validate_selection(raw: Variant) -> String:
	if typeof(raw) != TYPE_ARRAY:
		return "INVALID_ACQUIRED_TRAITS"
	var previous := ""
	for id in raw:
		if typeof(id) != TYPE_STRING or not TRAITS.has(id) or (previous != "" and id <= previous):
			return "INVALID_ACQUIRED_TRAIT_ID_OR_ORDER"
		previous = id
	return ""

static func validate_history(ids: Array[String], events: Array[EventRecord], player_id: StringName, current_day: int) -> String:
	var seen: Array[String] = []
	var prefix: Array[EventRecord] = []
	var need_days := {}
	for event in events:
		if event.actor_id == player_id and event.type in ["PLAYER_NEED_UNMET", "ACQUIRED_TRAIT_ACCEPTED"] and (event.day < 0 or event.day > current_day):
			return "ACQUIRED_TRAIT_LEDGER_DAY_INVALID"
		if event.actor_id == player_id and event.type == "PLAYER_NEED_UNMET":
			var water: Variant = event.payload.get("water_unmet")
			var food: Variant = event.payload.get("food_unmet")
			if event.target_id != &"road" or event.payload.size() != 2 or typeof(water) not in [TYPE_FLOAT, TYPE_INT] or typeof(food) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(water)) or not is_finite(float(food)) or float(water) < 0.0 or float(water) > 1.0 or float(food) < 0.0 or float(food) > 1.0 or (float(water) == 0.0 and float(food) == 0.0) or need_days.has(event.day):
				return "ACQUIRED_TRAIT_NEED_LEDGER_MALFORMED"
			need_days[event.day] = true
		if event.actor_id == player_id and event.type == "ACQUIRED_TRAIT_ACCEPTED":
			var id: Variant = event.payload.get("trait_id")
			if event.target_id != &"character" or typeof(id) != TYPE_STRING or not TRAITS.has(id) or seen.has(id) or not candidates(prefix, player_id, event.day).has(id):
				return "ACQUIRED_TRAIT_LEDGER_MALFORMED"
			seen.append(id)
		prefix.append(event)
	seen.sort()
	if seen != ids:
		return "ACQUIRED_TRAIT_LEDGER_MISMATCH"
	return ""
