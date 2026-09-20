class_name NpcDecisionObservation
extends RefCounted

# ==============================================================================
# S4-F1: NPC DECISION OBSERVATION PROJECTION
# ==============================================================================
# What a named NPC is allowed to SEE when deciding. This is a narrow, read-only
# value projection — never a handle on WorldState.
#
# The decision engine is given one of these and nothing else. It therefore
# CANNOT read world.settlements, world.events, other NPCs' states, or anything
# about the future, because it never holds a reference that could reach them.
# "No direct mutation" is structural here, not a rule someone has to remember.
#
# This boundary is also the seed of S7 Information Fog: when knowledge becomes
# imperfect, it narrows THIS projection rather than being retrofitted into a
# decision engine that had grown used to omniscience.
#
# Floats are canonicalized on construction (S4-C.2), because observations are
# recorded into decision evidence and must survive persistence unchanged.
# ==============================================================================

var npc_id: StringName = &""
var day: int = 0
var current_settlement_id: StringName = &""
var water_pressure: float = 0.0
var food_pressure: float = 0.0
var security: float = 100.0

# Candidate destinations, already filtered by the world's own rules. Each entry
# is a small value dictionary, never a settlement reference.
var candidate_destinations: Array = []

static func create(
	p_npc_id: StringName,
	p_day: int,
	p_settlement_id: StringName,
	p_water_pressure: float,
	p_food_pressure: float,
	p_security: float,
	p_candidates: Array
) -> NpcDecisionObservation:
	var obs := NpcDecisionObservation.new()
	obs.npc_id = p_npc_id
	obs.day = p_day
	obs.current_settlement_id = p_settlement_id
	obs.water_pressure = NumericCanon.canonical_float(p_water_pressure)
	obs.food_pressure = NumericCanon.canonical_float(p_food_pressure)
	obs.security = NumericCanon.canonical_float(p_security)
	obs.candidate_destinations = p_candidates.duplicate(true)
	return obs

func duplicate_observation() -> NpcDecisionObservation:
	return NpcDecisionObservation.create(
		npc_id, day, current_settlement_id,
		water_pressure, food_pressure, security,
		candidate_destinations
	)

# The observed_state block recorded in decision evidence.
func to_dict() -> Dictionary:
	return {
		"npc_id": String(npc_id),
		"day": day,
		"current_settlement_id": String(current_settlement_id),
		"water_pressure": water_pressure,
		"food_pressure": food_pressure,
		"security": security,
		"candidate_destinations": candidate_destinations.duplicate(true),
	}

static func from_dict(data: Dictionary) -> NpcDecisionObservation:
	return NpcDecisionObservation.create(
		StringName(data.get("npc_id", "")),
		int(data.get("day", 0)),
		StringName(data.get("current_settlement_id", "")),
		float(data.get("water_pressure", 0.0)),
		float(data.get("food_pressure", 0.0)),
		float(data.get("security", 100.0)),
		data.get("candidate_destinations", [])
	)
