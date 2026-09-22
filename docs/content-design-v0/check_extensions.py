"""Read-only extension validator. Packages are data, never executable plugins."""
import argparse
import copy
import hashlib
import json
import re
from pathlib import Path
from validate import (SEED, HERE, ROOT, read_rows, validate, validate_towns,
                      _shape, STRINGS, ITEM_SHAPE, EVENT_SHAPE, QUEST_SHAPE, HOOK_SHAPE)

FIELDS = {"format", "schema_version", "pack_id", "pack_version", "base_library",
          "requires_packs", "status", "items", "encounters", "quests", "npc_hooks"}
KINDS = {"items": ("content_id", "item"), "encounters": ("encounter_id", "encounter"),
         "quests": ("quest_id", "quest"), "npc_hooks": ("hook_id", "person")}
DATA_SHAPE = {"items": ("list", ITEM_SHAPE), "encounters": ("list", EVENT_SHAPE),
              "quests": ("list", QUEST_SHAPE), "npc_hooks": ("list", HOOK_SHAPE)}
PACK_SHAPE = {"format": str, "schema_version": int, "pack_id": str, "pack_version": int,
              "base_library": str, "requires_packs": STRINGS, "status": str, **DATA_SHAPE}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def read_pack(path):
    return json.loads(Path(path).read_text(encoding="utf-8"), object_pairs_hook=unique_object)


def check_packs(packs, baseline):
    """Returns a detached receipt. No files, runtime catalogues or globals changed."""
    errors = []
    # Reject malformed envelopes and nested records before hashing IDs,
    # resolving paths, traversing dependencies or accessing object fields.
    _shape(packs, ("list", PACK_SHAPE), "packs", errors)
    _shape(baseline, DATA_SHAPE, "baseline", errors)
    if errors:
        return {"status": "FAIL", "errors": errors}
    errors += validate(baseline["items"], baseline["encounters"])
    errors += validate_towns(baseline["quests"], baseline["npc_hooks"], baseline["encounters"])
    if errors:
        return {"status": "FAIL", "errors": ["baseline invalid: " + e for e in errors]}
    def need(condition, reason):
        if not condition:
            errors.append(reason)
    pack_ids = [p.get("pack_id") for p in packs]
    need(len(set(pack_ids)) == len(pack_ids), "duplicate pack_id")
    combined = copy.deepcopy(baseline)
    seeds = copy.deepcopy(SEED)
    owners = {}
    declared = {}
    for p in packs:
        pid = p.get("pack_id", "")
        need(set(p) == FIELDS, pid + ": exact package fields")
        need(p.get("format") == "wc-content-extension" and type(p.get("schema_version")) is int and p["schema_version"] == 1, pid + ": unsupported schema")
        need(type(p.get("pack_version")) is int and p["pack_version"] > 0, pid + ": version")
        need(bool(re.fullmatch(r"[a-z][a-z0-9_]*", pid)), pid + ": pack id")
        need(p.get("base_library") == "content-design-v0" and p.get("status") == "DESIGN_ONLY", pid + ": base/authority boundary")
        deps = p.get("requires_packs", [])
        need(isinstance(deps, list) and all(isinstance(x, str) for x in deps), pid + ": dependencies type")
        need(pid not in deps and set(deps) <= set(pack_ids), pid + ": dependency absent/self")
        declared[pid] = set(deps)
        for field, (key, kind) in KINDS.items():
            data = p.get(field, [])
            need(isinstance(data, list), pid + ": record array " + field)
            if not isinstance(data, list):
                continue
            for row in data:
                rid = row.get(key, "")
                need(bool(re.fullmatch(re.escape("pack_" + pid + "__" + kind + "__") + r"[a-z][a-z0-9_]*", rid)), pid + ": namespaced id " + rid)
                need(rid not in owners, pid + ": duplicate record " + rid)
                owners[rid] = pid
                if field == "items":
                    need(row.get("runtime_item_id") is None, rid + ": cannot install runtime id")
                    need(row.get("art_role") in {"item_illustration", "category_illustration"}, rid + ": art role")
                    sections = row.get("art_sections")
                    need(isinstance(sections, list) and all(type(x) is int and x > 0 for x in sections) and len(set(sections)) == len(sections), rid + ": art sections")
                    art = row.get("art_file", "")
                    need(art.startswith("ui/assets/items/") and "\\" not in art and not Path(art).is_absolute(),
                         rid + ": art path must be repo-relative ui/assets/items/... with forward slashes")
                    resolved = (ROOT / art).resolve()
                    try:
                        relative = resolved.relative_to((ROOT / "ui/assets/items").resolve())
                        need(resolved.is_file() and relative.suffix.lower() == ".png", rid + ": art must be an existing item PNG")
                    except ValueError:
                        errors.append(rid + ": art escaped item asset directory")
                    seeds[rid] = {k: row.get(k) for k in ("content_id", "name_zh", "art_file", "art_sections", "art_role", "runtime_item_id")}
                    seeds[rid]["baseline_weight_g"] = None
                combined[field].append(copy.deepcopy(row))
    # Cross-pack edges need an explicit dependency; base-library IDs are always available.
    def walk(value):
        if isinstance(value, dict):
            for child in value.values():
                yield from walk(child)
        elif isinstance(value, list):
            for child in value:
                yield from walk(child)
        elif isinstance(value, str):
            yield value
    for p in packs:
        pid = p.get("pack_id", "")
        for value in walk({k:p.get(k, []) for k in KINDS}):
            if value in owners and owners[value] != pid:
                need(owners[value] in declared.get(pid, set()), pid + ": undeclared cross-pack reference " + value)
    # Dependency cycles would make independent version/retirement impossible.
    def visit(pid, stack, done):
        if pid in stack:
            errors.append("dependency cycle: " + " -> ".join(stack + [pid]))
            return
        if pid in done:
            return
        for dep in sorted(declared.get(pid, set())):
            visit(dep, stack + [pid], done)
        done.add(pid)
    done = set()
    for pid in sorted(declared):
        visit(pid, [], done)
    if errors:
        return {"status": "FAIL", "errors": errors}
    try:
        errors += validate(combined["items"], combined["encounters"], complete=False, seeds=seeds, flexible_ids=True)
        errors += validate_towns(combined["quests"], combined["npc_hooks"], combined["encounters"],
                                complete=False, seeds=seeds, extra_hooks=[h["hook_id"] for h in combined["npc_hooks"]], flexible_ids=True)
    except (KeyError, TypeError, AttributeError):
        errors.append("malformed nested schema")
    if errors:
        return {"status": "FAIL", "errors": errors}
    normalized = {k:sorted(v, key=lambda r:r[KINDS[k][0]]) for k,v in combined.items()}
    digest = hashlib.sha256(json.dumps(normalized, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()
    return {"status": "PASS", "packs": sorted(pack_ids), "pack_versions": {p["pack_id"]:p["pack_version"] for p in sorted(packs,key=lambda p:p["pack_id"])}, "counts": {k:len(v) for k,v in combined.items()},
            "combined_sha256": digest, "runtime_changed": False}


def self_test(baseline):
    template = read_pack(HERE / "extension-template.json")
    package = copy.deepcopy(template)
    package["pack_id"] = "probe"
    new_item = copy.deepcopy(next(i for i in baseline["items"] if i["content_id"] == "content_rope"))
    new_item.update(content_id="pack_probe__item__reference_rope", runtime_item_id=None, name_zh="擴充驗證用繩索")
    package["items"] = [new_item]
    new_event = copy.deepcopy(baseline["encounters"][0])
    new_event.update(encounter_id="pack_probe__encounter__reference_crossing", title_zh="擴充驗證渡口", context_zh="測試fixture，不是交付內容或已註冊事件。")
    new_event["choices"][0]["required_items"] = [new_item["content_id"]]
    package["encounters"] = [new_event]
    new_hook = copy.deepcopy(baseline["npc_hooks"][0])
    new_hook.update(hook_id="pack_probe__person__reference_keeper", role_zh="擴充驗證保管人")
    new_hook["item_refs"] = [new_item["content_id"]]
    new_hook["encounter_refs"] = [new_event["encounter_id"]]
    package["npc_hooks"] = [new_hook]
    new_quest = copy.deepcopy(baseline["quests"][0])
    new_quest.update(quest_id="pack_probe__quest__reference_delivery", title_zh="擴充驗證委託", premise_zh="測試新增委託可引用同包人物與事件，並保留基準人物關係。", issuer_hook_id=new_hook["hook_id"])
    new_quest["encounter_refs"] = [new_event["encounter_id"]]
    package["quests"] = [new_quest]
    before = copy.deepcopy(baseline)
    assert check_packs([package], baseline)["status"] == "PASS"
    mutations = [
        ("schema", lambda p:p.update(schema_version=2)),
        ("bool schema", lambda p:p.update(schema_version=True)),
        ("runtime", lambda p:p["items"][0].update(runtime_item_id="rope")),
        ("replace base id", lambda p:p["items"][0].update(content_id="content_rope")),
        ("missing item", lambda p:p["encounters"][0]["choices"][0].update(required_items=["absent"])),
        ("missing person", lambda p:p["quests"][0].update(issuer_hook_id="absent")),
        ("missing event", lambda p:p["npc_hooks"][0].update(encounter_refs=["absent"])),
        ("invent damage", lambda p:p["items"][0].update(damage=999)),
        ("escape art root", lambda p:p["items"][0].update(art_file="../secret.png")),
        ("absent dependency", lambda p:p.update(requires_packs=["absent"])),
        ("third party reference", lambda p:p["quests"][0]["approaches"][0].update(required_skill={"skill":"MAGIC","rank":2})),
    ]
    for label, mutate in mutations:
        p = copy.deepcopy(package)
        mutate(p)
        assert check_packs([p], baseline)["status"] == "FAIL", label
    assert check_packs([package, package], baseline)["status"] == "FAIL"
    second = copy.deepcopy(template)
    second["pack_id"] = "later"
    second["requires_packs"] = ["probe"]
    cross_event = copy.deepcopy(new_event)
    cross_event.update(encounter_id="pack_later__encounter__cross_pack", title_zh="跨包驗證事件", context_zh="驗證引用另一包物品必須宣告依賴。")
    second["encounters"] = [cross_event]
    assert check_packs([package, second], baseline) == check_packs([second, package], baseline)
    second["requires_packs"] = []
    assert check_packs([package, second], baseline)["status"] == "FAIL"
    second["requires_packs"] = ["probe"]
    cyclic = copy.deepcopy(package)
    cyclic["requires_packs"] = ["later"]
    assert check_packs([cyclic, second], baseline)["status"] == "FAIL"
    wrong_type = copy.deepcopy(package)
    wrong_type["quests"][0]["issuer_hook_id"] = new_item["content_id"]
    assert check_packs([wrong_type], baseline)["status"] == "FAIL"
    try:
        unique_object([("id", 1), ("id", 2)])
    except ValueError:
        pass
    else:
        raise AssertionError("accepted duplicate JSON key")
    assert baseline == before, "extension validation mutated baseline"
    return {"positive_extension": "four kinds + declared cross-pack references", "negative_probes": len(mutations)+5,
            "package_order_invariant": True, "baseline_unchanged": True}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    baseline = {"items": read_rows("items"), "encounters": read_rows("encounters"),
                "quests": read_rows("quests"), "npc_hooks": read_rows("npc-hooks")}
    if args.self_test:
        print(json.dumps(self_test(baseline), ensure_ascii=False, indent=2))
    try:
        result = check_packs([read_pack(p) for p in args.paths], baseline)
    except (ValueError, KeyError, TypeError, AttributeError) as exc:
        result = {"status": "FAIL", "errors": [str(exc)]}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    raise SystemExit(0 if result["status"] == "PASS" else 1)
