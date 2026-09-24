# Common item artwork — first set

The broader owner-directed candidate catalogue and proposed next art batches live
in `docs/item-world-v0.md`. The water canteen, ration and scrap illustrations here
represent existing aggregate resources, not separate container/food/material
inventories. Regional sourcing and new item effects in that catalogue are future
content directions, not mechanics enabled by these images.

The follow-up twelve-item art set is documented in `candidates/ASSETS.md`, with
separate original PNGs, prompts and preview sheets. Candidate artwork is not
registered in the runtime item component until its corresponding gameplay exists.

The full fifteen-category illustration library is documented in
`library/ASSETS.md`, with a browsable category and original-image index at
`artifacts/item-art-library/INDEX.md`. It reuses the twelve-item baseline and four
of these existing illustrations; it does not replace their runtime resource roles.

Six original transparent images generated on 2026-09-22 with the built-in
`image_gen` tool. Exact prompts are in `prompts.json`. All files are the original
tool outputs, copied into this repository with alpha preserved; no third-party
pack, API/CLI fallback, or offline image editing was used.

| ID / PNG | Visual identity | Current use |
| --- | --- | --- |
| water | Blue-grey oval canteen | Personal supplies, market, supply chips, field loot |
| food | Ivory and olive wrapped ration | Personal supplies, market, supply chips, field loot |
| scrap | Rusty gear, plate and bolts | Personal supplies and market |
| fuel | Ochre/rust rectangular jerrycan | Personal supplies and market |
| caps | Three plain worn bottle caps | Personal currency |
| crowbar | Diagonal steel pry bar | Owned/equipped item row and runtime battle weapon |

All six correspond to existing game resources or equipment. These images do not
add items, alter inventory, change prices, supply new weapon statistics or make
new character appearances selectable. Quantity and ownership remain live text.

Use `ui/components/item_icon.gd` for 32 px inventory/market icons. It preserves
aspect ratio and loads either imported Godot textures or raw PNGs for headless
runs before editor import. It caches each texture and ignores mouse input so art
does not intercept a command. Unknown IDs keep the neighboring text available.

The battle crowbar shares the same illustration; Godot applies only runtime
position/scale and existing motion. It is suitable for the current static fighter
pose, not a full weapon sprite sheet with independently authored grip angles.

Visual direction: weathered but legible silhouettes, soft upper-left light,
restrained blue/olive/ivory/rust/steel, no words, branding or baked interface.
Future variants should keep this direction and be compared at 32–48 px on the
actual PDA panel. Asset hashes/dimensions are in `manifest.json`; actual renderer
captures and verification are in `artifacts/common-items/`.
