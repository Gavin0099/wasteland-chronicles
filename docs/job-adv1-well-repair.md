# JOB-ADV-1 — Repair the old well's pump on site

Risk: L2, bounded player-driven production change and persisted equipment state.
Aspiration: "I want to put my mechanical skill to work and leave a working pump."

The existing old well must first be marked and reported to Gray Valley or Dry
Well. That owner then posts an eight-day repair contract while its pump is broken.
One active contract at a time; expired work can repost in a later board window.
The repaired pump stays repaired, so the job cannot mint repeat production.

Take the owning town's job, carry a wrench and three scrap, and revisit the
Gray Valley–Dry Well road. MECHANICS 2 (including Abban's existing party skill)
repairs the pump in one real day. The wrench stays; scrap is consumed. The owner
gains exactly one daily water production immediately, and the equipment receipt
records BROKEN -> WORKING with production before/after. Return to the owner for
80 base caps and 12 XP before the deadline. If payment expires after repair,
the physical improvement remains. No new NPC, autonomous repair, decay or regulator.

Equipment state derives from the ledger; old saves remain broken until an actual
repair. All new equipment receipts are checked on load, including historical ones.
The quest uses a repair objective bound to its own accepted contract, not an item
handoff. The board, encounter, result and map communicate that distinction.

Acceptance: mark/report -> accept -> actual revisit -> repair -> return/reward;
negative skill/tool/material/deadline/location and duplicate paths; persisted
state and bounded production; malformed historical ledger rejection; dual-track
SHA replay and global invariants. Full regression and two rendered sizes required.
Human playtest should check whether this feels like a different livelihood.

Verification: all 103 `tests/test_*.gd` suites exit 0, with no SCRIPT ERROR.
The focused suite passes 116 assertions, including continuous versus
save/resume SHA-256
`2074b597c03e96d747b1cf9ea4914f60417cee46015258a13d8f7c06d21259d9`.
Six actual rendered contract/site/result views at 1280x720 and 1152x648 were
inspected. Existing renderer teardown RID/ObjectDB warnings remain; this is not
a clean runtime-log claim. Lint has zero errors and one existing dynamic-node
warning; NPC authority fixtures and governance drift checks pass.

Independent read-only review found no P0/P1. One P2 is deferred: the generic
payment notification currently says `已交付擊退劫匪 ×1` for repair completion.
The contract, physical pump state, production effect and paid reward are correct;
the notification needs its own repair wording in a follow-up.
