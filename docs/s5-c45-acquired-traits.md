# S5-C4.5 acquired traits — first playable identity

Status: **partial**. `DESERT_HARDENED`, `SCAVENGER_INSTINCT` and `KNOWN_HELPER` are implemented. `HARD_BARGAINER` and `DEATH_TESTED` remain planned. `CARAVAN_FRIEND` is **BLOCKED**, not merely unstarted: caravan events are recorded with the world's caravans as the actor and the player has no interaction with a caravan at all, so no player-side evidence exists to derive it from. It stays blocked until a real player/caravan interaction exists; inventing world authority to justify a trait is not an option.

Core traits still come only from character creation. Perks still come from XP milestones. Acquired traits have a separate `PlayerState.acquired_trait_ids` owner and a separate `ACQUIRED_TRAIT_ACCEPTED` history. They end with this character; this change grants no legacy bonus.

## 荒野歷練 / DESERT_HARDENED

- **Evidence:** On two distinct travel days, the player's requested water went unmet. The daily survival calculation records `PLAYER_NEED_UNMET` with exact water/food unmet ratios. Merely running out of water in a settlement, or displaying a warning, is not qualification.
- **Choice:** At a settlement, the character sheet offers acceptance. Closing the sheet keeps the current self; qualifying does not auto-grant the trait. The offer remains available while the evidence remains in this life's ledger.
- **New action:** At a rockslide, `ENDURE_CROSSING` spends one food and no extra day. A character without the trait cannot see or commit it. With no food, it is visibly disabled and the authority rejects it without mutation.
- **Limit:** It works only at a rockslide and requires a real ration. It does not change daily metabolism, HP, combat, or the world's water supply.

## 拾荒直覺 / SCAVENGER_INSTINCT

- **Evidence:** Successful `SEARCH` receipts on three distinct days, each with goods or an item actually carried away. Empty searches and multiple receipts on the same day do not qualify. Existing receipts do not identify a physical wreck, so this is evidence of repeated salvage work, not three proven distinct sites.
- **Choice:** The survivor accepts the candidate at a settlement through the same opt-in authority; qualification alone changes nothing.
- **New knowledge:** At a wreck, the encounter screen shows what this wreck's ordinary `SEARCH` would offer before the player spends a day. The preview is read-only and matches the existing deterministic yield functions.
- **Limit:** The preview applies only to ordinary wreck searching. It does not add loot, reveal every specialized approach, or bypass bag capacity. The player can still decide that the day and rations are not worth the find.

## 救人手法 / KNOWN_HELPER

- **Evidence:** On two distinct days, a `GIVE_WATER`, `HYDRATE` or `SHARE_FOOD` receipt whose `spent` shows the ration really leaving the pack. Choosing an option is not help; paying for it is. `LEAVE` and `TAKE_PACK` never qualify, and several receipts stamped on one day are one day of practice.
- **Why two days and not three:** a wreck is ordinary roadside furniture, but a dying traveller or a refugee column is not. The three-day bar that suits salvage would make this identity unreachable in a normal run rather than merely demanding.
- **Choice:** Accepted at a settlement through the same opt-in authority; qualification alone changes nothing and the identity cannot be taken twice.
- **New knowledge:** At a dehydrated traveller or a refugee column, the encounter screen shows what that person can offer in return before the ration is spent. It reads the existing deterministic `traveller_yield` / `refugee_yield` functions, so it is the road's real answer rather than an estimate.
- **Limit:** It is knowledge, not a discount. The water or food is still paid in full, the offer is not increased, nothing is revealed about a wreck, a roadblock or an ambush, and the world does not remember the player. This is a character who learned to read people, not a reputation system: no faction, standing or NPC memory is introduced.

Checked loading and live invariants validate trait IDs, acquisition history, dated preceding evidence, and deprivation-event shape. The ledger does not independently reconstruct every travel ration calculation or wreck yield from old world snapshots; its committed event is the historical fact. Legacy saves without the new field load with an empty acquired set; old history is not retroactively invented.

`tests/test_s5_c45_desert_hardened.gd` exercises the normal creation and travel path, two days of unmet water, opt-in, blocked/owned encounter options, cost receipt, confirmation, checked save/load, invalid records, and two full-world SHA-256 replays. `tests/test_s5_c45_scavenger_instinct.gd` exercises multiple actual wreck searches, candidate and acceptance, the owned/unowned knowledge boundary, preview/result agreement, checked persistence, and two full-world SHA-256 replays. Godot screenshots are captured at 1280×720 and 1152×648 with `tools/capture_acquired_trait.gd` and `tools/capture_scavenger_instinct.gd`.

The scavenger fixture stages three wreck encounters and then resolves each through the production intent. It does not establish how often natural travel will produce three worthwhile wrecks; that remains a pacing playtest question.

`tests/test_s5_c45_known_helper.gd` exercises refusing help, one day versus two, receipts with no ration spent, robbing instead of helping, opt-in and double-acceptance, the unowned/owned knowledge boundary at both helping encounters, preview/result agreement, the ration still being paid, non-leakage into wreck encounters, checked persistence and two full-world SHA-256 replays. `tools/capture_known_helper.gd` captures it at 1280x720 and 1152x648, earning the identity through production intents rather than setting it directly.

Remaining C4.5 work: `HARD_BARGAINER` and `DEATH_TESTED`, each with a supported effect and real tradeoff or limit; `CARAVAN_FRIEND` is blocked as described above; then player experience testing. This slice does not close C4.5 or all of S5.
