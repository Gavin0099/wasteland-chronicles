"""Editorial convenience only. Never imported by the game."""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
SEEDS = json.loads((HERE / "item-seeds.json").read_text(encoding="utf-8"))
BY_NAME = {row["name_zh"]: row["content_id"] for row in SEEDS}


def ids(names):
    return [BY_NAME[name] for name in names.split("/") if name]


def choice(label, cost, outcome, held="", spent="", skill=None, rewards=()):
    return {"label_zh": label, "required_items": ids(held),
            "consumed_items": ids(spent),
            "required_skill": {"skill": skill[0], "rank": skill[1]} if skill else None,
            "cost_zh": cost, "outcome_zh": outcome,
            "rewards": [{"content_id": BY_NAME[name], "quantity": quantity}
                        for name, quantity in rewards]}


def event(event_id, category, title, context, places, axis, choices, followup,
          dependencies, refs, condition=None):
    return {"encounter_id": event_id, "category": category, "status": "DESIGN_ONLY",
            "title_zh": title, "context_zh": context, "location_tags": places,
            "trigger": {"basis": "PROPOSED_WORLD_FACT", "condition_zh": condition or context},
            "primary_axis": axis, "choices": choices, "followup_zh": followup,
            "dependencies": dependencies, "inspiration_refs": refs}


def write(filename, rows):
    directory = HERE / "encounters"
    directory.mkdir(exist_ok=True)
    (directory / filename).write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n",
                                        encoding="utf-8")
    print(f"Authored {len(rows)} proposals: {filename}")
