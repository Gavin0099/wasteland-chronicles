---
name: wasteland-chronicles-ui-v1
description: >-
  Visual and interaction design guidelines, design tokens, and UI layout specifications
  for Wasteland Chronicles. Defines the Survivor PDA aesthetic, design tokens, panel hierarchy,
  and rendering standards for all in-game UI and generative anchors.
---

# Wasteland Chronicles UI Specification (v1)

## 1. Aesthetic Core: Survivor PDA (Dark Industrial)

Wasteland Chronicles strictly avoids broad-area green CRT (Pip-Boy) and cyberpunk neon.
The visual identity is anchored on a **rugged, dark industrial field terminal (Survivor PDA)**:
- **Tone**: Pragmatic, tactile, high contrast, weathered field survival hardware.
- **Color Temperature**: Charcoal substrate, dirty ivory readable text, muted industrial amber accents, rust red warnings.
- **Phosphor Green Rule**: Green (`#39D353`) is strictly restricted to small operational badges (e.g. `[LIVE]`, `[HERE]`) and healthy metrics. It must **never** be used as a primary screen wash or overall background glow.
- **Information Density**: High density, zero decorative clutter. Every rendered element maps directly to an authoritative simulation field.

---

## 2. Design Tokens & Color Palette

| Token | Hex Value | Role / Usage |
| :--- | :--- | :--- |
| `color-bg-base` | `#121316` | Dark industrial charcoal base substrate |
| `color-panel-bg` | `#181A1F` | Panel container cards, docked windows |
| `color-border-thin` | `#2E333D` | Thin 1px industrial frame borders |
| `color-border-accent` | `#D9822B` | Focused/selected frame border (muted amber) |
| `color-text-main` | `#D8D3C8` | Primary readable text, labels (dirty ivory) |
| `color-text-amber` | `#D9822B` | Section headers, currency caps, primary actions |
| `color-text-muted` | `#8B949E` | Secondary metadata, distances, captions |
| `color-badge-live` | `#39D353` | Small status indicator for LIVE / current location |
| `color-accent-danger` | `#A8382B` | Shortage warnings, critical deprivation, rust red |
| `color-water-cyan` | `#58A6FF` | Water metrics, caravan routes |

---

## 3. UI Layout Grammar & Panel Hierarchy

The Survivor PDA follows a strict 4-panel split:

```text
┌─────────────────────────────────────────────────────────────┐
│ DAY 12                                      Vagrant  $50    │  [Header Ribbon: 36px]
├───────────────────────────────┬─────────────────────────────┤
│                               │                             │
│       [WORLD MAP PANEL]       │     [SETTLEMENT PANEL]      │  [Main Viewport: 60/40 Split]
│                               │                             │
├───────────────────────────────┼─────────────────────────────┤
│       [PLAYER HUD PANEL]      │    [DEBUG WORLD FEED]       │  [Footer Dock: 130px]
└───────────────────────────────┴─────────────────────────────┘
```

1. **Header Ribbon (36px)**:
   - Left: Day counter (`DAY %d` in `color-text-amber`).
   - Center: System Title (`SURVIVOR PDA` in `color-text-main`).
   - Right: Player identity and currency (`%s | $%d CAPS` in `color-text-amber`).
2. **World Map Panel (Left 55%)**:
   - Tactical vector nodes connected by thin dashed caravan routes.
   - Nodes indicate settlement names. Player presence highlighted with `[*] (HERE)`.
3. **Settlement Panel (Right 45%)**:
   - **LIVE Distinction**: When viewing current settlement, displays LIVE authoritative warehouse stock, security, and prices.
   - **Remote Distinction**: When viewing a remote settlement, displays **ONLY** route availability and overland distance (`Route: Available | Distance: 3 days`). Strictly **no** economic or population leaks (preserving S7 Information Fog boundary).
   - **Action Dock**: Displays `[TRAVEL TO ...]` action button. (Note: `WAIT` button is deferred to S5-B1).
4. **Player HUD Panel (Bottom Left 50%)**:
   - Location, travel status (`SETTLED` or `IN_TRANSIT (X days remaining)`).
   - Backpack load fraction (`Load: %d / %d`).
   - Commodities breakdown: Water, Food, Scrap, Fuel.
   - Strictly **no** HP, stamina, radiation, XP, or levels.
5. **Debug World Feed (Bottom Right 50%)**:
   - Clearly labeled `--- [ DEBUG WORLD FEED ] ---`.
   - Scrollable historical events from the committed event ledger.
   - Toggleable via `debug_world_feed_enabled`.

---

## 4. Interaction & Button States

- **Normal State**: Dark charcoal background (`#181A1F`), thin border (`#2E333D`), dirty ivory text (`#D8D3C8`).
- **Hover/Focused State**: Amber border highlight (`#D9822B`), amber text.
- **Disabled State**: Muted border (`#1F2228`), dimmed gray text (`#555960`).
  - Travel button while in transit: text displays `"CANNOT TRAVEL (CURRENTLY IN TRANSIT)"`.
  - Travel button for current location: hidden / disabled.

---

## 5. UI Anchor & Asset Generation Rules

- **Anchor Continuity**: The initial World Map Anchor is the established visual benchmark. Subsequent screens (Settlement Detailed View, Market Trading Desk, Scavenge Encounter) must reference the existing anchor images and adhere to the exact color tokens above.
- **Aspect Ratio**: Always 16:9 for screen mockups.
- **Styling**: Direct frontal perspective of the PDA screen, matte finish, sharp pixel/vector lines, faint phosphor scanlines, zero fantasy glow.
