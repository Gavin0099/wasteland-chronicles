"""Independent editorial extension probes, fixtures and byte-preservation evidence.

Does not import simulation, instantiate a world, register runtime items or commit.
Run once all baseline authors are done. Preview output stays under extension-previews.
"""
import contextlib
import copy
import hashlib
import io
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
from validate import read_rows, validate, validate_towns
from check_extensions import check_packs, read_pack
from build_reference import build


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def protected():
    files = [HERE / "item-seeds.json"]
    for folder in ("items", "encounters", "quests", "npc-hooks", "catalogue", "derived"):
        files += [p for p in (HERE / folder).rglob("*") if p.is_file()]
    for folder in ("simulation", "game_data", "ui", "tests", "player"):
        files += [p for p in (HERE.parents[1] / folder).rglob("*") if p.is_file() and "__pycache__" not in p.parts]
    return {str(p.relative_to(HERE.parents[1])).replace("\\", "/"): sha(p) for p in sorted(files)}


def verify_preview_links(preview, fixture):
    sources = list(preview.rglob("*.md"))
    cache = {p.resolve():p.read_text(encoding="utf-8") for p in sources}
    count = 0
    for source, body in cache.copy().items():
        for raw in re.findall(r"\[[^\]]*\]\(([^)]+)\)", body):
            if "://" in raw:
                continue
            path, _, fragment = raw.partition("#")
            target = (source.parent / path).resolve() if path else source
            assert target.is_file(), (source, "missing preview link", raw)
            if fragment:
                if target not in cache:
                    cache[target] = target.read_text(encoding="utf-8")
                assert f'id="{fragment}"' in cache[target], (source, "missing preview anchor", raw)
            count += 1
    expected = [("items", "content_id", "items.md"), ("encounters", "encounter_id", "encounters-npc.md"),
                ("quests", "quest_id", "quests-dry_well.md"), ("npc_hooks", "hook_id", "npc-dry_well.md")]
    for field, key, file in expected:
        text = cache[(preview / "catalogue" / file).resolve()]
        assert f'id="{fixture[field][0][key]}"' in text, (field, "new record omitted from preview")
    return count


def make_fixture(base):
    pack = json.loads((HERE / "extension-template.json").read_text(encoding="utf-8"))
    pack.update(pack_id="independent_review", pack_version=1)
    item = copy.deepcopy(next(r for r in base["items"] if r["content_id"] == "content_rope"))
    item.update(content_id="pack_independent_review__item__marked_rope", runtime_item_id=None,
                name_zh="驗證用有記號繩索", description_zh="獨立檢查fixture；借用既有繩索圖，沒有新增遊戲物品。")
    event = copy.deepcopy(next(r for r in base["encounters"] if r["encounter_id"] == "npc_067"))
    event.update(encounter_id="pack_independent_review__encounter__rope_return", title_zh="獨立驗證：有記號繩的交還",
                 context_zh="這是檢查擴充引用的fixture，沒有註冊新遭遇。")
    event["choices"][0]["required_items"] = [item["content_id"]]
    hook = copy.deepcopy(next(r for r in base["npc_hooks"] if r["hook_id"] == "hook_dry_well_023"))
    hook.update(hook_id="pack_independent_review__person__rope_owner", role_zh="獨立驗證：繩索原主候選",
                item_refs=[item["content_id"]], encounter_refs=[event["encounter_id"]])
    quest = copy.deepcopy(next(r for r in base["quests"] if r["quest_id"] == "quest_dry_well_001"))
    quest.update(quest_id="pack_independent_review__quest__return_marked_rope", title_zh="獨立驗證：交還有記號的繩",
                 premise_zh="只驗證四種新增記錄可在同包與基準人物之間形成型別正確的引用，不是交付內容。",
                 issuer_hook_id=hook["hook_id"], encounter_refs=[event["encounter_id"]])
    pack.update(items=[item], encounters=[event], quests=[quest], npc_hooks=[hook])
    return pack


def run():
    baseline = {"items": read_rows("items"), "encounters": read_rows("encounters"),
                "quests": read_rows("quests"), "npc_hooks": read_rows("npc-hooks")}
    errors = validate(baseline["items"], baseline["encounters"])
    errors += validate_towns(baseline["quests"], baseline["npc_hooks"], baseline["encounters"])
    assert not errors, errors
    before = protected()
    baseline_copy = copy.deepcopy(baseline)
    evidence = HERE / "evidence"
    fixture = make_fixture(baseline)
    fixture_path = evidence / "extension-four-kind-fixture.json"
    write(fixture_path, fixture)
    positive = check_packs([read_pack(fixture_path)], baseline)
    assert positive["status"] == "PASS", positive

    mutations = [
        ("unknown_schema", lambda p:p.update(schema_version=2)),
        ("boolean_schema", lambda p:p.update(schema_version=True)),
        ("boolean_pack_version", lambda p:p.update(pack_version=True)),
        ("pack_id_array", lambda p:p.update(pack_id=[])),
        ("dependency_null", lambda p:p.update(requires_packs=None)),
        ("null_record", lambda p:p.update(items=[None])),
        ("null_art_path", lambda p:p["items"][0].update(art_file=None)),
        ("unknown_package_field", lambda p:p.update(execute="arbitrary code")),
        ("baseline_id_replacement", lambda p:p["items"][0].update(content_id="content_rope")),
        ("wrong_namespace_kind", lambda p:p["items"][0].update(content_id="pack_independent_review__person__wrong")),
        ("runtime_id_escalation", lambda p:p["items"][0].update(runtime_item_id="rope")),
        ("duplicate_item", lambda p:p["items"].append(copy.deepcopy(p["items"][0]))),
        ("unknown_item", lambda p:p["encounters"][0]["choices"][0].update(required_items=["missing"])),
        ("unknown_event", lambda p:p["npc_hooks"][0].update(encounter_refs=["missing"])),
        ("unknown_person", lambda p:p["quests"][0].update(issuer_hook_id="missing")),
        ("item_as_issuer", lambda p:p["quests"][0].update(issuer_hook_id=p["items"][0]["content_id"])),
        ("person_as_item", lambda p:p["encounters"][0]["choices"][0].update(required_items=[p["npc_hooks"][0]["hook_id"]])),
        ("event_as_relationship", lambda p:p["npc_hooks"][0]["relationships"][0].update(target_hook_id=p["encounters"][0]["encounter_id"])),
        ("new_skill", lambda p:p["encounters"][0]["choices"][0].update(required_skill={"skill":"MAGIC","rank":1})),
        ("bool_skill_rank", lambda p:p["encounters"][0]["choices"][0].update(required_skill={"skill":"SURVIVAL","rank":True})),
        ("damage_field", lambda p:p["items"][0].update(damage=100)),
        ("asset_directory_escape", lambda p:p["items"][0].update(art_file="../outside.png")),
        ("absolute_asset_path", lambda p:p["items"][0].update(art_file=str((HERE.parents[1]/p["items"][0]["art_file"]).resolve()))),
        ("category_as_reward", lambda p:p["encounters"][0]["choices"][0].update(rewards=[{"content_id":"content_ammunition","quantity":1}])),
        ("category_as_salvage", lambda p:p["items"][0].update(salvage={"possible":True,"outputs":["content_medicines"],"note_zh":"故意非法：分類不是產物。"})),
        ("category_as_repair_input", lambda p:p["items"][0].update(repair={"possible":True,"inputs":["content_mechanical_parts"],"note_zh":"故意非法：分類不是材料。"})),
        ("integer_choice_prose", lambda p:p["encounters"][0]["choices"][0].update(cost_zh=123)),
        ("integer_availability", lambda p:p["npc_hooks"][0]["availability"].update(condition_zh=123)),
        ("object_actions", lambda p:p["items"][0].update(actions={"tie":1})),
        ("object_required_items", lambda p:p["encounters"][0]["choices"][0].update(required_items={"content_rope":1})),
        ("object_dependencies", lambda p:p["items"][0].update(dependencies={"item_ownership":1})),
        ("unknown_group", lambda p:p["npc_hooks"][0].update(group_ids=["missing_group"])),
        ("blank_context", lambda p:p["encounters"][0].update(context_zh="   ")),
        ("integer_market_reason", lambda p:p["items"][0]["markets"]["new_hope"].update(reason_zh=42)),
        ("integer_hook_use", lambda p:p["items"][0]["hooks"][0].update(use_zh=42)),
        ("object_relationship_text", lambda p:p["npc_hooks"][0]["relationships"][0].update(tension_zh={"bad":"type"})),
        ("integer_world_effect", lambda p:p["quests"][0]["world_effect_proposals"][0].update(change_zh=42)),
        ("null_trigger", lambda p:p["encounters"][0].update(trigger=None)),
        ("unexpected_trigger_field", lambda p:p["encounters"][0]["trigger"].update(mutate_world=True)),
        ("array_skill", lambda p:p["encounters"][0]["choices"][0].update(required_skill=[])),
        ("object_rewards", lambda p:p["encounters"][0]["choices"][0].update(rewards={})),
        ("string_repair_inputs", lambda p:p["items"][0]["repair"].update(inputs="content_rope")),
        ("object_item_refs", lambda p:p["npc_hooks"][0].update(item_refs={"content_rope":1})),
        ("missing_deadline_key", lambda p:p["quests"][0]["deadline"].pop("without_player_zh")),
        ("absent_dependency", lambda p:p.update(requires_packs=["missing_pack"])),
    ]
    probes = []
    for label, mutate in mutations:
        bad = copy.deepcopy(fixture)
        mutate(bad)
        try:
            result = check_packs([bad], baseline)
            status = result.get("status")
            reason = result.get("errors", [])
        except Exception as exc:
            status, reason = "UNCAUGHT_EXCEPTION", [type(exc).__name__ + ": " + str(exc)]
        probes.append({"probe":label, "status":status, "errors":reason})
    second = copy.deepcopy(fixture)
    second.update(pack_id="independent_followup", items=[], quests=[], npc_hooks=[], requires_packs=["independent_review"])
    second["encounters"][0].update(encounter_id="pack_independent_followup__encounter__check_return",
                                  title_zh="獨立驗證：交還後查帳", context_zh="獨立檢查另一包引用需要明列依賴。")
    first_order = check_packs([fixture, second], baseline)
    reverse_order = check_packs([second, fixture], baseline)
    assert first_order["status"] == "PASS" and first_order == reverse_order
    second["requires_packs"] = []
    probes.append({"probe":"undeclared_cross_pack", **check_packs([fixture, second], baseline)})
    second["requires_packs"] = ["independent_review"]
    cyclic = copy.deepcopy(fixture)
    cyclic["requires_packs"] = ["independent_followup"]
    probes.append({"probe":"dependency_cycle", **check_packs([cyclic, second], baseline)})
    try:
        invalid = evidence / "extension-duplicate-key-fixture.json"
        invalid.write_text('{"pack_id":"first","pack_id":"second"}\n', encoding="utf-8")
        read_pack(invalid)
        duplicate_key = "ACCEPTED"
    except ValueError:
        duplicate_key = "FAIL"
    probes.append({"probe":"duplicate_json_key", "status":duplicate_key})
    for label, packs in (("top_package_array", [[]]), ("top_package_null", [None]), ("packages_not_array", {})):
        probes.append({"probe":label, **check_packs(packs, baseline)})
    assert baseline == baseline_copy, "validator mutated caller data"
    regional_interest = copy.deepcopy(fixture)
    regional_interest["npc_hooks"][0]["group_ids"] = ["nh_growers"]
    assert check_packs([regional_interest], baseline)["status"] == "PASS", "regional interests may cross town boundaries"

    preview = HERE / "extension-previews" / "independent-review"
    with contextlib.redirect_stdout(io.StringIO()):
        build([str(fixture_path)], str(preview))
    receipt = json.loads((preview / "derived/validation-receipt.json").read_text(encoding="utf-8"))
    assert receipt["counts"] == {"items":186,"events":481,"quests":121,"hooks":151}, receipt
    local_link_count = verify_preview_links(preview, fixture)
    preview_first = {str(p.relative_to(preview)):sha(p) for p in preview.rglob("*") if p.is_file()}
    with contextlib.redirect_stdout(io.StringIO()):
        build([str(fixture_path)], str(preview))
    preview_second = {str(p.relative_to(preview)):sha(p) for p in preview.rglob("*") if p.is_file()}
    assert preview_first == preview_second, "same extension build changed bytes"
    with contextlib.redirect_stdout(io.StringIO()):
        build()
    preview_after_baseline = {str(p.relative_to(preview)):sha(p) for p in preview.rglob("*") if p.is_file()}
    assert preview_after_baseline == preview_second, "baseline build overwrote previous preview via global paths"
    after = protected()
    unchanged = before == after
    failures = [p for p in probes if p["status"] != "FAIL"]
    report = {"status":"PASS" if not failures and unchanged else "FAIL", "scope":"DESIGN_ONLY extension validation and rendering; no runtime gates",
              "positive":positive, "negative_probe_count":len(probes), "negative_probes":probes,
              "package_order_invariant":True,"caller_data_unchanged":baseline == baseline_copy,
              "cross_town_regional_interest_allowed":True,
              "baseline_and_runtime_bytes_unchanged":unchanged, "protected_file_count":len(before),
              "changed_protected_files":[p for p in sorted(set(before)|set(after)) if before.get(p)!=after.get(p)],
              "preview_counts":receipt["counts"], "preview_repeat_identical":preview_first==preview_second,
              "preview_then_baseline_no_output_leak":preview_after_baseline==preview_second,
              "preview_local_links_resolve":local_link_count, "all_four_new_records_rendered":True,
              "fixture_sha256":sha(fixture_path), "preview_file_sha256":preview_first,
              "reviewed_tool_sha256":{name:sha(HERE/name) for name in ("check_extensions.py","validate.py","build_reference.py")}}
    write(evidence / "independent-extension-review.json",report)
    print(json.dumps({k:v for k,v in report.items() if k not in {"negative_probes","preview_file_sha256"}},ensure_ascii=False,indent=2))
    if failures:
        print(json.dumps(failures,ensure_ascii=False,indent=2))
    assert report["status"] == "PASS", "See independent-extension-review.json"


if __name__ == "__main__":
    run()
