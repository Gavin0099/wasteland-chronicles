---
name: wc-survivor-pda-design-system
description: >-
  Build, edit, and review Wasteland Chronicles Godot interfaces and UI artwork with
  the shared Survivor PDA theme. Use for character, supplies, encounters, equipment,
  and combat screens when those features are in scope; not for unrelated apps.
---

# Survivor PDA — canonical UI skill

Use this skill for Wasteland Chronicles UI work. It replaces the competing visual
rules in `wasteland-chronicles-ui-v1`. Preserve the existing dark industrial PDA:
charcoal panels, dirty ivory text, restrained amber commands, thin square borders.
Traditional Chinese is the primary player language. Keep names and numerical data
as actual Godot text, never baked into artwork.

## Sources of truth

Resolve paths from the repository root, three levels above this skill directory.

- `ui/theme/pda_tokens.gd`: shared color, spacing, and type tokens. Reuse these;
  adding a new token requires a real semantic use, not a screen-specific shade.
- `ui/theme/theme_builder.gd` → `ui/theme/survivor_pda_theme.tres`: generated project
  theme. Change the builder, regenerate, then inspect its diff. Never fix only the output.
- `ui/components/`: reuse existing components. Character and supplies use
  `character_sheet.gd`; skill ranks use `skill_rank_row.gd`. Common item artwork uses
  `item_icon.gd` with water / food / scrap / fuel / caps / crowbar IDs. Reuse the
  transparent originals in `ui/assets/items/`; keep names and quantities next to
  32 px icons, and consult that folder's `ASSETS.md` and `prompts.json` for variants.
- Simulation / projection data decide values, available actions and consequences.
  A visual mockup is never evidence that the corresponding mechanic exists.
- `references/resources.md`: verified external references and how to apply them.
  Read for theming, accessibility, layout, or icon decisions; these resources do not
  replace the project's visual identity.

## Visual contract

| Role | Token / value |
| --- | --- |
| App / panel / elevated | `BASE #121316` / `PANEL #1B1D22` / `ELEVATED #22252B` |
| Quiet / strong border | `BORDER #2A2D35` / `BORDER_STRONG #454A55` |
| Text / supporting text | `TEXT #D8D3C8` / `SECONDARY #96938B` |
| Selected / primary action | `AMBER #D9822B` |
| Critical accent | `CRITICAL #A8382B`; use readable ivory wording beside it |
| Operational indicator | `LIVE #39D353`; only a small marker with a label |
| Spacing | 4, 8, 12, 16, 24, 32 px |
| Type | title 24, section 18, body/data 16, supporting 14 px |
| Geometry | 1 px borders, 0–2 px corners; commands at least 40 px tall |

Use a labeled warning, lock, selection marker, or numeric value as well as color.
Necessary text targets 4.5:1 contrast; a locked requirement is still necessary text.
Muted does not mean unreadable. Rust red is an accent, not small body text.
No green screen wash, neon, glow, glass cards, scanlines, decorative rust behind text,
or unrelated SaaS dashboard styling. Existing legacy colors may be migrated when a
component is touched; do not repaint unrelated screens just to widen a UI task.

## Layout and components

- Use Godot Containers, size flags, wrapping, and scroll areas. Do not manually place
  children of Containers. Keep primary actions outside scrolling content when feasible.
- Each panel answers one question. Character: who am I / what can I do? Supplies:
  what do I carry? Encounter: what can I choose / what happened? Combat, once implemented:
  whose turn is it / what will this action cost / what happened?
- Reuse theme type variations `PdaTitle`, `PdaSection`, `PdaMuted`, `PdaCommand`, `PdaPrimary`,
  `PdaPanel`, and `PdaDialog`. Do not copy a local StyleBox into each new screen.
- Skill ranks are integers 0–5 with five segments, number, and rank name:
  外行 / 略懂 / 熟練 / 專業 / 專家 / 大師. Never display them as percentages.
- Buttons support normal, hover, focus, pressed and disabled states. Keep keyboard
  focus visible; Tab/Enter and Esc-close work. Tooltips supplement visible information.
- Raw internal error codes belong in diagnostics. Player messages state the cause and
  next possible action. Do not turn an authority rejection into UI-side world repair.
- Creation, live character view and receipts project the current feature set. Revisit
  copy such as “not implemented” whenever the feature is implemented.
- Encounter receipts persist until explicit confirmation. A locked option stays readable;
  hidden/locked eligibility and result rules remain the simulation's authority.
- No empty HP, XP, equipment or combat pages unless the requested work implements those
  systems or explicitly requests a labeled prototype. User-approved new slices may add
  corresponding real components; this skill is not a feature approval gate.

## Chrome belongs to the tokens too

A screen can follow every rule inside its panels and still look wrong, because
the frame around them was written separately. Window chrome, toolbars and title
bars are UI; they use the same tokens as everything else. Checked 2026-09-25:
`desktop_window.gd` and `field_screen.gd` between them hardcoded a `#496AA8`
title bar, a 2px `#B8B6AF` frame, pale `#DCDAD2` / `#D1D0C9` toolbars and pure
white title text. None of those are in the token table, and together they read
as a pale desktop window pasted over a dark industrial PDA. They were the
loudest thing on every screen and the first thing an owner playtest called ugly.

- Chrome uses `PANEL` / `ELEVATED` fills, `BORDER` or `BORDER_STRONG` at 1 px,
  `TEXT` for labels and `AMBER` only where it means "this is what you are about
  to touch": the active title, focus, hover, the primary command.
- An accent is a hairline or a word, not a filled band. If a quarter of the
  screen is one accent colour, that colour has stopped meaning anything.
- Before adding a colour, find its token. A colour with no token is a decision
  nobody wrote down, and it will not survive the next screen.

## A battle screen is three questions in reading order

Combat is the screen where a player is making a decision under a clock, so its
layout is a sequence, not a grid of boxes:

1. **Who is fighting and how hurt are they?** Both fighters get a labelled bar
   AND the number: `你　6 / 12`. A number alone makes the player do arithmetic
   before they can feel danger; a bar alone hides the exact value the rules use.
2. **What is about to happen?** A telegraphed action is the single fact that
   decides the turn, so it sits immediately above the commands, states the real
   damage, and says what bracing would save. It takes `CRITICAL` only when the
   incoming blow really is the dangerous one — a panel that is always red is
   never a warning.
3. **What can I do, and what will it cost?** Each command carries its own number
   (`攻擊 · 傷害 5`, `架勢防禦 · 減傷 7`), so the comparison happens on the
   buttons rather than in the log.

The combat log is history, not the interface. Anything a player needs in order
to choose must not live in a scrolling log; found 2026-09-25 with the raider's
wind-up buried under the arena while a near-empty "交戰位置" panel held a screen
of blank space beside the commands. Panels that state a constant deserve their
space only if the constant is a decision.

## Data and interaction boundary

UI reads projections and sends existing intents. It never mutates world inventories,
HP, skills, population or time directly. Refresh after a committed action; opening or
closing a sheet must not spend a day or resolve an encounter. Retain local/remote
knowledge boundaries. Debug history remains labeled as debug, not player knowledge.

## Verification before reporting a screen done

1. Exercise the real scene, including empty/zero, full capacity, locked/error states,
   long names, keyboard focus and return/close. Run behavior tests when wiring changes.
2. Capture the real Godot renderer at 1280×720 and 1152×648; inspect the images. Verify
   no clipped text/actions, meaningful scroll, consistent alignment and legible locks.
3. Confirm UI queries leave world snapshots unchanged. New gameplay slices additionally
   follow repo replay/invariant tests; do not equate screenshots with authority coverage.
4. Record screenshots and what was actually checked. Keep C2 player-experience claims
   separate from code tests. A changed UI build is a new playtest version.

Do not add images or download asset packs just to satisfy this skill. Reuse local art;
if art is requested, reference an existing anchor and apply this same palette and grammar.

## Current combat art reference

Owner selected **Lunatic Dawn: Passage of the Book (俠客遊・前途道標)** as the
first battle-screen reference. Use an elevated/isometric arena with visible fighters
and a stable command area, retaining this project's PDA frame. First slice was a
single player and animal opponent; PLAY-4 added a bandit and a heavy raider. Do
not imply formation, pathfinding, party or movement mechanics from the visual
composition. Where an enemy has no artwork, draw a labelled stand-in rather than
reusing another enemy's art: two opponents that share a sprite teach the player
that the picture is decoration. Stand-ins say so on screen and are recorded in
`ui/assets/combat/ASSETS.md` as drop-in replaceable. Assets live in `ui/assets/combat/`.
The environment contains no fighters, UI or text. Fighter cutouts are separate;
weapon presence, HP, damage and outcomes come from current state. Tween motion is a
projection after commit; never apply damage in an animation callback. Keep reduced
motion available. Sprite pose animation can be expanded later without changing combat
authority. See `docs/field-combat-lite.md` for the implemented first-slice limits.
