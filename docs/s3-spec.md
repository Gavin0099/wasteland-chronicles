# Slice 3 (S3) Specification: Human Ecology

本規格書定義《Wasteland Chronicles》**S3 人類生態（Human Ecology）** 的分階段架構與第一子階段 **S3-A — Population Metabolism（人口基礎代謝）** 的實作規格與驗收紀錄。

---

## 1. 人類生態六部曲架構 (The 6-Stage Human Ecology Roadmap)

在 S0~S2 中，聚落的資源消耗為寫死的常數（Hard-coded Constants）。  
S3 的核心使命是：**「讓人類生存需求成為宏觀經濟的真正驅動力；短缺不再只是價格數字變動，而是引發壓力、逃難、人口重組與荒原危險的連鎖生態反應。」**

```text
S3-A: Population Metabolism (人口基礎代謝) [CLOSED ✅]
  └─ 問題：人口是不是經濟需求真正的來源？
  └─ 成果：引入 population、water_rate、food_rate，廢除 hard-coded 消耗，通過 100 天 Shadow Run。
  │
S3-B: Basic Needs Pressure (生理匱乏壓力) [NEXT 🟡]
  └─ 問題：缺水、缺糧能不能形成壓力，而不是瞬間死人？
  └─ 機制：引入 water_pressure、food_pressure（0 -> 100 累積），先不死人。
  │
S3-C: Migration (難民逃難遷徙) [PLANNED ⏳]
  └─ 問題：人會不會因為環境變差而離開？
  └─ 機制：壓力過高引發外移，難民歷經實體旅行抵達鄰近聚落，災難跨聚落轉移。
  │
S3-D: Mortality (極限生理死亡) [PLANNED ⏳]
  └─ 問題：什麼情況下人才真的會死亡？
  └─ 機制：長期嚴重匱乏且無法遷徙時才觸發死亡，非 water == 0 立即抹殺。
  │
S3-E: Labor (勞動力反饋) [PLANNED ⏳]
  └─ 問題：人口下降會不會反過來影響生產？
  └─ 機制：population 決定聚落可用勞動力，勞力下降連帶重挫工業廢料/燃料產出。
  │
S3-F: Security Pressure (治安與掠奪威脅) [PLANNED ⏳]
  └─ 問題：聚落變弱後，危險是否自然增加？
  └─ 機制：引入 security 與 instability 壓制度，道路荒廢，掠奪危險自然湧現。
```

---

## 2. S3-A 專屬技術規格 (Population Metabolism Spec)

### 2.1 需求本質拆分 (Biological vs. Industrial Demand)
資源需求嚴格區分為兩大範疇：
1. **生物生理消耗 (Biological Survival Consumption - Water & Food)**：
   - 消耗主體為「活生生的人類居民（`population`）」。
   - 每日消耗量由聚落當前人口規模與基礎人均代謝率動態推導。
2. **工業設施維護 (Industrial Facility Maintenance - Scrap & Fuel)**：
   - 消耗主體為聚落重工業設施與機械發電機。
   - S3-A 維持聚落基礎維護需求（未來可依勞動力開工率調節）。

---

### 2.2 資料模型與架構不變量 (Data Model & Architectural Invariant)

#### `SettlementState` 欄位：
* `population: int`：聚落目前常住人口總數（$\ge 0$）。
* `metabolism_water_rate: float`：人均每日耗水量（單位：Water / 人 / 日）。
* `metabolism_food_rate: float`：人均每日耗糧量（單位：Food / 人 / 日）。
* `maintenance_scrap: int`：設施每日基礎廢料維護消耗。
* `maintenance_fuel: int`：設施每日基礎燃料維護消耗。

#### 架構不變量 (Architectural Invariant)：
> **`Resource demand MUST NOT depend directly on settlement identity.`**  
> 嚴禁在引擎或聚落類別中出現 `if settlement.id == "gray_valley"` 特判，需求一律由人口與代謝率動態推導：

$$\text{Daily Water Demand} = \text{max}\Big(0, \text{round}\big(\text{population} \times \text{metabolism\_water\_rate}\big)\Big)$$

$$\text{Daily Food Demand} = \text{max}\Big(0, \text{round}\big(\text{population} \times \text{metabolism\_food\_rate}\big)\Big)$$

---

### 2.3 初始數值校準 (Baseline Calibration for S1/S2 Compatibility)

| 聚落名稱 | 初始人口 ($P_0$) | 人均水代謝率 | 每日耗水 ($\lfloor P \times r_w \rceil$) | 人均糧代謝率 | 每日耗糧 ($\lfloor P \times r_f \rceil$) | 廢料維護 | 燃料維護 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **新希望 (New Hope)** | 120 | 0.050 | **6** | 0.03333... (1/30) | **4** | 4 | 2 |
| **灰谷 (Gray Valley)** | 100 | 0.050 | **5** | 0.040 | **4** | 4 | 2 |
| **乾井 (Dry Well)**   | 80  | 0.050 | **4** | 0.050 | **4** | 2 | 3 |

---

## 3. S3-A 驗收結果 (Acceptance Gates Record - ALL PASSED ✅)

全套自動化測試腳本：`tests/test_s3_metabolism.gd`

| Gate # | 驗收項目 | 驗收條件 | 結果 | 實測紀錄 |
| :---: | :--- | :--- | :---: | :--- |
| **A1** | **Legacy Consumption Equivalence** | 逐一比對三聚落動態推導消費額與 S1/S2 寫死常數完全一致，且通用聚落無特判 | **PASS** | 新希望 (6, 4), 灰谷 (5, 4), 乾井 (4, 4) 100% 精確吻合 |
| **A2** | **100-Day Shadow Run** | 同步運行 Legacy 世界與 Population 世界至 Day 100，經濟投影完全相同 | **PASS** | 庫存、價格、商隊位置、負載與事件 **100% Bitwise 一致** |
| **A3** | **Population Sensitivity (Up)** | 灰谷人口調升至 120 (+20%)：耗水增至 6，庫存消耗加速 | **PASS** | Day 40 水庫存自 21 降至 19，壓力自然湧現 |
| **A4** | **Population Sensitivity (Down)** | 灰谷人口調降至 80 (-20%)：耗水降至 4，耗糧降至 3，庫存壓力大幅舒緩 | **PASS** | Day 40 水庫存自 21 舒緩升至 85 |
| **A5** | **Determinism & Invariants** | 100 天決定論 SHA-256 雜湊回放一致，`population >= 0` 等不變量全期有效 | **PASS** | SHA-256: `94149bd36f756459328da4c7f4050abccc5bdf2d8e1098fb5884139863db4da5` |
| **A6** | **Full Regression Suite** | S0~S2 所有現有測試腳本全數 PASS | **PASS** | M0, Invariants, S1, S2-Shock, S2-Recovery 全部 Exit Code 0 |
