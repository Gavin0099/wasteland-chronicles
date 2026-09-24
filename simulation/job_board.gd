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

# The board turns over on a cadence rather than daily, so work the player walked
# past yesterday is usually still there when they come back for it.
const POSTING_WINDOW_DAYS := 3
# Quest ids are validated as stable identifiers - lowercase, digits and
# underscores only - so the namespace is a prefix, not a colon. The resolver
# checks authored content first, so a collision favours the authored quest
# rather than letting a generated one silently replace it.
const JOB_ID_PREFIX := "job_"

const COURIER_DEADLINE_DAYS := 7
const SALVAGE_DEADLINE_DAYS := 8
const BOUNTY_DEADLINE_DAYS := 9

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
const SALVAGE_ITEMS := ["wrench", "rope", "flashlight", "first_aid_kit"]
const SALVAGE_ITEM_NAMES := {"wrench": "扳手", "rope": "繩索", "flashlight": "手電筒", "first_aid_kit": "急救包"}

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
	]
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
		out.append(entry)
	return out

# Every posting on every board today.
static func all_postings(world) -> Array:
	var out: Array = []
	for settlement_id in _sorted_settlement_ids(world):
		for entry in postings(world, StringName(settlement_id)):
			out.append(entry)
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
	var urgent := worst_gap >= 10
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
			"description_zh": "%s帶 %d 份%s到%s交付。走%s一線大約 %d 天，路況%s。你自己路上的水糧要另外算——這份工作買下你背上的貨，不會因此把倉庫填滿。" % [
				shortage_line, quantity, RESOURCE_NAMES[worst], settlement.name,
				_name_of(world, StringName(origin_id)), days, RISK_WORDS[risk]],
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

# ── Salvage: an exploration and gambling question ─────────────────────────────
static func _salvage(world, settlement, window: int) -> Dictionary:
	var settlement_id: StringName = settlement.id
	var pick := stable_hash("salvage|%s|%d" % [String(settlement_id), window]) % SALVAGE_ITEMS.size()
	var item_id: String = SALVAGE_ITEMS[pick]
	var scrap_gap: int = int(settlement.get_target("scrap")) - int(settlement.inventory.get_amount("scrap"))
	var pressed := scrap_gap >= 10

	var risk := RISK_CALM
	var neighbour := _worst_neighbour(world, settlement_id)
	if neighbour != "":
		risk = road_risk(world, settlement_id, StringName(neighbour), Route.ROUTE_WILDERNESS)
	var caps: int = 38 + 6 * risk + (10 if pressed else 0)
	var xp: int = 3 + risk

	return {
		"definition": {
			"id": "%s%s_salvage_%d" % [JOB_ID_PREFIX, _short(String(settlement_id)), window],
			"title_zh": "%s回收：%s 收%s" % ["急件 " if pressed else "", settlement.name, SALVAGE_ITEM_NAMES[item_id]],
			"description_zh": "%s的工棚開單收一件%s。%s從哪裡弄來沒人過問：市場上買現成的最省事，但舊公路的殘骸裡翻得出來的話，翻出來的其他東西都歸你。" % [
				settlement.name, SALVAGE_ITEM_NAMES[item_id],
				"修理抽水與機具的料快見底了（廢料 %d／%d）。" % [int(settlement.inventory.get_amount("scrap")), int(settlement.get_target("scrap"))] if pressed else ""],
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
		},
		"archetype": "SALVAGE",
		"risk": risk,
		"route_days": 0,
		"urgent": pressed,
		"summary": "交一件%s" % SALVAGE_ITEM_NAMES[item_id],
	}

# ── Bounty: a combat-readiness question ───────────────────────────────────────
static func _bounty(world, settlement, window: int) -> Dictionary:
	var settlement_id: StringName = settlement.id
	var target_id := _worst_neighbour(world, settlement_id)
	if target_id == "":
		return {}
	var risk := road_risk(world, settlement_id, StringName(target_id), Route.ROUTE_HIGHWAY)
	var days := _route_days(world, settlement_id, StringName(target_id))
	var other = world.get_settlement(StringName(target_id))
	var security: float = minf(float(settlement.security), float(other.security) if other != null else 100.0)

	# A standing clearing contract is routine; a collapsing road makes it pay
	# far better and count for more. This is the whole point of modulation: the
	# job exists either way, and the world decides how bad it is.
	var caps: int = 55 + 20 * risk + int(maxf(0.0, 100.0 - security))
	var xp: int = 6 + 4 * risk
	var target_name := _name_of(world, StringName(target_id))

	return {
		"definition": {
			"id": "%s%s_bounty_%d" % [JOB_ID_PREFIX, _short(String(settlement_id)), window],
			"title_zh": "%s懸賞：清理往%s的路" % ["高額 " if risk >= RISK_ROUGH else "", target_name],
			"description_zh": "商隊回報往%s那條路上有人攔車（該路段治安 %d，路況%s）。%s出賞金：在那條路上把攔路的人打退一次，回來領賞。付錢打發或掉頭跑掉都不算——要真的打贏。路程約 %d 天。" % [
				target_name, int(security), RISK_WORDS[risk], settlement.name, days],
			"settlement_id": _short(String(settlement_id)),
			"issuer_npc_id": "",
			"availability": {"required_day": 0, "required_flags": []},
			"deadline_days": BOUNTY_DEADLINE_DAYS,
			"objectives": [{
				"id": "clear_road", "type": "WIN_ROAD_COMBAT",
				"origin_id": _short(String(settlement_id)), "destination_id": _short(target_id), "quantity": 1,
			}],
			"outcomes": {
				"resolved": {"rewards": [{"type": "CURRENCY", "amount": caps}, {"type": "XP", "amount": xp}], "world_effects": []},
				"failed": {"rewards": [], "world_effects": []},
				"expired": {"rewards": [], "world_effects": []},
			},
		},
		"archetype": "BOUNTY",
		"risk": risk,
		"route_days": days,
		"urgent": risk >= RISK_ROUGH,
		"summary": "在往%s的路上打贏一次" % target_name,
	}

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
	if archetype == "COURIER" and player.perk_ids.has("ROAD_RUNNER"):
		var caps := 0
		for reward in entry.definition.outcomes.resolved.rewards:
			if String(reward.type) == "CURRENCY":
				caps = int(reward.amount)
		var fair: int = caps + 6 * int(entry.get("route_days", 2))
		if fair > caps:
			lines.append("〔商路熟手〕這趟開 %d 瓶蓋偏低，照路程你估合理價該在 %d 上下。" % [caps, fair])
	if archetype == "BOUNTY" and player.has_acquired_trait("DEATH_TESTED"):
		var hp: int = int(player.field_kit.get("hp", 0))
		if hp <= 6:
			lines.append("〔見過底的人〕你現在 %d 點血。以這個狀態接這張賞金，不是勇敢的問題。" % hp)
		else:
			lines.append("〔見過底的人〕你現在 %d 點血，撐得住一場硬仗。" % hp)
	if archetype == "COURIER" and player.has_acquired_trait("DESERT_HARDENED"):
		lines.append("〔荒野歷練〕這段路你走過更糟的，估算補給時可以抓得比一般人緊。")
	if risk >= RISK_BAD:
		lines.append("這條路目前的治安狀況會讓路上遇到的麻煩比平常更多。")
	return lines
