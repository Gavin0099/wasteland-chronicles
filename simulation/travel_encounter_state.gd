class_name TravelEncounterState
extends RefCounted

# ==============================================================================
# S5-B4: THE ENCOUNTER CURRENTLY BLOCKING A JOURNEY
# ==============================================================================
# Stores only WHICH encounter is pending and WHERE it happened. Everything the
# player reads - title, description, options, costs - is looked up from the
# TravelEncounter catalogue, so a saved game can never disagree with the rules
# about what a choice does.
# ==============================================================================

var encounter_type: StringName = &""
var day: int = 0
var origin_id: StringName = &""
var destination_id: StringName = &""
var travel_day_index: int = 0

static func create(
	p_type: StringName,
	p_day: int,
	p_origin: StringName,
	p_destination: StringName,
	p_index: int
) -> TravelEncounterState:
	var e := TravelEncounterState.new()
	e.encounter_type = p_type
	e.day = p_day
	e.origin_id = p_origin
	e.destination_id = p_destination
	e.travel_day_index = p_index
	return e

func duplicate_state() -> TravelEncounterState:
	return TravelEncounterState.create(encounter_type, day, origin_id, destination_id, travel_day_index)

func to_dict() -> Dictionary:
	return {
		"encounter_type": String(encounter_type),
		"day": day,
		"origin_id": String(origin_id),
		"destination_id": String(destination_id),
		"travel_day_index": travel_day_index,
	}

static func from_dict(data: Dictionary) -> TravelEncounterState:
	return TravelEncounterState.create(
		StringName(data.get("encounter_type", "")),
		int(data.get("day", 0)),
		StringName(data.get("origin_id", "")),
		StringName(data.get("destination_id", "")),
		int(data.get("travel_day_index", 0))
	)
