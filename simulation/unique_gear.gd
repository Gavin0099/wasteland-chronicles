extends RefCounted
# Only the two authored retrievals. Historical facts are folded from receipts.
const SITES := {
	"RECOVER_GAS_MASK": {"place_id": "place:sealed_checkpoint", "item_id": "military_gas_mask", "day_index": 1, "route": "HIGHWAY", "rumor": "rumor:gas_mask"},
	"ENTER_TOXIC_WORKSHOP": {"place_id": "place:toxic_workshop", "item_id": "engineer_precision_tools", "day_index": 1, "route": "WILDERNESS", "rumor": "rumor:engineer_tools"},
}
const SCRAP_COST: int = 2

static func tracked(world) -> String:
	if world == null or world.player == null:
		return ""
	for index: int in range(world.event_log.size() - 1, -1, -1):
		if world.event_log[index].type == "RUMOR_TRACKED" and world.event_log[index].actor_id == world.player.npc_id:
			return String(world.event_log[index].payload.get("rumor_id", ""))
	return ""

static func taken(world, method: String) -> bool:
	if not SITES.has(method):
		return false
	for event in world.event_log:
		if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.payload.get("option") == method and event.payload.get("place_id") == SITES[method].place_id and event.payload.get("items_gained", {}).get(SITES[method].item_id, 0) == 1:
			return true
	return false

static func refusal(world, method: String) -> String:
	if not SITES.has(method):
		return "INVALID_UNIQUE_METHOD"
	var site: Dictionary = SITES[method]
	var encounter = world.active_encounter
	if tracked(world) != site.rumor or encounter == null or encounter.encounter_type != &"PLACE_VISIT" or encounter.context.get("place_id") != site.place_id or encounter.travel_day_index != int(site.day_index):
		return "UNIQUE_SITE_REQUIRED"
	var life = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	var party = world.get_refugee_party(life.population_container_id) if life != null else null
	if party == null or String(party.route_type) != String(site.route) or encounter.origin_id != party.origin_id or encounter.destination_id != party.destination_id or not ((String(party.origin_id) == "settlement:dry_well" and String(party.destination_id) == "settlement:new_hope") or (String(party.origin_id) == "settlement:new_hope" and String(party.destination_id) == "settlement:dry_well")):
		return "UNIQUE_SITE_REQUIRED"
	if taken(world, method):
		return "PLACE_ALREADY_CLEARED"
	if method == "ENTER_TOXIC_WORKSHOP" and not world.player.item_inventory.contains("military_gas_mask"):
		return "ITEM_NOT_HELD: military gas mask required"
	if world.player.inventory.scrap < SCRAP_COST:
		return "INSUFFICIENT_SCRAP: retrieval needs 2 scrap"
	if not world.player.item_inventory.has_capacity_for(site.item_id, 1, world.player.equipment.equipped_item("back")):
		return "ITEM_CAPACITY_EXCEEDED"
	return ""

static func validate(world) -> String:
	var retrieved: Dictionary = {}
	var visits: Dictionary = {}
	var trip: Dictionary = {}
	var chase: String = ""
	for event in world.event_log:
		var p: Dictionary = event.payload
		if event.type == "RUMOR_TRACKED" and world.player != null and event.actor_id == world.player.npc_id:
			chase = String(p.get("rumor_id", ""))
		if event.type == "PLAYER_TRAVEL_STARTED" and world.player != null and event.actor_id == world.player.npc_id:
			trip = p
			visits.clear()
		if event.type == "TRAVEL_ENCOUNTER" and p.get("encounter_type") == "PLACE_VISIT":
			visits[String(p.get("place_id", ""))] = {"event": event, "trip": trip.duplicate(true), "rumor": chase}
		if event.type != "TRAVEL_ENCOUNTER_RESOLVED":
			continue
		if not SITES.has(p.get("option", "")):
			visits.erase(String(p.get("place_id", "")))
			continue
		var method: String = p.option
		var site: Dictionary = SITES[method]
		if world.player == null or event.actor_id != world.player.npc_id or retrieved.has(method) or p.get("place_id") != site.place_id or p.get("encounter_type") != "PLACE_VISIT" or p.get("elapsed_days") != 1 or p.get("cost_extra_day") != true or typeof(p.get("spent")) != TYPE_DICTIONARY or p.spent.get("scrap") != 2 or typeof(p.get("items_gained")) != TYPE_DICTIONARY or p.items_gained.size() != 1 or p.items_gained.get(String(site.item_id)) != 1 or p.get("items_left_behind", {}) != {} or p.get("gained") != {}:
			return "UNIQUE_RETRIEVAL_INVALID"
		var source: Dictionary = visits.get(String(site.place_id), {})
		var visit = source.get("event")
		var journey: Dictionary = source.get("trip", {})
		if source.get("rumor") != site.rumor or visit == null or visit.actor_id != world.player.npc_id or event.day != visit.day + 1 or p.get("origin") != visit.payload.get("origin") or p.get("destination") != visit.payload.get("destination"):
			return "UNIQUE_RETRIEVAL_SITE_MISMATCH"
		if p.origin not in ["settlement:dry_well", "settlement:new_hope"] or p.destination not in ["settlement:dry_well", "settlement:new_hope"] or p.origin == p.destination or visit.payload.get("travel_day_index") != int(site.day_index) or journey.get("route_type") != site.route or journey.get("origin") != p.origin or journey.get("destination") != p.destination:
			return "UNIQUE_RETRIEVAL_ROUTE_MISMATCH"
		retrieved[method] = true
	return ""

