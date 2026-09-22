# Wasteland Chronicles — 內容設計庫 V0

本庫把物品、城鎮任務、荒野遭遇、人物利益和地區供需放在同一組可追查的資料裡。
所有內容均為 **DESIGN_ONLY**；遊戲並未因此新增 185 件正式物品、480 個遭遇或
150 個人口。ITEM-1 已實作的十二筆最小定義維持獨立。

## 先從這裡閱讀

| 內容 | 入口 |
| --- | --- |
| 第一輪實作候選：30 物品／15 遭遇／9 任務／10 NPC | [FIRST_PLAYABLE_SLICE.md](FIRST_PLAYABLE_SLICE.md) |
| 185 個既有美術名稱的完整內容稿 | [物品內容](catalogue/items.md) |
| 新希望的 40 任務／50 人物鉤子 | [任務](catalogue/quests-new_hope.md) · [人物](catalogue/npc-new_hope.md) |
| 灰谷的 40 任務／50 人物鉤子 | [任務](catalogue/quests-gray_valley.md) · [人物](catalogue/npc-gray_valley.md) |
| 乾井的 40 任務／50 人物鉤子 | [任務](catalogue/quests-dry_well.md) · [人物](catalogue/npc-dry_well.md) |
| 100 荒野／100 聚落／60 商隊遭遇 | [荒野](catalogue/encounters-wilderness.md) · [聚落](catalogue/encounters-settlement.md) · [商隊](catalogue/encounters-caravan.md) |
| 100 遺跡／80 人物／40 奇物遭遇 | [遺跡](catalogue/encounters-ruins.md) · [人物](catalogue/encounters-npc.md) · [奇物](catalogue/encounters-anomaly.md) |
| 四庫引用、物品使用密度、缺口 | [矩陣報告](derived/MATRIX_REPORT.md) · [完整語義連結 JSON](derived/world-links.json) |
| 三聚落供需／取得來源 | [供需矩陣](derived/ECONOMY_MATRIX.md) · [555 筆理由](derived/settlement-economy.json) · [取得來源](derived/loot-sources.json) |
| 製作、維修與拆解關係 | [12 個製作方向](crafting-proposals.json) · [材料關係](derived/material-relations.json) |
| 之後如何擴充 | [EXTENDING.md](EXTENDING.md) · [內容包起始檔](extension-template.json) |
| 審核與驗證 | [REVIEW.md](REVIEW.md) · [VERIFICATION.md](VERIFICATION.md) |
| 內容接入既有程式的缺口 | [IMPLEMENTATION_GAP_REVIEW.md](IMPLEMENTATION_GAP_REVIEW.md) |

物品不是單一傷害值：每件都有來源、買家、已知／調查後描述、兩個有成本的用途，
以及缺少的 gameplay 權限。三張「彈藥／藥物／機械零件」分類示意圖只作家族摘要，
不當作可重複的實體物品。鹽和電池各只保留一個 ID，跨分類共享。

## 參考了什麼

- [《俠客遊：前途道標》官方資料研究](research/lunatic-dawn.md)：地域取得、日常工作、
  危險探索及人生延續。精確辨認 ARTDINK 的 Passage of the Book，未採用未查證的
  「400 件物品」數字或別代作品的規則。
- [廢土遊戲研究](research/wasteland-games.md)：CDDA、Underrail、Kenshi、Wasteland 3、
  Metro Exodus、S.T.A.L.K.E.R. 2 的工具條件、買家差異、準備成本與選擇後果。
- [小說研究](research/wasteland-fiction.md)：Roadside Picnic、The Road、A Canticle for
  Leibowitz、Wool、Metro 2033 的未知物、援助代價、知識保存與聚落路線。

研究採開發者、官方文件、作者或出版社可讀資料。各筆 inspiration_refs 可回查研究 ID。
外部作品的事實與我們的原創設計推論分開；沒有移植角色、任務對白或專有物品設定。
研究日期為 2026-09-22；來源不等於所有遊戲版本都已親自遊玩驗證。

## 資料與權限

- authoring 下保存本批的原始作者稿；items、encounters、quests、npc-hooks 下的 JSON
  是可交換與檢查的內容稿，由作者稿重產。修改 V0 基準時先修改作者稿並重建，勿只改
  生成 JSON；新增內容則依 EXTENDING.md 建獨立資料包，不必更改這些作者工具。
- catalogue 和 derived 是閱讀版／矩陣，不是另一份可寫真相；由 build_reference.py 生成。
- [原始內容契約](DESIGN_CONTRACT.md)及[城鎮任務契約](TOWN_LIBRARY_CONTRACT.md)定義欄位；
  [世界與經濟邊界](ECONOMY_AND_AUTHORITY.md)解釋哪些事仍需正式權限。
- 新內容包使用獨立命名空間與版本；同 schema 可加資料，不需要把既有 185 筆重新編號。
  新 mechanic 則要先有正式 owner；加一個 tag 不等於實作了一種動作。

## 重建與檢查

在 repo root 執行：

    python docs/content-design-v0/validate.py
    python docs/content-design-v0/check_extensions.py --self-test
    python docs/content-design-v0/build_reference.py
    python docs/content-design-v0/build_shortlist.py

若修改本批原始作者稿，執行下列命令重產基準 JSON、閱讀版、矩陣與候選清單：

    python docs/content-design-v0/rebuild_content.py

這個命令會覆寫基準 JSON，使用前先保存變更。它只執行明列的 repo 作者工具，
不執行擴充包內容。一般新增物品／任務應使用獨立 JSON 包及預覽命令。

驗證器檢查數量、固定素材綁定、十二筆已定重量、重複 ID、未知引用、技能範圍、
分類示意圖誤用、三地供需、任務期限與人物關係。它也實際執行負向 fixtures。
這些檢查證明資料結構與引用符合契約；**不證明有趣、平衡或可以直接上線**。
玩家體驗與 gameplay authority 的測試仍屬後續可玩切片。
