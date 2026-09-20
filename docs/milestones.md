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
| **S4 — Individual NPC Ecology**| 世界裡的人是不是「個體」？ | NPC 身份、生活狀態、背景、特質、潛能、自主決策 (無數值點數) | **CURRENT 🟡** |
| **S5 — Player & Party** | 玩家怎麼成為世界裡的一個人？ | 玩家化身、動詞、屬性發現、技能、創角點數、同伴、專長、Perk | **PLANNED ⏳** |
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
  * **S4-F2 — Autonomous Migration**：PENDING（decision → 物理出發 → 在途 → 物理抵達全程驗收）。
  * **S4-F3 — Multi-NPC Determinism**：PENDING（規模化評估順序、容量與總量會計）。
* **Finding**：`STRINGNAME_SORT_IS_NOT_LEXICOGRAPHIC` — **CONFIRMED 📌，S4-F1 已於決策階段規避**
  - **Discovered by**：S4-F1 Gate F6（canonical evaluation order 檢查）
  - **問題**：Godot 的 `StringName` 以**內部指標**比較，故
    `[&"zeta", &"alpha", &"mid"].sort()` 得到 `[mid, alpha, zeta]`。
    排序結果取決於記憶體配置順序，而非識別字內容。
  - **S4-F1 處置**：決策階段改以 `String` 排序後再轉回 `StringName`，並於程式碼註明原因。
  - **尚未處理的範圍**：引擎既有多處 `world.settlements.keys(); sort()` /
    `world.caravans.keys(); sort()` 亦以 StringName 排序。實測目前三個聚落
    *碰巧* 得到字典序，且同一 process 內順序穩定，因此既有測試與 artifact hash 未受影響；
    但這是**巧合而非保證**，與 Axiom 5「任何環境下位元一致」的主張存在落差。
  - **Disposition**：不在 S4-F1 擴大重構。記錄為 finding，待 Owner 裁定是否另開
    hardening slice（影響面為全域迭代順序，屬 Persistence/Determinism 類，非 gameplay）。
  背景是否提供 action eligibility，由此時已驗證的 gameplay 動詞決定，**不得由 S4-C 預先定義**。
* **S4-G — NPC Relationships**：**PENDING**（自 S4-C 切出獨立成 Slice）。
  關係圖是獨立的權威面：方向性、對稱性、死亡後是否保留、跨聚落與跨容器關係，
  皆需各自的不變量與 fail-closed 規則，不應混入 Background metadata。

---

## S5 — Player & Party (玩家與隊伍)

從玩家動詞反推 RPG 系統，嚴禁憑空畫技能樹：
* **S5-A — Player Avatar**：`identity, inventory, location, needs, money, reputation`（玩家是世界裡的普通人，無技能樹）。
* **S5-B — Player Verbs**：驗證核心玩法動詞（Travel, Trade, Scavenge, Talk, Fight, Repair, Escort）。
* **S5-C — Core Attribute Discovery**：由玩法動詞反推核心屬性（如 Body, Awareness, Mind, Presence 等，無 gameplay consequence 的屬性不存在）。
* **S5-D — Skill System**：由 Verbs 衍生技能（Rifle, Melee, Survival, Trade, Mechanics, Medicine, Speech），採「使用型成長（Use-based Growth）」。
* **S5-E — Character Creation & Point Allocation**：正式開放玩家點數分配（屬性點、背景、特質、天賦、起始技能）。
* **S5-F — Companion Recruitment**：隊伍系統（玩家 + 0~3 名同伴），招募、離隊、槽位、生理需求與裝備。
* **S5-G — Party Ecology**：隊伍規模的代價（戰力與負重增加 vs. 水糧消耗暴增與更高荒原成本）。
* **S5-H — Companion Relationships**：隊員好感度、信任度、派系立場衝突（決定論響應，如屠殺平民扣好感）。
* **S5-I — Party Roles**：隊伍功能分工（Scout, Medic, Mechanic, Negotiator, Gunner）。
* **S5-J — Proficiencies**：專業專長（柴油引擎大修、野戰手術、水質淨化、黑犬幫暗號等特殊知識）。
* **S5-K — Special Abilities / Perks**：解鎖全新機制或玩法規則的高級專長（能開新玩法者才作為 Perk）。

---

## S6 — Roguelite Legacy (死亡與遺產傳承)

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
