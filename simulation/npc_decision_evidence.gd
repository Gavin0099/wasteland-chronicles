class_name NpcDecisionEvidence
extends RefCounted

# ==============================================================================
# S4-F1: STRUCTURED DECISION EVIDENCE (Decision Audit Trail)
# ==============================================================================
# Governance Axiom 15: an NPC decision leaves precise structured evidence, never
# an unbounded chain of thought.
#
#   <Day, Phase, NPC_ID, Observed_State, Eligible_Actions, Selected_Action,
#    Rule_Invoked, Result>
#
# This trail is NOT the world event ledger. Axiom 11.1 / §5.1: the ledger holds
# only committed facts, while rejected intents live here and here only. A
# decision that was refused must never be readable as "Mara migrated".
#
# On committed_event_index: S4-C.1 deliberately refused to give EventRecord an
# id, so evidence references a committed event by its POSITION in the ledger.
# The ledger is append-only and canonically ordered, which makes the position
# stable, and it stays a derived reference rather than a second identity.
# ==============================================================================

enum Result {
	COMMITTED = 0,  # authorized, revalidated, and applied atomically
	NO_OP     = 1,  # a legal decision that changes nothing (STAY)
	REJECTED  = 2,  # refused at authorization or revalidation; world untouched
}

var day: int = 0
var phase: String = ""
var npc_id: StringName = &""
var observed_state: Dictionary = {}
var eligible_actions: Array = []
var selected_action: String = ""
var rule_invoked: StringName = &""
var result: Result = Result.NO_OP
var reason: String = ""
var committed_event_index: int = -1

static func create(
	p_day: int,
	p_phase: String,
	p_intent: NpcDecisionIntent,
	p_result: Result,
	p_reason: String,
	p_event_index: int
) -> NpcDecisionEvidence:
	var ev := NpcDecisionEvidence.new()
	ev.day = p_day
	ev.phase = p_phase
	ev.npc_id = p_intent.npc_id
	# S4-C.1/S4-C.2 discipline: evidence is a RECORD, so it is canonicalized at
	# the moment it is written. Without this, nested ints in the observation
	# widen to float on reload and the snapshot stops being a fixed point.
	ev.observed_state = EventRecord.canonicalize_payload(p_intent.observation.to_dict())
	var names: Array = []
	for a in p_intent.eligible_actions:
		names.append(NpcDecisionEngine.action_name(a))
	ev.eligible_actions = names
	ev.selected_action = NpcDecisionEngine.action_name(p_intent.action)
	ev.rule_invoked = p_intent.rule_invoked
	ev.result = p_result
	ev.reason = p_reason
	ev.committed_event_index = p_event_index
	return ev

func duplicate_evidence() -> NpcDecisionEvidence:
	var copy := NpcDecisionEvidence.new()
	copy.day = day
	copy.phase = phase
	copy.npc_id = npc_id
	copy.observed_state = observed_state.duplicate(true)
	copy.eligible_actions = eligible_actions.duplicate()
	copy.selected_action = selected_action
	copy.rule_invoked = rule_invoked
	copy.result = result
	copy.reason = reason
	copy.committed_event_index = committed_event_index
	return copy

func to_dict() -> Dictionary:
	return {
		"day": day,
		"phase": phase,
		"npc_id": String(npc_id),
		"observed_state": observed_state.duplicate(true),
		"eligible_actions": eligible_actions.duplicate(),
		"selected_action": selected_action,
		"rule_invoked": String(rule_invoked),
		"result": result,
		"reason": reason,
		"committed_event_index": committed_event_index,
	}

static func from_dict(data: Dictionary) -> NpcDecisionEvidence:
	var ev := NpcDecisionEvidence.new()
	ev.day = int(data.get("day", 0))
	ev.phase = String(data.get("phase", ""))
	ev.npc_id = StringName(data.get("npc_id", ""))
	ev.observed_state = EventRecord.canonicalize_payload((data.get("observed_state", {}) as Dictionary).duplicate(true))
	ev.eligible_actions = (data.get("eligible_actions", []) as Array).duplicate()
	ev.selected_action = String(data.get("selected_action", ""))
	ev.rule_invoked = StringName(data.get("rule_invoked", ""))
	ev.result = int(data.get("result", Result.NO_OP)) as Result
	ev.reason = String(data.get("reason", ""))
	ev.committed_event_index = int(data.get("committed_event_index", -1))
	return ev

static func validate_dict(data: Variant, index: int) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "decision_audit_trail[%d] is not an object" % index
	for field in ["day", "phase", "npc_id", "observed_state", "eligible_actions",
			"selected_action", "rule_invoked", "result"]:
		if not data.has(field):
			return "decision_audit_trail[%d] is missing required field '%s'" % [index, field]
	if typeof(data["observed_state"]) != TYPE_DICTIONARY:
		return "decision_audit_trail[%d].observed_state is not an object" % index
	if typeof(data["eligible_actions"]) != TYPE_ARRAY:
		return "decision_audit_trail[%d].eligible_actions is not an array" % index
	return ""
