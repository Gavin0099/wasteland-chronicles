class_name EnemyCatalogue
extends RefCounted

# ==============================================================================
# PLAY-4: THREE ENEMIES THAT FIGHT DIFFERENTLY
# ==============================================================================
# Hand-play, twice: "敵人只有一種 是狼" and then "戰鬥畫面還是有點死板". The
# second was not really a picture problem. One enemy with one damage pattern
# means every fight is ATTACK until something falls over, and no amount of
# animation fixes that.
#
# THE HARD GATE THE OWNER SET: three enemies must not be three health bars.
#
#   狗   HP 6  fast, steady, no wind-up, nothing to say
#   劫匪 HP 8  a person: ordinary rhythm, and you could have paid or talked
#   重裝 HP 16 slow but telegraphs a hammer blow you can see coming
#
# So the difference lives in the PATTERN, not in the numbers alone. With only
# ATTACK and DEFEND the dog is "kill it before it chews through you", the
# bandit is "was this fight even worth it", and the raider is "he is winding
# up - do I spend this turn bracing or gamble on out-damaging him".
#
# STILL DETERMINISTIC. A turn's action is a pure function of the enemy and the
# turn number, so replay stays exact and a telegraph is a promise the game
# actually keeps rather than a bluff the RNG might not honour.
#
# NOT HERE, deliberately: loot tables, enemy AI, status effects, criticals,
# action points, or a move list. PLAY-4 is the smallest thing that answers
# "do I change how I fight, and will I come back for the one I ran from".
# ==============================================================================

const FERAL_DOG := "feral_dog"
const BANDIT := "bandit"
const HEAVY_RAIDER := "heavy_raider"
const DEFAULT_ENEMY := FERAL_DOG

# Bracing takes a turn of damage off. A telegraphed blow is the one worth
# bracing for, so bracing against it is worth appreciably more than usual -
# otherwise DEFEND is never the right answer and the choice is decorative.
const BRACE_REDUCTION := 3
const BRACE_REDUCTION_HEAVY := 7

const ENEMIES := {
	FERAL_DOG: {
		"name_zh": "野犬",
		"hp": 6,
		"can_parley": false,
		"art": "feral_dog",
		"note_zh": "瘦但快，撲上來就不鬆口。談不了，也沒什麼好拿。",
	},
	BANDIT: {
		"name_zh": "荒原劫匪",
		"hp": 8,
		"can_parley": true,
		"art": "bandit",
		"note_zh": "一個要錢的人。打得下去，也談得下來。",
	},
	HEAVY_RAIDER: {
		"name_zh": "重裝掠奪者",
		"hp": 16,
		"can_parley": false,
		"art": "heavy_raider",
		"note_zh": "披著焊死的廢鐵板，動作慢，但鐵鎚砸下來能要人命。",
	},
}

static func exists(enemy_id: Variant) -> bool:
	return typeof(enemy_id) == TYPE_STRING and ENEMIES.has(enemy_id)

static func resolve(enemy_id: Variant) -> Dictionary:
	if not exists(enemy_id):
		return ENEMIES[DEFAULT_ENEMY].duplicate(true)
	return ENEMIES[enemy_id].duplicate(true)

static func max_hp(enemy_id: Variant) -> int:
	return int(resolve(enemy_id).hp)

static func display_name(enemy_id: Variant) -> String:
	return String(resolve(enemy_id).name_zh)

# The largest health any enemy can have, used by the persistence bounds so a
# saved battle cannot claim a number no enemy could ever reach.
static func highest_hp() -> int:
	var top := 0
	for id in ENEMIES:
		top = maxi(top, int(ENEMIES[id].hp))
	return top

# ── Behaviour ─────────────────────────────────────────────────────────────────
#
# What this enemy does on this turn. Pure function of enemy and turn, so the
# telegraph below can promise it honestly.
#
#   damage  what it will deal before any bracing
#   heavy   worth spending a turn to brace against
static func action_for(enemy_id: Variant, turn: int) -> Dictionary:
	var safe_turn: int = maxi(1, turn)
	match String(enemy_id) if typeof(enemy_id) == TYPE_STRING else DEFAULT_ENEMY:
		FERAL_DOG:
			# No rhythm to read and no wind-up: it simply keeps biting. The
			# pressure is that it never lets up, so a wasted turn costs you.
			return {"damage": 3, "heavy": false}
		HEAVY_RAIDER:
			# Two ordinary swings, then the hammer. Slow enough to see coming,
			# and hard enough that seeing it matters.
			if safe_turn % 3 == 0:
				return {"damage": 9, "heavy": true}
			return {"damage": 3, "heavy": false}
		_:
			# The bandit keeps the rhythm road combat already had.
			return {"damage": 4 if safe_turn % 3 == 0 else 2, "heavy": false}

# What the player is told BEFORE choosing this turn's action. The telegraph is
# the whole reason DEFEND is a decision, so it has to name the coming blow
# plainly rather than hinting at it.
static func telegraph(enemy_id: Variant, turn: int) -> String:
	var action := action_for(enemy_id, turn)
	var name := display_name(enemy_id)
	if bool(action.heavy):
		return "%s高舉鐵鎚，整個人沉下去——下一擊將造成 %d 傷害。架住它，或是賭你能先把他放倒。" % [name, int(action.damage)]
	match String(enemy_id) if typeof(enemy_id) == TYPE_STRING else DEFAULT_ENEMY:
		FERAL_DOG:
			return "%s低伏著繞圈，沒有停下來的意思，將造成 %d 傷害。" % [name, int(action.damage)]
		HEAVY_RAIDER:
			return "%s拖著鐵鎚調整站位，將造成 %d 傷害。" % [name, int(action.damage)]
	return "%s準備揮砍，將造成 %d 傷害。" % [name, int(action.damage)]

# How much a braced turn actually saves against what is coming.
static func brace_reduction(enemy_id: Variant, turn: int) -> int:
	return BRACE_REDUCTION_HEAVY if bool(action_for(enemy_id, turn).heavy) else BRACE_REDUCTION
