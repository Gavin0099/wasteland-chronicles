# DUN-3 — Room combat with reliable returns

Owner-approved slice: connect existing real turn combat to waterworks rooms,
retain room checkpoints through battles/results, handle victory, escape and death,
and grant each room's combat reward once. Risk L2. Existing named-player death,
population conservation and eight-phase day/travel formulas remain authoritative.
Enemies are catalogue opponents, not newly materialized human NPCs.

## Contract

Three rooms offer explicitly chosen fights: guard / bandit, pump / feral dog,
polluted_store / ash ghoul. A nearby enemy marker offers FIGHT with exactly
`command` and `room_id`. It requires an alive exploring player in that actual
room, no pending activity and no previous room victory. Moving itself does not
force combat; route requirements belong to DUN-4. Existing catalogue health,
damage, brace, ammunition and practice rules apply, with fatal field damage
instead of the road's protected one-HP defeat floor.

DUNGEON_BATTLE_STARTED captures dungeon_id, room_id, battle_id, enemy,
site_enemy_hp and hp. The existing monotonic field battle sequence supplies
the ID. The battle uses source=dungeon plus fixed room/dungeon metadata and
retains the home supply-shed enemy-health snapshot. FIELD_TURN and FIELD_RESULT
carry the same source/context so history and snapshots can be cross-checked.
The room ledger checks start → ordered turns → result → explicit confirmation,
and rejects stale IDs, forged room/source/enemy/health/turn/receipt facts.

While combat/result is pending, only applicable existing ATTACK, SHOOT,
DEFEND, FLEE or CONFIRM field intents are permitted. Movement, latch, exit,
rest, trading and other actions refuse atomically; direct field entry obeys the
same boundary. UI and animation never apply damage or time.

First-victory room rewards: guard 5 caps + 2 scrap, pump 2 scrap, polluted
store 10 caps + 3 scrap. Effective carrying capacity limits actual scrap and
the result names leftovers; missed loot does not respawn. Existing first-field
victory XP remains once per life. Validated victory derives room clearance;
retreat does not clear a room or award resources. Later visits cannot restart
a cleared room's encounter or duplicate its reward.

DUNGEON_BATTLE_CONFIRMED references dungeon_id, room_id, battle_id and
result_index. Confirmation restores the exact saved home-site enemy health.
A living victor or escapee returns to the same room's safe arrival doorway;
an uncleared enemy can be challenged again. Battle/save/restart/Continue and
unconfirmed results retain the pending room. A fatal result permits confirmation
but no revival, walking or further combat; confirming it ends derived exploration
and exposes the existing death summary.

## Presentation

Reuse authored enemy/player poses, equipped weapon art, deterministic telegraphs
and committed-turn animation. The waterworks has its own original opaque painted
battle background, separate from runtime actors/UI. The room marker names the
actual enemy; clearance remains visible. Real outcomes name room/enemy and return
to exploration, rather than displaying supply-shed copy or town field actions.

## Verification plan

Execute independent catalogue/reward fixtures; actual chosen fights and combat
commands, stale/forged intents, victory/retreat/fatal outcomes, carrying limits,
leftovers and blocked second rewards. Twin SHA-256 replay and actual disk loads
must preserve active battles, unconfirmed results, clearance and home-state
restoration, including an already-open home cache. Negative save/history/phase
fixtures execute live and checked validators. Check global population invariants
around actual existing player death. Preserve DUN-1/DUN-2 and road/shed saves;
run the full Godot suite.

Drive room → fight → committed animated turns → result → room and startup
Continue at both required resolutions. Inspect enemy/weapon/environment,
animation anchoring, command states, receipts and death/retreat messages.
Human pacing/fun remains an observation gate.

## Executed evidence and boundaries

- Final focused suite: 479 assertions / 0 failures / no SCRIPT ERROR,
  `%TEMP%/wc-dun3-focused-final.log`. Includes twin SHA-256 replay, actual disk
  saves/loads, room enemy/reward fixtures, real ammunition consumption and
  one-time first-field XP, full pack leftovers, zero-HP opened home cache,
  actual escape/death, and 31 forged start/turn/result/confirmation fixtures
  executed against both checked persistence and live domain validation.
- Final real Vulkan run: 34 distinct PNG / 290 assertions / 0 failures at
  1280×720 and 1152×648, `%TEMP%/wc-dun3-renderer-final.log` and
  `user://captures/dun3/`. Both contact sheets plus native battle, motion,
  pending outcome and restored ghoul room frames inspected. Commands fit both
  viewports with at least 40px height. Real committed brace/attack animation
  stays busy and read-only; reduced-motion turns, startup Continue, save menu,
  victory clearance, retreat and fatal acknowledgement also execute through UI.
- Whole debugger: 322 resources, 0 errors / 0 parse errors / 0 node configuration
  warnings / 0 physics-layer findings. 167 existing project warnings remain;
  none name dungeon scripts. `%TEMP%/wc-dun3-validation-final.json`.
- Lint: 0 errors, one existing dynamic FieldScreen node-path warning. Governance
  drift checks pass. Two-scene fuzz smoke passes; its 110 existing warnings and
  existing standalone Shell seven-orphan-node finding are not claimed fixed.
- Godot shutdown still reports resource diagnostics: final headless 16 dummy
  textures / 21 shaped-text / 1 font / 35 CanvasItem / 143 ObjectDB; final Vulkan
  16 texture allocations and 16 texture RIDs / 21 shaped-text / 1 font /
  70 CanvasItem / 197 ObjectDB. These are reported exit diagnostics, not zero
  diagnostic claims. No gameplay SCRIPT ERROR occurred in the final runs.
- Earlier failing fixture runs are retained separately under `%TEMP%/wc-dun3-*`:
  incorrect negative-fixture event selection, effective-capacity setup and
  headless default 64×64 window were corrected before acceptance. Visual
  inspection caught a ghoul white rectangle: a draw-local texture reference was
  released before deferred rendering. Room setup now retains it; actual alpha
  and corrected native renders are checked. The original PNG remains unchanged.

Whole regression: all 128 Godot suites PASS, no SCRIPT ERROR,
`%TEMP%/wc-dun3-regression-final/summary.json`, with individual suite logs.
This run executed the final core simulation snapshot (DUN-3 focused478).
Subsequent UI-only ghoul texture retention and test variable-warning cleanup
were rechecked through final focused479, Vulkan34/290 and whole debugger167
existing warnings/0 errors. The entire suite was not repeated after those
UI/test-only changes. Delivered in PR74: implementation3804074691d4e2201cbdf44f154f4b7df70d7588,
bound evidence/canonical-memory companiona621db6462e555d9d7d9717d1ff4b68b0f335c0b,
merge373a63ecd7acf0c83fb9b2009c7ed58607d9b16a (2026-10-04 08:45:39Z).
Independent implementation and companion reviews report zero unresolved P0/P1.
GitHub Codex completed on exact companion head with one acknowledged P2;
CI37189586669/job111398802897 ran on runner1000022546 with all seven steps
successful. Main synchronized clean, readonly memory guard exited0. No post-merge
writer/session_end or owner pacing acceptance is claimed.

Non-blocking P2 from independent review: at 1152px the battle result history
window initially shows the room/enemy first line; full outcome text and actual
caps/scrap receipt require scrolling. The data and confirmation command exist.
Record and defer under the reviewed-delivery threshold. Previously recorded
fixed-height SAVE-1 summary overlap and arbitrary-start DUN-2 guide collision
remain outside this slice. No autonomous pathfinding or human pacing acceptance
is claimed. Pump/floor/waterworks images are original; ghoul uses the existing
cutout and procedural combat motion, not a newly authored sprite atlas.

Exact-head GitHub P2: historical turn checks prove arithmetical health
consistency, but coordinated plausible damage and snapshot changes can still
pass without reconstructing the original gear/ammo/preparation inputs. Recorded
and deferred in PR74 issuecomment-5978225626; no complete save anti-tamper claim.
Malformed metadata types that crash comparison are a separate acceptance bug
addressed and regression-tested by DUN-4, not a reconstruction of these inputs.
