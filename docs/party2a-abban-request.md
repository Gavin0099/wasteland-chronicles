# PARTY-2A — Recover Abban's tool from the convoy wreck

Risk: L2, bounded authored-item recovery, transfer and receipt-derived hire fee.
Aspiration: "I want to take this detour for the mechanic travelling with me."

While Abban accompanies you, Find People offers his personal request in town:
recover his wrench from the existing convoy wreck on the Gray Valley–New Hope
highway. Accept, defer, or refuse. Deferral can be answered later; refusal is
final for this one request and never removes his normal companion ability.
Accepting preserves the destination even when ordinary wreck scrap is empty or
the place was recently passed. Dismissal pauses recovery until Abban rejoins.

At the real wreck with Abban, RECOVER_ABBAN_TOOL spends one extra road day and
places one actual wrench in the player's item inventory. It can happen only
once. Existing unique-item and capacity rules apply: carry no other wrench and
leave room for it. The authored cache is independent of caravan scrap. The
shared experience records this specific recovery day and place, not any trip.
You may keep/use/sell the tool or hand over one wrench to Abban in town. Buying
an ordinary wrench cannot bypass the accepted request and actual recovery.
Items of the same catalogue ID remain fungible after that one-time recovery.

The allowlisted RESPOND_COMPANION_REQUEST only accepts ACCEPT/DEFER/REFUSE;
FULFILL_COMPANION_REQUEST has an empty payload and removes exactly one owned
wrench. Neither action creates money, XP, skill or population. The existing
encounter action space includes the bounded recovery. Completion changes future
Gray Valley hire cost from 50 to 25 caps; road supplies and all existing hiring
guards remain unchanged. No general relationship score or new saved state/NPC.

Request response, real visit/recovery and delivery receipts derive the state.
Checked loading and global invariants reject malformed actor/target, item,
quantity, recovery reference, town, fee and duplicate completion. The PDA shows
choices, route, cost, refusal reasons, shared experience and reduced price.

Acceptance: actual accept/travel/recover/deliver/dismiss/return/rehire; defer and
refuse; bought tools cannot bypass recovery; no duplicate item or benefit;
absent companion, missing tool, malformed payload, wrong-player, road/pending/
dead-player and insufficient-fee refusals; exact domain errors for bad saved
receipts; dual-track SHA and global invariants. Full regression and rendered
views at 1280x720 and 1152x648. Human playtest remains open: does this detour feel
worth taking for Abban, and does handing over a useful tool feel like a choice?

Verification: final full run of all 104 `tests/test_*.gd` suites exits 0 with no
SCRIPT ERROR. The focused suite passes 205 assertions; continuous and save/resume
tracks have SHA-256
`ea299a860b6d5f3fbe3b9170a15c543225b6339661a7ef216134d63be0db8a78`.
Twelve actual rendered views (choices, accepted, site, delivery, completed,
rehire at both sizes) were inspected. Lint has zero errors and one existing
dynamic FieldScreen-node warning. NPC authority fixtures and governance drift
checks pass. Renderer teardown still reports baseline RID/ObjectDB leaks;
this is not a clean runtime-log claim. Independent read-only review confirms
the accepted wreck-retrieval scope and no unresolved P0/P1 findings.
The first full pass exposed the intervention test's old explicit allowlist;
its reviewed fixture now names the two newly authorized request actions and
still rejects unknown action 99. Its six gates passed after that update.
