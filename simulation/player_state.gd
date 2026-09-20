class_name PlayerState
extends RefCounted

const Capability = preload("res://simulation/capability_profile.gd")
var capability: RefCounted

# ==============================================================================
# S5-A: PLAYER AVATAR STATE
# ==============================================================================
# The player is an ordinary human within the wasteland, not an omnipotent
# observer. The player's identity and life state are part of the world's
# authoritative population accounting.
#
# FIELDS:
#   npc_id: StringName - References the underlying NpcIdentity and NpcLifeState
#   inventory: CargoState - Personal physical backpack (water, food, scrap, fuel)
#   capacity_total: int - Maximum backpack carrying capacity (default 20)
#   money: int - Scrip / bottle caps / wasteland currency (default 50)
#   water_pressure: float - Personal physiological water deprivation pressure
#   food_pressure: float - Personal physiological food deprivation pressure
#   water_exposure: float - Accumulated water deprivation, in equivalent days
#   food_exposure: float - Accumulated food deprivation, in equivalent days
#
# S5-B5 replaced the old days_deprived_* counters with exposure, to match the
# settlement model the world already uses. A day on half rations and a day with
# nothing at all are not the same suffering, and an integer "days with zero
# water" counter cannot tell them apart: exposure accumulates unmet/requested,
# so partial deprivation accumulates partially.
# ==============================================================================

var npc_id: StringName = &""
var inventory: ResourceState = null
var capacity_total: int = 20
var money: int = 50
var water_pressure: float = 0.0
var food_pressure: float = 0.0
var water_exposure: float = 0.0
var food_exposure: float = 0.0

func _init(
	p_npc_id: StringName = &"",
	p_capacity: int = 20,
	p_money: int = 50
) -> void:
	npc_id = p_npc_id
	capacity_total = p_capacity
	money = p_money
	inventory = ResourceState.new()
	capability = Capability.legacy(npc_id) if npc_id != &"" else null

func get_total_inventory_load() -> int:
	if inventory == null:
		return 0
	return inventory.water + inventory.food + inventory.scrap + inventory.fuel

func has_cargo_capacity(amount: int) -> bool:
	return get_total_inventory_load() + amount <= capacity_total

func duplicate_state() -> PlayerState:
	var copy := PlayerState.new(npc_id, capacity_total, money)
	if inventory != null:
		copy.inventory = inventory.duplicate_state()
	copy.water_pressure = water_pressure
	copy.food_pressure = food_pressure
	copy.water_exposure = water_exposure
	copy.food_exposure = food_exposure
	copy.capability = capability.duplicate_profile() if capability != null else null
	return copy

func to_dict() -> Dictionary:
	return {
		"npc_id": String(npc_id),
		"capability": capability.to_dict() if capability != null else null,
		"capacity_total": capacity_total,
		"money": money,
		"inventory": inventory.to_dict() if inventory != null else {},
		"water_pressure": NumericCanon.canonical_float(water_pressure),
		"food_pressure": NumericCanon.canonical_float(food_pressure),
		"water_exposure": NumericCanon.canonical_float(water_exposure),
		"food_exposure": NumericCanon.canonical_float(food_exposure),
	}

static func from_dict(data: Dictionary) -> PlayerState:
	var nid := StringName(data.get("npc_id", ""))
	var cap := int(data.get("capacity_total", 20))
	var mon := int(data.get("money", 50))
	var p := PlayerState.new(nid, cap, mon)
	if data.has("capability"):
		p.capability = Capability.from_dict_checked(data.capability).profile

	if data.has("inventory") and typeof(data["inventory"]) == TYPE_DICTIONARY:
		p.inventory = ResourceState.from_dict(data["inventory"])
	else:
		p.inventory = ResourceState.new()

	p.water_pressure = float(data.get("water_pressure", 0.0))
	p.food_pressure = float(data.get("food_pressure", 0.0))
	p.water_exposure = float(data.get("water_exposure", 0.0))
	p.food_exposure = float(data.get("food_exposure", 0.0))
	return p
