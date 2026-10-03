# COMBAT-VIS-1 — battle stage

Scope: Slice 1 of the owner proposal in [rpg-gear-combat-slices.md](rpg-gear-combat-slices.md). L1 presentation change; simulation authority, damage, ammo, experience, lifecycle and day timing are unchanged.

The player stays left and the enemy right, on a shared foot line. Authored foot UVs, contact shadows and per-item grip UVs remain the placement authority. The screen uses a wide arena with identity/HP/weapon beside the player and the real enemy action/damage/brace consequence above the enemy. Commands form a fixed bottom grid; history and loot receipts scroll independently. Six preparation commands use three columns. The normal/reduced-motion post-commit pipeline is preserved for COMBAT-VIS-2 to extend later.

Scenery follows battle/receipt metadata, in this order: `place:hammer_camp`, `route_type=WILDERNESS`, road source, then the Gray Valley shed. Confirming or fleeing never invents a different place. No new enemy or place was added.

## Validation

- `tests/test_combat_vis1.gd`: 510 assertions across 1280×720 / 1152×648, all four scenes and two weapon styles. Checks actual actor/card boundaries, commands, asset loading, refusal of unknown scenery, no world mutation on refresh, result scenery and opponent identity, checked persistence, UI/headless SHA-256 replay and global invariants. Preparation is created through real character/equipment intents.
- Full `tests/test_*.gd` regression: 105 suites exit 0, no SCRIPT ERROR. After the result-identity repair, all six affected UI/combat suites were rerun and pass.
- `tools/capture_combat_vis1.gd`: 22 real OpenGL captures, including preparation, melee/gun in four scenes, no ammunition and camp result, at both sizes. Stored under the Godot user-data `captures/combat-vis1` directory. Images inspected before delivery. Automated geometry and images establish layout, not the owner's three-second comprehension or FP2-B fun acceptance.
- Existing Godot test teardown RID/ObjectDB warnings remain; successful exit codes do not claim clean runtime logs.
- Godot lint: zero errors, existing dynamic FieldScreen lookup warning. NPC authority fixtures and governance drift checks pass.

## Background assets

Generated with the built-in imagegen tool on 2026-10-03; original outputs copied unchanged into `ui/assets/combat/wilderness.png` and `ui/assets/combat/raider-camp.png`. No baked UI, people, state or place labels. The existing highway/shed art remains in use. Prompts:

### Wilderness

Original game background asset, landscape 16:9. Empty post-apocalyptic wasteland wilderness battle arena in painterly realistic late-1990s isometric RPG illustration style, muted dusty amber tan brown palette. Slight elevated camera looking into a broad flat dirt clearing; rocky ridges on horizon, scattered dry scrub and distant rubble at perimeter. Open empty central and lower foreground ground for two separately rendered fighters. Ground plane extends unobstructed across lower half. Warm overcast sun. Detailed consistent game environment illustration, no people, animals, weapons, interface, lettering, markers, roads or asphalt. Output single background only.

### Camp

Original game background asset, landscape 16:9. Empty post-apocalyptic raider camp battle arena in painterly realistic late-1990s isometric RPG illustration style, muted dusty amber tan brown palette. Slight elevated camera looking into broad flat dirt clearing, improvised canvas tents and corrugated metal barricades at far back and outer sides, rusty barrel near perimeter. Open empty central and lower foreground for two separately rendered fighters, unobstructed ground plane across lower half. Warm overcast sun. Detailed consistent game environment illustration, no people, animals, weapons, interface, lettering or markers. Output single background only.
