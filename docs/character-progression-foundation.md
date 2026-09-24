# Character Progression Foundation — owner direction, 2026-09-20

This is the design roadmap, not a gameplay implementation. The authoritative C0/C1 decisions are in [S5-C0/C1 Contract](s5-c0-c1-contract.md); they supersede earlier open questions here. Encounter Resolution Feedback was committed independently as `e18b88e`.

## Player experience

The world lives independently. The player grows from an unknown wanderer. Their capabilities change what they can do in that same world. The central acceptance question is: **Can I now solve something I previously could not, and can another build solve it differently?**

World-reactive encounter selection already exists: real refugee parties, recent lost caravans, security and water pressure affect the road. That foundation must become visible through meaningful choices and consequences; do not present it as a newly built system. More cities, more templates, four isolated tools, and combat are not substitutes for a growth curve.

## Separate concepts

| Concept | Role | Required distinction |
| --- | --- | --- |
| Background | Starting history and initial strengths | Creation choices must remain consistent with the existing population identity rules. |
| Core Trait | What kind of person you start as | Creation selects 0–2; no rank bonus or pre-emptive pair restrictions. S4 metadata remains separate. |
| Acquired Trait | What this life makes you become | Evidence from this run creates candidates; player acceptance is separate. C4.5, not implemented. |
| Legacy Trait / Unlock | What remains after death | S6 world opportunities; no automatic inheritance of the previous character build. |
| Skill | What you can actually do | Relevant actions/work develop that skill. Character level does not automatically raise every skill. |
| Level | Accumulated life experience | Opens specialization milestones, not automatic HP/damage inflation. Its experience source is still to be specified. |
| Perk | What kind of person you become | Sparse choices that change play; prerequisites may combine level, skills, earlier perks and justified background/traits. |
| Equipment | What new actions/places become possible | Protection, access and problem-solving capability take priority over rarity tiers and numeric upgrades. |

The latest owner brief fixes the target catalogue below, replacing the earlier coarse Survival/Trade/Technical/Social/Combat examples. First perks near levels 3/6/9 remain a cadence proposal, not a finalized XP formula or authorization to implement combat in the current repair. Aptitude metadata does not silently become Skill authority.

## Initial catalogue and creation contract

Target: one Background, zero to two starting Traits, ten core Skills with integer ranks 0–5. Ranks mean 外行 / 略懂 / 熟練 / 專業 / 專家 / 大師. There is no free point allocation. A validated Background package assigns three distinct skills 2/1/1 and the other seven 0. Trait pairs are all permitted except duplicates; the approved package catalogue maps the four existing closed-profile IDs directly.

| Skill | 中文 | Capability scope |
| --- | --- | --- |
| FIREARMS | 槍械 | Weapon knowledge and later firearm approaches; no combat mechanics implied. |
| MELEE | 近戰 | Close-range physical approaches; combat implementation remains separate. |
| SURVIVAL | 荒野求生 | Routes, weather, water and tracks; travelling through the wilderness. |
| SCAVENGING | 搜刮 | Finding and recognizing useful things in ruins; distinct from wilderness survival. |
| STEALTH | 潛行 | Observation, evasion and concealed entry where the world supports them. |
| MECHANICS | 機械 | Mechanical diagnosis, dismantling and repair. |
| ELECTRONICS | 電子 | Circuits, terminals and electronic controls. |
| MEDICINE | 醫療 | Diagnosis and treatment once injury/disease authority exists. |
| SPEECH | 交涉 | Asking, persuasion, negotiation and deception. |
| BARTER | 交易 | Valuation, prices, terms and compensation. |

Skills should support understanding information, unlocking an approach, reducing a concrete cost, and changing a result. Not every skill must immediately have all four uses; every implemented use needs an observable world effect. Detailed repair costs in the brief are examples, not balancing rules.

Retain the six existing Trait identifiers; the target catalogue adds eight. Traits express a way of approaching the world, with meaningful constraints or costs rather than free Skill +1 bonuses.

| Trait | 中文 | Intended identity; effect remains slice-scoped |
| --- | --- | --- |
| CAUTIOUS | 謹慎 | Observe risk first; some approaches take time. |
| AGGRESSIVE | 好鬥 | Confrontation and pressure; peaceful approaches may suffer. |
| COMPASSIONATE | 慈悲 | Aid and trust with personal resource tradeoffs. |
| GREEDY | 貪財 | Seek better terms or profit; relationships may be affected when supported. |
| STUBBORN | 固執 | Resist pressure, with limits on compromise. |
| LOYAL | 忠誠 | Commitment and obligations; party/relationship effects require those systems. |
| VIGILANT | 警覺 | Notice supported dangers earlier. |
| RECKLESS | 莽撞 | Fast, risky approaches with explicit consequences. |
| IRON_STOMACH | 鐵胃 | Food/water options only after ingestion risks are defined. |
| LIGHT_SLEEPER | 淺眠 | Camp vigilance versus rest, once camping exists. |
| LONER | 獨行者 | Solo preference versus teamwork, once party mechanics exist. |
| CURIOUS | 好奇 | Investigate unfamiliar things. |
| SUSPICIOUS | 多疑 | Question inconsistencies with trust tradeoffs. |
| PACIFIST | 厭戰 | Nonviolent approaches and limits on initiating violence. |

Trait determines the approach; Skill determines the capability to execute it. Example build directions include CAUTIOUS + SURVIVAL, AGGRESSIVE + SPEECH, CURIOUS + ELECTRONICS, and COMPASSIONATE + MEDICINE. Their example thresholds are not final balance values.

Background defines earlier experience, initial skill tendencies and justified knowledge; Perks define later specialization. The four existing Background IDs and their three selected package skills are owner-approved in [C0-P0](c0-p0-background-packages.md); the 2/1/1 rank rule is fixed. The proposed scavenger Background mentions LOCKPICKING, but that skill is explicitly deferred: do not silently add an eleventh core skill or choose a substitute before defining the relevant mechanic.

EXPLOSIVES, LEADERSHIP, LOCKPICKING and WEIRD_TECH are deferred. Narrow expertise such as welding or trauma surgery can later be Perk, Proficiency or background knowledge rather than expanding the core skill list indefinitely. This does not introduce a Proficiency subsystem now.

C0/C1 rules for package ranks, unrestricted distinct Trait pairs, zero-rank legacy migration and strict persistence are now fixed in the authoritative contract. The four Background packages are now owner-approved, and the strict rank codec decision is proven; see [headless delivery record](c0-c1-headless-implementation.md) for local implementation/gate status. Before C2, define the real facts each choice observes or changes. No false promise of injury, ambush, camping, party or relationship effects may be attached to metadata-only choices.

## Planned slices

| Slice | Scope | Player acceptance signal |
| --- | --- | --- |
| S5-C0 Character Creation | Background, initial skills, starting Traits | This is my character. |
| S5-C1 Capability Foundation | Explicit skill authority, persistence, eligibility checks | My character has concrete strengths and limits. |
| S5-C2 Trait & Skill Encounters | Different approaches to existing situations | Two characters can solve the same encounter differently. |
| S5-C3 Skill Growth | Relevant use/work advances the corresponding skill | What I practice changes what I can do. |
| S5-C4 Level & Perks | Experience milestones and specialization choices | My build diverges through meaningful decisions. |
| S5-C4.5 Acquired Traits | Real-history eligibility, opt-in acceptance, gameplay effects and tradeoffs | This life changes the kind of person I become. |
| S5-C5 Equipment Progression | Gear enables capabilities and exploration access | Finding an item opens a new possibility. |
| S5-C6 Job Progression | Increasingly demanding work through natural requirements | Growth gives me useful new work, not just larger numbers. |
| S5-C7 Capstone | Advanced perks and rare equipment/items | A long-term pursuit can affect both my character and the world. |

This sequence supersedes the former S5-C0 world-expansion label and older generic S5-D skill references for future scheduling. It does not rewrite historical completion evidence. Expand the sparse map and state-aware event library after the foundation demonstrates different decisions.

## Acquired and Legacy boundaries

C4.5 targets six acquired identities: DESERT_HARDENED, CARAVAN_FRIEND, HARD_BARGAINER, KNOWN_HELPER, SCAVENGER_INSTINCT and DEATH_TESTED. Each needs concrete committed-history eligibility, a supported effect and at least one tradeoff or limit. Qualification does not force acquisition: offer acceptance or keeping the current self at a defined milestone. No random per-level reward pool, invented history, injury or trust system.

S6 owns death and succession. The prior build ends while the world persists. Legacy may preserve clinics, recoverable equipment, memories or future Background/Perk/companion possibilities when those facts exist; it does not copy Skills and Traits into the next person or grant permanent account stats. LEGACY_MIGRATION in C1 is a save-format provenance label, not this gameplay system.

## Design constraints for subsequent slices

- Existing simulation facts remain authoritative. Observation cannot invent ambushers, survivor histories or world repairs just to justify a new option. Hidden facts require a defined player-knowledge boundary.
- Eligibility and costs must be checked again at commit; UI only projects available approaches. Rejected actions leave the world unchanged.
- Specify skill/level experience sources, repeat-action abuse prevention, progression pace, perk selection frequency and save compatibility before implementing growth.
- Keep ordinary fallback approaches where the situation permits. Gate by understandable capability/equipment conditions, not unexplained quest-level labels.
- Example capstone approaches: technical repair, socially obtained access, or a survival route. Each requires a concrete world contract before implementation.
- A purification core that changes a settlement's supply needs explicit resource and economic rules. It is a future mechanic, never a regulator added to hide collapse in the existing simulation.
- Validate each behavior slice with regression/negative cases, independent replay hashes, and global population/resource invariants. New lifecycle or core accounting authority requires its own review.

No creation UI, Skill/XP, Level, Perk, equipment, job, capstone, combat or new settlement system is implemented by this document.
