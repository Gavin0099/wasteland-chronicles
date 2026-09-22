extends SceneTree

const ItemIcon = preload("res://ui/components/item_icon.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")

func _init() -> void:
	call_deferred("run")

func shot(file: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/common-items/" + file)

func label_in(parent: Node, text: String, variant: String = "") -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var gallery := PanelContainer.new()
	gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(gallery)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	gallery.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	label_in(layout, "荒原物資 / 常用素材第一批", "PdaTitle")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	layout.add_child(grid)
	var names := {"water": "水壺", "food": "口糧", "scrap": "廢料", "fuel": "燃料", "caps": "瓶蓋", "crowbar": "撬棍"}
	for id in ItemIcon.ITEM_IDS:
		var panel := PanelContainer.new()
		panel.theme_type_variation = "PdaPanel"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		panel.add_child(column)
		column.add_child(ItemIcon.make(id, 168))
		label_in(column, names[id], "PdaSection")
		var small := HBoxContainer.new()
		small.alignment = BoxContainer.ALIGNMENT_CENTER
		small.add_theme_constant_override("separation", 16)
		column.add_child(small)
		small.add_child(ItemIcon.make(id, 32))
		small.add_child(ItemIcon.make(id, 48))
	await shot("catalogue.png")
	gallery.queue_free()
	await process_frame
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.creation.name_input.text = "阿灰"
	main.creation.select_background("MECHANIC")
	main.creation.submit()
	main.creation.enter_button.pressed.emit()
	await shot("market.png")
	main.engine.commit_player_intent(main.world, PlayerIntent.create_buy(main.world.player.npc_id, &"scrap", 3))
	main.shell._show_field()
	var screen = main.shell.get_node("FieldScreen")
	screen.reduce_motion.button_pressed = true
	await screen.perform({"command": "CRAFT"})
	await screen.perform({"command": "EQUIP"})
	await screen.perform({"command": "START"})
	await shot("battle.png")
	await screen.perform(screen.payload_for("ATTACK"))
	await screen.perform(screen.payload_for("DEFEND"))
	await screen.perform(screen.payload_for("ATTACK"))
	await screen.perform(screen.payload_for("CONFIRM"))
	await screen.perform({"command": "OPEN"})
	root.size = Vector2i(1152, 648)
	await shot("loot-small.png")
	await screen.perform(screen.payload_for("CONFIRM"))
	screen.close()
	await process_frame
	main.shell._show_character()
	await shot("character-small.png")
	root.size = Vector2i(1280, 720)
	await shot("character.png")
	main.queue_free()
	await process_frame
	quit()
