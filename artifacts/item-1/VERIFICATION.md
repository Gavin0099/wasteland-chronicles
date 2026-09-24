# ITEM-1 verification

Result: twelve metadata definitions only, all six contract gates verified.
No existing production file or test assertion is changed. New runtime files are
the definition source, explicit art-reference table, schema validator and pure
catalogue API. No world/player field, save codec, UI, inventory, item instance,
price, capacity, HP, combat or encounter behavior is added or changed.

- `tests/test_item1_definitions.gd`: PASS, 1,102 assertions / zero failures.
  Independent twelve-row fixtures verify fields and PNG paths; negative fixtures
  exercise wrong types, unknown identifiers, duplicate IDs/tags, deferred fields,
  asset rebinding and atomic refusal. Copy mutation and twelve permutations
  verify source isolation and ordering invariance.
- Real dual-track creation, buy/sell, travel, wreck search, result confirmation,
  pending-result save/load, deprivation and death match full-world SHA at every
  checkpoint. Global invariants and absence of definition data in saves are
  checked throughout. Evidence: `replay-evidence.json`.
- Fresh baseline and post-change runs both pass all 40 existing suites, with no
  SCRIPT ERROR. All 48 SHA output lines and eight emitted world snapshots are
  identical. Original test sources are unchanged. Historical artifacts written
  by those suites are preserved separately and restored byte-for-byte.
  Evidence: `regression-comparison.json`, `before/`, `after/`.
- Eight existing UI-related suites retain shutdown RID/CanvasItem/ObjectDB leak
  diagnostics, identical before/after. This is not a leak-free claim.
- Independent source review found no actionable issue. Its additional 113-check
  probe covers read-only caller containers, malformed Variants, detached outputs,
  real asset paths and canonical ordering: `review/independent_probe.gd`.

Definition SHA-256:
`b921c0b02f5be7a5aad40595d8ac91986614d4fccbfcb664808a8f96fa496f01`

Final deprivation/save-load world SHA-256:
`50f42527f2e4e66685167ffdc7ec0ac96dbb1c9121afd7385dbfd81bc28db7bc`

The authored gram values are initial design values. They are not connected to
the pre-existing capacity units. The medkit cannot heal, the backpack cannot add
capacity and the weapons cannot participate in the existing combat example.
ITEM-2+ and the separate full content-design pass remain outside this commit.
