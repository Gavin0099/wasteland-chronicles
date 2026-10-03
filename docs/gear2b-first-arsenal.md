# GEAR-2B — First Arsenal

Slice 3 of docs/rpg-gear-combat-slices.md. Nine curated core choices include the existing kit crowbar, machete, old-world saber and revolver. Five new weapons and one ammunition identity are added; existing rusted knife, hunting knife and rebar club remain compatible. Thus there are eleven formal weapon identities plus the legacy kit crowbar, and twenty-two total formal items. This is not a random loot table or activation of the art library.

## Authored decisions

Damage below is unprepared MELEE0/FIREARMS0, solo. Existing skill, preparation and companion contributions still apply. Tier/Quality never multiply damage. New equipment is COMMON; old-world saber retains its UNIQUE classification.

| Core choice | Tier | Weight g | Base caps | Damage | Decision |
| --- | --- | ---: | ---: | ---: | --- |
| Kit crowbar | T1 | existing kit | existing kit | 3 | Existing cache OPEN; armory still needs its skill method |
| Sledgehammer | T1 | 3200 | 38 | 6 | Retreat costs 2 HP instead of 1 |
| Scrap machete | T2 | 1200 | 48 | 5 | Existing dependable melee choice |
| Combat knife | T2 | 450 | 90 | 5 | GEAR-BALANCE-1: +1 over hunting knife; lighter than same-damage machete |
| Reinforced saber | T3 | 1600 | 200 | 6 | Same hammer damage, lighter, ordinary retreat |
| Old-world saber | T4 UNIQUE | 1300 | 300 | 7 | Existing armory aspiration, retained |
| Old revolver | T1 | 1000 | 160 | 6 | One 12-cap revolver round |
| Police revolver | T2 | 1200 | 230 | 7 | Same ammunition, higher damage |
| Short shotgun | T2 | 2800 | 240 | 10 | One 30-cap, 50g shotgun shell |

Prices are base values; the existing regional and shortage quotes remain authoritative. Hammer and combat knife are stocked in Gray Valley; hammer also in Dry Well. New Hope stocks all five additions and shotgun shells. Old saved stock is preserved exactly on load; the existing four-day restock adds missing supplied identities without resetting other quantities. Old loot, ownership and prices are unchanged.

Against the existing 16-HP heavy raider, fresh solo MECH characters buying a complete ammunition batch in New Hope have these verified outcomes:

| Firearm | Shots | HP after victory | Ammunition caps |
| --- | ---: | ---: | ---: |
| Old revolver | 3 | 6 | 36 |
| Police revolver | 3 | 6 | 36 |
| Short shotgun | 2 | 9 | 60 |

This excludes weapon purchase. The shotgun avoids the next enemy retaliation at higher ammunition cost. Police revolver need not reduce every enemy's turn count to justify its distinct fixed damage. Holding a firearm still permits melee and retreat when empty. Wrong ammunition cannot authorize SHOOT and changes no state. Committed shot receipts identify the actual gun and ammunition; checked loads reject cross-ammunition receipts. No population, daily phase or arrival formula changes.

## Presentation and evidence

Five new weapons have explicit icon-to-fist grip profiles. Left-facing source police revolver and shotgun art is mirrored, with each grip pinned to the hand and muzzle toward the opponent. Existing profiles are unchanged. Field command labels use actual equipped damage, ammunition, remaining quantity and hammer retreat cost.

The focused harness executes real purchases, equipment, heavy-raider combat, exact caps/HP/ammunition outcomes, malformed and stale receipt refusals, old-stock preservation, save/resume, dual-track SHA-256 and global invariants. Fixed expected values above are authored design fixtures, not derived from production tables. Market fixtures declare the new identity set and regional counts (New Hope 20, Gray Valley 14, Dry Well 13 offers).

Validation: 141 focused assertions pass. Full regression executed all 107 suites: 105 initially passed; two old-fixture assumptions (market counts, unmirrored source grips) were corrected and rerun successfully. Final affected reruns also include COMBAT-VIS-1 (510) and arsenal (141); every suite now has exit 0 and no SCRIPT ERROR. NPC authority validator and governance drift pass; lint has zero errors and one existing dynamic-node warning.

Actual OpenGL captures: tools/capture_gear2b.gd, five weapons at 1280×720 and 1152×648, stored in Godot user captures/gear2b. Existing test-shutdown RID/ObjectDB warnings and one dynamic FieldScreen lint warning remain; automated verification does not close FP2-B human play acceptance.

Independent review found no unresolved P0/P1. Deferred P2: retained hunting knife offers the same damage as combat knife for 400g/72 caps instead of 450g/90 caps. The new knife is lightweight relative to the heavy core weapons, but currently lacks an advantage over that legacy knife; its balance distinction remains follow-up. Two documentation count/access inaccuracies were corrected before commit; no gameplay change was made for nonblocking findings.

Original sledgehammer artwork: imagegen, transparent PNG copied unchanged to ui/assets/items/sledgehammer.png. Final prompt: "Original inventory icon for a wasteland RPG, a plain civilian heavy sledgehammer made of worn steel rectangular head and long dark wooden handle wrapped with faded cloth at grip. Single object only, diagonal grip at lower-left and hammer head upper-right, fully visible with roomy transparent margin. Muted dusty brown and steel grey painterly realistic late-1990s RPG item illustration, elevated three-quarter view, hand-painted texture. No text, no lettering, no effects, no power cells, no lights, no futuristic attachments, no hand or person. Truly transparent background." Other icons reuse existing explicit art references; shotgun ammunition is a small authored SVG.
