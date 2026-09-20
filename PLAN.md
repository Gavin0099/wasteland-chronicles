# PLAN.md
<!-- governance-baseline: overridable -->
<!-- baseline_version: 1.0.0 -->

> **最後更新**: 2026-09-20
> **Owner**: Gavin0099
> **Freshness**: Sprint (7d)

---

## Current Phase

- [ ] S4 — Individual NPC Ecology

## Active Sprint

- [x] S4-A : NPC Identity (+ G1.5-B1 Runtime Enforcement) — CLOSED
- [x] S4-B : NPC Life State (+ G1.5-B2 Lifecycle Atomicity) — CLOSED
- [x] S4-C : Background / Profile Metadata — CLOSED
- [x] S4-C.1 : Event Ledger Persistence (+ G1.5-B4 Historical Fact Authority) — CLOSED
- [x] S4-C.2 : Snapshot Numeric Canonicality (+ G1.5-B5 Persistence Boundary Transparency) — CLOSED
- [x] S4-D : Traits — CLOSED (Fast Lane)
- [x] S4-E : Aptitude Schema (No XP) — CLOSED (Fast Lane)
- [x] S4-F1 : Autonomous Decision Authority (+ G2-lite) — CLOSED
- [x] S5-B3 : Travel Auto-Advance (journey runs itself) — CLOSED
- [x] S5-B5 : Player Survival (water/food pressure, exposure, death) — CLOSED
- [x] S5-B4 : Travel Encounters (4 deterministic roadside events, Scavenge folded in) — CLOSED
- [x] S5-B4.1 : World-Reactive Encounters — CLOSED
- [ ] **S5-C0 : World Expansion 3 -> 5 settlements (sparse road network with chokepoints) — CURRENT**
- [ ] S5-B4.2 : Encounter Variety 4 -> 8-10 state-aware templates
- [ ] ★ FP2 : still finding new decisions after 20 minutes
- [ ] S4-F2 : Autonomous Migration (decision to physical arrival)
- [ ] S4-F3 : Multi-NPC Determinism at scale
- [ ] S4-G : NPC Relationships (split out of S4-C)

## Backlog

- P1: S5 — Player & Party (Player Verbs, RPG Progression Discovery)
- P1: S6 — Roguelite Legacy (Succession & World Memory)
- P2: S7 — Information Fog / UI (Fail-Closed Knowledge Boundary)
- P2: S8 — Vertical Slice (30~60 min Emergent Simulation RPG)

## Decision Log

- 2026-09-20: **S3 Human Ecology CLOSED ✅** and tagged `v0.0.1-s3` (S3-A through S3-F fully verified).
- 2026-09-20: **G1.5-A NPC Authority Contract CLOSED ✅** (Authority matrix, Single population membership, deterministic ID minting, validate-before-commit).
- 2026-09-20: **AI Governance Framework Imported** as submodule at `additional/ai-governance-framework`.
- 2026-09-20: **S4-A / S4-B / S4-C CLOSED ✅** (identity materialization, lifecycle atomicity, immutable background profile with zero action authority).
- 2026-09-20: **S4-C.1 Event Ledger Persistence CLOSED ✅** — committed events are the sole authority for historical world facts; `event_count` demoted to derived metadata.
- 2026-09-20: **S4-C.2 Snapshot Numeric Canonicality CLOSED ✅** — save-time `snapped()` removed; authoritative floats canonicalized at the end-of-day commit boundary via the persistence codec. Save/Load is now a transparent boundary (N4: interrupted and uninterrupted Day 100 worlds are identical in state, ledger and projection). Finding `NON_LEDGER_STATE_NOT_ROUNDTRIPPED` → **RESOLVED**. Canonical artifacts intentionally regenerated.
- 2026-09-20: **Play-test finding (Owner)** — content exhausted in ~5 minutes. Measured: 3 settlements, 6 directed routes, 4 encounter types, ~1.5 encounters per trip, a fixed trade triangle. Root cause is not "too few events": nothing accumulates, and the road ignored what the world was doing.
- 2026-09-20: **Owner ordering ruling** — world-reactive encounters BEFORE expanding the map. Expanding first would scale 5 minutes of the same thing into 15. Also rejected the "7 settlements -> 30+ routes" framing: near-full connectivity destroys geography. A wasteland wants chokepoints, detours, hubs and dangerous corridors — 6 settlements should have ~7-9 physical roads, not 30.
- 2026-09-20: **S5-B4.1 World-Reactive Encounters CLOSED** — encounter candidates and weights now come from world state. Barricades grow where security collapsed (10 -> 54 over 180 road-days as security fell 100 -> 15), dying travellers appear on roads out of towns that ran dry (10 -> 30), fresh wreckage appears where the world really lost a caravan (29 -> 70), and a refugee column is an actual party in world.refugees rather than a spawned prop. An empty road drops 100 -> 60 in a world in crisis. Still no RNG: selection is a pure function of facts plus route and day, so replay stays exact.
- 2026-09-20: **S5-B4 Travel Encounters CLOSED** — the road can now stop you. Four encounters (wreck, rockslide, roadblock, dehydrated traveller), chosen as a pure function of route + departure day + travel-day index, with no RNG. Scavenge is folded into the wreck rather than built as its own system. Choices go through a RESOLVE_ENCOUNTER intent; a day spent is a real tick that drinks water and eats food, and a detour is padded so it costs time without shortening the road.
- 2026-09-20: **Owner ruling (S5-B5 follow-up)** — a settled player MAY fall back on their own backpack when the town's need goes unmet. The private ration protects only the player: it adds nothing to settlement stock, relieves nobody else's pressure and changes no aggregate. Drinking your own water and giving it to a town stay different acts.
- 2026-09-20: **Note** — transit deaths are attributed to the ORIGIN settlement's cumulative_deaths for population accounting. Read that as "the cohort they left", not as "they died in Gray Valley".
- 2026-09-20: **S5-B5 Player Survival CLOSED** — water and food are real resources now. Reuses the settlement model: need outcome -> pressure -> exposure -> grace -> death. In transit needs come from the backpack; settled, the player shares the town's own fulfillment ratio and the backpack is never touched, so there is no double metabolism. Replaced days_deprived_* with exposure so half rations accumulate as half a day of suffering. Two superseded rules, both rewritten rather than deleted: S4-B forbade IN_TRANSIT -> DEAD (you can now die on the road, counted against the settlement you left), and the autonomous NPC decision engine was quietly evacuating the PLAYER from failing towns — the player is now excluded from it.
- 2026-09-20: **Open design question (S5-B5)** — a SETTLED player cannot drink their own backpack, so camping in a town that cannot find water is fatal even with a full canteen. This follows directly from "the player shares the settlement's fortune", but the inverse case was not explicitly decided. Awaiting Owner ruling.
- 2026-09-20: **Play-test findings (Owner)** — the build is an operable world shell, not yet a First Playable: travel, events and survival are three open loops. Baked-in map art was lying about player position; travel made the player press "wait one day" per leg; with no events, trade is just spending down caps; water/food cannot kill, so they are decorative resources.
- 2026-09-20: **Map art rule (Owner)** — background artwork may contain terrain, ruins, roads and buildings ONLY. Place names, player markers, route day counts, node circles and UI text must be drawn by Godot at runtime, because baked text cannot follow a world that changes. AI-generated art answers "what does the world look like", never "where are you now".
- 2026-09-20: **S5-B3 Travel Auto-Advance CLOSED** — choosing a destination is the decision; the days of walking are not a second decision to keep confirming. Travel split into begin_player_travel + advance_player_travel so encounters can interrupt a journey later. This supersedes the S5-A.2 "no auto-tick" principle, and gate UI3 was rewritten rather than deleted so the change of intent stays visible.
- 2026-09-20: **S4-F1 Autonomous Decision Authority CLOSED ✅ (G2-lite)** — closed action space of STAY/MIGRATE only; the decision engine never holds a WorldState, so zero mutation authority is structural. Batch semantics with an immutable start-of-phase snapshot and lexicographic npc_id order. Rejected intents stay in the decision audit trail and never reach the event ledger. Traits/Aptitudes/Backgrounds deliberately do NOT influence decisions in F1.
- 2026-09-20: **Finding `STRINGNAME_SORT_IS_NOT_LEXICOGRAPHIC` CONFIRMED** — Godot sorts StringName by internal pointer. Avoided in the decision phase; existing engine iteration sites still sort StringName keys and are only coincidentally ordered. Awaiting Owner disposition.
- 2026-09-20: **S4-E Aptitude CLOSED ✅ (Fast Lane)** — closed-domain tag set on `NpcProfile`; deliberately no numeric ratings, since no Skill Growth system exists yet to give a rating meaning. S5-D will decide how TECHNICAL relates to Mechanics, not the reverse.
- 2026-09-20: **S4-D Traits CLOSED ✅ (first Fast Lane slice)** — closed-enum, set-like trait metadata on the existing `NpcProfile`; no new registry, no new governance axiom, no new validator type. D5 counterfactual confirms traits are simulation-inert. Whether a trait ever influences behavior stays an S4-F question.
- 2026-09-20: **Governance cadence set to Risk-Based (Owner)** — governance strength scales with new authority boundaries, not with every slice. Fast Lane (focused spec/tests, existing validators, regression; no new governance doctrine) for S4-D Traits and S4-E Aptitude. Full governance resumes at S4-F Autonomous Decisions. Inner loop runs focused tests; full regression + drift + independent validator run at slice closure only.
- 2026-09-20: **Finding `NON_LEDGER_STATE_NOT_ROUNDTRIPPED` ACCEPTED_FOR_WORK** — Owner disposition: dedicated slice **S4-C.2 Snapshot Numeric Canonicality**, activated before S4-D Traits. Traits are explicitly on WAIT until persistence continuity is proven.

## Known Risks

- **NPC Population Inflation**: Identity materialization must remain strictly representational, not demographic.
- **Identity Duplication / Floating Entities**: Enforce Single Population Membership invariant (exactly one container per alive NPC).
- **Narrative Authority Leaks**: Prevent downstream LLM dialogue from mutating world state.
- **PERSISTENCE_CODEC_DEFINES_NUMERIC_CANONICALITY** (recorded risk, not a blocker): since S4-C.2, authoritative float semantics are defined by Godot 4.7.2's JSON stringify/parse. If a future engine upgrade changes that formatting, the world's numeric trajectory can change with it. Mitigation: `NumericCanon.PROBE_CORPUS` (17 vectors) is asserted by Gate N6 — **run it FIRST on any engine upgrade**. A mismatch is not a routine dependency bump; it is a persistence/simulation compatibility change.
- **Aptitude Drifting into Skills**: S4-E is tag-only on purpose. Adding a rating, multiplier, learning rate or growth curve before S5-D defines real skills would let S4-E silently become the skill system. At S4-F, only Traits may participate in the Decision Engine; Aptitudes stay inert until S5-D.
- **StringName Iteration Order**: `Array[StringName].sort()` orders by internal pointer, not lexicographically, so any simulation step whose outcome depends on iterating sorted StringName keys is ordered by allocation rather than by id. S4-F1 sorts Strings explicitly; the older settlement/caravan iteration sites have not been changed and are only coincidentally in lexicographic order today.
- **Heuristic Numeric Repair**: Guessing a domain type from a serialized value (treating `3.0` as int) would overwrite domain truth with a guess. Restoration must be schema-driven, never inferred.
