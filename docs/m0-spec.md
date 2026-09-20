# Milestone 0 (M0) Specification: Headless Economic Baseline

本規格書定義 M0 里程碑中世界模擬的初始數值、運算公式、離散步驟與驗收標準（Acceptance Criteria）。

---

## 1. 實體初始配置 (Initial World Setup)

M0 世界僅存在 3 個聚落與 1 台往返商隊，無玩家介入。

### 1.1 聚落設定 (Settlements)

| 聚落 ID | 名稱 | 定位 | 水 (初始/產出/消耗/目標) | 食物 (初始/產出/消耗/目標) | 基礎水價 | 基礎糧價 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `settlement:new_hope` | 新希望 | 綠洲產水基地 | 120 / +15 / -5 / 100 | 80 / +6 / -6 / 80 | $10.0 | $12.0 |
| `settlement:gray_valley`| 灰谷 | 缺水礦鎮 (淨消耗) | 80 / +0 / -5 / 80 | 100 / +10 / -8 / 100 | $15.0 | $10.0 |
| `settlement:dry_well` | 乾井 | 中繼哨站 (自給自足)| 50 / +5 / -5 / 50 | 50 / +5 / -5 / 50 | $12.0 | $12.0 |

> **說明**：
> * **灰谷** 每天淨消耗 $5$ 單位水，本身不產水，與商隊每 6 天往返運送 30 單位水達成動態平衡（$6 \times 5 = 30$）。
> * **新希望** 每天淨剩餘 $+10$ 單位水，做為供水來源。
> * **乾井** 在 M0 作為獨立自給自足控制組（Control Group），供需平衡，價格常態保持穩定在 $12.0。

### 1.2 商隊設定 (Caravan `c1`)

* **ID**: `caravan:c1`
* **名稱**: 「新希望一號水車」
* **起點**: `settlement:new_hope`
* **終點**: `settlement:gray_valley`
* **單程旅行天數**: $3$ 天（往返一個週期共 $6$ 天）
* **運載容量與內容**: $30$ 單位水（每次從起點裝載 30 水，送往灰谷卸下；返回時空車或載運等值貨款，M0 簡化為專職運水）
* **初始狀態**: Day 1 出發，剩餘航行天數 $= 3$。

---

## 2. 核心公式 (Formulas)

### 2.1 市場定價公式 (Pricing Formula)
每個聚落每日根據自身庫存與目標庫存的匱乏度計算即時價格。

設：
* $P_{\text{base}}$：基準價格 (Base Price)
* $S$：當前庫存量 (Current Stock, $S \ge 0$)
* $T$：目標安全庫存 (Target Stock, $T > 0$)
* $k$：價格彈性係數，M0 定為 $1.5$
* $P_{\min} = 0.2 \times P_{\text{base}}$
* $P_{\max} = 5.0 \times P_{\text{base}}$

計算公式：
$$P = \text{clamp}\left( P_{\text{base}} \times \left(1.0 + k \times \frac{T - S}{T}\right), P_{\min}, P_{\max} \right)$$

#### 行為範例（灰谷水價，基準價 $15.0$、目標 $80$）：
* 當庫存充沛 ($S = 80$)：$P = 15.0 \times (1 + 0) = 15.0$
* 當庫存稍微盈餘 ($S = 100$)：$P = 15.0 \times (1 - 0.375) = 9.375$
* 當庫存短缺至半數 ($S = 40$)：$P = 15.0 \times (1 + 0.75) = 26.25$
* 當庫存枯竭 ($S = 0$)：$P = 15.0 \times (1 + 1.5) = 37.5$（達最高上限時由 $P_{\max} = 75.0$ 保護）

---

## 3. 每日 Tick 執行流程 (Daily Tick Execution)

每次呼叫 `world.tick()` 時，必須依照以下嚴格順序執行：

```text
Step 1: 各聚落結算生產 (Production)
        settlement.inventory.water += settlement.production.water
        settlement.inventory.food  += settlement.production.food

Step 2: 各聚落結算消耗 (Consumption)
        settlement.inventory.water = max(0, settlement.inventory.water - settlement.consumption.water)
        settlement.inventory.food  = max(0, settlement.inventory.food  - settlement.consumption.food)

Step 3: 各聚落重新計算市場報價 (Market Re-pricing)
        update_price(settlement, "water")
        update_price(settlement, "food")

Step 4: 商隊移動推進 (Caravan Movement)
        for caravan in active_caravans:
            if not caravan.is_destroyed:
                caravan.travel_days_remaining -= 1

Step 5: 商隊抵達與裝卸貨 (Arrival & Trading)
        for caravan in active_caravans:
            if caravan.travel_days_remaining <= 0:
                resolve_caravan_arrival(caravan)

Step 6: 外部衝擊掛鉤 (External Shock Hook)
        trigger_scheduled_shocks(world.current_day)

Step 7: 世界不變量檢查與歷史紀錄 (Invariants & History)
        assert_world_invariants(world)
        log_daily_snapshot(world)
        world.current_day += 1
```

### 3.1 商隊折返邏輯 (`resolve_caravan_arrival`)
當 `travel_days_remaining <= 0`：
1. 抵達 `destination_id`：
   * 卸貨：`destination.inventory.water += caravan.cargo.water`
   * 清空商隊負載：`caravan.cargo.water = 0`
2. 啟動返程或新航程：
   * 交換起訖點：`temp = origin; origin = destination; destination = temp`
   * 若新起點有能力裝貨（如回到新希望）：從起點庫存扣除 30 水，裝入商隊。
   * 重置旅行時間：`travel_days_remaining = travel_days_total` (3 天)。

---

## 4. 驗收標準 (Acceptance Criteria)

### M0-A：正常經濟基線 (Normal Baseline)
* **測試情境**：以 Seed `1337` 執行無干涉的 30 天模擬。
* **驗收標準**：
  1. 商隊在 Day 3 抵達灰谷，卸下 30 單位水；灰谷庫存回補，水價回落。
  2. 商隊在 Day 6 返回新希望，裝載 30 單位水並再次出發。
  3. 30 天內，灰谷水庫存維持在安全範圍內（未曾跌至 0）。
  4. 控制組乾井庫存維持 50，價格完全持平在 12.0。

### M0-B：外部供應衝擊 (Supply Shock)
* **測試情境**：在 Day 10 執行外部衝擊事件：`caravan:c1.is_destroyed = true`（模擬商隊遭黑犬幫擊毀）。
* **驗收標準**：
  1. Day 10 後，商隊不再移動，灰谷不再收到任何水資源補給。
  2. 灰谷庫存隨每日固定消耗 (-8) 單調下降，約在 Day 17 ~ Day 18 歸零。
  3. 灰谷水價隨庫存枯竭持續上漲，最終達到上限 $P_{\max}$。
  4. 乾井與新希望未受直接衝擊（驗證隔離性）。

### M0-C：決定論與可回放性 (Determinism & Replay)
* **測試情境**：
  * Run 1：輸入種子 `1337`，執行 30 天，導出 Day 30 狀態 JSON。
  * Run 2：輸入種子 `1337`，執行 30 天，導出 Day 30 狀態 JSON。
* **驗收標準**：
  * 兩次產出的 JSON 字串與 SHA-256 雜湊值 **100% 完全相同**。

### M0-D：不變量測試套件 (Invariant Suite)
每個 Tick 結束後自動驗證以下斷言：
1. **非負性**：所有聚落庫存 $\ge 0$。
2. **正價格**：所有商品當前價格 $> 0$。
3. **質量守恆 (Conservation of Cargo)**：在正常流轉中，起點扣除的貨物必等於商隊新增的貨物；商隊卸下的貨物必等於目的地增加的貨物（除明確銷毀外，物質不憑空創生或消失）。
4. **死亡實體隔離**：`is_destroyed == true` 的商隊，其 `travel_days_remaining` 絕不可繼續減少，亦不可觸發任何貨物交易。
