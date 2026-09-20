# AI Governance Framework (Level G1)

本文件定義 `wasteland-chronicles` 在工程開發、狀態管理與 AI 輔助協作中的最高約束準則。

---

## G1 核心治理八大公理 (Eight G1 Axioms)

### 1. 當前 Slice 即為唯一權威邊界 (Current Slice Is Authoritative Scope)
AI Agent 執行任務時，其變更範圍嚴格受限於當前推進之 Slice。嚴禁在未經授權的情況下跨越至後續 Slice。

### 2. 嚴禁提前實作未來系統 (No Future-Slice Implementation)
不允許在 S2 階段「順手」建立人口衰退、難民遷徙、戰鬥數值或 LLM 敘事層。各模組必須在所屬 Slice 到達時，以獨立且具備測試的規格正式引入。

### 3. 世界模擬狀態為唯一真相 (Simulation State Is Authoritative)
所有數值增減、物質流動、實體存亡皆由 `SimulationEngine` 之數學與規則邏輯計算。
> **公理**：`AI must never be authoritative over world state.`  
> AI 僅能作為下游觀察者將結構化 Event 轉化為敘事文本，絕無直接改寫 WorldState 變數之權限。

### 4. 規則變更必須依循明確規格 (Rule Changes Require Explicit Spec)
嚴禁因單一測試報錯而臨時、隨意修改底層定價或產銷公式。任何世界規則與經濟常數之調整，必須先同步更新對應的 `docs/sX-spec.md` 文檔。

### 5. 決定論不變性 (Deterministic Repeatability)
相同之初始狀態輸入加上相同之外部干涉指令，必須在任何環境下產生完全位元一致（Bitwise Identical）的狀態快照與 SHA-256 雜湊值。

### 6. 不變量持續有效 (Invariants Must Remain Valid)
無論施加何種外部衝擊或極端壓力，底層核心不變量（庫存非負、價格合法有界、實體參照有效、毀滅實體不行動）必須在每日 Tick 結束時持續維持成立。

### 7. 因果證據必須由反事實對比證明 (Baseline vs Counterfactual Evidence Required)
驗證一個事件或機制的影響時，必須採取「無介入基準組 (Baseline)」對比「施加介入組 (Counterfactual)」的雙軌運行比對，產出明確的 $\Delta \text{Stock}$ 與 $\Delta \text{Price}$ 數據，而非憑空斷言。

### 8. 發現異常不等於新增規則 (Uncertain Finding != New Game Rule)
當模擬中觀察到非預期的崩潰或極端狀態（例如灰谷在失去水路後永久枯竭）時：
* **嚴禁**：AI Agent 自作主張建立「緊急走私客」、「秘密水井」等人為作弊調節器（Stabilizers）來掩蓋問題。
* **標準流程**：
  $$\text{記錄客觀因果證據} \longrightarrow \text{呈報架構師/負責人 (Owner Decision)} \longrightarrow \text{決策是否保留此 Failure Mode 或正式立項設計合法機制}$$

### 9. 唯一時間語意公理 (Authoritative Temporal Semantics)
所有子系統、實體推進、狀態快照與事件日誌必須嚴格依循 [docs/simulation-semantics.md](file:///d:/wasteland-chronicles/docs/simulation-semantics.md) 所定義之 8 階段生命週期與離散日旅行計算公式：
$$\text{Arrival Day} = \text{Departure Day} + \text{Route Days} - 1$$
日初出發、耗時 $D$ 天的旅程，必然於第 $D$ 天日末（黃昏）抵達。嚴禁規格書、測試腳本與程式碼之間存在任何 off-by-one 模糊空間。

### 10. 角色數值系統層級邊界鎖 (Strict RPG Progression Layering Guard)
嚴禁在指定 Slice 之前提前實作或引入未定義的 RPG 數值、技能、經驗值或點數：
* **公理**：`No Attributes, Skills, XP, Point Allocation, Proficiencies, or Perks before their designated slice.`
* **強制鎖定次序**：
  * **S4-A ~ E**：NPC 身份、狀態、背景（Background）、特質（Trait）、潛能架構（Aptitude Schema）。**嚴禁在此時加入 XP、技能點數或戰鬥數值**。
  * **S5-A**：玩家化身（Avatar: Identity, Inventory, Location, Needs, Money, Reputation）。**無技能樹**。
  * **S5-B**：玩家動詞（Verbs: Travel, Trade, Scavenge, Talk, Fight, Repair, Escort）。
  * **S5-C**：核心屬性發現（Core Attributes: 從玩法動詞反推）。
  * **S5-D**：技能系統（Skills: 使用型成長 Use-based Growth）。
  * **S5-E**：角色創角與點數分配（Character Creation & Point Allocation）。
  * **S5-F ~ H**：同伴招募、隊伍生態與同伴關係（Companion Recruitment, Party Ecology & Relationships）。
  * **S5-I**：隊伍功能角色（Party Roles: Scout, Medic, Mechanic, Negotiator, Gunner）。
  * **S5-J**：專業專長（Proficiencies: 如柴油引擎修復、野戰手術）。
  * **S5-K**：特殊能力與專長（Perks / Special Abilities: 能開啟新玩法機制者）。

---

## G1.5 NPC 權威治理公理 (Level G1.5 Axioms)

自 S4 起，世界首次引入具名個體 NPC。為杜絕 AI Agent 在模擬中產生幻覺、人口不一致、實體分裂或敘事權限洩漏，正式確立以下六大治理公理（Axioms 11 ~ 16）：

### 11. 人口權威與子集公理 (Population Authority & Subset Invariant)
* **聚落人口 (`Settlement.population`) 是總人數的唯一權威真理。**
* 具名個體 NPC (`Named NPC Registry`) 是該聚落人口之「已具名識別子集（Identified Subset）」，絕非外加人口。
* **約束公式**：
  $$\text{named\_npcs\_alive\_at}(S) \le S.\text{population}$$
* **生命守恆全域不變量**：
  $$\sum_{S} S.\text{population} + \sum \text{refugees\_in\_transit} + \text{cumulative\_deaths} == \text{Initial Total Headcount}$$
  絕不因個體化追蹤而膨脹或憑空增減總人口。

### 12. 身份永久不可變公理 (Immutable Identity Axiom)
* NPC ID（例如 `npc:0000127`）一旦鑄造即終身永久固定，嚴禁重新生成。
* **身份與狀態嚴格解耦**：
  $$\text{Identity} \ne \text{Location} \ne \text{Occupation} \ne \text{Faction} \ne \text{Party Membership}$$
* 無論 NPC 搬遷聚落、變更職業、轉移陣營或加入玩家隊伍，其實體 ID 永不變更。

### 13. 原子化生命週期變更公理 (Atomic Lifecycle Commit Axiom)
* NPC 實體之狀態轉移（遷徙、傷亡、招募）必須跨以下三層原子性同時提交（Single Atomic Commit）：
  1. NPC 個體狀態（`location`, `alive` 等）
  2. 聚落總額度計數（`population`, `cumulative_deaths`）
  3. 結構化事件審計日誌（Structured Event Ledger）
* 嚴禁殘留懸空狀態（Dangling State）：不允許聚落人口已扣除但 NPC 仍留在原地的半提交狀態。

### 14. 封閉行為空間公理 (Closed Action Space Axiom)
* 自主決策 NPC 只能從當前 Slice 所顯式授權的合法行為集合中選取動作（例如 S4-F 之 `STAY`, `MIGRATE`, `WORK`, `JOIN_CARAVAN`, `LEAVE_JOB`）。
* **嚴禁行為發明**：NPC 不得執行世界規則尚未定義的行為（例如在未定義建造水廠前自主宣告「興建淨水廠」）。未授權行為強制 Fail-Closed 拒絕。

### 15. 結構化決策證據公理 (Structured Decision Evidence Axiom)
* NPC 自主決策不得記錄無邊界之 Chain-of-Thought，必須以精確的結構化 Evidence 模式留存審計軌跡：
  $$\text{Evidence} = \langle \text{Timestamp}, \text{NPC\_ID}, \text{Observed\_State}, \text{Eligible\_Actions}, \text{Selected\_Action}, \text{Rule\_Invoked}, \text{Resulting\_Mutation} \rangle$$
* 確保所有個體行為具備 100% 事後反查與決定論重播檢驗能力。

### 16. 世界狀態權威單向管線公理 (Zero World-State Authority for Narrative/LLM)
* LLM 與敘事生成層絕無直接修改世界狀態之權限。
* **系統管線嚴格單向流動**：
  $$\text{World State} \longrightarrow \text{NPC Decision Engine} \longrightarrow \text{Authorized Action} \longrightarrow \text{Simulation Commit} \longrightarrow \text{Narrative Layer}$$
* 敘事文本僅作為已提交模擬結果之下游投射；NPC 的心願與台詞不能反向倒推修改世界數值或實體位置。

---

## 治理框架分級路線圖 (AI Governance Cadence)

| 階段 | 治理等級 | 核心防護範疇 | 狀態 |
| :--- | :---: | :--- | :---: |
| **S0–S1** | **G0** | 基礎決定論與位元級可重複性 | ✅ |
| **S2–S3** | **G1** | 經濟衝擊反事實驗證、8 階段唯一時間語意、無土匪純客觀湧現 | ✅ |
| **S4-A～E** | **G1.5** | **NPC 權威防護：人口子集約束、不可變身份、原子化提交、單向敘事管線** | **ACTIVE 🟡** |
| **S4-F** | **G2-lite** | NPC 自主行為授權、閉環決策審計證據、動態行為邊界鎖 | 規劃中 |
| **S5** | **G2** | 玩家與隊伍行為授權、存檔重播驗證、可驗證的世界歷程 | 規劃中 |
| **S6** | **G2+** | 死亡繼承傳承、世界記憶跨代傳承不變量 | 規劃中 |
| **S7** | **G2.5** | 資訊迷霧 Fail-Closed 知識邊界防禦（防真相洩漏） | 規劃中 |
| **Narrative**| **G3** | LLM 輸出完整治理、幻覺偵測與世界真理斷言驗證 | 規劃中 |



