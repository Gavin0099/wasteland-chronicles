extends RefCounted

# GEAR-2C: closed, authored behavior. Tier and Quality never grant stats.
const Properties = preload("res://game_data/gear_property_profiles.gd")
const PROTECTION := {"thick_cloth_coat": 0, "leather_jacket": 1, "reinforced_leather_jacket": 2, "ballistic_vest": 3}
const PACK_CARGO := {"travel_backpack": 8, "reinforced_travel_backpack": 10, "military_backpack": 12}
const MECHANICAL_TOOLS := {"wrench": 1, "repair_toolbox": 2, "precision_repair_kit": 3, "fieldrepair_precision_kit": 3, "precision_repair_toolbox": 2}
const ELECTRONIC_TOOLS := {"simple_meter": 1, "electronic_repair_kit": 2, "military_electronic_tools": 3}
const METHOD_TOOLS := {
	"OPEN_ARMORY": ["MECHANICS", 2], "BRIDGE_ARMORY": ["ELECTRONICS", 1],
	"CALIBRATE_ARMORY": ["ELECTRONICS", 3], "REPAIR_PUMP": ["MECHANICS", 1],
	"OVERHAUL_PUMP": ["MECHANICS", 3], "REWIRE_PUMP": ["ELECTRONICS", 2],
}

static func protection(player) -> int:
	var id: String = player.equipment.equipped_item("body")
	return int(PROTECTION.get(Properties.base_item(id), 0)) + (1 if Properties.has(id, "plated") else 0)

static func cargo_bonus(player) -> int:
	var body: String = player.equipment.equipped_item("body")
	var penalty: int = (1 if Properties.has(body, "lightweight") else 3) if Properties.base_item(body) == "ballistic_vest" else 0
	return int(PACK_CARGO.get(Properties.base_item(player.equipment.equipped_item("back")), 0)) - penalty

static func defeat_water_loss(player) -> int:
	return 1 if Properties.base_item(player.equipment.equipped_item("back")) == "reinforced_travel_backpack" else 2

static func best_tool(player, skill: String) -> String:
	var tools: Dictionary = MECHANICAL_TOOLS if skill == "MECHANICS" else (ELECTRONIC_TOOLS if skill == "ELECTRONICS" else {})
	var best := ""
	var grade := 0
	for id: String in tools:
		var candidate_grade: int = grade_for(id, skill)
		if player.item_inventory.contains(id) and (candidate_grade > grade or (candidate_grade == grade and Properties.has(id, "field_repair"))):
			best = id
			grade = candidate_grade
	return best

static func tool_grade(player, skill: String) -> int:
	return grade_for(best_tool(player, skill), skill)

static func grade_for(id: String, skill: String) -> int:
	var tools: Dictionary = MECHANICAL_TOOLS if skill == "MECHANICS" else (ELECTRONIC_TOOLS if skill == "ELECTRONICS" else {})
	return int(tools.get(id, 0)) + (1 if skill == "MECHANICS" and Properties.has(id, "precision_set") else 0)

static func method_refusal(player, method: String) -> String:
	if method == "SLIP_PAST" and Properties.base_item(player.equipment.equipped_item("body")) == "ballistic_vest":
		return "ARMOR_BLOCKS_STEALTH: ballistic vest must be removed before sneaking"
	if METHOD_TOOLS.has(method):
		var requirement: Array = METHOD_TOOLS[method]
		if tool_grade(player, String(requirement[0])) < int(requirement[1]):
			return "TOOL_REQUIRED: %s needs %s physical tool grade %d" % [method, requirement[0], requirement[1]]
	return ""
