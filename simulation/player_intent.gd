class_name PlayerIntent
extends RefCounted

# ==============================================================================
# S5-A: PLAYER ACTION INTENT
# ==============================================================================
# Human input is translated into a structured PlayerIntent before reaching the
# simulation engine. The simulation engine authorizes and commits the intent
# through the same physical rules and transactions as NPCs.
#
# CLOSED ACTION SPACE (S5-A):
#   WAIT   = 0 (Stay in place, let time pass)
#   TRAVEL = 1 (Move to another settlement via physical route)
# ==============================================================================

enum Action {
	WAIT   = 0,
	TRAVEL = 1,
}

const AUTHORIZED_ACTIONS: Array[int] = [Action.WAIT, Action.TRAVEL]

var action: int = Action.WAIT
var player_id: StringName = &""
var destination_id: StringName = &""
var payload: Dictionary = {}

func _init(
	p_action: int = Action.WAIT,
	p_player_id: StringName = &"",
	p_destination_id: StringName = &"",
	p_payload: Dictionary = {}
) -> void:
	action = p_action
	player_id = p_player_id
	destination_id = p_destination_id
	payload = p_payload

static func action_name(value: int) -> String:
	match value:
		Action.WAIT: return "WAIT"
		Action.TRAVEL: return "TRAVEL"
		_: return "INVALID(%d)" % value

static func is_authorized_action(value: int) -> bool:
	return value in AUTHORIZED_ACTIONS

static func create_wait(p_player_id: StringName) -> PlayerIntent:
	return PlayerIntent.new(Action.WAIT, p_player_id, &"", {})

static func create_travel(p_player_id: StringName, p_dest_id: StringName) -> PlayerIntent:
	return PlayerIntent.new(Action.TRAVEL, p_player_id, p_dest_id, {})

func to_dict() -> Dictionary:
	return {
		"action": action,
		"player_id": String(player_id),
		"destination_id": String(destination_id),
		"payload": payload.duplicate(true),
	}

static func from_dict(data: Dictionary) -> PlayerIntent:
	return PlayerIntent.new(
		int(data.get("action", Action.WAIT)),
		StringName(data.get("player_id", "")),
		StringName(data.get("destination_id", "")),
		data.get("payload", {})
	)
