# 獨立審查：擴充工具與 75 件用品／材料／貿易品

審查日期：2026-09-22。審查人：`item1_contract_tests` 子代理。

範圍限 DESIGN_ONLY 資料、引用、輸出隔離及內容邊界；沒有載入世界、
登錄物品、建立人口、改商店存貨，亦不宣稱已可玩或價格平衡。
本代理編寫了另 39 件遺物、120 個人物／異常遭遇與 150 個人物鉤子，
因此這些不是本報告的獨立內容審查範圍。用品 75 件與原始擴充工具由其他作者完成。

最終結果：PASS。作者凍結後，在基準 dataset
`d8c049092ce0e6bcdde3ac2ff4125f4cab94ffbd450d27b74a773855960ae1bb`
上執行完整流程；51 個負例全拒絕，合法四型包成功輸出 186／481／121／151 筆。
1,672 條 preview 本地連結與 anchor 全部解析成功，4 個新增記錄都實際呈現。
兩次相同 preview 的所有輸出逐字節一致，preview 後同程序重建 baseline 沒有輸出位置洩漏；
536 個受檢基準與 runtime 檔案沒有任何 byte 改動。這些是結構及輸出驗證，並非 gameplay gate。

## 發現與修正

| 原始獨立發現 | 影響 | 修正與證據 |
| --- | --- | --- |
| 非空判斷將 `cost_zh: 123`、數字型人物出現條件當作有效文字 | 錯誤資料可通過 checker；文字串接時才可能中斷輸出 | 在語義走訪前驗證四種記錄全部欄位與巢狀形狀；文字必須是非空字串 |
| `actions` 或 `dependencies` 的 object keys 可冒充字串陣列 | 下游讀到與契約不同的形狀 | 全部清單逐項驗證型別，不隱式轉換或只遍歷 keys |
| 分類示意圖可出現在維修投入／拆解產物 | 會把「彈藥、藥物、機械零件」分類提案當成實體 | 沿用 encounter 的實體引用邊界，拒絕分類圖的物理關係 |
| package 或 record 不是 object、`pack_id: []`、`requires_packs: null`、`art_file: null` | CLI 會拒絕，但直接 `check_packs()` API 拋未處理例外 | 在 regex、Path、set、`.get()` 等操作之前檢查完整 package／baseline 形狀；API 回傳 FAIL receipt |

根代理授權本審查人修正 `validate.py` 與 `check_extensions.py`，因此
**原始問題由獨立審查發現，修正後負例屬同作者回歸驗證**，不包裝成再次獨立批准。
修前實際結果保存在 [independent-extension-before-fix.json](independent-extension-before-fix.json)。
該舊報告將跨城利益群體列為失敗；根代理後來明確確認群體可跨城，因此此項不是缺陷，
修後以正例保留。未知群體仍拒絕。

另一項 `build()` 使用 module global 輸出位置的風險由根代理修正；最終檢查
同一程序依序建立 preview、再次建立相同 preview、再建立 baseline，檢查
preview 不被 baseline 蓋寫、基準內容與 runtime 檔案逐字節不變。

## 實際擴充流程

`extension-four-kind-fixture.json` 是明確標示的測試包，只放在 evidence，
不加入基準四庫。它新增一件引用既有圖片的物品、一個遭遇、一個人物鉤子與一個委託，
同包引用及基準引用都有實際走過 checker 與 builder。

預覽固定在 `extension-previews/independent-review/`，合併計數應為
186 物品、481 遭遇、121 委託、151 人物鉤子；正式基準仍為 185／480／120／150。
最終原始結果與每個 preview 輸出 SHA 見
[independent-extension-review.json](independent-extension-review.json)。

可重跑：

```text
python docs/content-design-v0/authoring/review_extensions_independent.py
python docs/content-design-v0/check_extensions.py --self-test docs/content-design-v0/evidence/extension-four-kind-fixture.json
```

第一支應在作者凍結且基準輸出已重建後執行。它有 51 個拒絕負例、四型正例、
宣告依賴的跨包正例、跨城利益群體正例、順序不變檢查、兩次相同預覽檢查，
並快照基準四庫、catalogue／derived 及 simulation／game_data／ui／tests／player
的檔案 SHA。預覽中的本地圖片、文件連結與 anchor 均實際解析，四種新增記錄也必須
出現在對應的閱讀稿中。型別錯置包含 item 作 issuer、person 作 item、event 作 relationship target。
另涵蓋未知 ID、schema、權限欄位、art path 越界及不可攜的絕對路徑、JSON 重複 key、
循環依賴與巢狀錯型別。素材路徑必須是以 `ui/assets/items/` 開頭的 repo 相對路徑；
即使絕對路徑指向同一張合法圖片仍拒絕，避免把內容包綁到單一機器磁碟。

## 用品／材料／貿易品的獨立內容檢查

[02-supplies-materials-trade.json](../items/02-supplies-materials-trade.json) 共 75 件，
75 個不同素材引用；其中 72 個實體候選、3 個分類摘要。結構性快照見
[independent-supplies-review.json](independent-supplies-review.json)。

| 檢查 | 判斷 |
| --- | --- |
| 水、燃料與容器 | 水壺 300g、燃料罐 900g 明示空容器；淨水 1100g、燃料 1000g 明示含包裝估重，不直換既有 aggregate resource |
| 套件與內物 | 工具箱、急救包、手術包及舊世醫療箱需要實際清點；沒有免費複製套內工具或醫用品 |
| 三種分類摘要 | 重量／價格空值，動作空陣列，供需 none，不能修理或拆解成實體 |
| 區域供需 | 225 筆都有具體用途理由；高供給與高需求可並存，沒有固定買價倍率、無限收購或自動人口效果 |
| 維修與拆解 | 濾水器外殼維修不恢復未知濾材，繩端標記維護不恢復承載纖維；拆解失去原物完整性，未宣稱等量回收 |
| 醫療與未知物 | 急救包不具 HP 指令，醫藥不承諾治癒；未標示藥劑沒有通用估價或試喝增益 |
| 既有權限 | runtime IDs 符合 seed，其他候選保持 null；沒有把圖片直接放入掉落或世界庫存 |

未發現需擋住這批 DESIGN_ONLY 用品稿的實質問題。仍不能據此宣稱配方質量／價值守恆：
目前只有象徵材料連結，缺乏產出數量、耗損與工時；流體容量、容器內容與真實價格也尚待
其對應 domain 契約。這些是已明示的後續實作缺口。
