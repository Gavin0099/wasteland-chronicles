# Wasteland Chronicles — UI/UX Roadmap & Specification (U0–U2)

> **最高架構不變量 (Authoritative Boundary Rule)**：  
> **`UI 永遠只能呈現 Player Knowledge，絕對不能偷看 Simulation Truth。`**  
> 資料流動是嚴格單向過濾的：  
> `Simulation Truth (真實世界) ──► Knowledge System (觀測與情報) ──► Player ViewModel (玩家知曉) ──► UI (呈現)`

---

## 1. UX Mission (使用者體驗使命)

讓玩家**「看懂這個世界正在發生什麼，以及為什麼」**，而非單純閱讀枯燥數值，亦不依賴滿地問號與驚嘆號任務標記。

---

## 2. 五大 UX 原則 (UX Principles)

1. **World First (世界優先)**  
   聚落生存狀況、資源庫存、價格走勢、商路安全、情報傳聞的優先級，高於個人屬性與立繪展示。
2. **Cause Before Number (因果先於數字)**  
   不單單展示「水價 $42 ↑」，必須提示誘發趨勢的訊號脈絡（如：商隊未抵達、旱災）。
3. **Knowledge Before Truth (認知先於真相 / 情報迷霧)**  
   UI 呈現的永遠是「玩家目前掌握的認知與情報狀態」，絕不把系統底層的客觀全知事實直接洩漏在畫面上。
4. **Low Friction (低操作阻力)**  
   核心高頻操作（旅行、查看市集、檢視傳聞、接取委託）點擊路徑嚴格控制在 2–3 層以內。
5. **No Quest-marker Dependency (去任務標記依賴)**  
   不靠傳統 RPG 的自動尋路驚嘆號。玩家在酒館與市場讀取「訊號」後，自己推論出哪裡有利可圖或哪裡需要救援。

---

## 3. 資訊層級 (Information Hierarchy)

```text
Level 1: Global Context (世界地圖 / 總覽)
         - 玩家當前所在聚落、鄰近節點連線、距離與旅行消耗、宏觀危險度

Level 2: Settlement Status (聚落總覽)
         - 聚落生存指針 (水/糧庫存警示)、安全等級、當前主要危機

Level 3: Operational Subsystems (聚落子系統)
         ├─ Market (物資買賣、價格變化、短缺程度)
         ├─ Intel (即時情報、傳聞流、過期資訊追蹤)
         ├─ Jobs (聚落因供需失衡湧現的高額委託)
         └─ People (關鍵人物、商人、流浪者)

Level 4: Transient Encounters (暫態遭遇)
         - 旅行途中遭遇 (危機決策、交涉、戰鬥操作)
```

---

## 4. 認知狀態模型與 SignalTag (Knowledge Model & SignalTag)

UI 中的情報與因果標籤必須以 `SignalTag` 統一規範，不允許 UI 直接顯示「真相」。

### 4.1 兩大獨立認知維度 (Freshness & Confidence)
SignalTag 嚴格拆分為「資料新鮮度」與「認知可信度」兩個正交維度，杜絕語意混淆：

* **資料新鮮度 (Freshness)**：
  * **`LIVE`**：當前親身處於該聚落/節點所獲得之即時數據。
  * **`RECENT`**：數日內尚有參考價值的近期動態。
  * **`STALE`**：時隔已久之過期歷史情報（如 5 天前離開新希望時的水價）。

* **認知可信度 (Confidence)**：
  * **`CONFIRMED`**：已有實體直接證據核實之事實（如親見殘骸或官方交易記錄）。
  * **`SUSPECTED`**：具備高關聯性推論但未經實證（如商隊逾期 4 天推測遇險）。
  * **`RUMOR`**：未經證實之道聽途說（酒館醉鬼傳言「東邊有掠奪者」）。
  * **`DISPROVEN`**：已被證實為假消息或已失效的情報。

### 4.2 SignalTag 資料欄位
```text
SignalTag
├── subject          # 主體 (如: "water_price", "caravan_c1")
├── value_change     # 變化值或描述 (如: "+170%", "missing_4_days")
├── observed_at      # 記錄時的世界日 (如: Day 14)
├── freshness        # 新鮮度 (LIVE | RECENT | STALE)
├── confidence       # 可信度 (CONFIRMED | SUSPECTED | RUMOR | DISPROVEN)
├── source           # 情報來源 (如: "gray_valley_market", "tavern_gossip", "wreckage_site")
└── knowledge_state  # 玩家認知狀態摘要
```

### 4.3 介面呈現對比範例
* ❌ **洩漏真相的錯誤 UI**：  
  `💧 水價 $42 ↑ (+170%) [原因：黑犬幫於舊公路摧毀商隊]`
* ✔ **忠於情報迷霧的正確 UI**：  
  `💧 水價 $42 ↑ (+170%)`  
  `[ ⚠ SUPPLY CRITICAL ]`  
  `[ ❓ SUSPECTED · 商隊已 4 天未抵達 · 來源：灰谷市場 ]`  
  若日後在公路上親自調查殘骸，才於 Intel 頁籤解鎖：  
  `[ ✓ CONFIRMED · 發現 C1 水車殘骸 · 來源：實地勘查 ]`

---

## 5. 核心畫面流轉架構 (Navigation Flow)

```text
       [ World Map ] ◄──────────────────────────────┐
             │                                      │
       Select Node                                  │
             │                                      │
             ▼                                      │
    [ Settlement Overview ]                         │
    ├── [ Market ] (交易/價格/短缺)                  │
    ├── [ Intel ]  (訊號/傳聞/世界動態)             │
    ├── [ Jobs ]   (湧現委託/懸賞)                  │
    └── [ People ] (對話/招募)                      │
             │                                      │
        Click Travel                                │
             │                                      │
             ▼                                      │
        [ Travel HUD ] (消耗糧水/里程推進)           │
             │                                      │
       Encounter Trigger?                           │
        ├── No  ────────────────────────────────────┼───► 抵達新聚落
        └── Yes                                     │
             ▼                                      │
       [ Encounter Screen ]                         │
        ├── Resolve by Speech/Trade ────────────────┘
        └── Resolve by Combat                       │
             ▼                                      │
       [ Combat Screen ] ───────────────────────────┘
```

---

## 6. 七大核心畫面定義 (Seven Core Screens)

1. **World Map (世界地圖)**：全域節點圖、連線距離、旅行物資消耗預估、路段已知情報。
2. **Settlement (聚落總覽)**：聚落生存儀表（水/糧現存量）、治安與管制派系、主要警報。
3. **Market (市場交易)**：商品清單、買賣價、價格波動趨勢（`↑/↓`）、在地物資短缺警報。
4. **Intel (情報傳聞總覽)**：按時間排序的 `SignalTag` 卡片流，標明來源、時效性與可信度。
5. **Jobs (動態機會板)**：非固定任務清單，而是由市場飢渴產生的即時委託（如高價急購飲用水）。
6. **Encounter (旅行遭遇)**：途中突發事件、危機描述、選擇分支（繞路/交涉/迎擊/投降）。
7. **Combat (戰鬥對抗)**：生存戰術決策、生命值、彈藥、掩體與撤退判斷。

---

## 7. 語意視覺規範 (Semantic Palette - Non-authoritative)

本階段嚴禁鎖死十六進位色碼（那是 U4 Visual Skill 的工作），僅定義語意視覺方針：

* **風格定位**：**Survivor PDA**（末日倖存者個人手持終端機）。
* **視覺基調**：冷峻、實用主義、高資訊密度、微細工業格線、低圓角。
* **語意色彩層級**：
  * **底色 (Base)**：深碳黑 (Charcoal)
  * **文字與邊框 (Fore)**：髒象牙白 (Dirty Ivory)
  * **警示與波動 (Warning / Trend)**：沉穩琥珀金 (Muted Amber)
  * **危機與致命 (Danger / Critical)**：鐵鏽紅 (Rust Red)
  * **已確認標記 (Confirmed)**：鈍青灰 (Dull Cyan/Slate)
* **嚴格禁止項 (Avoid List)**：
  * ❌ 禁止模仿 Fallout 的刺眼綠色大面積 CRT 與粗圓角外框。
  * ❌ 禁止賽博龐克高飽和霓虹光效。
  * ❌ 禁止重度污漬、血跡遮蔽文字導致可讀性受損。

---

## 8. 雙軌研發路線與同步點 (Workstream Sync Roadmap)

```text
[Simulation Track]                         [UX Track]
      M0-A (Baseline) ───────┐               U0–U2 (Specs & Wireframes)
                             │                       │
      M0-B (Shock)           │                       │
                             ├───────────────────────┘
      M0-C (Replay)          │
                             ▼
      M0-D (Invariants) ──► [Sync Point 1: U3 ViewModel Prototype]
                             (直接以 M0 真實資料餵入 UI Component)
                             │
      M1 (World Dynamics)    │
      (人口/難民/自發商隊)   │
                             ▼
                           [Sync Point 2: U4 Visual Skill & U5 Anchors]
                             (以成熟動態世界作為 Anchor 產圖基準)
```

---

## 9. Non-Goals (本階段非目標)

* 不使用 AI 產圖工具（Midjourney/DALL-E 等）生成介面 Mockup。
* 不在 Godot 中撰寫任何 Control 節點或 UI 場景。
* 不定死具體 CSS / Hex 色碼或像素級字體大小。
