class_name WorldState
extends RefCounted

var current_day: int = 0
var total_initial_population: int = -1
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
		"settlements": settlements_dict,
		"caravans": caravans_dict,
		"refugees": refugees_dict,
		"event_count": events_arr.size()
	}

func to_canonical_json() -> String:
	return JSON.stringify(to_dict(), "\t", true)
