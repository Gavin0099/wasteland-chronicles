# QUEST-3 — Two simultaneous commissions

Gray Valley's board now offers a second, separate delivery: **送一條繩索到乾井**.
The existing item market supplies `rope` in Gray Valley, while Dry Well's
existing profile marks rope demand high. The player can accept either or both
commissions, buy the relevant item, travel the existing road, and deliver each
one separately. Rope has a five-day inclusive deadline and pays 65 Caps plus
20 XP. Its completion consumes one owned rope, sets
`dry_well_rope_delivered`, and writes its own quest receipt. The wrench promise
retains its eight-day deadline and its own item, rewards and world flag.

The PDA selector names and counts the visible commissions, shows their
individual state, and preserves the selected commission through refresh. A
button sends the selected stable quest ID through the existing player-intent
authority. A tracked quest stays visible after leaving its issuing town;
remote unaccepted board entries remain hidden. The selected quest's item,
deadline, reward and result receipt are not copied from another row.

This is a second playable commission, not import of the 120 editorial quest
designs. It does not create NPCs, a rope stockpile at Dry Well, a medical or
repair mechanic, dynamic prices, or skill growth. Turning in rope removes its
existing road-use possibility from the player's inventory; that consequence
comes from the existing item gate, not a new scripted effect. Both quests still
have one `DELIVER_ITEM` objective each. Multi-objective presentation, branching
resolution and job progression need separate authority and UI work.

`tests/test_quest3_multiple_commissions.gd` covers independent local
visibility, selected-ID UI routing, normal starting funds, simultaneous active
promises, independent turn-in and rewards, rejection atomicity, expiry,
save/load, full-world SHA-256 replay and global invariants. Real Godot
renderer captures at 1280×720 and 1152×648 are in `artifacts/quest-3/`.
