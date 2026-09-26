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
	"KNOWN_HELPER": {
		"name_zh": "救人手法",
		"description_zh": "曾在兩個不同日子真的分出自己的水或糧食給路上的人。之後遇到同樣的人，能先看出對方拿得出什麼回報；不會改變對方拿得出多少，你仍要付出那一份補給。",
	},
	"DEATH_TESTED": {
		"name_zh": "見過底的人",
		"description_zh": "曾在兩個不同日子被打到只剩最後一口氣，而且活著離開。動手之前算得出這一仗要打幾回合、會被打掉多少；不會讓你更強、更不容易被打中，也不會多掉東西。",
	},
}
# Helping costs a real ration, so these are the only options that count. LEAVE
# and TAKE_PACK are not help, and an option the player could not afford never
# produced a receipt at all.
const HELPING_OPTIONS := ["GIVE_WATER", "HYDRATE", "SHARE_FOOD"]
const Travel = preload("res://simulation/travel_encounter.gd")

static func candidates(events: Array[EventRecord], player_id: StringName, through_day: int) -> Array[String]:
	var water_days := {}
	var useful_search_days := {}
	var helping_days := {}
	# DEATH_TESTED needs two facts from the same day: a turn that really left the
	# player on their last point of health, and a battle on that day that ended
	# with them still alive. Both come from committed receipts; neither is
	# inferred. Keyed by day, so a long fight cannot count itself twice.
	var edge_days := {}
	var survived_days := {}
	for event in events:
		if event.actor_id != player_id or event.day > through_day:
			continue
		if event.type == "FIELD_TURN":
			if int(event.payload.get("taken", 0)) >= 1 and int(event.payload.get("hp", -1)) == 1:
				edge_days[event.day] = true
		elif event.type == "FIELD_RESULT":
			if String(event.payload.get("outcome", "")) != "DEAD":
				survived_days[event.day] = true
		if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and String(event.payload.get("option", "")) in HELPING_OPTIONS and Travel.valid_resolution(event.payload):
			# The receipt must show the ration actually leaving the pack. An
			# option chosen is not help; a cost paid is. The same distinct-day
			# rule as SCAVENGER_INSTINCT: receipts carry a day, not an identity
			# for the person helped, so two encounters on one day prove one day
			# of lived practice, not two people.
			var spent: Dictionary = event.payload.get("spent", {})
			if int(spent.get("water", 0)) >= 1 or int(spent.get("food", 0)) >= 1:
				helping_days[event.day] = true
		if event.type == "PLAYER_NEED_UNMET":
			if event.target_id == &"road" and typeof(event.payload.get("water_unmet")) in [TYPE_FLOAT, TYPE_INT] and float(event.payload.water_unmet) > 0.0 and float(event.payload.water_unmet) <= 1.0:
				water_days[event.day] = true
		elif event.type == "TRAVEL_ENCOUNTER_RESOLVED":
			if event.payload.get("encounter_type") == "WRECK" and event.payload.get("option") == "SEARCH" and Travel.valid_resolution(event.payload) and (not event.payload.gained.is_empty() or not event.payload.get("items_gained", {}).is_empty()):
				# Old encounter receipts identify a search day and route, but carry no
				# physical wreck ID. Count lived practice on distinct days; do not
				# claim that returning to the same roadside wreck proves a new site.
				useful_search_days[event.day] = true
	# Appended in ID order so the candidate list is stable for the sheet.
	var out: Array[String] = []
	var tested_days := 0
	for day in edge_days:
		if survived_days.has(day):
			tested_days += 1
	if tested_days >= 2:
		out.append("DEATH_TESTED")
	if water_days.size() >= 2:
		out.append("DESERT_HARDENED")
	# Two days rather than three: a wreck is common roadside furniture, but a
	# dying traveller or a refugee column is not, so the same bar would make
	# this identity unreachable in a normal run rather than merely demanding.
	if helping_days.size() >= 2:
		out.append("KNOWN_HELPER")
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
		if event.actor_id == player_id and event.type in ["PLAYER_NEED_UNMET", "ACQUIRED_TRAIT_ACCEPTED", "TRAVEL_ENCOUNTER_RESOLVED", "FIELD_TURN", "FIELD_RESULT"] and (event.day < 0 or event.day > current_day):
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
