extends RefCounted

# ==============================================================================
# REP-1: LOCAL TRUST
# ==============================================================================
# Owner ruling: not a world reputation and not a good/evil meter. Three towns,
# each remembering what the player did FOR it and TO it:
#
#   不受歡迎 <= -5    the town gives you no work, and sells to you dear
#   陌生     -4..3
#   熟客     4..9     its jobs pay 10% more
#   信任     10+      its jobs pay 20% more
#
# Everything is folded from receipts, so a saved game carries nothing new:
#
#   +2  a job this town issued, delivered            (QUEST_RESOLVED)
#   +3  a road place reported to this town           (PLACE_REPORTED)
#   -10 its consigned cargo kept                     (JOB_BETRAYED)
#   -5  its consigned cargo simply never arrived     (consignment EXPIRED)
#
# A betrayal or an abandoned load weighs in full for BETRAYAL_MEMORY_DAYS -
# long enough that the town's work is closed "for a while" - then fades to a
# scar: towns forgive slowly and never completely, and a second betrayal on top
# of a scar closes the door for good.
# ==============================================================================

const TOWNS := ["settlement:dry_well", "settlement:gray_valley", "settlement:new_hope"]

const DELIVERED := 2
const REPORTED := 3
const BETRAYED := -10
const BETRAYED_SCAR := -3
const ABANDONED := -5
const ABANDONED_SCAR := -2
const UNWELCOME_AT := -5
const BETRAYAL_MEMORY_DAYS := 20

const UNWELCOME := "UNWELCOME"
const STRANGER := "STRANGER"
const REGULAR := "REGULAR"
const TRUSTED := "TRUSTED"
const TIER_NAMES := {UNWELCOME: "不受歡迎", STRANGER: "陌生", REGULAR: "熟客", TRUSTED: "信任"}

const UNWELCOME_MARKUP := 1.25

static func _short(settlement_id: String) -> String:
	return settlement_id.replace("settlement:", "")

static func _full(short_or_full: String) -> String:
	return short_or_full if short_or_full.begins_with("settlement:") else "settlement:" + short_or_full

# Which town issued a quest, read from the contract the player took.
static func issuer_of(world, quest_id: String) -> String:
	if world.accepted_jobs.has(quest_id):
		return _full(String(world.accepted_jobs[quest_id].get("settlement_id", "")))
	const QuestRegistry = preload("res://simulation/quest_registry.gd")
	var found: Dictionary = QuestRegistry.get_definition(quest_id)
	if bool(found.get("success", false)):
		return _full(String(found.definition.get("settlement_id", "")))
	return ""

static func is_consignment(world, quest_id: String) -> bool:
	return world.accepted_jobs.has(quest_id) and world.accepted_jobs[quest_id].has("consign_resource")

static func score(world, settlement_id: String) -> int:
	var town := _full(settlement_id)
	var total := 0
	for evt in world.event_log:
		if typeof(evt.payload) != TYPE_DICTIONARY:
			continue
		match evt.type:
			"QUEST_RESOLVED":
				if issuer_of(world, String(evt.payload.get("quest_id", ""))) == town:
					total += DELIVERED
			"PLACE_REPORTED":
				if _full(String(evt.payload.get("settlement_id", ""))) == town:
					total += REPORTED
			"JOB_BETRAYED":
				if _full(String(evt.payload.get("settlement_id", ""))) == town:
					total += BETRAYED if int(world.current_day) - int(evt.day) < BETRAYAL_MEMORY_DAYS else BETRAYED_SCAR
	for quest_id in world.accepted_jobs.keys():
		if not is_consignment(world, String(quest_id)) or issuer_of(world, String(quest_id)) != town:
			continue
		var qs = world.quest_state.get_quest(quest_id)
		if qs != null and String(qs.status) == "EXPIRED":
			var expired_on: int = int(qs.deadline_day) + 1
			total += ABANDONED if int(world.current_day) - expired_on < BETRAYAL_MEMORY_DAYS else ABANDONED_SCAR
	return total

static func tier(world, settlement_id: String) -> String:
	var s := score(world, settlement_id)
	if s <= UNWELCOME_AT:
		return UNWELCOME
	if s >= 10:
		return TRUSTED
	if s >= 4:
		return REGULAR
	return STRANGER

static func tier_name(world, settlement_id: String) -> String:
	return String(TIER_NAMES[tier(world, settlement_id)])

# How much more (or less) a town's own jobs pay you.
static func reward_multiplier(world, settlement_id: String) -> float:
	match tier(world, settlement_id):
		TRUSTED: return 1.2
		REGULAR: return 1.1
	return 1.0

# What a town charges you on top of the market price.
static func buy_markup(world, settlement_id: String) -> float:
	return UNWELCOME_MARKUP if world != null and tier(world, settlement_id) == UNWELCOME else 1.0

static func gives_work(world, settlement_id: String) -> bool:
	return tier(world, settlement_id) != UNWELCOME

# One line for the town panel and the board.
static func summary(world, settlement_id: String) -> String:
	var t := tier(world, settlement_id)
	match t:
		UNWELCOME: return "%s：不受歡迎——不接你的委託，買東西貴 25%%。" % _town_name(world, settlement_id)
		REGULAR: return "%s：熟客——這裡的委託多付一成。" % _town_name(world, settlement_id)
		TRUSTED: return "%s：信任——這裡的委託多付兩成。" % _town_name(world, settlement_id)
	return "%s：陌生。" % _town_name(world, settlement_id)

static func _town_name(world, settlement_id: String) -> String:
	var s = world.get_settlement(StringName(_full(settlement_id)))
	if s == null:
		return _short(settlement_id)
	var name := String(s.name)
	var cut := name.find(" (")
	return name.substr(0, cut) if cut > 0 else name
