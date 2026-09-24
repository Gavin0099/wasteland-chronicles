extends RefCounted

# One-time experiential XP is derived from the committed actor's event history.
# The caller puts the returned award in its own result event, so no extra
# mutable marker or independently ordered event is needed.
const FIRST_WRECK_SALVAGE := "FIRST_WRECK_SALVAGE"
const FIRST_FIELD_VICTORY := "FIRST_FIELD_VICTORY"
const Travel = preload("res://simulation/travel_encounter.gd")

# New experiential awards must agree with the committed result that carries
# them. Older quest/legacy XP has no such receipt contract, so only these
# explicitly tagged awards are reconciled against the current profile total.
static func validate_history(events: Array[EventRecord], player_id: StringName, player_xp: int) -> String:
	var seen := {}
	var current_awards := 0
	for event in events:
		var has_source: bool = event.payload.has("xp_source")
		var has_amount: bool = event.payload.has("xp_gained")
		if not has_source and not has_amount:
			continue
		if not has_source or not has_amount or typeof(event.payload.xp_source) != TYPE_STRING:
			return "XP_LEDGER_MALFORMED"
		var amount: Variant = event.payload.xp_gained
		if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(amount)) or float(amount) != floor(float(amount)):
			return "XP_LEDGER_MALFORMED"
		var source: String = event.payload.xp_source
		match source:
			FIRST_WRECK_SALVAGE:
				if event.type != "TRAVEL_ENCOUNTER_RESOLVED" or event.payload.get("encounter_type") != "WRECK" or event.payload.get("option") not in ["SEARCH", "SORT_WRECK", "STRIP_PARTS", "USE_WRENCH", "QUICK_PICK"] or int(amount) != 10 or not Travel.valid_resolution(event.payload):
					return "XP_LEDGER_INVALID_SALVAGE"
				var goods: Variant = event.payload.get("gained", {})
				var items: Variant = event.payload.get("items_gained", {})
				if typeof(goods) != TYPE_DICTIONARY or typeof(items) != TYPE_DICTIONARY or (goods.is_empty() and items.is_empty()):
					return "XP_LEDGER_INVALID_SALVAGE"
			FIRST_FIELD_VICTORY:
				if event.type != "FIELD_RESULT" or event.payload.get("outcome") != "VICTORY" or int(amount) != 15:
					return "XP_LEDGER_INVALID_VICTORY"
			_:
				return "XP_LEDGER_UNKNOWN_SOURCE"
		var key := "%s|%s" % [String(event.actor_id), source]
		if seen.has(key):
			return "XP_LEDGER_DUPLICATE"
		seen[key] = true
		if event.actor_id == player_id:
			current_awards += int(amount)
	if current_awards > player_xp:
		return "XP_LEDGER_EXCEEDS_PLAYER_XP"
	return ""

static func award_once(world, event_type: String, source_id: String, amount: int) -> int:
	for event in world.event_log:
		if event.type == event_type and event.actor_id == world.player.npc_id and event.payload.get("xp_source", "") == source_id:
			return 0
	world.player.xp += amount
	return amount
