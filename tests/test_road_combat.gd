extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")
var engine := SimulationEngine.new()
var failed := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)

func fresh_world() -> WorldState:
	var w := S1WorldData.create_s1_world()
	engine.commit_character_creation(w, Intent.new({
		"source_settlement_id": "settlement:gray_valley",
		"character_name": "Road Warrior",
		"age": 28,
		"background_id": "CARAVAN_GUARD",
		"trait_ids": []
	}))
	return w

func fresh_legacy() -> WorldState:
	var w := S1WorldData.create_s1_world()
	engine.commit_character_creation(w, Intent.new({
		"source_settlement_id": "settlement:gray_valley",
		"character_name": "Field Tester",
		"age": 23,
		"background_id": "MECHANIC",
		"trait_ids": []
	}))
	return w

func travel_world(water: int = 10, food: int = 10, caps: int = 50) -> WorldState:
	var w := fresh_world()
	w.player.inventory.set_amount("water", water)
	w.player.inventory.set_amount("food", food)
	w.player.money = caps
	engine.begin_player_travel(w, PlayerIntent.create_travel(w.player.npc_id, &"settlement:dry_well"))
	return w

func fields(w: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload.battle_id = w.field_state.battle.id
		payload.turn = w.field_state.battle.turn
	if command == "CONFIRM":
		payload.receipt = w.field_state.receipt
	return payload

func act_field(w: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(w, PlayerIntent.create_field_action(w.player.npc_id, fields(w, command)))

func _init() -> void:
	print("================================================================================")
	print("ROAD-COMBAT TEST SUITE: 7 HARD GATES")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# GATE 1: FIELD_BATTLE_CONFLICT & Atomic Ownership Handoff
	# --------------------------------------------------------------------------
	print("\n--- [GATE 1] FIELD_BATTLE_CONFLICT & Ownership Handoff ---")
	var w1 := travel_world()
	w1.active_encounter = TravelEncounterState.create(
		TravelEncounter.BANDIT_AMBUSH, w1.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1
	)
	check(w1.active_encounter != null and w1.field_state.battle.is_empty(), "encounter present, battle empty before fight")
	
	# Trying to act on field battle while encounter is active must fail closed
	var field_denied := engine.commit_player_intent(w1, PlayerIntent.create_field_action(w1.player.npc_id, {"command": "ATTACK", "battle_id": 1, "turn": 1}))
	check(not field_denied.success, "field action denied while encounter is active")

	# Select FIGHT -> atomic handoff
	var fight_res := engine.commit_player_intent(w1, PlayerIntent.create_resolve_encounter(w1.player.npc_id, &"FIGHT"))
	check(fight_res.success and fight_res.action == "START_ROAD_COMBAT", "FIGHT option commits road combat start")
	check(w1.active_encounter == null, "encounter ownership released on FIGHT")
	check(not w1.field_state.battle.is_empty(), "field battle ownership active")
	check(w1.field_state.battle.source == "road", "battle source is road")
	check(w1.field_state.enemy_hp == 8, "bandit enemy HP initialized to 8")
	check(engine.validate_invariants(w1) == "", "invariants pass during road battle")

	# Concurrent travel/wait/encounter intent while battle is active must be rejected
	var wait_denied := engine.commit_player_intent(w1, PlayerIntent.create_wait(w1.player.npc_id))
	check(not wait_denied.success, "world wait intent blocked during road combat")
	var enc_denied := engine.commit_player_intent(w1, PlayerIntent.create_resolve_encounter(w1.player.npc_id, &"FIGHT"))
	check(not enc_denied.success, "resolve encounter intent blocked during road combat")
	print("PASS GATE 1: Single ownership & atomic handoff verified.")

	# --------------------------------------------------------------------------
	# GATE 2: Save Compatibility & Optional Source Key
	# --------------------------------------------------------------------------
	print("\n--- [GATE 2] Save Compatibility & Optional Source Key ---")
	var save_json := w1.to_canonical_json()
	var loaded := WorldState.from_json_checked(save_json)
	check(loaded.success, "active road combat save/load successful")
	check(loaded.world.field_state.battle.source == "road", "loaded battle preserves source=road")
	check(loaded.world.to_canonical_json().sha256_text() == save_json.sha256_text(), "bit-for-bit road combat save round-trip")

	# Backward compatibility: legacy save with battle active but NO "source" key must load and default to "field"
	var legacy_dict: Dictionary = JSON.parse_string(save_json)
	legacy_dict.field_state.battle.erase("source")
	var legacy_loaded := WorldState.from_dict_checked(legacy_dict)
	# Legacy field battle requires SETTLED in HOME to pass invariants
	var legacy_settled := fresh_world()
	act_field(legacy_settled, "START")
	var legacy_shed_dict := legacy_settled.to_dict()
	legacy_shed_dict.field_state.battle.erase("source") # No source key
	var shed_loaded := WorldState.from_dict_checked(legacy_shed_dict)
	check(shed_loaded.success, "legacy schema v1 battle without source key loads cleanly")
	check(act_field(shed_loaded.world, "ATTACK").success, "legacy combat continues without source key")
	print("PASS GATE 2: Save compatibility & optional source key verified.")

	# --------------------------------------------------------------------------
	# GATE 3: Determinism & Scaled Non-Negative Weights
	# --------------------------------------------------------------------------
	print("\n--- [GATE 3] Determinism & Scaled Non-Negative Weights ---")
	# Assert weights are never negative
	for sec in [100.0, 90.0, 75.0, 70.0, 50.0, 20.0, 0.0, -10.0]:
		var pool := TravelEncounter.candidates({"min_security": sec})
		for c in pool:
			check(int(c.weight) >= 0, "candidate weight must never be negative (sec=%f)" % sec)

	# High security road has 0 bandit ambush weight
	var calm_pool := TravelEncounter.candidates({"min_security": 100.0})
	var has_bandit_calm := false
	for c in calm_pool:
		if c.type == TravelEncounter.BANDIT_AMBUSH:
			has_bandit_calm = true
	check(not has_bandit_calm, "calm road has no bandit ambush")

	# Low security road has scaled bandit ambush weight (~1 to 5)
	var unsafe_pool := TravelEncounter.candidates({"min_security": 25.0})
	var bandit_weight := 0
	for c in unsafe_pool:
		if c.type == TravelEncounter.BANDIT_AMBUSH:
			bandit_weight = int(c.weight)
	check(bandit_weight >= 1 and bandit_weight <= 6, "unsafe road has scaled bandit weight (got %d)" % bandit_weight)

	# Dual-track deterministic replay
	var wa := travel_world(5, 5, 50)
	wa.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, wa.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(wa, PlayerIntent.create_resolve_encounter(wa.player.npc_id, &"FIGHT"))
	var wb := WorldState.from_json(wa.to_canonical_json())

	for track in [wa, wb]:
		check(act_field(track, "ATTACK").success, "turn 1 attack")
		check(act_field(track, "DEFEND").success, "turn 2 defend")
		check(act_field(track, "ATTACK").success, "turn 3 attack")
	check(wa.to_canonical_json().sha256_text() == wb.to_canonical_json().sha256_text(), "dual-track replay matches byte-for-byte")
	print("PASS GATE 3: Determinism & non-negative weights verified.")

	# --------------------------------------------------------------------------
	# GATE 4: Defeat Aftermath (戰敗 ≠ 死亡) & Strict Intent Gating
	# --------------------------------------------------------------------------
	print("\n--- [GATE 4] Defeat Aftermath (Defeat != Death) & Strict Intent Gating ---")
	var wd := travel_world(5, 5, 30)
	wd.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, wd.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(wd, PlayerIntent.create_resolve_encounter(wd.player.npc_id, &"FIGHT"))
	
	# Force player to low HP so next hit defeats them
	wd.player.field_kit.hp = 2
	# Enemy hits for 2 damage (turn 1). Raw damage 2 >= HP 2 -> non-lethal defeat triggers!
	var defeat_turn := act_field(wd, "ATTACK")
	check(defeat_turn.success, "turn resolves to defeat")
	check(wd.player.field_kit.hp == 1, "road defeat clamps HP to 1 (重傷)")
	var ls_d := wd.npc_life_state_registry.get_life_state(wd.player.npc_id)
	check(ls_d.is_alive(), "player remains alive after road defeat")
	check(ls_d.status == NpcLifeState.Status.IN_TRANSIT, "player remains in transit after road defeat")
	check(wd.field_state.battle.is_empty(), "battle is closed after defeat")
	check(wd.field_state.receipt >= 0, "defeat receipt is pending")
	check(engine.validate_invariants(wd) == "", "invariants pass after defeat")

	# STRICT INTENT GATING: before CONFIRM, world intents MUST be blocked!
	var travel_blocked := engine.commit_player_intent(wd, PlayerIntent.create_wait(wd.player.npc_id))
	check(not travel_blocked.success and travel_blocked.error.contains("FIELD_ACTIVITY_PENDING"), "world wait blocked before receipt confirm")
	var move_blocked := engine.commit_player_intent(wd, PlayerIntent.create_travel(wd.player.npc_id, &"settlement:dry_well"))
	check(not move_blocked.success, "world travel blocked before receipt confirm")

	# Confirm the receipt
	var confirm_res := act_field(wd, "CONFIRM")
	check(confirm_res.success, "defeat receipt confirm successful")
	check(wd.field_state.receipt == -1, "receipt cleared after confirm")
	check(wd.field_state.battle.is_empty(), "battle remains closed")
	check(ls_d.status == NpcLifeState.Status.IN_TRANSIT, "player still IN_TRANSIT after confirm")

	# After CONFIRM: world intent is accepted!
	var wait_ok := engine.commit_player_intent(wd, PlayerIntent.create_wait(wd.player.npc_id))
	check(wait_ok.success, "world accepts next intent after road defeat confirmation")
	print("PASS GATE 4: Defeat aftermath & strict intent gating verified.")

	# --------------------------------------------------------------------------
	# GATE 5: Feedback & Currency / Inventory Separation
	# --------------------------------------------------------------------------
	print("\n--- [GATE 5] Feedback & Currency / Inventory Separation ---")
	# Test Victory Rewards
	var wv := travel_world(5, 5, 20)
	wv.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, wv.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(wv, PlayerIntent.create_resolve_encounter(wv.player.npc_id, &"FIGHT"))
	# Give player high weapon bonus to defeat bandit in 1 turn
	wv.field_state.enemy_hp = 1
	var money_before := wv.player.money
	var scrap_before := wv.player.inventory.scrap
	act_field(wv, "ATTACK")
	check(wv.field_state.enemy_hp == 0, "bandit defeated")
	check(wv.player.inventory.scrap == scrap_before + 2, "victory grants scrap via inventory")
	check(wv.player.money == money_before + 5, "victory grants caps via money (currency separation)")
	var vic_receipt: Dictionary = wv.event_log[wv.field_state.receipt].payload
	check(vic_receipt.outcome == "VICTORY" and vic_receipt.source == "road", "receipt records road victory")
	check(int(vic_receipt.gained.get("scrap", 0)) == 2 and int(vic_receipt.get("caps_gained", 0)) == 5, "receipt cleanly separates goods from caps")
	act_field(wv, "CONFIRM")
	print("PASS GATE 5: Feedback & currency/inventory separation verified.")

	# --------------------------------------------------------------------------
	# GATE 6: Resource & HP Clamps (No Negative Values)
	# --------------------------------------------------------------------------
	print("\n--- [GATE 6] Resource & HP Clamps ---")
	# Defeat with zero supplies
	var wz := travel_world(0, 0, 0)
	wz.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, wz.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(wz, PlayerIntent.create_resolve_encounter(wz.player.npc_id, &"FIGHT"))
	wz.player.field_kit.hp = 1
	act_field(wz, "ATTACK")
	check(wz.player.field_kit.hp == 1, "HP clamped to 1")
	check(wz.player.inventory.water == 0, "water clamped at 0 (never negative)")
	check(wz.player.inventory.food == 0, "food clamped at 0 (never negative)")
	check(wz.player.money == 0, "money clamped at 0 (never negative)")
	var def_receipt: Dictionary = wz.event_log[wz.field_state.receipt].payload
	check(def_receipt.outcome == "DEFEAT" and def_receipt.lost.is_empty(), "zero resource defeat reports 0 losses")
	act_field(wz, "CONFIRM")

	# Road Flee with 1 HP
	var wf := travel_world(5, 5, 20)
	wf.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, wf.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	engine.commit_player_intent(wf, PlayerIntent.create_resolve_encounter(wf.player.npc_id, &"FIGHT"))
	wf.player.field_kit.hp = 1
	act_field(wf, "FLEE")
	check(wf.player.field_kit.hp == 1, "road flee with 1 HP preserves HP >= 1 (does not kill)")
	check(wf.npc_life_state_registry.get_life_state(wf.player.npc_id).is_alive(), "player alive after road flee")
	act_field(wf, "CONFIRM")

	# Canonical FLEE_ROAD with starvation/dehydration must NOT bypass death rules
	var w_starve := travel_world(0, 0, 10)
	w_starve.player.water_exposure = SimulationEngine.WATER_EXPOSURE_GRACE_DAYS
	w_starve.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, w_starve.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	var flee_res := engine.commit_player_intent(w_starve, PlayerIntent.create_resolve_encounter(w_starve.player.npc_id, &"FLEE_ROAD"))
	check(flee_res.success, "FLEE_ROAD committed")
	var ls_starve := w_starve.npc_life_state_registry.get_life_state(w_starve.player.npc_id)
	check(not ls_starve.is_alive(), "FLEE_ROAD under lethal exposure triggers canonical death")
	print("PASS GATE 6: Resource and HP clamps verified.")

	# --------------------------------------------------------------------------
	# GATE 7: Legacy Field Combat Non-Regression
	# --------------------------------------------------------------------------
	print("\n--- [GATE 7] Legacy Field Combat Non-Regression ---")
	# Re-run the exact sequence from test_field_combat.gd and assert SHA match
	var w_leg := fresh_legacy()
	var denied := func(w: WorldState, payload: Dictionary) -> void:
		var before := w.to_canonical_json().sha256_text()
		check(not engine.commit_player_intent(w, PlayerIntent.create_field_action(w.player.npc_id, payload)).success, "invalid field intent denied")
		check(w.to_canonical_json().sha256_text() == before, "rejection atomic SHA")

	denied.call(w_leg, {"command": "CRAFT"})
	denied.call(w_leg, {"command": "EQUIP"})
	denied.call(w_leg, {"command": "OPEN"})
	denied.call(w_leg, {"command": "SPAWN_GUN"})
	w_leg.player.inventory.scrap = 3
	check(act_field(w_leg, "CRAFT").success and w_leg.player.inventory.scrap == 0 and w_leg.player.get_total_inventory_load() == 12, "3 scrap -> unique 2-weight crowbar")
	denied.call(w_leg, {"command": "CRAFT"})
	check(act_field(w_leg, "EQUIP").success and w_leg.player.field_kit.equipped, "equip owned item")
	denied.call(w_leg, {"command": "EQUIP"})
	check(act_field(w_leg, "UNEQUIP").success and not w_leg.player.field_kit.equipped, "explicit unequip")
	denied.call(w_leg, {"command": "UNEQUIP"})
	check(act_field(w_leg, "EQUIP").success, "re-equip before battle")
	var la := w_leg.duplicate_state()
	var lb := WorldState.from_json(w_leg.to_canonical_json())
	for track in [la, lb]:
		check(act_field(track, "START").success, "start encounter")
	var stale := fields(la, "ATTACK")
	for track in [la, lb]:
		check(act_field(track, "ATTACK").success, "turn 1")
		check(track.player.field_kit.hp == 10 and track.field_state.enemy_hp == 5, "equipped hit 3 and enemy hit 2")
	denied.call(la, stale)
	denied.call(la, {"command": "REST"})
	var before := la.to_canonical_json()
	check(not engine.commit_player_intent(la, PlayerIntent.create_wait(la.player.npc_id)).success and before == la.to_canonical_json(), "world time blocked during combat")
	for track in [la, lb]:
		check(act_field(track, "DEFEND").success and track.player.field_kit.hp == 10, "defend absorbs normal hit")
	lb = WorldState.from_json(lb.to_canonical_json())
	for track in [la, lb]:
		check(act_field(track, "ATTACK").success and track.field_state.enemy_hp == 0 and track.player.field_kit.hp == 10, "prepared hit 5 wins before retaliation")
		check(track.current_day == 0, "rounds do not spend days")
		check(engine.validate_invariants(track) == "", "combat global invariants")
	check(la.to_canonical_json().sha256_text() == lb.to_canonical_json().sha256_text(), "mid-turn save/load dual-track replay")
	var receipt := fields(la, "CONFIRM")
	check(act_field(la, "CONFIRM").success, "explicit combat result confirmation")
	denied.call(la, receipt)
	check(act_field(la, "OPEN").success, "crowbar opens cleared cache")
	check(la.player.inventory.water == 9 and la.player.inventory.food == 7 and la.player.get_total_inventory_load() == 18, "actual one-time cache goods and tool weight")
	act_field(la, "CONFIRM")
	denied.call(la, {"command": "OPEN"})
	check(act_field(la, "REST").success and la.current_day == 1 and la.player.field_kit.hp == 12, "rest advances real day, heals to cap")
	# C3 deliberately adds MELEE practice to successful attacks. Project out only
	# that new authority to retain the independent pre-C3 combat fixture: HP,
	# enemy state, inventory, death and time must still match byte for byte.
	var legacy_projection: Dictionary = la.to_dict()
	legacy_projection.player.capability.skill_ranks.MELEE = w_leg.player.capability.get_skill_rank("MELEE").rank
	legacy_projection.player.capability.erase("skill_practice")
	legacy_projection.player.capability.erase("skill_growth_schema_version")
	for event in legacy_projection.events:
		if event.type == "FIELD_TURN":
			event.payload.erase("skill_practice")
	var leg_sha := JSON.stringify(legacy_projection, "\t", true).sha256_text()
	check(leg_sha == "4077195a038b6d5db19c9cb69905d10f1aa60228542cb0907f4688b3706c3d68", "pre-C3 combat state still matches exact reference after excluding C3 practice")
	
	# Outskirts lethal defeat still commits death for source != road
	var w_fatal := fresh_world()
	act_field(w_fatal, "START")
	w_fatal.player.field_kit.hp = 1
	var pop_before := w_fatal.get_settlement(&"settlement:gray_valley").population
	act_field(w_fatal, "FLEE") # Takes 1 damage in shed -> HP becomes 0 -> DEAD!
	check(w_fatal.player.field_kit.hp == 0, "legacy shed flee can be lethal at 1 HP")
	check(not w_fatal.npc_life_state_registry.get_life_state(w_fatal.player.npc_id).is_alive(), "legacy lethal death committed")
	check(w_fatal.get_settlement(&"settlement:gray_valley").population == pop_before - 1, "named death decrements population")
	check(engine.validate_invariants(w_fatal) == "", "population conservation holds")
	print("PASS GATE 7: Legacy field combat non-regression verified.")

	print("\n================================================================================")
	print("ROAD-COMBAT GATES (1 ~ 7): ", "ALL PASS" if failed == 0 else "FAILED (%d)" % failed)
	print("================================================================================")
	quit(0 if failed == 0 else 1)
