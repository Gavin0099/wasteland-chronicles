extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Screen = preload("res://ui/field_screen.gd")
var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-2B: " + label)

func _init() -> void:
	call_deferred("run")

func fresh() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:new_hope", "character_name": "Arsenal", "age": 30, "background_id": "MECHANIC", "trait_ids": []})).success, "creation")
	world.player.money = 1000
	return world

func start(world: WorldState) -> void:
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success, "real travel")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:new_hope", &"settlement:dry_well", 1, {"target_enemy": "heavy_raider"})
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT")).success, "real heavy raider battle")

func payload(world: WorldState, command: String) -> Dictionary:
	return {"command": command, "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)}

func action(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload(world, command)))

func run() -> void:
	# Fixed values from the reviewed arsenal table, never computed from rules.
	for id in {"sledgehammer": ["T1", 3200, 6, 2], "combat_knife": ["T2", 450, 5, 1], "reinforced_saber": ["T3", 1600, 6, 1]}:
		var values: Array = {"sledgehammer": ["T1", 3200, 6, 2], "combat_knife": ["T2", 450, 5, 1], "reinforced_saber": ["T3", 1600, 6, 1]}[id]
		var definition: Dictionary = Registry.resolve(id).definition
		check(definition.tier == values[0] and definition.base_weight == values[1] and definition.quality == "COMMON", "fixed melee metadata")
		var world := fresh()
		check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success, "real melee purchase")
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), "main_hand")).success, "real melee equip")
		check(Field.attack_damage(world) == values[2] and Field.flee_damage(world) == values[3], "melee damage and retreat cost")
		start(world)
		var twin := WorldState.from_json_checked(world.to_canonical_json())
		check(twin.success, "melee midbattle save")
		var hp: int = world.player.field_kit.hp
		check(action(world, "FLEE").success and world.player.field_kit.hp == hp - int(values[3]), "actual retreat cost")
		check(action(twin.world, "FLEE").success and twin.world.to_canonical_json().sha256_text() == world.to_canonical_json().sha256_text(), "melee dual-track replay")
		check(engine.validate_invariants(world) == "", "melee global invariants")
	# [damage, shots, HP after victory, total ammunition caps].
	for id in ["old_revolver", "police_revolver", "short_shotgun"]:
		var expected: Array = {"old_revolver": [6, 3, 6, 36], "police_revolver": [7, 3, 6, 36], "short_shotgun": [10, 2, 9, 60]}[id]
		var ammo := "shotgun_shell" if id == "short_shotgun" else "revolver_round"
		var world := fresh()
		check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success, "real firearm purchase")
		var before_money: int = world.player.money
		check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(ammo), int(expected[1]))).success, "real ammo purchase")
		check(before_money - world.player.money == int(expected[3]), "authored ammo economy tradeoff")
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), "main_hand")).success, "real firearm equip")
		check(Field.shot_damage(world) == int(expected[0]), "fixed firearm damage")
		start(world)
		var twin := world.duplicate_state()
		for shot in range(int(expected[1])):
			var intent := payload(world, "SHOOT")
			check(engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, intent)).success, "shot committed")
			check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, intent)).success, "second track committed")
			var loaded := WorldState.from_json_checked(twin.to_canonical_json())
			check(loaded.success, "new firearm receipt loads")
			if loaded.success:
				twin = loaded.world
			check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "firearm SHA-256 replay")
			check(engine.validate_invariants(world) == "", "shot global invariants")
			var receipt := {}
			for index in range(world.event_log.size() - 1, -1, -1):
				if world.event_log[index].type == "FIELD_TURN":
					receipt = world.event_log[index].payload
					break
			check(receipt.get("weapon_id") == id and receipt.get("ammo_item_id") == ammo and receipt.get("ammo_spent") == 1, "receipt names actual gun/ammo")
			var stale_before := world.to_canonical_json()
			check(not engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, intent)).success and world.to_canonical_json() == stale_before, "stale shot atomic")
		check(world.player.field_kit.hp == int(expected[2]) and world.field_state.receipt >= 0, "heavy raider victory at reviewed HP")
		check(world.player.item_inventory.quantity(ammo) == 0, "exact ammunition spent")
		var wire: Dictionary = JSON.parse_string(world.to_canonical_json())
		for event in wire.events:
			if event.type == "FIELD_TURN" and event.payload.command == "SHOOT":
				event.payload.ammo_item_id = "revolver_round" if ammo == "shotgun_shell" else "shotgun_shell"
				break
		check(WorldState.from_dict_checked(wire).error == "INVALID_FIREARM_RECEIPT", "cross-ammunition receipt rejected")
	var empty := fresh()
	check(empty.player.item_inventory.pickup_item("short_shotgun", 1).success, "empty gun owned")
	check(empty.player.item_inventory.pickup_item("revolver_round", 4).success, "wrong ammo owned")
	check(engine.commit_player_intent(empty, PlayerIntent.create_equip_item(empty.player.npc_id, &"short_shotgun", "main_hand")).success, "empty gun equipped")
	start(empty)
	var before := empty.to_canonical_json()
	var refusal := action(empty, "SHOOT")
	check(not refusal.success and refusal.error == "NEED_AMMUNITION" and empty.to_canonical_json() == before, "wrong ammo changes no HP/practice/day/stock")
	var ui := Screen.new()
	root.add_child(ui)
	ui.setup(empty, engine)
	await process_frame
	check(ui.buttons.SHOOT.disabled and ui.buttons.SHOOT.text.contains("霰彈槍彈藥不足"), "truthful shell refusal")
	check(ui.stage.weapon.visible and ui.stage.current_weapon_id == "short_shotgun", "actual shotgun art")
	# Independently measured source-art points: trigger grip at (0.70, 0.56),
	# muzzle at (0.06, 0.16). The held grip coincides with the fighter's fist;
	# the mirrored muzzle must point toward the enemy on the right.
	var held: Sprite2D = ui.stage.weapon
	var dimensions := Vector2(held.texture.get_width(), held.texture.get_height())
	var grip_world := held.to_global(held.offset + dimensions * Vector2(0.30, 0.56))
	var muzzle_world := held.to_global(held.offset + dimensions * Vector2(0.94, 0.16))
	check(grip_world.distance_to(held.global_position) < 0.01 and muzzle_world.x > grip_world.x, "shotgun held by trigger with muzzle toward opponent")
	ui.stage.configure("heavy_raider", "police_revolver", true)
	dimensions = Vector2(held.texture.get_width(), held.texture.get_height())
	grip_world = held.to_global(held.offset + dimensions * Vector2(0.14, 0.73))
	muzzle_world = held.to_global(held.offset + dimensions * Vector2(0.95, 0.24))
	check(grip_world.distance_to(held.global_position) < 0.01 and muzzle_world.x > grip_world.x, "police revolver held by handle with muzzle toward opponent")
	ui.queue_free()
	await process_frame
	# A saved shop predating the six additions keeps existing stock on load;
	# the ordinary authored restock mechanism makes new supplies available.
	var old := fresh()
	var stock: Dictionary = ItemMarketState.seeded_for("new_hope").to_dict()
	stock.items = stock.items.filter(func(row: Dictionary) -> bool: return row.item_id not in ["sledgehammer", "combat_knife", "reinforced_saber", "police_revolver", "short_shotgun", "shotgun_shell"])
	old.get_settlement(&"settlement:new_hope").item_market = ItemMarketState.from_dict_checked(stock).market
	old.get_settlement(&"settlement:new_hope").item_market.set_quantity("wrench", 42)
	var old_wire := old.to_canonical_json()
	var resumed := WorldState.from_json_checked(old_wire)
	check(resumed.success and resumed.world.to_canonical_json() == old_wire, "old shop loads byte-identically")
	for day in range(4):
		engine.tick(old)
		engine.tick(resumed.world)
		check(old.to_canonical_json().sha256_text() == resumed.world.to_canonical_json().sha256_text(), "legacy shop replay")
	check(old.get_settlement(&"settlement:new_hope").item_market.quantity("short_shotgun") == 1 and old.get_settlement(&"settlement:new_hope").item_market.quantity("shotgun_shell") == 4, "legacy shop gets actual new stock through restock")
	check(old.get_settlement(&"settlement:new_hope").item_market.quantity("wrench") >= 42, "legacy stock never reset")
	print("GEAR-2B: %s assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
