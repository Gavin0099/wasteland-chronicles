extends "res://tools/capture_combatvis2.gd"

func _init() -> void:
	output_dir = OS.get_user_data_dir().path_join("captures/combat-animation-completion-final")
	call_deferred("capture")

func phase_frame(phase: String, prefix: String) -> void:
	pending_frames += 1
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("%s/%s_%s_%dx%d.png" % [output_dir, prefix, phase, root.size.x, root.size.y]) == OK)
	count += 1
	pending_frames -= 1

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		# Staged asset checks are separate from receipt-driven playback snapshots.
		for actor_id in preload("res://ui/components/battle_pose_library.gd").FRAMES:
			for pose in preload("res://ui/components/battle_pose_library.gd").FRAMES[actor_id]:
				var spec: Array = preload("res://ui/components/battle_pose_library.gd").FRAMES[actor_id][pose]
				if spec.size() <= 4:
					continue
				var weapon: String = "sledgehammer" if String(pose).begins_with("hammer") else "scrap_machete"
				if String(pose).begins_with("shotgun"):
					weapon = "short_shotgun"
				elif String(pose).begins_with("revolver") or pose in ["empty_gun", "gun_recover"]:
					weapon = "old_revolver"
				var environment: String = {"feral_dog": "shed", "bandit": "highway", "heavy_raider": "camp"}.get(actor_id, "highway")
				var world: WorldState = Fixture.create(weapon, engine, environment)
				var unchanged: String = world.to_canonical_json()
				var ui: Control = make_screen(world, "atlas_" + actor_id + "_" + pose)
				for tick in range(5): await process_frame
				ui.stage.hero_actor.hold_pose("rest")
				ui.stage.enemy_actor.hold_pose("rest")
				var actor: Node2D = ui.stage.hero_actor if actor_id == "drifter" else ui.stage.enemy_actor
				actor.hold_pose(pose)
				await still_frame("atlas_" + actor_id + "_" + pose)
				assert(actor.pose == pose and world.to_canonical_json() == unchanged)
				ui.queue_free()
				await process_frame
		for weapon in Fixture.Weapons + ["combat_knife", "rebar_club", "police_revolver", "reinforced_saber", "quickdraw_police_revolver"]:
			var world: WorldState = Fixture.create(weapon, engine)
			var ui: Control = make_screen(world, weapon)
			await still_frame(weapon + "_idle")
			ui.stage.hero_actor.anim_player.advance(0.8)
			await still_frame(weapon + "_breathing")
			var command: String = "SHOOT" if not preload("res://simulation/weapon_rules.gd").firearm(weapon).is_empty() else "ATTACK"
			var reference: WorldState = world.duplicate_state()
			var payload: Dictionary = ui.payload_for(command)
			assert(engine.commit_player_intent(reference, PlayerIntent.create_field_action(reference.player.npc_id, payload)).success)
			await ui.perform(payload)
			assert(reference.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text())
			await still_frame(weapon + "_after")
			ui.queue_free()
			await process_frame
			print("Captured weapon %s at %s" % [weapon, resolution])
		for environment in ["shed", "highway", "camp"]:
			var world: WorldState = Fixture.create("crowbar" if environment == "shed" else "sledgehammer", engine, environment)
			var ui: Control = make_screen(world, environment)
			await ui.perform(ui.payload_for("DEFEND"))
			await ui.perform(ui.payload_for("DEFEND"))
			await still_frame(environment + "_prepared")
			while not world.field_state.battle.is_empty():
				await ui.perform(ui.payload_for("ATTACK"))
			await still_frame(environment + "_result")
			print("Captured enemy %s at %s" % [environment, resolution])
			ui.queue_free()
			await process_frame
		for reduced in [false, true]:
			var world: WorldState = Fixture.create("scrap_machete", engine)
			var ui: Control = make_screen(world, "reduced_flee" if reduced else "flee")
			ui.reduce_motion.button_pressed = reduced
			await ui.perform(ui.payload_for("FLEE"))
			await still_frame("reduced_flee_result" if reduced else "flee_result")
			ui.queue_free()
			await process_frame
		var world: WorldState = Fixture.create("old_revolver", engine, "camp")
		var ui: Control = make_screen(world, "empty")
		await ui.perform(ui.payload_for("SHOOT"))
		await ui.perform(ui.payload_for("SHOOT"))
		await ui.perform(ui.payload_for("SHOOT"))
		await still_frame("empty_gun")
		ui.queue_free()
		await process_frame
		world = Fixture.create("old_revolver", engine)
		world.player.field_kit.hp = 2
		ui = make_screen(world, "defeat")
		await ui.perform(ui.payload_for("ATTACK"))
		await still_frame("defeat_alive_result")
		ui.queue_free()
		await process_frame
	var drain_frames: int = 0
	print("Draining %d pending snapshots" % pending_frames)
	while pending_frames > 0 and drain_frames < 300:
		# Finish queued post-draw snapshots even if the capture window lost focus.
		RenderingServer.force_draw()
		await process_frame
		drain_frames += 1
	if pending_frames > 0:
		push_error("Capture snapshots did not drain: %d" % pending_frames)
		quit(1)
		return
	print("CAPTURED %d actual frames: %s" % [count, output_dir])
	quit(0)
