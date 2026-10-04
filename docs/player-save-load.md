# SAVE-1 — player-owned manual save/load

Risk: L2 (persistent data integrity). Owner authorized the next slice on 2026-10-04.

One local slot lives at `user://saves/journey.json`. Startup offers New Journey
and Continue; the map and field/battle toolbars offer Save/Load. New Journey does
not delete a prior save. Saving is explicit, with no autosave or cloud storage.

The slot is the existing canonical WorldState JSON, including the event ledger,
inventory, jobs, companions, travel interruption, battle turn and unconfirmed
receipts. UI selection, dialog position and animation playback are transient.
Opening/closing menus never ticks the world. Loading an active field battle or
receipt restores its screen without resolving it or replaying rewards.

Raw bytes enter `WorldState.from_json_checked` before any JSON transformation.
The candidate must have a player and pass global invariants before Main replaces
the live world/shell. Failed loads keep the live world and UI. Continue is disabled
for missing/invalid/unreadable saves, with a visible explanation. In-game Load
requires confirmation of the saved character/day and loss of unsaved progress.

Save validates a canonical snapshot, writes/flushes/closes a sibling temporary
file and checks its exact bytes and checked decoding. It moves the old slot to a
sibling `.bak` before promoting the temporary file to the now-empty slot. Failed
promotion restores the old file. If restoration also fails, the retained backup
is loadable at startup when the main slot is missing, labelled as a recovered
previous save. The backup is removed only after successful promotion. A leftover
temporary file is never offered as a save. This is recoverable single-process
replacement, not multi-process locking or power-loss/filesystem certification.

Independent review found that installed Godot 4.7.2's Windows rename deletes an
existing destination before moving the source. The original direct overwrite was
therefore rejected before delivery. All replacement renames now target absent
files; regression injects promotion/restoration failures and checks actual disk
bytes, fresh-store recovery and actual Main Continue. Engine source:
https://github.com/godotengine/godot/blob/ed1daf0bf/drivers/windows/dir_access_windows.cpp#L319-L325

Verification plan: actual disk round trips and uninterrupted versus reloaded
SHA-256 replay/global invariants; real travel interruption/receipt and battle
turn/result continuation; corrupt JSON/rank tokens/ledger/invariants, missing
player, failed writes; actual main/menu confirmation/cancel/failure/restart;
all Godot suites, import, lint, drift; renderer at 1280×720 and 1152×648;
independent read-only review, canonical companion, exact-head GitHub review and CI.

No simulation formulas, population lifecycle or autonomous actions change.
PR70's allied-betrayal wording and compact growth clipping remain separate follow-ups.

## Local verification

Final focused regression:271 assertions, zero failures. It executes actual disk
storage, two-track SHA-256/global invariants, real jobs/equipment/Abban and his
accepted request, travel choices/receipts, home and legacy hunt battles, one-time
acknowledgement, and existing survival death without resurrection. The mortality
fixture uses the existing engine travel/wait entry points with an explicitly
empty pack, not player clicks or a change to mortality rules. Main UI cases cover
creation, save failure, cancel, corrupt/valid changed slot after preview, fresh
Continue and backup recovery. Promotion/restoration fault injection checks real
disk bytes and ordinary reload, not only mocked return values.

The first regression fixtures mistakenly targeted an unused ledger key and a
nonexistent rank value; these were corrected to `events` and the reviewed
MECHANICS2 raw-token fixture. A home combat defeat was initially assumed fatal;
the existing game keeps that player alive, so death coverage now drives actual
daily survival instead. Production behavior was not changed to fit tests.

Final full regression after the Windows fix and expanded cases:all125
`tests/test_*.gd` exit0/no SCRIPT ERROR (wrapper `wc-save1-regression-converged`).
Lint reports0errors and the existing dynamic FieldScreen path warning. DriftPASS.

Renderer:32 actual Vulkan captures at1280×720 and1152×648,234assertions/0,
all inspected. Startup missing/corrupt/recovery, long-name in-game missing/save/
write failure/load confirmation/failed load, real restarted battle and victory,
road result and toolbar entries were checked. Actual Escape, safe confirmation
focus, fit and read-only rendering are exercised. A first harness pressed the
second battle command before presentation finished; it now waits for the real
busy flag before pressing the next real button. Screenshots are in local Godot
user data under `captures/save1`; no screenshot assets enter the game.

Known P2 presentation limit: a freshly loaded in-transit Shell has no cached town
picture, so its left settlement scene panel is blank; the route/receipt and
Continue command remain usable. General travel-scene rendering is not repaired.
Shutdown warnings remain:focused14texture/16shaped-text/1font/28CanvasItem/
117ObjectDB; renderer20texture/21shaped-text/1font/84CanvasItem/232ObjectDB.
No clean shutdown or long human-play acceptance is claimed.

Independent Windows-fix convergence reports no unresolved P0/P1. Final evidence
convergence, canonical companion and exact-head GitHub review/CI precede merge.

Manual check:run `godot --path D:\wasteland-chronicles`, create a journey, open
`存讀檔` on either toolbar and save. Close/relaunch and choose `繼續遊戲`.
Repeat during combat and before acknowledging a result. Load prompts before
discarding unsaved progress. This remains one explicitly saved local slot.
