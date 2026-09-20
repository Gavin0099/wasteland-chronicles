class_name NpcRegistry
extends RefCounted

# ==============================================================================
# S4-A: NPC REGISTRY
# ==============================================================================
# Authoritative registry managing materialized NPC identities.
# Enforces non-demographic identity materialization, monotonic ID minting,
# and subset invariant constraints.
# ==============================================================================

var npcs: Dictionary = {} # Dictionary[StringName, NpcIdentity]

func has_npc(id: StringName) -> bool:
	return npcs.has(id)

func get_npc(id: StringName) -> NpcIdentity:
	return npcs.get(id, null)

func get_all_npcs() -> Array[NpcIdentity]:
	var list: Array[NpcIdentity] = []
	var sorted_keys := npcs.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		list.append(npcs[k])
	return list

func get_named_count_at(settlement_id: StringName) -> int:
	var count: int = 0
	for k in npcs:
		var npc: NpcIdentity = npcs[k]
		if npc.origin_settlement_id == settlement_id:
			count += 1
	return count

func get_anonymous_count_at(world: WorldState, settlement_id: StringName) -> int:
	var s: SettlementState = world.get_settlement(settlement_id)
	if s == null:
		return 0
	return maxi(0, s.population - get_named_count_at(settlement_id))

# Materialize an individual identity from a settlement's existing population pool.
# Precondition checks fail-closed without mutating any world state or consuming sequences.
func materialize_identity(
	world: WorldState,
	settlement_id: StringName,
	name: String,
	age_at_materialization: int
) -> Dictionary:
	# 1. Verify settlement existence
	var settlement: SettlementState = world.get_settlement(settlement_id)
	if settlement == null:
		return {
			"success": false,
			"error": "INVALID_SETTLEMENT_REFERENCE: Settlement %s does not exist" % settlement_id
		}

	# 2. Check subset capacity constraint (Named <= Aggregate Population)
	var current_named: int = get_named_count_at(settlement_id)
	if current_named >= settlement.population:
		return {
			"success": false,
			"error": "CAPACITY_OVERFLOW: Settlement %s has %d named NPCs out of %d total population" % [
				settlement_id, current_named, settlement.population
			]
		}

	# 3. Check candidate monotonic ID
	var candidate_id := StringName("npc:%08d" % world.next_npc_sequence)
	if has_npc(candidate_id):
		return {
			"success": false,
			"error": "DUPLICATE_ID: NPC ID %s already exists in registry" % candidate_id
		}

	# 4. Atomic Commit (Only executed when all preconditions pass)
	var npc := NpcIdentity.new(candidate_id, name, age_at_materialization, settlement_id)
	npcs[candidate_id] = npc

	# Advance sequence ONLY upon successful commit
	world.next_npc_sequence += 1

	return {
		"success": true,
		"npc": npc,
		"settlement_population": settlement.population,
		"named_count": current_named + 1,
		"anonymous_count": settlement.population - (current_named + 1)
	}

func duplicate_registry() -> NpcRegistry:
	var copy := NpcRegistry.new()
	for k in npcs:
		copy.npcs[k] = (npcs[k] as NpcIdentity).duplicate_identity()
	return copy

func to_dict() -> Dictionary:
	var out: Dictionary = {}
	var sorted_keys := npcs.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		out[String(k)] = (npcs[k] as NpcIdentity).to_dict()
	return out

static func from_dict(data: Dictionary) -> NpcRegistry:
	var registry := NpcRegistry.new()
	for k in data:
		var npc_dict: Dictionary = data[k]
		var npc := NpcIdentity.from_dict(npc_dict)
		registry.npcs[npc.id] = npc
	return registry
