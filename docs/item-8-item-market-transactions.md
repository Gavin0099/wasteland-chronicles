# ITEM-8 — Item market transactions

ITEM-8 makes the ITEM-7 regional catalogue stateful for the twelve canonical
items. A settlement lazily seeds routine shop stock from its authored supply
level (`low` 1, `medium` 3, `high` 6). Buying removes stock and adds an owned
item; selling requires regional demand and adds stock back. Both operations
move caps and write an `ITEM_TRADE_COMPLETED` ledger event through a
`PlayerIntent`.

The market state is omitted from untouched settlements and old saves. It is
created only when an item transaction commits, so worlds that never use the
item shop retain their existing wire shape and replay behavior. Item inventory
capacity, stack rules and unique-item rules are rechecked before mutation.

Quotes use the canonical metadata `base_value` for buying and a fixed 50%
sell spread. This is an explicit first transaction rule, not a claim that
regional price elasticity, restocking or caravan supply has been implemented.

## Deferred authority

- daily restocking and caravan/quest supply changes;
- dynamic item prices from world pressure or settlement inventory;
- shop UI controls and regional market presentation;
- crafting, repair, durability, combat or medical effects;
- any item outside the twelve canonical runtime definitions.
