# WPROG-3 — Better loot

The New Hope–Dry Well wilderness detour can lead to a remote wreck. A thorough
search occasionally finds a sealed field kit with a military backpack. The
same wreck either has or lacks that cache on replay; `SEARCH`, `STRIP_PARTS`
and `USE_WRENCH` see the same cache fact, while `QUICK_PICK` cannot reach it.
Most wrecks have no military backpack. Highway and legacy wrecks retain their
old loot table. The encounter receipt names the item only if it was actually
added to inventory, and reports it as left behind if inventory rules refuse it.

This promotes one existing art asset to a formal thirteenth item. It is not
ordinary shop stock. At settlement it can occupy the back slot and raises
aggregate cargo capacity from 20 to 32, compared with 28 from the old travel
backpack. Equipping, swapping, unequipping and checked save/load retain the
same authority and overload invariant. An equipped item cannot be sold until
unequipped. A saved encounter's route must match its actual travel party, and
loot resolution reads that party rather than trusting display context. The
sealed bag contains no free weapon,
medicine or supplies. Durability and a military status are not implied.

The WPROG-3 test finds both rare and ordinary wreck days from the real selector,
travels the actual route, resolves the encounter twice, compares complete-world
SHA-256, checks receipt/ownership/save-load, and tests an overloaded bag swap
or equipped sale fails atomically. A forged highway-to-wilderness encounter
context is rejected by checked load and cannot mint exclusive loot at runtime.
WPROG-4 may later give the find another use in a higher-tier
contract; this slice creates no such contract.
