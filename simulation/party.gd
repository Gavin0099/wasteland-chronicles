extends RefCounted

# ==============================================================================
# PARTY-1: ONE COMPANION
# ==============================================================================
# Lunatic Dawn pillar 7, in the owner's wasteland terms: a companion is not
# +20% damage. They are another mouth on the road, and a different set of
# abilities, so the party's life route changes:
#
#   阿扳 (Gray Valley)  a mechanic   the party counts as MECHANICS 2 - the
#                                   armory door, stripping parts
#   鐵牛 (New Hope)     a fighter    every attack lands +2 - the raider becomes
#                                   thinkable
#   沙狐 (Dry Well)     a guide      finds water on the road for both of you -
#                                   long roads cost food only
#
# One at a time: who you walk with is itself the choice.
#
# THE COST IS THE ROAD. In town the town feeds everyone, companion included,
# the same way it feeds the player (process_player_daily_needs). On a travel
# day a companion eats from YOUR pack after you do; if the pack cannot feed
# them, they leave you on the road.
#
# Everything is folded from COMPANION_JOINED / COMPANION_LEFT receipts; nothing
# new is saved. PARTY-2A adds exactly one personal request and shared journey;
# no general relationship score, new NPC lifecycle or romance.
# ==============================================================================

const LocalTrust = preload("res://simulation/local_trust.gd")
const ABBAN := "companion:abban"
const FRIEND_FEE := 25

const COMPANIONS := {
	"companion:abban": {
		"name_zh": "阿扳",
		"role_zh": "技師",
		"town": "settlement:gray_valley",
		"fee": 50,
		"skills": {"MECHANICS": 2},
		"damage_bonus": 0,
		"road_water": 1,
		"road_food": 1,
		"finds_water": false,
		"pitch_zh": "拆過的東西比你見過的還多。帶上他，隊伍的機械就算〔熟練〕。",
	},
	"companion:tieniu": {
		"name_zh": "鐵牛",
		"role_zh": "打手",
		"town": "settlement:new_hope",
		"fee": 60,
		"skills": {},
		"damage_bonus": 2,
		"road_water": 1,
		"road_food": 1,
		"finds_water": false,
		"pitch_zh": "護衛隊退下來的。打起來他跟著你砍，每一擊多 2 傷害。",
	},
	"companion:shahu": {
		"name_zh": "沙狐",
		"role_zh": "嚮導",
		"town": "settlement:dry_well",
		"fee": 50,
		"skills": {},
		"damage_bonus": 0,
		"road_water": 0,
		"road_food": 1,
		"finds_water": true,
		"pitch_zh": "在荒原裡找得到水。路上你們兩個都不用喝背包裡的水，只吃食物。",
	},
}

static func ids() -> Array:
	var out: Array = COMPANIONS.keys()
	out.sort()
	return out

static func exists(companion_id: Variant) -> bool:
	return typeof(companion_id) == TYPE_STRING and COMPANIONS.has(companion_id)

static func info(companion_id: String) -> Dictionary:
	return (COMPANIONS[companion_id] as Dictionary).duplicate(true) if exists(companion_id) else {}

# Who walks with the player now.
static func current(world) -> String:
	if world == null or world.player == null:
		return ""
	var who := ""
	for evt in world.event_log:
		if String(evt.actor_id) != String(world.player.npc_id):
			continue
		if evt.type == "COMPANION_JOINED":
			who = String(evt.payload.get("companion_id", ""))
		elif evt.type == "COMPANION_LEFT":
			who = ""
	return who if exists(who) else ""

static func for_hire_in(settlement_id: String) -> String:
	for companion_id in ids():
		if String(COMPANIONS[companion_id].town) == settlement_id:
			return companion_id
	return ""

# Why this companion cannot be hired here now, or "".
static func hire_refusal(world, settlement_id: String, companion_id: String) -> String:
	if not exists(companion_id) or String(COMPANIONS[companion_id].town) != settlement_id:
		return "COMPANION_NOT_HERE"
	if current(world) != "":
		return "ALREADY_HAS_COMPANION"
	if not LocalTrust.gives_work(world, settlement_id):
		return "TOWN_DISTRUSTS_YOU"
	if int(world.player.money) < hire_fee(world, companion_id):
		return "INSUFFICIENT_FUNDS"
	return ""

# PARTY-2A keeps one request in existing event receipts.
const Request = preload("res://simulation/companion_request.gd")

static func personal_state(world) -> Dictionary:
	return Request.state(world)

static func validate_personal_history(world) -> String:
	return String(Request.state(world).error)

static func hire_fee(world, companion_id: String) -> int:
	if companion_id == ABBAN and bool(personal_state(world).tool_given):
		return FRIEND_FEE
	return int(COMPANIONS[companion_id].fee) if exists(companion_id) else 0

static func request_refusal(world) -> String:
	return Request.delivery_refusal(world)

static func personal_note(world) -> String:
	return Request.note(world)

# ── What the party can do ─────────────────────────────────────────────────────

static func skill_rank(world, skill_id: String) -> int:
	var own: int = int(world.player.capability.get_rank(skill_id)) if world.player.capability != null else 0
	var who := current(world)
	if who == "":
		return own
	return maxi(own, int((COMPANIONS[who].skills as Dictionary).get(skill_id, 0)))

# The same shape as CapabilityProfile.meets_requirements: skill clauses are met
# by the party, trait clauses only by the player (a companion's temperament is
# not yours).
static func meets(world, requirements: Variant) -> Dictionary:
	var own: Dictionary = world.player.capability.meets_requirements(requirements)
	if not own.success or own.met or current(world) == "":
		return own
	for clause in requirements.all:
		match String(clause.get("kind", "skill")):
			"skill":
				if skill_rank(world, String(clause.skill_id)) < int(clause.min_rank):
					return own
			_:
				var single: Dictionary = world.player.capability.meets_requirements({"all": [clause]})
				if not single.success or not single.met:
					return own
	return {"success": true, "met": true, "error": "", "by_companion": current(world)}

static func attack_bonus(world) -> int:
	var who := current(world)
	return int(COMPANIONS[who].damage_bonus) if who != "" else 0

# One line for the main screen.
static func summary(world) -> String:
	var who := current(world)
	if who == "":
		return ""
	var c: Dictionary = COMPANIONS[who]
	var cost := "路上每天多吃 %d 食物" % int(c.road_food)
	if int(c.road_water) > 0:
		cost = "路上每天多吃 %d 水 %d 食物" % [int(c.road_water), int(c.road_food)]
	if bool(c.finds_water):
		cost += "，但幫你們找水"
	return "同行：%s（%s）· %s" % [String(c.name_zh), String(c.role_zh), cost]
