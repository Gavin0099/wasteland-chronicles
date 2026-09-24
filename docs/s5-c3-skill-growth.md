# S5-C3-A — Skill practice from committed actions

This slice lets actions the world already resolves advance the corresponding
skill. `PlayerState.capability` remains the sole writable owner of ranks and
practice. Level XP from commissions remains separate; no XP-to-skill exchange or
free skill point allocation is introduced.

| Skill | Existing committed action that practices it |
| --- | --- |
| BARTER | Buy or sell a commodity or item in a settlement; roadside haggling or column trade |
| MELEE | Land an attack in an existing field/road battle |
| MECHANICS | Assemble the one-time crowbar from three scrap; strip a wreck or use a wrench on it |
| MEDICINE | Use an owned first-aid kit to recover actual missing HP outside combat |
| SCAVENGING | Search a wreck or take the quick-pick approach |
| SPEECH | Persuade guards at a roadblock to reduce the toll, or parley with highway bandits |
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
and ELECTRONICS lacks electronic equipment. STEALTH still requires a starting
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

## Existing craft as a novice Mechanics source

The Gray Valley crowbar assembly already consumes three scrap and creates one
owned tool. That committed `CRAFT` action now grants one MECHANICS practice day
and shows the award in the field screen. It is one-time: a second craft is
refused without spending resources or minting practice. A MECHANICS-0 character
can combine this work with a later day's wrench use at a wreck to reach rank 1.
The world owns the resulting rank; the `FIELD_ACTION` ledger carries only a
validated receipt. Legacy profiles remain inert, and Level XP is unchanged.

`tests/test_s5_c3_craft_practice.gd` exercises the actual craft, regional
wrench purchase and subsequent encounter, refusal atomicity, save/load,
receipt corruption, UI feedback, dual-track world SHA-256 and invariants. Real
1280×720 and 1152×648 renderer captures confirm the feedback is visible with
unclipped actions and a stable command area; opening the screen does not
change the world snapshot. The action
still exists only once per character; it does not establish long-run pacing.

## Field treatment as a Medicine source

The existing first-aid kit now has an actual use while the player is settled,
injured and outside combat. One kit restores up to four missing HP immediately;
it does not advance the day. A successful treatment awards at most one MEDICINE
practice point per world day. Full health, no kit, battle, or pending result
refuses the action before a kit or practice is consumed. The item is bought
through the existing market, remains an ordinary inventory item until use, and
is removed by the item inventory authority. A second treatment on the same day
still heals and spends a kit but grants no extra practice. There is no new
injury/disease authority or automatic HP/skill bonus from owning a kit.

`tests/test_s5_c3_field_treatment.gd` covers real field damage, kit purchase,
healing and consumption, same-day practice cap, next-day rank-up, denied-action
atomicity, save/load and malformed treatment receipts, dual-track world SHA-256
and global invariants. Both required Godot renderer sizes show the actual HP
and practice result without hiding the command area. C3 remains open for the
three unsupported skills, beginner Stealth access, and long-run pacing.
The character sheet now also offers treatment beside current HP whenever an
owned kit is usable. It is available from any settlement; in battle, during
travel or at full health the button shows the blocking reason. Both the field
screen and character sheet send the same `TREAT` intent and display its actual
HP, item and practice result. Opening the sheet remains read-only. The
character-sheet bridge is verified by `tests/test_item14_medkit_sheet_use.gd`
with a New Hope purchase/use path, direct-authority full-world SHA-256 match,
save/load, full-health lock and 1280×720 plus 1152×648 renderer captures.

## Roadside negotiation as a SPEECH source (S5-C3b)

Persuasion now has a grounded, economic role in roadside encounters without
inventing new factions, secret lore or relationship state. At roadblocks and
highway ambushes, the player can choose to negotiate down the demand instead of
paying full price or relying on trade/stealth proficiency:

* **ROADBLOCK** (`PERSUADE` / "跟他們談談"):
  Attempts to talk down the 10-cap toll. Success costs 5 caps; failure costs the
  full 10 caps.
* **BANDIT_AMBUSH** (`PARLEY` / "出言周旋"):
  Attempts to talk down the 15-cap bandit bribe. Success costs 8 caps; failure
  costs the full 15 caps.

Both options are accessible to Rank 0 / novice characters. An attempt requires
holding the full demand in caps so that a refusal can always be paid atomically.
Success is calculated deterministically via `check_persuasion_success` using
a stable string hash of the route, day and encounter, modified by the actor's
`SPEECH` rank (35% base at Rank 0, 60% at Rank 1, 80% at Rank 2, 95% at Rank 3,
100% at Rank 4+) and the road's `min_security`.

Crucially, **failed persuasion does NOT award skill practice**. The player only
advances `SPEECH` when their persuasion actually succeeds in altering the
outcome. This prevents negotiation from becoming a "press button for free XP"
action that dominates plain payment. Practice remains subject to the canonical
one-point-per-day cap.

`tests/test_s5_c3b_speech_training.gd` verifies rank-0 accessibility, atomic
insufficient-fund refusal, deterministic success/failure outcomes, daily practice
caps, level-up progression, rank-scaling success, save/load persistence and
dual-track full-world SHA-256 replay.

