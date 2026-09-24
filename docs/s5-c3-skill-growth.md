# S5-C3-A — Skill practice from committed actions

This slice lets actions the world already resolves advance the corresponding
skill. `PlayerState.capability` remains the sole writable owner of ranks and
practice. Level XP from commissions remains separate; no XP-to-skill exchange or
free skill point allocation is introduced.

| Skill | Existing committed action that practices it |
| --- | --- |
| BARTER | Buy or sell a commodity or item in a settlement; roadside haggling or column trade |
| MELEE | Land an attack in an existing field/road battle |
| MECHANICS | Strip a wreck or use a wrench on it |
| SCAVENGING | Search a wreck or take the quick-pick approach |
| STEALTH | Slip past a roadblock |
| SURVIVAL | Detour/scout/use a rope at a rockslide, or hydrate a traveller |

Only a successful commit with its actual world cost qualifies. An option that
is unavailable, unaffordable or stale cannot award practice. An unranked
legacy profile has no new practice effect. Each skill can receive one practice
point per world day; buying in several small transactions or repeatedly
attacking in a turn-based battle cannot farm it. Current rank thresholds are
2/3/4/5/6 practice days for ranks 0→1 through 4→5. Rank 5 is the cap. This
is a deterministic first pacing rule, subject to review with longer play.

The profile writes a versioned, sparse `skill_practice` record only after the
first award. Old profiles retain their previous wire shape. Receipts and turn
events state each awarded practice or rank-up. The character view projects the
same profile and shows partial progress as `練習 x/y`; encounter results, market
transactions and combat turn logs show the immediate outcome. A future-dated
practice record is invalid at the world boundary.

This does not declare all ten skills trainable. FIREARMS lacks firearm attacks,
ELECTRONICS lacks electronic equipment, MEDICINE lacks a medical action, and
SPEECH lacks a speech action. STEALTH and MECHANICS currently require a starting
rank or an item-supported approach. Those gaps need an actual playable action,
not an invisible timer or invented background bonus. C3 stays open until the
coverage and pacing are evaluated as a complete progression system.

Validation: `tests/test_s5_c3_skill_growth.gd` exercises committed encounters,
market transactions and combat turns, anti-repeat, authorization refusal,
optional save fields, malformed records, rank cap, full-world two-track replay
SHA-256, and global invariants. Full-suite status is recorded in the delivery
report, not presumed from this focused suite.

## Feedback and saved-receipt integrity

The follow-up C3 feedback slice keeps a market practice notice tied to the
settlement where its trade occurred. Opening the market again or leaving that
settlement clears the old notice. A finishing combat blow copies its actual
practice award into the persistent `FIELD_RESULT` receipt, where the result
screen shows it above the scrollable outcome text. Saved `FIELD_TURN` and
`FIELD_RESULT` awards use the same strict receipt validator as encounters;
invalid awards, practice on a defensive turn, and practice on a non-victory
result fail load before the player-facing view renders.

The next consistency slice also clears the market notice when the details
window closes, the quest journal takes over, or a different settlement is
selected. A saved victory result
may carry practice only when the immediately preceding finishing attack has
the identical award, actor and day. This prevents a result panel from showing
a structurally valid but unearned rank-up. The cross-record check applies to
the displayed result award; it does not rebuild the entire character profile
from historical combat events.

`tests/test_s5_c3_feedback_integrity.gd` covers real trade, travel, combat,
save/load rejection and acceptance, full-world dual-track SHA-256 replay and
global invariants. Its renderer capture at 1152×648 verifies that a finishing
blow's practice notice is visible in the result screen. This resolves feedback
and data-integrity gaps; it does not close the remaining C3 source-coverage or
pacing decisions.
