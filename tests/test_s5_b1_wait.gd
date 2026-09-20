extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-B1 TRAVEL + WAIT TEST SUITE
# ==============================================================================
# Verifies that WAIT is the authoritative, unified time-advancing player verb:
#   B1: WAIT Authorization (Valid PlayerIntent, fail-closed for invalid/deceased)
#   B2: Exactly One Tick (Simulation and all world entities advance together)
#   B3: Settled Wait (No double-metabolism: backpack water/food preserved)
#   B4: Transit Wait (Travel progress + personal backpack consumption)
#   B5: Physical Arrival (Axiom 9 arrival timing, settlement re-integration)
#   B6: UI State / Mid-Route Save-Load Determinism
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S5-B1 TRAVEL + WAIT TEST SUITE                       ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	print("\n--- [GATE B1] WAIT Authorization ---")
	var w1 := S1WorldData.create_s1_world()
	var mat_res := engine.materialize_player(w1, &"settlement:gray_valley", "Vagrant", 25)
	if not mat_res["success"]:
		print("FAIL B1: Player materialization failed: %s" % mat_res.get("error", ""))
		quit(1)
		return

	var p: PlayerState = w1.player

	# Valid WAIT intent
	var valid_wait := PlayerIntent.create_wait(p.npc_id)
	var auth_ok := engine.authorize_player_intent(w1, valid_wait)
	if auth_ok != "":
		print("FAIL B1: Valid WAIT intent refused: %s" % auth_ok)
		quit(1)
		return

	# Bogus player id
	var bogus_wait := PlayerIntent.create_wait(&"npc:99999999")
	var bogus_err := engine.authorize_player_intent(w1, bogus_wait)
	if not bogus_err.begins_with("INVALID_PLAYER_ID"):
		print("FAIL B1: Bogus player ID authorized: %s" % bogus_err)
		quit(1)
		return

	# Deceased player
	var ls: NpcLifeState = w1.npc_life_state_registry.get_life_state(p.npc_id)
	ls.status = NpcLifeState.Status.DEAD
	var dead_err := engine.authorize_player_intent(w1, valid_wait)
	if not dead_err.begins_with("DECEASED_OR_NO_LIFE_STATE"):
		print("FAIL B1: Deceased player authorized to WAIT: %s" % dead_err)
		quit(1)
		return

	ls.status = NpcLifeState.Status.SETTLED # Restore life state
	print("  WAIT is a first-class PlayerIntent")
	print("  Fail-closed authorization verified against invalid/deceased entities")
	print("PASS GATE B1: WAIT Authorization verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE B2] Exactly One Tick & World Evolution ---")
	var initial_day := w1.current_day # Day 0
	var gv: SettlementState = w1.get_settlement(&"settlement:gray_valley")
	var gv_water_before := gv.inventory.water
	var events_before := w1.event_log.size()

	# Commit WAIT intent
	var wait_res := engine.commit_player_intent(w1, valid_wait)
	if not wait_res.get("success", false):
		print("FAIL B2: Failed to commit WAIT intent: %s" % wait_res.get("error", ""))
		quit(1)
		return

	# Exactly one tick: Day 0 -> Day 1
	if w1.current_day != initial_day + 1:
		print("FAIL B2: Expected day %d, got %d" % [initial_day + 1, w1.current_day])
		quit(1)
		return

	# World actually evolved
	var gv_water_after := gv.inventory.water
	if gv_water_after >= gv_water_before:
		print("FAIL B2: Settlement did not consume resources during tick! %d -> %d" % [gv_water_before, gv_water_after])
		quit(1)
		return

	if w1.event_log.size() <= events_before:
		print("FAIL B2: Event log did not record events during tick!")
		quit(1)
		return

	# Assert PLAYER_WAIT event committed to ledger
	var found_wait_evt := false
	for evt in w1.event_log:
		if evt.type == "PLAYER_WAIT" and evt.day == 0:
			found_wait_evt = true
			break
	if not found_wait_evt:
		print("FAIL B2: PLAYER_WAIT event missing from ledger!")
		quit(1)
		return

	print("  WAIT advanced world by exactly one tick: Day %d -> Day %d" % [initial_day, w1.current_day])
	print("  World evolved: Gray Valley water %d -> %d, events logged: %d" % [
		gv_water_before, gv_water_after, w1.event_log.size()
	])
	print("PASS GATE B2: Exactly One Tick & World Evolution verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE B3] Settled Wait (No Double-Metabolism) ---")
	# Player is SETTLED in Gray Valley.
	# Personal backpack starts at water: 5, food: 5, load: 10
	var bp_water_start := p.inventory.water
	var bp_food_start := p.inventory.food
	var bp_load_start := p.get_total_inventory_load()

	# Run 3 consecutive settled WAIT actions (Day 1 -> Day 4)
	for i in range(3):
		var res := engine.execute_player_wait(w1)
		if not res.get("success", false):
			print("FAIL B3: Settled wait %d failed: %s" % [i, res.get("error", "")])
			quit(1)
			return

	if w1.current_day != 4:
		print("FAIL B3: Expected day 4 after 3 waits, got %d" % w1.current_day)
		quit(1)
		return

	# Backpack MUST be untouched because player is part of settlement aggregate population
	if p.inventory.water != bp_water_start or p.inventory.food != bp_food_start:
		print("FAIL B3: Double-metabolism detected! Backpack consumed while settled: water %d->%d, food %d->%d" % [
			bp_water_start, p.inventory.water, bp_food_start, p.inventory.food
		])
		quit(1)
		return

	if p.get_total_inventory_load() != bp_load_start:
		print("FAIL B3: Backpack load changed while settled!")
		quit(1)
		return

	print("  3 Days settled in Gray Valley: Day %d" % w1.current_day)
	print("  Backpack load strictly preserved: %d / %d (Water: %d, Food: %d)" % [
		p.get_total_inventory_load(), p.capacity_total, p.inventory.water, p.inventory.food
	])
	print("  Zero double-metabolism confirmed")
	print("PASS GATE B3: Settled Wait (No Double-Metabolism) verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE B4] Transit Wait (Travel Progress + Personal Consumption) ---")
	# Initiate travel from Gray Valley to New Hope (Route: 3 days)
	var travel_intent := PlayerIntent.create_travel(p.npc_id, &"settlement:new_hope")
	var travel_res := engine.commit_player_intent(w1, travel_intent)
	if not travel_res.get("success", false):
		print("FAIL B4: Failed to commit travel intent: %s" % travel_res.get("error", ""))
		quit(1)
		return

	var party_id: StringName = travel_res["party_id"]
	var party: RefugeePartyState = w1.get_refugee_party(party_id)
	if party == null:
		print("FAIL B4: Refugee party not found!")
		quit(1)
		return

	# Day 4: Departure registered. Travel has NOT ticked yet.
	if party.days_remaining != 3:
		print("FAIL B4: Expected party days_remaining 3, got %d" % party.days_remaining)
		quit(1)
		return

	# Transit Wait 1: Advances Day 4 -> 5
	var wait_t1 := engine.execute_player_wait(w1)
	if not wait_t1.get("success", false):
		print("FAIL B4: Transit wait 1 failed: %s" % wait_t1.get("error", ""))
		quit(1)
		return

	if w1.current_day != 5:
		print("FAIL B4: Expected Day 5, got %d" % w1.current_day)
		quit(1)
		return

	if party.days_remaining != 2:
		print("FAIL B4: Expected days_remaining 2, got %d" % party.days_remaining)
		quit(1)
		return

	# Personal backpack consumed 1 water, 1 food
	if p.inventory.water != 4 or p.inventory.food != 4:
		print("FAIL B4: Expected backpack water=4, food=4; got water=%d, food=%d" % [
			p.inventory.water, p.inventory.food
		])
		quit(1)
		return

	# Transit Wait 2: Advances Day 5 -> 6
	var wait_t2 := engine.execute_player_wait(w1)
	if not wait_t2.get("success", false):
		print("FAIL B4: Transit wait 2 failed: %s" % wait_t2.get("error", ""))
		quit(1)
		return

	if w1.current_day != 6:
		print("FAIL B4: Expected Day 6, got %d" % w1.current_day)
		quit(1)
		return

	if party.days_remaining != 1:
		print("FAIL B4: Expected days_remaining 1, got %d" % party.days_remaining)
		quit(1)
		return

	if p.inventory.water != 3 or p.inventory.food != 3:
		print("FAIL B4: Expected backpack water=3, food=3; got water=%d, food=%d" % [
			p.inventory.water, p.inventory.food
		])
		quit(1)
		return

	print("  Transit Wait 1 (Day 4->5): days_remaining 2, backpack water=4, food=4")
	print("  Transit Wait 2 (Day 5->6): days_remaining 1, backpack water=3, food=3")
	print("PASS GATE B4: Transit Wait verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE B5] Physical Arrival via WAIT (Axiom 9) ---")
	# Transit Wait 3 (Arrival tick: Day 6 -> 7)
	# Departure was Day 4, route 3 days -> Arrival Day = 4 + 3 - 1 = 6.
	# At the end of Day 6 execution, arrival completes and current_day increments to 7.
	var wait_t3 := engine.execute_player_wait(w1)
	if not wait_t3.get("success", false):
		print("FAIL B5: Transit wait 3 (arrival tick) failed: %s" % wait_t3.get("error", ""))
		quit(1)
		return

	if w1.current_day != 7:
		print("FAIL B5: Expected Day 7, got %d" % w1.current_day)
		quit(1)
		return

	var ls_arr: NpcLifeState = w1.npc_life_state_registry.get_life_state(p.npc_id)
	if ls_arr.status != NpcLifeState.Status.SETTLED or ls_arr.population_container_id != &"settlement:new_hope":
		print("FAIL B5: Player not settled at New Hope on arrival! status=%d container=%s" % [
			ls_arr.status, ls_arr.population_container_id
		])
		quit(1)
		return

	# Population conservation holds
	var total_life := 0
	for s_id in w1.settlements:
		var s: SettlementState = w1.settlements[s_id]
		total_life += s.population + s.cumulative_deaths
	for r_id in w1.refugees:
		var r: RefugeePartyState = w1.refugees[r_id]
		if r.is_active and not r.is_arrived:
			total_life += r.headcount

	if total_life != 300:
		print("FAIL B5: Life conservation broken on arrival: %d != 300" % total_life)
		quit(1)
		return

	# Subsequent WAIT at New Hope is now SETTLED wait (backpack water/food preserved at 3/3)
	engine.execute_player_wait(w1)
	if p.inventory.water != 3 or p.inventory.food != 3:
		print("FAIL B5: Backpack consumed after settlement arrival!")
		quit(1)
		return

	print("  Player arrived at New Hope on Day 6 execution, settled at Day 7")
	print("  Life conservation intact: %d == 300" % total_life)
	print("  Post-arrival wait returned to settlement metabolism (backpack 3/3 preserved)")
	print("PASS GATE B5: Physical Arrival via WAIT verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE B6] UI State & Mid-Route Save/Load Determinism ---")
	# 1. UI Shell Integration
	var test_world := S1WorldData.create_s1_world()
	engine.materialize_player(test_world, &"settlement:gray_valley", "Vagrant", 25)
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(test_world, engine)

	# When settled: button text is [WAIT 1 DAY]
	if shell.btn_wait.text != "[WAIT 1 DAY]":
		print("FAIL B6: Expected btn_wait '[WAIT 1 DAY]', got '%s'" % shell.btn_wait.text)
		quit(1)
		return

	# Press WAIT via UI
	var ui_wait_res := shell.on_wait_pressed()
	if not ui_wait_res.get("success", false) or test_world.current_day != 1:
		print("FAIL B6: UI on_wait_pressed failed or did not advance day: %s" % ui_wait_res)
		quit(1)
		return

	# Initiate travel via UI
	shell.select_settlement("settlement:new_hope")
	shell.on_travel_pressed()

	# When in transit: button text dynamically switches to [CONTINUE — 1 DAY]
	if shell.btn_wait.text != "[CONTINUE — 1 DAY]":
		print("FAIL B6: Expected btn_wait '[CONTINUE — 1 DAY]', got '%s'" % shell.btn_wait.text)
		quit(1)
		return

	# 2. Mid-Route Save/Load Equivalence
	# World A: Continuous run
	var wa := S1WorldData.create_s1_world()
	engine.materialize_player(wa, &"settlement:gray_valley", "Vagrant", 25)
	engine.execute_player_wait(wa) # Day 1
	var tr_a := PlayerIntent.create_travel(wa.player.npc_id, &"settlement:new_hope")
	engine.commit_player_intent(wa, tr_a)
	engine.execute_player_wait(wa) # Day 2 (mid-route)
	engine.execute_player_wait(wa) # Day 3 (mid-route)
	engine.execute_player_wait(wa) # Day 4 (arrived)
	for d in range(5):
		engine.execute_player_wait(wa) # Day 5..9

	# World B: Interrupted at Day 2 (mid-route Save/Load)
	var wb := S1WorldData.create_s1_world()
	engine.materialize_player(wb, &"settlement:gray_valley", "Vagrant", 25)
	engine.execute_player_wait(wb) # Day 1
	var tr_b := PlayerIntent.create_travel(wb.player.npc_id, &"settlement:new_hope")
	engine.commit_player_intent(wb, tr_b)
	engine.execute_player_wait(wb) # Day 2 (mid-route)

	# Save/Load round trip
	var json_snap := wb.to_canonical_json()
	var snap_dict: Dictionary = JSON.parse_string(json_snap)
	var wb_restored := WorldState.from_dict(snap_dict)
	if wb_restored == null:
		print("FAIL B6: WorldState.from_dict failed to restore snapshot!")
		quit(1)
		return

	# Continue from restored world to Day 9
	engine.execute_player_wait(wb_restored) # Day 3
	engine.execute_player_wait(wb_restored) # Day 4
	for d in range(5):
		engine.execute_player_wait(wb_restored)

	var sha_a := wa.to_canonical_json().sha256_text()
	var sha_b := wb_restored.to_canonical_json().sha256_text()

	if sha_a != sha_b:
		print("FAIL B6: Mid-route save/load diverged!")
		print("  Continuous SHA: %s" % sha_a)
		print("  Restored   SHA: %s" % sha_b)
		quit(1)
		return

	print("  UI dynamic button text: [WAIT 1 DAY] <-> [CONTINUE — 1 DAY] verified")
	print("  Continuous vs Mid-Route Restored Day 9 Canonical SHA: %s (100%% bitwise identical)" % sha_a)
	print("PASS GATE B6: UI State & Mid-Route Save-Load Determinism verified.")

	print("\n================================================================================")
	print("ALL S5-B1 TRAVEL + WAIT GATES (B1 ~ B6) PASSED CLEANLY!                         ")
	print("================================================================================")
	shell.queue_free()
	quit(0)
