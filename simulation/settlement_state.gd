class_name SettlementState
extends RefCounted

const ItemMarket = preload("res://simulation/item_market_state.gd")

var id: StringName = &""
var name: String = ""

# 庫存、產能、消耗 (包含 water, food, scrap, fuel)
var inventory: ResourceState
var production: ResourceState
var consumption: ResourceState

# S3-A 人口與生理代謝率 (Population & Biological Metabolism)
var population: int = 0
var metabolism_water_rate: float = 0.05
var metabolism_food_rate: float = 0.04
var maintenance_scrap: int = 0
var maintenance_fuel: int = 0

# S3-E 基準額定勞動人口與小數產出累加器 (Labor Capacity Baseline & Deterministic Credit Accumulator)
var reference_population: int = 0
var production_credits: Dictionary = {}

# S3-B 生理短缺壓力 (Basic Needs Pressure - Durable State)
var water_pressure: float = 0.0
var food_pressure: float = 0.0

# S3-C 難民遷徙冷卻記錄 (Durable State)
var days_since_last_migration: int = 999

# S3-D 生理匱乏暴露累積與累積死亡 (Deprivation Exposure & Mortality - Durable State)
var water_exposure: float = 0.0
var food_exposure: float = 0.0
var cumulative_deaths: int = 0

# S3-F 聚落治安度與在地秩序損耗統計 (Security & Local Disorder Loss - Durable State)
var security: float = 100.0
var disorder_loss_credits: Dictionary = {}
var cumulative_disorder_loss: Dictionary = {}

# 每日需求會計觀測記錄 (Transient Tick Evidence - 非持久化世界狀態)
var last_need_outcomes: Dictionary = {}

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

# S5-B2 本地市場貨幣儲備 (Market Cash / Currency Reserve - Durable State)
var market_cash: int = 500
var item_market: RefCounted = null

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
	p_base_price_fuel: float = 15.0,
	p_market_cash: int = 500
) -> void:
	id = p_id
	name = p_name
	inventory = p_inventory if p_inventory != null else ResourceState.new()
	production = p_production if p_production != null else ResourceState.new()
	consumption = p_consumption if p_consumption != null else ResourceState.new()
	market_cash = p_market_cash
	
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

# S3-A 人口生理代謝需求動態推導 (無聚落身份特判)
func get_biological_demand(resource: StringName) -> int:
	if resource == &"water":
		return int(round(float(population) * metabolism_water_rate))
	elif resource == &"food":
		return int(round(float(population) * metabolism_food_rate))
	return 0

func update_consumption_from_metabolism() -> void:
	if consumption == null:
		consumption = ResourceState.new()
	if population > 0:
		consumption.water = get_biological_demand(&"water")
		consumption.food = get_biological_demand(&"food")
	if maintenance_scrap > 0:
		consumption.scrap = maintenance_scrap
	if maintenance_fuel > 0:
		consumption.fuel = maintenance_fuel

func set_population_and_rates(
	p_pop: int,
	p_water_rate: float,
	p_food_rate: float,
	p_maint_scrap: int = 0,
	p_maint_fuel: int = 0,
	p_ref_pop: int = -1
) -> void:
	population = p_pop
	metabolism_water_rate = p_water_rate
	metabolism_food_rate = p_food_rate
	maintenance_scrap = p_maint_scrap
	maintenance_fuel = p_maint_fuel
	reference_population = p_ref_pop if p_ref_pop >= 0 else p_pop
	update_consumption_from_metabolism()

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
	copy.population = population
	copy.metabolism_water_rate = metabolism_water_rate
	copy.metabolism_food_rate = metabolism_food_rate
	copy.maintenance_scrap = maintenance_scrap
	copy.maintenance_fuel = maintenance_fuel
	copy.reference_population = reference_population
	copy.production_credits = production_credits.duplicate(true)
	copy.water_pressure = water_pressure
	copy.food_pressure = food_pressure
	copy.days_since_last_migration = days_since_last_migration
	copy.water_exposure = water_exposure
	copy.food_exposure = food_exposure
	copy.cumulative_deaths = cumulative_deaths
	copy.security = security
	copy.disorder_loss_credits = disorder_loss_credits.duplicate(true)
	copy.cumulative_disorder_loss = cumulative_disorder_loss.duplicate(true)
	copy.last_need_outcomes = last_need_outcomes.duplicate(true)
	copy.market_cash = market_cash
	copy.item_market = item_market.duplicate_state() if item_market != null else null
	return copy

func to_dict() -> Dictionary:
	var result := {
		"id": String(id),
		"name": name,
		"inventory": inventory.to_dict(),
		"production": production.to_dict(),
		"consumption": consumption.to_dict(),
		"population": population,
		"metabolism_water_rate": metabolism_water_rate,
		"metabolism_food_rate": metabolism_food_rate,
		"maintenance_scrap": maintenance_scrap,
		"maintenance_fuel": maintenance_fuel,
		"reference_population": reference_population,
		"production_credits": production_credits.duplicate(true),
		"water_pressure": water_pressure,
		"food_pressure": food_pressure,
		"days_since_last_migration": days_since_last_migration,
		"water_exposure": water_exposure,
		"food_exposure": food_exposure,
		"cumulative_deaths": cumulative_deaths,
		"security": security,
		"disorder_loss_credits": disorder_loss_credits.duplicate(true),
		"cumulative_disorder_loss": cumulative_disorder_loss.duplicate(true),
		"market_cash": market_cash,
		"target_water": target_water,
		"target_food": target_food,
		"target_scrap": target_scrap,
		"target_fuel": target_fuel,
		"base_price_water": base_price_water,
		"base_price_food": base_price_food,
		"base_price_scrap": base_price_scrap,
		"base_price_fuel": base_price_fuel,
		"price_water": price_water,
		"price_food": price_food,
		"price_scrap": price_scrap,
		"price_fuel": price_fuel
	}
	if item_market != null and not item_market.is_empty():
		result["item_market"] = item_market.to_dict()
	return result

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
		float(data.get("base_price_fuel", 15.0)),
		int(data.get("market_cash", 500))
	)
	s.market_cash = int(data.get("market_cash", 500))
	s.price_water = float(data.get("price_water", s.base_price_water))
	s.price_food = float(data.get("price_food", s.base_price_food))
	s.price_scrap = float(data.get("price_scrap", s.base_price_scrap))
	s.price_fuel = float(data.get("price_fuel", s.base_price_fuel))
	s.population = int(data.get("population", 0))
	s.metabolism_water_rate = float(data.get("metabolism_water_rate", 0.05))
	s.metabolism_food_rate = float(data.get("metabolism_food_rate", 0.04))
	s.maintenance_scrap = int(data.get("maintenance_scrap", 0))
	s.maintenance_fuel = int(data.get("maintenance_fuel", 0))
	s.reference_population = int(data.get("reference_population", s.population))
	# AUTHORITATIVE STATE (carry accumulation read by later ticks): Dictionary[*, float]
	s.production_credits = NumericCanon.canonical_float_dict(data.get("production_credits", {}))
	s.water_pressure = float(data.get("water_pressure", 0.0))
	s.food_pressure = float(data.get("food_pressure", 0.0))
	s.days_since_last_migration = int(data.get("days_since_last_migration", 999))
	s.water_exposure = float(data.get("water_exposure", 0.0))
	s.food_exposure = float(data.get("food_exposure", 0.0))
	s.cumulative_deaths = int(data.get("cumulative_deaths", 0))
	s.security = float(data.get("security", 100.0))
	s.disorder_loss_credits = NumericCanon.canonical_float_dict(data.get("disorder_loss_credits", {}))
	# ACCOUNTING STATE (no simulation-control authority): Dictionary[StringName, int].
	# Restored by DECLARED SCHEMA, not by what the serialized value looks like.
	var raw_cumulative: Dictionary = data.get("cumulative_disorder_loss", {})
	s.cumulative_disorder_loss = {}
	for k in raw_cumulative:
		var r := NumericCanon.restore_int(raw_cumulative[k], "cumulative_disorder_loss.%s" % String(k), 0)
		s.cumulative_disorder_loss[k] = r["value"] if r["ok"] else 0
	if data.has("item_market"):
		s.item_market = ItemMarket.from_dict(data.item_market)
	return s
