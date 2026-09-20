# Wasteland Chronicles — Expanded Slice Roadmap (S0–S8)

本文件定義專案從底層機械基線到垂直切片的**產品與模擬切片（Product & Simulation Slices）**路線圖。

每個切片的核心精神：
> **每個 Slice 只回答一個具體的遊戲設計問題。**  
> 遵循公理：`No Attributes, Skills, XP, Point Allocation, Proficiencies, or Perks before their designated slice.`

---

## 核心切片總覽矩陣 (Core Slice Matrix)

| Slice | 核心設計問題 | 主要內容 | 狀態 |
| :--- | :--- | :--- | :---: |
| **S0 — Mechanical Baseline** | 世界能穩定跑嗎？ | 3 聚落、2 資源、1 商隊、決定論與不變量基線 | **CLOSED ✅** |
| **S1 — Living Economy** | 聚落為什麼需要彼此？ | 4 資源、聚落分工 (Specialization)、供需推導、自然貿易網 | **CLOSED ✅** |
| **S2 — Fragility & Recovery**| 世界被破壞後會怎樣？ | 物流中斷、短缺、暴漲、恢復延遲與路徑依賴（三世界驗證） | **CLOSED ✅** |
| **S3 — Human Ecology** | 人口會如何受世界影響？ | 人口代謝、短缺壓力、難民遷徙、生理死亡、勞動生產力反饋 | **CLOSED ✅** |
| **S4 — Individual NPC Ecology**| 世界裡的人是不是「個體」？ | NPC 身份、生活狀態、背景、特質、潛能、自主決策 (無數值點數) | **CLOSED ✅** |
| **S5 — Player & Party** | 玩家怎麼成為世界裡的一個人？ | 玩家化身、Playable UI Shell、動詞驗證、經濟干預、世界反饋 | **CURRENT 🟡** |
| **S6 — Roguelite Legacy** | 角色死亡後，世界還能延續嗎？ | 永久死亡、隊員繼承、裝備與名聲遺留、世界記憶、歷史存續 | **PLANNED ⏳** |
| **S7 — Information Fog + UX**| 玩家如何認識世界？ | 真相/觀察/傳播/謠言/情報霧、ViewModel 隔離、Survivor PDA | **PLANNED ⏳** |
| **S8 — Vertical Slice** | 這整套東西真的好玩嗎？ | 6 聚落、3 勢力、50~100 NPC、完整循環試玩 30~60 分鐘 | **PLANNED ⏳** |

---

## S2.1 — Temporal Hardening 收尾 (CLOSED ✅)

在進入 S3 前完成以下三項硬化，S2 正式全面結案：
* **S2.1-A (Day / Tick Semantics)**：確立 8 階段離散日生命週期（Phase 0 ~ 7），狀態以日末結算為唯一快照。
* **S2.1-B (Travel-time Semantics)**：確立權威旅行公式 $\text{Arrival Day} = \text{Departure Day} + \text{Route Days} - 1$。Day 60 清晨修復出發、路程 3 天，嚴格於 Day 62 傍晚進城入庫。
* **S2.1-C (Recovery Terminology)**：滯後性術語客觀降級為「路徑依賴與恢復延遲（Path-dependence / Recovery Lag Observed; Persistent Hysteresis Not Yet Established）」。
* **S2-D (Market Stabilizer)**：**DEFERRED ⏸**（暫不加入人為替代商隊，由 S3 人口生態自發調節）。

---

## S3 — Human Ecology (已完成 ✅)

| 子切片 | 核心問題 | 核心機制 | 狀態 |
| :--- | :--- | :--- | :--- |
| **S3-A — Population Metabolism** | 人口是不是經濟需求真正的來源？ | 引入 `population`、`water_rate`、`food_rate`，廢除 hard-coded 消耗 | **CLOSED ✅** |
| **S3-B — Basic Needs Pressure** | 缺水缺糧能不能形成壓力，而不是瞬間死人？ | 引入 `water_pressure`、`food_pressure`（0 $\to$ 100 累積），先不死人 | **CLOSED ✅** |
| **S3-C — Refugee Migration** | 人會不會因為環境變差而離開？ | 壓力過高產生難民，歷經物理在途旅行抵達新聚落，災難跨聚落轉移 | **CLOSED ✅** |
| **S3-D — Mortality** | 什麼情況下人才真的會死亡？ | 長期極限匱乏且無法遷徙時才觸發生理死亡，非 `water == 0` 立即抹殺 | **CLOSED ✅** |
| **S3-E — Labor** | 人口下降會不會反過來影響生產？ | `population` 決定聚落可用勞動力，勞力下降連帶重挫工業廢料/燃料產出 | **CLOSED ✅** |
| **S3-F — Security Pressure** | 聚落變弱後，危險是否自然增加？ | 治安衰退、倉庫物資流失與商路掠奪損耗，無預設土匪純粹湧現危險 | **CLOSED ✅** |

---

## G1.5-A — NPC Authority Contract (已完成 ✅)

為防止進入個體 NPC 生態時產生幻覺、人口不一致與權限洩漏，正式建立 G1.5-A 治理契約層：
* **Rule 1 (Population Authority & Materialization)**：具名化是表徵識別，非人口增長；具名 NPC 為聚落人口之子集合（$N_{\text{named}} \le N_{\text{pop}}$）。
* **Rule 2 (Deterministic Identity Minting)**：NPC ID 依單調遞增序號確定性鑄造（`npc:00000001`），終身不變且永不復用，與位置/職業/派系徹底解耦。
* **Rule 3 (Single Population Membership)**：活體 NPC 必須且僅能屬於唯一人口容器（Settlement / Transit / Party），死者歸屬墓地。
* **Rule 4 (Validate-Before-Commit)**：前置驗證失敗則零修改中止（不需回滾機制）；通過則實體與總量原子提交。
* **Rule 5 (Slice-Scoped Action Space)**：自主行為按 Slice 顯式解鎖，未授權行為強制 Fail-Closed。
* **Rule 6 (Committed Event Ledger)**：世界事件帳本僅記已提交事實；未提交意圖僅進審計軌跡。
* **Rule 7 (Authority Matrix & Unidirectional Narrative)**：確立資料所有權矩陣，LLM 僅為下游觀察者，0 世界狀態修改權限。
* **驗收成果**：[docs/npc-authority.md](file:///d:/wasteland-chronicles/docs/npc-authority.md) 規格發布，[tests/test_npc_population_accounting.gd](file:///d:/wasteland-chronicles/tests/test_npc_population_accounting.gd) 七大契約 Gate (GA1 ~ GA7) 全數 PASS。

---

## S4 — Individual NPC Ecology (當前推進切片 🟡)

將聚落的人口數字拆解為世界中的可識別個體：
* **S4-A — NPC Identity (+ G1.5-B1 Runtime Enforcement)**：**CLOSED ✅**
  - 核心機制：`NpcRegistry`、`NpcIdentity`、最小身份表徵化實體（`id`, `name`, `age_at_materialization`, `origin_settlement_id`）。
  - G1.5-B1 運行防護：具名子集約束驗證（$N_{\text{named}} \le N_{\text{pop}}$）、確定性單調序號持久化、防人口通膨、前置驗證失敗零突變（A1 ~ A7 驗證通過）。
  - 領域驗證器：獨立 Python 權威驗證器 `governance_tools/npc_authority_validator.py` 納入合約。
* **S4-B — NPC Life State (+ G1.5-B2 Lifecycle Atomicity)**：**CLOSED ✅**
  - 核心機制：`NpcLifeState`、`NpcLifeStateRegistry`，將 mutable 生命狀態自 Identity 解耦。
    S4-B 僅收斂至 `status`(SETTLED / IN_TRANSIT / DEAD) 與 `container_id`；
    `alive` 由 `status != DEAD` 推導而不落欄位，`location` 亦不落欄位——
    `container_id` 即 authoritative whereabouts。`job` / `health` / `needs` /
    `relationships` 明確延後至後續 Slice，不在本切片實作。
  - G1.5-B2 運行防護：遷徙與死亡之個體/總額雙重原子提交真實驗收。
    - **Atomic Departure / Arrival**：個體 `NpcLifeState` 轉移與 aggregate `population`
      增減構成單一 observable unit；出發與抵達嚴格兩步拆分，遵守 Axiom 9
      （`Arrival Day = Departure Day + Route Days − 1`），禁止瞬移。
    - **Atomic Mortality**：死亡僅允許 `SETTLED → DEAD`；`IN_TRANSIT → DEAD` 於 S4-B 封鎖。
      死亡銷毀 life state，但 **`NpcIdentity` 永存**。
    - **Aggregate Cannot Choose Named**：aggregate 遷徙/死亡僅得消耗匿名人口
      (`anonymous = population − named_settled`)；匿名歸零時強制 **fail-closed**，
      發出 `NAMED_MIGRATION_DECISION_REQUIRED` / `NAMED_SELECTION_REQUIRED`
      且 `population` 零突變，待 S4-F 具備自主決策後方可處置具名個體。
  - **驗收成果**：[tests/test_s4_life_state.gd](file:///d:/wasteland-chronicles/tests/test_s4_life_state.gd)
    八大 Gate (B1 ~ B8) 全數 PASS，含序列化 round-trip 與雙世界 bitwise replay 一致性。
* **S4-C — Background / Profile Metadata**：**CLOSED ✅**
  - 核心機制：`NpcProfile`、`NpcProfileRegistry`，構成 NPC 三層分解的第三層：
    `NpcIdentity`（這個人是誰）／ `NpcLifeState`（這個人在哪、活著嗎）／ `NpcProfile`（這個人的背景）。
  - 封閉列舉，恰好四個：`CARAVAN_GUARD`, `MECHANIC`, `FARMER`, `SCAVENGER`。
    **無 `UNASSIGNED` 成員**——「沒有 profile」與「background 是 UNASSIGNED」是兩回事，只有前者存在。
  - 指派規則（全部 fail-closed，拒絕時零突變）：profile 為**可選**、background **一經指派永久不可變**
    （同值重複指派亦拒絕）、**僅限存活 NPC**（死者不得事後補寫傳記，但生前已有的背景在死後永存）、
    **僅接受 caller 顯式指定**（不建立任何 demographics generator）、未知值拒絕。
  - **Background 是傳記，不是能力**。本切片明確**不含**：衍生 social role、eligible-action tags、
    occupation、relationships、技能、數值、任何模擬效果。
    `get_authorized_actions()` 對所有背景一律回傳 `[]`（`npc-authority.md` §6：S4-C 行為空間 = NONE）。
  - **決定性驗收（C5 Simulation Inertness）**：同一世界，一邊有 Background、一邊完全沒有，
    跑 30 天後 Simulation Projection **必須 bitwise identical**——證明 background 只改變世界的
    *紀錄*，不改變世界的 *行為*。
  - **驗收成果**：[tests/test_s4_profile.gd](file:///d:/wasteland-chronicles/tests/test_s4_profile.gd)
    七大 Gate (C1 ~ C7) 全數 PASS；Python 權威驗證器新增 `NPC-007`（profile ⊆ identity）、
    `NPC-008`（封閉 background 列舉）兩條規則。
* **S4-C.1 — Event Ledger Persistence Hardening**：**CLOSED ✅**
  - **Finding**：`EVENT_LEDGER_NOT_ROUNDTRIPPED`
  - **Origin**：Pre-existing `WorldState` serialization behavior（非 S4-C 引入）
  - **Discovered by**：S4-C C7 persistence validation
  - **Disposition**：獨立 hardening slice，不併入 S4-C，亦不在 C7 中順手修復
  - **問題**：`to_dict()` 僅輸出 `event_count`，從不序列化 `EventRecord` 陣列，
    故 `from_dict()` 永遠還原出空帳本。世界目前只有 **Current State Authority ✅**，
    而 **Historical Fact Authority ❌**——與「Event Ledger 記錄 committed world fact」
    之治理定義直接衝突。至 S4-F 自主決策上線後，最關鍵的 audit evidence 會在 load 後消失。
  - **架構修正方向**：`events` 為唯一權威，`event_count` 降為 **derived value**
    （`event_count := events.size()`），不得形成第二真相；validator 必須驗證
    `serialized event_count == len(events)` 而非信任它。此與 `alive ← status 推導`、
    `social_role 不重複存` 為同一套設計哲學。
  - **驗收 Gate（L1 ~ L6）**：非空 round-trip、順序保存、nested payload 保存、
    derived count、決定論 snapshot SHA、全回歸。含負向 fixture：
    `event_count = 9 / events = [7 events]` 必須 **VALIDATOR FAIL**，不得靜默接受。
  - **Schema 變更為刻意行為**：本專案仍處 pre-player / pre-savegame / pre-alpha，
    無真實存檔相容義務。**不為保護 prototype artifact 的 hash 而保留已知 persistence defect**；
    修 schema → 重產 canonical artifacts → 重建 baseline evidence → 記錄 intentional schema change。
    舊有歷史證據由既有 commit 與 `v0.0.1-s3` tag 保存。
  - **落地結果**：`to_dict()` 輸出完整有序 `events` 陣列；`from_dict()` 由 `events` 重建帳本。
    `event_count` 降為 derived（`WorldState.get_event_count()` 即 `event_log.size()`，不存欄位），
    序列化中保留僅作 checksum-like metadata，載入時**只拿來對帳、永不據以推斷歷史**。
  - **Payload 值模型**：帳本以 JSON 持久化，而 `JSON.parse_string` 會把所有數字放寬為 float，
    未經正規化的帳本因此**不是序列化不動點**——save → load → save 會產生與第一次不同的檔案。
    對稽核帳本而言不可接受，故 payload 於 **commit 當下** 正規化為 JSON 值模型
    （`WorldState.record_event()` 為唯一入口），使記憶體形態與持久化形態一致，round-trip 成為恆等。
    超出 2^53 的整數**不做有損轉換**，改由不變量與 validator 舉報。
  - **驗收成果**：[tests/test_s4_c1_event_ledger.gd](file:///d:/wasteland-chronicles/tests/test_s4_c1_event_ledger.gd)
    六大 Gate (L1 ~ L6) 全數 PASS，含 357 事件之非空帳本 byte-identical round-trip、
    帳本不動點、亂序保序、三層巢狀 payload 保真、`9 vs 7` 與 `count-without-ledger`
    與 malformed record 三種 fail-closed 拒絕、以及 save/load 後帳本 SHA 不變。
    Python 權威驗證器新增 `EVENT-001` ~ `EVENT-004` 四條規則（完全獨立重算，不呼叫 GDScript 邏輯）。
* **Finding**：`NON_LEDGER_STATE_NOT_ROUNDTRIPPED` — **Status: ACCEPTED_FOR_WORK**
  - **Owner disposition**：S4-C.2 — Snapshot Numeric Canonicality（先於 S4-D Traits 處理）
  - **Scope**：schema-aware restoration + authoritative numeric canonicality + save/load continuation equivalence
  - **Not included**：traits / aptitude / relationships / NPC decisions / save migration compatibility / gameplay expansion
  - **Origin**：Pre-existing `SettlementState` serialization behavior（非 S4-C.1 引入）
  - **Discovered by**：S4-C.1 L1 全快照不動點驗證
  - **問題**：`production_credits` / `disorder_loss_credits` / `cumulative_disorder_loss` /
    `last_need_outcomes` 以原始 `Dictionary` 存放，其 int 值於重載後放寬為 float；
    另有極小浮點數經 JSON round-trip 後精度流失
    （`0.00000000000000488498130835069` → `0.00000000000000488`）。
    因此**整份快照尚非不動點**，但**事件帳本本身已是**。
  - **Disposition**：屬 settlement-state 序列化缺陷，非 event-ledger 缺陷。
    S4-C.1 只主張它實際證明的帳本範圍，其餘升為本 finding，不靜默吸收。
* **S4-C.2 — Snapshot Numeric Canonicality**：**CLOSED ✅**
  - **本切片只回答一題**：整個 authoritative `WorldState` 經過 Save → Load 後，
    能不能重新得到同一個 canonical state——型別、數值與後續 simulation 語意皆然。
  - **不追求「JSON 數字原始字串完全一樣」**。那是工具行為。真正要鎖的是：
    `Domain type → serialized representation → loaded domain type` 必須一致
    （`42` 不得變成 `42.0`）。
  - **嚴禁啟發式修數字**：不做 `recursive_fix_all_numbers()`，不得看到 `3.0` 就猜它是 int。
    還原必須由 **domain schema 決定**，猜測等同以臆測覆寫 domain 真相。
  - **嚴禁 save 時偷偷 round**：若 authoritative float 需要量化，必須發生在**狀態提交點**
    （`calculate → canonicalize → commit authoritative state → save`），
    使 runtime world 與 persisted world 只有一套真相。Save 只是忠實記錄。
    此與 S4-C.1 於 `record_event()` 正規化 payload 為同一條紀律。
  - **N0 先於一切**：precision policy **不得在證據存在之前選定**。
  - **驗收 Gate（N0 ~ N6）**：
    - **N0 Numeric Classification**：對每個 affected field 取得證據——declared domain type、
      是否影響下一 tick（AUTHORITATIVE SIMULATION STATE vs OBSERVATIONAL / ACCOUNTING ONLY）、
      值如何產生（加法 / 乘法 / 除法 / carry accumulation）、是否存在合法小數、
      JSON round-trip 實際變化、該變化會否使 Day N+1 分叉。
      已知受影響欄位至少：`production_credits`、`disorder_loss_credits`、
      `cumulative_disorder_loss`、`last_need_outcomes`。
    - **N1 Full Snapshot Fixed Point**：非空真實世界 snapshot `save→load→save` canonical hash 一致。
    - **N2 Schema-aware Type Restoration**：int / float / 容器元素型別按 schema 正確恢復。
    - **N3 Authoritative Float Canonicality**：真正參與 simulation 的 float 具明確 canonical policy。
    - **N4 Interrupted vs Uninterrupted Continuation**：**本切片核心 Gate**。
      World A 不中斷跑 Day 0 → 100；World B 跑至 Day 50 後 save / load 再續跑至 Day 100。
      兩者之 settlement / caravan / refugee / NPC identity / life state / profile /
      event ledger / numeric credits / final canonical hash **全部必須相同**。
      **N4 FAIL 則本切片不算完成**，即使 N1 的 hash 看起來漂亮。
    - **N5 Negative / Malformed Snapshot**：不合法 numeric representation **fail closed，不猜型別**。
      schema 宣告 `requested: int` 卻收到 `3.7` → `INVALID_DOMAIN_NUMERIC_TYPE`，
      嚴禁 `int(3.7) → 3` 後裝沒事。`3.0` 是否可 canonicalize 為 int `3`，
      須於 N0 明確拍板，不得由 implementation 自行猜測。`NaN` / `Inf` / `-Inf` 若 domain 不允許，一律拒絕。
    - **N6 Independent Verification / Regression**：Godot suites + Python validator +
      governance drift + 全回歸 PASS。
  - **N0 證據結論（推翻了原本的假設）**：四個 dictionary 欄位只是**症狀**，不是病因。
    實測顯示 `production_credits` / `disorder_loss_credits` 早已正確以 float 還原；
    `last_need_outcomes` 根本不序列化且每 tick 清空（perturbation 證明對後續完全惰性）；
    `cumulative_disorder_loss` 的 int→float 純屬表徵差異。
    **真正的軌跡分叉來自 `to_dict()` 對 authoritative float 套用 `snapped()`**——
    runtime 持有 `5.666…`、快照持有 `5.67`，載入後世界從不同的數字繼續，
    Day 51 即分叉。這正是「save 時偷偷 round」的反模式，且為既有行為。
  - **Owner 拍板（N0 後）**：
    - **Q1 → (b)** 不把 `snapped()` 的 0.01 / 0.0001 反向解讀為遊戲設計規則。
      沒有證據支持「water pressure 只能有 2 位小數」。移除 save-time rounding。
      *數值怎麼顯示是 UI 的事；怎麼存活過 Save/Load 是 persistence 的事；在遊戲裡代表什麼才是 domain rule。*
    - **Q2 → YES** 接受 integral float → int，但必須
      `finite AND mathematically integral AND |v| <= 2^53-1 AND within domain range`；
      `3.7` 一律 `INVALID_DOMAIN_NUMERIC_TYPE` fail-closed，嚴禁靜默截斷。
    - **Q3 → YES** `cumulative_disorder_loss` = `Dictionary[StringName, int]`、ACCOUNTING STATE、
      無 simulation-control authority，schema-aware 還原為 int，不套 float policy。
  - **N3 判定：REQUIRED ✅，但 policy 不是位數**。實測 Godot `JSON.stringify` 只寫 15 位有效數字，
    8 個全精度 double 有 7 個無法無損 round-trip；**連已量化的值也不穩定**
    （`snapped(99.994, 0.01)` = `99.990000000000009` → 寫成 `99.99` → 讀回 `99.989999999999995`）。
    因此採 **persistence-codec canonicality**：
    `canonical_float(x) := JSON.parse_string(JSON.stringify(x))`，
    17/17 probe 滿足 `canonical(canonical(x)) == canonical(x)`。
    **正規化位置：end-of-day state commit boundary**（每日一次，physics 之後、invariant 之前），
    使每一個已提交的日界世界本身就是 persistence-canonical，save 只是忠實記錄。
  - **N4（closure blocker）實測**：World A 不中斷跑至 Day 100，World B 於 Day 50 存檔重載後續跑，
    full canonical state SHA、event ledger SHA、simulation projection SHA **三者全部相同**，
    且 Day 51（載入後第一天）即已相同。
  - **驗收成果**：[tests/test_s4_c2_numeric.gd](file:///d:/wasteland-chronicles/tests/test_s4_c2_numeric.gd)
    N1 ~ N6 全數 PASS；證據 harness [tests/n0_numeric_evidence.gd](file:///d:/wasteland-chronicles/tests/n0_numeric_evidence.gd)
    與 `artifacts/s4c2_n0_evidence.txt` 保留 N0 原始測量；
    Python 驗證器新增 `NUM-001` ~ `NUM-003`（獨立重算，不共用 GDScript 還原邏輯）。
  - **刻意的 baseline 變更**：移除 save-time rounding 會改變模擬軌跡，所有 canonical artifact
    已重新產生。不為保護舊 hash 而保留已知 persistence defect；舊歷史由既有 commit 與 `v0.0.1-s3` tag 保存。
  - **Finding `NON_LEDGER_STATE_NOT_ROUNDTRIPPED` → RESOLVED ✅**（N1 PASS 且 N4 PASS）。
  - **Future note（S4-C.2 不做）**：`cumulative_disorder_loss` 理論上可由 authoritative event ledger
    的 `LOCAL_DISORDER_LOSS` 事件推導而成為 derived statistic。現在改 authority model 會擴 Slice，不動。
* **S4-D — Traits**：**CLOSED ✅**（Governance Fast Lane）
  - 核心機制：**沿用既有 `NpcProfile`，不新增 Registry 或 Authority Surface**。
    `NpcProfile = { npc_id, background, traits[] }`；traits 是 Profile metadata，非 LifeState。
  - 封閉列舉六項：`CAUTIOUS`, `LOYAL`, `GREEDY`, `AGGRESSIVE`, `COMPASSIONATE`, `STUBBORN`。
  - **Trait 是描述，不是能力**。明定：`CAUTIOUS ≠ 自動逃跑`、`LOYAL ≠ relationship bonus`、
    `GREEDY ≠ trade bonus`、`AGGRESSIVE ≠ attack permission`。
  - **Set-like 語意**：不得重複；**指派順序不構成世界差異**——一律以 enum order 正規化儲存，
    `[LOYAL, CAUTIOUS]` 與 `[CAUTIOUS, LOYAL]` 產生位元相同的世界。
  - 指派規則同 Background：僅接受 caller 顯式指定、無隨機生成、
    **不由 background 推論 trait**、無人口分佈、未知值 fail-closed、
    僅限存活且已有 Profile 之 NPC；生前已有的 trait 在死後保留（那是這個人的歷史）。
  - **不設數量上限**：目前無 evidence 支持「每人 2~3 個」這類限制，屬角色平衡問題，不預先鎖。
  - **本切片明確不含**：action eligibility、decision weight、attribute / skill / relationship /
    price / combat modifier、隨機生成、trait conflict matrix、正負分數。
    這些至少要等 S4-F / S5 有真正 gameplay verb 可驗證才談。
  - **驗收成果**：[tests/test_s4_traits.gd](file:///d:/wasteland-chronicles/tests/test_s4_traits.gd)
    D1 ~ D6 全數 PASS（D5 反事實：6 個 trait vs 無 trait 跑 30 天，
    simulation projection SHA 完全相同，而 full-state hash 不同）；
    既有 Python 驗證器擴充 `TRAIT-001`（封閉列舉）、`TRAIT-002`（無重複）兩項檢查。
* **S4-E — Aptitude Schema**：**CLOSED ✅**（Governance Fast Lane）
  - 核心機制：續用既有 `NpcProfile`，不新增 Registry。
    `NpcProfile = { npc_id, background, traits[], aptitudes[] }`。
  - 封閉領域標籤五項：`COMBAT`, `SURVIVAL`, `TRADE`, `TECHNICAL`, `SOCIAL`。
  - **刻意不用數值**。不做 `Combat = 8`、不做 `HIGH / MEDIUM / LOW`、不做 `★★★`、
    不做 `TECHNICAL → XP ×1.5`。理由：目前**根本沒有 Skill Growth**，
    因此沒有證據能判斷天賦究竟該是倍率、成長曲線、上限還是別的東西。
    若現在寫下「Technical 3」，下一步必然變成「3 星加多少 XP？」——S4-E 就會偷跑進 S5-D。
    等 S5-D 建立真實技能（Mechanics / Medicine / Rifle / Trade…）後，
    再由當時已驗證的成長模型決定 `TECHNICAL` 如何影響 `Mechanics`，而非反過來。
  - 指派規則沿用 Traits：顯式指定、無隨機、**不由 background 或 trait 推論**、
    未知值與重複 fail-closed、僅限存活且已有 Profile 之 NPC、生前既有者死後保留、無數量上限。
  - **驗收成果**：[tests/test_s4_aptitude.gd](file:///d:/wasteland-chronicles/tests/test_s4_aptitude.gd)
    E1 ~ E6 全數 PASS（E5 反事實 projection SHA 相同、full-state hash 不同；
    E4 另掃 `xp_multiplier` / `learning_rate` / `skill_bonus` / `skill_cap` /
    `growth_rate` / `attribute_bonus` / `rating` / `stars` 字樣，schema 與序列化皆不得出現）；
    既有 Python 驗證器擴充 `APT-001`（封閉領域）、`APT-002`（無重複）。

**S4 Profile 三層語意（S4-C ~ E 完成後）**：
```text
Background = 這個人以前做過什麼
Traits     = 這個人是什麼樣的人
Aptitudes  = 這個人可能比較容易學哪類事情
```
三者目前一律 `NO ACTION / NO STATS / NO SKILLS / NO XP / NO SIMULATION EFFECT`。
進入 S4-F 時**僅 Traits 可能參與 Decision Engine**；Aptitude 傾向繼續保持 inert，
待 S5-D Skills 才啟用。嚴禁因為進了 S4-F 就順手讓
`SURVIVAL aptitude → 更容易選 MIGRATE`——那沒有語意基礎。
* **S4-F — NPC Autonomous Decisions**（G2-lite 治理 checkpoint）
  * **S4-F1 — Decision Authority**：**CLOSED ✅**
    - **封閉 action space 僅兩項**：`STAY`, `MIGRATE`。
      `WORK` / `JOIN_CARAVAN` / `LEAVE_JOB` / `JOIN_FACTION` / `TRADE` / `REPAIR` /
      `ATTACK` / `HELP` 一律不納入——目前真正具備完整 physics 與 atomic transition
      支援的 NPC 行為只有「留下」與「遷徙」，其餘會逼迫 occupation / faction /
      combat / relationship authority 提前誕生。
    - **權威鏈（固定單向）**：
      `World State → Observation Projection → Eligibility Filter → Decision Engine →
      Structured Intent → Authorization → 既有 Atomic Lifecycle Commit →
      Committed Event → Decision Evidence`
    - **Observation Boundary**：`NpcDecisionObservation` 為窄化唯讀值投影，
      只含 `npc_id / day / current_settlement_id / water_pressure / food_pressure /
      security / candidate_destinations`。Decision Engine **從不持有 WorldState**，
      因此結構上無法讀取 settlements、事件帳本、其他 NPC 狀態或未來資訊——
      「零修改權限」是結構保證而非口頭約束。此邊界同時是 S7 Information Fog 的正確起點。
    - **Zero Mutation Authority**：`NpcDecisionEngine` 所有函式輸入為 Observation、
      輸出為值；提交由既有 S4-B `begin_named_migration()` 原子交易負責，
      決策層自身沒有任何 mutation path。
    - **Batch Semantics**：日初取一份不可變 observation snapshot，
      依 **lexicographic npc_id order** 全員決策 → 收集 intents → canonical commit order
      → **逐一重新驗證前置條件** → commit 或 reject。
      嚴禁「Mara 決定並立即改世界 → Eli 看到已被改過的世界」。
    - **Rejected intent 只進 Decision Audit Trail，絕不寫入事件帳本**
      （Axiom 11.1 / §5.1）。被拒絕的意圖永遠不得被讀成「Mara migrated」。
    - **Structured Decision Evidence**：`world.decision_audit_trail` 記錄
      `day / phase / npc_id / observed_state / eligible_actions / selected_action /
      rule_invoked / result / committed_event_index`，**不存 Chain-of-Thought**。
      `committed_event_index` 採帳本位置引用——S4-C.1 刻意不給 EventRecord id，
      故以 append-only 帳本的位置作為 derived reference，不形成第二身份。
    - **第一版不讓 Traits / Aptitude / Background 影響決策**。所有 NPC 在相同
      observation 下遵循相同規則，先證明 decision architecture 本身成立；
      若出問題就知道是架構而非 personality weighting。
      `CAUTIOUS` 是否值得在相同行情下產生不同選擇，是 S4-F2 才問的問題——
      而且可能根本不值得做。**Trait 不會因為存在就必須有作用。**
    - **不重新發明目的地演算法**：沿用 S3-C `select_refugee_destination()`，
      避免「匿名人口認為 New Hope 最安全，Mara 卻用另一套算法跑去 Dry Well」。
    - **本輪嚴禁**：LLM decisions、randomness、goal planner、Utility AI、
      Behavior Tree、GOAP、relationships、occupation、faction、combat、trading。
      兩個 action 加幾條決定論規則不需要框架。
    - **驗收成果**：[tests/test_s4_f1_decisions.gd](file:///d:/wasteland-chronicles/tests/test_s4_f1_decisions.gd)
      F1 ~ F8 全數 PASS。實例：Mara 於 Day 13 依
      `RULE_SEVERE_LOCAL_DEPRIVATION` 自行決定離開灰谷前往新希望，
      經既有難民隊伍物理路徑上路，生命守恆 300 == 300。
  * **S4-F2 — Autonomous Migration**：**CLOSED ✅**
    - **核心問題**：NPC 在自主決定遷徙後，能否完整走完「決策 → 物理出發 → 在途旅行 → 物理抵達入籍」的全生命週期？
    - **六大驗收 Gate（F2-1 ~ F2-6）**：
      - **F2-1 (Decision Chain)**：灰谷危機惡化，Mara 觀察到短缺壓力 $\ge 60.0$，自主產生 `MIGRATE` 意圖，授權通過，審計軌跡記錄 `COMMITTED`。
      - **F2-2 (Atomic Departure)**：出發日 Gray Valley 人口 $-1$，Mara 進入 `RefugeePartyState`，生活狀態轉為 `IN_TRANSIT`，`days_remaining = route_days - 1`，途中不瞬移。
      - **F2-3 (Axiom 9 Physical Arrival)**：嚴格遵守 $\text{Arrival Day} = \text{Departure Day} + \text{Route Days} - 1$（Day $13 + 3 - 1 = 15$），第 15 天抵達新希望，New Hope 人口 $+1$，Mara 轉為 `SETTLED`，帳本記錄 `NAMED_MIGRATION_COMPLETED`。
      - **F2-4 (Mid-Route Persistence Equivalence / 核心驗收)**：半路存檔（Mara 在途時 SAVE → LOAD），載入後繼續旅行，**抵達日（Day 15）與不中斷運行的 World A 完全一致**，且 Day 25 全世界 Canonical JSON SHA-256 **位元完全一致**（`a8a48676...` == `a8a48676...`）。
      - **F2-5 (Post-Arrival Continuity)**：抵達新希望後，Mara 成為安定居民，後續決策週期穩定選擇 `STAY`（`RULE_STAY_DEFAULT`），不無休止漂流；永久身份 `origin_settlement_id` 維持灰谷，所在容器維持新希望。
      - **F2-6 (Global Invariants)**：全週期全域生命總量維持嚴格守恆（$300 == 300$），引擎不變量 100% 通過。
    - **驗收成果**：[tests/test_s4_f2_migration.gd](file:///d:/wasteland-chronicles/tests/test_s4_f2_migration.gd) F2-1 ~ F2-6 全數 PASS，全專案 23 組測試套件 100% PASS。
  * **S4-F3 — Multi-NPC Batch Determinism**：**CLOSED ✅**
    - **核心問題**：多個具名 NPC 同一天看到同一份世界快照、各自做決策時，結果是否不受 Dictionary 插入順序、評估順序或前一人的 mutation 影響？
    - **六大驗收 Gate（F3-1 ~ F3-6）**：
      - **F3-1 (Shared Snapshot)**：同 phase 內所有 NPC 評估皆基於不可變快照，無觀察交錯修改。
      - **F3-2 (Canonical Evaluation Order)**：嚴格依 `String(npc_id)` 字典序評估與提交，帳本事件嚴格保序。
      - **F3-3 (Insertion Independence)**：正序、倒序、洗牌三種 Registry 插入順序運行 25 天後，世界快照 SHA-256 位元完全一致（`d2fa296e...`），決策審計軌跡亦位元完全一致（`3fbb3a67...`）。
      - **F3-4 (Multi-Intent Revalidation / Case B: Contention)**：在接近人口底線（pop=12, floor=10）的世界中，3 名 NPC 同日決定 MIGRATE：`01` 提交成功（pop 12→11）並寫入帳本、`02` 提交成功（pop 11→10）並寫入帳本、`03` 重新驗證失敗（`PRECONDITION_CHANGED: origin population at or below migration floor (10)`）被 REJECTED；**被拒絕的 `03` 在世界事件帳本中嚴格產生 0 筆事件**（未提交意圖僅留存於審計軌跡，絕不寫入歷史事實）；5 次重播勝者與敗者 100% 相同。
      - **F3-5 (Population & Transit Conservation / Case A: All Succeed)**：5 名 NPC 同日出發，組成 5 人難民隊伍，依 Axiom 9 航行 3 天後全數抵達新希望，世界生命守恆 300 == 300。
      - **F3-6 (Replay / Save-Load Equivalence)**：連續運行 30 天 vs 第 14 天在途存檔重載，最終世界 Canonical SHA（`bcfd3261...`）與決策軌跡 SHA（`fcc35692...`）完全位元一致。
    - **驗收成果**：[tests/test_s4_f3_batch_determinism.gd](file:///d:/wasteland-chronicles/tests/test_s4_f3_batch_determinism.gd) 全數 PASS，全專案 24 組測試套件 100% PASS。
  * **S4 — Individual NPC Ecology 總結**：**CLOSED ✅ (Tag: `v0.0.1-s4`)**
    - **核心問題已回答**：「世界裡的人是不是獨立存在？」——**YES**。
    - NPC 具備完整四層架構：Identity（我是誰）、Life State（我在哪/生死）、Profile（過去背景/特質/天賦）、Decision（唯讀觀察/STAY與MIGRATE意圖/授權/物理行動/在途存檔不動點）。
    - 實例已證明：灰谷危機 → Mara 自主察覺 → 決定離開 → 物理旅行 3 天（Axiom 9）→ 抵達新希望入籍 → 穩定生活。
  * **S4-G — NPC Relationships**：**DEFERRED ⏸**（邊際效益低於讓玩家進入世界，先行延後）。
  * **Trait Personality Effects**：**DEFERRED ⏸**（不硬加 personality weighting，先證明基本動作空間）。
* **Finding**：`STRINGNAME_SORT_IS_NOT_LEXICOGRAPHIC` — **Status: RECORDED_DEBT 📌（Finding != Task，F3 驗證無分叉）**
  - **處置裁定**：Gate F3-3 實測證明在多實體洗牌插入順序下，世界未發生跨 run 分叉。繼續保留為 technical debt finding，不形成 blocker。

---

## S5 — Player & Party (玩家與隊伍：FIRST PLAYABLE 推進 🟡)

核心轉折：從「世界模擬得夠不夠完整？」轉為「**我終於可以進去玩了嗎？**」。
採用 G2-Lite 治理原則：**Human Input ≠ World State Mutation**，玩家無作弊 API，與 NPC 共享同一條物理與授權鏈（Human Input $\to$ Player Intent $\to$ Authorization $\to$ Simulation Commit）。

* **S5-A — Player Avatar**：**CLOSED ✅**
  - **核心問題已回答**：玩家能不能成為這個世界中的一個普通人，而不是上帝視角？——**YES**。
  - **資料模型**：`PlayerState` 包含 `npc_id`（連結底層權威 `NpcIdentity` / `NpcLifeState`）、`inventory: ResourceState`（個人物理背包，預設容量 20）、`money: int`（貨幣預設 50）、`water_pressure / food_pressure`（個人生理需求指標）。
  - **無特權／無作弊 API (G2-Lite)**：玩家輸入強制投影為 `PlayerIntent`，經 `authorize_player_intent()` 嚴格校驗合法性後，方透過既有原子交易鏈 `commit_player_intent()` 執行，完全拒絕直接竄改 `WorldState`。
  - **統一架構**：
    ```text
    NPC decision ─────┐
                      ↓
                    Intent
                      ↓
    Player input ─────┘
                      ↓
                Authorization
                      ↓
                 World State
    ```
  - **驗收成果**：[tests/test_s5_a_player.gd](file:///d:/wasteland-chronicles/tests/test_s5_a_player.gd) 六大 Gate (P1 ~ P6) 全數 PASS：
    - **P1 (Materialization & Conservation)**：玩家具名化（Vagrant, 27歲）僅認領灰谷 1 個無名人口名額，世界生命總量守恆 300 == 300；拒絕重複具現化。
    - **P2 (Unified Authorization)**：非法目的地、越界與非封閉意圖強制 Fail-Closed 拒絕，被拒絕意圖對世界 Hash 產生 0 改變。
    - **P3 (Physical Movement / Axiom 9)**：玩家旅行完全複用既有難民物理移動交易鏈，Day 0 出發、Day 1 在途、Day 2 抵達新希望（$0 + 3 - 1 = 2$），嚴禁瞬移；入籍新希望人口 $+1$。
    - **P4 (Personal Backpack & Load Limits)**：在途每日消耗背包 1 水 1 糧（10 $\to$ 6 負重），抵達後切換為聚落供餐；嚴格執行容量上限（20 單位），超載觸發不變量驗證中斷。
    - **P5 (Save/Load Round-Trip Fixed Point)**：世界含玩家化身經序列化/反序列化後為嚴格數學不動點，Canonical JSON SHA-256 位元完全一致（`b23f4d47843cac3de0118d351e50cb39b4458a2fd32e0de265d6ce3317672b6c`）。
    - **P6 (Coexistence with NPC Ecosystem)**：玩家與多名自主 NPC 同場並行模擬 10 天，世界全域不變量 0 違規，生命總量守恆 300 == 300。
  - 全專案 25 組測試套件 100% PASS，Governance Drift Checker 18/18 PASS。
* **S5-A.2 — Playable UI Shell**：**CLOSED ✅**
  - **核心問題已回答**：玩家如何看得到世界與操作化身？——**YES**。打開 Godot 介面第一次像「一款遊戲」，且嚴格僅提供目前世界已有權威之能力。
  - **三層隔離架構 (UI5 Simulation Isolation)**：`WorldState` $\to$ `PlayerUIProjection` $\to$ `Godot UI`。UI 控制器無任何直接讀寫 `WorldState` 之代碼路徑，僅能透過受控唯讀投影與 `PlayerIntent` 交易鏈。
  - **動詞邊界**：A.2 嚴格**不實作 WAIT 按鈕**（留待 S5-B1）。點擊 `[TRAVEL]` 僅提交 `PlayerIntent(TRAVEL)` 並將玩家狀態轉為 `IN_TRANSIT`，不自動推進時間。
  - **資訊邊界 (LIVE vs Remote)**：目前所在聚落呈現 LIVE 真實資料；遠端聚落僅顯示路線可用性與旅途天數（嚴禁洩漏遠端經濟／庫存／物價，預留 S7 Information Fog 邊界）。
  - **HUD 規範**：僅顯示位置、在途狀態、金錢、水/糧/廢料/燃料、背包容量負重；嚴格無 HP、體力、輻射、XP、等級。
  - **除錯日誌標記**：事件帳本於介面明確標註為 `[DEBUG WORLD FEED]`，並提供 `debug_world_feed_enabled` 開關。
  - **視覺規範與錨點**：正式發布 [`.agents/skills/wasteland-chronicles-ui-v1/SKILL.md`](file:///d:/wasteland-chronicles/.agents/skills/wasteland-chronicles-ui-v1/SKILL.md)（Survivor PDA，Dark Industrial，Charcoal、Dirty Ivory、Muted Amber、Rust Red；綠色僅限小面積狀態指示）。生成並鎖定首組視覺錨點（World Map Anchor 與 Settlement HUD Anchor）。
  - **驗收成果**：[tests/test_s5_a2_ui_shell.gd](file:///d:/wasteland-chronicles/tests/test_s5_a2_ui_shell.gd) 六大 Gate (UI1 ~ UI6) 全數 PASS：
    - **UI1 (World Visibility)**：玩家位置（灰谷）與扇區 3 大世界節點（灰谷、乾井、新希望）及有效路線完整可見。
    - **UI2 (State Fidelity)**：HUD 顯示數值與底層 `PlayerState` / `PlayerUIProjection` 100% 保真，遠端節點無經濟資訊洩漏。
    - **UI3 (Travel Interaction)**：點擊遠端聚落僅發出合法 `PlayerIntent(TRAVEL)`，世界天數保持不變（不偷跑自動時間推進）。
    - **UI4 (Transit Feedback & Axiom 9)**：出發後狀態即時反映為 `IN_TRANSIT`；外部驅動 3 次 tick 後精確抵達新希望並切換為 LIVE 面板，嚴禁瞬移。
    - **UI5 (Simulation Isolation)**：非法目的地強制 Fail-Closed；UI 無任何直接篡改世界的途徑。
    - **UI6 (Playable Smoke Test)**：完整生命週期（開局 $\to$ 選地點 $\to$ Travel $\to$ 在途 $\to$ 外部 tick $\to$ 抵達 $\to$ Feed 切換）0 error 0 crash。
  - 全專案 26 組測試套件 100% PASS，Governance Drift Checker 18/18 PASS。
* **S5-B — Player Verbs (核心動詞循環)**：
  - **S5-B1 (Travel + Wait)**：**CLOSED ✅**
    - **核心問題已回答**：玩家能不能主動讓世界過一天，而且自己、NPC、經濟、商隊、旅行進度都真的一起過一天？——**YES**。
    - **WAIT 雙態語意**：
      - **定居狀態 (Settled)**：按鈕顯示 `[WAIT 1 DAY]`，世界全域推進 1 tick，玩家留在原地；**個人背包水糧絕不額外扣除**（嚴禁雙重代謝，聚落宏觀消耗已計入玩家）。
      - **在途狀態 (In Transit)**：按鈕動態切換為 `[CONTINUE — 1 DAY]`，底層同為 `PlayerIntent.WAIT`，物理航程推進 1 日（`days_remaining - 1`）並扣除個人背包 1 水 1 糧。
    - **嚴防雙重 Tick**：權威完全由 `SimulationEngine.commit_player_intent(WAIT)` 鎖定，成功提交後由引擎推進精確 1 個完整 world tick，UI 僅做投影刷新，嚴禁重複推進。
    - **驗收成果**：[tests/test_s5_b1_wait.gd](file:///d:/wasteland-chronicles/tests/test_s5_b1_wait.gd) 六大 Gate (B1 ~ B6) 全數 PASS：
      - **B1 (WAIT Authorization)**：WAIT 為第一級正式意圖，對非法 ID 或死亡狀態強制 Fail-Closed。
      - **B2 (Exactly One Tick)**：每次 WAIT 精確推進 1 個 tick（Day 0 $\to$ 1），灰谷水庫存消耗（80 $\to$ 75）、事件入帳、`PLAYER_WAIT` 登錄證明世界實質演進。
      - **B3 (Settled Wait / No Double-Metabolism)**：定居灰谷連續等待 3 天，個人背包 5 水 5 糧完全保留（負重 10 / 20 恆定）。
      - **B4 (Transit Wait)**：在途等待逐日推進航程並消耗個人背包水糧（5/5 $\to$ 4/4 $\to$ 3/3）。
      - **B5 (Physical Arrival / Axiom 9)**：第 3 次在途等待精確於第 6 天執行完畢抵達新希望（$4 + 3 - 1 = 6 \to$ Day 7），人口守恆 300 == 300，抵達後等待切回聚落供餐。
      - **B6 (UI State & Mid-Route Save/Load)**：UI 按鈕動態切換；在途中存檔重載續跑至 Day 9 與連續運行世界 Canonical SHA-256 位元 100% 一致（`d92431d8841077597ea87496e76fe5a690935473bcab6c679bcd5b4099cdd31b`）。
    - 全專案 27 組測試套件 100% PASS，Governance Drift Checker 18/18 PASS。
  - **S5-B2 (Trade)**：**CLOSED ✅**
    - **核心問題已回答**：玩家能不能使用世界既有的庫存與價格，在聚落間買低賣高，而且每一筆交易都是合法、原子、可保存的世界變化？——**YES**。
    - **本地市場貨幣儲備 (`market_cash`)**：聚落新增 `market_cash` 貨幣儲備（預設 500 瓶蓋），拒絕無限印鈔；每一筆買賣皆遵循全域貨幣與物資雙重守恆（$\Delta \text{Player Cash} + \Delta \text{Settlement Cash} == 0$ 且 $\Delta \text{Player Stock} + \Delta \text{Settlement Stock} == 0$）。
    - **整數報價與自然價差 (Integer Quotes & Natural Spread)**：
      - $\text{BUY quote} = \max(1, \lceil \text{price} \rceil)$
      - $\text{SELL quote} = \max(1, \lfloor \text{price} \rfloor)$
      - 自然保證 $\text{SELL quote} \le \text{BUY quote}$，最低單價保底 1 瓶蓋，全額整數結算無小數零錢。
    - **交易不推進時間 (Trade != World Tick)**：交易僅原子轉移物資與金錢並記錄 `TRADE_COMPLETED` 帳本事件，不推進世界天數（價格不立即跳動，由後續世界 WAIT tick 依供需平衡自然演進重算）。
    - **Fail-Closed 零突變防護**：非定居狀態（在途中）、未知商品、數量非正數、聚落庫存不足、玩家資金不足、背包超載（20 容量上限）、玩家庫存不足、聚落儲備金不足等 8 種邊界條件強制拒絕，世界快照 SHA-256 嚴格 0 突變。
    - **UI 隔離與情報防禦**：當前聚落呈現即時行情與買賣按鈕；遠端聚落嚴格隱藏交易介面與物價，0 資訊洩漏。
    - **驗收成果**：[tests/test_s5_b2_trade.gd](file:///d:/wasteland-chronicles/tests/test_s5_b2_trade.gd) 七大 Gate (T1 ~ T7) 全數 PASS，全專案 28 組測試套件 100% PASS，Governance Drift Checker 18/18 PASS。
  - **S5-B3 (Player Intervention Scenario)**：**CLOSED ✅**
    - **核心設計問題已回答**：玩家能不能看見一場危機，自己判斷介入方式，並在數天後清楚看到「有我」和「沒我」的世界走向不同？——**YES**。
    - **三世界反事實實測成果 (Three Worlds Counterfactual - Day 16)**：
      - **World A (No Intervention)**：灰谷缺水危機爆發，玩家不介入。人口暴跌至 47、累積死亡 22 人、治安重挫至 26.5。
      - **World B (Full Intervention)**：玩家自新希望購買 12 水（`BUY`），物理旅行 3 天（`TRAVEL`），在灰谷注入實體物資（`SELL`），推進時間（`WAIT`）。人口保存至 58（多保全 11 人）、累積死亡降至 16（減少 6 死）、治安維持 48.0。
      - **World C (Partial Intervention)**：玩家僅帶入 4 水。人口 47、死亡 22、治安 30.4。短中期（Day 6 水壓 80.0 介於 A 100.0 與 B 15.0 之間）與長期治安（30.4 介於 26.5 與 48.0 之間）嚴格單調遞增，證明**無魔術任務旗標，影響程度嚴格取決於實際運載物資量**。
    - **驗收成果**：[tests/test_s5_b3_intervention.gd](file:///d:/wasteland-chronicles/tests/test_s5_b3_intervention.gd) 六大 Gate (I1 ~ I6) 全數 PASS：
      - **I1 (Crisis Readability)**：UI 投影與面板清楚呈現 `[CRITICAL]`、`[HIGH_RISK]` 標籤，遠端聚落 0 洩漏，無虛假任務。
      - **I2 (Legal Intervention)**：閉環動詞（`BUY` / `TRAVEL` / `WAIT` / `SELL`），非法意圖強制 Fail-Closed。
      - **I3 (Physical Conservation)**：20 單位背包容量與貨幣真實約束，物資與瓶蓋在買賣中雙重守恆。
      - **I4 (Causal Effect)**：賣入的 10 水直接進入灰谷倉庫，下一日被居民生理代謝精確消耗 5 水，0 水匱乏暴露。
      - **I5 (Counterfactual Divergence)**：Day 6 水壓、Day 10 死亡延遲、Day 16 累積人口/死亡/治安三維度全數呈現嚴格客觀因果分歧。
      - **I6 (Persistence & Save/Load Determinism)**：在途中攜帶 12 水貨物存檔重載，Day 16 世界快照 Canonical SHA-256 與連續世界 100% 位元一致（`317a22b3...`）。
    - 全專案 29 組測試套件 100% PASS，Governance Drift Checker 18/18 PASS。
* **★ FIRST PLAYABLE CHECKPOINT ★**：**READY FOR PLAYTEST 🎮**
  - 完成 S5-B3 後立即停止新增系統，直接透過 Survivor PDA 介面連續實機試玩 20~30 分鐘，驗證四大核心產品體驗問題：
    1. **我有沒有自己看出哪個聚落有問題？**（Crisis Discovery）
    2. **我有沒有自己想到「我可以把物資帶過去」？**（Self-Motivated Agency）
    3. **過程中的 Travel / Wait / Trade 是否節奏合理？**（Loop Friction）
    4. **我介入後看到後果時，有沒有產生「世界真的因我改變」的感覺？**（Causal Impact）
* **S5-B4 — Scavenge (Optional after playtest)**：
  - 僅在 First Playable 試玩後證明「除了聚落間買賣套利，確實缺乏野外獲取物資方式」時，方才實作最小確定性廢墟搜刮（固定 Salvage Pool，無隨機掉寶、無稀有裝備、無戰鬥、無 Respawn）。
* **S5-C0 ~ S5-C7 — Character Progression Foundation（2026-09-20：C0/C1 CLOSED，C2+ 尚未實作）**：
  - 創角 → 能力權威 → Trait/Skill 遭遇選項 → 使用型技能成長 → Level/Perks → C4.5 Acquired Traits → 裝備 → 工作 → Capstone。
  - 核心驗收是「以前做不到，成長後做得到」，不同角色能用不同方法處理同一世界。
  - 詳見 [角色成長規劃](character-progression-foundation.md)。此排序取代原先近期擴城與泛稱 S5-D Skills 的未來排程；歷史完成紀錄保留，C0/C1 [權威契約](s5-c0-c1-contract.md)已完成並凍結；[headless 實作](c0-c1-headless-implementation.md)已獨立提交 `6b9c741`；[創角 UI 與能力呈現](c0-d-character-creation-ui.md)通過 36 suites、六項 UI gates、世界 SHA 重播與畫面驗證，C0/C1 整體 CLOSED。XP 與後續效果仍待各切片定義。
  - Encounter Result UX 獨立修復，不計為新玩法；稀疏路網擴城與擴充事件庫延後。Companions、Relationships、Combat 另行規劃。

---

## S6 — Roguelite Legacy (死亡與遺產傳承)

2026-09-20 Owner 界線：Core Traits 屬創角，Acquired Traits 屬 C4.5 的本局經歷；跨死亡的 Legacy Traits／Unlock 留在 S6。角色 build 隨死亡結束，世界繼續；可留下世界事實與下一任可取得的可能性，不把前任 Skills／Traits 全部繼承，不做帳號永久數值加成。

* **S6-A — Character Permadeath**：角色永久死亡，世界時鐘不重置，廢土持續運轉。
* **S6-B — Companion Succession**：主角死亡後自現存同伴中指派一人繼承，延續旅程。
* **S6-C — Equipment Legacy**：死者裝備的去向（被搶、散落、被隊員收回、遺失於荒原）。
* **S6-D — Reputation Legacy**：歷史聲望傳承（「你是跟著前任老大的那位副手嗎？」）。
* **S6-E — World Memory**：世界記住玩家歷史（誰死在哪裡、誰拯救過灰谷）。
* **S6-F — Legacy Progression**：知識、關係與世界資產沉澱（非單純數值 +10%）。

---

## S7 — Information Fog + UX (情報迷霧與介面)

* **S7-A — Truth**：世界唯一定理與客觀事實。
* **S7-B — Observation**：各實體於何時何地目擊了什麼。
* **S7-C — Knowledge Propagation**：信使與商隊傳播速度。
* **S7-D — Rumor**：非第一手觀察產生的失真情報。
* **S7-E — Player Knowledge**：玩家當前已獲取之情報集。
* **S7-F — ViewModel**：UI 介面與世界真實狀態的物理隔離層。
* **S7-G — SignalTag**：Freshness（新鮮度）與 Confidence（信任度）雙維度標籤。
* **S7-H — Actual UI**：荒原大地圖、聚落面板、情報終端（Survivor PDA）。

---

## S8 — Vertical Slice (可玩垂直切片)

* **規模規格**：6 聚落、3 勢力、50~100 位具備身份的 NPC、30 個大地圖節點、玩家與 3 名同伴。
* **體驗目標**：不需額外解說，可連續獨立遊玩 30~60 分鐘。
* **終極檢驗**：是否產生「我想知道這個世界接下來會怎樣」的強烈沉浸感。
