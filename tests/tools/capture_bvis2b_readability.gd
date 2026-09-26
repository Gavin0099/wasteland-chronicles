extends SceneTree

# ==============================================================================
# BVIS-2B: REAL RENDERER READABILITY CAPTURE TOOL
# ==============================================================================
# Renders and saves real Godot viewport frames at 1280x720:
#   1. bvis2b_heavy_charge_1280x720: Heavy Raider arched-back telegraph posture
#   2. bvis2b_player_hit_bandit_1280x720: Player attack impact + gold damage popup above Bandit
#   3. bvis2b_heavy_unbraced_1280x720: Heavy strike unbraced + critical red popup + recoil
#   4. bvis2b_heavy_defended_1280x720: Heavy strike defended + blunted popup + brace stance
# ==============================================================================

const Stage = preload("res://ui/components/battle_stage.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Generating BVIS-2B Readability Captures ---")
	var sz := Vector2i(1280, 720)
	var output_dir := "res://ui/assets/combat/previews"
	DirAccess.make_dir_recursive_absolute("res://ui/assets/combat/previews")

	# --------------------------------------------------------------------------
	# Frame 1: Heavy Raider Telegraph Charge Pose (Arched Back, Raised Tension)
	# --------------------------------------------------------------------------
	var vp1 := SubViewport.new()
	vp1.size = sz
	vp1.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp1)

	var stage1 := Stage.new()
	stage1.size = Vector2(sz)
	vp1.add_child(stage1)
	stage1.configure("heavy_raider", "scrap_machete", true)
	stage1.refresh(true, true)
	stage1.arrange()

	# Wait for layout to settle
	for i in range(2):
		await RenderingServer.frame_post_draw

	# Freeze in peak heavy_charge pose (arched back away from drifter)
	stage1.enemy_actor.anim_player.play("heavy_charge")
	stage1.enemy_actor.anim_player.pause()
	stage1.enemy_actor.anim_player.seek(0.25, true)

	for i in range(2):
		await RenderingServer.frame_post_draw

	_save_capture(vp1, "bvis2b_heavy_charge_1280x720.png")
	vp1.queue_free()
	for i in range(2):
		await RenderingServer.frame_post_draw

	# --------------------------------------------------------------------------
	# Frame 2: Player Attack Impact + Gold Popup over Bandit
	# --------------------------------------------------------------------------
	var vp2 := SubViewport.new()
	vp2.size = sz
	vp2.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp2)

	var stage2 := Stage.new()
	stage2.size = Vector2(sz)
	vp2.add_child(stage2)
	stage2.configure("bandit", "scrap_machete", true)
	stage2.refresh(true, true)
	stage2.arrange()

	for i in range(2):
		await RenderingServer.frame_post_draw

	# Hero lunged forward to attack; Bandit hit reaction; gold popup over Bandit
	stage2.hero_actor.position = stage2.hero_origin.lerp(stage2.enemy_origin, 0.48)
	stage2.hero_actor.anim_player.play("attack_pose")
	stage2.hero_actor.anim_player.pause()
	stage2.hero_actor.anim_player.seek(0.22, true)

	stage2.enemy_actor.position = stage2.enemy_origin + Vector2(7, -3)
	stage2.enemy_actor.anim_player.play("hit_reaction")
	stage2.enemy_actor.anim_player.pause()
	stage2.enemy_actor.anim_player.seek(0.06, true)

	var p2 := stage2.spawn_damage_popup(stage2.enemy_actor, 6, false, false)
	# Center popup directly above enemy head for static capture
	p2.position = Vector2(stage2.enemy_actor.position.x - 70.0, stage2.enemy_actor.position.y - stage2.enemy_actor.target_height - 35.0)

	for i in range(2):
		await RenderingServer.frame_post_draw

	_save_capture(vp2, "bvis2b_player_hit_bandit_1280x720.png")
	vp2.queue_free()
	for i in range(2):
		await RenderingServer.frame_post_draw

	# --------------------------------------------------------------------------
	# Frame 3: Heavy Strike Unbraced + Critical Red Popup over Hero
	# --------------------------------------------------------------------------
	var vp3 := SubViewport.new()
	vp3.size = sz
	vp3.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp3)

	var stage3 := Stage.new()
	stage3.size = Vector2(sz)
	vp3.add_child(stage3)
	stage3.configure("heavy_raider", "scrap_machete", true)
	stage3.refresh(true, true)
	stage3.arrange()

	for i in range(2):
		await RenderingServer.frame_post_draw

	# Raider lunged in heavy release; Hero staggered backwards with violent recoil
	stage3.enemy_actor.position = stage3.enemy_origin.lerp(stage3.hero_origin, 0.44)
	stage3.enemy_actor.anim_player.play("heavy_release")
	stage3.enemy_actor.anim_player.pause()
	stage3.enemy_actor.anim_player.seek(0.12, true)

	stage3.hero_actor.position = stage3.hero_origin + Vector2(-18, 5)
	stage3.hero_actor.anim_player.play("hit_reaction")
	stage3.hero_actor.anim_player.pause()
	stage3.hero_actor.anim_player.seek(0.06, true)

	var p3 := stage3.spawn_damage_popup(stage3.hero_actor, 9, true, false)
	p3.position = Vector2(stage3.hero_actor.position.x - 70.0, stage3.hero_actor.position.y - stage3.hero_actor.target_height - 35.0)

	for i in range(2):
		await RenderingServer.frame_post_draw

	_save_capture(vp3, "bvis2b_heavy_unbraced_1280x720.png")
	vp3.queue_free()
	for i in range(2):
		await RenderingServer.frame_post_draw

	# --------------------------------------------------------------------------
	# Frame 4: Heavy Strike Defended + Blunted Popup + Hero Bracing
	# --------------------------------------------------------------------------
	var vp4 := SubViewport.new()
	vp4.size = sz
	vp4.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp4)

	var stage4 := Stage.new()
	stage4.size = Vector2(sz)
	vp4.add_child(stage4)
	stage4.configure("heavy_raider", "scrap_machete", true)
	stage4.refresh(true, true)
	stage4.arrange()

	for i in range(2):
		await RenderingServer.frame_post_draw

	# Raider lunged; Hero firmly planted in defensive brace with minimal recoil (-2px)
	stage4.enemy_actor.position = stage4.enemy_origin.lerp(stage4.hero_origin, 0.44)
	stage4.enemy_actor.anim_player.play("heavy_release")
	stage4.enemy_actor.anim_player.pause()
	stage4.enemy_actor.anim_player.seek(0.12, true)

	stage4.hero_actor.position = stage4.hero_origin + Vector2(-2, 1)
	stage4.hero_actor.anim_player.play("brace")
	stage4.hero_actor.anim_player.pause()
	stage4.hero_actor.anim_player.seek(0.15, true)

	var p4 := stage4.spawn_damage_popup(stage4.hero_actor, 2, true, true)
	p4.position = Vector2(stage4.hero_actor.position.x - 70.0, stage4.hero_actor.position.y - stage4.hero_actor.target_height - 35.0)

	for i in range(2):
		await RenderingServer.frame_post_draw

	_save_capture(vp4, "bvis2b_heavy_defended_1280x720.png")
	vp4.queue_free()
	for i in range(2):
		await RenderingServer.frame_post_draw

	print("BVIS-2B captures generated successfully.")
	quit(0)

func _save_capture(vp: SubViewport, file_name: String) -> void:
	var img := vp.get_texture().get_image()
	if img != null:
		var out_path := "res://ui/assets/combat/previews/%s" % file_name
		var err := img.save_png(out_path)
		print("Saved %s (code=%d, size=%dx%d)" % [out_path, err, img.get_width(), img.get_height()])

		var artifact_path := "C:/Users/daish/.gemini/antigravity/brain/93c61494-1abd-45d4-a474-87d5878a4856/%s" % file_name
		img.save_png(artifact_path)
	else:
		print("Failed to capture image for %s" % file_name)
