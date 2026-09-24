class_name NpcLifeStateRegistry
extends RefCounted

# ==============================================================================
# S4-B: NPC LIFE STATE REGISTRY
# ==============================================================================
# Authoritative store for all named NPC life states.
# Enforces the Anonymous-First Bridge:
#   - Aggregate S3 rules only mutate anonymous cohort.
#   - Named individuals require explicit atomic transitions.
#
# ATOMIC LIFECYCLE API:
#   register_life_state()   — MATERIALIZED → SETTLED (called after S4-A materialization)
#   begin_named_migration() — SETTLED → IN_TRANSIT (atomic departure)
#   complete_named_migration() — IN_TRANSIT → SETTLED (atomic arrival)
#   commit_named_death()    — SETTLED → DEAD (atomic mortality, S4-B only)
#
# GOVERNANCE AXIOM (G1.5-X):
#   "Aggregate simulation must never implicitly select or mutate a named individual."
# ==============================================================================

var life_states: Dictionary = {}  # Dictionary[StringName(npc_id), NpcLifeState]

# ── Query API ──────────────────────────────────────────────────────────────────

func has_life_state(npc_id: StringName) -> bool:
	return life_states.has(npc_id)

func get_life_state(npc_id: StringName) -> NpcLifeState:
	return life_states.get(npc_id, null)

func get_all_living_in(container_type: NpcLifeState.ContainerType, container_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var sorted_keys := life_states.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		var ls: NpcLifeState = life_states[k]
		if ls.is_alive() and ls.population_container_type == container_type and ls.population_container_id == container_id:
			result.append(ls.npc_id)
	return result

func get_named_living_count_in_settlement(settlement_id: StringName) -> int:
	var count := 0
	for k in life_states:
		var ls: NpcLifeState = life_states[k]
		if ls.is_alive() and ls.status == NpcLifeState.Status.SETTLED and ls.population_container_id == settlement_id:
			count += 1
	return count

func get_named_living_count_in_party(party_id: StringName) -> int:
	var count := 0
	for k in life_states:
		var ls: NpcLifeState = life_states[k]
		if ls.is_alive() and ls.status == NpcLifeState.Status.IN_TRANSIT and ls.population_container_id == party_id:
			count += 1
	return count

# ── Lifecycle Transitions (All Validate-Before-Commit, Fail-Closed) ───────────

# Called immediately after S4-A NpcRegistry.materialize_identity() succeeds.
# Registers the initial SETTLED life state.
func register_life_state(world: WorldState, npc_id: StringName, settlement_id: StringName) -> Dictionary:
	if not world.npc_registry.has_npc(npc_id):
		return {"success": false, "error": "INVALID_NPC: %s not found in identity registry" % npc_id}
	if not world.settlements.has(settlement_id):
		return {"success": false, "error": "INVALID_SETTLEMENT: %s not found" % settlement_id}
	if has_life_state(npc_id):
		return {"success": false, "error": "DUPLICATE_LIFE_STATE: NPC %s already has a life state" % npc_id}

	var ls := NpcLifeState.new()
	ls.npc_id = npc_id
	ls.status = NpcLifeState.Status.SETTLED
	ls.population_container_type = NpcLifeState.ContainerType.SETTLEMENT
	ls.population_container_id = settlement_id
	life_states[npc_id] = ls
	return {"success": true, "life_state": ls}

# Atomic Departure: SETTLED → IN_TRANSIT
# Decrements origin population by 1 and creates/joins a refugee party.
# party_id must be a new unique ID (caller responsibility).
# If party already exists (joining), caller should pass existing party_id.
func begin_named_migration(
	world: WorldState,
	npc_id: StringName,
	dest_id: StringName,
	party_id: StringName,
	route_days: int,
	current_day: int,
	route_type: StringName = &""
) -> Dictionary:
	var ls: NpcLifeState = get_life_state(npc_id)
	if ls == null:
		return {"success": false, "error": "INVALID_NPC: No life state for %s" % npc_id}
	if ls.status != NpcLifeState.Status.SETTLED:
		return {"success": false, "error": "INVALID_STATUS: NPC %s must be SETTLED (got %d)" % [npc_id, ls.status]}

	var origin_id := ls.population_container_id
	var origin: SettlementState = world.get_settlement(origin_id)
	if origin == null:
		return {"success": false, "error": "INVALID_SETTLEMENT: Origin %s not found" % origin_id}
	if not world.settlements.has(dest_id):
		return {"success": false, "error": "INVALID_SETTLEMENT: Destination %s not found" % dest_id}
	if origin.population <= 0:
		return {"success": false, "error": "EMPTY_SETTLEMENT: Origin population is 0"}

	# Atomic Commit: individual first, then aggregate
	ls.status = NpcLifeState.Status.IN_TRANSIT
	ls.population_container_type = NpcLifeState.ContainerType.REFUGEE_PARTY
	ls.population_container_id = party_id

	origin.population -= 1

	var party: RefugeePartyState = world.get_refugee_party(party_id)
	if party == null:
		party = RefugeePartyState.new(party_id, origin_id, dest_id, 1, route_days, route_days, current_day, route_type)
		world.add_refugee_party(party)
	else:
		party.headcount += 1

	return {
		"success": true,
		"npc_id": npc_id,
		"origin_id": origin_id,
		"dest_id": dest_id,
		"party_id": party_id,
		"event_type": "NAMED_MIGRATION_STARTED"
	}

# Atomic Arrival: IN_TRANSIT → SETTLED(destination)
# Individual commits first, then aggregate.
func complete_named_migration(world: WorldState, npc_id: StringName) -> Dictionary:
	var ls: NpcLifeState = get_life_state(npc_id)
	if ls == null:
		return {"success": false, "error": "INVALID_NPC: No life state for %s" % npc_id}
	if ls.status != NpcLifeState.Status.IN_TRANSIT:
		return {"success": false, "error": "INVALID_STATUS: NPC %s must be IN_TRANSIT (got %d)" % [npc_id, ls.status]}

	var party_id := ls.population_container_id
	var party: RefugeePartyState = world.get_refugee_party(party_id)
	if party == null:
		return {"success": false, "error": "INVALID_PARTY: Party %s not found" % party_id}

	var dest: SettlementState = world.get_settlement(party.destination_id)
	if dest == null:
		return {"success": false, "error": "INVALID_SETTLEMENT: Destination %s not found" % party.destination_id}

	var dest_id := party.destination_id

	# Atomic Commit: individual first, then aggregate
	ls.status = NpcLifeState.Status.SETTLED
	ls.population_container_type = NpcLifeState.ContainerType.SETTLEMENT
	ls.population_container_id = dest_id

	dest.population += 1
	party.headcount -= 1

	return {
		"success": true,
		"npc_id": npc_id,
		"dest_id": dest_id,
		"party_id": party_id,
		"event_type": "NAMED_MIGRATION_COMPLETED"
	}

# Atomic Mortality: SETTLED → DEAD
#
# S4-B originally forbade IN_TRANSIT → DEAD ("sane transit, no death mid-route"),
# which was correct while the wasteland road was an abstraction. S5-B5 makes the
# road a place a person can actually die: running out of water three days from
# anywhere is the whole point of carrying water. Dying mid-route is therefore
# now a legal transition, handled by commit_named_death_in_transit() so that the
# accounting stays explicit rather than being folded into the settled path.
func commit_named_death(world: WorldState, npc_id: StringName) -> Dictionary:
	var ls: NpcLifeState = get_life_state(npc_id)
	if ls == null:
		return {"success": false, "error": "INVALID_NPC: No life state for %s" % npc_id}
	if ls.status == NpcLifeState.Status.IN_TRANSIT:
		return commit_named_death_in_transit(world, npc_id)
	if ls.status != NpcLifeState.Status.SETTLED:
		return {"success": false, "error": "INVALID_STATUS: cannot die from status %d" % ls.status}

	var settlement_id := ls.population_container_id
	var settlement: SettlementState = world.get_settlement(settlement_id)
	if settlement == null:
		return {"success": false, "error": "INVALID_SETTLEMENT: Settlement %s not found" % settlement_id}
	if settlement.population <= 0:
		return {"success": false, "error": "EMPTY_SETTLEMENT: Settlement population is 0"}

	# Atomic Commit: individual first, then aggregate
	ls.status = NpcLifeState.Status.DEAD
	ls.population_container_type = NpcLifeState.ContainerType.NONE
	ls.population_container_id = &""

	settlement.population -= 1
	settlement.cumulative_deaths += 1

	return {
		"success": true,
		"npc_id": npc_id,
		"settlement_id": settlement_id,
		"event_type": "NAMED_NPC_DIED"
	}

# Atomic Mortality on the road: IN_TRANSIT → DEAD.
#
# Life conservation counts a traveller inside their party headcount, so the
# headcount is what must drop. The death is recorded against the settlement they
# set out FROM: that is the community that actually lost a person. Attributing
# it to the destination would credit a death to a town they never reached.
func commit_named_death_in_transit(world: WorldState, npc_id: StringName) -> Dictionary:
	var ls: NpcLifeState = get_life_state(npc_id)
	if ls == null:
		return {"success": false, "error": "INVALID_NPC: No life state for %s" % npc_id}
	if ls.status != NpcLifeState.Status.IN_TRANSIT:
		return {"success": false, "error": "INVALID_STATUS: NPC %s is not in transit (got %d)" % [npc_id, ls.status]}

	var party_id := ls.population_container_id
	var party: RefugeePartyState = world.get_refugee_party(party_id)
	if party == null:
		return {"success": false, "error": "INVALID_PARTY: Party %s not found" % party_id}
	if party.headcount <= 0:
		return {"success": false, "error": "EMPTY_PARTY: Party %s has no headcount" % party_id}

	var origin: SettlementState = world.get_settlement(party.origin_id)
	if origin == null:
		return {"success": false, "error": "INVALID_SETTLEMENT: Origin %s not found" % party.origin_id}

	# Atomic Commit: individual first, then aggregate
	ls.status = NpcLifeState.Status.DEAD
	ls.population_container_type = NpcLifeState.ContainerType.NONE
	ls.population_container_id = &""

	party.headcount -= 1
	origin.cumulative_deaths += 1

	# A party whose last traveller died never arrives anywhere.
	if party.headcount <= 0:
		party.is_active = false

	return {
		"success": true,
		"npc_id": npc_id,
		"party_id": party_id,
		"settlement_id": party.origin_id,
		"event_type": "NAMED_NPC_DIED_IN_TRANSIT"
	}

# ── Serialization ──────────────────────────────────────────────────────────────

func duplicate_registry() -> NpcLifeStateRegistry:
	var copy := NpcLifeStateRegistry.new()
	var sorted_keys := life_states.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		copy.life_states[k] = (life_states[k] as NpcLifeState).duplicate_life_state()
	return copy

func to_dict() -> Dictionary:
	var out: Dictionary = {}
	var sorted_keys := life_states.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		out[String(k)] = (life_states[k] as NpcLifeState).to_dict()
	return out

static func from_dict(data: Dictionary) -> NpcLifeStateRegistry:
	var registry := NpcLifeStateRegistry.new()
	for k in data:
		var ls := NpcLifeState.from_dict(data[k])
		registry.life_states[ls.npc_id] = ls
	return registry
