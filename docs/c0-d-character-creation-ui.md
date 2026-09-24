# S5-C0-D Character Creation UI / C1 Capability Presentation

狀態：IMPLEMENTED / VERIFIED；S5-C0 與 S5-C1 CLOSED。Headless 已先獨立提交 `6b9c741`；本 UI 以第二次本機提交交付，未 push。C2+ 未開始。

## 玩家流程與權威邊界

正常 New Game → 姓名、年齡、一個背景、0–2 Core Traits → 開始旅程 → `CharacterCreationIntent` / `commit_character_creation` → 已建立角色摘要 → 進入荒原。摘要確認不推進一天、不再次 materialize。非法輸入顯示錯誤並留在表單，authority 原子拒絕；年齡文字不合法時原樣交付拒絕，不截斷小數或 clamp。

起點仍固定灰谷。四組背景直接查詢已核准的 catalogue；顯示完整十技能、0–5 方格與契約階級名稱，註明只決定初始能力。14 個 Trait 用人格描述 tooltip 與 accessibility description，清楚說明目前尚未影響遭遇。第三個 Trait checkbox 禁用，authority 仍拒絕非法注入。Trait 不增加能力。

建立後摘要只顯示身份、背景、Traits 與較擅長技能。地圖頂部「角色 / 能力」顯示完整十技能，可關閉返回旅程。兩者透過唯讀 `character_presentation.gd` 投射 `PlayerState.capability`，沒有第二個 writable profile。舊角色呈現不套用新背景 package。

`main.gd` 不再呼叫 `materialize_player`。舊 API 保留於模擬層及既有測試；`main.gd` / `ui/` 無呼叫。沒有新增 XP、Level、Perk、裝備、戰鬥、HP 或事件能力效果。

## 驗證

Godot 4.7.2，`--headless --path . --script tests/test_*.gd`（逐檔執行）：36 suites，exit code 全部 0，沒有 SCRIPT ERROR。完整清單與每套原始診斷見 `artifacts/character-creation-ui/results.json` 及同目錄 logs。最後排版調整後重跑 `test_character_creation_ui.gd`，仍 PASS。

| Gate | 實際執行證據 |
| --- | --- |
| 四背景預覽 2/1/1 | 操作按鈕後逐一比對畫面十技能；expected 來自 owner decision table |
| 0、1、2 Traits 合法，第三個被阻擋 | 實際 checkbox 信號、disabled 狀態、注入三項時 authority 拒絕 |
| Trait 順序 canonical | 正反兩順序的 UI 建立世界 SHA-256 相同 |
| 非法輸入 authority 拒絕 | 空白姓名、負年齡／小數／非數字、非法背景；失敗前後整個世界 canonical snapshot 相同 |
| 既有人口只實體化一人 | 聚落人口不變、named count +1、next sequence +1，全域不變量通過 |
| Production New Game 不可繞過 | 真正 main scene 起始無玩家、提早 entry 被擋、提交後仍無 shell、摘要確認才顯示 shell；provenance 為 CHARACTER_CREATION |
| 唯讀能力呈現 | 修改 projection 副本與開啟能力視窗不改世界 snapshot |
| 完整世界 replay | UI 建立 → travel → encounter receipt → save/load → confirm 的雙軌 SHA-256 相同，兩軌全域不變量通過 |

Replay SHA-256：`e654ac44223ac925ecbe0d108b23296ebfe1068485d7647ff5fffb9bd1f49264`。

以實際 OpenGL renderer 產生並檢查 `creation.png`、`summary.png`、`capabilities.png`（1280×720）及 `creation-small.png`（1152×648）。較小視窗的內容可捲動，主要提交按鈕保持可見；摘要與完整能力表各自可捲動。截圖腳本在同目錄 `capture.gd`。

注意：既有 PlayableShell 關閉時仍出現 CanvasItem / ObjectDB / texture / font RID 洩漏診斷；本輪通過代表功能 gate / exit 0，不代表 leak-free。未擴大到無關生命週期清理。

Memory milestone 由 canonical writer 寫入 daily / active-task-summary；`memory_workflow --check --repo . --run-guard` 無 blocking item。仍有 writer/guard 路徑 discovery 與 evidence provenance/metadata advisory，詳見 `artifacts/character-creation-ui/memory-check.log`；不宣稱治理告警全清。
