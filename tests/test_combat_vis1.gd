extends SceneTree

const Screen = preload("res://ui/field_screen.gd")
const Fixture = preload("res://tests/fixtures/combat_vis1_world.gd")
var assertions := 0
var failures := 0
var engine := SimulationEngine.new()

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("COMBAT-VIS-1: " + label)

func _init() -> void:
	call_deferred("run")

func settle() -> void:
	for frame in range(12):
		await process_frame

func run() -> void:
	for resolution in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for environment in ["shed", "highway", "wilderness", "camp"]:
			for firearm in [false, true]:
				var world := Fixture.create(environment, firearm, engine)
				check(not world.field_state.battle.is_empty(), "fixture starts a real battle")
				check(Screen.environment_for(world) == environment, "truthful environment from battle")
				var before := world.to_canonical_json().sha256_text()
				var opponent: String = Screen.Field.battle_enemy(world.field_state)
				var ui := Screen.new()
				root.add_child(ui)
				ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				ui.setup(world, engine)
				await settle()
				ui.refresh()
				await settle()
				check(before == world.to_canonical_json().sha256_text(), "layout/refresh never mutate world")
				var stage = ui.stage
				check(stage.wilderness_background.texture != null and stage.camp_background.texture != null, "authored environment assets load")
				check(stage.environment_id == environment, "stage uses projected environment")
				check(not stage.configure_environment("invented_arena") and stage.environment_id == environment, "unknown environment rejected without changing scene")
				check(stage.hero_origin.x < stage.enemy_origin.x and stage.hero_origin.y > stage.enemy_origin.y, "reference revision: player front-left, opponent back-right")
				check(ui.player_bar.get_meta("caption").text.contains("荒原旅人"), "real player identity near fighter")
				check(ui.intent_label.get_parent() == ui.enemy_bar.get_parent().get_parent(), "intent belongs to enemy card")
				check(ui.status_label.text.contains("左輪" if firearm else "砍刀"), "actual weapon label")
				check(stage.weapon.visible and stage.current_weapon_id == ("old_revolver" if firearm else "scrap_machete"), "held weapon art")
				var viewport_rect := Rect2(Vector2.ZERO, Vector2(resolution))
				for button in ui.buttons.values():
					check(viewport_rect.encloses(button.get_global_rect()), "all commands remain within viewport")
					check(button.global_position.y >= stage.global_position.y + stage.size.y, "commands below arena")
				for pair in [[ui.player_card, stage.hero_actor], [ui.enemy_card, stage.enemy_actor]]:
					var card: Control = pair[0]
					var actor = pair[1]
					check(card.global_position.y >= stage.global_position.y + stage.size.y, "reference revision: fixed HUD below the arena")
				check(not ui.player_card.get_global_rect().intersects(ui.enemy_card.get_global_rect()), "combatant cards never overlap")
				var twin := world.duplicate_state()
				var command := "SHOOT" if firearm else "ATTACK"
				var payload: Dictionary = ui.payload_for(command)
				check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, payload)).success, "headless reference action")
				ui.reduce_motion.button_pressed = environment != "highway"
				await ui.perform(payload)
				check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "UI/headless dual-track SHA-256 replay")
				check(engine.validate_invariants(world) == "", "global invariants after UI action")
				var loaded := WorldState.from_json_checked(world.to_canonical_json())
				check(loaded.success and loaded.world.to_canonical_json() == world.to_canonical_json(), "checked persistence unchanged")
				ui.reduce_motion.button_pressed = true
				if not world.field_state.battle.is_empty():
					await ui.perform(ui.payload_for("FLEE"))
				check(Screen.environment_for(world) == environment, "result retains original scenery")
				check(ui.stage.current_enemy_id == opponent, "result retains actual opponent art")
				check(ui.enemy_bar.get_meta("caption").text.contains(Screen.Field.Enemies.display_name(opponent)), "result retains actual opponent identity")
				check(ui.buttons.has("CONFIRM"), "fixed result confirmation available")
				await settle()
				check(viewport_rect.encloses(ui.buttons.CONFIRM.get_global_rect()), "result command within viewport")
				ui.queue_free()
				await settle()
		# Preparation has six commands, several with visible refusal reasons.
		var initial := Fixture.create("shed", false, engine, false)
		var preparation := Screen.new()
		root.add_child(preparation)
		preparation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preparation.setup(initial, engine)
		await settle()
		check(preparation.buttons.size() == 6, "six preparation commands")
		for button in preparation.buttons.values():
			check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(button.get_global_rect()), "preparation commands within viewport")
		preparation.queue_free()
		await settle()
	print("COMBAT-VIS-1: %s assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
