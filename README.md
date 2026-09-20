# Wasteland Chronicles (廢土編年史)

> 專案代號：`afterdust-rpg`  
> 核心目標：證明「**玩家不介入，世界也會自己發展；玩家介入後，世界會留下可觀察的後果**」這件事本身好不好玩。

---

## 核心公理 (Core Invariants)

1. **AI 絕不對世界狀態擁有權威 (AI must never be authoritative over world state)**  
   * **Simulation 是真相**：世界引擎產生結構化數值與事件。  
   * **AI 是表達**：LLM 僅做為下游觀察者與翻譯器，負責把世界狀態渲染為傳聞、酒館對白與敘事文本，絕不直接修改底層數值。
2. **決定論與可回放 (Deterministic & Replay)**  
   * 相同的 Seed 與相同的輸入指令序列，必須產生 100% 相同且位元一致的模擬結果。  
   * 嚴禁在模擬核心內呼叫全域隨機或系統時間。
3. **強型別領域模型 (Typed Runtime Model)**  
   * 執行期採用強型別資料類別 (`SettlementState`, `CaravanState`, `WorldState`) 與字串識別碼 (`StringName`) 進行關聯，禁止無型別的萬用字典 (Dictionary-of-Everything) 漫延。
   * 字典與 JSON 僅作為儲存存檔 (Save Snapshot) 與邊界傳輸使用。

---

## 目錄結構 (Directory Layout)

```text
wasteland-chronicles/
├── docs/               # 系統設計、架構規範、里程碑與驗收標準
│   ├── game-pillars.md # 遊戲核心設計支柱
│   ├── architecture.md # 系統架構、狀態分層、Tick 語意與規則
│   ├── milestones.md   # M0 至 M5 完整研發路線圖
│   └── m0-spec.md      # M0 基準模型技術規格與測試驗收標準
├── simulation/         # 核心世界模擬引擎 (純邏輯，無 UI 依賴)
├── game_data/          # 聚落、物品、派系靜態定義與初始種子設定
├── tests/              # 確定性回放、不變量驗證與因果測試套件
└── godot/              # Godot 4 專案 (P4 階段才導入視覺與地圖)
```

---

## 當前里程碑進度

- [x] **P0 / Architecture Skeleton**: 架構規範、狀態 Schema、Tick 語意與驗收標準鎖定。
- [ ] **M0-A**: 決定論經濟基線 (3 聚落 / 2 資源 / 1 商隊 / 30 天穩定運行)。
- [ ] **M0-B**: 外部供應衝擊 (Day 10 商隊摧毀測試，驗證短缺與價格湧現)。
- [ ] **M0-C**: 決定論回放驗證 (相同 Seed 雙重回放產出雜湊一致)。
- [ ] **M0-D**: 不變量測試套件 (數值非負、質量守恆、實體參照有效性)。

詳細設計與技術規格請見 [docs/](file:///d:/wasteland-chronicles/docs/)。
