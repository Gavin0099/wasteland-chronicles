extends SceneTree

# ==============================================================================
# WASTELAND CHRONICLES - S4-C.1 EVENT LEDGER PERSISTENCE TEST SUITE
# ==============================================================================
# Verifies 6 Hard Gates (L1 ~ L6):
#   L1: Non-empty Round-trip   (a world that really has events keeps them)
#   L2: Ordering Preservation  (commit order survives; never re-sorted)
#   L3: Payload Fidelity       (nested arrays/dicts/scalars survive intact)
#   L4: Single Authority       (events authoritative; bad event_count fails closed)
#   L5: Deterministic Replay   (same inputs -> same serialized ledger SHA)
#   L6: Independent Verification + Regression
#
# THE ONE SENTENCE THIS SLICE LOCKS DOWN:
#   世界發生過的事情，不會因為 Save / Load 而被世界忘記。
# ==============================================================================

func _init() -> void:
	print("================================================================================")
	print("      WASTELAND CHRONICLES - S4-C.1 EVENT LEDGER PERSISTENCE TEST SUITE         ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	# GATE L1: Non-empty Round-trip
	# --------------------------------------------------------------------------
	print("\n--- [GATE L1] Non-empty Round-trip ---")

	var world := build_eventful_world()
	var types_present := {}
	for evt in world.event_log:
		types_present[evt.type] = true

	if world.get_event_count() == 0:
		print("FAIL L1: fixture world produced no events — the gate would be vacuous!")
		quit(1)
		return
	print("  Fixture world produced %d committed events across %d distinct types" % [
		world.get_event_count(), types_present.size()
	])

	# The gate is only meaningful if genuinely varied history is present.
	for required in ["CARAVAN_ARRIVED", "REFUGEES_DEPARTED", "SETTLEMENT_MORTALITY"]:
		if not types_present.has(required):
			print("FAIL L1: fixture lacks a %s event — history is not representative!" % required)
			print("    present: %s" % str(types_present.keys()))
			quit(1)
			return
	print("  Required event types present: CARAVAN_ARRIVED, REFUGEES_DEPARTED, SETTLEMENT_MORTALITY")

	# World -> to_dict() -> JSON text -> parse -> from_dict()
	var json_text := JSON.stringify(world.to_dict(), "\t", true)
	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		print("FAIL L1: snapshot JSON did not parse back into an object!")
		quit(1)
		return
	var loaded := WorldState.from_dict(parsed)
	if loaded == null:
		print("FAIL L1: loader refused a snapshot it had just produced!")
		quit(1)
		return

	if loaded.get_event_count() != world.get_event_count():
		print("FAIL L1: ledger size changed across the round-trip: %d -> %d" % [
			world.get_event_count(), loaded.get_event_count()
		])
		quit(1)
		return
	print("  Through JSON text and back: %d events in, %d events out" % [
		world.get_event_count(), loaded.get_event_count()
	])

	var original_ledger := JSON.stringify(ledger_of(world), "\t", true)
	var loaded_ledger := JSON.stringify(ledger_of(loaded), "\t", true)
	if original_ledger != loaded_ledger:
		print("FAIL L1: serialized ledger differs after round-trip!")
		quit(1)
		return
	print("  Serialized ledger byte-identical: %s" % original_ledger.sha256_text())

	# Idempotence: for the LEDGER, save -> load -> save must be a FIXED POINT,
	# not merely "equivalent". Otherwise every load/save cycle rewrites recorded
	# history, and an audit of a reloaded save would disagree with the original.
	var reloaded_twice := WorldState.from_dict(JSON.parse_string(JSON.stringify(loaded.to_dict())))
	if reloaded_twice == null:
		print("FAIL L1: second load was refused!")
		quit(1)
		return
	if JSON.stringify(ledger_of(reloaded_twice), "\t", true) != original_ledger:
		print("FAIL L1: ledger is not a fixed point - history rewrites itself on each save/load!")
		quit(1)
		return
	print("  Ledger save -> load -> save is a fixed point (identical across two cycles)")

	# SCOPE NOTE - finding NON_LEDGER_STATE_NOT_ROUNDTRIPPED (recorded in milestones.md):
	# The WHOLE snapshot is not yet a fixed point, for reasons outside this slice.
	# Settlement credit dictionaries (production_credits, disorder_loss_credits,
	# cumulative_disorder_loss, last_need_outcomes) are stored as raw Dictionaries
	# whose int values widen to float on reload, and very small floats lose
	# precision through JSON. Those are settlement-state serialization defects, not
	# event-ledger defects. S4-C.1 asserts the ledger claim it actually proves, and
	# records the rest as a separate finding rather than quietly absorbing it.
	print("PASS GATE L1: Non-empty Round-trip verified.")

	# --------------------------------------------------------------------------
	# GATE L2: Ordering Preservation
	# --------------------------------------------------------------------------
	print("\n--- [GATE L2] Ordering Preservation ---")

	# Order must be COMMIT order, and must survive an order that canonical
	# key-sorting would happily rearrange if it were ever applied to the ledger.
	var ordered := WorldState.new()
	ordered.record_event(EventRecord.new(9, "ZULU_EVENT", &"actor:z", &"target:z", {"seq": 1}))
	ordered.record_event(EventRecord.new(3, "ALPHA_EVENT", &"actor:a", &"target:a", {"seq": 2}))
	ordered.record_event(EventRecord.new(7, "MIKE_EVENT", &"actor:m", &"target:m", {"seq": 3}))

	var ordered_loaded := WorldState.from_dict(JSON.parse_string(JSON.stringify(ordered.to_dict())))
	if ordered_loaded == null:
		print("FAIL L2: loader refused the ordering fixture!")
		quit(1)
		return

	var expected_types := ["ZULU_EVENT", "ALPHA_EVENT", "MIKE_EVENT"]
	var actual_types := []
	for evt in ordered_loaded.event_log:
		actual_types.append(evt.type)
	if actual_types != expected_types:
		print("FAIL L2: ledger was re-ordered! expected %s got %s" % [str(expected_types), str(actual_types)])
		quit(1)
		return
	print("  Commit order Z, A, M survives load as Z, A, M (not alphabetized)")

	# Days are also out of order on purpose: the ledger is not sorted by day either.
	var days := []
	for evt in ordered_loaded.event_log:
		days.append(evt.day)
	if days != [9, 3, 7]:
		print("FAIL L2: ledger was sorted by day! got %s" % str(days))
		quit(1)
		return
	print("  Days 9, 3, 7 survive unsorted (canonical key ordering != event ordering)")

	# And the real, long fixture ledger keeps its order too.
	for i in range(world.event_log.size()):
		if world.event_log[i].type != loaded.event_log[i].type:
			print("FAIL L2: fixture ledger order broke at index %d" % i)
			quit(1)
			return
		if world.event_log[i].day != loaded.event_log[i].day:
			print("FAIL L2: fixture ledger day mismatch at index %d" % i)
			quit(1)
			return
	print("  All %d fixture events preserved positionally" % world.event_log.size())
	print("PASS GATE L2: Ordering Preservation verified.")

	# --------------------------------------------------------------------------
	# GATE L3: Payload Fidelity
	# --------------------------------------------------------------------------
	print("\n--- [GATE L3] Payload Fidelity ---")

	var nested := WorldState.new()
	var rich_payload := {
		"causes": ["water", "food"],
		"loss": {
			"scrap": 4,
			"fuel": 2,
		},
		"risk": 50.0,
		"flag": true,
		"absent": null,
		"note": "low_security",
		"deep": {
			"level_two": {
				"level_three": [1, 2, {"inner": "value"}],
			},
		},
		"empty_list": [],
		"empty_map": {},
	}
	nested.record_event(EventRecord.new(12, "RICH_PAYLOAD", &"actor:x", &"target:y", rich_payload))

	var nested_loaded := WorldState.from_dict(JSON.parse_string(JSON.stringify(nested.to_dict())))
	if nested_loaded == null:
		print("FAIL L3: loader refused the payload fixture!")
		quit(1)
		return
	var before: Dictionary = nested.event_log[0].payload
	var after: Dictionary = nested_loaded.event_log[0].payload

	if not before.recursive_equal(after, 32):
		print("FAIL L3: payload changed across the round-trip!")
		print("  before: %s" % str(before))
		print("  after:  %s" % str(after))
		quit(1)
		return
	print("  Nested payload recursively equal after round-trip")

	# Spot-check the structures that a careless serializer would flatten.
	if after["causes"] != ["water", "food"]:
		print("FAIL L3: array payload corrupted: %s" % str(after["causes"]))
		quit(1)
		return
	if not (after["loss"] as Dictionary).has("scrap") or after["loss"]["scrap"] != 4:
		print("FAIL L3: nested dictionary corrupted: %s" % str(after["loss"]))
		quit(1)
		return
	if after["deep"]["level_two"]["level_three"][2]["inner"] != "value":
		print("FAIL L3: three-level nesting corrupted!")
		quit(1)
		return
	if after["flag"] != true or after["absent"] != null or after["note"] != "low_security":
		print("FAIL L3: scalar payload values corrupted!")
		quit(1)
		return
	if not (after["empty_list"] as Array).is_empty() or not (after["empty_map"] as Dictionary).is_empty():
		print("FAIL L3: empty containers corrupted!")
		quit(1)
		return
	print("  Arrays, 3-level nesting, bool, null, string and empty containers all intact")

	# The payload value model is canonicalized AT COMMIT, so the in-memory
	# ledger already holds exactly what will be persisted. That is what makes
	# the round-trip an identity rather than a lossy approximation.
	if typeof(before["loss"]["scrap"]) != typeof(after["loss"]["scrap"]):
		print("FAIL L3: value type drifted across the round-trip (%d -> %d)!" % [
			typeof(before["loss"]["scrap"]), typeof(after["loss"]["scrap"])
		])
		quit(1)
		return
	print("  Value types identical in and out (payload canonicalized at commit time)")
	print("PASS GATE L3: Payload Fidelity verified.")

	# --------------------------------------------------------------------------
	# GATE L4: Single Authority / Fail-Closed Count
	# --------------------------------------------------------------------------
	print("\n--- [GATE L4] Single Authority / Fail-Closed Count ---")

	# Runtime: the count is derived, never stored.
	if world.get_event_count() != world.event_log.size():
		print("FAIL L4: derived count disagrees with the ledger at runtime!")
		quit(1)
		return
	var snap := world.to_dict()
	if int(snap["event_count"]) != (snap["events"] as Array).size():
		print("FAIL L4: serialized event_count disagrees with serialized events!")
		quit(1)
		return
	print("  Runtime and serialized counts both derived from the ledger (%d)" % world.get_event_count())

	# Legal fixture: 7 events, count 7.
	var seven := WorldState.new()
	for i in range(7):
		seven.record_event(EventRecord.new(i, "FIXTURE_EVENT", &"a", &"b", {"i": i}))
	var seven_snap := seven.to_dict()
	var seven_res := WorldState.from_dict_checked(seven_snap)
	if not seven_res["success"]:
		print("FAIL L4: legal 7/7 fixture was rejected: %s" % seven_res["error"])
		quit(1)
		return
	print("  Legal fixture accepted: events = 7, event_count = 7")

	# Illegal fixture: 7 events, count 9. Must fail closed, whole.
	var lying_snap := seven.to_dict()
	lying_snap["event_count"] = 9
	var lying_res := WorldState.from_dict_checked(lying_snap)
	if lying_res["success"]:
		print("FAIL L4: snapshot claiming 9 events with only 7 was ACCEPTED!")
		quit(1)
		return
	if not String(lying_res["error"]).begins_with("LEDGER_COUNT_MISMATCH"):
		print("FAIL L4: wrong error for count mismatch: %s" % lying_res["error"])
		quit(1)
		return
	if lying_res["world"] != null:
		print("FAIL L4: a partial world was returned alongside the refusal!")
		quit(1)
		return
	print("  Illegal fixture refused: %s" % lying_res["error"])
	print("  No partial world acceptance: no truncation to 7, no padding to 9, no empty fallback")

	# The undercount direction must fail too.
	var undercount_snap := seven.to_dict()
	undercount_snap["event_count"] = 5
	if WorldState.from_dict_checked(undercount_snap)["success"]:
		print("FAIL L4: undercounted snapshot (5 declared, 7 present) was accepted!")
		quit(1)
		return
	print("  Undercount (declared 5, present 7) also refused")

	# A pre-S4-C.1 snapshot — a count with no ledger — is the dangerous case:
	# accepting it would assert that nothing ever happened.
	var legacy_snap := seven.to_dict()
	legacy_snap.erase("events")
	var legacy_res := WorldState.from_dict_checked(legacy_snap)
	if legacy_res["success"]:
		print("FAIL L4: legacy snapshot (event_count=7, no events) was accepted as empty history!")
		quit(1)
		return
	if not String(legacy_res["error"]).begins_with("LEDGER_MISSING"):
		print("FAIL L4: wrong error for missing ledger: %s" % legacy_res["error"])
		quit(1)
		return
	print("  Legacy snapshot refused: %s" % legacy_res["error"])

	# Malformed records are refused rather than silently dropped.
	var malformed_snap := seven.to_dict()
	var broken_events: Array = (malformed_snap["events"] as Array).duplicate(true)
	(broken_events[3] as Dictionary).erase("payload")
	malformed_snap["events"] = broken_events
	var malformed_res := WorldState.from_dict_checked(malformed_snap)
	if malformed_res["success"]:
		print("FAIL L4: event missing its payload field was accepted!")
		quit(1)
		return
	if not String(malformed_res["error"]).begins_with("LEDGER_MALFORMED"):
		print("FAIL L4: wrong error for malformed record: %s" % malformed_res["error"])
		quit(1)
		return
	print("  Malformed record refused: %s" % malformed_res["error"])

	# An empty ledger is perfectly legal — "nothing has happened yet" is a fact.
	var empty_world := WorldState.new()
	var empty_res := WorldState.from_dict_checked(empty_world.to_dict())
	if not empty_res["success"]:
		print("FAIL L4: an empty ledger was rejected: %s" % empty_res["error"])
		quit(1)
		return
	if (empty_res["world"] as WorldState).get_event_count() != 0:
		print("FAIL L4: empty ledger did not load as empty!")
		quit(1)
		return
	print("  Empty ledger accepted: events = [], event_count = 0")
	print("PASS GATE L4: Single Authority / Fail-Closed Count verified.")

	# --------------------------------------------------------------------------
	# GATE L5: Deterministic Ledger Replay
	# --------------------------------------------------------------------------
	print("\n--- [GATE L5] Deterministic Ledger Replay ---")

	var run_a := build_eventful_world()
	var run_b := build_eventful_world()

	var ledger_a := JSON.stringify(ledger_of(run_a), "\t", true).sha256_text()
	var ledger_b := JSON.stringify(ledger_of(run_b), "\t", true).sha256_text()
	if ledger_a != ledger_b:
		print("FAIL L5: ledger SHA diverged between identical runs!")
		print("  A = %s" % ledger_a)
		print("  B = %s" % ledger_b)
		quit(1)
		return
	print("  Two identical runs -> identical ledger SHA-256 (%d events):" % run_a.get_event_count())
	print("    %s" % ledger_a)

	# The ledger hash must be compared on its own, not smuggled in behind the
	# final world state: a world can match while its history does not.
	if run_a.get_event_count() == 0:
		print("FAIL L5: comparison was vacuous (no events)!")
		quit(1)
		return

	# And it must survive a load, so an audit performed on a reloaded save
	# reaches the same conclusion as one performed on the live world.
	var reloaded := WorldState.from_dict(JSON.parse_string(JSON.stringify(run_a.to_dict())))
	var ledger_reloaded := JSON.stringify(ledger_of(reloaded), "\t", true).sha256_text()
	if ledger_reloaded != ledger_a:
		print("FAIL L5: ledger SHA changed after a save/load cycle!")
		quit(1)
		return
	print("  Ledger SHA unchanged after save/load: an audit of the save agrees with the live world")
	print("PASS GATE L5: Deterministic Ledger Replay verified.")

	# --------------------------------------------------------------------------
	# GATE L6: Independent Verification + Engine Invariants
	# --------------------------------------------------------------------------
	print("\n--- [GATE L6] Independent Verification ---")

	var engine := SimulationEngine.new()
	var inv := engine.validate_invariants(world)
	if inv != "":
		print("FAIL L6: engine invariants violated: %s" % inv)
		quit(1)
		return
	print("  Engine invariants PASS on the eventful world (%d events)" % world.get_event_count())

	var inv_loaded := engine.validate_invariants(loaded)
	if inv_loaded != "":
		print("FAIL L6: engine invariants violated on the RELOADED world: %s" % inv_loaded)
		quit(1)
		return
	print("  Engine invariants PASS on the reloaded world")

	# Negative test on the ledger invariant itself.
	var corrupt := WorldState.new()
	var bad_rec := EventRecord.new(1, "CORRUPT", &"a", &"b", {})
	corrupt.record_event(bad_rec)
	bad_rec.payload["bad_value"] = Vector2(1, 2)
	var inv_corrupt := engine.validate_invariants(corrupt)
	if inv_corrupt == "":
		print("FAIL L6: invariant failed to detect an unpersistable payload value!")
		quit(1)
		return
	print("  Negative test: unpersistable payload detected -> %s" % inv_corrupt)

	var empty_type := WorldState.new()
	var untyped := EventRecord.new(1, "", &"a", &"b", {})
	empty_type.record_event(untyped)
	if engine.validate_invariants(empty_type) == "":
		print("FAIL L6: invariant failed to detect an empty event type!")
		quit(1)
		return
	print("  Negative test: empty event type detected")

	# Export a snapshot with real history for the independent Python validator.
	var f := FileAccess.open("res://artifacts/world_snapshot_s4c1.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(world.to_dict(), "\t", true))
		f.close()
		print("  Exported artifacts/world_snapshot_s4c1.json (%d events) for independent validation." % world.get_event_count())
	print("PASS GATE L6: Independent Verification verified.")

	print("\n================================================================================")
	print("ALL S4-C.1 EVENT LEDGER HARD GATES (L1 ~ L6) PASSED CLEANLY!")
	print("================================================================================")
	quit(0)

# ==============================================================================
# Fixture helpers
# ==============================================================================

# Extract just the ledger portion of a world, so L1/L5 compare history itself
# rather than the final world state that happens to surround it.
func ledger_of(w: WorldState) -> Array:
	var out: Array = []
	for evt in w.event_log:
		out.append((evt as EventRecord).to_dict())
	return out

# A world driven hard enough to produce genuinely varied committed history:
# caravan arrivals, a refugee migration, and settlement mortality.
func build_eventful_world() -> WorldState:
	var w := S1WorldData.create_s1_world()
	var engine := SimulationEngine.new()
	engine.enable_migration = true
	engine.enable_mortality = true
	engine.enable_security = true

	# Run a stable stretch first so caravans complete real journeys.
	for day in range(40):
		engine.tick(w)

	# Then starve Dry Well so pressure drives migration and, eventually, deaths.
	var dry_well: SettlementState = w.get_settlement(&"settlement:dry_well")
	dry_well.inventory.water = 0.0
	dry_well.inventory.food = 0.0
	dry_well.production.water = 0.0
	dry_well.production.food = 0.0

	for day in range(80):
		engine.tick(w)
		dry_well.inventory.water = 0.0
		dry_well.inventory.food = 0.0

	return w
