# DUN-4 — Waterworks front route and maintenance passage

Owner-authorized next slice after delivered PR74. Risk L2: resource spending,
room authorization and checked persistence. No new NPC lifecycle or simulation
day/travel formula. Dungeon state remains a projection of committed events.

## Contract

New ENTER facts carry `route_rules: 1` in addition to dungeon/room IDs. Existing
two-key ENTER facts remain legacy rules0, so valid old explorations/history can
load and finish unchanged. The next real ENTER always records current rules1;
the intent cannot select or downgrade rules. Once rules1 exists in history,
later entry cannot downgrade to rules0. Graph geometry stays eight rooms.

Under rules1, guard ↔ pump requires a verified guard victory; escape cannot
open it. Maintenance ↔ pump requires the maintenance gate to have been opened.
Other edges and all routes back to entrance remain available. Control shortcut
continues to work after its existing latch is opened. Cleared guard and opened
maintenance gate persist across exit/revisit. No forced encounter on walking.

Only while alive in maintenance, with no combat or result pending, may
`OPEN_MAINTENANCE` carry exactly command/method. Fixed choices:

| Method | Actual requirement | Actual cost |
| --- | --- | --- |
| SKILL | Player's own MECHANICS rank ≥2 | 1 scrap |
| TOOL | Owned legacy crowbar or real-item wrench | 2 scrap |
| ABBAN | Existing current companion is Abban | 1 scrap |

The selected method is explicit; no automatic fallback or skill/companion
substitution. Sufficient scrap must exist before mutation. On success deduct
the fixed cost once and record `DUNGEON_MAINTENANCE_OPENED` with exact five-key
payload dungeon_id/room_id/method/scrap_spent/proof. Proof is the actual rank,
the actual crowbar/wrench token, or Abban ID. No extra XP, loot, practice or relationship
reward is introduced. Opening twice, wrong room/actor/type/method, extra fields,
missing ownership/rank/companion, stale context or missing scrap fail atomically.

Ordered history validates the rules for each move, guard clearance and gate
fact, exact selected-method cost and proof. The live and checked load validator
share this contract. Gate facts require rules1 and maintenance before movement;
duplicate openings and crossing closed gates fail. This is structural/history
validation, not historical inventory/equipment anti-tamper reconstruction.
PR74's acknowledged Codex P2 about plausible forged damage remains deferred.

## UI and verification plan

Use shared Survivor PDA controls. Locked doors state the actual requirement;
maintenance shows all three choices, requirements and costs. Opening commands
require reaching the gate in the room; physical walking remains presentation.
Disabled choices explain missing conditions or scrap. Success displays method
and paid cost, updates the doorway and map, and restores normal interaction.
Failure text directs the actual next choice/backtrack rather than falsely
suggesting corrupt save/reload. Reuse original floor/pump/crowbar/companion art.

Verify each method, both route gates, actual cost, once-only spending, escape,
backtracking, disk saves/revisits, legacy rules0 continuation and current-rules
reentry. Twin SHA-256 replay and global population invariants remain mandatory.
Pass/fail fixtures execute both live and checked validators; existing DUN-2/3
tests explicitly retain legacy checkpoint fixtures while this slice verifies
current ENTER and gates. Run all Godot suites, lint/debugger/drift/smoke, and
actual rendered maintenance/guard states at both required window sizes.

## Executed evidence and boundaries

- Final focused:1028 assertions /0 failures / no SCRIPT ERROR,
  `%TEMP%/wc-dun4-focused-final.log`. Includes actual three-method costs,
  once-only opening, disk/revisit/dismissal, twin SHA-256 replay and global
  invariants; actual front escape/rechallenge/victory; missing requirements,
  legacy continuation/reentry and malformed opening/movement fixtures.
- Typed persistence acceptance found a real failure: source=false in an
  actual FIELD_TURN caused a String/bool comparison exception and checked load
  returned success. Field wire/result and Dungeon history/snapshot now check
  type before comparison. Four actual valid battle-phase controls plus 148
  malformed text/numeric/bool history/snapshot cases execute checked and live
  rejection. Retained first probe and intermediate receipt-HP errors in
  `%TEMP%/wc-dun4-source-probe.log` and `wc-dun4-typed-focused.log`; final
  focused has no SCRIPT ERROR. No plausible historical-damage reconstruction.
- Final UI renders:54 distinct real Vulkan PNG /754 assertions /0 failures,
  27 states each at1280×720 and1152×648. Both contact sheets and native
  skill/missing-tool/Abban-map/opened-gate frames inspected. Actual method
  buttons, map pause/return, physical guide, disabled gate, cost notice,
  preserved local position and startup Continue execute through UI. Commands
  fit viewports and have at least40px height; arena remains at least340px.
  `%TEMP%/wc-dun4-renderer-final2.log`, `user://captures/dun4/`.
- Whole debugger:324 resources,0 errors /0 parse errors;167 existing warnings,
  no new warning. Lint0 errors /one existing dynamic node-path warning.
  Drift PASS. Two-scene fuzz smoke PASS,110 existing warnings and the existing
  seven-orphan Shell finding remain qualified. Logs `wc-dun4-validation-final.json`,
  `wc-dun4-lint-final.json`, `wc-dun4-drift-final.log`, `wc-dun4-smoke-final.json`.
- Shutdown resource diagnostics remain: headless10 dummy textures /31 shaped
  text /1 font /56 CanvasItem /177 ObjectDB; Vulkan10 texture allocations and
  10 texture RIDs /31 text /1 font /112 CanvasItem /279 ObjectDB. These are
  reported diagnostics, not zero diagnostic claims.

Whole129 Godot regression PASS with no SCRIPT ERROR against the final core,
`%TEMP%/wc-dun4-regression-final2/summary.json`; every suite exited0. Focused
1028 and Vulkan54/754 are also on this final core/UI snapshot. The earlier129
run had one failing animation suite because36 imported pose references were
absent; actual editor import restored them before the passing full run.
Delivered PR75: implementation63588da91bd93a30f4302716c34a9bfda3dc62b0 and
bound evidence/canonical companion10981e859f0397535d9c8950bb8e4bb48a006ca1.
Independent implementation/companion zero unresolved P0/P1; exact-head Codex
completed2026-10-04 09:36:22Z with no findings and bot+1 confirmation. Real
CI37192485908/job111407421011 runner1000022557/seven steps PASS. Merged
34d7ea13bf7a61a821640abe3c11d230e9ae379a at09:38:31Z; main synchronized clean,
readonly memory guard exit0. No post-merge writer/session_end, second closeout
PR or human pacing/fun acceptance is claimed.

Independent P2 recorded/deferred: map closed passages use only red versus grey
lines, so color-impaired users cannot distinguish that map cue. Actual door
text, interaction refusal and method requirements remain readable. DUN-1 save
summary overlap, DUN-2 arbitrary-start guide collision and both DUN-3 P2 findings
remain qualified rather than silently claimed fixed.
