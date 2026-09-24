# ITEM-13 — Equipment actions in the character PDA

ITEM-13 exposes equip and unequip controls in the existing Survivor PDA
character sheet for owned items with declared equipment slots. The controls
send `EQUIP_ITEM` and `UNEQUIP_ITEM` intents; the sheet never edits equipment
state directly. Successful changes write an `EQUIPMENT_CHANGED` ledger event,
refresh the projection and reopen the sheet with the new binding.

The action is available only while the player is settled. Ownership, slot
compatibility and stale state are rechecked by the simulation authority. The
presentation uses the shared PDA command style and the existing item art.
