class_name EventRecord
extends RefCounted

var day: int = 0
var type: String = ""
var actor_id: StringName = &""
var target_id: StringName = &""
var payload: Dictionary = {}

func _init(
	p_day: int = 0,
	p_type: String = "",
	p_actor_id: StringName = &"",
	p_target_id: StringName = &"",
	p_payload: Dictionary = {}
) -> void:
	day = p_day
	type = p_type
	actor_id = p_actor_id
	target_id = p_target_id
	payload = p_payload

func duplicate_record() -> EventRecord:
	return EventRecord.new(day, type, actor_id, target_id, payload.duplicate(true))

func to_dict() -> Dictionary:
	return {
		"day": day,
		"type": type,
		"actor_id": String(actor_id),
		"target_id": String(target_id),
		"payload": payload
	}

static func from_dict(data: Dictionary) -> EventRecord:
	return EventRecord.new(
		int(data.get("day", 0)),
		data.get("type", ""),
		StringName(data.get("actor_id", "")),
		StringName(data.get("target_id", "")),
		data.get("payload", {})
	)
