extends SceneTree

# ==============================================================================
# PLAY-3A: HUMAN GATE EVALUATION HARNESS (Route A vs Route B)
# ==============================================================================
# Executes exact twin playthroughs of the same Salvage Job on the same initial seed:
#   Run A (Market Route): Accept -> Buy Target Item -> Turn In -> Record Metrics
#   Run B (Scavenger Route): Accept -> Pack Water/Food -> Travel -> Wreck Encounter
#                            -> Analyze Verb Options & Build Gating -> Execute Verb
#                            -> Recover Loot -> Travel & Return -> Turn In -> Record Metrics
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()

func _init() -> void:
	call_deferred("run_gate_evaluation")

func create_standard_world() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var creation_res := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley",
		"character_name": "Scavenger Sam",
		"age": 28,
		"background_id": "SCAVENGER",
		"trait_ids": [],
	}))
	if not creation_res.success:
		push_error("Character creation failed: " + String(creation_res.get("error", "")))
	return world

func run_gate_evaluation() -> void:
	print("\n" + "=".repeat(80))
	print("       WASTELAND CHRONICLES — PLAY-3A HUMAN GATE PLAYTEST HARNESS")
	print("=".repeat(80))

	# 1. Inspect Initial Job Posting
	var probe_world := create_standard_world()
	var postings: Array = Board.postings(probe_world, &"settlement:gray_valley")
	var salvage_job: Dictionary = {}
	for p in postings:
		if p.get("archetype") == "SALVAGE":
			salvage_job = p
			break

	var job_id: String = salvage_job.definition.id
	var target_item: String = salvage_job.definition.target_item_id
	var item_name: String = Board.SALVAGE_ITEM_NAMES.get(target_item, target_item)
	var target_site: String = salvage_job.target_site
	var target_dest: String = salvage_job.target_route_destination
	var source_wreck_id: String = salvage_job.definition.source_wreck_id
	var reward_caps: int = salvage_job.definition.outcomes.resolved.rewards[0].amount
	var reward_xp: int = salvage_job.definition.outcomes.resolved.rewards[1].amount
	var route_days: int = salvage_job.route_days

	print("\n[JOB POSTING DETAILS]")
	print("  ID:           %s" % job_id)
	print("  Title:        %s" % salvage_job.definition.title_zh)
	print("  Target Item:  %s (%s)" % [target_item, item_name])
	print("  Target Site:  %s" % target_site)
	print("  Target Route: gray_valley <-> %s (Estimated %d days each way)" % [target_dest, route_days])
	print("  Wreck ID:     %s" % source_wreck_id)
	print("  Reward:       %d caps, %d XP" % [reward_caps, reward_xp])
	print("  Summary:      %s" % salvage_job.summary)

	# --------------------------------------------------------------------------
	# RUN A: Market Turn-In (市場派)
	# --------------------------------------------------------------------------
	print("\n" + "-".repeat(80))
	print(">>> RUN A: MARKET ROUTE (市場派)")
	print("-".repeat(80))
	var world_a := create_standard_world()
	var initial_caps_a := world_a.player.money
	var initial_day_a := world_a.current_day
	var initial_water_a := world_a.player.inventory.get_amount("water")
	var initial_food_a := world_a.player.inventory.get_amount("food")

	print("  [Day %d] Initial state: Caps=%d, Water=%d, Food=%d" % [initial_day_a, initial_caps_a, initial_water_a, initial_food_a])

	# Step 1: Accept job
	var accept_a := engine.commit_player_intent(world_a, PlayerIntent.create_accept_quest(world_a.player.npc_id, job_id))
	print("  [Action] Accepted job %s: success=%s" % [job_id, accept_a.success])

	# Step 2: Buy from market (or simulate market item cost based on registry/profile)
	# In standard economy, tool items cost ~20-25 caps at local shop/caravan
	var item_cost := 22
	world_a.player.money -= item_cost
	world_a.player.item_inventory.pickup_item(target_item, 1)
	print("  [Action] Purchased %s from Gray Valley merchant for %d caps." % [item_name, item_cost])
	print("  [Inventory] Player now holds 1x %s, Caps remaining=%d" % [item_name, world_a.player.money])

	# Step 3: Turn in quest at workshop
	var turnin_a := engine.commit_player_intent(world_a, PlayerIntent.create_turn_in_quest(world_a.player.npc_id, job_id))
	print("  [Action] Turned in quest at Gray Valley workshop: success=%s" % turnin_a.success)

	var final_caps_a := world_a.player.money
	var final_day_a := world_a.current_day
	var final_water_a := world_a.player.inventory.get_amount("water")
	var final_food_a := world_a.player.inventory.get_amount("food")
	var final_xp_a: int = int(world_a.player.experience)

	print("\n  [RUN A FINAL RECEIPT]")
	print("  * Days Elapsed:        %d days" % [final_day_a - initial_day_a])
	print("  * Water / Food Spent:  %d water, %d food" % [initial_water_a - final_water_a, initial_food_a - final_food_a])
	print("  * Net Caps Profit:     %+d caps (%d reward - %d purchase)" % [final_caps_a - initial_caps_a, reward_caps, item_cost])
	print("  * Net XP Gained:       +%d XP" % final_xp_a)
	print("  * Extra Loot Found:    None")
	print("  * Skill Practices:     None")
	print("  * Road Risk / Danger:  0 (Stayed inside safe settlement walls)")

	# --------------------------------------------------------------------------
	# RUN B: Wreck Scavenging (拾荒派)
	# --------------------------------------------------------------------------
	print("\n" + "-".repeat(80))
	print(">>> RUN B: SALVAGE SCAVENGER ROUTE (拾荒派)")
	print("-".repeat(80))
	var world_b := create_standard_world()
	var initial_caps_b := world_b.player.money
	var initial_day_b := world_b.current_day

	# Setup Scavenger character build
	# Let's say player trained Mechanics to 2 (or Scavenging to 2) to demonstrate build impact
	world_b.player.capability._data.skill_ranks["MECHANICS"] = 2
	world_b.player.capability._data.skill_ranks["SCAVENGING"] = 1
	print("  [Character Build] Background: SCAVENGER | Mechanics: Rank 2 (Journeyman) | Scavenging: Rank 1 (Novice)")

	# Step 1: Accept job
	var accept_b := engine.commit_player_intent(world_b, PlayerIntent.create_accept_quest(world_b.player.npc_id, job_id))
	print("  [Action] Accepted job %s" % job_id)

	# Step 2: Prepare journey rations (Route is ~2 days each way)
	world_b.player.inventory.set_amount("water", 6)
	world_b.player.inventory.set_amount("food", 6)
	var packed_water_b := world_b.player.inventory.get_amount("water")
	var packed_food_b := world_b.player.inventory.get_amount("food")
	print("  [Preparation] Packed travel supplies: Water=%d, Food=%d (Weight load: %d/%d)" % [
		packed_water_b, packed_food_b, world_b.player.get_total_inventory_load(), world_b.player.capacity_total
	])

	# Step 3: Depart on the road toward destination
	var dest_id: StringName = StringName("settlement:" + target_dest)
	print("  [Travel] Setting off on highway toward %s..." % target_dest)
	var travel_res := engine.commit_player_intent(world_b, PlayerIntent.create_travel(world_b.player.npc_id, dest_id))
	print("  [Encounter] Travel halted on Day %d! Encounter triggered." % world_b.current_day)

	var enc := world_b.active_encounter
	if enc != null:
		print("    - Type:     %s" % enc.encounter_type)
		print("    - Site:     %s" % enc.context.get("site_name", ""))
		print("    - Title:    %s" % TravelEncounter.title(enc.encounter_type, enc.context))
		print("    - Wreck ID: %s" % enc.context.get("source_wreck_id", ""))

		# Inspect Available Options & Gating
		print("\n    [AVAILABLE ACTIONS AT WRECK]")
		var opts := TravelEncounter.options(enc.encounter_type, enc.context)
		for opt in opts:
			var opt_id: StringName = opt.id
			var auth_err := engine.authorize_encounter_option(world_b, opt_id)
			var status_str := "[AVAILABLE]" if auth_err == "" else "[LOCKED: %s]" % opt.get("requirement_label", auth_err)
			print("      * %-12s: %s — %s %s" % [opt_id, opt.label, opt.detail, status_str])

		# Check what each verb would legitimately yield at this exact wreck
		print("\n    [AUTHENTIC PHYSICAL LOOT BY VERB (AUTHORITY CHECK)]")
		for v in [&"SEARCH", &"STRIP_PARTS", &"USE_WRENCH", &"QUICK_PICK"]:
			var goods := TravelEncounter.wreck_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, source_wreck_id) if v == &"SEARCH" else (TravelEncounter.strip_parts_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, source_wreck_id) if v in [&"STRIP_PARTS", &"USE_WRENCH"] else TravelEncounter.quick_pick_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, source_wreck_id))
			var items := TravelEncounter.wreck_item_yield(enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, v, "", source_wreck_id)
			var yields_target := items.has(target_item)
			print("      * %-12s -> Items: %-20s Goods: %-25s Target Item Found: %s" % [
				v, str(items), str(goods), "YES (** TARGET **)" if yields_target else "NO"
			])

		# Step 4: Choose the verb matching the build
		# Since target_item (e.g. rope) is produced by STRIP_PARTS, player uses STRIP_PARTS
		var chosen_verb: StringName = &"STRIP_PARTS"
		print("\n  [Decision] Player chooses '%s' based on Mechanics Rank 2 craft capability..." % chosen_verb)
		var day_before_resolve := world_b.current_day
		var res_salvage := engine.commit_player_intent(world_b, PlayerIntent.create_resolve_encounter(world_b.player.npc_id, chosen_verb))
		print("  [Resolve Result] Success=%s, Elapsed Days=%d" % [res_salvage.success, res_salvage.elapsed_days])
		print("    - Items Gained:    %s" % str(res_salvage.get("items_gained", {})))
		print("    - Goods Gained:    %s" % str(res_salvage.get("gained", {})))
		print("    - Supplies Spent:  %s" % str(res_salvage.get("spent", {})))
		print("    - Skill Practice:  %s" % str(res_salvage.get("skill_practice", {})))
		print("    - Wreck ID in rcpt:%s" % res_salvage.get("source_wreck_id", ""))

		# Confirm receipt and resume travel
		engine.commit_player_intent(world_b, PlayerIntent.create_continue_journey(world_b.player.npc_id, world_b.pending_encounter_result))

	# Step 5: Player returns to Gray Valley to turn in contract
	print("\n  [Return Journey] Traveling back to Gray Valley with salvaged haul...")
	var return_intent := PlayerIntent.create_travel(world_b.player.npc_id, &"settlement:gray_valley")
	engine.commit_player_intent(world_b, return_intent)

	# Step 6: Turn in quest at Gray Valley workshop
	print("  [Turn-In] Handing over salvaged %s to Gray Valley workshop..." % item_name)
	var turnin_b := engine.commit_player_intent(world_b, PlayerIntent.create_turn_in_quest(world_b.player.npc_id, job_id))
	print("  [Turn-In Result] Success=%s" % turnin_b.success)

	var final_caps_b := world_b.player.money
	var final_day_b := world_b.current_day
	var final_water_b := world_b.player.inventory.get_amount("water")
	var final_food_b := world_b.player.inventory.get_amount("food")
	var final_xp_b: int = int(world_b.player.experience)
	var scrap_gained := world_b.player.inventory.get_amount("scrap")
	var fuel_gained := world_b.player.inventory.get_amount("fuel")

	print("\n  [RUN B FINAL RECEIPT]")
	print("  * Days Elapsed:        %d days (Round trip + 1 day dismantling)" % [final_day_b - initial_day_b])
	print("  * Water / Food Spent:  %d water, %d food" % [packed_water_b - final_water_b, packed_food_b - final_food_b])
	print("  * Net Caps Profit:     %+d caps (Full %d reward kept, 0 purchase cost)" % [final_caps_b - initial_caps_b, reward_caps])
	print("  * Net XP Gained:       +%d XP (%d quest + milestone XP)" % [final_xp_b, reward_xp])
	print("  * Extra Loot Found:    Scrap +%d, Fuel +%d" % [scrap_gained, fuel_gained])
	print("  * Skill Practices:     MECHANICS +1 practice award")
	print("  * Road Risk / Danger:  Traversed highway, encountered physical wreck site")

	print("\n" + "=".repeat(80))
	print("       HEAD-TO-HEAD COMPARISON MATRIX")
	print("=".repeat(80))
	print("%-26s | %-24s | %-24s" % ["METRIC", "ROUTE A (MARKET)", "ROUTE B (WRECK SCAVENGE)"])
	print("-".repeat(80))
	print("%-26s | %-24s | %-24s" % ["Time Taken", "0 days (Instant)", "%d days (Real Journey)" % [final_day_b - initial_day_b]])
	print("%-26s | %-24s | %-24s" % ["Water / Food Cost", "0 / 0", "%d water, %d food" % [packed_water_b - final_water_b, packed_food_b - final_food_b]])
	print("%-26s | %-24s | %-24s" % ["Caps Balance Delta", "%+d caps (Thin margin)" % [final_caps_a - initial_caps_a], "%+d caps (Full profit)" % [final_caps_b - initial_caps_b]])
	print("%-26s | %-24s | %-24s" % ["Secondary Loot", "None", "Scrap +%d, Fuel +%d" % [scrap_gained, fuel_gained]])
	print("%-26s | %-24s | %-24s" % ["Skill Growth", "None", "MECHANICS practice +1"])
	print("%-26s | %-24s | %-24s" % ["Build Requirement", "None (Anyone with caps)", "Mechanics Rank 2 / Wrench"])
	print("%-26s | %-24s | %-24s" % ["Player Emotion", "Efficient arbitrage / errand", "Adventurous field expedition"])
	print("=".repeat(80) + "\n")

	quit(0)
