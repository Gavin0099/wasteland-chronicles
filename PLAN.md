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

- [ ] S4-A : NPC Identity (+ G1.5-B1 Runtime Enforcement)
- [ ] S4-B : NPC Life State (+ G1.5-B2 Lifecycle Atomicity)
- [ ] S4-C : Background
- [ ] S4-D : Traits
- [ ] S4-E : Aptitude Schema (No XP)
- [ ] S4-F : NPC Autonomous Decisions (+ G2-lite Governance)

## Backlog

- P1: S5 — Player & Party (Player Verbs, RPG Progression Discovery)
- P1: S6 — Roguelite Legacy (Succession & World Memory)
- P2: S7 — Information Fog / UI (Fail-Closed Knowledge Boundary)
- P2: S8 — Vertical Slice (30~60 min Emergent Simulation RPG)

## Decision Log

- 2026-09-20: **S3 Human Ecology CLOSED ✅** and tagged `v0.0.1-s3` (S3-A through S3-F fully verified).
- 2026-09-20: **G1.5-A NPC Authority Contract CLOSED ✅** (Authority matrix, Single population membership, deterministic ID minting, validate-before-commit).
- 2026-09-20: **AI Governance Framework Imported** as submodule at `additional/ai-governance-framework`.

## Known Risks

- **NPC Population Inflation**: Identity materialization must remain strictly representational, not demographic.
- **Identity Duplication / Floating Entities**: Enforce Single Population Membership invariant (exactly one container per alive NPC).
- **Narrative Authority Leaks**: Prevent downstream LLM dialogue from mutating world state.
