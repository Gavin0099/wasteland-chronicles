class_name SettlementState
extends RefCounted

var id: StringName = &""
var name: String = ""

# 庫存、產能、消耗 (包含 water, food, scrap, fuel)
var inventory: ResourceState
var production: ResourceState
var consumption: ResourceState

# 目標安全庫存與基準價格
var target_water: int = 100
var target_food: int = 100
var target_scrap: int = 60
var target_fuel: int = 40

var base_price_water: float = 10.0
var base_price_food: float = 10.0
var base_price_scrap: float = 12.0
var base_price_fuel: float = 15.0

# 即時浮動價格
var price_water: float = 10.0
var price_food: float = 10.0
var price_scrap: float = 12.0
var price_fuel: float = 15.0

func _init(
	p_id: StringName = &"",
	p_name: String = "",
	p_inventory: ResourceState = null,
	p_production: ResourceState = null,
	p_consumption: ResourceState = null,
	p_target_water: int = 100,
	p_target_food: int = 100,
	p_base_price_water: float = 10.0,
	p_base_price_food: float = 10.0,
	p_target_scrap: int = 60,
	p_target_fuel: int = 40,
	p_base_price_scrap: float = 12.0,
	p_base_price_fuel: float = 15.0
) -> void:
	id = p_id
	name = p_name
	inventory = p_inventory if p_inventory != null else ResourceState.new()
	production = p_production if p_production != null else ResourceState.new()
	consumption = p_consumption if p_consumption != null else ResourceState.new()
	
	target_water = p_target_water
	target_food = p_target_food
	target_scrap = p_target_scrap
	target_fuel = p_target_fuel

	base_price_water = p_base_price_water
	base_price_food = p_base_price_food
	base_price_scrap = p_base_price_scrap
	base_price_fuel = p_base_price_fuel

	price_water = base_price_water
	price_food = base_price_food
	price_scrap = base_price_scrap
	price_fuel = base_price_fuel

func get_target(res_name: String) -> int:
	match res_name:
		"water": return target_water
		"food": return target_food
		"scrap": return target_scrap
		"fuel": return target_fuel
		_: return 0

func get_base_price(res_name: String) -> float:
	match res_name:
		"water": return base_price_water
		"food": return base_price_food
		"scrap": return base_price_scrap
		"fuel": return base_price_fuel
		_: return 10.0

func get_current_price(res_name: String) -> float:
	match res_name:
		"water": return price_water
		"food": return price_food
		"scrap": return price_scrap
		"fuel": return price_fuel
		_: return 10.0

func set_current_price(res_name: String, p: float) -> void:
	match res_name:
		"water": price_water = p
		"food": price_food = p
		"scrap": price_scrap = p
		"fuel": price_fuel = p

# 盈餘量 (可對外輸出)：現有庫存大於目標庫存的部分
func get_surplus(res_name: String) -> int:
	var cur := inventory.get_amount(res_name)
	var tgt := get_target(res_name)
	return maxi(0, cur - tgt)

# 赤字量 (急需輸入補給)：現有庫存低於目標庫存的缺口
func get_deficit(res_name: String) -> int:
	var cur := inventory.get_amount(res_name)
	var tgt := get_target(res_name)
	return maxi(0, tgt - cur)

func duplicate_state() -> SettlementState:
	var copy := SettlementState.new(
		id,
		name,
		inventory.duplicate_state(),
		production.duplicate_state(),
		consumption.duplicate_state(),
		target_water,
		target_food,
		base_price_water,
		base_price_food,
		target_scrap,
		target_fuel,
		base_price_scrap,
		base_price_fuel
	)
	copy.price_water = price_water
	copy.price_food = price_food
	copy.price_scrap = price_scrap
	copy.price_fuel = price_fuel
	return copy

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"name": name,
		"inventory": inventory.to_dict(),
		"production": production.to_dict(),
		"consumption": consumption.to_dict(),
		"target_water": target_water,
		"target_food": target_food,
		"target_scrap": target_scrap,
		"target_fuel": target_fuel,
		"base_price_water": base_price_water,
		"base_price_food": base_price_food,
		"base_price_scrap": base_price_scrap,
		"base_price_fuel": base_price_fuel,
		"price_water": snapped(price_water, 0.01),
		"price_food": snapped(price_food, 0.01),
		"price_scrap": snapped(price_scrap, 0.01),
		"price_fuel": snapped(price_fuel, 0.01)
	}

static func from_dict(data: Dictionary) -> SettlementState:
	var s := SettlementState.new(
		StringName(data.get("id", "")),
		data.get("name", ""),
		ResourceState.from_dict(data.get("inventory", {})),
		ResourceState.from_dict(data.get("production", {})),
		ResourceState.from_dict(data.get("consumption", {})),
		int(data.get("target_water", 100)),
		int(data.get("target_food", 100)),
		float(data.get("base_price_water", 10.0)),
		float(data.get("base_price_food", 10.0)),
		int(data.get("target_scrap", 60)),
		int(data.get("target_fuel", 40)),
		float(data.get("base_price_scrap", 12.0)),
		float(data.get("base_price_fuel", 15.0))
	)
	s.price_water = float(data.get("price_water", s.base_price_water))
	s.price_food = float(data.get("price_food", s.base_price_food))
	s.price_scrap = float(data.get("price_scrap", s.base_price_scrap))
	s.price_fuel = float(data.get("price_fuel", s.base_price_fuel))
	return s
