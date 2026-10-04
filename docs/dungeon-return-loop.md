# DUN-8 — Bring the waterworks journey back into town

Final authorized first-dungeon slice, after PR78. L2 ledger/trust/action risk.
Reuse existing market, rumors, well-repair contracts and faction thresholds;
no new life/population/day/travel formula, item, stat, quest system or NPC agency.

REPORT is an explicit command-only DUNGEON_ACTION. Requires a living idle player
actually settled in Gray Valley, outside the dungeon, a real permanent device
decision and a subsequent real entrance-stairs exit. The report is optional;
defer and keep/sell the loot without reporting. PRESERVE reports +3 local Gray
Valley trust and therefore +3 existing forge faction standing; SALVAGE reports
−3. No money, XP, items or extra day, and no second award on revisit. Existing
faction thresholds, shared services and non-compounding modifiers remain intact.

DUNGEON_REPORTED contains exactly seven facts:site,room_id outside,choice,
decision_index,settlement_id Gray Valley,faction_id forge,standing_delta +3/−3.
History validates typed exact values, the real decision index/choice, subsequent
real exit, outside-home travel prefix, alive history, pending activity and once.
The current authorizer also checks actual life/membership/activity. New reporting
uses valid existing DUN-7 decisions without rewriting trips or requiring re-entry.
Trust folds the validated report; narrative/UI holds no mutation authority.

A shared PDA waterworks record window in the current town action row shows
discovery/once-only loot/device/report status, both voluntary report consequences,
and grounded next actions:existing local market, existing old-well rumor pursuit,
or actual dungeon revisit. It explains that repair still needs a claimed well,
an accepted contract, skills, materials and travel. Existing field-repair kit
reduces mechanical repair scrap3→2; it does not instantly repair a town.
The device dialog also explains later voluntary report consequences before
preserve/salvage. No automatic sale, repair or reputation change on exit.

Acceptance:actual entire prepared dungeon→loot→device→exit→report→sale or keep
→real old-well claim/contract/travel/repair/payment, with existing production
effect and2-scrap tool discount; both choice reactions/shared faction projections,
no duplicate report/loot/device, optional defer, actual market and rumor buttons,
Continue/revisit, typed positive/negative live+checked fixtures, twin SHA-256,
disk/global invariants, all Godot suites, native1280×720/1152×648 renders and
40px commands. Independent implementation/companion, bound canonical evidence,
exact-head Codex/real CI, merge/sync/readonlyguard remain required. Human10–20min
pacing/fun is unmeasured; earlier recorded P2 remain deferred.

## Verification and playtest

Focused:`godot --headless --path . --script res://tests/test_dungeon_return_loop.gd`.
Capture:`godot --path . --script res://tools/capture_dungeon_return_loop.gd --fixed-fps 60 --disable-vsync`.
Both use private dungeon save slots, not the player's save. Current focused1134/0
includes actual optional-deferred report after travel/home arrival, pending
battle/result and confirmed death refusal,35typed malformed fields and11fixed
context/owner/duplicate fixtures through both live and checked-load validators.
The persisted ledger canonicalizes numbers to floats at record time; trust uses
numeric equality so both+3/-3 actually survive commits and disk reloads.

The whole-journey twin uses reviewed initial owned mask/knife/armor/bandage/rope,
supplies and500caps; real hire/gate/rations/rope crossing/bribes are committed,
and timed detours are not silently ignored. Mask's original road acquisition
is separately covered by existingGEAR-2E suites. The keep branch actually claims
the existing well, returns for an owner-issued contract, repairs with2scrap and
one day, returns within the committed deadline and receives the accepted88caps
and authored12XP. Report3 + existing claim3 + quest2 yields Gray8/forge8:
existing peer cooperation pays1.05, local regular1.1 without compounding.
The alternative actual market sale removes the owned unique tool and pays cash;
revisit cannot respawn it or repeat the device/trust outcome.

NativeVulkan28distinctPNGs/744assertions/0 at1280x720 and1152x648; both contact
sheets and full-size returned record/owned loot/actual2scrap repaired-production
receipt inspected. Four action commands and defer are visible and at least40px.
Debugger335resources/0errors/0parse/167existingwarnings after test-variable
shadow cleanup; lint0errors/one existing warning; two scene smokes pass with110
existing warnings/seven existing Shell orphan nodes. Drift check passes.
Initial helper name collisions, a temporary test-only rename typo, and the
actual float-trust defect were repaired; early failed runs are not acceptance.
Headless shutdown:14dummytextures/28text/one font/35Canvas/144ObjectDB;
native shutdown:14textures/RIDs/28text/one font/70Canvas/200ObjectDB. No zero-leak
claim. All133Godot suites pass/exit0/no SCRIPT ERROR on final production,
including the initial1039-assertion DUN-8 test; added final refusal coverage
separately passes1134/0. Raw suite logs/summary in the task's private TEMP
wc-dun8-regression-final directory. Bound focused receipt will be committed as
artifacts/evidence/test-results/dungeon-return-loop.json/.txt. Remote exact-head
Codex/real CI/merge/sync/readonlyguard remain pending before PR delivery.

Independent implementation review zero unresolvedP0/P1. One non-blockingP3
acknowledged/deferred:the already-reported record still phrases defer/general
copy as「暫不回報／可自願回報」while the actual report command correctly shows
「已回報」and is disabled. Do not change the head solely for this text polish.

Manual:`godot --path D:\wasteland-chronicles`. Create a mechanic in Gray Valley,
prepare mask, weapon, armor, companion and supplies, then visit「封存水廠」.
Explore at your pace; after a device choice exit via entrance stairs and select
「水廠紀錄」to report or defer, open the market, pursue the old well, or revisit.
Nothing is sold/repaired/reported automatically on exit. Human journey pacing
and fun still require playtesting.
