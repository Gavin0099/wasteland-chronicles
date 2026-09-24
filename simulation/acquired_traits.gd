class_name AcquiredTraits
extends RefCounted

# This-life identities are separate from creation traits and level perks.
# A candidate is derived from committed history; selecting it is a new fact.
const TRAITS := {
	"DESERT_HARDENED": {
		"name_zh": "荒野歷練",
		"description_zh": "曾在路上兩天缺水。遇到崩塌路段可消耗 1 份食物趕路，不延誤；沒有食物時無法使用。",
	},
	"SCAVENGER_INSTINCT": {
		"name_zh": "拾荒直覺",
		"description_zh": "曾在三個不同日子搜尋殘骸並帶走收穫。搜尋前能判讀徒手搜索可找到什麼；不會增加收穫，背包仍可能裝不下。",
	},
}
const Travel = preload("res://simulation/travel_encounter.gd")

static func candidates(events: Array[EventRecord], player_id: StringName, through_day: int) -> Array[String]:
	var water_days := {}
	var useful_search_days := {}
	for event in events:
		if event.actor_id != player_id or event.day > through_day:
			continue
		if event.type == "PLAYER_NEED_UNMET":
			if event.target_id == &"road" and typeof(event.payload.get("water_unmet")) in [TYPE_FLOAT, TYPE_INT] and float(event.payload.water_unmet) > 0.0 and float(event.payload.water_unmet) <= 1.0:
				water_days[event.day] = true
		elif event.type == "TRAVEL_ENCOUNTER_RESOLVED":
			if event.payload.get("encounter_type") == "WRECK" and event.payload.get("option") == "SEARCH" and Travel.valid_resolution(event.payload) and (not event.payload.gained.is_empty() or not event.payload.get("items_gained", {}).is_empty()):
				# Old encounter receipts identify a search day and route, but carry no
				# physical wreck ID. Count lived practice on distinct days; do not
				# claim that returning to the same roadside wreck proves a new site.
				useful_search_days[event.day] = true
	var out: Array[String] = []
	if water_days.size() >= 2:
		out.append("DESERT_HARDENED")
	if useful_search_days.size() >= 3:
		out.append("SCAVENGER_INSTINCT")
	return out

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
		if event.actor_id == player_id and event.type in ["PLAYER_NEED_UNMET", "ACQUIRED_TRAIT_ACCEPTED", "TRAVEL_ENCOUNTER_RESOLVED"] and (event.day < 0 or event.day > current_day):
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
