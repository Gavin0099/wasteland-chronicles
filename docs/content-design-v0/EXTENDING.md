# 如何新增物品、任務、遭遇與人物

本批 185／480／120／150 是 V0 的完整驗收基準，不是總量上限。新增內容放在獨立
JSON 內容包，沿用四種 record schema；檢查器不會安裝它，也不改基準 JSON。

## 實際新增流程

1. 複製 extension-template.json，填 pack_id 與正整數 pack_version。
2. 新 ID 使用 pack_<pack_id>__item__<slug>、__encounter__、__quest__、__person__。
   ID 不依名稱、中文翻譯、陣列位置或亂數而改變；同名不同物需要不同 ID 與用途理由。
3. 將相同 schema 的完整 records 放入 items、encounters、quests、npc_hooks。
   新物品可引用既有 PNG，但 runtime_item_id 必須為 null。新圖先經美術流程存入
   ui/assets/items，再引用 repo 相對路徑；不使用本機磁碟絕對路徑，也不得把外部路徑
   或程式放進內容包。
4. 可引用基準物品／人物／事件；引用其他內容包時必須將對方 pack_id 列入
   requires_packs，並一併交給檢查器。不能用缺失引用表示「之後再補」。
5. 執行 python docs/content-design-v0/check_extensions.py path/to/pack.json。
   多包可依任意順序列出；檢查結果及合併資料指紋應相同。
6. 重建含擴充資料的閱讀版與矩陣時，執行：

       python docs/content-design-v0/build_reference.py --extension path/to/pack.json --output docs/content-design-v0/extension-previews/example

   可重複指定 --extension。輸出必須在 extension-previews 下，避免覆寫本批基準產物。
7. 人工審核來源、物品流向、期限、互斥後果、沒有工具時的解法與實作缺口。
   結構 PASS 不代表好玩、數值平衡或已獲實作授權。

空 template 是合法起點，不增加任何內容。self-test 會在記憶體裡新增四種類型，
測跨引用、未知 ID、重複 ID、越界圖片、未來版本、假技能、偷放傷害欄位與順序穩定性。
這些 probe 不計入交付數量，也不寫進遊戲。

## 哪些變更只動資料

| 變更 | 處理方式 |
| --- | --- |
| 同 schema 的新物品、工作、人物、遭遇 | 新增內容包，引用既有類別／技能／聚落 |
| 名稱、描述、傳聞勘誤 | 保留 ID；提高 pack_version，重新檢查引用與結果 |
| 補藝術素材 | 保留既有物品 ID；明示圖片對應變更，不能默默重綁 runtime 資產 |
| 新能力、新代價、新數值 owner | 先開獨立 authority slice；不能只加 action tag 讓它執行 |
| 新聚落、技能、類別或關係機制 | 先更新對應 domain 契約與 validator，再提高 schema 版本 |
| 刪除／合併已被引用的 ID | 先找所有反向引用，定義 replacement／退役與保存策略，不直接重用舊 ID |
| 已上線任務修改期限或步驟 | 未來需 active quest version 固定或正式遷移；不能讓讀檔重新發獎勵 |

schema_version 表示格式；pack_version 表示內容修訂；runtime save schema 是另一層。
requires_packs 目前宣告包名，檢查憑證會列出本次各包的 pack_version；尚未提供
相依版本區間、自動選版本或跨版本相容性判定。保存內容時須一併保存使用的包版本。
目前 extension checker 只接受 schema_version=1，未知版本拒絕。它不實作遊戲存檔
遷移、內容包載入器、熱更新或模組執行。這些缺口不能用資料量掩蓋。

目前的 cost_zh、outcome_zh 和世界效果描述是設計語言，不是可執行DSL。
日後提升為玩法時，應將選定方案轉成已註冊的 requirement／intent／receipt，
並用正式 quantity、時間與owner欄位表示變更。不得讓LLM解析句子直接修改世界，
也不要為每條新任務在engine新增一段特例。新內容包在同一套已授權動作內組合；
超出動作集合才開新的機制切片。

## 為未來 runtime 保留的邊界

- Definition、實體 ownership、裝備效果、價格、工作狀態分開。存檔存 ID 與可變實例，
  不複製一份定義變成另一個可寫來源。
- 任務引用工具與世界事實，不把技能檢查當作修理成功、也不把傳聞當已存在地點。
- 時限沿用世界唯一時計。任務 instance 將來需 instance_id、definition_id、version、
  binding、接受日、狀態與結算憑證，避免重播／讀檔重複交付。
- 所有權轉移與世界後果需原子 commit；唯一物品與現有人口綁定不能複製。
- 變更包時先跑四庫引用檢查，再重建矩陣；真正 gameplay 改動另跑該 slice 的 Godot
  重播與不變量測試。本次 Python 檢查不能取代它們。
