extends RefCounted

# One-time experiential XP is derived from the committed actor's event history.
# The caller puts the returned award in its own result event, so no extra
# mutable marker or independently ordered event is needed.
const FIRST_WRECK_SALVAGE := "FIRST_WRECK_SALVAGE"
const FIRST_FIELD_VICTORY := "FIRST_FIELD_VICTORY"

static func award_once(world, event_type: String, source_id: String, amount: int) -> int:
	for event in world.event_log:
		if event.type == event_type and event.actor_id == world.player.npc_id and event.payload.get("xp_source", "") == source_id:
			return 0
	world.player.xp += amount
	return amount
