# UI/UX review — 2026-09-23

Scope: the current playable loop, from character creation through settlement work, travel encounters, local combat, character/supplies, and death. This is a presentation pass. It does not add quests, enemies, equipment effects, or world authority.

| Surface | Review finding | Change in this pass |
| --- | --- | --- |
| Character creation | Name, background, traits, skill preview, and start action have a clear order. A failed creation exposed an engine error code. | Keep the form; show a player-facing validation message. |
| Settlement hub | The map and warehouse telemetry dominated the first screen; available work, preparation, and travel were scattered. | Put current place and its actions first, shrink the map, make detailed settlement data expandable, keep the market in the same scroll. |
| Commissions | The journal was reachable but its entry competed with dense town data. | Keep its persistent button and status counts directly under local actions; opening it still gives the journal its own pane. |
| Market | Two-line rows fit the narrow view, but commodity labels and transaction buttons mixed English and Chinese. | Use Chinese transaction labels and keep the amount beside each button. |
| Travel and encounters | A reserved, empty encounter-art frame implied missing content and spent vertical room. | Hide the placeholder; keep encounter choices and receipts visible until explicit confirmation. |
| Combat | The arena, active turn, opponent state, and attack/defend/escape controls already establish a readable combat loop. | Retain the existing focused combat screen. |
| Character and supplies | The read-only sheet distinguishes identity, equipment, supplies, and skill ranks. The global header duplicated the day in two languages, while the bottom resource strip was mislabeled as equipment. | Shorten the header and label the strip as carried supplies. |
| World history | An empty/debug radio occupied half the bottom area and looked like player knowledge. | Hide the debug history by default; it remains available to test/debug mode and is labeled as development information. |
| Death and refusals | Death has a dedicated banner and disables actions; unknown rejection codes could still reach the player. | Keep the death state and replace the generic raw-code fallback with a player-facing message. |

The [1280×720 and 1152×648 renderer captures](../artifacts/ui-workflow-review/) cover the local hub, remote destination, market shortcut, and completed journal. Character creation, character sheet, encounter, battle, death, keyboard navigation, and long-name edge cases still need fresh manual playtest after this UI build; existing automation is not evidence of how those screens feel to a player.

Content boundaries remain visible: the current commissions are finite, and the present combat slice is limited to its implemented encounter. Repeating commissions or adding enemy types is gameplay work, not part of this UI pass.
