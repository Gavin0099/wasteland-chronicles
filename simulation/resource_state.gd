class_name ResourceState
extends RefCounted

var water: int = 0
var food: int = 0
var scrap: int = 0
var fuel: int = 0

func _init(p_water: int = 0, p_food: int = 0, p_scrap: int = 0, p_fuel: int = 0) -> void:
	water = p_water
	food = p_food
	scrap = p_scrap
	fuel = p_fuel

func duplicate_state() -> ResourceState:
	return ResourceState.new(water, food, scrap, fuel)

func get_amount(resource_name: String) -> int:
	match resource_name:
		"water": return water
		"food": return food
		"scrap": return scrap
		"fuel": return fuel
		_: return 0

func set_amount(resource_name: String, amount: int) -> void:
	match resource_name:
		"water": water = amount
		"food": food = amount
		"scrap": scrap = amount
		"fuel": fuel = amount

func add_amount(resource_name: String, amount: int) -> void:
	match resource_name:
		"water": water += amount
		"food": food += amount
		"scrap": scrap += amount
		"fuel": fuel += amount

func to_dict() -> Dictionary:
	return {
		"water": water,
		"food": food,
		"scrap": scrap,
		"fuel": fuel
	}

static func from_dict(data: Dictionary) -> ResourceState:
	var res := ResourceState.new()
	res.water = int(data.get("water", 0))
	res.food = int(data.get("food", 0))
	res.scrap = int(data.get("scrap", 0))
	res.fuel = int(data.get("fuel", 0))
	return res
