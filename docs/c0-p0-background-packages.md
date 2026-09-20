# C0-P0 — Background Package Mapping

狀態：CLOSED。Owner 在本次 task 明確回覆「核准這四組 mapping」；版本 1 catalogue 按下表實作。

沿用既有四個 stable ID，不新增背景。每列技能互異，完整十技能向量為 2／1／1，其餘七項 0；Trait 與 Aptitude 不改變 ranks。

| background_id | Primary 2 | Secondary A 1 | Secondary B 1 | 對應既有身份 |
| --- | --- | --- | --- | --- |
| CARAVAN_GUARD | FIREARMS | MELEE | SURVIVAL | 商隊守衛：武裝防衛與在途求生 |
| MECHANIC | MECHANICS | ELECTRONICS | SCAVENGING | 機械師：機械、電路與零件辨識 |
| FARMER | SURVIVAL | MECHANICS | BARTER | 農夫：基本求生、農具維護與物資交換 |
| SCAVENGER | SCAVENGING | SURVIVAL | STEALTH | 拾荒者：找物資、荒野活動與避開危險 |

映射直接使用同名 `NpcProfile.Background`；不重排既有 enum。槍械／近戰 rank 是能力資料，不代表 Combat 已存在。此表只影響新角色創角；舊存檔照凍結契約遷移為十技能全零。

驗收：Owner review 已完成。版本 1 catalogue 與獨立 expected fixtures 逐列實作／驗證，沒有新增未核准背景。
