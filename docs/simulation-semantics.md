# Simulation Day Semantics (世界時間與離散日生命週期權威定義)

本文件為《Wasteland Chronicles》所有子系統（物流、人口、生理、派系、情報傳播、任務計時）的**唯一權威時間與離散 Tick 語意規範**。所有程式碼實作、規格書與自動化測試必須嚴格遵守本定義，嚴禁出現 off-by-one 模糊空間。

---

## 1. 離散日生命週期 (The 8-Phase Day Lifecycle)

在模擬器中，每一「天（Day $N$）」被視為一個包含 8 個嚴格循序階段的封閉離散區間：

```text
[Day N 開始]
  │
  ├─ Phase 0: 日初重置與外部介入 (Start of Day & External Interventions)
  │   - 玩家介入、GM 指令、世界衝擊注入（如在 Day 30 切斷商路、Day 60 修復商路）。
  │   - 商隊於起點裝貨完畢、編隊就緒，於清晨啟程。
  │
  ├─ Phase 1: 聚落生存消耗 (Settlement Survival Consumption)
  │   - 人口基礎代謝，由庫存扣除今日飲用水與口糧需求（庫存不足則進入短缺狀態）。
  │
  ├─ Phase 2: 聚落在地生產 (Settlement Local Production)
  │   - 綠洲產水、農場產糧、廢墟開採廢料、油井開採燃料。
  │
  ├─ Phase 3: 市場價格重新結算 (Price Recalculation)
  │   - 各聚落根據今日生產與消耗後的剩餘庫存與目標儲備，重算供需報價。
  │
  ├─ Phase 4: 在途商隊物理推進 (Caravan Travel Progress)
  │   - 所有在途商隊在荒原上行進一天，剩餘天數遞減：
  │     days_remaining -= 1
  │
  ├─ Phase 5: 到站交割、卸貨與折返裝貨 (Arrival, Unload & Turnaround Loading)
  │   - 凡 days_remaining <= 0 之商隊於傍晚進城。
  │   - 貨物正式卸載入庫，更新目的地庫存，目的地物價隨之平緩下調。
  │   - 商隊重設折返目的地，匹配雙向需求裝載回程物資。
  │
  ├─ Phase 6: 不變量嚴格驗證 (Invariant Validation)
  │   - 驗證庫存非負、價格非負且有限、運力守恆，違者立即拋出例外阻斷。
  │
  ├─ Phase 7: 事件日誌持久化與日末結算 (Event Commit & End of Day)
  │   - 提交當日所有產生的事件紀錄至歷史日誌。
  │   - 日期推進至 Day N + 1。
  │
[Day N 結束]
```

---

## 2. 旅行天數與抵達日換算公式 (Travel Duration Semantics)

在日常語言中，「旅行 3 天」容易引起歧義（是經歷 3 次日落？還是在第 3 天的某個時刻？）。  
本模擬引擎確立以下唯一換算公式：

### 核心公式：
若一商隊（或未來之難民、信使、軍隊）在 **Day $N$ 清晨（Phase 0）** 出發，其路程耗時為 **$D$ 天（$D \ge 1$）**：

$$\text{Arrival Day} = N + D - 1$$

### 物理詮釋 (Day-by-Day Progression)：
以 **Day 60 清晨修復出發、路程 $D = 3$ 天** 為例：
* **Day 60**：清晨出發。當日經過 Phase 4 行進，`days_remaining` 自 $3 \to 2$。完成第 1 天旅行。未抵達。
* **Day 61**：在途行進。當日經過 Phase 4 行進，`days_remaining` 自 $2 \to 1$。完成第 2 天旅行。未抵達。
* **Day 62**：在途行進。當日經過 Phase 4 行進，`days_remaining` 自 $1 \to 0$。完成第 3 天旅行。
  * **在 Day 62 的 Phase 5（傍晚）進城交割入庫**。
  * 抵達當日即為 **Day 62**。

> **結論**：
> Day 60 出發、路程 3 天，其抵達時間為 **Day 62 傍晚**。
> 絕非 Day 63。在途實際消耗的完整日曆天數為：Day 60、Day 61、Day 62 共整整 3 天。

---

## 3. 快照與觀察時間點 (Observation & State Snapshot Timestamp)

* 任何測試或報告中記錄之「Day $N$ 聚落庫存與價格」，皆嚴格指代 **Day $N$ 經過 Phase 7 結算後（End of Day Snapshot）** 之世界終態。
* 因此：
  * **Day 60 終態**：灰谷尚未到貨，水庫存維持 $0$，水價維持封頂 $\$37.50$。
  * **Day 61 終態**：灰谷尚未到貨，水庫存維持 $0$，水價維持封頂 $\$37.50$。
  * **Day 62 終態**：首批水車於 Phase 5 卸貨入庫，水庫存自 $0 \to 23$，水價自 $\$37.50 \to \$31.03$。

---

## 4. 未來系統對齊指引 (Guidance for Future Slices)

後續所有擴展系統必須依循上述離散日生命週期：
1. **S3-A 人口代謝**：在 **Phase 1** 結算。
2. **S3-B 飢渴壓力累積**：若 Phase 1 發生短缺，在 Phase 1 末累積壓力值。
3. **S3-C 難民遷徙**：
   - 難民逃難隊伍視同在途旅行實體，耗時 $D$ 天，遵循 $\text{Arrival Day} = N + D - 1$ 公式，於抵達日的 Phase 5 併入新聚落人口。
4. **S7 情報衰退**：在 Phase 7 進行衰減。
