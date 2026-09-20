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
    * **背景惰性推論（S4-C 落地）**：背景是傳記而非能力。嚴禁由背景推導現在式社會角色（`social_role`）或
      預先宣告 action eligibility tags（如 `MECHANIC → REPAIR`）——前者會與後續 occupation / party_role
      系統形成第二個權威，後者等同在 gameplay 動詞誕生前搶先定義 S4-F 的能力語意。
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

自 S4 起，世界首次引入具名個體 NPC。為杜絕 AI Agent 在模擬中產生幻覺、人口不一致、實體分裂或敘事權限洩漏，G1.5 劃分為兩階段落地：
- **G1.5-A (Authority Contract)**：S4 前鎖死資料真理邊界、契約規範與 Schema 驗收。
- **G1.5-B (Runtime Enforcement)**：自 S4-A/B 隨 NPC 運行實體誕生而實行代碼級強制約束。

### 11. 人口權威與單一容器公理 (Population Authority & Single Membership Invariant)
* **聚落人口 (`Settlement.population`) 是總人數的唯一權威真理。**
* **具名化是表徵識別，非人口增長 (Materialization Is Representational, Not Demographic)**：將人口具名化絕不增加世界總人口（$50 \text{ 人口} \to 1 \text{ 具名} + 49 \text{ 背景} = 50 \text{ 總額}$）。
* **單一人口容器不變量 (Single Population Membership)**：每個存活的具名 NPC 在任一 Tick **必須且僅能屬於恰好一個人口容器**（Settlement / Transit / Party），嚴禁同時存在於兩處，亦嚴禁成為無歸屬之遊離個體。
* **約束公式**：
  $$\text{named\_npcs\_alive\_at}(S) \le S.\text{population}$$
* **生命守恆全域不變量**：
  $$\sum_{S} S.\text{population} + \sum \text{refugees\_in\_transit} + \text{cumulative\_deaths} == \text{Initial Total Headcount}$$

### 11.1 歷史事實權威公理 (Committed Event Ledger Authority Axiom)
* **Committed Event Ledger is the sole authority for persisted historical facts.**
  已提交之事件帳本是持久化歷史事實的唯一權威。世界「發生過什麼」只能由帳本本身回答。
* **Derived metadata must never reconstruct missing authoritative history.**
  衍生 metadata 絕不得用以重建缺失的權威歷史。`event_count` 是由帳本推導的便利輸出，
  載入時只可用於對帳（`event_count == len(events)`），**永不得據以推斷世界發生過幾件事**。
* **權威方向嚴格單向**：
  $$\text{Committed Events} \longrightarrow \text{Serialized Ledger} \longrightarrow \text{Loaded Events}$$
  嚴禁反向：`event_count → inferred historical state`。
* **Fail-Closed 整份拒絕**：帳本不可信之快照**整份拒絕載入**，不截斷至 count、不補齊至 count、
  不退回空帳本。一個安靜載入成「從未發生任何事」的世界，比一個拒絕載入的世界更危險——
  前者會說謊，後者只是停下來。
* **序列化不動點要求**：帳本必須滿足 save → load → save 恆等。若持久化格式會改寫數值形態，
  則必須在**提交當下**正規化，使記憶體形態與持久化形態一致；否則每次存讀都在重寫歷史。

### 11.2 持久化邊界透明性公理 (Persistence Boundary Transparency Axiom)
* **Save / Load 必須是 simulation 的透明邊界。**中斷後續跑的世界，與從未中斷的世界，
  在同一天必須得到完全相同的 authoritative state——存讀不得造成時間分叉。
* **型別權威來自 schema，不來自序列化後的值。**還原時嚴禁由序列化值反推 domain type
  （看到 `3.0` 就猜它是 int）。以臆測覆寫 domain 真相，比原本的序列化缺陷更危險。
* **正規化發生在狀態提交點，不發生在存檔時。**
  $$\text{calculate} \longrightarrow \text{canonicalize} \longrightarrow \text{commit authoritative state} \longrightarrow \text{save}$$
  若於存檔時才修飾數值，runtime world 與 persisted world 將成為兩套真相。
  Save 的職責只是**忠實記錄**權威狀態。
* **不合法之數值表徵 Fail-Closed**：違反 domain 宣告之數值（型別不符、`NaN`、`Inf`）
  一律拒絕載入，嚴禁靜默轉型後照常運行。

### 12. 決定論身份永久不可變公理 (Immutable Deterministic Identity Axiom)
* NPC ID 必須依據世界狀態中單調遞增之計數器（`next_npc_sequence`）確定性鑄造（如 `npc:00000001`）。嚴禁隨機數或時間戳。
* 序號納入快照，且**永久不可復用**（NPC 死亡亦作廢不重發）。
* **身份與狀態嚴格解耦**：
  $$\text{Identity} \ne \text{Location} \ne \text{Occupation} \ne \text{Faction} \ne \text{Party Membership}$$
* 無論 NPC 搬遷聚落、變更職業、轉移陣營或加入玩家隊伍，其實體 ID 永不變更。

### 13. 驗證後原子提交公理 (Validate-Before-Commit Lifecycle Axiom)
* 避免複雜回滾機制，採用單線程確定性之「驗證後提交」模式：
  1. **前置驗證 (Precondition Validation)**：檢查存活、所在容器合法性、目標容器容量與行為授權。若任何條件不符，強制中斷，**完全不修改任何狀態（State Hash 不變）**。
  2. **原子提交 (Atomic Commit)**：驗證通過後，個體狀態與容器計數同時更新。
  3. **事實寫入 (Event Emission)**：僅將**已成功提交之世界事實**寫入 Event Ledger。被拒絕之意圖不記入世界歷史。

### 14. 分期封閉行為空間公理 (Slice-Scoped Closed Action Space)
* 自主決策 NPC 只能從當前 Slice 所顯式授權的合法行為集合中選取動作（S4-A/B 無自主行為；S4-F 開放 `STAY`, `MIGRATE`, `JOIN_CARAVAN`, `LEAVE_JOB` 等）。
* **嚴禁行為發明**：未授權行為強制 Fail-Closed 拒絕。

### 15. 結構化決策證據公理 (Structured Decision Evidence Axiom)
* NPC 自主決策不得記錄無邊界之 Chain-of-Thought，必須以精確的結構化 Evidence 模式留存審計軌跡：
  $$\text{Evidence} = \langle \text{Day}, \text{Phase}, \text{NPC\_ID}, \text{Observed\_State}, \text{Eligible\_Actions}, \text{Selected\_Action}, \text{Rule\_Invoked}, \text{Result} \rangle$$
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
| **S4 前置**| **G1.5-A**| **NPC 權威契約：權威矩陣、單一容器歸屬、決定論 ID 鑄造、驗證後提交模式** | **CLOSED ✅** |
| **S4-A** | **G1.5-B1**| **NPC 身份運行防護：具名子集約束、確定性序列持久化、防人口通膨** | **CLOSED ✅** |
| **S4-B** | **G1.5-B2**| **生命週期原子防護：真實個體遷移/死亡雙重計數原子一致性驗證、Aggregate 不得挑選具名個體（Fail-Closed）** | **CLOSED ✅** |
| **S4-C** | **G1.5-B3**| **背景傳記惰性防護：封閉列舉、寫入後不可變、僅限存活個體、零行為授權、模擬惰性 bitwise 反事實** | **CLOSED ✅** |
| **S4-C.1**| **G1.5-B4**| **歷史事實權威：committed event ledger 完整持久化、derived count、非空 round-trip 決定論** | **CLOSED ✅** |
| **S4-C.2**| **G1.5-B5**| **持久化邊界透明性：schema-aware 型別還原、authoritative float canonicality、存讀不造成世界分叉** | 🟡 CURRENT |
| **S4-D** | **G1.5-B3**| **特質（Traits）：純決定論客觀效果** | WAIT |
| **S4-F** | **G2-lite** | NPC 自主行為授權、閉環決策審計證據、動態行為邊界鎖 | 規劃中 |
| **S5** | **G2** | 玩家與隊伍行為授權、存檔重播驗證、可驗證的世界歷程 | 規劃中 |
| **S6** | **G2+** | 死亡繼承傳承、世界記憶跨代傳承不變量 | 規劃中 |
| **S7** | **G2.5** | 資訊迷霧 Fail-Closed 知識邊界防禦（防真相洩漏） | 規劃中 |
| **Narrative**| **G3** | LLM 輸出完整治理、幻覺偵測與世界真理斷言驗證 | 規劃中 |



