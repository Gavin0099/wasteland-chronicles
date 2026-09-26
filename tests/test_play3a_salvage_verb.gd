extends SceneTree

# ==============================================================================
# PLAY-3A: SALVAGE JOB VERB SUITE (PLAY-3A4 Source Integrity & Stable Site)
# ==============================================================================
# Verifies the 6 Hard Gates for the Salvage Job Verb loop:
#   Gate 1: Target Contract & Authentic Yield (source_wreck_id, real item from wreck)
#   Gate 2: Target Site Encounter Trigger & Pipeline Propagation (QUEST_ACCEPTED, TRAVEL_ENCOUNTER)
#   Gate 3: Build Differences & Verb Gating (SEARCH, STRIP_PARTS, QUICK_PICK, USE_WRENCH)
#   Gate 4: Canonical Cost & Zero Repeatable XP (QUICK_PICK 0 extra days vs SEARCH 1 day)
#   Gate 5: Physical Loot, Source Integrity & Capacity (no artificial injection, stable across days)
#   Gate 6: Dual Route Turn-in (Route A market vs Route B wreck, TRAVEL_ENCOUNTER_RESOLVED receipt)
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-3A FAIL: " + label)
	else:
		print("  PASS: " + label)

func _init() -> void:
	call_deferred("run")

func create_test_world(origin_id: String = "settlement:gray_valley") -> WorldState:
	var world := S1WorldData.create_s1_world()
	var creation_res := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin_id,
		"character_name": "Scavenger Sam",
		"age": 28,
		"background_id": "SCAVENGER",
		"trait_ids": [],
	}))
	if not creation_res.success:
		push_error("Failed character creation: " + String(creation_res.get("error", "")))
	return world

func run() -> void:
	print("\n================================================================================")
	print("      WASTELAND CHRONICLES - PLAY-3A SALVAGE JOB VERB SUITE")
	print("================================================================================")

	test_gate_1_target_contract()
	test_gate_2_encounter_trigger()
	test_gate_3_build_differences_and_verbs()
	test_gate_4_canonical_cost()
	test_gate_5_physical_loot_and_capacity()
	test_gate_6_dual_route_turn_in()

	print("================================================================================")
	if failures == 0:
		print("PLAY-3A SUITE PASSED ALL 6 GATES! assertions=%d, failures=0\n" % assertions)
		quit(0)
	else:
		print("PLAY-3A SUITE FAILED! assertions=%d, failures=%d\n" % [assertions, failures])
		quit(1)

# ── Gate 1: Target Contract & Authentic Yield ─────────────────────────────────
func test_gate_1_target_contract() -> void:
	print("\n--- [GATE 1] Target Contract & Authentic Yield ---")
	var world := create_test_world("settlement:gray_valley")
	var postings: Array = Board.postings(world, &"settlement:gray_valley")
	var salvage_entry: Dictionary = {}
	for p in postings:
		if p.get("archetype") == "SALVAGE":
			salvage_entry = p
			break

	check(not salvage_entry.is_empty(), "G1: Salvage job is posted on the board")
	check(salvage_entry.has("target_site") and String(salvage_entry.target_site) != "", "G1: Target site is generated and non-empty")
	check(salvage_entry.has("target_route_origin") and String(salvage_entry.target_route_origin) != "", "G1: Target route origin exists")
	check(salvage_entry.has("target_route_destination") and String(salvage_entry.target_route_destination) != "", "G1: Target route destination exists")
	check(int(salvage_entry.get("route_days", 0)) > 0, "G1: route_days is non-zero (reflects actual journey time)")
	check(salvage_entry.definition.description_zh.contains("買現成品交件") and salvage_entry.definition.description_zh.contains("親自搜刮"), "G1: Description explains buying and salvaging in player language")

	# Stable source_wreck_id checks
	check(salvage_entry.has("source_wreck_id") and String(salvage_entry.source_wreck_id) != "", "G1: Entry has non-empty source_wreck_id")
	check(salvage_entry.definition.has("source_wreck_id") and String(salvage_entry.definition.source_wreck_id) != "", "G1: Definition has non-empty source_wreck_id")
	var source_wreck_id: String = String(salvage_entry.source_wreck_id)
	check(source_wreck_id.begins_with("salvage:"), "G1: source_wreck_id follows salvage: namespace")

	# Authentic yield check: verify that target_item_id is legitimately produced by this wreck
	var target_item_id: String = String(salvage_entry.target_item_id)
	var dest_full := StringName("settlement:" + String(salvage_entry.target_route_destination))
	var authentic_verbs: Array[StringName] = []
	for v in [&"SEARCH", &"STRIP_PARTS", &"USE_WRENCH", &"QUICK_PICK"]:
		var y := TravelEncounter.wreck_item_yield(0, &"settlement:gray_valley", dest_full, 1, v, "", source_wreck_id)
		if y.has(target_item_id):
			authentic_verbs.append(v)
	check(not authentic_verbs.is_empty(), "G1: target_item_id is authentically yielded by source_wreck_id (%s via %s)" % [target_item_id, str(authentic_verbs)])

	# Check UI projection has target_site
	var proj := PlayerUIProjection.project(world)
	var projected_salvage: Dictionary = {}
	for q in proj.quests:
		if q.get("archetype") == "SALVAGE":
			projected_salvage = q
			break
	check(not projected_salvage.is_empty() and projected_salvage.get("target_site") != "", "G1: PlayerUiProjection projects target_site")

	# Check intelligence for capabilities
	var intel: Array = Board.intel_for(world, salvage_entry)
	check(typeof(intel) == TYPE_ARRAY, "G1: intel_for returns array")

# ── Gate 2: Target Site Encounter Trigger & Pipeline Propagation ───────────────
func test_gate_2_encounter_trigger() -> void:
	print("\n--- [GATE 2] Target Site Encounter Trigger & Pipeline Propagation ---")
	var world := create_test_world("settlement:gray_valley")
	var postings: Array = Board.postings(world, &"settlement:gray_valley")
	var salvage_entry: Dictionary = {}
	for p in postings:
		if p.get("archetype") == "SALVAGE":
			salvage_entry = p
			break

	var job_id: String = salvage_entry.definition.id
	var source_wreck_id: String = salvage_entry.definition.source_wreck_id
	var accept_res := engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job_id))
	check(accept_res.success, "G2: Player accepted salvage quest")

	# Check QUEST_ACCEPTED event payload has source_wreck_id
	var quest_accepted_evt: EventRecord = null
	for evt in world.event_log:
		if evt.type == "QUEST_ACCEPTED" and String(evt.payload.get("quest_id", "")) == job_id:
			quest_accepted_evt = evt
			break
	check(quest_accepted_evt != null, "G2: QUEST_ACCEPTED event found in log")
	if quest_accepted_evt != null:
		check(String(quest_accepted_evt.payload.get("source_wreck_id", "")) == source_wreck_id, "G2: QUEST_ACCEPTED payload contains correct source_wreck_id")

	var dest_id: StringName = StringName("settlement:" + String(salvage_entry.target_route_destination))
	world.player.inventory.set_amount("water", 5)
	world.player.inventory.set_amount("food", 5)

	# Travel initiates and halts at wreck
	var travel_intent := PlayerIntent.create_travel(world.player.npc_id, dest_id)
	var travel_res := engine.commit_player_intent(world, travel_intent)
	check(travel_res.success, "G2: Player started travel toward target route destination")

	check(world.active_encounter != null, "G2: Travel halted by active encounter")
	if world.active_encounter != null:
		check(world.active_encounter.encounter_type == TravelEncounter.WRECK, "G2: Encounter is WRECK")
		check(String(world.active_encounter.context.get("salvage_job_id", "")) == job_id, "G2: Encounter context binds salvage_job_id")
		check(String(world.active_encounter.context.get("source_wreck_id", "")) == source_wreck_id, "G2: Encounter context binds source_wreck_id")
		check(String(world.active_encounter.context.get("salvage_target_item", "")) != "", "G2: Encounter context binds salvage_target_item")
		check(TravelEncounter.title(world.active_encounter.encounter_type, world.active_encounter.context).contains("目標殘骸"), "G2: Title reflects target wreck")
		check(TravelEncounter.body(world.active_encounter.encounter_type, world.active_encounter.context).contains("這正是工棚通報的目標殘骸"), "G2: Body text confirms target wreck site")

	# Check TRAVEL_ENCOUNTER event payload contains source_wreck_id
	var travel_enc_evt: EventRecord = null
	for evt in world.event_log:
		if evt.type == "TRAVEL_ENCOUNTER":
			travel_enc_evt = evt
	check(travel_enc_evt != null, "G2: TRAVEL_ENCOUNTER event found in log")
	if travel_enc_evt != null:
		check(String(travel_enc_evt.payload.get("source_wreck_id", "")) == source_wreck_id, "G2: TRAVEL_ENCOUNTER event payload contains source_wreck_id")

# ── Gate 3: Build Differences & Real Verb Reuse ───────────────────────────────
func test_gate_3_build_differences_and_verbs() -> void:
	print("\n--- [GATE 3] Build Differences & Verb Gating ---")
	var world := create_test_world("settlement:gray_valley")

	world.active_encounter = TravelEncounterState.create(
		TravelEncounter.WRECK, world.current_day, &"settlement:gray_valley", &"settlement:dry_well", 0,
		{"salvage_job_id": "job_salvage_test", "salvage_target_item": "wrench", "site_name": "拋錨車輛", "source_wreck_id": "salvage:test:gv_dw:0"}
	)

	# Low ranks
	world.player.capability._data.skill_ranks["MECHANICS"] = 0
	world.player.capability._data.skill_ranks["SCAVENGING"] = 1
	var opts: Array = TravelEncounter.options(TravelEncounter.WRECK)
	var strip_opt: Dictionary = {}
	var quick_opt: Dictionary = {}
	for o in opts:
		if o.id == &"STRIP_PARTS":
			strip_opt = o
		elif o.id == &"QUICK_PICK":
			quick_opt = o

	check(not strip_opt.is_empty() and not quick_opt.is_empty(), "G3: WRECK options contain STRIP_PARTS and QUICK_PICK")
	check(engine.authorize_encounter_option(world, &"STRIP_PARTS") != "", "G3: Low MECHANICS correctly denied STRIP_PARTS")
	check(engine.authorize_encounter_option(world, &"QUICK_PICK") != "", "G3: Low SCAVENGING correctly denied QUICK_PICK")

	# Upgrade player capability
	world.player.capability._data.skill_ranks["MECHANICS"] = 2
	world.player.capability._data.skill_ranks["SCAVENGING"] = 2
	check(engine.authorize_encounter_option(world, &"STRIP_PARTS") == "", "G3: MECHANICS 2 authorizes STRIP_PARTS")
	check(engine.authorize_encounter_option(world, &"QUICK_PICK") == "", "G3: SCAVENGING 2 authorizes QUICK_PICK")

	# Without a wrench in inventory, USE_WRENCH is denied
	check(not world.player.item_inventory.contains("wrench", 1), "G3: Player initially has no wrench")
	check(engine.authorize_encounter_option(world, &"USE_WRENCH") != "", "G3: Missing wrench denies USE_WRENCH")

	# Give a wrench -> USE_WRENCH authorized
	world.player.item_inventory.pickup_item("wrench", 1)
	check(engine.authorize_encounter_option(world, &"USE_WRENCH") == "", "G3: Holding wrench authorizes USE_WRENCH")

# ── Gate 4: Canonical Time, Physiological Cost & Zero Repeatable XP ───────────
func test_gate_4_canonical_cost() -> void:
	print("\n--- [GATE 4] Canonical Cost & Zero Repeatable XP ---")
	# Case A: QUICK_PICK (costs 0 extra days)
	var world_a := create_test_world("settlement:gray_valley")
	world_a.player.capability._data.skill_ranks["SCAVENGING"] = 2
	world_a.player.inventory.set_amount("water", 5)
	world_a.player.inventory.set_amount("food", 5)

	var job_entry: Dictionary = Board.postings(world_a, &"settlement:gray_valley")[1] # salvage
	var job_id: String = job_entry.definition.id
	engine.commit_player_intent(world_a, PlayerIntent.create_accept_quest(world_a.player.npc_id, job_id))
	var dest_id: StringName = StringName("settlement:" + String(job_entry.target_route_destination))
	engine.commit_player_intent(world_a, PlayerIntent.create_travel(world_a.player.npc_id, dest_id))

	check(world_a.active_encounter != null, "G4: World A encounter active")
	var day_before := world_a.current_day

	# Resolve with QUICK_PICK
	var res_qp := engine.commit_player_intent(world_a, PlayerIntent.create_resolve_encounter(world_a.player.npc_id, &"QUICK_PICK"))
	check(res_qp.success, "G4: QUICK_PICK committed successfully")
	check(res_qp.cost_extra_day == false, "G4: QUICK_PICK does not cost extra travel day")
	check(world_a.current_day == day_before, "G4: QUICK_PICK day remains unchanged immediately")

	# Case B: SEARCH (costs 1 extra day via tick)
	var world_b := create_test_world("settlement:gray_valley")
	world_b.player.inventory.set_amount("water", 5)
	world_b.player.inventory.set_amount("food", 5)
	var job_b: Dictionary = Board.postings(world_b, &"settlement:gray_valley")[1]
	engine.commit_player_intent(world_b, PlayerIntent.create_accept_quest(world_b.player.npc_id, job_b.definition.id))
	var dest_b: StringName = StringName("settlement:" + String(job_b.target_route_destination))
	engine.commit_player_intent(world_b, PlayerIntent.create_travel(world_b.player.npc_id, dest_b))

	check(world_b.active_encounter != null, "G4: World B encounter active")
	var day_b_before := world_b.current_day
	var water_b_before := world_b.player.inventory.get_amount("water")
	var res_search := engine.commit_player_intent(world_b, PlayerIntent.create_resolve_encounter(world_b.player.npc_id, &"SEARCH"))
	check(res_search.success, "G4: SEARCH committed successfully")
	check(res_search.cost_extra_day == true, "G4: SEARCH costs 1 extra day")
	check(world_b.current_day == day_b_before + 1, "G4: SEARCH advanced world by exactly 1 day")
	check(world_b.player.inventory.get_amount("water") < water_b_before, "G4: SEARCH consumed water via canonical tick")

# ── Gate 5: Physical Loot, Source Integrity & Capacity ────────────────────────
func test_gate_5_physical_loot_and_capacity() -> void:
	print("\n--- [GATE 5] Physical Loot, Source Integrity & Capacity ---")
	var world := create_test_world("settlement:gray_valley")
	var job_entry: Dictionary = Board.postings(world, &"settlement:gray_valley")[1]
	var target_item: String = job_entry.definition.target_item_id
	var source_wreck_id: String = job_entry.definition.source_wreck_id
	var dest_full := StringName("settlement:" + String(job_entry.target_route_destination))

	# 1. Day Invariance Check: Verify that source_wreck_id produces identical yields regardless of day
	var yield_day_0 := TravelEncounter.wreck_item_yield(0, &"settlement:gray_valley", dest_full, 1, &"SEARCH", "", source_wreck_id)
	var yield_day_5 := TravelEncounter.wreck_item_yield(5, &"settlement:gray_valley", dest_full, 1, &"SEARCH", "", source_wreck_id)
	var yield_day_20 := TravelEncounter.wreck_item_yield(20, &"settlement:gray_valley", dest_full, 1, &"SEARCH", "", source_wreck_id)
	check(yield_day_0 == yield_day_5 and yield_day_5 == yield_day_20, "G5: Wreck yield is strictly invariant across different calendar days")

	# 2. Source Integrity & No Artificial Injection Check:
	# Find a verb that yields target_item and a verb that does NOT yield target_item
	var effective_verb: StringName = &""
	var ineffective_verb: StringName = &""
	for v in [&"SEARCH", &"STRIP_PARTS", &"USE_WRENCH", &"QUICK_PICK"]:
		var y := TravelEncounter.wreck_item_yield(0, &"settlement:gray_valley", dest_full, 1, v, "", source_wreck_id)
		if y.has(target_item):
			effective_verb = v
		else:
			ineffective_verb = v

	check(effective_verb != &"", "G5: At least one verb legitimately yields the target item (%s)" % effective_verb)

	# Test ineffective verb: if an ineffective verb exists, verify target_item is NOT injected!
	if ineffective_verb != &"":
		var world_ineff := create_test_world("settlement:gray_valley")
		world_ineff.player.capability._data.skill_ranks["MECHANICS"] = 2
		world_ineff.player.capability._data.skill_ranks["SCAVENGING"] = 2
		world_ineff.player.item_inventory.pickup_item("wrench", 1)
		world_ineff.active_encounter = TravelEncounterState.create(
			TravelEncounter.WRECK, world_ineff.current_day, &"settlement:gray_valley", dest_full, 0,
			{"salvage_job_id": job_entry.definition.id, "salvage_target_item": target_item, "site_name": "拋錨車輛", "source_wreck_id": source_wreck_id}
		)
		var res_ineff := engine.commit_player_intent(world_ineff, PlayerIntent.create_resolve_encounter(world_ineff.player.npc_id, ineffective_verb))
		check(res_ineff.success, "G5: Ineffective verb (%s) resolved" % ineffective_verb)
		var ineff_items: Dictionary = res_ineff.get("items_gained", {})
		check(not ineff_items.has(target_item), "G5: Target item is NOT artificially injected when using non-yielding verb (%s)" % ineffective_verb)

	# 3. Normal capacity with effective verb -> target item naturally picked up
	var world_eff := create_test_world("settlement:gray_valley")
	world_eff.player.capability._data.skill_ranks["MECHANICS"] = 2
	world_eff.player.capability._data.skill_ranks["SCAVENGING"] = 2
	world_eff.player.item_inventory.pickup_item("wrench", 1)
	world_eff.active_encounter = TravelEncounterState.create(
		TravelEncounter.WRECK, world_eff.current_day, &"settlement:gray_valley", dest_full, 0,
		{"salvage_job_id": job_entry.definition.id, "salvage_target_item": target_item, "site_name": "拋錨車輛", "source_wreck_id": source_wreck_id}
	)
	var res_normal := engine.commit_player_intent(world_eff, PlayerIntent.create_resolve_encounter(world_eff.player.npc_id, effective_verb))
	check(res_normal.success, "G5: Effective verb (%s) resolved" % effective_verb)
	check(res_normal.has("items_gained") and res_normal.items_gained.has(target_item), "G5: Target item gained via effective verb when capacity allows")
	check(world_eff.player.item_inventory.contains(target_item, 1), "G5: Target item in player inventory")

	# 4. Over capacity test: fill player inventory to max weight
	var world_full := create_test_world("settlement:gray_valley")
	world_full.player.capability._data.skill_ranks["MECHANICS"] = 2
	world_full.player.capability._data.skill_ranks["SCAVENGING"] = 2
	world_full.player.item_inventory.pickup_item("wrench", 1)
	world_full.active_encounter = TravelEncounterState.create(
		TravelEncounter.WRECK, world_full.current_day, &"settlement:gray_valley", dest_full, 0,
		{"salvage_job_id": job_entry.definition.id, "salvage_target_item": target_item, "site_name": "拋錨車輛", "source_wreck_id": source_wreck_id}
	)
	world_full.player.item_inventory._quantities["military_backpack"] = 5 # 12000g
	var res_full := engine.commit_player_intent(world_full, PlayerIntent.create_resolve_encounter(world_full.player.npc_id, effective_verb))
	check(res_full.success, "G5: Effective verb resolved while full")
	check(res_full.has("items_left_behind") and res_full.items_left_behind.has(target_item), "G5: When full, target item drops to items_left_behind")

# ── Gate 6: Dual Route Turn-in & Receipt Invariants ───────────────────────────
func test_gate_6_dual_route_turn_in() -> void:
	print("\n--- [GATE 6] Dual Route Turn-in & Ledger Invariants ---")

	# Sub-gate 6A: Route A (Market Purchase Turn-in)
	var world_a := create_test_world("settlement:gray_valley")
	var job_a: Dictionary = Board.postings(world_a, &"settlement:gray_valley")[1]
	var job_id_a: String = job_a.definition.id
	var item_a: String = job_a.definition.target_item_id

	check(engine.commit_player_intent(world_a, PlayerIntent.create_accept_quest(world_a.player.npc_id, job_id_a)).success, "G6A: Accepted job A")
	world_a.player.item_inventory.pickup_item(item_a, 1)
	var turnin_a := engine.commit_player_intent(world_a, PlayerIntent.create_turn_in_quest(world_a.player.npc_id, job_id_a))
	check(turnin_a.success, "G6A: Route A turn-in succeeds with market-bought item")
	check(not world_a.player.item_inventory.contains(item_a, 1), "G6A: Item deducted from inventory")

	# Sub-gate 6B: Route B (Wreck Salvage Turn-in)
	var world_b := create_test_world("settlement:gray_valley")
	var job_b: Dictionary = Board.postings(world_b, &"settlement:gray_valley")[1]
	var job_id_b: String = job_b.definition.id
	var item_b: String = job_b.definition.target_item_id
	var source_wreck_id_b: String = job_b.definition.source_wreck_id
	var dest_full_b := StringName("settlement:" + String(job_b.target_route_destination))

	check(engine.commit_player_intent(world_b, PlayerIntent.create_accept_quest(world_b.player.npc_id, job_id_b)).success, "G6B: Accepted job B")

	# Find effective verb for this wreck
	var eff_verb: StringName = &"SEARCH"
	for v in [&"SEARCH", &"STRIP_PARTS", &"USE_WRENCH", &"QUICK_PICK"]:
		var y := TravelEncounter.wreck_item_yield(0, &"settlement:gray_valley", dest_full_b, 1, v, "", source_wreck_id_b)
		if y.has(item_b):
			eff_verb = v
			break

	# Configure skills to permit eff_verb
	world_b.player.capability._data.skill_ranks["MECHANICS"] = 2
	world_b.player.capability._data.skill_ranks["SCAVENGING"] = 2
	world_b.player.item_inventory.pickup_item("wrench", 1)

	world_b.active_encounter = TravelEncounterState.create(
		TravelEncounter.WRECK, world_b.current_day, &"settlement:gray_valley", dest_full_b, 0,
		{"salvage_job_id": job_id_b, "salvage_target_item": item_b, "site_name": "拋錨車輛", "source_wreck_id": source_wreck_id_b}
	)
	var res_salvage := engine.commit_player_intent(world_b, PlayerIntent.create_resolve_encounter(world_b.player.npc_id, eff_verb))
	check(res_salvage.success, "G6B: Salvaged wreck via %s" % eff_verb)
	check(res_salvage.get("source_wreck_id", "") == source_wreck_id_b, "G6B: Encounter receipt includes source_wreck_id")
	check(res_salvage.items_gained.has(item_b), "G6B: Recovered item from wreck")
	check(world_b.player.item_inventory.contains(item_b, 1), "G6B: Item currently in inventory")

	# Confirm encounter receipt
	var confirm_res := engine.commit_player_intent(world_b, PlayerIntent.create_continue_journey(world_b.player.npc_id, world_b.pending_encounter_result))
	check(confirm_res.success, "G6B: Confirmed encounter receipt")

	# Turn in at issuing workshop
	var turnin_b := engine.commit_player_intent(world_b, PlayerIntent.create_turn_in_quest(world_b.player.npc_id, job_id_b))
	check(turnin_b.success, "G6B: Route B turn-in succeeds with salvaged item")
	check(not world_b.player.item_inventory.contains(item_b, 1), "G6B: Salvaged item deducted from inventory")

	# Verify Board cleanup and Event log
	var proj := PlayerUIProjection.project(world_b)
	for q in proj.quests:
		check(q.id != job_id_b, "G6B: Settled job removed from board")

	var event_found := false
	for evt in world_b.event_log:
		if evt.type == "QUEST_RESOLVED" and String(evt.payload.get("quest_id", "")) == job_id_b:
			event_found = true
			break
	check(event_found, "G6B: QUEST_RESOLVED event recorded in event log")

	# Verify TRAVEL_ENCOUNTER_RESOLVED event payload has source_wreck_id
	var resolved_evt: EventRecord = null
	for evt in world_b.event_log:
		if evt.type == "TRAVEL_ENCOUNTER_RESOLVED" and String(evt.payload.get("salvage_job_id", "")) == job_id_b:
			resolved_evt = evt
			break
	check(resolved_evt != null and String(resolved_evt.payload.get("source_wreck_id", "")) == source_wreck_id_b, "G6B: TRAVEL_ENCOUNTER_RESOLVED payload has source_wreck_id")

	check(engine.validate_invariants(world_b) == "", "G6B: All simulation invariants hold")
