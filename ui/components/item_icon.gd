extends TextureRect

# Shared presentation-only art. Item names and quantities stay in adjacent labels.
const ITEM_IDS := ["water", "food", "scrap", "fuel", "caps", "crowbar"]
const ItemRegistry = preload("res://simulation/item_registry.gd")
const ItemArt = preload("res://game_data/item_art_references.gd")
static var texture_cache: Dictionary = {}
var item_id: String = ""

static func make(id: String, edge: int = 32) -> TextureRect:
	return load("res://ui/components/item_icon.gd").new(id, edge)

static func texture_for(id: String) -> Texture2D:
	if texture_cache.has(id):
		return texture_cache[id]
	var path := ""
	if id in ITEM_IDS:
		path = "res://ui/assets/items/%s.png" % id
	else:
		var resolved := ItemRegistry.resolve(id)
		if not resolved.success:
			return null
		var art := ItemArt.resolve(resolved.definition.asset_id)
		if not art.success:
			return null
		path = art.path
	var loaded: Texture2D = null
	if ResourceLoader.exists(path):
		loaded = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		# Raw-image fallback also supports headless runs before editor import.
		var source := Image.load_from_file(path)
		if source != null and not source.is_empty():
			loaded = ImageTexture.create_from_image(source)
	if loaded != null:
		texture_cache[id] = loaded
	return loaded

func _init(id: String = "", pixels: int = 32) -> void:
	item_id = id
	custom_minimum_size = Vector2(pixels, pixels)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture = texture_for(id)
