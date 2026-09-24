extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")
var engine := SimulationEngine.new()
var failed := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
		print("FAIL: " + message)

func fresh() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Tester",
		"age": 25, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	}))
	check(result.success, "creation fixture")
	return world

func field_action(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command == "ATTACK":
		payload["battle_id"] = world.field_state.battle.id
		payload["turn"] = world.field_state.battle.turn
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var market := fresh()
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(market, engine)
	var purchase := shell.on_buy_pressed("water", 1)
	check(purchase.success and shell.market_practice_label.visible, "awarded market practice is immediately visible")
	check(shell.market_practice_label.text.contains("交易練習"), "market feedback names actual practice")
	shell._show_local_market()
	check(not shell.market_practice_label.visible, "reopening the market clears an old practice notice")
	shell.on_buy_pressed("water", 1)
	check(not shell.market_practice_label.visible, "same-day unawarded trade does not preserve old notice")
	var waited := engine.execute_player_wait(market)
	check(waited.success, "world advances to a new day")
	var next_trade := shell.on_buy_pressed("water", 1)
	check(next_trade.success and shell.market_practice_label.visible, "new day's real trade creates a fresh notice")
	var travel := engine.commit_player_intent(market,
		PlayerIntent.create_travel(market.player.npc_id, &"settlement:new_hope"))
	check(travel.success, "player travels away from the market")
	shell.refresh_ui()
	check(not shell.market_practice_label.visible, "a changed location clears a prior town's notice")
	shell.queue_free()
	await process_frame

	var battle := fresh()
	check(field_action(battle, "START").success, "existing battle starts")
	check(field_action(battle, "ATTACK").success, "nonfatal attack commits")
	var turn_index := -1
	for i in range(battle.event_log.size()):
		if battle.event_log[i].type == "FIELD_TURN":
			turn_index = i
	check(turn_index >= 0, "turn ledger exists")
	if turn_index >= 0:
		var valid := WorldState.from_json_checked(battle.to_canonical_json())
		check(valid.success, "valid practiced combat turn survives JSON load")
		for invalid in ["corrupt", {"skill_id": "MELEE", "rank_up": true, "from_rank": 0,
			"to_rank": 999, "points": 0, "required": 0}]:
			var tampered: Dictionary = battle.to_dict().duplicate(true)
			tampered.events[turn_index].payload.skill_practice = invalid
			check(not WorldState.from_dict_checked(tampered).success, "malformed turn practice is rejected before UI")
			check(not WorldState.from_json_checked(JSON.stringify(tampered)).success, "malformed JSON turn practice is rejected")
		var mismatch: Dictionary = battle.to_dict().duplicate(true)
		mismatch.events[turn_index].payload.command = "DEFEND"
		check(not WorldState.from_dict_checked(mismatch).success, "practice cannot be attached to a defensive turn")

	var finisher := fresh()
	check(field_action(finisher, "START").success, "finisher battle starts")
	finisher.field_state.enemy_hp = 2
	check(field_action(finisher, "ATTACK").success, "finishing attack commits")
	var receipt: Dictionary = finisher.event_log[finisher.field_state.receipt].payload
	check(receipt.get("skill_practice", {}).get("skill_id", "") == "MELEE", "finishing blow carries practice into result receipt")
	check(WorldState.from_json_checked(finisher.to_canonical_json()).success, "finisher receipt survives JSON load")
	for invalid_receipt in ["corrupt", {"skill_id": "MELEE", "rank_up": false,
		"from_rank": 0, "to_rank": 0, "points": 999, "required": 2}]:
		var tampered_result: Dictionary = finisher.to_dict().duplicate(true)
		tampered_result.events[finisher.field_state.receipt].payload.skill_practice = invalid_receipt
		check(not WorldState.from_dict_checked(tampered_result).success, "malformed victory practice receipt is rejected")
		check(not WorldState.from_json_checked(JSON.stringify(tampered_result)).success, "malformed JSON victory practice receipt is rejected")
	var wrong_outcome: Dictionary = finisher.to_dict().duplicate(true)
	wrong_outcome.events[finisher.field_state.receipt].payload.outcome = "ESCAPED"
	check(not WorldState.from_dict_checked(wrong_outcome).success, "practice cannot be attached to a non-victory result")
	var field_ui = preload("res://ui/field_screen.gd").new()
	root.add_child(field_ui)
	field_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field_ui.setup(finisher, engine)
	check(field_ui.growth_notice_label.visible and field_ui.growth_notice_label.text.contains("近戰練習"), "finishing blow feedback appears outside the scrollable result body")
	check(engine.validate_invariants(finisher) == "", "global invariants hold after finishing blow")
	if "--capture" in OS.get_cmdline_user_args():
		root.size = Vector2i(1152, 648)
		for frame in range(8):
			await process_frame
		var dir := OS.get_user_data_dir().path_join("captures/c3-growth")
		DirAccess.make_dir_recursive_absolute(dir)
		var image_path := dir.path_join("finishing_blow_1152x648.png")
		check(root.get_texture().get_image().save_png(image_path) == OK, "real renderer saves finishing blow")
		print("CAPTURED ", image_path)
	field_ui.queue_free()
	await process_frame

	var a := finisher.to_canonical_json().sha256_text()
	var b_world := fresh()
	field_action(b_world, "START")
	b_world.field_state.enemy_hp = 2
	field_action(b_world, "ATTACK")
	check(a == b_world.to_canonical_json().sha256_text(), "two-track full-world SHA-256 replay after finishing blow")
	print("S5-C3 feedback replay SHA-256: " + a)
	print("S5-C3 feedback integrity: " + ("PASS" if failed == 0 else "FAIL"))
	quit(0 if failed == 0 else 1)
