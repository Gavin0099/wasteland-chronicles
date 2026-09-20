# C0/C1 — Headless Implementation Record

權威契約：`s5-c0-c1-contract.md` 已由 Owner 宣告 COMPLETE / FROZEN FOR IMPLEMENTATION。角色系統方向不再重議；本文件記錄後續實作，與契約狀態分開。

## 交付範圍

| 項目 | 狀態與證據 |
| --- | --- |
| Encounter Result UX | IMPLEMENTED / TESTED / COMMITTED_LOCAL，`e18b88e`；未 push |
| Character Progression Foundation | OWNER DIRECTION LOCKED |
| C0/C1 authority contract | COMPLETE / FROZEN；不是功能完成宣告 |
| C0-P0 | Owner 已明確核准四組 mapping；CLOSED |
| C1-P0 | raw `2` 成功、`2.0`／`2e0` 失敗；世界 float codec 不變；CLOSED |
| C1-A | 本機實作：十技能 domain、profile schema、validators |
| C1-B | 本機實作：persistence、顯式 migration、skill-only eligibility |
| C0-A | 本機實作：版本 1 Background catalogue |
| C0-B | 本機實作：headless CharacterCreationIntent 驗證 |
| C0-C | 本機實作：原子 materialization、player binding |
| 創角 UI | NOT STARTED；現有遊戲啟動流程未改為創角畫面 |
| C2 / XP / Level / Perk / Equipment / Combat / Legacy | NOT IMPLEMENTED，本輪未新增 |

本份 headless 實作獨立提交；尚未 push。沒有將 S5-C0／C1 整體標成 CLOSED；headless 驗收與玩家畫面分開記錄。

## 實作邊界

- `PlayerState.capability` 是唯一的玩家能力資料 owner；NpcProfile 的 Background／Trait／Aptitude metadata 不複製成第二個能力容器。
- `CapabilityProfile` 提供完整 profile 驗證、rank 查詢、AND 門檻判斷與 defensive copies。非法查詢回傳 error；有效但不滿足回傳 `met=false`。不提供 XP 或技能成長 mutator。
- World snapshot 的 `progression_schema_version=1` 區分現代資料與 pre-C1 migration。僅無版本且整份 capability 欄位不存在的合法舊檔，建立全零 ranks、空 Core 與 LEGACY_MIGRATION；新版部分缺欄位／未知版本不降級。
- 既有舊版 `materialize_player` 啟動／測試入口保留原行為，附上全零的 legacy-compatible capability；不把舊背景偷偷配成新 package。新 package 只由 `commit_character_creation` 明確啟用。
- 新創角要求來源聚落、姓名、背景、Traits 及明確 age。Age 沿用現有非負整數身份資料，不隨機產生。初始物資仍由既有 materialize_player 規則提供。
- 創角驗證後在私有 world copy 呼叫既有 materialization；所有 profile／世界不變量通過，才一次發布受影響的 registries、序號、player 與帳本。聚落、人口、物資、天數不變，失敗不消耗 ID。
- Legacy biography 在舊 loader canonicalize 之前驗證，避免非法／重複 metadata 被修正後誤當成合法來源。Migration 不產生虛構遊戲事件，載入結果有 `migrated` 回報；磁碟原檔不自動覆寫。
- Capability 與 snapshot 都保留人物關聯；新創角 provenance 的 background 必須和既有 profile 背景一致。

## 驗收對應

`tests/test_c0_c1_headless.gd` 使用 Owner 核准表的獨立 expected vectors，不呼叫 catalogue 反算預期值。

| Gates | 執行內容 |
| --- | --- |
| C0-1 / C0-4 | 每背景創角人口守恆、一個單調 ID；非法字段、缺匿名槽、第二 player 拒絕後全世界 hash 不變 |
| C0-2 / C0-3 | 四組 2/1/1 向量；Traits 不改 rank；全部 distinct pairs 合法，重複／未知／超量拒絕；順序置換 canonical 相同 |
| C0-5 | 舊 Background／Traits／TECHNICAL Aptitude 保留，新 ranks 全零；損毀 metadata 拒絕；migration 冪等且不改舊世界其他資料 |
| C1-1 / C1-2 | 十技能 keys、int 0～5、非法 rank；AND、空集合、等於邊界、順序置換、false-prefix 後的非法條件仍拒絕 |
| C1-3 | 新 schema raw JSON 型別、profile 固定點、world copy；已流失 token 的浮點 Dictionary 拒絕；缺字段／未知版本拒絕 |
| C1-4 | 創角 → 旅行 → encounter choice → result → save/load → confirmation 的雙軌 canonical SHA-256 一致 |
| C1-5 | 只改 skills／Core Traits 的對照世界，原遭遇／旅行／資源與帳本仍一致；新資料未授予世界效果 |

完整回歸結果及命令輸出：`artifacts/c0-c1-headless/results.json` 與相鄰 logs。既有 UI harness 的退出資源洩漏診斷仍存在；此輪無創角 UI／視覺變更，沒有聲稱修復那些診斷。
