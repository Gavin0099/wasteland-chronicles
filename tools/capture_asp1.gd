extends SceneTree

# ASP-1 evidence, real renderer:
#   1. the armory door, locked, saying what it needs
#   2. the old-world saber, held, in a road fight

const Creation = preload("res://simulation/character_creation_intent.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
var output_dir := OS.get_user_data_dir().path_join("captures/asp1-world-secret")

func _init() -> void:
	call_deferred("capture")

func _world() -> Dictionary:
	var world := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "尋寶的人",
		"age": 29, "background_id": "SCAVENGER", "trait_ids": [],
	}))
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	return {"world": world, "engine": engine}

func _save(label: String) -> void:
	for frame in range(10):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]
	if root.get_texture().get_image().save_png(path) == OK:
		print("CAPTURED ", path)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = viewport_size
		var setup := _world()
		var world: WorldState = setup.world
		var shell := PlayableShell.new()
		root.add_child(shell)
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shell.setup(world, setup.engine)
		shell.select_settlement("settlement:new_hope")
		shell.selected_route_type = "WILDERNESS"
		shell.on_travel_pressed()
		var guard := 0
		while guard < 10 and not (world.active_encounter != null and String(world.active_encounter.context.get("place_id", "")) == "place:old_armory"):
			guard += 1
			if world.pending_encounter_result >= 0:
				shell.on_encounter_continue_pressed(world.pending_encounter_result)
				continue
			if world.active_encounter == null:
				break
			var choice := "LEAVE"
			match world.active_encounter.encounter_type:
				TravelEncounter.BANDIT_AMBUSH: choice = "FLEE_ROAD"
				TravelEncounter.ROCKSLIDE: choice = "DETOUR"
				TravelEncounter.ROADBLOCK: choice = "PAY"
			shell.on_encounter_option_pressed(choice)
		shell.refresh_ui()
		await _save("1_armory_locked")
		shell.queue_free()
		await process_frame

		var fight := _world()
		var fw: WorldState = fight.world
		fw.player.item_inventory.pickup_item("old_world_saber", 1)
		fight.engine.commit_player_intent(fw, PlayerIntent.create_equip_item(fw.player.npc_id, &"old_world_saber", "main_hand"))
		WorldState.Field.begin_road_battle(fw, {"target_enemy": "heavy_raider", "route_type": "WILDERNESS"})
		var screen = FieldScreen.new()
		root.add_child(screen)
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		screen.setup(fw, fight.engine)
		await _save("2_saber_in_hand")
		screen.queue_free()
		await process_frame
	quit(0)
