# Shared faction consequences

Owner request: 多一點城鎮，並且要有陣營; continued delivery after explicitly approving the supply road. TOWN-1 delivered PR #69 (5331c21). FACTION-1 makes public affiliations affect the player's livelihood: helping New Hope earns better future work in Spring Ford; keeping Iron Pass's entrusted cargo makes Gray Valley's services and purchases costly. The player can pursue an alliance or accept the cost of betraying one. This is regional memory of committed player actions, not a world good/evil score.

Contract (L1 behavior change; simulation regression gates apply):

| Shared standing | Member-town consequence |
| --- | --- |
| Sum <= -10, 抵制 | New commissions, teaching and hiring refused; purchases +15% |
| Sum >= 10, 盟友 | Future commission currency +10% |
| Sum >= 4, 合作 | Future commission currency +5% |
| Otherwise, 觀望 | No shared adjustment |

Standing is the sum of existing receipt-derived LocalTrust scores for actual present member towns. No new save fields, parallel counters or receipts. Local town tiers stay unchanged. Job pay and purchase markup take the larger of local and shared modifiers, never multiply them; existing accepted contracts keep their agreed pay, turn-in remains possible, XP is unchanged. Existing betrayal/abandonment decay still applies after20 days. A one-town faction therefore retains its earlier local economy behavior. Unknown factions/towns or absent members contribute nothing. Travel, purchases and selling remain available during shared resistance; no wars, membership action, new NPC lifecycle, autonomous action or world-state formula changes.

The PDA toolbar opens a read-only 陣營 window showing real public members, the player's existing history, standing, shared thresholds and effective member-town benefits/restrictions. UI consumes projections only; opening/closing/scrolling spends no time or changes world state. No remote stocks, price quotes or economic pressures are exposed.

Verification:571 focused assertions pass, with actual accepted/fulfilled/betrayed/expired contracts, positive4/10 thresholds, atomically refused peer work/teaching/hiring, permitted marked-up resource and item purchases, accepted-pay preservation even after shared improvement/resistance, exact20-day recovery, other-faction isolation, old three-town behavior and checked reload. Each actual action verifies twin SHA-256/global invariants/persistence. Owned parts/resources and funded services are explicitly labelled test fixtures; no test for obtaining those materials or funds is implied. The first focused run had four failures because one singleton part was both prepared for the held contract and needed for a peer contract. The fixture now prepares the part immediately before its actual delivery, rather than duplicating it or fabricating reputation receipts;571 then passes. Authority was not changed to accommodate the fixture.

All124 suites pass after the final presentation-only fit correction, one final wrapper exit0/no SCRIPT ERROR. Final20 actual Vulkan renderer saves at1280x720/1152x648 have676 assertions/zero failures: public members/rules, cooperative peer5% versus issuer10%, actual53caps/5XP contract (including scrolled small screen), ally10% versus local20%, resistance peer15% versus issuer25%, actual locked work/marked market, and day20 reopening. Toolbar wiring, keyboard close focus, actual Escape-close and read-only opening/scrolling/closing are exercised. Root inspected both-resolution states. A new full status line initially crowded the compact growth-bar background; the final projection supplies a compact faction hint alongside the existing trust line, keeping the original line count. The adjacent older desktop growth-bar layout still clips its bottom capacity line at1152; changed dialog and commands fit, no general desktop-layout repair claimed (P2 deferred). Import0/no SCRIPT ERROR, lint0errors/one existing dynamic-node warning, driftPASS. Focused shutdown reports10 texture RIDs/16 shaped-text RIDs/1font/7CanvasItems/63ObjectDB; renderer reports13/16/1/126/297 respectively. These exit warnings are not claimed repaired.

Independent implementation and presentation-only convergence reviews report zero unresolved P0/P1. Final evidence convergence, separately bound canonical companion and exact-head GitHub review/actual CI remain required before merge.

Human acceptance remains open: does the player want to work for a regional ally, avoid losing its access, or deliberately take the betrayal payoff? More affiliation cards alone do not prove that choice is interesting.
