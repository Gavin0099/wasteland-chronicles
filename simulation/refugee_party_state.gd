class_name RefugeePartyState
extends RefCounted

var id: StringName = &""
var origin_id: StringName = &""
var destination_id: StringName = &""
var headcount: int = 0
var route_days: int = 3
var days_remaining: int = 3
var departure_day: int = 0
var is_active: bool = true
var is_arrived: bool = false

var route_type: StringName = &""

func _init(
	p_id: StringName = &"",
	p_origin_id: StringName = &"",
	p_destination_id: StringName = &"",
	p_headcount: int = 0,
	p_route_days: int = 3,
	p_days_remaining: int = 3,
	p_departure_day: int = 0,
	p_route_type: StringName = &""
) -> void:
	id = p_id
	origin_id = p_origin_id
	destination_id = p_destination_id
	headcount = p_headcount
	route_days = p_route_days
	days_remaining = p_days_remaining
	departure_day = p_departure_day
	route_type = p_route_type
	is_active = true
	is_arrived = false

func duplicate_state() -> RefugeePartyState:
	var copy := RefugeePartyState.new(
		id,
		origin_id,
		destination_id,
		headcount,
		route_days,
		days_remaining,
		departure_day,
		route_type
	)
	copy.is_active = is_active
	copy.is_arrived = is_arrived
	return copy

func to_dict() -> Dictionary:
	var data := {
		"id": String(id),
		"origin_id": String(origin_id),
		"destination_id": String(destination_id),
		"headcount": headcount,
		"route_days": route_days,
		"days_remaining": days_remaining,
		"departure_day": departure_day,
		"is_active": is_active,
		"is_arrived": is_arrived
	}
	if route_type != &"":
		data["route_type"] = String(route_type)
	return data

static func from_dict(data: Dictionary) -> RefugeePartyState:
	var r := RefugeePartyState.new(
		StringName(data.get("id", "")),
		StringName(data.get("origin_id", "")),
		StringName(data.get("destination_id", "")),
		int(data.get("headcount", 0)),
		int(data.get("route_days", 3)),
		int(data.get("days_remaining", 3)),
		int(data.get("departure_day", 0)),
		StringName(data.get("route_type", ""))
	)
	r.is_active = bool(data.get("is_active", true))
	r.is_arrived = bool(data.get("is_arrived", false))
	return r
