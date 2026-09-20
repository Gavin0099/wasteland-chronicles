# Slice 2 (S2) Specification: Fragile World & Counterfactual Evidence

本規格書定義 S2 脆弱世界切片中，單一供應鏈衝擊的注入方式、反事實雙軌比較假說以及因果驗證標準。

---

## 1. 外部衝擊協議 (S2-A Single Supply Shock Protocol)

* **衝擊注入時間**：世界時間 **Day 30** 結束後。
* **目標實體**：商隊 `caravan:c_hope_gray`（負責「新希望 $\longleftrightarrow$ 灰谷」之生命線車隊）。
* **衝擊效果**：
  1. `caravan.is_destroyed = true`，`caravan.is_active = false`。
  2. 車隊當時所承載之貨物全數銷毀，絕不外洩至任何聚落庫存。
  3. 自 Day 31 起，該商隊永久停止前進，新希望與灰谷之間的主幹道物流完全中斷。
* **限制**：**嚴禁引入任何自動補償、走私客、難民遷徙或人口死亡機制**。世界僅在裸露的經濟與物流物理層面進行自我演化。

---

## 2. 因果演化假說 (Causal Hypotheses)

反事實雙軌實驗：
* **World A (Baseline)**：S1 活體經濟網在無任何干涉下持續運轉至 Day 100。
* **World B (Counterfactual Shock)**：在 Day 30 摧毀 `c_hope_gray`，觀察至 Day 100。

### 2.1 因果方向 (Causal Direction)
* **灰谷 (Gray Valley)**：
  * 水資源補給歸零，每日淨虧損 $5$ 單位水，庫存單調歸零。
  * 糧食補給銳減，每日淨虧損 $2$ 單位糧，庫存單調歸零。
  * 稀缺度（Scarcity Ratio）單調上升至 $100\%$，水價與糧價單調飆升至最高上限 $P_{\max}$。
  * 廢料（Scrap）無法輸出給新希望，廢料庫存急速積壓。
* **新希望 (New Hope)**：
  * 水與糧食失去灰谷出口通路，本地積壓率上升。
  * 失去灰谷之廢料補給，本地廢料庫存逐步滑落。

### 2.2 影響局部性 (Locality)
* **乾井 (Dry Well)** 與其相關之商路 (`c_hope_dry`, `c_gray_dry`) 未直接遭到襲擊。
* 乾井在 Day 30 後數十天內仍維持相對正常之燃料輸出與水糧輸入，證明衝擊具備局域性，不引發全地圖無差別瞬間崩潰。

### 2.3 傳導延遲性 (Latency / No Teleportation)
* 價格不是在 Day 30 瞬間跳空至漲停（Teleport）。
* 價格嚴格依照每日消耗所造成的庫存赤字擴大，以連續平滑的曲線遞增。

---

## 3. 反事實驗證指標與驗收標準 (S2-B Acceptance Criteria)

### Criteria 1: 決定論驗證 (Determinism)
同一初始狀態並於 Day 30 注入相同衝擊，兩次獨立運行至 Day 100 的狀態 JSON SHA-256 必須 **100% 完全相同**。

### Criteria 2: 貨物守恆與隔離 (Cargo Conservation & Isolation)
被摧毀時商隊貨物歸零，目的地與起點聚落庫存皆不產生非法的幽靈突增。

### Criteria 3: 無幽靈抵達 (No Phantom Arrivals)
Day 31 ~ Day 100 期間，灰谷與新希望之間由 `c_hope_gray` 產生的交割次數必須嚴格為 **0**。

### Criteria 4: 因果差分可解釋性 (Explainable Counterfactual Delta)
自動輸出 Day 20（衝擊前）、Day 30（衝擊點）、Day 40、50、60、80、100 之 $\Delta \text{Stock}$ 與 $\Delta \text{Price}$ 表格：
$$\Delta \text{Stock}(d) = \text{Stock}_{\text{Shock}}(d) - \text{Stock}_{\text{Base}}(d)$$
$$\Delta \text{Price}(d) = \text{Price}_{\text{Shock}}(d) - \text{Price}_{\text{Base}}(d)$$
證明所有數值偏差皆能由「失去該商隊」唯一合法因果所解釋。

---

## 4. S2-E 修復力規格 (Post-restoration Recovery Protocol)

S2-E 探討核心問題：**「既有經濟系統被打斷後，只把原本的路修回去，世界能否自己復原？」**

### 4.1 核心修復原則 (Restoration Principle)
> **公理**：**`Repair 本身不是供應；Repair 只是重新允許物流發生。`**  
> 在 Day 60 日初宣布修復商路時，嚴禁直接向灰谷灌入物資或手動重設價格。商隊必須自新希望重新裝貨，依循離散日語意（$\text{Arrival Day} = 60 + 3 - 1 = 62$）經歷完整的 3 天旅行天數，首批水車於 **Day 62 傍晚** 抵達進城，第一批水才能正式入庫。

### 4.2 三世界對照模型 (Three-World Counterfactual Model)
持續模擬至 **Day 120**，橫向比對三條平行歷史：
1. **World A (Baseline 正常世界)**：120 天無任何干涉。
2. **World B (Permanent Shock 壞掉的世界)**：Day 30 切斷 `c_hope_gray`，永不修復。
3. **World C (Post-restoration Recovery 壞掉後被修好的世界)**：Day 30 切斷，Day 60 修復重啟。

### 4.3 嚴格區分 Hard Gates 與 Observations

#### [Hard Gates] 必須全數通過，否則視為測試失敗：
1. **無幽靈抵達**：Day 60 與 Day 61 當日絕無交割事件（需歷經 Day 60、61、62 整整 3 天路程，首批到貨嚴格於 Day 62 發生）。
2. **修路不瞬間補貨**：Day 60 當日結束時灰谷水庫存依然為 0，水價依然封頂。
3. **首批到貨實質入庫**：第一批貨物於 Day 62 抵達，灰谷水庫存正式自 0 向上躍升。
4. **價格隨稀缺緩跌**：水價僅在實際到貨（Day 62）後才隨庫存回補而逐步退燒，非因修路指令而降。
5. **積壓廢料開始出清**：商隊回程開始載運灰谷積壓之 Scrap 返回新希望。
6. **全期不變量與決定論回放**：120 天內 Invariants 全數成立，World C 兩次運行 SHA-256 雜湊完全一致。

#### [Observations] 屬於客觀實證記錄，不判錯、不擅自調參（遵守 G1 第 8 條公理）：
* **恢復耗時 (Days to Normalcy)**：從 Day 60 恢復，需要多少天才能讓水庫存與價格重返常態波動區間？
* **價格過衝現象 (Price Overshoot)**：在水庫存見底期間積累的高價，是否隨到貨迅速收斂，還是維持遲滯？
* **廢料出清速度 (Backlog Drainage Rate)**：灰谷積壓至 500+ 的廢料，每趟被運走多少？
* **路徑依賴與恢復延遲 (Path-dependence / Recovery Lag Observed; Persistent Hysteresis Not Yet Established)**：
  到 Day 120 時，World C 廢料為 432，相較 World A（391）仍有 $\Delta = +41$ 的歷史殘留差值。此現象證明存在物流恢復延遲與暫態路徑依賴；但是否構成永久滯後（Persistent Hysteresis），須待更長天數（如 Day 240+）進一步檢驗，目前不宜過度斷言為永久創傷。
