# S5-C4.5 acquired traits — first playable identity

Status: **partial**. `DESERT_HARDENED` and `SCAVENGER_INSTINCT` are implemented; the other four planned identities are not.

Core traits still come only from character creation. Perks still come from XP milestones. Acquired traits have a separate `PlayerState.acquired_trait_ids` owner and a separate `ACQUIRED_TRAIT_ACCEPTED` history. They end with this character; this change grants no legacy bonus.

## 荒野歷練 / DESERT_HARDENED

- **Evidence:** On two distinct travel days, the player's requested water went unmet. The daily survival calculation records `PLAYER_NEED_UNMET` with exact water/food unmet ratios. Merely running out of water in a settlement, or displaying a warning, is not qualification.
- **Choice:** At a settlement, the character sheet offers acceptance. Closing the sheet keeps the current self; qualifying does not auto-grant the trait. The offer remains available while the evidence remains in this life's ledger.
- **New action:** At a rockslide, `ENDURE_CROSSING` spends one food and no extra day. A character without the trait cannot see or commit it. With no food, it is visibly disabled and the authority rejects it without mutation.
- **Limit:** It works only at a rockslide and requires a real ration. It does not change daily metabolism, HP, combat, or the world's water supply.

## 拾荒直覺 / SCAVENGER_INSTINCT

- **Evidence:** Three distinct wrecks resolved with `SEARCH`, each with goods or an item actually carried away. Empty searches and repeated records of the same wreck do not qualify.
- **Choice:** The survivor accepts the candidate at a settlement through the same opt-in authority; qualification alone changes nothing.
- **New knowledge:** At a wreck, the encounter screen shows what this wreck's ordinary `SEARCH` would offer before the player spends a day. The preview is read-only and matches the existing deterministic yield functions.
- **Limit:** The preview applies only to ordinary wreck searching. It does not add loot, reveal every specialized approach, or bypass bag capacity. The player can still decide that the day and rations are not worth the find.

Checked loading and live invariants validate trait IDs, acquisition history, dated preceding evidence, and deprivation-event shape. The ledger does not independently reconstruct every travel ration calculation or wreck yield from old world snapshots; its committed event is the historical fact. Legacy saves without the new field load with an empty acquired set; old history is not retroactively invented.

`tests/test_s5_c45_desert_hardened.gd` exercises the normal creation and travel path, two days of unmet water, opt-in, blocked/owned encounter options, cost receipt, confirmation, checked save/load, invalid records, and two full-world SHA-256 replays. `tests/test_s5_c45_scavenger_instinct.gd` exercises multiple actual wreck searches, candidate and acceptance, the owned/unowned knowledge boundary, preview/result agreement, checked persistence, and two full-world SHA-256 replays. Godot screenshots are captured at 1280×720 and 1152×648 with `tools/capture_acquired_trait.gd` and `tools/capture_scavenger_instinct.gd`.

The scavenger fixture stages three wreck encounters and then resolves each through the production intent. It does not establish how often natural travel will produce three worthwhile wrecks; that remains a pacing playtest question.

Remaining C4.5 work: four more evidence-backed identities (`CARAVAN_FRIEND`, `HARD_BARGAINER`, `KNOWN_HELPER`, `DEATH_TESTED`), each with a supported effect and real tradeoff or limit; then player experience testing. This slice does not close C4.5 or all of S5.
