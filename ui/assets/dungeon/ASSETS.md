# Waterworks exploration art

`waterworks-floor.png` is original opaque floor art generated with the built-in
image_gen tool on 2026-10-04. Source: exec-70977f28-32a1-43fb-8fe1-22a07bf5d5b7.png.
SHA-256: fea17544115e594889d0266be974ab2bb6bc126793ee9b6bcd689879f60112c9.
The generated PNG is preserved verbatim. No external source assets were copied.

Full generation prompt:

> Use case: stylized-concept. Asset type: production 2D game FLOOR TEXTURE for Wasteland Chronicles abandoned underground waterworks. Create a square, straight-down orthographic view of a worn industrial concrete floor ONLY, filling the whole image edge to edge. Gritty hand-painted late-1990s PC RPG art, subdued charcoal grey concrete with muted brown mineral grime, subtle cracks, faint broad square slab joints, scattered tiny dust grit and old water staining. Readable calm middle area so a small olive-jacket traveller and runtime doors can be seen. Even overhead ambient illumination, moderate detail without visual noise. Absolutely NO walls, doors, furniture, machinery, pipes, stairs, characters, shadows from objects, text, icons, numbers, borders, UI, perspective, isometric diamond, glossy reflections, neon or grid overlays. This is a ground material layer: collision walls, props and door positions will be drawn separately by the game. Opaque floor, not transparent. Match a serious dusty post-apocalyptic water treatment basement.

Room geometry, labels and collision use the same runtime obstacle/door coordinates.
The traveller reuses the existing drifter-movement atlas's authored step_a/step_b
and recover regions from battle_pose_library.gd. Runtime foot anchors preserve
standing scale; reduced motion selects recover while retaining movement. This
slice supplies two alternating lateral stride poses, not a newly authored
eight-direction animation set. No weapon, enemy or loot is implied by this art.

`waterworks-pump.png` is an original transparent prop generated with built-in
image_gen on the same date. Source: exec-2ed7fe9f-1650-4ca5-a78d-8de9de553c6c.png.
SHA-256: d1463d0dacf33d1e210b33f37ff03d761a67953b35c34884486c90d56c69a1b4.
RGBA alpha was inspected read-only (0–254); the PNG remains unmodified. It is
drawn into authored obstacle rectangles, with conservative twelve-unit foot clearance.

Full generation prompt:

> Use case: stylized-concept. Production transparent isolated game prop for Wasteland Chronicles. One abandoned rectangular industrial water pump assembly: low squat heavy oxidized steel pump housing, rusty pipes bent along its top and sides, one old circular valve wheel and worn bolts, dusty chipped paint and muted brown grey grime. Camera elevated very high 3/4 overhead, designed to sit on a top-down RPG concrete floor. Broad rectangular silhouette with all pipes contained inside its overall rectangle; full object, centered, generous transparent padding, no cropped pipes. Gritty hand-painted late-1990s PC RPG art with clear detailed material texture, matching an olive-jacket wasteland traveller. Genuine transparent alpha background, NO floor, cast ground shadow, background, room, characters, text, labels, logos, UI, gradients or glow. A single prop, not a sheet. Even overhead light; darker steel housing, restrained rusty accents.
