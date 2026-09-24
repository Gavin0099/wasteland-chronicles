"""Render the deliberately small next-slice proposal, not a runtime allowlist."""
import json
from pathlib import Path
from validate import HERE, read_rows


def build():
    items = {x["content_id"]: x for x in read_rows("items")}
    events = {x["encounter_id"]: x for x in read_rows("encounters")}
    quests = {x["quest_id"]: x for x in read_rows("quests")}
    hooks = {x["hook_id"]: x for x in read_rows("npc-hooks")}
    first = json.loads((HERE / "first-items.json").read_text(encoding="utf-8"))
    item_ids = {x["content_id"] for x in first}
    assert len(first) == len(item_ids) == 30
    assert {x["content_id"] for x in items.values() if x["runtime_item_id"]} <= item_ids
    hook_ids = [f"hook_{town}_{n:03}" for town, count in (("new_hope",3),("gray_valley",3),("dry_well",4)) for n in range(1,count+1)]
    quest_ids = [f"quest_{town}_{n:03}" for town in ("new_hope","gray_valley","dry_well") for n in range(1,4)]
    event_ids = [f"town_{n:03}" for n in (1,2,3,35,36,37,68,69,70,71)] + ["wild_026", "wild_028", "wild_051"]
    # These final two are editorial selections stored alongside the shortlist.
    supplement = json.loads((HERE / "first-events.json").read_text(encoding="utf-8"))
    event_ids += supplement
    assert len(event_ids) == len(set(event_ids)) == 15
    assert set(event_ids) <= set(events) and set(quest_ids) <= set(quests) and set(hook_ids) <= set(hooks)
    for qid in quest_ids:
        q = quests[qid]
        assert q["issuer_hook_id"] in hook_ids and set(q["stakeholder_hook_ids"]) <= set(hook_ids), qid + ": exceeds ten NPCs"
        assert set(q["encounter_refs"]) & set(event_ids), qid + ": no selected event route"
    deferred = []
    for rid in event_ids + quest_ids:
        row = events.get(rid) or quests[rid]
        options = row.get("choices", row.get("approaches"))
        for index, c in enumerate(options):
            required = set(c["required_items"] + c["consumed_items"] + [r["content_id"] for r in c["rewards"]])
            if not required <= item_ids:
                deferred.append({"record_id":rid, "choice_index":index, "label_zh":c["label_zh"], "outside_items":sorted(required-item_ids)})
    deferred_hook_contexts = []
    for hid in hook_ids:
        h = hooks[hid]
        extra = {"outside_items":sorted(set(h["item_refs"]) - item_ids),
                 "outside_encounters":sorted(set(h["encounter_refs"]) - set(event_ids)),
                 "outside_people":sorted({r["target_hook_id"] for r in h["relationships"]} - set(hook_ids))}
        if any(extra.values()):
            deferred_hook_contexts.append({"hook_id":hid, **extra})
    result = {"status":"DESIGN_ONLY", "not_runtime_allowlist":True, "item_ids":[x["content_id"] for x in first],
              "encounter_ids":event_ids, "quest_ids":quest_ids, "hook_ids":hook_ids, "deferred_options":deferred,
              "hook_scope":"Use roles in selected quests/events only; additional personal hooks remain deferred.",
              "deferred_hook_contexts":deferred_hook_contexts}
    (HERE / "first-playable-slice.json").write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n",encoding="utf-8")
    md = ["# 第一輪可玩內容候選", "", "**30 物品＋15 遭遇＋9 城鎮任務＋10 NPC 候選。** 這是下一次實作的範圍提案，不是已可遊玩的版本，也不自動授權未來機制。",
          "", "先驗證「準備工具 → 接小工作 → 選擇做法 → 真正交付／失約 → 看見結果」，再把三城工作透過既有旅行和選定路上遭遇串起來。先不要把四庫全部投入遊戲。",
          "", "## 三段相連的生活", "",
          "新希望提出容器、保種與醫療交付需求；灰谷提供工具、回收與有限零件；乾井處理核帳、出發排程與缺水。這九份工作以城內交付為主，跨城旅行讓玩家接觸另一批需求；尚未宣稱九份工作本身都要求跨城。真正的跨城委託另有庫內候選，接入時要把旅行天數、補給與交付期限一起驗證。",
          "", "所有人都從既有人口綁定。完成一次交付不得同時新增另一份物品、人口或商隊。任務失約只取消仍有效的承諾，不製造死亡來處罰玩家。",
          "", "## 物品分批", "", "| 波次 | 物品 | 選入理由 |", "| --- | --- | --- |"]
    for row in first:
        iid = row["content_id"]
        md.append(f"| {row['wave']} | [{items[iid]['name_zh']}](catalogue/items.md#{iid}) | {row['reason_zh']} |")
    md += ["", "波次 1 保留已定義十二件，先做 ownership 與有結算的物品移轉。波次 2 才接有限回收、採買與交付；波次 3 的照明、防護、機械和 crowbar 橋接各需明確規則。三波是順序提案，不宣稱全套動作已存在。", "",
           "## 九份工作", "", "| 任務 | 委託者 | 初始遭遇入口 |", "| --- | --- | --- |"]
    for qid in quest_ids:
        q = quests[qid]
        linked = [events[e]["title_zh"] for e in q["encounter_refs"] if e in event_ids]
        md.append(f"| [{q['title_zh']}](catalogue/quests-{q['town_id']}.md#{qid}) | {hooks[q['issuer_hook_id']]['role_zh']} | {'、'.join(linked)} |")
    md += ["", "## 十五個遭遇", ""]
    for eid in event_ids:
        e = events[eid]
        md.append(f"- [{eid} · {e['title_zh']}](catalogue/encounters-{e['category']}.md#{eid})：{e['context_zh']}")
    md += ["", "## 十個人物候選", "",
           "先採用這十個職務在上述九工作與十五遭遇中的角色。下列個人需求是後續人物方向；完整鉤子內其他物品、事件和關係不隨選入人物自動上線。", ""]
    for hid in hook_ids:
        h = hooks[hid]
        md.append(f"- [{h['role_zh']}](catalogue/npc-{h['town_id']}.md#{hid})：{h['public_need_zh']} 個人利害：{h['private_stake_zh']}")
    md += ["", "## 尚未納入本輪的分支", "",
           "以下選項引用首30以外物品；實作第一輪時應整條保留為未開放候選，不得悄悄加入額外物品或發放不存在的獎勵。其他選項也仍需各自 authority，列入清單不是可執行證明。", ""]
    for d in deferred:
        md.append(f"- {d['record_id']}「{d['label_zh']}」：{'、'.join(items[i]['name_zh'] for i in d['outside_items'])}。")
    if not deferred:
        md.append("- 沒有越出首30的物品引用；仍須完成 ownership、jobs 等權限。")
    md += ["", "人物完整鉤子中，以下引用留待後續；這也避免選入十人時連帶拉進第十一人或額外物品：", ""]
    for d in deferred_hook_contexts:
        labels = []
        if d["outside_items"]:
            labels.append("物品：" + "、".join(items[i]["name_zh"] for i in d["outside_items"]))
        if d["outside_encounters"]:
            labels.append("遭遇：" + "、".join(d["outside_encounters"]))
        if d["outside_people"]:
            labels.append("人物：" + "、".join(d["outside_people"]))
        md.append(f"- {hooks[d['hook_id']]['role_zh']}：{'；'.join(labels)}。")
    md += ["", "## 實作驗收順序", "",
           "1. ITEM-2：物品 instance 與單一 owner；有限來源、借用、交付、取消都能原子處理，未知 ID 拒絕。",
           "2. 三個小工作先跑接單／重驗／期限／交付／結果確認，沿用世界日期。保留另一解法與拒絕。",
           "3. 接上選定旅行遭遇，再擴到九工作；驗證補給成本、超重、委託人遷移／死亡、商隊先出發。",
           "4. 用 save/load、重播與全域人口不變量驗證已授權效果；敘事層永遠不得直接寫世界。",
           "5. 玩家比較不同背景／準備，記錄是否記得目的地、是否為缺的工具回訪，以及期限是否清楚；通過後才提第二批內容。",
           "", "這批資料的字數、引用數及檢查 PASS 都不替代第五步。第一輪也沒有包含技能成長、完整醫療、稀有植入、派系系統或150位NPC的全部實作。"]
    (HERE / "FIRST_PLAYABLE_SLICE.md").write_text("\n".join(md)+"\n",encoding="utf-8")
    print(json.dumps({"items":30,"events":15,"quests":9,"hooks":10,"deferred_options":len(deferred)},ensure_ascii=False))


if __name__ == "__main__":
    build()
