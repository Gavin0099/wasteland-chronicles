class_name PlayerUIProjection
extends RefCounted

const ItemMarketCatalogue = preload("res://simulation/item_market_catalogue.gd")
const ItemMarketState = preload("res://simulation/item_market_state.gd")
const QuestRegistry = preload("res://simulation/quest_registry.gd")
const QuestEngine = preload("res://simulation/quest_engine.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
const TravelRoute = preload("res://simulation/travel_route.gd")

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
		"debug_feed_enabled": debug_feed_enabled,
		"active_encounter": _project_encounter(world),
		"encounter_result": _project_encounter_result(world),
		"death": _project_death(world),
		"growth": _project_growth(world),
		"quests": _project_quests(world),
	}
	return proj

const JobBoard = preload("res://simulation/job_board.gd")
const Growth = preload("res://simulation/growth_points.gd")

# PLAY-2 follow-up: a level has to announce itself. Before this the only place
# that said "you levelled" was the character sheet, so a player who did not
# think to open it never found out they had something to spend.
static func _project_growth(world: WorldState) -> Dictionary:
	if world.player == null:
		return {}
	var points := Growth.available(world)
	if points <= 0:
		return {}
	return {"points": points, "openings": Growth.openings(world)}
const RESOURCE_LABELS := {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}

static func _project_quests(world: WorldState) -> Array:
	var rows: Array = []
	if world.player == null:
		return rows
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or not life.is_alive():
		return rows
	# FUN-1: the board is part of the same list. Authored content first, then
	# contracts already taken (their committed copy, never today's board), then
	# whatever this settlement is posting right now.
	var sources: Array = []
	for authored in QuestRegistry.all_definitions():
		sources.append({"definition": authored, "extras": {}})
	for job_id in world.accepted_jobs:
		sources.append({"definition": world.accepted_jobs[job_id], "extras": {}})
	if life.status == NpcLifeState.Status.SETTLED:
		for entry in JobBoard.postings(world, life.population_container_id):
			if world.accepted_jobs.has(String(entry.definition.id)):
				continue
			sources.append({"definition": entry.definition, "extras": entry})

	for source in sources:
		var definition: Dictionary = source.definition
		var extras: Dictionary = source.extras
		var quest_id := String(definition.id)
		var state = world.quest_state.get_quest(quest_id)
		var status := String(state.status) if state != null else String(QuestEngine.evaluate_availability(world, quest_id))
		var at_issuer := life.status == NpcLifeState.Status.SETTLED and String(life.population_container_id) == "settlement:" + String(definition.settlement_id)
		if state == null and not at_issuer:
			continue
		if state == null and status != "AVAILABLE" and not definition.availability.has("required_equipped_item_id"):
			continue
		var objective: Dictionary = definition.objectives[0]
		var is_survey: bool = definition.objectives.any(func(obj: Dictionary) -> bool: return String(obj.type) == "VISIT_LOCATION")
		var objective_type := String(objective.get("type", ""))
		var item_id := String(objective.get("item_id", ""))
		var item_result: Dictionary = ItemRegistry.resolve(item_id) if item_id != "" else {"success": false}
		var item_name := String(item_result.definition.display_name_zh) if item_result.success else "物品"
		var target := _settlement_name("settlement:" + String(objective.get("settlement_id", definition.settlement_id)))
		var required := int(objective.get("quantity", 0))
		var held: int = world.player.item_inventory.quantity(item_id) if item_id != "" else 0
		# FUN-1 objectives count different things, so the progress line has to
		# read the right one rather than reporting "0 / 5 物品" for water.
		if objective_type == "DELIVER_RESOURCE":
			var resource := String(objective.get("resource", ""))
			item_name = RESOURCE_LABELS.get(resource, resource)
			held = int(world.player.inventory.get_amount(resource)) if world.player.inventory != null else 0
		elif objective_type == "WIN_ROAD_COMBAT":
			item_name = "擊退劫匪"
			target = _settlement_name("settlement:" + String(objective.get("destination_id", "")))
			held = 1 if QuestEngine.evaluate_objectives(world, quest_id) else 0
		var action := PlayerIntent.create_accept_quest(world.player.npc_id, quest_id) if status == "AVAILABLE" else PlayerIntent.create_turn_in_quest(world.player.npc_id, quest_id)
		var can_act := status in ["AVAILABLE", "ACTIVE"] and SimulationEngine.new().authorize_player_intent(world, action) == ""
		var reward_caps := 0
		var reward_xp := 0
		for reward in definition.outcomes.resolved.rewards:
			if String(reward.type) == "CURRENCY":
				reward_caps += int(reward.amount)
			elif String(reward.type) == "XP":
				reward_xp += int(reward.amount)
		rows.append({
			"id": quest_id, "title": String(definition.title_zh), "description": String(definition.description_zh),
			"status": status, "deadline_day": state.deadline_day if state != null else -1,
			"deadline_days": int(definition.deadline_days), "target": target, "item_name": item_name,
			"required": required, "held": held, "can_act": can_act,
			"is_survey": is_survey,
			"required_equipped_item": String(definition.availability.get("required_equipped_item_id", "")),
			"reward_caps": reward_caps, "reward_xp": reward_xp,
			"objective_type": objective_type,
			"archetype": String(extras.get("archetype", "")),
			"risk": int(extras.get("risk", 0)),
			"risk_stars": JobBoard.RISK_STARS.get(int(extras.get("risk", 0)), ""),
			"route_days": int(extras.get("route_days", 0)),
			"urgent": bool(extras.get("urgent", false)),
			"target_site": String(extras.get("target_site", definition.get("target_site", ""))),
			"intel": JobBoard.intel_for(world, extras) if not extras.is_empty() else [],
		})
	# Hand-play: "任務結束應該直接不見 而不是還在那邊". Finished work used to
	# stay in the list for ever, so the board silently turned into a graveyard
	# and fresh work was buried under contracts already settled.
	#
	# Generated jobs leave entirely once terminal: they are routine hauling, and
	# their record lives in the event log where history belongs. Authored
	# commissions keep their completion line - QUEST-UI added that deliberately
	# after an earlier playtest - but sort to the bottom so they can never push
	# an available job out of sight.
	var live: Array = []
	var finished: Array = []
	for row in rows:
		var terminal: bool = String(row.status) in ["RESOLVED", "EXPIRED", "FAILED"]
		if not terminal:
			live.append(row)
		elif not String(row.id).begins_with("job_"):
			finished.append(row)
	return live + finished

# The end of a run is a world fact, not a side effect of a panel. The engine
# already refuses every intent from a dead player; until this existed the UI had
# no way to say so, so the buttons stayed lit and the game looked frozen.
#
# Read from the PLAYER_DIED receipt rather than recomputed, so the screen can
# never disagree with the event log about how the run ended.
static func _project_death(world: WorldState) -> Dictionary:
	if world.player == null:
		return {}
	var ls := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if ls == null or ls.is_alive():
		return {}
	for i in range(world.event_log.size() - 1, -1, -1):
		var evt: EventRecord = world.event_log[i]
		if evt.type != "PLAYER_DIED" or evt.actor_id != world.player.npc_id:
			continue
		return {
			"cause": String(evt.payload.get("cause", "")),
			"day": evt.day,
			"days_survived": int(evt.payload.get("days_survived", evt.day)),
			"in_transit": bool(evt.payload.get("in_transit", false)),
			"place": _settlement_name(String(evt.target_id)),
		}
	# Dead with no receipt should be impossible, but the screen must still stop
	# the player rather than silently accept input.
	return {"cause": "", "day": world.current_day, "days_survived": world.current_day,
		"in_transit": false, "place": ""}

static func _project_encounter_result(world: WorldState) -> Dictionary:
	if world.pending_encounter_result < 0:
		return {}
	var evt := world.event_log[world.pending_encounter_result]
	var result := evt.payload.duplicate(true)
	result["result_index"] = world.pending_encounter_result
	result["title"] = TravelEncounter.title(StringName(result.encounter_type), result)
	result["route_label"] = "%s → %s" % [_settlement_name(result.origin), _settlement_name(result.destination)]
	var ls := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	result["can_continue"] = ls != null and ls.is_alive() and ls.status == NpcLifeState.Status.IN_TRANSIT
	result["is_dead"] = ls != null and not ls.is_alive()
	return result

# S5-B4: what the road is currently asking. Options carry an `enabled` flag so
# the UI can grey out a choice the player cannot afford, using the SAME check
# the engine will apply when it authorizes the intent.
static func _project_encounter(world: WorldState) -> Dictionary:
	var enc := world.active_encounter
	if enc == null:
		return {}

	var options: Array = []
	var engine := SimulationEngine.new()
	for o in TravelEncounter.options(enc.encounter_type, enc.context):
		var option_id: StringName = o["id"]
		var reason := engine.authorize_encounter_option(world, option_id)
		if reason.begins_with("PERK_NOT_OWNED") or reason.begins_with("ACQUIRED_TRAIT_NOT_OWNED"):
			continue
		# S5-C2: an approach this character cannot take is either hidden or shown
		# locked, depending on WHY. A knowledge gate is hidden, because the
		# character has no idea the option exists. A capability gate is shown
		# and disabled with its requirement, because seeing the locked door is
		# the only way the player ever learns which skill is worth raising -
		# and coming back later to find it open is the point of the whole
		# progression. Running out of caps is a third thing entirely: a
		# temporary shortage, disabled as it always was.
		var gated: bool = reason.begins_with("CAPABILITY_")
		if gated and TravelEncounter.option_gate(enc.encounter_type, option_id) != TravelEncounter.GATE_CAPABILITY:
			continue
		options.append({
			"id": String(option_id),
			"label": o["label"],
			"detail": o["detail"],
			"requirement_label": String(o.get("requirement_label", "")),
			"locked": gated,
			"enabled": reason == "",
			"blocked_reason": reason,
		})

	var search_preview := {}
	if enc.encounter_type == TravelEncounter.WRECK and world.player.has_acquired_trait("SCAVENGER_INSTINCT"):
		search_preview = {
			"goods": TravelEncounter.wreck_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, String(enc.context.get("source_wreck_id", ""))),
			"items": TravelEncounter.wreck_item_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, &"SEARCH", String(enc.context.get("route_type", "")), String(enc.context.get("source_wreck_id", ""))),
		}
	# KNOWN_HELPER: the same read-only shape as the wreck preview, over the
	# existing deterministic yield functions. Someone who has really given their
	# own water away twice can tell what the person in front of them still has
	# to offer. It changes nothing about the outcome - the ration is still paid
	# and the yield is still whatever the road already decided.
	var help_preview := {}
	if world.player.has_acquired_trait("KNOWN_HELPER"):
		if enc.encounter_type == TravelEncounter.DEHYDRATED_TRAVELLER:
			help_preview = {
				"option": "GIVE_WATER",
				"goods": TravelEncounter.traveller_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index),
			}
		elif enc.encounter_type == TravelEncounter.REFUGEE_COLUMN:
			help_preview = {
				"option": "SHARE_FOOD",
				"goods": TravelEncounter.refugee_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index),
			}

	# DEATH_TESTED: the arithmetic of the fight in front of you, before you
	# commit to it. Read-only, and it moves no combat number whatsoever.
	var risk_preview := {}
	if enc.encounter_type == TravelEncounter.BANDIT_AMBUSH and world.player.has_acquired_trait("DEATH_TESTED"):
		risk_preview = WorldState.Field.forecast(world, true)

	return {
		"encounter_type": String(enc.encounter_type),
		"title": TravelEncounter.title(enc.encounter_type, enc.context),
		"body": TravelEncounter.body(enc.encounter_type, enc.context),
		"day": enc.day,
		"route_label": "%s → %s" % [
			_settlement_name(String(enc.origin_id)), _settlement_name(String(enc.destination_id))
		],
		"options": options,
		"search_preview": search_preview,
		"help_preview": help_preview,
		"risk_preview": risk_preview,
	}

static func _project_player(world: WorldState) -> Dictionary:
	if world.player == null:
		return {
			"has_player": false,
			"is_alive": true,
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

	var origin_id := ""
	var destination_id := ""
	var total_route_days := 0
	if is_in_transit and ls != null:
		var p_party: RefugeePartyState = world.get_refugee_party(ls.population_container_id)
		if p_party != null:
			origin_id = String(p_party.origin_id)
			destination_id = String(p_party.destination_id)
			total_route_days = p_party.route_days
	var item_entries: Array = []
	if p.item_inventory != null:
		item_entries = p.item_inventory.to_dict().get("items", [])
	var equipment_data: Dictionary = {"slots": []}
	if p.equipment != null:
		equipment_data = p.equipment.to_dict()

	return {
		"has_player": true,
		"npc_id": String(p.npc_id),
		"name": p_name,
		"money": p.money,
		"health": p.field_kit.hp if p.field_kit != null else 12,
		"status": status_str,
		"is_in_transit": is_in_transit,
		"location_display": location_display,
		"current_container_id": String(ls.population_container_id) if ls != null else "",
		"origin_id": origin_id,
		"destination_id": destination_id,
		"days_remaining": days_left,
		"total_route_days": total_route_days,
		"backpack": {
			"water": p.inventory.water if p.inventory != null else 0,
			"food": p.inventory.food if p.inventory != null else 0,
			"scrap": p.inventory.scrap if p.inventory != null else 0,
			"fuel": p.inventory.fuel if p.inventory != null else 0,
			"load": bp_load,
			"capacity": p.get_effective_capacity()
		},
		"items": item_entries,
		"equipment": equipment_data,
		"water_pressure": p.water_pressure,
		"food_pressure": p.food_pressure,
		"is_alive": ls == null or ls.is_alive(),
		"water_exposure": p.water_exposure,
		"food_exposure": p.food_exposure
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
	var market_view: RefCounted = s.item_market if s.item_market != null else ItemMarketState.seeded_for(s.id)
	var item_market_result := ItemMarketCatalogue.offers_for(s.id)
	var item_offers: Array[Dictionary] = []
	if item_market_result.success:
		for offer in item_market_result.offers:
			var item_id := String(offer.item_id)
			var owned: int = world.player.item_inventory.quantity(item_id)
			var sell_quote: int = ItemMarketState.sell_quote(item_id, s.id)
			item_offers.append({
				"item_id": item_id,
				"display_name_zh": offer.display_name_zh,
				"category": offer.category,
				"asset_id": offer.asset_id,
				"supply": offer.supply,
				"demand": offer.demand,
				"stock": market_view.quantity(item_id),
				"owned": owned,
				"quote_buy": ItemMarketState.buy_quote(item_id, s.id, market_view),
				"quote_sell": sell_quote,
				"can_buy": market_view.quantity(item_id) > 0 and world.player.money >= ItemMarketState.buy_quote(item_id, s.id, market_view),
				"can_sell": owned > 0 and sell_quote > 0 and s.market_cash >= sell_quote,
			})

	# LIVE authoritative data for player's current location only
	return {
		"id": String(s.id),
		"name": s.name,
		"population": s.population,
		"market_cash": s.market_cash,
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
		"quote_buy_water": SimulationEngine.get_buy_quote(s, &"water"),
		"quote_sell_water": SimulationEngine.get_sell_quote(s, &"water"),
		"quote_buy_food": SimulationEngine.get_buy_quote(s, &"food"),
		"quote_sell_food": SimulationEngine.get_sell_quote(s, &"food"),
		"quote_buy_scrap": SimulationEngine.get_buy_quote(s, &"scrap"),
		"quote_sell_scrap": SimulationEngine.get_sell_quote(s, &"scrap"),
		"quote_buy_fuel": SimulationEngine.get_buy_quote(s, &"fuel"),
		"quote_sell_fuel": SimulationEngine.get_sell_quote(s, &"fuel"),
		"item_market": item_offers,
		"water_supply_status": _get_stock_status(s.inventory.water, s.target_water),
		"food_supply_status": _get_stock_status(s.inventory.food, s.target_food),
		"scrap_supply_status": _get_stock_status(s.inventory.scrap, s.target_scrap),
		"fuel_supply_status": _get_stock_status(s.inventory.fuel, s.target_fuel),
		"water_pressure_status": _get_pressure_status(s.water_pressure),
		"food_pressure_status": _get_pressure_status(s.food_pressure),
		"is_live": true
	}

static func _get_stock_status(current_stock: int, target_stock: int) -> String:
	if target_stock <= 0:
		return "STABLE"
	var ratio := float(current_stock) / float(target_stock)
	if ratio <= 0.25:
		return "CRITICAL"
	elif ratio <= 0.60:
		return "LOW"
	return "STABLE"

static func _get_pressure_status(pressure: float) -> String:
	if pressure >= 90.0:
		return "EXTREME"
	elif pressure >= 60.0:
		return "HIGH_RISK"
	elif pressure >= 30.0:
		return "ELEVATED"
	return "NORMAL"

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

		var routes: Array[Dictionary] = []
		if not is_here and is_settled:
			routes = TravelRoute.get_available_routes(current_loc, StringName(s_id))

		# Remote settlement projection: ONLY name, route availability, distance.
		# Strictly NO economic leaks (no specialization, no stock, no prices).
		list.append({
			"id": String(s.id),
			"name": s.name,
			"route_days": route_days,
			"routes": routes,
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
		var narrated := _narrate_event(evt)
		if narrated.is_empty():
			continue
		result.append({
			"day": evt.day,
			"text": narrated["text"],
			"category": narrated["category"],
		})
	return result

# ==============================================================================
# EVENT FEED NARRATION
# ==============================================================================
# The feed is the radio, not a log viewer. Every line is finished prose in the
# player's language, and NO internal identifier (settlement:gray_valley,
# CARAVAN_LOADED, npc:00000001) may ever reach the screen. Unknown event types
# are dropped rather than printed raw, because a leaked type name breaks the
# fiction harder than a missing line does.
#
# This stays a deterministic formatter: same event, same sentence, every time.
# No LLM involved.
static func _settlement_name(raw_id: String) -> String:
	match raw_id:
		"settlement:gray_valley": return "灰谷"
		"settlement:dry_well": return "乾井"
		"settlement:new_hope": return "新希望"
	if raw_id.begins_with("settlement:"):
		return raw_id.replace("settlement:", "").replace("_", " ").capitalize()
	if raw_id.begins_with("refugee:"):
		return "路上"
	return raw_id

# Returns {"text": String, "category": String} or an empty dict to omit.
static func _narrate_event(evt: EventRecord) -> Dictionary:
	var here := _settlement_name(String(evt.target_id))
	var actor_place := _settlement_name(String(evt.actor_id))
	var payload: Dictionary = evt.payload

	match evt.type:
		"PLAYER_MATERIALIZED":
			return {"text": "你在%s落腳，廢土旅程就此開始。" % here, "category": "player"}
		"PLAYER_TRAVEL_STARTED":
			return {"text": "你動身前往%s，路程約 %d 天。" % [here, int(payload.get("route_days", 3))], "category": "player"}
		"PLAYER_WAIT":
			if not String(evt.target_id).begins_with("settlement:"):
				return {"text": "你在路上又走了一天。", "category": "player"}
			return {"text": "你在%s歇了一天。" % here, "category": "player"}
		"TRADE_COMPLETED":
			var goods := _commodity_name(String(payload.get("commodity", "")))
			var qty := int(payload.get("quantity", 0))
			var caps := int(payload.get("total_amount", 0))
			if String(payload.get("action", "")).to_upper() == "BUY":
				return {"text": "你在%s買下 %d 份%s，付了 %d 瓶蓋。" % [here, qty, goods, caps], "category": "trade"}
			return {"text": "你在%s賣出 %d 份%s，進帳 %d 瓶蓋。" % [here, qty, goods, caps], "category": "trade"}

		"CARAVAN_LOADED":
			var dest := _settlement_name(String(payload.get("destination", "")))
			return {"text": "一支商隊在%s裝載完畢，啟程前往%s。" % [here, dest], "category": "caravan"}
		"CARAVAN_ARRIVED":
			return {"text": "商隊抵達%s，物資卸入倉庫。" % here, "category": "caravan"}
		"CARAVAN_DESTROYED":
			return {"text": "前往%s的商隊在路上失聯了。" % here, "category": "danger"}
		"CARAVAN_RESTORED":
			return {"text": "往返%s的商路重新通行。" % here, "category": "caravan"}
		"TRANSIT_PREDATION":
			return {"text": "通往%s的路上遭到劫掠，部分貨物不見了。" % here, "category": "danger"}

		"REFUGEES_DEPARTED":
			var from_place := _settlement_name(String(payload.get("origin", "")))
			return {"text": "%d 人受不了%s的日子，收拾行囊離開。" % [int(payload.get("headcount", 1)), from_place], "category": "people"}
		"REFUGEES_ARRIVED":
			return {"text": "%d 名難民抵達%s，暫時有了落腳處。" % [int(payload.get("headcount", 1)), here], "category": "people"}
		"SETTLEMENT_MORTALITY":
			return {"text": "%s傳來死訊，%d 人沒能撐過來。" % [here, int(payload.get("deaths", 0))], "category": "danger"}
		"DISORDER_LOSS":
			return {"text": "%s治安敗壞，倉庫裡的東西正在流失。" % here, "category": "danger"}

		"NAMED_NPC_MIGRATION_STARTED":
			return {"text": "%s決定離開%s，動身前往%s。" % [
				_person_name(payload), actor_place, here], "category": "person"}
		"NAMED_MIGRATION_COMPLETED":
			return {"text": "%s平安抵達%s。" % [_person_name(payload), here], "category": "person"}
		"NAMED_NPC_DIED":
			return {"text": "%s死在了%s。" % [_person_name(payload), here], "category": "danger"}

	# Unknown type: stay silent rather than leak an internal name.
	return {}

static func _person_name(payload: Dictionary) -> String:
	var n := String(payload.get("name", ""))
	return n if n != "" else "一名居民"

static func _commodity_name(key: String) -> String:
	match key:
		"water": return "水"
		"food": return "食物"
		"scrap": return "廢料"
		"fuel": return "燃料"
	return key
