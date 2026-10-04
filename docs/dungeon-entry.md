# DUN-1 — Waterworks entrance and exploration checkpoint

Owner authorized the eight-slice first-dungeon plan on 2026-10-04. This slice
lets a living player stopped in Gray Valley enter the sealed underground
waterworks, walk through its entrance and equipment foyer, backtrack, leave
through the entrance stairs, save, and Continue inside the remembered room.

## Contract and boundaries

Risk: L2, because a new player action crosses simulation and persistence boundaries.
The existing settlement population membership, NPC lifecycle, population
conservation and eight-phase day/travel formulas remain unchanged. These rooms
are a local place near Gray Valley, not another population container or route.

`PlayerIntent.Action.DUNGEON_ACTION = 21` is the only new action. Its closed
commands are ENTER, MOVE and EXIT. ENTER and EXIT carry only `command`; MOVE
carries exactly `command`, `from_room_id` and `room_id`. Only entrance ↔ foyer
is adjacent. Enter requires an alive settled player in Gray Valley with no
road encounter, pending travel result, field battle or unconfirmed field result.
Exit requires the entrance. Wrong owners, commands, types, extra payload fields,
stale source rooms, unknown destinations and repeated entry/exit fail atomically.

One committed event follows each successful action: DUNGEON_ENTERED,
DUNGEON_ROOM_ENTERED or DUNGEON_LEFT. The site ID is the fixed
`dungeon:sealed_waterworks`; no timestamps, random IDs or parallel room-state
counter are introduced. Current room and arrival doorway derive from ordered
events. Checked loading and global invariants execute the same history validator,
including on snapshots with dungeon facts but no player. Events validate their
owner, site, exact payload, day and legal transition sequence.

Walking, animation, pointer targets and doorway proximity are local presentation.
Room transitions use engine intents. A load reconstructs the safe arrival point
inside the saved room, not the interrupted animation frame or exact walking pixel.
Only room checkpoints are promised. Doorway proximity is an interaction affordance,
not a persisted simulation collision rule. Other player intents are locked until
exit; the direct journey and field entry points also reject while exploring.

DUN-1 entry, movement, room transitions and exit spend no days or supplies and
grant no rewards. Trip costs arrive in the separately authorized DUN-5 contract;
there is no loot/XP/health benefit to repeating this first slice's room loop.

## Controls and rendering

Town toolbar: 水廠. Mouse click on walkable floor sets a walking target. WASD
and arrow keys walk with normalized diagonal speed; arrows retain arena focus
instead of triggering Control focus navigation. Approaching a door enables the
shared PDA command. E/Enter interacts while the arena has focus; Tab/Enter also
operates command buttons. Guide buttons walk along the clear central corridor.
Pointer movement respects walls and conservative pump rectangles; it does not
claim automatic pathfinding around obstacles. Esc opens save/load.

Save/load pauses room movement and restores focus on return. Continue and live
confirmed load automatically reopen the saved exploration screen. Save summaries
name the dungeon and room and state the room-entry restoration policy.

The generated concrete floor and transparent pump are original image_gen PNGs,
preserved verbatim with full prompts/provenance in ui/assets/dungeon/ASSETS.md.
Existing authored drifter movement regions provide alternating strides and a
recover stance at a stable foot anchor and scale. Reduced motion retains walking
without frame cycling. Two stride frames are delivered, not an eight-direction
character sheet. Geometry/door labels use shared Survivor PDA tokens; names and
interaction commands remain runtime text. The room fills the central screen area.

Renderer inspection found and corrected an actor transform that reset rather
than composed the room's centered scaling. Independent wide/tall-canvas fixtures
now check the expected projected foot coordinates. Door labels were widened so
the complete stair destination fits.

## Verification

The focused suite executes real engine intents, actual disk save/load, duplicate
and malformed refusals, forged history pass/fail fixtures, dual-track canonical
SHA-256 replay and global invariants. It also exercises real startup, town toolbar,
room movement/door commands, modal pause, confirmed load, restart Continue, and
return to town. Full tests include all tests/test_*.gd. The historical I2 closed
action specification was extended explicitly for the owner-approved action 21;
unknown action 99 remains rejected. Its initial failure is retained in the first
regression log; the corrected focused I1–I6 suite passed.

Actual Vulkan capture harness: tools/capture_dungeon_entry.gd. Thirteen states
at each of 1280×720 and 1152×648 cover the town command, entrance, enabled door,
visible keyboard focus, foyer, both strides, left/reduced motion, paused save,
startup Continue, continued foyer, backtrack and returned town. The harness uses
actual pointer input and frame processing for walking. Images are saved to
`user://captures/dun1/`; render/menu probes assert no world mutation.

Focused: 178 assertions, zero failures. Actual Vulkan: 26 screenshots, 156
assertions, zero failures/SCRIPT ERROR; root inspected both contact sheets and
full-resolution entrance/foyer/save/startup states. Independent read-only review
reports zero unresolved P0/P1. All 126 suites exited zero in the converged full
run (its DUN-1 snapshot was 174 assertions); the subsequent real keyboard-input
extension reran focused at 178/0. No SCRIPT ERROR in accepted focused/full/render
logs. Current-head GitHub review/CI/merge are still required. Technical pass does not establish the later
10–20 minute adventure pacing or owner fun acceptance; this is the two-room
movement/checkpoint slice only.

Known diagnostics: whole-project debugger validation loaded 316 resources with
zero load errors, zero node configuration findings and zero physics-layer findings;
167 warnings originate in existing files, with none in the new dungeon scripts.
Static lint has zero errors and the existing dynamic FieldScreen-node warning.
All two existing scenes passed the two-second input-fuzz smoke run (exit zero;
110 reported warnings and one non-failing finding, not a zero-warning claim).
Focused headless shutdown reports 10 dummy textures, 19 shaped text objects,
one font, 21 CanvasItems and 95 ObjectDB instances. Actual renderer shutdown
reports 10 texture allocations/texture RIDs, 19 shaped text objects, one font,
28 CanvasItems and 99 ObjectDB instances. These exit diagnostics are recorded,
not claimed repaired. Earlier capture fixture/name/null-shell script errors were
corrected before the successful capture; zero SCRIPT ERROR is required for the
accepted final runs. Import sidecars and known test-owned snapshot outputs are
inventoried/cleaned only after Godot processes finish and are not implementation.

Independent review P2 (deferred): the longer three-line dungeon summary in the
existing fixed-height save dialog makes its bottom return/new-journey button
partly overlap the Save/Load or Continue row, reproduced at 1152×648 (and visible
at startup). Labels and main clickable areas remain usable. No head change is
made solely for this non-blocking layout finding.

## Try it

Run `godot --path D:\wasteland-chronicles`. Start in Gray Valley or Continue a
player already there. Select 水廠, click the north door's approach or use
走向設備前廳, then E/Enter to enter. Save in the foyer, restart and Continue.
Walk south to return to the entrance, then south again to leave via the stairs.
