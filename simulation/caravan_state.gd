class_name CaravanState
extends RefCounted

var id: StringName = &""
var name: String = ""
var origin_id: StringName = &""
var destination_id: StringName = &""

var cargo: ResourceState
var capacity_total: int = 30
var capacity_water: int = 30 # 保留向後相容
var route_days: int = 3
var days_remaining: int = 3

var is_active: bool = true
var is_destroyed: bool = false

func _init(
	p_id: StringName = &"",
	p_name: String = "",
	p_origin_id: StringName = &"",
	p_destination_id: StringName = &"",
	p_cargo: ResourceState = null,
	p_capacity: int = 30,
	p_route_days: int = 3,
	p_days_remaining: int = 3
) -> void:
	id = p_id
	name = p_name
	origin_id = p_origin_id
	destination_id = p_destination_id
	cargo = p_cargo if p_cargo != null else ResourceState.new()
	capacity_total = p_capacity
	capacity_water = p_capacity
	route_days = p_route_days
	days_remaining = p_days_remaining
	is_active = true
	is_destroyed = false

func get_total_cargo() -> int:
	return cargo.water + cargo.food + cargo.scrap + cargo.fuel

func duplicate_state() -> CaravanState:
	var copy := CaravanState.new(
		id,
		name,
		origin_id,
		destination_id,
		cargo.duplicate_state(),
		capacity_total,
		route_days,
		days_remaining
	)
	copy.is_active = is_active
	copy.is_destroyed = is_destroyed
	return copy

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"name": name,
		"origin_id": String(origin_id),
		"destination_id": String(destination_id),
		"cargo": cargo.to_dict(),
		"capacity_total": capacity_total,
		"route_days": route_days,
		"days_remaining": days_remaining,
		"is_active": is_active,
		"is_destroyed": is_destroyed
	}

static func from_dict(data: Dictionary) -> CaravanState:
	var c := CaravanState.new(
		StringName(data.get("id", "")),
		data.get("name", ""),
		StringName(data.get("origin_id", "")),
		StringName(data.get("destination_id", "")),
		ResourceState.from_dict(data.get("cargo", {})),
		int(data.get("capacity_total", data.get("capacity_water", 30))),
		int(data.get("route_days", 3)),
		int(data.get("days_remaining", 3))
	)
	c.is_active = bool(data.get("is_active", true))
	c.is_destroyed = bool(data.get("is_destroyed", false))
	return c
