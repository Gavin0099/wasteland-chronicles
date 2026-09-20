# System Architecture & Technical Guidelines

本規範定義 `wasteland-chronicles` 的系統分層、狀態管理、決定論控制以及編程準則。

---

## 1. 核心架構分層 (Architectural Layers)

```text
+-------------------------------------------------------------+
|               View Layer (P4 - Godot 2D / UI)               |
|      - Node Graph / Travel Map / Settlement HUD / Logs      |
+-------------------------------------------------------------+
                              ▲ (One-way read / Commands)
+-------------------------------------------------------------+
|           Narrative Expression Layer (P5 - LLM / AI)        |
|  - Strictly Read-Only Consumer of Structured Event Stream   |
|  - Translates (Truth/Observation) -> Wasteland Flavor Text  |
+-------------------------------------------------------------+
                              ▲ (Read-Only Event Listener)
+-------------------------------------------------------------+
|        Information & Knowledge Layer (P3 - Rumors / Fog)    |
|   - TruthEvent -> Observation -> Propagation -> Local Intel |
+-------------------------------------------------------------+
                              ▲
+-------------------------------------------------------------+
|           Player Agency Layer (P2 - Gameplay Loop)          |
|    - Travel, Market Trades, Combat Choices, Quest Action    |
+-------------------------------------------------------------+
                              ▲
+-------------------------------------------------------------+
|           Simulation Engine (P1 - The Source of Truth)      |
|    - Discrete Daily Tick                                    |
|    - Invariant Verification Engine                          |
|    - Deterministic RNG Stream                               |
+-------------------------------------------------------------+
                              ▲
+-------------------------------------------------------------+
|               Domain State Model (Typed Classes)            |
|       SettlementState / CaravanState / WorldState           |
|            (ID References, Strictly Serialized)             |
+-------------------------------------------------------------+
```

---

## 2. 核心架構鐵律 (Iron Rules)

### 規則 1：AI 絕不對世界狀態擁有權威 (AI Is Never Authoritative)
* **允許**：LLM 讀取 `{"event": "water_shortage", "settlement": "gray_valley", "severity": 3}`，生成一段路倒拾荒者的悲鳴日記。
* **嚴禁**：LLM 輸出決定「灰谷現在剩下 10 單位水」或「商隊遭到突襲而扣除 50 血」。所有狀態轉移、數值增減均由 `SimulationEngine` 的數學與規則邏輯計算。

### 規則 2：強型別領域模型，禁止以 Dictionary 作為內部 Domain Model
* 記憶體中的執行期實體必須是**具備強型別宣告的 GDScript 類別**（例如 `SettlementState`、`CaravanState`）。
* 禁止在模擬內部使用巢狀字典 `state["settlements"][id]["economy"]["water"]`，避免 schema drift 與欄位拼寫混亂。
* 只有在 **存檔持久化 (Save Game)**、**網路傳輸** 或 **輸入給測試斷言** 時，才透過各類別的 `to_dict()` / `from_dict()` 轉換為純資料字典。

### 規則 3：ID 化關聯，嚴禁物件指標互相參照
* 實體之間只保存 `StringName` 識別碼，例如 `origin_settlement_id: StringName = &"settlement:new_hope"`。
* 嚴禁在 `CaravanState` 中持有 `SettlementState` 的物件引用。
* 所有實體查詢必須透過 `WorldState` 的查找表進行：`world.get_settlement(id)`。

### 規則 4：嚴格隔離 RNG 實例，追求絕對決定論
* 嚴禁在模擬代碼中呼叫全域 `randi()`、`randf()`、`randi_range()` 或存取系統時鐘 `Time.get_unix_time_from_system()`。
* 所有隨機性必須由 `WorldState.rng`（型別為 `RandomNumberGenerator`）提供，且該實例由傳入的種子 (`seed: int`) 唯一初始化。

---

## 3. 領域模型結構規範 (Typed State Schema)

### 3.1 資源清單型別 (Resource Inventory)
```gdscript
class_name ResourceInventory
extends RefCounted

var water: int = 0
var food: int = 0

func to_dict() -> Dictionary:
    return {"water": water, "food": food}

static func from_dict(data: Dictionary) -> ResourceInventory:
    var inv := ResourceInventory.new()
    inv.water = int(data.get("water", 0))
    inv.food = int(data.get("food", 0))
    return inv
```

### 3.2 聚落狀態 (SettlementState) - *M0-A 規格*
```gdscript
class_name SettlementState
extends RefCounted

var id: StringName
var name: String

# 資源庫存
var inventory: ResourceInventory = ResourceInventory.new()

# 每日生產與消耗率 (固定常數，M0 不動人口)
var production: ResourceInventory = ResourceInventory.new()
var consumption: ResourceInventory = ResourceInventory.new()

# 市場參考基準與目前報價
var target_stock_water: int = 100
var target_stock_food: int = 100
var base_price_water: float = 10.0
var base_price_food: float = 10.0
var current_price_water: float = 10.0
var current_price_food: float = 10.0

func to_dict() -> Dictionary:
    return {
        "id": String(id),
        "name": name,
        "inventory": inventory.to_dict(),
        "production": production.to_dict(),
        "consumption": consumption.to_dict(),
        "target_stock_water": target_stock_water,
        "target_stock_food": target_stock_food,
        "base_price_water": base_price_water,
        "base_price_food": base_price_food,
        "current_price_water": current_price_water,
        "current_price_food": current_price_food
    }
```

### 3.3 商隊狀態 (CaravanState) - *M0-A 規格*
```gdscript
class_name CaravanState
extends RefCounted

var id: StringName
var name: String
var origin_id: StringName
var destination_id: StringName

var cargo: ResourceInventory = ResourceInventory.new()
var travel_days_total: int = 3
var travel_days_remaining: int = 3

var is_active: bool = true
var is_destroyed: bool = false

func to_dict() -> Dictionary:
    return {
        "id": String(id),
        "name": name,
        "origin_id": String(origin_id),
        "destination_id": String(destination_id),
        "cargo": cargo.to_dict(),
        "travel_days_total": travel_days_total,
        "travel_days_remaining": travel_days_remaining,
        "is_active": is_active,
        "is_destroyed": is_destroyed
    }
```

### 3.4 世界全域狀態 (WorldState)
```gdscript
class_name WorldState
extends RefCounted

var current_day: int = 1
var seed_value: int = 1337
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# 實體集合表 (Key: StringName)
var settlements: Dictionary = {} # Dictionary[StringName, SettlementState]
var caravans: Dictionary = {}    # Dictionary[StringName, CaravanState]

# 歷史事件流
var event_log: Array[Dictionary] = []
```

---

## 4. Tick 語意與離散執行序 (Tick Semantics)

每天的推進 (`tick()`) 必須嚴格按照以下七大階段依序執行，每個階段都有明確的職責與前後依賴關係：

```text
+-------------------------------------------------------------+
| Phase 1: Production                                         |
| 各聚落依自身產能增加 inventory 庫存                         |
+-------------------------------------------------------------+
                              ↓
+-------------------------------------------------------------+
| Phase 2: Consumption                                        |
| 各聚落依固定需求扣除 inventory（不足則降為 0，記錄赤字）    |
+-------------------------------------------------------------+
                              ↓
+-------------------------------------------------------------+
| Phase 3: Market Re-pricing                                  |
| 各聚落根據庫存與目標庫存比例，更新水與食物的 current_price   |
+-------------------------------------------------------------+
                              ↓
+-------------------------------------------------------------+
| Phase 4: Logistics & Movement                               |
| 商隊旅行天數推進 (travel_days_remaining - 1)                |
+-------------------------------------------------------------+
                              ↓
+-------------------------------------------------------------+
| Phase 5: Arrival & Unload                                   |
| 抵達目的地之商隊卸貨入庫，並結算折返或新航程任務            |
+-------------------------------------------------------------+
                              ↓
+-------------------------------------------------------------+
| Phase 6: External Shocks / Scheduled Events                 |
| 執行外部注入事件（如 M0-B 中的特定 Day 襲擊劫殺商隊）        |
+-------------------------------------------------------------+
                              ↓
+-------------------------------------------------------------+
| Phase 7: Invariant Verification & History Logging           |
| 執行世界不變量斷言（庫存 >= 0、價格 > 0 等），記錄當日日誌  |
+-------------------------------------------------------------+
```
