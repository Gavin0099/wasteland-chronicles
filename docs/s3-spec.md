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
S3-C: Refugee Migration (難民逃難遷徙) [CLOSED ✅]
  └─ 問題：人會不會因為環境變差而離開？
  └─ 成果：實體荒原在途旅行 (Axiom 9)、全域人口嚴格守恆、閉環需求漣漪效應、理智目的地理性湧現。
  │
S3-D: Mortality (極限生理死亡) [CLOSED ✅]
  └─ 問題：什麼情況下人才真的會死亡？
  └─ 成果：匱乏暴露等效日 (Exposure)、逃難優先於死亡、遷徙下限非永生特權、全域人類生命守恆、恢復即刻阻斷。
  │
S3-E: Labor (勞動力反饋) [NEXT 🟡]
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

---

## 5. S3-C 專屬技術規格 (Refugee Migration Spec - CLOSED ✅)

### 5.1 核心設計原則
1. **遷徙觸發與外移冷卻 (State != Rules)**：
   - 觸發閾值：$\max(\text{water\_pressure}, \text{food\_pressure}) \ge 60.0$。
   - 外移人數：$H = \max(1, \lfloor \text{population} \times 0.10 \rfloor)$。
   - 保底留存人口：$\text{MIN\_POPULATION} = 10$（低於 10 人停止外移）。
   - 外移冷卻：同一聚落每 3 天最多出發一次外移，避免微細碎片化。
2. **目的地理性客觀評估 (Rational Desirability Scoring)**：
   - 難民評分公式：
     $$\text{Score} = (\text{Net Survival Prod} \times 3.0) + (\text{Stock Ratio} \times 10.0) - (\text{Pressure} \times 2.0) - (\text{Route Days} \times 5.0)$$
   - 綠洲新希望（水源豐沛、淨水+8、無壓力）得分遠高於乾井（乾旱缺水、淨水-3）。灰谷難民自然湧向新希望。
3. **荒原旅行與時間語意 (Axiom 9 Compliance)**：
   - 難民隊以 `RefugeePartyState` 實體行進：
     $$\text{Arrival Day} = \text{Departure Day} + \text{Route Days} - 1$$
   - Day 44 出發、路程 3 天，嚴格於 Day 46 傍晚進城入籍。
4. **全域人類生命守恆 (Conservation of Human Life Invariant)**：
   - S3-C 階段無死亡（No Mortality），每一 Tick 嚴格守恆：
     $$\sum_{s \in \text{settlements}} s.\text{population} + \sum_{r \in \text{active\_refugees}} r.\text{headcount} \equiv \text{World Constant (300)}$$
5. **閉環需求漣漪效應 (Closed-Loop Demand Ripple)**：
   - 難民入籍新希望後，新希望人口增長 $\to$ 次日水需求增加 $\to$ 水盈餘縮減，危機以實體人類流動跨聚落轉移。

---

## 6. S3-C 七大 Hard Gates 驗收成果 (`tests/test_s3_migration.gd`)

| Gate # | 驗收項目 | 測試檢驗內容 | 實測結果 | 核心證明 |
| :---: | :--- | :--- | :---: | :--- |
| **C1** | **Conservation of Population** | 100 天中每一 Tick `settlements.pop + in_transit.headcount == 300` | **PASS** | 人口總量嚴格守恆，無人憑空消失或增生。 |
| **C2** | **Trigger Sensitivity & Cooldown** | 壓力未達 60.0 絕此外移；超標當日 (Day 44) 準確出發；冷卻期 (Day 45~46) 嚴格遵守；屆滿 (Day 47) 觸發第二波 | **PASS** | Day 43 人口 100、難民 0；Day 44 出發 10 人；Day 47 出發 9 人。 |
| **C3** | **Physical In-Transit Semantics** | Day 44 出發、路程 3 天，嚴格於 Day 46 傍晚抵達入籍 (44 + 3 - 1 = 46) | **PASS** | Day 44 剩餘 2 天 $\to$ Day 45 剩餘 1 天 $\to$ Day 46 抵達，新希望人口即刻達 130。 |
| **C4** | **Closed-Loop Demand Ripple** | 新希望人口增至 130，次日水需求自 6 升至 7 (+16.7%)；灰谷外移後水需求自 5 降至 4 | **PASS** | 需求動態響應人口變動，危機實質轉移至繁榮聚落。 |
| **C5** | **Rational Destination Selection** | 灰谷難民在綠洲新希望與乾井之間自主評估選擇 | **PASS** | 湧向水源充沛的新希望，避開缺水乾井。 |
| **C6** | **Invariant & Serialization** | 複製與序列化完全無損且確定 | **PASS** | `duplicate_state()` 與 `to_canonical_json()` 100% 一致。 |
| **C7** | **Determinism & Regression** | 100 天決定論 SHA-256 回放一致，且全套迴歸測試全數通過 | **PASS** | SHA-256: `e75dacb...`；S0～S3-B 測試全部 Exit Code 0。 |

---

## 7. S3-D 專屬技術規格 (Mortality Spec - CLOSED ✅)

### 7.1 核心設計原則
1. **匱乏暴露等效日 (Equivalent Full-Deprivation Days)**：
   - 拒絕 `water_pressure == 100` 即刻死人之飽和盲區。
   - 每日依未滿足比例累加暴露量：$\text{exposure} += \frac{\text{unmet}}{\text{requested}}$。
   - 當物資供應滿足（`unmet == 0`）時，暴露時長按每日 1.0 等效日退燒衰減。
2. **致命資格雙重門檻 (Double Threshold for Mortality Eligibility)**：
   - 生理死亡必須同時滿足：
     $$\text{daily\_unmet} > 0 \quad \text{AND} \quad \text{exposure} > \text{GRACE\_DAYS}$$
   - 斷水寬限期：`WATER_EXPOSURE_GRACE_DAYS = 6.0`。
   - 斷糧寬限期：`FOOD_EXPOSURE_GRACE_DAYS = 18.0`。
   - 當天 `unmet == 0` 時，致命資格立即解除，即使歷史暴露量仍高於寬限期，亦嚴禁死人。
3. **每日單一結算與多重死因 (Single Settlement with Causes)**：
   - 若水糧同時致命，當日僅結算一次死亡事件，並在事件載荷標註 `causes: ["water", "food"]`。
4. **逃難優先與基數確定性 (Migration First on Post-Migration Population)**：
   - 離散 Phase 1 順序：會計記帳 $\to$ 壓力累積 $\to$ 暴露累積 $\to$ 難民外移 $\to$ 極限生理死亡。
   - 死亡人數以**外移後留存人口 (Post-Migration Population)** 為計算基準：
     $$\text{deaths} = \min\left(\text{pop}, \max\left(1, \lfloor \text{pop} \times \text{MORTALITY\_BASE\_RATE} \rfloor\right)\right)$$
   - `MORTALITY_BASE_RATE = 0.05` 明確標記為原型調校參數（Prototype Tuning Parameter）。
5. **遷徙下限非永生特權 (Migration Floor $\neq$ Immortality Floor)**：
   - 聚落人口降至 $\le 10$ 時遷徙停止，但極限乾旱持續時，死亡機制允許人口進一步降至 0。
6. **全域人類生命守恆公理 (Global Conservation of Human Life)**：
   $$\sum_{s} s.\text{population} + \sum_{r} r.\text{headcount} + \sum_{s} s.\text{cumulative\_deaths} \equiv \text{TOTAL\_INITIAL\_POPULATION (300)}$$

---

## 8. S3-D 七大 Hard Gates 驗收成果 (`tests/test_s3_mortality.gd`)

| Gate # | 驗收項目 | 測試檢驗內容 | 實測結果 | 核心證明 |
| :---: | :--- | :--- | :---: | :--- |
| **D1** | **No Instant Death** | Day 42 首次水短缺（unmet > 0）當日，死亡人數嚴格為 0 | **PASS** | Exposure = 0.60, Cumulative Deaths = 0。 |
| **D2** | **Duration Matters** | 暴露量 $\le 6.0$ 寬限期內，死亡人數嚴格為 0 | **PASS** | Day 47 累積暴露 5.6，死亡人數保持為 0。 |
| **D3** | **Migration First** | Day 44 首波難民 10 人外移時，死亡人數為 0 | **PASS** | 能逃者先逃，逃難嚴格先於死亡。 |
| **D4** | **Floor Separation** | 灰谷人口跌破遷徙下限（10 人）後，死亡持續發生 | **PASS** | Day 100 灰谷留存 9 人，累積死亡 44 人。 |
| **D5** | **Conservation Invariant** | 100 天世界中每一 Tick，`living + transit + deaths == 300` | **PASS** | 300 人無一人憑空消失或增生。 |
| **D6** | **Immediate Recovery Stop** | Day 62 到貨、Day 63 喝到水後，死亡立即凍結 | **PASS** | Day 63 死亡人數 31，Day 100 仍為 31（到貨後零新死亡）。 |
| **D7** | **Determinism & Regression** | 100 天決定論 SHA-256 回放一致，且全套迴歸測試全數通過 | **PASS** | SHA-256: `60d7103...`；M0～S3-D 測試全部 Exit Code 0。 |

---

## 9. Slice 3-E: Labor (勞動力反饋)

### 9.1 核心問題
> **「聚落人口下降後，原本依靠人力維持的產業是否會失去產能，並進一步反噬區域供應鏈？」**

### 9.2 關鍵架構決策 (Key Architectural Decisions)

1. **不對稱產能上限封頂 (Capacity Ceiling, Not Infinite Growth)**：
   - 模擬「工廠缺人所以產能下降」，而非「難民湧入工廠機台就自動變多」。
   - 勞動力因子公式：
     $$\text{labor\_factor} = \text{clamp}\left(\frac{\text{current\_population}}{\text{reference\_population}}, 0.0, 1.0\right)$$
   - 當新希望接收難民人口增至 167 人（$> 120$）時，$\text{labor\_factor}$ 嚴格封頂於 1.0，絕不無端產生超額水糧而將難民負擔自我抵銷。
   - 當人口降至 0 時，$\text{labor\_factor} = 0.0$。

2. **按商品類別劃分勞動敏感度 (Labor Sensitivity by Commodity)**：
   - 絕不以聚落 ID 特判，嚴格依商品物理屬性劃分：
     * **工業品（高度依賴人力開採/精煉）**：
       - `scrap`: `sensitivity = 1.0`（灰谷廢料開採）
       - `fuel`: `sensitivity = 1.0`（乾井油田精煉）
     * **生存品（受自然湧水量與既有農地面積約束）**：
       - `water`: `sensitivity = 0.0`（綠洲地下水自然湧出）
       - `food`: `sensitivity = 0.0`（農田面積與技術暫未建模，先不因難民暴增產糧）
   - 有效產出公式：
     $$\text{effective\_factor} = 1.0 - \text{sensitivity} \times (1.0 - \text{labor\_factor})$$
     $$\text{effective\_production} = \text{base\_production} \times \text{effective\_factor}$$

3. **確定性小數產能累加器 (Deterministic Fractional Credit Accumulator)**：
   - 灰谷人口降至 9 人時，$\text{labor\_factor} = 0.09$，基礎產能 11 單位，每日產出為 $11 \times 0.09 = 0.99$。
   - 若使用整數截斷（`floor(0.99) = 0`），產能將永遠為 0，產生嚴重的離散取整失真。
   - 透過 `SettlementState.production_credits: Dictionary`：
     $$\text{credit} += \text{effective\_production}$$
     $$\text{to\_add} = \lfloor \text{credit} + 10^{-9} \rfloor$$
     $$\text{credit} = \max(0.0, \text{credit} - \text{to\_add})$$
     $$\text{inventory} += \text{to\_add}$$
   - 100 天精確累積 99 單位廢料，長期比例嚴格吻合且 100% 決定論位元級可重播。

4. **固定基準人口 (Fixed Reference Population)**：
   - `reference_population` 為聚落設定不變量（Configuration Invariant），記錄設施的額定全額勞動需求（灰谷 100、新希望 120、乾井 80）。
   - 人口下降或傷亡絕不動態下調 reference population。

### 9.3 驗收標準 (Hard Gates E1 ~ E7)

| Gate # | 項目 | 檢驗標準 | 結果 | 關鍵證據 |
| :---: | :--- | :--- | :---: | :--- |
| **E1** | **Baseline Equivalence** | 當 $\text{pop} == \text{ref\_pop}$ 時，全品項產出與無勞動力版本 100% 位元級相容 | **PASS** | 30 天常態運轉下，三聚落全品項庫存 100% 一致。 |
| **E2** | **Population Sensitivity** | 人口減半時，廢料產出精確減半 | **PASS** | 灰谷人口 50 時，10 天產出 55 廢料（基準為 110）。 |
| **E3** | **Capacity Ceiling** | 人口暴增至 200 時，產能嚴格維持基準上限，不得增加 | **PASS** | 新希望人口 200 時，10 天水糧產能嚴格為 140/90，無超額產出。 |
| **E4** | **Zero Population Collapse** | 人口降為 0 時，敏感商品產能歸 0 | **PASS** | 人口為 0 之廢棄聚落 10 天廢料產出嚴格為 0。 |
| **E5** | **Fractional Accumulator** | 小數產能長期精確累計且雙軌重跑決定論一致 | **PASS** | 殘存 9 人（0.99/日）100 天精確產出 99 廢料，重跑 SHA-256 吻合。 |
| **E6** | **Regional Ripple** | 比較 World B 勞動力開關：人口崩落反噬區域供應鏈 | **PASS** | Day 100 灰谷廢料庫存：無勞動力 557 vs 有勞動力 98（暴跌 -459 廢料），新希望廢料斷供降至 1。 |
| **E7** | **Full Regression Pass** | 全不變量檢驗通過，且 M0~S3-E 全 11 個測試套件全綠 | **PASS** | Invariants 嚴格維持，全套 11 測試套件 Exit Code 0。 |

---

## 10. Slice 3-F: Social Order & Route Predation (治安動態、在地損耗與商路掠奪)

### 10.1 核心問題
> **「當聚落人口崩落、水糧長期匱乏時，社會秩序是否會自然瓦解？衰退聚落與其周邊商路是否會自發湧現危險，進一步反噬物流與庫存？」**

### 10.2 關鍵架構決策與實作規範 (Level G1 Governance)

1. **治安劣化雙重動態 (Civic Capacity & Needs Desperation)**：
   - **公共秩序維繫力赤字（Civic Capacity Drag）**：
     $$\text{civic\_capacity\_ratio} = \text{clamp}\left(\frac{\text{population}}{\text{reference\_population}}, 0.0, 1.0\right)$$
     $$\text{civic\_capacity\_drag} = (1.0 - \text{civic\_capacity\_ratio}) \times 3.0$$
   - **生存短缺絕望感（Desperation Drag）**：
     $$\text{desperation\_drag} = \left(\frac{\max(\text{water\_pressure}, \text{food\_pressure})}{100.0}\right) \times 5.0$$
   - **自然恢復語意**：僅當 $\text{civic\_capacity\_ratio} \ge 0.8$ 且生存壓力為 0 時，治安以每日 +2.0 回升。
   - **核心洞見**：**物質恢復 $\neq$ 秩序恢復（Material Recovery $\neq$ Social Recovery）**。人口跌至 9 人的廢棄聚落，即使供水恢復，因缺乏足夠人口組織看守，治安仍維持崩潰狀態。

2. **因果時序與延遲性 (Phase Ordering Causal Latency)**：
   - Tick 開始時取得 `start_of_day_security` 快照，用於判定今日之在地秩序損耗與商路掠奪。
   - 今日的人口變動與需求短缺，於 Phase 5.5 結算產生明日生效之治安度。
   - 杜絕「早上死人、下午倉庫立刻遭竊、同日商隊在途立刻被搶」的超距瞬時傳導。

3. **在地秩序損耗 (Local Disorder Loss - Deterministic Fractional Accumulator)**：
   - 當 $\text{security} < 40.0$ 時，內部失序導致貴重物資（scrap、fuel）流失。
   - 採用 `disorder_loss_credits` 小數累加器，按 5% 嚴格確定性扣減，徹底消除整數盲區。
   - 發布事件：`EventRecord("DISORDER_LOSS")`。

4. **商路危險度推導與在途物流掠奪 (Route Risk & Transit Predation)**：
   - **純衍生危險度 (Stateless Derived Risk)**：
     $$\text{route\_risk} = \frac{(100.0 - \text{security}_{\text{origin}}) + (100.0 - \text{security}_{\text{dest}})}{2.0}$$
   - **每趟航程結算一次 (Once Per Leg)**：於抵達目的地進城前結算掠奪（損失 10% 貨物），避免隨航程天數累乘放大。
   - **中立實體守護**：無 NPC Bandit/Raider，僅記錄客觀現象 `EventRecord("TRANSIT_PREDATION", cause_class: "low_security")`。

### 10.3 驗收標準 (Hard Gates F1 ~ F7)

| Gate # | 項目 | 檢驗標準 | 結果 | 關鍵證據 |
| :---: | :--- | :--- | :---: | :--- |
| **F1** | **Baseline Stability** | 常態 30 天三聚落治安維持 100.0，無損耗無掠奪 | **PASS** | 30 天內治安 100.0，disorder loss = 0，transit predations = 0。 |
| **F2** | **Causal Degradation** | 灰谷遭遇乾旱與人口流失後，治安單調遞減破 40 | **PASS** | Day 30 100.0 $\to$ Day 41 100.0 $\to$ Day 50 87.9 $\to$ Day 60 27.5。 |
| **F3** | **Recovery Semantics** | 受控充足人口聚落平滑恢復；灰谷（9 人）物質恢復 $\neq$ 秩序恢復 | **PASS** | 受控聚落治安 60 $\to$ 70（+2.0/日）；灰谷供水恢復後治安維持 0.0。 |
| **F4** | **Local Disorder Loss** | 僅 Security < 40 觸發確定性 5% 損耗，健康聚落嚴格為 0 | **PASS** | 灰谷累積損耗 172 廢料、69 燃料；新希望與乾井損耗為 0。 |
| **F5** | **Derived Route Risk** | 商路危險度純函數推導，安全商路為 0，灰谷商路精確推導 | **PASS** | 新希望-乾井風險 0.0；灰谷-乾井風險 40.0。 |
| **F6** | **Transit Predation** | 每 leg 嚴格一次結算，安全商路 0 損失，危險商路依率扣減 | **PASS** | 新希望-乾井商隊 0 劫掠；灰谷-乾井商隊遭 14 次在途掠奪。 |
| **F7** | **Determinism & Invariants** | 雙軌回放 SHA-256 吻合，全 12 個測試套件全綠 | **PASS** | 全套 12 測試套件 Exit Code 0，SHA-256 位元級重播。 |




