# S5-C4: first Level and Perk milestone

This is the first playable milestone of S5-C4, not closure of the full progression slice.

Lifetime XP determines Level; it does not grant skill ranks or growth points. The first thresholds are Lv.2 at 20 XP, Lv.3 at 45 XP, and Lv.4 at 75 XP. Existing commissions award 25 XP for the wrench delivery, 20 XP for the rope delivery, and 45 XP for the northern survey. The two ordinary deliveries therefore reach Lv.3 without the survey. Skill practice remains a separate progression channel.

Lv.3 opens one permanent Perk choice while settled in a town. The character sheet shows the milestone and sends a `SELECT_PERK` intent; the simulation checks the earned slot and writes the selected stable ID to `PlayerState`. Old saves without a Perk list load with none. Unknown, duplicate, unordered, or unearned lists fail checked loading.

| Perk | New encounter approach | Cost and limit |
| --- | --- | --- |
| 細心拾荒者 (`CAREFUL_SALVAGER`) | At a wreck, sort metal for one offered scrap. | Costs one day and normal daily supplies; cannot find the sealed field kit by this method. Capacity may prevent taking the scrap. |
| 商路熟手 (`ROAD_RUNNER`) | At a roadblock, take a known side route without toll or delay. | Only applies to roadblocks; selecting it forgoes the salvager choice at this milestone. |

Unowned Perk approaches stay hidden in the player UI and are rejected by the simulation if forged. Selection itself grants no health, combat damage, skill rank, or item. Later Level milestones, more XP sources, more Perks, and acquired Traits are outside this increment.

The slice also exposes an older replay hazard: `StringName` keys do not sort lexically. New option identifiers changed their allocation order and therefore changed the order in which the daily simulation processed caravans. The daily tick now sorts settlement, caravan, and refugee IDs by their string values; this restores the S3 migration and mortality scenarios and makes the intended order explicit.
