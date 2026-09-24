class_name PerkCatalogue
extends RefCounted

# S5-C4 first milestone. Quest XP is lifetime experience; practice never adds it.
# Thresholds grow by five XP per level: 0, 20, 45, 75, 110 ...
const PERKS := {
	"CAREFUL_SALVAGER": {"name_zh": "細心拾荒者", "description_zh": "翻覆貨車可選擇花一天仔細分類，保底找到 1 份廢料；這種做法找不到密封貨箱。"},
	"ROAD_RUNNER": {"name_zh": "商路熟手", "description_zh": "遇到路障時能沿已知的繞行路線快速通過，不付過路費，也不延誤。"},
}

static func level_for_xp(xp: int) -> int:
	var level := 1
	while level < 100 and xp >= xp_for_level(level + 1):
		level += 1
	return level

static func xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return 5 * (level - 1) * (level + 6) / 2

static func available_slots(level: int) -> int:
	return 1 if level >= 3 else 0

static func validate_selection(raw: Variant, xp: int) -> String:
	if typeof(raw) != TYPE_ARRAY or raw.size() > available_slots(level_for_xp(xp)):
		return "INVALID_PERK_COUNT"
	var previous := ""
	for id in raw:
		if typeof(id) != TYPE_STRING or not PERKS.has(id) or (previous != "" and id <= previous):
			return "INVALID_PERK_ID_OR_ORDER"
		previous = id
	return ""

static func choices() -> Array:
	var ids := PERKS.keys()
	ids.sort()
	var rows: Array = []
	for id in ids:
		rows.append({"id": id, "name_zh": PERKS[id].name_zh, "description_zh": PERKS[id].description_zh})
	return rows
