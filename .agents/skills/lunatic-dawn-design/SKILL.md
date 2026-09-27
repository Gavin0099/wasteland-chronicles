---
name: lunatic-dawn-design
description: Use when designing, scoping or reviewing Wasteland Chronicles gameplay for Lunatic Dawn (俠客遊) style player agency - jobs, progression, travel, places, combat purpose, consequences, companions, or when a playtest says "boring / just walking around / all jobs feel the same". Judges whether a feature makes the player think "我想……", not how many features, quests or map nodes exist.
---

# 俠客遊 / Lunatic Dawn 式玩法設計

## 使命

Use this skill when designing or reviewing Wasteland Chronicles gameplay for Lunatic Dawn-style player agency. Optimize for self-directed aspirations, meaningful livelihood choices, capability-gated opportunities, purposeful travel, costly combat, persistent consequences, and an emergent life story. Do not optimize for quest count, map-node count, feature count, or checklist completion.

一句話：**這個功能會不會讓玩家在這個世界裡自己產生「我想……」？**

## 什麼時候用

- 規劃下一個 slice，或要在多個玩法方向之間做選擇時
- review 一個新系統、新工作類型、新地點、新敵人、新 UI 時
- 真人試玩回報「無聊」「任務都差不多」「只是在走來走去」「沒有想追的東西」時
- 有人想用「加更多城鎮／任務／選項」來解決好玩問題時（先用這個 skill 擋一下）

不用在：純 UI token、美術規範、Godot 語法問題（那些看 `wc-survivor-pda-design-system`、`godot`）。

## 核心 Loop（判斷基準）

> 看到一個自己想要、但目前拿不到的東西 → 接工作賺錢、累積能力 → 在旅行與風險中成長 → 終於做到以前做不到的事 → 世界又出現新的慾望與人生選擇。

不是：接任務 → 跑地圖 → 戰鬥 → 領 XP → 接下一個任務。

四個字：**自由、慾望、代價、人生。**

## 工作流程

1. **先講清楚要解決的玩家體感**：引用試玩原話（例如「只是在走來走去」），不要從功能清單出發。
2. **對照八大支柱**（[gameplay-pillars.md](references/gameplay-pillars.md)）：這個問題屬於哪一根柱子缺了？通常一次只缺一兩根。
3. **做「我想……」測試**（[review-checklist.md](references/review-checklist.md)）：寫出這個設計會讓玩家說出的句子。寫不出來，或只寫得出「系統叫我按這個」，就不是這種玩法。
4. **查反例**：逐條對照 anti-patterns，特別是「選項數量＝自由」「checklist＝長期目標」「更多城鎮＝更好探索」。
5. **看世界數據，不照例子**：誰缺什麼、誰產什麼、數值能不能讓後果被感覺到，先查遊戲裡的實際數字（見 [travel-and-world.md](references/travel-and-world.md)）。
6. **切最小可證明的一刀**：一個地點、一個敵人、一個背叛選項，先證明它讓遊戲變好玩，再複製結構。不承諾數量。
7. **定義驗收**：技術測試證明「規則正確」，真人試玩才證明「好玩」。每個 slice 都寫下試玩時要觀察的問題。

## 分主題參考

| 主題 | 檔案 |
|---|---|
| 八大支柱、核心 loop、原作機制事實 | [gameplay-pillars.md](references/gameplay-pillars.md) |
| 委託／工作設計、偏離與背叛、後果 | [quest-design.md](references/quest-design.md) |
| 成長、慾望、能力門檻、傳聞 | [progression-and-aspiration.md](references/progression-and-aspiration.md) |
| 旅行、地點、世界、數據驅動 | [travel-and-world.md](references/travel-and-world.md) |
| 戰鬥的角色與可讀性 | [combat-philosophy.md](references/combat-philosophy.md) |
| 夥伴、時間、人生，以及它們的順序 | [companions-and-life.md](references/companions-and-life.md) |
| Review 問題清單、反例、試玩觀察 | [review-checklist.md](references/review-checklist.md) |

## 本專案的硬約束（不可因「更有俠客遊味」而違反）

- **決定論**：沒有 RNG；同樣的輸入永遠同樣的結果。「現在打不贏」必須是算得出來的承諾。
- **收據是權威**：後果寫在 EventRecord 裡。能從收據推導的狀態（信任、地點狀態、傳聞）就不要另存新存檔欄位。
- **世界調節，不封鎖**：世界狀態讓工作變難、變貴、變危險，而不是讓內容消失。
- **失敗關閉**：非法意圖在 engine 的授權層被拒絕，UI 隱藏按鈕不算保護。
- **新的玩家行動要進 intervention allowlist**，並寫明理由（它移動什麼、不創造什麼）。
- **範圍順序由 owner 決定**：寫進 `PLAN.md` 的順序與拒絕清單優先於這個 skill 的建議；有衝突時提出，不要自己改路線。

## 輸出格式（review 時）

```
玩家體感：<引用試玩原話或要解決的問題>
缺的支柱：<1–2 根>
「我想……」：<這個設計會產生的句子；寫不出來就直說>
反例檢查：<踩到哪幾條，或無>
世界數據：<查到的實際數字與結論>
最小一刀：<先做什麼、刻意不做什麼>
試玩觀察：<要問玩家的 1–3 個問題>
```
