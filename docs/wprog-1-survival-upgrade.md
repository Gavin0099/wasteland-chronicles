# WPROG-1 — First Survival Upgrade

## Core Progression Loop
《Wasteland Chronicles》core progression is not traditional stat inflation, but an expansion of survival risk tolerance:
> 「我為了活下來接任務；完成任務讓我有能力走得更遠，而越遠的地方藏著越好的東西。」
> 接任務 → 冒險生存 → 獲得報酬 → 購買裝備改善下一趟生存能力 → 承擔更嚴苛的廢土風險。

## Slice Specifications

### 1. Earn Requirement (Gate 1)
- Player begins with limited starting caps (default 50) and water/food supplies.
- High-impact survival gear (`travel_backpack` 60 caps, `scrap_machete` 48 caps) cannot be bought carelessly at start without running out of funds or starving.
- Completing the first contract (such as QUEST-2 Gray Valley wrench delivery, earning 75 caps and 25 XP) provides the liquidity necessary to fund the player's first major upgrade.

### 2. Meaningful Branching Choice (Gate 2)
- Post-contract capital (~75 caps) forces an exclusive choice between survival archetypes:
  - **Scavenger Route (`travel_backpack`)**: 60 caps. Expands personal carrying capacity, allowing player to haul all salvage home rather than abandoning supplies on the road.
  - **Fighter Route (`scrap_machete`)**: 48 caps. Increases melee combat damage from 2 to 5 (+3 bonus), defeating road bandits in 2 turns instead of suffering heavy damage and attrition.
- Buying one precludes immediately buying the other with the initial reward.

### 3. Functional Payoffs (Gate 3A & 3B)
- **Backpack Effect**:
  - `PlayerState.get_effective_capacity()` computes `capacity_total + (8 if equipped_item("back") == "travel_backpack" else 0)`.
  - Cargo load calculations, market purchases, road salvage, and field cache looting respect effective capacity.
  - In a wreck search yielding 5 scrap and 2 fuel (7 units), an un-upgraded player with 18 initial load leaves 3 units behind (`left_behind > 0`); an upgraded player with `travel_backpack` takes everything (`left_behind` is empty).
- **Weapon Effect**:
  - Main hand weapon bonuses in `field_adventure.gd`: `scrap_machete` grants +3 damage.
  - In a `BANDIT_AMBUSH` (enemy HP = 8), base unarmed/knife attack deals 2 dmg (takes 4 rounds and significant retaliation damage); `scrap_machete` deals 5 dmg per round, eliminating the threat in round 2 with high surviving HP.

### 4. Invariants & Persistence (Gate 4)
- Equipping and unequipping preserves dual-track deterministic replay and canonical JSON serialization.
- Base capacity (`capacity_total = 20`) is never permanently mutated by equipment, protecting migration invariants.
- Anti-exploit: unequipping a backpack while carrying more than base capacity (`load > capacity_total`) is rejected fail-closed with `INSUFFICIENT_CAPACITY`.

### 5. Cause Before Number (Gate 5)
- UI presentation (`lbl_encounter_body`) explicitly notes the gear contribution when salvage is brought home:
  `舊旅行包提供了額外負重空間。`
- Player understands *why* they could carry the salvage, connecting the contract reward directly to the adventure outcome.

## Verification
- Focused test suite: `tests/test_wprog_1_survival_upgrade.gd` (51 assertions, 0 failures across all 5 Gates).
