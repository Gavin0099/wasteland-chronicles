# CHAR-2：人物與裝備比較

人物頁保留肖像、姓名／年齡／背景、等級、生命／歷練／生存負重、十項0–5技能、成長點、特質與特長。中央先顯示主手／身體／背包，再列實際持有的最佳機械與電子工具：個人知識等級和工具級別分開，不把工具當作技能。

正在追尋只呈現已聽過且目前選定的傳聞、真實進度與下一步。經歷來自既有聚落信任折疊、阿扳找回／交還扳手回條及重裝掠奪者實際交戰／結果；未發生的不列為成就。一般傳聞仍在自己的頁面。

行囊與裝備皆可「查看」；詳情顯示 Tier、Quality、固定詞綴、重量／基價和具體用途，對照同一欄目前裝備。武器顯示常態近戰／射擊、實際彈種與每次耗量、手邊彈數、撤退傷害；防具顯示防護／生存容量；背包顯示容量／敗退失水；工具顯示實體級別／方法。常態傷害含技能與同行支援，排除架勢及首回合快拔；條件效果另用文字說明，沒有Quality倍率或紅綠箭頭。

比較只在 detached world 副本裝備候選並讀既有規則。只有按下裝備才送既有 intent；角色／時間／世界不由 UI 寫入。面具與工程師工具沒有新增頭部或工具裝備槽；持有已生效時顯示返回人物。拒絕換裝時明示聚落或負重原因。保留舊裝備／成長／急救操作與相容成員，鍵盤焦點、Esc關閉與底部返回繼續可用。

本刀 UI／read-only projection；不新增存檔欄位、技能、戰鬥規則或經歷 authority。驗證包含實際 UI 裝備與原子拒絕、checked save、雙軌SHA-256／全域不變量、空／長名／持有獨特工具／固定詞綴等兩解析度實際畫面；全回歸、獨立 review 與遠端 gates 完成後才合併。真人遊玩接受未宣稱。

前一刀 GEAR-2E 已交付 PR57，merge a597f41c95acaeaa1d3a84bf4981118a367f294d；current-head Codex review／實際CI通過。遠端 P2 延後：Unique checked receipt 未要求面具取得先於工坊；兩日工程師程序中途代謝死亡仍可完成結算並 tick 第二日。另保留面具回條未提示切換追尋的 P2；本刀不修這些 gameplay authority 邊界。

驗證：32 focused assertions，真實詳情按鈕→裝備intent、超載拒絕／零變更、checked save、雙軌 SHA-256、全域不變量、真實阿扳回收與重裝交戰。112套Godot全回歸Exit0、無SCRIPT ERROR；%TEMP%/wc-char2-final-regression。24張OpenGL實際畫面已於1280×720、1152×648檢視，user_data/captures/char2；capture同時斷言詳情正文不能越過底部確認區。Lint0 errors／既有FieldScreen warning1；NPC authority fixtures／drift PASS。既有RID／ObjectDB退出清理訊息仍存在。

獨立review無未解決P0/P1；P2延後：遭遇待處理／結果待確認时換裝被原子拒絕，但泛用提示只說確認持有物品與欄位，沒有對應「先完成遭遇」（ui/playable_shell.gd _gear_change_reason）。GitHub current-head review／CI／merge尚待完成。
