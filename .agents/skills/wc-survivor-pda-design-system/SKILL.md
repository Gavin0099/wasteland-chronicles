---
name: wc-survivor-pda-design-system
description: >-
  Authoritative visual design language, color tokens, typography, component specs,
  and interaction states for Wasteland Chronicles Survivor PDA interface.
---

# Wasteland Chronicles — Survivor PDA Design System

## Purpose
This skill defines the authoritative visual design language for Wasteland Chronicles.
It controls:
- visual hierarchy
- color tokens
- typography hierarchy
- spacing and border rules
- component appearance
- component interaction states
- map-node grammar
- status and warning semantics
- artwork integration rules
- consistency requirements for generated visual anchors

It does not define gameplay rules, player knowledge, simulation state, or Godot implementation details.
Those belong to:
- `wc-ui-ux-shell`
- `wc-godot-ui-implementation`

---

## 1. Design Intent
Wasteland Chronicles should feel like:
> A rugged survivor information terminal assembled from durable industrial hardware, designed to help someone understand a hostile living world.

The UI must communicate:
- scarcity
- distance
- danger
- changing world conditions
- imperfect survival infrastructure

while remaining:
- readable
- systematic
- restrained
- functional
- high-information-density

The interface must feel like a game interface, not an analytics dashboard.

---

## 2. Visual Identity
### Core Direction: Survivor PDA
Visual characteristics:
- dark industrial interface
- utilitarian military-inspired information layout
- thin technical borders
- restrained wear
- high information density
- strong typographic hierarchy
- functional iconography
- physical-world feeling without excessive skeuomorphism

The interface should feel repaired, reused and practical rather than futuristic.

---

## 3. Explicit Avoid List
Do **NOT** use:
- broad-area green CRT styling
- Fallout / Pip-Boy imitation
- cyberpunk neon palettes
- glowing holographic interfaces
- excessive scanlines
- heavy rust textures behind readable text
- blood splatter overlays
- exaggerated sci-fi glassmorphism
- rounded consumer-app cards everywhere
- decorative fantasy ornament
- excessive gradients
- generic SaaS dashboard aesthetics

Green may only appear as a small operational / healthy-state accent.

---

## 4. Color Tokens

### Foundation
- `surface/base`: `#121316` (Main application background)
- `surface/panel`: `#1B1D22` (Primary information panels)
- `surface/elevated`: `#22252B` (Selected / elevated control surfaces)
- `border/default`: `#2A2D35` (Thin structural borders)
- `border/strong`: `#454A55` (Active or strongly separated boundaries)

### Text
- `text/primary`: `#D8D3C8` (Dirty ivory. Default readable foreground)
- `text/secondary`: `#96938B` (Supporting metadata)
- `text/dim`: `#686A70` (De-emphasized information)

### Semantic
- `accent/amber`: `#D9822B` (Primary interactive highlight. Selection, active control, meaningful change)
- `status/critical`: `#A8382B` (Severe danger, supply collapse, fatal state)
- `status/warning`: `#D9822B` (Warning / scarcity / rising risk)
- `status/live`: `#39D353` (LIVE / operational confirmation only. Must remain visually minor)
- `status/info`: dirty ivory or muted steel tone. Never introduce neon blue unless later approved.

---

## 5. Color Usage Rules
- Amber is the primary accent.
- Red is reserved for critical states.
- Green is reserved for small positive-state indicators such as `[LIVE]`, `connected`, `operational`, `currently here`.
- Never use large green panels, green body text, or green CRT backgrounds.
- Semantic meaning must not rely on color alone. Every warning must include at least one of: icon, label, arrow, explicit wording (e.g. `⚠ SUPPLY CRITICAL`, not merely red text).

---

## 6. Typography

### General Style
Typography should feel:
- technical
- narrow
- utilitarian
- readable at small sizes

Preferred character: industrial grotesk, technical sans-serif, restrained monospace for numeric / machine information.
Do not turn the entire UI into monospace terminal text.

### Hierarchy
- **Display / Location**: Used for settlement names, major encounter titles. Strong weight.
- **Section Heading**: Used for `MARKET`, `LOCAL STATUS`, `TRAVEL`, `WORLD MAP`. Uppercase permitted.
- **Body**: Used for descriptive information, event text, contextual explanations.
- **Data / Numeric**: Used for prices, quantities, day count, distance, backpack capacity. May use monospace styling.
- **Metadata**: Used for timestamps, `LIVE` / `REMOTE`, source freshness, secondary status. Smallest readable tier.

---

## 7. Spacing System
- Base spacing grid: `4px`
- Primary increments: `4`, `8`, `12`, `16`, `24`, `32`
- Avoid arbitrary spacing such as 7, 13, 19.
- Panels should feel compact but never cramped. High information density does not mean zero breathing room.

---

## 8. Border & Shape Grammar
- Default component corners: square or minimally rounded (0–3 px visual radius).
- Avoid soft mobile-app rounded cards.
- Default border: thin, technical, approximately 1 px visual weight.
- Important or selected sections may use: amber edge, double-line indicator, bracket marker, stronger border.
- Do not use large drop shadows as the primary depth mechanism.

---

## 9. Component State Grammar
Interactive components should support these states where applicable:
- `DEFAULT`
- `HOVER`
- `PRESSED`
- `SELECTED`
- `DISABLED`
- `WARNING`
- `CRITICAL`

State differences should primarily use: border, foreground contrast, amber highlight, subtle surface change. Avoid large glow effects.

---

## 10. Button Grammar
Buttons should feel like physical PDA commands rather than web CTA cards (e.g. `[ TRAVEL TO NEW HOPE ]`).
- Rectangular, thin border, uppercase or technical label, clear disabled state, subtle hover increase, stronger pressed inset.
- Primary actions use amber emphasis.
- Dangerous actions use rust red only when the action itself is dangerous or destructive.

---

## 11. Status Badge Grammar
Examples: `[LIVE]`, `[REMOTE]`, `[IN TRANSIT]`, `[LOW]`, `[CRITICAL]`.
- Badges must be compact.
- `LIVE`: small green accent.
- `REMOTE`: muted neutral tone.
- `WARNING`: amber.
- `CRITICAL`: rust red.
- Do not render status badges as oversized pills.

---

## 12. Resource Grammar
Core resources: Water, Food, Scrap, Fuel.
- Each resource requires one stable icon or glyph (e.g. `💧 WATER 4`).
- Resource identity must not change between HUD, market, settlement panel, event screens.
- Emoji are acceptable for early prototype only; final UI migrates toward a coherent icon set.

---

## 13. Market Row Grammar
A Market Row contains:
- resource identity
- local stock
- buy quote
- sell quote
- player quantity
- `BUY` action
- `SELL` action
- optional trend indicator

Example:
```text
WATER   Stock 84   Buy $9 ↑   Sell $8   You 3   [BUY 1] [SELL 1]
```
Trend arrows must describe actual known price movement, never decorative movement.
Remote settlements must not expose market information unless Player Knowledge explicitly allows it.

---

## 14. Settlement Panel Grammar
- Current settlement may display LIVE information: population, resources, prices, pressure, security, relevant local status.
- Remote settlement display must remain constrained by Player Knowledge.
- Before S7 Information Fog is implemented, remote settlement UI should default to: settlement name, route availability, known travel distance.
- Do not expose remote inventory, prices, pressure, security, exact population unless explicitly authorized.

---

## 15. World Map Grammar
World Map must feel geographic / infrastructural rather than like a list of buttons.
- **Settlement Node States**: current, reachable, selected, remote, critical, unavailable.
- **Route States**: normal, selected, dangerous, blocked, unknown.
- **Player Marker**: Must clearly distinguish settled at node vs travelling along route (e.g. `GRAY VALLEY ●────◇ YOU────● NEW HOPE`). The player marker must not be confused with settlement nodes.

---

## 16. Information Density Rule
Every panel must answer one primary question:
- World Map: Where can I go?
- Settlement Panel: What is happening here?
- Market: What can I buy or sell here?
- Player HUD: What am I carrying and where am I?
- Event Feed: What just happened?

Do not mix unrelated information into one panel merely because space is available.

---

## 17. Cause-Before-Number Rule
Whenever possible, meaningful state changes should include readable context.
- Weak: `Water $31`
- Better: `Water $31 ↑`
- Best when knowledge supports it: `Water $31 ↑  ⚠ SUPPLY CRITICAL`
- Do not reveal causal truth the player has not learned.

---

## 18. LIVE vs REMOTE Visual Grammar
- **LIVE information**: primary text contrast, optional small green `[LIVE]`, complete authorized local information.
- **REMOTE information**: reduced contrast, `[REMOTE]`, limited data, no implied live precision.
- Never visually present stale/remote information as live fact.

---

## 19. Event Feed Rule
Before S7: Event Feed is explicitly `DEBUG WORLD FEED`. It represents committed world history for development feedback. It is NOT player knowledge, rumor, intelligence, or dialogue. Future S7 will replace or filter this through Player Knowledge.

---

## 20. Artwork Integration
Artwork must support the UI, not replace information hierarchy.
- Preferred artwork surfaces: settlement banner, encounter scene, important NPC portrait, key world location.
- Avoid using generated artwork as: button backgrounds, every inventory item, every numeric panel, decorative filler.
- Suggested visual ratio:
  - 50% structured UI / information
  - 25% map + icons
  - 15% environmental artwork
  - 10% NPC portraits

---

## 21. Image Generation Consistency Rule
All generated Wasteland Chronicles UI or presentation artwork must use this skill as the visual authority.
After the first approved visual anchor exists:
- use the approved anchor as visual reference
- preserve palette
- preserve panel grammar
- preserve border treatment
- preserve typography character
- preserve information density
- do not regenerate future screens from a fresh standalone style prompt.

---

## 22. Anchor Strategy
Required anchor sequence: World Map $\rightarrow$ Settlement $\rightarrow$ Encounter $\rightarrow$ NPC portrait treatment.

---

## 23. Accessibility / Readability
- Strong foreground/background contrast.
- Warning meaning never color-only.
- Readable small text.
- Disabled state visually obvious.
- Hover not required to understand controls.
- Critical information visible without animation.
- Avoid excessive flickering, scanlines or chromatic aberration.

---

## 24. Source-of-Truth Hierarchy
Visual authority order:
1. Approved Design Tokens
2. Approved Components
3. Approved Anchor Screens
4. Current mockups
5. Generated artwork

Generated images must never override established design-system rules.

---

## 25. Definition of Done for a UI Screen
A UI screen is considered visually conformant only if:
- it uses existing tokens
- it uses existing components when available
- component states are consistent
- information hierarchy is obvious
- LIVE / REMOTE boundary is preserved
- warning semantics are consistent
- no prohibited visual style is introduced
- image assets match approved visual anchors
- it remains readable without decorative artwork

The design system should survive removal of every illustration and still remain usable.

---

# UI Component List v1

### Foundation
- **AppFrame**: Outermost layout (`VBoxContainer`: TopStatusBar, MainContent, BottomPlayerHUD).
- **Panel**: Common base for information zones (`Default`, `Elevated`, `Selected`, `Warning`, `Critical`).
- **SectionHeader**: `WORLD MAP`, `MARKET`, `LOCAL STATUS`, `DEBUG WORLD FEED` (Title + optional badge + divider).

### Global Status
- **TopStatusBar**: `DAY 18 | VAGRANT | $184 | PACK 12/20`.
- **StatusBadge**: `LIVE`, `REMOTE`, `IN TRANSIT`, `LOW`, `WARNING`, `CRITICAL`, `DISABLED`.

### World Map
- **WorldMapPanel**: Custom `Control` with `_draw()` rendering routes, settlement nodes, and player marker.
- **SettlementNode**: `Current`, `Remote`, `Selected`, `Reachable`, `Critical`.
- **RouteLine**: `Normal`, `Selected`, `Dangerous`, `Blocked`.
- **PlayerMapMarker**: `Settled`, `In Transit`.

### Player
- **PlayerHUD**: Location, travel status, money, backpack load, resource strip.
- **ResourceChip**: `💧 Water`, `🍖 Food`, `⚙ Scrap`, `⛽ Fuel`.
- **CapacityMeter**: Backpack load representation (`BACKPACK 12 / 20`).

### Settlement
- **SettlementPanel**: Modes `LIVE` vs `REMOTE`.
- **SettlementMetricRow**: `WATER 18 ⚠`, `SECURITY 31 ↓`.
- **WarningBanner**: `⚠ SUPPLY CRITICAL`.

### Market
- **MarketPanel**: Exists only in Current Settlement / LIVE.
- **MarketRow**: Resource, stock, buy quote, sell quote, player qty, BUY button, SELL button.
- **PriceTrend**: `↑`, `→`, `↓`.

### Actions
- **CommandButton**: `TRAVEL`, `WAIT`, `BUY`, `SELL`.
- **TravelAction**: `[TRAVEL TO NEW HOPE — 3 DAYS]`.
- **WaitAction**: `[WAIT 1 DAY]` / `[CONTINUE — 1 DAY]`.

### Event / Feedback
- **DebugEventFeed**: `--- [ DEBUG WORLD FEED ] ---`.
- **EventFeedRow**: Day, summary.

### Artwork Slots
- **SettlementBanner**: Wide environmental artwork (Gray Valley, New Hope, Dry Well).
- **EncounterArtwork**: Highway wreck, abandoned station.
- **NpcPortrait**: Mara, future companions.

---

## v1 Component Stop Rule
Do **NOT** add a new component unless:
1. An existing component cannot express the required state;
2. The UI requirement already exists in gameplay;
3. Reusing the existing component would create semantic ambiguity.

Do not create speculative components for: combat, companions, quests, perks, skills, HP, radiation, equipment until those systems exist.
