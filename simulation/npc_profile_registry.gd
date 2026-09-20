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

# ── S4-D: Traits (set-like Profile metadata) ──────────────────────────────────
# Same discipline as Background: explicit assignment only, no random generation,
# no inference from background, no demographic distribution, immutable once added.
# A trait says what kind of person someone is; it grants nothing.

func get_traits(npc_id: StringName) -> Array[int]:
	var profile: NpcProfile = get_profile(npc_id)
	if profile == null:
		return []
	return profile.traits.duplicate()

func get_npcs_with_trait(trait_value: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var sorted_keys := profiles.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		var p: NpcProfile = profiles[k]
		if p.has_trait(trait_value):
			result.append(p.npc_id)
	return result

# Add one trait to a living NPC that already has a Profile.
func assign_trait(world: WorldState, npc_id: StringName, trait_value: int) -> Dictionary:
	# 1. Closed enum membership
	if not NpcProfile.is_valid_trait(trait_value):
		return {
			"success": false,
			"error": "INVALID_TRAIT: %d is not a member of the closed Trait enum" % trait_value
		}

	# 2. Identity must exist
	if not world.npc_registry.has_npc(npc_id):
		return {"success": false, "error": "INVALID_NPC: %s not found in identity registry" % npc_id}

	# 3. Traits are Profile metadata: a Profile must already exist
	var profile: NpcProfile = get_profile(npc_id)
	if profile == null:
		return {
			"success": false,
			"error": "NO_PROFILE: NPC %s has no profile; traits are profile metadata" % npc_id
		}

	# 4. Set semantics — a trait is held once or not at all
	if profile.has_trait(trait_value):
		return {
			"success": false,
			"error": "DUPLICATE_TRAIT: NPC %s already has trait %s" % [
				npc_id, NpcProfile.trait_name(trait_value)
			]
		}

	# 5. Living NPCs only — no post-mortem personality authoring.
	#    Traits assigned before death are kept: they are part of who that person was.
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(npc_id)
	if ls == null:
		return {"success": false, "error": "NO_LIFE_STATE: NPC %s has no life state" % npc_id}
	if not ls.is_alive():
		return {
			"success": false,
			"error": "DECEASED_NPC: NPC %s is dead; traits cannot be authored post-mortem" % npc_id
		}

	# 6. Atomic Commit — profile metadata only, held in canonical enum order so
	#    that assignment order can never produce a different world.
	var updated := profile.traits.duplicate()
	updated.append(trait_value)
	profile.traits = NpcProfile.canonical_traits(updated)

	return {
		"success": true,
		"npc_id": npc_id,
		"trait": trait_value,
		"trait_name": NpcProfile.trait_name(trait_value),
		"traits": profile.traits.duplicate(),
	}

# ── S4-E: Aptitudes (set-like Profile metadata) ───────────────────────────────
# Same discipline as traits. An aptitude names a domain someone may find easier
# to learn in. It is NOT a rating, multiplier, growth curve or cap, and it has no
# gameplay consequence at all until S5-D defines real skills.

func get_aptitudes(npc_id: StringName) -> Array[int]:
	var profile: NpcProfile = get_profile(npc_id)
	if profile == null:
		return []
	return profile.aptitudes.duplicate()

func get_npcs_with_aptitude(aptitude_value: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var sorted_keys := profiles.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		var p: NpcProfile = profiles[k]
		if p.has_aptitude(aptitude_value):
			result.append(p.npc_id)
	return result

func assign_aptitude(world: WorldState, npc_id: StringName, aptitude_value: int) -> Dictionary:
	if not NpcProfile.is_valid_aptitude(aptitude_value):
		return {
			"success": false,
			"error": "INVALID_APTITUDE: %d is not a member of the closed Aptitude enum" % aptitude_value
		}
	if not world.npc_registry.has_npc(npc_id):
		return {"success": false, "error": "INVALID_NPC: %s not found in identity registry" % npc_id}

	var profile: NpcProfile = get_profile(npc_id)
	if profile == null:
		return {
			"success": false,
			"error": "NO_PROFILE: NPC %s has no profile; aptitudes are profile metadata" % npc_id
		}
	if profile.has_aptitude(aptitude_value):
		return {
			"success": false,
			"error": "DUPLICATE_APTITUDE: NPC %s already has aptitude %s" % [
				npc_id, NpcProfile.aptitude_name(aptitude_value)
			]
		}

	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(npc_id)
	if ls == null:
		return {"success": false, "error": "NO_LIFE_STATE: NPC %s has no life state" % npc_id}
	if not ls.is_alive():
		return {
			"success": false,
			"error": "DECEASED_NPC: NPC %s is dead; aptitudes cannot be authored post-mortem" % npc_id
		}

	var updated := profile.aptitudes.duplicate()
	updated.append(aptitude_value)
	profile.aptitudes = NpcProfile.canonical_traits(updated)

	return {
		"success": true,
		"npc_id": npc_id,
		"aptitude": aptitude_value,
		"aptitude_name": NpcProfile.aptitude_name(aptitude_value),
		"aptitudes": profile.aptitudes.duplicate(),
	}

# ── Action Authority (S4-C/D/E: EMPTY, unconditionally) ───────────────────────

# npc-authority.md §6: the S4-C ~ E authorized action space is NONE.
# This returns [] for EVERY background AND every combination of traits and
# aptitudes. It is not
# a stub awaiting content — whether a background or trait confers action
# eligibility is an S4-F decision to be made against gameplay verbs that do not
# exist yet.
func get_authorized_actions(_npc_id: StringName) -> Array[StringName]:
	return []

# Any attempt to execute an action on the strength of a background is refused
# with zero state change, at every slice up to S4-F.
func attempt_background_action(_world: WorldState, npc_id: StringName, action: StringName) -> Dictionary:
	return {
		"success": false,
		"error": "UNAUTHORIZED_ACTION: action %s denied for NPC %s — S4-C/S4-D background and trait action space is EMPTY (NO_STATE_CHANGE)" % [
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
