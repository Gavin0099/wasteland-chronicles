class_name ItemMarketState
extends RefCounted

## ITEM-8: the smallest stateful shop authority.
##
## Stock is seeded lazily from ITEM-7 supply metadata. A missing state means a
## fresh shop, so old saves and untouched worlds retain their exact wire shape.
## Prices use the authored base value with a fixed buy/sell spread; regional
## supply/demand controls availability and whether the market accepts sales.

const Registry = preload("res://simulation/item_registry.gd")
const Markets = preload("res://simulation/item_market_catalogue.gd")
const MAX_STOCK: int = 1000

var _stock: Dictionary = {}

static func default_quantity(supply: String) -> int:
	match supply:
		"low": return 1
		"medium": return 3
		"high": return 6
		_: return 0

static func seeded_for(settlement_id: Variant) -> RefCounted:
	var state := new()
	var normalized := Markets.settlement_key(settlement_id)
	if normalized.is_empty():
		return state
	for definition in Registry.all_definitions():
		var supply := String(definition.settlement_supply[normalized])
		var quantity := default_quantity(supply)
		if quantity > 0:
			state._stock[definition.item_id] = quantity
	return state

func is_empty() -> bool:
	return _stock.is_empty()

func quantity(item_id: Variant) -> int:
	if typeof(item_id) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return 0
	return int(_stock.get(String(item_id), 0))

func set_quantity(item_id: Variant, value: int) -> Dictionary:
	var normalized_item := String(item_id) if typeof(item_id) in [TYPE_STRING, TYPE_STRING_NAME] else ""
	if not Registry.resolve(normalized_item).success:
		return _failure("UNKNOWN_ITEM_ID")
	if typeof(value) != TYPE_INT or value < 0 or value > MAX_STOCK:
		return _failure("INVALID_MARKET_STOCK")
	_stock[normalized_item] = value
	return {"success": true, "error": "", "item_id": normalized_item, "quantity": value}

func remove(item_id: Variant, requested: int) -> Dictionary:
	if typeof(requested) != TYPE_INT or requested <= 0:
		return _failure("INVALID_ITEM_QUANTITY")
	if quantity(item_id) < requested:
		return _failure("INSUFFICIENT_MARKET_STOCK")
	_stock[item_id] = quantity(item_id) - requested
	return {"success": true, "error": "", "item_id": item_id, "quantity": quantity(item_id)}

func add(item_id: Variant, quantity_to_add: int) -> Dictionary:
	if typeof(quantity_to_add) != TYPE_INT or quantity_to_add <= 0:
		return _failure("INVALID_ITEM_QUANTITY")
	var normalized_item := String(item_id) if typeof(item_id) in [TYPE_STRING, TYPE_STRING_NAME] else ""
	if not Registry.resolve(normalized_item).success:
		return _failure("UNKNOWN_ITEM_ID")
	var next := quantity(normalized_item) + quantity_to_add
	if next > MAX_STOCK:
		return _failure("MARKET_STOCK_LIMIT_EXCEEDED")
	_stock[normalized_item] = next
	return {"success": true, "error": "", "item_id": normalized_item, "quantity": next}

func duplicate_state() -> RefCounted:
	var copy := new()
	copy._stock = _stock.duplicate(true)
	return copy

func restock_for(settlement_id: Variant, current_day: int) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	var normalized := Markets.settlement_key(settlement_id)
	if normalized.is_empty() or current_day <= 0:
		return changes
	var ids: Array = _stock.keys()
	ids.sort()
	for item_id in ids:
		var profile := Markets.profile_for(String(item_id), normalized)
		if not profile.success:
			continue
		var interval := _restock_interval(String(profile.supply))
		if interval <= 0 or current_day % interval != 0 or quantity(item_id) >= MAX_STOCK:
			continue
		var before := quantity(item_id)
		_stock[item_id] = mini(MAX_STOCK, before + 1)
		changes.append({"item_id": String(item_id), "before": before, "after": quantity(item_id)})
	return changes

func to_dict() -> Dictionary:
	var entries: Array = []
	var ids: Array = _stock.keys()
	ids.sort()
	for item_id in ids:
		entries.append({"item_id": item_id, "quantity": int(_stock[item_id])})
	return {"items": entries}

static func buy_quote(item_id: Variant, settlement_id: Variant, market: RefCounted = null) -> int:
	var profile := Markets.profile_for(item_id, settlement_id)
	if not profile.success or not profile.is_routinely_supplied:
		return 0
	var resolved := Registry.resolve(String(item_id))
	var base_value: int = int(resolved.definition.base_value)
	var target: int = default_quantity(String(profile.supply))
	var current: int = target if market == null else market.quantity(String(item_id))
	var shortage_ratio: float = 0.0 if target <= 0 else clampf(float(target - current) / float(target), 0.0, 1.0)
	return maxi(1, int(ceil(float(base_value) * (1.0 + shortage_ratio * 0.5))))

static func sell_quote(item_id: Variant, settlement_id: Variant) -> int:
	var profile := Markets.profile_for(item_id, settlement_id)
	if not profile.success or profile.demand == "none":
		return 0
	var resolved := Registry.resolve(String(item_id))
	var demand_rate: float = float({"low": 0.4, "medium": 0.5, "high": 0.6}.get(profile.demand, 0.0))
	return maxi(1, int(floor(float(resolved.definition.base_value) * float(demand_rate))))

static func validate_serialized(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY or data.size() != 1 or not data.has("items") or typeof(data.items) != TYPE_ARRAY:
		return "INVALID_ITEM_MARKET"
	var seen := {}
	for entry in data.items:
		if typeof(entry) != TYPE_DICTIONARY or entry.size() != 2 or not entry.has("item_id") or not entry.has("quantity"):
			return "INVALID_ITEM_MARKET_ENTRY"
		if typeof(entry.item_id) != TYPE_STRING or seen.has(entry.item_id):
			return "INVALID_ITEM_MARKET_ID"
		if not Registry.resolve(entry.item_id).success:
			return "UNKNOWN_ITEM_ID"
		var restored := _restore_quantity(entry.quantity)
		if not restored.ok or restored.value > MAX_STOCK:
			return "INVALID_MARKET_STOCK"
		seen[entry.item_id] = true
	return ""

static func from_dict_checked(data: Variant) -> Dictionary:
	var error := validate_serialized(data)
	if error != "":
		return {"success": false, "market": null, "error": error}
	var market := new()
	for entry in data.items:
		market._stock[entry.item_id] = int(entry.quantity)
	return {"success": true, "market": market, "error": ""}

static func from_dict(data: Variant) -> RefCounted:
	var checked := from_dict_checked(data)
	return checked.market if checked.success else new()

static func _restore_quantity(value: Variant) -> Dictionary:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) < 0 or float(value) != floor(float(value)):
		return {"ok": false, "value": 0}
	if absf(float(value)) > 9007199254740992.0:
		return {"ok": false, "value": 0}
	return {"ok": true, "value": int(value)}

static func _restock_interval(supply: String) -> int:
	match supply:
		"high": return 1
		"medium": return 2
		"low": return 4
		_: return 0

func _failure(error: String) -> Dictionary:
	return {"success": false, "error": error, "item_id": "", "quantity": 0}
