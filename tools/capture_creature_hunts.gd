extends "res://tests/test_creature_hunts.gd"

var output_dir: String = OS.get_user_data_dir().path_join("captures/creature-hunts")
var captures: int = 0
var pending_frames: int = 0
var phase_prefix: String = ""
var seen: Dictionary = {}

func _init() -> void:
	call_deferred("capture")

func frame(label: String) -> void:
	pending_frames += 1
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)
	captures += 1
	pending_frames -= 1

func phase(phase_name: String) -> void:
	if phase_prefix == "" or phase_name not in ["enemy_windup", "blocked", "enemy_fall"]: return
	var label: String = phase_prefix + "_" + phase_name
	if seen.has(label): return
	seen[label] = true
	frame(label)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		seen.clear()
		for spec: Dictionary in SPECS:
			var world: WorldState = hunter(spec)
			var entry: Dictionary = posting(world, spec)
			assert(not entry.is_empty() and failures == 0)
			var shell: PlayableShell = Shell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			shell.quest_id_shown = entry.definition.id
			shell._on_quest_access_pressed()
			var unchanged: String = world.to_canonical_json()
			for tick: int in range(8): await process_frame
			await frame(spec.enemy + "_board")
			assert(world.to_canonical_json() == unchanged)
			shell.queue_free()
			await process_frame
			assert(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id)).success)
			assert(reach_target(world, spec, entry.definition.id) and failures == 0)
			shell = Shell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			unchanged = world.to_canonical_json()
			for tick: int in range(8): await process_frame
			await frame(spec.enemy + "_encounter")
			assert(world.to_canonical_json() == unchanged)
			shell.queue_free()
			await process_frame
			assert(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT")).success)
			var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
			assert(loaded.success)
			var twin: WorldState = loaded.world
			var ui: Control = Screen.new()
			root.add_child(ui)
			ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ui.setup(world, engine)
			ui.stage.feedback_phase.connect(phase)
			for tick: int in range(8): await process_frame
			assert(not ui.stage.showing_placeholder and not ui.buttons.ATTACK.disabled)
			await frame(spec.enemy + "_idle")
			for step: int in range(12):
				if world.field_state.battle.is_empty(): break
				var turn: int = int(world.field_state.battle.turn)
				var move: String = "DEFEND" if int(spec.pattern[(turn - 1) % 8]) >= 5 else "ATTACK"
				phase_prefix = spec.enemy + "_turn" + str(turn)
				var data: Dictionary = ui.payload_for(move)
				assert(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, data)).success)
				await ui.perform(data)
				parity(world, twin, "rendered creature turn")
				assert(failures == 0)
				if turn == 1: await frame(spec.enemy + "_after_first")
				if not world.field_state.battle.is_empty() and bool(Enemies.action_for(spec.enemy, turn + 1).heavy): await frame(spec.enemy + "_heavy_ready_turn" + str(turn + 1))
			phase_prefix = ""
			assert(world.field_state.receipt >= 0 and world.event_log[world.field_state.receipt].payload.outcome == "VICTORY")
			await frame(spec.enemy + "_victory")
			ui.queue_free()
			await process_frame
			world = battle_world(spec)
			assert(failures == 0)
			ui = Screen.new()
			root.add_child(ui)
			ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ui.setup(world, engine)
			ui.reduce_motion.button_pressed = true
			twin = WorldState.from_json_checked(world.to_canonical_json()).world
			var escape: Dictionary = ui.payload_for("FLEE")
			assert(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, escape)).success)
			await ui.perform(escape)
			parity(world, twin, "rendered reduced escape")
			assert(failures == 0)
			await frame(spec.enemy + "_reduced_escape")
			ui.queue_free()
			await process_frame
	for drain: int in range(120):
		if pending_frames == 0: break
		RenderingServer.force_draw()
		await process_frame
	assert(pending_frames == 0 and failures == 0)
	print("CREATURE CAPTURE: %d frames -> %s" % [captures, output_dir])
	quit(0)
