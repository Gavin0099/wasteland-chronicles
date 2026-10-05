extends "res://tests/test_relay_return.gd"

const JourneyCapture = preload("res://simulation/relay_custody.gd")
const JourneyDisposition = preload("res://simulation/relay_disposition.gd")
const JourneyTrust = preload("res://simulation/local_trust.gd")
var journey_snapshots: Dictionary = {}
var journey_metrics: Array[Dictionary] = []

func _init() -> void:
	store = Store.new("user://tests/rly8/journey.json")
	call_deferred("run_journey")

func journey_step(world: WorldState, twin: WorldState, intent: PlayerIntent, label: String) -> Dictionary:
	var result: Dictionary = pair_intent(world, twin, intent, label)
	if not result.success: print("JOURNEY_REFUSAL ", label, " ", result)
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", label + " actual global invariants")
	return result

func journey_checkpoint(world: WorldState, label: String) -> WorldState:
	var twin: WorldState = disk_copy(world, label)
	journey_snapshots[label] = world.to_canonical_json()
	journey_metrics.append({"stage": label, "day": world.current_day, "caps": world.player.money, "hp": world.player.field_kit.hp, "water": world.player.inventory.water, "food": world.player.inventory.food, "fuel": world.player.inventory.fuel, "scrap": world.player.inventory.scrap, "melee": world.player.capability.get_rank("MELEE"), "dog_energy": Hound.state(world).energy, "standing": JourneyTrust.score(world, String(ReturnRules.HOME)), "world_sha256": world.to_canonical_json().sha256_text()})
	print("JOURNEY_STAGE ", JSON.stringify(journey_metrics.back()))
	return twin

func ordinary_journey() -> WorldState:
	# normal_relay_start only creates the official new world and commits Creation;
	# no funded/stock/gear/capture_prepared/hound_prepared fixture is called here.
	var world: WorldState = normal_relay_start()
	check(world.player.money == 50 and world.player.inventory.water == 5 and world.player.inventory.food == 5 and world.player.inventory.scrap == 0 and world.player.inventory.fuel == 0 and world.player.field_kit.hp == 12 and world.player.item_inventory.to_dict().items.is_empty(), "reviewed true ordinary50/5water5food/12HP, no gifted items")
	var twin: WorldState = journey_checkpoint(world, "ordinary_start")
	var courier: Dictionary = {}
	for job: Dictionary in Board.postings(world, ReturnRules.HOME):
		if job.archetype == "COURIER": courier = job.definition
	check(not courier.is_empty() and courier.objectives[0].resource == "scrap" and courier.objectives[0].quantity == 2, "reviewed normal day0 rotation offers actual two-scrap delivery")
	var promised: int = 0
	for reward: Dictionary in courier.outcomes.resolved.rewards:
		if reward.type == "CURRENCY": promised = reward.amount
	journey_step(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, courier.id), "accept real posted work before supplies")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 2), "pay for own delivery scrap")
	var money: int = world.player.money
	var stock: int = world.get_settlement(ReturnRules.HOME).inventory.scrap
	journey_step(world, twin, PlayerIntent.create_turn_in_quest(world.player.npc_id, courier.id), "real delivery and promised payment")
	check(world.player.money == money + promised and world.player.inventory.scrap == 0 and world.get_settlement(ReturnRules.HOME).inventory.scrap == stock + 2 and world.current_day == 0, "posted contract paid; same actual two goods enter town, no travel/time invented")
	journey_step(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "START"}), "real supply-shed enemy")
	for turn_index: int in range(3): journey_step(world, twin, combat_intent(world, "ATTACK"), "ordinary base2 against real6HP dog")
	check(world.player.field_kit.hp == 6 and world.field_state.enemy_hp == 0, "reviewed three attacks and two3 counters; no healing/gun gift")
	twin = journey_checkpoint(world, "earned_loot_battle")
	journey_step(world, twin, combat_intent(world, "CONFIRM"), "actual shed result confirmed")
	rejected(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "OPEN"}), "clearing enemy alone does not provide required pry tool")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 3), "pay actual three scrap to make needed pry tool")
	journey_step(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "CRAFT"}), "craft real owned crowbar, leave unequipped")
	check(world.player.field_kit.crowbar and not world.player.field_kit.equipped and world.player.inventory.scrap == 0, "reviewed three-scrap owned tool cost, no damage upgrade gift")
	journey_step(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "OPEN"}), "take actual finite shed supplies")
	check(world.player.inventory.water == 9 and world.player.inventory.food == 7, "reviewed original5 plus actual4water2food loot")
	rejected(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": "OPEN"}), "supply cache cannot respawn")
	journey_step(world, twin, combat_intent(world, "CONFIRM"), "confirm actual cache loot receipt before market or rest")
	journey_step(world, twin, PlayerIntent.create_sell(world.player.npc_id, &"water", 4), "sell actual recovered water for preparation money")
	journey_step(world, twin, PlayerIntent.create_sell(world.player.npc_id, &"food", 2), "sell actual recovered food, retain original rations")
	check(world.player.inventory.water == 5 and world.player.money > 50, "earned budget without direct money/resource writes")
	journey_step(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "REST"}), "real first town recovery day")
	check(world.current_day == 1 and world.player.field_kit.hp == 10, "reviewed actual REST heals4 and advances1 full world day")
	journey_step(world, twin, PlayerIntent.create_field_action(world.player.npc_id, {"command": "REST"}), "real second recovery day")
	check(world.current_day == 2 and world.player.field_kit.hp == 12, "second actual day restores remaining2, no hidden reset")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "actual repair fuel at evolved market")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 4), "actual three repair scrap plus one escape scrap")
	journey_step(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "rope", 1), "one real unique exit rope")
	twin = journey_checkpoint(world, "paid_preparation")
	target_setup(world, twin)
	relay_pair(world, twin, "ENTER"); hound_pair(world, twin, "INSPECT_HOUND"); hound_pair(world, twin, "REPAIR_HOUND")
	check(world.player.inventory.fuel == 0 and world.player.inventory.scrap == 1 and Hound.state(world).energy == 4, "earned repair really pays1fuel3scrap")
	relay_pair(world, twin, "SEARCH"); relay_pair(world, twin, "MOVE", "relay_tunnel"); target_pair(world, twin, "INSPECT_EXIT"); target_pair(world, twin, "BLOCK_EXIT")
	check(not world.player.item_inventory.contains("rope") and world.player.inventory.scrap == 0, "escape consumes only rope and fourth actual scrap")
	twin = journey_checkpoint(world, "repaired_blocked")
	hound_pair(world, twin, "HOUND_OPEN_TUNNEL")
	check(Hound.state(world).energy == 2 and Relay.state(world).tunnel_open, "finite machine gate4->2 replaces tool payment")
	relay_pair(world, twin, "MOVE", "relay_records"); relay_pair(world, twin, "FIND_CARD"); relay_pair(world, twin, "MOVE", "relay_vault"); relay_pair(world, twin, "TAKE_PRIZE")
	check(world.player.item_inventory.quantity("military_backpack") == 1, "real exploration desire physically obtained")
	twin = journey_checkpoint(world, "real_backpack")
	relay_pair(world, twin, "MOVE", "relay_records")
	journey_step(world, twin, JourneyCapture.intent(world, "CHALLENGE_TARGET"), "real living named-person pursuit")
	journey_step(world, twin, JourneyCapture.intent(world, "SUBDUE_TARGET"), "ordinary initial nonlethal2 and earned practice")
	check(JourneyCapture.state(world).target_hp == 6 and world.player.field_kit.hp == 9 and world.player.capability.get_rank("MELEE") == 1, "reviewed second distinct practice day promotes0->1 after first2damage/counter3")
	journey_step(world, twin, JourneyCapture.intent(world, "DISARM_TARGET"), "newly learned actual personal1 disarm")
	journey_step(world, twin, JourneyCapture.intent(world, "SUBDUE_TARGET"), "learned melee3 with unarmed1 counter")
	check(JourneyCapture.state(world).target_hp == 3 and world.player.field_kit.hp == 7 and Hound.state(world).energy == 2, "reviewed human6->3, player9->8->7, no dog human attack")
	twin = journey_checkpoint(world, "pursuit_needs_rope")
	rejected(world, JourneyCapture.intent(world, "BIND_TARGET"), "first exit rope cannot bind weakened target")
	rejected(world, Hound.intent(world, "HOUND_SUPPORT_ON"), "machine cannot work during named pursuit")
	journey_step(world, twin, JourneyCapture.intent(world, "RETREAT_TARGET"), "actual decision to return for separate rope")
	journey_step(world, twin, JourneyCapture.intent(world, "CONFIRM_CAPTURE"), "actual retreat confirmed, same wounds/disarm")
	relay_pair(world, twin, "MOVE", "relay_tunnel"); relay_pair(world, twin, "MOVE", "relay_entrance"); relay_pair(world, twin, "EXIT")
	journey_step(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, "rope", 1), "real second unique binding rope")
	twin = journey_checkpoint(world, "binding_preparation")
	relay_pair(world, twin, "ENTER"); relay_pair(world, twin, "MOVE", "relay_tunnel"); relay_pair(world, twin, "MOVE", "relay_records")
	journey_step(world, twin, JourneyCapture.intent(world, "CHALLENGE_TARGET"), "actual same wounded target revisit")
	check(JourneyCapture.state(world).target_hp == 3 and JourneyCapture.state(world).disarmed, "no enemy heal/rearm/respawn on return")
	journey_step(world, twin, JourneyCapture.intent(world, "BIND_TARGET"), "capture same real resident with second rope")
	check(world.player.field_kit.hp == 6 and JourneyCapture.state(world).captured and not world.player.item_inventory.contains("rope") and Hound.state(world).energy == 2, "retreat1 then binding0 counters; rope consumed, machine unchanged")
	twin = journey_checkpoint(world, "capture_pending")
	journey_step(world, twin, JourneyCapture.intent(world, "CONFIRM_CAPTURE"), "actual capture confirmation")
	relay_pair(world, twin, "MOVE", "relay_tunnel"); relay_pair(world, twin, "MOVE", "relay_entrance"); relay_pair(world, twin, "EXIT")
	var target_id: String = TargetRules.state(world).npc_id
	var sequence: int = world.next_npc_sequence
	money = world.player.money
	var standing: int = JourneyTrust.score(world, String(ReturnRules.HOME))
	journey_step(world, twin, JourneyDisposition.intent(world, "HAND_OVER_TARGET"), "actual living return report")
	check(world.player.money == money + 80 and JourneyTrust.score(world, String(ReturnRules.HOME)) == standing + 4 and world.next_npc_sequence == sequence and String(TargetRules.life(world).npc_id) == target_id and TargetRules.life(world).is_alive(), "reviewed live80/standing4; same resident/identity, no new population")
	rejected(world, JourneyDisposition.intent(world, "HAND_OVER_TARGET"), "no repeated bounty payment")
	journey_step(world, twin, PlayerIntent.create_equip_item(world.player.npc_id, "military_backpack", "back"), "earned backpack equipped in town")
	check(world.player.get_effective_capacity() == 32, "authored actual cargo20->32 reward")
	twin = journey_checkpoint(world, "reported_equipped")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "pay separate shared station fuel")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 1), "pay separate shared station scrap")
	money = world.player.money
	journey_step(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, ReturnRules.ABBAN), "first actual human companion hire")
	check(world.player.money == money - 50, "Abban initial50 is actually paid after earning, never waived")
	relay_pair(world, twin, "ENTER"); relay_pair(world, twin, "MOVE", "relay_tunnel"); relay_pair(world, twin, "INSPECT_POWER"); relay_pair(world, twin, "POWER_TURRET")
	for destination: String in ["relay_entrance", "relay_corridor", "relay_entrance"]: relay_pair(world, twin, "MOVE", destination)
	relay_pair(world, twin, "EXIT")
	check(SimulationEngine.Party.current(world) == ReturnRules.ABBAN and ReturnRules.state(world).operation_index >= 0 and world.player.inventory.fuel == 0 and world.player.inventory.scrap == 0, "actual continuously fed Abban shared paid operation and return")
	twin = journey_checkpoint(world, "shared_return")
	var before: String = world.to_canonical_json()
	var report: Dictionary = ReturnRules.project(world)
	check(report.available and not report.jobs.is_empty() and report.abban.contains("阿扳") and world.to_canonical_json() == before, "current real news/work/companion next decision is read only")
	journey_step(world, twin, ReturnRules.intent(world), "explicit future companion agreement")
	rejected(world, ReturnRules.intent(world), "shared agreement cannot stack")
	journey_step(world, twin, PlayerIntent.create_dismiss_companion(world.player.npc_id), "actual dismissal")
	money = world.player.money
	journey_step(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, ReturnRules.ABBAN), "actual future25 companion rehire")
	check(world.player.money == money - 25 and last_fact(world.to_dict(), "COMPANION_JOINED").payload.fee == 25 and world.player.money >= 0, "reviewed future25 paid, ordinary journey solvent")
	twin = journey_checkpoint(world, "final_rehire")
	parity(world, twin, "full earned ordinary journey finalSHA")
	return world

func ordinary_budget_boundary() -> void:
	var world: WorldState = normal_relay_start()
	var twin: WorldState = disk_copy(world, "alternative actual ordinary repair-only budget")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"fuel", 1), "alternative actual day0 fuel")
	journey_step(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"scrap", 3), "alternative actual day0 repair scrap")
	check(world.player.money < 50, "spending starting money does not create companion funding")
	rejected(world, PlayerIntent.create_hire_companion(world.player.npc_id, ReturnRules.ABBAN), "cannot get first companion free after actual spending")
	disk_copy(world, "actual budget refusal remains valid")

func journey_native() -> void:
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for label: String in ["paid_preparation", "repaired_blocked", "pursuit_needs_rope", "reported_equipped", "final_rehire"]:
			var checked: Dictionary = WorldState.from_json_checked(journey_snapshots[label])
			check(checked.success and store.save_game(checked.world).success, "native exact earned checkpoint saved " + label)
			var main: Node = new_main(); await frames(); main.save_dialog.load_button.pressed.emit(); await frames()
			check(main.world.to_canonical_json() == journey_snapshots[label], "real Main Continue restores earned exact world " + label)
			var before: String = main.world.to_canonical_json()
			match label:
				"repaired_blocked":
					var screen: Control = main.shell.find_child("RelayScreen", false, false)
					screen.show_hound(); await frames(); hound_geometry(screen.hound_dialog)
				"pursuit_needs_rope":
					var screen: Control = main.shell.find_child("RelayScreen", false, false)
					var combat: Control = screen.capture_screen
					check(combat.buttons.BIND_TARGET.disabled and combat.buttons.BIND_TARGET.text.contains("另一條繩索") and not combat.stage.hound_actor.visible, "native actual missing-rope lock and human pursuit isolation")
					for button: Button in combat.buttons.values(): check(button.size.y >= 40, "native pursuit40px commands")
				"reported_equipped": find_command(main.shell, "追獵").pressed.emit(); await frames()
				"final_rehire":
					find_command(main.shell, "回城見聞").pressed.emit(); await frames()
					var dialog: AcceptDialog
					for child: Node in main.shell.get_children():
						if child is ReturnWindow: dialog = child
					hound_geometry_return(dialog)
					for node: Node in dialog.find_children("*", "ScrollContainer", true, false): node.scroll_vertical = 100000
					await frames()
					check(dialog.detail.text.contains("再雇用他收25") and dialog.detail.text.contains("現在可接"), "native actual agreed Abban and real current work in scroll")
			check(main.world.to_canonical_json() == before, "native views and scrolling cannot change earned world")
			await relay_observe("journey_" + label)
			main.queue_free(); await frames()
	clear_slot()

func run_journey() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--render-dir="): render_dir = arg.trim_prefix("--render-dir=")
	if render_dir != "": DirAccess.make_dir_recursive_absolute(render_dir)
	ordinary_journey()
	if failures > 0:
		print("RLY-8: %d assertions, %d failures" % [assertions, failures]); clear_slot(); quit(1); return
	ordinary_budget_boundary()
	await journey_native()
	if render_dir != "":
		var file: FileAccess = FileAccess.open(render_dir.path_join("ordinary-journey-metrics.json"), FileAccess.WRITE)
		check(file != null, "durable actual ordinary journey metrics")
		if file != null: file.store_string(JSON.stringify({"start": "official Gray mechanic28/no traits/50caps; engine commands only, no gifts", "stages": journey_metrics, "human_fun_pacing": "NOT CLAIMED"}, "\t")); file.close()
	clear_slot()
	print("RLY-8: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
