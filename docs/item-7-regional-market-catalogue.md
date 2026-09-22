# ITEM-7 — Regional item market catalogue

ITEM-7 turns the twelve ITEM-2 market metadata profiles into a deterministic,
read-only regional projection. A caller can ask what a settlement routinely
supplies and how strongly it needs an item, using either `new_hope` or a full
`settlement:new_hope` ID.

The projection carries only stable item identity, asset binding, category and
supply/demand levels. It does not create merchant stock, prices, ownership,
buy/sell transactions, or any new settlement resource. Existing aggregate
water/food/scrap/fuel trading is unchanged.

`ItemMarketCatalogue` is deliberately data-driven: adding a future validated
item registry row automatically makes it eligible for this projection without
adding a settlement-specific branch. Unknown items and settlements fail closed;
returned arrays and dictionaries are detached from the registry.

## Deferred authority

The following remain separate future slices:

- stateful shop stock and restocking;
- item buy/sell intents and caps transfer;
- item prices or conversion from `base_value`;
- regional stock changes caused by caravans, quests or world pressure;
- UI rendering of the regional catalogue.

This boundary keeps ITEM-7 useful for later content expansion without turning
the existing item metadata into an untested gameplay economy.
