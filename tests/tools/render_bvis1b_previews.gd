extends SceneTree

const Stage = preload("res://ui/components/battle_stage.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Generating BVIS-1B Real Renderer Previews ---")
	var target_resolutions := [
		{"name": "1280x720", "size": Vector2i(1280, 720)},
		{"name": "1152x648", "size": Vector2i(1152, 648)},
	]
	var enemies := ["feral_dog", "bandit", "heavy_raider"]

	var output_dir := "res://ui/assets/combat/previews"
	DirAccess.make_dir_recursive_absolute("res://ui/assets/combat/previews")

	for res in target_resolutions:
		var sz: Vector2i = res.size
		var res_name: String = res.name

		for enemy_id in enemies:
			var vp := SubViewport.new()
			vp.size = sz
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(vp)

			var stage := Stage.new()
			stage.size = Vector2(sz)
			vp.add_child(stage)

			var is_road: bool = (enemy_id != "feral_dog")
			stage.configure(enemy_id, "scrap_machete", is_road)
			stage.refresh(true, true)
			stage.arrange()

			# Wait for frames to draw
			for i in range(4):
				await RenderingServer.frame_post_draw

			var img := vp.get_texture().get_image()
			if img != null:
				var file_name := "bvis1b_%s_%s.png" % [enemy_id, res_name]
				var out_path := "%s/%s" % [output_dir, file_name]
				var err := img.save_png(out_path)
				print("Saved %s (code=%d, size=%dx%d)" % [out_path, err, img.get_width(), img.get_height()])

				# Also save a copy to artifact directory for user viewing
				var artifact_path := "C:/Users/daish/.gemini/antigravity/brain/93c61494-1abd-45d4-a474-87d5878a4856/%s" % file_name
				img.save_png(artifact_path)
			else:
				print("Failed to get viewport image for %s at %s" % [enemy_id, res_name])

			vp.queue_free()
			for i in range(2):
				await RenderingServer.frame_post_draw

	print("Previews generation finished successfully.")
	quit(0)
