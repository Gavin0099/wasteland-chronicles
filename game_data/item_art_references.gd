class_name ItemArtReferences
extends RefCounted

# Explicit asset IDs, independent of gameplay categories and the 185-name art
# index. These references do not register items in UI, ownership or loot tables.
static func resolve(asset_id: Variant) -> Dictionary:
	var paths := {
		"item_rusted_knife": "res://ui/assets/items/candidates/rusty_knife.png",
		"item_hunting_knife": "res://ui/assets/items/candidates/hunting_knife.png",
		"item_rebar_club": "res://ui/assets/items/candidates/rebar_club.png",
		"item_scrap_machete": "res://ui/assets/items/candidates/scrap_machete.png",
		"item_work_clothes": "res://ui/assets/items/candidates/work_clothes.png",
		"item_desert_robe": "res://ui/assets/items/candidates/desert_robe.png",
		"item_caravan_coat": "res://ui/assets/items/candidates/caravan_coat.png",
		"item_travel_backpack": "res://ui/assets/items/candidates/travel_backpack.png",
		"item_rope": "res://ui/assets/items/candidates/rope.png",
		"item_flashlight": "res://ui/assets/items/candidates/flashlight.png",
		"item_wrench": "res://ui/assets/items/candidates/wrench.png",
		"item_first_aid_kit": "res://ui/assets/items/candidates/medkit.png",
	}
	if typeof(asset_id) != TYPE_STRING or not paths.has(asset_id):
		return {"success": false, "path": "", "error": "UNKNOWN_ITEM_ASSET"}
	return {"success": true, "path": paths[asset_id], "error": ""}
