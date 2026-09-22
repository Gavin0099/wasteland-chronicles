"""Validate editorial references and limits; does not load or mutate a world."""
import argparse
import copy
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
COUNTS = {"wilderness": 100, "settlement": 100, "caravan": 60,
          "ruins": 100, "npc": 80, "anomaly": 40}
PREFIX = dict(zip(COUNTS, ("wild", "town", "caravan", "ruin", "npc", "anomaly")))
SKILLS = set("BARTER ELECTRONICS FIREARMS MECHANICS MEDICINE MELEE SCAVENGING SPEECH STEALTH SURVIVAL".split())
DEPS = set("item_ownership equipment combat_extension injury repair lighting water_treatment cooking camping cargo navigation electronics identification knowledge npc_relationship reputation jobs regional_trade crafting disassembly hazards exploration succession skills_growth".split())
REFS = {f"LD-P{i:02}" for i in range(1, 5)} | {f"WG-{i:02}" for i in range(1, 7)} | {"FICTION-" + x for x in ("ROADSIDE", "ROAD", "CANTICLE", "WOOL", "METRO")}
AXES = {"combat", "trade", "explore", "survival"}
MARKETS = {"new_hope", "gray_valley", "dry_well"}
SEEDS = json.loads((HERE / "item-seeds.json").read_text(encoding="utf-8"))
SEED = {x["content_id"]: x for x in SEEDS}
ITEM_FIELDS = set("content_id name_zh art_file art_sections art_role runtime_item_id status category subtype proposed_weight_g proposed_base_value_caps value_rationale_zh rarity tags roles actions origin_tags markets loot_sources description_zh known_description_zh identified_description_zh world_notes_zh hooks repair salvage dependencies inspiration_refs".split())
EVENT_FIELDS = set("encounter_id category status title_zh context_zh location_tags trigger primary_axis choices followup_zh dependencies inspiration_refs".split())


def _shape(value, schema, path, errors):
    """Validate JSON shapes before semantic checks traverse nested structures.

    All strings are meaningful nonblank text, integer tokens exclude booleans,
    and dictionaries have exact fields. No coercion or world mutation occurs.
    """
    if schema is str:
        if not isinstance(value, str) or not value.strip():
            errors.append(path + ": expected nonempty string")
    elif schema in (int, bool):
        if type(value) is not schema:
            errors.append(path + ": expected " + schema.__name__)
    elif isinstance(schema, tuple):
        kind, child = schema
        if kind == "nullable":
            if value is not None:
                _shape(value, child, path, errors)
        elif kind == "list":
            if not isinstance(value, list):
                errors.append(path + ": expected array")
            else:
                for n, row in enumerate(value):
                    _shape(row, child, f"{path}[{n}]", errors)
    elif isinstance(schema, dict):
        if not isinstance(value, dict):
            errors.append(path + ": expected object")
            return
        if set(value) != set(schema):
            errors.append(path + ": exact object fields")
        for key, child in schema.items():
            if key in value:
                _shape(value[key], child, path + "." + key, errors)
    else:
        raise AssertionError("Unknown internal shape descriptor")


STRINGS = ("list", str)
SKILL_SHAPE = ("nullable", {"skill": str, "rank": int})
TRIGGER_SHAPE = {"basis": str, "condition_zh": str}
CHOICE_SHAPE = {"label_zh": str, "required_items": STRINGS, "consumed_items": STRINGS,
                "required_skill": SKILL_SHAPE, "cost_zh": str, "outcome_zh": str,
                "rewards": ("list", {"content_id": str, "quantity": int})}
ITEM_SHAPE = {field: str for field in ITEM_FIELDS}
ITEM_SHAPE.update({
    "art_sections": ("list", int), "runtime_item_id": ("nullable", str),
    "proposed_weight_g": ("nullable", int), "proposed_base_value_caps": ("nullable", int),
    **{field: STRINGS for field in ("tags", "roles", "actions", "origin_tags", "loot_sources", "dependencies", "inspiration_refs")},
    "markets": {town: {"supply": str, "demand": str, "reason_zh": str} for town in MARKETS},
    "hooks": ("list", {"situation_zh": str, "use_zh": str, "cost_or_limit_zh": str}),
    "repair": {"possible": bool, "inputs": STRINGS, "note_zh": str},
    "salvage": {"possible": bool, "outputs": STRINGS, "note_zh": str},
})
EVENT_SHAPE = {field: str for field in EVENT_FIELDS}
EVENT_SHAPE.update({"location_tags": STRINGS, "trigger": TRIGGER_SHAPE,
                    "choices": ("list", CHOICE_SHAPE), "dependencies": STRINGS, "inspiration_refs": STRINGS})


def read_rows(folder):
    return [row for path in sorted((HERE / folder).glob("*.json"))
            for row in json.loads(path.read_text(encoding="utf-8"))]


def validate(items, events, complete=True, seeds=None, flexible_ids=False):
    seeds = SEED if seeds is None else seeds
    errors = []
    _shape(items, ("list", ITEM_SHAPE), "items", errors)
    _shape(events, ("list", EVENT_SHAPE), "events", errors)
    if errors:
        return errors
    def check(condition, message):
        if not condition:
            errors.append(message)
    def strings(values, where, nonempty=True):
        check(isinstance(values, list) and (bool(values) or not nonempty)
              and all(isinstance(v, str) and v.strip() for v in values), where)
    def refs(row, where):
        check(set(row.get("dependencies", [])) <= DEPS, where + ": unknown mechanic")
        check(bool(row.get("inspiration_refs")) and set(row.get("inspiration_refs", [])) <= REFS, where + ": unknown/missing source")
        check(row.get("status") == "DESIGN_ONLY", where + ": authority boundary")
    def itemrefs(values, where):
        check(all(v in seeds for v in values), where + ": unknown item")

    counts = Counter(x.get("content_id") for x in items)
    check(all(v == 1 for v in counts.values()), "duplicate item IDs")
    if complete:
        check(set(counts) == set(seeds), "item coverage must be exactly 185 seeds")
    for row in items:
        rid = row.get("content_id", "MISSING")
        check(set(row) == ITEM_FIELDS, rid + ": exact item fields")
        if rid not in seeds:
            errors.append(rid + ": unknown seed")
            continue
        seed = seeds[rid]
        for field in ("content_id", "name_zh", "art_file", "art_sections", "art_role", "runtime_item_id"):
            check(row.get(field) == seed[field], rid + ": changed seed " + field)
        check((ROOT / seed["art_file"]).is_file(), rid + ": missing art")
        family = seed["art_role"] == "category_illustration"
        weight = row.get("proposed_weight_g")
        value = row.get("proposed_base_value_caps")
        check(weight is None if family else type(weight) is int and weight > 0, rid + ": weight")
        check(value is None or type(value) is int and value > 0, rid + ": value")
        if seed["baseline_weight_g"] is not None:
            check(weight == seed["baseline_weight_g"], rid + ": baseline weight drift")
        if family:
            check(value is None and row.get("actions") == [] and row.get("rarity") == "category", rid + ": family cannot be an instance")
        check(row.get("category") in {"WEAPON", "APPAREL", "CONTAINER", "TOOL", "CONSUMABLE", "MISC"}, rid + ": category")
        check(row.get("rarity") in {"common", "uncommon", "rare", "unique", "category"}, rid + ": rarity")
        check(bool(re.fullmatch(r"[a-z][a-z0-9_]*", row.get("subtype", ""))), rid + ": subtype")
        for field in ("tags", "roles", "origin_tags", "loot_sources"):
            strings(row.get(field), rid + ": " + field, field != "loot_sources")
        check(set(row.get("roles", [])) <= AXES, rid + ": role")
        for field in ("tags", "actions"):
            check(all(re.fullmatch(r"[a-z][a-z0-9_]*", x) for x in row.get(field, [])), rid + ": invalid token")
        for field in ("description_zh", "known_description_zh", "identified_description_zh", "world_notes_zh", "value_rationale_zh"):
            check(isinstance(row.get(field), str) and len(row[field].strip()) >= 8, rid + ": missing prose " + field)
        markets = row.get("markets", {})
        check(set(markets) == MARKETS, rid + ": three markets")
        for town, data in markets.items():
            check(set(data) == {"supply", "demand", "reason_zh"}, rid + ": market fields")
            check(data.get("supply") in {"none", "low", "medium", "high"} and data.get("demand") in {"none", "low", "medium", "high"}, rid + ": market levels")
            check(bool(data.get("reason_zh")), rid + ": market reason")
            if row.get("rarity") == "unique":
                check(data.get("supply") == "none", rid + ": unique regular stock")
        hooks = row.get("hooks", [])
        check(len(hooks) >= 2, rid + ": two hooks")
        for hook in hooks:
            check(set(hook) == {"situation_zh", "use_zh", "cost_or_limit_zh"} and all(hook.values()), rid + ": hook completeness")
        for field, edge in (("repair", "inputs"), ("salvage", "outputs")):
            rel = row.get(field, {})
            check(set(rel) == {"possible", edge, "note_zh"} and type(rel.get("possible")) is bool and bool(rel.get("note_zh")), rid + ": relation schema")
            itemrefs(rel.get(edge, []), rid + ": " + field)
            check(all(seeds.get(x, {}).get("art_role") != "category_illustration" for x in rel.get(edge, [])), rid + ": category illustration in physical relation")
            check(rid not in rel.get(edge, []), rid + ": self-producing relation")
            check(rel.get("possible") or not rel.get(edge), rid + ": impossible relation has edges")
        refs(row, rid)
    event_ids = Counter(row.get("encounter_id") for row in events)
    check(all(v == 1 for v in event_ids.values()), "duplicate encounter IDs")
    check(len({row.get("title_zh") for row in events}) == len(events), "duplicate encounter titles")
    check(len({row.get("context_zh") for row in events}) == len(events), "duplicate encounter contexts")
    if complete:
        expected = {f"{PREFIX[cat]}_{n:03}" for cat, count in COUNTS.items() for n in range(1, count + 1)}
        check(set(event_ids) == expected, "encounter coverage must equal specified 480 IDs")
        check(Counter(row.get("category") for row in events) == COUNTS, "encounter category counts")
    for row in events:
        eid = row.get("encounter_id", "MISSING")
        check(set(row) == EVENT_FIELDS, eid + ": event fields")
        check(row.get("category") in COUNTS and (flexible_ids or eid.startswith(PREFIX.get(row.get("category"), "INVALID") + "_")), eid + ": prefix/category")
        check(row.get("primary_axis") in AXES, eid + ": axis")
        strings(row.get("location_tags"), eid + ": places")
        for field in ("title_zh", "context_zh", "followup_zh"):
            check(bool(row.get(field)), eid + ": missing " + field)
        trigger = row.get("trigger", {})
        check(set(trigger) == {"basis", "condition_zh"} and trigger.get("basis") in {"EXISTING_READ", "PROPOSED_WORLD_FACT"} and bool(trigger.get("condition_zh")), eid + ": trigger")
        choices = row.get("choices", [])
        check(len(choices) >= 3, eid + ": at least three choices")
        check(any(not c.get("required_items") and not c.get("consumed_items") and c.get("required_skill") is None for c in choices), eid + ": ungated choice")
        check(len({c.get("label_zh") for c in choices}) == len(choices), eid + ": duplicate choice label")
        check(len({c.get("outcome_zh") for c in choices}) >= 2, eid + ": identical consequences")
        for c in choices:
            check(set(c) == {"label_zh", "required_items", "consumed_items", "required_skill", "cost_zh", "outcome_zh", "rewards"}, eid + ": choice fields")
            for field in ("label_zh", "cost_zh", "outcome_zh"):
                check(bool(c.get(field)), eid + ": missing choice prose")
            all_refs = c.get("required_items", []) + c.get("consumed_items", [])
            for reward in c.get("rewards", []):
                check(set(reward) == {"content_id", "quantity"} and type(reward.get("quantity")) is int and reward["quantity"] > 0, eid + ": reward")
                all_refs.append(reward.get("content_id"))
            itemrefs(all_refs, eid)
            check(all(seeds.get(x, {}).get("art_role") != "category_illustration" for x in all_refs), eid + ": category illustration treated as physical item")
            if all_refs:
                check("item_ownership" in row.get("dependencies", []), eid + ": item ownership gap missing")
            skill = c.get("required_skill")
            check(skill is None or set(skill) == {"skill", "rank"} and skill.get("skill") in SKILLS and type(skill.get("rank")) is int and 1 <= skill["rank"] <= 5, eid + ": skill")
        refs(row, eid)
    return errors


def rejection_probes(items, events):
    """Independent forbidden fixtures; each must actually fail validation."""
    mutations = [
        ("unknown item", lambda a, b: a[0].update(content_id="invented")),
        ("duplicate identity", lambda a, b: a.append(copy.deepcopy(a[0]))),
        ("runtime escalation", lambda a, b: a[0].update(status="IMPLEMENTED")),
        ("baseline mass drift", lambda a, b: next(x for x in a if x["runtime_item_id"] == "rope").update(proposed_weight_g=1)),
        ("invented source", lambda a, b: b[0].update(inspiration_refs=["FAKE"])),
        ("category as loot", lambda a, b: b[0]["choices"][0].update(rewards=[{"content_id": "content_ammunition", "quantity": 1}])),
        ("zero reward", lambda a, b: b[0]["choices"][0].update(rewards=[{"content_id": "content_rope", "quantity": 0}])),
        ("fractional skill", lambda a, b: b[0]["choices"][0].update(required_skill={"skill": "MECHANICS", "rank": 2.0})),
        ("missing escape", lambda a, b: [c.update(required_skill={"skill": "SURVIVAL", "rank": 1}) for c in b[0]["choices"]]),
        ("omitted ownership", lambda a, b: b[0].update(dependencies=[])),
    ]
    for label, mutate in mutations:
        a, b = copy.deepcopy(items), copy.deepcopy(events)
        mutate(a, b)
        assert validate(a, b), "validator accepted: " + label
    return len(mutations)


GROUPS = {"new_hope": {"nh_water_stewards", "nh_growers", "nh_clinic", "nh_newcomers"},
          "gray_valley": {"gv_yard_workers", "gv_workshops", "gv_salvage_buyers", "gv_residents"},
          "dry_well": {"dw_fuel_cooperative", "dw_caravan_brokers", "dw_well_queue", "dw_outer_camps"}}
KINDS = {"work", "life", "economy", "faction", "exploration", "world_state"}
QUEST_FIELDS = set("quest_id town_id status kind title_zh premise_zh issuer_hook_id stakeholder_hook_ids trigger deadline approaches encounter_refs world_effect_proposals followup_zh dependencies inspiration_refs".split())
HOOK_FIELDS = set("hook_id town_id status role_zh public_need_zh private_stake_zh leverage_zh limit_zh group_ids binding_zh item_refs encounter_refs relationships availability dependencies inspiration_refs".split())
HOOK_SHAPE = {field: str for field in HOOK_FIELDS}
HOOK_SHAPE.update({
    **{field: STRINGS for field in ("group_ids", "item_refs", "encounter_refs", "dependencies", "inspiration_refs")},
    "relationships": ("list", {"target_hook_id": str, "tension_zh": str, "cooperation_zh": str}),
    "availability": {"condition_zh": str, "without_player_zh": str},
})
QUEST_SHAPE = {field: str for field in QUEST_FIELDS}
QUEST_SHAPE.update({
    **{field: STRINGS for field in ("stakeholder_hook_ids", "encounter_refs", "dependencies", "inspiration_refs")},
    "trigger": TRIGGER_SHAPE, "approaches": ("list", CHOICE_SHAPE),
    "deadline": {"kind": str, "days": ("nullable", int), "expiry_zh": str, "without_player_zh": str},
    "world_effect_proposals": ("list", {"target_zh": str, "change_zh": str, "authority_needed_zh": str, "derivation_boundary_zh": str}),
})


def validate_towns(quests, hooks, events, complete=True, seeds=None, extra_hooks=(), flexible_ids=False):
    seeds = SEED if seeds is None else seeds
    errors = []
    _shape(quests, ("list", QUEST_SHAPE), "quests", errors)
    _shape(hooks, ("list", HOOK_SHAPE), "hooks", errors)
    _shape(events, ("list", EVENT_SHAPE), "events", errors)
    if errors:
        return errors
    def check(condition, message):
        if not condition:
            errors.append(message)
    quest_ids = {q.get("quest_id") for q in quests}
    hook_ids = {h.get("hook_id") for h in hooks}
    event_ids = {e["encounter_id"] for e in events}
    valid_hooks = {f"hook_{town}_{n:03}" for town in MARKETS for n in range(1, 51)}
    valid_events = {f"{PREFIX[cat]}_{n:03}" for cat, count in COUNTS.items() for n in range(1, count + 1)}
    if flexible_ids:
        valid_hooks.update(extra_hooks)
        valid_events.update(event_ids)
    if complete:
        check(hook_ids == valid_hooks, "hook coverage must be exactly 150 IDs")
        check(quest_ids == {f"quest_{town}_{n:03}" for town in MARKETS for n in range(1, 41)}, "quest coverage must be exactly 120 IDs")
    check(len(quest_ids) == len(quests), "duplicate quest ID")
    check(len(hook_ids) == len(hooks), "duplicate hook ID")
    check(len({q.get("title_zh") for q in quests}) == len(quests), "duplicate quest title")
    for h in hooks:
        hid = h.get("hook_id", "MISSING")
        check(set(h) == HOOK_FIELDS, hid + ": fields")
        check(h.get("status") == "DESIGN_ONLY", hid + ": authority")
        check(h.get("town_id") in MARKETS and (flexible_ids or hid.startswith("hook_" + h.get("town_id", "INVALID") + "_")), hid + ": town")
        for field in ("role_zh", "public_need_zh", "private_stake_zh", "leverage_zh", "limit_zh", "binding_zh"):
            check(bool(h.get(field)), hid + ": prose " + field)
        check(bool(h.get("group_ids")) and set(h["group_ids"]) <= set.union(*GROUPS.values()), hid + ": group")
        check(bool(h.get("item_refs")) and set(h["item_refs"]) <= set(seeds), hid + ": item links")
        check(bool(h.get("encounter_refs")) and set(h["encounter_refs"]) <= (event_ids if complete else valid_events), hid + ": event links")
        check(bool(h.get("relationships")), hid + ": relationship required")
        for r in h.get("relationships", []):
            check(set(r) == {"target_hook_id", "tension_zh", "cooperation_zh"} and all(r.values()), hid + ": relationship fields")
            check(r.get("target_hook_id") in (hook_ids if complete else valid_hooks) and r.get("target_hook_id") != hid, hid + ": relationship target")
        check(set(h.get("availability", {})) == {"condition_zh", "without_player_zh"} and all(h.get("availability", {}).values()), hid + ": availability")
        check(set(h.get("dependencies", [])) <= DEPS and bool(h.get("inspiration_refs")) and set(h["inspiration_refs"]) <= REFS, hid + ": gaps/sources")
    normalized = []
    for n, q in enumerate(quests):
        qid = q.get("quest_id", "MISSING")
        check(set(q) == QUEST_FIELDS, qid + ": fields")
        check(q.get("town_id") in MARKETS and (flexible_ids or qid.startswith("quest_" + q.get("town_id", "INVALID") + "_")), qid + ": town")
        check(q.get("kind") in KINDS, qid + ": kind")
        check(q.get("issuer_hook_id") in (hook_ids if complete else valid_hooks), qid + ": issuer")
        check(bool(q.get("stakeholder_hook_ids")) and set(q["stakeholder_hook_ids"]) <= (hook_ids if complete else valid_hooks), qid + ": stakeholders")
        check(bool(q.get("encounter_refs")) and set(q["encounter_refs"]) <= (event_ids if complete else valid_events), qid + ": event links")
        d = q.get("deadline", {})
        check(set(d) == {"kind", "days", "expiry_zh", "without_player_zh"} and d.get("kind") in {"relative_days", "world_event", "none"} and d.get("expiry_zh") and d.get("without_player_zh"), qid + ": deadline")
        check(type(d.get("days")) is int and d["days"] > 0 if d.get("kind") == "relative_days" else d.get("days") is None, qid + ": deadline days")
        check(bool(q.get("world_effect_proposals")), qid + ": effects required")
        for effect in q.get("world_effect_proposals", []):
            check(set(effect) == {"target_zh", "change_zh", "authority_needed_zh", "derivation_boundary_zh"} and all(effect.values()), qid + ": proposed effect authority")
        normalized.append({"encounter_id": f"wild_{n+1:03}", "category": "wilderness", "status": q.get("status"),
                           "title_zh": q.get("title_zh"), "context_zh": q.get("premise_zh"),
                           "location_tags": [q.get("town_id")], "trigger": q.get("trigger"), "primary_axis": "explore",
                           "choices": q.get("approaches", []), "followup_zh": q.get("followup_zh"),
                           "dependencies": q.get("dependencies", []), "inspiration_refs": q.get("inspiration_refs", [])})
    errors.extend("quest choice: " + e for e in validate([], normalized, complete=False, seeds=seeds, flexible_ids=flexible_ids))
    if complete:
        for town in MARKETS:
            check({q["kind"] for q in quests if q["town_id"] == town} == KINDS, town + ": six quest kinds")
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--partial", action="store_true")
    args = parser.parse_args()
    items, events = read_rows("items"), read_rows("encounters")
    quests, hooks = read_rows("quests"), read_rows("npc-hooks")
    errors = validate(items, events, complete=not args.partial)
    errors.extend(validate_towns(quests, hooks, events, complete=not args.partial))
    if errors:
        print("\n".join(errors))
        raise SystemExit(1)
    probes = rejection_probes(items, events) if not args.partial else 0
    dataset = {"items": sorted(items, key=lambda r: r["content_id"]), "events": sorted(events, key=lambda r: r["encounter_id"]), "quests": sorted(quests, key=lambda r:r["quest_id"]), "hooks": sorted(hooks, key=lambda r:r["hook_id"])}
    digest = hashlib.sha256(json.dumps(dataset, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()
    print(json.dumps({"status": "PASS", "items": len(items), "events": len(events), "quests": len(quests), "hooks": len(hooks), "negative_probes": probes, "dataset_sha256": digest}, indent=2))
