# ITEM-9 — Regional item market PDA presentation

ITEM-9 adds the regional item market to the existing Survivor PDA marketplace.
The four aggregate survival resources remain the compact default table. A
collapsed `物品商店／區域供需` section expands to twelve rows using the same
market row component and item art, showing stock, buy/sell quotes, owned count,
and a compact supply/demand label.

The UI receives this through `PlayerUIProjection.current_settlement.item_market`.
Rows call `PlayerIntent.create_buy_item` and `create_sell_item`; they never
write `WorldState` directly. The projection uses a detached default market view
for untouched settlements, so merely opening the panel does not create shop
state or alter a save.

This is a presentation slice. It does not add restocking, dynamic pricing,
remote-market information, crafting, equipment effects or new item definitions.
