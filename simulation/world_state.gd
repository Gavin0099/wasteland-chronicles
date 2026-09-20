class_name WorldState
extends RefCounted

var current_day: int = 0
var total_initial_population: int = -1
var next_npc_sequence: int = 1
var npc_registry: NpcRegistry = NpcRegistry.new()
var npc_life_state_registry: NpcLifeStateRegistry = NpcLifeStateRegistry.new()
var npc_profile_registry: NpcProfileRegistry = NpcProfileRegistry.new()
var settlements: Dictionary = {} # Dictionary[StringName, SettlementState]
var caravans: Dictionary = {}    # Dictionary[StringName, CaravanState]
var refugees: Dictionary = {}    # Dictionary[StringName, RefugeePartyState]
var event_log: Array[EventRecord] = []

# S5-A Player Avatar State
var player: PlayerState = null

# S4-F1 Decision Audit Trail. Separate from event_log ON PURPOSE: the ledger
# holds committed facts only, while REJECTED intents live here and nowhere else.
var decision_audit_trail: Array[NpcDecisionEvidence] = []

# S5-B4: the encounter currently halting the player's journey, or null.
var active_encounter: TravelEncounterState = null

func get_settlement(id: StringName) -> SettlementState:
	return settlements.get(id, null)

func get_caravan(id: StringName) -> CaravanState:
	return caravans.get(id, null)

func get_refugee_party(id: StringName) -> RefugeePartyState:
	return refugees.get(id, null)

func add_settlement(settlement: SettlementState) -> void:
	settlements[settlement.id] = settlement

func add_caravan(caravan: CaravanState) -> void:
	caravans[caravan.id] = caravan

func add_refugee_party(party: RefugeePartyState) -> void:
	refugees[party.id] = party

# The single chokepoint through which a fact enters the historical ledger.
# The payload is canonicalized to the persisted value model HERE, at commit
# time, so that the in-memory ledger and the serialized ledger are the same
# thing — making save -> load -> save a fixed point (S4-C.1).
func record_event(event: EventRecord) -> void:
	event.canonicalize()
	event_log.append(event)

# ==============================================================================
# S4-C.2: CANONICAL NUMERIC COMMIT (end-of-day state commit boundary)
# ==============================================================================
# Called once per tick, after the day's physics and before invariant validation,
# so that every committed day is already persistence-canonical and the next day
# starts from a canonical value. Save then merely records; it never repairs.
# See NumericCanon for why the codec — not a digit count — defines canonical.
func canonicalize_numeric_state() -> void:
	for s_id in settlements:
		var s: SettlementState = settlements[s_id]
		s.metabolism_water_rate = NumericCanon.canonical_float(s.metabolism_water_rate)
		s.metabolism_food_rate = NumericCanon.canonical_float(s.metabolism_food_rate)
		s.water_pressure = NumericCanon.canonical_float(s.water_pressure)
		s.food_pressure = NumericCanon.canonical_float(s.food_pressure)
		s.water_exposure = NumericCanon.canonical_float(s.water_exposure)
		s.food_exposure = NumericCanon.canonical_float(s.food_exposure)
		s.security = NumericCanon.canonical_float(s.security)
		s.base_price_water = NumericCanon.canonical_float(s.base_price_water)
		s.base_price_food = NumericCanon.canonical_float(s.base_price_food)
		s.base_price_scrap = NumericCanon.canonical_float(s.base_price_scrap)
		s.base_price_fuel = NumericCanon.canonical_float(s.base_price_fuel)
		s.price_water = NumericCanon.canonical_float(s.price_water)
		s.price_food = NumericCanon.canonical_float(s.price_food)
		s.price_scrap = NumericCanon.canonical_float(s.price_scrap)
		s.price_fuel = NumericCanon.canonical_float(s.price_fuel)
		s.production_credits = NumericCanon.canonical_float_dict(s.production_credits)
		s.disorder_loss_credits = NumericCanon.canonical_float_dict(s.disorder_loss_credits)
	if player != null:
		player.water_pressure = NumericCanon.canonical_float(player.water_pressure)
		player.food_pressure = NumericCanon.canonical_float(player.food_pressure)

# event_count is DERIVED, never stored. There is exactly one authority for how
# many things have happened: the ledger itself.
func get_event_count() -> int:
	return event_log.size()

func record_decision(evidence: NpcDecisionEvidence) -> void:
	decision_audit_trail.append(evidence)

func get_decision_count() -> int:
	return decision_audit_trail.size()

func duplicate_state() -> WorldState:
	var copy := WorldState.new()
	copy.current_day = current_day
	copy.total_initial_population = total_initial_population
	copy.next_npc_sequence = next_npc_sequence
	copy.npc_registry = npc_registry.duplicate_registry()
	copy.npc_life_state_registry = npc_life_state_registry.duplicate_registry()
	copy.npc_profile_registry = npc_profile_registry.duplicate_registry()
	for s_id in settlements:
		copy.settlements[s_id] = (settlements[s_id] as SettlementState).duplicate_state()
	for c_id in caravans:
		copy.caravans[c_id] = (caravans[c_id] as CaravanState).duplicate_state()
	for r_id in refugees:
		copy.refugees[r_id] = (refugees[r_id] as RefugeePartyState).duplicate_state()
	for evt in event_log:
		copy.event_log.append((evt as EventRecord).duplicate_record())
	for ev in decision_audit_trail:
		copy.decision_audit_trail.append((ev as NpcDecisionEvidence).duplicate_evidence())
	if player != null:
		copy.player = player.duplicate_state()
	return copy

func to_dict() -> Dictionary:
	var settlements_dict := {}
	# 依照 Key 排序以維持序列化一致性
	var sorted_s_keys := settlements.keys()
	sorted_s_keys.sort()
	for s_key in sorted_s_keys:
		settlements_dict[String(s_key)] = (settlements[s_key] as SettlementState).to_dict()

	var caravans_dict := {}
	var sorted_c_keys := caravans.keys()
	sorted_c_keys.sort()
	for c_key in sorted_c_keys:
		caravans_dict[String(c_key)] = (caravans[c_key] as CaravanState).to_dict()

	var refugees_dict := {}
	var sorted_r_keys := refugees.keys()
	sorted_r_keys.sort()
	for r_key in sorted_r_keys:
		refugees_dict[String(r_key)] = (refugees[r_key] as RefugeePartyState).to_dict()

	# Ledger order is COMMIT order and is never re-sorted. Canonical key
	# ordering (sorting dictionary keys for stable hashing) applies to the
	# containers above; it must never be applied to this sequence.
	var events_arr := []
	for evt in event_log:
		events_arr.append((evt as EventRecord).to_dict())

	# Decision order is evaluation order and is never re-sorted.
	var decisions_arr := []
	for ev in decision_audit_trail:
		decisions_arr.append((ev as NpcDecisionEvidence).to_dict())

	var result := {
		"current_day": current_day,
		"total_initial_population": total_initial_population,
		"next_npc_sequence": next_npc_sequence,
		"npc_registry": npc_registry.to_dict(),
		"npc_life_state_registry": npc_life_state_registry.to_dict(),
		"npc_profile_registry": npc_profile_registry.to_dict(),
		"settlements": settlements_dict,
		"caravans": caravans_dict,
		"refugees": refugees_dict,
		# "events" is the authority. "event_count" is derived metadata kept for
		# human/diagnostic convenience only — loaders must never trust it as
		# state, they must only check it agrees with the ledger.
		"event_count": events_arr.size(),
		"events": events_arr,
		"decision_audit_trail": decisions_arr,
		"active_encounter": active_encounter.to_dict() if active_encounter != null else {}
	}
	if player != null:
		result["player"] = player.to_dict()
	return result

# ==============================================================================
# S4-C.1: FAIL-CLOSED LOADING
# ==============================================================================
# Returns {"success": bool, "world": WorldState|null, "error": String}.
#
# AUTHORITATIVE DIRECTION:
#   Committed Events -> Serialized Ledger -> Loaded Events
# NEVER:
#   event_count -> inferred historical state
#
# A snapshot whose ledger cannot be trusted is REFUSED WHOLE. There is no
# partial world acceptance: no truncating the ledger to the count, no padding
# the ledger up to the count, no falling back to an empty ledger. A world that
# quietly loads as "nothing ever happened" is more dangerous than a world that
# refuses to load at all, because the first one lies and the second one stops.
static func from_dict_checked(data: Dictionary) -> Dictionary:
	# The events key is MANDATORY. A pre-S4-C.1 snapshot carrying
	# "event_count": 20 with no ledger would otherwise silently reconstruct a
	# world in which nothing has ever happened.
	if not data.has("events"):
		return {
			"success": false,
			"world": null,
			"error": "LEDGER_MISSING: snapshot has no 'events' array (a pre-S4-C.1 snapshot cannot be trusted as history)"
		}
	if typeof(data["events"]) != TYPE_ARRAY:
		return {"success": false, "world": null, "error": "LEDGER_MALFORMED: 'events' is not an array"}

	var events_data: Array = data["events"]

	# S4-C.2: validate every declared numeric field against the SCHEMA before
	# constructing anything. An invalid snapshot yields no partial world.
	var numeric_error := NumericCanon.validate_world_numerics(data)
	if numeric_error != "":
		return {"success": false, "world": null, "error": numeric_error}

	# event_count is metadata. It is CHECKED against the ledger, never trusted.
	if data.has("event_count"):
		var declared := int(data["event_count"])
		if declared != events_data.size():
			return {
				"success": false,
				"world": null,
				"error": "LEDGER_COUNT_MISMATCH: declared event_count %d != serialized events %d" % [
					declared, events_data.size()
				]
			}

	for i in range(events_data.size()):
		var err := EventRecord.validate_dict(events_data[i], i)
		if err != "":
			return {"success": false, "world": null, "error": "LEDGER_MALFORMED: %s" % err}

	var w := from_dict_unchecked(data)

	# Rebuild the ledger from the events themselves, in serialized order.
	for i in range(events_data.size()):
		w.event_log.append(EventRecord.from_dict(events_data[i]))

	# S4-F1 decision audit trail, same fail-closed discipline as the ledger.
	if data.has("decision_audit_trail"):
		if typeof(data["decision_audit_trail"]) != TYPE_ARRAY:
			return {"success": false, "world": null, "error": "AUDIT_TRAIL_MALFORMED: decision_audit_trail is not an array"}
		var decisions_data: Array = data["decision_audit_trail"]
		for i in range(decisions_data.size()):
			var d_err := NpcDecisionEvidence.validate_dict(decisions_data[i], i)
			if d_err != "":
				return {"success": false, "world": null, "error": "AUDIT_TRAIL_MALFORMED: %s" % d_err}
		for i in range(decisions_data.size()):
			w.decision_audit_trail.append(NpcDecisionEvidence.from_dict(decisions_data[i]))

	if data.has("active_encounter") and typeof(data["active_encounter"]) == TYPE_DICTIONARY:
		var enc_data: Dictionary = data["active_encounter"]
		if not enc_data.is_empty():
			var enc := TravelEncounterState.from_dict(enc_data)
			if not TravelEncounter.is_valid_type(enc.encounter_type):
				return {"success": false, "world": null, "error": "ENCOUNTER_MALFORMED: unknown encounter type '%s'" % enc.encounter_type}
			w.active_encounter = enc

	return {"success": true, "world": w, "error": ""}

# Thin wrapper: returns the world, or null when the snapshot is refused.
static func from_dict(data: Dictionary) -> WorldState:
	var result := from_dict_checked(data)
	if not result["success"]:
		push_error("WorldState.from_dict refused snapshot: %s" % result["error"])
		return null
	return result["world"]

# Everything EXCEPT the ledger. Never call this directly to load a snapshot —
# it performs no ledger validation and yields a world with no history.
static func from_dict_unchecked(data: Dictionary) -> WorldState:
	var w := WorldState.new()
	w.current_day = int(data.get("current_day", 0))
	w.total_initial_population = int(data.get("total_initial_population", -1))
	w.next_npc_sequence = int(data.get("next_npc_sequence", 1))
	if data.has("npc_registry"):
		w.npc_registry = NpcRegistry.from_dict(data["npc_registry"])
	if data.has("npc_life_state_registry"):
		w.npc_life_state_registry = NpcLifeStateRegistry.from_dict(data["npc_life_state_registry"])
	if data.has("npc_profile_registry"):
		w.npc_profile_registry = NpcProfileRegistry.from_dict(data["npc_profile_registry"])
	if data.has("settlements"):
		var s_data: Dictionary = data["settlements"]
		for s_id in s_data:
			w.settlements[StringName(s_id)] = SettlementState.from_dict(s_data[s_id])
	if data.has("caravans"):
		var c_data: Dictionary = data["caravans"]
		for c_id in c_data:
			w.caravans[StringName(c_id)] = CaravanState.from_dict(c_data[c_id])
	if data.has("refugees"):
		var r_data: Dictionary = data["refugees"]
		for r_id in r_data:
			w.refugees[StringName(r_id)] = RefugeePartyState.from_dict(r_data[r_id])
	if data.has("player") and data["player"] != null and typeof(data["player"]) == TYPE_DICTIONARY:
		w.player = PlayerState.from_dict(data["player"])
	return w

func to_canonical_json() -> String:
	return JSON.stringify(to_dict(), "\t", true)

# ==============================================================================
# S4-C: SIMULATION PROJECTION
# ==============================================================================
# The full canonical JSON necessarily differs between a world with backgrounds
# and one without — the profile registry is part of it. The Simulation
# Projection is everything the aggregate simulation actually runs on:
# identical to to_dict() MINUS npc_profile_registry.
#
# Identity and life states stay INSIDE the projection on purpose. Backgrounds
# must not perturb who exists or where they are either, so keeping those layers
# under the hash makes the inertness claim stronger, not weaker.
#
# Gate C5 asserts: same world, one with profiles and one without, run the same
# number of days → byte-identical projection hash.
# ==============================================================================
func to_simulation_projection_dict() -> Dictionary:
	var projection := to_dict()
	projection.erase("npc_profile_registry")
	return projection

func to_simulation_projection_json() -> String:
	return JSON.stringify(to_simulation_projection_dict(), "	", true)
