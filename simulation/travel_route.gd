class_name TravelRoute
extends RefCounted

# ==============================================================================
# WPROG-2: ROUTE CHOICE ON THE NEW HOPE–DRY WELL CORRIDOR
# ==============================================================================
# "My growth choice alters which route I consider worthwhile to travel."
#
# Route A: HIGHWAY (廢棄公路)
#   - 2 Days (low water/food consumption)
#   - Bandit ambush is more likely, never guaranteed.
#   - Fighters can use their existing weapon advantage when one happens.
#
# Route B: WILDERNESS (荒野繞路)
#   - 4 Days (high water/food consumption)
#   - Bandits are less likely; wrecks are more likely, never guaranteed.
#   - Wreck yield remains the existing deterministic S5-B4 yield.
#   - Scavengers can use their existing backpack capacity when a wreck pays.
#
# Untyped legacy journeys and other corridors retain their previous route and
# world-reactive encounter selection. WPROG-3 owns exclusive high-tier loot.
# ==============================================================================

const ROUTE_HIGHWAY := &"HIGHWAY"
const ROUTE_WILDERNESS := &"WILDERNESS"

const ROUTES := {
	"HIGHWAY": {
		"id": "HIGHWAY",
		"name_zh": "廢棄公路",
		"days": 2,
		"risk_zh": "較容易遭遇劫匪",
		"reward_zh": "路程短、水糧消耗低",
		"description_zh": "舊時代鋪設的柏油公路，路程筆直只需 2 天；路旁掩體讓劫匪有機會埋伏。",
	},
	"WILDERNESS": {
		"id": "WILDERNESS",
		"name_zh": "荒野繞路",
		"days": 4,
		"risk_zh": "耗時長、消耗水糧高",
		"reward_zh": "較少劫匪、較可能發現貨車殘骸",
		"description_zh": "遠離主幹道的荒野沙地，路程蜿蜒需耗時 4 天，水糧消耗加倍；有時能發現被遺落的貨車殘骸。",
	}
}

static func is_valid_route(route_id: Variant) -> bool:
	return String(route_id) in ["HIGHWAY", "WILDERNESS"]

static func supports_pair(origin_id: StringName, dest_id: StringName) -> bool:
	return (origin_id == &"settlement:new_hope" and dest_id == &"settlement:dry_well") or (origin_id == &"settlement:dry_well" and dest_id == &"settlement:new_hope")

static func get_route(route_id: Variant) -> Dictionary:
	var key := String(route_id)
	if ROUTES.has(key):
		return (ROUTES[key] as Dictionary).duplicate(true)
	return {}

static func get_available_routes(origin_id: StringName, dest_id: StringName) -> Array[Dictionary]:
	if not supports_pair(origin_id, dest_id):
		return []
	return [
		(ROUTES["HIGHWAY"] as Dictionary).duplicate(true),
		(ROUTES["WILDERNESS"] as Dictionary).duplicate(true)
	]

static func get_route_days(origin_id: StringName, dest_id: StringName, route_type: Variant) -> int:
	if not supports_pair(origin_id, dest_id) or not is_valid_route(route_type):
		return -1
	return int(ROUTES[String(route_type)]["days"])
