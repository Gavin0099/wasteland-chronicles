# Field Combat Lite — authorized slice, 2026-09-22

Owner approved proceeding after the unified UI skill and selected small turn-based
combat with attack, defend and flee. This slice implements one complete playable
example; it does not close C3/C4/C5 or C2-B.

The concrete example is one locked supply shed on Gray Valley's outskirts guarded by
one wild dog. The animal is not human population. The player remains a member of their
settlement; this is a short local confrontation, not a new migration/travel formula.
Rounds do not advance days. No firearm, ammo, armor, AP, XP, random accuracy or injury
statuses. Combat has real persisted HP (12), turn sequence, enemy HP (8), and receipts.

A crowbar is assembled from 3 scrap in a settlement; it weighs 2, is unique to the
player, can be equipped, and opens the one-time cache after the dog is defeated.
Attacks do 2 unarmed or 3 equipped, plus MELEE rank. Defend reduces the next enemy
attack by 3 and prepares +2 damage on the next attack (does not stack). The enemy
attack is telegraphed: 2 normally, 4 on every third turn. Flee always exits but takes
1 damage; it can be fatal. Enemy damage persists after escape. At zero player HP the
existing named-death authority removes exactly one human from the original population.

Rest in a settlement advances one real day through the existing eight phases, then
heals 4 HP if still alive. Existing deprivation can still kill; rest is not resurrection.
The cache offers water 4 / food 2 once, limited by real backpack capacity. Receipts
record actual gains and leftovers and require confirmation. Craft/equip/start/rounds/
cache do not advance a full day. Quantities, costs and enemy intent are visible first.

`PlayerState.field_kit` owns HP and crowbar state. `WorldState.field_state` owns the
site, battle sequence and pending ledger reference. `field_schema_version=1` is
separate from the strict progression codec. Whole missing pre-field schema migrates;
partial/new malformed saves fail closed. New numeric fields accept integral JSON
transport values, while C1 rank spelling remains strict. New actions validate on a
private world copy before publishing; stale battle ID/turn and duplicate receipts fail
without mutation. While fighting or confirming a field receipt, other player actions
are blocked. Save/load preserves every turn and the unique loot claim.

## Implemented presentation

The owner confirmed **俠客遊・前途道標 / Lunatic Dawn: Passage of the Book**.
The first screen uses an elevated arena, separate visible fighters, a right-hand
status/result panel, and stable attack/defend/flee commands below. It keeps the
shared Survivor PDA theme. It does not implement the reference game's whole battle
system, a movement grid, formations, or a party. The official reference is
[ARTDINK's game page](https://www.artdink.co.jp/japanese/title/ldpob/).

Three original generated images supply the environment, drifter and dog. See
`ui/assets/combat/ASSETS.md`. Equipment presence is drawn at runtime. Godot Tweens
provide attack anticipation and lunges, defensive feedback, muted hit responses,
ground-contact shadows, damage text and retreat.
These are cutout animations, not separate hand-drawn sprite poses. Animation follows
an already committed turn; its callbacks never change HP or world state. Repeated
inputs are blocked while animating. Reduced motion skips motion with the same result.

Future pose work can replace the fighter cutouts with idle/attack/hit/retreat sprite
frames, using one fixed camera, scale, light direction and anchor per character.
Keep combat results independent of frame count and playback speed. No video asset,
external animation service, skeleton, extra mechanic or paid pack is required for
this first version.

The initial command authority included CRAFT, EQUIP, UNEQUIP, START, ATTACK,
DEFEND, FLEE, OPEN, REST and CONFIRM. C3 later added TREAT. Equip and unequip
are explicit desired states; duplicate requests cannot silently toggle an item
back. This slice adds FIELD_ACTION to the
existing player-action whitelist and retains rejection of all unknown actions.

## Play this version

1. Start the game and create a character in Gray Valley.
2. Buy 3 scrap in the settlement market (the starting funds cover this).
3. Open **郊外 / 裝備**, assemble and equip the crowbar, then approach the shed.
4. Choose attack, defend or flee. Confirm the result before another action.
5. After victory, use the crowbar to open the shed and confirm the actual supplies.
6. **人物 / 補給** shows current HP, equipment, resources, load and all ten skills.

The shed is a single persistent site and the cache is claimed once. Capacity-limited
leftovers are forfeited, as recorded by the receipt. After leaving Gray Valley the
field entry is unavailable; this version is not a world-wide equipment management
screen. C2-B human playtesting and the full C5 progression system remain open.

## Verification

- All 40 `tests/test_*.gd` suites exit 0; individual logs and results are in
  `artifacts/field-combat/`.
- `test_field_combat.gd`: atomic rejection, explicit equipment state, real damage,
  defense, flee, death/population conservation, result confirmation, capacity,
  unique loot, real-day rest, corrupted saves, old-schema migration, and dual-track
  SHA-256 replay through a mid-battle save/load.
- `test_field_combat_ui.gd`: readonly screen entry, displayed equipment, close
  gating, animation-time duplicate input, saved committed turns, reduced/normal
  motion yielding identical world SHA, visible cache receipt and one-time buttons.
- Real renderer captures at 1280×720 and 1152×648: preparation, battle, damage,
  victory, cache and character sheet. Automated screenshots establish layout and
  wiring; they do not establish whether combat feels fun.
- Existing shutdown RID/CanvasItem/ObjectDB leak diagnostics remain in UI suite
  logs. The suite pass claim is not a claim that shutdown is leak-free.

Earlier world snapshot artifacts remain the explicitly versioned historical
baseline from `a6c3ae7`; this slice does not silently refresh their provenance.
