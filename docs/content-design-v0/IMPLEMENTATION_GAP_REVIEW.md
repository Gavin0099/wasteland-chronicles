# 內容接線前的程式缺口檢查

基準：ITEM-1 local commit 87f6821。這是針對新內容將碰到的實際入口做唯讀檢查，
不是整個 repository 的安全稽核，也沒有修改 production/test code。

| 已觀察的程式事實 | 對內容擴充的影響 | 下個實作需要驗證什麼 |
| --- | --- | --- |
| simulation/item_catalogue.gd 讀取固定十二筆來源，沒有接到任務／掉落 | 定義存在不表示有實物；這是 ITEM-1 刻意的邊界 | 新實體的穩定 ID、單一 owner、數量、未知 ID 拒絕 |
| simulation/player_state.gd 的 inventory 是 ResourceState；負重是四資源數量加 Field.KIT_WEIGHT | 新物品的公克不能直接與現有容量20相加 | 提出單位橋接或獨立物品負重規則，保留既有重播結果 |
| simulation/resource_state.gd 只有 water/food/scrap/fuel | 水壺不等於water，廢鐵不自動等於scrap | 封裝／解封資源的守恆提交，不允許容器與內容物雙算 |
| simulation/field_adventure.gd 的 kit 是 hp/crowbar/equipped 小字典 | 已有撬棍示例，不能新增第二份可寫的撬棍所有權 | 明確遷移／橋接舊field schema，裝備狀態與負重只算一次 |
| simulation/player_intent.gd 是 WAIT/TRAVEL/BUY/SELL/RESOLVE_ENCOUNTER/CONTINUE_JOURNEY/FIELD_ACTION 的封閉集合 | 內容包的actions只是提案，不能任意呼叫動作 | 新意圖逐項授權、驗證與原子提交；失敗不改世界 |
| simulation/travel_encounter.gd 目前五類正式事件讀取世界事實，選擇仍由engine提交 | 480筆草案不可直接替換真實候選選取器 | 世界事實綁定、重驗、唯一結算、清楚結果面板與確認 |
| simulation/world_state.gd 具有progression/field schema邊界和ledger檢查 | 新工作狀態需要版本及保存規則，不能塞在敘事字串 | 接單／期限／取消／完成／領獎後save-load連續性與版本遷移 |
| ui/components/item_icon.gd 目前只認water/food/scrap/fuel/caps/crowbar | 185圖庫和十二定義不是現有UI清單 | 日後由正式item asset引用呈現，圖片失敗不能回傳假物品 |

## 先做的三個風險點

1. **物品與資源的橋接。** 先把物體和所有權講清楚，再接負重／商店。否則採買一個
   水壺可能被算成飲水，或同時保有一份資源和一份裝填物。
2. **任務完成只能一次。** 接受工作時綁真實對象與版本；交付與報酬同一交易完成。
   重按、讀檔、期限剛過、委託者遷移或死亡，都不能領兩次或補造發獎者。
3. **候選事實與世界真相分開。** 新地窖、事故、受助者只存在於設計稿。實作時要由
   正式世界／場所／NPC owner 建立或綁定，不以觸發文字偷偷生成。

## 有意保留而非漏接

- C2-B玩家體驗、完整C5裝備成長和ITEM-2以後仍未因本庫完成而關閉。
- 185物品估值、維修投入與材料圖不進經濟公式；完整價差／質量守恆尚無驗證。
- 150鉤子可由同一既有人物兼任不同情境，並不要求世界同時存在150個新NPC。
- 假技能、假武器或裝備圖片不能通過真正能力門檻；既有HP也不等於有正式醫療系統。
- 本輪沒有為上述未實作機制添加空殼runtime類別或mock-only測試。

## 後續真正上線時的測試清單

| 邊界 | 至少一個失敗案例 | 可觀察的證據 |
| --- | --- | --- |
| 物品移轉 | 不足、他人所有物、未知ID、超重 | 前後owner／庫存／世界SHA不變 |
| 同一獎勵 | 連點、重試、reload後再領 | 只有一次item移轉和一筆結算 |
| 任務時間 | 接受時已過期、途中到期、商隊先出發 | 依真實日期關閉，不倒退世界 |
| NPC綁定 | 人已遷移、死亡、不在可用人口 | atomic fail且人口守恆 |
| 新存檔schema | 缺版號、未知版號、破損instance引用 | 合法舊存檔明確遷移；壞存檔fail closed |
| 內容包更新 | 舊任務引用被刪除或換版本 | 明確退役／遷移，不重新生成物品 |

這些是缺口與驗收建議，並非宣稱測試已存在或本輪已獲實作授權。
本輪實際檢查見 VERIFICATION.md；ITEM-1先前41套Godot證據另在 artifacts/item-1。
