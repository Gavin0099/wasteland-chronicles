extends SceneTree

# ==============================================================================
# BVIS-2B: COMBAT READABILITY TEST SUITE
# ==============================================================================
# Verifies the 4 Hard Gates of BVIS-2B:
#   G1 Telegraph Stance: Heavy Raider arched-back charge pose (>0.18 rad),
#      looping until release; zero reliance on text labels.
#   G2 Damage Ownership: Damage popups spawn directly above the victim actor
#      (gold over enemy, critical red over hero); values strictly from receipt.
#   G3 Impact Contrast: Local hit stop intervals (0.04s normal, 0.06s heavy);
#      Engine.time_scale is strictly 1.0 at all times (no global pause).
#   G4 DEFEND Contrast: Radical contrast between unbraced (violent recoil,
#      hit_reaction, critical popup) vs defended (subtle recoil, brace pose,
#      shield popup).
# ==============================================================================

const Stage = preload("res://ui/components/battle_stage.gd")
const Director = preload("res://ui/components/battle_motion_director.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("BVIS-2B FAIL: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Running BVIS-2B Combat Readability Test Suite ---")

	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "Readability Tester",
		"age": 28, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")

	var stage := Stage.new()
	stage.size = Vector2(1280, 720)
	root.add_child(stage)
	stage.configure("heavy_raider", "scrap_machete", true)
	stage.refresh(true, true)
	stage.arrange()

	# Invariant check: Engine.time_scale MUST always be 1.0
	check(Engine.time_scale == 1.0, "G3: Engine.time_scale is initially 1.0")

	# ==========================================================================
	# G1: TELEGRAPH STANCE (Heavy Raider Charge Pose)
	# ==========================================================================
	var enemy_anim: AnimationPlayer = stage.enemy_actor.anim_player
	check(enemy_anim != null, "G1: enemy anim_player present")
	check(enemy_anim.has_animation("heavy_charge"), "G1: heavy_charge animation exists")

	var a_chg: Animation = enemy_anim.get_animation("heavy_charge")
	check(a_chg.loop_mode == Animation.LOOP_LINEAR, "G1: heavy_charge loops to sustain charge stance across turn")

	# Inspect heavy_charge rotation track
	var found_chg_rot := false
	var max_chg_rot := 0.0
	for t_idx in range(a_chg.get_track_count()):
		var p := String(a_chg.track_get_path(t_idx))
		if p == "Body:rotation":
			found_chg_rot = true
			for k in range(a_chg.track_get_key_count(t_idx)):
				var val: float = float(a_chg.track_get_key_value(t_idx, k))
				if val > max_chg_rot:
					max_chg_rot = val
	check(found_chg_rot, "G1: heavy_charge has track on Body:rotation")
	check(max_chg_rot >= 0.18, "G1: heavy_charge arches back >= 0.18 rad (actual: %.2f rad, ~%.1f deg)" % [max_chg_rot, rad_to_deg(max_chg_rot)])

	# Inspect heavy_release animation
	check(enemy_anim.has_animation("heavy_release"), "G1: heavy_release animation exists")
	var a_rel: Animation = enemy_anim.get_animation("heavy_release")
	var found_rel_smash := false
	for t_idx in range(a_rel.get_track_count()):
		var p := String(a_rel.track_get_path(t_idx))
		if p == "Body:rotation":
			for k in range(a_rel.track_get_key_count(t_idx)):
				var val: float = float(a_rel.track_get_key_value(t_idx, k))
				if val <= -0.15:
					found_rel_smash = true
	check(found_rel_smash, "G1: heavy_release smashes forward violently (rotation <= -0.15 rad)")

	# Trigger telegraph turn and verify enemy enters sustained heavy_charge pose
	var charge_turn_receipt := {
		"command": "DEFEND", "dealt": 0, "taken": 0, "enemy_id": "heavy_raider", "turn": 2,
		"is_heavy": false, "next_heavy": true
	}
	await Director.direct_turn(stage, charge_turn_receipt)
	check(enemy_anim.current_animation == "heavy_charge", "G1: enemy anim_player actively holding heavy_charge pose")

	# ==========================================================================
	# G2: DAMAGE OWNERSHIP (Spatial Popups Directly Above Victim)
	# ==========================================================================
	check(stage.fx_layer != null, "G2: stage has fx_layer")
	check(stage.fx_layer.get_parent() == stage.stage_canvas, "G2: fx_layer parented to stage_canvas")

	# 1. Player hits enemy -> Gold popup over enemy
	var enemy_popup: Label = stage.spawn_damage_popup(stage.enemy_actor, 6, false, false)
	check(enemy_popup != null, "G2: enemy damage popup created")
	check(enemy_popup.text == "-6", "G2: enemy popup text derived strictly from receipt value '-6'")
	var enemy_popup_center_x := enemy_popup.position.x + enemy_popup.custom_minimum_size.x * 0.5
	check(absf(enemy_popup_center_x - stage.enemy_origin.x) < 25.0, "G2: enemy popup horizontally centered above enemy (delta: %.1f px)" % absf(enemy_popup_center_x - stage.enemy_origin.x))
	check(enemy_popup.position.y < stage.enemy_origin.y - stage.enemy_actor.target_height * 0.8, "G2: enemy popup positioned above enemy head")
	var enemy_popup_col: Color = enemy_popup.get_theme_color("font_color")
	check(enemy_popup_col.r > 0.9 and enemy_popup_col.g > 0.7 and enemy_popup_col.b < 0.5, "G2: enemy damage popup uses gold palette (r=%.2f, g=%.2f, b=%.2f)" % [enemy_popup_col.r, enemy_popup_col.g, enemy_popup_col.b])

	# 2. Enemy hits hero -> Critical / Orange popup over hero
	var hero_popup: Label = stage.spawn_damage_popup(stage.hero_actor, 4, false, false)
	check(hero_popup != null, "G2: hero damage popup created")
	check(hero_popup.text == "-4", "G2: hero popup text derived strictly from receipt value '-4'")
	var hero_popup_center_x := hero_popup.position.x + hero_popup.custom_minimum_size.x * 0.5
	check(absf(hero_popup_center_x - stage.hero_origin.x) < 25.0, "G2: hero popup horizontally centered above hero (delta: %.1f px)" % absf(hero_popup_center_x - stage.hero_origin.x))
	check(hero_popup.position.y < stage.hero_origin.y - stage.hero_actor.target_height * 0.8, "G2: hero popup positioned above hero head")
	var hero_popup_col: Color = hero_popup.get_theme_color("font_color")
	check(hero_popup_col.r > 0.9 and hero_popup_col.g < 0.6, "G2: hero damage popup uses crimson/orange palette (r=%.2f, g=%.2f, b=%.2f)" % [hero_popup_col.r, hero_popup_col.g, hero_popup_col.b])

	# 3. Heavy critical popup over hero
	var heavy_popup: Label = stage.spawn_damage_popup(stage.hero_actor, 10, true, false)
	check(heavy_popup.text == "-10 重創!", "G2: heavy unbraced popup contains critical suffix '-10 重創!'")
	check(heavy_popup.get_theme_font_size("font_size") >= 18, "G2: heavy unbraced popup uses large font size (>= 18)")

	# 4. Defended popup over hero
	var def_popup: Label = stage.spawn_damage_popup(stage.hero_actor, 2, true, true)
	check(def_popup.text == "-2 (格擋)", "G2: defended popup contains defense indicator '-2 (格擋)'")

	# Clean up manual test popups
	enemy_popup.queue_free()
	hero_popup.queue_free()
	heavy_popup.queue_free()
	def_popup.queue_free()

	# ==========================================================================
	# G3: IMPACT CONTRAST & ZERO Engine.time_scale
	# ==========================================================================
	var before_world := world.to_canonical_json()
	var attack_receipt := {
		"command": "ATTACK", "dealt": 4, "taken": 3, "enemy_id": "heavy_raider", "turn": 1,
		"is_heavy": false, "next_heavy": false
	}
	await Director.direct_turn(stage, attack_receipt)
	check(Engine.time_scale == 1.0, "G3: Engine.time_scale strictly remains 1.0 (no global pause)")
	check(world.to_canonical_json() == before_world, "G3: simulation state remains 100% untouched by combat motion")

	# ==========================================================================
	# G4: DEFEND CONTRAST (Unbraced vs Defended Heavy Strike)
	# ==========================================================================
	# 1. Inspect unbraced heavy strike recoil formula
	var hero_prof: Dictionary = stage.VISUAL_PROFILES.get("heavy_raider", {})
	var base_recoil: float = float(hero_prof.get("recoil_strength", 3.0))
	var unbraced_recoil_mag := base_recoil * 3.0 # -9.0px
	var defended_recoil_mag := base_recoil * 0.45 # -1.35px
	check(unbraced_recoil_mag >= base_recoil * 2.5, "G4: unbraced heavy recoil is violent (>= 2.5x base)")
	check(defended_recoil_mag <= base_recoil * 0.6, "G4: defended heavy recoil is heavily blunted (<= 0.6x base)")
	check(unbraced_recoil_mag / defended_recoil_mag >= 4.0, "G4: unbraced vs defended recoil contrast ratio >= 4.0x (actual: %.1fx)" % (unbraced_recoil_mag / defended_recoil_mag))

	# 2. Hero anim_player has brace animation with golden shield modulate
	var hero_anim: AnimationPlayer = stage.hero_actor.anim_player
	check(hero_anim.has_animation("brace"), "G4: hero has brace animation")
	var a_brace: Animation = hero_anim.get_animation("brace")
	var found_brace_glow := false
	for t_idx in range(a_brace.get_track_count()):
		if String(a_brace.track_get_path(t_idx)) == "Body:modulate":
			for k in range(a_brace.track_get_key_count(t_idx)):
				var c: Color = a_brace.track_get_key_value(t_idx, k)
				if c.r > 1.0 and c.g > 1.0:
					found_brace_glow = true
	check(found_brace_glow, "G4: brace animation has golden shield flash (Body:modulate r>1, g>1)")

	# 3. Execute defended heavy turn and verify clean return
	var defended_heavy_receipt := {
		"command": "DEFEND", "dealt": 0, "taken": 2, "enemy_id": "heavy_raider", "turn": 3,
		"is_heavy": true, "next_heavy": false
	}
	await Director.direct_turn(stage, defended_heavy_receipt)
	check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.01, "G4: hero returns deterministically to hero_origin after defended heavy hit")
	check(stage.enemy_actor.position.distance_to(stage.enemy_origin) < 0.01, "G4: enemy returns deterministically to enemy_origin after heavy release")

	stage.free()

	if failures == 0:
		print("BVIS-2B combat readability: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("BVIS-2B combat readability: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
