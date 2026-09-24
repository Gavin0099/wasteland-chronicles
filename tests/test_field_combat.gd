extends SceneTree
const Intent = preload("res://simulation/character_creation_intent.gd")
var engine := SimulationEngine.new()
var failed := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
func fresh() -> WorldState:
	var w := S1WorldData.create_s1_world()
	engine.commit_character_creation(w, Intent.new({"source_settlement_id": "settlement:gray_valley", "character_name": "Field Tester", "age": 23, "background_id": "MECHANIC", "trait_ids": []}))
	return w
func fields(w: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload.battle_id = w.field_state.battle.id
		payload.turn = w.field_state.battle.turn
	if command == "CONFIRM":
		payload.receipt = w.field_state.receipt
	return payload
func act(w: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(w, PlayerIntent.create_field_action(w.player.npc_id, fields(w, command)))
func denied(w: WorldState, payload: Dictionary) -> void:
	var before := w.to_canonical_json().sha256_text()
	check(not engine.commit_player_intent(w, PlayerIntent.create_field_action(w.player.npc_id, payload)).success, "invalid field intent denied")
	check(w.to_canonical_json().sha256_text() == before, "rejection atomic SHA")
func _init() -> void:
	var w := fresh()
	denied(w, {"command": "CRAFT"})
	denied(w, {"command": "EQUIP"})
	denied(w, {"command": "OPEN"})
	denied(w, {"command": "SPAWN_GUN"})
	w.player.inventory.scrap = 3
	check(act(w, "CRAFT").success and w.player.inventory.scrap == 0 and w.player.get_total_inventory_load() == 12, "3 scrap -> unique 2-weight crowbar")
	denied(w, {"command": "CRAFT"})
	check(act(w, "EQUIP").success and w.player.field_kit.equipped, "equip owned item")
	denied(w, {"command": "EQUIP"})
	check(act(w, "UNEQUIP").success and not w.player.field_kit.equipped, "explicit unequip")
	denied(w, {"command": "UNEQUIP"})
	check(act(w, "EQUIP").success, "re-equip before battle")
	var a := w.duplicate_state()
	var b := WorldState.from_json(w.to_canonical_json())
	for track in [a, b]:
		check(act(track, "START").success, "start encounter")
	var stale := fields(a, "ATTACK")
	for track in [a, b]:
		check(act(track, "ATTACK").success, "turn 1")
		check(track.player.field_kit.hp == 10 and track.field_state.enemy_hp == 5, "equipped hit 3 and enemy hit 2")
	denied(a, stale)
	denied(a, {"command": "REST"})
	var before := a.to_canonical_json()
	check(not engine.commit_player_intent(a, PlayerIntent.create_wait(a.player.npc_id)).success and before == a.to_canonical_json(), "world time blocked during combat")
	for track in [a, b]:
		check(act(track, "DEFEND").success and track.player.field_kit.hp == 10, "defend absorbs normal hit")
	b = WorldState.from_json(b.to_canonical_json())
	for track in [a, b]:
		check(act(track, "ATTACK").success and track.field_state.enemy_hp == 0 and track.player.field_kit.hp == 10, "prepared hit 5 wins before retaliation")
		check(track.current_day == 0, "rounds do not spend days")
		check(engine.validate_invariants(track) == "", "combat global invariants")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "mid-turn save/load dual-track replay")
	var receipt := fields(a, "CONFIRM")
	check(act(a, "CONFIRM").success, "explicit combat result confirmation")
	denied(a, receipt)
	check(act(a, "OPEN").success, "crowbar opens cleared cache")
	check(a.player.inventory.water == 9 and a.player.inventory.food == 7 and a.player.get_total_inventory_load() == 18, "actual one-time cache goods and tool weight")
	act(a, "CONFIRM")
	denied(a, {"command": "OPEN"})
	check(act(a, "REST").success and a.current_day == 1 and a.player.field_kit.hp == 12, "rest advances real day, heals to cap")
	# No-capacity loot must report leftovers, and cannot be claimed twice.
	act(b, "CONFIRM")
	b.player.inventory.water = 18
	b.player.inventory.food = 0
	check(act(b, "OPEN").success, "full pack still opens cache honestly")
	var result: Dictionary = b.event_log[b.field_state.receipt].payload
	check(result.gained.is_empty() and result.left_behind == {"water": 4.0, "food": 2.0}, "full pack receipt records all leftovers")
	# Unarmed and escape persist real damage.
	w = fresh()
	act(w, "START")
	act(w, "ATTACK")
	check(w.field_state.enemy_hp == 6 and w.player.field_kit.hp == 10, "unarmed damage fixture")
	check(act(w, "FLEE").success and w.player.field_kit.hp == 9 and w.field_state.enemy_hp == 6, "escape keeps both HP values")
	act(w, "CONFIRM")
	act(w, "START")
	check(w.field_state.battle.id == 2 and w.field_state.enemy_hp == 6, "monotonic ID and no enemy respawn/heal")
	# Lethal result uses existing population authority exactly once.
	w.player.field_kit.hp = 1
	var population := w.get_settlement(&"settlement:gray_valley").population
	var deaths := w.get_settlement(&"settlement:gray_valley").cumulative_deaths
	check(act(w, "FLEE").success, "fatal escape commits")
	check(w.get_settlement(&"settlement:gray_valley").population == population - 1 and w.get_settlement(&"settlement:gray_valley").cumulative_deaths == deaths + 1, "one human death, no animal population inflation")
	check(engine.validate_invariants(w) == "", "fatal invariants")
	var dead_load := WorldState.from_json_checked(w.to_canonical_json())
	check(dead_load.success, "fatal pending result survives load")
	check(act(w, "CONFIRM").success, "dead player can dismiss result")
	denied(w, {"command": "REST"})
	# Versioned corruption is not legacy. Skill strict codec remains covered elsewhere.
	for patch in [{"field_schema_version": 2}, {"field_state": {}}, {"field_schema_version": null}]:
		var raw := a.to_dict()
		raw.merge(patch, true)
		check(not WorldState.from_dict_checked(raw).success, "reject malformed field schema")
	for hp in [-1, 13, 1.5, true, "12", null]:
		var raw := a.to_dict()
		raw.player.field_kit.hp = hp
		check(not WorldState.from_dict_checked(raw).success, "reject invalid HP")
	var legacy := fresh().to_dict()
	legacy.erase("field_schema_version")
	legacy.erase("field_state")
	legacy.player.erase("field_kit")
	var migrated := WorldState.from_dict_checked(legacy)
	check(migrated.success and migrated.world.player.field_kit.hp == 12 and not migrated.world.player.field_kit.crowbar, "whole old schema migration")
	legacy.player.field_kit = {"hp": 12, "crowbar": true, "equipped": false}
	check(not WorldState.from_dict_checked(legacy).success, "partial legacy rejects injected equipment")
	print("Field replay SHA-256: ", a.to_canonical_json().sha256_text())
	print("Field combat gates: ", "PASS" if failed == 0 else "FAIL", "; failures=", failed)
	quit(0 if failed == 0 else 1)
