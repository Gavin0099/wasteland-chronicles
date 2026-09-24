# QUEST-2 — First playable town quest

The Gray Valley notice board offers **送一把扳手到乾井**. A player can accept it
while settled in Gray Valley, buy an existing `wrench` from the normal item
market, travel on the existing road to Dry Well, and deliver one owned wrench
there within eight inclusive days. Completion grants 75 Caps and 25 XP, sets
`dry_well_wrench_delivered`, and writes a `QUEST_RESOLVED` event. XP does not
raise skill ranks or growth points.

The player-facing panel uses the Survivor PDA theme and shows the deadline,
destination, required item, current ownership, reward, and the action currently
allowed by the simulation. It stays available as a tracked quest after leaving
Gray Valley. Acceptance and turn-in go through `PlayerIntent`; opening or
refreshing the panel is read-only. An accepted quest at the wrong destination
remains visible with its turn-in command disabled. A receipt waits for player
confirmation after either action.

The definition is authored in `simulation/quest_registry.gd`. Its item ID is
the existing ITEM-1/2 `wrench`; the delivery consumes the player's physical
item instance. Runtime state and rewards remain in the QUEST-1 engine. The
catalogue contained **one** playable quest at QUEST-2 closure. QUEST-3 adds a
second independent commission and a selector; the larger content-design library
remains editorial data and is not imported into gameplay. The present panel
projects the first objective of each quest, so a later multi-objective quest
needs a corresponding presentation slice before it is player-facing.

`tests/test_quest2_wrench_delivery.gd` covers local visibility, remote
knowledge isolation, illegal intents without mutation, market acquisition,
real travel and encounter continuation, deadline expiry, single transfer and
reward, save/load, two-track full-world SHA-256 replay, invariants, and the
PDA button path. Rendered screenshots at 1280×720 and 1152×648 are in
`artifacts/quest-2/`.
