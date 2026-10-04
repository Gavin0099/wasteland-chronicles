extends "res://tests/test_dungeon_layout.gd"

func _init() -> void:
	store = Store.new("user://tests/dun3/journey.json")
	call_deferred("run_combat")

func fight_intent(world: WorldState, room: String) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "FIGHT", "room_id": room})

func combat_intent(world: WorldState, action: String) -> PlayerIntent:
	var payload: Dictionary = {"command": action}
	if action == "CONFIRM": payload.receipt = int(world.field_state.receipt)
	else:
		payload.battle_id = int(world.field_state.battle.id)
		payload.turn = int(world.field_state.battle.turn)
	return PlayerIntent.create_field_action(world.player.npc_id, payload)

func room_world(route: Array[String]) -> WorldState:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "actual combat trip entry")
	for destination: String in route:
		check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", Dungeon.state(world).room_id, destination)).success, "actual combat approach " + destination)
	return world

func combat_replay() -> void:
	clear_slot()
	var world: WorldState = room_world(["foyer", "guard"])
	var original_money: int = world.player.money
	var original_scrap: int = world.player.inventory.scrap
	var home_hp: int = world.field_state.enemy_hp
	var twin: WorldState = disk_copy(world, "pre-fight actual room")
	for intent: PlayerIntent in [fight_intent(world, "pump"), fight_intent(world, "unknown"), PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "FIGHT", "room_id": "guard", "reward": 100})]: rejected(world, intent, "forged chosen room")
	pair_intent(world, twin, fight_intent(world, "guard"), "real room battle")
	check(world.field_state.battle.source == "dungeon" and world.field_state.battle.room_id == "guard" and world.field_state.battle.enemy == "bandit" and world.field_state.enemy_hp == 8, "independent guard catalogue fixture")
	twin = disk_copy(world, "active dungeon battle actual disk")
	rejected(world, fight_intent(world, "guard"), "second active battle")
	rejected(world, dungeon_intent(world, "MOVE", "guard", "foyer"), "movement while fighting")
	rejected(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "REST"}), "town rest while fighting")
	var stale: PlayerIntent = combat_intent(world, "ATTACK")
	pair_intent(world, twin, combat_intent(world, "DEFEND"), "real brace")
	rejected(world, stale, "stale dungeon turn")
	for turn_index: int in range(12):
		if world.field_state.battle.is_empty(): break
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "real dungeon strike")
		twin = disk_copy(world, "dungeon strike actual disk")
	check(world.field_state.receipt >= 0 and world.event_log[world.field_state.receipt].payload.outcome == "VICTORY", "actual guard victory receipt")
	check(world.player.money == original_money + 5 and world.player.inventory.scrap == original_scrap + 2, "reviewed guard reward is five caps and two scrap once")
	check(Dungeon.state(world).cleared == ["guard"] and Dungeon.state(world).room_id == "guard", "victory remembers actual cleared room without changing checkpoint")
	rejected(world, dungeon_intent(world, "MOVE", "guard", "foyer"), "unconfirmed victory keeps room locked")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "explicit combat result confirmation")
	check(world.field_state.enemy_hp == home_hp and world.field_state.receipt == -1 and world.field_state.battle.is_empty(), "confirmation restores exact home cache state")
	twin = disk_copy(world, "confirmed room clearance actual disk")
	rejected(world, fight_intent(world, "guard"), "second guard reward blocked")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "guard", "foyer"), "actual post-battle backtrack")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "foyer", "maintenance"), "maintenance branch")
	pair_intent(world, twin, dungeon_intent(world, "MOVE", "maintenance", "pump"), "pump approach")
	pair_intent(world, twin, fight_intent(world, "pump"), "actual different room opponent")
	check(world.field_state.battle.enemy == "feral_dog" and world.field_state.enemy_hp == 6, "independent pump catalogue fixture")
	var before_money: int = world.player.money
	var before_scrap: int = world.player.inventory.scrap
	pair_intent(world, twin, combat_intent(world, "FLEE"), "actual retreat")
	check(world.event_log[world.field_state.receipt].payload.outcome == "ESCAPED" and Dungeon.state(world).cleared == ["guard"] and world.player.money == before_money and world.player.inventory.scrap == before_scrap, "retreat grants nothing and does not clear pump")
	twin = disk_copy(world, "retreat result actual disk")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "retreat confirmation")
	check(Dungeon.state(world).room_id == "pump" and world.field_state.enemy_hp == home_hp, "retreat returns exact source room and home snapshot")
	pair_intent(world, twin, fight_intent(world, "pump"), "uncleared pump can be challenged again")
	clear_slot()

func fatal_combat() -> void:
	clear_slot()
	var world: WorldState = room_world(["foyer", "guard"])
	world.player.field_kit.hp = 1 # Reviewed one-HP fixture before battle start.
	var baseline_population: int = world.get_settlement(&"settlement:gray_valley").population
	var baseline_deaths: int = world.get_settlement(&"settlement:gray_valley").cumulative_deaths
	var twin: WorldState = disk_copy(world, "one-HP real trip fixture")
	pair_intent(world, twin, fight_intent(world, "guard"), "fatal-risk chosen fight")
	pair_intent(world, twin, combat_intent(world, "FLEE"), "fatal dungeon retreat applies existing field mortality")
	check(world.event_log[world.field_state.receipt].payload.outcome == "DEAD" and not world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive(), "dungeon has no protected road defeat floor")
	check(world.get_settlement(&"settlement:gray_valley").population == baseline_population - 1 and world.get_settlement(&"settlement:gray_valley").cumulative_deaths == baseline_deaths + 1, "existing single-player death transfers one living person to deaths")
	twin = disk_copy(world, "fatal pending result actual disk")
	rejected(world, fight_intent(world, "guard"), "dead player cannot fight")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "fatal result can be acknowledged")
	check(not Dungeon.state(world).active and world.field_state.receipt < 0 and world.player.field_kit.hp == 0, "fatal acknowledgement ends exploration without reviving player")
	twin = disk_copy(world, "finished dead journey actual disk")
	rejected(world, dungeon_intent(world, "ENTER"), "dead journey cannot reenter")
	clear_slot()

func run_combat() -> void:
	root.size = Vector2i(1280, 720)
	combat_replay()
	fatal_combat()
	reward_boundaries()
	combat_history_fixtures()
	await combat_ui()
	print("DUN-3: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)

func win(world: WorldState) -> void:
	for turn_index: int in range(12):
		if world.field_state.battle.is_empty(): break
		check(engine.commit_player_intent(world, combat_intent(world, "ATTACK")).success, "real boundary fight turn")
	check(world.field_state.receipt >= 0 and world.event_log[world.field_state.receipt].payload.outcome == "VICTORY", "boundary fixture survives actual victory")

func reward_boundaries() -> void:
	clear_slot()
	for target: String in ["pump", "polluted_store"]:
		var route: Array[String] = ["foyer", "maintenance", "pump"]
		if target == "polluted_store": route.append(target)
		var world: WorldState = room_world(route)
		world.player.field_kit.crowbar = true
		world.player.field_kit.equipped = true
		var initial_caps: int = world.player.money
		var initial_scrap: int = world.player.inventory.scrap
		check(engine.commit_player_intent(world, fight_intent(world, target)).success, "chosen deep opponent")
		check(world.field_state.enemy_hp == (6 if target == "pump" else 12), "independent deep enemy HP fixture")
		win(world)
		check(world.player.money == initial_caps + (0 if target == "pump" else 10) and world.player.inventory.scrap == initial_scrap + (2 if target == "pump" else 3), "independently specified deep rewards")
		var reward_twin: WorldState = disk_copy(world, "deep victory disk receipt")
		pair_intent(world, reward_twin, combat_intent(world, "CONFIRM"), "deep reward confirmation")
		rejected(world, fight_intent(world, target), "deep reward once")
		check(engine.validate_invariants(world) == "", "deep victory full invariant check")
	var full: WorldState = room_world(["foyer", "guard"])
	full.player.inventory.scrap += full.player.get_effective_capacity() - full.player.get_total_inventory_load()
	check(full.player.get_total_inventory_load() == full.player.get_effective_capacity(), "independent pack fixture fills effective carrying capacity including protected water allowance")
	full.field_state.opened = true
	full.field_state.enemy_hp = 0 # Independent already-open cache fixture.
	check(engine.validate_invariants(full) == "", "full pack plus open cache seed valid")
	check(engine.commit_player_intent(full, fight_intent(full, "guard")).success, "opened home cache allows dungeon combat")
	win(full)
	var receipt: Dictionary = full.event_log[full.field_state.receipt].payload
	check(receipt.gained.is_empty() and receipt.left_behind.size() == 1 and int(receipt.left_behind.get("scrap", 0)) == 2 and int(receipt.caps_gained) == 5, "full pack records two missed scrap but caps remain weightless")
	check(engine.commit_player_intent(full, combat_intent(full, "CONFIRM")).success and full.field_state.enemy_hp == 0 and full.field_state.opened, "exact zero home snapshot restored")
	rejected(full, fight_intent(full, "guard"), "missed scrap cannot be farmed later")
	full = disk_copy(full, "open-cache cleared room persistence")
	for destination: String in ["foyer", "entrance"]:
		check(engine.commit_player_intent(full, dungeon_intent(full, "MOVE", Dungeon.state(full).room_id, destination)).success, "clearance persists while backtracking")
	check(engine.commit_player_intent(full, dungeon_intent(full, "EXIT")).success, "cleared trip exits")
	check(engine.commit_player_intent(full, dungeon_intent(full, "ENTER")).success, "cleared trip revisits")
	for destination: String in ["foyer", "guard"]:
		check(engine.commit_player_intent(full, dungeon_intent(full, "MOVE", Dungeon.state(full).room_id, destination)).success, "cleared trip returns to actual room")
	rejected(full, fight_intent(full, "guard"), "clearance survives real exit and revisit")
	var armed: WorldState = room_world(["foyer", "guard"])
	check(armed.player.item_inventory.pickup_item("old_revolver", 1).success and armed.player.item_inventory.pickup_item("revolver_round", 3).success, "owned firearm/ammunition independent fixture")
	check(armed.player.equip_item("old_revolver", "main_hand").success and engine.validate_invariants(armed) == "", "actual equipped firearm fixture valid")
	check(engine.commit_player_intent(armed, fight_intent(armed, "guard")).success, "armed room encounter")
	var rounds: int = armed.player.item_inventory.quantity("revolver_round")
	var twin: WorldState = disk_copy(armed, "armed active fight disk")
	pair_intent(armed, twin, combat_intent(armed, "SHOOT"), "actual dungeon firearm turn")
	check(armed.player.item_inventory.quantity("revolver_round") == rounds - 1, "real ammunition debited exactly one round")
	if not armed.field_state.battle.is_empty(): win(armed)
	check(int(armed.event_log[armed.field_state.receipt].payload.get("xp_gained", 0)) == 15, "first actual field-family victory grants the specified fifteen XP")
	check(engine.commit_player_intent(armed, combat_intent(armed, "CONFIRM")).success, "armed victory acknowledged")
	var first_xp: int = armed.player.xp
	for destination: String in ["pump"]:
		check(engine.commit_player_intent(armed, dungeon_intent(armed, "MOVE", Dungeon.state(armed).room_id, destination)).success, "actual second room after first XP")
	check(engine.commit_player_intent(armed, fight_intent(armed, "pump")).success, "second actual fight after first XP")
	win(armed)
	check(armed.player.xp == first_xp and not armed.event_log[armed.field_state.receipt].payload.has("xp_gained"), "second distinct victory does not duplicate first-field XP")
	clear_slot()

func reject_fixture(data: Dictionary, label: String) -> void:
	var checked: Dictionary = WorldState.from_json_checked(JSON.stringify(data))
	check(not checked.success and checked.world == null, label + " checked persistence rejects")
	var raw: WorldState = WorldState.from_dict_unchecked(data)
	for event: Dictionary in data.events: raw.event_log.append(EventRecord.from_dict(event))
	check(Dungeon.validate_world(raw) != "", label + " actual live validator rejects")

func last_fact(data: Dictionary, kind: String) -> Dictionary:
	for index: int in range(data.events.size() - 1, -1, -1):
		if data.events[index].type == kind: return data.events[index]
	check(false, "negative fixture must select actual " + kind)
	return {}

func combat_history_fixtures() -> void:
	var world: WorldState = room_world(["foyer", "guard"])
	check(engine.commit_player_intent(world, fight_intent(world, "guard")).success, "valid history start fixture")
	for mode: int in range(13):
		var data: Dictionary = world.to_dict().duplicate(true)
		var start: Dictionary = data.events.back()
		match mode:
			0: start.actor_id = "npc:unknown"
			1: start.payload.enemy = "feral_dog"
			2: start.payload.room_id = "pump"
			3: start.payload.hp = 0
			4: start.payload.site_enemy_hp = "8"
			5: start.payload.battle_id = 0
			6: data.field_state.battle.erase("source")
			7: data.field_state.battle.room_id = "pump"
			8: data.field_state.battle.turn = 2
			9: data.field_state.enemy_hp = 7
			10: data.player.field_kit.hp = 11
			11: data.field_state.battle.prepared = true
			12:
				data.events.append(start.duplicate(true))
				data.event_count = data.events.size()
		reject_fixture(data, "forged start/snapshot %d" % mode)
	check(engine.commit_player_intent(world, combat_intent(world, "DEFEND")).success, "real turn history fixture")
	for mode: int in range(7):
		var data: Dictionary = world.to_dict().duplicate(true)
		var turn: Dictionary = last_fact(data, "FIELD_TURN")
		match mode:
			0: turn.payload.erase("source")
			1: turn.payload.battle_id = 99
			2: turn.payload.turn = 2
			3: turn.payload.dealt = 1
			4: turn.payload.taken = -1
			5: turn.payload.hp = 0
			6: turn.payload.room_id = "pump"
		reject_fixture(data, "forged combat turn %d" % mode)
	win(world)
	for mode: int in range(7):
		var data: Dictionary = world.to_dict().duplicate(true)
		var result: Dictionary = data.events[data.field_state.receipt]
		match mode:
			0: result.payload.erase("source")
			1: result.payload.gained = {"scrap": 99}
			2: result.payload.caps_gained = 500
			3: result.payload.outcome = "ESCAPED"
			4: result.payload.site_enemy_hp = 0
			5: result.payload.room_id = "pump"
			6: data.field_state.receipt -= 1
		reject_fixture(data, "forged victory receipt %d" % mode)
	check(engine.commit_player_intent(world, combat_intent(world, "CONFIRM")).success, "real confirmation history fixture")
	for mode: int in range(4):
		var data: Dictionary = world.to_dict().duplicate(true)
		var confirmation: Dictionary = last_fact(data, "DUNGEON_BATTLE_CONFIRMED")
		match mode:
			0: confirmation.payload.result_index = -1
			1: confirmation.payload.battle_id = 999
			2: confirmation.payload.room_id = "pump"
			3:
				data.events.append(confirmation.duplicate(true))
				data.event_count = data.events.size()
		reject_fixture(data, "forged confirmation %d" % mode)
	check(engine.validate_invariants(world) == "", "negative histories do not mutate valid original")

func observe(label: String, main: Node) -> void:
	await frames()
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	check(screen != null and engine.validate_invariants(main.world) == "", label + " actual dungeon screen and invariants")
	if screen == null: return
	if is_instance_valid(screen.combat_screen):
		var battle: Control = screen.combat_screen
		check(not screen.view.enabled and battle.stage.environment_id == "waterworks" and battle.stage.waterworks_background.texture != null, label + " actual battle background and exploration lock")
		for command_button: Button in battle.buttons.values():
			var bounds: Rect2 = command_button.get_global_rect()
			check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= root.size.x and bounds.end.y <= root.size.y and bounds.size.y >= 40, label + " real command fits viewport and touch height")
	else:
		check(screen.view.enabled and screen.view.walkable(screen.view.actor_position), label + " living checkpoint resumes walkable exploration")
		if screen.view.enemy_id == "ash_ghoul":
			check(screen.view.enemy_texture != null and screen.view.enemy_texture.get_image().get_pixel(0, 0).a == 0, label + " retained transparent enemy bitmap survives deferred drawing")

func battle_command(screen: Control, command_name: String) -> void:
	check(screen.buttons.has(command_name) and not screen.buttons[command_name].disabled, "actual available combat command " + command_name)
	if not screen.buttons.has(command_name) or screen.buttons[command_name].disabled: return
	screen.buttons[command_name].pressed.emit()
	if command_name in ["DEFEND", "ATTACK"] and not screen.stage.reduced_motion:
		await motion_observe(screen, command_name)
	for tick: int in range(480):
		if not is_instance_valid(screen) or not screen.busy: break
		await process_frame
	await frames()

func motion_observe(screen: Control, command_name: String) -> void:
	var before: String = screen.world.to_canonical_json()
	for tick: int in range(18): await process_frame
	check(screen.busy and screen.stage.active_motion != null, command_name + " real committed animation is in progress")
	check(screen.world.to_canonical_json() == before and engine.validate_invariants(screen.world) == "", command_name + " animation cannot change committed world")

func combat_ui() -> void:
	clear_slot()
	var world: WorldState = room_world(["foyer", "guard"])
	check(store.save_game(world).success, "real room UI slot")
	var main: Node = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await observe("guard_room", main)
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	var selection: int = -1
	for index: int in range(screen.view.doors.size()):
		if screen.view.doors[index].command == "FIGHT": selection = index
	check(selection >= 0, "actual room enemy interaction exposed")
	if selection < 0: return
	screen.route_choice.select(selection)
	screen.guide_button.pressed.emit()
	for tick: int in range(480):
		if screen.view.target_position.x < 0: break
		await process_frame
	check(not screen.interact_button.disabled and screen.view.nearest_door().command == "FIGHT", "actual guide reaches chosen enemy interaction")
	screen.interact_button.pressed.emit()
	await observe("guard_battle", main)
	var battle: Control = screen.combat_screen
	check(battle._display_enemy() == "bandit" and battle.buttons.has("ATTACK") and not battle.buttons["ATTACK"].disabled, "actual guard attacker remains usable")
	find_command(battle, "存讀檔").pressed.emit()
	await frames()
	main.save_dialog.save_button.pressed.emit()
	check(main.save_dialog.summary.text.contains("戰鬥中"), "actual save summary describes battle rather than safe room restart")
	main.save_dialog.get_ok_button().pressed.emit()
	await frames()
	check(not screen.view.enabled, "closing save cannot enable hidden room during battle")
	var before: String = main.world.to_canonical_json()
	main.queue_free()
	await frames()
	main = new_main()
	await frames()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	screen = main.shell.find_child("DungeonScreen", false, false)
	battle = screen.combat_screen
	check(main.world.to_canonical_json() == before and is_instance_valid(battle), "startup Continue restores exact dungeon battle and actual combat UI")
	await observe("continued_guard_battle", main)
	await battle_command(battle, "DEFEND")
	await observe("guard_braced", main)
	for turn: int in range(12):
		if main.world.field_state.battle.is_empty(): break
		await battle_command(battle, "ATTACK")
		await observe("guard_strike_%d" % turn, main)
		battle.reduce_motion.button_pressed = true
	check(battle.buttons.has("CONFIRM") and battle.log_label.text.contains("警衛區") and battle.log_label.text.contains("只結算一次"), "actual victory receipt names source room and one-shot reward")
	await observe("guard_victory", main)
	find_command(battle, "存讀檔").pressed.emit()
	await frames()
	main.save_dialog.save_button.pressed.emit()
	before = main.world.to_canonical_json()
	main.queue_free()
	await frames()
	main = new_main()
	await frames()
	check(main.save_dialog.summary.text.contains("結果待確認"), "startup pending result summary truthful")
	main.save_dialog.load_button.pressed.emit()
	await frames()
	screen = main.shell.find_child("DungeonScreen", false, false)
	battle = screen.combat_screen
	check(main.world.to_canonical_json() == before and battle.buttons.size() == 1 and battle.buttons.has("CONFIRM"), "Continue restores only actual pending receipt command")
	await observe("continued_victory", main)
	await battle_command(battle, "CONFIRM")
	await observe("cleared_guard_return", main)
	check(Dungeon.state(main.world).room_id == "guard" and screen.view.actor_position == Layout.arrival(Layout.doors("guard", false), "foyer") and screen.view.enemy_id == "" and screen.message.text.contains("威脅已排除"), "confirmation restores exact safe source room with clearance and no shed actions")
	main.queue_free()
	await frames()
	for fatal: bool in [false, true]:
		clear_slot()
		world = room_world(["foyer", "maintenance", "pump", "polluted_store"])
		if fatal: world.player.field_kit.hp = 1
		check(engine.commit_player_intent(world, fight_intent(world, "polluted_store")).success and store.save_game(world).success, "real ghoul retreat UI fixture")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("DungeonScreen", false, false)
		battle = screen.combat_screen
		await observe("ghoul_fatal_battle" if fatal else "ghoul_battle", main)
		battle.reduce_motion.button_pressed = true
		await battle_command(battle, "FLEE")
		await observe("fatal_result" if fatal else "ghoul_retreat", main)
		check(battle.log_label.text.contains("倒下") if fatal else battle.log_label.text.contains("敵人仍在"), "actual death/retreat text matches committed outcome")
		await battle_command(battle, "CONFIRM")
		if fatal:
			check(main.shell.find_child("DungeonScreen", false, false) == null and not Dungeon.state(main.world).active and SaveDialog.describe(main.world).contains("旅程已結束"), "fatal confirmation closes exploration and keeps death summary")
		else:
			await observe("ghoul_retreat_return", main)
			check(screen.view.enemy_id == "ash_ghoul" and Dungeon.state(main.world).room_id == "polluted_store", "retreat returns same room and uncleared ghoul")
		main.queue_free()
		await frames()
	clear_slot()
