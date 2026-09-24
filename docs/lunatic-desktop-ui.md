# Windowed desktop UI pass

The owner supplied two screenshots from *俠客遊：前途道標* as the interface reference. They show a stable desktop arrangement: a dominant isometric scene, smaller character and map windows, a tool window, and a message window. The previous fixed-column dashboard missed that composition. This pass changes the arrangement, not the underlying quest, travel, trade or combat rules.

The settlement scene now stays open by default. Clicking a destination opens a route detail window; market and commissions open task-specific views in the same main area. A real return button restores the scene. The right column keeps character, tool and map windows visible. Combat uses the same window grammar with stage, status, commands, message log and a simple confrontation indicator. The indicator is visual orientation only; combat still has one player, one opponent and attack/defend/flee commands, with no grid movement.

The three settlement scenes are original artwork and are selected only for the player's actual settlement. Remote settlements retain limited route information; clicking them does not reveal their live markets. The UI still reads projections and commits existing intents. Opening or switching windows does not advance time or change world state.

Renderer evidence is under [`artifacts/lunatic-desktop-ui`](../artifacts/lunatic-desktop-ui/) at 1280×720 and 1152×648. The source reference is the owner's attached screenshots in this conversation. This implementation borrows window hierarchy and rhythm; it does not copy the source game's copyrighted art, text, or rules.
