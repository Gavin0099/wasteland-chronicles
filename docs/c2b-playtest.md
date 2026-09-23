# C2-B controlled player check

This is a disposable playtest entry point for the **current UI build**. It opens
the real encounter screen on the Gray Valley → New Hope road. Every run uses the
same world seed, day, road, supplies and encounter context; the background and
traits in the command are the only intended differences. Closing the window
discards the run. This tool does not write or load a save.

From PowerShell in `D:\wasteland-chronicles`, compare the four backgrounds at
the overturned truck. Close each window before running the next command:

```powershell
godot --path . --script tools/c2b_playtest.gd -- --background=CARAVAN_GUARD --encounter=WRECK
godot --path . --script tools/c2b_playtest.gd -- --background=MECHANIC --encounter=WRECK
godot --path . --script tools/c2b_playtest.gd -- --background=FARMER --encounter=WRECK
godot --path . --script tools/c2b_playtest.gd -- --background=SCAVENGER --encounter=WRECK
```

The truck alone does not show the farmer's strongest path. Compare a second
encounter, then check a trait with the same background:

```powershell
godot --path . --script tools/c2b_playtest.gd -- --background=FARMER --encounter=ROCKSLIDE
godot --path . --script tools/c2b_playtest.gd -- --background=SCAVENGER --encounter=ROADBLOCK
godot --path . --script tools/c2b_playtest.gd -- --background=MECHANIC --encounter=ROCKSLIDE
godot --path . --script tools/c2b_playtest.gd -- --background=MECHANIC --encounter=ROCKSLIDE --traits=RECKLESS
godot --path . --script tools/c2b_playtest.gd -- --background=MECHANIC --encounter=DEHYDRATED_TRAVELLER
godot --path . --script tools/c2b_playtest.gd -- --background=MECHANIC --encounter=DEHYDRATED_TRAVELLER --traits=GREEDY
```

Record what you actually noticed while choosing and after the result. In
particular: did a different background give you a different *way* to act; did a
locked choice make you feel the character lacked a skill; and did that make you
want to develop the skill? Also note if a gray choice felt like clutter. These
are experience questions. The 20-case automated projection check below cannot
answer them.

```powershell
godot --headless --path . --script tools/c2b_playtest.gd -- --verify
```

`--verify` checks all four backgrounds against all five existing encounter
templates, both trait A/B pairs, and confirms projecting an encounter does not
change the world SHA. The `--capture` option is for real-renderer QA only; run it
without `--headless`, optionally with `--size=1152x648`. The captured images
live in `artifacts/c2b-playtest/` and are visual evidence, not a player verdict.

This check does not close C2-B until a player reports the three observations.
C3 Skill Growth remains separate. The controlled entry point does not replace a
normal full journey for pacing or encounter-frequency feedback.
