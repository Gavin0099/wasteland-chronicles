# Common item art — second batch verification

Twelve original built-in `image_gen` outputs were copied into
`ui/assets/items/candidates/` without editing their pixels. `sources.json` records
the generated filenames and SHA-256 hashes calculated from the source files.
`manifest.json` records matching copied-file hashes, dimensions and alpha bounds.
Exact generation prompts are retained in the same asset directory.

The read-only Pillow check verified all twelve IDs and source records, RGBA mode,
both transparent and opaque pixels, and nonempty subjects at the required size.
The wrapped command passed with exit 0; see `test-receipt.json`:

```powershell
python -m governance_tools.test_evidence_receipt_writer --project-root . --output artifacts/item-art-v0-batch2/test-receipt.json -- python artifacts/item-art-v0-batch2/verify_assets.py
```

The Godot 4.7.2 parser check and actual Compatibility renderer both exited 0.
`capture.log` records all four successful saves; `capture-errors.log` is empty.
`catalogue.png` is 1600×1080; the three category sheets are 1280×720. These are
artwork review screens rendered with the shared PDA theme, not game integration.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --check-only --script artifacts/item-art-v0-batch2/capture.gd
Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility --script artifacts/item-art-v0-batch2/capture.gd
```

Visual inspection of all four sheets found complete subjects, transparent
backgrounds and no clipped labels. Steel, cloth and leather follow the muted worn
material direction. The 32/48 px samples retain the broad silhouettes; fine wear
and the narrow rebar lose detail at 32 px, so item names must remain alongside
icons as required by the UI skill. This is agent inspection, not owner acceptance
or evidence that the items improve play.

An independent agent inspected all four rendered sheets and found no clipping,
label mismatch or visible background/edge defect. It also noted that the rusty
knife and scrap machete need their names at 32 px; the thin rebar is almost a
diagonal line at that size. These assets must not become unlabeled small buttons.

No production component, gameplay catalogue, simulation code or existing test
assertion changed. Gameplay suites were not re-run for this art-only batch. The
candidate garments are inventory illustrations, not character outfit layers;
weapons are not animation sets. No new item effects or C5 closure are claimed.

The receipt identifies the pre-change HEAD; the new artwork and verification
files were present in the working tree for that check.
