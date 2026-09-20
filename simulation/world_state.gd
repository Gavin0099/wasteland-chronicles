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

func record_event(event: EventRecord) -> void:
	event_log.append(event)

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

	var events_arr := []
	for evt in event_log:
		events_arr.append((evt as EventRecord).to_dict())

	return {
		"current_day": current_day,
		"total_initial_population": total_initial_population,
		"next_npc_sequence": next_npc_sequence,
		"npc_registry": npc_registry.to_dict(),
		"npc_life_state_registry": npc_life_state_registry.to_dict(),
		"npc_profile_registry": npc_profile_registry.to_dict(),
		"settlements": settlements_dict,
		"caravans": caravans_dict,
		"refugees": refugees_dict,
		"event_count": events_arr.size()
	}

static func from_dict(data: Dictionary) -> WorldState:
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
