# QUEST-1 — Quest foundation

QUEST-1 freezes the first quest authority without adding authored town content.
Quest definitions are immutable catalogue data; runtime progress lives in a
separate `QuestStateRegistry` owned by `WorldState`.

The v1 definition contract uses stable lowercase IDs, a required settlement and
issuer, day/flag availability, an integer deadline, typed objectives, and
outcomes with list-based rewards:

```json
{
  "type": "XP",
  "amount": 60
}
```

Supported objective types are `HAVE_ITEM`, `DELIVER_ITEM`, `WORLD_FLAG`, and
`VISIT_LOCATION`. Supported rewards are `XP` and `CURRENCY`; the only world
effect is `SET_FLAG`. The authored catalogue is intentionally empty until the
next quest-content slice.

The lifecycle is `LOCKED → AVAILABLE → ACTIVE → RESOLVED`, with explicit
`FAILED` and `EXPIRED` terminals. Deadlines are inclusive: a quest accepted on
day N with `deadline_days = 3` remains active through N+2 and expires after
that day. Rewards and effects are guarded by `reward_granted`, so save/load or
repeated resolution cannot grant them twice.

Quest XP changes `PlayerState.xp` only. Skill ranks and `growth_points` remain
owned by the future character-progression authority. Empty quest state and flags
are omitted from serialization, preserving legacy world hashes; populated quest
state carries `quest_schema_version = 1` and loads fail closed on malformed
state, flags, or unsupported versions.

Evidence:

- `tests/test_quest1.gd`: nine gates, including definition validation,
  transition safety, determinism, migration, deadline semantics, idempotency,
  non-regression, and progression-authority separation.
- Full Godot suite: 57/57 tests pass after QUEST-1 integration.

Deferred to later slices: real quest catalogue entries, quest UI, acceptance
controls, item delivery mutation, branching outcomes, faction/reputation,
repeatability, and XP-to-growth conversion.
