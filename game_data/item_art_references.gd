class_name ItemArtReferences
extends RefCounted

# Explicit asset IDs, independent of gameplay categories and the 185-name art
# index. These references do not register items in UI, ownership or loot tables.
static func resolve(asset_id: Variant) -> Dictionary:
	var paths := {
		"item_military_gas_mask": "res://ui/assets/items/library/clothing/gas_mask.png",
		"item_engineer_precision_tools": "res://ui/assets/items/library/supplies/welding_tools.png",
		"item_thick_cloth_coat": "res://ui/assets/items/library/clothing/worker_leather_jacket.png",
		"item_leather_jacket": "res://ui/assets/items/library/clothing/motorcycle_jacket.png",
		"item_reinforced_leather_jacket": "res://ui/assets/items/library/clothing/stab_vest.png",
		"item_ballistic_vest": "res://ui/assets/items/library/clothing/police_ballistic_vest.png",
		"item_reinforced_travel_backpack": "res://ui/assets/items/library/clothing/hiking_backpack.png",
		"item_repair_toolbox": "res://ui/assets/items/library/supplies/toolbox.png",
		"item_precision_repair_kit": "res://ui/assets/items/library/supplies/welding_tools.png",
		"item_simple_meter": "res://ui/assets/items/library/supplies/multimeter.png",
		"item_electronic_repair_kit": "res://ui/assets/items/library/supplies/toolbox.png",
		"item_military_electronic_tools": "res://ui/assets/items/library/supplies/signal_receiver.png",
		"item_sledgehammer": "res://ui/assets/items/sledgehammer.png",
		"item_combat_knife": "res://ui/assets/items/candidates/hunting_knife.png",
		"item_reinforced_saber": "res://ui/assets/items/library/weapons/desert_sabre.png",
		"item_police_revolver": "res://ui/assets/items/library/weapons/heavy_revolver.png",
		"item_short_shotgun": "res://ui/assets/items/library/weapons/double_barrel_shotgun.png",
		"item_shotgun_shell": "res://ui/assets/items/shotgun_shell.svg",
		"item_old_revolver": "res://ui/assets/items/library/weapons/old_revolver.png",
		"item_revolver_round": "res://ui/assets/items/revolver_round.svg",
		"item_rusted_knife": "res://ui/assets/items/candidates/rusty_knife.png",
		"item_hunting_knife": "res://ui/assets/items/candidates/hunting_knife.png",
		"item_rebar_club": "res://ui/assets/items/candidates/rebar_club.png",
		"item_scrap_machete": "res://ui/assets/items/candidates/scrap_machete.png",
		"item_work_clothes": "res://ui/assets/items/candidates/work_clothes.png",
		"item_desert_robe": "res://ui/assets/items/candidates/desert_robe.png",
		"item_caravan_coat": "res://ui/assets/items/candidates/caravan_coat.png",
		"item_travel_backpack": "res://ui/assets/items/candidates/travel_backpack.png",
		"item_military_backpack": "res://ui/assets/items/library/clothing/military_backpack.png",
		"item_old_world_saber": "res://ui/assets/items/library/weapons/desert_sabre.png",
		"item_rope": "res://ui/assets/items/candidates/rope.png",
		"item_flashlight": "res://ui/assets/items/candidates/flashlight.png",
		"item_wrench": "res://ui/assets/items/candidates/wrench.png",
		"item_first_aid_kit": "res://ui/assets/items/candidates/medkit.png",
	}
	if typeof(asset_id) != TYPE_STRING or not paths.has(asset_id):
		return {"success": false, "path": "", "error": "UNKNOWN_ITEM_ASSET"}
	return {"success": true, "path": paths[asset_id], "error": ""}
