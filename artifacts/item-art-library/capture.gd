extends SceneTree

# Standalone art review, never a production inventory or world mutation surface.
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const PdaTheme = preload("res://ui/theme/survivor_pda_theme.tres")
const OUTPUT := "res://artifacts/item-art-library/"
var textures: Dictionary = {}

func _init() -> void:
	call_deferred("run")

func label_in(parent: Node, text: String, variant: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variant
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func image_in(parent: Node, path: String, pixels: int) -> void:
	var preview := TextureRect.new()
	preview.texture = textures[path]
	preview.custom_minimum_size = Vector2(pixels, pixels)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(preview)

func build_page(items: Array, title: String) -> Control:
	var page := Control.new()
	page.theme = PdaTheme
	root.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Tokens.BASE
	page.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margins := MarginContainer.new()
	page.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 24)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", Tokens.PAD)
	margins.add_child(layout)
	label_in(layout, title, "PdaTitle")
	label_in(layout, "物品世界 V0 / 素材圖庫 · 圖片不代表物品玩法已啟用", "PdaMuted")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", Tokens.PAD)
	grid.add_theme_constant_override("v_separation", Tokens.PAD)
	layout.add_child(grid)
	for item in items:
		var panel := PanelContainer.new()
		panel.theme_type_variation = "PdaPanel"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", Tokens.GAP)
		panel.add_child(column)
		image_in(column, item.file, 180)
		label_in(column, item.name, "PdaSection")
		var samples := HBoxContainer.new()
		samples.alignment = BoxContainer.ALIGNMENT_CENTER
		samples.add_theme_constant_override("separation", Tokens.PAD)
		column.add_child(samples)
		for pixels in [32, 48]:
			image_in(samples, item.file, pixels)
			label_in(samples, "%d px" % pixels, "PdaMuted")
	return page

func render_page(items: Array, title: String, file: String) -> bool:
	# Load only one page of originals to keep the review run's memory bounded.
	for item in items:
		var source := Image.load_from_file("res://" + item.file)
		if source == null or source.is_empty():
			push_error("Missing artwork: " + item.file)
			return false
		textures[item.file] = ImageTexture.create_from_image(source)
	var page := build_page(items, title)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var status := root.get_texture().get_image().save_png(OUTPUT + file)
	page.queue_free()
	await process_frame
	textures.clear()
	if status != OK:
		push_error("Cannot save review: " + file)
		return false
	print("Saved: " + file)
	return true

func run() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ui/assets/items/library/catalogue.json"))
	var selected: Array[int] = []
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--section="):
			selected.append(argument.trim_prefix("--section=").to_int())
	if selected.is_empty() and int(catalogue.get("pending", -1)) != 0:
		push_error("Full art review requires completed catalogue; rebuild index first.")
		quit(1)
		return
	root.size = Vector2i(1600, 1080)
	var pages := 0
	var covered_rows := 0
	for section in catalogue.sections:
		if not selected.is_empty() and not int(section.id) in selected:
			continue
		var items: Array = []
		for item in catalogue.items:
			if float(section.id) in item.sections:
				if item.status == "PENDING":
					push_error("Unfinished artwork: " + str(item.name))
					quit(1)
					return
				items.append(item)
		if items.is_empty():
			push_error("Empty art category: " + str(section.id))
			quit(1)
			return
		covered_rows += items.size()
		var page_count := ceili(float(items.size()) / 12.0)
		for page_index in range(page_count):
			var selection := items.slice(page_index * 12, mini(items.size(), (page_index + 1) * 12))
			var title := "%02d / %s · %d/%d" % [section.id, section.name, page_index + 1, page_count]
			var file := "category-%02d-%02d.png" % [section.id, page_index + 1]
			if not await render_page(selection, title, file):
				quit(1)
				return
			pages += 1
	if not selected.is_empty():
		if pages == 0:
			push_error("No requested category exists")
			quit(1)
			return
		print("PASS: selected categories, %d rows / %d sheets." % [covered_rows, pages])
		quit(0)
		return
	if covered_rows != 187:
		push_error("Expected 187 category rows, got " + str(covered_rows))
		quit(1)
		return
	# Representative cover; every item remains available on its category sheet.
	var cover: Array = []
	for wanted in ["工兵鏟", "老式左輪", "商隊步槍", "農務服", "防毒面具", "登山背包", "濾水器", "工具箱", "種子", "舊世界手錶", "鳴石", "沒有寄出的信"]:
		for item in catalogue.items:
			if item.name == wanted:
				cover.append(item)
	if not await render_page(cover, "荒原物品 / 完整素材圖庫選覽", "cover.png"):
		quit(1)
		return
	print("PASS: %d category sheets cover 187 rows / 185 names, plus one cover." % pages)
	quit(0)
