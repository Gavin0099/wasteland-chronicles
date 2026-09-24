extends SceneTree

# Artwork review only. No runtime catalogue registration or gameplay state.
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const ThemeResource = preload("res://ui/theme/survivor_pda_theme.tres")
const ASSET_DIR := "res://ui/assets/items/candidates/"
const OUTPUT_DIR := "res://artifacts/item-art-v0-batch2/"
const GROUPS := [
	{"id": "weapons", "name": "常見近戰", "items": [
		["rusty_knife", "生鏽小刀"], ["hunting_knife", "獵刀"],
		["rebar_club", "鋼筋棍"], ["scrap_machete", "廢鐵砍刀"]
	]},
	{"id": "clothing", "name": "旅行穿著", "items": [
		["work_clothes", "舊工作服"], ["desert_robe", "沙地長袍"],
		["caravan_coat", "商隊外套"], ["travel_backpack", "舊旅行包"]
	]},
	{"id": "tools", "name": "常用用品", "items": [
		["rope", "繩索"], ["flashlight", "手電筒"],
		["wrench", "扳手"], ["medkit", "急救包"]
	]}
]

var textures: Dictionary = {}

func _init() -> void:
	call_deferred("run")

func load_assets() -> bool:
	for group in GROUPS:
		for item in group.items:
			var path: String = ASSET_DIR + item[0] + ".png"
			if not FileAccess.file_exists(path):
				push_error("Missing review artwork: " + path)
				return false
			var texture: Texture2D
			if ResourceLoader.exists(path):
				texture = load(path) as Texture2D
			else:
				var source := Image.load_from_file(path)
				if source == null or source.is_empty():
					push_error("Unreadable review artwork: " + path)
					return false
				texture = ImageTexture.create_from_image(source)
			if texture == null:
				push_error("Failed to load review texture: " + path)
				return false
			textures[item[0]] = texture
	return true

func label_in(parent: Node, text: String, variant: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func image_in(parent: Node, id: String, pixels: int) -> TextureRect:
	var preview := TextureRect.new()
	preview.texture = textures[id]
	preview.custom_minimum_size = Vector2(pixels, pixels)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(preview)
	return preview

func card_in(parent: Node, item: Array, category: String, preview_size: int) -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "PdaPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", Tokens.GAP)
	panel.add_child(column)
	image_in(column, item[0], preview_size)
	var caption := HBoxContainer.new()
	caption.alignment = BoxContainer.ALIGNMENT_CENTER
	caption.add_theme_constant_override("separation", Tokens.GAP)
	column.add_child(caption)
	label_in(caption, item[1], "PdaSection")
	label_in(caption, category, "PdaMuted")
	var samples := HBoxContainer.new()
	samples.alignment = BoxContainer.ALIGNMENT_CENTER
	samples.add_theme_constant_override("separation", Tokens.PAD)
	column.add_child(samples)
	for pixels in [32, 48]:
		var pair := HBoxContainer.new()
		pair.alignment = BoxContainer.ALIGNMENT_CENTER
		pair.add_theme_constant_override("separation", Tokens.GAP)
		samples.add_child(pair)
		image_in(pair, item[0], pixels)
		label_in(pair, "%d px" % pixels, "PdaMuted")

func build_gallery(groups: Array, title: String, preview_size: int) -> Control:
	var gallery := Control.new()
	gallery.theme = ThemeResource
	gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(gallery)
	var backdrop := ColorRect.new()
	backdrop.color = Tokens.BASE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gallery.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	gallery.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", Tokens.PAD)
	margin.add_child(layout)
	label_in(layout, title, "PdaTitle")
	label_in(layout, "物品世界 V0 · 候選美術 / 圖片已製作，尚未啟用對應玩法", "PdaMuted")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", Tokens.PAD)
	grid.add_theme_constant_override("v_separation", Tokens.PAD)
	layout.add_child(grid)
	for group in groups:
		for item in group.items:
			card_in(grid, item, group.name, preview_size)
	return gallery

func capture(file: String) -> bool:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT_DIR + file)
	if error != OK:
		push_error("Unable to save artwork review: %s (%d)" % [file, error])
		return false
	print("Artwork review saved: " + file)
	return true

func run() -> void:
	if not load_assets():
		quit(1)
		return
	root.size = Vector2i(1600, 1080)
	var gallery := build_gallery(GROUPS, "荒原物品 / 常用素材第二批", 180)
	if not await capture("catalogue.png"):
		quit(1)
		return
	gallery.queue_free()
	await process_frame
	root.size = Vector2i(1280, 720)
	for group in GROUPS:
		gallery = build_gallery([group], "荒原物品 / " + group.name, 248)
		if not await capture(group.id + ".png"):
			quit(1)
			return
		gallery.queue_free()
		await process_frame
	textures.clear()
	print("PASS: 12 artwork candidates, four review sheets.")
	quit(0)
