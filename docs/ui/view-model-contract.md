# ViewModel Contract Specification (UI Data Boundary)

本文件規範 **世界模擬真實 (Simulation Truth)** 與 **前端呈現模型 (Player ViewModel)** 之間的嚴格邊界。

---

## 1. 核心隔離原則 (Anti-Leak Rules)

```text
[ WorldState / SimulationEngine ]  <-- 擁有絕對客觀真相 (含隱藏數據)
                │
                ▼ (嚴格過濾與認知投影)
     [ KnowledgeSystem ]           <-- 依據玩家位置、視野、已獲情報進行篩選
                │
                ▼ (產生純資料 ViewModel)
     [ PlayerViewModel ]           <-- 唯讀、無方法計算、僅包含玩家知曉之內容
                │
                ▼
         [ UI Layer ]              <-- 僅綁定 PlayerViewModel，無法接觸 WorldState
```

### 嚴格防洩漏清單 (Anti-Leak Checklist)
1. **隱藏毀損與殺手**：若商隊在無人目擊處遭擊毀，ViewModel 中商隊狀態只能是 `"missing"`（失聯），絕不可出現 `"destroyed"` 或 `attacker: "black_dogs"`。
2. **遠方聚落庫存隔離**：若玩家目前身處「灰谷」，「新希望」的庫存數據只能顯示最後一次造訪時的歷史快照，並標記為 `is_stale: true`，不可直接讀取當日世界實時庫存。
3. **無全知計算**：ViewModel 內的任何數值皆為純靜態純字串/數字，禁止在 UI 層直接呼叫 `world.get_real_price(...)`。

---

## 2. ViewModel 型別規格 (GDScript Schema)

### 2.1 訊號標籤模型 (SignalTagViewModel)
```gdscript
class_name SignalTagViewModel
extends RefCounted

# 標題與簡述
var subject: String = ""              # e.g. "💧 水價波動"
var headline: String = ""             # e.g. "+170% 急遽上漲"
var detail: String = ""               # e.g. "商隊已連續 4 天未入港"

# 認知維度 (正交拆分)
# freshness: "LIVE" | "RECENT" | "STALE"
var freshness: String = "LIVE"
# confidence: "CONFIRMED" | "SUSPECTED" | "RUMOR" | "DISPROVEN"
var confidence: String = "RUMOR"      
var observed_at: int = 1              # 觀測時的世界日 (e.g. Day 12)
var freshness_text: String = ""       # e.g. "即時" / "2 天前" / "未知"
var source_name: String = ""          # e.g. "灰谷市集公告板"

# 視覺語意引導
# "INFO" | "WARNING" | "CRITICAL" | "SUCCESS"
var severity: String = "INFO"         
```

### 2.2 聚落市場品項模型 (MarketItemViewModel)
```gdscript
class_name MarketItemViewModel
extends RefCounted

var item_id: StringName = &""
var display_name: String = ""         # e.g. "飲用水"
var icon_symbol: String = "💧"

# 價格與趨勢
var buy_price: float = 0.0            # 玩家買入價
var sell_price: float = 0.0           # 玩家賣出價
var price_trend: String = "STABLE"    # "UP" | "DOWN" | "STABLE"
var delta_percent_text: String = "0%" # e.g. "+170%"

# 在地庫存觀測
# 玩家在當地時顯示確切數量，不在當地或缺貨時顯示語意指標
var stock_display: String = ""        # e.g. "12 單位" 或 "告急 / 枯竭"
var is_critical_shortage: bool = false

# 關聯已知訊號
var signals: Array[SignalTagViewModel] = []
```

### 2.3 聚落總覽模型 (SettlementOverviewViewModel)
```gdscript
class_name SettlementOverviewViewModel
extends RefCounted

var settlement_id: StringName = &""
var settlement_name: String = ""      # e.g. "灰谷"
var controlling_faction: String = ""  # e.g. "拾荒者同盟"
var is_current_location: bool = false

# 生存指標 (在地即時或歷史舊聞)
var is_stale_data: bool = false
var last_visited_day_text: String = ""# e.g. "本日" 或 "5 天前情報"

# 警示列表
var active_warnings: Array[String] = [] # e.g. ["[ ⚠ 嚴重缺水 ]", "[ ⚠ 掠奪者活動增加 ]"]

# 關聯主要事件訊號
var recent_signals: Array[SignalTagViewModel] = []
```

### 2.4 世界地圖節點模型 (WorldMapNodeViewModel)
```gdscript
class_name WorldMapNodeViewModel
extends RefCounted

var node_id: StringName = &""
var display_name: String = ""
var is_visited: bool = false
var is_current_player_location: bool = false

# 連線與旅行消耗 (以當前玩家位置為基準推算)
var is_reachable: bool = false
var travel_days: int = 0
var required_water: int = 0
var required_food: int = 0
var route_danger_level: String = "LOW" # "LOW" | "MODERATE" | "EXTREME"

# 玩家已知之該地現況標籤
var known_status_tags: Array[String] = [] # e.g. ["高價收購水", "商隊終點"]
```
