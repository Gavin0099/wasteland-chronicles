class_name RankJsonCodec
extends RefCounted

# C1-P0: Godot owns ordinary JSON values and world float semantics. This
# structural pass retains rank token spelling BEFORE integral floats erase it.
# It does not search raw JSON with a regex or infer token types from Dictionary.
var _text: String
var _at := 0
var _error := ""
var _rank_path: Array
var _ranks := {}

static func decode(raw: String, rank_path: Array = ["player", "capability", "skill_ranks"]) -> Dictionary:
	var json := JSON.new()
	if json.parse(raw) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"success": false, "data": null, "error": "INVALID_JSON_OBJECT"}
	var reader = load("res://simulation/rank_json_codec.gd").new()
	reader._text = raw
	reader._rank_path = rank_path
	reader._value([], 0)
	reader._space()
	if reader._error == "" and reader._at != raw.length():
		reader._error = "TRAILING_JSON_CONTENT"
	if reader._error != "":
		return {"success": false, "data": null, "error": reader._error}
	var data: Dictionary = json.data
	var parent: Variant = data
	for key in rank_path:
		if typeof(parent) != TYPE_DICTIONARY or not parent.has(key):
			# Missing domains belong to schema/migration validation, not this codec.
			return {"success": true, "data": data, "error": ""}
		parent = parent[key]
	if typeof(parent) == TYPE_DICTIONARY:
		for key in reader._ranks:
			parent[key] = reader._ranks[key]
	return {"success": true, "data": data, "error": ""}

func _space() -> void:
	while _at < _text.length() and _text[_at] in [" ", "\t", "\r", "\n"]:
		_at += 1

func _take(token: String) -> bool:
	_space()
	if _at < _text.length() and _text[_at] == token:
		_at += 1
		return true
	return false

func _string() -> String:
	_space()
	var start := _at
	if not _take("\""):
		_error = "EXPECTED_JSON_STRING"
		return ""
	while _at < _text.length():
		var ch := _text[_at]
		_at += 1
		if ch == "\\":
			_at += 1 # Native parser already validates string escape syntax.
		elif ch == "\"":
			return String(JSON.parse_string(_text.substr(start, _at - start)))
	_error = "UNTERMINATED_STRING"
	return ""

func _value(path: Array, depth: int) -> void:
	_space()
	if _error != "":
		return
	if depth > 128 or _at >= _text.length():
		_error = "JSON_DEPTH_OR_END"
		return
	if path.size() == _rank_path.size() + 1 and path.slice(0, -1) == _rank_path:
		var start := _at
		while _at < _text.length() and _text[_at] not in [",", "}", "]", " ", "\t", "\r", "\n"]:
			_at += 1
		var token := _text.substr(start, _at - start)
		if token.length() != 1 or token not in ["0", "1", "2", "3", "4", "5"]:
			_error = "INVALID_RANK_TOKEN: %s" % String(path[-1])
			return
		_ranks[path[-1]] = int(token) # Only a validated single integer digit.
		return
	if _take("{"):
		var keys := {}
		if _take("}"):
			return
		while _error == "":
			var key := _string()
			if _error != "":
				return
			if keys.has(key):
				_error = "DUPLICATE_JSON_KEY: %s" % key
				return
			keys[key] = true
			if not _take(":"):
				_error = "EXPECTED_COLON"
				return
			_value(path + [key], depth + 1)
			if _take("}"):
				return
			if not _take(","):
				_error = "EXPECTED_OBJECT_SEPARATOR"
				return
	elif _take("["):
		if _take("]"):
			return
		var index := 0
		while _error == "":
			_value(path + [index], depth + 1)
			index += 1
			if _take("]"):
				return
			if not _take(","):
				_error = "EXPECTED_ARRAY_SEPARATOR"
				return
	elif _text[_at] == "\"":
		_string()
	else:
		var start := _at
		while _at < _text.length() and _text[_at] not in [",", "}", "]", " ", "\t", "\r", "\n"]:
			_at += 1
		if _at == start:
			_error = "EXPECTED_JSON_VALUE"
