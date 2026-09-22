class_name ItemMarketCatalogue
extends RefCounted

## ITEM-7: read-only regional item market projection.
##
## This slice answers which canonical items have a regional supply/demand
## profile. It deliberately does not create shop stock, prices, ownership or
## transaction authority. Those are separate stateful slices.

const Registry = preload("res://simulation/item_registry.gd")

const SETTLEMENTS: Array[String] = ["new_hope", "gray_valley", "dry_well"]
const SUPPLY_LEVELS: Array[String] = ["none", "low", "medium", "high"]

static func settlement_key(value: Variant) -> String:
	if typeof(value) != TYPE_STRING:
		return ""
	var key := String(value)
	if key.begins_with("settlement:"):
		key = key.trim_prefix("settlement:")
	return key if key in SETTLEMENTS else ""

static func profile_for(item_id: Variant, settlement_id: Variant) -> Dictionary:
	var settlement := settlement_key(settlement_id)
	if settlement.is_empty():
		return _failure("UNKNOWN_SETTLEMENT")
	var resolved := Registry.resolve(item_id)
	if not resolved.success:
		return _failure("UNKNOWN_ITEM_ID")
	var definition: Dictionary = resolved.definition
	return {
		"success": true,
		"error": "",
		"item_id": definition.item_id,
		"settlement_id": "settlement:" + settlement,
		"display_name_zh": definition.display_name_zh,
		"category": definition.category,
		"asset_id": definition.asset_id,
		"supply": String(definition.settlement_supply[settlement]),
		"demand": String(definition.settlement_demand[settlement]),
		"is_routinely_supplied": definition.settlement_supply[settlement] != "none",
	}

static func offers_for(settlement_id: Variant) -> Dictionary:
	var settlement := settlement_key(settlement_id)
	if settlement.is_empty():
		return _failure("UNKNOWN_SETTLEMENT")
	var offers: Array[Dictionary] = []
	for definition in Registry.all_definitions():
		var supply := String(definition.settlement_supply[settlement])
		if supply == "none":
			continue
		offers.append({
			"item_id": definition.item_id,
			"display_name_zh": definition.display_name_zh,
			"category": definition.category,
			"asset_id": definition.asset_id,
			"supply": supply,
			"demand": String(definition.settlement_demand[settlement]),
		})
	offers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.item_id) < String(b.item_id)
	)
	return {
		"success": true,
		"error": "",
		"settlement_id": "settlement:" + settlement,
		"offers": offers,
	}

static func summary_for(settlement_id: Variant) -> Dictionary:
	var listed := offers_for(settlement_id)
	if not listed.success:
		return listed
	var counts := {"low": 0, "medium": 0, "high": 0}
	for offer in listed.offers:
		var level := String(offer.supply)
		if counts.has(level):
			counts[level] += 1
	return {
		"success": true,
		"error": "",
		"settlement_id": listed.settlement_id,
		"listed_item_count": listed.offers.size(),
		"supply_counts": counts,
	}

static func validate_catalogue() -> String:
	for definition in Registry.all_definitions():
		for settlement in SETTLEMENTS:
			if not definition.settlement_supply.has(settlement) or not definition.settlement_demand.has(settlement):
				return "INCOMPLETE_MARKET_PROFILE:%s:%s" % [definition.item_id, settlement]
			if not String(definition.settlement_supply[settlement]) in SUPPLY_LEVELS:
				return "INVALID_SUPPLY_LEVEL:%s:%s" % [definition.item_id, settlement]
			if not String(definition.settlement_demand[settlement]) in SUPPLY_LEVELS:
				return "INVALID_DEMAND_LEVEL:%s:%s" % [definition.item_id, settlement]
	return ""

static func _failure(error: String) -> Dictionary:
	return {"success": false, "error": error}
