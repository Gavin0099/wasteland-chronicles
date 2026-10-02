extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Screen = preload("res://ui/field_screen.gd")
var engine: SimulationEngine = SimulationEngine.new()
var failures: int = 0
var assertions: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GUN-1: " + label)

func fixture() -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:new_hope", "character_name": "Gunner", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "character creation")
	world.player.money = 500
	return world

func arm(world: WorldState, rounds: int = 3) -> void:
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"old_revolver", 1)).success, "buy actual gun in New Hope")
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"revolver_round", rounds)).success, "buy actual rounds")
	check(world.player.money == 500 - 160 - rounds * 12, "authored purchase cost")
	check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"old_revolver", "main_hand")).success, "equip owned gun")

func battle(world: WorldState, enemy_id: String) -> void:
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success, "begin real transit")
	world.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:new_hope", &"settlement:dry_well", 1, {"target_enemy": enemy_id})
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT")).success, "encounter handoff")
	check(Field.battle_enemy(world.field_state) == enemy_id, "actual battle enemy")

func turn(world: WorldState, command: String) -> Dictionary:
	return {"command": command, "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)}

func act(world: WorldState, payload: Dictionary) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))

func sha(world: WorldState) -> String:
	return world.to_canonical_json().sha256_text()

func track(resume: bool, enemy_id: String, shots: int, hp: int) -> String:
	var world: WorldState = fixture()
	arm(world)
	battle(world, enemy_id)
	for index: int in range(shots):
		var shot: Dictionary = turn(world, "SHOOT")
		var result: Dictionary = act(world, shot)
		check(result.success, "shot commits")
		check(world.player.item_inventory.quantity("revolver_round") == 2 - index, "one bullet per committed shot")
		var before: String = sha(world)
		check(not act(world, shot).success and sha(world) == before, "stale shot refuses atomically")
		if resume:
			var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
			check(loaded.success, "mid-fight or result checked load")
			if loaded.success:
				check(sha(loaded.world) == before, "shot save fixed point")
				world = loaded.world
		check(engine.validate_invariants(world) == "", "shot global invariants")
	check(world.field_state.battle.is_empty() and world.field_state.receipt >= 0, "victory reached")
	check(world.player.field_kit.hp == hp, "reviewed enemy pattern HP outcome")
	check(world.player.capability.get_practice_progress("FIREARMS").points == 1, "one daily firearm practice regardless of shots")
	check(world.player.capability.get_practice_progress("MELEE").points == 0, "shooting does not practice melee")
	return sha(world)

func run() -> void:
	var legacy: WorldState = fixture()
	var market: Dictionary = ItemMarketState.seeded_for("new_hope").to_dict()
	market.items = market.items.filter(func(row: Dictionary) -> bool: return row.item_id not in ["old_revolver", "revolver_round"])
	legacy.get_settlement(&"settlement:new_hope").item_market = ItemMarketState.from_dict_checked(market).market
	legacy.get_settlement(&"settlement:new_hope").item_market.set_quantity("wrench", 42)
	var legacy_wire: String = legacy.to_canonical_json()
	var restored: Dictionary = WorldState.from_json_checked(legacy_wire)
	check(restored.success and restored.world.to_canonical_json() == legacy_wire, "pre-gun shop loads unchanged")
	var resumed: WorldState = restored.world
	for day: int in range(4):
		engine.tick(legacy)
		engine.tick(resumed)
		resumed = WorldState.from_json_checked(resumed.to_canonical_json()).world
		check(sha(legacy) == sha(resumed) and engine.validate_invariants(resumed) == "", "legacy restock dual-track SHA and invariants")
	var shop = resumed.get_settlement(&"settlement:new_hope").item_market
	check(shop.quantity("old_revolver") == 1 and shop.quantity("revolver_round") == 4, "missing firearm entries replenish on authored daily/four-day schedules")
	check(shop.quantity("wrench") >= 42, "legacy existing quantities not reset")
	check(engine.commit_player_intent(resumed, PlayerIntent.create_buy_item(resumed.player.npc_id, &"old_revolver", 1)).success, "old save can buy new gun")
	check(engine.commit_player_intent(resumed, PlayerIntent.create_buy_item(resumed.player.npc_id, &"revolver_round", 1)).success, "old save can buy new ammunition")
	var prepared: WorldState = fixture()
	arm(prepared)
	prepared.player.capability.raise_rank_by_point("FIREARMS")
	battle(prepared, "heavy_raider")
	check(act(prepared, turn(prepared, "DEFEND")).success, "prepare a shot")
	check(act(prepared, turn(prepared, "SHOOT")).success and prepared.field_state.enemy_hp == 7, "rank-one prepared shot deals nine")
	check(not prepared.field_state.battle.prepared and Field.shot_damage(prepared) == 7, "shot consumes preparation once")
	# Fixed combat expectations: 6 damage at rank zero, enemy HP 6/8/16,
	# dog dies before striking; bandit returns 2; raider returns 3 twice.
	for entry: Array in [["feral_dog", 1, 12], ["bandit", 2, 10], ["heavy_raider", 3, 6]]:
		check(track(false, entry[0], entry[1], entry[2]) == track(true, entry[0], entry[1], entry[2]), "dual-track SHA-256 " + entry[0])
	var unarmed: WorldState = fixture()
	battle(unarmed, "bandit")
	var before: String = sha(unarmed)
	var refused: Dictionary = act(unarmed, turn(unarmed, "SHOOT"))
	check(not refused.success and refused.error == "NEED_EQUIPPED_FIREARM" and sha(unarmed) == before, "skill without gun does not authorize shooting")
	var world: WorldState = fixture()
	arm(world, 1)
	battle(world, "heavy_raider")
	var screen: Control = Screen.new()
	root.add_child(screen)
	screen.setup(world, engine)
	await process_frame
	check(screen.buttons.has("SHOOT") and not screen.buttons.SHOOT.disabled and screen.buttons.SHOOT.text.contains("彈藥 −1"), "UI exposes real shot and bullet cost")
	screen.queue_free()
	await process_frame
	check(act(world, turn(world, "SHOOT")).success, "last bullet fires")
	before = sha(world)
	refused = act(world, turn(world, "SHOOT"))
	check(not refused.success and refused.error == "NEED_AMMUNITION" and sha(world) == before, "empty gun changes neither HP, time nor practice")
	check(act(world, turn(world, "ATTACK")).success, "melee remains an available fallback")
	var raw: Dictionary = JSON.parse_string(world.to_canonical_json())
	for event: Dictionary in raw.events:
		if event.type == "FIELD_TURN" and event.payload.command == "SHOOT":
			event.payload.ammo_spent = 2
	check(not WorldState.from_json_checked(JSON.stringify(raw)).success, "forged bullet receipt rejected")
	check(GrowthPoints.is_spendable("FIREARMS"), "existing earned growth points support usable firearm skill")
	print("GUN-1: assertions=%d failures=%d" % [assertions, failures])
	quit(1 if failures else 0)
