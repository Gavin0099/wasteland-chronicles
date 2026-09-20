# NPC Authority Specification (Level G1.5-A Contract)

本規格書定義 `wasteland-chronicles` 自 **S4 (Individual NPC Ecology)** 起，關於具名個體 NPC 之身份權威、人口隸屬關係、生命週期轉移與決策邊界的契約公理與權威矩陣。

本文件為 **G1.5-A (Authority Contract)** 階段之規範，鎖定資料真理權限，供後續 S4-A / S4-B 實作遵循，並於 S4-A 引入 **G1.5-B (Runtime Enforcement)**。

---

## 1. 核心治理背景與目標

在 S0 至 S3 階段，世界由純粹的宏觀數值驅動（灰谷 100 人、新希望 120 人、乾井 80 人），生命總量維持嚴格守恆：
$$\sum_{S} S.\text{population} + \sum \text{in\_transit} + \text{deaths} == 300$$

進入 S4 後，聚落中將首次浮現具名個體（Named Individuals）。為杜絕 AI Agent 產生幻覺、人口不一致或狀態分裂，確立本權威規格。

---

## 2. 權威矩陣 (Authority Matrix)

當世界狀態發生變更時，依據下表裁定資料的唯一權威真理來源（Single Source of Truth）：

| 資料類別 | 唯一權威主體 (Authority) | 說明與邊界 |
| :--- | :--- | :--- |
| **世界總人口** | `Aggregate Simulation` | 全域守恆不變量，任何個體化操作絕不改變世界總額 |
| **聚落人口 (`population`)** | `SettlementState` | 聚落總人數之權威真理，具名 NPC 為其子集 |
| **NPC 身份 ID (`npc_id`)** | `NPC Registry` | 透過單調遞增序列鑄造，終身永久不可變 |
| **NPC 當前位置 (`location`)** | `Lifecycle Transaction` | 必須且僅能屬於唯一人口容器（Settlement / Transit / Party） |
| **NPC 存活狀態 (`alive`)** | `Lifecycle Transaction` | 生理真理；死亡後永久不可逆，移至墓地計入累積死亡 |
| **NPC 背景與特質** | `NPC Profile` | S4-C ~ D 實作，獨立 registry，不污染已鎖定之 `NpcIdentity`；為純傳記 metadata，於 S4-C 完全無行為授權與模擬效果，是否影響行為權限由 S4-F 裁定 |
| **NPC 自主決策** | `Decision Engine` | S4-F 引入，依據當前狀態從授權行為集中選取 |
| **行為授權 (Authorization)**| `Simulation Rules` | 當前 Slice 顯式許可之封閉行為集，未授權強制拒絕 |
| **已發生世界事實** | `Event Ledger` | 僅記錄**已成功提交**之事件，不記失敗之意圖 |
| **敘事文本與對話** | `Narrative Layer` | 純下游觀察者，**對世界狀態具備 0 修改權限** |
| **世界狀態修改權** | **Simulation Engine Only** | 唯一擁有狀態修改（Mutation）權限之主體 |

---

## 3. 人口權威與單一人口容器公理 (Population Membership)

### 3.1 實體化為「具名表徵」，非「人口增加」 (Materialization Is Representational, Not Demographic)
* 具名個體 NPC 不是憑空創造的新人類。
* 將無名人口具名化（Identity Materialization）本質為：**自既有人口總額中識別出具名子集**。
* **數學公理**：
  $$\text{Population}_{\text{before}} == \text{Population}_{\text{after}}$$
  $$\text{Anonymous}_{\text{after}} = \text{Population} - \text{Named}_{\text{after}}$$
  *例：灰谷 50 人，將 1 人具名為 Mara $\implies$ 灰谷仍為 50 人（1 具名 + 49 無名），世界總人數絕不變成 51。*

### 3.2 單一人口容器不變量 (Single Population Membership Invariant)
在任意模擬 Tick，**每一個存活的具名 NPC 必須且僅能屬於恰好一個人口容器（Authoritative Population Container）**：
$$\text{Container}(NPC) \in \{\text{SETTLEMENT}(S), \text{TRANSIT}(R), \text{PARTY}(P)\}$$

* **禁止雙重歸屬**：NPC 不得同時為灰谷居民又處於難民在途狀態。
* **禁止懸空遊離**：存活 NPC 不得不屬於任何容器而在世界中漂浮。
* **死亡歸宿**：當 `alive == false`，NPC 退出所有生活人口容器，其存在全額轉入世界與聚落之 `cumulative_deaths` 墓地審計紀錄中。

### 3.3 子集約束與全域守恆
在任意聚落 $S$：
$$\text{named\_npcs\_alive\_at}(S) \le S.\text{population}$$

全域日末結算公理：
$$\sum_{S} S.\text{population} + \sum_{R} R.\text{headcount} + \sum \text{party\_members} + \text{cumulative\_deaths} == \text{Initial World Population}$$

---

## 4. 決定論 ID 鑄造協定 (Deterministic ID Minting Protocol)

為確保世界在任何平台、任何時間重播均能維持 100% 位元級一致（Bitwise Replay Determinism）：
1. **嚴禁隨機數與時間戳**：禁止使用 `UUID.random()`、`Time.get_unix_time_from_system()`。
2. **單調遞增計數器**：在 `WorldState` 中維護 `next_npc_sequence: int`（初始為 1）。
3. **格式規範**：
   $$\text{npc\_id} = \text{"npc:"} + \text{pad\_zeros}(\text{next\_npc\_sequence}, 8)$$
   *例：`npc:00000001`, `npc:00000002`。*
4. **永久不復用**：即使該 NPC 死亡或刪除，該序號永久作廢，計數器僅單調遞增。
5. **納入快照**：`next_npc_sequence` 必須參與狀態序列化（`to_dict()` / `from_dict()`）與 SHA-256 雜湊。

### 4.1 身份解耦公理
$$\text{Identity} \ne \text{Location} \ne \text{Occupation} \ne \text{Faction} \ne \text{Party Membership}$$
搬遷、轉職、加入派系或被玩家招募，其 `npc_id` 終身固定不變。

---

## 5. 生命週期轉移：驗證後提交模式 (Validate-Before-Commit)

本架構不採用複雜的多階段交易與回滾機制（Rollback Machinery），而採用嚴謹的**前置條件驗證後原子提交（Validate-Before-Commit）**：

```text
    Intent to Mutate
           ↓
[ 1. Check Preconditions ]
   - NPC alive?
   - NPC in expected container?
   - Container capacity / population > 0?
   - Destination valid?
   - Action authorized by slice?
           ↓
   (Any check fails?) ──YES──> [ Reject & Abort ]
           ↓ NO                 - Mutate NOTHING
[ 2. Commit All Mutations ]     - State Hash Unchanged
   - Update individual state
   - Update aggregate container counts
           ↓
[ 3. Emit Event to Ledger ]
   - Append to World Event Log (Fact Committed)
```

### 5.1 事件帳本公理 (Event Ledger Truth)
* **世界事件帳本（World Event Ledger）僅記錄已成功提交之世界事實。**
* 失敗的嘗試或被拒絕的意圖，僅記入決策審計軌跡（Decision Audit Trail），絕不寫入世界事件帳本。

---

## 6. 行為空間分期授權 (Slice-Scoped Action Space)

自主行為空間隨 Slice 演進逐步解鎖，未授權行為強制 **Fail-Closed**：

| Slice | 開放之行為集合 (Authorized Action Space) |
| :--- | :--- |
| **S4-A** | `NONE`（僅純靜態身份資料建立，無自主行為） |
| **S4-B** | `NONE`（僅被動生命代謝與被動槽位就業，無主動決策） |
| **S4-C ~ E** | `NONE`（身份背景與特質定義；`get_authorized_actions()` 對所有背景一律回傳 `[]`，且嚴禁預先宣告 eligibility tags） |
| **S4-F** | `["STAY", "MIGRATE", "JOIN_CARAVAN", "LEAVE_JOB", "CHANGE_JOB"]` |
| **S5** | 開放玩家互動動詞 (`TALK`, `TRADE`, `RECRUIT`, `DISMISS`) |

**嚴禁行為**：任何未經規則定義之行為（如 `BUILD_FACILITY`, `MAGIC_HEAL`, `ATTACK`）在所有階段一律非法。

---

## 7. 結構化決策證據規範 (Decision Evidence Schema)

於 S4-F 正式啟用，記錄於個體審計軌跡中（非自然語言 CoT）：
```json
{
  "day": 45,
  "phase": "PHASE_1_NEEDS",
  "npc_id": "npc:00000001",
  "observed_state": {
    "container": "settlement:gray_valley",
    "water_pressure": 82.5,
    "security": 24.0
  },
  "eligible_actions": ["STAY", "MIGRATE"],
  "selected_action": "MIGRATE",
  "rule_invoked": "RULE_REFUGEE_DESPERATION_MIGRATION",
  "result": "COMMITTED",
  "mutation_event_ids": ["evt:1042"]
}
```

---

## 8. 單向下游敘事管線 (Strict Downstream Narrative Pipeline)

系統架構維持嚴格的單向因果流向：
$$\text{World State} \longrightarrow \text{Decision Engine} \longrightarrow \text{Simulation Commit} \longrightarrow \text{Event Ledger} \longrightarrow \text{Narrative Layer}$$

* **LLM 邊界鎖**：LLM 僅能讀取已發生之事件與狀態，將其轉化為對話與小說式報導。
* **零權限公理**：LLM 絕無修改世界狀態、瞬移 NPC、改寫死亡或增減資源之權限。
