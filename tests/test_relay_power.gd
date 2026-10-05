extends "res://tests/test_relay_target.gd"

const PowerRules = preload("res://simulation/relay_power.gd")
const PowerWindow = preload("res://ui/components/relay_power_dialog.gd")

func _init() -> void:
	store = Store.new("user://tests/rly3/journey.json")
	call_deferred("run_power")

func panel(world: WorldState, twin: WorldState) -> void:
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "SEARCH")
	relay_pair(world, twin, "MOVE", "relay_tunnel")
	relay_pair(world, twin, "INSPECT_POWER")
	var before: String = world.to_canonical_json()
	relay_pair(world, twin, "INSPECT_POWER")
	check(world.to_canonical_json() == before, "reopening discovered panel is byte-identical read only")

func bought_power(quantity: int = 1) -> WorldState:
	var world: WorldState = normal_relay_start()
	var twin: WorldState = disk_copy(world, "normal mechanic no gifts")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", quantity), "real fuel purchase")
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", quantity), "real scrap purchase")
	check(world.player.capability.get_rank("ELECTRONICS") == 1 and world.player.capability.get_rank("MECHANICS") == 2, "reviewed mechanic background ranks1/2")
	return world

func turret_replay() -> WorldState:
	var world: WorldState = bought_power()
	var twin: WorldState = disk_copy(world, "actual preparation")
	var ids: Array = world.npc_life_state_registry.life_states.keys()
	panel(world, twin)
	relay_pair(world, twin, "POWER_TURRET")
	check(world.player.inventory.fuel == 0 and world.player.inventory.scrap == 0 and PowerRules.state(world).charges == 2, "paid fuel1 scrap1 gives exactly two shots")
	rejected(world, relay_intent(world, "POWER_TURRET"), "no duplicate full recharge")
	twin = disk_copy(world, "paid device checked disk")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	rejected(world, relay_intent(world, "MOVE", "relay_records"), "exclusive turret leaves lift closed")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	relay_pair(world, twin, "FIGHT")
	check(Field.attack_damage(world) == 2 and Field.intent_preview(world).attack_damage == 4 and not Field.intent_preview(world).attack_kills, "independent two ordinary plus two support, six HP enemy")
	check(Field.forecast_for_enemy(world, "feral_dog", false).turns == 2 and Field.forecast_for_enemy(world, "feral_dog", false).incoming == 3, "independent supported forecast two attacks with one three-damage retaliation")
	rejected(world, relay_intent(world, "POWER_OFF"), "cannot rewire during combat")
	rejected(world, combat_intent(world, "SHOOT"), "unarmed shot refused without charge loss")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "actual ordinary strike and support")
	var turn_fact: Dictionary = last_fact(world.to_dict(), "FIELD_TURN")
	check(world.field_state.enemy_hp == 2 and world.player.field_kit.hp == 9 and PowerRules.state(world).charges == 1 and turn_fact.payload.dealt == 4 and turn_fact.payload.turret_dealt == 2, "independent first strike:6->2,12->9,2->1; distinct support receipt")
	twin = disk_copy(world, "midcombat paid remaining charge")
	check(Field.intent_preview(world).attack_kills and Field.intent_preview(world).turret_support == 0, "ordinary killing strike preview uses no shot")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "ordinary kill retains charge")
	check(world.field_state.enemy_hp == 0 and world.player.field_kit.hp == 9 and PowerRules.state(world).charges == 1 and not last_fact(world.to_dict(), "FIELD_TURN").payload.has("turret_dealt"), "kill gives no retaliation and no wasted charge")
	check(world.event_log[world.field_state.receipt].payload.outcome == "VICTORY" and Relay.state(world).cleared == ["relay_corridor"], "existing victory authority clears actual dog")
	twin = disk_copy(world, "supported victory receipt")
	rejected(world, relay_intent(world, "POWER_OFF"), "pending result locks device")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "actual result confirmation")
	rejected(world, relay_intent(world, "FIGHT"), "no respawn or device farm")
	check(world.npc_life_state_registry.life_states.keys() == ids, "fixed equipment introduces no human entity")
	# Same real guard without support: three 2-damage attacks, two3-damage blows.
	var ordinary: WorldState = normal_relay_start()
	var ordinary_twin: WorldState = disk_copy(ordinary, "ordinary comparison independent fixture")
	relay_pair(ordinary, ordinary_twin, "ENTER")
	relay_pair(ordinary, ordinary_twin, "MOVE", "relay_corridor")
	relay_pair(ordinary, ordinary_twin, "FIGHT")
	for step: int in range(3): pair_intent(ordinary, ordinary_twin, combat_intent(ordinary, "ATTACK"), "ordinary comparison attack")
	check(ordinary.player.field_kit.hp == 6 and ordinary.field_state.enemy_hp == 0 and PowerRules.state(ordinary).charges == 0, "independent unpowered comparison HP6 vs powered HP9")
	return world

func lift_replay() -> WorldState:
	var world: WorldState = bought_power()
	var twin: WorldState = disk_copy(world, "lift normal preparation")
	panel(world, twin)
	relay_pair(world, twin, "POWER_LIFT")
	rejected(world, relay_intent(world, "POWER_LIFT"), "no duplicate lift payment")
	check(PowerRules.state(world).mode == "LIFT" and PowerRules.state(world).charges == 0 and not Relay.state(world).tunnel_open, "real mutually exclusive lift, no manual door shortcut")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "MOVE", "relay_records")
	check(Relay.state(world).trip_moves == 3 and Relay.state(world).cleared.is_empty() and not Relay.state(world).tunnel_open, "entrance to records is one real movement bypassing uncleared guard and sealed inner door")
	rejected(world, relay_intent(world, "MOVE", "relay_vault"), "lift never gifts vault card")
	rejected(world, relay_intent(world, "MOVE", "relay_tunnel"), "original sealed door condition unchanged")
	relay_pair(world, twin, "FIND_CARD")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	check(world.current_day == 1 and world.player.inventory.water == 4 and world.player.inventory.food == 4 and Relay.state(world).work_units == 0, "four moves including both lift directions advance real global day and rations")
	relay_pair(world, twin, "EXIT")
	twin = disk_copy(world, "lift survives retreat and actual Continue")
	relay_pair(world, twin, "ENTER")
	relay_pair(world, twin, "MOVE", "relay_records")
	relay_pair(world, twin, "MOVE", "relay_vault")
	relay_pair(world, twin, "TAKE_PRIZE")
	check(world.player.item_inventory.quantity("military_backpack") == 1 and PowerRules.state(world).mode == "LIFT", "real once-only prize with paid persistent lift")
	return world

func power_cost_boundaries() -> void:
	var world: WorldState = normal_relay_start()
	world.player.inventory.fuel = 2 # Explicit two-bundle switching boundary, not a normal-start gift.
	world.player.inventory.scrap = 2
	var twin: WorldState = disk_copy(world, "two paid bundles")
	panel(world, twin)
	relay_pair(world, twin, "POWER_TURRET")
	relay_pair(world, twin, "POWER_LIFT")
	check(world.player.inventory.fuel == 0 and world.player.inventory.scrap == 0 and PowerRules.state(world).charges == 0, "switch pays again and discards two unused shots")
	relay_pair(world, twin, "POWER_OFF")
	check(PowerRules.state(world).mode == "OFF" and world.player.inventory.fuel == 0, "off refunds nothing")
	rejected(world, relay_intent(world, "POWER_OFF"), "off again refuses")
	rejected(world, relay_intent(world, "POWER_TURRET"), "empty fuel no free enable")
	var cold: WorldState = PlayableWorld.create_world()
	check(engine.commit_character_creation(cold, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "非技師", "age": 28, "background_id": "SCAVENGER", "trait_ids": []})).success, "actual nonmechanic background")
	cold.player.inventory.fuel = 1 # Explicit resource boundary fixture; no skill gift.
	cold.player.inventory.scrap = 1
	twin = disk_copy(cold, "nonmechanic resource fixture")
	pair_intent(cold, twin, PlayerIntent.create_hire_companion(cold.player.npc_id, "companion:abban"), "real Abban hire cannot lend personal electronic/mechanical rank")
	panel(cold, twin)
	rejected(cold, relay_intent(cold, "POWER_TURRET"), "personal electronics required")
	rejected(cold, relay_intent(cold, "POWER_LIFT"), "no mechanics or actual tool")
	check(cold.player.pickup_item("wrench").success, "explicit owned fallback tool fixture")
	twin = disk_copy(cold, "owned tool no personal skill")
	relay_pair(cold, twin, "POWER_LIFT")
	var configured: Dictionary = last_fact(cold.to_dict(), "STATION_POWER_CONFIGURED").payload
	check(configured.method == "TOOL" and configured.tool_id == "wrench" and configured.rank == 0 and cold.player.item_inventory.contains("wrench"), "real tool authorizes lift, recorded rank0 and retained tool")
	var rejected_world: WorldState = normal_relay_start()
	twin = disk_copy(rejected_world, "no resources")
	for command_id: String in PowerRules.COMMANDS: rejected(rejected_world, relay_intent(rejected_world, command_id), "outside panel " + command_id)
	relay_pair(rejected_world, twin, "ENTER")
	relay_pair(rejected_world, twin, "SEARCH")
	relay_pair(rejected_world, twin, "MOVE", "relay_tunnel")
	rejected(rejected_world, relay_intent(rejected_world, "POWER_TURRET"), "inspect first")
	relay_pair(rejected_world, twin, "INSPECT_POWER")
	rejected(rejected_world, relay_intent(rejected_world, "POWER_LIFT"), "actual fuel missing")
	rejected_world.player.inventory.fuel = 1
	rejected(rejected_world, relay_intent(rejected_world, "POWER_TURRET"), "actual scrap missing")
	var before: String = rejected_world.to_canonical_json()
	check(not PowerRules.commit(rejected_world, {"site_id": PowerRules.SITE, "command": "POWER_TURRET"}, [], engine).success and rejected_world.to_canonical_json() == before, "direct device API resource rejection remains atomic")
	for payload: Dictionary in [{"site_id": PowerRules.SITE, "command": "POWER_OFF", "refund": 1}, {"site_id": false, "command": "POWER_OFF"}, {"site_id": PowerRules.SITE, "command": 1}, {"site_id": PowerRules.SITE, "command": "POWER_ALL"}]: rejected(rejected_world, PlayerIntent.create_dungeon_action(rejected_world.player.npc_id, payload), "closed exact power intent")
	rejected(rejected_world, PlayerIntent.create_dungeon_action(&"npc:unknown", {"site_id": PowerRules.SITE, "command": "POWER_OFF"}), "wrong power actor")
	# A second purchased bundle refills a partially used turret without resetting
	# the dog or refunding the original fuel. Money here is an explicit budget fixture.
	var refill: WorldState = normal_relay_start()
	refill.player.money = 100
	twin = disk_copy(refill, "explicit refuel budget")
	pair_intent(refill, twin, PlayerIntent.create_buy(refill.player.npc_id, &"fuel", 2), "actual two fuel purchase")
	pair_intent(refill, twin, PlayerIntent.create_buy(refill.player.npc_id, &"scrap", 2), "actual two scrap purchase")
	panel(refill, twin)
	relay_pair(refill, twin, "POWER_TURRET")
	relay_pair(refill, twin, "MOVE", "relay_entrance")
	relay_pair(refill, twin, "MOVE", "relay_corridor")
	relay_pair(refill, twin, "FIGHT")
	pair_intent(refill, twin, combat_intent(refill, "ATTACK"), "spent partial fuel")
	pair_intent(refill, twin, combat_intent(refill, "FLEE"), "refill retreat")
	pair_intent(refill, twin, combat_intent(refill, "CONFIRM"), "refill receipt confirm")
	relay_pair(refill, twin, "MOVE", "relay_entrance")
	relay_pair(refill, twin, "MOVE", "relay_tunnel")
	relay_pair(refill, twin, "POWER_TURRET")
	check(PowerRules.state(refill).charges == 2 and refill.player.inventory.fuel == 0 and refill.player.inventory.scrap == 0 and Relay.state(refill).cleared.is_empty(), "partial refill pays another bundle, two remaining charges, no direct guard clear")
	twin = disk_copy(refill, "actual refilled checked save")
	relay_pair(refill, twin, "MOVE", "relay_entrance")
	relay_pair(refill, twin, "EXIT")
	pair_intent(refill, twin, PlayerIntent.create_field_action(refill.player.npc_id, {"command": "START"}), "ordinary supply shed with paid relay turret elsewhere")
	pair_intent(refill, twin, combat_intent(refill, "ATTACK"), "other site no support")
	check(PowerRules.state(refill).charges == 2 and not last_fact(refill.to_dict(), "FIELD_TURN").payload.has("turret_dealt"), "actual other-site battle preserves all relay charges")
	var gun: WorldState = bought_power()
	check(gun.player.pickup_item("police_revolver").success, "explicit real gun ownership fixture with no ammo")
	check(engine.commit_player_intent(gun, PlayerIntent.create_equip_item(gun.player.npc_id, "police_revolver", "main_hand")).success, "actual firearm equipped before entry")
	twin = disk_copy(gun, "actual empty weapon checked control")
	panel(gun, twin)
	relay_pair(gun, twin, "POWER_TURRET")
	relay_pair(gun, twin, "MOVE", "relay_entrance")
	relay_pair(gun, twin, "MOVE", "relay_corridor")
	relay_pair(gun, twin, "FIGHT")
	rejected(gun, combat_intent(gun, "SHOOT"), "equipped empty gun loses neither turn nor support")
	check(gun.player.pickup_item("revolver_round").success, "explicit one owned round fixture")
	twin = disk_copy(gun, "one actual round")
	pair_intent(gun, twin, combat_intent(gun, "SHOOT"), "ordinary lethal firearm spends round, no turret charge")
	check(gun.player.item_inventory.quantity("revolver_round") == 0 and PowerRules.state(gun).charges == 2 and not last_fact(gun.to_dict(), "FIELD_TURN").payload.has("turret_dealt"), "six HP gun kill retains both support charges")

func retained_and_empty() -> WorldState:
	var world: WorldState = bought_power()
	var twin: WorldState = disk_copy(world, "retreat charge replay")
	panel(world, twin)
	relay_pair(world, twin, "POWER_TURRET")
	relay_pair(world, twin, "MOVE", "relay_entrance")
	relay_pair(world, twin, "MOVE", "relay_corridor")
	relay_pair(world, twin, "FIGHT")
	pair_intent(world, twin, combat_intent(world, "DEFEND"), "brace never spends support")
	check(PowerRules.state(world).charges == 2, "brace charge count unchanged")
	pair_intent(world, twin, combat_intent(world, "FLEE"), "escape never spends support")
	check(PowerRules.state(world).charges == 2 and Relay.state(world).cleared.is_empty(), "escape keeps charges and uncleared guard")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "escape confirmation")
	relay_pair(world, twin, "FIGHT")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "first spent shot before retreat")
	pair_intent(world, twin, combat_intent(world, "FLEE"), "one shot remains through flee")
	twin = disk_copy(world, "one remaining paid shot after actual flee")
	pair_intent(world, twin, combat_intent(world, "CONFIRM"), "second escape confirmation")
	relay_pair(world, twin, "FIGHT")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "last support charge spent")
	check(PowerRules.state(world).charges == 0 and world.field_state.enemy_hp == 2, "independent last shot6->2 and charges1->0")
	pair_intent(world, twin, combat_intent(world, "ATTACK"), "empty charge normal strike")
	check(PowerRules.state(world).charges == 0 and not last_fact(world.to_dict(), "FIELD_TURN").payload.has("turret_dealt"), "empty turret has no ghost shot")
	return world

func power_negative(world: WorldState) -> void:
	for fixture: int in range(28):
		var data: Dictionary = world.to_dict().duplicate(true)
		var p: Dictionary = last_fact(data, "STATION_POWER_CONFIGURED").payload
		var shot: Dictionary = last_fact(data, "STATION_POWER_SHOT")
		match fixture:
			0: p.mode = "ALL"
			1: p.mode = false
			2: p.charges = 3
			3: p.charges = false
			4: p.fuel_spent = 0
			5: p.scrap_spent = "1"
			6: p.method = "COMPANION"
			7: p.rank = 2
			8: p.tool_id = "wrench"
			9: p.room_id = "relay_records"
			10: p.site_id = "dungeon:sealed_waterworks"
			11: p.refund = 1
			12: last_fact(data, "STATION_POWER_CONFIGURED").actor_id = "npc:unknown"
			13: last_fact(data, "STATION_POWER_CONFIGURED").target_id = "dungeon:sealed_waterworks"
			14: shot.payload.remaining = 2
			15: shot.payload.damage = 3
			16: shot.payload.turn = 2
			17: shot.payload.battle_id = 99
			18: shot.payload.enemy = "bandit"
			19: shot.payload.room_id = "relay_tunnel"
			20: shot.payload.remaining = false
			21: data.events.erase(shot)
			22:
				for fact: Dictionary in data.events:
					if fact.type == "FIELD_TURN" and fact.payload.has("turret_dealt"): fact.payload.turret_dealt = 1
			23: data.events.erase(last_fact(data, "STATION_POWER_FOUND"))
			24: p.rank = 0.5
			25: p.method = false
			26: last_fact(data, "STATION_POWER_CONFIGURED").day = 1
			27:
				for fact: Dictionary in data.events:
					if fact.type == "FIELD_TURN" and fact.payload.has("turret_dealt"): fact.payload.source = "field"
		relay_reject_fixture(data, "power invalid typed receipt " + str(fixture))
	var stray: Dictionary = world.to_dict().duplicate(true)
	stray.events.append({"day": world.current_day, "type": "STATION_POWER_UNKNOWN", "actor_id": String(world.player.npc_id), "target_id": PowerRules.SITE, "payload": {"site_id": PowerRules.SITE}})
	relay_reject_fixture(stray, "closed unknown power fact")

func power_compatibility() -> void:
	var old: WorldState = side_replay()
	check(not PowerRules.state(old).inspected and PowerRules.state(old).mode == "OFF" and WorldState.from_json_checked(old.to_canonical_json()).success, "old relay facts retain unpowered original route and checked snapshot")
	var dead: WorldState = normal_relay_start()
	dead.player.field_kit.hp = 1
	var twin: WorldState = disk_copy(dead, "fatal power refusal control")
	panel(dead, twin)
	relay_pair(dead, twin, "MOVE", "relay_entrance")
	relay_pair(dead, twin, "MOVE", "relay_corridor")
	relay_pair(dead, twin, "FIGHT")
	pair_intent(dead, twin, combat_intent(dead, "FLEE"), "actual fatal relay escape")
	pair_intent(dead, twin, combat_intent(dead, "CONFIRM"), "fatal confirmation")
	rejected(dead, relay_intent(dead, "INSPECT_POWER"), "dead player no device use")
	var road: WorldState = fresh_towns("settlement:gray_valley")
	check(not PowerRules.supported_battle(road) and PowerRules.preview(road, 2) == 0, "unrelated ordinary field never receives device support")
	var water: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(water, dungeon_intent(water, "ENTER")).success, "legacy waterworks positive")
	for command_id: String in PowerRules.COMMANDS: rejected(water, relay_intent(water, command_id), "waterworks cannot use relay device")
	check(WorldState.from_json_checked(water.to_canonical_json()).success, "legacy checked waterworks snapshot unchanged")
	var learner: WorldState = PlayableWorld.create_world()
	check(engine.commit_character_creation(learner, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "電子學徒", "age": 28, "background_id": "SCAVENGER", "trait_ids": []})).success, "real nonmechanic training preparation")
	learner.player.money = 120 # Explicit teacher-budget fixture, not a gifted rank.
	twin = disk_copy(learner, "teacher-budget control")
	pair_intent(learner, twin, PlayerIntent.create_train_skill(learner.player.npc_id, "ELECTRONICS"), "actual existing Gray Valley teacher")
	check(learner.player.capability.get_rank("ELECTRONICS") == 1 and learner.current_day == 2 and learner.player.money == 60, "actual teacher raises personal rank for60caps and two days")
	pair_intent(learner, twin, PlayerIntent.create_buy(learner.player.npc_id, &"fuel", 1), "learner real fuel")
	pair_intent(learner, twin, PlayerIntent.create_buy(learner.player.npc_id, &"scrap", 1), "learner real scrap")
	panel(learner, twin)
	relay_pair(learner, twin, "POWER_TURRET")
	check(PowerRules.state(learner).charges == 2 and last_fact(learner.to_dict(), "STATION_POWER_CONFIGURED").payload.rank == 1, "learned personal electronics opens actual new device ability")

func power_geometry(dialog: AcceptDialog) -> void:
	check(dialog.position.x >= 0 and dialog.position.y >= 0 and dialog.position.x + dialog.size.x <= root.size.x and dialog.position.y + dialog.size.y <= root.size.y, "native power window fits viewport")
	check(dialog.get_ok_button().size.y >= 40, "native power return40px")
	for command_id: String in dialog.action_buttons:
		var b: Button = dialog.action_buttons[command_id]
		check(b.size.y >= 40 and b.get_global_rect().end.x <= dialog.size.x, "actual power commands fit40px " + command_id)

func power_ui() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		var world: WorldState = bought_power()
		check(store.save_game(world).success, "normal purchased supply native disk")
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		find_command(main.shell, "中繼站").pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("RelayScreen", false, false)
		for entry: Dictionary in [{"command": "SEARCH"}, {"command": "MOVE", "to": "relay_tunnel"}, {"command": "INSPECT_POWER"}]:
			target_guide(screen, entry.command, entry.get("to", ""))
			screen.interact_button.pressed.emit()
			await frames()
		check(screen.power_dialog != null and not screen.view.enabled, "actual nearby power panel opens and pauses walker")
		var dialog: AcceptDialog = screen.power_dialog
		power_geometry(dialog)
		await relay_observe("power_choices")
		dialog.action_buttons.POWER_TURRET.pressed.emit()
		await frames()
		check(PowerRules.state(main.world).charges == 2 and dialog.action_buttons.POWER_TURRET.disabled and dialog.detail.text.contains("燃料0"), "native real purchase and payment shown")
		power_geometry(dialog)
		await relay_observe("turret_paid")
		dialog.get_ok_button().pressed.emit()
		await frames()
		for destination: String in ["relay_entrance", "relay_corridor"]:
			target_guide(screen, "MOVE", destination)
			screen.interact_button.pressed.emit()
			await frames()
		await relay_observe("turret_room")
		target_guide(screen, "FIGHT")
		screen.interact_button.pressed.emit()
		await frames()
		var combat: Control = screen.combat_screen
		check(combat.stage.support_turret.visible and combat.buttons.ATTACK.text.contains("砲塔2"), "real battle displays controlled original prop and separate support")
		var phases: Array[String] = []
		combat.stage.feedback_phase.connect(func(value: String) -> void: phases.append(value))
		combat.buttons.ATTACK.pressed.emit()
		for step: int in range(100):
			if "turret_support" in phases: break
			await create_timer(0.02).timeout
		await relay_observe("turret_support_motion")
		await relay_combat_ready(combat)
		check("turret_support" in phases and main.world.field_state.enemy_hp == 2 and combat.status_label.text.contains("砲塔剩1"), "actual committed support has receipt motion and remaining count")
		combat.stage.reduced_motion = true
		combat.buttons.ATTACK.pressed.emit()
		await relay_combat_ready(combat)
		check(PowerRules.state(main.world).charges == 1 and "reduced" in phases, "native reduced-motion killing strike does not consume support")
		await relay_observe("supported_victory_reduced")
		combat.buttons.CONFIRM.pressed.emit()
		await frames()
		check(store.save_game(main.world).success, "actual remaining charge Continue disk")
		var before: String = main.world.to_canonical_json()
		main.queue_free()
		await frames()
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		check(main.world.to_canonical_json() == before and PowerRules.state(main.world).charges == 1, "actual Continue retains paid charge and clear once")
		await relay_observe("turret_continue")
		main.queue_free()
		await frames()
		world = bought_power()
		var twin: WorldState = disk_copy(world, "native actual lift preparation")
		panel(world, twin)
		relay_pair(world, twin, "POWER_LIFT")
		relay_pair(world, twin, "MOVE", "relay_entrance")
		check(store.save_game(world).success, "actual powered lift native disk")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		relay_geometry(screen)
		await relay_observe("lift_entrance")
		target_guide(screen, "MOVE", "relay_records")
		screen.interact_button.pressed.emit()
		await frames()
		check(Relay.state(main.world).room_id == "relay_records" and Relay.state(main.world).cleared.is_empty(), "native real lift moves past live guard")
		await relay_observe("lift_records")
		main.queue_free()
		await frames()
		# A genuine nonmechanic and no-resource panel, then a reduced-motion
		# support turn. Both are actual runtime scenes, never a visual mockup.
		world = PlayableWorld.create_world()
		check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "拾荒旅人", "age": 28, "background_id": "SCAVENGER", "trait_ids": []})).success, "native real skill-lock character")
		twin = disk_copy(world, "native empty-resource control")
		panel(world, twin)
		check(store.save_game(world).success, "native locked panel disk")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		target_guide(screen, "INSPECT_POWER")
		screen.interact_button.pressed.emit()
		await frames()
		dialog = screen.power_dialog
		power_geometry(dialog)
		check(dialog.action_buttons.POWER_TURRET.disabled and dialog.action_buttons.POWER_TURRET.text.contains("本人電子1") and dialog.action_buttons.POWER_LIFT.text.contains("機械1"), "actual skill locks visibly state personal requirements")
		before = main.world.to_canonical_json()
		await relay_observe("power_skill_locked")
		check(main.world.to_canonical_json() == before, "native locked queries preserve bytes")
		main.queue_free()
		await frames()
		world = bought_power()
		twin = disk_copy(world, "native reduced support start")
		panel(world, twin)
		relay_pair(world, twin, "POWER_TURRET")
		relay_pair(world, twin, "MOVE", "relay_entrance")
		relay_pair(world, twin, "MOVE", "relay_corridor")
		relay_pair(world, twin, "FIGHT")
		check(store.save_game(world).success, "native reduced support actual battle disk")
		main = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		screen = main.shell.find_child("RelayScreen", false, false)
		combat = screen.combat_screen
		combat.stage.reduced_motion = true
		phases.clear()
		combat.stage.feedback_phase.connect(func(value: String) -> void: phases.append(value))
		combat.buttons.ATTACK.pressed.emit()
		await relay_combat_ready(combat)
		check("turret_support" in phases and "reduced" in phases and PowerRules.state(main.world).charges == 1 and main.world.field_state.enemy_hp == 2, "reduced motion retains actual support damage and charge")
		await relay_observe("turret_support_reduced")
		main.queue_free()
		await frames()
	clear_slot()

func run_power() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	root.size = Vector2i(1280, 720)
	var supported: WorldState = turret_replay()
	var lifted: WorldState = lift_replay()
	for value: Variant in [false, 1, {}, "ALL"]:
		var data: Dictionary = lifted.to_dict().duplicate(true)
		last_fact(data, "STATION_POWER_CONFIGURED").payload.mode = value
		relay_reject_fixture(data, "malformed mode with actual historical lift moves " + str(value))
	power_cost_boundaries()
	retained_and_empty()
	power_negative(supported)
	power_compatibility()
	await power_ui()
	print("RLY-3: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
