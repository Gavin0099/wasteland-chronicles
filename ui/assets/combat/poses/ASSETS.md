# Combat pose assets

Created with the built-in image_gen tool on 2026-10-03, using this repository's existing drifter, feral dog, bandit and raider art as identity/style references. The four final PNGs are original generated cutouts; no external demo texture, model or audio was copied. Existing originals were preserved.

Full final prompts, reference paths and SHA-256 provenance are in prompts.json. The first horizontal bandit draft was rejected because its pipe crossed into another frame; only the separated square final is shipped.

The atlas cells are not assumed to be uniform. battle_pose_library.gd authors the actual rectangle, foot point, hand point and standing reference height for each pose. AtlasTexture selects regions at runtime without rewriting the PNG or its alpha. Feet and weapon grips are tested through the real Sprite2D transforms. Original rest artwork preserves the existing idle grip contract; the drifter atlas idle cell is unused.

Drifter: overhead windup, extended strike, aiming, crouched brace, hurt, kneeling collapse, prone collapse. Enemies: windup, strike, hurt and fallen poses. The drifter's hands contain no weapon; actual equipped item art is attached at each authored grip. Bandit and raider retain their fixed enemy weapons. Defeat art has no gore and does not imply a road player died.

Reference timing/lifecycle guidance is documented in docs/battle-animation-references.md. Image generation is an asset-authoring tool; committed simulation receipts retain combat authority.

Animation completion adds six companion atlases (36 poses) without replacing the four original atlases: drifter-movement.png, drifter-melee.png, drifter-guns.png, feral-dog-movement.png, road-bandit-movement.png and heavy-raider-movement.png. Built-in image_gen generated all six; completion-prompts.json records complete generation/edit prompts, reference roles, selected source filenames and unchanged source/final SHA-256 hashes. The first melee companion draft was rejected because its top boots entered the lower windup rectangle; image_gen widened the gutters. PNG files and generated alpha were preserved verbatim; read-only silhouette analysis informed the authored regions.

New frames cover idle breathing, alternating approach/retreat strides, blade/hammer follow-through, handgun/long-gun recoil and lowering, three enemy half-collapse frames and heavy anticipation. Each selects its own imported atlas through ResourceLoader; a checked raw fallback supports an unimported source project. Shotgun aim/recoil use a longer projected silhouette to clear the forward support hand; original resting weapon proportions and grip remain intact. Actor feet and weapon muzzle/grip positions are authored separately from world movement.


RLY-4 adds original grey-crow-capture.png (1536×1024RGBA) from built-in image_gen with the existing Grey Crow portrait as reference. The bitmap is copied unchanged; six manually authored regions/feet share485px standing scale including the physically shorter living captive. grey-crow-capture-provenance.json records the complete prompt, original source/reference and SHA-256. Knife/disarmed/tied poses follow committed PURSUIT facts, with no damage/custody authority in art.

RLY-5 adds the separate original grey-crow-aftermath.png (1536×1024RGBA), built-in image_gen using the same portrait as character/style reference. It depicts one fallen person without gore or ropes; the original bitmap/alpha is unchanged. grey-crow-aftermath.provenance.json retains complete prompt, source/reference and SHA-2567c937b9fb047f4fbde1307e603aca30c263e02cf60c5b49daf667352a730bd5c. Authored region selects the silhouette with a1380px equivalent standing reference, rather than magnifying the wide generated pose to the old atlas's485px. The six living poses remain unchanged. Only an actual TARGET_DEAD receipt selects fall.
