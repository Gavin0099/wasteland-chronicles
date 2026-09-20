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


