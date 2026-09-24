# WPROG-4 — Next contract

乾井的「北線補給測繪」是第一份非交貨委託。玩家必須先在乾井裝備軍用背包才能接案；接案後親自抵達新希望，並在十天期限內回乾井回報。回報時仍須持有背包。成功給 150 瓶蓋、45 XP，並記錄 `dry_well_north_surveyed` 任務旗標。背包不會被交付或消耗。此旗標目前不更動路線、價格或聚落庫存，UI 也不宣稱這些後果。

`VISIT_LOCATION` 讀取既有 `NAMED_MIGRATION_COMPLETED` 世界紀錄，核對玩家身分、目標聚落，以及同一委託的 `QUEST_ACCEPTED` 事件順序。接案前到過新希望不算完成。所有接案、回報與報酬仍經過 QuestEngine 和 PlayerIntent，任務 UI 只讀 projection。

這個門檻讓 WPROG-3 的稀有發現變成可接的新工作，同時保留更大的背包對長程水糧準備的用途。它不是保證掉寶或新的商店供給；往返風險仍由既有旅途系統決定。

驗證：`tests/test_wprog_4_next_contract.gd` 覆蓋未裝備/已裝備資格、錯誤地點、接案前抵達、實際往返、一次性結算、存檔讀取、雙軌世界 SHA-256 與全域不變量；UI 須另以 1280×720 與 1152×648 的 Godot 畫面確認。
