class_name NpcLifeState
extends RefCounted

# ==============================================================================
# S4-B: NPC LIFE STATE MODEL
# ==============================================================================
# Tracks WHERE this person is and WHETHER they are alive.
# Strictly decoupled from NpcIdentity (WHO they are permanently).
#
# AUTHORITY CONTRACT:
# - is_alive() is derived from status, NOT a stored bool.
# - whereabouts is derived from container, NOT a stored location field.
# - This eliminates the possibility of "status=DEAD, alive=true" contradictions.
# ==============================================================================

enum Status {
	SETTLED    = 0,  # Living in a settlement (population_container = settlement)
	IN_TRANSIT = 1,  # En route (population_container = refugee party)
	DEAD       = 2,  # Deceased (population_container = NONE)
}

enum ContainerType {
	SETTLEMENT    = 0,
	REFUGEE_PARTY = 1,
	NONE          = 2,  # Only valid for DEAD
}

var npc_id: StringName = &""
var status: Status = Status.SETTLED
var population_container_type: ContainerType = ContainerType.SETTLEMENT
var population_container_id: StringName = &""

# Derived property: alive := status != DEAD (never stored separately)
func is_alive() -> bool:
	return status != Status.DEAD

func duplicate_life_state() -> NpcLifeState:
	var copy := NpcLifeState.new()
	copy.npc_id = npc_id
	copy.status = status
	copy.population_container_type = population_container_type
	copy.population_container_id = population_container_id
	return copy

func to_dict() -> Dictionary:
	return {
		"npc_id": String(npc_id),
		"status": status,
		"population_container_type": population_container_type,
		"population_container_id": String(population_container_id),
	}

static func from_dict(data: Dictionary) -> NpcLifeState:
	var ls := NpcLifeState.new()
	ls.npc_id = StringName(data.get("npc_id", ""))
	ls.status = int(data.get("status", Status.SETTLED)) as Status
	ls.population_container_type = int(data.get("population_container_type", ContainerType.SETTLEMENT)) as ContainerType
	ls.population_container_id = StringName(data.get("population_container_id", ""))
	return ls
