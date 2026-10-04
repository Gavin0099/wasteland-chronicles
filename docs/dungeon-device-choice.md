# DUN-7 — Abban's preserved device or immediate salvage

Seventh authorized slice, after PR77. L2 action/equipment/persistence risk.
The control room contains a fixed repair bench. New trips carry device_rules1;
valid older trips keep their original behavior until re-entry. No choice can
downgrade the version or repeat the permanent device decision.

At the visible bench, a living idle player can leave the choice undecided,
return with preparation, or explicitly choose:

- PRESERVE:current Abban, owned leather_jacket and3 aggregate scrap. Repair
  and retain the bench, transform exactly one existing leather jacket1400g
  into the existing reinforced leather jacket1900g. Actual owned-item capacity
  must accommodate the extra500g; an already-owned unique result refuses.
  If that jacket was worn, keep it worn via validated slot replacement;
  otherwise do not change the body slot. Existing protection rises1→2 only
  when worn, with existing combat rules and no new stat formula.
- SALVAGE:gain4 aggregate scrap, requiring actual cargo room for all4. The
  bench is dismantled permanently; no later armor transformation. No new item,
  sale currency, XP, practice, extra day or town production is added.

DUNGEON_DEVICE_DECIDED has exactly nine facts:site,control room,choice,current
companion_id,scrap_spent,scrap_gained,item_spent,item_gained,worn. Fixed typed
amount/item proofs, prefix companion, room/activity/version and once-only
decision are checked by live invariants and checked loading. Current owned
inventory/equipment is preflighted on detached copies before atomic commit;
historical proof does not reconstruct every past equip/drop/purchase.

The saved ledger projects choice/day/companion and a durable shared memory
when Abban was actually present. His existing personal request/hire fee stays
independent. Control-room feedback and the existing town companion window show
this memory after retreat, Save/Continue and later visits. No general relation
score, NPC lifecycle, new population or autonomous action.

Use shared PDA theme/buttons and original existing room/pump/armor artwork.
Actual walking opens a modal showing both costs, requirement refusals, armor
weight/protection and irreversibility before commitment. Cancel costs nothing
and preserves local feet. Required evidence:real preserve/salvage/leave-and-
return, worn/stowed replacement, duplicate/full budgets, battle/result/death/
owner/type refusal, typed live/checked fixtures, twin SHA/disk/global invariants,
all Godot suites, two-resolution Vulkan rendering, independent implementation
and bound companion review, exact-head Codex/actual CI, merge/sync/readonlyguard.
DUN-8 town report/faction/repair loop remains excluded; human pacing unmeasured.

## Executed local evidence

Final focused748 assertions/0/no SCRIPT ERROR. Includes both actual choices,
exact three-scrap exchange/four-scrap gain, worn and stowed armor, detached
duplicate/500g/aggregate-capacity atomic refusals, pending fight/result/fatal
refusals, typed positive/negative live and checked history, old-five-key trip
activation, disk roundtrip and twin SHA-256/global invariants. Actual dog
combat compares old defense1 versus reinforced2 against the authored3-damage
first bite:HP10 versus11. The tool/equipment effect is actual engine behavior.

Vulkan final acceptance:34 captures/662 assertions/0 after fixing the mandatory
theme and return-height gap.17 per
resolution1280×720 and1152×648,15 distinct PNG hashes per resolution (two
intentional unchanged-state captures). Native choices/full-item refusal and
town shared memory plus both final contact sheets inspected. Actual return
commands meet40px at both resolutions; choice buttons meet72px.

Debugger332 resources/0 errors/0 parse errors/167 existing warnings and no new
node warnings. Lint0 errors/1 existing warning. Both smoke scenes pass with110
existing warnings and the old seven-node Shell shutdown group. Drift passes.
All132 Godot suites passed with no SCRIPT ERROR on final core; the one-line
shared-theme correction landed before the new dungeon suite began. The full
runner's new dungeon suite also reports748/0. Summary:
%TEMP%/wc-dun7-regression-final/summary.json. Independent final implementation
review zero unresolved P0/P1 and no new P2/P3; all acceptance fixes verified.
Bound companion, exact-head remote review/CI and merge remain pending.

Earlier attempts are qualified:the first353/0/exit0 log had SCRIPT ERROR from
a fixture assigning nonexistent PlayerIntent.actor_id and looking for the
nonexistent「同伴」button; fixed to actual player_id and real「找人」button.
The first actual combat expectation assumed a2-damage bite; corrected against
the authored3-damage dog specification, without changing production combat.
The initial unknown PdaContentDialog fell back to native grey styling and a
34px return command. Required acceptance correction reuses existing
PdaMapDialog and asserts the actual return height. Existing non-wrapping people
dialog reports1×1 under headless Dummy, so the CPU harness materializes its
existing520×470 request only under headless; real Vulkan uses production size.
The actual whole memory label is scrolled into view.

Shutdown remains qualified:headless10 dummy textures/25 text/1 font/49 Canvas/
157 ObjectDB; Vulkan10 textures/10 RID/25 text/1 font/98 Canvas/245 ObjectDB.
No leak-free, complete historical inventory reconstruction, human pacing/fun,
NPC relationship score or general crafting/repair-system claim.

## Try it

Run `godot --path D:\wasteland-chronicles`. Hire Abban in Gray Valley and carry
your ordinary leather jacket, at least4 scrap for the skill/Abban maintenance
gate plus device repair, sufficient water/food for both and500g free item space.
Enter waterworks, reach the control room and walk to the central repair bench.
Inspect both choices, defer freely, or choose preserve/salvage. A worn jacket
stays worn when improved. Open the east shortcut, leave through the entrance
stairs and select「找人」to read the persistent shared experience. Save/Continue
and later visits retain the permanent device outcome.

Focused:`godot --headless --path . --script res://tests/test_dungeon_device_choice.gd`.
Capture:`godot --path . --script res://tools/capture_dungeon_device_choice.gd --fixed-fps 60 --disable-vsync`.
Both use private dungeon test save slots.
