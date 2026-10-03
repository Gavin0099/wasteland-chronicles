extends RefCounted

# Fixed authored variants; no rolled instance metadata or quality multiplier.
const VARIANTS := {
	"quickdraw_police_revolver": ["police_revolver", "T2", ["quick_draw"]],
	"heavyhead_sledgehammer": ["sledgehammer", "T1", ["heavy_head"]],
	"balanced_combat_knife": ["combat_knife", "T2", ["balanced"]],
	"toolloop_travel_backpack": ["travel_backpack", "T1", ["tool_loops"]],
	"waterpouch_travel_backpack": ["travel_backpack", "T1", ["water_pouch"]],
	"lightweight_ballistic_vest": ["ballistic_vest", "T3", ["lightweight"]],
	"plated_leather_jacket": ["reinforced_leather_jacket", "T2", ["plated"]],
	"fieldrepair_precision_kit": ["precision_repair_kit", "T3", ["field_repair"]],
	"precision_repair_toolbox": ["repair_toolbox", "T2", ["precision_set"]],
	"expedition_travel_backpack": ["travel_backpack", "T1", ["tool_loops", "water_pouch"]],
}
const DESCRIPTIONS := {
	"quick_draw": "快拔：第一回合射擊傷害 +2",
	"heavy_head": "重鎚頭：架勢後的下一次近戰傷害再 +1",
	"balanced": "平衡：近身攻擊時敵方反擊傷害 −1",
	"tool_loops": "工具環：裝備後最多 2 公斤實際工具免計正式物品負重",
	"water_pouch": "水袋：裝備後最多 2 水免計生存物資負重",
	"lightweight": "輕量：防彈背心容量代價 −3 改為 −1；仍限制潛行",
	"plated": "加甲：防護 +1；此件重量增加 500 克",
	"field_repair": "現地維修：使用這組機械工具修井泵少耗 1 廢料",
	"precision_set": "精密套件：工具箱等同機械工具 3；仍需機械 3 精修",
}

static func base_item(id: String) -> String:
	return String(VARIANTS[id][0]) if VARIANTS.has(id) else id

static func has(id: String, property: String) -> bool:
	return VARIANTS.has(id) and property in VARIANTS[id][2]

static func profile(id: String) -> Dictionary:
	if not VARIANTS.has(id):
		return {}
	return {"tier": VARIANTS[id][1], "quality": "RARE" if VARIANTS[id][2].size() == 2 else "MODIFIED", "properties": VARIANTS[id][2].duplicate(), "unique_effect": ""}
