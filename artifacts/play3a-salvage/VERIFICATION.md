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

No commit, push, PR or merge was performed during the original verification pass. The existing branch had eight local
commits beyond its remote tracking branch; PR #26 still targets an older head.
The slice was isolated for review and its fixes were copied back without
changing existing combat code or artwork.

## Isolated delivery check

The cumulative candidate (eight inherited gameplay commits plus PLAY-3A,
excluding the separate BVIS working-tree changes) was then tested in
`D:/wasteland-chronicles-worktrees/play3a-salvage`: **83/83 suites exit 0**, no
timeouts or detected script/parse errors. See `delivery-regression-summary.json`.
Governance drift and canonical memory guards reported no completion blockers.
Independent cumulative review found no unresolved P0/P1, including confirmation
that the accepted-contract serialization fix closes the historical replay P1.

Deferred P2 findings in inherited gameplay: spending a growth point clears the
same-day practice marker; terminal road-combat presentation can fall back to the
dog identity after the battle state is cleared. The latter is part of the next
BVIS presentation slice. PR #26's four acknowledged P2 findings remain separate
follow-ups recorded on that PR; this delivery does not claim they were fixed.

## Bundled tooling review

The inherited commits include 214 Godot development-skill paths. Their import
option helper trusted sidecar `deps.dest_files` when deleting cache files. The
fix validates every artifact and companion before saving any sidecar change,
restricting deletion to direct `.godot/imported` files and rejecting traversal,
directories and links. Independent review reports no unresolved P0/P1.

The actual-dispatcher harness `tools/test_import_options_boundary.py` passes
17 cases (see `import-boundary.json`), including external paths, mixed valid and
invalid destinations, ADS paths and Windows junctions. Three file-symlink cases
were skipped because the host lacks that privilege. The author ran the same
harness against the unchanged original helper as a negative control: exit 1,
`external: external-outside.keep changed`; its sentinel was confined to the
disposable test root. This negative-control result is author-reported evidence.

Runtime: Godot 4.7.2 console, SHA-256
`c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643`.
Deferred P2: unchecked cache-deletion return codes can misreport locked files as
invalidated. Complete executable-trust hardening, concurrent hostile filesystem
replacement, and bundled-skill provenance/licensing certification are not claimed.
