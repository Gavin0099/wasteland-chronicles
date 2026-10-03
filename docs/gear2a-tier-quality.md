# GEAR-2A — Tier and Quality contract

Scope is Slice 2 of docs/rpg-gear-combat-slices.md. L2 definition/schema work; this changes rich item definitions, not world-instance persistence. No new gear, damage, protection, special action, random affix or economy formula.

## Contract

Rich ItemRegistry definitions add exactly four fields: `tier` (T1–T4), `quality` (COMMON/MODIFIED/RARE/UNIQUE), `properties` (stable-ID array), `unique_effect` (stable-ID string or empty). COMMON has zero properties, MODIFIED one, RARE two. UNIQUE has zero generic properties and exactly one fixed unique effect. Properties cannot repeat. Extra stat/multiplier fields, invalid counts/types and missing fields are rejected.

Tier describes an item's capability stage: T1 civilian/battered, T2 professional/improved, T3 military/high-end, T4 old-world top. Quality describes authored specialness, not a damage multiplier. Property/effect tokens are metadata at this step; GEAR-2D/2E will bind their approved behavior. Validation is structural, not permission to execute a property. `old_world_edge` labels the saber's existing fixed +5 melee contribution; it adds nothing to the existing formula.

The existing seven-field ItemCatalogue identity/asset contract stays separate and unchanged. Rich registry rows are detached, as are `gear_profile()` results. There is no installation API for candidate metadata.

| Existing item | Tier | Quality | Existing behavior retained |
| --- | --- | --- | --- |
| Legacy field-kit crowbar | T1 | COMMON | 3 unprepared melee damage at MELEE0, one cache opening |
| scrap_machete | T2 | COMMON | +3 melee contribution |
| old_revolver | T1 | COMMON | 6 + FIREARMS shot damage, one round per shot |
| old_world_saber | T4 | UNIQUE | fixed old_world_edge label; existing +5 melee contribution |
| travel_backpack | T1 | COMMON | +8 cargo capacity |
| military_backpack | T3 | COMMON | +12 cargo capacity |

Remaining existing definitions also have explicit mappings: hunting knife/caravan coat T2; all other current identities T1 COMMON. Crowbar remains in its legacy field kit and is accessible only through `gear_profile("crowbar")`; this does not create formal item ownership or accept a new registry ID.

## Compatibility and validation

Saves continue to contain item IDs and their existing equipment/inventory fields. Tier/Quality are looked up from authored definitions, never guessed from persisted numeric values or written into old saves. No schema bump or migration is needed. Existing market stock/counts, prices, weights and descriptions are unchanged.

`tests/fixtures/gear2a_legacy_item_registry.gd` is the verbatim rich registry source from pre-slice commit 97feb4d1198d7bb7430597b855e51f70b49739e6. The focused harness executes it as an independent frozen fixture and compares every former field in all sixteen records. It also executes pass/fail quality fixtures, actual legacy craft/equip/damage/backpack checks, ID-only save roundtrip, metadata-query purity, eight-day dual-track SHA-256 replay and global invariants. Focused result: 458 assertions pass.

Full `tests/test_*.gd` regression: 106 suites exit 0, no SCRIPT ERROR. Existing character, rumor and shop screens are captured at 1280×720 and 1152×648 using tools/capture_sheet_and_shop.gd to confirm rich-row compatibility; all six actual OpenGL captures inspected. Tier presentation and item comparison follow at CHAR-2. Automated checks do not prove FP2-B fun or player comprehension. Existing Godot test shutdown RID/ObjectDB warnings and the dynamic FieldScreen lint warning remain qualified in delivery evidence.
