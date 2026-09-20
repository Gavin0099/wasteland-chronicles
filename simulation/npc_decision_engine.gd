class_name NpcDecisionEngine
extends RefCounted

# ==============================================================================
# S4-F1: AUTONOMOUS DECISION AUTHORITY (G2-lite)
# ==============================================================================
# The first time a named individual decides something for themselves.
#
# AUTHORITY CHAIN (fixed, one-way):
#   World State -> Observation Projection -> Eligibility Filter -> Decision
#   -> Structured Intent -> Authorization -> Existing Atomic Lifecycle Commit
#   -> Committed Event -> Decision Evidence
#
# ZERO MUTATION AUTHORITY: every function here takes an NpcDecisionObservation
# (a value projection) and returns a value. None of them receives WorldState, so
# this class structurally cannot change the world. Committing is the simulation
# engine's job, through the S4-B lifecycle transactions that already exist.
#
# CLOSED ACTION SPACE (S4-F1): exactly STAY and MIGRATE. These are the only two
# behaviors the world already has complete physics and atomic transitions for.
# WORK, JOIN_CARAVAN, LEAVE_JOB, JOIN_FACTION, TRADE, REPAIR, ATTACK and HELP are
# NOT here, because each would force occupation, faction, combat or relationship
# authority into existence ahead of its slice.
#
# DELIBERATELY ABSENT (do not add "while you are here"):
#   - Trait / Aptitude / Background weighting. S4-F1 proves the decision
#     machinery itself; every NPC follows identical rules from identical
#     observations. If something misbehaves, it is the architecture, not
#     personality weighting. Whether CAUTIOUS should ever change a choice is an
#     S4-F2 question — and may turn out not to be worth doing at all.
#   - Randomness. Decisions are a pure function of the observation.
#   - LLM reasoning, utility AI, GOAP, behavior trees. Two actions and a handful
#     of deterministic rules do not need a framework.
# ==============================================================================

enum Action {
	STAY    = 0,
	MIGRATE = 1,
}

# The closed registry. An action outside this set is refused, and the decision
# engine cannot invent one: selection only ever returns a member of this enum.
const AUTHORIZED_ACTIONS: Array[int] = [Action.STAY, Action.MIGRATE]

# Rule identifiers recorded in decision evidence. Structured, auditable, and
# deliberately NOT a chain of thought.
const RULE_STAY_DEFAULT := &"RULE_STAY_DEFAULT"
const RULE_SEVERE_LOCAL_DEPRIVATION := &"RULE_SEVERE_LOCAL_DEPRIVATION"
const RULE_LOCAL_SECURITY_COLLAPSE := &"RULE_LOCAL_SECURITY_COLLAPSE"
const RULE_NO_VIABLE_DESTINATION := &"RULE_NO_VIABLE_DESTINATION"

# Thresholds mirror the aggregate S3-C/S3-F semantics so a named individual and
# the anonymous cohort do not disagree about what "bad" means.
const DEPRIVATION_PRESSURE_THRESHOLD: float = 60.0
const SECURITY_COLLAPSE_THRESHOLD: float = 25.0

static func action_name(value: int) -> String:
	match value:
		Action.STAY: return "STAY"
		Action.MIGRATE: return "MIGRATE"
		_: return "INVALID(%d)" % value

static func is_authorized_action(value: int) -> bool:
	return value in AUTHORIZED_ACTIONS

# ── Eligibility ───────────────────────────────────────────────────────────────

# Which actions this NPC may choose from, given only what they can see.
# STAY is always eligible: staying put is always a legal thing for a person to do.
static func eligible_actions(obs: NpcDecisionObservation) -> Array[int]:
	var eligible: Array[int] = [Action.STAY]
	if obs.candidate_destinations.is_empty():
		return eligible
	if _is_local_situation_severe(obs):
		eligible.append(Action.MIGRATE)
	return eligible

static func _is_local_situation_severe(obs: NpcDecisionObservation) -> bool:
	if obs.water_pressure >= DEPRIVATION_PRESSURE_THRESHOLD:
		return true
	if obs.food_pressure >= DEPRIVATION_PRESSURE_THRESHOLD:
		return true
	if obs.security <= SECURITY_COLLAPSE_THRESHOLD:
		return true
	return false

# ── Selection ─────────────────────────────────────────────────────────────────

# A pure function of the observation: the same observation always yields the
# same intent, for every NPC, on every machine, on every replay.
static func decide(obs: NpcDecisionObservation) -> NpcDecisionIntent:
	var eligible := eligible_actions(obs)

	if not eligible.has(Action.MIGRATE):
		var rule := RULE_STAY_DEFAULT
		if _is_local_situation_severe(obs) and obs.candidate_destinations.is_empty():
			# The situation is bad, but there is nowhere to go. Staying is not
			# contentment; recording the distinct rule keeps that legible.
			rule = RULE_NO_VIABLE_DESTINATION
		return NpcDecisionIntent.create(obs, eligible, Action.STAY, rule, &"")

	# Rule precedence is fixed so the recorded reason is deterministic when more
	# than one condition holds at once.
	var migrate_rule := RULE_LOCAL_SECURITY_COLLAPSE
	if obs.water_pressure >= DEPRIVATION_PRESSURE_THRESHOLD or obs.food_pressure >= DEPRIVATION_PRESSURE_THRESHOLD:
		migrate_rule = RULE_SEVERE_LOCAL_DEPRIVATION

	# The destination is the world's own evaluation, carried in the observation.
	# The named individual does not run a private scoring algorithm: an
	# anonymous cohort and Mara must not disagree about which town is safest
	# without a stated reason to.
	var destination := StringName(String((obs.candidate_destinations[0] as Dictionary).get("settlement_id", "")))
	return NpcDecisionIntent.create(obs, eligible, Action.MIGRATE, migrate_rule, destination)

# ── Authorization ─────────────────────────────────────────────────────────────

# Fail-closed gate between deciding and committing. Returns "" when the intent
# may proceed to revalidation, else the refusal reason.
static func authorize(intent: NpcDecisionIntent) -> String:
	if not is_authorized_action(intent.action):
		return "UNAUTHORIZED_ACTION: %s is outside the S4-F1 closed action space" % NpcDecisionEngine.action_name(intent.action)
	if not intent.eligible_actions.has(intent.action):
		return "INELIGIBLE_ACTION: %s was selected but is not eligible for %s" % [
			NpcDecisionEngine.action_name(intent.action), intent.npc_id
		]
	if intent.action == Action.MIGRATE and intent.destination_id == &"":
		return "INVALID_INTENT: MIGRATE without a destination"
	return ""
