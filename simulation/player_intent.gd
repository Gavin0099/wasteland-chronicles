class_name PlayerIntent
extends RefCounted

# ==============================================================================
# S5-A: PLAYER ACTION INTENT
# ==============================================================================
# Human input is translated into a structured PlayerIntent before reaching the
# simulation engine. The simulation engine authorizes and commits the intent
# through the same physical rules and transactions as NPCs.
#
# CLOSED ACTION SPACE (S5-B2):
#   WAIT   = 0 (Stay in place, let time pass)
#   TRAVEL = 1 (Move to another settlement via physical route)
#   BUY    = 2 (Purchase commodity from current settlement)
#   SELL   = 3 (Sell commodity to current settlement)
#   RESOLVE_ENCOUNTER = 4 (S5-B4: choose an option on a roadside encounter)
#   CONTINUE_JOURNEY = 5 (confirm a committed result, then resume travel)
# ==============================================================================

enum Action {
	WAIT              = 0,
	TRAVEL            = 1,
	BUY               = 2,
	SELL              = 3,
	RESOLVE_ENCOUNTER = 4,
	CONTINUE_JOURNEY = 5,
	FIELD_ACTION = 6,
	EQUIP_ITEM = 7,
	UNEQUIP_ITEM = 8,
}

const AUTHORIZED_ACTIONS: Array[int] = [Action.WAIT, Action.TRAVEL, Action.BUY, Action.SELL, Action.RESOLVE_ENCOUNTER, Action.CONTINUE_JOURNEY, Action.FIELD_ACTION, Action.EQUIP_ITEM, Action.UNEQUIP_ITEM]

var action: int = Action.WAIT
var player_id: StringName = &""
var destination_id: StringName = &""
var commodity: StringName = &""
var item_id: StringName = &""
var quantity: int = 0
var payload: Dictionary = {}

func _init(
	p_action: int = Action.WAIT,
	p_player_id: StringName = &"",
	p_destination_id: StringName = &"",
	p_payload: Dictionary = {},
	p_commodity: StringName = &"",
	p_quantity: int = 0,
	p_item_id: StringName = &""
) -> void:
	action = p_action
	player_id = p_player_id
	destination_id = p_destination_id
	payload = p_payload
	commodity = p_commodity
	item_id = p_item_id
	quantity = p_quantity

static func action_name(value: int) -> String:
	match value:
		Action.FIELD_ACTION: return "FIELD_ACTION"
		Action.EQUIP_ITEM: return "EQUIP_ITEM"
		Action.UNEQUIP_ITEM: return "UNEQUIP_ITEM"
		Action.WAIT: return "WAIT"
		Action.TRAVEL: return "TRAVEL"
		Action.BUY: return "BUY"
		Action.SELL: return "SELL"
		Action.RESOLVE_ENCOUNTER: return "RESOLVE_ENCOUNTER"
		Action.CONTINUE_JOURNEY: return "CONTINUE_JOURNEY"
		_: return "INVALID(%d)" % value

static func is_authorized_action(value: int) -> bool:
	return value in AUTHORIZED_ACTIONS

static func create_wait(p_player_id: StringName) -> PlayerIntent:
	return PlayerIntent.new(Action.WAIT, p_player_id, &"", {})

static func create_travel(p_player_id: StringName, p_dest_id: StringName) -> PlayerIntent:
	return PlayerIntent.new(Action.TRAVEL, p_player_id, p_dest_id, {})

static func create_buy(p_player_id: StringName, p_commodity: StringName, p_quantity: int) -> PlayerIntent:
	return PlayerIntent.new(Action.BUY, p_player_id, &"", {}, p_commodity, p_quantity)

static func create_sell(p_player_id: StringName, p_commodity: StringName, p_quantity: int) -> PlayerIntent:
	return PlayerIntent.new(Action.SELL, p_player_id, &"", {}, p_commodity, p_quantity)

static func create_buy_item(p_player_id: StringName, p_item_id: StringName, p_quantity: int) -> PlayerIntent:
	return PlayerIntent.new(Action.BUY, p_player_id, &"", {}, &"", p_quantity, p_item_id)

static func create_sell_item(p_player_id: StringName, p_item_id: StringName, p_quantity: int) -> PlayerIntent:
	return PlayerIntent.new(Action.SELL, p_player_id, &"", {}, &"", p_quantity, p_item_id)

static func create_equip_item(p_player_id: StringName, p_item_id: StringName, slot: String) -> PlayerIntent:
	return PlayerIntent.new(Action.EQUIP_ITEM, p_player_id, &"", {"item_id": String(p_item_id), "slot": slot})

static func create_unequip_item(p_player_id: StringName, slot: String) -> PlayerIntent:
	return PlayerIntent.new(Action.UNEQUIP_ITEM, p_player_id, &"", {"slot": slot})

func to_dict() -> Dictionary:
	var result := {
		"action": action,
		"player_id": String(player_id),
		"destination_id": String(destination_id),
		"commodity": String(commodity),
		"quantity": quantity,
		"payload": payload.duplicate(true),
	}
	if item_id != &"":
		result["item_id"] = String(item_id)
	return result

static func from_dict(data: Dictionary) -> PlayerIntent:
	return PlayerIntent.new(
		int(data.get("action", Action.WAIT)),
		StringName(data.get("player_id", "")),
		StringName(data.get("destination_id", "")),
		data.get("payload", {}),
		StringName(data.get("commodity", "")),
		int(data.get("quantity", 0)),
		StringName(data.get("item_id", ""))
	)

# S5-B4: the chosen option travels as an intent like everything else. A UI
# button handler must never apply an encounter's effects itself.
static func create_resolve_encounter(p_player_id: StringName, p_option_id: StringName) -> PlayerIntent:
	return PlayerIntent.new(
		Action.RESOLVE_ENCOUNTER, p_player_id, &"", {"option_id": String(p_option_id)}
	)

static func create_continue_journey(p_player_id: StringName, result_index: int) -> PlayerIntent:
	return PlayerIntent.new(Action.CONTINUE_JOURNEY, p_player_id, &"", {"result_index": result_index})

static func create_field_action(p_player_id: StringName, fields: Dictionary) -> PlayerIntent:
	return PlayerIntent.new(Action.FIELD_ACTION, p_player_id, &"", fields.duplicate(true))
