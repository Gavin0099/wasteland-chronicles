# Slice 3 (S3) Specification: Human Ecology

本規格書定義《Wasteland Chronicles》**S3 人類生態（Human Ecology）** 的分階段架構，以及已完成之 **S3-A（人口基礎代謝）** 與 **S3-B（生理匱乏壓力）** 技術規格與驗收紀錄。

---

## 1. 人類生態六部曲架構 (The 6-Stage Human Ecology Roadmap)

在 S0~S2 中，聚落的資源消耗為寫死的常數（Hard-coded Constants）。  
S3 的核心使命是：**「讓人類生存需求成為宏觀經濟的真正驅動力；短缺不再只是價格數字變動，而是引發壓力、逃難、人口重組與荒原危險的連鎖生態反應。」**

```text
S3-A: Population Metabolism (人口基礎代謝) [CLOSED ✅]
  └─ 問題：人口是不是經濟需求真正的來源？
  └─ 成果：引入 population、water_rate、food_rate，廢除 hard-coded 消耗，通過 100 天 Shadow Run。
  │
S3-B: Basic Needs Pressure (生理匱乏壓力) [CLOSED ✅]
  └─ 問題：當人口實際拿不到足夠的水／食物時，這種短缺能不能累積成持續的人道壓力？
  └─ 成果：會計記帳 requested = fulfilled + unmet；零庫存無偽壓力；物理到貨始恢復；Shadow Non-Interference 通過。
  │
S3-C: Refugee Migration (難民逃難遷徙) [NEXT 🟡]
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

## 2. S3-A 專屬技術規格 (Population Metabolism Spec - CLOSED ✅)

### 2.1 需求本質拆分與動態推導
* 生理需求公式：
  $$\text{Daily Water Demand} = \text{max}\Big(0, \text{round}\big(\text{population} \times \text{metabolism\_water\_rate}\big)\Big)$$
  $$\text{Daily Food Demand} = \text{max}\Big(0, \text{round}\big(\text{population} \times \text{metabolism\_food\_rate}\big)\Big)$$
* 架構不變量：`Resource demand MUST NOT depend directly on settlement identity.`（無聚落特判）。

### 2.2 初始數值校準
* **新希望**：人口 120，水代謝率 0.050 (6)，糧代謝率 1/30 (4)。
* **灰谷**：人口 100，水代謝率 0.050 (5)，糧代謝率 0.040 (4)。
* **乾井**：人口 80，水代謝率 0.050 (4)，糧代謝率 0.050 (4)。

---

## 3. S3-B 專屬技術規格 (Basic Needs Pressure Spec - CLOSED ✅)

### 3.1 核心設計原則
1. **短缺源於未滿足需求，而非庫存歸零 (No False Pressure on stock = 0)**：
   - 消耗階段每日結算：$\text{requested} = \text{fulfilled} + \text{unmet}$。
   - 若當日庫存恰好耗盡，但全額滿足人口需求（`unmet == 0`），全員飲水解渴，**水壓力嚴格不得增加**。
2. **規則與狀態嚴格分離 (State != Rules)**：
   - 壓力變量為持久化狀態：`water_pressure`、`food_pressure`（0.0 ~ 100.0）。
   - 速率為模擬引擎通用規則常數：
     - `WATER_PRESSURE_GAIN_RATE = 25.0`, `WATER_PRESSURE_RECOVERY_RATE = 15.0`
     - `FOOD_PRESSURE_GAIN_RATE = 25.0`, `FOOD_PRESSURE_RECOVERY_RATE = 15.0`
   - 每日需求會計（`last_need_outcomes`）作為 Transient Tick Evidence，不汙染持久化世界狀態。
3. **零除數與無人聚落權威語意 (Zero Denominator Semantics)**：
   - 當 `population <= 0` 時，聚落無居民受苦，壓力嚴格歸零（`water_pressure = 0.0, food_pressure = 0.0`）。
   - 當 `requested == 0` 且 `population > 0` 時，`unmet = 0`，壓力按恢復率正常衰減，嚴禁發生除零。
4. **非權威性觀察層 (Shadow Non-Interference)**：
   - 壓力純為人道受苦狀態之觀測記錄，**嚴禁反向影響人口、生產力、價格、貿易或商隊行為**。

### 3.2 壓力演化公式
若 `requested > 0` 且 `unmet > 0`：
$$\text{pressure} = \min\left(100.0, \text{pressure} + \frac{\text{float}(unmet)}{\text{float}(requested)} \times \text{gain\_rate}\right)$$
若 `unmet == 0`：
$$\text{pressure} = \max\left(0.0, \text{pressure} - \text{recovery\_rate}\right)$$

---

## 4. S3-B 七大 Hard Gates 驗收成果 (`tests/test_s3_pressure.gd`)

| Gate # | 驗收項目 | 測試檢驗內容 | 實測結果 | 核心證明 |
| :---: | :--- | :--- | :---: | :--- |
| **B1** | **Demand Accounting** | 每一 tick 水糧記帳嚴格成立：`requested = fulfilled + unmet` 且非負 | **PASS** | 30 天全聚落全商品記帳無瑕疵。 |
| **B2** | **No False Pressure** | 庫存恰好等於今日消耗（耗盡後 stock = 0，但 unmet = 0）時壓力不得增加 | **PASS** | stock = 0, fulfilled = 100%, water_pressure = 0.0。 |
| **B3** | **Accumulation** | 衝擊切斷後，只要 `unmet > 0` 持續存在，壓力單調不減並封頂 100.0 | **PASS** | 灰谷 Day 30 (0.0) $\to$ Day 42 (15.0) $\to$ Day 46 (100.0)。 |
| **B4** | **Severity Sensitivity** | 比較 100% unmet 與 40% unmet 之單日壓力累積增量 | **PASS** | 100% unmet 單日增 25.0；40% unmet 單日增 10.0。 |
| **B5** | **Physical Recovery** | Day 60 修路當天不降壓力；唯有 Day 62 實體水車入庫、Day 63 喝到水後壓力才退燒 | **PASS** | Day 60 (100.0) $\to$ Day 62 (100.0) $\to$ Day 63 (85.0)。 |
| **B6** | **Shadow Non-Interference** | 雙軌世界（計算壓力 vs 強制清零壓力）100 天經濟投影完全一致 | **PASS** | 庫存、價格、商隊位置與貨物 **100% Bitwise 一致**。 |
| **B7** | **Determinism & Regression** | 100 天決定論 SHA-256 回放一致，且全套迴歸測試全數通過 | **PASS** | SHA-256: `e31c779...`；M0～S3-A 測試全部 Exit Code 0。 |
