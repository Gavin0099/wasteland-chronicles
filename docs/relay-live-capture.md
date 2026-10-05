# RLY-4 — 繳械與活捉灰鴉

Owner authorized RLY-1–8, with one reviewed PR merged before the next slice. RLY-3 is delivered as PR82/main7676994087fc53895f2712e7b4f52d6761e1300f. This slice is L2/HIGH: new explicit custody constrains an existing named human, without adding a human, population container, NPC status enum or changing population/travel/day formulas. Contract and independent review precede implementation.

Player aspiration: 「我想先堵住退路，再讓他放下刀；帶第二條繩索把活人留下，之後自己決定怎麼處置。」

## Authority and bounded combat

At the relay records room, an accepted, actually alive/settled Gray Valley target can be challenged only after the RLY-2 exit block. The existing interview/escape remain separate choices; an open exit cannot secretly become custody. A first blocked challenge also records an actual face-to-face interview if no earlier interview/escape proof exists. No target teleportation or second identity. Existing RLY-1–3/waterworks/field/road saves retain their old state.

The named nonlethal duel is a separate exact typed PURSUIT ledger, routed through relay-bound DUNGEON_ACTION, not a generic creature kill. A monotonic ledger session number and exact turn/result binding reject stale commands. Target starts8HP, armed3incoming damage; disarmed1. SUBDUE uses existing actual melee equipment/rank/party bonus and a one-turn brace+2, clamped so this living person retains at least1HP. A real successful strike may grant existing MELEE practice. The UI explicitly calls it a nonlethal subdual, not a lethal firearm shot. SHOOT/KILL and future disposition commands are outside RLY-4's closed space.

DISARM takes one turn and deals0HP damage. It requires personal MELEE1 or targetHP≤3; once committed it removes the knife and uses the unarmed1damage retaliation. It cannot repeat. BRACE consumes a turn, reduces incoming damage by3 and prepares+2 for the next subdual, without stacking. RETREAT costs up to1HP, grants no loot/XP/custody and requires confirmation. Target HP and disarm state survive retreat/Continue; no invented healing/rearming. Ordinary protection applies. No world-day advancement during this pending duel, and no relay-corridor turret support against this human.

BIND requires disarmed targetHP≤3 and one more actual owned rope; the earlier exit-block rope is not reusable. Binding consumes exactly one rope, prevents retaliation and creates custody of that same living NPC. Result/explicit confirmation preserve pending UI and input locks. No direct payment, XP or creature clear from capture; RLY-2 scouting fee retains its own witnessed-proof rules. Fatal player retaliation/retreat invokes existing named-death accounting once and an actual PLAYER_DIED proof; confirmation ends the expedition without revival. All refusals stage/validate/publish atomically.

## Custody lifecycle

Custody is a fixed Gray Valley relay holding point under the player's authority, not a portable inventory item or an escort/travel party. The target remains SETTLED in the existing Gray Valley population. No population subtraction/addition, second registration or extra ration bill. Existing settlement mortality selects anonymous population; this slice does not add automatic selection of named victims. Existing named-death APIs and sourced death facts remain valid; death fixtures exercise those APIs and do not claim the settlement automatically kills a detainee.

While both custodian and target are actually alive and the bound receipt remains un-disposed, the named NPC cannot autonomously migrate: the normal decision batch omits the held individual, revalidation and direct named-migration APIs refuse. Snapshot/global/checked-loader validation rejects a migration recorded while custody was active. Existing STAY/MIGRATE for free NPCs is unchanged. Real target or custodian death ends effective custody; reducer reads the sourced death facts/life status, and a surviving free target returns to ordinary decisions on the next normal phase. Historical capture proof remains, without revival. No new autonomous release/migration action is invented. The player may return to town/travel; the detainee does not silently follow or move to another holding point.

Returning to Gray Valley displays the real held/dead/free status, but live/dead/released disposition and bounty payment are RLY-5. No handing in, executing, releasing, robot companion or future profession tree is implemented ahead of that slice. Live/checked invariants validate the own exact typed owner/target/site/room/session/turn/HP/disarm/rope/result/order and current pending player/target snapshots. Full historical gear reconstruction/tamper-proof saves are not claimed.

## Acceptance

Twin SHA-256 with global invariants and actual checked disk; real preparations/exit block, disarm-before-subdual versus weakened-target disarm, separate second rope, brace/retreat/persistent wounds/Continue, no charge/loot/XP/duplicate capture. Independently authored8HP/3armed/1unarmed/HPfloor1 and protection fixtures. Both live and checked pass/fail ledger fixtures, wrong actor/location/target/pending/dead/stale/missing rope, direct-API atomic refusals, ordinary target migration before capture versus denied after capture, owner/target mortality and conservation. Actual native named-target duel, armed/disarmed/captured/locked/receipt/Continue/reduced motion and town status at1280×720 and1152×648, original art provenance, ≥40px commands/return. Full Godot suite/debug/lint/smokes/drift; independent review, same-PR bound receipt/memory, exact-head GitHub Codex and actual CI precede merge.

Human fun/pacing and whether players value a live person over a faster fight remain playtest questions, not facts proved by these tests.


## Preparation and presentation

Rope ownership is UNIQUE: carry one to block the exit, return to Gray Valley and actually repurchase the binding rope. UI explains this. The side-route full capture fixture uses an explicitly labeled120caps budget and buys the real wrench/three scrap/two sequential ropes. No gifted skills/equipment in that flow; no claim that a normal50caps new character can immediately afford the whole route. RLY-8 checks ordinary earning/preparation and pacing.

Original1536×1024RGBA ui/assets/combat/poses/grey-crow-capture.png uses the existing portrait as an image_gen character/style reference. Six authored regions/foot anchors select armed rest, windup, extension, empty-handed guard, recoil and living tied kneel. Original bitmap/alpha unchanged. Reference485px stays constant for kneeling, avoiding enlargement. Disarm chooses empty-handed rest/attack poses. Shared receipt-only motion supplies approach/counter/brace/recoil/retreat; reduced motion keeps feedback. No third-party character/code copied. Complete prompt/source/hash are recorded alongside the atlas.

Independent review supplied isolated repros for two P1s: malformed fatal PLAYER_DIED cause could script-error/fail open; sourced external target death during an active duel could strand commands despite accepted saves. Exact typed fatal proof and fail-closed active target life/location resolve those. Live+checked regressions cover both. A captured receipt after later sourced death still confirms. Nonblocking P2 raw retaliation label1/3 does not subtract armor, while actual damage/protection are correct; deferred. Earlier RLY-1 walker/idle scan and RLY-2 secondary escape-hint P2 remain deferred.

## Verification (2026-10-05)

Final headless capture suite:1512assertions/0failures, actual twin SHA-256/global invariants and checked disk. Native final:1534assertions/0failures,22PNG/22distinctSHA-256 at1280×720 and1152×648; actual new atlas, empty-handed disarm, knife counter, brace, reduced motion, living tied result, Continue and town custody status. Actual controls are at least40px. Screens are locally available in artifacts/rly4-rendered/.

Full137-suite invocation returned exit1:136suites passed; test_combat_animation_completion.gd alone included the new named actor in its original36-pose milestone count. Its independently authored six-atlas fixture now counts only that original milestone, retains exact36 and still loads/checks every actor/region/import. The corrected suite actually reran273assertions/0failures/exit0/no SCRIPT ERROR. Production did not change during that full run; latest results across all137suites are exit0/no SCRIPT ERROR. Initial failed summary/log and successful retry are retained in the temporary evidence directory, rather than claiming the original invocation passed.

Debug348checked/0errors/167pre-existing warnings, zero new custody/capture/test diagnostics; lint0errors/one pre-existing dynamicFieldScreen-path warning. Two bounded2s fuzz smokes passed;110pre-existing warnings/seven pre-existing playable-shell orphan nodes. Governance drift and git diff --check passed. Focused shutdown still reports16DummyTexture/26text/1font/42Canvas/162ObjectDB; native16Texture/26text/1font/42Canvas/146ObjectDB. No zero-leak, runtime-soak, full historical gear anti-tamper, normal50caps preparation or human-fun claim.

The disarm motion reuses DEFEND feedback and its damage popup says「格擋」; actual knife removal, unarmed retaliation and damage are correct. This presentation P2 is recorded for follow-up alongside the raw retaliation forecast. Same-PR bound receipt/canonical memory, exact-head GitHub Codex and actual CI remain remote delivery gates; no merge is claimed by local verification.
