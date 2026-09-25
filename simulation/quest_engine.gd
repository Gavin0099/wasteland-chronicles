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

const Board = preload("res://simulation/job_board.gd")

# FUN-1: a definition now comes from one of three places, checked in the order
# that makes a committed contract unbreakable:
#
#   1. the authored registry          - fixed content, never changes
#   2. the player's accepted jobs     - a contract already taken, committed
#   3. today's board                  - a posting that has not been accepted yet
#
# Order matters. Once a job is accepted its committed copy wins, so a board
# that has since rotated - or a town that stopped being short - cannot alter
# or cancel work the player is already carrying.
static func _definition(world: WorldState, quest_id: String) -> Dictionary:
	var authored: Dictionary = Registry.get_definition(quest_id)
	if authored.success:
		return authored
	if world != null and world.accepted_jobs.has(quest_id):
		return {"success": true, "definition": world.accepted_jobs[quest_id]}
	if world != null and Board.is_job_id(quest_id):
		var posting: Dictionary = Board.find_posting(world, quest_id)
		if not posting.is_empty():
			return {"success": true, "definition": posting}
	return {"success": false, "definition": {}, "error": "QUEST_NOT_FOUND"}

static func _settled_at(world: WorldState, settlement_id: String) -> bool:
	if world.player == null:
		return false
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	return life != null and life.status == NpcLifeState.Status.SETTLED and String(life.population_container_id) == "settlement:" + settlement_id

static func authorize_accept(world: WorldState, quest_id: String) -> String:
	var found: Dictionary = _definition(world, quest_id)
	if not found.success:
		return "QUEST_NOT_FOUND"
	var definition: Dictionary = found.definition
	if not _settled_at(world, String(definition.settlement_id)):
		return "QUEST_ISSUER_NOT_HERE"
	var existing = world.quest_state.get_quest(quest_id)
	if existing != null and existing.status != &"AVAILABLE":
		return "ILLEGAL_QUEST_TRANSITION"
	if evaluate_availability(world, quest_id) != &"AVAILABLE":
		return "QUEST_NOT_AVAILABLE"
	return ""

static func authorize_turn_in(world: WorldState, quest_id: String) -> String:
	var found: Dictionary = _definition(world, quest_id)
	if not found.success:
		return "QUEST_NOT_FOUND"
	var qs = world.quest_state.get_quest(quest_id)
	if qs == null or qs.status != &"ACTIVE" or qs.reward_granted:
		return "ILLEGAL_QUEST_TRANSITION"
	if world.current_day > qs.deadline_day:
		return "QUEST_DEADLINE_PASSED"
	var definition: Dictionary = found.definition
	var has_delivery := false
	for objective in definition.objectives:
		if String(objective.type) in ["DELIVER_ITEM", "DELIVER_RESOURCE"]:
			has_delivery = true
			break
	if not has_delivery and not _settled_at(world, String(definition.settlement_id)):
		return "QUEST_ISSUER_NOT_HERE"
	for objective in definition.objectives:
		if String(objective.type) in ["DELIVER_ITEM", "DELIVER_RESOURCE"] and not _settled_at(world, String(objective.settlement_id)):
			return "QUEST_DELIVERY_LOCATION_REQUIRED"
		if not _objective_satisfied(world, quest_id, objective):
			return "QUEST_OBJECTIVE_NOT_MET"
	return ""

static func turn_in(world: WorldState, quest_id: String) -> Dictionary:
	var error := authorize_turn_in(world, quest_id)
	if error != "":
		return _fail(error)
	var definition: Dictionary = _definition(world, quest_id).definition
	var inventory = world.player.item_inventory.duplicate_state()
	var delivered: Array = []
	for objective in definition.objectives:
		if String(objective.type) != "DELIVER_ITEM":
			continue
		var removed: Dictionary = inventory.remove_item(String(objective.item_id), int(objective.quantity))
		if not removed.success:
			return _fail(String(removed.error))
		delivered.append({"item_id": String(objective.item_id), "quantity": int(objective.quantity)})
	# FUN-1: aggregate cargo leaves the pack here. It is deliberately NOT added
	# to the settlement: the contract buys what you carried, and the world's
	# response to that is QUEST-W1, not this slice.
	var handed_over: Array = []
	for objective in definition.objectives:
		if String(objective.type) != "DELIVER_RESOURCE":
			continue
		var resource := String(objective.resource)
		var quantity := int(objective.quantity)
		if int(world.player.inventory.get_amount(resource)) < quantity:
			return _fail("QUEST_OBJECTIVE_NOT_MET")
		handed_over.append({"resource": resource, "quantity": quantity})
	for entry in handed_over:
		world.player.inventory.add_amount(String(entry.resource), -int(entry.quantity))

	world.player.item_inventory = inventory
	var result := resolve(world, quest_id)
	if not result.success:
		return result
	return {"success": true, "error": "", "delivered": delivered, "handed_over": handed_over,
		"rewards": definition.outcomes.resolved.rewards.duplicate(true)}

# ── Availability ──────────────────────────────────────────────────────────────

# Read-only query: returns &"AVAILABLE" or &"LOCKED".
# Does not mutate the world.
static func evaluate_availability(world: WorldState, quest_id: String) -> StringName:
	var result := _definition(world, quest_id)
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
	var equipped_id := String(avail.get("required_equipped_item_id", ""))
	if equipped_id != "" and (world.player == null or world.player.equipment == null or world.player.equipment.equipped_item("back") != equipped_id):
		return &"LOCKED"
	return &"AVAILABLE"

# ── Accept ────────────────────────────────────────────────────────────────────

static func accept(world: WorldState, quest_id: String) -> Dictionary:
	# A tracked quest state owns its transition error even if its authored
	# definition is unavailable; this keeps illegal state transitions explicit.
	var qs = world.quest_state.get_quest(quest_id)
	if qs != null and qs.status == &"LOCKED":
		return _fail("ILLEGAL_QUEST_TRANSITION: %s is LOCKED, not AVAILABLE" % quest_id)
	var result := _definition(world, quest_id)
	if not result.success:
		return _fail("QUEST_NOT_FOUND: %s" % quest_id)
	var defn: Dictionary = result.definition
	var auth_error := authorize_accept(world, quest_id)
	if auth_error != "":
		return _fail(auth_error)

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
	# FUN-1: take a copy of the posting at the moment it becomes a contract.
	# From here the board is irrelevant to this quest - it can rotate, and the
	# shortage that produced it can end, without touching the work owed.
	if Board.is_job_id(quest_id) and not world.accepted_jobs.has(quest_id):
		world.accepted_jobs[quest_id] = defn.duplicate(true)
	return {"success": true, "error": ""}

# ── Objective evaluation ──────────────────────────────────────────────────────

# Read-only: returns true if ALL objectives are satisfied.
static func evaluate_objectives(world: WorldState, quest_id: String) -> bool:
	var result := _definition(world, quest_id)
	if not result.success:
		return false
	var defn: Dictionary = result.definition
	for obj in defn.objectives:
		if not _objective_satisfied(world, quest_id, obj):
			return false
	return true

static func _objective_satisfied(world: WorldState, quest_id: String, obj: Dictionary) -> bool:
	match StringName(obj.get("type", "")):
		&"HAVE_ITEM":
			if world.player == null:
				return false
			var inspect: Dictionary = world.player.item_inventory.inspect_item(obj.get("item_id", ""))
			return inspect.success and inspect.get("quantity", 0) >= int(obj.get("quantity", 1))
		&"DELIVER_ITEM":
			if world.player == null:
				return false
			var inspect: Dictionary = world.player.item_inventory.inspect_item(obj.get("item_id", ""))
			return inspect.success and inspect.get("quantity", 0) >= int(obj.get("quantity", 1))
		&"DELIVER_RESOURCE":
			# Aggregate cargo, checked the same way a carried item is: you must
			# actually have it on you when you hand it over.
			if world.player == null or world.player.inventory == null:
				return false
			return int(world.player.inventory.get_amount(String(obj.get("resource", "")))) >= int(obj.get("quantity", 1))
		&"WIN_ROAD_COMBAT":
			# Satisfied by something the player DID, proven by committed
			# receipts: road victories on the named road, after acceptance.
			# Paying the bandits off or running away leaves no such receipt.
			if world.player == null:
				return false
			var origin: String = "settlement:" + String(obj.get("origin_id", ""))
			var destination: String = "settlement:" + String(obj.get("destination_id", ""))
			var needed: int = int(obj.get("quantity", 1))
			# A FIELD_RESULT records the outcome but NOT the road - the route
			# lives on the ROAD_COMBAT_BEGAN receipt that opened the battle. So
			# the two are correlated in ledger order rather than changing a
			# committed receipt shape and every save that contains one.
			var accepted_at := -1
			var wins := 0
			var current_road := {}
			for i in range(world.event_log.size()):
				var record: EventRecord = world.event_log[i]
				if record.type == "QUEST_ACCEPTED" and record.actor_id == world.player.npc_id and String(record.payload.get("quest_id", "")) == quest_id:
					accepted_at = i
					wins = 0
					current_road = {}
					continue
				if accepted_at < 0 or i < accepted_at or record.actor_id != world.player.npc_id:
					continue
				if record.type == "ROAD_COMBAT_BEGAN":
					current_road = {
						"origin": String(record.payload.get("origin", "")),
						"destination": String(record.payload.get("destination", "")),
					}
					continue
				if record.type != "FIELD_RESULT":
					continue
				var ended_a_road_battle: bool = String(record.payload.get("source", "")) == "road"
				if ended_a_road_battle and String(record.payload.get("outcome", "")) == "VICTORY" and not current_road.is_empty():
					# Either direction counts: the people working a road do not
					# care which way the player happened to be walking.
					var a := String(current_road.origin)
					var b := String(current_road.destination)
					if (a == origin and b == destination) or (a == destination and b == origin):
						wins += 1
				if ended_a_road_battle:
					current_road = {}
			return wins >= needed
		&"WORLD_FLAG":
			return world.quest_flags.get(obj.get("flag", ""), false)
		&"VISIT_LOCATION":
			# Only this player's committed arrivals after this quest was accepted count.
			var target: String = obj.get("settlement_id", "")
			if target.is_empty() or world.player == null:
				return false
			var accepted_index := -1
			for i in range(world.event_log.size()):
				var evt: EventRecord = world.event_log[i]
				if evt.type == "QUEST_ACCEPTED" and evt.actor_id == world.player.npc_id and String(evt.payload.get("quest_id", "")) == quest_id:
					accepted_index = i
				elif i > accepted_index and accepted_index >= 0 and evt.type == "NAMED_MIGRATION_COMPLETED" and evt.actor_id == world.player.npc_id and String(evt.target_id) == "settlement:" + target:
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
	var rewards := _get_outcome_rewards(world, qs.quest_id, outcome_key)
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
	_apply_world_effects(world, _get_outcome_effects(world, qs.quest_id, outcome_key))

static func _get_outcome_rewards(world: WorldState, quest_id: String, outcome_key: String) -> Array:
	var result := _definition(world, quest_id)
	if not result.success:
		return []
	return result.definition.outcomes.get(outcome_key, {}).get("rewards", [])

static func _get_outcome_effects(world: WorldState, quest_id: String, outcome_key: String) -> Array:
	var result := _definition(world, quest_id)
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
