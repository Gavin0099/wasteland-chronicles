extends RefCounted

# Existing items only. Crowbar is the legacy field-kit item, not a new formal
# inventory entry. Quality/effect labels describe existing behavior only.
const TIERS := {
	"crowbar": "T1", "rusted_knife": "T1", "hunting_knife": "T2",
	"rebar_club": "T1", "scrap_machete": "T2", "old_revolver": "T1",
	"old_world_saber": "T4", "work_clothes": "T1", "desert_robe": "T1",
	"caravan_coat": "T2", "travel_backpack": "T1", "military_backpack": "T3",
	"rope": "T1", "flashlight": "T1", "wrench": "T1",
	"first_aid_kit": "T1", "revolver_round": "T1",
}

static func resolve(id: Variant) -> Dictionary:
	if typeof(id) != TYPE_STRING or not TIERS.has(id):
		return {}
	return {"tier": TIERS[id], "quality": "UNIQUE" if id == "old_world_saber" else "COMMON",
		"properties": [], "unique_effect": "old_world_edge" if id == "old_world_saber" else ""}
