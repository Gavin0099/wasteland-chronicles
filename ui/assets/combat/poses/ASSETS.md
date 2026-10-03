# Combat pose assets

Created with the built-in image_gen tool on 2026-10-03, using this repository's existing drifter, feral dog, bandit and raider art as identity/style references. The four final PNGs are original generated cutouts; no external demo texture, model or audio was copied. Existing originals were preserved.

Full final prompts, reference paths and SHA-256 provenance are in prompts.json. The first horizontal bandit draft was rejected because its pipe crossed into another frame; only the separated square final is shipped.

The atlas cells are not assumed to be uniform. battle_pose_library.gd authors the actual rectangle, foot point, hand point and standing reference height for each pose. AtlasTexture selects regions at runtime without rewriting the PNG or its alpha. Feet and weapon grips are tested through the real Sprite2D transforms. Original rest artwork preserves the existing idle grip contract; the drifter atlas idle cell is unused.

Drifter: overhead windup, extended strike, aiming, crouched brace, hurt, kneeling collapse, prone collapse. Enemies: windup, strike, hurt and fallen poses. The drifter's hands contain no weapon; actual equipped item art is attached at each authored grip. Bandit and raider retain their fixed enemy weapons. Defeat art has no gore and does not imply a road player died.

Reference timing/lifecycle guidance is documented in docs/battle-animation-references.md. Image generation is an asset-authoring tool; committed simulation receipts retain combat authority.
