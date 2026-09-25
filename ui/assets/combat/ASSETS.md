# Original combat assets — 2026-09-22

Generated with the built-in image generation tool for this project, following the
owner-confirmed elevated battle-screen direction of **俠客遊・前途道標**. No original
game screenshot, sprite, logo, UI frame or third-party asset pack is incorporated.
These are illustrative bitmap assets; they do not encode combat state or UI text.

| File | Generation brief / use |
| --- | --- |
| `supply-shed.png` | Dusty wasteland supply-shed arena in an elevated/isometric view; quiet central fighting space, ruined walls, scrap and weathered shed. No fighters, text, symbols or interface. |
| `drifter.png` | Separate transparent adult drifter in an olive jacket and backpack, unarmed, three-quarter rear view facing upper-right; grounded muted wasteland illustration. |
| `feral-dog.png` | Separate transparent brown/grey feral dog, facing lower-left toward the drifter; matching elevated camera and muted illustration. |

Briefs above summarize the intended visual direction, not a promise of exact
regeneration. The checked-in PNGs are the original tool outputs, without image
post-processing. Runtime placement, scaling and equipment are handled in
`ui/components/battle_stage.gd`. The crowbar uses the separate generated
`ui/assets/items/crowbar.png`, scaled and positioned at the character's hand at
runtime. Its visibility follows equipped state; it is not painted into the character.

Motion uses Godot Tweens: anticipation, lunge, muted hit response, return,
defense feedback and retreat. Layered contact shadows follow each fighter's feet;
they are presentation only. Preserve a reduced-motion option and never put
damage, loot or death in an animation callback. Later sprite poses should keep
identical camera, lighting, scale and foot anchors. Do not generate a baked
battle video: HP, equipment and outcomes must remain live.

Reference: [ARTDINK official page](https://www.artdink.co.jp/japanese/title/ldpob/).
The reference sets visual direction; this version implements its own limited 1v1
rules rather than reproducing the reference game's mechanics.

## PLAY-1 placeholders — 2026-09-25

The road ambush has **no artwork**. Until it does, `battle_stage.gd` draws two
explicit stand-ins and labels them on screen as 暫用示意圖:

| Stand-in | What it is |
| --- | --- |
| `PlaceholderFigure` | A drawn humanoid silhouette used for the road bandit. It is not generated art and is not intended to ship; it exists so that a fight against people stops being drawn as a feral dog. |
| `PlaceholderBackdrop` | A drawn road: sky band, ridge line and a road widening toward the camera. It exists so that a roadside ambush stops being drawn inside the Gray Valley supply shed. |

The weapon in the fighter's hand is no longer hardcoded to the crowbar. It is
`ItemIcon.texture_for(<the item actually equipped in main_hand>)`, so the four
canonical melee items each show their own existing art, and an unarmed fighter
shows nothing. The crowbar remains the fallback for the legacy field kit.

Replacing either placeholder is a drop-in: supply real art and switch the
`configure()` branch to a TextureRect, exactly as the dog already is.
