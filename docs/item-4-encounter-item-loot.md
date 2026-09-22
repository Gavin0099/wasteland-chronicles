# ITEM-4 — Formal encounter item loot

ITEM-4 adds a second, explicit reward channel to the existing roadside
encounter receipt. Wreck `SEARCH`, `STRIP_PARTS` and `QUICK_PICK` can now yield a
stable item ID in addition to the pre-existing aggregate resources. The item
yield is derived from the encounter's frozen day, route and travel index; there
is no random number generator or mutable loot table.

## Commit boundary

`SimulationEngine.commit_encounter_choice` resolves the item offer at the same
atomic boundary as the resource offer. `PlayerState.pickup_item` owns the
inventory mutation. A duplicate unique item, stack limit or item capacity
failure leaves the player unchanged and records the item under
`items_left_behind`. Successful units are recorded under `items_gained`.

The existing `gained`, `spent` and `left_behind` fields remain the aggregate
resource channel, so old receipts and consumers continue to work. New item
fields are optional for backward compatibility; old receipts without them are
valid. Unknown IDs, non-integral quantities and unique-item quantities above
one are rejected when a receipt is loaded.

## Result feedback

The encounter result panel renders item names from `ItemRegistry`, alongside the
resource gains and losses. It does not infer gameplay effects from item tags or
metadata. The item is owned, inspectable and persisted, but it is not equipped,
usable as a medical effect, sellable, craftable or a combat modifier yet.

The next slice can define equipment slots and explicit equip authority without
changing this receipt format.
