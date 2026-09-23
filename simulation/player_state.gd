class_name PlayerState
extends RefCounted

const Capability = preload("res://simulation/capability_profile.gd")
const ItemInventory = preload("res://simulation/item_inventory_state.gd")
const Equipment = preload("res://simulation/equipment_state.gd")
var capability: RefCounted
const Field = preload("res://simulation/field_adventure.gd")
var field_kit: Dictionary = Field.new_kit()

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
var item_inventory: RefCounted = null
var equipment: RefCounted = null
var capacity_total: int = 20
var money: int = 50
var water_pressure: float = 0.0
var food_pressure: float = 0.0
var water_exposure: float = 0.0
var food_exposure: float = 0.0

# QUEST-1 Progression State (CHAR-PROG-1 owns spending logic)
var xp: int = 0             # lifetime XP earned from quests and events
var growth_points: int = 0  # spendable points: CHAR-PROG-1 converts XP -> growth_points

func _init(
	p_npc_id: StringName = &"",
	p_capacity: int = 20,
	p_money: int = 50
) -> void:
	npc_id = p_npc_id
	capacity_total = p_capacity
	money = p_money
	inventory = ResourceState.new()
	item_inventory = ItemInventory.new()
	equipment = Equipment.new()
	capability = Capability.legacy(npc_id) if npc_id != &"" else null

func pickup_item(item_id: Variant, quantity: int = 1) -> Dictionary:
	return item_inventory.pickup_item(item_id, quantity)

func drop_item(item_id: Variant, quantity: int = 1) -> Dictionary:
	return item_inventory.drop_item(item_id, quantity)

func inspect_item(item_id: Variant) -> Dictionary:
	return item_inventory.inspect_item(item_id)

func equip_item(item_id: Variant, slot: String) -> Dictionary:
	return equipment.equip(item_id, slot, item_inventory)

func unequip_item(slot: String) -> Dictionary:
	return equipment.unequip(slot)

func get_total_inventory_load() -> int:
	if inventory == null:
		return 0
	return inventory.water + inventory.food + inventory.scrap + inventory.fuel + (Field.KIT_WEIGHT if field_kit.crowbar else 0)

func has_cargo_capacity(amount: int) -> bool:
	return get_total_inventory_load() + amount <= capacity_total

func duplicate_state() -> PlayerState:
	var copy := PlayerState.new(npc_id, capacity_total, money)
	if inventory != null:
		copy.inventory = inventory.duplicate_state()
	if item_inventory != null:
		copy.item_inventory = item_inventory.duplicate_state()
	if equipment != null:
		copy.equipment = equipment.duplicate_state()
	copy.field_kit = field_kit.duplicate(true)
	copy.water_pressure = water_pressure
	copy.food_pressure = food_pressure
	copy.water_exposure = water_exposure
	copy.food_exposure = food_exposure
	copy.capability = capability.duplicate_profile() if capability != null else null
	copy.xp = xp
	copy.growth_points = growth_points
	return copy

func to_dict() -> Dictionary:
	var result := {
		"npc_id": String(npc_id),
		"field_kit": field_kit.duplicate(true),
		"capability": capability.to_dict() if capability != null else null,
		"capacity_total": capacity_total,
		"money": money,
		"inventory": inventory.to_dict() if inventory != null else {},
		"water_pressure": NumericCanon.canonical_float(water_pressure),
		"food_pressure": NumericCanon.canonical_float(food_pressure),
		"water_exposure": NumericCanon.canonical_float(water_exposure),
		"food_exposure": NumericCanon.canonical_float(food_exposure),
	}
	if item_inventory != null and not item_inventory.is_empty():
		result["item_inventory"] = item_inventory.to_dict()
	if equipment != null and not equipment.is_empty():
		result["equipment"] = equipment.to_dict()
	# Omit-if-zero: avoids touching existing save SHA when progression is unused
	if xp > 0:
		result["xp"] = xp
	if growth_points > 0:
		result["growth_points"] = growth_points
	return result

static func from_dict(data: Dictionary) -> PlayerState:
	var nid := StringName(data.get("npc_id", ""))
	var cap := int(data.get("capacity_total", 20))
	var mon := int(data.get("money", 50))
	var p := PlayerState.new(nid, cap, mon)
	if data.has("field_kit"):
		p.field_kit = data.field_kit.duplicate(true)
		p.field_kit.hp = int(p.field_kit.hp)
	if data.has("capability"):
		p.capability = Capability.from_dict_checked(data.capability).profile

	if data.has("inventory") and typeof(data["inventory"]) == TYPE_DICTIONARY:
		p.inventory = ResourceState.from_dict(data["inventory"])
	else:
		p.inventory = ResourceState.new()
	if data.has("item_inventory"):
		p.item_inventory = ItemInventory.from_dict(data["item_inventory"])
	else:
		p.item_inventory = ItemInventory.new()
	if data.has("equipment"):
		p.equipment = Equipment.from_dict(data["equipment"], p.item_inventory)
	else:
		p.equipment = Equipment.new()

	p.water_pressure = float(data.get("water_pressure", 0.0))
	p.food_pressure = float(data.get("food_pressure", 0.0))
	p.water_exposure = float(data.get("water_exposure", 0.0))
	p.food_exposure = float(data.get("food_exposure", 0.0))
	# Graceful migration: old saves without xp/growth_points load as 0
	p.xp = int(data.get("xp", 0))
	p.growth_points = int(data.get("growth_points", 0))
	return p
