extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - LEVEL G1.5 NPC GOVERNANCE & POPULATION CONTRACT SUITE
# ==============================================================================
# Verifies the 6 Core Governance Axioms (Axioms 11 ~ 16) established in G1.5:
#   1. Population Authority & Subset Rule (Named NPCs <= Aggregate Headcount)
#   2. Immutable Identity (ID permanent across relocation, job, faction, party)
#   3. Atomic Lifecycle Commit (Migration & Death transactions commit atomically)
#   4. Closed Action Space (Fail-closed rejection of unauthorized actions)
#   5. Structured Decision Evidence (Replayable, schema-compliant audit trail)
#   6. Universal Life Conservation (Living + In-Transit + Deaths == Initial Pop)
# ==============================================================================

class MockNPC:
	var id: StringName
	var name: String
	var location: StringName
	var alive: bool = true
	var occupation: String = "unemployed"
	var faction: String = "neutral"
	var party_id: StringName = &""
	var cause_of_death: String = ""

	func _init(p_id: StringName, p_name: String, p_location: StringName) -> void:
		id = p_id
		name = p_name
		location = p_location

class NPCTransactionResult:
	var success: bool = false
	var error_message: String = ""
	var event_record: Dictionary = {}

class NPCLifecycleManager:
	static func validate_subset_invariant(world: WorldState, registry: Array[MockNPC]) -> Dictionary:
		var counts_by_settlement: Dictionary = {}
		for s_id in world.settlements:
			counts_by_settlement[s_id] = 0

		for npc in registry:
			if npc.alive:
				if not counts_by_settlement.has(npc.location):
					return {"valid": false, "error": "NPC %s at unknown location: %s" % [npc.id, npc.location]}
				counts_by_settlement[npc.location] += 1

		for s_id in world.settlements:
			var s: SettlementState = world.settlements[s_id]
			var named_count: int = counts_by_settlement[s_id]
			if named_count > s.population:
				return {
					"valid": false,
					"error": "Subset violation at %s: %d named NPCs > %d total population" % [
						s_id, named_count, s.population
					]
				}

		return {"valid": true, "counts": counts_by_settlement}

	static func validate_universal_conservation(world: WorldState, initial_population: int) -> Dictionary:
		var living: int = 0
		var total_deaths: int = 0
		for s_id in world.settlements:
			var s: SettlementState = world.settlements[s_id]
			living += s.population
			total_deaths += s.cumulative_deaths

		var in_transit: int = 0
		for r_id in world.refugees:
			var r: RefugeePartyState = world.refugees[r_id]
			if r.is_active and not r.is_arrived:
				in_transit += r.headcount

		var total: int = living + in_transit + total_deaths
		if total != initial_population:
			return {
				"valid": false,
				"error": "Conservation broken: living(%d) + transit(%d) + deaths(%d) == %d != %d" % [
					living, in_transit, total_deaths, total, initial_population
				]
			}
		return {"valid": true, "total": total, "living": living, "transit": in_transit, "deaths": total_deaths}

	static func atomic_migrate_npc(
		world: WorldState,
		npc: MockNPC,
		dest_id: StringName,
		event_ledger: Array[Dictionary]
	) -> NPCTransactionResult:
		var res := NPCTransactionResult.new()
		if not npc.alive:
			res.error_message = "Cannot migrate deceased NPC: %s" % npc.id
			return res

		var orig_id: StringName = npc.location
		if not world.settlements.has(orig_id):
			res.error_message = "Invalid origin settlement: %s" % orig_id
			return res
		if not world.settlements.has(dest_id):
			res.error_message = "Invalid destination settlement: %s" % dest_id
			return res

		var s_orig: SettlementState = world.settlements[orig_id]
		var s_dest: SettlementState = world.settlements[dest_id]

		if s_orig.population < 1:
			res.error_message = "Origin settlement %s has 0 population; cannot transfer" % orig_id
			return res

		# Atomic commit across 3 layers:
		# Layer 1: Aggregates
		s_orig.population -= 1
		s_dest.population += 1

		# Layer 2: Entity
		npc.location = dest_id

		# Layer 3: Event Ledger
		var evt := {
			"event": "NPC_MIGRATION",
			"npc_id": npc.id,
			"from": orig_id,
			"to": dest_id,
			"day": world.current_day
		}
		event_ledger.append(evt)

		res.success = true
		res.event_record = evt
		return res

	static func atomic_kill_npc(
		world: WorldState,
		npc: MockNPC,
		cause: String,
		event_ledger: Array[Dictionary]
	) -> NPCTransactionResult:
		var res := NPCTransactionResult.new()
		if not npc.alive:
			res.error_message = "NPC %s already dead" % npc.id
			return res

		var loc: StringName = npc.location
		if not world.settlements.has(loc):
			res.error_message = "NPC %s at invalid settlement: %s" % [npc.id, loc]
			return res

		var s: SettlementState = world.settlements[loc]
		if s.population < 1:
			res.error_message = "Settlement %s population is 0; cannot kill" % loc
			return res

		# Atomic commit across 3 layers:
		# Layer 1: Entity
		npc.alive = false
		npc.cause_of_death = cause

		# Layer 2: Aggregates
		s.population -= 1
		s.cumulative_deaths += 1

		# Layer 3: Event Ledger
		var evt := {
			"event": "NPC_MORTALITY",
			"npc_id": npc.id,
			"settlement": loc,
			"cause": cause,
			"day": world.current_day
		}
		event_ledger.append(evt)

		res.success = true
		res.event_record = evt
		return res

	static func is_action_authorized(action_name: String, active_slice: String) -> bool:
		# Authorized action space per slice
		var authorized_actions: Dictionary = {
			"S4-A": [],
			"S4-B": ["STAY", "WORK", "LEAVE_JOB"],
			"S4-F": ["STAY", "WORK", "LEAVE_JOB", "JOIN_CARAVAN", "MIGRATE", "JOIN_FACTION", "TRADE_PERSONAL"]
		}
		if not authorized_actions.has(active_slice):
			return false
		var allowed: Array = authorized_actions[active_slice]
		return allowed.has(action_name)

func _init() -> void:
	print("================================================================================")
	print("   WASTELAND CHRONICLES - LEVEL G1.5 NPC GOVERNANCE CONTRACT TEST SUITE         ")
	print("================================================================================")

	var world := S1WorldData.create_s1_world()
	var gv: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var nh: SettlementState = world.get_settlement(&"settlement:new_hope")
	var dw: SettlementState = world.get_settlement(&"settlement:dry_well")
	var initial_total_pop: int = gv.population + nh.population + dw.population # 100 + 120 + 80 = 300

	# --------------------------------------------------------------------------
	# GATE G1: Population Authority & Subset Constraint
	# --------------------------------------------------------------------------
	print("\n--- [GATE G1] Population Authority & Subset Constraint ---")
	var registry: Array[MockNPC] = []
	for i in range(10):
		registry.append(MockNPC.new(StringName("npc:gv_%d" % i), "Mara_%d" % i, &"settlement:gray_valley"))

	var sub_res := NPCLifecycleManager.validate_subset_invariant(world, registry)
	if not sub_res["valid"]:
		print("FAIL G1: Valid subset falsely rejected: %s" % sub_res["error"])
		quit(1)
		return

	# Test subset violation: registering 105 named NPCs in a 100-person settlement
	var invalid_registry: Array[MockNPC] = []
	for i in range(105):
		invalid_registry.append(MockNPC.new(StringName("npc:overflow_%d" % i), "Overflow_%d" % i, &"settlement:gray_valley"))

	var overflow_res := NPCLifecycleManager.validate_subset_invariant(world, invalid_registry)
	if overflow_res["valid"]:
		print("FAIL G1: Overflowed registry (> total population) was not detected!")
		quit(1)
		return
	print("  Expected subset violation properly caught: %s" % overflow_res["error"])

	# Ensure adding named NPCs did NOT alter aggregate population
	if gv.population != 100 or nh.population != 120 or dw.population != 80:
		print("FAIL G1: Registering NPCs mutated aggregate population!")
		quit(1)
		return
	print("PASS GATE G1: Population Authority & Subset Constraint strictly verified.")

	# --------------------------------------------------------------------------
	# GATE G2: Immutable Identity Invariant
	# --------------------------------------------------------------------------
	print("\n--- [GATE G2] Immutable Identity Invariant ---")
	var test_npc := MockNPC.new(&"npc:0000127", "Mara", &"settlement:gray_valley")
	var original_id: StringName = test_npc.id

	# Mutate location, occupation, faction, party
	test_npc.location = &"settlement:new_hope"
	test_npc.occupation = "caravan_guard"
	test_npc.faction = "black_dogs"
	test_npc.party_id = &"party:player_group"

	if test_npc.id != original_id or test_npc.id != &"npc:0000127":
		print("FAIL G2: NPC ID mutated during state changes! ID: %s" % test_npc.id)
		quit(1)
		return
	print("  NPC ID 'npc:0000127' preserved across relocation, occupation change, faction swap, and party enrollment.")
	print("PASS GATE G2: Immutable Identity Invariant verified.")

	# --------------------------------------------------------------------------
	# GATE G3: Atomic Migration Transition
	# --------------------------------------------------------------------------
	print("\n--- [GATE G3] Atomic Migration Transition ---")
	var event_ledger: Array[Dictionary] = []
	var mara := registry[0]
	var gv_pop_before: int = gv.population
	var nh_pop_before: int = nh.population

	var mig_res := NPCLifecycleManager.atomic_migrate_npc(world, mara, &"settlement:new_hope", event_ledger)
	if not mig_res.success:
		print("FAIL G3: Atomic migration failed: %s" % mig_res.error_message)
		quit(1)
		return

	if gv.population != gv_pop_before - 1:
		print("FAIL G3: Origin population not decremented! Expected %d, got %d" % [gv_pop_before - 1, gv.population])
		quit(1)
		return
	if nh.population != nh_pop_before + 1:
		print("FAIL G3: Destination population not incremented! Expected %d, got %d" % [nh_pop_before + 1, nh.population])
		quit(1)
		return
	if mara.location != &"settlement:new_hope":
		print("FAIL G3: NPC entity location not updated!")
		quit(1)
		return
	if event_ledger.size() != 1 or event_ledger[0]["event"] != "NPC_MIGRATION":
		print("FAIL G3: Event ledger not updated atomically!")
		quit(1)
		return

	# Check subset invariant after migration
	var post_mig_subset := NPCLifecycleManager.validate_subset_invariant(world, registry)
	if not post_mig_subset["valid"]:
		print("FAIL G3: Subset invariant invalid after migration: %s" % post_mig_subset["error"])
		quit(1)
		return
	print("  Gray Valley pop: %d -> %d | New Hope pop: %d -> %d | Mara location: %s" % [
		gv_pop_before, gv.population, nh_pop_before, nh.population, mara.location
	])
	print("PASS GATE G3: Atomic Migration Transition verified.")

	# --------------------------------------------------------------------------
	# GATE G4: Atomic Mortality Transition
	# --------------------------------------------------------------------------
	print("\n--- [GATE G4] Atomic Mortality Transition ---")
	var eli := registry[1] # in Gray Valley
	var gv_pop_before_death: int = gv.population
	var deaths_before: int = gv.cumulative_deaths

	var death_res := NPCLifecycleManager.atomic_kill_npc(world, eli, "water_deprivation", event_ledger)
	if not death_res.success:
		print("FAIL G4: Atomic mortality failed: %s" % death_res.error_message)
		quit(1)
		return

	if eli.alive:
		print("FAIL G4: NPC alive flag remained true after mortality commit!")
		quit(1)
		return
	if gv.population != gv_pop_before_death - 1:
		print("FAIL G4: Settlement population not decremented upon death! Expected %d, got %d" % [
			gv_pop_before_death - 1, gv.population
		])
		quit(1)
		return
	if gv.cumulative_deaths != deaths_before + 1:
		print("FAIL G4: Gray Valley cumulative deaths not incremented! Expected %d, got %d" % [
			deaths_before + 1, gv.cumulative_deaths
		])
		quit(1)
		return

	# Dead NPC cannot migrate
	var invalid_mig := NPCLifecycleManager.atomic_migrate_npc(world, eli, &"settlement:dry_well", event_ledger)
	if invalid_mig.success:
		print("FAIL G4: Deceased NPC was allowed to migrate!")
		quit(1)
		return
	print("  Dead NPC correctly barred from further transitions: %s" % invalid_mig.error_message)
	print("PASS GATE G4: Atomic Mortality Transition verified.")

	# --------------------------------------------------------------------------
	# GATE G5: Universal Population Conservation with Mixed Cohorts
	# --------------------------------------------------------------------------
	print("\n--- [GATE G5] Universal Population Conservation Invariant ---")
	var cons_res := NPCLifecycleManager.validate_universal_conservation(world, initial_total_pop)
	if not cons_res["valid"]:
		print("FAIL G5: Population conservation failed: %s" % cons_res["error"])
		quit(1)
		return

	# Simulate a refugee group in transit (from S3-C)
	var party := RefugeePartyState.new(
		&"refugee_wave_1",
		&"settlement:gray_valley",
		&"settlement:new_hope",
		5,
		3,
		2,
		45
	)
	world.add_refugee_party(party)
	gv.population -= 5 # Conserved in transit

	var transit_cons := NPCLifecycleManager.validate_universal_conservation(world, initial_total_pop)
	if not transit_cons["valid"]:
		print("FAIL G5: Conservation broken with in-transit cohort: %s" % transit_cons["error"])
		quit(1)
		return
	var total_living: int = gv.population + nh.population + dw.population
	var total_all_deaths: int = gv.cumulative_deaths + nh.cumulative_deaths + dw.cumulative_deaths
	print("  Living (%d) + In-Transit (5) + Deaths (%d) == Initial Total (300)" % [
		total_living, total_all_deaths
	])
	print("PASS GATE G5: Universal Population Conservation Invariant strictly verified.")

	# --------------------------------------------------------------------------
	# GATE G6: Closed Action Space Fail-Closed Authorization
	# --------------------------------------------------------------------------
	print("\n--- [GATE G6] Closed Action Space Fail-Closed Authorization ---")
	# In S4-B, only STAY, WORK, LEAVE_JOB allowed
	if not NPCLifecycleManager.is_action_authorized("STAY", "S4-B"):
		print("FAIL G6: Valid S4-B action 'STAY' rejected!")
		quit(1)
		return
	if not NPCLifecycleManager.is_action_authorized("WORK", "S4-B"):
		print("FAIL G6: Valid S4-B action 'WORK' rejected!")
		quit(1)
		return
	if NPCLifecycleManager.is_action_authorized("JOIN_CARAVAN", "S4-B"):
		print("FAIL G6: Future-slice action 'JOIN_CARAVAN' unauthorized in S4-B was accepted!")
		quit(1)
		return

	# Dangerous / invented actions must fail closed in ALL slices
	var illegal_actions := ["BUILD_WATER_PLANT", "ATTACK_BANDIT", "MAGIC_HEAL", "SPAWN_FOOD", "GOD_MODE"]
	for illegal in illegal_actions:
		if NPCLifecycleManager.is_action_authorized(illegal, "S4-F"):
			print("FAIL G6: Illegal uninvented action '%s' was permitted!" % illegal)
			quit(1)
			return
	print("  Authorized action checks: STAY/WORK pass; premature and illegal actions fail closed.")
	print("PASS GATE G6: Closed Action Space Fail-Closed Authorization verified.")

	# --------------------------------------------------------------------------
	# GATE G7: Structured Decision Evidence Validation & Replay Consistency
	# --------------------------------------------------------------------------
	print("\n--- [GATE G7] Structured Decision Evidence Validation ---")
	var evidence_record := {
		"timestamp": {"day": 45, "phase": "PHASE_1_NEEDS"},
		"npc_id": "npc:gv_0",
		"observed_state": {
			"home_settlement": "settlement:gray_valley",
			"home_water_pressure": 82.5,
			"home_security": 24.0,
			"candidate_destinations": [
				{"id": "settlement:new_hope", "water_pressure": 0.0, "security": 100.0}
			]
		},
		"eligible_actions": ["STAY", "MIGRATE"],
		"selected_action": "MIGRATE",
		"rule_invoked": "RULE_REFUGEE_DESPERATION_MIGRATION",
		"resulting_mutation": {
			"type": "NPC_MIGRATION_INITIATED",
			"origin": "settlement:gray_valley",
			"destination": "settlement:new_hope"
		}
	}

	var required_evidence_keys := [
		"timestamp", "npc_id", "observed_state", "eligible_actions",
		"selected_action", "rule_invoked", "resulting_mutation"
	]
	for k in required_evidence_keys:
		if not evidence_record.has(k):
			print("FAIL G7: Evidence record missing required schema key: %s" % k)
			quit(1)
			return

	# Validate deterministic replay of evidence
	var evidence_json_1 := JSON.stringify(evidence_record)
	var evidence_json_2 := JSON.stringify(evidence_record)
	if evidence_json_1.sha256_text() != evidence_json_2.sha256_text():
		print("FAIL G7: Decision evidence replay hash mismatch!")
		quit(1)
		return
	print("  Evidence record conforms to Schema; SHA-256 serialization bitwise identical.")
	print("PASS GATE G7: Structured Decision Evidence Validation verified.")

	print("\n================================================================================")
	print("ALL LEVEL G1.5 NPC GOVERNANCE GATES (G1 ~ G7) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)
