class_name BackgroundCatalogue
extends RefCounted

const Profile = preload("res://simulation/capability_profile.gd")
const VERSION := 1
# Owner-approved C0-P0 table; no enum reordering and no inferred packages.
const PACKAGES := {
	"CARAVAN_GUARD": ["FIREARMS", "MELEE", "SURVIVAL"],
	"MECHANIC": ["MECHANICS", "ELECTRONICS", "SCAVENGING"],
	"FARMER": ["SURVIVAL", "MECHANICS", "BARTER"],
	"SCAVENGER": ["SCAVENGING", "SURVIVAL", "STEALTH"],
}

static func resolve(background_id: Variant) -> Dictionary:
	if typeof(background_id) != TYPE_STRING or not PACKAGES.has(background_id):
		return {"success": false, "error": "UNKNOWN_BACKGROUND_PACKAGE"}
	var skills: Array = PACKAGES[background_id]
	var ranks := {}
	for skill in Profile.SKILLS:
		ranks[skill] = 0
	for i in range(3):
		ranks[skills[i]] = 2 if i == 0 else 1
	return {"success": true, "ranks": ranks, "background": NpcProfile.Background.get(background_id), "version": VERSION, "error": ""}
