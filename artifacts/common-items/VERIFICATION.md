# Common item artwork verification

Six original generated PNGs were copied without changing their bytes. The asset
manifest records matching source/output SHA-256, 1280×1280 dimensions, RGBA format
and alpha extrema 0–255 for each. Prompts are retained beside the assets.

The actual Godot renderer was inspected at 1280×720 and 1152×648. `catalogue.png`
shows every item at 168 px and at 32 / 48 px. `market.png`, `character.png`,
`character-small.png`, `battle.png`, and `loot-small.png` show game integration.
The first character capture exposed offscreen capacity/fuel; the final capture
uses two columns and keeps capacity visible. The battle weapon follows the hand
in the current pose, and remains governed by equipped state.

Eight affected existing suites pass: PDA character sheet, field combat UI,
character creation UI, encounter results, UI shell, wait, trade, and field combat.
The field UI receipt regression additionally covers full backpack: no gained
rows and the correct uncollected quantities. Existing replay and invariant gates
remain in the relevant suites. This is a presentation change, not a new gameplay
slice; no simulation file changes or new whole-suite completion claim.

No parse/script/asset-load errors were found. Existing shutdown RID/ObjectDB
diagnostics remain in the logs; these tests do not claim leak-free shutdown.
The shared skill passes its validator. The independent UI review identified the
character layout issue above and found no stale constructor call sites or new
world-state writes.

The test receipt's linked commit records the pre-change HEAD; tests were run
against the working implementation that is committed with these artifacts.
