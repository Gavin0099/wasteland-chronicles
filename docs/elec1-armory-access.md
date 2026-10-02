# ELEC-1 — Electronics opens the armory

Risk: L2 (encounter authorization, resource consumption and receipt persistence).
The aspiration is: "I want the armory's weapon without becoming a mechanic."
Electronics now provides a second build path to the existing place and prize.

At the old armory, ELECTRONICS 2 plus two scrap can bridge the controller.
It costs one real travel day, consumes the two scrap, grants electronics practice
and offers the same saber and three scrap as mechanical entry. Existing carrying
capacity and daily survival still apply. Both entries share the same prize-taken
receipt; taking the saber closes both. Mechanical entry remains MECHANICS 2.

Gray Valley's electrical repairer teaches rank 0 to 2 using existing two-day,
60/120-cap lessons. Earned growth points can also raise ELECTRONICS. Rumors,
map status and the encounter explain both routes and the material cost.

Acceptance: actual lessons and road journey; missing skill/material refusals
preserve world hash; real costs and practice; same one-time prize after either
entry; checked save/load, continuous/resumed SHA and global invariants; existing
mechanical saves remain valid. Inspect both supported window sizes. Human
playtest should assess whether learning electronics creates a wanted alternative;
technical checks cannot close that question.

Validation: all 102 Godot suites exited 0, no SCRIPT ERROR. Focused suite: 50
assertions; replay SHA-256
`698e6277c2f92b5aa7d42afbe71a6556d5aef7371e6a39b07b1d929ffd9ea6b4`.
Independent review: no unresolved P0/P1. Six actual teacher/gate/receipt screens
inspected at 1280×720 and 1152×648 using tools/capture_elec1.gd. Lint zero errors,
one baseline dynamic-node warning; NPC fixtures and governance drift pass.
Existing UI teardown leak diagnostics remain. Remote review/CI/merge pending.
