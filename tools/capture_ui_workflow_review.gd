extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const OUT_DIR := "res://artifacts/ui-workflow-review"

func _init() -> void:
	call_deferred("capture")

func _save_view(size: Vector2i, label: String) -> bool:
	root.size = size
	for frame in range(5):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [OUT_DIR, label, size.x, size.y]
	var image: Image = root.get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("UI workflow capture failed: " + path)
		return false
	print("CAPTURED ", path)
	return true

func _reach_dry_well(world: WorldState, engine: SimulationEngine) -> bool:
	if not engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success:
		return false
	for turn in range(12):
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life.status == NpcLifeState.Status.SETTLED:
			return String(life.population_container_id) == "settlement:dry_well"
		if world.pending_encounter_result >= 0:
			if not engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success:
				return false
		elif world.active_encounter != null:
			var selected := &""
			for option in TravelEncounter.options(world.active_encounter.encounter_type):
				if engine.authorize_encounter_option(world, option.id) == "":
					selected = option.id
					break
			if selected == &"" or not engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, selected)).success:
				return false
		else:
			return false
	return false

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "灰谷信差", "age": 24,
		"background_id": "SCAVENGER", "trait_ids": []}))
	if not result.success:
		push_error("UI workflow capture: character creation failed")
		quit(1)
		return
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, engine)
	for size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		if not await _save_view(size, "gray_valley_local"):
			quit(1)
			return
		shell.select_settlement("settlement:new_hope")
		if not await _save_view(size, "gray_valley_inspecting_remote"):
			quit(1)
			return
		if size.x == 1152:
			shell.btn_local_market.pressed.emit()
			if not await _save_view(size, "gray_valley_market_shortcut"):
				quit(1)
				return
		shell.select_settlement("settlement:gray_valley")
		shell.right_scroll.scroll_vertical = 0
	if not engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, "gray_valley_rope_run")).success or not engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rope", 1)).success or not _reach_dry_well(world, engine):
		push_error("UI workflow capture: cannot reach quest turn-in")
		quit(1)
		return
	if not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, "gray_valley_rope_run")).success:
		push_error("UI workflow capture: quest turn-in failed")
		quit(1)
		return
	shell.select_settlement("settlement:new_hope")
	shell.refresh_ui()
	for size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		if not await _save_view(size, "dry_well_inspecting_remote"):
			quit(1)
			return
		shell._on_quest_access_pressed()
		if not await _save_view(size, "dry_well_completed_journal"):
			quit(1)
			return
		shell._on_quest_close_pressed()
	shell.queue_free()
	await process_frame
	quit(0)

