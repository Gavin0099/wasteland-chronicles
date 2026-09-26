# PLAY-3A local verification — 2026-09-26

Tested workspace: `D:/wasteland-chronicles`, based on
`ca477bab53ae7de99802215b30b1ac44b97df839`, with uncommitted PLAY-3A and pre-existing
combat changes. This is working-tree evidence, not CI, merge or release evidence.
`source-hashes.json` identifies the scoped files that were verified.

| Check | Observed result |
| --- | --- |
| Every `tests/test_*.gd`, Godot 4.7.2 headless, one process per suite | 87/87 exit 0; no timeout or SCRIPT ERROR/Parse Error in stderr |
| `test_play3a_salvage_integration.gd` | 321 assertions, 0 failures; real market and travel/return flows; save-resumed full SHA replay and invariants |
| `test_play3a_salvage_verb.gd` | 69 assertions, 0 failures; component fixtures supplement the real-flow suite |
| `python governance_tools/npc_authority_validator.py --check` | pass/fail fixtures passed |
| Godot skill `lint_project.py` | 0 errors; one pre-existing dynamic FieldScreen node-reference warning |
| Independent read-only final review | no unresolved P0/P1 findings |
| `capture_play3a_salvage.gd`, OpenGL renderer, real main scene | exit 0; eight images at 1280×720 and 1152×648; main controls and text not clipped; view interactions preserve world SHA |

The integration suite uses a reviewed fixed fixture: Gray Valley's day-zero
rope contract, three-day road to Dry Well, mechanic dismantling returns one
rope and two scrap while spending one additional day. It tests real payment,
stock transfer, return and item consumption, duplicate rejection, expired and
legacy jobs, malformed contract/context/receipt data, and no item injection for
unproductive approaches. The source is scoped to one contract, not a persistent
world location registry.

Run the focused test with:

```powershell
godot --headless --path D:/wasteland-chronicles --script res://tests/test_play3a_salvage_integration.gd
```

Run the screen evidence with:

```powershell
godot --path D:/wasteland-chronicles --rendering-method gl_compatibility --script res://tests/tools/capture_play3a_salvage.gd
```

Rendering limitations: disabled wrench-option text has approximately 2.59:1
contrast and remains a P2 follow-up. Renderer shutdown reports RID/ObjectDB
leaks; the cause is unqualified. `render.log` and `render.err` retain these
diagnostics. Neither screenshots nor automated playthroughs establish human
enjoyment or close PLAY-3/C2-B player-experience acceptance.

No commit, push, PR or merge was performed. The existing branch has eight local
commits beyond its remote tracking branch; PR #26 still targets an older head.
The slice was isolated for review and its fixes were copied back without
changing existing combat code or artwork.
