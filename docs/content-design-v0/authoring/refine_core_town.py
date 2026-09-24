"""Retired one-time editorial migration; retained as a compatibility marker.

The reviewed replacements now live only in town_caravan_encounters.py.
This file must not keep another copy of those records or rewrite the author
source. Rebuild in dependency order: town_caravan_encounters.py, then
town_quests_nh_gv.py, then the generated reference and shortlist views.

Running this old entry point is harmless and does not read or write content.
It is not an authoring/rebuild step and does not validate generated JSON.
"""

if __name__ == "__main__":
    print("Retired: use town_caravan_encounters.py as the sole town/caravan author source; no files changed.")
