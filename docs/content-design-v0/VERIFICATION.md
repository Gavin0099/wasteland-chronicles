# 內容設計 V0 驗證紀錄

日期：2026-09-22。基準 commit：87f682168aa47ca36c637d458662490ab30fc905。
分支：codex/encounter-result-feedback。這是內容設計與 Python 編輯工具驗證，
不是新的 Godot gameplay gate。遊戲程式、現有測試、圖片與正式十二筆物品均未修改。

## 完整交付

| 內容 | 實際數量 |
| --- | ---: |
| 物品內容稿 | 185（182實體候選、3分類摘要） |
| 物品用途情境 | 370 |
| 遭遇 | 480：荒野100、聚落100、商隊60、遺跡100、人物80、奇物40 |
| 遭遇選項 | 1,448 |
| 城鎮任務 | 120：每城40，共360方案 |
| 人物／關係鉤子 | 150：每城50，共150關係 |
| 利益群體分類 | 12；未註冊為派系 |
| 三城供需記錄 | 555 |
| 四庫語義連結 | 2,416 |
| 維修／拆解／製作關係 | 434，含12個象徵性製作方向 |
| 首輪範圍提案 | 30物品／15遭遇／9任務／10人物 |

首輪選項沒有引用30件以外的物品；十個人物的完整個人鉤子仍有額外引用，已逐項
列為延後內容。選職務不等於把整條人物支線帶入實作。

保留的缺口：52件沒有四庫引用（含3分類摘要）、55實體候選未進遭遇、137條目沒有
具體獎勵入口。完整 ID 名單見 [矩陣報告](derived/MATRIX_REPORT.md)，沒有為補比例
而填造掉落。估值、重量與材料方向尚未經玩法平衡或完整守恆驗證。

## 執行過的檢查

| 命令／檢查 | 結果與證據 |
| --- | --- |
| python docs/content-design-v0/validate.py | PASS：完整185／480／120／150、10個反例；[原始receipt](derived/validation-receipt.json) |
| python docs/content-design-v0/check_extensions.py --self-test docs/content-design-v0/evidence/extension-four-kind-fixture.json | PASS：16個反例、四型新增、跨包引用、包順序不影響結果、基準不變 |
| python docs/content-design-v0/rebuild_content.py，連續兩輪 | PASS：41生成檔逐字節相同；原作者稿可重產相同JSON；[逐檔SHA](evidence/reproducibility.json) |
| 生成閱讀版／矩陣／首輪清單的本地連結 | 1,727條檔案及anchor引用可解析；同上receipt |
| python docs/content-design-v0/authoring/review_extensions_independent.py | PASS：51個負例、四型真實preview、1,672連結；[完整證據](evidence/independent-extension-review.json) |
| preview → 相同preview → baseline，同一程序 | PASS：preview不污染下一次基準輸出、兩次preview逐字節相同、536個基準及runtime檔案沒有變化 |
| git diff --exit-code 87f6821 -- simulation ui tests tools game_data | Exit 0，無production／test差異 |
| git status --porcelain -- simulation ui tests tools game_data player | 0行，沒有新production／test檔案 |

三組反例有重疊，不能將10＋16＋51當成77種獨立語意證明。它們實際執行驗證器，
涵蓋有效正例及拒絕分支，沒有只比較同一份生成器算出的期望值。

四型驗證包的預覽數量為186／481／121／151。測試包只在evidence，預覽輸出位於
被gitignore排除的extension-previews；不算入基準交付，也沒有載入遊戲。

## 指紋與重產範圍

完整四庫 canonical JSON SHA-256：

    d8c049092ce0e6bcdde3ac2ff4125f4cab94ffbd450d27b74a773855960ae1bb

四庫先依穩定ID排序，object keys固定排序，再以UTF-8計算。沒有時間戳。
逐檔byte一致性是在本次Windows環境觀察；Git可能正規化行尾，不宣稱換平台後所有
Markdown／JSON檔案byte都相同。canonical資料指紋不受這種行尾正規化影響。

原始作者稿的正常重建不再執行一次性refine工具；town_caravan是唯一城鎮事件來源，
之後才產出引用它的核心任務。退役入口不讀寫資料。這避免正常重建重寫另一份作者稿。

## 審查發現與限制

獨立審查及整合檢查已修正免費繞過障礙、到期物資瞬移、跨城NPC當日到場、重複
報酬、錯誤的玩家持物門檻，以及格式驗證漏接。198個半天成本已按內容分為135個
零天現場互動和63個一天工作／等待，全480事件與120任務成本的半日單位殘留為0。
成本仍是設計提案，零天互動的有限來源與一次性提交需在實作時測試。

任務引用不全是共享scene：非核心改編與可選線索已在各筆followup區分。共享工作
才使用同一物資與結算憑證，尚未宣稱120任務都能直接接入執行流程。

詳細範圍與修正見 [整合審查](REVIEW.md)、[獨立內容審查](INDEPENDENT_CONTENT_REVIEW.md)、
[抽核](CONTENT_SPOT_REVIEW.md)及[工具／用品審查](evidence/INDEPENDENT_REVIEW.md)。
工具首次獨立發現與審查者自己完成的後續修正分開記錄，修前FAIL原始證據仍保留。

本輪未重跑41套Godot測試，因為沒有runtime或現有test code變更；ITEM-1先前的
41套PASS與世界SHA證據在artifacts/item-1，不能冒稱本輪設計庫的玩法測試。
不宣稱新增遊戲物品、任務系統、裝備效果、醫療、派系、熱更新、存檔遷移或玩家樂趣驗收。
