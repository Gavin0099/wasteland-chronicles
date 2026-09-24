# ITEM-5 presentation — items and equipment in the PDA sheet

The existing `人物與補給` dialog now projects the player's owned item IDs and
equipment slot bindings. Item names, quantities and gram weights are rendered
as Godot text beside the local transparent art; equipped `main_hand`, `body` and
`back` slots are shown in the same panel. Empty state text is explicit.

The projection is read-only. Opening, closing and refreshing the sheet do not
send an intent or mutate inventory, equipment, time or the world hash. It uses
the shared Survivor PDA tokens and the existing item icon component; it does
not create an equipment action or infer effects from tags.

Verification uses the real character-sheet test: zero and full aggregate cargo,
one owned/equipped item, ten skill rows, save/load SHA stability and global
invariants. The full Godot suite remains the authority for the UI wiring.
