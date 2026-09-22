extends RefCounted

# Localized, read-only presentation. Packages and ranks come from authority.
const Catalogue = preload("res://simulation/background_catalogue.gd")
const Profile = preload("res://simulation/capability_profile.gd")
const SKILL_NAMES = {"BARTER": "交易", "ELECTRONICS": "電子", "FIREARMS": "槍械", "MECHANICS": "機械", "MEDICINE": "醫療", "MELEE": "近戰", "SCAVENGING": "搜刮", "SPEECH": "社交", "STEALTH": "潛行", "SURVIVAL": "荒野求生"}
const RANK_NAMES = ["外行", "略懂", "熟練", "專業", "專家", "大師"]
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

static func project(world: WorldState) -> Dictionary:
	if world.player == null:
		return {}
	var identity: NpcIdentity = world.npc_registry.get_npc(world.player.npc_id)
	var data: Dictionary = world.player.capability.to_dict()
	return {"name": identity.name, "age": identity.age_at_materialization,
		"field_kit": world.player.field_kit.duplicate(true),
		"background_id": data.background_id, "traits": data.selected_creation_traits,
		"ranks": data.skill_ranks, "legacy": data.creation_origin == "LEGACY_MIGRATION"}

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

static func summary_text(data: Dictionary) -> String:
	return "%s · %d 歲\n\n背景　%s\n特質　%s\n\n能力\n%s" % [data.name, data.age, background_name(data.background_id), trait_text(data.traits), skill_text(data.ranks)]

static func creation_summary(data: Dictionary) -> String:
	var strengths := PackedStringArray()
	for skill in Profile.SKILLS:
		if data.ranks[skill] > 0:
			strengths.append("%s　%d  %s" % [SKILL_NAMES[skill], data.ranks[skill], RANK_NAMES[data.ranks[skill]]])
	return "%s · %d 歲\n\n背景　%s\n特質　%s\n\n較擅長\n%s" % [data.name, data.age, background_name(data.background_id), trait_text(data.traits), "\n".join(strengths)]
