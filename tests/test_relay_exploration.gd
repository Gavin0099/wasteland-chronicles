extends "res://tests/test_dungeon_supplies.gd"

const Relay = preload("res://simulation/relay_exploration.gd")
const RelayScreen = preload("res://ui/relay_screen.gd")
var render_dir: String = ""

func _init() -> void:
	store = Store.new("user://tests/rly1/journey.json")
	call_deferred("run_relay")

func relay_intent(world: WorldState, relay_command: String, destination: String = "") -> PlayerIntent:
	var payload: Dictionary = {"command": relay_command, "site_id": "dungeon:buried_relay"}
	if relay_command == "MOVE":
		payload.from_room_id = Relay.state(world).room_id
		payload.room_id = destination
	return PlayerIntent.create_dungeon_action(world.player.npc_id, payload)

func relay_pair(world: WorldState, twin: WorldState, relay_command: String, destination: String = "") -> void:
	var result: Dictionary = pair_intent(world, twin, relay_intent(world, relay_command, destination), "relay " + relay_command + " " + destination)
	if not result.success: print("RELAY FAILURE ", result)
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", "relay actual global invariants")

func normal_relay_start() -> WorldState:
	var world: WorldState = PlayableWorld.create_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "中繼站旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "ordinary creation without gifted equipment or bankroll")
	return world

func side_replay() -> WorldState:
	var world: WorldState = normal_relay_start()
	var twin: WorldState = disk_copy(world, "old ordinary world remains byte-identical")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 2), "actual affordable scrap preparation; starting water/food5 suffice")
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "wrench", 1), "actual purchased side-route tool")
	var before_scrap: int = world.player.inventory.scrap
	var sequence: int = world.next_npc_sequence
	var life_ids: Array = world.npc_life_state_registry.life_states.keys()
	relay_pair(world, twin, "ENTER")
	rejected(world, relay_intent(world, "MOVE", "relay_tunnel"), "undiscovered side door")
	relay_pair(world, twin, "SEARCH")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	rejected(world, relay_intent(world, "MOVE", "relay_records"), "closed side-door authority")
	relay_pair(world, twin, "OPEN_TUNNEL")
	check(world.player.inventory.scrap == before_scrap - 2 and world.player.item_inventory.contains("wrench"), "reviewed fixture: consume exactly two scrap, retain actual wrench")
	rejected(world, relay_intent(world, "OPEN_TUNNEL"), "once-only side opening")
	twin = disk_copy(world, "opened side door persists")
	relay_pair(world, twin, "MOVE", "relay_records")
	rejected(world, relay_intent(world, "MOVE", "relay_vault"), "card-gated real vault")
	relay_pair(world, twin, "FIND_CARD")
	relay_pair(world, twin, "MOVE", "relay_vault")
	relay_pair(world, twin, "TAKE_PRIZE")
	check(world.player.item_inventory.quantity("military_backpack") == 1 and world.player.item_inventory.total_weight_g() == 3100, "independent authored weights: wrench700 + backpack2400")
	rejected(world, relay_intent(world, "TAKE_PRIZE"), "once-only physical prize")
	relay_pair(world, twin, "MOVE", "relay_records")
	check(world.current_day == 1 and Relay.state(world).work_units == 0 and world.player.inventory.water == 4 and world.player.inventory.food == 4, "four actual transitions advance one real world day and consume one water/food")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "EXIT")
	check(world.next_npc_sequence == sequence and world.npc_life_state_registry.life_states.keys() == life_ids, "local expedition adds no human identity; world tick may update existing lives")
	pair_intent(world, twin, PlayerIntent.create_equip_item(world.player.npc_id, "military_backpack", "back"), "actual useful reward equip in town")
	check(world.player.get_effective_capacity() == 32 and world.player.item_inventory.capacity_grams("military_backpack") == 12000, "independent reward changes cargo20 to32; item budget remains12kg")
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	relay_pair(world, twin, "MOVE", "relay_records")
	check(world.current_day == 2 and Relay.state(world).tunnel_open and Relay.state(world).card_found, "fractional time survives exit and second visit")
	relay_pair(world, twin, "MOVE", "relay_vault")
	rejected(world, relay_intent(world, "TAKE_PRIZE"), "revisit does not regenerate backpack")
	twin = disk_copy(world, "second site with permanent discoveries actual disk")
	check(SaveDialog.describe(twin).contains("舊中繼站") and SaveDialog.describe(twin).contains("地下保管室"), "actual Continue summary names correct site and room")
	return world

func front_replay() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var twin: WorldState = disk_copy(world, "front approach")
	var home_hp: int = world.field_state.enemy_hp
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	rejected(world, relay_intent(world, "MOVE", "relay_records"), "dog guards front door")
	relay_pair(world, twin, "FIGHT")
	check(world.field_state.enemy_hp == 6 and world.field_state.battle.dungeon_id == "dungeon:buried_relay", "independent six-HP dog belongs to this relay battle")
	twin = disk_copy(world, "relay active combat")
	pair_intent(world, twin, combat_intent(world, "FLEE"), "real relay escape")
	check(world.event_log[world.field_state.receipt].payload.outcome == "ESCAPED" and Relay.state(world).cleared.is_empty(), "escape neither clears front nor grants rewards")
	twin = disk_copy(world, "escape pending Continue")
	rejected(world, relay_intent(world, "MOVE", "relay_entrance"), "pending escape result locks exploration")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "confirm actual escape")
	check(world.field_state.enemy_hp == home_hp, "home field snapshot restores after relay escape")
	relay_pair(world, twin, "FIGHT")
	var caps: int = world.player.money
	var scrap: int = world.player.inventory.scrap
	for step: int in range(6):
		if world.field_state.battle.is_empty(): break
		pair_intent(world, twin, combat_intent(world, "ATTACK"), "real relay fight")
	check(world.field_state.receipt >= 0 and world.event_log[world.field_state.receipt].payload.outcome == "VICTORY", "ordinary melee wins the real dog fight")
	check(world.player.money == caps and world.player.inventory.scrap == scrap, "relay guard gives no arbitrary scrap/caps bonus")
	check(Relay.state(world).cleared == ["relay_corridor"] and Dungeon.state(world).cleared.is_empty(), "site clearances do not leak into waterworks")
	twin = disk_copy(world, "relay unconfirmed victory")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "confirm real relay victory")
	rejected(world, relay_intent(world, "FIGHT"), "cannot farm cleared dog")
	relay_pair(world, twin, "MOVE", "relay_records")
	relay_pair(world, twin, "FIND_CARD")
	relay_pair(world, twin, "MOVE", "relay_vault")
	relay_pair(world, twin, "TAKE_PRIZE")
	check(world.player.item_inventory.contains("military_backpack") and not Relay.state(world).tunnel_found, "front approach earns real backpack without discovered side route")
	clear_slot()

func relay_refusals() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	for payload: Dictionary in [{"command": "ENTER", "site_id": "unknown"}, {"command": "ENTER", "site_id": false}, {"command": 1, "site_id": Relay.SITE}, {"command": "ENTER", "site_id": Relay.SITE, "reward": 10}, {"command": "MOVE", "site_id": Relay.SITE, "from_room_id": "relay_entrance", "room_id": 7}]: rejected(world, PlayerIntent.create_dungeon_action(world.player.npc_id, payload), "untrusted relay command")
	rejected(world, PlayerIntent.create_dungeon_action(&"npc:unknown", {"command": "ENTER", "site_id": Relay.SITE}), "wrong relay actor")
	rejected(fresh_towns("settlement:new_hope"), relay_intent(world, "ENTER"), "wrong city/actor")
	check(engine.commit_player_intent(world, relay_intent(world, "ENTER")).success, "refusal fixture entry")
	for intent: PlayerIntent in [dungeon_intent(world, "ENTER"), PlayerIntent.create_wait(world.player.npc_id), PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope"), PlayerIntent.create_buy(world.player.npc_id, &"water", 1), PlayerIntent.create_field_action(world.player.npc_id, {"command": "REST"})]: rejected(world, intent, "other activities locked inside relay")
	var before: String = world.to_canonical_json()
	check(not engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success and world.to_canonical_json() == before, "direct road API cannot bypass relay lock")
	check(not Field.commit(world, engine, {"command": "REST"}).success and world.to_canonical_json() == before, "direct field API cannot bypass relay lock")
	check(engine.commit_player_intent(world, relay_intent(world, "SEARCH")).success, "actual side discovery")
	check(engine.commit_player_intent(world, relay_intent(world, "MOVE", "relay_tunnel")).success, "actual side approach")
	rejected(world, relay_intent(world, "OPEN_TUNNEL"), "actual missing owned tool")
	check(world.player.pickup_item("wrench").success, "reviewed owned-tool boundary fixture")
	world.player.inventory.scrap = 1
	rejected(world, relay_intent(world, "OPEN_TUNNEL"), "actual insufficient scrap")
	world.player.inventory.scrap = 2
	check(engine.commit_player_intent(world, relay_intent(world, "OPEN_TUNNEL")).success, "actual boundary affordability")
	check(engine.commit_player_intent(world, relay_intent(world, "MOVE", "relay_records")).success, "actual records entry")
	check(engine.commit_player_intent(world, relay_intent(world, "FIND_CARD")).success, "actual owned card")
	check(engine.commit_player_intent(world, relay_intent(world, "MOVE", "relay_vault")).success, "actual vault entry")
	check(world.player.pickup_item("first_aid_kit", 14).success and world.player.item_inventory.total_weight_g() == 11900, "independent capacity fixture: wrench700 + fourteen kits11200")
	rejected(world, relay_intent(world, "TAKE_PRIZE"), "insufficient item space retains treasure")
	check(not Relay.state(world).prize_taken and world.player.drop_item("first_aid_kit", 3).success, "capacity refusal retains pickup opportunity")
	check(engine.commit_player_intent(world, relay_intent(world, "TAKE_PRIZE")).success, "free space allows retry")
	check(world.player.drop_item("military_backpack").success, "real inventory drop")
	rejected(world, relay_intent(world, "TAKE_PRIZE"), "dropped reward never regenerates")
	var water: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(water, dungeon_intent(water, "ENTER")).success, "existing waterworks entry remains valid")
	rejected(water, relay_intent(water, "ENTER"), "waterworks prevents concurrent relay")
	check(Dungeon.validate_world(water) == "" and WorldState.from_json_checked(water.to_canonical_json()).success, "existing waterworks checked saves remain valid")
	clear_slot()

func relay_negative_history() -> void:
	var world: WorldState = side_replay()
	for mode: int in range(15):
		var data: Dictionary = world.to_dict().duplicate(true)
		var event: Dictionary = last_fact(data, "RELAY_TUNNEL_OPENED")
		match mode:
			0: event.actor_id = "npc:unknown"
			1: event.target_id = "dungeon:sealed_waterworks"
			2: event.payload.dungeon_id = "dungeon:sealed_waterworks"
			3: event.payload.tool_id = false
			4: event.payload.scrap_spent = 0
			5: event.payload.room_id = "relay_records"
			6: event.payload.reward = 100
			7: data.events.erase(last_fact(data, "RELAY_TUNNEL_FOUND"))
			8: data.events.erase(last_fact(data, "RELAY_TUNNEL_OPENED"))
			9: data.events.erase(last_fact(data, "RELAY_CARD_FOUND"))
			10: data.events.insert(data.events.find(event), event.duplicate(true))
			11: last_fact(data, "RELAY_PRIZE_TAKEN").payload.quantity = 2
			12: last_fact(data, "RELAY_DAY_SPENT").payload.water_after = 999
			13: event.type = "RELAY_UNKNOWN"
			14: last_fact(data, "RELAY_MOVED").payload.from_room_id = false
		relay_reject_fixture(data, "independent relay malformed fixture " + str(mode))
	var world2: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(world2, relay_intent(world2, "ENTER")).success, "combat forgery entry")
	check(engine.commit_player_intent(world2, relay_intent(world2, "MOVE", "relay_corridor")).success, "combat forgery corridor")
	check(engine.commit_player_intent(world2, relay_intent(world2, "FIGHT")).success, "actual combat positive control")
	check(engine.validate_invariants(world2) == "" and WorldState.from_json_checked(world2.to_canonical_json()).success, "active relay combat positive live and checked control")
	for mode: int in range(5):
		var data: Dictionary = world2.to_dict().duplicate(true)
		match mode:
			0: data.field_state.battle.dungeon_id = "dungeon:sealed_waterworks"
			1: data.field_state.battle.room_id = "guard"
			2: data.field_state.battle.enemy = "bandit"
			3: last_fact(data, "RELAY_BATTLE_STARTED").payload.hp = 1
			4: data.events.erase(last_fact(data, "RELAY_BATTLE_STARTED"))
		relay_reject_fixture(data, "relay combat wrong source/context " + str(mode))
	clear_slot()

func relay_reject_fixture(data: Dictionary, label: String) -> void:
	data.event_count = data.events.size()
	var checked: Dictionary = WorldState.from_json_checked(JSON.stringify(data))
	check(not checked.success and checked.world == null, label + " actual checked loader rejects")
	var raw: WorldState = WorldState.from_dict_unchecked(data)
	# The unchecked base loader deliberately omits field state; restore the actual
	# candidate before exercising the live snapshot validator.
	raw.field_state = data.field_state.duplicate(true)
	for e: Dictionary in data.events: raw.event_log.append(EventRecord.from_dict(e))
	check(engine.validate_invariants(raw) != "", label + " actual full live invariants reject")

func relay_death() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	world.player.field_kit.hp = 1 # Explicit fatal-risk fixture before any battle.
	var initial_population: int = world.get_settlement(Dungeon.HOME).population
	var deaths: int = world.get_settlement(Dungeon.HOME).cumulative_deaths
	var twin: WorldState = disk_copy(world, "one HP before relay")
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	relay_pair(world, twin, "FIGHT")
	pair_intent(world, twin, combat_intent(world, "FLEE"), "relay fatal escape has no road immunity")
	check(world.get_settlement(Dungeon.HOME).population == initial_population - 1 and world.get_settlement(Dungeon.HOME).cumulative_deaths == deaths + 1, "real mortality retains global human conservation")
	twin = disk_copy(world, "fatal relay pending result")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "acknowledge fatal relay result")
	check(not Relay.state(world).active and world.player.field_kit.hp == 0, "fatal confirmation ends expedition without revival")
	rejected(world, relay_intent(world, "ENTER"), "dead character cannot reenter relay")
	var dry: WorldState = fresh_towns("settlement:gray_valley")
	dry.player.inventory.water = 0
	dry.player.water_exposure = 6.0 # Existing six-day grace, one more dry day kills.
	var dry_twin: WorldState = disk_copy(dry, "dehydration positive starting control")
	relay_pair(dry, dry_twin, "ENTER")
	for destination: String in ["relay_corridor", "relay_entrance", "relay_corridor", "relay_entrance"]: relay_pair(dry, dry_twin, "MOVE", destination)
	check(not Relay.state(dry).active and not dry.npc_life_state_registry.get_life_state(dry.player.npc_id).is_alive(), "real fourth transition applies deprivation death and ends relay")
	dry_twin = disk_copy(dry, "deprivation death checked disk")
	for mode: int in range(3):
		var data: Dictionary = dry.to_dict().duplicate(true)
		match mode:
			0: data.events.erase(last_fact(data, "RELAY_DAY_SPENT"))
			1: last_fact(data, "PLAYER_NEED_UNMET").payload.water_unmet = 0.0
			2: last_fact(data, "RELAY_TRIP_ENDED").payload.cause = "unknown"
		relay_reject_fixture(data, "relay deprivation false history " + str(mode))
	clear_slot()

func relay_observe(label: String) -> void:
	await frames()
	if render_dir != "":
		await RenderingServer.frame_post_draw
		var path: String = render_dir.path_join(label + "_%dx%d.png" % [root.size.x, root.size.y])
		check(root.get_texture().get_image().save_png(path) == OK, "actual native renderer capture " + label)

func relay_companion() -> void:
	for fed: bool in [true, false]:
		var world: WorldState = fresh_towns("settlement:gray_valley")
		world.player.inventory.water = 2 if fed else 1
		world.player.inventory.food = 2 if fed else 1
		var twin: WorldState = disk_copy(world, "explicit companion ration boundary")
		pair_intent(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, "companion:abban"), "actual paid Abban hire")
		relay_pair(world, twin, "ENTER")
		for destination: String in ["relay_corridor", "relay_entrance", "relay_corridor", "relay_entrance"]: relay_pair(world, twin, "MOVE", destination)
		var fact: Dictionary = last_fact(world.to_dict(), "RELAY_DAY_SPENT")
		check(fact.payload.companion_fed == fed and fact.payload.companion_id == "companion:abban" and world.player.inventory.water == 0 and world.player.inventory.food == 0, "real relay day pays player1 and Abban1 if available")
		check(Dungeon.Party.current(world) == ("companion:abban" if fed else ""), "real relay HUNGER departure only when companion rations missing")
		twin = disk_copy(world, "relay fed/hungry companion history")
		if not fed:
			var data: Dictionary = world.to_dict().duplicate(true)
			data.events.erase(last_fact(data, "COMPANION_LEFT"))
			relay_reject_fixture(data, "missing required relay hunger departure")
	clear_slot()

func relay_geometry(screen: Control) -> void:
	for control: Control in [screen.view, screen.title_label, screen.status_label, screen.message, screen.route_choice, screen.guide_button, screen.interact_button]:
		var rect: Rect2 = control.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x + 0.1 and rect.end.y <= root.size.y + 0.1, "actual relay layout fits " + control.get_class())
	for control: Control in [screen.route_choice, screen.guide_button, screen.interact_button]: check(control.size.y >= 40, "actual primary relay command height")

func relay_guide(screen: Control, relay_command: String, target: String = "") -> void:
	var found: Dictionary = {}
	for door: Dictionary in screen.view.doors:
		if door.command == relay_command and (target == "" or door.get("room_id", "") == target): found = door
	check(not found.is_empty(), "actual visible relay guide target " + relay_command)
	if found.is_empty(): return
	screen.view.guide_to(found)
	for step: int in range(260):
		screen.view._process(0.08)
		if screen.view.actor_position.distance_to(found.point) < 65: break
	screen.refresh_interaction()
	check(screen.view.actor_position.distance_to(found.point) < 65, "real local walk reaches relay interaction")

func relay_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		clear_slot()
		var world: WorldState = fresh_towns("settlement:gray_valley")
		check(world.player.pickup_item("wrench").success, "explicit UI tool fixture")
		world.player.inventory.scrap = 2
		check(store.save_game(world).success, "real relay UI initial save")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		find_command(main.shell, "中繼站").pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("RelayScreen", false, false)
		check(screen != null and screen.title_label.text.contains("中繼站入口"), "actual town entry opens relay")
		if screen == null: continue
		relay_geometry(screen)
		await relay_observe("entry")
		var before: String = main.world.to_canonical_json()
		var feet: Vector2 = screen.view.actor_position
		screen.show_map()
		await relay_observe("map_frontier")
		check(screen.map_dialog.get_ok_button().size.y >= 40, "native relay map return meets40px acceptance gate")
		check(not screen.view.enabled and not screen.map_dialog.dialog_text.contains("掩埋維修道") and main.world.to_canonical_json() == before, "actual map hides unknown side path and remains read-only")
		screen.map_dialog.get_ok_button().pressed.emit()
		await frames()
		check(screen.view.enabled and screen.view.actor_position == feet, "actual map close restores same feet")
		relay_guide(screen, "SEARCH")
		screen.interact_button.pressed.emit()
		await frames()
		relay_guide(screen, "MOVE", "relay_tunnel")
		screen.interact_button.pressed.emit()
		await frames()
		await relay_observe("side_gate")
		relay_guide(screen, "OPEN_TUNNEL")
		screen.interact_button.pressed.emit()
		await frames()
		relay_guide(screen, "MOVE", "relay_records")
		screen.interact_button.pressed.emit()
		await frames()
		relay_guide(screen, "FIND_CARD")
		screen.interact_button.pressed.emit()
		await frames()
		await relay_observe("card_found")
		relay_guide(screen, "MOVE", "relay_vault")
		screen.interact_button.pressed.emit()
		await frames()
		await relay_observe("vault_prize")
		relay_geometry(screen)
		relay_guide(screen, "TAKE_PRIZE")
		screen.interact_button.pressed.emit()
		await frames()
		check(main.world.player.item_inventory.contains("military_backpack"), "real walking and interaction earns real item")
		await relay_observe("vault_empty")
		before = main.world.to_canonical_json()
		screen.show_supplies()
		await relay_observe("owned_backpack")
		check(not screen.view.enabled and screen.supplies_dialog.summary.text.contains("再換房1次") and main.world.to_canonical_json() == before, "actual relay supplies uses relay clock without mutation")
		screen.supplies_dialog.get_ok_button().pressed.emit()
		await frames()
		find_command(screen, "存讀檔").pressed.emit()
		await frames()
		check(not screen.view.enabled, "actual save menu pauses relay walking")
		main.save_dialog.save_button.pressed.emit()
		check(FileAccess.get_file_as_string(store.path) == before, "actual relay UI save bytes")
		await relay_observe("save_checkpoint")
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		check(screen != null and Relay.state(main.world).room_id == "relay_vault" and main.world.to_canonical_json() == before, "real Continue restores relay, not waterworks")
		await relay_observe("continue_vault")
		relay_geometry(screen)
		for destination: String in ["relay_records", "relay_tunnel", "relay_entrance"]:
			relay_guide(screen, "MOVE", destination)
			screen.interact_button.pressed.emit()
			await frames()
		relay_guide(screen, "EXIT")
		screen.interact_button.pressed.emit()
		await frames()
		check(not Relay.state(main.world).active and main.shell.find_child("RelayScreen", false, false) == null, "actual retreat restores town")
		main.queue_free()
		await frames()
		# Actual front-route combat presentation, receipt animation, and return.
		world = fresh_towns("settlement:gray_valley")
		check(store.save_game(world).success, "native front-route starting slot")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		find_command(main.shell, "中繼站").pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		relay_guide(screen, "MOVE", "relay_corridor")
		screen.interact_button.pressed.emit()
		await frames()
		await relay_observe("front_dog")
		relay_guide(screen, "FIGHT")
		screen.interact_button.pressed.emit()
		await frames()
		var combat: Control = screen.combat_screen
		check(combat != null and combat.heading_label.text.contains("舊中繼站") and combat.stage.environment_id == "relay", "actual combat uses relay identity and original scene")
		await relay_observe("relay_combat")
		var old_hp: int = main.world.field_state.enemy_hp
		combat.buttons.ATTACK.pressed.emit()
		await create_timer(0.12).timeout
		await relay_observe("relay_attack_motion")
		check(main.world.field_state.enemy_hp < old_hp and main.world.field_state.battle.dungeon_id == Relay.SITE, "actual attack applies relay turn before animation")
		await relay_combat_ready(combat)
		for turn_index: int in range(8):
			if main.world.field_state.battle.is_empty(): break
			if not combat.buttons.ATTACK.disabled: combat.buttons.ATTACK.pressed.emit()
			await relay_combat_ready(combat)
		check(main.world.field_state.receipt >= 0, "actual UI combat reaches result")
		await relay_observe("relay_combat_result")
		check(combat.buttons.has("CONFIRM"), "completed combat animation exposes actual confirm command")
		if not combat.buttons.has("CONFIRM"): return
		combat.buttons.CONFIRM.pressed.emit()
		await create_timer(0.3).timeout
		await frames()
		check(Relay.state(main.world).cleared == ["relay_corridor"] and screen.view.enabled, "actual confirm returns to cleared relay room")
		main.queue_free()
		await frames()
		# Entry-refusal dialog is a real negative UI state.
		world = fresh_towns("settlement:new_hope")
		check(store.save_game(world).success, "wrong-city UI fixture")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		before = main.world.to_canonical_json()
		find_command(main.shell, "中繼站").pressed.emit()
		await frames()
		var refusal_dialog: AcceptDialog
		for child: Node in main.shell.get_children():
			if child is AcceptDialog and child.title == "中繼站入口": refusal_dialog = child
		check(refusal_dialog != null and refusal_dialog.get_ok_button().size.y >= 40 and refusal_dialog.dialog_text.contains("灰谷"), "actual refused entry is readable and native return40px")
		check(main.world.to_canonical_json() == before and not Relay.state(main.world).active, "refusal UI preserves authoritative world")
		await relay_observe("wrong_city_refusal")
		refusal_dialog.get_ok_button().pressed.emit()
		await frames()
		main.queue_free()
		await frames()
	clear_slot()

func relay_combat_ready(combat: Control) -> void:
	for frame_group: int in range(80):
		if not combat.busy: return
		await create_timer(0.05).timeout
	check(not combat.busy, "actual relay combat animation releases input within four seconds")

func run_relay() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	root.size = Vector2i(1280, 720)
	side_replay()
	front_replay()
	relay_refusals()
	relay_negative_history()
	relay_death()
	relay_companion()
	await relay_ui()
	print("RLY-1: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
