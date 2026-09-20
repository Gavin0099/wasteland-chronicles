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
* **S4-C.2 — Snapshot Numeric Canonicality**：**CURRENT 🟡**
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
* **S4-D — Traits**：**WAIT**（阻擋於 S4-C.2 之後）謹慎、貪婪、忠誠、好鬥、酗酒等（純決定論客觀效果）。
* **S4-E — Aptitude Schema**：戰鬥、求生、交易、技術、社交潛能（先定義天賦易學性，**不做 XP**）。
* **S4-F — NPC Autonomous Decisions**：工作、移動、加入商隊、逃離聚落、轉職（自主湧現日常）。
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
