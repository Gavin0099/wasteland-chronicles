# Slice 3 (S3) Specification: Human Ecology

本規格書定義《Wasteland Chronicles》**S3 人類生態（Human Ecology）** 的分階段架構與第一子階段 **S3-A — Population Metabolism（人口基礎代謝）** 的實作規格。

---

## 1. 人類生態五部曲架構 (The 5-Stage Human Ecology Roadmap)

在 S0~S2 中，聚落的資源消耗為寫死的常數（Hard-coded Constants）。  
S3 的核心使命是：**「讓人類生存需求成為宏觀經濟的真正驅動力；短缺不再只是價格數字變動，而是引發壓力、逃難、人口重組與荒原危險的連鎖生態反應。」**

```text
S3-A: Population Metabolism (人口基礎代謝)
  └─ 人口規模決定每日水與糧食需求。
  │
S3-B: Deprivation & Stress (短缺壓力)
  └─ 短缺不立即死亡，而是積累 Shortage Stress。
  │
S3-C: Refugee Migration (難民逃難遷徙)
  └─ 壓力過高引發外移，難民歷經實體旅行抵達鄰近聚落，轉移生存壓力。
  │
S3-D: Mortality & Economic Decay (衰亡與勞力崩潰)
  └─ 極限狀態下發生死亡，勞動力衰減摧毀在地生產力（如灰谷廢料產量崩跌）。
  │
S3-E: Security & Raider Dynamics (荒原掠奪者生態)
  └─ 道路荒廢與聚落衰退引發掠奪活動，威脅物流生命線。
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

### 2.2 資料模型擴充 (Data Model Extensions)

#### `SettlementState` 新增欄位：
* `population: int`：聚落目前常住人口總數（$\ge 0$）。
* `metabolism_water_rate: float`：人均每日耗水量（單位：Water / 人 / 日）。
* `metabolism_food_rate: float`：人均每日耗糧量（單位：Food / 人 / 日）。

#### 動態需求推導公式 (Phase 1 執行)：
在世界生命週期 **Phase 1 (Settlement Survival Consumption)** 開始時，依據當前人口動態計算今日生存消耗：

$$\text{Daily Water Demand} = \text{max}\Big(1, \text{round}\big(\text{population} \times \text{metabolism\_water\_rate}\big)\Big)$$

$$\text{Daily Food Demand} = \text{max}\Big(1, \text{round}\big(\text{population} \times \text{metabolism\_food\_rate}\big)\Big)$$

---

### 2.3 初始數值校準 (Baseline Calibration for S1/S2 Compatibility)

為保證 S3-A 引入後，不影響既有 S1 百日穩定性與 S2 衝擊數值因果，初始人口與人均代謝率必須精確等價於 S1 初始消耗：

| 聚落名稱 | 初始人口 ($P_0$) | 人均水代謝率 | 每日耗水 ($\lfloor P \times r_w \rceil$) | 人均糧代謝率 | 每日耗糧 ($\lfloor P \times r_f \rceil$) | 廢料維護 | 燃料維護 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **新希望 (New Hope)** | 120 | 0.050 | **6** | 0.03333... | **4** | 4 | 2 |
| **灰谷 (Gray Valley)** | 100 | 0.050 | **5** | 0.040 | **4** | 4 | 2 |
| **乾井 (Dry Well)**   | 80  | 0.050 | **4** | 0.050 | **4** | 2 | 3 |

> **說明**：
> 在人口恆定為 $P_0$ 時，各聚落的水/糧每日扣除額完全等於 S1 的數值 $(6, 4), (5, 4), (4, 4)$。  
> 這保證了在人口尚未變動前，S1 與 S2 的所有測試與經濟行為保持 100% 回歸相容。

---

### 2.4 S3-A 嚴格非目標 (Out of Scope for S3-A)

遵守 **G1 治理第二公理（No Future-Slice Implementation）**：
* ❌ **嚴禁在 S3-A 實作死亡**：庫存為 0 時，人口不減少（留待 S3-D）。
* ❌ **嚴禁在 S3-A 實作難民**：不產生逃難隊伍（留待 S3-C）。
* ❌ **嚴禁在 S3-A 實作壓力**：不引入 Shortage Stress 變數（留待 S3-B）。
* ❌ **嚴禁在 S3-A 實作人口自然出生/繁殖**。

---

## 3. S3-A 驗收標準 (Acceptance Gates)

1. **Gate 1: 動態推導響應 (Dynamic Scaling Gate)**：
   - 撰寫單元測試：手動將灰谷人口自 100 調降至 60，當日耗水量必須精確自 5 降至 3；調升至 160 時，耗水升至 8。
2. **Gate 2: S1 百日迴歸等價性 (S1 100-Day Regression Gate)**：
   - 在人口保持預設基準下，運行 100 天，所有商品範圍、物流交割次數與 Invariants 必須與 S1 基準一致。
3. **Gate 3: 不變量有效性 (Invariants Gate)**：
   - 擴充 `validate_invariants()`：驗證所有聚落 `population >= 0` 且代謝率為非負有限浮點數。
4. **Gate 4: 決定論回放 (Determinism Gate)**：
   - 100 天世界狀態快照 SHA-256 具備 100% 決定論重現性。
