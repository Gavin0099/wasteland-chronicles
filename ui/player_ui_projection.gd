class_name PlayerUIProjection
extends RefCounted

# ==============================================================================
# S5-A.2: PLAYER UI PROJECTION (ISOLATION LAYER)
# ==============================================================================
# Architecture Boundary:
#   WorldState -> PlayerUIProjection -> Godot UI
#
# UI controls and views MUST NEVER read or write WorldState directly.
# Current settlement provides LIVE authoritative data.
# Remote settlements provide only minimal KNOWN data (Name, route, distance),
# guarding against information leakage prior to S7 Information Fog.
# Event feed is explicitly marked as a DEBUG WORLD FEED.
# ==============================================================================

static func project(world: WorldState, debug_feed_enabled: bool = true) -> Dictionary:
	if world == null:
		return {}

	var proj := {
		"current_day": world.current_day,
		"player": _project_player(world),
		"current_settlement": _project_current_settlement(world),
		"destinations": _project_destinations(world),
		"events": _project_recent_events(world, 8) if debug_feed_enabled else [],
		"debug_feed_enabled": debug_feed_enabled
	}
	return proj

static func _project_player(world: WorldState) -> Dictionary:
	if world.player == null:
		return {
			"has_player": false,
			"npc_id": "",
			"name": "Unknown",
			"money": 0,
			"status": "NONE",
			"location_display": "Nowhere",
			"backpack": {
				"water": 0,
				"food": 0,
				"scrap": 0,
				"fuel": 0,
				"load": 0,
				"capacity": 20
			}
		}

	var p: PlayerState = world.player
	var id: NpcIdentity = world.npc_registry.get_npc(p.npc_id)
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(p.npc_id)

	var p_name := id.name if id != null else "Drifter"
	var status_str := "UNKNOWN"
	var location_display := "Unknown"
	var is_in_transit := false
	var days_left := 0

	if ls != null:
		match ls.status:
			NpcLifeState.Status.SETTLED:
				status_str = "SETTLED"
				var s: SettlementState = world.get_settlement(ls.population_container_id)
				location_display = s.name if s != null else String(ls.population_container_id)
			NpcLifeState.Status.IN_TRANSIT:
				status_str = "IN_TRANSIT"
				is_in_transit = true
				var party: RefugeePartyState = world.get_refugee_party(ls.population_container_id)
				if party != null:
					var dest: SettlementState = world.get_settlement(party.destination_id)
					var dest_name := dest.name if dest != null else String(party.destination_id)
					days_left = party.days_remaining
					location_display = "In Transit to %s (%d days remaining)" % [dest_name, days_left]
				else:
					location_display = "In Transit"
			NpcLifeState.Status.DEAD:
				status_str = "DEAD"
				location_display = "Deceased"

	var bp_load := p.get_total_inventory_load()

	return {
		"has_player": true,
		"npc_id": String(p.npc_id),
		"name": p_name,
		"money": p.money,
		"status": status_str,
		"is_in_transit": is_in_transit,
		"location_display": location_display,
		"current_container_id": String(ls.population_container_id) if ls != null else "",
		"backpack": {
			"water": p.inventory.water if p.inventory != null else 0,
			"food": p.inventory.food if p.inventory != null else 0,
			"scrap": p.inventory.scrap if p.inventory != null else 0,
			"fuel": p.inventory.fuel if p.inventory != null else 0,
			"load": bp_load,
			"capacity": p.capacity_total
		},
		"water_pressure": p.water_pressure,
		"food_pressure": p.food_pressure
	}

static func _project_current_settlement(world: WorldState) -> Dictionary:
	if world.player == null:
		return {}

	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if ls == null or ls.status != NpcLifeState.Status.SETTLED:
		return {}

	var s: SettlementState = world.get_settlement(ls.population_container_id)
	if s == null:
		return {}

	# LIVE authoritative data for player's current location only
	return {
		"id": String(s.id),
		"name": s.name,
		"population": s.population,
		"water": s.inventory.water,
		"food": s.inventory.food,
		"scrap": s.inventory.scrap,
		"fuel": s.inventory.fuel,
		"security": s.security,
		"water_pressure": s.water_pressure,
		"food_pressure": s.food_pressure,
		"price_water": s.price_water,
		"price_food": s.price_food,
		"price_scrap": s.price_scrap,
		"price_fuel": s.price_fuel,
		"is_live": true
	}

static func _project_destinations(world: WorldState) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if world.player == null:
		return list

	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	var current_loc: StringName = ls.population_container_id if ls != null else &""
	var is_settled: bool = (ls != null and ls.status == NpcLifeState.Status.SETTLED)

	var sorted_keys: Array = world.settlements.keys()
	sorted_keys.sort_custom(func(a, b): return String(a) < String(b))

	for s_id in sorted_keys:
		var s: SettlementState = world.settlements[s_id]
		var is_here: bool = (StringName(s_id) == current_loc)
		var route_days := 0
		if not is_here and is_settled:
			route_days = _calc_route_days(world, current_loc, StringName(s_id))

		# Remote settlement projection: ONLY name, route availability, distance.
		# Strictly NO economic leaks (no specialization, no stock, no prices).
		list.append({
			"id": String(s.id),
			"name": s.name,
			"route_days": route_days,
			"is_current": is_here,
			"can_travel": (not is_here and is_settled)
		})

	return list

static func _calc_route_days(world: WorldState, from_id: StringName, to_id: StringName) -> int:
	for c_id in world.caravans:
		var c: CaravanState = world.caravans[c_id]
		if (c.origin_id == from_id and c.destination_id == to_id) or (c.origin_id == to_id and c.destination_id == from_id):
			return c.route_days
	return 3 # Default fallback

static func _project_recent_events(world: WorldState, max_count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_events := world.event_log.size()
	var start_idx := maxi(0, total_events - max_count)

	for i in range(total_events - 1, start_idx - 1, -1):
		var evt: EventRecord = world.event_log[i]
		result.append({
			"day": evt.day,
			"type": evt.type,
			"summary": _format_event_summary(evt)
		})
	return result

static func _format_event_summary(evt: EventRecord) -> String:
	match evt.type:
		"PLAYER_MATERIALIZED":
			return "Player '%s' materialized at %s" % [
				evt.payload.get("name", "Drifter"),
				String(evt.target_id).replace("settlement:", "")
			]
		"PLAYER_TRAVEL_STARTED":
			return "Player departed towards %s (ETA %d days)" % [
				String(evt.target_id).replace("settlement:", ""),
				evt.payload.get("route_days", 3)
			]
		"CARAVAN_ARRIVED":
			return "Caravan arrived at %s" % String(evt.target_id).replace("settlement:", "")
		"CARAVAN_LOADED":
			return "Caravan departed %s for %s" % [
				String(evt.target_id).replace("settlement:", ""),
				evt.payload.get("destination", "").replace("settlement:", "")
			]
		"REFUGEE_ARRIVED":
			return "%d refugees arrived at %s" % [
				evt.payload.get("headcount", 1),
				String(evt.target_id).replace("settlement:", "")
			]
		"REFUGEE_DEPARTED":
			return "%d refugees fled towards %s" % [
				evt.payload.get("headcount", 1),
				String(evt.target_id).replace("settlement:", "")
			]
		"MORTALITY_EVENT":
			return "%d deaths recorded at %s" % [
				evt.payload.get("deaths", 0),
				String(evt.target_id).replace("settlement:", "")
			]
		_:
			return "%s at %s" % [evt.type, String(evt.target_id).replace("settlement:", "")]
