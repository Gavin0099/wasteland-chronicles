# Item World V0 — full art library

The owner requested completing the inventory art catalogue before ITEM-1 on
2026-09-22. This changes the art production order, not the item gameplay contract.
The twelve-item baseline commit `38f2bad` and its original PNGs stay intact.

`docs/item-world-v0.md` contains 187 category rows and 185 different names. Salt
and batteries each occur in two categories and share one image. Sixteen names
reuse existing art: the baseline twelve, crowbar, canteen, ration and fuel. The
remaining 169 have separate generation jobs, split into four groups:

| Group | Catalogue sections | New illustrations |
| --- | --- | --- |
| [weapons prompts](weapons/prompts.json) | 1–4 | 36 |
| [clothing prompts](clothing/prompts.json) | 5–6 | 26 |
| [supplies prompts](supplies/prompts.json) | 7–11 | 68 |
| [relics prompts](relics/prompts.json) | 12–15 | 39 |

Delivery status on 2026-09-22: **185/185 names covered, 169/169 new images
generated, zero pending**. Metadata validation and the full Godot capture pass.
See [verification](../../../../artifacts/item-art-library/VERIFICATION.md).

Each group retains exact `prompts.json` instructions and per-image `records/`
with source filename, SHA-256, dimensions and alpha metadata. Original built-in
`image_gen` outputs are copied without pixel editing. `catalogue.json` gives
name/category coverage and honest generated/pending status; regenerate it with
`python artifacts/item-art-library/build_catalogue.py`. Use `--require-complete`
to reject missing illustrations at final delivery. The art index is not a runtime
item registry and supplies no authoritative item IDs, balance values or effects.

Browse the [category gallery and all originals](../../../../artifacts/item-art-library/INDEX.md).
The gallery uses the actual Godot Survivor PDA theme, with a main illustration
and 32/48 px samples. The twelve-image cover is a representative selection;
the category pages contain every catalogue row.

The canteen, ration and fuel reuse is visual only. Existing aggregate resources
do not thereby become separate containers or consumable item stacks. Medicine,
mechanical parts and ammunition include category illustrations; their precise
item types remain for ITEM-1/ITEM-2. Clothing is inventory art, not character outfit
layers or portraits. Weapons are not complete held-pose or animation sets.

Visual direction follows the canonical Survivor PDA skill: restrained weathered
materials, soft upper-left light, transparent backgrounds, clear silhouettes and
no baked interface text. Display labels alongside small icons, especially slender
weapons. Use the retained originals at the size the eventual Inventory UI needs;
do not redraw approved 32 px icons solely because fine texture disappears.

This library does not enable equipment, treatment, repair, climbing, lighting,
ammunition, regional prices, loot, durability or identification mechanics. Those
remain in the ITEM-1 → ITEM-6 implementation sequence. Art completion and system
completion are separate milestones.
