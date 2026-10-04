extends "res://tests/test_dungeon_deep_reward.gd"

func _init() -> void:
	store = Store.new("user://tests/dun7/journey.json")
	call_deferred("run_device")

func device_intent(world: WorldState, choice: Variant) -> PlayerIntent:
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"command": "DECIDE_DEVICE", "choice": choice})

func device_fixture(with_abban: bool = true, worn: bool = true) -> WorldState:
	var world: WorldState = deep_fixture()
	check(engine.commit_player_intent(world, dungeon_intent(world, "EXIT")).success, "actual device preparation in town")
	if with_abban:
		world.player.money = 50 # Reviewed existing hire-fee fixture, no new currency source.
		check(engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Dungeon.Party.ABBAN)).success, "actual Abban hire")
	if not worn: check(engine.commit_player_intent(world, PlayerIntent.create_unequip_item(world.player.npc_id, "body")).success, "actual stowed armor preparation")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success, "actual versioned device trip")
	return world

func to_control(world: WorldState, twin: WorldState = null) -> void:
	to_pump(world, twin)
	var intent: PlayerIntent = dungeon_intent(world, "MOVE", "pump", "control")
	if twin == null: check(engine.commit_player_intent(world, intent).success, "actual control fourth move")
	else: pair_intent(world, twin, intent, "actual control fourth move twin")

func leave_control(world: WorldState, twin: WorldState = null) -> void:
	for intent: PlayerIntent in [dungeon_intent(world, "OPEN_SHORTCUT"), dungeon_intent(world, "MOVE", "control", "entrance"), dungeon_intent(world, "EXIT")]:
		if twin == null: check(engine.commit_player_intent(world, intent).success, "actual device shortcut retreat")
		else: pair_intent(world, twin, intent, "actual device shortcut retreat twin")

func device_replay() -> void:
	for choice: String in ["PRESERVE", "SALVAGE"]:
		var world: WorldState = device_fixture()
		var twin: WorldState = disk_copy(world, "actual device entry disk")
		to_control(world, twin)
		check(world.current_day == 1 and world.player.inventory.scrap == 3 and world.player.inventory.water == 4 and world.player.inventory.food == 4, "independent one-day Abban supply/once gate fixture")
		var old_weight: int = world.player.item_inventory.total_weight_g()
		var old_protection: int = Gear.protection(world.player)
		var before_day: int = world.current_day
		pair_intent(world, twin, device_intent(world, choice), "actual explicit device choice twin")
		check(world.current_day == before_day and world.player.inventory.scrap == (0 if choice == "PRESERVE" else 7), "independent exact material exchange/no extra day")
		check(Dungeon.state(world).device_choice == choice and Dungeon.state(world).device_companion == Dungeon.Party.ABBAN and Dungeon.device_note(world).contains("你和阿扳"), "actual choice/shared companion memory")
		if choice == "PRESERVE":
			check(not world.player.item_inventory.contains("leather_jacket") and world.player.item_inventory.contains("reinforced_leather_jacket"), "real existing armor replaced once")
			check(world.player.item_inventory.total_weight_g() == old_weight + 500 and old_protection == 1 and Gear.protection(world.player) == 2, "independent armor weight/protection consequence")
			check(world.player.equipment.equipped_item("body") == "reinforced_leather_jacket", "worn armor stays worn by validated replacement")
		else:
			check(world.player.item_inventory.total_weight_g() == old_weight and Gear.protection(world.player) == old_protection, "salvage changes only actual aggregate scrap")
		rejected(world, device_intent(world, choice), "device decision cannot charge or reward twice")
		rejected(world, device_intent(world, "SALVAGE" if choice == "PRESERVE" else "PRESERVE"), "device decision irreversible")
		var restored: WorldState = disk_copy(world, "actual decided device save")
		parity(world, restored, "device persisted twin SHA")
		leave_control(world, twin)
		pair_intent(world, twin, dungeon_intent(world, "ENTER"), "actual device revisit")
		pair_intent(world, twin, dungeon_intent(world, "MOVE", "entrance", "control"), "actual saved shortcut revisit")
		rejected(world, device_intent(world, "PRESERVE"), "revisit cannot reuse bench")
		check(Dungeon.state(world).device_choice == choice, "actual persistent bench outcome")
	var stowed: WorldState = device_fixture(true, false)
	to_control(stowed)
	check(engine.commit_player_intent(stowed, device_intent(stowed, "PRESERVE")).success and stowed.player.equipment.equipped_item("body") == "" and Gear.protection(stowed.player) == 0, "stowed transformation does not silently equip armor")
	check(engine.validate_invariants(stowed) == "" and WorldState.from_json_checked(stowed.to_canonical_json()).success, "stowed armor live/checked positive control")
	clear_slot()

func device_refusals_and_history() -> void:
	var world: WorldState = device_fixture()
	rejected(world, device_intent(world, "PRESERVE"), "wrong room device refusal")
	to_control(world)
	for invalid: Variant in [false, "OTHER", null, 1, {}]: rejected(world, device_intent(world, invalid), "closed typed device choice")
	var extra: PlayerIntent = device_intent(world, "PRESERVE")
	extra.payload["free"] = true
	rejected(world, extra, "device extra payload rejected")
	var wrong: PlayerIntent = device_intent(world, "PRESERVE")
	wrong.player_id = &"npc:unknown"
	rejected(world, wrong, "wrong device actor")
	var not_enough: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	not_enough.player.inventory.scrap = 2
	rejected(not_enough, device_intent(not_enough, "PRESERVE"), "three scrap actually required")
	var full_items: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	check(full_items.player.pickup_item("first_aid_kit", 11).success and full_items.player.item_inventory.total_weight_g() == 11650, "independent near-full real item budget")
	rejected(full_items, device_intent(full_items, "PRESERVE"), "extra500g refuses atomically before materials/slot exchange")
	check(Dungeon.state(full_items).device_choice == "" and full_items.player.equipment.equipped_item("body") == "leather_jacket", "full refusal retains old armor and undecided bench")
	var duplicate: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	check(duplicate.player.pickup_item("reinforced_leather_jacket").success, "owned unique result fixture")
	rejected(duplicate, device_intent(duplicate, "PRESERVE"), "duplicate result refuses without consuming source")
	var missing: WorldState = device_fixture(false)
	to_control(missing)
	rejected(missing, device_intent(missing, "PRESERVE"), "actual missing Abban cannot preserve")
	missing.player.inventory.water = 19
	missing.player.inventory.food = 1
	missing.player.inventory.scrap = 0
	rejected(missing, device_intent(missing, "SALVAGE"), "full aggregate budget cannot receive four scrap")
	missing.player.inventory.water = 15
	check(engine.commit_player_intent(missing, device_intent(missing, "SALVAGE")).success and missing.player.inventory.scrap == 4 and Dungeon.state(missing).device_companion == "", "solo salvage actual full-four capacity and no invented Abban memory")
	check(not Dungeon.device_note(missing).contains("阿扳"), "solo memory does not invent companion participation")
	check(engine.commit_player_intent(world, device_intent(world, "PRESERVE")).success, "actual positive decided history seed")
	check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "device live/checked positive control")
	for key: String in ["choice", "companion_id", "scrap_spent", "scrap_gained", "item_spent", "item_gained", "worn", "room_id", "dungeon_id"]:
		var data: Dictionary = world.to_dict().duplicate(true)
		last_fact(data, "DUNGEON_DEVICE_DECIDED").payload[key] = null
		reject_global_fixture(data, "typed device fact rejects malformed " + key)
	for mode: int in range(11):
		var data: Dictionary = world.to_dict().duplicate(true)
		var fact: Dictionary = last_fact(data, "DUNGEON_DEVICE_DECIDED")
		match mode:
			0: fact.payload.scrap_spent = 2
			1: fact.payload.scrap_gained = 4
			2: fact.payload.item_gained = "plated_leather_jacket"
			3: fact.payload.companion_id = "companion:shahu"
			4: fact.payload.room_id = "pump"
			5: fact.actor_id = "npc:unknown"
			6: fact.payload.extra = true
			7: data.events.append(fact.duplicate(true))
			8: fact.day += 1
			9: last_fact(data, "DUNGEON_ENTERED").payload.erase("device_rules")
			10: fact.payload.worn = "true"
		reject_global_fixture(data, "device exact fixed/context/once proof %d" % mode)
	for invalid: Variant in [false, "1", 0, 2, null, {}]:
		var data: Dictionary = world.to_dict().duplicate(true)
		last_fact(data, "DUNGEON_ENTERED").payload.device_rules = invalid
		reject_global_fixture(data, "typed device trip version")
	var pending: WorldState = device_fixture()
	to_pump(pending)
	check(engine.commit_player_intent(pending, fight_intent(pending, "pump")).success, "actual pending device-refusal fight")
	rejected(pending, device_intent(pending, "SALVAGE"), "pending fight device choice refused")
	win(pending)
	rejected(pending, device_intent(pending, "SALVAGE"), "unconfirmed battle receipt device choice refused")
	var fatal: WorldState = device_fixture(false)
	to_pump(fatal)
	fatal.player.field_kit.hp = 1 # Reviewed injury; death must come from actual combat.
	check(engine.commit_player_intent(fatal, fight_intent(fatal, "pump")).success, "actual low-health fight")
	check(engine.commit_player_intent(fatal, combat_intent(fatal, "ATTACK")).success and fatal.player.field_kit.hp == 0, "actual fatal counterattack")
	rejected(fatal, device_intent(fatal, "SALVAGE"), "dead pending device choice refused")
	clear_slot()

func armor_combat_consequence() -> void:
	var improved: WorldState = device_fixture()
	to_control(improved)
	var ordinary: WorldState = disk_copy(improved, "actual pre-improvement comparison checkpoint")
	check(engine.commit_player_intent(improved, device_intent(improved, "PRESERVE")).success, "actual armor improvement for combat")
	for world: WorldState in [ordinary, improved]:
		check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "control", "pump")).success, "actual return to optional pump opponent")
		check(engine.commit_player_intent(world, fight_intent(world, "pump")).success, "actual same first dog bite fixture")
		check(engine.commit_player_intent(world, combat_intent(world, "ATTACK")).success, "actual same knife strike and counterattack")
		check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "actual armor combat live/checked")
	# Authored first dog bite3, ordinary defense1 and reinforced defense2.
	check(ordinary.player.field_kit.hp == 10 and improved.player.field_kit.hp == 11, "real combat receives one less damage after chosen armor improvement")
	clear_slot()

func undecided_legacy_revisit() -> void:
	var world: WorldState = device_fixture(false)
	for event: EventRecord in world.event_log:
		if event.type == "DUNGEON_ENTERED": event.payload.erase("device_rules") # Reviewed old five-key DUN-6 trip.
	to_control(world)
	check(engine.validate_invariants(world) == "" and Dungeon.state(world).device_rules == 0, "old deep1 trip retains valid pre-device behavior")
	rejected(world, device_intent(world, "SALVAGE"), "old trip cannot acquire unsupported device result")
	world = disk_copy(world, "valid old control checkpoint")
	leave_control(world)
	check(engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Dungeon.Party.ABBAN)).success, "actual later Abban preparation after undecided retreat")
	check(engine.commit_player_intent(world, dungeon_intent(world, "ENTER")).success and Dungeon.state(world).device_rules == 1, "next actual entry activates device rules")
	check(engine.commit_player_intent(world, dungeon_intent(world, "MOVE", "entrance", "control")).success, "actual revisit saved shortcut")
	world.player.inventory.scrap = 3 # Reviewed supplied return visit.
	check(engine.commit_player_intent(world, device_intent(world, "PRESERVE")).success, "undecided old trip can return prepared and choose once")
	check(engine.validate_invariants(world) == "" and WorldState.from_json_checked(world.to_canonical_json()).success, "legacy activation positive live/checked")
	var downgrade: Dictionary = world.to_dict().duplicate(true)
	last_fact(downgrade, "DUNGEON_ENTERED").payload.erase("device_rules")
	reject_global_fixture(downgrade, "device decision needs activated version")
	clear_slot()

func observe_device(label: String, main: Node) -> void:
	await observe_deep(label, main)
	var screen: Control = main.shell.find_child("DungeonScreen", false, false)
	if screen != null and is_instance_valid(screen.device_dialog):
		var dialog: AcceptDialog = screen.device_dialog
		check(dialog.size.x <= root.size.x and dialog.size.y <= root.size.y, "actual device dialog fits viewport")
		check(dialog.get_ok_button().size.y >= 40, "actual defer/return command meets shared40px requirement")
		for choice: String in dialog.choice_buttons:
			var button: Button = dialog.choice_buttons[choice]
			check(button.size.y >= 40 and Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()), "actual device choice readable/visible/touchable")

func show_device_memory(main: Node) -> void:
	var memory_label: Label
	for node: Node in main.shell.find_children("*", "Label", true, false):
		if node.text.contains(Dungeon.device_note(main.world)): memory_label = node
	check(memory_label != null, "actual companion window projects saved device history")
	if memory_label == null: return
	var ancestor: Node = memory_label.get_parent()
	while ancestor != null and not ancestor is ScrollContainer: ancestor = ancestor.get_parent()
	check(ancestor != null, "actual shared memory has scroll viewport")
	if ancestor == null: return
	var scroll: ScrollContainer = ancestor
	var dialog: AcceptDialog = scroll.get_parent()
	if DisplayServer.get_name() == "headless":
		dialog.size = Vector2i(520, 470) # Existing non-wrapping people popup's requested size.
		await frames()
	scroll.ensure_control_visible(memory_label)
	await frames()
	check(scroll.get_global_rect().encloses(memory_label.get_global_rect()), "actual complete shared history scrolled into view")

func device_ui() -> void:
	for variant: String in ["preserve", "salvage", "missing", "full_items", "full_cargo"]:
		clear_slot()
		var world: WorldState = device_fixture(variant != "missing")
		to_control(world)
		if variant == "full_items": check(world.player.pickup_item("first_aid_kit", 11).success, "actual UI full items fixture")
		if variant == "full_cargo":
			world.player.inventory.water = 19
			world.player.inventory.food = 1
			world.player.inventory.scrap = 0
		check(store.save_game(world).success, "actual UI control save " + variant)
		var main: Node = new_main()
		await frames()
		main.save_dialog.load_button.pressed.emit()
		await frames()
		var screen: Control = main.shell.find_child("DungeonScreen", false, false)
		await guide_deep_command(screen, "DEVICE")
		await observe_device("bench_" + variant, main)
		var before: String = main.world.to_canonical_json()
		var feet: Vector2 = screen.view.actor_position
		screen.interact_button.pressed.emit()
		await frames()
		await observe_device("choice_" + variant, main)
		check(not screen.view.enabled and main.world.to_canonical_json() == before, "actual modal pauses walking and remains read-only")
		check(screen.device_dialog.detail.text.contains("1900g") and screen.device_dialog.detail.text.contains("防護1 → 2"), "actual armor consequence before choice")
		if variant in ["missing", "full_items", "full_cargo"]:
			var chosen: String = "SALVAGE" if variant == "full_cargo" else "PRESERVE"
			check(screen.device_dialog.choice_buttons[chosen].disabled and screen.device_dialog.choice_buttons[chosen].text.contains("需要" if variant == "missing" else "容量"), "actual visible requirement refusal")
			screen.device_dialog.get_ok_button().pressed.emit()
			await frames()
			check(main.world.to_canonical_json() == before and screen.view.actor_position == feet and screen.view.enabled, "actual cancel costs nothing and preserves feet")
		else:
			screen.device_dialog.get_ok_button().pressed.emit()
			await frames()
			check(main.world.to_canonical_json() == before and screen.view.actor_position == feet, "actual optional defer preserves choice")
			screen.interact_button.pressed.emit()
			await frames()
			var chosen: String = "PRESERVE" if variant == "preserve" else "SALVAGE"
			screen.device_dialog.choice_buttons[chosen].pressed.emit()
			await frames()
			check(Dungeon.state(main.world).device_choice == chosen and screen.view.actor_position == feet and screen.view.enabled, "actual choice commits and restores same local feet")
			await observe_device("decided_" + variant, main)
			if variant == "preserve":
				screen.supplies_button.pressed.emit()
				await frames()
				var item_label: Label = await show_owned_pack_item(screen.supplies_dialog, "強化皮甲")
				check(item_label != null and main.world.player.item_inventory.total_weight_g() == 3350 and Gear.protection(main.world.player) == 2, "actual owned armor pack and independent weight/protection consequence")
				await observe_device("reinforced_owned_pack", main)
				screen.supplies_dialog.get_ok_button().pressed.emit()
				await frames()
			check(store.save_game(main.world).success, "actual decided UI save")
			main.queue_free()
			await frames()
			main = new_main()
			await frames()
			main.save_dialog.load_button.pressed.emit()
			await frames()
			screen = main.shell.find_child("DungeonScreen", false, false)
			check(Dungeon.state(main.world).device_choice == chosen, "actual Continue keeps device decision")
			await observe_device("continued_" + variant, main)
			await guide_deep_command(screen, "OPEN_SHORTCUT")
			screen.interact_button.pressed.emit()
			await frames()
			await guide_route(screen, "entrance")
			screen.interact_button.pressed.emit()
			await frames()
			await guide_deep_command(screen, "EXIT")
			screen.interact_button.pressed.emit()
			await frames()
			main.shell.btn_local_train.pressed.emit()
			await frames()
			await show_device_memory(main)
			await observe_device("town_memory_" + variant, main)
			check(Dungeon.device_note(main.world).contains("阿扳"), "actual returned persistent shared memory")
		main.queue_free()
		await frames()
		clear_slot()

func run_device() -> void:
	root.size = Vector2i(1280, 720)
	device_replay()
	device_refusals_and_history()
	armor_combat_consequence()
	undecided_legacy_revisit()
	await device_ui()
	print("DUN-7: %d assertions, %d failures" % [assertions, failures])
	quit(0 if failures == 0 else 1)
