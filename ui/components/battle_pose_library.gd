extends RefCounted

# Original generated PNGs remain intact. Rectangles/anchors are authored against
# their actual alpha silhouettes, rather than assuming a generated uniform grid.
const FRAMES := {
	"bandit": {
		"windup": [Rect2(113, 13, 448, 597), Vector2(430, 608), Vector2.ZERO, 485.0],
		"strike": [Rect2(649, 116, 565, 492), Vector2(1040, 606), Vector2.ZERO, 485.0],
		"hurt": [Rect2(44, 649, 525, 548), Vector2(420, 1195), Vector2.ZERO, 485.0],
		"fall": [Rect2(688, 937, 551, 270), Vector2(970, 1205), Vector2.ZERO, 485.0],
	},
	"drifter": {
		"windup": [Rect2(390, 12, 309, 570), Vector2(606, 580), Vector2(550, 40), 550.0],
		"strike": [Rect2(738, 61, 395, 522), Vector2(1000, 582), Vector2(1115, 160), 550.0],
		"aim": [Rect2(1129, 43, 295, 545), Vector2(1350, 585), Vector2(1390, 133), 550.0],
		"brace": [Rect2(42, 664, 258, 385), Vector2(235, 1046), Vector2(265, 783), 550.0],
		"hurt": [Rect2(384, 604, 300, 450), Vector2(610, 1051), Vector2(580, 650), 550.0],
		"kneel": [Rect2(735, 712, 301, 332), Vector2(945, 1042), Vector2(988, 990), 550.0],
		"fall": [Rect2(1063, 832, 369, 233), Vector2(1250, 1062), Vector2(1380, 945), 550.0],
	},
	"feral_dog": {
		"windup": [Rect2(17, 146, 528, 524), Vector2(295, 666), Vector2.ZERO, 520.0],
		"strike": [Rect2(531, 35, 576, 432), Vector2(830, 465), Vector2.ZERO, 520.0],
		"hurt": [Rect2(1111, 95, 484, 546), Vector2(1370, 638), Vector2.ZERO, 520.0],
		"fall": [Rect2(1618, 395, 537, 281), Vector2(1900, 673), Vector2.ZERO, 520.0],
	},
	"heavy_raider": {
		"windup": [Rect2(65, 8, 466, 664), Vector2(345, 668), Vector2.ZERO, 520.0],
		"strike": [Rect2(549, 149, 548, 524), Vector2(890, 670), Vector2.ZERO, 520.0],
		"hurt": [Rect2(1123, 138, 501, 538), Vector2(1380, 673), Vector2.ZERO, 520.0],
		"fall": [Rect2(1643, 367, 521, 342), Vector2(1890, 706), Vector2.ZERO, 520.0],
	},
}
const FILES := {"drifter": "drifter", "feral_dog": "feral-dog", "bandit": "road-bandit", "heavy_raider": "heavy-raider"}
static var atlases: Dictionary = {}
static var textures: Dictionary = {}

static func frame(actor_id: String, pose: String) -> Dictionary:
	var poses: Dictionary = FRAMES.get(actor_id, {})
	if not poses.has(pose):
		return {}
	var spec: Array = poses[pose]
	var key := actor_id + "/" + pose
	if not textures.has(key):
		if not atlases.has(actor_id):
			var bitmap := Image.load_from_file("res://ui/assets/combat/poses/%s-poses.png" % FILES[actor_id])
			if bitmap == null:
				return {}
			atlases[actor_id] = ImageTexture.create_from_image(bitmap)
		var texture := AtlasTexture.new()
		texture.atlas = atlases[actor_id]
		texture.region = spec[0]
		texture.filter_clip = true
		textures[key] = texture
	var region: Rect2 = spec[0]
	return {"texture": textures[key], "foot": (spec[1] - region.position) / region.size,
		"hand": (spec[2] - region.position) / region.size, "reference_height": spec[3]}

static func weapon_style(item_id: String) -> Dictionary:
	var base: String = preload("res://game_data/gear_property_profiles.gd").base_item(item_id)
	# Durations/swing angles are authored presentation values, never combat rules.
	match base:
		"sledgehammer": return {"name": "hammer", "windup": 0.24, "strike": 0.18, "recover": 0.26, "reach": 0.60, "angle": 0.80}
		"old_world_saber", "reinforced_saber": return {"name": "saber", "windup": 0.08, "strike": 0.10, "recover": 0.17, "reach": 0.62, "angle": 0.15}
		"scrap_machete": return {"name": "machete", "windup": 0.15, "strike": 0.12, "recover": 0.20, "reach": 0.54, "angle": 0.55}
		"old_revolver", "police_revolver": return {"name": "revolver", "windup": 0.16, "strike": 0.07, "recover": 0.15, "reach": 0.0, "angle": 0.0}
		"short_shotgun": return {"name": "shotgun", "windup": 0.25, "strike": 0.12, "recover": 0.23, "reach": 0.0, "angle": 0.0}
		_: return {"name": "crowbar", "windup": 0.12, "strike": 0.14, "recover": 0.18, "reach": 0.50, "angle": 0.30}
