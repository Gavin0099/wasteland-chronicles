class_name GrowthPoints
extends RefCounted

# ==============================================================================
# PLAY-2: GROWTH CHOICE — a level has to hand the player a decision
# ==============================================================================
# Hand-play: "人物升級沒有感覺 不能點點數 也沒有技能可以升級". All three were
# true at once. Levels 1 and 2 carry no perk slot, so the first two levels gave
# literally nothing; skill practice only fires on a handful of roadside options,
# so a player who spent the session running jobs moved no skill at all; and
# there was no way to decide anything.
#
# THE OWNER'S ORIGINAL OBJECTION STILL HOLDS. Free points AT CREATION would let
# a player pour everything into the most efficient skill and dissolve the
# Background into a spreadsheet. But spending a point that was EARNED by
# surviving and working is the opposite act: it is the game asking, after the
# fact, "what did that make you?"
#
# SO POINTS ARE NEVER GRANTED, ONLY EARNED AND DERIVED:
#   earned    = levels gained beyond the first
#   spent     = committed SKILL_POINT_SPENT receipts
#   available = earned - spent
#
# Nothing is stored that could drift out of step with history. This mirrors how
# perks and acquired traits already work: the ledger is the fact, and the screen
# is a projection of it.
#
# PRACTICE IS NOT REPLACED. Doing a thing still makes you better at it; that is
# the character growing by itself. A point is the other half - the character
# growing because you chose it. Both write the same skill ranks.
# ==============================================================================

const Profile = preload("res://simulation/capability_profile.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")

# Which skills a point may be spent on. Deliberately not every skill in the
# schema: three of them have no way to matter yet, and selling a player a rank
# in something the world never asks for is a worse lie than showing it locked.
#
# The reason is stated per skill so the screen can show it rather than silently
# hiding a choice, and so this list is obviously a statement about CONTENT that
# exists, not about the skill schema.
const SPENDABLE := ["BARTER", "MECHANICS", "MELEE", "SCAVENGING", "SPEECH", "STEALTH", "SURVIVAL"]
const UNAVAILABLE_REASON := {
	"FIREARMS": "目前沒有任何遭遇或戰鬥會用到槍械。",
	"ELECTRONICS": "目前沒有任何遭遇會用到電子。",
	"MEDICINE": "急救包目前只靠使用來熟練，還沒有需要醫療門檻的場合。",
}

static func is_spendable(skill_id: Variant) -> bool:
	return typeof(skill_id) == TYPE_STRING and SPENDABLE.has(skill_id)

# Every level after the first is one point. Level 1 is where you start, not
# something you achieved.
static func earned_for_xp(xp: int) -> int:
	return maxi(0, Perks.level_for_xp(maxi(0, xp)) - 1)

static func spent(events: Array[EventRecord], player_id: StringName) -> int:
	var count := 0
	for event in events:
		if event.type == "SKILL_POINT_SPENT" and event.actor_id == player_id:
			count += 1
	return count

static func available(world) -> int:
	if world == null or world.player == null:
		return 0
	return maxi(0, earned_for_xp(int(world.player.xp)) - spent(world.event_log, world.player.npc_id))

# A committed spend must name a real, spendable skill and a rank it could
# actually have reached. The ledger cannot reconstruct a final rank on its own,
# because practice raises ranks too and practice progress lives in the profile;
# that limit is stated here rather than pretended away.
static func validate_history(events: Array[EventRecord], player_id: StringName, xp: int) -> String:
	var count := 0
	for event in events:
		if event.type != "SKILL_POINT_SPENT" or event.actor_id != player_id:
			continue
		if event.target_id != &"character":
			return "GROWTH_LEDGER_MALFORMED"
		var skill: Variant = event.payload.get("skill_id")
		var to_rank: Variant = event.payload.get("to_rank")
		if not is_spendable(skill):
			return "GROWTH_LEDGER_UNKNOWN_SKILL"
		if typeof(to_rank) not in [TYPE_INT, TYPE_FLOAT] or float(to_rank) != floor(float(to_rank)) or int(to_rank) < 1 or int(to_rank) > 5:
			return "GROWTH_LEDGER_INVALID_RANK"
		count += 1
	if count > earned_for_xp(maxi(0, xp)):
		return "GROWTH_LEDGER_EXCEEDS_EARNED_POINTS"
	return ""

# What the character sheet shows: every skill, whether a point may go into it
# right now, and if not, why not. A locked door with a reason on it teaches the
# player something; a missing door teaches them nothing.
# What ONE point would concretely open, right now, for this character.
#
# Derived from the encounter catalogue rather than written out, for the same
# reason the creation screen derives its copy: a hand-written promise drifts the
# first time an option is retuned, and the player would have spent a point on
# something the road no longer honours.
#
# Only skills where the very next rank crosses a real requirement are listed.
# "+1 社交" opens no door at all - it only shifts the odds on a door that is
# already there - so it is deliberately absent rather than dressed up.
static func openings(world) -> Array:
	const Travel = preload("res://simulation/travel_encounter.gd")
	const Names = {"BARTER": "交易", "ELECTRONICS": "電子", "FIREARMS": "槍械", "MECHANICS": "機械",
		"MEDICINE": "醫療", "MELEE": "近戰", "SCAVENGING": "搜刮", "SPEECH": "社交",
		"STEALTH": "潛行", "SURVIVAL": "荒野求生"}
	var out: Array = []
	if world == null or world.player == null or world.player.capability == null:
		return out
	if available(world) < 1:
		return out
	var encounter_types := [Travel.WRECK, Travel.ROCKSLIDE, Travel.ROADBLOCK,
		Travel.DEHYDRATED_TRAVELLER, Travel.REFUGEE_COLUMN, Travel.BANDIT_AMBUSH]
	for skill_id in SPENDABLE:
		var have: int = world.player.capability.get_rank(skill_id)
		if have >= 5:
			continue
		var labels := PackedStringArray()
		for encounter_type in encounter_types:
			for option in Travel.options(encounter_type):
				for clause in (option.get("requires", {}) as Dictionary).get("all", []):
					if String(clause.get("kind", "")) != "skill" or String(clause.get("skill_id", "")) != skill_id:
						continue
					var need := int(clause.get("min_rank", 0))
					if have < need and have + 1 >= need:
						labels.append("%s：%s" % [Travel.title(encounter_type), String(option.label)])
		if labels.size() > 0:
			out.append({
				"skill_id": skill_id,
				"skill_name": String(Names.get(skill_id, skill_id)),
				"opens": "、".join(labels),
				"count": labels.size(),
			})
	return out

static func choices(world) -> Array:
	var rows: Array = []
	if world == null or world.player == null or world.player.capability == null:
		return rows
	var points := available(world)
	for skill_id in Profile.SKILLS:
		var rank: int = world.player.capability.get_rank(skill_id)
		var reason := ""
		if not is_spendable(skill_id):
			reason = String(UNAVAILABLE_REASON.get(skill_id, "目前沒有用途。"))
		elif rank >= 5:
			reason = "已經是大師，沒有更高的一階。"
		elif points <= 0:
			reason = "沒有可用的成長點。"
		rows.append({
			"skill_id": skill_id,
			"rank": rank,
			"can_spend": reason == "",
			"reason": reason,
		})
	return rows
