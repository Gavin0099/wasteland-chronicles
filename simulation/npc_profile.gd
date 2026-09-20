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

enum Background {
	CARAVAN_GUARD = 0,  # 前商隊守衛
	MECHANIC      = 1,  # 機械師
	FARMER        = 2,  # 農夫
	SCAVENGER     = 3,  # 拾荒者
}

var npc_id: StringName = &""
var background: Background = Background.FARMER

# Closed enum membership test. Any value outside this set is rejected fail-closed.
static func is_valid_background(value: int) -> bool:
	return value in Background.values()

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
	return copy

func to_dict() -> Dictionary:
	return {
		"npc_id": String(npc_id),
		"background": background,
	}

static func from_dict(data: Dictionary) -> NpcProfile:
	var p := NpcProfile.new()
	p.npc_id = StringName(data.get("npc_id", ""))
	p.background = int(data.get("background", Background.FARMER)) as Background
	return p
