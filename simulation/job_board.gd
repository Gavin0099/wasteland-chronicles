class_name JobBoard
extends RefCounted

# ==============================================================================
# FUN-1: THE WASTELAND JOB LOOP — the board a survivor actually reads
# ==============================================================================
# Every job in the game used to be authored: three of them, each completable
# once. Finish them and there was nothing left to want. The XP economy said the
# same thing in numbers - five awards, 115 XP, all one-time - so a player's
# fifth week looked exactly like their first.
#
# This makes work the thing you always have. Three livelihoods, each asking a
# DIFFERENT question of the player:
#
#   COURIER  — a routing and supply question. This pays well, but how long is
#              the road, how rough is it, and am I carrying enough to survive
#              it on top of the cargo?
#   SALVAGE  — an exploration and gambling question. I can buy the part and
#              hand it in for a thin margin, or go out and dig for it and keep
#              whatever else I find.
#   BOUNTY   — a combat-readiness question. The pay is the best on the board
#              because somebody has to fight for it. Am I in shape for that
#              right now, or do I take the safe run and come back?
#
# WHY WORLD STATE MODULATES RATHER THAN GATES:
#   The first cut made a bounty conditional on collapsed security. Measurement
#   killed that design: across 180 simulated days a healthy world never dropped
#   below 98.3 security and produced zero predation, zero caravan losses and
#   zero refugees. A world that never degrades would have posted a bounty never.
#
#   A standing job is not a crisis. Towns always need hauling, workshops always
#   need parts, and caravans always report somebody working the road. So the
#   BASELINE is unconditional, and real world facts make the work heavier,
#   better paid and more dangerous rather than making it exist at all. When the
#   world does finally go bad, the board gets worse with it.
#
#   That separation is also why nothing here fakes a shortage to manufacture
#   content: a shortage in a description is always read from the settlement.
#
# NO RNG ANYWHERE. A board is a pure function of world facts plus the posting
# window, so replay stays exact for free.
#
# WHAT THIS SLICE STILL DOES NOT DO:
#   Handing five water to a thirsty town does not put five water in that town.
#   The job pays because the shortage is real; the world's response to player
#   action is QUEST-W1 and is not smuggled in here.
# ==============================================================================

const Definition = preload("res://simulation/quest_definition.gd")
const Route = preload("res://simulation/travel_route.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const FieldAdventure = preload("res://simulation/field_adventure.gd")
const RoadPlaces = preload("res://simulation/road_places.gd")
const LocalTrust = preload("res://simulation/local_trust.gd")

# The board turns over on a cadence rather than daily, so work the player walked
# past yesterday is usually still there when they come back for it.
const POSTING_WINDOW_DAYS := 3
# Quest ids are validated as stable identifiers - lowercase, digits and
# underscores only - so the namespace is a prefix, not a colon. The resolver
# checks authored content first, so a collision favours the authored quest
# rather than letting a generated one silently replace it.
const JOB_ID_PREFIX := "job_"

const COURIER_DEADLINE_DAYS := 7
# A stock this far below target is a shortfall the town posts as urgent. The
# delivery receipt uses the same line, so "you ended the shortage" means the
# next board really will stop calling it urgent.
const COURIER_URGENT_GAP := 10
# REP-1: consignment - the town hands you its own goods to carry.
const CONSIGN_DEADLINE_DAYS := 8
const SALVAGE_DEADLINE_DAYS := 8
const BOUNTY_DEADLINE_DAYS := 9
# The standing raider bounty (owner ruling 2026-09-27).
const STANDING_RAIDER_PREFIX := "new_hope_raider_standing_"
const STANDING_RAIDER_CAPS := 150
const STANDING_RAIDER_XP := 18

# One distinct, reachable creature hunt on each original town's board.
# Contracts reuse WIN_ROAD_COMBAT; no autonomous creatures or new entity lifecycle.
const HUNTS := {
	"new_hope": {"enemy": "feral_boar", "destination": "dry_well", "route": "WILDERNESS", "caps": 95, "xp": 10},
	"dry_well": {"enemy": "desert_scorpion", "destination": "gray_valley", "route": "HIGHWAY", "caps": 75, "xp": 8},
	"gray_valley": {"enemy": "ash_ghoul", "destination": "new_hope", "route": "HIGHWAY", "caps": 100, "xp": 12},
}

# Danger is a 1..3 rating, and it is the spine of the whole board: it sets the
# stars the player reads, the caps, and the experience. Easy work pays rent;
# only dangerous work teaches you anything.
const RISK_CALM := 1
const RISK_ROUGH := 2
const RISK_BAD := 3
const RISK_STARS := {1: "★☆☆", 2: "★★☆", 3: "★★★"}
const RISK_WORDS := {1: "平靜", 2: "不太平", 3: "危險"}

const RESOURCE_NAMES := {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}
const COURIER_RESOURCES := ["water", "food", "scrap", "fuel"]
const SALVAGE_ITEMS := ["wrench", "rope", "flashlight", "first_aid_kit", "rusted_knife"]
const SALVAGE_ITEM_NAMES := {"wrench": "扳手", "rope": "繩索", "flashlight": "手電筒", "first_aid_kit": "急救包", "rusted_knife": "生鏽小刀"}

# Same hand-written hash as the encounter catalogue, and for the same reason:
# engine-internal hashing is not guaranteed stable across engine versions, and
# the board must not quietly change on an upgrade.
static func stable_hash(text: String) -> int:
	var h := 2166136261
	for i in range(text.length()):
		h = (h ^ text.unicode_at(i)) * 16777619
		h = h & 0x7FFFFFFF
	return h

static func window_for_day(day: int) -> int:
	return int(floor(float(maxi(0, day)) / float(POSTING_WINDOW_DAYS)))

static func is_job_id(quest_id: String) -> bool:
	return quest_id.begins_with(JOB_ID_PREFIX)

static func _short(settlement_id: String) -> String:
	return settlement_id.replace("settlement:", "")

static func _name_of(world, settlement_id: StringName) -> String:
	var s = world.get_settlement(settlement_id)
	return s.name if s != null and s.name != "" else _short(String(settlement_id))

static func _sorted_settlement_ids(world) -> Array:
	var ids: Array = []
	for s in world.settlements.values():
		ids.append(String(s.id))
	ids.sort()
	return ids

# ── Danger ────────────────────────────────────────────────────────────────────

# How rough a road is right now. Security is the world's own figure, so a
# decaying world really does push every road toward the top of the scale.
static func road_risk(world, origin_id: StringName, destination_id: StringName, route_type: StringName) -> int:
	var origin = world.get_settlement(origin_id)
	var destination = world.get_settlement(destination_id)
	var security := 100.0
	if origin != null:
		security = minf(security, float(origin.security))
	if destination != null:
		security = minf(security, float(destination.security))
	var risk := RISK_CALM
	if security < 85.0:
		risk = RISK_ROUGH
	if security < 60.0:
		risk = RISK_BAD
	# The wilderness is harder than the highway whatever the towns say.
	if route_type == Route.ROUTE_WILDERNESS:
		risk = mini(RISK_BAD, risk + 1)
	return risk

# The neighbour whose road is worst, for the settlement to post work about.
# Deterministic: ties break on the sorted identifier.
static func _worst_neighbour(world, settlement_id: StringName) -> String:
	var worst := ""
	var worst_risk := -1
	var worst_security := 1000.0
	for other_id in _sorted_settlement_ids(world):
		if other_id == String(settlement_id):
			continue
		var other = world.get_settlement(StringName(other_id))
		if other == null:
			continue
		var risk := road_risk(world, settlement_id, StringName(other_id), Route.ROUTE_HIGHWAY)
		var security := float(other.security)
		if risk > worst_risk or (risk == worst_risk and security < worst_security):
			worst_risk = risk
			worst_security = security
			worst = other_id
	return worst

static func _route_days(world, origin_id: StringName, destination_id: StringName) -> int:
	var days := Route.get_route_days(origin_id, destination_id, Route.ROUTE_HIGHWAY)
	return days if days > 0 else 2

# ── Generation ────────────────────────────────────────────────────────────────

# Everything this settlement is posting today, richest first. Each entry is
# {definition, risk, route_days, summary}: the definition is the contract and
# nothing else, so presentation can never drift into a committed contract.
static func postings(world, settlement_id: StringName) -> Array:
	var settlement = world.get_settlement(settlement_id)
	if settlement == null:
		return []
	var window := window_for_day(world.current_day)
	var built: Array = [
		_courier(world, settlement, window),
		_salvage(world, settlement, window),
		_bounty(world, settlement, window),
		_hunt(world, settlement, window),
		_consignment(world, settlement, window),
		preload("res://simulation/well_repair.gd").posting(world, settlement, window),
	]
	built.append_array(_item_requests(world, settlement, window))
	if _short(String(settlement_id)) == "new_hope":
		built.append(_standing_raider(world, settlement, window))
	var out: Array = []
	for entry in built:
		if entry.is_empty():
			continue
		# A generator that emits an invalid definition is a bug in this file.
		# Surfacing it as a missing job would hide it, so carry the error and
		# let the tests fail loudly on it instead.
		var error := Definition.validate_definition(entry.definition)
		if error != "":
			push_error("JobBoard generated an invalid posting: %s (%s)" % [String(entry.definition.get("id", "?")), error])
			continue
		# REP-1: a town that knows you pays you better for its own work.
		_scale_pay(entry, LocalTrust.reward_multiplier(world, String(settlement_id)))
		out.append(entry)
	return out

static func _scale_pay(entry: Dictionary, multiplier: float) -> void:
	if is_equal_approx(multiplier, 1.0):
		return
	for reward in entry.definition.outcomes.resolved.rewards:
		if String(reward.type) == "CURRENCY":
			reward.amount = int(round(float(reward.amount) * multiplier))

# Every posting on every board today.
static func all_postings(world) -> Array:
	var out: Array = []
	for settlement_id in _sorted_settlement_ids(world):
		for entry in postings(world, StringName(settlement_id)):
			out.append(entry)
	return out

# ECON-1: shortages are world facts, independent of quest acceptance.
static func wanted_items(world, settlement_id: StringName) -> Dictionary:
	var town = world.get_settlement(settlement_id)
	var out: Dictionary = {}
	if town == null:
		return out
	var market: RefCounted = town.item_market if town.item_market != null else ItemMarketState.seeded_for(settlement_id)
	# One unit is the minimum stock for the existing recoverable workshop tools.
	# Queries never materialize a market or change its stock.
	for item_id: String in SALVAGE_ITEMS:
		var profile: Dictionary = ItemMarketCatalogue.profile_for(item_id, settlement_id)
		if profile.success and String(profile.demand) != "none" and market.quantity(item_id) == 0:
			out[item_id] = true
	return out

static func _item_requests(world, settlement, window: int) -> Array:
	var out: Array = []
	var ids: Array = wanted_items(world, settlement.id).keys()
	ids.sort()
	for item_id: String in ids:
		var definition: Dictionary = ItemRegistry.resolve(item_id).definition
		var short_id: String = _short(String(settlement.id))
		out.append({
			"definition": {
				"id": "%s%s_item_request_%s_%d" % [JOB_ID_PREFIX, short_id, item_id, window],
				"title_zh": "%s缺貨求購：%s" % [settlement.name, definition.display_name_zh],
				"description_zh": "%s的%s庫存為 0，需要補到 1 件。可到別鎮買現成品交件，或親自搜刮；交件會補入本鎮庫存。接單後按約付酬，不受後來補貨影響。" % [settlement.name, definition.display_name_zh],
				"settlement_id": short_id, "issuer_npc_id": "",
				"availability": {"required_day": 0, "required_flags": []},
				"deadline_days": SALVAGE_DEADLINE_DAYS,
				"objectives": [{"id": "restock_" + item_id, "type": "DELIVER_ITEM", "item_id": item_id, "quantity": 1, "settlement_id": short_id}],
				"outcomes": {
					"resolved": {"rewards": [{"type": "CURRENCY", "amount": int(definition.base_value) + 12}, {"type": "XP", "amount": 3}], "world_effects": []},
					"failed": {"rewards": [], "world_effects": []}, "expired": {"rewards": [], "world_effects": []},
				},
			},
			"archetype": "ITEM_REQUEST", "risk": RISK_CALM, "route_days": 0, "urgent": true,
			"summary": "補入一件%s（庫存 0 → 1）" % definition.display_name_zh,
		})
	return out

static func find_posting(world, quest_id: String) -> Dictionary:
	if not is_job_id(quest_id):
		return {}
	for entry in all_postings(world):
		if String(entry.definition.id) == quest_id:
			return entry.definition
	return {}

# ── Courier: a routing and supply question ────────────────────────────────────
static func _courier(world, settlement, window: int) -> Dictionary:
	var settlement_id: StringName = settlement.id
	var origin_id := _worst_neighbour(world, settlement_id)
	if origin_id == "":
		return {}

	# Which goods this town wants moved. A real shortfall names itself; with no
	# shortfall the town still restocks, and the choice rotates on the window
	# rather than pretending nothing is ever needed.
	var worst := ""
	var worst_gap := 0
	for resource in COURIER_RESOURCES:
		var gap: int = int(settlement.get_target(resource)) - int(settlement.inventory.get_amount(resource))
		if gap > worst_gap:
			worst_gap = gap
			worst = resource
	var urgent := worst_gap >= COURIER_URGENT_GAP
	if not urgent:
		worst = COURIER_RESOURCES[stable_hash("courier|%s|%d" % [String(settlement_id), window]) % COURIER_RESOURCES.size()]

	var quantity: int = clampi(2 + int(worst_gap / 12), 2, 6)
	var risk := road_risk(world, StringName(origin_id), settlement_id, Route.ROUTE_HIGHWAY)
	var days := _route_days(world, StringName(origin_id), settlement_id)
	var pressure: float = float(settlement.water_pressure if worst == "water" else (settlement.food_pressure if worst == "food" else 0.0))

	var caps: int = 10 * quantity + 8 * risk + int(pressure / 2.0)
	# Hauling is how you pay rent, not how you become someone. Experience is
	# deliberately thin here so the board cannot be farmed with the safest run.
	var xp: int = 2 + risk

	var shortage_line := "%s的倉儲目前短缺%s（%d／%d）。" % [
		settlement.name, RESOURCE_NAMES[worst],
		int(settlement.inventory.get_amount(worst)), int(settlement.get_target(worst))
	] if urgent else "%s的商隊固定收購%s。" % [settlement.name, RESOURCE_NAMES[worst]]

	return {
		"definition": {
			"id": "%s%s_courier_%d" % [JOB_ID_PREFIX, _short(String(settlement_id)), window],
			"title_zh": "%s運補：%s 收%s %d 份" % ["急件 " if urgent else "", settlement.name, RESOURCE_NAMES[worst], quantity],
			"description_zh": "%s帶 %d 份%s到%s交付。走%s一線大約 %d 天，路況%s。你自己路上的水糧要另外算。交出去的貨會進%s的倉庫，當地的存量和價格會跟著變。" % [
				shortage_line, quantity, RESOURCE_NAMES[worst], settlement.name,
				_name_of(world, StringName(origin_id)), days, RISK_WORDS[risk], settlement.name],
			"settlement_id": _short(String(settlement_id)),
			"issuer_npc_id": "",
			"availability": {"required_day": 0, "required_flags": []},
			"deadline_days": COURIER_DEADLINE_DAYS,
			"objectives": [{
				"id": "deliver_%s" % worst, "type": "DELIVER_RESOURCE",
				"resource": worst, "quantity": quantity, "settlement_id": _short(String(settlement_id)),
			}],
			"outcomes": {
				"resolved": {"rewards": [{"type": "CURRENCY", "amount": caps}, {"type": "XP", "amount": xp}], "world_effects": []},
				"failed": {"rewards": [], "world_effects": []},
				"expired": {"rewards": [], "world_effects": []},
			},
		},
		"archetype": "COURIER",
		"risk": risk,
		"route_days": days,
		"urgent": urgent,
		"summary": "帶 %d 份%s來交付" % [quantity, RESOURCE_NAMES[worst]],
	}

# ── Consignment: carry the town's own goods (REP-1) ──────────────────────────
# Lunatic Dawn's delivery job: low pay, little risk, and the goods are on your
# back - so keeping them is possible, and the town remembers. A town ships
# what it produces to the neighbour that needs it most; the goods really
# leave its stores when the job is taken.
static func _consignment(world, settlement, window: int) -> Dictionary:
	var origin_id: StringName = settlement.id
	var best_resource := ""
	var best_dest := ""
	var best_need := -1000
	for resource in COURIER_RESOURCES:
		if settlement.production.get_amount(resource) <= settlement.consumption.get_amount(resource):
			continue
		for other_id in _sorted_settlement_ids(world):
			if other_id == String(origin_id):
				continue
			var other = world.get_settlement(StringName(other_id))
			# Need is today's gap, or failing that the town's standing deficit.
			var need: int = maxi(other.get_target(resource) - other.inventory.get_amount(resource), other.consumption.get_amount(resource) - other.production.get_amount(resource))
			if need > best_need:
				best_need = need
				best_resource = resource
				best_dest = other_id
	if best_resource == "" or best_need <= 0:
		return {}
	var quantity: int = clampi(2 + int(best_need / 10), 2, 5)
	if settlement.inventory.get_amount(best_resource) < quantity:
		return {}
	var days := _route_days(world, origin_id, StringName(best_dest))
	var risk := road_risk(world, origin_id, StringName(best_dest), Route.ROUTE_HIGHWAY)
	var caps: int = 4 * quantity + 5 * days + 6 * risk
	var xp: int = 2 + risk
	var dest_name := _name_of(world, StringName(best_dest))
	var res_name: String = RESOURCE_NAMES[best_resource]
	var short_origin := _short(String(origin_id))
	return {
		"definition": {
			"id": "%s%s_consign_%d" % [JOB_ID_PREFIX, short_origin, window],
			"title_zh": "運貨：%s %d 份 → %s" % [res_name, quantity, dest_name],
			"description_zh": "%s把自己產的%s交給你，%d 份，運到%s交貨。錢不多，但貨本不用你出。走公路約 %d 天，路況%s。\n貨在你背上——要私吞也行，只是%s會記住。" % [
				settlement.name, res_name, quantity, dest_name, days, RISK_WORDS[risk], settlement.name],
			"settlement_id": short_origin,
			"issuer_npc_id": "",
			"availability": {"required_day": 0, "required_flags": []},
			"deadline_days": CONSIGN_DEADLINE_DAYS,
			"objectives": [{
				"id": "deliver_%s" % best_resource, "type": "DELIVER_RESOURCE",
				"resource": best_resource, "quantity": quantity, "settlement_id": _short(best_dest),
			}],
			"outcomes": {
				"resolved": {"rewards": [{"type": "CURRENCY", "amount": caps}, {"type": "XP", "amount": xp}], "world_effects": []},
				"failed": {"rewards": [], "world_effects": []},
				"expired": {"rewards": [], "world_effects": []},
			},
			"consign_resource": best_resource,
			"consign_quantity": quantity,
			"consign_to": _short(best_dest),
		},
		"archetype": "CONSIGNMENT",
		"risk": risk,
		"route_days": days,
		"urgent": false,
		"summary": "把 %d 份%s運到%s" % [quantity, res_name, dest_name],
	}

# ── Salvage: an exploration and gambling question ─────────────────────────────
static func _salvage(world, settlement, window: int) -> Dictionary:
	var settlement_id: StringName = settlement.id
	var scrap_gap: int = int(settlement.get_target("scrap")) - int(settlement.inventory.get_amount("scrap"))
	var pressed := scrap_gap >= 10

	var risk := RISK_CALM
	var neighbour := _worst_neighbour(world, settlement_id)
	if neighbour != "":
		risk = road_risk(world, settlement_id, StringName(neighbour), Route.ROUTE_WILDERNESS)
	var caps: int = 38 + 6 * risk + (10 if pressed else 0)
	var xp: int = 3 + risk

	var neighbour_name := _name_of(world, StringName(neighbour)) if neighbour != "" else "廢棄公路"
	var days: int = Route.get_route_days(settlement_id, StringName(neighbour), Route.ROUTE_HIGHWAY)
	if days < 1:
		days = SimulationEngine.new().get_route_days_between(world, settlement_id, StringName(neighbour))
	var site_patterns := [
		"往%s公路旁的拋錨貨車",
		"往%s方向的舊貨運站殘骸",
		"往%s公路沿線的廢棄車輛",
	]
	var job_id: String = "%s%s_salvage_%d" % [JOB_ID_PREFIX, _short(String(settlement_id)), window]
	var origin_short := _short(String(settlement_id))
	var dest_short := _short(neighbour)

	# Derive source_wreck_id: a job-scoped stable salvage site identity.
	# NOTE: This guarantees exact yield and encounter stability across travel days and
	# re-visits for this specific contract. It is job-scoped, not a permanent global POI registry.
	var base_site_idx := stable_hash("salvage_site|%s|%d" % [String(settlement_id), window]) % site_patterns.size()
	var chosen_site_idx := base_site_idx
	var source_wreck_id := ""
	var item_id := ""
	var candidate_verbs: Array[StringName] = [&"SEARCH", &"STRIP_PARTS", &"USE_WRENCH", &"QUICK_PICK"]

	for attempt in range(64):
		var test_site_idx := (base_site_idx + attempt) % site_patterns.size()
		var test_wreck_id := "salvage:%s:%s_%s:%d" % [job_id, origin_short, dest_short, test_site_idx]
		if attempt >= site_patterns.size():
			test_wreck_id = "salvage:%s:%s_%s:%d_%d" % [job_id, origin_short, dest_short, test_site_idx, attempt]
		var found_items: Array[String] = []
		for verb in candidate_verbs:
			var yields := TravelEncounter.wreck_item_yield(0, settlement_id, StringName(neighbour), 1, verb, "", test_wreck_id)
			for it in yields:
				if not found_items.has(it) and SALVAGE_ITEM_NAMES.has(it):
					found_items.append(it)
		if not found_items.is_empty():
			chosen_site_idx = test_site_idx
			source_wreck_id = test_wreck_id
			found_items.sort()
			var pick := stable_hash("salvage_item|%s|%d" % [test_wreck_id, window]) % found_items.size()
			item_id = found_items[pick]
			break

	if item_id == "":
		push_error("No recoverable salvage contract for %s" % job_id)
		return {}

	var site_name: String = site_patterns[chosen_site_idx] % neighbour_name
	var methods: Array[String] = []
	var method_names: Dictionary = {&"SEARCH": "仔細搜索", &"STRIP_PARTS": "拆解零件（機械熟練）", &"USE_WRENCH": "用扳手拆卸", &"QUICK_PICK": "順手搜刮（搜刮熟練）"}
	for verb in candidate_verbs:
		if TravelEncounter.wreck_item_yield(0, settlement_id, StringName(neighbour), 1, verb, "", source_wreck_id).has(item_id):
			methods.append(method_names[verb])

	var shortage_info := "修理抽水與機具的料快見底了（廢料 %d／%d）。" % [
		int(settlement.inventory.get_amount("scrap")), int(settlement.get_target("scrap"))
	] if pressed else ""

	return {
		"definition": {
			"id": job_id,
			"title_zh": "%s回收：%s 收%s" % ["急件 " if pressed else "", settlement.name, SALVAGE_ITEM_NAMES[item_id]],
			"description_zh": "%s的工棚開單收一件%s。%s商隊回報在%s發現了車輛殘骸，取回方式：%s。請沿公路前往；荒野繞路不經過這處目標。也能買現成品交件；親自搜刮取得的其他物資歸你。公路單程約 %d 天。" % [
				settlement.name, SALVAGE_ITEM_NAMES[item_id],
				shortage_info, site_name, "、".join(methods), days],
			"settlement_id": _short(String(settlement_id)),
			"issuer_npc_id": "",
			"availability": {"required_day": 0, "required_flags": []},
			"deadline_days": SALVAGE_DEADLINE_DAYS,
			"objectives": [{
				"id": "hand_over_%s" % item_id, "type": "DELIVER_ITEM",
				"item_id": item_id, "quantity": 1, "settlement_id": _short(String(settlement_id)),
			}],
			"outcomes": {
				"resolved": {"rewards": [{"type": "CURRENCY", "amount": caps}, {"type": "XP", "amount": xp}], "world_effects": []},
				"failed": {"rewards": [], "world_effects": []},
				"expired": {"rewards": [], "world_effects": []},
			},
			"target_site": site_name,
			"target_route_origin": _short(String(settlement_id)),
			"target_route_destination": _short(neighbour),
			"target_item_id": item_id,
			"route_days": days,
			"source_wreck_id": source_wreck_id,
		},
		"archetype": "SALVAGE",
		"risk": risk,
		"route_days": days,
		"urgent": pressed,
		"summary": "交一件%s（目標：%s）" % [SALVAGE_ITEM_NAMES[item_id], site_name],
		"target_site": site_name,
		"target_route_origin": _short(String(settlement_id)),
		"target_route_destination": _short(neighbour),
		"target_item_id": item_id,
		"source_wreck_id": source_wreck_id,
	}

# ── Bounty: a combat-readiness question ───────────────────────────────────────
static func _bounty(world, settlement, window: int, standing_generation: int = -1) -> Dictionary:
	var settlement_id: StringName = settlement.id
	var short_origin := _short(String(settlement_id))
	var target_id := &""
	var route_type: StringName = Route.ROUTE_HIGHWAY
	var target_enemy := Enemies.BANDIT

	# Owner ruling: the raider is a STANDING bounty, not one that rotates away
	# in three days - the point is to read it, know you cannot take it yet,
	# and still find it there when you come back stronger. The rotating work
	# on these two boards is the bandit on the highway.
	if standing_generation >= 0:
		target_id = &"settlement:dry_well"
		route_type = Route.ROUTE_WILDERNESS
		target_enemy = Enemies.HEAVY_RAIDER
	elif short_origin == "new_hope":
		target_id = &"settlement:dry_well"
		route_type = Route.ROUTE_HIGHWAY
		target_enemy = Enemies.BANDIT
	elif short_origin == "dry_well":
		target_id = &"settlement:new_hope"
		route_type = Route.ROUTE_HIGHWAY
		target_enemy = Enemies.BANDIT
	elif short_origin == "gray_valley":
		target_id = &"settlement:dry_well"
		route_type = Route.ROUTE_HIGHWAY
		target_enemy = Enemies.FERAL_DOG if window % 2 == 0 else Enemies.BANDIT
	else:
		target_id = StringName(_worst_neighbour(world, settlement_id))
		route_type = Route.ROUTE_HIGHWAY
		target_enemy = Enemies.BANDIT

	# PLACE-4: nobody posts the raider while his camp is burned out.
	if target_enemy == Enemies.HEAVY_RAIDER and RoadPlaces.camp_cleared(world):
		target_enemy = Enemies.BANDIT
		route_type = Route.ROUTE_HIGHWAY

	if target_id == "":
		return {}

	var days := Route.get_route_days(settlement_id, target_id, route_type)
	if days <= 0:
		days = 4 if route_type == Route.ROUTE_WILDERNESS else 2

	var risk := road_risk(world, settlement_id, target_id, route_type)
	var other = world.get_settlement(target_id)
	var security: float = minf(float(settlement.security), float(other.security) if other != null else 100.0)

	var base_caps := 40
	var base_xp := 4
	match target_enemy:
		Enemies.FERAL_DOG:
			base_caps = 40
			base_xp = 4
		Enemies.BANDIT:
			base_caps = 65
			base_xp = 8
		Enemies.HEAVY_RAIDER:
			base_caps = 100
			base_xp = 14

	var caps: int = base_caps + 15 * risk + int(maxf(0.0, 100.0 - security))
	var xp: int = base_xp + 2 * risk
	var target_name := _name_of(world, target_id)
	var enemy_info: Dictionary = Enemies.resolve(target_enemy)
	var enemy_name: String = String(enemy_info.get("name_zh", "目標"))
	var route_name: String = "荒野繞路" if route_type == Route.ROUTE_WILDERNESS else "廢棄公路"
	var job_id := "%s%s_bounty_%d" % [JOB_ID_PREFIX, short_origin, window]
	if standing_generation >= 0:
		job_id = "%s%s%d" % [JOB_ID_PREFIX, STANDING_RAIDER_PREFIX, standing_generation]
		# A fixed price: the same number is on the board every time you look.
		caps = STANDING_RAIDER_CAPS
		xp = STANDING_RAIDER_XP

	var title_zh := "%s懸賞：%s（往%s）" % [
		"高額 " if risk >= RISK_ROUGH or target_enemy == Enemies.HEAVY_RAIDER else "",
		enemy_name, target_name
	]
	var description_zh := "商隊回報在往%s的%s上有%s攔路（該路段治安 %d，路況%s）。%s出賞金：在那條路上把%s打退一次，回來領賞。付錢打發或掉頭跑掉都不算——要真的打贏。路程約 %d 天。" % [
		target_name, route_name, enemy_name, int(security), RISK_WORDS[risk], settlement.name, enemy_name, days
	]
	var summary := "在往%s的%s擊退%s" % [target_name, route_name, enemy_name]
	if standing_generation >= 0:
		title_zh = "常駐懸賞：%s（%s）" % [enemy_name, route_name]
		description_zh = "%s在往%s的%s上紮了營，商隊繞著走。這張賞單一直貼在這裡，直到有人把他打下來。付錢、談判、掉頭跑都不算——要真的打贏。路程約 %d 天。\n商隊的人還說：他的營地再往荒野裡走一天，沙裡埋著一座舊世的地下軍械庫。" % [enemy_name, target_name, route_name, days]

	return {
		"definition": {
			"id": job_id,
			"title_zh": title_zh,
			"description_zh": description_zh,
			"settlement_id": short_origin,
			"issuer_npc_id": "",
			"availability": {"required_day": 0, "required_flags": []},
			"deadline_days": BOUNTY_DEADLINE_DAYS,
			"objectives": [{
				"id": "clear_road", "type": "WIN_ROAD_COMBAT",
				"origin_id": short_origin, "destination_id": _short(String(target_id)),
				"quantity": 1, "target_enemy": target_enemy, "bounty_job_id": job_id,
			}],
			"outcomes": {
				"resolved": {"rewards": [{"type": "CURRENCY", "amount": caps}, {"type": "XP", "amount": xp}], "world_effects": []},
				"failed": {"rewards": [], "world_effects": []},
				"expired": {"rewards": [], "world_effects": []},
			},
			"target_enemy": target_enemy,
			"target_route_origin": short_origin,
			"target_route_destination": _short(String(target_id)),
			"target_route_type": String(route_type),
			"route_days": days,
		},
		"archetype": "BOUNTY",
		"risk": risk,
		"route_days": days,
		"urgent": risk >= RISK_ROUGH or target_enemy == Enemies.HEAVY_RAIDER,
		"target_enemy": target_enemy,
		"target_route_origin": short_origin,
		"target_route_destination": _short(String(target_id)),
		"target_route_type": String(route_type),
		"summary": summary,
	}

static func _hunt(world, settlement, window: int) -> Dictionary:
	var origin: String = _short(String(settlement.id))
	if not HUNTS.has(origin):
		return {}
	var spec: Dictionary = HUNTS[origin]
	var destination := StringName("settlement:" + String(spec.destination))
	if world.get_settlement(destination) == null:
		return {}
	var enemy: String = spec.enemy
	var days: int = 2
	for caravan in world.caravans.values():
		if (caravan.origin_id == settlement.id and caravan.destination_id == destination) or (caravan.destination_id == settlement.id and caravan.origin_id == destination):
			days = int(caravan.route_days)
			break
	if Route.supports_pair(settlement.id, destination):
		days = Route.get_route_days(settlement.id, destination, spec.route)
	var risk: int = road_risk(world, settlement.id, destination, StringName(spec.route))
	var job_id := "%s%s_hunt_%s_%d" % [JOB_ID_PREFIX, origin, enemy, window]
	var enemy_name: String = Enemies.display_name(enemy)
	var route_name: String = "荒野繞路" if spec.route == "WILDERNESS" else "廢棄公路"
	var title := "狩獵委託：%s（往%s）" % [enemy_name, _name_of(world, destination)]
	var description := "在往%s的%s擊退%s，回%s交付勝利紀錄領賞。單程 %d 天，期限 %d 天。逃跑不算完成。\n%s" % [_name_of(world, destination), route_name, enemy_name, settlement.name, days, BOUNTY_DEADLINE_DAYS, Enemies.resolve(enemy).note_zh]
	var definition := {
		"id": job_id, "title_zh": title, "description_zh": description,
		"settlement_id": origin, "issuer_npc_id": "",
		"availability": {"required_day": 0, "required_flags": []}, "deadline_days": BOUNTY_DEADLINE_DAYS,
		"objectives": [{"id": "hunt_creature", "type": "WIN_ROAD_COMBAT", "origin_id": origin, "destination_id": String(spec.destination), "quantity": 1, "target_enemy": enemy, "bounty_job_id": job_id}],
		"outcomes": {
			"resolved": {"rewards": [{"type": "CURRENCY", "amount": int(spec.caps) + 15 * risk}, {"type": "XP", "amount": int(spec.xp) + 2 * risk}], "world_effects": []},
			"failed": {"rewards": [], "world_effects": []}, "expired": {"rewards": [], "world_effects": []},
		},
		"target_enemy": enemy, "target_route_origin": origin, "target_route_destination": String(spec.destination), "target_route_type": String(spec.route), "route_days": days,
	}
	return {"definition": definition, "archetype": "HUNT", "risk": risk, "route_days": days, "urgent": false, "target_enemy": enemy, "target_route_origin": origin, "target_route_destination": String(spec.destination), "target_route_type": String(spec.route), "summary": "擊退%s，再回%s領賞" % [enemy_name, settlement.name]}

# The standing raider bounty. It stays on New Hope's board until it is
# resolved, expires or fails; each ending opens the next generation, so a
# missed deadline puts the same raider back up rather than losing him. Not
# posted while his camp is burned out (PLACE-4).
static func standing_raider_generation(world) -> int:
	var ended := 0
	for quest_id in world.quest_state.all_quest_ids():
		if String(quest_id).begins_with(JOB_ID_PREFIX + STANDING_RAIDER_PREFIX):
			var qs = world.quest_state.get_quest(quest_id)
			if qs != null and String(qs.status) in ["RESOLVED", "EXPIRED", "FAILED"]:
				ended += 1
	return ended

static func _standing_raider(world, settlement, window: int) -> Dictionary:
	if RoadPlaces.camp_cleared(world):
		return {}
	var entry := _bounty(world, settlement, window, standing_raider_generation(world))
	if not entry.is_empty():
		entry["standing"] = true
	return entry

# ── What this character, specifically, can read off the board ─────────────────

# Perks and acquired identities stop being a thing that fires at one encounter
# and start being how this person reads work. Every line here is derived from
# facts the game already holds; none of it changes pay, danger or outcome.
static func intel_for(world, entry: Dictionary) -> Array:
	var lines: Array = []
	if world == null or world.player == null or entry.is_empty():
		return lines
	var player = world.player
	var archetype := String(entry.get("archetype", ""))
	var risk := int(entry.get("risk", RISK_CALM))

	if archetype == "SALVAGE" and player.perk_ids.has("CAREFUL_SALVAGER"):
		lines.append("〔細心拾荒者〕舊公路的殘骸你翻得比別人乾淨，這件自己去找通常划得來。")
	if archetype == "SALVAGE" and player.capability != null:
		if player.capability.get_rank("SCAVENGING") >= 2:
			lines.append("〔搜刮 熟練〕你能順手搜刮殘骸，不耽誤趕路天數；拿得到什麼仍看殘骸本身。")
		if player.capability.get_rank("MECHANICS") >= 2:
			lines.append("〔機械 熟練〕你能拆解引擎與傳動，取出一般搜索會漏掉的零件。")
	if archetype == "COURIER" and player.perk_ids.has("ROAD_RUNNER"):
		var caps := 0
		for reward in entry.definition.outcomes.resolved.rewards:
			if String(reward.type) == "CURRENCY":
				caps = int(reward.amount)
		var fair: int = caps + 6 * int(entry.get("route_days", 2))
		if fair > caps:
			lines.append("〔商路熟手〕這趟開 %d 瓶蓋偏低，照路程你估合理價該在 %d 上下。" % [caps, fair])
	if archetype in ["BOUNTY", "HUNT"]:
		lines.append("以下估算採連續近身攻擊；射擊傷害與耗彈請見戰鬥行動。")
		var target_enemy: String = String(entry.get("target_enemy", ""))
		var enemy_name: String = String(Enemies.resolve(target_enemy).get("name_zh", "目標")) if target_enemy != "" else "攔路敵人"
		var has_death_tested: bool = player.has_acquired_trait("DEATH_TESTED")
		if has_death_tested:
			var fc: Dictionary = FieldAdventure.forecast_for_enemy(world, target_enemy, true)
			if not fc.is_empty():
				var beaten_note := "，以目前血量可能會倒下！" if fc.get("beaten", false) else "。"
				lines.append("〔見過底的人〕目標：%s（推估需 %d 輪、每擊 %d 傷、承受約 %d 傷、戰後剩餘約 %d HP%s）" % [
					enemy_name, int(fc.turns), int(fc.damage_per_hit), int(fc.incoming), int(fc.hp_after), beaten_note
				])
			else:
				var hp: int = int(player.field_kit.get("hp", 0))
				lines.append("〔見過底的人〕你現在 %d 點血，對手是%s。" % [hp, enemy_name])
		else:
			var rank_int: int = player.capability.get_rank("MELEE") if player.capability != null else 0
			var rank_name: String = {0: "生疏", 1: "略懂", 2: "熟練", 3: "精通"}.get(rank_int, "生疏")
			var weapon_note: String = "赤手空拳"
			if player.equipment != null:
				var w_id: String = player.equipment.equipped_item("main_hand")
				if w_id != "":
					weapon_note = "裝備了武器"
			lines.append("懸賞目標：%s（威脅度 %s）。你目前的格鬥水平為〔%s〕，%s。" % [
				enemy_name, RISK_STARS.get(risk, "★☆☆"), rank_name, weapon_note
			])
			# The "not yet" has to be readable, or the player cannot decide to
			# come back later. Words only - the arithmetic stays DEATH_TESTED's.
			var read: Dictionary = FieldAdventure.forecast_for_enemy(world, target_enemy, true) if target_enemy != "" else {}
			if not read.is_empty():
				if bool(read.beaten):
					lines.append("照你現在的身手，正面打多半會被打倒。練強一點、換把好武器再回來。")
				elif int(read.hp_after) <= 4:
					lines.append("硬拚打得下來，但會打得很慘。")
				else:
					lines.append("以你現在的身手，這一仗打得贏。")
	if archetype == "COURIER" and player.has_acquired_trait("DESERT_HARDENED"):
		lines.append("〔荒野歷練〕這段路你走過更糟的，估算補給時可以抓得比一般人緊。")
	if risk >= RISK_BAD:
		lines.append("這條路目前的治安狀況會讓路上遇到的麻煩比平常更多。")
	return lines
