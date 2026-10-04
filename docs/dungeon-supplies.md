# DUN-5 — Expedition time, carried supplies and treatment

Owner-authorized next slice after delivered PR75. Risk L2: clock/needs,
resource ownership and checked persistence. Preserve all population membership,
existing mortality/grace rules, daily phase order and route arrival formula.
No new entity lifecycle, regulator, town shop or free rest inside the dungeon.

## Contract

New ENTER carries `trip_rules:1` alongside route_rules1. Valid older two/three-key
entries retain cost-free trip rules0 until the next real ENTER; callers cannot
choose versions and an activated trip version cannot later downgrade.
Physical walking, map and pack browsing never mutate time or resources.

Each committed room transition under trip1 represents six expedition hours.
Four accumulated transitions advance one existing full world tick. Partial
work units persist across exit/reentry, preventing resetting the budget by
brief town visits; per-trip move/day counters reset on entry. Entry itself has
no full-day charge. Existing opened shortcut/backtrack routes remain available
even without supplies; running out is not a teleport or hard refusal.

On a dungeon day the player consumes one owned aggregate water and one food
when available. A current companion consumes its existing road_water/road_food
allowance after the player; a guide no longer waives the player's own water
underground (its existing zero-water companion allowance is retained). A pack
unable to cover both companion allowances triggers the existing HUNGER leave
fact. Dungeon supplies do not come from settlement stock or town fulfilment.
Aggregate town metabolism remains the existing coarse model and membership is
unchanged; no exact individual town-demand subtraction is claimed.

`DUNGEON_DAY_SPENT` records actual pack before/after, current companion and
whether that companion was fed. Typed live/checked validation enforces exact
payload, room/version/day order, integer amounts and the specified deduction;
an unfed companion requires its corresponding immediate leave fact. The ledger
owns accumulated work/day counters. A four-transition checkpoint cannot be
persisted without its day receipt. Existing unmet-need pressure/exposure and
grace periods apply, including actual deprivation death. A verified existing
PLAYER_DIED closes exploration with DUNGEON_TRIP_ENDED before tick validation;
no new death implementation or revival is introduced.

The clock cannot advance while a dungeon fight/result is pending. The supported
intent flow advances only on committed exploration transitions, or an actual
idle world day; no extra day is added to attack/confirmation or treatment.

Between fights use owned bandage (+2 HP) or first_aid_kit (+4 HP, capped at12)
through existing FIELD_ACTION/TREAT validation, mutation and Medicine practice.
Missing items, full health, bad types/extra fields, wrong actor, dead player,
combat/result pending fail atomically. No crafting/rest/market access is added.

## Presentation and acceptance

Shared Survivor PDA controls show actual HP, aggregate cargo total/effective
capacity and separate owned-item weight/capacity, carried
water/food, consumed days, work until next day and companion allowance. A pack
dialog lists owned items with existing icons/descriptions; treatment is an
explicit item choice and uses its real intent. Modal pack/map/save pause local
walking and do not consume a day. Refusals identify the actual missing item or
pending fight. Retreat follows actual opened doors/shortcut, with costs still
visible. No automatic potion or hidden resupply.

Meaningful tests cover four real transitions versus local walking/browsing,
carry-over/revisit, solo/companion/guide costs and departure, deprivation/death,
real treatment/once-only item use/full pack receipts, valid legacy trips,
pass/fail live and checked fixtures, twin SHA-256 replay/disk persistence and
global invariants. Run all Godot suites and render real pack/time/treatment/
low-supply/retreat/death states at1280×720 and1152×648. Independent review,
bound same-PR canonical evidence/memory, exact-head GitHub Codex and actual CI
precede merge. Human pacing/fun remains unmeasured.

## Executed local evidence

Final focused run:634 assertions/0, no SCRIPT ERROR. Actual four-transition
day deduction, carry-over across visits, companion/guide allowances and hunger
departure, grace/dehydration death, treatment item consumption and pending-fight
clock refusal are exercised. Twin canonical SHA-256 and actual disk saves cover
paid days, companions and treatment. Positive and corrupted day/need/death/
version fixtures execute checked loading and the live full invariant validator;
no mock-only schema claim. Separate 12kg item capacity remains independent of
aggregate cargo, whose consumed rations really free room for two guard scrap.

Actual Vulkan two-resolution renderer:38 captures/626 assertions/0, nineteen
captures and seventeen distinct PNG hashes per resolution. Duplicates are
intentional same-state pack and old/new entrance controls; not38 unique images.
Both contact sheets and native compact companion/normal full-pack screens were
inspected. Includes owned medical inventory, actual treatment, save/Continue,
spent time, both full budgets, Abban feeding/departure, empty-water retreat,
fatal trip closure and valid older three-key journey. Pack dialogs fit and
pause local walking; command and return heights remain at least40px.

Whole-resource debugger:327 resources loaded/0 failures,0 parse/errors,167
existing warnings and no new diagnostic. Lint0 errors/one existing dynamic
Field-node warning. Two scene smokes pass,110 existing warnings/one existing
seven-Shell-orphan finding; governance drift passes. These are not warning-
or leak-free claims: focused shutdown reports10 dummy texture allocations,
23 shaped text/one font,49 CanvasItem RIDs and155 ObjectDB instances;
Vulkan shutdown10 texture allocations/10 texture RIDs,23 shaped text/one font,
98 CanvasItem RIDs and243 ObjectDB instances. No runtime SCRIPT ERROR.

Initial focused failures exposed the road-only existing unmet-need validator
and a pack dialog that expanded above its viewport. Both were fixed and
rechecked. Two erroneous test expectations were corrected independently:
initial population is lazily initialized by the first real tick, and JSON
receipts deserialize whole numeric gains as floats. Conservation now asserts
one living human removed/one death added plus full invariants; reward tests
assert numeric amounts instead of dictionary type identity. Expanded local
walking calls the actual controller with its supported0.08-second maximum
step, keeping slow headless runners bounded without assigning room state.

Independent final implementation review:zero unresolved P0/P1. P3 recorded
and deferred:the companion allowance line still begins with「獨行」before its
actual companion name and additional costs; no deduction or ownership error.
All130 Godot suites then passed on the final core/UI/test snapshot with no
SCRIPT ERROR. Same-PR bound evidence/memory and remote gates remain pending.

Claim boundaries:town aggregate metabolism/membership remain coarse and
unchanged; historical supply receipts prove internal deduction/need context,
not complete reconstruction of every preceding purchase. Existing PR74
plausible damage-history P2 remains deferred. No human pacing/fun acceptance,
DUN-6 gear/reward/rumor, deployment, F-7 update, post-merge memory writer or
session-close inference is claimed.

## Try it

`godot --path D:\wasteland-chronicles` starts the actual game. In Gray Valley,
take carried water/food and owned medical items before selecting「水廠」.
Press B for pack descriptions, the two real capacity budgets and owned healing.
Follow入口→前廳→零件庫→前廳→入口:the fourth committed door spends one day and
one water/food; an accompanying Abban requires another of each. Local walking
and browsing are free. Exit via the south stairs, then revisit:unfinished
subday work is retained. Treatment consumes a chosen owned item only when
injured and between confirmed fights. Save/Continue preserves these facts.

Focused verification:`godot --headless --path . --script res://tests/test_dungeon_supplies.gd`.
Actual screen capture:`godot --path . --script res://tools/capture_dungeon_supplies.gd --fixed-fps 60 --disable-vsync`.
The capture script uses its own test save slot, not the player's journey.
