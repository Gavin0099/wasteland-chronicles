# WPROG-2 — Risky route

New Hope and Dry Well now offer two visible routes before departure. The
abandoned highway takes two days and raises the chance of a bandit ambush. The
wilderness detour takes four days, raises the chance of a wreck, and lowers
bandit exposure. Both routes can have quiet days and still respond to the
existing security, water, refugee and caravan facts. Route choice is stored on
the player's travel party and in the departure ledger; it survives save/load.

This is a build decision rather than an equipment lock. A machete improves a
real highway fight under the existing combat rules. A backpack improves the
value of a salvage encounter under the existing capacity rules. Neither item
changes the encounter selector directly. The player can take either route
without an upgrade and accept the cost. Other settlement pairs, NPC travel and
older saves continue using their previous travel behavior.

The selector changes **encounter weights**, not outcomes. It does not force a
bandit or wreck on day one or mint a fixed cache every trip. WPROG-3 remains
responsible for any exclusive high-tier loot. Unknown routes, unsupported
origin/destination pairs and corrupt saved route durations fail before a world
is published.

The player-facing route controls and descriptive risk/benefit copy were
captured from the real Godot renderer at 1280×720 and 1152×648. The route test
covers the UI-to-authority path, atomic rejection, legacy compatibility,
encounter distributions, checked save/load, two-track full-world SHA replay,
combat payoff and global invariants. Existing headless UI suites still print
Godot shutdown RID leak diagnostics despite exit code 0.
