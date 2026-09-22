# ITEM-10 — Deterministic regional shop restock

ITEM-10 gives an already-created item market a small, deterministic restock
rule derived from regional supply metadata:

- high supply: one unit every day;
- medium supply: one unit every two days;
- low supply: one unit every four days;
- none: never listed or restocked.

Restock is capped at the existing market stock limit and uses the stable item
ID order. It runs during the existing settlement price phase. A settlement
without an item market state remains untouched; merely advancing an old world
does not create a new item economy.

Dynamic prices, caravan deliveries, production costs, quests and item use are
still separate authorities. Restock is intentionally a bounded availability
rule, not a claim that the full regional economy is complete.
