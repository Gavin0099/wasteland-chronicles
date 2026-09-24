# ITEM-12 — Equipment combat bridge

ITEM-12 connects the existing `main_hand` equipment slot to the existing
Field Combat Lite damage authority. A held and equipped canonical melee item
adds a fixed, authored damage bonus:

- 生鏽小刀 +1;
- 獵刀 +2;
- 鋼筋棍 +2;
- 廢鐵砍刀 +3.

Unarmed combat, unequipped items, non-weapons and the separate crafted crowbar
kit remain unchanged. The combat action still goes through `FIELD_ACTION`,
turn validation, the existing HP/death authority and the existing combat
receipt. No durability, armor, accuracy, ammunition or weapon upgrade ladder
is introduced.
