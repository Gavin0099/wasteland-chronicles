extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Party = preload("res://simulation/party.gd")
var engine := SimulationEngine.new()
var output_dir := OS.get_user_data_dir().path_join("captures/party2a")

func _init() -> void:
	call_deferred("capture")

func save_frame(label: String, shell: PlayableShell, control: String = "") -> void:
	for frame in range(10):
		await process_frame
	if shell.companion_buttons.has(control):
		var button: Control = shell.companion_buttons[control]
		var scroll: ScrollContainer = button.get_parent().get_parent()
		scroll.ensure_control_visible(button)
	for frame in range(4):
		await process_frame
	root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y])

func close_dialogs(shell: PlayableShell) -> void:
	for child in shell.get_children():
		if child is AcceptDialog:
			child.hide()
			child.queue_free()

func journey(world: WorldState, target: StringName, shell: PlayableShell) -> void:
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, target))
	for step in range(24):
		if world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
			continue
		if world.active_encounter == null:
			return
		var option: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: option = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: option = &"DETOUR"
			TravelEncounter.ROADBLOCK: option = &"PAY"
			TravelEncounter.PLACE_VISIT:
				if world.active_encounter.context.get("companion_request", false):
					shell.refresh_ui()
					await save_frame("site", shell)
					option = &"RECOVER_ABBAN_TOOL"
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = size
		var world := S1WorldData.create_s1_world()
		engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "同行者", "age": 28, "background_id": "SCAVENGER", "trait_ids": []}))
		world.player.money = 500
		engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Party.ABBAN))
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, engine)
		shell._show_training()
		await save_frame("choices", shell, "REFUSE")
		shell.companion_buttons.ACCEPT.pressed.emit()
		for frame in range(5): await process_frame
		await save_frame("accepted", shell)
		close_dialogs(shell)
		await journey(world, &"settlement:new_hope", shell)
		shell.refresh_ui()
		shell._show_training()
		await save_frame("request", shell, "request")
		shell.companion_buttons.request.pressed.emit()
		await save_frame("fulfilled", shell)
		shell.companion_buttons.dismiss.pressed.emit()
		await process_frame
		await journey(world, &"settlement:gray_valley", shell)
		shell.refresh_ui()
		shell._show_training()
		await save_frame("rehire", shell, Party.ABBAN)
		shell.queue_free()
		await process_frame
	print("CAPTURED " + output_dir)
	quit(0)
