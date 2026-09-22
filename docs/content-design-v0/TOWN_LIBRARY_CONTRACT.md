# Town Quest / NPC Hook V0 — DESIGN_ONLY

Owner added these libraries while the item/encounter pass was in progress.
Deliver 120 quest skeletons (40 per town) and 150 NPC/relationship hooks (50 per
town). They join, rather than replace, the 185-name and 480-encounter libraries.
No quest manager, faction state, NPC spawn, deadline tick or reward is installed.

## Shared town and group IDs

Town IDs: `new_hope`, `gray_valley`, `dry_well`.
Interest groups are editorial stakeholder labels, not live faction entities:

| Town | Labels |
| --- | --- |
| new_hope | nh_water_stewards, nh_growers, nh_clinic, nh_newcomers |
| gray_valley | gv_yard_workers, gv_workshops, gv_salvage_buyers, gv_residents |
| dry_well | dw_fuel_cooperative, dw_caravan_brokers, dw_well_queue, dw_outer_camps |

Groups may have internal disagreements. Do not assign a whole group fixed moral
alignment or grant it existing world authority. A relationship records interests
and evidence, not automatic reputation points.

## NPC / relationship hooks

`npc-hooks/*.json` arrays; IDs `hook_<town>_001` … `_050`. Each record:

```text
hook_id, town_id, status = DESIGN_ONLY
role_zh, public_need_zh, private_stake_zh, leverage_zh, limit_zh
group_ids = one or more labels from the table
binding_zh = how a future implementation binds an existing living population member
item_refs = editorial content IDs
encounter_refs = existing proposed event IDs (editorial relation, not executable steps)
relationships = [{target_hook_id, tension_zh, cooperation_zh}]
availability = {condition_zh, without_player_zh}
dependencies, inspiration_refs
```

At least one concrete relationship with another hook, with both a conflict and
reason to cooperate. At least one item and encounter reference. No new runtime
person ID, generated death or automatic world history. Availability is a proposal
requiring jobs/relationship/world authority, not a countdown implemented by prose.

Reserve these ten coherent first-slice candidates; author their details:

| Hook suffix | Role |
| --- | --- |
| hook_new_hope_001 | 水務保管人 |
| hook_new_hope_002 | 種庫照管人 |
| hook_new_hope_003 | 診療所收貨人 |
| hook_gray_valley_001 | 拆解場帶班工 |
| hook_gray_valley_002 | 流動技工 |
| hook_gray_valley_003 | 材料記帳員 |
| hook_dry_well_001 | 燃料核帳員 |
| hook_dry_well_002 | 商隊排程人 |
| hook_dry_well_003 | 井口輪值人 |
| hook_dry_well_004 | 返程信差 |

Other hooks can include townspeople or visiting roles; do not copy only the job
title while retaining identical interests. Proposed criminals still need facts,
evidence and consent/ownership rules; no trait label proves guilt.

## Town quest skeletons

`quests/*.json` arrays; IDs `quest_<town>_001` … `_040`.

```text
quest_id, town_id, status = DESIGN_ONLY
kind = work|life|economy|faction|exploration|world_state
title_zh, premise_zh
issuer_hook_id, stakeholder_hook_ids
trigger = {basis: EXISTING_READ|PROPOSED_WORLD_FACT, condition_zh}
deadline = {kind: relative_days|world_event|none, days: positive int|null,
            expiry_zh, without_player_zh}
approaches = >=3 choice records using DESIGN_CONTRACT encounter choice schema
encounter_refs = >=1 actual proposed event ID
world_effect_proposals = [{target_zh, change_zh, authority_needed_zh,
                          derivation_boundary_zh}]
followup_zh, dependencies, inspiration_refs
```

All six kinds must appear in each town; do not make every quest a courier job.
At least one approach is ungated decline, postponement or non-item solution.
Costs/consumption and rewards refer to the same physical objects: transferred
items cannot remain in both inventories. Outcomes cannot reuse one unique object
as a replenishing reward. Explicitly say which facts are unknown at offer time.

Deadlines have a condition and observable closure reason. When the player does
nothing, describe **conditional** continued world resolution: caravan departure,
an actual theft investigation, another worker taking a job, or an offer ending.
Do not manufacture success, attack, migration or death just to punish expiry.
Revalidate on accept/commit; closing an offer cannot rewind an already departed
caravan or revive a dead issuer. Never freeze the world to wait for the player.

World effects are proposed fact changes with an identified missing owner. Price,
population and caravan responses must be derived by existing simulation after
authorized facts change; do not grant `water output +10%`, price reductions or
NPC spawning directly from a quest paragraph. Fixed percentage examples in the
discussion were illustrations, not accepted balance or new mutation permission.

## Integration

encounter_refs / quest_encounter edges are editorial relations: a shared job,
an optional lead, or an adapted scene premise. The record's followup must say
which applies. Different physical facts cannot be combined as one runtime
scene or share a completion receipt. Only an explicitly bound same operation
shares items, costs and one reward; these links are not an executable graph.

Produce sparse Item × Encounter × Quest × NPC links, with edge kinds and reasons.
Select 30 items, 15 events, 9 quests (3/town) and the ten reserved NPC candidates.
List deferred mechanics and offer a feasible first loop; a design candidate is
not yet playable or approved implementation. Retain all counts in evidence, and
report weak links or prerequisites instead of padding the dataset to look ready.
