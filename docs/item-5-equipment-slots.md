# ITEM-5 — Equipment slots

This slice adds the smallest equipment authority on top of ITEM-3 ownership.
The player may equip an owned item into a slot declared by its ITEM-2
definition: `main_hand`, `body` or `back`. A slot swap is atomic; an item cannot
occupy two slots, an item cannot be equipped when it is not owned, and an item
cannot use a slot its definition does not declare. Unequipping removes only the
slot binding; ownership remains in the item inventory.

Equipment is saved as sorted slot/item references and is omitted when empty, so
legacy player snapshots retain their old shape. World loading validates every
reference against the loaded item inventory before constructing the player.

This is presentation and ownership state only. It does not add damage, armor,
capacity bonuses, durability, prices, repair, medical effects, combat changes
or encounter requirements. The existing Field Combat Lite crowbar remains its
separate authorized field-kit example until a later slice deliberately joins
the systems.
