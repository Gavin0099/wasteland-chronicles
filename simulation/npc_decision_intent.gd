class_name NpcDecisionIntent
extends RefCounted

# ==============================================================================
# S4-F1: STRUCTURED INTENT
# ==============================================================================
# What an NPC wants to do. An intent is NOT a world fact: it has changed nothing
# and may still be refused. Only after authorization, revalidation and an atomic
# lifecycle commit does anything reach the event ledger.
# ==============================================================================

var npc_id: StringName = &""
var observation: NpcDecisionObservation = null
var eligible_actions: Array[int] = []
var action: int = NpcDecisionEngine.Action.STAY
var rule_invoked: StringName = &""
var destination_id: StringName = &""

static func create(
	p_observation: NpcDecisionObservation,
	p_eligible: Array[int],
	p_action: int,
	p_rule: StringName,
	p_destination: StringName
) -> NpcDecisionIntent:
	var intent := NpcDecisionIntent.new()
	intent.npc_id = p_observation.npc_id
	intent.observation = p_observation
	intent.eligible_actions = p_eligible.duplicate()
	intent.action = p_action
	intent.rule_invoked = p_rule
	intent.destination_id = p_destination
	return intent
