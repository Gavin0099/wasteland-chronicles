# Encounter Resolution Feedback

This is a UX repair, not new gameplay content. Previously the engine settled an option and immediately advanced the remaining trip; the UI refreshed without displaying the result. Players could not distinguish search costs from later travel consumption or see what they received.

## Behavior

Choice → atomic resource and extra-day settlement → persistent result → explicit confirmation → existing travel loop. The next encounter interrupts normally. A zero-day choice still requires confirmation. Nothing passes while the result is being read.

- Show actual gains, actual losses, elapsed days and current water/food.
- The extra day's water/food losses are observed from state; nonexistent rations are not reported as consumed. Later travel costs occur only after confirmation.
- Separate empty searches from goods left behind because capacity was exhausted, including partial collection. Payout and capacity ordering are unchanged.
- Fatal settlement displays the result and ends the journey. Confirmation dismisses that receipt without advancing time.
- Store the pending ledger reference in WorldState. The committed event remains the authority for facts; the UI does not maintain a second reward record.
- `CONTINUE_JOURNEY` carries that reference and validates it before consuming the receipt. Repeated/stale confirmation and other player actions while the receipt is pending are refused without mutations.
- Save/load and world copies preserve the pause. Existing saves without the new field default to no pending result. Malformed references or receipt data fail closed.

## Verification

All 33 `tests/test_*.gd` scripts exited 0 in Godot 4.7.2, with no script errors. Full results and individual logs: `artifacts/encounter-feedback-tests/results.json` and adjacent files.

The focused `tests/test_encounter_resolution_feedback.gd` covers fixed loot, no loot, full/partial capacity, exact time and consumption, zero-day choices, duplicate/stale intent rejection, blocked direct auto-travel, fatal outcomes, legacy/malformed saves, world copying, UI result visibility and explicit confirmation. Saved/loaded and uninterrupted paths compare canonical SHA-256, with global invariants checked.

Existing travel/UI tests now explicitly confirm receipts before asserting arrival; their previous auto-resume expectation is superseded by the owner-requested flow. The arrival assertions remain.

Rendered gains, empty and full-capacity results at 1280×720 using Godot's OpenGL compatibility renderer. All result fields and the continue button fit. Screenshots and a repeatable capture script are in the same artifact directory.

Limitation: UI harness shutdown reports resource/RID leak diagnostics. Passing behavior tests and visual checks do not establish leak-free lifecycle behavior. This repair is delivered separately from the character-progression contracts; push and merge are outside this delivery.
