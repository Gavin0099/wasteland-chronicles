extends RefCounted

# ITEM-1 authored definitions. Each call constructs detached records; no writable
# global catalogue, save-owned copy, asset-directory scan or gameplay side effect.
static func rows() -> Array:
	return [
		_row("rusted_knife", "生鏽小刀", "WEAPON", 250, "item_rusted_knife", ["blade", "tool"]),
		_row("hunting_knife", "獵刀", "WEAPON", 400, "item_hunting_knife", ["blade", "hunting", "tool"]),
		_row("rebar_club", "鋼筋棍", "WEAPON", 1800, "item_rebar_club", ["blunt", "metal"]),
		_row("scrap_machete", "廢鐵砍刀", "WEAPON", 1200, "item_scrap_machete", ["blade", "salvaged"]),
		_row("work_clothes", "舊工作服", "APPAREL", 1200, "item_work_clothes", ["clothing", "workwear"]),
		_row("desert_robe", "沙地長袍", "APPAREL", 900, "item_desert_robe", ["clothing", "desert"]),
		_row("caravan_coat", "商隊外套", "APPAREL", 1500, "item_caravan_coat", ["clothing", "travel"]),
		_row("travel_backpack", "舊旅行包", "CONTAINER", 1100, "item_travel_backpack", ["bag", "travel"]),
		_row("rope", "繩索", "TOOL", 2500, "item_rope", ["rope", "travel"]),
		_row("flashlight", "手電筒", "TOOL", 400, "item_flashlight", ["lighting", "tool"]),
		_row("wrench", "扳手", "TOOL", 700, "item_wrench", ["hand_tool", "metal"]),
		_row("first_aid_kit", "急救包", "CONSUMABLE", 800, "item_first_aid_kit", ["medical"], "STACKABLE"),
	]

static func _row(id: String, label: String, category: String, grams: int, asset: String, tags: Array, stacking: String = "UNIQUE") -> Dictionary:
	return {"item_id": id, "display_name_zh": label, "category": category,
		"stack_mode": stacking, "base_weight": grams, "asset_id": asset, "tags": tags}
