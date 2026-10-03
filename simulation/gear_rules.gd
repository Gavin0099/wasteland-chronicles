extends RefCounted

# GEAR-2C: closed, authored behavior. Tier and Quality never grant stats.
const PROTECTION := {"thick_cloth_coat": 0, "leather_jacket": 1, "reinforced_leather_jacket": 2, "ballistic_vest": 3}
const PACK_CARGO := {"travel_backpack": 8, "reinforced_travel_backpack": 10, "military_backpack": 12}
const MECHANICAL_TOOLS := {"wrench": 1, "repair_toolbox": 2, "precision_repair_kit": 3}
const ELECTRONIC_TOOLS := {"simple_meter": 1, "electronic_repair_kit": 2, "military_electronic_tools": 3}
const METHOD_TOOLS := {
	"OPEN_ARMORY": ["MECHANICS", 2], "BRIDGE_ARMORY": ["ELECTRONICS", 1],
	"CALIBRATE_ARMORY": ["ELECTRONICS", 3], "REPAIR_PUMP": ["MECHANICS", 1],
	"OVERHAUL_PUMP": ["MECHANICS", 3], "REWIRE_PUMP": ["ELECTRONICS", 2],
}

static func protection(player) -> int:
	return int(PROTECTION.get(player.equipment.equipped_item("body"), 0))

static func cargo_bonus(player) -> int:
	return int(PACK_CARGO.get(player.equipment.equipped_item("back"), 0)) - (3 if player.equipment.equipped_item("body") == "ballistic_vest" else 0)

static func defeat_water_loss(player) -> int:
	return 1 if player.equipment.equipped_item("back") == "reinforced_travel_backpack" else 2

static func best_tool(player, skill: String) -> String:
	var tools: Dictionary = MECHANICAL_TOOLS if skill == "MECHANICS" else (ELECTRONIC_TOOLS if skill == "ELECTRONICS" else {})
	var best := ""
	var grade := 0
	for id: String in tools:
		if player.item_inventory.contains(id) and int(tools[id]) > grade:
			best = id
			grade = int(tools[id])
	return best

static func tool_grade(player, skill: String) -> int:
	var tools: Dictionary = MECHANICAL_TOOLS if skill == "MECHANICS" else (ELECTRONIC_TOOLS if skill == "ELECTRONICS" else {})
	return int(tools.get(best_tool(player, skill), 0))

static func method_refusal(player, method: String) -> String:
	if method == "SLIP_PAST" and player.equipment.equipped_item("body") == "ballistic_vest":
		return "ARMOR_BLOCKS_STEALTH: ballistic vest must be removed before sneaking"
	if METHOD_TOOLS.has(method):
		var requirement: Array = METHOD_TOOLS[method]
		if tool_grade(player, String(requirement[0])) < int(requirement[1]):
			return "TOOL_REQUIRED: %s needs %s physical tool grade %d" % [method, requirement[0], requirement[1]]
	return ""
