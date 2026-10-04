# RLY-1 — 舊中繼站首次探險

Owner approved the RLY-1–8 adventure direction and sequential reviewed delivery on 2026-10-05. This PR implements RLY-1 only. Risk: L2, because command authorization, checked historical state and the existing daily simulation are involved; population lifecycle and the eight-phase travel formula remain unchanged.

Player aspiration: 「我想先買工具，繞過守路的野犬，把保管室裡的軍用背包帶回來。」

## Contract before implementation

- Gray Valley residents provide a rumor about a real, fixed relay station. Entry is an explicit existing DUNGEON_ACTION with `site_id=dungeon:buried_relay`; absent site_id retains the waterworks contract. Unknown sites and extra command fields fail closed.
- Five fixed rooms: entrance, watch corridor, maintenance tunnel, records room, vault. Entrance connects to the corridor; inspecting the entrance discovers the tunnel. The corridor–records passage requires a confirmed victory over the existing feral dog. The tunnel–records passage requires an owned wrench or crowbar and two scrap, consumed once when explicitly opening it. Both routes reach the same records room, where a once-only access-card discovery opens the actual vault. No unused future-location promise.
- The access card is a site-bound ledger fact, carried in the explorer's journal, rather than a tradable inventory stack. It only opens this vault. The vault contains one existing, equippable military backpack: actual item capacity is checked before pickup, refusal preserves the reward, and taking/selling/dropping it never respawns the site reward.
- Four room transitions advance one day through the existing world tick and personal-needs phase. Fractional work carries across visits. Existing companion rations, treatment, hunger departure and player mortality apply; no new time formula or hidden rest/reset.
- Relay events use a separate `RELAY_` ledger namespace. Waterworks facts, saves, rewards and standing remain unchanged. Exactly one local exploration activity is allowed. Combat uses existing Field turns, animation and monotonic battle IDs with an exact relay site/room context; pending receipts require confirmation, escape does not clear the corridor, and death cannot revive an explorer.
- Within-room walking is presentation only. Room, discovery, gate, card, reward, combat and time receipts survive checked save/load and Continue. Save menus pause movement without simulation effects. Retreat is available by backtracking to the entrance, including before either gate is opened.
- Original relay-room presentation ships with this slice, using existing survivor poses, shared PDA controls and receipt-driven combat motion. No turret, wanted-person lifecycle, live capture or mechanical dog is implemented here.

## Verification plan

Execute focused positive/negative fixtures through both live validators and checked disk persistence; dual-track SHA-256 and global population invariants at each meaningful checkpoint. Cover both approaches, owned-tool and scrap failures, gate forgery, wrong actor/site/room, concurrent waterworks/road/combat locks, capacity refusal and retry, once-only discovery/loot, retreat/revisit, daily rations/death, pending combat/escape/death, field snapshot restoration and legacy waterworks saves. Run all tests/test_*.gd with exit 0 and no SCRIPT ERROR after simulation changes. Verify real UI and immutable presentation, and inspect native rendered screens at 1280×720 and 1152×648. Independent review precedes commits/PR; exact-head GitHub review and real CI precede merge.

Human playtest remains separate: Does the rumor make a normal new character want the backpack? Does preparing a tool feel worthwhile? After returning with it, does the player choose a heavier or longer expedition?

## Implemented behavior and local evidence

The normal-start fixture buys a wrench and two scrap with the actual starting money, finds and opens the side passage, retrieves the real backpack, retreats, equips it and revisits without respawning loot. The combat approach checks actual attack/escape/death/confirmation, source-room restoration and isolation from waterworks rewards. Companion fixtures cover Abban's real extra ration and hunger departure; six-day water exposure covers the existing deprivation death rule. Forged gate, supply, owner, room, battle, health, event-order and mortality records are executed through live global validators and the checked disk loader. Both replay tracks check full-world SHA-256 and global invariants.

- Focused: `godot --headless --path . --script res://tests/test_relay_exploration.gd`: 819 assertions, zero failures, exit 0, no SCRIPT ERROR.
- Native Vulkan: the same script with `-- --render-dir=artifacts/rly1-rendered`: 847 assertions, zero failures, exit 0; 28 capture files (26 distinct image hashes) at 1280×720 and 1152×648. Entry, map, side gate, card, available/empty vault, supplies, save/Continue, actual dog combat, attack motion, result and wrong-city refusal were rendered. Primary actions and the relay map/refusal native confirmation buttons are measured at least 40 px; actual UI actions mutate only through engine intents.
- The first full run exposed an asynchronous test-harness error: it requested CONFIRM before the existing battle animation had finished. A bounded wait for the actual busy state fixes that test without changing combat authority. Final full rerun: all 134 tests/test_*.gd suites pass, wrapper exit 0, every suite exit 0 and no SCRIPT ERROR; summary in `artifacts/rly1-rendered/full-suite-summary.json`.
- The debugger's 14 new test shadowing/unnecessary-await warnings were corrected through parameter naming and removal of synchronous awaits. Final debugger: 339 checked, zero errors/parse errors/configuration findings, 167 prior warnings and zero relay warnings. Focused recheck remains 819/0, exit 0, no SCRIPT ERROR. Static lint: zero errors and one existing dynamic-node warning. Both fuzzed scene smokes pass; their existing 110 warnings and seven shell orphan nodes remain. Governance drift passes.

Shutdown diagnostics remain: focused 15 texture /27 text /1 font RIDs, 56 CanvasItems and 188 ObjectDB instances; native 15 rendering textures, 27 text/1 font RIDs, 56 CanvasItems and 173 ObjectDB instances. These are not claimed fixed or evidence of clean shutdown. Shared save/supply dialogs retain their prior native-button presentation; the new relay map and entry refusal satisfy their own native 40 px gate.

Independent review P2, acknowledged/deferred: closing supplies or treating refreshes the current room and returns the presentation-only walker to that room's arrival point. The authoritative checkpoint, discoveries, inventory and time remain unchanged. No head change is made solely for this nonblocking refinement. Human pacing/fun and full save anti-tamper protection are not claimed.

## Try the expedition

Run `godot --path D:/wasteland-chronicles`. Create or continue a living character, reach Gray Valley and choose 「中繼站」. Follow the front corridor for a real fight, or buy a wrench and two scrap and inspect the entrance drag marks for the maintenance route. Walk with WASD/arrows or click the floor; E/Enter interacts nearby. M shows the discovered map, B opens owned supplies, Esc opens save/load. After retrieving the backpack, backtrack to the entrance, return to town and equip it in 「人物」. Its cargo budget becomes 32; the separate formal-item budget remains 12 kg.

## Next authorized slices (sequential, no advance implementation)

RLY-2 named-target investigation/escape; RLY-3 turret control; RLY-4 disarm/live capture; RLY-5 disposition; RLY-6 mechanical dog; RLY-7 return reactions; RLY-8 normal-start full journey. Named-target and custody lifecycle decisions require their own contract before implementation.
