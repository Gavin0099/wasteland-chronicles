extends RefCounted

# Public authored affiliations, not NPC membership or a second save-state ledger.
const FACTIONS := {
	"oasis": {"name": "綠洲同盟", "purpose": "水源、農作與補給互助", "towns": ["settlement:new_hope", "settlement:spring_ford"]},
	"forge": {"name": "熔爐協約", "purpose": "工坊、廢鐵與通道維護", "towns": ["settlement:gray_valley", "settlement:iron_pass"]},
	"free_wells": {"name": "自由井邦", "purpose": "獨立商旅與燃料交換", "towns": ["settlement:dry_well"]},
}
const TOWNS := {
	"settlement:new_hope": {"name": "新希望", "en": "New Hope", "flavour": "農業聚落 · 東部綠帶", "scene": "new_hope_scene.png", "faction": "oasis"},
	"settlement:gray_valley": {"name": "灰谷", "en": "Gray Valley", "flavour": "工業聚落 · 西部荒谷", "scene": "gray_valley_scene.png", "faction": "forge"},
	"settlement:dry_well": {"name": "乾井", "en": "Dry Well", "flavour": "燃料精煉鎮 · 南方乾原", "scene": "dry_well_scene.png", "faction": "free_wells"},
	"settlement:spring_ford": {"name": "泉渡", "en": "Spring Ford", "flavour": "河谷水糧站 · 綠帶渡口", "scene": "spring_ford_scene.png", "faction": "oasis"},
	"settlement:iron_pass": {"name": "鐵關", "en": "Iron Pass", "flavour": "金屬加工鎮 · 西部山口", "scene": "iron_pass_scene.png", "faction": "forge"},
}

static func town_name(town_id: String) -> String:
	return String(TOWNS.get(town_id, {}).get("name", town_id.trim_prefix("settlement:")))

static func faction_id(town_id: String) -> String:
	return String(TOWNS.get(town_id, {}).get("faction", ""))

static func faction_name(town_id: String) -> String:
	return String(FACTIONS.get(faction_id(town_id), {}).get("name", ""))
