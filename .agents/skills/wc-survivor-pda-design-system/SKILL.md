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
  `character_sheet.gd`; skill ranks use `skill_rank_row.gd`.
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
- Reuse theme type variations `PdaTitle`, `PdaSection`, `PdaMuted`, `PdaPrimary`,
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
