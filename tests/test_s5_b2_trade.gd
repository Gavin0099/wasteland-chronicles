extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-B2 TRADE TEST SUITE
# ==============================================================================
# Verifies that player trading is legal, atomic, fail-closed, and conservative:
#   T1: Quote Correctness (BUY=ceil, SELL=floor, spread, minimum 1 cap)
#   T2: BUY Atomicity & Time Invariance (Stock, caps, backpack, day preserved)
#   T3: SELL Atomicity & Time Invariance (Stock, caps, backpack, day preserved)
#   T4: Fail-Closed Preconditions (0 Mutation across all failure cases)
#   T5: Full Conservation Law (Commodities and currency strictly conserved)
#   T6: UI Shell Fidelity & Isolation (Live market vs remote info fog)
#   T7: Persistence & Save/Load Determinism (Bitwise fixed point)
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S5-B2 TRADE TEST SUITE                               ")
	print("================================================================================")

	var engine := SimulationEngine.new()

	# --------------------------------------------------------------------------
	print("\n--- [GATE T1] Quote Correctness (Spread & Minimum Price) ---")
	var s_test := SettlementState.new(&"settlement:test", "Test Town")
	s_test.price_water = 10.0
	s_test.price_food = 8.4
	s_test.price_scrap = 12.7
	s_test.price_fuel = 0.2

	# Exact integer price: buy == sell == 10
	var b_water := SimulationEngine.get_buy_quote(s_test, &"water")
	var s_water := SimulationEngine.get_sell_quote(s_test, &"water")
	if b_water != 10 or s_water != 10:
		print("FAIL T1: Expected water quotes 10/10, got buy=%d, sell=%d" % [b_water, s_water])
		quit(1)
		return

	# Fractional price: 8.4 -> buy=9, sell=8
	var b_food := SimulationEngine.get_buy_quote(s_test, &"food")
	var s_food := SimulationEngine.get_sell_quote(s_test, &"food")
	if b_food != 9 or s_food != 8:
		print("FAIL T1: Expected food quotes 9/8, got buy=%d, sell=%d" % [b_food, s_food])
		quit(1)
		return

	# Fractional price: 12.7 -> buy=13, sell=12
	var b_scrap := SimulationEngine.get_buy_quote(s_test, &"scrap")
	var s_scrap := SimulationEngine.get_sell_quote(s_test, &"scrap")
	if b_scrap != 13 or s_scrap != 12:
		print("FAIL T1: Expected scrap quotes 13/12, got buy=%d, sell=%d" % [b_scrap, s_scrap])
		quit(1)
		return

	# Sub-1 price: 0.2 -> buy=1 (ceil), sell=1 (maxi(1, 0))
	var b_fuel := SimulationEngine.get_buy_quote(s_test, &"fuel")
	var s_fuel := SimulationEngine.get_sell_quote(s_test, &"fuel")
	if b_fuel != 1 or s_fuel != 1:
		print("FAIL T1: Expected fuel quotes 1/1, got buy=%d, sell=%d" % [b_fuel, s_fuel])
		quit(1)
		return

	# Zero price test
	s_test.price_fuel = 0.0
	var b_zero := SimulationEngine.get_buy_quote(s_test, &"fuel")
	var s_zero := SimulationEngine.get_sell_quote(s_test, &"fuel")
	if b_zero != 1 or s_zero != 1:
		print("FAIL T1: Expected zero-price quotes 1/1, got buy=%d, sell=%d" % [b_zero, s_zero])
		quit(1)
		return

	print("  BUY quote = ceil(price), SELL quote = floor(price)")
	print("  Natural spread guaranteed: SELL quote <= BUY quote")
	print("  Minimum floor of 1 cap per unit strictly enforced")
	print("PASS GATE T1: Quote Correctness verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE T2] BUY Atomicity & Time Invariance ---")
	var w2 := S1WorldData.create_s1_world()
	engine.materialize_player(w2, &"settlement:gray_valley", "Trader", 25)
	var p2: PlayerState = w2.player
	p2.money = 50
	p2.capacity_total = 20
	p2.inventory.water = 0
	p2.inventory.food = 0

	var gv2: SettlementState = w2.get_settlement(&"settlement:gray_valley")
	var init_gv_water: int = gv2.inventory.water # 80
	var init_gv_cash: int = gv2.market_cash # 500
	var init_p_money: int = p2.money # 50
	var init_p_water: int = p2.inventory.water # 0
	var buy_q_water := SimulationEngine.get_buy_quote(gv2, &"water") # 15

	var buy_res := engine.execute_player_buy(w2, &"water", 2)
	if not buy_res.get("success", false):
		print("FAIL T2: BUY failed: %s" % buy_res)
		quit(1)
		return

	if buy_res.get("unit_price") != buy_q_water or buy_res.get("total_amount") != buy_q_water * 2:
		print("FAIL T2: Result cost mismatch: %s" % buy_res)
		quit(1)
		return

	if p2.money != init_p_money - (buy_q_water * 2):
		print("FAIL T2: Player money expected %d, got %d" % [init_p_money - (buy_q_water * 2), p2.money])
		quit(1)
		return

	if p2.inventory.water != init_p_water + 2 or p2.get_total_inventory_load() != 2:
		print("FAIL T2: Player backpack water expected 2, got %d" % p2.inventory.water)
		quit(1)
		return

	if gv2.inventory.water != init_gv_water - 2:
		print("FAIL T2: Settlement stock expected %d, got %d" % [init_gv_water - 2, gv2.inventory.water])
		quit(1)
		return

	if gv2.market_cash != init_gv_cash + (buy_q_water * 2):
		print("FAIL T2: Settlement market_cash expected %d, got %d" % [init_gv_cash + (buy_q_water * 2), gv2.market_cash])
		quit(1)
		return

	if w2.current_day != 0:
		print("FAIL T2: Trade must NOT advance world day, got Day %d" % w2.current_day)
		quit(1)
		return

	# Event log check
	var last_evt: EventRecord = w2.event_log.back()
	if last_evt == null or last_evt.type != "TRADE_COMPLETED" or last_evt.payload.get("action") != "BUY":
		print("FAIL T2: TRADE_COMPLETED event not properly logged: %s" % last_evt)
		quit(1)
		return

	print("  BUY 2 water: goods and caps atomically transferred")
	print("  Player: -30 caps ($20 remaining), +2 water (load 2/20)")
	print("  Settlement: +30 caps ($530 reserve), -2 water (78 remaining)")
	print("  Time invariance confirmed: Day %d" % w2.current_day)
	print("PASS GATE T2: BUY Atomicity & Time Invariance verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE T3] SELL Atomicity & Time Invariance ---")
	var sell_q_water := SimulationEngine.get_sell_quote(gv2, &"water") # 15
	var pre_sell_p_money: int = p2.money # 20
	var pre_sell_gv_cash: int = gv2.market_cash # 530
	var pre_sell_gv_water: int = gv2.inventory.water # 78

	var sell_res := engine.execute_player_sell(w2, &"water", 1)
	if not sell_res.get("success", false):
		print("FAIL T3: SELL failed: %s" % sell_res)
		quit(1)
		return

	if sell_res.get("unit_price") != sell_q_water or sell_res.get("total_amount") != sell_q_water:
		print("FAIL T3: Result revenue mismatch: %s" % sell_res)
		quit(1)
		return

	if p2.money != pre_sell_p_money + sell_q_water:
		print("FAIL T3: Player money expected %d, got %d" % [pre_sell_p_money + sell_q_water, p2.money])
		quit(1)
		return

	if p2.inventory.water != 1 or p2.get_total_inventory_load() != 1:
		print("FAIL T3: Player backpack expected 1 water, got %d" % p2.inventory.water)
		quit(1)
		return

	if gv2.inventory.water != pre_sell_gv_water + 1:
		print("FAIL T3: Settlement stock expected %d, got %d" % [pre_sell_gv_water + 1, gv2.inventory.water])
		quit(1)
		return

	if gv2.market_cash != pre_sell_gv_cash - sell_q_water:
		print("FAIL T3: Settlement market_cash expected %d, got %d" % [pre_sell_gv_cash - sell_q_water, gv2.market_cash])
		quit(1)
		return

	if w2.current_day != 0:
		print("FAIL T3: Trade must NOT advance world day, got Day %d" % w2.current_day)
		quit(1)
		return

	print("  SELL 1 water: goods and caps atomically transferred")
	print("  Player: +15 caps ($35 total), -1 water (load 1/20)")
	print("  Settlement: -15 caps ($515 reserve), +1 water (79 total)")
	print("PASS GATE T3: SELL Atomicity & Time Invariance verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE T4] Fail-Closed Preconditions (0 Mutation) ---")
	var w4 := S1WorldData.create_s1_world()
	engine.materialize_player(w4, &"settlement:gray_valley", "Vagrant", 25)
	var p4: PlayerState = w4.player
	p4.money = 20
	p4.capacity_total = 5
	p4.inventory.water = 2
	p4.inventory.food = 2 # total load = 4 / 5

	var gv4: SettlementState = w4.get_settlement(&"settlement:gray_valley")

	# Test matrix of 8 fail-closed conditions
	var test_cases: Array[Dictionary] = [
		{
			"name": "Invalid commodity",
			"intent": PlayerIntent.create_buy(p4.npc_id, &"laser_rifle", 1),
			"err_prefix": "INVALID_COMMODITY"
		},
		{
			"name": "Zero quantity",
			"intent": PlayerIntent.create_buy(p4.npc_id, &"water", 0),
			"err_prefix": "INVALID_QUANTITY"
		},
		{
			"name": "Negative quantity",
			"intent": PlayerIntent.create_buy(p4.npc_id, &"water", -3),
			"err_prefix": "INVALID_QUANTITY"
		},
		{
			"name": "Insufficient settlement stock",
			"intent": PlayerIntent.create_buy(p4.npc_id, &"water", 9999),
			"err_prefix": "INSUFFICIENT_STOCK"
		},
		{
			"name": "Insufficient player funds",
			"intent": PlayerIntent.create_buy(p4.npc_id, &"water", 2), # 2 * 15 = 30 > 20 caps
			"err_prefix": "INSUFFICIENT_FUNDS"
		},
		{
			"name": "Insufficient backpack capacity",
			"intent": PlayerIntent.create_buy(p4.npc_id, &"scrap", 2), # load 4 + 2 = 6 > capacity 5
			"err_prefix": "INSUFFICIENT_CAPACITY"
		},
		{
			"name": "Insufficient player stock on sell",
			"intent": PlayerIntent.create_sell(p4.npc_id, &"water", 5), # player only has 2
			"err_prefix": "INSUFFICIENT_PLAYER_STOCK"
		},
		{
			"name": "Insufficient settlement market cash on sell",
			"intent": PlayerIntent.create_sell(p4.npc_id, &"water", 1), # water sell quote = 15 > 2
			"err_prefix": "INSUFFICIENT_MARKET_CASH",
			"setup": func(): gv4.market_cash = 2
		}
	]

	for tc in test_cases:
		if tc.has("setup"):
			tc["setup"].call()
		var sha_before := w4.to_canonical_json().sha256_text()
		var res: Dictionary = engine.commit_player_intent(w4, tc["intent"])
		var sha_after := w4.to_canonical_json().sha256_text()

		if res.get("success", true):
			print("FAIL T4: Case '%s' should have failed, but succeeded!" % tc["name"])
			quit(1)
			return

		var err_str: String = res.get("error", "")
		if not err_str.begins_with(tc["err_prefix"]):
			print("FAIL T4: Case '%s' expected error starting with '%s', got '%s'" % [tc["name"], tc["err_prefix"], err_str])
			quit(1)
			return

		if sha_before != sha_after:
			print("FAIL T4: Case '%s' mutated world state on failure!" % tc["name"])
			quit(1)
			return
		print("  Verified fail-closed: %s (0 mutation, bitwise SHA intact)" % tc["name"])

	# Test player in-transit fail-closed
	var ls4: NpcLifeState = w4.npc_life_state_registry.get_life_state(p4.npc_id)
	ls4.status = NpcLifeState.Status.IN_TRANSIT
	var transit_buy := PlayerIntent.create_buy(p4.npc_id, &"water", 1)
	var transit_res := engine.commit_player_intent(w4, transit_buy)
	if transit_res.get("success", true) or not String(transit_res.get("error", "")).begins_with("INVALID_STATUS"):
		print("FAIL T4: In-transit player trade was not rejected: %s" % transit_res)
		quit(1)
		return
	ls4.status = NpcLifeState.Status.SETTLED
	print("  Verified fail-closed: In-transit player cannot trade")

	print("PASS GATE T4: Fail-Closed Preconditions (0 Mutation) verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE T5] Full Conservation Law ---")
	var w5 := S1WorldData.create_s1_world()
	engine.materialize_player(w5, &"settlement:gray_valley", "Merchant", 28)
	var p5: PlayerState = w5.player
	p5.money = 100
	p5.capacity_total = 20

	var gv5: SettlementState = w5.get_settlement(&"settlement:gray_valley")

	var initial_total_water := _get_world_total_commodity(w5, "water")
	var initial_total_food := _get_world_total_commodity(w5, "food")
	var initial_total_scrap := _get_world_total_commodity(w5, "scrap")
	var initial_total_fuel := _get_world_total_commodity(w5, "fuel")
	var initial_subsystem_cash := p5.money + gv5.market_cash

	# Execute a sequence of 6 trades
	engine.execute_player_buy(w5, &"water", 2)
	engine.execute_player_buy(w5, &"food", 1)
	engine.execute_player_sell(w5, &"water", 1)
	engine.execute_player_buy(w5, &"scrap", 3)
	engine.execute_player_sell(w5, &"scrap", 2)
	engine.execute_player_buy(w5, &"fuel", 1)

	var final_total_water := _get_world_total_commodity(w5, "water")
	var final_total_food := _get_world_total_commodity(w5, "food")
	var final_total_scrap := _get_world_total_commodity(w5, "scrap")
	var final_total_fuel := _get_world_total_commodity(w5, "fuel")
	var final_subsystem_cash := p5.money + gv5.market_cash

	if initial_total_water != final_total_water:
		print("FAIL T5: Water conservation violated: %d != %d" % [initial_total_water, final_total_water])
		quit(1)
		return
	if initial_total_food != final_total_food:
		print("FAIL T5: Food conservation violated: %d != %d" % [initial_total_food, final_total_food])
		quit(1)
		return
	if initial_total_scrap != final_total_scrap:
		print("FAIL T5: Scrap conservation violated: %d != %d" % [initial_total_scrap, final_total_scrap])
		quit(1)
		return
	if initial_total_fuel != final_total_fuel:
		print("FAIL T5: Fuel conservation violated: %d != %d" % [initial_total_fuel, final_total_fuel])
		quit(1)
		return
	if initial_subsystem_cash != final_subsystem_cash:
		print("FAIL T5: Currency conservation violated: %d != %d" % [initial_subsystem_cash, final_subsystem_cash])
		quit(1)
		return

	print("  World water conservation: %d == %d" % [initial_total_water, final_total_water])
	print("  World food conservation:  %d == %d" % [initial_total_food, final_total_food])
	print("  World scrap conservation: %d == %d" % [initial_total_scrap, final_total_scrap])
	print("  World fuel conservation:  %d == %d" % [initial_total_fuel, final_total_fuel])
	print("  Local currency conservation: %d == %d (player $%d + market $%d)" % [
		initial_subsystem_cash, final_subsystem_cash, p5.money, gv5.market_cash
	])
	print("PASS GATE T5: Full Conservation Law verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE T6] UI Shell Fidelity & Fast-Lane Market ---")
	var w6 := S1WorldData.create_s1_world()
	engine.materialize_player(w6, &"settlement:gray_valley", "Vagrant", 25)
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(w6, engine)

	# 1. At Gray Valley (current location): market panel must be visible
	if not shell.market_panel.visible:
		print("FAIL T6: Market panel should be visible at current settlement")
		quit(1)
		return

	# 2. Inspect remote settlement (New Hope): market panel must hide (Information Fog)
	shell.select_settlement("settlement:new_hope")
	if shell.market_panel.visible:
		print("FAIL T6: Market panel should be hidden when inspecting remote settlement")
		quit(1)
		return

	# 3. Return to Gray Valley: market panel becomes visible again
	shell.select_settlement("settlement:gray_valley")
	if not shell.market_panel.visible:
		print("FAIL T6: Market panel should become visible again upon returning to current location")
		quit(1)
		return

	# 4. Trigger UI trade: Buy 1 Water
	var init_w6_water: int = w6.player.inventory.water
	var ui_buy_res := shell.on_buy_pressed("water", 1)
	if not ui_buy_res.get("success", false):
		print("FAIL T6: UI on_buy_pressed failed: %s" % ui_buy_res)
		quit(1)
		return

	if w6.player.inventory.water != init_w6_water + 1:
		print("FAIL T6: Player did not receive water via UI: %d" % w6.player.inventory.water)
		quit(1)
		return

	# Check UI HUD updated
	if shell.lbl_hud_money.text != "CAPS: $%d" % w6.player.money:
		print("FAIL T6: HUD money label did not update: %s" % shell.lbl_hud_money.text)
		quit(1)
		return

	# 5. Trigger UI trade: Sell 1 Water
	var ui_sell_res := shell.on_sell_pressed("water", 1)
	if not ui_sell_res.get("success", false):
		print("FAIL T6: UI on_sell_pressed failed: %s" % ui_sell_res)
		quit(1)
		return

	if w6.player.inventory.water != init_w6_water:
		print("FAIL T6: Player did not sell water via UI: %d" % w6.player.inventory.water)
		quit(1)
		return

	print("  Live settlement displays market panel with buy/sell controls")
	print("  Remote settlement strictly hides market controls (0 information leak)")
	print("  UI trade button dispatches PlayerIntent and updates HUD reactively")
	print("PASS GATE T6: UI Shell Fidelity & Fast-Lane Market verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE T7] Persistence & Save/Load Determinism ---")
	var w7_a := S1WorldData.create_s1_world()
	engine.materialize_player(w7_a, &"settlement:gray_valley", "Courier", 24)
	w7_a.player.money = 75
	engine.execute_player_buy(w7_a, &"water", 3)
	engine.execute_player_buy(w7_a, &"food", 2)
	engine.execute_player_sell(w7_a, &"water", 1)

	# Serialize
	var snap: Dictionary = w7_a.to_dict()
	var w7_b: WorldState = WorldState.from_dict(snap)

	# Bitwise identity check
	var sha_orig := w7_a.to_canonical_json().sha256_text()
	var sha_rest := w7_b.to_canonical_json().sha256_text()

	if sha_orig != sha_rest:
		print("FAIL T7: Saved and restored world canonical JSON mismatch!")
		print("  Original SHA: %s" % sha_orig)
		print("  Restored SHA: %s" % sha_rest)
		quit(1)
		return

	# Check settlement market_cash preservation
	var gv_a: SettlementState = w7_a.get_settlement(&"settlement:gray_valley")
	var gv_b: SettlementState = w7_b.get_settlement(&"settlement:gray_valley")
	if gv_a.market_cash != gv_b.market_cash:
		print("FAIL T7: market_cash mismatch: %d != %d" % [gv_a.market_cash, gv_b.market_cash])
		quit(1)
		return

	# Advance one world tick on both worlds to verify identical simulation evolution
	engine.execute_player_wait(w7_a)
	engine.execute_player_wait(w7_b)

	var sha_orig_d1 := w7_a.to_canonical_json().sha256_text()
	var sha_rest_d1 := w7_b.to_canonical_json().sha256_text()

	if sha_orig_d1 != sha_rest_d1:
		print("FAIL T7: Post-trade simulation diverged after tick!")
		print("  Original Day 1 SHA: %s" % sha_orig_d1)
		print("  Restored Day 1 SHA: %s" % sha_rest_d1)
		quit(1)
		return

	print("  Pre-tick restored world bitwise identical: %s" % sha_orig)
	print("  Post-tick Day 1 simulation evolution bitwise identical: %s" % sha_orig_d1)
	print("PASS GATE T7: Persistence & Save/Load Determinism verified.")

	print("\n================================================================================")
	print("ALL S5-B2 TRADE GATES (T1 ~ T7) PASSED CLEANLY!                                ")
	print("================================================================================")
	shell.queue_free()
	quit(0)

func _get_world_total_commodity(world: WorldState, commodity: String) -> int:
	var total := 0
	for s_id in world.settlements:
		var s: SettlementState = world.settlements[s_id]
		total += s.inventory.get_amount(commodity)
	for c_id in world.caravans:
		var c: CaravanState = world.caravans[c_id]
		total += c.cargo.get_amount(commodity)
	if world.player != null and world.player.inventory != null:
		total += world.player.inventory.get_amount(commodity)
	return total
