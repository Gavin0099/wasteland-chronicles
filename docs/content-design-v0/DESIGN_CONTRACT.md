# Content Design V0 — design-only authoring contract

Status: DESIGN_ONLY. These files are editorial proposals, never runtime inputs.
The implemented item catalogue remains the original twelve in ITEM-1. No code
may import this directory to register items, spawn loot, set prices, grant actions
or modify world state. No additional image generation is part of this pass.

Deliverables: 185 distinct-name content records, 480 original encounter proposals
(wilderness 100, settlement 100, caravan 60, ruins 100, NPC 80, anomaly 40), an
independent consistency review, item/encounter usage matrix, three-settlement
economy/loot matrix, crafting/disassembly relationship graph and a first-30
implementation shortlist. Counts are coverage targets, not proof of fun or
implementation readiness. Duplicate title/renamed-template filler is not accepted.

Owner later added 120 town-quest skeletons, 150 NPC/relationship hooks and an
extensible authoring path. TOWN_LIBRARY_CONTRACT.md defines the additional fields.
EXTENDING.md defines versioned, namespaced, design-only extension packages; the
counts above freeze this baseline, not the maximum size of future libraries.
The first-slice proposal now binds 30 items / 15 events / 9 quests / 10 NPC hooks.

## Sources and boundaries

Read the three research notes in `research/` and cite their stable source IDs.
Verified outside-game facts and our original adaptations stay separate. Do not
copy dialogue, item lore, factions, maps or proprietary game data. Use this
project's three settlements and the existing item names.

Current world facts from `game_data/s1_world.gd`: New Hope favors water/food,
Gray Valley scrap/industry, Dry Well fuel/refining. All three currently trade the
four aggregate resources; none of the proposed item supply tables are live.
Existing base-price anchors are water 8–15, food 10–15, scrap 8–16 and fuel 10–20
Caps per abstract resource unit. These are reference scale only, not a conversion
from liters/kilograms to current carrying units or a current merchant quote.

Weights for the twelve ITEM-1 entries must match that contract. Other weights and
values are proposed design estimates, not measured products or accepted balance.
For the three category illustrations (ammunition, medicines, mechanical parts),
use null weight/value: they summarize families, not new duplicate inventory IDs.
Unique objects have no routine stock; unknown artifacts may have null value and
describe specific interested buyers instead of pretending to know a universal
price. Supply and demand are separate: low local supply can coexist with demand.

Known limitation: existing combat/HP/crowbar/cache are a narrow earlier example.
New item use still requires proper ownership/equip/action authority. New NPCs
must bind existing population; no design proposal permits population inflation.
Tags, skill eligibility and narrative never gain mutation authority.

## Item records

Read `item-seeds.json`: names, content IDs, art references, memberships and any
ITEM-1 runtime ID/weight are fixed. `content_id` is an editorial reference only.
Each `items/*.json` is an array of records with these fields:

```text
content_id, name_zh, art_file, art_sections, art_role, runtime_item_id
status = DESIGN_ONLY
category = WEAPON|APPAREL|CONTAINER|TOOL|CONSUMABLE|MISC
subtype = lowercase_snake_case
proposed_weight_g = positive int or null for category illustrations
proposed_base_value_caps = positive int or null (unknown/unique/category)
value_rationale_zh
rarity = common|uncommon|rare|unique|category
tags = nonempty array of lowercase_snake_case labels
roles = nonempty subset of combat|trade|explore|survival
actions = array of lowercase_snake_case proposed verbs; [] for category artwork
origin_tags = array of setting/source tags
markets = {new_hope:{supply,demand,reason_zh}, gray_valley:{...}, dry_well:{...}}
  supply/demand = none|low|medium|high
loot_sources = array of proposed source/container types, not executable tables
description_zh, known_description_zh, identified_description_zh, world_notes_zh
hooks = two or more {situation_zh, use_zh, cost_or_limit_zh}
repair = {possible:bool, inputs:[content_id...], note_zh}
salvage = {possible:bool, outputs:[content_id...], note_zh}
dependencies = array of required future mechanic IDs
inspiration_refs = array of research source IDs
```

`repair.inputs` and `salvage.outputs` are symbolic relationship proposals, not
recipes or yields. Do not invent conversion ratios, repeatable money loops or
self-producing materials. Consumables should not produce full replacements.
Every action/hook needs a meaningful limitation: access, information, transport,
time, expenditure, social consent, specialized knowledge or finite material.
Avoid making one tool a universal key. Ordinary weapon variants need a world
reason or distinct handling/preparation niche, not a made-up damage ladder.

Required future mechanic IDs may use: item_ownership, equipment,
combat_extension, injury, repair, lighting, water_treatment, cooking, camping,
cargo, navigation, electronics, identification, knowledge, npc_relationship,
reputation, jobs, regional_trade, crafting, disassembly, hazards, exploration,
succession, skills_growth. These are gap labels, not implemented systems.

## Encounter records

Each `encounters/*.json` is an array. IDs use `wild_001`…`wild_100`,
`town_001`…`town_100`, `caravan_001`…`caravan_060`, `ruin_001`…`ruin_100`,
`npc_001`…`npc_080`, `anomaly_001`…`anomaly_040`.

```text
encounter_id, category = wilderness|settlement|caravan|ruins|npc|anomaly
status = DESIGN_ONLY
title_zh, context_zh
location_tags = array
trigger = {basis:EXISTING_READ|PROPOSED_WORLD_FACT, condition_zh}
primary_axis = combat|trade|explore|survival
choices = at least three {
  label_zh,
  required_items:[content_id...], consumed_items:[content_id...],
  required_skill:null|{skill:one existing skill ID,rank:1..5},
  cost_zh, outcome_zh,
  rewards:[{content_id,quantity:positive int}]
}
followup_zh
dependencies = array of required future mechanic IDs
inspiration_refs = array of research source IDs
```

At least one option must require no item or skill. At least two options must
solve different problems or accept different consequences; simple resource
reskins are insufficient. A no-reward retreat/decline option is legitimate.
Show exact proposed costs/rewards when numbers are specified; do not hide the
result behind vague prose. Risks need explicit missing authority dependencies.
New locations/hazards/NPC situations are proposed world facts, not claimed to
exist. Never use a skill as proof of owning a weapon/tool. A held weapon must be
stated as owned/equipped in context/cost and must declare equipment/combat gaps.
Do not use category-illustration IDs as physical requirements or rewards.

Existing skills: BARTER, ELECTRONICS, FIREARMS, MECHANICS, MEDICINE, MELEE,
SCAVENGING, SPEECH, STEALTH, SURVIVAL. Requirements do not grant world-mutation
permission. Injury, reputation, identification and the other listed gaps are
future mechanics; record them openly rather than manufacturing current facts.

## Matrices and review

Derive matrices from authored references, not from the entire Cartesian product.
Report unused images, missing reward roles, overused tools, weak regional identity,
overlapping choices, unsupported authority and unresolved price/weight assumptions.
Coverage of all 185 names does not mean every item must be a universal tool or
random drop. Category illustrations and unique personal objects may be explicitly
excluded from ordinary drops with reasons.

The first-30 shortlist includes the original twelve and eighteen additions with
concrete event support, regional purpose, prerequisite mechanics and rollout order.
Design completeness is distinct from player validation and implementation approval.
