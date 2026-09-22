# Item World V0 illustration library — verification

Result on 2026-09-22: PASS. Coverage is 185/185 names, with 169/169 new
illustrations and no pending images. The completion command exits 0. Godot exits
0 after rendering 22 category pages and the cover; renderer stderr is empty.
Independent read-only verification confirms all 169 new PNG/record/source hashes,
the 16 baseline manifest matches, exact category membership and all 207 gallery
index links. No missing or incorrectly reused original was found.

Scope: complete the existing owner catalogue's inventory illustrations before
ITEM-1. This is an art milestone, separate from gameplay implementation. The
twelve-item baseline at `38f2bad` remains unchanged.

## Evidence

- `build_catalogue.py` reads the fifteen numbered catalogue tables directly from
  `docs/item-world-v0.md`: 187 rows, 185 distinct names. Salt and batteries each
  belong to two categories and share their image.
- The production plan contains 169 separate generation prompts: 36 weapons,
  26 clothing/carrying assets, 68 supplies/materials/trade illustrations and
  39 old-world/special/anomalous/unique objects. Sixteen existing images are reused.
- `record_asset.py` copies original built-in `image_gen` outputs without pixel
  modification and checks the copied bytes against the source SHA-256. Every
  output retains its individual prompt, source output name and metadata record.
- The completion check requires every name to resolve, verifies recorded SHA-256,
  RGBA mode, non-empty alpha bounds, both transparent and opaque pixels, and
  minimum dimensions of 512 px. Reused images must also match their original
  baseline manifests. See `test-receipt.json` for the executed command and result.
- `capture.gd` is a standalone art-review scene. It loads one page at a time,
  uses the shared Survivor PDA theme, and displays each illustration at a main
  preview size plus 32/48 px. The full run covers 187 category rows in 22 pages,
  with one additional representative cover. See `capture.log` and
  `capture-errors.log` for the Godot run.

## Visual review criteria

Original image review checks subject identity, overall material/light direction,
complete silhouettes, transparency and absence of baked UI. Godot review checks
actual dark-panel compositing, correct name/image pairing, legible labels and
layout. The main agent reviews all category pages; independent review also
covers the weapons, survival, medical, tool, materials and trade pages. No
blocking image mismatch, cropped subject, opaque background box or clipped label
was found on the reviewed sheets.

Thin weapons and tools need adjacent names at 32 px. Fine detail loss at that
size is accepted under the owner's instruction, and is not a redraw trigger.
Some generated PNGs have faint alpha near an image edge; alpha bounds alone do
not establish a cropped subject. No offline cleanup or resampling is performed.
Small physical instrument markings are part of the object artwork, not player
statistics or interface labels. Sparse category pages deliberately retain the
same card layout and therefore have more whitespace.

## Claim boundary

The art catalogue is not a runtime item registry. Ammunition, medicines and
mechanical parts have category illustrations; they do not create duplicate item
stacks. Canteen/ration/fuel reuse does not split existing aggregate resources.
Clothing illustrations are not character outfit layers, and weapon illustrations
are not held-pose or animation sheets.

No simulation, production UI component, gameplay test, balance, loot, inventory,
shop or equipment behavior changes are included. The gameplay regression suites
are not rerun for this art-only delivery. Art verification does not close C2-B,
full C5, ITEM-1–6, or any other gameplay slice; it also does not claim owner
playtest acceptance.

The milestone is recorded through the canonical memory writer. The memory guard
exits 0 with no blocking item; its existing topology/provenance advisory warnings
remain visible in `memory-guard.log`. This delivery makes no governance update
or clean-adoption claim.

## Reproduce

```powershell
python artifacts/item-art-library/build_catalogue.py --require-complete
Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility --script artifacts/item-art-library/capture.gd
```

The capture requires a real renderer rather than headless mode. During this
delivery it runs as a hidden Windows process. Godot version:
`4.7.2.stable.official.ed1daf0bf`.
