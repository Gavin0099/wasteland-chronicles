# NPC Authority Specification (Level G1.5 Governance)

本規格書定義 `wasteland-chronicles` 自 **S4 (Individual NPC Ecology)** 起，關於具名個體 NPC 之身份權威、人口隸屬關係、生命週期轉移與決策邊界的最高技術規範。

---

## 1. 核心治理背景與目標

在 S0 至 S3 階段，世界由純粹的宏觀數值驅動（如灰谷人口 100 人、新希望 120 人）。在 S3-D 中，我們確立了人口嚴格守恆公式：
$$\sum_{S} S.\text{population} + \sum \text{in\_transit} + \text{deaths} == 300$$

進入 S4 後，聚落中將首次浮現具名個體（Named Individuals）。若缺乏嚴格權威規範，AI Agent 極易引入以下系統性破壞：
1. **人口重疊膨脹**：將具名 NPC 當成額外生成的人數（$50 \text{ 人口} + 10 \text{ NPC} = 60$）。
2. **身份漂移與分裂**：同一個人在遷移、換工作或入隊後重新生成 ID，甚至同時在兩地行動。
3. **半原子化狀態懸空**：聚落人數扣除但 NPC 個體仍逗留在原地，或 NPC 死亡但聚落人數未同步扣減。
4. **規則外行為發明**：NPC 自主執行未經物理規則授權的動作（如「建造淨水廠」）。
5. **敘事權威倒置**：LLM 憑藉對話或劇情需求直接修改世界狀態與 NPC 位置。

**G1.5 NPC Authority 規範旨在在 S4-A 動工前將上述漏洞全面鎖死。**

---

## 2. 人口權威與子集模型 (Population Authority & Subset Invariant)

### 2.1 權威總人數 (Authoritative Headcount)
* **聚落的 `population` 欄位永遠是該聚落總人數的唯一權威真理（Ground Truth）。**
* **具名 NPC 是聚落總人口中的「已具名識別子集（Identified Subset）」**，並非附加人口。
* 任何未被具名註冊的人口，均屬於聚落中的「背景群體（Anonymous Cohort）」。

### 2.2 子集不變量 (Subset Invariant)
在任意時間點 $t$ 與任意聚落 $S$：
$$\text{named\_npcs\_alive}(S) \le S.\text{population}$$

* 當灰谷人口為 50 人，且具名註冊了 10 名 NPC 時，代表該 10 人生活在該 50 人之中，其餘 40 人為背景居民。
* 聚落總人數絕非 $50 + 10 = 60$。

### 2.3 全域生命守恆不變量 (Universal Conservation Invariant)
無論有多少比例的人口轉化為具名 NPC，S3-D 確立的全域生命守恆公式必須在每日日末維持嚴格成立：
$$\sum_{S \in \text{Settlements}} S.\text{population} + \sum_{R \in \text{Refugees}} R.\text{count} + \text{cumulative\_deaths} == \text{Initial World Population}$$

---

## 3. 身份永久不可變公理 (Immutable Identity Authority)

### 3.1 ID 鑄造與格式
* NPC ID 在首次生成或由背景人口具名化時鑄造，格式為唯一識別字串（如 `npc:0000127` 或 `npc:gray_valley_mara`）。
* **永久不可變性**：NPC ID 一旦鑄造，在該世界實例中**終身永久固定，嚴禁重新生成或改寫**。

### 3.2 身份解耦公理
個體身份嚴格獨立於其附屬屬性：
$$\text{Identity} \ne \text{Location} \ne \text{Occupation} \ne \text{Faction} \ne \text{Party Membership}$$

* **遷徙**：從灰谷搬到新希望，`location` 改變，`npc_id` 不變。
* **就業**：從「拾荒者」轉職為「商隊守衛」，`occupation` 改變，`npc_id` 不變。
* **派系**：從「中立居民」加入「黑犬幫」，`faction` 改變，`npc_id` 不變。
* **隊伍**：被玩家招募入隊或離隊，`party_id` 改變，`npc_id` 不變。

---

## 4. 原子化生命週期變更 (Atomic Lifecycle Transitions)

為杜絕狀態漂移與懸空指標，NPC 的任何生命週期重大變更必須跨越三層進行**單一原子化提交（Single Atomic Commit）**：
1. **個體實體層（NPC Entity State）**
2. **聚落總量層（Settlement Aggregate Count）**
3. **事件日誌層（Structured Event Ledger）**

### 4.1 遷徙原子轉移 (Atomic Migration)
當具名 NPC 隨難民潮或自主遷徙從聚落 $A$ 移往聚落 $B$：
```text
Begin Atomic Transaction:
  1. Origin Settlement (A):
     - population = population - 1
     - remove NPC from A's local roster
  2. NPC Entity:
     - transit_state = IN_TRANSIT (or location = B if instant teleport test)
  3. In-Transit Refugee Entity (if physical travel):
     - attached_npc_ids.append(npc_id)
     - refugee_count = refugee_count (conserved)
  4. Destination Settlement (B) (upon arrival):
     - population = population + 1
     - add NPC to B's local roster
     - NPC.location = B
  5. Event Ledger:
     - commit event: { "event": "NPC_MIGRATION", "npc_id": id, "from": A, "to": B }
End Transaction
```
若其中任何一步失敗，整體回滾；嚴禁出現「總人口移轉了但 NPC 遺留在原聚落」的非同步現象。

### 4.2 死亡原子結算 (Atomic Mortality)
當具名 NPC 因匱乏、衰老或事件死亡：
```text
Begin Atomic Transaction:
  1. NPC Entity:
     - alive = false
     - cause_of_death = cause
     - death_day = current_day
  2. Settlement (Location):
     - population = population - 1
     - remove from alive roster; record to graveyard registry
  3. World State:
     - cumulative_deaths = cumulative_deaths + 1
  4. Event Ledger:
     - commit event: { "event": "NPC_DEATH", "npc_id": id, "cause": cause }
End Transaction
```
**死者絕不復活**，且聚落總額與全域死亡數必須同步結算。

---

## 5. 封閉行為空間 (Closed Action Space Boundary)

自主決策 NPC 不是自由創作的智慧體，其行為受嚴格的狀態機與世界規則約束。

### 5.1 行為空間授權清單
在指定 Slice 開放前，未授權的行為強制屬於**非法行為（Unauthorized Action）**：

| 行為代號 | 所屬授權切片 | 說明與邊界 |
| :--- | :---: | :--- |
| `STAY` | S4-B | 留存原地，進行日常生存代謝 |
| `WORK` | S4-B | 在當前聚落就業槽位提供勞動力 |
| `LEAVE_JOB` | S4-B | 脫離當前就業槽位，轉為無業/待業狀態 |
| `JOIN_CARAVAN` | S4-F | 加入出發商隊擔任護衛/搬運工，進入物理旅行狀態 |
| `MIGRATE` | S4-F | 隨難民潮或個人依據壓力轉移聚落 |
| `JOIN_FACTION` | S4-F | 變更派系隸屬 |
| `TRADE_PERSONAL` | S4-F | 以個人庫存進行微量交易 |
| `BUILD_*` | **FORBIDDEN ❌** | 世界模擬尚無動態建造規則，嚴禁 NPC 自主造工廠/水井 |
| `ATTACK_*` | **FORBIDDEN ❌** | S5 戰鬥系統前，嚴禁 NPC 發動未經定義的戰術攻擊 |

### 5.2 拒絕原則 (Fail-Closed Enforcement)
若決策引擎或 AI 生成之指令不在當前已授權清單中，系統必須直接拋出 `ERR_UNAUTHORIZED_ACTION` 並拒絕執行，保留原狀態（Fallback to `STAY`）。

---

## 6. 結構化決策證據規範 (Structured Decision Evidence)

為確保 100% 可重現性與可解釋性，NPC 決策日誌**禁止記錄非結構化、無邊界的 Chain-of-Thought 自然語言**，而必須以統一 Schema 記錄客觀因果證據。

### 6.1 決策證據 Schema (Evidence Record)
```json
{
  "timestamp": {
    "day": 45,
    "phase": "PHASE_1_NEEDS"
  },
  "npc_id": "npc:gray_valley_mara",
  "observed_state": {
    "home_settlement": "settlement:gray_valley",
    "home_water_pressure": 82.5,
    "home_security": 24.0,
    "candidate_destinations": [
      { "id": "settlement:new_hope", "water_pressure": 0.0, "security": 100.0 }
    ]
  },
  "eligible_actions": ["STAY", "MIGRATE"],
  "selected_action": "MIGRATE",
  "rule_invoked": "RULE_REFUGEE_DESPERATION_MIGRATION",
  "resulting_mutation": {
    "type": "NPC_MIGRATION_INITIATED",
    "origin": "settlement:gray_valley",
    "destination": "settlement:new_hope"
  }
}
```
透過此結構，架構師與測試腳本能以純粹數學比對驗證決策因果，避免任何「猜測 AI 意圖」的模糊性。

---

## 7. 世界狀態權威單向管線 (One-Way State Authority Pipeline)

### 7.1 系統架構流向
```text
+-------------------------+
|      World State        |  <-- 物理客觀真相 (SimulationEngine)
+-------------------------+
             |
             v
+-------------------------+
|   NPC Decision Engine   |  <-- 依據不變量與授權行為空間篩選
+-------------------------+
             |
             v
+-------------------------+
|    Structured Action    |  <-- 產出標準化 Action Data
+-------------------------+
             |
             v
+-------------------------+
|    Simulation Commit    |  <-- 原子性修改 WorldState 並寫入 Ledger
+-------------------------+
             |
             v
+-------------------------+
|     Narrative Layer     |  <-- LLM / 文本生成層 (純下游觀察者，0 權威)
+-------------------------+
```

### 7.2 LLM 權限隔離界線 (Zero State Authority)
* **LLM 可以做**：讀取已 Commit 的 `NPC_MIGRATION` 事件與 Evidence，生成生動的對話（如：「這鬼地方一滴水也沒有，我必須逃去新希望！」）。
* **LLM 絕對不能做**：
  - 在對話中宣告「我決定離開」後直接修改 `npc.location`。
  - 自行創造不在 WorldState 中的物品贈送給 NPC 或玩家。
  - 繞過 SimulationEngine 決定一個 NPC 的生死或派系歸屬。
