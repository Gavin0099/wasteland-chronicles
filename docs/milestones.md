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
| **S3 — Human Ecology** | 人口會如何受世界影響？ | 人口代謝、短缺壓力、難民遷徙、生理死亡、勞動生產力反饋 | **CURRENT 🟡** |
| **S4 — Individual NPC Ecology**| 世界裡的人是不是「個體」？ | NPC 身份、生活狀態、背景、特質、潛能、自主決策 (無數值點數) | **PLANNED ⏳** |
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
* **S4-A — NPC Identity (+ G1.5-B1 Runtime Enforcement)**：
  - 核心機制：`NPCRegistry`、`NpcIdentity`、最小身份表徵化實體。
  - G1.5-B1 運行防護：具名子集約束驗證、確定性序列持久化、防人口通膨（GB1~GB5）。
* **S4-B — NPC Life State (+ G1.5-B2 Lifecycle Atomicity)**：
  - 核心機制：`location, job, health, needs, relationships`。
  - G1.5-B2 運行防護：遷徙與死亡之個體/總額雙重原子提交真實驗收。
* **S4-C — Background**：前商隊守衛、機械師、農夫、拾荒者（影響社會角色、初始關係、可用行為，不決定數值點數）。
* **S4-D — Traits**：謹慎、貪婪、忠誠、好鬥、酗酒等（純決定論客觀效果）。
* **S4-E — Aptitude Schema**：戰鬥、求生、交易、技術、社交潛能（先定義天賦易學性，**不做 XP**）。
* **S4-F — NPC Autonomous Decisions**：工作、移動、加入商隊、逃離聚落、轉職（自主湧現日常）。

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
