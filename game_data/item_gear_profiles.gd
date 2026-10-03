extends RefCounted

# Existing items only. Crowbar is the legacy field-kit item, not a new formal
# inventory entry. Quality/effect labels describe existing behavior only.
const Properties = preload("res://game_data/gear_property_profiles.gd")
const TIERS := {
	"thick_cloth_coat": "T1",
	"leather_jacket": "T1",
	"reinforced_leather_jacket": "T2",
	"ballistic_vest": "T3",
	"reinforced_travel_backpack": "T2",
	"repair_toolbox": "T2",
	"precision_repair_kit": "T3",
	"simple_meter": "T1",
	"electronic_repair_kit": "T2",
	"military_electronic_tools": "T3",
	"sledgehammer": "T1", "combat_knife": "T2", "reinforced_saber": "T3",
	"police_revolver": "T2", "short_shotgun": "T2", "shotgun_shell": "T1",
	"crowbar": "T1", "rusted_knife": "T1", "hunting_knife": "T2",
	"rebar_club": "T1", "scrap_machete": "T2", "old_revolver": "T1",
	"old_world_saber": "T4", "work_clothes": "T1", "desert_robe": "T1",
	"caravan_coat": "T2", "travel_backpack": "T1", "military_backpack": "T3",
	"rope": "T1", "flashlight": "T1", "wrench": "T1",
	"first_aid_kit": "T1", "revolver_round": "T1",
}

static func resolve(id: Variant) -> Dictionary:
	if typeof(id) != TYPE_STRING:
		return {}
	if Properties.VARIANTS.has(id):
		return Properties.profile(id)
	if not TIERS.has(id):
		return {}
	return {"tier": TIERS[id], "quality": "UNIQUE" if id == "old_world_saber" else "COMMON",
		"properties": [], "unique_effect": "old_world_edge" if id == "old_world_saber" else ""}
