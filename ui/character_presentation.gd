extends RefCounted

# Localized, read-only presentation. Packages and ranks come from authority.
const Catalogue = preload("res://simulation/background_catalogue.gd")
const Profile = preload("res://simulation/capability_profile.gd")
const Perks = preload("res://simulation/perk_catalogue.gd")
const Acquired = preload("res://simulation/acquired_traits.gd")
const SKILL_NAMES = {"BARTER": "交易", "ELECTRONICS": "電子", "FIREARMS": "槍械", "MECHANICS": "機械", "MEDICINE": "醫療", "MELEE": "近戰", "SCAVENGING": "搜刮", "SPEECH": "社交", "STEALTH": "潛行", "SURVIVAL": "荒野求生"}
const RANK_NAMES = ["外行", "略懂", "熟練", "專業", "專家", "大師"]
# One line on how each background actually plays. Copy only; the numbers above
# come from the authority.
const BACKGROUND_PLAYSTYLE = {
	"CARAVAN_GUARD": "打得動手的路線。近戰與槍械起步最高，但路上的遭遇多半不吃武力，前期選項最少。",
	"MECHANIC": "從殘骸裡榨東西出來。拆解與搜刮強，缺乏談判與求生手段。",
	"FARMER": "靠撐過去與談下來。求生與交易讓你少花錢、少死人，但拆不了東西。",
	"SCAVENGER": "撿得快、躲得掉。搜刮與潛行讓你不必正面處理麻煩，正面衝突時最弱。",
}
const BACKGROUNDS = {
	"CARAVAN_GUARD": ["商隊守衛", "你曾隨商隊巡守路線，保護沿途的貨物。"],
	"MECHANIC": ["聚落技工", "你曾替聚落維修機械與基礎設備。"],
	"FARMER": ["荒地農夫", "你曾在貧瘠土地耕作，維持聚落的日常補給。"],
	"SCAVENGER": ["廢墟拾荒者", "你曾穿梭廢墟，從遺落的物件中尋找生計。"]
}
const TRAITS = {
	"AGGRESSIVE": ["好鬥", "遇到衝突時，你傾向正面回應。"],
	"CAUTIOUS": ["謹慎", "遇到危險時，你傾向先觀察。"],
	"COMPASSIONATE": ["慈悲", "你在意陌生人的處境。"],
	"CURIOUS": ["好奇", "你想弄清楚未知事物。"],
	"GREEDY": ["貪財", "你很難放過眼前的利益。"],
	"IRON_STOMACH": ["鐵胃", "你向來不太挑剔飲食。"],
	"LIGHT_SLEEPER": ["淺眠", "你習慣留意夜裡的動靜。"],
	"LONER": ["獨行", "你更習慣獨自生活。"],
	"LOYAL": ["忠誠", "你看重承諾與同行的人。"],
	"PACIFIST": ["和平主義", "你傾向避免以暴力解決問題。"],
	"RECKLESS": ["魯莽", "你常常先行動，再考慮後果。"],
	"STUBBORN": ["固執", "你不輕易改變自己的決定。"],
	"SUSPICIOUS": ["多疑", "你不輕易相信陌生人的話。"],
	"VIGILANT": ["警覺", "你習慣留意周遭的變化。"]
}

const Encounter = preload("res://simulation/travel_encounter.gd")

# CHAR-INFO: what a Background or a Trait ACTUALLY does, derived from the
# encounter catalogue instead of written out by hand here.
#
# The catalogue is the only place a requirement is declared (S5-C2), and the
# engine re-reads it at commit time. If this screen described effects in its own
# prose, the description and the road would drift apart the first time an option
# was retuned - and the player would have chosen a character on a promise the
# world does not keep. So it is read back from the same declarations.
#
# SCOPE, stated honestly to the player as well: this covers roadside encounter
# approaches. Field combat, items and trade have their own rules and are not
# summarised here.
const ENCOUNTER_TYPES := [
	Encounter.WRECK, Encounter.ROCKSLIDE, Encounter.ROADBLOCK,
	Encounter.DEHYDRATED_TRAVELLER, Encounter.REFUGEE_COLUMN,
]

static func _approach(encounter_type: StringName, option: Dictionary) -> Dictionary:
	return {
		"encounter": Encounter.title(encounter_type),
		"label": String(option.get("label", "")),
		"detail": String(option.get("detail", "")),
		"gate": String(option.get("gate", "")),
		"requirement": String(option.get("requirement_label", "")),
	}

# Every roadside approach this trait, and only this trait, opens.
static func trait_unlocks(trait_id: String) -> Array:
	var out: Array = []
	for t in ENCOUNTER_TYPES:
		for o in Encounter.options(t):
			for clause in (o.get("requires", {}) as Dictionary).get("all", []):
				if String(clause.get("kind", "")) == "trait_present" and String(clause.get("trait_id", "")) == trait_id:
					out.append(_approach(t, o))
	return out

# Split the roadside approaches into what these starting ranks can already take
# and what they cannot yet. The second list is the point: seeing the locked door
# is how a player learns which skill is worth raising.
static func rank_approaches(ranks: Dictionary) -> Dictionary:
	var open_list: Array = []
	var locked: Array = []
	for t in ENCOUNTER_TYPES:
		for o in Encounter.options(t):
			var clauses: Array = (o.get("requires", {}) as Dictionary).get("all", [])
			var skill_clauses: Array = []
			var trait_gated := false
			for clause in clauses:
				match String(clause.get("kind", "")):
					"skill": skill_clauses.append(clause)
					"trait_present", "trait_absent": trait_gated = true
			if trait_gated or skill_clauses.is_empty():
				continue
			var met := true
			for clause in skill_clauses:
				if int(ranks.get(String(clause.get("skill_id", "")), 0)) < int(clause.get("min_rank", 0)):
					met = false
					break
			if met:
				open_list.append(_approach(t, o))
			else:
				locked.append(_approach(t, o))
	return {"open": open_list, "locked": locked}

static func _approach_lines(approaches: Array) -> PackedStringArray:
	var lines := PackedStringArray()
	for a in approaches:
		var req := String(a.requirement)
		if req != "":
			lines.append("· %s：%s（需要 %s）" % [a.encounter, a.label, req])
		else:
			lines.append("· %s：%s" % [a.encounter, a.label])
	return lines

# The plain-language case for a Background: what it is good at, what it opens on
# the road, and what it gives up. The tradeoff is stated because a background
# with no cost is not a choice.
static func background_effect_text(background_id: String, ranks: Dictionary) -> String:
	var split := rank_approaches(ranks)
	var blocks := PackedStringArray()

	var strengths := PackedStringArray()
	for skill in Profile.SKILLS:
		var rank: int = int(ranks.get(skill, 0))
		if rank > 0:
			strengths.append("%s +%d" % [SKILL_NAMES[skill], rank])
	blocks.append("起始加成　%s" % ("、".join(strengths) if not strengths.is_empty() else "無"))

	if BACKGROUND_PLAYSTYLE.has(background_id):
		blocks.append("玩法　%s" % BACKGROUND_PLAYSTYLE[background_id])

	var open_lines := _approach_lines(split.open)
	blocks.append("路上已經做得到
%s" % ("
".join(open_lines) if not open_lines.is_empty() else "· 只剩人人都能選的選項"))

	var locked_lines := _approach_lines(split.locked)
	if not locked_lines.is_empty():
		blocks.append("代價：這些還做不到
%s" % "
".join(locked_lines))

	blocks.append("（以上只涵蓋路上的遭遇。戰鬥、物品與交易另有規則。）")
	return "
".join(blocks)

# What a Trait does, and — just as important — when it does nothing yet.
static func trait_effect_text(trait_id: String) -> String:
	if not TRAITS.has(trait_id):
		return ""
	var unlocks := trait_unlocks(trait_id)
	if unlocks.is_empty():
		return "%s　%s
效果　目前只影響敘事，還沒有專屬的遭遇選項。" % [TRAITS[trait_id][0], TRAITS[trait_id][1]]
	var lines := PackedStringArray()
	for a in unlocks:
		lines.append("· %s：%s　—　%s" % [a.encounter, a.label, a.detail])
	return "%s　%s
只有你想得到的做法
%s" % [TRAITS[trait_id][0], TRAITS[trait_id][1], "
".join(lines)]

static func project(world: WorldState) -> Dictionary:
	if world.player == null:
		return {}
	var identity: NpcIdentity = world.npc_registry.get_npc(world.player.npc_id)
	var data: Dictionary = world.player.capability.to_dict()
	var practice := {}
	for skill in Profile.SKILLS:
		var progress: Dictionary = world.player.capability.get_practice_progress(skill)
		if progress.success:
			practice[skill] = {"points": progress.points, "required": progress.required}
	return {"name": identity.name, "age": identity.age_at_materialization,
		"field_kit": world.player.field_kit.duplicate(true),
		"background_id": data.background_id, "traits": data.selected_creation_traits,
		"ranks": data.skill_ranks, "practice": practice,
		"level": world.player.level(), "xp": world.player.xp,
		"next_level_xp": Perks.xp_for_level(world.player.level() + 1),
		"perks": world.player.perk_ids.duplicate(),
		"perk_choices": Perks.choices() if world.player.perk_ids.size() < Perks.available_slots(world.player.level()) else [],
		"acquired_traits": world.player.acquired_trait_ids.duplicate(),
		"acquired_candidates": Acquired.candidates(world.event_log, world.player.npc_id, world.current_day).filter(func(id: String) -> bool: return not world.player.has_acquired_trait(id)),
		"legacy": data.creation_origin == "LEGACY_MIGRATION"}

static func background_name(id: String) -> String:
	return BACKGROUNDS[id][0] if BACKGROUNDS.has(id) else "舊有角色（未套用創角背景）"

static func trait_text(ids: Array) -> String:
	var names := PackedStringArray()
	for id in ids:
		names.append(TRAITS[id][0])
	return "、".join(names) if not names.is_empty() else "未選擇"

static func skill_text(ranks: Dictionary) -> String:
	var lines := PackedStringArray()
	for id in Profile.SKILLS:
		var rank: int = ranks[id]
		lines.append("%s    %s%s    %d  %s" % [SKILL_NAMES[id], "■".repeat(rank), "□".repeat(5 - rank), rank, RANK_NAMES[rank]])
	return "\n".join(lines)

# CHAR-INFO: the creation preview used to print all ten skills, seven of which
# are always "0 外行" for a 2/1/1 package. Those seven rows carried no
# information and pushed everything that did below the fold. The full ten-row
# list still belongs on the in-game character sheet, where ranks change; here
# only what the background actually granted is worth the space.
static func starting_skill_text(ranks: Dictionary) -> String:
	var lines := PackedStringArray()
	var untrained := PackedStringArray()
	for id in Profile.SKILLS:
		var rank: int = int(ranks.get(id, 0))
		if rank > 0:
			lines.append("%s    %s%s    %d  %s" % [SKILL_NAMES[id], "■".repeat(rank), "□".repeat(5 - rank), rank, RANK_NAMES[rank]])
		else:
			untrained.append(SKILL_NAMES[id])
	if not untrained.is_empty():
		lines.append("其餘 %d 項　外行（0）：%s" % [untrained.size(), "、".join(untrained)])
	return "\n".join(lines)

static func summary_text(data: Dictionary) -> String:
	return "%s · %d 歲\n\n背景　%s\n特質　%s\n\n能力\n%s" % [data.name, data.age, background_name(data.background_id), trait_text(data.traits), skill_text(data.ranks)]

static func creation_summary(data: Dictionary) -> String:
	var strengths := PackedStringArray()
	for skill in Profile.SKILLS:
		if data.ranks[skill] > 0:
			strengths.append("%s　%d  %s" % [SKILL_NAMES[skill], data.ranks[skill], RANK_NAMES[data.ranks[skill]]])
	return "%s · %d 歲\n\n背景　%s\n特質　%s\n\n較擅長\n%s" % [data.name, data.age, background_name(data.background_id), trait_text(data.traits), "\n".join(strengths)]
