# S5-C0 / C1 — Character Creation & Capability Contract

狀態：2026-09-20 Owner 核准，SPEC / AUTHORITY CONTRACT COMPLETE；FROZEN FOR IMPLEMENTATION。功能交付狀態另記於 [headless 實作紀錄](c0-c1-headless-implementation.md)，不由契約完成推導功能完成。

本文件決定 C0/C1 的驗收行為，優先於成長 roadmap 中已被取代的例子。既有身份、人口守恆、世界帳本、決定論與 fail-closed 邊界仍適用。它不宣稱下面的 gates 已通過，也不授權本輪實作 C2、XP、Level、Perk、Equipment、Combat 或繼承。

## 1. 切片邊界與依賴

| 切片 | 可以建立的權威 | 不得擴張的權威 |
| --- | --- | --- |
| C0 Character Creation | 驗證創角請求，從既有人口實體化，設定背景 package 與 Core Traits | 人口增生、自由配點、Trait 加 rank、事件效果 |
| C1 Capability Foundation | 十項技能資料、唯讀門檻判斷、明確 migration、canonical persistence | XP 成長、維修／醫療／戰鬥效果、Perk／Equipment 條件執行 |
| C2（後續） | 以既有遭遇證明不同人物有不同選項與後果 | 本輪不實作；第一版不增加新 encounter template |

C0 的初始技能輸出使用 C1 的資料契約。未來實作應先讓共同資料與驗證器可用，再啟用 C0 commit；不建立另一套臨時 rank 容器，也不能把 C0 介面完成當成 C1 行為已完成。

## 2. C0 輸入與背景 package

創角只選 1 Background、0～2 Core Traits，並填姓名／既有基本身份資料，不提供自由配點。

建議的領域請求形狀為 `CharacterCreationIntent`：

| 欄位 | 契約 |
| --- | --- |
| source_settlement_id | 指向實際存在、可提供匿名人口槽的聚落 |
| character_name | 有效的非空文字；沿用身份層約束，不作為實體 ID |
| background_id | 來自明確、版本化 package catalogue 的 stable ID |
| trait_ids | 0～2 個互異 Core Trait stable ID |

年齡等既有身份必填資料需由明確的新遊戲設定或輸入提供；UI 不得發明隨機預設。實體 ID 仍由既有單調序號產生，與姓名、時間戳、隨機數無關。

每個背景 package 必須指定三個**互異**的核心技能：

- Primary rank = 2。
- Secondary A rank = 1；Secondary B rank = 1。
- 其他七項 rank = 0。
- 完整向量總和為 4，且必須包含十個合法 key。
- 相同 catalogue 版本與 background_id 永遠產生相同向量；Trait 不加 rank。

「MECHANICS 2 / ELECTRONICS 1 / SCAVENGING 1」是 package 形狀示例，不是已核定的新背景。既有 `NpcProfile.Background` 是 CARAVAN_GUARD、MECHANIC、FARMER、SCAVENGER 的 closed enum；這輪不增加或重排 enum，也不拍板新的背景清單。實作前必須提出 stable ID → 既有 profile 背景及 package 的完整對照。未知背景或沒有 package 的背景應拒絕，不能落回 FARMER 或全零。

## 3. Core Trait 選取

合法清單共 14 個：

`CAUTIOUS`, `AGGRESSIVE`, `COMPASSIONATE`, `GREEDY`, `STUBBORN`, `LOYAL`, `VIGILANT`, `RECKLESS`, `IRON_STOMACH`, `LIGHT_SLEEPER`, `LONER`, `CURIOUS`, `SUSPICIOUS`, `PACIFIST`。

只驗證：合法 ID、數量 0～2、沒有重複。其餘組合均合法，包括 CAUTIOUS + RECKLESS、AGGRESSIVE + PACIFIST。不預建語意衝突表，不因人物看起來矛盾而拒絕。

重複輸入是錯誤，不得先去重後接受。通過驗證後才 canonicalize：轉為 String，再依字典序排序；不得依賴 StringName `.sort()`。輸入順序不影響 canonical 結果。

Core Traits 儲存在新的 `selected_creation_traits` 語意欄位，與既有 S4 `NpcProfile.traits` metadata 分開。0～2 上限只約束 Core，不是未來 Core + Acquired + Legacy 的混合上限。C0/C1 不因選取 Trait 改變遭遇選項、價格、代謝或世界真相。

## 4. 原子創角與人口守恆

Character Creation 不是新增人類：來源是聚落已存在的匿名人口槽，具名人物仍是人口的表徵子集。

提交前完成全部驗證：身份欄位、來源聚落／匿名槽、尚無 active player、背景 catalogue 與 package、Traits、C1 rank domain、profile 關聯及必要新遊戲前提。全部通過後，才以既有 materialization authority 一次提交身份、生命狀態、profile、capability 與玩家關聯。

任何拒絕均保持世界 canonical hash 不變，包含人口、庫存、貨幣、next_npc_sequence、registries、玩家、事件帳本與 audit state。不得先鑄 ID、先扣匿名槽或寫成功事件，再驗證 package。中途失敗不得留下半個人物。

成功後：

- 世界總人口、來源聚落總人口不增加。
- `Living + In-Transit + Deaths == Initial Population` 不變。
- 恰好一個匿名表徵轉為具名表徵；一個有效 life-state container。
- 具名 ID、player、profile 與 capability 指向同一人。
- UI 只送 request 與讀 projection，不可直接寫 `player.skills` 或自行生成 package。

此契約沿用現有身份生命週期，不定義新的 NPC 出生、死亡、遷徙或繼承流程。

## 5. C1 技能 domain

完整、封閉的十項技能：FIREARMS、MELEE、SURVIVAL、SCAVENGING、STEALTH、MECHANICS、ELECTRONICS、MEDICINE、SPEECH、BARTER。

rank 為 integer，`0 <= rank <= 5`：0 外行、1 略懂、2 熟練、3 專業、4 專家、5 大師。中文名稱只用於呈現，stable ID 才是識別。

必須拒絕未知 ID、缺少／多餘 skill key、重複 key、負數、6 以上、浮點 rank、布林、字串、null、NaN 或 infinity。不得 clamp、取整、從字串 parse、以未知 ID 回傳 0，或把格式錯誤視為 legacy migration。

完整新 profile 必須可驗證來源，語意欄位包括：版本、人物關聯、`creation_origin`、完整 `skill_ranks`、`selected_creation_traits`。新創角另有已驗證的 `background_id`／package 版本來源。存檔承載位置需在實作設計中落到單一 owner，不得同時在 PlayerState、NpcProfile 等地方各存一份可寫的 ranks。

## 6. 唯讀資格 API 與組合

| API | 行為 |
| --- | --- |
| get_skill_rank(skill_id) | 已驗證 profile 的合法 ID 回傳 int rank；非法 ID／profile 回傳明確錯誤，不能以 0 假裝合法 |
| meets_skill_requirement(skill_id, rank) | 合法 threshold 的 `actual >= required`；相等成功；不改任何狀態 |
| meets_requirements(requirement_set) | 所有條件都滿足才成功；先驗證整個集合，再計算結果 |

第一版 requirement set 是純資料的 AND 集合，例如：

```json
{
  "all": [
    {"kind": "skill", "skill_id": "MECHANICS", "min_rank": 3},
    {"kind": "skill", "skill_id": "ELECTRONICS", "min_rank": 2}
  ]
}
```

`min_rank` 使用同一 integer 0～5 domain。空的合法 `all` 集合表示無門檻（true）；缺少 `all`、未知欄位、非陣列或非法條件不是無門檻。相同 skill 在多條合法條件中按 AND 判斷，不相加、不按輸入順序覆蓋；條件順序不影響答案。

有效但不滿足的結果為 false；結構／ID 非法必須附明確驗證錯誤並拒絕，不能被呼叫端視為 true。即使前一個條件已不滿足，後面不合法的條件也不可被 short-circuit 掩蓋。

僅 `kind: skill` 有權威。`level`、`perk`、`equipment`、`trait`、OR／NOT 等未支援條件一律拒絕，不忽略、不預先實作。這個資料形狀容許將來透過新版本擴充，但目前不引入通用規則語言。

門檻通過只回答資格；不授予 UI 或敘事任何世界修改權。MECHANICS 3 不能自行修水泵；MEDICINE 3 不能創造槍傷；FIREARMS／MELEE 不能開啟未實作的 Combat。相同世界與相同意圖，在 C1 不得因 ranks／Core Traits 不同而產生不同遭遇效果。

## 7. Legacy save migration

先通過現有身份、profile、帳本與世界完整性檢查，再對**可辨識的前 C1 schema**做 migration。只有合法舊版本且整個新 progression 欄位不存在，才可走 legacy 分支。新版缺欄位、null、損毀部分 profile、未知版本皆拒絕；不能用 migration 掩蓋 corruption。

| 舊資料 | Migration 行為 |
| --- | --- |
| Identity / S4 profile | 保留原 ID、background、traits、aptitudes 的既有語意和值 |
| 新 skill_ranks | 十個 ID 全部 0 |
| 新 selected_creation_traits | 空集合 |
| 新 creation_origin | LEGACY_MIGRATION |
| 新 package 來源 | 無；不捏造背景 package 配發歷史 |

新遊戲來源標記為 CHARACTER_CREATION；LEGACY_MIGRATION 僅描述存檔轉換，與 S6 的 Legacy Unlock 完全不同。

不把 S4 metadata 升格成 Core 選擇或技能。尤其 TECHNICAL Aptitude 不代表 MECHANICS 2；舊 MECHANIC 背景也不能因此得到新 package。舊人物身分、已發生的事件、人口、資源、天數、next_npc_sequence 都不變，不重新 materialize、不補發成功遊戲事件。

Migration 明確告知使用者，必須可追溯、冪等；第二次載入不得再覆寫後續合法資料或重複產生 provenance。保留 pending encounter/result 狀態，不能藉 migration 偷偷續行。原始檔不因讀取就被破壞性覆寫；正常存檔保存已驗證的新 schema。

## 8. Persistence 與型別邊界

記憶體 rank 必須是 `TYPE_INT`。例如 API／建構輸入 2.0 也拒絕，不因數值剛好整數而默認合法。

存檔技能 rank 必須是 JSON 整數 token（例如 `2`），不是 `2.0`、`2e0`、百分比或字串。Skill／Trait／Background 使用 stable ID，JSON object 不得含重複 key。先驗證，再建構整個 profile；不得回傳部分有效世界。

**Godot 轉碼注意：**既有 JSON parser 會把 `2` 與 `2.0` 都解成浮點數，現有 NumericCanon 又容許明確整數欄位的 integral transport values。新 rank 的嚴格 wire 契約因此需要在原 token 資訊流失前驗證，或使用保留 integer token 類型的解碼路徑。已驗證的 `2` 可明確還原成領域 int；未驗證的 generic Dictionary 裡的 2.0 不能被當成「一定來自整數 token」。不得用普通正規式掃整份 JSON 來猜巢狀欄位或改動既有全域數字規則。具體 codec 方案是 C1 實作設計必答項，不是本輪宣稱已解決的程式。

新 profile 的 `save → load → save` 必須 canonical-equivalent，並保持 int 型別、完整 ranks、Core ID 集合及來源。既有世界浮點模型不變。合法舊存檔先顯式 migration，此後才要求新格式固定點；不能宣稱 migration 前後整個檔案 bytes 相同。

Canonical 順序固定：skill keys 與 Trait ID 均按 String 字典序，不使用 StringName pointer 排序。新 profile 的 round-trip、duplicate_state 與世界 SHA-256 replay 都要驗證，不只測一個序列化函式。

## 9. 驗收 gates（尚未執行）

| Gate | 必要正例與反例 |
| --- | --- |
| C0-1 Population Conservation | 成功創角保持人口及總生命守恆；沒有匿名槽時無 mutation |
| C0-2 Background Package | 固定、獨立 fixture 驗證 2/1/1/其餘 0；同背景不同 Trait ranks 相同；未知／缺 package／重複技能拒絕 |
| C0-3 Trait Contract | 0、1、2 個成功；矛盾名稱配對成功；3 個、未知、重複拒絕；順序置換 canonical 一致 |
| C0-4 Atomic Creation | 每個非法欄位、已有 player、來源失效均整個 hash 不變，含序號與帳本；無殘留 identity/profile |
| C0-5 Legacy Migration | 舊 profile metadata 全保留、新 ranks 全零、Core 空、LEGACY_MIGRATION；新版殘缺／未知版本拒絕；重載冪等 |
| C1-1 Rank Domain | 完整 10 keys、0/5 邊界成功；6、−1、2.5、runtime 2.0、bool/string/null、缺漏／未知／重複 key 拒絕 |
| C1-2 Eligibility | below/equal/above、跨技能 AND、空集合、順序置換；未知 kind／ID、負 threshold、隱藏在不滿足條件後的非法項全部拒絕；零 mutation |
| C1-3 Persistence | raw JSON `2` 成功、`2.0`/`2e0` 失敗；profile 固定點、世界複製、pending receipt 保留；無靜默 clamp／掉欄位 |
| C1-4 Replay | 相同世界／catalogue／創角輸入的雙軌 SHA-256 一致，包含中途存讀檔；全域不變量通過 |
| C1-5 No Premature Authority | 變更技能／Core metadata 後，既有事件成本、掉落、代謝、價格與生命狀態規則不變；無新增世界 action |

預期值取自本契約、獨立人工 fixture 或既有不變量，不得以 production package／eligibility 函式回算預期值。測試存在不等於 gate 通過；未來任何 simulation 變更仍須跑全套 `tests/test_*.gd`。

## 10. 三種 Trait 來源與後續權威

| 來源 | 取得時機 | 負責切片 | 本輪界線 |
| --- | --- | --- | --- |
| Core Trait | 創角，0～2 個 | C0 選取；C2 才接效果 | 不與 S4 metadata 混合 |
| Acquired Trait | 本局真實經歷產生候選，玩家可選或保持原樣 | C4.5 | 不實作取得、計數器、效果或新持久化欄位 |
| Legacy Trait / Unlock | 死亡／繼承後留給世界與下一人的可能性 | S6 | 不跨入死亡權威、不直接複製 build |

Acquired 首批目標為 DESERT_HARDENED（荒野歷練）、CARAVAN_FRIEND（商路熟客）、HARD_BARGAINER（強硬商人）、KNOWN_HELPER（荒原善人）、SCAVENGER_INSTINCT（拾荒直覺）、DEATH_TESTED（死裡逃生）。每個未來條目必須同時具備可核對的歷史條件、現有機制支持的 gameplay effect、至少一個 tradeoff 或限制；否則不能算已實作。

候選來自本局 committed history，不是每級隨機三選一。需區分「符合資格」與「玩家取得」，允許保持原狀。20 天／援助次數等是示例，C4.5 再定計數窗口、同一事件去重、候選展示時機、拒絕後是否再出現、上限與存讀檔冪等。只能驗證資料中確實存在的事實；目前沒有求助者／傷勢／聲望真相，就不能推導「從未拋棄任何求助者」或憑空產生信任／體力效果。

Acquired 是世界經歷塑造人物；Perk 是玩家在歷練里程碑主動選擇的專長。兩者不能共用一個無來源的 Trait 清單，亦不合併成 Level 的固定獎勵。

角色死亡結束本人的 build，世界延續。S6 可以讓診所、裝備、人物記憶、背景可選性、Perk 路線或繼承候選留下來，但必須各有世界事實與權威。下一個人不自動繼承前任 Skills／Traits，不做帳號永久加點。這些是後續方向，不是 C0/C1 功能。
