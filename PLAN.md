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
- [ ] **S4-F2 : Autonomous Migration (decision to physical arrival) — CURRENT**
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
