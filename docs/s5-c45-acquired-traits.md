# S5-C4.5 acquired traits — first playable identity

Status: **partial**. `DESERT_HARDENED` is implemented; the other five planned identities are not.

Core traits still come only from character creation. Perks still come from XP milestones. Acquired traits have a separate `PlayerState.acquired_trait_ids` owner and a separate `ACQUIRED_TRAIT_ACCEPTED` history. They end with this character; this change grants no legacy bonus.

## 荒野歷練 / DESERT_HARDENED

- **Evidence:** On two distinct travel days, the player's requested water went unmet. The daily survival calculation records `PLAYER_NEED_UNMET` with exact water/food unmet ratios. Merely running out of water in a settlement, or displaying a warning, is not qualification.
- **Choice:** At a settlement, the character sheet offers acceptance. Closing the sheet keeps the current self; qualifying does not auto-grant the trait. The offer remains available while the evidence remains in this life's ledger.
- **New action:** At a rockslide, `ENDURE_CROSSING` spends one food and no extra day. A character without the trait cannot see or commit it. With no food, it is visibly disabled and the authority rejects it without mutation.
- **Limit:** It works only at a rockslide and requires a real ration. It does not change daily metabolism, HP, combat, or the world's water supply.

Checked loading and live invariants validate trait IDs, acquisition history, dated preceding evidence, and deprivation-event shape. The ledger does not independently reconstruct every travel ration calculation from old world snapshots; its committed event is the historical fact. Legacy saves without the new field load with an empty acquired set; old history is not retroactively invented.

`tests/test_s5_c45_desert_hardened.gd` exercises the normal creation and travel path, two days of unmet water, opt-in, blocked/owned encounter options, cost receipt, confirmation, checked save/load, invalid records, and two full-world SHA-256 replays. Godot screenshots are captured at 1280×720 and 1152×648 with `tools/capture_acquired_trait.gd`.

Remaining C4.5 work: five more evidence-backed identities (`CARAVAN_FRIEND`, `HARD_BARGAINER`, `KNOWN_HELPER`, `SCAVENGER_INSTINCT`, `DEATH_TESTED`), each with a supported action and real tradeoff or limit; then player experience testing. This slice does not close C4.5 or all of S5.
