# ITEM-1 — twelve item definitions

Scope: the original twelve baseline items only. The 185-name art library remains
an asset catalogue. No art scan or catalogue import registers gameplay items.
This slice defines identity and descriptive metadata; it adds no item ownership,
instances, equip/use commands, loot, shops, recipes or gameplay effects.

## Authority and schema

`game_data/item_definitions.gd` is the single authored source of the twelve
definitions. It returns fresh records, never shared writable state.
`simulation/item_definition.gd` validates the exact seven fields below.
`simulation/item_catalogue.gd` exposes lookup, sorted enumeration and pure
catalogue validation/canonicalization. Returned dictionaries are detached views;
mutating one cannot change the source or another caller's view. There is no
register, install, load-from-save or mutation API.

| Field | Contract |
| --- | --- |
| `item_id` | Nonempty lowercase ASCII snake identifier, starting with a letter; stable and independent of Chinese display text and filenames |
| `display_name_zh` | Nonempty String without leading/trailing whitespace; presentation text, never lookup identity |
| `category` | String enum: `WEAPON`, `APPAREL`, `CONTAINER`, `TOOL`, `CONSUMABLE` |
| `stack_mode` | `UNIQUE` or `STACKABLE`; descriptive semantics only |
| `base_weight` | Positive integer grams per physical unit, excluding any future container contents; no float/string/bool coercion |
| `asset_id` | Stable key resolved by the separate explicit `game_data/item_art_references.gd` mapping |
| `tags` | Array of unique lowercase ASCII snake identifiers; order has no meaning; no implied action permission |

`UNIQUE` means units are individually distinguishable for future ownership; it
does not mean globally unique, rare, or a legendary item. `STACKABLE` means
identical units of that definition may be counted together once ownership exists.
Neither value currently creates an instance, stack, limit or merge operation.

The weights below are initial design values, not measured real-world product
specifications. Existing resource carrying units and `capacity_total` keep their
current meaning; there is no conversion to grams or recalculation of load here.

## Fixed first catalogue

| item_id | display_name_zh | category | stack_mode | base_weight (g) | asset_id | tags |
| --- | --- | --- | --- | ---: | --- | --- |
| rusted_knife | 生鏽小刀 | WEAPON | UNIQUE | 250 | item_rusted_knife | blade, tool |
| hunting_knife | 獵刀 | WEAPON | UNIQUE | 400 | item_hunting_knife | blade, hunting, tool |
| rebar_club | 鋼筋棍 | WEAPON | UNIQUE | 1800 | item_rebar_club | blunt, metal |
| scrap_machete | 廢鐵砍刀 | WEAPON | UNIQUE | 1200 | item_scrap_machete | blade, salvaged |
| work_clothes | 舊工作服 | APPAREL | UNIQUE | 1200 | item_work_clothes | clothing, workwear |
| desert_robe | 沙地長袍 | APPAREL | UNIQUE | 900 | item_desert_robe | clothing, desert |
| caravan_coat | 商隊外套 | APPAREL | UNIQUE | 1500 | item_caravan_coat | clothing, travel |
| travel_backpack | 舊旅行包 | CONTAINER | UNIQUE | 1100 | item_travel_backpack | bag, travel |
| rope | 繩索 | TOOL | UNIQUE | 2500 | item_rope | rope, travel |
| flashlight | 手電筒 | TOOL | UNIQUE | 400 | item_flashlight | lighting, tool |
| wrench | 扳手 | TOOL | UNIQUE | 700 | item_wrench | hand_tool, metal |
| first_aid_kit | 急救包 | CONSUMABLE | STACKABLE | 800 | item_first_aid_kit | medical |

The existing file `candidates/rusty_knife.png` serves `item_rusted_knife` and
`candidates/medkit.png` serves `item_first_aid_kit`. Other references map explicitly
to their baseline PNG. No ID is inferred from display text or a directory scan.
For this version, a known item ID with another asset ID is rejected even if that
asset exists. Stable bindings can only change through an explicit future source
change and contract review; neither saves nor caller-provided rows can replace
the authoritative source.

## API and refusal behavior

- `ItemDefinition.validate(raw: Variant) -> String`: empty string means valid;
  otherwise a stable error code. Rejects wrong types, missing/extra fields,
  unknown enums, invalid IDs, invalid weights and invalid/duplicate tags.
- `ItemCatalogue.resolve(item_id: Variant) -> Dictionary`: returns
  `{success, definition, error}`. IDs must be Strings and exact matches. Unknown
  IDs return `success=false`, `definition=null`, `UNKNOWN_ITEM_ID`; no fallback,
  alias, first-row selection or art-driven registration.
- `ItemCatalogue.all_definitions() -> Array`: fresh records sorted by item ID,
  with sorted tags. Only the fixed twelve are authoritative.
- `ItemCatalogue.canonicalize(raw: Variant) -> Dictionary`: pure validation of
  one complete twelve-row candidate; returns `{success, definitions,
  canonical_json, error}`. Rejects duplicates, unknown/missing IDs, wrong asset
  bindings and malformed records atomically. An error returns no partial rows or
  JSON. Success does not install the candidate or change authoritative lookup.
- `ItemArtReferences.resolve(asset_id: Variant) -> Dictionary`: returns
  `{success, path, error}`. Unknown/non-string keys fail closed. This is a path
  reference lookup only, with no texture loading or UI activation.

Canonical output is `{"schema_version":1,"items":[...]}` with item IDs, tags
and object keys sorted. It is a definition fingerprint/document, not save data.
`base_weight` remains an integer. Raw JSON decoding of definitions is not an
ITEM-1 API; the existing world and strict capability codecs are unchanged.

World/Player serialization, duplication, migration and schema versions are
unchanged. No definition or catalogue is stored in a save. Future instance
persistence should reference `item_id`; its rules belong to ITEM-2.

## Existing authority and deferred effects

The repository already has the separately authorized Field Combat Lite example:
HP, one crowbar, fixed carrying cost, combat and a one-time cache. ITEM-1 neither
removes that example nor generalizes it through the new definitions. The crowbar
and four aggregate resources are not silently added as a thirteenth item.

No damage, armor, accuracy, durability, rarity, level/skill/perk requirement,
modifier, healing, capacity bonus, price, repair cost, effect or recipe field is
accepted. No action is granted by `WEAPON`, `CONSUMABLE`, `medical`, `lighting` or
any other tag. The backpack grants no capacity and the medkit grants no healing.

## Acceptance evidence

1. Twelve stable IDs, explicit baseline asset mappings and valid metadata.
2. Unknown IDs, asset rebinding, duplicates and malformed/deferred fields refused
   without partial results or source mutation.
3. Returned record/tag mutations cannot change subsequent lookup or fingerprint.
4. Catalogue/field/tag ordering does not change canonical JSON or SHA-256.
5. Two real-world action tracks remain equal when lookups are interleaved in
   different orders and only one track is saved/loaded. Check population/resource
   invariants throughout, including pending encounter confirmation and deprivation.
6. All existing suites pass; compare their observable replay hashes with a fresh
   pre-implementation baseline. Existing world/inventory/travel/trade/encounter/
   survival/combat behavior remains unchanged.

The next owner-directed sequence is ITEM-2 instance/ownership, ITEM-3 equipment
slots/equip authority, ITEM-4 formal-item encounter loot, then C5 progression.
Only ITEM-1 is implemented by this slice.
