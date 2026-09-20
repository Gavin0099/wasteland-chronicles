class_name CharacterCreationIntent
extends RefCounted

# Keep untrusted input uncoerced until validation. No UI and no world writes.
var fields: Dictionary

func _init(raw: Dictionary = {}) -> void:
	fields = raw.duplicate(true)

func to_dict() -> Dictionary:
	return fields.duplicate(true)
