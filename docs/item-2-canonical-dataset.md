# ITEM-2 — twelve-item canonical dataset

This slice adds a read-only registry projection for the same twelve ITEM-1
stable IDs. It adds descriptive subtype, proposed value, stack semantics,
future equip slots, proposed actions, origins, loot sources and three-settlement
supply/demand metadata. These fields are validated and detached, but they do
not authorize pickup, equipment, repair, healing, lighting, combat or trade.

`game_data/item_registry.gd` is the single source for this richer projection;
`simulation/item_registry.gd` validates it and cross-checks each ID, asset,
category, stack mode and integer weight against `ItemCatalogue`. This keeps the
existing ITEM-1 identity contract intact while giving later Inventory and
Encounter slices one stable lookup boundary.

Condition fields are present as explicit `null` values. Durability remains
outside this slice. `base_value`, action names and market levels are planning
metadata, not live prices or executable verbs. The registry is not persisted
in saves and does not alter current ResourceState inventory.

Acceptance is covered by `tests/test_item2_registry.gd`: exactly 12 records,
unique IDs, explicit art/weight bindings, complete three-market metadata,
detached nested values, deterministic ordering and fail-closed malformed or
unknown records.
