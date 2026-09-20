class_name NpcIdentity
extends RefCounted

# ==============================================================================
# S4-A: MINIMAL NPC IDENTITY MODEL
# ==============================================================================
# Represents WHO this person is permanently in the world.
# Decoupled from mutable life states (location, alive, occupation are S4-B).
# ==============================================================================

var id: StringName = &""
var name: String = ""
var age_at_materialization: int = 0
var origin_settlement_id: StringName = &""

func _init(
	p_id: StringName = &"",
	p_name: String = "",
	p_age_at_materialization: int = 0,
	p_origin_settlement_id: StringName = &""
) -> void:
	id = p_id
	name = p_name
	age_at_materialization = p_age_at_materialization
	origin_settlement_id = p_origin_settlement_id

func duplicate_identity() -> NpcIdentity:
	return NpcIdentity.new(id, name, age_at_materialization, origin_settlement_id)

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"name": name,
		"age_at_materialization": age_at_materialization,
		"origin_settlement_id": String(origin_settlement_id)
	}

static func from_dict(data: Dictionary) -> NpcIdentity:
	var p_id := StringName(data.get("id", ""))
	var p_name: String = String(data.get("name", ""))
	var p_age: int = int(data.get("age_at_materialization", 0))
	var p_origin := StringName(data.get("origin_settlement_id", ""))
	return NpcIdentity.new(p_id, p_name, p_age, p_origin)
