# Item World V0 — follow-up art batch

Owner requested drawing the proposed next 12 common items on 2026-09-22.
These are original inventory illustrations generated with the built-in `image_gen`
tool. Exact prompts are in `prompts.json`; source output identities and original
hashes are in `sources.json`. `manifest.json` records the actual dimensions,
transparency and asset status after verification.

| Category | File | Display name |
| --- | --- | --- |
| Common melee | rusty_knife.png | 生鏽小刀 |
| Common melee | hunting_knife.png | 獵刀 |
| Common melee | rebar_club.png | 鋼筋棍 |
| Common melee | scrap_machete.png | 廢鐵砍刀 |
| Travel clothing | work_clothes.png | 舊工作服 |
| Travel clothing | desert_robe.png | 沙地長袍 |
| Travel clothing | caravan_coat.png | 商隊外套 |
| Travel clothing | travel_backpack.png | 舊旅行包 |
| Common tools/supplies | rope.png | 繩索 |
| Common tools/supplies | flashlight.png | 手電筒 |
| Common tools/supplies | wrench.png | 扳手 |
| Common tools/supplies | medkit.png | 急救包 |

Direction: worn utilitarian canvas, steel, leather and cloth; soft upper-left light;
muted olive, brown, ivory and rust. Subjects have distinct silhouettes and genuine
transparent backgrounds, with no baked labels or interface. Original PNG bytes and
alpha are preserved. No downloaded game art, paid pack or image-editing script was
used; Godot handles preview placement and scaling.

All twelve are **art candidates, with gameplay not implemented**. They are kept
outside the runtime `ItemIcon.ITEM_IDS` catalogue, markets, loot tables and saves.
This batch does not grant weapon statistics, clothing defense, backpack capacity,
healing, repair or new exploration abilities. The six previously implemented items
remain documented in the parent directory.

The garments are standalone inventory illustrations, not character portraits or
ready-to-swap clothing layers. The weapon images are not complete in-hand animations;
grip, perspective, occlusion and poses need separate verification when a weapon is
added to combat. See `docs/item-world-v0.md` for the broader content direction.

Review gallery: `artifacts/item-art-v0-batch2/catalogue.png` plus
`weapons.png`, `clothing.png` and `tools.png`. These are real Godot preview renders
with large images and 32 / 48 px samples, not production game screens.

Reproduce the preview once assets are present:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility --script artifacts/item-art-v0-batch2/capture.gd
```

Asset verification uses Pillow only to read images and write JSON metadata; it never
changes the PNGs:

```powershell
python artifacts/item-art-v0-batch2/verify_assets.py
```
