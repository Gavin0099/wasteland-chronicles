class_name QuestDefinition
extends RefCounted

# ==============================================================================
# QUEST-1A: QUEST DEFINITION CONTRACT
# ==============================================================================
# A QuestDefinition is IMMUTABLE content — the authored spec of what a quest is,
# what it wants, and what it gives. It is never mutated at runtime.
#
# Runtime progress and status live in QuestState (quest_state.gd).
# The registry that holds these definitions is QuestRegistry (quest_registry.gd).
#
# OBJECTIVE TYPES (v1 only):
#   HAVE_ITEM      — player.item_inventory contains >= quantity of item_id
#   DELIVER_ITEM   — player delivers item_id to settlement_id (quantity)
#   WORLD_FLAG     — world.quest_flags[flag_name] == true
#   VISIT_LOCATION — player has visited settlement_id (checked via event log)
#   DELIVER_RESOURCE — player hands over aggregate cargo (water/food/scrap/fuel)
#                      at settlement_id. The cargo leaves the pack; it does NOT
#                      enter the settlement's inventory. The world's response to
#                      player action is QUEST-W1 and is deliberately not here.
#   WIN_ROAD_COMBAT  — player won a road battle on origin_id->destination_id
#                      AFTER accepting, proven by a committed FIELD_RESULT.
#                      Paying the bandits off or running away does not count.
#
# OUTCOME KEYS: resolved | failed | expired
#
# REWARD TYPES (v1):
#   XP       — issues XP to world.player.xp via QuestEngine
#   CURRENCY — issues caps to world.player.money via QuestEngine
#
# WORLD EFFECTS (v1 only): SET_FLAG
#
# Reward format (list-based, extensible):
#   "rewards": [
#     { "type": "XP",       "amount": 60 },
#     { "type": "CURRENCY", "amount": 50 },
#   ]
#
# Deferred: PAUSED, ABANDONED, HIDDEN, escort, branching dialogue,
#           faction reputation, skill checks.
# FUN-1 supplies repeatability a different way: instead of a REPEATABLE flag on
# one definition, the job board GENERATES fresh definitions from world state on
# a rotating window, so the same livelihood keeps producing new contracts.
# ==============================================================================

const VALID_OBJECTIVE_TYPES: Array[StringName] = [
	&"HAVE_ITEM",
	&"DELIVER_ITEM",
	&"WORLD_FLAG",
	&"VISIT_LOCATION",
	# FUN-1. Aggregate survival cargo is not an item, so a town that has run
	# short of water could never post work about it with DELIVER_ITEM alone.
	&"DELIVER_RESOURCE",
	# FUN-1. The first objective that is satisfied by something the player DID
	# rather than something they carry, checked against committed FIELD_RESULT
	# receipts on the named road.
	&"WIN_ROAD_COMBAT",
]
const VALID_OBJECTIVE_RESOURCES: Array[String] = ["water", "food", "scrap", "fuel"]

const VALID_OUTCOME_KEYS: Array[String] = ["resolved", "failed", "expired"]
const VALID_REWARD_TYPES: Array[StringName] = [&"XP", &"CURRENCY"]
const VALID_WORLD_EFFECT_TYPES: Array[StringName] = [&"SET_FLAG"]

# Returns "" on success, or an error token on the first problem found.
static func validate_definition(raw: Variant) -> String:
	if typeof(raw) != TYPE_DICTIONARY:
		return "QUEST_DEF_NOT_DICT"

	# ── Identity ──────────────────────────────────────────────────────────────
	if not _stable_id(raw.get("id")):
		return "QUEST_DEF_INVALID_ID"
	for label_field in ["title_zh", "description_zh"]:
		if typeof(raw.get(label_field)) != TYPE_STRING or String(raw[label_field]).strip_edges().is_empty():
			return "QUEST_DEF_INVALID_%s" % label_field.to_upper()
	if not _stable_id(raw.get("settlement_id")):
		return "QUEST_DEF_INVALID_SETTLEMENT_ID"
	# issuer_npc_id may be empty string (anonymous issuer), but must be a string
	var issuer: Variant = raw.get("issuer_npc_id")
	if typeof(issuer) != TYPE_STRING:
		return "QUEST_DEF_INVALID_ISSUER"

	# ── Availability ──────────────────────────────────────────────────────────
	var avail: Variant = raw.get("availability")
	if typeof(avail) != TYPE_DICTIONARY:
		return "QUEST_DEF_INVALID_AVAILABILITY"
	var req_day: Variant = avail.get("required_day")
	if typeof(req_day) not in [TYPE_INT, TYPE_FLOAT] or req_day != floor(float(req_day)) or req_day < 0:
		return "QUEST_DEF_INVALID_AVAILABILITY_DAY"
	var req_flags: Variant = avail.get("required_flags")
	if typeof(req_flags) != TYPE_ARRAY:
		return "QUEST_DEF_INVALID_AVAILABILITY_FLAGS"
	for f in req_flags:
		if typeof(f) != TYPE_STRING or f.is_empty():
			return "QUEST_DEF_INVALID_AVAILABILITY_FLAG_TOKEN"
	if avail.has("required_equipped_item_id") and not _stable_id(avail.required_equipped_item_id):
		return "QUEST_DEF_INVALID_EQUIPPED_ITEM_ID"

	# ── Deadline ──────────────────────────────────────────────────────────────
	var ddl: Variant = raw.get("deadline_days")
	if typeof(ddl) not in [TYPE_INT, TYPE_FLOAT] or ddl != floor(float(ddl)) or int(ddl) < 1:
		return "QUEST_DEF_INVALID_DEADLINE_DAYS"

	# ── Objectives ────────────────────────────────────────────────────────────
	var objs: Variant = raw.get("objectives")
	if typeof(objs) != TYPE_ARRAY or objs.is_empty():
		return "QUEST_DEF_INVALID_OBJECTIVES"
	var seen_obj_ids: Dictionary = {}
	for obj in objs:
		var obj_err := _validate_objective(obj, seen_obj_ids)
		if obj_err != "":
			return obj_err

	# ── Outcomes ─────────────────────────────────────────────────────────────
	var outcomes: Variant = raw.get("outcomes")
	if typeof(outcomes) != TYPE_DICTIONARY:
		return "QUEST_DEF_INVALID_OUTCOMES"
	for key in VALID_OUTCOME_KEYS:
		if not outcomes.has(key):
			return "QUEST_DEF_MISSING_OUTCOME_%s" % key.to_upper()
		var out_err := _validate_outcome(outcomes[key])
		if out_err != "":
			return out_err

	return validate_salvage_target(raw)

# Optional on pre-PLAY-3A contracts; once present, the complete site is required.
static func validate_salvage_target(raw: Dictionary) -> String:
	var fields: Array[String] = ["target_site", "target_route_origin", "target_route_destination", "target_item_id", "route_days", "source_wreck_id"]
	var has_target: bool = false
	for field in fields:
		has_target = has_target or raw.has(field)
	if not has_target:
		return ""
	for field in fields:
		if not raw.has(field):
			return "SALVAGE_TARGET_INCOMPLETE"
		if field != "route_days" and (typeof(raw[field]) != TYPE_STRING or String(raw[field]).strip_edges().is_empty()):
			return "SALVAGE_TARGET_INVALID_" + field.to_upper()
	var days: Variant = raw.route_days
	if typeof(days) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(days)) or days != floor(float(days)) or days < 1:
		return "SALVAGE_TARGET_INVALID_ROUTE_DAYS"
	if not String(raw.id).begins_with("job_") or not _stable_id(raw.target_route_origin) or not _stable_id(raw.target_route_destination) or raw.target_route_origin != raw.settlement_id or raw.target_route_origin == raw.target_route_destination:
		return "SALVAGE_TARGET_INVALID_ROUTE"
	if not _stable_id(raw.target_item_id) or raw.objectives.size() != 1:
		return "SALVAGE_TARGET_INVALID_ITEM"
	var objective: Dictionary = raw.objectives[0]
	if objective.get("type") != "DELIVER_ITEM" or objective.get("item_id") != raw.target_item_id or objective.get("settlement_id") != raw.settlement_id or objective.get("quantity") != 1:
		return "SALVAGE_TARGET_OBJECTIVE_MISMATCH"
	var prefix: String = "salvage:%s:%s_%s:" % [raw.id, raw.target_route_origin, raw.target_route_destination]
	if not String(raw.source_wreck_id).begins_with(prefix):
		return "SALVAGE_TARGET_SOURCE_MISMATCH"
	var suffix: String = String(raw.source_wreck_id).trim_prefix(prefix)
	if suffix.is_empty():
		return "SALVAGE_TARGET_SOURCE_MISMATCH"
	for character in suffix:
		if character not in "0123456789_":
			return "SALVAGE_TARGET_SOURCE_MISMATCH"
	return ""

# ── Private helpers ────────────────────────────────────────────────────────────

static func _validate_objective(obj: Variant, seen: Dictionary) -> String:
	if typeof(obj) != TYPE_DICTIONARY:
		return "QUEST_OBJ_NOT_DICT"
	var otype: Variant = obj.get("type")
	if typeof(otype) != TYPE_STRING or StringName(otype) not in VALID_OBJECTIVE_TYPES:
		return "QUEST_OBJ_INVALID_TYPE"
	# Each objective must have a stable local id for progress tracking
	var oid: Variant = obj.get("id")
	if not _stable_id(oid):
		return "QUEST_OBJ_INVALID_ID"
	if seen.has(oid):
		return "QUEST_OBJ_DUPLICATE_ID"
	seen[oid] = true
	# Type-specific field validation
	match StringName(otype):
		&"HAVE_ITEM", &"DELIVER_ITEM":
			if not _stable_id(obj.get("item_id")):
				return "QUEST_OBJ_INVALID_ITEM_ID"
			var qty: Variant = obj.get("quantity")
			if typeof(qty) not in [TYPE_INT, TYPE_FLOAT] or qty != floor(float(qty)) or int(qty) < 1:
				return "QUEST_OBJ_INVALID_QUANTITY"
			if StringName(otype) == &"DELIVER_ITEM":
				if not _stable_id(obj.get("settlement_id")):
					return "QUEST_OBJ_INVALID_SETTLEMENT_ID"
		&"WORLD_FLAG":
			var flag: Variant = obj.get("flag")
			if typeof(flag) != TYPE_STRING or flag.is_empty():
				return "QUEST_OBJ_INVALID_FLAG"
		&"VISIT_LOCATION":
			if not _stable_id(obj.get("settlement_id")):
				return "QUEST_OBJ_INVALID_SETTLEMENT_ID"
		&"DELIVER_RESOURCE":
			var resource: Variant = obj.get("resource")
			if typeof(resource) != TYPE_STRING or not VALID_OBJECTIVE_RESOURCES.has(resource):
				return "QUEST_OBJ_INVALID_RESOURCE"
			var rqty: Variant = obj.get("quantity")
			if typeof(rqty) not in [TYPE_INT, TYPE_FLOAT] or rqty != floor(float(rqty)) or int(rqty) < 1:
				return "QUEST_OBJ_INVALID_QUANTITY"
			if not _stable_id(obj.get("settlement_id")):
				return "QUEST_OBJ_INVALID_SETTLEMENT_ID"
		&"WIN_ROAD_COMBAT":
			for endpoint in ["origin_id", "destination_id"]:
				if not _stable_id(obj.get(endpoint)):
					return "QUEST_OBJ_INVALID_SETTLEMENT_ID"
			if String(obj.get("origin_id")) == String(obj.get("destination_id")):
				return "QUEST_OBJ_INVALID_ROUTE"
			var wqty: Variant = obj.get("quantity")
			if typeof(wqty) not in [TYPE_INT, TYPE_FLOAT] or wqty != floor(float(wqty)) or int(wqty) < 1:
				return "QUEST_OBJ_INVALID_QUANTITY"
	return ""

static func _validate_outcome(out: Variant) -> String:
	if typeof(out) != TYPE_DICTIONARY:
		return "QUEST_OUTCOME_NOT_DICT"
	# rewards: Array of { type, amount } — may be empty (e.g. expired)
	var rewards: Variant = out.get("rewards")
	if typeof(rewards) != TYPE_ARRAY:
		return "QUEST_OUTCOME_INVALID_REWARDS"
	for r in rewards:
		var r_err := _validate_reward_entry(r)
		if r_err != "":
			return r_err
	# world_effects: Array of { type, ... }
	var effects: Variant = out.get("world_effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return "QUEST_OUTCOME_INVALID_WORLD_EFFECTS"
	for fx in effects:
		var fx_err := _validate_world_effect(fx)
		if fx_err != "":
			return fx_err
	return ""

static func _validate_reward_entry(r: Variant) -> String:
	if typeof(r) != TYPE_DICTIONARY:
		return "QUEST_REWARD_NOT_DICT"
	var rtype: Variant = r.get("type")
	if typeof(rtype) != TYPE_STRING or StringName(rtype) not in VALID_REWARD_TYPES:
		return "QUEST_REWARD_INVALID_TYPE"
	var amount: Variant = r.get("amount")
	if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or amount != floor(float(amount)) or int(amount) < 0:
		return "QUEST_REWARD_INVALID_AMOUNT"
	return ""

static func _validate_world_effect(fx: Variant) -> String:
	if typeof(fx) != TYPE_DICTIONARY:
		return "QUEST_WORLD_EFFECT_NOT_DICT"
	var ftype: Variant = fx.get("type")
	if typeof(ftype) != TYPE_STRING or StringName(ftype) not in VALID_WORLD_EFFECT_TYPES:
		return "QUEST_WORLD_EFFECT_INVALID_TYPE"
	match StringName(ftype):
		&"SET_FLAG":
			var flag: Variant = fx.get("flag")
			if typeof(flag) != TYPE_STRING or flag.is_empty():
				return "QUEST_WORLD_EFFECT_INVALID_FLAG"
	return ""

# A stable identifier: lowercase letters, digits (not first), underscores (not first).
static func _stable_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.is_empty():
		return false
	for index in range(value.length()):
		var code: int = value.unicode_at(index)
		if not ((code >= 97 and code <= 122) or (index > 0 and (code == 95 or (code >= 48 and code <= 57)))):
			return false
	return true
