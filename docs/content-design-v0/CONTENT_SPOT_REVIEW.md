# Content spot review — DESIGN_ONLY

Reviewed 2026-09-22 by the agent that authored items 01 and the town/caravan
library. The reviewed ruins, NPC, anomaly and Dry Well quest records were
authored by other agents. This is an independent editorial sample, followed by
the same reviewer's bounded fixes requested by the coordinator. It is not a
claim that all 480 events have received independent line-by-line review.

## Scope and method

Primary sample: 15 events, five per other-author category. The sample includes
the first, middle and last positions plus finite-reward or ownership-sensitive
records. Also read `ruin_093` to verify the third Dry Well core quest, making 16
events read in total, and read all three core Dry Well quest briefs.

| Category | Records read | Focus |
| --- | --- | --- |
| Ruins | `ruin_001`, `ruin_050`, `ruin_067`, `ruin_089`, `ruin_100` | Discovery vs possession, task cargo vs reward, alternate entrances, finite stock |
| NPC | `npc_001`, `npc_020`, `npc_040`, `npc_071`, `npc_080` | Loans, specific evidence objects, earned stock transfer, finite cargo space |
| Anomaly | `anomaly_001`, `anomaly_020`, `anomaly_021`, `anomaly_029`, `anomaly_040` | Observable facts vs powers, custody, transport, no invented combat or invisibility |
| Supporting integration | `ruin_093` | Same barrel scale, permission, work time, and reward as core quest 003 |
| Dry Well quests | `quest_dry_well_001`–`003` | Local work vs travel, zero/one/two day choices, one operation receipt |

Read complete context, trigger, choices, item/skill requirements, costs, rewards,
follow-up and dependencies. Compared source object, custody, location, gate,
time, reward source and conclusion with each linked core quest. Schema checks
alone would not detect the issues below.

## Findings and bounded fixes

### F1 — Scene evidence was incorrectly gated by owning another object: fixed

`npc_020` asked for a player-owned old photograph even though the resident's
specific photograph was the evidence. `npc_040` asked for a player-owned repair
manual even though the workshop's particular damaged book and its borrowing log
were the evidence. `anomaly_021` asked the player to own a reverse magnetic shard
before moving the workshop's particular specimen for a comparison.

Removed those three `required_items` gates. Context/trigger now bind the
particular original at the scene, its holder and permission. Costs/results keep
the original in that holder's custody. The skill requirements remain. An
unrelated same-type object does not satisfy evidence identity, and this change
does not grant possession of the scene object.

Synchronized `authoring/write_npc_events.py` and
`authoring/write_anomalies.py` with their generated JSON files.

### F2 — Fractional time without a day authority: fixed

Found 198 choice costs in the 80 NPC / 40 anomaly event files that said
`半天`. Those words were not supported by a fractional-day authority. No quest
cost had that problem.

Reviewed handling, inspection, navigation, experiments and actual waiting as
one-day work; same-site reading, discussion, display and simple handover as
zero-day interactions. The result is **135 zero-day costs and 63 one-day
costs**, replacing all 198 fractional costs. This is an editorial choice, not
rounding a numeric `0.5` token or changing the world's time codec. Zero-day
costs explicitly say that the world date does not advance. A negotiated
half-day observation phrase in an outcome was also changed to refer to the
current observation without inventing another clock.

`authoring/encounter-day-cost-review.json` records every affected event, choice
index, label and proposed day count. The repeatable authoring utility is
`authoring/normalize_encounter_days.py`. Source and generated files agree.

### F3 — Acquired samples need distinct custody and packaging: clarified

In `anomaly_001`, transferring away a sealed cargo crate while acquiring the
sample did not explain where the box and sample then were. Clarified that the
box goes to the specified custodian as a dedicated container, is not destroyed,
and holds the one signed-for sample at the recorded location. A sample in
remote custody is not simultaneously usable from the player's carried bag.

The eight finite specimen pickup alternatives (`anomaly_001`, `009`, `013`,
`021`, `025`, `029`, `033`, `037`) now explicitly depend on `cargo`, preserve
separate container/owner/custodian/location facts, and share the source removal
and receipt in one operation. A zero-day handover cannot transfer the same
original again. These are implementation prerequisites, not implemented storage
or anti-duplication rules.

## Dry Well core integration

| Quest | Finding after reading linked record |
| --- | --- |
| `quest_dry_well_001` | Paper account 10 → 8 uses the read-only formal fuel snapshot; the unknown clerk identity stays unknown. Salt comes from the clerk's reserved stock. `ruin_093` is expressly a later job, not a prerequisite or a second reward for the same accounting operation. |
| `quest_dry_well_002` / `ruin_089` | Same existing crate, dispatcher, receiver and reserved salt. Rope route: 1 day, rope returned. Cloth-sack route: 2 days, same salt after the complete delivery. Both records explicitly consume one shared completion receipt. The scene is one courtyard; subsequent inter-town travel is separate. |
| `quest_dry_well_003` / `ruin_093` | Same stopped scale and existing tables. Wrench + MECHANICS 2: 2 days, reserved cloth sack once. Already authorized side-corridor arrangement: 1 day, no item or extra speech gate and no sack reward. Both records explicitly share one operation receipt; no price, fuel, water, or calibration bonus is granted. |

## Other sample observations

- `ruin_067` does not reward the entrusted gear to the player: the gear enters
  task custody, while the separately available bearing is the one-off payment.
- `npc_001` moves the lent wrench out of carried possession until a real return;
  it does not simultaneously retain it as an available player tool.
- `npc_071` pays one tea portion from the stallholder's actual stock after work
  acceptance; availability must be rechecked if that stock is sold first.
- `npc_080` does not create another cargo space when the player withdraws an
  inquiry. An inquiry is not an existing reservation.
- `anomaly_029` distinguishes custody for examination from permission to plant;
  `anomaly_020` and `040` do not promote observations into a new weapon or
  invisibility effect.

## Verification and limits

After fixes, a scan of **all 480 event and 120 quest choice costs** found zero
occurrences of `半天`, `半日`, `小時` or `0.5`. The three corrected scene-object
branches require no player-owned copy and preserve their original skill gates.
The full design validator passes: 185 items, 480 events, 120 quests, 150 hooks,
and 10 rejection probes.

No gameplay code, clock, ownership engine, mission manager, combat system, save
format or live world state was changed or tested by this editorial pass. Before
implementation, zero-day paths still need adversarial tests for repeated
confirmation, duplicate operation receipts, source depletion, concurrent
ownership changes and failed partial handovers. This review does not substitute
for those tests or claim all proposal effects are implementable in the current
runtime.
