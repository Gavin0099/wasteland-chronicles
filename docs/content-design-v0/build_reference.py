"""Build human-readable proposals and sparse matrices from authored JSON only."""
import argparse
import hashlib
import json
import os
from collections import Counter, defaultdict
from pathlib import Path
from validate import HERE, COUNTS, MARKETS, read_rows, validate, validate_towns, rejection_probes

TOWNS = {"new_hope": "新希望", "gray_valley": "灰谷", "dry_well": "乾井"}
KINDS = {"work": "工作", "life": "生活", "economy": "經濟", "faction": "利益衝突", "exploration": "探索", "world_state": "世界狀態"}
CATS = {"wilderness": "荒野", "settlement": "聚落", "caravan": "商隊", "ruins": "遺跡", "npc": "人物", "anomaly": "奇物"}
OUT = HERE / "derived"
CATALOGUE = HERE / "catalogue"


def json_write(path, value):
    path.parent.mkdir(exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def md_write(path, lines):
    path.parent.mkdir(exist_ok=True)
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def digest(data):
    return hashlib.sha256(json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def build(extension_paths=(), output_root=None):
    # A preview must never redirect a later baseline build in this process.
    OUT = HERE / "derived"
    CATALOGUE = HERE / "catalogue"
    items = sorted(read_rows("items"), key=lambda x: x["content_id"])
    events = sorted(read_rows("encounters"), key=lambda x: x["encounter_id"])
    quests = sorted(read_rows("quests"), key=lambda x: x["quest_id"])
    hooks = sorted(read_rows("npc-hooks"), key=lambda x: x["hook_id"])
    errors = validate(items, events) + validate_towns(quests, hooks, events)
    if errors:
        raise ValueError("\n".join(errors))
    probes = rejection_probes(items, events)
    extension_receipt = None
    if extension_paths:
        from check_extensions import read_pack, check_packs
        packs = [read_pack(p) for p in extension_paths]
        extension_receipt = check_packs(packs, {"items":items,"encounters":events,"quests":quests,"npc_hooks":hooks})
        if extension_receipt["status"] != "PASS":
            raise ValueError(str(extension_receipt))
        if output_root is None:
            raise ValueError("Extensions require --output under docs/content-design-v0/extension-previews")
        output_root = Path(output_root).resolve()
        output_root.relative_to((HERE / "extension-previews").resolve())
        OUT, CATALOGUE = output_root / "derived", output_root / "catalogue"
        OUT.mkdir(parents=True, exist_ok=True)
        CATALOGUE.mkdir(parents=True, exist_ok=True)
        for p in packs:
            items += p["items"]
            events += p["encounters"]
            quests += p["quests"]
            hooks += p["npc_hooks"]
        for data, key in ((items,"content_id"),(events,"encounter_id"),(quests,"quest_id"),(hooks,"hook_id")):
            data.sort(key=lambda r:r[key])
    elif output_root:
        raise ValueError("--output is reserved for an explicit extension preview")
    by_item = {x["content_id"]: x for x in items}
    by_event = {x["encounter_id"]: x for x in events}
    by_hook = {x["hook_id"]: x for x in hooks}
    edges = []
    def edge(source, target, kind, reason):
        edges.append({"source": source, "target": target, "kind": kind, "reason_zh": reason})
    def names(ids):
        return "、".join(by_item[x]["name_zh"] for x in ids) or "無"
    def itemlink(iid):
        return f"[{by_item[iid]['name_zh']}](items.md#{iid})"
    def eventlink(eid):
        e = by_event[eid]
        return f"[{e['title_zh']}](encounters-{e['category']}.md#{eid})"
    def hooklink(hid):
        h = by_hook[hid]
        return f"[{h['role_zh']}](npc-{h['town_id']}.md#{hid})"
    def render_choice(c):
        rank = c["required_skill"]
        gate = f"{rank['skill']} {rank['rank']}" if rank else "無技能門檻"
        rewards = "、".join(f"{by_item[r['content_id']]['name_zh']} ×{r['quantity']}" for r in c["rewards"]) or "無物品獎勵"
        return [f"- **{c['label_zh']}**｜持有：{names(c['required_items'])}；交付／消耗：{names(c['consumed_items'])}；{gate}。",
                f"  成本：{c['cost_zh']} 結果：{c['outcome_zh']} 物品收入：{rewards}。"]
    def choice_edges(rowid, choices, prefix):
        for c in choices:
            for iid in c["required_items"]:
                edge(rowid, iid, prefix + "_requires", c["label_zh"])
            for iid in c["consumed_items"]:
                edge(rowid, iid, prefix + "_consumes", c["label_zh"])
            for r in c["rewards"]:
                edge(rowid, r["content_id"], prefix + "_rewards", c["label_zh"] + f" ×{r['quantity']}")
    for e in events:
        choice_edges(e["encounter_id"], e["choices"], "encounter")
    for q in quests:
        qid = q["quest_id"]
        choice_edges(qid, q["approaches"], "quest")
        for eid in q["encounter_refs"]:
            edge(qid, eid, "quest_encounter", q["title_zh"])
        for hid in sorted(set([q["issuer_hook_id"]] + q["stakeholder_hook_ids"])):
            edge(qid, hid, "quest_person", "委託／利害關係人")
    for h in hooks:
        hid = h["hook_id"]
        for iid in h["item_refs"]:
            edge(hid, iid, "person_item", h["public_need_zh"])
        for eid in h["encounter_refs"]:
            edge(hid, eid, "person_encounter", h["role_zh"])
        for r in h["relationships"]:
            edge(hid, r["target_hook_id"], "relationship", r["tension_zh"] + "；合作：" + r["cooperation_zh"])
        for group in h["group_ids"]:
            edge(hid, group, "stakeholder_group", "編輯用利益群體，非已存在勢力")
    relations = []
    for i in items:
        for iid in i["repair"]["inputs"]:
            relations.append({"source": iid, "target": i["content_id"], "kind": "repair_input", "note_zh": i["repair"]["note_zh"]})
        for iid in i["salvage"]["outputs"]:
            relations.append({"source": i["content_id"], "target": iid, "kind": "salvage_output", "note_zh": i["salvage"]["note_zh"]})
    for c in json.loads((HERE / "crafting-proposals.json").read_text(encoding="utf-8")):
        assert c["status"] == "DESIGN_ONLY"
        assert c["output"] in by_item and set(c["inputs"] + c["tools"]) <= set(by_item)
        assert c["output"] not in c["inputs"]
        for iid in c["inputs"]:
            relations.append({"source": iid, "target": c["output"], "kind": "craft_input", "note_zh": c["limit_zh"]})
        for iid in c["tools"]:
            relations.append({"source": iid, "target": c["output"], "kind": "craft_tool_not_consumed", "note_zh": c["limit_zh"]})
    usage = []
    for i in items:
        matched = [e for e in edges if e["target"] == i["content_id"]]
        usage.append({"content_id": i["content_id"], "name_zh": i["name_zh"], "art_role": i["art_role"],
                      "roles": i["roles"], "edge_counts": dict(sorted(Counter(e["kind"] for e in matched).items())),
                      "encounter_ids": sorted({e["source"] for e in matched if e["kind"].startswith("encounter_")}),
                      "quest_ids": sorted({e["source"] for e in matched if e["kind"].startswith("quest_")}),
                      "hook_ids": sorted({e["source"] for e in matched if e["kind"] == "person_item"})})
    economy = [{"content_id": i["content_id"], "town_id": town, **i["markets"][town],
                "proposed_weight_g": i["proposed_weight_g"], "proposed_base_value_caps": i["proposed_base_value_caps"],
                "value_rationale_zh": i["value_rationale_zh"]} for i in items for town in sorted(MARKETS)]
    loot = [{"content_id": i["content_id"], "proposed_sources": i["loot_sources"], "rarity": i["rarity"],
             "reward_encounters": sorted({e["source"] for e in edges if e["target"] == i["content_id"] and e["kind"] == "encounter_rewards"}),
             "reward_quests": sorted({e["source"] for e in edges if e["target"] == i["content_id"] and e["kind"] == "quest_rewards"}),
             "regular_stock_allowed": i["rarity"] not in {"unique", "category"}} for i in items]
    json_write(OUT / "world-links.json", sorted(edges, key=lambda e: (e["source"], e["target"], e["kind"], e["reason_zh"])))
    json_write(OUT / "item-usage.json", usage)
    json_write(OUT / "settlement-economy.json", economy)
    json_write(OUT / "loot-sources.json", loot)
    json_write(OUT / "material-relations.json", sorted(relations, key=lambda e:(e["source"], e["target"], e["kind"])))
    md = [f"# {len(items)} 件物品內容稿", "", "DESIGN_ONLY；數字皆為提案。圖庫分類與 gameplay 類別分開；只有十二個 runtime ID 已存在。", ""]
    for i in items:
        md += [f"<a id=\"{i['content_id']}\"></a>", f"## {i['name_zh']} · {i['content_id']}", "",
               f"{i['category']} / {i['subtype']}｜{i['proposed_weight_g']} g｜參考估值 {i['proposed_base_value_caps']} Caps｜{i['rarity']}。",
               f"估值理由：{i['value_rationale_zh']} 空值表示不設通用估值。" if i["proposed_base_value_caps"] is None else f"估值理由：{i['value_rationale_zh']}",
               f"[既有圖片]({Path(os.path.relpath(HERE.parents[1] / i['art_file'], CATALOGUE)).as_posix()})｜runtime ID：{i['runtime_item_id'] or '尚未註冊'}", "",
               i["description_zh"], "", "**初見：** " + i["known_description_zh"], "",
               "**調查後可確認：** " + i["identified_description_zh"], "", i["world_notes_zh"], "",
               "候選動作：" + "、".join(i["actions"]) + "。來源：" + "、".join(i["origin_tags"]) + "。", ""]
        for town in TOWNS:
            m = i["markets"][town]
            md += [f"- {TOWNS[town]}：供應 {m['supply']}／需求 {m['demand']}。{m['reason_zh']}"]
        md += [""]
        for hook in i["hooks"]:
            md += [f"- {hook['situation_zh']} → {hook['use_zh']} 代價／限制：{hook['cost_or_limit_zh']}"]
        md += ["", "維修：" + i["repair"]["note_zh"] + " 候選投入：" + names(i["repair"]["inputs"]),
               "拆解：" + i["salvage"]["note_zh"] + " 候選產物：" + names(i["salvage"]["outputs"]),
               "", "前置缺口：" + "、".join(i["dependencies"]) + "。研究：" + "、".join(i["inspiration_refs"]) + "。", ""]
    md_write(CATALOGUE / "items.md", md)
    for category in COUNTS:
        md = [f"# {CATS[category]}遭遇骨架", "", "DESIGN_ONLY；尚未安裝事件、報酬或世界事實。", ""]
        for e in [e for e in events if e["category"] == category]:
            md += [f"<a id=\"{e['encounter_id']}\"></a>", f"## {e['encounter_id']} · {e['title_zh']}", "", e["context_zh"], "",
                   f"觸發〔{e['trigger']['basis']}〕：{e['trigger']['condition_zh']}", ""]
            for c in e["choices"]:
                md += render_choice(c)
            md += ["", e["followup_zh"], "", "前置缺口：" + "、".join(e["dependencies"]) + "。研究：" + "、".join(e["inspiration_refs"]) + "。", ""]
        md_write(CATALOGUE / f"encounters-{category}.md", md)
    for town in TOWNS:
        md = [f"# {TOWNS[town]}任務骨架", "", "DESIGN_ONLY；期限、NPC、世界效果均需正式權限；世界不為任務停住。", ""]
        for q in [q for q in quests if q["town_id"] == town]:
            md += [f"<a id=\"{q['quest_id']}\"></a>", f"## {q['quest_id']} · {q['title_zh']}", "",
                   f"{KINDS[q['kind']]}｜委託人：{hooklink(q['issuer_hook_id'])}", "", q["premise_zh"], "",
                   "觸發：" + q["trigger"]["condition_zh"], "", f"期限：{q['deadline']['kind']} / {q['deadline']['days']} 天。",
                   "到期：" + q["deadline"]["expiry_zh"], "不介入：" + q["deadline"]["without_player_zh"], ""]
            for c in q["approaches"]:
                md += render_choice(c)
            md += ["", "相關遭遇：" + "、".join(eventlink(eid) for eid in q["encounter_refs"]), "",
                   "利害關係人：" + "、".join(hooklink(hid) for hid in q["stakeholder_hook_ids"]), ""]
            for p in q["world_effect_proposals"]:
                md += [f"- 提議改變 {p['target_zh']}：{p['change_zh']} 所需權限：{p['authority_needed_zh']} 邊界：{p['derivation_boundary_zh']}"]
            md += ["", q["followup_zh"], "", "前置缺口：" + "、".join(q["dependencies"]) + "。研究：" + "、".join(q["inspiration_refs"]) + "。", ""]
        md_write(CATALOGUE / f"quests-{town}.md", md)
        md = [f"# {TOWNS[town]}人物與關係鉤子", "", "DESIGN_ONLY；是角色候選，沒有新增150人口。", ""]
        for h in [h for h in hooks if h["town_id"] == town]:
            md += [f"<a id=\"{h['hook_id']}\"></a>", f"## {h['hook_id']} · {h['role_zh']}", "",
                   "公開需要：" + h["public_need_zh"], "個人利害：" + h["private_stake_zh"],
                   "能提供：" + h["leverage_zh"], "限制：" + h["limit_zh"],
                   "人口綁定：" + h["binding_zh"], "出現條件：" + h["availability"]["condition_zh"],
                   "不介入：" + h["availability"]["without_player_zh"], "",
                   "物品：" + "、".join(itemlink(iid) for iid in h["item_refs"]),
                   "遭遇：" + "、".join(eventlink(eid) for eid in h["encounter_refs"]), ""]
            for r in h["relationships"]:
                md += [f"- {hooklink(r['target_hook_id'])}：分歧：{r['tension_zh']} 合作：{r['cooperation_zh']}"]
            md += ["", "利益群體：" + "、".join(h["group_ids"]) + "。前置缺口：" + "、".join(h["dependencies"]) + "。研究：" + "、".join(h["inspiration_refs"]) + "。", ""]
        md_write(CATALOGUE / f"npc-{town}.md", md)
    top = sorted(usage, key=lambda u:(-len(u["encounter_ids"]), u["content_id"]))[:15]
    unused = [u for u in usage if not u["encounter_ids"] and not u["quest_ids"] and not u["hook_ids"]]
    missing_reward = [x for x in loot if not x["reward_encounters"] and not x["reward_quests"]]
    physical_no_event = [u for u in usage if not u["encounter_ids"] and u["art_role"] != "category_illustration"]
    md = ["# 關聯矩陣與覆蓋檢查", "", "由 JSON 的實際引用生成；不是 185×480 的填滿格子，也不是玩法驗收。", "",
          "quest_encounter 是編輯關聯，可表示同一工作、可選線索或情境改編；不是自動執行的任務步驟。是否共享實物與結算須讀該筆 followup，只有綁定同一次工作時才共用憑證。不同事實版本不得直接串接。", "",
          f"共有 {len(edges)} 條語義連結；{len(economy)} 筆聚落供需提案；{len(relations)} 條材料關係。", "",
          "## 物品 × 遭遇 × 任務 × 人物", "", "| 物品 | 遭遇數 | 任務數 | 人物鉤子數 |", "| --- | ---: | ---: | ---: |"]
    for u in usage:
        md += [f"| [{u['name_zh']}](../catalogue/items.md#{u['content_id']}) | {len(u['encounter_ids'])} | {len(u['quest_ids'])} | {len(u['hook_ids'])} |"]
    md += ["", "## 出現最多的物品", "", "數量只表示編輯引用密度。必須另看是否壟斷解法；持有、消耗與獎勵已在 JSON 分欄。", ""]
    md += [f"- {u['name_zh']}：{len(u['encounter_ids'])} 個遭遇。" for u in top]
    md += ["", "## 保留的缺口", "", "完全無四庫引用：" + (names([u["content_id"] for u in unused]) if unused else "無") + "。",
           "未作為遭遇物件的實體候選：" + names([u["content_id"] for u in physical_no_event]) + "。",
           "沒有具體獎勵入口：" + names([u["content_id"] for u in missing_reward]) + "。",
           "", "無獎勵入口不代表必須補掉落：可由購買、借用、既有持有或明確故事交付取得；未指定取得流程者仍是實作缺口。三種分類示意圖永遠不作實體掉落。", "",
           "材料關係僅表示可能投入／產物，不含數量、耗損或時間。即使沒有自產邊，也不能證明沒有套利；配方上線前需完整質量與價值守恆檢查。"]
    md_write(OUT / "MATRIX_REPORT.md", md)
    md = ["# 三聚落供需草案", "", "none / low / medium / high 是提案，不是即時庫存、價格倍率或已上線商店。", "",
          "| 物品 | 新希望 供／需 | 灰谷 供／需 | 乾井 供／需 |", "| --- | --- | --- | --- |"]
    for i in items:
        cells = [f"{i['markets'][t]['supply']} / {i['markets'][t]['demand']}" for t in TOWNS]
        md += [f"| {i['name_zh']} | " + " | ".join(cells) + " |"]
    md_write(OUT / "ECONOMY_MATRIX.md", md)
    dataset = {"items": items, "events": events, "quests": quests, "hooks": hooks}
    receipt = {"status": "PASS", "claim": "editorial structure/reference coverage only", "counts": {k:len(v) for k,v in dataset.items()},
               "negative_probes": probes, "dataset_sha256": digest(dataset), "edges": len(edges),
               "extensions": extension_receipt,
               "physical_items_without_encounter": [x["content_id"] for x in physical_no_event],
               "items_without_any_four_library_link": [x["content_id"] for x in unused],
               "items_without_reward_link": [x["content_id"] for x in missing_reward],
               "not_claimed": ["playability", "balanced prices/weights", "runtime registration", "quest/faction authority", "world mutation"]}
    json_write(OUT / "validation-receipt.json", receipt)
    print(json.dumps(receipt, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--extension", action="append", default=[])
    parser.add_argument("--output")
    args = parser.parse_args()
    build(args.extension, args.output)
