# GUN-1 — First usable firearm

Risk: L2 (combat authority, inventory consumption and persistence).

New Hope sells one old revolver (base price 160 caps, 1 kg) and individual revolver rounds
(base price 12 caps, 20 g; stack limit 100). Existing shortage pricing still applies.
These two explicit entries are the only item
promotion. The existing old_revolver artwork is reused; ammunition has a small
authored cartridge icon. The gun occupies main_hand.

SHOOT uses the same turn identity and enemy response as ATTACK. It requires an
owned equipped gun and one real round. It deals 6 + FIREARMS rank, plus the
existing prepared attack and fighter-companion bonuses, then consumes one round.
There is no hit roll, range or reload subsystem. Close attacks remain available
without ammunition and use the existing melee calculation. Shooting awards the
existing once-per-day FIREARMS practice; earned skill points can now raise it.

Rank-zero comparison, without a companion or prepared attack: the dog costs one
round and deals no damage; a bandit costs two and deals 2; a heavy raider costs
three and deals 6 before falling. These are bounded combat fixtures, not a claim
of economy balance or fun. Firearms cost cash on each shot; the rare saber and
ordinary melee retain their ammunition-free role.

FIELD_TURN carries weapon/ammo IDs, one spent round and remaining ammunition.
The checked loader validates those fields and the skill's provenance. Stale,
empty and unequipped shots fail before mutation. Saved melee fights remain valid.
UI displays damage, ammunition cost/count, refusals and the actual gun in hand;
receipt-driven recoil and reduced motion cannot mutate simulation state.
Board and rumor forecasts explicitly describe close attacks, not a shooting policy.

Pre-GUN shops load without mutation. Normal replenishment iterates the canonical
catalogue, including missing supplied entries: a revolver can return every fourth
day and a round every day. Existing quantities are never reset. This fixes the
independent review's P1 that otherwise made firearms unobtainable in old shops.

Verification: tests/test_gun1_first_firearm.gd exercises all three enemies with
continuous and resumed SHA replay, actual market purchase, atomic refusals,
practice, UI actions, corrupted receipts, legacy-market replenishment, rank and
prepared shots, and global invariants (175 assertions). Independent re-review
found no unresolved P0/P1. Real 1280×720 and 1152×648 loaded/empty gun screens
were inspected via tools/capture_gun1.gd. All 101 Godot suites have exit-zero
results on the final code, including reruns of the four old catalogue/market
fixtures and all suites run before the restock fix. No SCRIPT ERROR remained.
Lint: zero errors, one existing dynamic FieldScreen warning. NPC authority
fixtures and governance drift passed. Existing suite teardown leak diagnostics
remain a baseline limitation. GitHub review, CI and merge are still pending.
