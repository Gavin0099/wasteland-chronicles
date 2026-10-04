# DUN-6 — Prepared polluted-wing exploration and useful tools

Owner-authorized sixth slice after PR76. L2 action/persistence risk. Reuse the
existing eight rooms, combat, authored mask/tool definitions and clock. No new
NPC lifecycle, population container, loot randomness, repair system or DUN-7
device/relationship outcome.

New ENTER adds deep_rules1 to existing route/trip versions. Valid older entries
retain their original polluted-wing access until next entry; activated deep
rules cannot downgrade. Current entry into polluted_store requires an actually
owned military_gas_mask. This existing item has no equipment slot:carrying it
uses the same protection convention as the toxic road workshop; it is retained,
not silently consumed or equipped. Returning to pump is always allowed. A
deep1 pollution transition carries the fixed protection_item proof. Ordered
typed live/checked history validates this proof, version, legal source/target
and exact payload, without claiming full historical inventory reconstruction.

After the actual polluted-room ghoul victory is confirmed, explicitly recover
one existing fieldrepair_precision_kit at the visible tool cache. Requires a
living idle player in that room, current deep rules, confirmed clearance and
actual owned-item capacity. An already-owned unique stack or full item budget
refuses atomically and leaves the cache available; successful real pickup
records DUNGEON_TOOLS_RECOVERED exactly once across sale/drop/return visits.
No new item, bonus XP, extra day or automatic pickup. Existing caps/scrap combat
rewards remain separate. The recovered authored mechanical tool3 reduces
existing mechanical well-repair scrap by one; skills are still required.

A Gray Valley waterworks rumor joins existing heard/tracked projection. It
points at the real dungeon and describes route, mask, supplies, capacity,
clearance and actual recovery status. Choosing to track is optional; prepared
players can finish in one visit. First unprepared visits can open the bypass/
shortcut, encounter the mask gate, return, prepare and revisit without losing
discoveries or charging already-open gates. The available mask source remains
the existing sealed road checkpoint, reached via its actual rumor/journey.

Shared Survivor PDA door captions/refusals, a real existing tool icon/cache
interaction and pack descriptions show the requirements and useful reward.
No hidden direct UI world mutation; physical walking remains presentation and
all changes use authorized intents. Acceptance:actual first refusal/revisit,
prepared single-visit reward/return, optional rumor pursuit, full/duplicate
capacity rejection, once-only recovery, typed positive/negative live+checked
fixtures, twin SHA/disk/global invariants, all Godot suites, two-resolution real
Vulkan screens, independent review, bound same-PR memory/evidence, exact-head
Codex/actual CI then merge. Human pacing/fun remains unmeasured.

## Executed local verification

Final focused harness:614 assertions/0 failures, including real walking,
owned-item descriptions, optional rumor tracking, confirmed fights, capacity
refusal, explicit recovery, retreat/revisit, twin SHA-256 replay, disk roundtrip
and positive/negative live and checked validators. Final Vulkan harness:38
distinct PNG captures/628 assertions/0 failures,19 at each of1280×720 and
1152×648. Both contact sheets and native-size rumor, mask and recovered-pack
screens were inspected. The prepared pack weighs4650g and displays4.7kg;
aggregate cargo remains a separate budget.

Project debugger loaded329 resources with0 errors/0 parse errors/167 existing
warnings and no new node warnings. A new test-helper parameter shadow warning
was removed by renaming that parameter only. Lint:0 errors/1 existing warning.
Both scene smoke checks passed with110 existing warnings and the existing
seven-node Shell shutdown orphan group. Governance drift passed. All131 Godot
suites passed with no SCRIPT ERROR. The first81 recorded PASS/exit0 before the
runner was interrupted; the remaining50 completed on the same production
snapshot. The test-only helper rename changes no behavior. Combined summary:
%TEMP%/wc-dun6-regression-final/summary.json. Remote delivery remains pending.

Earlier attempts are not acceptance evidence:the first rumor test exited0
despite a SCRIPT ERROR from an indentation error, fixed before the40/0 clean
rerun. An incorrect4.6kg display expectation was corrected against independent
4650g inventory weight. Headless Dummy popup geometry reported1×1 for the
existing rumor dialog, so the CPU fixture materializes its requested640px/
80%-viewport size only under headless; actual Vulkan captures use production
geometry. The real card is scrolled fully into view and its choice is verified.

Independent final implementation review:zero unresolved P0/P1. Two P2 findings
are recorded and deferred under the delivery threshold:the discovered map's
polluted-wing edge checks the always-allowed exit direction, so it can omit the
locked reverse-entry mark after dropping the mask; the actual door still
refuses. Rumor guidance suggests clearing the pump-room threat although only
the polluted-room ghoul is required for this reward. Neither finding changes
the reviewed head solely for polish/guidance.

Claim boundaries:the focused prepared fixture owns the existing registry mask;
actual acquisition on its original road journey is covered by the existing
GEAR-2E suite, not claimed as part of this fixture. Historical fixed protection
proof does not reconstruct every past purchase/drop. No full save anti-tamper,
human pacing/fun acceptance, DUN-7 behavior or deployment is claimed. Shutdown
diagnostics remain qualified:headless15 dummy textures/31 text/1 font/42 Canvas/
164 ObjectDB; Vulkan15 textures/15 RID/31 text/1 font/84 Canvas/233 ObjectDB.

## Try it

Start with `godot --path D:\wasteland-chronicles`. In Gray Valley, read the
waterworks rumor or enter directly. Carry the existing military gas mask,
water/food, a weapon, medical items and at least1800g free item capacity. Open
the maintenance passage or clear the guard, reach the pump, then enter the
polluted store. Confirm the ghoul victory and walk to the tool cache to recover
the precision field-repair kit. B shows its existing mechanical3 property and
one-scrap mechanical repair saving. Open the control-room shortcut to return;
Save/Continue and later visits retain clearance and the once-only reward.

Focused check:`godot --headless --path . --script res://tests/test_dungeon_deep_reward.gd`.
Actual capture:`godot --path . --script res://tools/capture_dungeon_deep_reward.gd --fixed-fps 60 --disable-vsync`.
The harness uses its own dungeon test save slot.

## Delivered

PR77:implementationff43d0d454017958d70e2fa7e5aafe27c7bbcb09 and separately
reviewed companion3918471b26fb61193cc2415aea853e9a0d8f3bf7. Bound receipt
614/0/exit0. Exact3918471 Codex completed2026-10-04T12:09:47Z with one P2:
rumor guidance omits an already-owned unique kit although real pickup refuses
correctly. Acknowledged/deferred in PR comment5979779726 without head change.
CI37200901449/job111432198692 ran on runner1000022589, seven successful steps.
Merged2026-10-04T12:10:47Z as90e1468ad443b5c4abf05b57bfb7e8110ac2bbf1;
main synced clean, readonly guard0/current and repo B0=0/mismatch0/unbound0.
No post-merge writer ran. Both independent reviews had zero unresolved P0/P1.
