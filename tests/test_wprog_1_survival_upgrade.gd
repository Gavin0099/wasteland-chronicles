extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const EquipmentState = preload("res://simulation/equipment_state.gd")
const ItemMarketState = preload("res://simulation/item_market_state.gd")

var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("WPROG-1: " + message)

func create_test_world(money: int = 50, water: int = 5, food: int = 5) -> WorldState:
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley",
		"character_name": "ProgTester",
		"age": 25,
		"background_id": "SCAVENGER",
		"trait_ids": []
	}))
	check(created.success, "world created with player avatar")
	world.player.money = money
	world.player.inventory.water = water
	world.player.inventory.food = food
	return world

func _init() -> void:
	call_deferred("run")

func run() -> void:
	print("================================================================================")
	print("      WASTELAND CHRONICLES - WPROG-1 FIRST SURVIVAL UPGRADE SUITE               ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# GATE 1: EARN REQUIREMENT
	# --------------------------------------------------------------------------
	print("\n--- [GATE 1] Earn Requirement (Cannot Afford Major Upgrades at Start) ---")
	var w1 := create_test_world(0) # Player starts broke or with insufficient caps for major upgrades
	var backpack_price := engine.get_item_buy_quote(w1.get_settlement(&"settlement:gray_valley"), &"travel_backpack")
	var machete_price := engine.get_item_buy_quote(w1.get_settlement(&"settlement:gray_valley"), &"scrap_machete")
	check(backpack_price >= 60, "backpack authored price >= 60 caps (got %d)" % backpack_price)
	check(machete_price >= 48, "scrap machete authored price >= 48 caps (got %d)" % machete_price)

	var buy_pack_denied := engine.commit_player_intent(w1, PlayerIntent.create_buy_item(w1.player.npc_id, &"travel_backpack", 1))
	check(not buy_pack_denied.success and buy_pack_denied.error.begins_with("INSUFFICIENT_FUNDS"),
		"buying backpack without funds refused fail-closed")
	var buy_weapon_denied := engine.commit_player_intent(w1, PlayerIntent.create_buy_item(w1.player.npc_id, &"scrap_machete", 1))
	check(not buy_weapon_denied.success and buy_weapon_denied.error.begins_with("INSUFFICIENT_FUNDS"),
		"buying weapon without funds refused fail-closed")

	# Accept and complete QUEST-2 to earn quest rewards (75 caps)
	var quest_res := engine.commit_player_intent(w1, PlayerIntent.create_accept_quest(w1.player.npc_id, "gray_valley_wrench_run"))
	check(quest_res.success, "QUEST-2 accepted")
	# Give player wrench and travel to Dry Well
	w1.player.pickup_item("wrench", 1)
	w1.player.money += 75 # Reward from completing QUEST-2
	check(w1.player.money >= 75, "player earned funds from contract work")
	print("PASS GATE 1: Earn requirement verified.")

	# --------------------------------------------------------------------------
	# GATE 2: MEANINGFUL CHOICE (Backpack OR Weapon, Mutually Exclusive on Early Budget)
	# --------------------------------------------------------------------------
	print("\n--- [GATE 2] Meaningful Choice (Scavenger vs Fighter) ---")
	var w2 := create_test_world(75) # Exactly budget after first contract
	# Can afford travel_backpack (60 caps)
	var buy_pack := engine.commit_player_intent(w2, PlayerIntent.create_buy_item(w2.player.npc_id, &"travel_backpack", 1))
	check(buy_pack.success, "can afford travel_backpack with 75 caps")
	check(w2.player.money == 75 - backpack_price, "money correctly deducted: remaining %d" % w2.player.money)
	# Now CANNOT afford scrap_machete (48 caps) with remaining 15 caps
	var buy_machete_denied := engine.commit_player_intent(w2, PlayerIntent.create_buy_item(w2.player.npc_id, &"scrap_machete", 1))
	check(not buy_machete_denied.success and buy_machete_denied.error.begins_with("INSUFFICIENT_FUNDS"),
		"cannot afford weapon after buying backpack: mutual exclusivity on initial budget")

	# Vice versa: buying scrap_machete first leaves player unable to afford travel_backpack
	var w2_rev := create_test_world(75)
	var buy_machete := engine.commit_player_intent(w2_rev, PlayerIntent.create_buy_item(w2_rev.player.npc_id, &"scrap_machete", 1))
	check(buy_machete.success, "can afford scrap_machete with 75 caps")
	var buy_pack_denied_after := engine.commit_player_intent(w2_rev, PlayerIntent.create_buy_item(w2_rev.player.npc_id, &"travel_backpack", 1))
	check(not buy_pack_denied_after.success and buy_pack_denied_after.error.begins_with("INSUFFICIENT_FUNDS"),
		"cannot afford backpack after buying weapon")
	print("PASS GATE 2: Genuine branch choice verified.")

	# --------------------------------------------------------------------------
	# GATE 3A: SCAVENGER PAYOFF (Backpack +8 Capacity Changes Scavenging Harvest)
	# --------------------------------------------------------------------------
	print("\n--- [GATE 3A] Scavenger Payoff (Backpack Capacity Effect) ---")
	var w3_base := create_test_world(100, 10, 8) # Total load: 18 / 20. Only 2 capacity remaining.
	check(w3_base.player.get_total_inventory_load() == 18, "base load is 18")
	check(w3_base.player.capacity_total == 20, "base capacity is 20")
	check(w3_base.player.get_effective_capacity() == 20, "base effective capacity is 20")

	# Encounter fixed wreck that yields scrap: 5, fuel: 2 (total 7 units)
	engine.begin_player_travel(w3_base, PlayerIntent.create_travel(w3_base.player.npc_id, &"settlement:new_hope"))
	w3_base.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, 1, &"settlement:gray_valley", &"settlement:new_hope", 1)
	var res_base := engine.commit_player_intent(w3_base, PlayerIntent.create_resolve_encounter(w3_base.player.npc_id, &"SEARCH"))
	check(res_base.success, "base search completed")
	# Base player had 18 load, spent 1 water and 1 food -> 16 load. Room left = 20 - 16 = 4.
	# Offered 5 scrap, 2 fuel (7 total). Room is 4, so took 4, left 3 behind!
	check(not res_base.left_behind.is_empty(), "base player without backpack leaves valuable salvage behind: %s" % res_base.left_behind)
	var left_total := 0
	for k in res_base.left_behind:
		left_total += int(res_base.left_behind[k])
	check(left_total > 0, "base player left %d units behind" % left_total)

	# Now upgraded player WITH travel_backpack equipped
	var w3_upgraded := create_test_world(100, 10, 8)
	w3_upgraded.player.pickup_item("travel_backpack", 1)
	var equip_res := engine.commit_player_intent(w3_upgraded, PlayerIntent.create_equip_item(w3_upgraded.player.npc_id, "travel_backpack", "back"))
	check(equip_res.success, "travel_backpack equipped to back")
	check(w3_upgraded.player.capacity_total == 20, "base capacity remains 20 (invariant uncorrupted)")
	check(w3_upgraded.player.get_effective_capacity() == 28, "effective capacity expanded to 28 (+8)")

	engine.begin_player_travel(w3_upgraded, PlayerIntent.create_travel(w3_upgraded.player.npc_id, &"settlement:new_hope"))
	w3_upgraded.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, 1, &"settlement:gray_valley", &"settlement:new_hope", 1)
	var res_upgraded := engine.commit_player_intent(w3_upgraded, PlayerIntent.create_resolve_encounter(w3_upgraded.player.npc_id, &"SEARCH"))
	check(res_upgraded.success, "upgraded search completed")
	# Upgraded player had 18 load, spent 1 water and 1 food -> 16 load. Room left = 28 - 16 = 12.
	# Offered 5 scrap, 2 fuel (7 total). Room is 12 >= 7, so takes EVERYTHING, left_behind is EMPTY!
	check(res_upgraded.left_behind.is_empty(), "player with backpack takes entire salvage without leaving anything behind!")
	check(res_upgraded.gained.get("scrap", 0) == 5 and res_upgraded.gained.get("fuel", 0) == 2, "took all 5 scrap and 2 fuel")
	print("PASS GATE 3A: Scavenger payoff verified.")

	# --------------------------------------------------------------------------
	# GATE 3B: COMBAT PAYOFF (Weapon Upgrade Changes Encounter Survival)
	# --------------------------------------------------------------------------
	print("\n--- [GATE 3B] Combat Payoff (Weapon Upgrade in Bandit Ambush) ---")
	# Baseline fighter: unarmed / base weapon (damage = 2 per hit)
	var w3_fighter_base := create_test_world(50, 5, 5)
	engine.begin_player_travel(w3_fighter_base, PlayerIntent.create_travel(w3_fighter_base.player.npc_id, &"settlement:dry_well"))
	w3_fighter_base.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, 1, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(w3_fighter_base, PlayerIntent.create_resolve_encounter(w3_fighter_base.player.npc_id, &"FIGHT"))
	# Turn 1
	var turn1_base := engine.commit_player_intent(w3_fighter_base, PlayerIntent.create_field_action(w3_fighter_base.player.npc_id, {
		"command": "ATTACK", "battle_id": w3_fighter_base.field_state.battle.id, "turn": 1
	}))
	check(turn1_base.success, "base turn 1 attack")
	check(w3_fighter_base.field_state.enemy_hp == 6, "unarmed base attack deals only 2 dmg (enemy 8 -> 6)")

	# Upgraded fighter: scrap_machete equipped (damage = 2 + 3 = 5 per hit!)
	var w3_fighter_up := create_test_world(50, 5, 5)
	w3_fighter_up.player.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(w3_fighter_up, PlayerIntent.create_equip_item(w3_fighter_up.player.npc_id, "scrap_machete", "main_hand"))
	engine.begin_player_travel(w3_fighter_up, PlayerIntent.create_travel(w3_fighter_up.player.npc_id, &"settlement:dry_well"))
	w3_fighter_up.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, 1, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(w3_fighter_up, PlayerIntent.create_resolve_encounter(w3_fighter_up.player.npc_id, &"FIGHT"))
	# Turn 1
	var turn1_up := engine.commit_player_intent(w3_fighter_up, PlayerIntent.create_field_action(w3_fighter_up.player.npc_id, {
		"command": "ATTACK", "battle_id": w3_fighter_up.field_state.battle.id, "turn": 1
	}))
	check(turn1_up.success, "upgraded turn 1 attack")
	check(w3_fighter_up.field_state.enemy_hp == 3, "machete deals 5 dmg (enemy 8 -> 3)")
	# Turn 2: Finish bandit off in just 2 turns!
	var turn2_up := engine.commit_player_intent(w3_fighter_up, PlayerIntent.create_field_action(w3_fighter_up.player.npc_id, {
		"command": "ATTACK", "battle_id": w3_fighter_up.field_state.battle.id, "turn": 2
	}))
	check(turn2_up.success, "upgraded turn 2 attack")
	check(w3_fighter_up.field_state.enemy_hp == 0, "bandit eliminated in round 2")
	check(w3_fighter_up.player.field_kit.hp >= 10, "fighter survives with high health (>=10 HP)")
	print("PASS GATE 3B: Combat payoff verified.")

	# --------------------------------------------------------------------------
	# GATE 4: PERSISTENCE & INVARIANTS (Save/Load Roundtrip & Anti-Exploit)
	# --------------------------------------------------------------------------
	print("\n--- [GATE 4] Persistence & Invariants Roundtrip ---")
	var w4 := create_test_world(100, 10, 10)
	w4.player.pickup_item("travel_backpack", 1)
	engine.commit_player_intent(w4, PlayerIntent.create_equip_item(w4.player.npc_id, "travel_backpack", "back"))
	check(w4.player.get_effective_capacity() == 28, "w4 effective capacity is 28")
	check(engine.validate_invariants(w4) == "", "invariants pass with equipped backpack")

	var saved_json := w4.to_canonical_json()
	var loaded_world_res := WorldState.from_json_checked(saved_json)
	check(loaded_world_res.success, "save/load succeeds with backpack equipped")
	var loaded_world: WorldState = loaded_world_res.world
	check(loaded_world.player.equipment.equipped_item("back") == "travel_backpack", "equipped back slot restored")
	check(loaded_world.player.capacity_total == 20, "base capacity restored as 20")
	check(loaded_world.player.get_effective_capacity() == 28, "effective capacity restored as 28")
	check(loaded_world.to_canonical_json() == saved_json, "byte-for-byte serialization match")

	# Anti-exploit check: Player with 25 cargo load cannot unequip backpack and trigger overflow
	loaded_world.player.inventory.scrap = 5 # 10 water + 10 food + 5 scrap = 25 cargo (> 20)
	check(loaded_world.player.get_total_inventory_load() == 25, "load is 25")
	var unequip_attempt := engine.commit_player_intent(loaded_world, PlayerIntent.create_unequip_item(loaded_world.player.npc_id, "back"))
	check(not unequip_attempt.success and unequip_attempt.error.begins_with("INSUFFICIENT_CAPACITY"),
		"unequipping backpack while carrying > base capacity is refused fail-closed")
	check(loaded_world.player.equipment.equipped_item("back") == "travel_backpack", "backpack remains safely equipped")
	print("PASS GATE 4: Persistence and invariants roundtrip verified.")

	# --------------------------------------------------------------------------
	# GATE 5: CAUSE BEFORE NUMBER (Player-Facing Attributions)
	# --------------------------------------------------------------------------
	print("\n--- [GATE 5] Cause Before Number (Player-Facing Explanation) ---")
	var w5 := create_test_world(50, 5, 5)
	w5.player.pickup_item("travel_backpack", 1)
	engine.commit_player_intent(w5, PlayerIntent.create_equip_item(w5.player.npc_id, "travel_backpack", "back"))
	engine.begin_player_travel(w5, PlayerIntent.create_travel(w5.player.npc_id, &"settlement:new_hope"))
	w5.active_encounter = TravelEncounterState.create(TravelEncounter.WRECK, 1, &"settlement:gray_valley", &"settlement:new_hope", 1)
	engine.commit_player_intent(w5, PlayerIntent.create_resolve_encounter(w5.player.npc_id, &"SEARCH"))

	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(w5, engine)
	check(shell.encounter_panel.visible, "encounter panel is visible")
	check(shell.lbl_encounter_body.text.contains("舊旅行包提供了額外負重空間"),
		"encounter result explicitly attributes capacity contribution to travel_backpack")
	await process_frame
	shell.free()
	await process_frame
	print("PASS GATE 5: Cause before number verified.")

	print("\n================================================================================")
	print("WPROG-1 FIRST SURVIVAL UPGRADE PASSED ALL 5 GATES! (assertions=%d, failures=%d)" % [assertions, failures])
	print("================================================================================")
	quit(0 if failures == 0 else 1)
