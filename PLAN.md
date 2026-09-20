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
- [ ] **S4-C.2 : Snapshot Numeric Canonicality — CURRENT**
- [ ] S4-D : Traits — WAIT (blocked behind S4-C.2)
- [ ] S4-E : Aptitude Schema (No XP)
- [ ] S4-F : NPC Autonomous Decisions (+ G2-lite Governance)
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
- 2026-09-20: **Finding `NON_LEDGER_STATE_NOT_ROUNDTRIPPED` ACCEPTED_FOR_WORK** — Owner disposition: dedicated slice **S4-C.2 Snapshot Numeric Canonicality**, activated before S4-D Traits. Traits are explicitly on WAIT until persistence continuity is proven.

## Known Risks

- **NPC Population Inflation**: Identity materialization must remain strictly representational, not demographic.
- **Identity Duplication / Floating Entities**: Enforce Single Population Membership invariant (exactly one container per alive NPC).
- **Narrative Authority Leaks**: Prevent downstream LLM dialogue from mutating world state.
- **Save/Load Time Divergence**: Non-ledger world state is not yet a serialization fixed point (domain ints widen to float, tiny floats lose precision). Until S4-C.2 closes, an interrupted run cannot be assumed to continue identically to an uninterrupted one.
- **Heuristic Numeric Repair**: Guessing a domain type from a serialized value (treating `3.0` as int) would overwrite domain truth with a guess. Restoration must be schema-driven, never inferred.
