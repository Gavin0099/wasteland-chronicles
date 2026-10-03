extends RefCounted

const Gear = preload("res://simulation/gear_rules.gd")
const Properties = preload("res://game_data/gear_property_profiles.gd")
const EQUIPMENT := "old_well_pump"
const PLACE := "place:old_well"
const SCRAP_COST := 3
const WATER_BONUS := 1
const METHODS := {"REPAIR_PUMP": ["MECHANICS", 2, 1], "OVERHAUL_PUMP": ["MECHANICS", 3, 2], "REWIRE_PUMP": ["ELECTRONICS", 2, 1], "ENGINEER_OVERHAUL": ["MECHANICS", 2, 2]}

static func state(world) -> Dictionary:
	var out: Dictionary = {"status": "BROKEN", "owner": "", "quest_id": ""}
	for event in world.event_log:
		if event.type == "PLACE_REPORTED" and event.payload.get("place_id") == PLACE:
			out.owner = String(event.payload.get("settlement_id", ""))
		if event.type == "EQUIPMENT_REPAIRED" and event.payload.get("equipment_id") == EQUIPMENT:
			out.status = "WORKING"
			out["bonus"] = int(event.payload.production_after) - int(event.payload.production_before)
			out.quest_id = String(event.payload.get("quest_id", ""))
	return out

static func is_contract(definition: Dictionary) -> bool:
	var objectives: Array = definition.get("objectives", [])
	return objectives.size() == 1 and objectives[0].get("type") == "REPAIR_EQUIPMENT" and objectives[0].get("equipment_id") == EQUIPMENT

static func active_job(world) -> String:
	var ids: Array = world.accepted_jobs.keys()
	ids.sort()
	for id: String in ids:
		var quest = world.quest_state.get_quest(id)
		if is_contract(world.accepted_jobs[id]) and quest != null and quest.status == &"ACTIVE" and world.current_day <= quest.deadline_day:
			return id
	return ""

static func posting(world, town, window: int) -> Dictionary:
	var equipment: Dictionary = state(world)
	if equipment.owner != String(town.id) or equipment.status != "BROKEN" or active_job(world) != "":
		return {}
	var short_id: String = String(town.id).trim_prefix("settlement:")
	# The two-day procedure needs one additional day for the same return trip.
	var engineer_ready: bool = world.player != null and world.player.item_inventory.contains("engineer_precision_tools")
	var deadline_days: int = 9 if engineer_ready else 8
	return {"definition": {
		"id": "job_%s_repair_pump_%d" % [short_id, window],
		"title_zh": "現地修復：枯河井抽水泵",
		"description_zh": "%s已接手枯河舊水井，但抽水泵仍故障。帶扳手和 3 廢料，沿灰谷—乾井公路回井邊修理；需機械 2、耗時 1 天。工具保留，廢料消耗，普通修理後本鎮每日多產 1 水。帶精密修理組、機械 3 可精修多產 2 水；電子 2 與電子修理組也能重接線路多產 1 水。工程師工具另可用機械2、廢料3與2天精修+2；攜帶該工具接單時期限9天。期限內回本鎮領酬；逾期不付酬，已修好的泵仍運轉。" % town.name,
		"settlement_id": short_id, "issuer_npc_id": "",
		"availability": {"required_day": 0, "required_flags": []}, "deadline_days": deadline_days,
		"objectives": [{"id": "repair_pump", "type": "REPAIR_EQUIPMENT", "equipment_id": EQUIPMENT, "quantity": 1}],
		"outcomes": {"resolved": {"rewards": [{"type": "CURRENCY", "amount": 80}, {"type": "XP", "amount": 12}], "world_effects": []}, "failed": {"rewards": [], "world_effects": []}, "expired": {"rewards": [], "world_effects": []}},
	}, "archetype": "REPAIR", "risk": 1, "route_days": 2, "urgent": false, "summary": "井泵故障 → 運轉，普通修理每日產水 +1；機械精修 +2"}

static func duration(method: String) -> int:
	return 2 if method == "ENGINEER_OVERHAUL" else 1

static func discount_tool(world, method: String) -> String:
	if method == "ENGINEER_OVERHAUL" or not METHODS.has(method) or METHODS[method][0] != "MECHANICS":
		return ""
	var id: String = Gear.best_tool(world.player, "MECHANICS")
	return id if Properties.has(id, "field_repair") else ""

static func material_cost(world, method: String) -> int:
	return 2 if discount_tool(world, method) != "" else SCRAP_COST

static func refusal(world, method: String = "REPAIR_PUMP") -> String:
	if not METHODS.has(method):
		return "INVALID_REPAIR_METHOD"
	var encounter = world.active_encounter
	if encounter == null or encounter.encounter_type != &"PLACE_VISIT" or encounter.context.get("place_id") != PLACE or encounter.context.get("repair_visit") != true:
		return "REPAIR_SITE_REQUIRED"
	var life = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	var party = world.get_refugee_party(life.population_container_id) if life != null else null
	if party == null or encounter.origin_id != party.origin_id or encounter.destination_id != party.destination_id or not ((String(party.origin_id) == "settlement:gray_valley" and String(party.destination_id) == "settlement:dry_well") or (String(party.origin_id) == "settlement:dry_well" and String(party.destination_id) == "settlement:gray_valley")):
		return "REPAIR_SITE_REQUIRED"
	var equipment: Dictionary = state(world)
	if equipment.status != "BROKEN":
		return "EQUIPMENT_ALREADY_REPAIRED"
	var job: String = active_job(world)
	if job == "" or equipment.owner != "settlement:" + String(world.accepted_jobs[job].settlement_id):
		return "REPAIR_CONTRACT_REQUIRED"
	if world.current_day + duration(method) > world.quest_state.get_quest(job).deadline_day:
		return "REPAIR_DEADLINE_TOO_CLOSE"
	if world.player.inventory.get_amount("scrap") < material_cost(world, method):
		return "INSUFFICIENT_SCRAP: pump repair needs %d scrap" % material_cost(world, method)
	return ""

static func apply(world, method: String = "REPAIR_PUMP") -> Dictionary:
	var bonus: int = int(METHODS[method][2])
	var cost: int = material_cost(world, method)
	var tool: String = "engineer_precision_tools" if method == "ENGINEER_OVERHAUL" else discount_tool(world, method)
	var equipment: Dictionary = state(world)
	var town = world.get_settlement(StringName(equipment.owner))
	var before: int = town.production.get_amount("water")
	world.player.inventory.add_amount("scrap", -cost)
	town.production.add_amount("water", bonus)
	var receipt: Dictionary = {"equipment_id": EQUIPMENT, "place_id": PLACE, "quest_id": active_job(world), "settlement_id": equipment.owner, "from_state": "BROKEN", "to_state": "WORKING", "resource": "water", "production_before": before, "production_after": before + bonus, "scrap_spent": cost}
	if method != "REPAIR_PUMP" or tool != "":
		receipt["method"] = method
	if tool != "":
		receipt["tool_id"] = tool
	world.record_event(EventRecord.new(world.current_day, "EQUIPMENT_REPAIRED", world.player.npc_id, StringName(equipment.owner), receipt))
	return receipt

static func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= 0

static func validate(world) -> String:
	var owner: String = ""
	var accepted: Dictionary = {}
	var repaired: Dictionary = {}
	var repaired_day: int = -1
	var resolution_seen: bool = false
	for event in world.event_log:
		var p: Dictionary = event.payload
		if event.type == "PLACE_REPORTED" and p.get("place_id") == PLACE:
			owner = String(p.get("settlement_id", ""))
		if event.type == "QUEST_ACCEPTED" and world.player != null and event.actor_id == world.player.npc_id:
			accepted[String(p.get("quest_id", ""))] = true
		if event.type == "EQUIPMENT_REPAIRED":
			var method: Variant = p.get("method", "REPAIR_PUMP")
			var proven_tool: bool = p.has("tool_id")
			var discounted: bool = proven_tool and p.get("tool_id") == "fieldrepair_precision_kit"
			if typeof(method) != TYPE_STRING or not METHODS.has(method) or (p.has("method") and method == "REPAIR_PUMP" and not proven_tool):
				return "REPAIR_LEDGER_INVALID_METHOD"
			if method == "ENGINEER_OVERHAUL" and p.get("tool_id") != "engineer_precision_tools":
				return "REPAIR_LEDGER_INVALID_TOOL"
			if proven_tool and (not p.has("method") or typeof(p.tool_id) != TYPE_STRING or (p.tool_id != "engineer_precision_tools" if method == "ENGINEER_OVERHAUL" else not Properties.has(p.tool_id, "field_repair")) or METHODS[method][0] != "MECHANICS" or Gear.grade_for(p.tool_id, "MECHANICS") < int(Gear.METHOD_TOOLS[method][1])):
				return "REPAIR_LEDGER_INVALID_TOOL"
			if not repaired.is_empty() or world.player == null or event.actor_id != world.player.npc_id or p.size() != (12 if proven_tool else (10 if method == "REPAIR_PUMP" else 11)) or p.get("equipment_id") != EQUIPMENT or p.get("place_id") != PLACE or p.get("settlement_id") != owner or String(event.target_id) != owner or p.get("from_state") != "BROKEN" or p.get("to_state") != "WORKING" or p.get("resource") != "water":
				return "REPAIR_LEDGER_INVALID_EQUIPMENT"
			if not _integer(p.get("production_before")) or not _integer(p.get("production_after")) or not _integer(p.get("scrap_spent")) or p.production_after != p.production_before + int(METHODS[method][2]) or p.scrap_spent != (2 if discounted else SCRAP_COST):
				return "REPAIR_LEDGER_INVALID_EFFECT"
			var job: Variant = p.get("quest_id")
			if typeof(job) != TYPE_STRING or not accepted.has(job) or not world.accepted_jobs.has(job) or not is_contract(world.accepted_jobs[job]) or owner != "settlement:" + String(world.accepted_jobs[job].settlement_id):
				return "REPAIR_LEDGER_INVALID_CONTRACT"
			var quest = world.quest_state.get_quest(job)
			if quest == null or event.day < quest.accepted_day or event.day + duration(method) > quest.deadline_day:
				return "REPAIR_LEDGER_INVALID_DAY"
			var town = world.get_settlement(StringName(owner))
			if town == null or town.production.get_amount("water") < int(p.production_after):
				return "REPAIR_LEDGER_PRODUCTION_MISMATCH"
			repaired = p
			repaired_day = event.day
		if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and p.get("option") in METHODS:
			if resolution_seen or repaired.is_empty() or p.option != repaired.get("method", "REPAIR_PUMP") or p.get("equipment_repair") != repaired or p.get("place_id") != PLACE or p.get("encounter_type") != "PLACE_VISIT" or p.get("elapsed_days") != duration(String(repaired.get("method", "REPAIR_PUMP"))) or typeof(p.get("spent")) != TYPE_DICTIONARY or p.spent.get("scrap") != int(repaired.scrap_spent) or event.day != repaired_day + duration(String(repaired.get("method", "REPAIR_PUMP"))) or event.actor_id != world.player.npc_id:
				return "REPAIR_LEDGER_INVALID_RESOLUTION"
			resolution_seen = true
	return ""
