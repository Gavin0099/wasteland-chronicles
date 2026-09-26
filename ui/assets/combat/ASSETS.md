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

Both stand-ins were rewritten on 2026-09-25 against Godot's custom-drawing API
rather than being left as flat shapes. The first version used only
`draw_colored_polygon` with one colour per shape, which is why it looked like
coloured paper: `draw_polygon` accepts a colour PER VERTEX, and `draw_line` /
`draw_polyline` take an antialiased flag. The backdrop now carries a sky
gradient, three ridge layers that darken as they near the camera, a road with
perspective dashes and worn edges, roadside wreckage, and the figures carry a
ground shadow, a lit side and a rim light.

This is still a stand-in and still says so on screen. It does NOT match the
painted drifter and dog beside it, and no amount of drawing code will: the gap
between a stylised vector figure and a painted cutout is a style gap, not a
detail gap. Replacing either placeholder remains a drop-in: supply real art and
switch the `configure()` branch to a TextureRect, exactly as the dog already is.
