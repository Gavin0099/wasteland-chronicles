# ITEM-6 — Item-gated encounter approaches

Two existing roadside encounters now expose item-based alternatives through the
same authority path as skill approaches:

- A held `wrench` opens `USE_WRENCH` on a wreck. It performs the existing
  deterministic strip-parts resolution and costs the same day and rations as
  the mechanical approach.
- A held `rope` opens `USE_ROPE` on a rockslide. It clears the obstruction
  without spending scrap or a day.

The options are visible while unavailable, with `持有：扳手` or `持有：繩索`
shown beside the disabled command. The engine checks ownership at commit time,
so a stale UI or forged intent cannot use an absent item. Tools are reusable in
this slice; no durability, medical, repair, combat or stat effect is implied.
The existing encounter receipt and explicit confirmation flow remain unchanged.
