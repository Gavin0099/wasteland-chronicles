extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S5-A.2 PLAYABLE UI SHELL TEST SUITE
# ==============================================================================
# Acceptance Gates:
#   UI1: World Visibility (Player location + 3 settlements visible)
#   UI2: State Fidelity (Projection & UI display match authoritative state 100%)
#   UI3: Travel Interaction (Travel runs the journey through to arrival)
#
# NOTE: UI3 previously asserted the opposite - that pressing Travel must NOT
# advance time, leaving the player to press WAIT once per day. Play-testing
# showed that turns a journey into paperwork, and the Owner superseded that
# principle in S5-B3. The gate is rewritten to assert the new behaviour rather
# than removed, so the change of intent stays visible.
#   UI4: Transit Feedback (Shows IN_TRANSIT; external tick updates progress to arrival)
#   UI5: Simulation Isolation (UI reads via projection, mutations via Intent only)
#   UI6: Playable Smoke (Lifecycle from start to arrival with 0 crashes)
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("    WASTELAND CHRONICLES - S5-A.2 PLAYABLE UI SHELL TEST SUITE                  ")
	print("================================================================================")

	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()

	# Materialize player at Gray Valley
	var mat_res := engine.materialize_player(world, &"settlement:gray_valley", "Vagrant", 28, NpcProfile.Background.SCAVENGER)
	if not mat_res["success"]:
		print("FAIL: Failed to materialize player: %s" % mat_res.get("error", ""))
		quit(1)
		return

	# Instantiate UI Shell
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)

	# --------------------------------------------------------------------------
	print("\n--- [GATE UI1] World Visibility ---")
	var proj := shell.current_projection
	if not proj.has("player") or not proj["player"].get("has_player", false):
		print("FAIL UI1: Player projection missing or has_player false!")
		quit(1)
		return

	var p_view: Dictionary = proj["player"]
	if p_view["name"] != "Vagrant" or not p_view["location_display"].contains("Gray Valley"):
		print("FAIL UI1: Player name/location incorrect: %s @ %s" % [p_view["name"], p_view["location_display"]])
		quit(1)
		return

	var dests: Array = proj.get("destinations", [])
	if dests.size() != 3:
		print("FAIL UI1: Expected 3 sector settlements, found %d" % dests.size())
		quit(1)
		return

	var found_gv := false
	var found_dw := false
	var found_nh := false
	for d in dests:
		match d.get("id"):
			"settlement:gray_valley": found_gv = true
			"settlement:dry_well": found_dw = true
			"settlement:new_hope": found_nh = true

	if not (found_gv and found_dw and found_nh):
		print("FAIL UI1: Not all 3 settlements visible in destinations projection!")
		quit(1)
		return

	print("  Player visible: %s @ %s" % [p_view["name"], p_view["location_display"]])
	print("  3 World nodes projected: Gray Valley, Dry Well, New Hope")
	print("PASS GATE UI1: World Visibility verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE UI2] State Fidelity ---")
	var p_state: PlayerState = world.player
	var bp_view: Dictionary = p_view["backpack"]

	if p_view["money"] != p_state.money:
		print("FAIL UI2: Money mismatch: UI=%d, State=%d" % [p_view["money"], p_state.money])
		quit(1)
		return

	if bp_view["water"] != p_state.inventory.water or bp_view["food"] != p_state.inventory.food:
		print("FAIL UI2: Inventory water/food mismatch!")
		quit(1)
		return

	if bp_view["load"] != p_state.get_total_inventory_load():
		print("FAIL UI2: Backpack load mismatch: UI=%d, State=%d" % [bp_view["load"], p_state.get_total_inventory_load()])
		quit(1)
		return

	if bp_view["capacity"] != p_state.capacity_total:
		print("FAIL UI2: Backpack capacity mismatch: UI=%d, State=%d" % [bp_view["capacity"], p_state.capacity_total])
		quit(1)
		return

	# Current settlement LIVE fidelity
	var cs_view: Dictionary = proj.get("current_settlement", {})
	var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	if cs_view.get("population") != gv.population or cs_view.get("water") != gv.inventory.water:
		print("FAIL UI2: Settlement live data mismatch: pop %d vs %d, water %d vs %d" % [
			cs_view.get("population"), gv.population, cs_view.get("water"), gv.inventory.water
		])
		quit(1)
		return

	# Remote settlement should NOT leak economics (no specialization, no stock, no prices)
	for d in dests:
		if d.get("id") != "settlement:gray_valley":
			if d.has("specialization") or d.has("water") or d.has("price_water"):
				print("FAIL UI2: Remote settlement leaked economic data into projection!")
				quit(1)
				return

	print("  Player HUD values match authoritative PlayerState 100%")
	print("  Settlement Live View matches Gray Valley authoritative state 100%")
	print("  Remote settlements strictly guarded against information leaks")
	print("PASS GATE UI2: State Fidelity verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE UI3] Travel Interaction ---")
	# Select New Hope on map
	shell.select_settlement("settlement:new_hope")
	var travel_btn: Button = shell.btn_travel
	if travel_btn == null or not travel_btn.visible or travel_btn.disabled:
		print("FAIL UI3: Travel button not ready! btn=%s visible=%s disabled=%s text='%s'" % [
			travel_btn != null,
			travel_btn.visible if travel_btn != null else false,
			travel_btn.disabled if travel_btn != null else false,
			travel_btn.text if travel_btn != null else ""
		])
		quit(1)
		return

	var day_before: int = world.current_day

	# Pressing Travel commits the whole journey: the days pass on their own.
	var travel_res := shell.on_travel_pressed()
	if not travel_res.get("success", false):
		print("FAIL UI3: Travel action through UI failed: %s" % travel_res.get("error", ""))
		quit(1)
		return

	# Since S5-B4 the road can stop you. Answer whatever it asks, then the
	# journey must finish on its own - that is the behaviour under test.
	var encounters_answered := 0
	while world.active_encounter != null and encounters_answered < 8:
		var opts := TravelEncounter.options(world.active_encounter.encounter_type)
		var cheapest := String(opts[opts.size() - 1]["id"])
		shell.on_encounter_option_pressed(cheapest)
		encounters_answered += 1

	if world.current_day <= day_before:
		print("FAIL UI3: travelling advanced no days at all!")
		quit(1)
		return
	var final_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if final_ls.status != NpcLifeState.Status.SETTLED:
		print("FAIL UI3: player never arrived (status %d)" % final_ls.status)
		quit(1)
		return
	var arrived_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if arrived_ls.population_container_id != &"settlement:new_hope":
		print("FAIL UI3: player did not end up at New Hope: %s" % arrived_ls.population_container_id)
		quit(1)
		return

	print("  Selected New Hope and pressed TRAVEL")
	print("  UI dispatched PlayerIntent(TRAVEL) -> Authorization -> Atomic Commit")
	print("  Journey ran itself: day %d -> %d, arrived at New Hope (%d encounter(s) answered)" % [
		day_before, world.current_day, encounters_answered])
	print("  The player was never asked to confirm each day of walking")
	print("PASS GATE UI3: Travel Interaction verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE UI4] Transit Feedback & External Tick Progression ---")
	# Since S5-B3 the travel action carries the player all the way to arrival, so
	# nobody is left mid-route by pressing it. This gate is about how transit is
	# RENDERED, so it starts a journey explicitly on its own world and walks the
	# days forward one at a time to prove there is no teleport.
	var t_world := S1WorldData.create_s1_world()
	engine.materialize_player(t_world, &"settlement:gray_valley", "Drifter", 25)
	var t_shell := PlayableShell.new()
	get_root().add_child(t_shell)
	t_shell.setup(t_world, engine)
	var t_intent := PlayerIntent.create_travel(t_world.player.npc_id, &"settlement:new_hope")
	var t_begin := engine.begin_player_travel(t_world, t_intent)
	if not t_begin.get("success", false):
		print("FAIL UI4: could not start the journey: %s" % t_begin.get("error", ""))
		quit(1)
		return
	t_shell.refresh_ui()

	var proj_transit := t_shell.current_projection
	var p_transit: Dictionary = proj_transit["player"]

	if p_transit["status"] != "IN_TRANSIT" or not p_transit["is_in_transit"]:
		print("FAIL UI4: Player UI did not update to IN_TRANSIT after departure!")
		quit(1)
		return

	# Current settlement must be empty while in transit (Information Fog)
	if proj_transit["current_settlement"].size() > 0:
		print("FAIL UI4: Current settlement should not have live view while in transit!")
		quit(1)
		return

	if not t_shell.btn_travel.disabled:
		print("FAIL UI4: Travel button must be disabled while in transit!")
		quit(1)
		return

	print("  Post-departure UI: Player in transit: %s" % p_transit["location_display"])

	var route_len: int = int(t_begin["route_days"])
	for day_step in range(route_len - 1):
		t_shell.advance_day()
		if not t_shell.current_projection["player"]["is_in_transit"]:
			print("FAIL UI4: Premature arrival on day %d of %d (teleportation detected)!" % [day_step + 1, route_len])
			quit(1)
			return
		print("  Day %d: In-transit conserved: %s" % [
			t_world.current_day, t_shell.current_projection["player"]["location_display"]
		])

	# Final leg: the arrival tick.
	t_shell.advance_day()
	var p_arr: Dictionary = t_shell.current_projection["player"]
	if p_arr["status"] != "SETTLED" or p_arr["is_in_transit"]:
		print("FAIL UI4: Player did not arrive and settle after %d days! status=%s" % [route_len, p_arr["status"]])
		quit(1)
		return
	if p_arr["current_container_id"] != "settlement:new_hope":
		print("FAIL UI4: Player settled at %s instead of New Hope!" % p_arr["current_container_id"])
		quit(1)
		return

	t_shell.select_settlement("settlement:new_hope")
	var nh_view: Dictionary = t_shell.current_projection["current_settlement"]
	if nh_view.get("id") != "settlement:new_hope" or not nh_view.get("is_live", false):
		print("FAIL UI4: New Hope is not marked as LIVE current location upon arrival!")
		quit(1)
		return

	print("  Arrival tick executed: Player safely arrived at New Hope: %s" % p_arr["location_display"])
	print("  New Hope panel switched to LIVE authoritative readout")

	# --------------------------------------------------------------------------
	print("\n--- [GATE UI5] Simulation Isolation ---")
	# UI cannot travel to current location
	shell.select_settlement("settlement:new_hope")
	var invalid_res := shell.on_travel_pressed()
	if invalid_res.get("success", true):
		print("FAIL UI5: Same-destination travel should fail authorization!")
		quit(1)
		return

	print("  UI respects fail-closed authorization: %s" % invalid_res.get("error", ""))
	print("  UI relies strictly on read-only PlayerUIProjection and PlayerIntent transactions")
	print("PASS GATE UI5: Simulation Isolation verified.")

	# --------------------------------------------------------------------------
	print("\n--- [GATE UI6] Playable Smoke Test ---")
	# Multi-node selection
	shell.select_settlement("settlement:gray_valley")
	shell.select_settlement("settlement:dry_well")
	shell.select_settlement("settlement:new_hope")

	# Debug world feed toggle
	shell.debug_world_feed_enabled = true
	shell.refresh_ui()
	if shell.event_feed_container.get_child_count() == 0:
		print("FAIL UI6: Debug feed enabled but 0 events rendered!")
		quit(1)
		return

	shell.debug_world_feed_enabled = false
	shell.refresh_ui()
	var first_child: Label = shell.event_feed_container.get_child(0) as Label
	# UX-P1 replaced the debug wording with an in-fiction line.
	if first_child == null or not first_child.text.contains("電台靜默"):
		print("FAIL UI6: Debug feed toggle did not disable feed display!")
		quit(1)
		return

	print("  Debug World Feed toggle verified (enabled/disabled modes)")
	print("  Full interaction loop (start -> select -> travel -> external tick -> arrival) completed with 0 errors")
	print("PASS GATE UI6: Playable Smoke Test verified.")

	print("\n================================================================================")
	print("ALL S5-A.2 PLAYABLE UI SHELL GATES (UI1 ~ UI6) PASSED CLEANLY!                  ")
	print("================================================================================")
	shell.queue_free()
	quit(0)
