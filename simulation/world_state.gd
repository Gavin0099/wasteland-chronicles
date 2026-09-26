class_name WorldState
extends RefCounted

const Field = preload("res://simulation/field_adventure.gd")
var field_state: Dictionary = Field.new_state()

const Capability = preload("res://simulation/capability_profile.gd")
const RankCodec = preload("res://simulation/rank_json_codec.gd")
const ItemInventory = preload("res://simulation/item_inventory_state.gd")
const Equipment = preload("res://simulation/equipment_state.gd")
const ItemMarket = preload("res://simulation/item_market_state.gd")
const QuestStateReg = preload("res://simulation/quest_state_registry.gd")
const TravelRoute = preload("res://simulation/travel_route.gd")

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
# A receipt points to the committed ledger, never a second copy of the rewards.
# -1 also preserves compatibility with saves made before result confirmation.
var pending_encounter_result: int = -1

# QUEST-1: Quest runtime state and world-effect flags.
# quest_state is omitted from to_dict() when empty (same pattern as player/item_inventory)
# so old saves produce byte-identical JSON — Gate 7.
var quest_state: RefCounted = QuestStateReg.new()
var quest_flags: Dictionary = {}  # Dictionary[String, bool] — set by quest world_effects
# FUN-1: the definition of every job the player has ACCEPTED from a board.
# The board itself is recomputed from today's facts and is never stored, so a
# town that stops being short cannot retroactively cancel work already taken.
# Once accepted, this committed copy is the only truth about that contract.
var accepted_jobs: Dictionary = {}  # Dictionary[String, Dictionary] — quest_id -> definition

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
	copy.active_encounter = active_encounter.duplicate_state() if active_encounter != null else null
	copy.pending_encounter_result = pending_encounter_result
	copy.field_state = field_state.duplicate(true)
	# QUEST-1
	copy.quest_state = quest_state.duplicate_registry()
	copy.quest_flags = quest_flags.duplicate(true)
	copy.accepted_jobs = accepted_jobs.duplicate(true)
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
		"progression_schema_version": 1,
		"field_schema_version": 1,
		"field_state": field_state.duplicate(true),
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
		"active_encounter": active_encounter.to_dict() if active_encounter != null else {},
		"pending_encounter_result": pending_encounter_result,
	}
	if player != null:
		result["player"] = player.to_dict()
	# Omit-if-empty: old saves without quest activity produce the same JSON bytes (Gate 7)
	if not quest_state.is_empty():
		result["quest_schema_version"] = 1
		result["quest_state"] = quest_state.to_dict()
	if not quest_flags.is_empty():
		result["quest_schema_version"] = 1
		result["quest_flags"] = quest_flags.duplicate(true)
	if not accepted_jobs.is_empty():
		result["quest_schema_version"] = 1
		# Contract numbers share the ledger's JSON value model. A raw duplicate
		# turns integer tokens into floats only after a load, breaking replay SHA.
		result["accepted_jobs"] = EventRecord.canonicalize_payload(accepted_jobs)
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
	var field_error := Field.validate_wire(data)
	if field_error != "":
		return {"success": false, "world": null, "error": field_error}
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
	if data.has("settlements"):
		if typeof(data.settlements) != TYPE_DICTIONARY:
			return {"success": false, "world": null, "error": "INVALID_SETTLEMENTS"}
		for settlement_id in data.settlements:
			var raw_settlement: Variant = data.settlements[settlement_id]
			if typeof(raw_settlement) != TYPE_DICTIONARY:
				return {"success": false, "world": null, "error": "INVALID_SETTLEMENT_STATE"}
			if raw_settlement.has("item_market"):
				var item_market_error := ItemMarket.validate_serialized(raw_settlement.item_market)
				if item_market_error != "":
					return {"success": false, "world": null, "error": item_market_error}

	var events_data: Array = data["events"]

	# S4-C.2: validate every declared numeric field against the SCHEMA before
	# constructing anything. An invalid snapshot yields no partial world.
	var numeric_error := NumericCanon.validate_world_numerics(data)
	if numeric_error != "":
		return {"success": false, "world": null, "error": numeric_error}
	if data.has("refugees"):
		if typeof(data.refugees) != TYPE_DICTIONARY:
			return {"success": false, "world": null, "error": "INVALID_REFUGEE_PARTIES"}
		for party_id in data.refugees:
			var party_data: Variant = data.refugees[party_id]
			if typeof(party_data) != TYPE_DICTIONARY:
				return {"success": false, "world": null, "error": "INVALID_REFUGEE_PARTY"}
			if party_data.has("route_type"):
				var raw_route: Variant = party_data.route_type
				if typeof(raw_route) != TYPE_STRING or TravelRoute.get_route_days(StringName(party_data.get("origin_id", "")), StringName(party_data.get("destination_id", "")), raw_route) != int(party_data.get("route_days", -1)):
					return {"success": false, "world": null, "error": "INVALID_TRAVEL_ROUTE"}

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

	# Missing version + missing capability is the explicit pre-C1 migration.
	# A versioned partial profile is corruption, never a migration fallback.
	var player_data: Variant = data.get("player")
	var has_player_data := typeof(player_data) == TYPE_DICTIONARY
	if player_data != null and not has_player_data:
		return {"success": false, "world": null, "error": "INVALID_PLAYER_PROFILE"}
	if data.has("progression_schema_version"):
		var version: Variant = data.progression_schema_version
		if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or version != 1:
			return {"success": false, "world": null, "error": "UNSUPPORTED_PROGRESSION_SCHEMA"}
		if has_player_data:
			var capability_error := Capability.validate(player_data.get("capability"))
			if capability_error != "":
				return {"success": false, "world": null, "error": capability_error}
			if player_data.capability.npc_id != player_data.get("npc_id"):
				return {"success": false, "world": null, "error": "CAPABILITY_OWNER_MISMATCH"}
	elif has_player_data and player_data.has("capability"):
		return {"success": false, "world": null, "error": "MISSING_PROGRESSION_SCHEMA"}
	if has_player_data:
		var perk_error := PlayerState.Perks.validate_selection(player_data.get("perk_ids", []), int(player_data.get("xp", 0)))
		if perk_error != "":
			return {"success": false, "world": null, "error": perk_error}
		var acquired_error := PlayerState.Acquired.validate_selection(player_data.get("acquired_trait_ids", []))
		if acquired_error != "":
			return {"success": false, "world": null, "error": acquired_error}
		if player_data.has("item_inventory"):
			var item_inventory_error := ItemInventory.validate_serialized(player_data.item_inventory)
			if item_inventory_error != "":
				return {"success": false, "world": null, "error": item_inventory_error}
		if player_data.has("equipment"):
			var item_inventory_data: Variant = player_data.get("item_inventory", {"items": []})
			var checked_inventory := ItemInventory.from_dict_checked(item_inventory_data)
			if not checked_inventory.success:
				return {"success": false, "world": null, "error": checked_inventory.error}
			var equipment_error := Equipment.validate_serialized(player_data.equipment, checked_inventory.inventory)
			if equipment_error != "":
				return {"success": false, "world": null, "error": equipment_error}
		# Old profile loaders canonicalize metadata. Before migration, reject
		# malformed values rather than repairing them into a different biography.
		var profiles: Variant = data.get("npc_profile_registry")
		if typeof(profiles) != TYPE_DICTIONARY:
			return {"success": false, "world": null, "error": "MISSING_PROFILE_REGISTRY"}
		for owner in profiles:
			var biography: Variant = profiles[owner]
			if typeof(biography) != TYPE_DICTIONARY or biography.get("npc_id") != owner:
				return {"success": false, "world": null, "error": "INVALID_BIOGRAPHY_OWNER"}
			var background := NumericCanon.restore_int(biography.get("background"), "background", 0, 3)
			if not background.ok:
				return {"success": false, "world": null, "error": "INVALID_BIOGRAPHY_BACKGROUND"}
			for field in ["traits", "aptitudes"]:
				var tags: Variant = biography.get(field, [])
				if typeof(tags) != TYPE_ARRAY:
					return {"success": false, "world": null, "error": "INVALID_BIOGRAPHY_TAGS"}
				var previous := -1
				for tag in tags:
					var restored := NumericCanon.restore_int(tag, field, 0, 5 if field == "traits" else 4)
					if not restored.ok or restored.value <= previous:
						return {"success": false, "world": null, "error": "INVALID_BIOGRAPHY_TAGS"}
					previous = restored.value

	# QUEST-1: quest_schema_version validation (migration: absent = v1 empty state)
	if data.has("quest_schema_version"):
		var qv: Variant = data.quest_schema_version
		if typeof(qv) not in [TYPE_INT, TYPE_FLOAT] or qv != 1:
			return {"success": false, "world": null, "error": "UNSUPPORTED_QUEST_SCHEMA"}
	# Validate quest_state dict shape before constructing
	if data.has("quest_state"):
		var qs_err := QuestStateReg.validate_dict(data["quest_state"])
		if qs_err != "":
			return {"success": false, "world": null, "error": qs_err}
	if data.has("quest_flags"):
		if typeof(data["quest_flags"]) != TYPE_DICTIONARY:
			return {"success": false, "world": null, "error": "QUEST_FLAGS_NOT_DICT"}
		for flag in data["quest_flags"]:
			if typeof(flag) != TYPE_STRING or flag.is_empty() or typeof(data["quest_flags"][flag]) != TYPE_BOOL:
				return {"success": false, "world": null, "error": "QUEST_FLAGS_INVALID_ENTRY"}
	# FUN-1: an accepted job is a committed contract, so a malformed one must
	# fail the load rather than silently becoming unfulfillable.
	if data.has("accepted_jobs"):
		if typeof(data["accepted_jobs"]) != TYPE_DICTIONARY:
			return {"success": false, "world": null, "error": "ACCEPTED_JOBS_NOT_DICT"}
		const JobDefinition = preload("res://simulation/quest_definition.gd")
		for job_id in data["accepted_jobs"]:
			if typeof(job_id) != TYPE_STRING or not job_id.begins_with("job_"):
				return {"success": false, "world": null, "error": "ACCEPTED_JOB_INVALID_ID"}
			var raw: Variant = data["accepted_jobs"][job_id]
			if typeof(raw) != TYPE_DICTIONARY or String(raw.get("id", "")) != job_id:
				return {"success": false, "world": null, "error": "ACCEPTED_JOB_ID_MISMATCH"}
			var job_err := JobDefinition.validate_definition(raw)
			if job_err != "":
				return {"success": false, "world": null, "error": "ACCEPTED_JOB_" + job_err}

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
			var encounter_life: NpcLifeState = w.npc_life_state_registry.get_life_state(w.player.npc_id) if w.player != null else null
			var encounter_party: RefugeePartyState = w.get_refugee_party(encounter_life.population_container_id) if encounter_life != null and encounter_life.status == NpcLifeState.Status.IN_TRANSIT else null
			if enc.context.has("route_type") or (encounter_party != null and encounter_party.route_type != &""):
				if encounter_party == null or typeof(enc.context.get("route_type", null)) != TYPE_STRING or String(enc.context.route_type) != String(encounter_party.route_type) or enc.origin_id != encounter_party.origin_id or enc.destination_id != encounter_party.destination_id:
					return {"success": false, "world": null, "error": "ENCOUNTER_ROUTE_MISMATCH"}
			w.active_encounter = enc

	var salvage_error: String = _validate_salvage_sources(w)
	if salvage_error != "":
		return {"success": false, "world": null, "error": salvage_error}

	if data.has("field_state"):
		w.field_state = Field.normalize_state(data.field_state)
	var field_world_error := Field.validate_world(w)
	if field_world_error != "":
		return {"success": false, "world": null, "error": field_world_error}
	var receipt: Variant = data.get("pending_encounter_result", -1)
	if typeof(receipt) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(receipt)) or float(receipt) != floor(float(receipt)) or float(receipt) < -1 or float(receipt) >= w.event_log.size():
		return {"success": false, "world": null, "error": "ENCOUNTER_RESULT_MALFORMED: invalid ledger reference"}
	w.pending_encounter_result = int(receipt)
	if w.pending_encounter_result >= 0:
		var evt := w.event_log[w.pending_encounter_result]
		if w.active_encounter != null or w.player == null or evt.actor_id != w.player.npc_id or evt.type != "TRAVEL_ENCOUNTER_RESOLVED" or not TravelEncounter.valid_resolution(evt.payload):
			return {"success": false, "world": null, "error": "ENCOUNTER_RESULT_MALFORMED: invalid receipt"}
	if w.player != null:
		var owner_id := w.player.npc_id
		if not w.npc_registry.has_npc(owner_id) or not w.npc_life_state_registry.has_life_state(owner_id) or not w.npc_profile_registry.has_profile(owner_id):
			return {"success": false, "world": null, "error": "INVALID_CAPABILITY_OWNER_REFERENCE"}
		var capability_data: Dictionary = w.player.capability.to_dict()
		if capability_data.creation_origin == "CHARACTER_CREATION" and capability_data.background_id != NpcProfile.background_name(w.npc_profile_registry.get_profile(owner_id).background):
			return {"success": false, "world": null, "error": "CAPABILITY_BACKGROUND_MISMATCH"}
		var world_error := SimulationEngine.new().validate_invariants(w)
		if world_error != "":
			return {"success": false, "world": null, "error": world_error}
	return {"success": true, "world": w, "error": "", "migrated": not data.has("progression_schema_version")}

# Site facts have authority because the accepted contract and committed ledger
# agree. Older jobs have none of these fields and keep their original behavior.
static func _validate_salvage_sources(world: WorldState) -> String:
	var accepted: Dictionary = {}
	var resolved: Dictionary = {}
	for event in world.event_log:
		if event.type not in ["QUEST_ACCEPTED", "TRAVEL_ENCOUNTER", "TRAVEL_ENCOUNTER_RESOLVED"]:
			continue
		var payload: Dictionary = event.payload
		if not payload.has("source_wreck_id") and not payload.has("salvage_job_id"):
			continue
		var job_id: Variant = payload.get("quest_id") if event.type == "QUEST_ACCEPTED" else payload.get("salvage_job_id")
		if typeof(job_id) != TYPE_STRING or not world.accepted_jobs.has(job_id):
			return "SALVAGE_SOURCE_UNKNOWN_JOB"
		var definition: Dictionary = world.accepted_jobs[job_id]
		if not definition.has("source_wreck_id") or typeof(payload.get("source_wreck_id")) != TYPE_STRING or payload.source_wreck_id != definition.source_wreck_id:
			return "SALVAGE_SOURCE_CONTRACT_MISMATCH"
		if world.player == null or event.actor_id != world.player.npc_id:
			return "SALVAGE_SOURCE_ACTOR_MISMATCH"
		if event.type == "QUEST_ACCEPTED":
			accepted[job_id] = true
			continue
		if not accepted.has(job_id) or not _salvage_route_matches(definition, payload.get("origin"), payload.get("destination")) or payload.get("encounter_type") != "WRECK":
			return "SALVAGE_SOURCE_ROUTE_MISMATCH"
		if resolved.has(job_id):
			return "SALVAGE_SOURCE_ALREADY_RESOLVED"
		if event.type == "TRAVEL_ENCOUNTER_RESOLVED":
			if payload.get("site_name") != definition.target_site:
				return "SALVAGE_SOURCE_SITE_MISMATCH"
			resolved[job_id] = true
	for job_id in world.accepted_jobs:
		var definition: Dictionary = world.accepted_jobs[job_id]
		if not definition.has("source_wreck_id"):
			continue
		if not accepted.has(job_id):
			return "SALVAGE_SOURCE_ACCEPTANCE_MISSING"
		if world.get_settlement(StringName("settlement:" + definition.target_route_origin)) == null or world.get_settlement(StringName("settlement:" + definition.target_route_destination)) == null:
			return "SALVAGE_SOURCE_UNKNOWN_ROUTE"
	if world.active_encounter != null:
		var encounter: TravelEncounterState = world.active_encounter
		var context: Dictionary = encounter.context
		# Removing the whole context must not downgrade an already announced
		# contract site into an ordinary day-seeded wreck after loading.
		for index in range(world.event_log.size() - 1, -1, -1):
			var event: EventRecord = world.event_log[index]
			if event.type != "TRAVEL_ENCOUNTER" or event.day != encounter.day or event.payload.get("origin") != String(encounter.origin_id) or event.payload.get("destination") != String(encounter.destination_id) or event.payload.get("travel_day_index") != encounter.travel_day_index:
				continue
			if event.payload.has("source_wreck_id") and (context.get("source_wreck_id") != event.payload.source_wreck_id or context.get("salvage_job_id") != event.payload.get("salvage_job_id")):
				return "SALVAGE_SOURCE_CONTEXT_MISMATCH"
			break
		if context.has("source_wreck_id") or context.has("salvage_job_id") or context.has("salvage_target_item"):
			var job_id: Variant = context.get("salvage_job_id")
			if typeof(job_id) != TYPE_STRING or not accepted.has(job_id) or resolved.has(job_id):
				return "SALVAGE_SOURCE_INVALID_ACTIVE_JOB"
			var definition: Dictionary = world.accepted_jobs[job_id]
			if encounter.encounter_type != TravelEncounter.WRECK or context.get("source_wreck_id") != definition.source_wreck_id or context.get("salvage_target_item") != definition.target_item_id or context.get("site_name") != definition.target_site:
				return "SALVAGE_SOURCE_CONTEXT_MISMATCH"
			if not _salvage_route_matches(definition, String(encounter.origin_id), String(encounter.destination_id)) or context.get("route_type", "") == "WILDERNESS":
				return "SALVAGE_SOURCE_ROUTE_MISMATCH"
	return ""

static func _salvage_route_matches(definition: Dictionary, origin: Variant, destination: Variant) -> bool:
	var start: String = "settlement:" + definition.target_route_origin
	var finish: String = "settlement:" + definition.target_route_destination
	return (origin == start and destination == finish) or (origin == finish and destination == start)

# Raw saves must enter here, before Godot erases rank-token spelling.
static func from_json_checked(raw: String) -> Dictionary:
	var decoded := RankCodec.decode(raw)
	if not decoded.success:
		return {"success": false, "world": null, "error": decoded.error}
	return from_dict_checked(decoded.data)

static func from_json(raw: String) -> WorldState:
	var result := from_json_checked(raw)
	if not result.success:
		push_error("WorldState.from_json refused snapshot: %s" % result.error)
	return result.world

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
	# QUEST-1: load quest runtime state (graceful migration — absent = empty registry)
	if data.has("quest_state") and typeof(data["quest_state"]) == TYPE_DICTIONARY:
		w.quest_state = QuestStateReg.from_dict(data["quest_state"])
	if data.has("quest_flags") and typeof(data["quest_flags"]) == TYPE_DICTIONARY:
		w.quest_flags = data["quest_flags"].duplicate(true)
	if data.has("accepted_jobs") and typeof(data["accepted_jobs"]) == TYPE_DICTIONARY:
		w.accepted_jobs = data["accepted_jobs"].duplicate(true)
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
	return JSON.stringify(to_simulation_projection_dict(), "\t", true)
