class_name QuestEngine
extends RefCounted

# ==============================================================================
# QUEST-1D/E/F/G: QUEST LIFECYCLE ENGINE
# ==============================================================================
# All static methods. The engine drives the legal state machine:
#
#   LOCKED → AVAILABLE  (evaluate_availability — read-only query)
#   AVAILABLE → ACTIVE  (accept)
#   ACTIVE → RESOLVED   (resolve)
#   ACTIVE → FAILED     (fail_quest)
#   ACTIVE → EXPIRED    (expire_quest / check_deadlines)
#
# All other transitions fail closed: { success: false, error: "ILLEGAL_QUEST_TRANSITION" }.
#
# IDEMPOTENCY (Gates 6 & 8):
#   resolve() and fail_quest() check QuestState.reward_granted. If already true,
#   they return success without re-applying rewards.
#
# XP AUTHORITY:
#   _apply_reward() issues XP to world.player.xp and caps to world.player.money.
#   The engine does NOT modify skill ranks or growth_points.
#   CHAR-PROG-1 owns the XP → growth_points → skill rank conversion.
#
# REWARD FORMAT (v1 — list-based):
#   "rewards": [
#     { "type": "XP",       "amount": 60 },
#     { "type": "CURRENCY", "amount": 50 },
#   ]
#   "expired" outcome typically has rewards: []
#
# WORLD FLAGS (v1):
#   Only SET_FLAG is supported. Stored in world.quest_flags Dictionary.
# ==============================================================================

const Registry = preload("res://simulation/quest_registry.gd")
const QState   = preload("res://simulation/quest_state.gd")

# ── Availability ──────────────────────────────────────────────────────────────

# Read-only query: returns &"AVAILABLE" or &"LOCKED".
# Does not mutate the world.
static func evaluate_availability(world: WorldState, quest_id: String) -> StringName:
	var result := Registry.get_definition(quest_id)
	if not result.success:
		return &"LOCKED"
	var defn: Dictionary = result.definition
	var avail: Dictionary = defn.availability
	# Required day check
	if world.current_day < int(avail.get("required_day", 0)):
		return &"LOCKED"
	# Required flags check
	for flag in avail.get("required_flags", []):
		if not world.quest_flags.get(flag, false):
			return &"LOCKED"
	return &"AVAILABLE"

# ── Accept ────────────────────────────────────────────────────────────────────

static func accept(world: WorldState, quest_id: String) -> Dictionary:
	# A tracked quest state owns its transition error even if its authored
	# definition is unavailable; this keeps illegal state transitions explicit.
	var qs = world.quest_state.get_quest(quest_id)
	if qs != null and qs.status == &"LOCKED":
		return _fail("ILLEGAL_QUEST_TRANSITION: %s is LOCKED, not AVAILABLE" % quest_id)
	var result := Registry.get_definition(quest_id)
	if not result.success:
		return _fail("QUEST_NOT_FOUND: %s" % quest_id)
	var defn: Dictionary = result.definition

	# Resolve current status: if no state yet, derive from availability
	var current_status: StringName
	if qs == null:
		current_status = evaluate_availability(world, quest_id)
	else:
		current_status = qs.status

	# Legal: AVAILABLE → ACTIVE only
	if current_status != &"AVAILABLE":
		return _fail("ILLEGAL_QUEST_TRANSITION: %s is %s, not AVAILABLE" % [quest_id, String(current_status)])

	if qs == null:
		qs = QState.new(quest_id)

	qs.status = &"ACTIVE"
	qs.accepted_day = world.current_day
	# deadline_day = accepted_day + deadline_days - 1  (Gate 5 contract)
	qs.deadline_day = world.current_day + int(defn.deadline_days) - 1
	world.quest_state.set_quest(qs)
	return {"success": true, "error": ""}

# ── Objective evaluation ──────────────────────────────────────────────────────

# Read-only: returns true if ALL objectives are satisfied.
static func evaluate_objectives(world: WorldState, quest_id: String) -> bool:
	var result := Registry.get_definition(quest_id)
	if not result.success:
		return false
	var defn: Dictionary = result.definition
	for obj in defn.objectives:
		if not _objective_satisfied(world, obj):
			return false
	return true

static func _objective_satisfied(world: WorldState, obj: Dictionary) -> bool:
	match StringName(obj.get("type", "")):
		&"HAVE_ITEM":
			if world.player == null:
				return false
			var inspect: Dictionary = world.player.item_inventory.inspect_item(obj.get("item_id", ""))
			return inspect.success and inspect.get("quantity", 0) >= int(obj.get("quantity", 1))
		&"DELIVER_ITEM":
			# v1: treated as HAVE_ITEM — player holds the items.
			# QUEST-2 can extend with delivery location checks.
			if world.player == null:
				return false
			var inspect: Dictionary = world.player.item_inventory.inspect_item(obj.get("item_id", ""))
			return inspect.success and inspect.get("quantity", 0) >= int(obj.get("quantity", 1))
		&"WORLD_FLAG":
			return world.quest_flags.get(obj.get("flag", ""), false)
		&"VISIT_LOCATION":
			# Check event log for a PLAYER_ARRIVED event at the target settlement
			var target: String = obj.get("settlement_id", "")
			if target.is_empty():
				return false
			for evt in world.event_log:
				if evt.type == "PLAYER_ARRIVED" and evt.payload.get("settlement_id", "") == target:
					return true
			return false
	return false

# ── Resolve ───────────────────────────────────────────────────────────────────

static func resolve(world: WorldState, quest_id: String) -> Dictionary:
	var qs = world.quest_state.get_quest(quest_id)
	if qs == null or qs.status != &"ACTIVE":
		return _fail("ILLEGAL_QUEST_TRANSITION: %s must be ACTIVE to resolve" % quest_id)
	# Idempotency: reward already granted → flip status, return success without re-applying
	if qs.reward_granted:
		qs.status = &"RESOLVED"
		return {"success": true, "error": ""}
	qs.status = &"RESOLVED"
	_apply_reward(world, qs, "resolved")
	return {"success": true, "error": ""}

# ── Fail ──────────────────────────────────────────────────────────────────────

static func fail_quest(world: WorldState, quest_id: String) -> Dictionary:
	var qs = world.quest_state.get_quest(quest_id)
	if qs == null or qs.status != &"ACTIVE":
		return _fail("ILLEGAL_QUEST_TRANSITION: %s must be ACTIVE to fail" % quest_id)
	if qs.reward_granted:
		qs.status = &"FAILED"
		return {"success": true, "error": ""}
	qs.status = &"FAILED"
	_apply_reward(world, qs, "failed")
	return {"success": true, "error": ""}

# ── Expire ────────────────────────────────────────────────────────────────────

static func expire_quest(world: WorldState, quest_id: String) -> Dictionary:
	var qs = world.quest_state.get_quest(quest_id)
	if qs == null or qs.status != &"ACTIVE":
		return _fail("ILLEGAL_QUEST_TRANSITION: %s must be ACTIVE to expire" % quest_id)
	qs.status = &"EXPIRED"
	# The authored expired outcome normally has no rewards, but applying the
	# declared outcome keeps the contract extensible and the idempotency guard
	# authoritative if a future quest intentionally grants an expiry payment.
	_apply_reward(world, qs, "expired")
	return {"success": true, "error": ""}

# Called by SimulationEngine once per day advance, after survival resolution.
# Transitions all ACTIVE quests past their deadline to EXPIRED.
# Deadline semantics: current_day > deadline_day  →  EXPIRED  (Gate 5)
static func check_deadlines(world: WorldState) -> void:
	for id in world.quest_state.all_quest_ids():
		var qs = world.quest_state.get_quest(id)
		if qs == null or qs.status != &"ACTIVE":
			continue
		if qs.deadline_day >= 0 and world.current_day > qs.deadline_day:
			expire_quest(world, id)

# ── Reward application (private) ──────────────────────────────────────────────

static func _apply_reward(world: WorldState, qs, outcome_key: String) -> void:
	var rewards := _get_outcome_rewards(qs.quest_id, outcome_key)
	for r in rewards:
		if typeof(r) != TYPE_DICTIONARY:
			continue
		var rtype: StringName = StringName(r.get("type", ""))
		var amount: int = int(r.get("amount", 0))
		if world.player != null:
			match rtype:
				&"XP":
					world.player.xp += amount
				&"CURRENCY":
					world.player.money += amount
	qs.reward_granted = true
	_apply_world_effects(world, _get_outcome_effects(qs.quest_id, outcome_key))

static func _get_outcome_rewards(quest_id: String, outcome_key: String) -> Array:
	var result := Registry.get_definition(quest_id)
	if not result.success:
		return []
	return result.definition.outcomes.get(outcome_key, {}).get("rewards", [])

static func _get_outcome_effects(quest_id: String, outcome_key: String) -> Array:
	var result := Registry.get_definition(quest_id)
	if not result.success:
		return []
	return result.definition.outcomes.get(outcome_key, {}).get("world_effects", [])

static func _apply_world_effects(world: WorldState, effects: Array) -> void:
	for fx in effects:
		if typeof(fx) != TYPE_DICTIONARY:
			continue
		match StringName(fx.get("type", "")):
			&"SET_FLAG":
				var flag: String = fx.get("flag", "")
				if not flag.is_empty():
					world.quest_flags[flag] = true

# ── Private ───────────────────────────────────────────────────────────────────

static func _fail(error: String) -> Dictionary:
	return {"success": false, "error": error}
