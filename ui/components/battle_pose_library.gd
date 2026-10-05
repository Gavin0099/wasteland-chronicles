extends RefCounted

# Original generated PNGs remain intact. Rectangles/anchors are authored against
# their actual alpha silhouettes, rather than assuming a generated uniform grid.
const FRAMES := {
	"grey_crow": {
		"armed": [Rect2(123, 13, 324, 495), Vector2(191, 502), Vector2.ZERO, 485.0, "grey-crow-capture"],
		"windup": [Rect2(595, 13, 355, 495), Vector2(674, 502), Vector2.ZERO, 485.0, "grey-crow-capture"],
		"strike": [Rect2(1030, 62, 408, 446), Vector2(1246, 502), Vector2.ZERO, 485.0, "grey-crow-capture"],
		"unarmed": [Rect2(139, 512, 309, 487), Vector2(190, 994), Vector2.ZERO, 485.0, "grey-crow-capture"],
		"hurt": [Rect2(628, 519, 318, 477), Vector2(672, 992), Vector2.ZERO, 485.0, "grey-crow-capture"],
		"kneel": [Rect2(1174, 613, 255, 347), Vector2(1305, 956), Vector2.ZERO, 485.0, "grey-crow-capture"],
		"fall": [Rect2(70, 280, 1410, 532), Vector2(760, 790), Vector2.ZERO, 1380.0, "grey-crow-aftermath"],
	},
	"bandit": {
		"idle_breath": [Rect2(59, 47, 412, 465), Vector2(425, 506), Vector2.ZERO, 450.0, "road-bandit-movement"],
		"step_a": [Rect2(540, 49, 433, 458), Vector2(660, 501), Vector2.ZERO, 450.0, "road-bandit-movement"],
		"step_b": [Rect2(1053, 60, 434, 443), Vector2(1220, 497), Vector2.ZERO, 450.0, "road-bandit-movement"],
		"recover": [Rect2(54, 549, 411, 433), Vector2(418, 976), Vector2.ZERO, 450.0, "road-bandit-movement"],
		"kneel": [Rect2(532, 635, 455, 345), Vector2(761, 974), Vector2.ZERO, 450.0, "road-bandit-movement"],
		"settle": [Rect2(1106, 535, 383, 445), Vector2(1275, 974), Vector2.ZERO, 450.0, "road-bandit-movement"],
		"windup": [Rect2(113, 13, 448, 597), Vector2(430, 608), Vector2.ZERO, 485.0],
		"strike": [Rect2(649, 116, 565, 492), Vector2(1040, 606), Vector2.ZERO, 485.0],
		"hurt": [Rect2(44, 649, 525, 548), Vector2(420, 1195), Vector2.ZERO, 485.0],
		"fall": [Rect2(688, 937, 551, 270), Vector2(970, 1205), Vector2.ZERO, 485.0],
	},
	"drifter": {
		"idle_breath": [Rect2(184, 35, 247, 495), Vector2(370, 524), Vector2(409, 216), 480.0, "drifter-movement"],
		"step_a": [Rect2(609, 38, 309, 486), Vector2(863, 518), Vector2(892, 216), 480.0, "drifter-movement"],
		"step_b": [Rect2(1086, 39, 325, 488), Vector2(1355, 521), Vector2(1380, 210), 480.0, "drifter-movement"],
		"retreat_a": [Rect2(139, 548, 282, 457), Vector2(365, 999), Vector2(378, 682), 480.0, "drifter-movement"],
		"retreat_b": [Rect2(625, 547, 281, 458), Vector2(850, 999), Vector2(862, 680), 480.0, "drifter-movement"],
		"recover": [Rect2(1134, 542, 249, 466), Vector2(1325, 1002), Vector2(1360, 750), 480.0, "drifter-movement"],
		"slash_windup": [Rect2(113, 40, 322, 441), Vector2(306, 475), Vector2(198, 88), 430.0, "drifter-melee"],
		"slash_strike": [Rect2(621, 49, 358, 432), Vector2(865, 475), Vector2(958, 156), 430.0, "drifter-melee"],
		"slash_recover": [Rect2(1174, 55, 281, 429), Vector2(1360, 478), Vector2(1430, 278), 430.0, "drifter-melee"],
		"hammer_windup": [Rect2(117, 557, 312, 420), Vector2(379, 971), Vector2(174, 586), 430.0, "drifter-melee"],
		"hammer_strike": [Rect2(597, 590, 343, 384), Vector2(878, 968), Vector2(902, 785), 430.0, "drifter-melee"],
		"hammer_recover": [Rect2(1126, 602, 287, 367), Vector2(1350, 963), Vector2(1390, 827), 430.0, "drifter-melee"],
		"revolver_aim": [Rect2(122, 45, 308, 479), Vector2(316, 518), Vector2(410, 135), 460.0, "drifter-guns"],
		"revolver_recoil": [Rect2(653, 78, 245, 447), Vector2(845, 519), Vector2(855, 116), 460.0, "drifter-guns"],
		"shotgun_aim": [Rect2(1079, 52, 333, 473), Vector2(1290, 519), Vector2(1265, 174), 460.0, "drifter-guns"],
		"shotgun_recoil": [Rect2(168, 563, 262, 425), Vector2(379, 982), Vector2(273, 683), 460.0, "drifter-guns"],
		"empty_gun": [Rect2(650, 550, 236, 449), Vector2(824, 993), Vector2(850, 750), 460.0, "drifter-guns"],
		"gun_recover": [Rect2(1131, 555, 231, 446), Vector2(1300, 995), Vector2(1342, 783), 460.0, "drifter-guns"],
		"windup": [Rect2(390, 12, 309, 570), Vector2(606, 580), Vector2(550, 40), 550.0],
		"strike": [Rect2(738, 61, 395, 522), Vector2(1000, 582), Vector2(1115, 160), 550.0],
		"aim": [Rect2(1129, 43, 295, 545), Vector2(1350, 585), Vector2(1390, 133), 550.0],
		"brace": [Rect2(42, 664, 258, 385), Vector2(235, 1046), Vector2(265, 783), 550.0],
		"hurt": [Rect2(384, 604, 300, 450), Vector2(610, 1051), Vector2(580, 650), 550.0],
		"kneel": [Rect2(735, 712, 301, 332), Vector2(945, 1042), Vector2(988, 990), 550.0],
		"fall": [Rect2(1063, 832, 369, 233), Vector2(1250, 1062), Vector2(1380, 945), 550.0],
	},
	"feral_dog": {
		"idle_breath": [Rect2(64, 26, 390, 489), Vector2(234, 509), Vector2.ZERO, 470.0, "feral-dog-movement"],
		"step_a": [Rect2(581, 41, 399, 467), Vector2(672, 502), Vector2.ZERO, 470.0, "feral-dog-movement"],
		"step_b": [Rect2(1094, 50, 404, 466), Vector2(1200, 510), Vector2.ZERO, 470.0, "feral-dog-movement"],
		"recover": [Rect2(22, 520, 450, 469), Vector2(226, 983), Vector2.ZERO, 470.0, "feral-dog-movement"],
		"kneel": [Rect2(537, 699, 476, 269), Vector2(740, 962), Vector2.ZERO, 470.0, "feral-dog-movement"],
		"settle": [Rect2(1089, 539, 416, 450), Vector2(1270, 983), Vector2.ZERO, 470.0, "feral-dog-movement"],
		"windup": [Rect2(17, 146, 528, 524), Vector2(295, 666), Vector2.ZERO, 520.0],
		"strike": [Rect2(531, 35, 576, 432), Vector2(830, 465), Vector2.ZERO, 520.0],
		"hurt": [Rect2(1111, 95, 484, 546), Vector2(1370, 638), Vector2.ZERO, 520.0],
		"fall": [Rect2(1618, 395, 537, 281), Vector2(1900, 673), Vector2.ZERO, 520.0],
	},
	"heavy_raider": {
		"idle_breath": [Rect2(39, 40, 430, 413), Vector2(190, 447), Vector2.ZERO, 410.0, "heavy-raider-movement"],
		"step_a": [Rect2(519, 49, 440, 418), Vector2(738, 461), Vector2.ZERO, 410.0, "heavy-raider-movement"],
		"step_b": [Rect2(1037, 43, 446, 422), Vector2(1217, 459), Vector2.ZERO, 410.0, "heavy-raider-movement"],
		"recover": [Rect2(48, 587, 451, 398), Vector2(450, 979), Vector2.ZERO, 410.0, "heavy-raider-movement"],
		"kneel": [Rect2(569, 627, 376, 337), Vector2(712, 958), Vector2.ZERO, 410.0, "heavy-raider-movement"],
		"charge": [Rect2(1057, 510, 447, 479), Vector2(1117, 983), Vector2.ZERO, 410.0, "heavy-raider-movement"],
		"windup": [Rect2(65, 8, 466, 664), Vector2(345, 668), Vector2.ZERO, 520.0],
		"strike": [Rect2(549, 149, 548, 524), Vector2(890, 670), Vector2.ZERO, 520.0],
		"hurt": [Rect2(1123, 138, 501, 538), Vector2(1380, 673), Vector2.ZERO, 520.0],
		"fall": [Rect2(1643, 367, 521, 342), Vector2(1890, 706), Vector2.ZERO, 520.0],
	},
}
const FILES := {"drifter": "drifter", "feral_dog": "feral-dog", "bandit": "road-bandit", "heavy_raider": "heavy-raider", "grey_crow": "grey-crow-capture"}
static var atlases: Dictionary = {}
static var textures: Dictionary = {}

static func frame(actor_id: String, pose: String) -> Dictionary:
	var poses: Dictionary = FRAMES.get(actor_id, {})
	if not poses.has(pose):
		return {}
	var spec: Array = poses[pose]
	var key := actor_id + "/" + pose
	if not textures.has(key):
		var file: String = String(spec[4]) if spec.size() > 4 else "%s-poses" % FILES[actor_id]
		if not atlases.has(file):
			var source: Texture2D = load_atlas("res://ui/assets/combat/poses/%s.png" % file)
			if source == null:
				return {}
			atlases[file] = source
		var texture := AtlasTexture.new()
		texture.atlas = atlases[file]
		texture.region = spec[0]
		texture.filter_clip = true
		textures[key] = texture
	var region: Rect2 = spec[0]
	return {"texture": textures[key], "foot": (spec[1] - region.position) / region.size,
		"hand": (spec[2] - region.position) / region.size, "reference_height": spec[3]}

static func load_atlas(path: String) -> Texture2D:
	# Exported PNG sources are remapped to imported texture resources.
	if ResourceLoader.exists(path):
		var imported: Texture2D = ResourceLoader.load(path) as Texture2D
		if imported != null and imported.get_width() > 0 and imported.get_height() > 0:
			return imported
	if FileAccess.file_exists(path):
		var bitmap: Image = Image.load_from_file(path)
		if bitmap != null and not bitmap.is_empty():
			return ImageTexture.create_from_image(bitmap)
	return null

static func attack_poses(style: Dictionary) -> Array[String]:
	if style.name == "hammer":
		return ["hammer_windup", "hammer_strike", "hammer_recover"]
	if style.name in ["machete", "saber"]:
		return ["slash_windup", "slash_strike", "slash_recover"]
	return ["windup", "strike", "recover"]

static func gun_pose(style: Dictionary, recoil: bool = false) -> String:
	return ("shotgun" if style.name == "shotgun" else "revolver") + ("_recoil" if recoil else "_aim")

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
