"""Reproduce the reviewed V0 authoring baseline, then rebuild reading views.

Only explicit repository authoring files execute. Extension JSON is data and
never enters this script. This command overwrites generated baseline JSON.
"""
import contextlib
import io
import json
import runpy
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
AUTHORS = (
    "weapons_equipment.py", "supplies_materials_trade.py", "write_relics.py",
    "wilderness.py", "town_caravan_encounters.py",
    "ruins.py", "write_npc_events.py", "write_anomalies.py",
    "write_npc_hooks.py", "quests_industry_fuel.py",
    "quests_new_hope_later.py", "town_quests_nh_gv.py",
)


def main():
    sys.path.insert(0, str(HERE))
    sys.path.insert(0, str(HERE / "authoring"))
    completed = []
    for name in AUTHORS:
        with contextlib.redirect_stdout(io.StringIO()):
            runpy.run_path(str(HERE / "authoring" / name), run_name="__main__")
        completed.append(name)
    from build_reference import build
    from build_shortlist import build as shortlist
    with contextlib.redirect_stdout(io.StringIO()):
        build()
        shortlist()
    receipt = json.loads((HERE / "derived/validation-receipt.json").read_text(encoding="utf-8"))
    print(json.dumps({"status":receipt["status"], "authoring_steps":completed,
                      "counts":receipt["counts"], "dataset_sha256":receipt["dataset_sha256"]},
                     ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
