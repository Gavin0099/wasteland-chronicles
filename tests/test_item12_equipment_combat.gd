extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-12: " + message)

func fresh() -> WorldState:
	var world := S1WorldData.create_s1_world()
	engine.commit_character_creation(world, Intent.new({"source_settlement_id": "settlement:gray_valley", "character_name": "Weapon Tester", "age": 26, "background_id": "MECHANIC", "trait_ids": []}))
	return world

func field_payload(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload["battle_id"] = world.field_state.battle.id
		payload["turn"] = world.field_state.battle.turn
	return payload

func act(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, field_payload(world, command)))

func _init() -> void:
	var unarmed := fresh()
	check(act(unarmed, "START").success, "unarmed battle starts")
	check(act(unarmed, "ATTACK").success and unarmed.field_state.enemy_hp == 4, "unarmed attack remains damage 2")

	var knife := fresh()
	check(knife.player.pickup_item("rusted_knife").success, "test player owns rusted knife")
	check(knife.player.equip_item("rusted_knife", "main_hand").success, "main-hand knife equips through equipment authority")
	check(act(knife, "START").success, "equipped battle starts")
	check(Field.attack_damage(knife) == 3, "rusted knife adds one main-hand damage")
	check(act(knife, "ATTACK").success and knife.field_state.enemy_hp == 3, "equipped knife changes committed combat result")

	var machete := fresh()
	machete.player.pickup_item("scrap_machete")
	machete.player.equip_item("scrap_machete", "main_hand")
	check(Field.attack_damage(machete) == 5, "scrap machete adds three main-hand damage")
	var saved := machete.to_canonical_json()
	var loaded := WorldState.from_json_checked(saved)
	check(loaded.success and Field.attack_damage(loaded.world) == 5, "equipment combat effect survives save/load")
	check(engine.validate_invariants(knife) == "" and engine.validate_invariants(loaded.world) == "", "equipment combat preserves invariants")
	print("ITEM-12 equipment combat bridge: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
