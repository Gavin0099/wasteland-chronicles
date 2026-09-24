# ITEM-11 — Regional item price elasticity

ITEM-11 gives the item shop a deterministic quote rule grounded in the
existing regional metadata. Buy quotes start from the authored `base_value`
and add up to a 50% shortage premium as current stock falls below the
supply-derived target. Sell quotes use the demand level (`low` 40%, `medium`
50%, `high` 60% of base value).

The calculation is pure and uses the persisted market stock when present. A
fresh, untouched market projects its target stock without creating state. The
existing aggregate water/food/scrap/fuel price elasticity is unchanged.

This is a bounded quote rule, not a complete economy. Caravan deliveries,
production costs, bargaining skill, taxes, price memory and quest subsidies
remain future authorities.
