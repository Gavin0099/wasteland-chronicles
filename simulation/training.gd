extends RefCounted

# ==============================================================================
# TRAIN-1: MONEY INTO GROWTH
# ==============================================================================
# Lunatic Dawn pillar 6: money has to turn into becoming stronger, or earning
# it stops meaning anything once the few weapons are bought. In Lunatic Dawn 2
# attributes were trained for money; here a town's teacher raises one skill a
# rank for caps and days.
#
# Each town teaches what it lives by, so the three towns stop being the same
# place with different prices:
#
#   灰谷   an industrial scrap town   MECHANICS, SCAVENGING
#   乾井   the fuel and water town    SURVIVAL, BARTER
#   新希望 the guarded oasis          MELEE, SPEECH
#
# STEALTH is not taught: it is learned by doing.
#
# Teachers only take you as far as 熟練 (rank 2). Past that is practice, levels
# and whatever the world hides - so money is a way to start, not a way to finish.
# A town that has turned on you (REP-1) will not teach you.
#
# Every lesson is a SKILL_TRAINED receipt; nothing new is saved.
# ==============================================================================

const LocalTrust = preload("res://simulation/local_trust.gd")

const TEACH_CAP := 2
const LESSON_DAYS := 2
const PRICE_BY_RANK := {1: 60, 2: 120}

const TEACHERS := {
	"settlement:gray_valley": {
		"MECHANICS": "老焊工阿強",
		"SCAVENGING": "拾荒頭子老鼠",
	},
	"settlement:dry_well": {
		"SURVIVAL": "井邊的老嚮導",
		"BARTER": "油行的帳房",
	},
	"settlement:new_hope": {
		"MELEE": "護衛隊長",
		"SPEECH": "農會的調解人",
	},
}

const SKILL_NAMES := {"MECHANICS": "機械", "SCAVENGING": "拾荒", "SURVIVAL": "求生", "BARTER": "交易", "MELEE": "格鬥", "SPEECH": "口才"}
const RANK_NAMES := {0: "外行", 1: "略懂", 2: "熟練", 3: "精通", 4: "專家", 5: "大師"}

static func teaches(settlement_id: String, skill_id: String) -> bool:
	return TEACHERS.has(settlement_id) and TEACHERS[settlement_id].has(skill_id)

# Where a skill can be learned, for rumours and hints.
static func town_for(skill_id: String) -> String:
	for town in TEACHERS:
		if TEACHERS[town].has(skill_id):
			return town
	return ""

static func price(to_rank: int) -> int:
	return int(PRICE_BY_RANK.get(to_rank, 0))

# Why this lesson cannot be taken now, or "" if it can.
static func refusal(world, settlement_id: String, skill_id: String) -> String:
	if not teaches(settlement_id, skill_id):
		return "NOT_TAUGHT_HERE"
	if not LocalTrust.gives_work(world, settlement_id):
		return "TOWN_DISTRUSTS_YOU"
	var rank: int = int(world.player.capability.get_rank(skill_id)) if world.player.capability != null else 0
	if rank >= TEACH_CAP:
		return "BEYOND_TEACHER"
	if int(world.player.money) < price(rank + 1):
		return "INSUFFICIENT_FUNDS"
	return ""

# The lessons a town offers this character, with the reason any is closed.
static func offers(world, settlement_id: String) -> Array:
	var out: Array = []
	if not TEACHERS.has(settlement_id) or world.player == null:
		return out
	var skills: Array = TEACHERS[settlement_id].keys()
	skills.sort()
	for skill_id in skills:
		var rank: int = int(world.player.capability.get_rank(skill_id)) if world.player.capability != null else 0
		var why := refusal(world, settlement_id, skill_id)
		var note := ""
		match why:
			"BEYOND_TEACHER": note = "你已經%s，他教不了你更多。再往上只能靠實戰和歷練。" % RANK_NAMES[rank]
			"INSUFFICIENT_FUNDS": note = "要 %d 瓶蓋，你只有 %d。" % [price(rank + 1), int(world.player.money)]
			"TOWN_DISTRUSTS_YOU": note = "這個鎮現在不想跟你打交道。"
		out.append({
			"skill_id": skill_id,
			"skill_name": String(SKILL_NAMES.get(skill_id, skill_id)),
			"teacher": String(TEACHERS[settlement_id][skill_id]),
			"from_rank": rank,
			"to_rank": rank + 1,
			"to_rank_name": String(RANK_NAMES.get(mini(rank + 1, 5), "")),
			"price": price(rank + 1) if rank < TEACH_CAP else 0,
			"days": LESSON_DAYS,
			"can_train": why == "",
			"note": note,
		})
	return out
