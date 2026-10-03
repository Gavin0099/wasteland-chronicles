extends SceneTree

const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combat_vis1_world.gd")
var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("COMBAT-ISO: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	for resolution in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for environment in ["shed", "highway", "wilderness", "camp"]:
			var world := Fixture.create(environment, true, engine)
			var before := world.to_canonical_json()
			var screen := Screen.new()
			root.add_child(screen)
			screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			screen.setup(world, engine)
			for frame in range(12):
				await process_frame
			var stage = screen.stage
			var ground = stage.isometric_ground
			check(stage.isometric and ground.visible and ground.surface.texture != null, "real screen shows textured isometric ground")
			check(stage.size.y >= float(resolution.y) * 0.62 and stage.stage_canvas.size.x >= float(resolution.x) * 0.95, "owner correction: battle scene dominates height and fills width")
			check(ground.span >= float(resolution.x) * 0.65, "owner correction: projected floor occupies at least 65 percent of screen width")
			check(not screen.history_window.visible, "battle history initially collapsed for larger arena")
			var corners: PackedVector2Array = ground.corners
			check(corners.size() == 4 and is_equal_approx(corners[1].x - corners[3].x, 2.0 * (corners[2].y - corners[0].y)), "reference diamond has true 2:1 projection")
			check(ground.left_edge.polygon.size() == 4 and ground.right_edge.polygon.size() == 4, "raised floor has both opaque front faces")
			for actor in [stage.hero_actor, stage.enemy_actor]:
				check(Geometry2D.is_point_in_polygon(actor.position, corners), "both feet inside the same physical-looking plane")
				check(actor.get_local_foot_anchor().distance_to(Vector2.ZERO) < 0.01 and actor.shadow.position == Vector2.ZERO, "authored feet and shadow remain fixed to ground origin")
				check(actor.position.y - actor.target_height >= 0, "no clipped actor head")
			check(stage.actor_layer.y_sort_enabled and stage.hero_origin.y > stage.enemy_origin.y and stage.hero_origin.x < stage.enemy_origin.x, "front-left hero and rear-right opponent use native depth order")
			var viewport_rect := Rect2(Vector2.ZERO, Vector2(resolution))
			for card in [screen.player_card, screen.enemy_card]:
				check(viewport_rect.encloses(card.get_global_rect()) and card.global_position.y >= stage.global_position.y + stage.size.y, "HP/intent dock below arena inside viewport")
			for button in screen.buttons.values():
				check(viewport_rect.encloses(button.get_global_rect()) and button.global_position.y >= screen.enemy_card.get_global_rect().end.y, "fixed commands remain below status and within viewport")
			check(world.to_canonical_json() == before, "projection and layout are pure")
			screen.history_toggle.button_pressed = true
			for frame in range(12):
				await process_frame
			check(screen.history_window.visible and viewport_rect.encloses(screen.history_window.get_global_rect()), "history expands inside viewport")
			for button in screen.buttons.values():
				check(viewport_rect.encloses(button.get_global_rect()), "commands remain reachable with expanded history")
			check(world.to_canonical_json() == before, "expanding history changes no authoritative state")
			screen.history_toggle.button_pressed = false
			var twin := world.duplicate_state()
			var intent := screen.payload_for("SHOOT")
			check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, intent)).success, "independent headless reference")
			screen.reduce_motion.button_pressed = environment != "camp"
			await screen.perform(intent)
			check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "isometric receipt feedback has identical authoritative SHA-256")
			check(engine.validate_invariants(world) == "", "global invariants after feedback")
			var loaded := WorldState.from_json_checked(world.to_canonical_json())
			check(loaded.success and loaded.world.to_canonical_json() == world.to_canonical_json(), "checked save/resume unchanged")
			if not world.field_state.battle.is_empty():
				screen.reduce_motion.button_pressed = true
				await screen.perform(screen.payload_for("FLEE"))
			check(screen.history_window.visible and screen.buttons.has("CONFIRM"), "result receipts automatically expand with explicit confirmation")
			screen.queue_free()
			await process_frame
		var named := Fixture.create("shed", false, engine, false)
		named.npc_registry.get_npc(named.player.npc_id).name = "南方商道上的失散修理匠與最後的同行者"
		var keyboard := Screen.new()
		root.add_child(keyboard)
		keyboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		keyboard.setup(named, engine)
		keyboard.reduce_motion.button_pressed = true
		for frame in range(12):
			await process_frame
		for card in [keyboard.player_card, keyboard.enemy_card]:
			check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(card.get_global_rect()), "long name wraps without moving HUD outside viewport")
		keyboard.buttons.START.grab_focus()
		check(keyboard.buttons.START.has_focus(), "fixed start command receives keyboard focus")
		var expected := named.duplicate_state()
		check(engine.commit_player_intent(expected, PlayerIntent.create_field_action(expected.player.npc_id, {"command": "START"})).success, "keyboard reference start authorized")
		for pressed in [true, false]:
			var accept := InputEventAction.new()
			accept.action = "ui_accept"
			accept.pressed = pressed
			root.push_input(accept)
			await process_frame
		await create_timer(0.4).timeout
		check(not named.field_state.battle.is_empty() and named.to_canonical_json().sha256_text() == expected.to_canonical_json().sha256_text(), "keyboard accept commits the same real start intent")
		keyboard.close()
		check(not keyboard.is_queued_for_deletion(), "keyboard-started unresolved battle cannot be closed")
		keyboard.queue_free()
		await process_frame
	print("COMBAT-ISO: %s assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
