# DUN-2 — Fixed waterworks layout and explored routes

Risk: L2. The owner-approved second dungeon slice expands the local place to
eight rooms without adding combat, rewards, costs, NPC lifecycles or a new save
field. Its purpose is to let a traveller choose a route, remember explored rooms
and open a shorter way home. Human observation: can the player explain where
they are, choose a different branch and recognize the newly available return?

## Authoritative contract

The fixed, bidirectional ordinary passages are:

- entrance ↔ foyer
- foyer ↔ guard, maintenance and parts_store
- guard ↔ pump
- maintenance ↔ pump
- pump ↔ control and polluted_store

The control ↔ entrance passage is initially closed. OPEN_SHORTCUT is a closed
command with only `command`; it requires an active traveller in control and a
shortcut that has never been opened. One DUNGEON_SHORTCUT_OPENED fact records
the fixed dungeon ID and control room. Opening and moving spend no time or
supplies in this slice. Repeating opening, opening elsewhere, extra fields and
attempting the closed shortcut fail atomically. The history validator checks
the shortcut against the room sequence at the moment each fact occurred.

Visited rooms and the opened shortcut derive from committed history and persist
across exits and visits. Loading a DUN-1 room checkpoint remains valid and must
not change canonical snapshot bytes. Local movement and room scenery remain
read-only presentation; arrival places the player safely beside the actual
source doorway. Unknown rooms, nonadjacent transitions and forged facts fail
the live validator and checked persistence, including snapshots without a player.

## Presentation and acceptance

The room remains the principal play area. A labeled map dialog shows visited
room names, the current room and only frontier rooms reachable from visited
rooms as unexplored. It must not reveal unvisited deeper topology. The map
pauses walking, supports keyboard opening/closing and never changes the world.
Available doorway guide commands use the actual room layout. A closed return
door is visible at control with a real command to open it; entrance shows it
only once the shortcut is open.

Original DUN-1 floor/pump artwork and the existing original sealed cargo crate
provide room scenery. Different obstacle arrangements and door locations
distinguish branches. Painted inventory items do not promise pickups; this
slice offers no loot commands. Discovery is a consequence of actual traversal,
not an achievement reward or numbered task list.

## Verification plan

Independent fixed-room/edge fixtures, both branch walks, every room's arrivals
and physical route clearance, shortcut refusal/opening/backtrack/revisit,
malformed histories, real save/load, twin SHA-256 replay and global invariants
must execute. Existing DUN-1 tests remain unchanged and pass. All Godot suites
are required for simulation changes. Capture the actual eight-room interface,
partial/complete maps, open shortcut and load at both required resolutions;
inspect action fit, actor placement, keyboard focus and read-only rendering.

Focused regression: 430 assertions, zero failures, including real engine
intents, actual disk round-trips, two-track SHA-256 replay, global invariants,
seven malformed-history fixtures run through both live/checked validators,
the independent eight-room connectivity fixture and all authored door-to-door
routes. The real Main/Continue/UI path saves and restores deep rooms and the
opened shortcut. Existing DUN-1 tests remain unchanged.

Actual Vulkan capture: 34 distinct PNGs at 1280×720 and 1152×648, 340 assertions,
zero failures or SCRIPT ERROR. The harness drives real guide-button wiring,
frame-based walking, E door/latch interactions and M/Esc map input. Root inspected
both 17-image contact sheets and native room/map/door frames. The earlier capture
overwrote the second foyer image (34 writes, 32 distinct PNGs); the final harness
names the storage-return state separately and produced 34 distinct PNGs.

Renderer review moved the shortcut line around ordinary map nodes so it does
not appear to pass through the foyer. Side-door labels use the shared opaque
PDA panel for readable text over painted equipment. Original crate artwork is
reused verbatim from `ui/assets/items/library/clothing/sealed_cargo_crate.png`,
with its existing source record beside the item library; floor/pump provenance
remains in `ui/assets/dungeon/ASSETS.md`. No asset or animation is synthesized by
the room controller.

The new PdaMapDialog variation inherits the shared PdaDialog styles and sets
`buttons_min_height` to the existing 40 px command token. Godot's native
[AcceptDialog layout](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/dialogs.cpp#L209)
replaces button custom minimums from its theme when laying out the dialog.
The failed eight button-height checks are retained in the prior renderer run;
the final 340-assertion run verifies real height and viewport fit. The builder
regenerated the shared theme; its only resource changes are this type variation
and constant. Existing dialog types are unchanged.

Low-frame-rate guide verification exposed overshooting around a destination;
pointer/guide movement now caps its step at remaining distance. The regression
executes real guide processing at 80 ms from every source doorway toward every
door and asserts it stops in interaction range while respecting obstacles.

Import, lint, debugger validation and governance drift pass. Debugger loaded
320 resources, with zero load/parse/node-configuration/physics-layer errors;
167 existing warnings remain, none in dungeon files. Both scene smoke runs pass
with 110 warnings and the existing standalone-shell seven-orphan-node finding.
Focused shutdown retains 10 dummy textures, 25 shaped text objects, one font,
14 CanvasItems and 87 ObjectDB instances. Final Vulkan shutdown retains 10
texture allocations/RIDs, 31 shaped text objects, one font, 28 CanvasItems and
111 ObjectDB instances. These are recorded exit diagnostics, not repaired or
represented as a zero-warning project.

All 127 Godot suites exited zero with no SCRIPT ERROR, including unchanged
DUN-1 at 178/0 and DUN-2 at 430/0. The later map-only button-height refinement
reran focused at 430/0 and actual Vulkan at 340/0. Independent read-only review
found zero unresolved P0/P1. Same-PR bound evidence/memory and current-head
GitHub review/CI/merge remain required.
Technical verification does not establish the eventual adventure pacing or fun.

Deferred P2: guide routing assumes the player starts on a doorway/central
corridor. From arbitrary floor points behind equipment (for example entrance
`(120,200)`), a straight first leg can stick against an obstacle. Manual movement
can restore the route; automatic arbitrary-start pathfinding is not delivered.
The previously recorded DUN-1 save-dialog row overlap also remains.

## Try it

Run `godot --path D:\wasteland-chronicles`, then enter 水廠 in Gray Valley. At the
foyer choose a doorway from the bottom selector and use 走向選取的門, followed by
E/Enter. M opens the discovered map; Esc closes it. Walk either the guard or
maintenance branch to the pump room, then to control. Approach the east return
door, remove its latch, and use the opened shortcut. Save/restart/Continue keeps
the explored rooms and opened return.
