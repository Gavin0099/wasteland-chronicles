class_name NpcProfile
extends RefCounted

# ==============================================================================
# S4-C: NPC PROFILE (BACKGROUND ONLY)
# ==============================================================================
# Records WHO this person USED TO BE, before the world named them.
#
# AUTHORITY CONTRACT (S4-C):
# - Background is BIOGRAPHY, not CAPABILITY.
# - It grants no stats, no skills, no occupation, no relationships,
#   and NO action authority whatsoever (see npc-authority.md §6: S4-C = NONE).
# - It must be bitwise-inert with respect to the aggregate simulation.
#
# DELIBERATE NON-FEATURES (do not "helpfully" add these):
# - No derived social_role / current role. CARAVAN_GUARD is a PAST occupation;
#   deriving a present-tense role here would create a second authority that
#   collides with the real occupation / party_role systems in later slices.
# - No eligible-action tags. Declaring MECHANIC → REPAIR would pre-define
#   S4-F capability semantics before gameplay verbs exist. Action eligibility
#   is decided in S4-F by then-validated verbs, not here.
# - No UNASSIGNED enum member. "Has no profile" and "background is UNASSIGNED"
#   are different statements; only the former exists.
# ==============================================================================

# S4-D: closed trait enum. These are DESCRIPTIONS of a person, not capabilities.
# Explicitly NOT implied by any of them:
#   CAUTIOUS      != flees automatically / lower risk exposure
#   LOYAL         != relationship bonus / less likely to leave a party
#   GREEDY        != trade bonus
#   AGGRESSIVE    != permission to attack / combat modifier
#   COMPASSIONATE != healing or morale effect
#   STUBBORN      != resistance to persuasion
# Whether a trait ever influences behavior is an S4-F question, to be answered
# against gameplay verbs that do not exist yet — not pre-empted here.
enum Trait {
	CAUTIOUS      = 0,
	LOYAL         = 1,
	GREEDY        = 2,
	AGGRESSIVE    = 3,
	COMPASSIONATE = 4,
	STUBBORN      = 5,
}

# S4-E: closed aptitude DOMAINS. Deliberately tag-only — no ratings, no stars,
# no HIGH/MEDIUM/LOW, no multipliers. "Mara has a TECHNICAL aptitude" currently
# means only that the world records a learning leaning; it carries no gameplay
# consequence whatsoever.
#
# WHY NOT A 1-5 RATING: there is no Skill Growth system yet, so there is no
# evidence about what an aptitude even IS — a multiplier, a growth curve, a cap,
# or something else. Writing "Technical 3" now would immediately raise "how much
# XP does 3 give?" and drag S4-E into S5-D. When S5-D defines real skills
# (Mechanics, Medicine, Rifle, Trade...), the growth model decides how TECHNICAL
# relates to Mechanics — not the other way round.
enum Aptitude {
	COMBAT    = 0,
	SURVIVAL  = 1,
	TRADE     = 2,
	TECHNICAL = 3,
	SOCIAL    = 4,
}

enum Background {
	CARAVAN_GUARD = 0,  # 前商隊守衛
	MECHANIC      = 1,  # 機械師
	FARMER        = 2,  # 農夫
	SCAVENGER     = 3,  # 拾荒者
}

var npc_id: StringName = &""
var background: Background = Background.FARMER

# Set-like metadata: no duplicates, and ALWAYS held in enum order so that the
# order traits were assigned in can never produce a different world.
var traits: Array[int] = []

# Set-like metadata, same discipline as traits.
var aptitudes: Array[int] = []

# Closed enum membership tests. Any value outside these sets is rejected fail-closed.
static func is_valid_background(value: int) -> bool:
	return value in Background.values()

static func is_valid_trait(value: int) -> bool:
	return value in Trait.values()

static func is_valid_aptitude(value: int) -> bool:
	return value in Aptitude.values()

static func aptitude_name(value: int) -> String:
	if not is_valid_aptitude(value):
		return "INVALID(%d)" % value
	return String(Aptitude.keys()[value])

static func trait_name(value: int) -> String:
	if not is_valid_trait(value):
		return "INVALID(%d)" % value
	return String(Trait.keys()[value])

# Canonical set order is enum order, so [LOYAL, CAUTIOUS] and [CAUTIOUS, LOYAL]
# serialize identically and cannot become two different worlds. Used for both
# traits and aptitudes.
static func canonical_traits(values: Array) -> Array[int]:
	var out: Array[int] = []
	for v in values:
		var i := int(v)
		if not out.has(i):
			out.append(i)
	out.sort()
	return out

# Display-only helper for logs and test output. Carries no authority and is
# never persisted — it is just the enum key spelled out.
static func background_name(value: int) -> String:
	if not is_valid_background(value):
		return "INVALID(%d)" % value
	return String(Background.keys()[value])

func duplicate_profile() -> NpcProfile:
	var copy := NpcProfile.new()
	copy.npc_id = npc_id
	copy.background = background
	copy.traits = traits.duplicate()
	copy.aptitudes = aptitudes.duplicate()
	return copy

func has_trait(value: int) -> bool:
	return traits.has(value)

func has_aptitude(value: int) -> bool:
	return aptitudes.has(value)

func to_dict() -> Dictionary:
	return {
		"npc_id": String(npc_id),
		"background": background,
		"traits": traits.duplicate(),
		"aptitudes": aptitudes.duplicate(),
	}

static func from_dict(data: Dictionary) -> NpcProfile:
	var p := NpcProfile.new()
	p.npc_id = StringName(data.get("npc_id", ""))
	p.background = int(data.get("background", Background.FARMER)) as Background
	p.traits = canonical_traits(data.get("traits", []))
	p.aptitudes = canonical_traits(data.get("aptitudes", []))
	return p
