extends SceneTree

# ==============================================================================
# BVIS-1B: 2.5D ASSET INTEGRATION & FRAMING TEST SUITE
# ==============================================================================
# Verifies the 4 Gates of BVIS-1B:
#   G1 Visual Profile: Detached catalogue defines single source of visual truth.
#   G2 Stage Framing: 16:9 AspectRatioContainer ensures fixed virtual camera.
#   G3 Asset Truth: Drifter, Dog, Bandit, Raider load authored art, fail-closed.
#   G4 Ground Alignment: Ground Actor Contract holds across all visual profiles.
# ==============================================================================

const Stage = preload("res://ui/components/battle_stage.gd")

var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("BVIS-1B: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Running BVIS-1B Asset Integration Test Suite ---")

	# ==========================================================================
	# G1: VISUAL PROFILE CONTRACT
	# ==========================================================================
	var profiles: Dictionary = Stage.VISUAL_PROFILES
	check(profiles.has("drifter"), "G1: drifter profile exists")
	check(profiles.has("feral_dog"), "G1: feral_dog profile exists")
	check(profiles.has("bandit"), "G1: bandit profile exists")
	check(profiles.has("heavy_raider"), "G1: heavy_raider profile exists")

	for char_id in ["drifter", "feral_dog", "bandit", "heavy_raider"]:
		var p: Dictionary = profiles[char_id]
		check(p.has("texture_path") and String(p.texture_path) != "", "G1: %s has texture_path" % char_id)
		check(p.has("foot_anchor_uv") and p.foot_anchor_uv is Vector2, "G1: %s has foot_anchor_uv" % char_id)
		check(p.has("height_ratio") and float(p.height_ratio) > 0.0, "G1: %s has positive height_ratio" % char_id)
		check(p.has("shadow_radius_ratio") and float(p.shadow_radius_ratio) > 0.0, "G1: %s has positive shadow_radius_ratio" % char_id)

		var uv: Vector2 = p.foot_anchor_uv
		check(uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0, "G1: %s foot_anchor_uv in [0, 1] range" % char_id)

		var tex: Texture2D = Stage.load_texture_safe(p.texture_path)
		check(tex != null, "G1: %s texture exists and loads successfully" % char_id)

	# Height hierarchy check: dog < bandit <= drifter < heavy_raider
	var h_dog: float = float(profiles["feral_dog"].height_ratio)
	var h_bandit: float = float(profiles["bandit"].height_ratio)
	var h_drifter: float = float(profiles["drifter"].height_ratio)
	var h_raider: float = float(profiles["heavy_raider"].height_ratio)
	check(h_dog < h_bandit, "G1: dog is shorter than bandit (%f < %f)" % [h_dog, h_bandit])
	check(h_bandit <= h_drifter, "G1: bandit is comparable to drifter (%f <= %f)" % [h_bandit, h_drifter])
	check(h_raider > h_drifter, "G1: heavy raider is taller than drifter (%f > %f)" % [h_raider, h_drifter])

	# ==========================================================================
	# G2: STAGE FRAMING (16:9 Aspect Ratio)
	# ==========================================================================
	var stage := Stage.new()
	stage.size = Vector2(1280, 720)
	root.add_child(stage)
	stage.arrange()

	check(stage.aspect_frame != null, "G2: aspect_frame exists")
	check(absf(stage.aspect_frame.ratio - (16.0 / 9.0)) < 0.001, "G2: framing ratio is 16:9")
	check(stage.stage_canvas != null, "G2: stage_canvas exists")
	check(stage.actor_layer != null, "G2: actor_layer exists")
	check(stage.actor_layer.y_sort_enabled, "G2: actor_layer has y_sort_enabled = true")

	# Check road background authored aspect ratio
	var road_tex: Texture2D = stage.road_background.texture
	check(road_tex != null, "G2: road_background texture is loaded")
	if road_tex != null:
		var bg_ratio := float(road_tex.get_width()) / float(road_tex.get_height())
		check(absf(bg_ratio - (16.0 / 9.0)) < 0.01, "G2: abandoned-road.png authored aspect ratio is 16:9 (width=%d, height=%d, ratio=%.4f)" % [road_tex.get_width(), road_tex.get_height(), bg_ratio])

	# ==========================================================================
	# G3: ASSET TRUTH & FAIL-CLOSED BOUNDARY
	# ==========================================================================
	# Test bandit configuration
	var ok_bandit := stage.configure("bandit", "scrap_machete", true)
	check(ok_bandit, "G3: configure bandit succeeds")
	stage.refresh(true, true)
	check(stage.enemy.visible, "G3: bandit uses real sprite")
	check(not stage.enemy_placeholder.visible, "G3: bandit does not show placeholder")
	check(not stage.placeholder_note.visible, "G3: bandit carries no placeholder note")
	check(stage.road_background.visible, "G3: road background is visible")
	check(not stage.shed_background.visible, "G3: shed background is hidden")
	var bandit_tex_ref: Texture2D = stage.enemy.texture

	# Test heavy_raider configuration
	var ok_raider := stage.configure("heavy_raider", "", true)
	check(ok_raider, "G3: configure heavy_raider succeeds")
	stage.refresh(false, true)
	check(stage.enemy.visible, "G3: heavy_raider uses real sprite")
	check(not stage.enemy_placeholder.visible, "G3: heavy_raider does not show placeholder")
	check(not stage.placeholder_note.visible, "G3: heavy_raider carries no placeholder note")
	var raider_tex_ref: Texture2D = stage.enemy.texture
	check(raider_tex_ref != bandit_tex_ref, "G3: raider does not borrow bandit texture")

	# Test feral_dog configuration
	var ok_dog := stage.configure("feral_dog", "", false)
	check(ok_dog, "G3: configure feral_dog succeeds")
	stage.refresh(false, true)
	check(stage.enemy.visible, "G3: feral_dog uses real sprite")
	var dog_tex_ref: Texture2D = stage.enemy.texture
	check(dog_tex_ref != bandit_tex_ref and dog_tex_ref != raider_tex_ref, "G3: dog does not borrow bandit or raider texture")

	# Fail-closed test on unregistered enemy ID
	var ok_invalid := stage.configure("unregistered_creature_xyz", "", true)
	check(not ok_invalid, "G3: unregistered enemy ID fails closed")

	# ==========================================================================
	# G4: GROUND ALIGNMENT & SQUASH RATIO ACROSS CHARACTERS
	# ==========================================================================
	for enemy_id in ["bandit", "heavy_raider", "feral_dog"]:
		stage.configure(enemy_id, "", true)
		stage.arrange()
		var anchor := stage.enemy_actor.get_local_foot_anchor()
		check(anchor.length() < 0.001, "G4: %s local foot anchor exactly at (0, 0)" % enemy_id)
		check(stage.enemy_shadow.position == Vector2.ZERO, "G4: %s shadow positioned at (0, 0)" % enemy_id)
		check(absf(stage.enemy_shadow.squashed_ratio - 0.22) < 0.001, "G4: %s shadow squashed ratio is 0.22" % enemy_id)

	# Verify Hero Ground Actor alignment
	var hero_anchor := stage.hero_actor.get_local_foot_anchor()
	check(hero_anchor.length() < 0.001, "G4: hero local foot anchor exactly at (0, 0)")
	check(stage.hero_shadow.position == Vector2.ZERO, "G4: hero shadow positioned at (0, 0)")
	check(absf(stage.hero_shadow.squashed_ratio - 0.22) < 0.001, "G4: hero shadow squashed ratio is 0.22")

	stage.free()

	if failures == 0:
		print("BVIS-1B asset integration: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("BVIS-1B asset integration: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
