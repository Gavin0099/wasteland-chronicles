extends RefCounted

# Local browsing state only. No world reference, intent or persisted ordering.
const Registry = preload("res://simulation/item_registry.gd")
const CATEGORIES := ["ALL", "WEAPON", "APPAREL", "CONTAINER", "TOOL", "CONSUMABLE"]
const CATEGORY_NAMES := ["全部物品", "武器", "防具", "背包", "工具", "消耗品"]
const ORDERS := ["NAME", "WEIGHT", "QUALITY"]
const ORDER_NAMES := ["名稱", "重量由重到輕", "品質由高到低"]
const QUALITY_RANK := {"COMMON": 0, "MODIFIED": 1, "RARE": 2, "UNIQUE": 3}

static func normalize(state: Dictionary) -> Dictionary:
	var category: String = String(state.get("category", "ALL"))
	var order: String = String(state.get("order", "NAME"))
	return {"category": category if category in CATEGORIES else "ALL",
		"order": order if order in ORDERS else "NAME", "query": String(state.get("query", ""))}

static func rows(items: Array, state: Dictionary) -> Array[Dictionary]:
	var selected: Dictionary = normalize(state)
	var query: String = selected.query.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for entry: Dictionary in items:
		var found: Dictionary = Registry.resolve(String(entry.get("item_id", "")))
		if not found.success or int(entry.get("quantity", 0)) <= 0:
			continue
		var definition: Dictionary = found.definition
		if selected.category != "ALL" and definition.category != selected.category:
			continue
		var haystack: String = String(definition.display_name_zh) + " " + String(definition.description_zh)
		if query != "" and not haystack.to_lower().contains(query):
			continue
		result.append({"item_id": String(entry.item_id), "quantity": int(entry.quantity),
			"name": String(definition.display_name_zh), "definition": definition.duplicate(true),
			"weight_g": int(entry.quantity) * int(definition.base_weight)})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if selected.order == "WEIGHT" and a.weight_g != b.weight_g:
			return int(a.weight_g) > int(b.weight_g)
		if selected.order == "QUALITY":
			var aq: int = int(QUALITY_RANK[a.definition.quality])
			var bq: int = int(QUALITY_RANK[b.definition.quality])
			if aq != bq: return aq > bq
		var compared: int = String(a.name).naturalnocasecmp_to(String(b.name))
		return compared < 0 if compared != 0 else String(a.item_id) < String(b.item_id))
	return result
