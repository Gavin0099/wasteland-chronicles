# UI resources checked 2026-09-22

These are implementation and usability references, not alternate art directions.
No external assets have been downloaded or added to the game.

| Resource | Use in this project |
| --- | --- |
| [ARTDINK: Lunatic Dawn, Passage of the Book](https://www.artdink.co.jp/japanese/title/ldpob/) | Owner-confirmed battle-screen reference. Use the elevated arena and visible fighters as direction; original game art is not copied. Current mechanics remain our small 1v1 turn-based slice. |
| [Godot: Theme type variations](https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html) | Named shared variants inherit base Control styling; avoid repeated per-node overrides. |
| [Godot: Using Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html) | Container-managed layout, size flags, scrolling and resizing. |
| [Game Accessibility Guidelines: contrast](https://gameaccessibilityguidelines.com/provide-high-contrast-between-text-ui-and-background/) | Keep text readable over panels and artwork; check disabled-but-informative requirements too. |
| [Game Accessibility Guidelines: full list](https://gameaccessibilityguidelines.com/full-list/) | Do not encode essential information using fixed color alone; retain text/shape cues. |
| [W3C: Contrast minimum](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum) | Use 4.5:1 normal-text contrast as our design target; this is not a claim of WCAG certification for a game. |
| [Kenney UI Pack](https://kenney.nl/assets/ui-pack) | Optional future icon/control source, listed as CC0 on this pack's page. Keep one icon family, restyle to PDA tokens, retain local license evidence if assets are later imported. Do not replace the game's style with the pack. |

Use stable Godot documentation and verify APIs against the installed engine. The
current project uses Godot 4.7.2; a moving documentation URL is not a version pin.

For original generated combat assets and motion boundaries, read
`ui/assets/combat/ASSETS.md` and `docs/field-combat-lite.md` from the repository root.
