extends TextureRect

# Shared presentation-only art. Item names and quantities stay in adjacent labels.
const ITEM_IDS := ["water", "food", "scrap", "fuel", "caps", "crowbar"]
static var texture_cache: Dictionary = {}
var item_id: String = ""

static func make(id: String, edge: int = 32) -> TextureRect:
	return load("res://ui/components/item_icon.gd").new(id, edge)

static func texture_for(id: String) -> Texture2D:
	if not id in ITEM_IDS:
		return null
	if texture_cache.has(id):
		return texture_cache[id]
	var path := "res://ui/assets/items/%s.png" % id
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
