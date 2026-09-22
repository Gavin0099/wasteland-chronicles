# ITEM-3 — Inventory minimum

This slice gives the player a small, persisted ownership layer for the twelve
ITEM-2 definitions. It is intentionally separate from the existing aggregate
survival cargo (`water`, `food`, `scrap`, and `fuel`). The old cargo authority,
field crowbar, travel, encounters, trade and survival rules are unchanged.

## Authority

`simulation/item_inventory_state.gd` is the only owner of these holdings. It
stores a detached `item_id -> quantity` map and resolves every definition
through `ItemRegistry`. An unknown ID, malformed quantity, duplicate unique
item, stack overflow or capacity overflow fails without partial mutation.

The minimum inventory capacity is 12,000 grams. This is a fixed ITEM-3
capacity and does not yet grant equipment bonuses. A unique item has quantity
one; a stackable item uses the authored `max_stack` as the single-stack limit.
The first slice therefore supports pickup, drop, quantity, weight and inspect,
but not equipment slots, effects, durability, loot, crafting, prices or combat.

## Persistence

`PlayerState.item_inventory` is copied with the player and is serialized only
when non-empty. Empty new and legacy players keep the previous canonical wire
shape, preserving existing replay hashes. A non-empty value is:

```json
{"items":[{"item_id":"rope","quantity":1}]}
```

Entries are sorted by stable ID. `WorldState.from_dict_checked` validates the
whole value before constructing a world; malformed item data is rejected.

## Deferred authority

This slice does not make an item usable merely because its metadata has an
`actions` list. Equipment, encounter choices, loot generation, market stock,
medical effects, repairs and combat all remain later slices. The next owner
slice is ITEM-4: formal item loot/usage at encounter resolution.
