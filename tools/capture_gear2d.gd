extends SceneTree
const Fixture = preload("res://tests/fixtures/gear2c_world.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
var output_dir: String = OS.get_user_data_dir().path_join("captures/gear2d")

func _init() -> void:
	call_deferred("capture")

func frame(label: String) -> void:
	for step: int in range(12):
		await process_frame
	assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, label, root.size.x, root.size.y]) == OK)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var engine := SimulationEngine.new()
		for mode: String in ["rare_sheet", "quickdraw_battle", "balanced_battle", "discount_methods", "discount_receipt", "equipped_delivery"]:
			var world: WorldState = Fixture.repair_site("fieldrepair_precision_kit") if mode.begins_with("discount") else Fixture.fresh("settlement:new_hope")
			if mode == "rare_sheet":
				for spec: Array in [["expedition_travel_backpack", "back"], ["plated_leather_jacket", "body"]]:
					assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(spec[0]), 1)).success)
					assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(spec[0]), spec[1])).success)
			var handoff_job: String = ""
			if mode == "equipped_delivery":
				assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"rusted_knife", 1)).success)
				assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"rusted_knife", "main_hand")).success)
				var town: SettlementState = world.get_settlement(&"settlement:new_hope")
				assert(town.item_market.remove("rusted_knife", town.item_market.quantity("rusted_knife")).success)
				for entry: Dictionary in JobBoard.postings(world, &"settlement:new_hope"):
					if String(entry.definition.id).contains("item_request_rusted_knife"):
						handoff_job = entry.definition.id
				assert(handoff_job != "" and engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, handoff_job)).success)
			if mode.begins_with("discount"):
				world.player.capability._data.skill_ranks.MECHANICS = 3
				world.player.inventory.set_amount("scrap", 2)
				if mode == "discount_receipt":
					assert(Fixture.answer(world, &"OVERHAUL_PUMP").success)
			if mode.ends_with("battle"):
				var weapon: String = "quickdraw_police_revolver" if mode.begins_with("quick") else "balanced_combat_knife"
				assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(weapon), 1)).success)
				assert(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(weapon), "main_hand")).success)
				if mode.begins_with("quick"):
					assert(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"revolver_round", 3)).success)
				Fixture.resupply(world)
				assert(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success)
				world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:new_hope", &"settlement:dry_well", 1, {"target_enemy": "heavy_raider"})
				assert(Fixture.answer(world, &"FIGHT").success)
				var field: Control = FieldScreen.new()
				root.add_child(field)
				field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				field.setup(world, engine)
				await frame(mode)
				field.queue_free()
			else:
				var shell := PlayableShell.new()
				root.add_child(shell)
				shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				shell.setup(world, engine)
				if mode == "rare_sheet":
					shell._show_character()
				if mode == "equipped_delivery":
					shell.quest_id_shown = handoff_job
					shell._on_quest_access_pressed()
				await frame(mode)
				if mode == "rare_sheet":
					for child in shell.get_children():
						if child.get_script() == preload("res://ui/components/character_sheet.gd"):
							var scrolls: Array[Node] = child.find_children("*", "ScrollContainer", true, false)
							if scrolls.size() >= 2:
								scrolls[1].scroll_vertical = 280
								await frame("rare_properties")
				shell.queue_free()
			await process_frame
	print("CAPTURED " + output_dir)
	quit(0)

