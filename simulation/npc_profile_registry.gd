class_name NpcProfileRegistry
extends RefCounted

# ==============================================================================
# S4-C: NPC PROFILE REGISTRY
# ==============================================================================
# Authoritative store for named NPC background metadata.
#
# THREE-LAYER NPC DECOMPOSITION (each layer its own registry, no bleed-through):
#   NpcRegistry          → 這個人是誰        (S4-A, permanent identity)
#   NpcLifeStateRegistry → 這個人在哪／活著嗎 (S4-B, mutable life state)
#   NpcProfileRegistry   → 這個人的背景描述   (S4-C, immutable biography)
#
# S4-C RULES (all enforced fail-closed, zero mutation on rejection):
#   1. Profile is OPTIONAL. Pre-S4-C NPCs without one remain fully valid.
#   2. Background is IMMUTABLE once assigned. No reassignment, ever.
#   3. LIVING NPCs ONLY. A dead NPC without a profile stays without one —
#      post-mortem biography authoring is a hallucination surface, so it is closed.
#   4. EXPLICIT caller assignment only. No distribution, no inference, no RNG.
#      Inventing a background distribution would smuggle in unspecified demographics.
#   5. Unknown background values are rejected.
#
# ACTION AUTHORITY (npc-authority.md §6): S4-C action space is EMPTY.
#   get_authorized_actions() returns [] for every background, without exception.
# ==============================================================================

var profiles: Dictionary = {}  # Dictionary[StringName(npc_id), NpcProfile]

# ── Query API ──────────────────────────────────────────────────────────────────

func has_profile(npc_id: StringName) -> bool:
	return profiles.has(npc_id)

func get_profile(npc_id: StringName) -> NpcProfile:
	return profiles.get(npc_id, null)

func get_profile_count() -> int:
	return profiles.size()

func get_npcs_with_background(background: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var sorted_keys := profiles.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		var p: NpcProfile = profiles[k]
		if p.background == background:
			result.append(p.npc_id)
	return result

# ── Assignment (Validate-Before-Commit, Fail-Closed) ──────────────────────────

# Assign a background to a living named NPC. First assignment only.
func assign_background(world: WorldState, npc_id: StringName, background: int) -> Dictionary:
	# 1. Closed enum membership
	if not NpcProfile.is_valid_background(background):
		return {
			"success": false,
			"error": "INVALID_BACKGROUND: %d is not a member of the closed Background enum" % background
		}

	# 2. Identity must exist
	if not world.npc_registry.has_npc(npc_id):
		return {
			"success": false,
			"error": "INVALID_NPC: %s not found in identity registry" % npc_id
		}

	# 3. Immutability — first assignment only
	if has_profile(npc_id):
		var existing: NpcProfile = get_profile(npc_id)
		return {
			"success": false,
			"error": "IMMUTABLE_BACKGROUND: NPC %s already has background %s; background is biography and can never be reassigned" % [
				npc_id, NpcProfile.background_name(existing.background)
			]
		}

	# 4. Living NPCs only — no post-mortem biography authoring
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(npc_id)
	if ls == null:
		return {
			"success": false,
			"error": "NO_LIFE_STATE: NPC %s has no life state; background requires a living NPC" % npc_id
		}
	if not ls.is_alive():
		return {
			"success": false,
			"error": "DECEASED_NPC: NPC %s is dead; backgrounds cannot be authored post-mortem" % npc_id
		}

	# 5. Atomic Commit — touches the profile registry ONLY.
	#    No population, no life state, no event ledger, no aggregate field.
	var profile := NpcProfile.new()
	profile.npc_id = npc_id
	profile.background = background as NpcProfile.Background
	profiles[npc_id] = profile

	return {
		"success": true,
		"npc_id": npc_id,
		"background": background,
		"background_name": NpcProfile.background_name(background),
	}

# ── Action Authority (S4-C: EMPTY, unconditionally) ───────────────────────────

# npc-authority.md §6: the S4-C authorized action space is NONE.
# This returns [] for EVERY background. It is not a stub awaiting content —
# whether a background confers action eligibility is an S4-F decision to be made
# against gameplay verbs that do not exist yet.
func get_authorized_actions(_npc_id: StringName) -> Array[StringName]:
	return []

# Any attempt to execute an action on the strength of a background is refused
# with zero state change, at every slice up to S4-F.
func attempt_background_action(_world: WorldState, npc_id: StringName, action: StringName) -> Dictionary:
	return {
		"success": false,
		"error": "UNAUTHORIZED_ACTION: action %s denied for NPC %s — S4-C background action space is EMPTY (NO_STATE_CHANGE)" % [
			action, npc_id
		],
		"authorized_actions": [],
		"state_changed": false,
	}

# ── Serialization ──────────────────────────────────────────────────────────────

func duplicate_registry() -> NpcProfileRegistry:
	var copy := NpcProfileRegistry.new()
	var sorted_keys := profiles.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		copy.profiles[k] = (profiles[k] as NpcProfile).duplicate_profile()
	return copy

func to_dict() -> Dictionary:
	var out: Dictionary = {}
	var sorted_keys := profiles.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		out[String(k)] = (profiles[k] as NpcProfile).to_dict()
	return out

static func from_dict(data: Dictionary) -> NpcProfileRegistry:
	var registry := NpcProfileRegistry.new()
	for k in data:
		var p := NpcProfile.from_dict(data[k])
		registry.profiles[p.npc_id] = p
	return registry
