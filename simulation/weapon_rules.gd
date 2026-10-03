extends RefCounted

# Fixed authored behavior. Neither Tier nor Quality appears in these formulas.
const Properties = preload("res://game_data/gear_property_profiles.gd")
const MELEE_BONUSES := {
	"rusted_knife": 1, "hunting_knife": 2, "rebar_club": 2,
	"scrap_machete": 3, "old_world_saber": 5,
	"sledgehammer": 4, "combat_knife": 3, "reinforced_saber": 4,
}
const FIREARMS := {
	"old_revolver": {"damage": 6, "ammo_item_id": "revolver_round", "ammo_spent": 1},
	"police_revolver": {"damage": 7, "ammo_item_id": "revolver_round", "ammo_spent": 1},
	"short_shotgun": {"damage": 10, "ammo_item_id": "shotgun_shell", "ammo_spent": 1},
}

static func firearm(id: Variant) -> Dictionary:
	if typeof(id) != TYPE_STRING:
		return {}
	id = Properties.base_item(id)
	if not FIREARMS.has(id):
		return {}
	return FIREARMS[id].duplicate(true)
