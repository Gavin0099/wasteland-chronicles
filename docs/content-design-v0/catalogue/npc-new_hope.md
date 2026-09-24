# 新希望人物與關係鉤子

DESIGN_ONLY；是角色候選，沒有新增150人口。

<a id="hook_new_hope_001"></a>
## hook_new_hope_001 · 水務保管人

公開需要：追回借出扳手並分清供水與農務的領用時段。
個人利害：怕漏記借具被當成私用公物，不願先答應修好水泵。
能提供：能提供當前借具簿與有權查驗的設備位置。
限制：不能因職務控制玩家飲水或認定陌生人偷工具。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『水務保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：借具尚未歸還且本次輪值仍由其負責。
不介入：若原借用人先歸還，關閉催還需求；若交班，只把已核對資料移交實際接班者。

物品：[扳手](items.md#content_wrench)、[繩索](items.md#content_rope)
遭遇：[輪到你的空水壺](encounters-settlement.md#town_001)、[水務保管人的借具簿](encounters-npc.md#npc_001)

- [種庫照管人](npc-new_hope.md#hook_new_hope_002)：分歧：種庫也要同一套工具，兩份已承諾時間互相衝突。 合作：共同核對領用簿可少做一次重複交接。

利益群體：nh_water_stewards。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_new_hope_002"></a>
## hook_new_hope_002 · 種庫照管人

公開需要：固定破角種箱並保留批次標記再分送。
個人利害：不願把分發延誤算在新住民頭上，也怕失去種子出處。
能提供：持有當前封條清單，能批準有限外觀查驗。
限制：不能憑目視保證發芽，也不能重複交付同一批種子。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『種庫照管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：待分箱仍在庫內且沒有其他人完成同一修補。
不介入：若箱已由另一工人妥善處理，取消借繩工作；原分發依有效承諾繼續，不等玩家。

物品：[繩索](items.md#content_rope)、[種子](items.md#content_seeds)、[防水袋](items.md#content_waterproof_bag)
遭遇：[種庫的兩種袋口](encounters-settlement.md#town_002)、[種庫照管人的破角箱](encounters-npc.md#npc_002)

- [水務保管人](npc-new_hope.md#hook_new_hope_001)：分歧：想先用工具修箱，水務卻有在先領用承諾。 合作：交換可驗證時段能讓兩邊各保住必要工作。

利益群體：nh_growers。前置缺口：cargo、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_003"></a>
## hook_new_hope_003 · 診療所收貨人

公開需要：補驗急救包外包與交付清單空格。
個人利害：擔心簽下未見內容害後續缺料者找錯責任人。
能提供：可安排原送貨人與可查的簽領紀錄。
限制：無資格憑封面替未知藥作安全認證。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『診療所收貨人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：封閉用品尚待驗收且現任保管者同意查驗。
不介入：若正本送達就改成核對工作；若已合法退貨，原驗收請求失效，不再憑空補一箱。

物品：[急救包](items.md#content_first_aid_kit)、[醫療手冊](items.md#content_medical_manual)
遭遇：[診所怕雨的收貨單](encounters-settlement.md#town_003)、[診療所收貨人的空格](encounters-npc.md#npc_003)

- [外營用品聯絡人](npc-new_hope.md#hook_new_hope_018)：分歧：外營用品聯絡人急需放貨，不願等完整清單。 合作：先分出可驗與未驗項目可讓有限的實物先依法交接。

利益群體：nh_clinic。前置缺口：cargo、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_004"></a>
## hook_new_hope_004 · 灌溉時段抄錄人

公開需要：把兩隊各自記的開閘時刻對上可共同見證的交班點。
個人利害：自己的時計會漂移，不想以不準時間懲罰鄰田。
能提供：能出示不同版本的手寫值班條。
限制：沒有權限改世界日數或強迫停水。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『灌溉時段抄錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：兩份當日紀錄仍可查且尚未裁定交班爭議。
不介入：若雙方已共同完成下一次交班，新工作改為補記；不改寫過去已發生的供水。

物品：[舊世界手錶](items.md#content_old_world_watch)、[紙本日記](items.md#content_paper_journal)
遭遇：[水務保管人的借具簿](encounters-npc.md#npc_001)、[老照片裡的井壁](encounters-npc.md#npc_020)

- [水務保管人](npc-new_hope.md#hook_new_hope_001)：分歧：保管人要求按舊簿辦，抄錄人認為時刻來源未校準。 合作：共同保留原始記錄可避免互相推責。

利益群體：nh_water_stewards、nh_growers。前置缺口：item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_new_hope_005"></a>
## hook_new_hope_005 · 井繩檢查工

公開需要：先辨認井架繩索的借用人與可見磨損，再提維護安排。
個人利害：怕原主臨行要收繩，自己卻被要求保證井架全天可用。
能提供：熟悉目前可合法接近的綁點與交班人。
限制：目視不能認證全部承重，不得私扣借物。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『井繩檢查工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：該繩仍在井架且有合法檢查窗口。
不介入：若繩已按約歸還，改為尋替代方案；不能自動從公庫生出新繩。

物品：[繩索](items.md#content_rope)、[工程護目鏡](items.md#content_engineering_goggles)
遭遇：[不想上鎖的水袋](encounters-npc.md#npc_019)、[排水溝旁的借鏟](encounters-npc.md#npc_016)

- [水務保管人](npc-new_hope.md#hook_new_hope_001)：分歧：保管人想留下繩，檢查工堅持到期先詢問原主。 合作：把用途與歸還時間寫清可減少臨時停工。

利益群體：nh_water_stewards。前置缺口：cargo、hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、repair、reputation。研究：FICTION-METRO、FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_006"></a>
## hook_new_hope_006 · 排水溝清理人

公開需要：只清理已確認的表層落葉，避免碰到未知管線。
個人利害：想證明普通清溝工作也值得付工錢，不願冒險挖深。
能提供：可指出可見堵塞位置與上次處理範圍。
限制：無權挖鄰田或宣布舊管線安全。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『排水溝清理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：表面堵塞仍存在且管理者允許進入。
不介入：若其他人先清完，按實際範圍驗收並關閉；不製造新的堵塞等玩家。

物品：[工兵鏟](items.md#content_entrenching_shovel)、[地質調查圖](items.md#content_geological_survey_map)
遭遇：[排水溝旁的借鏟](encounters-npc.md#npc_016)

- [灌溉時段抄錄人](npc-new_hope.md#hook_new_hope_004)：分歧：抄錄人想趕在輪灌前完工，清理人只答應有限範圍。 合作：公開已完成與未處理段落能合理排下一班。

利益群體：nh_water_stewards、nh_growers。前置缺口：hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、repair。研究：FICTION-METRO、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_007"></a>
## hook_new_hope_007 · 領水見證人

公開需要：讓新來者能看懂現行領水順序與已有承諾。
個人利害：擔心自己的親友被誤認插隊，不願代填未到場人。
能提供：能提供當日排隊記錄和見證者。
限制：不能額外生成水、名額或給朋友免排權。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『領水見證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當前隊伍尚在且名額仍由現任管理者核對。
不介入：若隊伍已散或輪值結束，改查交接記錄；不召回離開的居民。

物品：[水壺](items.md#content_water)、[紙本日記](items.md#content_paper_journal)
遭遇：[不想上鎖的水袋](encounters-npc.md#npc_019)、[嫌麻煩的濾水器](encounters-npc.md#npc_021)

- [新住民聯絡人](npc-new_hope.md#hook_new_hope_010)：分歧：新住民聯絡人要求快速照顧急件，見證人怕破壞原順序。 合作：先辨明實際已到與未到的人可減少雙重登記。

利益群體：nh_water_stewards、nh_newcomers。前置缺口：cargo、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、reputation、water_treatment。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_008"></a>
## hook_new_hope_008 · 糧袋秤重人

公開需要：在交貨前分清包材重量與實際可驗的貨物份額。
個人利害：自己曾忘記記空袋重量，不想讓搬運人承擔猜測損耗。
能提供：可以出示原秤具與尚未拆散的貨袋。
限制：不能自創公升公斤與既有 food 總量的換算。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『糧袋秤重人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：同批貨仍未結算且有見證稱量條件。
不介入：若買賣已正式完成，只能保存後續勘誤，不追回已消耗食物或改歷史數量。

物品：[布袋](items.md#content_cloth_sack)、[乾糧](items.md#content_food)
遭遇：[乾糧袋裡的私人標記](encounters-npc.md#npc_018)、[想換成咖啡的工錢](encounters-npc.md#npc_023)

- [種庫照管人](npc-new_hope.md#hook_new_hope_002)：分歧：種庫想先分貨，秤重人要求保留至少一組原始記錄。 合作：共同逐袋簽領可使批次流向可追溯。

利益群體：nh_growers。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_009"></a>
## hook_new_hope_009 · 還種批次核對人

公開需要：分開居民歸還的不同批次種子，不用相似外觀當成同種。
個人利害：怕被說刻意刁難回收少的家庭。
能提供：掌握借出與歸還日期的文書副本。
限制：不能因還種不足直接發明偷竊或農業失敗。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『還種批次核對人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：歸還袋尚未混合且原領種紀錄可查。
不介入：若原主撤回交還，停止驗收；若已依法混袋，坦承來源無法完全還原。

物品：[種子](items.md#content_seeds)、[種植手冊](items.md#content_planting_manual)
遭遇：[替種子找名字的人](encounters-npc.md#npc_014)、[雨前的種子領取人](encounters-npc.md#npc_030)

- [種庫照管人](npc-new_hope.md#hook_new_hope_002)：分歧：照管人想快點重新分裝，核對人要求先保留來源袋。 合作：共同建立批次代號能減少混種疑問。

利益群體：nh_growers。前置缺口：cargo、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-02、WG-04、WG-06。

<a id="hook_new_hope_010"></a>
## hook_new_hope_010 · 新住民聯絡人

公開需要：把取水、短工與借用品的實際窗口說清楚。
個人利害：不願為得到幫助替新來者編造身分或悲劇。
能提供：能聯繫已同意分享經驗的在場居民。
限制：不代表所有新來者，也無權增加聚落人口。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『新住民聯絡人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有已存在的在場居民自願提出需求。
不介入：若對方自行找到工作或按正式遷徙離開，更新聯絡狀態，不把玩家未幫忙當死亡原因。

物品：[身分證件](items.md#content_identity_document)、[水袋](items.md#content_waterskin)
遭遇：[不接受猜測的尋人表](encounters-npc.md#npc_026)、[帳篷要先留給病人嗎](encounters-npc.md#npc_024)

- [領水見證人](npc-new_hope.md#hook_new_hope_007)：分歧：對急需援助者想加快服務，見證人要遵守已有承諾。 合作：共同分辨緊急需求與缺失文書可找到合法安排。

利益群體：nh_newcomers。前置缺口：camping、cargo、identification、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-04。

<a id="hook_new_hope_011"></a>
## hook_new_hope_011 · 菜圃繫繩幫工

公開需要：用安全可握的工具或徒手解結整理攀架。
個人利害：自己的獵刀是借來的，怕留下便無法按時歸還。
能提供：知道哪些結可鬆開，能提供當次工作驗收範圍。
限制：不承諾處理食物，不私自拿走玩家刀具。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『菜圃繫繩幫工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：攀架尚未整理且雇主允許進場。
不介入：若其他短工已解完結，本次工作結束；刀具按實際借用紀錄歸還。

物品：[生鏽小刀](items.md#content_rusted_knife)、[獵刀](items.md#content_hunting_knife)、[繩索](items.md#content_rope)
遭遇：[削繩的小刀](encounters-npc.md#npc_011)

- [獵具保管人](npc-new_hope.md#hook_new_hope_012)：分歧：獵具保管人重視刀口保存，幫工只想快速解完繫繩。 合作：先挑可徒手解的段落可減少借刀時間。

利益群體：nh_growers。前置缺口：equipment、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_012"></a>
## hook_new_hope_012 · 獵具保管人

公開需要：保留獵刀缺口的來源記號，再決定可否磨修。
個人利害：擔心好心磨刀反而抹掉家族寄物特徵。
能提供：保存前次交接時的刀柄與刀口描述。
限制：沒有權利把有紀念意義的借物當一般庫存出售。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『獵具保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原刀尚在且所有人仍同意討論維修。
不介入：若原主領回，停止代理維修；不為玩家重新造一把同名紀念刀。

物品：[獵刀](items.md#content_hunting_knife)、[皮革](items.md#content_leather)
遭遇：[獵刀的缺口誰磨](encounters-npc.md#npc_012)

- [菜圃繫繩幫工](npc-new_hope.md#hook_new_hope_011)：分歧：幫工需要立即可用的刀，保管人不願犧牲辨識特徵。 合作：提供另一件合法工具能讓寄物保持完整。

利益群體：nh_growers。前置缺口：equipment、item_ownership、jobs、knowledge、npc_relationship、repair。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_new_hope_013"></a>
## hook_new_hope_013 · 棚邊圍籬住戶

公開需要：先確認哪些枝條支撐圍籬，再準許清理。
個人利害：怕菜圃擴張吃掉自己的出入口，卻也需要排水通暢。
能提供：知道圍籬上次補修位置與可見界標。
限制：私人說法不是土地權威，不能直接封路。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『棚邊圍籬住戶』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：枝條與界標仍在，雙方尚未同意施工。
不介入：若管理者已有可核實裁定，按新條件重驗；沒有裁定就保留爭議，不強行拆牆。

物品：[廢鐵砍刀](items.md#content_scrap_machete)、[繩索](items.md#content_rope)
遭遇：[廢鐵砍刀與棚邊枝條](encounters-npc.md#npc_013)、[老照片裡的井壁](encounters-npc.md#npc_020)

- [排水溝清理人](npc-new_hope.md#hook_new_hope_006)：分歧：清理人想去掉枝葉，住戶希望先有替代支撐。 合作：共同標出不影響通路的處理範圍。

利益群體：nh_growers、nh_newcomers。前置缺口：equipment、hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、repair、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_014"></a>
## hook_new_hope_014 · 儲種外觀整理人

公開需要：把未知種粒先編號與分袋，不急著取好聽名字。
個人利害：想做出可靠記錄，怕自己的猜測被商人當認證。
能提供：能提供可比較外觀與原袋位置。
限制：不能憑種植背景宣告可食、耐旱或高產。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『儲種外觀整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：未知種粒仍封存且有合法查驗同意。
不介入：若專業鑑定已完成，改用正式結果；若樣本消耗，不生成替代樣本補研究。

物品：[種植手冊](items.md#content_planting_manual)、[灰種](items.md#content_gray_seed)、[布袋](items.md#content_cloth_sack)
遭遇：[替種子找名字的人](encounters-npc.md#npc_014)、[要把灰種賣給誰](encounters-npc.md#npc_027)

- [還種批次核對人](npc-new_hope.md#hook_new_hope_009)：分歧：批次核對人看重交付日期，整理人關心袋內已混的外觀差異。 合作：兩份資訊並列能保留不確定性。

利益群體：nh_growers。前置缺口：hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、FICTION-ROADSIDE、LD-P02、WG-02、WG-04、WG-06。

<a id="hook_new_hope_015"></a>
## hook_new_hope_015 · 醃藏工作承接人

公開需要：為當次保存工作找有限鹽料並確認誰先到期。
個人利害：怕每次急件都要讓給出價較高的外來買家。
能提供：能列出已有食物與工作窗口，不只是泛稱需求高。
限制：沒有權利把鹽直接換成永久食物保存效果。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『醃藏工作承接人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當次食物與委託仍存在，鹽尚未另行售出。
不介入：若來源已合法賣出，重新報缺額或終止；不虛構另一車鹽填補。

物品：[鹽](items.md#content_salt)、[罐頭](items.md#content_canned_food)
遭遇：[第一袋鹽該給誰](encounters-npc.md#npc_017)

- [小額鹽料商販](npc-new_hope.md#hook_new_hope_034)：分歧：商販想把鹽帶去外地，承接人想保住本地已約定份額。 合作：公開現有承諾可讓剩餘批次合法交易。

利益群體：nh_growers。前置缺口：cooking、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_016"></a>
## hook_new_hope_016 · 食物箱保管人

公開需要：確認不冷的冰是否能與食物接觸，先把未知樣本分開。
個人利害：想少浪費食物，但不願承擔未驗證冷藏的保證。
能提供：有可提供對照的空箱與現有食物紀錄。
限制：不能由降溫現象判斷可食性或保存期限。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『食物箱保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍在且管理者同意隔離測試。
不介入：若已有正式安全結果，重新評估；若樣本被交走，試驗邀請關閉而非免費複製。

物品：[不冷的冰](items.md#content_uncold_ice)、[防水袋](items.md#content_waterproof_bag)
遭遇：[借冰的午餐箱](encounters-anomaly.md#anomaly_002)

- [醃藏工作承接人](npc-new_hope.md#hook_new_hope_015)：分歧：醃藏人想等可靠方法，保管人急於試試新樣本。 合作：先做與食品分離的有限觀察可降低爭議。

利益群體：nh_growers。前置缺口：cargo、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROAD、FICTION-ROADSIDE、LD-P02、WG-04。

<a id="hook_new_hope_017"></a>
## hook_new_hope_017 · 舊衣裁補人

公開需要：替舊工作服補口袋，保留原領用標記。
個人利害：希望裁補被看成正式勞動，而非用剩布就不必付工錢。
能提供：掌握可見縫線與能完成的小修範圍。
限制：不能替身份不明的人編造工作資格。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『舊衣裁補人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：衣物仍由合法持有人委託且材料可確認。
不介入：若物主先取回，取消後續工作；未完工只如實交接，不自動扣聲望。

物品：[舊工作服](items.md#content_work_clothes)、[布料](items.md#content_cloth)
遭遇：[帶班工的衣物標記](encounters-npc.md#npc_004)、[帳篷要先留給病人嗎](encounters-npc.md#npc_024)

- [新住民聯絡人](npc-new_hope.md#hook_new_hope_010)：分歧：聯絡人想先支援新來者，裁補人有在先承諾的衣物。 合作：可分出急需遮蔽的小修與可等待的大修。

利益群體：nh_growers、nh_newcomers。前置缺口：camping、cargo、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-04。

<a id="hook_new_hope_018"></a>
## hook_new_hope_018 · 外營用品聯絡人

公開需要：先送出已點驗的繃帶與日用品，未驗貨另等正本。
個人利害：自己的親人也在外營，不願讓私情變成插隊理由。
能提供：知道哪幾份領取要求已被正式接受。
限制：不代表每個病人，不能憑急迫故事跳過物資守恆。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『外營用品聯絡人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：外營需求由已存在人口提出且尚未被滿足。
不介入：若需求者正式離開、拒收或已有補給，關閉對應份額，不因等待玩家製造病情惡化。

物品：[繃帶](items.md#content_bandage)、[醫療袋](items.md#content_medical_satchel)、[急救包](items.md#content_first_aid_kit)
遭遇：[診療所收貨人的空格](encounters-npc.md#npc_003)、[帳篷要先留給病人嗎](encounters-npc.md#npc_024)

- [診療所收貨人](npc-new_hope.md#hook_new_hope_003)：分歧：收貨人不願簽未知空格，聯絡人希望可驗部分先走。 合作：分批點交能保留核帳與有限援助兩個目標。

利益群體：nh_clinic、nh_newcomers。前置缺口：camping、cargo、identification、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_019"></a>
## hook_new_hope_019 · 診療文獻整理人

公開需要：標出醫療手冊缺頁與仍可讀章節，避免整本被误用。
個人利害：不想讓整理工作被誤稱為自己能行醫。
能提供：可安排與合格照護者共同查詢。
限制：不開處方，不從讀書產生MEDICINE rank。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『診療文獻整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：手冊仍可合法查閱，版本尚未完整核對。
不介入：若另一份同版索引到來，改做校對；原缺頁與來源仍保留，不靜默補成完整書。

物品：[醫療手冊](items.md#content_medical_manual)、[軍醫資料晶片](items.md#content_military_medical_chip)
遭遇：[缺頁的醫療索引](encounters-npc.md#npc_022)、[藥箱上的舊封條](encounters-npc.md#npc_015)

- [診療所收貨人](npc-new_hope.md#hook_new_hope_003)：分歧：收貨人要快速查用品名，整理人需要先分版本。 合作：清楚索引能減少重複問錯箱號。

利益群體：nh_clinic。前置缺口：identification、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_020"></a>
## hook_new_hope_020 · 封條比對助手

公開需要：比較診療貨箱重貼封條與運送者說明。
個人利害：怕被當成故意刁難送貨人的人。
能提供：保留收貨時可見封條與箱面記錄。
限制：不能從重貼封條直接判斷藥物失效或遭竊。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『封條比對助手』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：同一貨箱尚未拆散且能找到合法保管者。
不介入：若貨已正式退回，停止現地查驗；只保留已見證的運送紀錄。

物品：[醫院識別卡](items.md#content_hospital_id_card)、[舊世醫療箱](items.md#content_old_world_medical_case)
遭遇：[藥箱上的舊封條](encounters-npc.md#npc_015)

- [外營用品聯絡人](npc-new_hope.md#hook_new_hope_018)：分歧：聯絡人急著放貨，助手希望未驗部分先封存。 合作：一起找原送貨人點交比互相指控更可核實。

利益群體：nh_clinic。前置缺口：identification、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_new_hope_021"></a>
## hook_new_hope_021 · 帳篷借用登記人

公開需要：把收容處帳篷借用與歸還對上實際人員。
個人利害：怕遺失記錄讓已離開的人背永久借物債。
能提供：有現行借用簿與管理者同意的查閱權。
限制：不能創造床位、治療量或自動安置新人口。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『帳篷借用登記人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：收容用品仍屬待借或待還狀態。
不介入：若原借用人依正式遷徙離開，轉成可查的未還紀錄，不把離開當偷竊。

物品：[帳篷](items.md#content_tent)、[睡袋](items.md#content_sleeping_bag)
遭遇：[帳篷要先留給病人嗎](encounters-npc.md#npc_024)、[留給誰的登山背包](encounters-npc.md#npc_029)

- [外營用品聯絡人](npc-new_hope.md#hook_new_hope_018)：分歧：用品聯絡人想先發再補記，登記人重視可追蹤交接。 合作：先記最少必要資訊可兼顧急需與所有權。

利益群體：nh_newcomers、nh_clinic。前置缺口：camping、cargo、equipment、injury、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_022"></a>
## hook_new_hope_022 · 私人照片保管人

公開需要：找能核對老照片地點的人，不願照片被當地契。
個人利害：照片對家族有意義，怕被研究者買走後再看不到。
能提供：可同意有限複看或提供背面字樣。
限制：不能用相似臉孔建立親屬或新NPC。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『私人照片保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原照尚在且持有人同意查看外觀。
不介入：若持有人撤回同意，停止複製與公開；已有合法筆記保留來源和限制。

物品：[老照片](items.md#content_old_photograph)、[相機](items.md#content_camera)
遭遇：[老照片裡的井壁](encounters-npc.md#npc_020)

- [地址沿革登記人](npc-new_hope.md#hook_new_hope_025)：分歧：地址登記人只接受可核實資料，保管人更相信長輩記憶。 合作：把記憶與文書並列可找可查的路段。

利益群體：nh_newcomers。前置缺口：item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_new_hope_023"></a>
## hook_new_hope_023 · 口述聲音記錄者

公開需要：保存地方錄音但先問被提及者是否同意公開。
個人利害：想留下自己的工作成果，也不願失去鄰里信任。
能提供：能指出原錄音與後來抄寫版本的差別。
限制：不能把錄音內容全部當真或自动提升全城士氣。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『口述聲音記錄者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原媒體可合法播放且相關持有人尚願協商。
不介入：若同意撤回，公開活動取消；不自行把聲音刪出世界歷史或制造新證詞。

物品：[音樂播放器](items.md#content_music_player)、[黑膠唱片](items.md#content_vinyl_record)
遭遇：[收音機裡的私人名字](encounters-npc.md#npc_028)

- [私人照片保管人](npc-new_hope.md#hook_new_hope_022)：分歧：照片保管人希望記憶完整公開，記錄者重視隱私同意。 合作：共同標示可分享範圍能保住原物與關係。

利益群體：nh_newcomers。前置缺口：electronics、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-WOOL、LD-P02、WG-04。

<a id="hook_new_hope_024"></a>
## hook_new_hope_024 · 寄物箱看守人

公開需要：核對兩只相似寄物箱，避免把藥品與衣物交錯。
個人利害：曾因口頭代領出錯，不想再替沒到場的人簽字。
能提供：可查目前寄物牌與實際到場人。
限制：不擅自開封、不認定所有領物者都有騙意。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『寄物箱看守人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：寄物仍在且尚未有完整交付。
不介入：若原主已合法領走，同號詢問只查紀錄；不生成第二箱滿足後來者。

物品：[密封貨箱](items.md#content_sealed_cargo_crate)、[舊旅行包](items.md#content_travel_backpack)
遭遇：[乾糧袋裡的私人標記](encounters-npc.md#npc_018)、[不接受猜測的尋人表](encounters-npc.md#npc_026)

- [新住民聯絡人](npc-new_hope.md#hook_new_hope_010)：分歧：聯絡人希望代辦，看守人需要原主明確授權。 合作：建立可驗的代領說明可減少奔波。

利益群體：nh_newcomers。前置缺口：cargo、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_025"></a>
## hook_new_hope_025 · 地址沿革登記人

公開需要：把舊街名與現行地標分開保存，協助查詢信件。
個人利害：怕一筆誤認讓普通居民被指成欠債者。
能提供：能提供已核實的地址改名記錄。
限制：地址相同不證明人相同，不額外創造人口。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『地址沿革登記人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：查詢人有合法理由且相關紀錄仍可讀。
不介入：若收件人確已依世界紀錄離開，轉向已知後續地址或明確查無，不復活或召回。

物品：[身分證件](items.md#content_identity_document)、[沒有寄出的信](items.md#content_unsent_letter)
遭遇：[不接受猜測的尋人表](encounters-npc.md#npc_026)、[老照片裡的井壁](encounters-npc.md#npc_020)

- [私人照片保管人](npc-new_hope.md#hook_new_hope_022)：分歧：照片保管人偏重家族說法，登記人要求另一項證據。 合作：交叉比對可縮小範圍而不用猜結論。

利益群體：nh_newcomers、nh_water_stewards。前置缺口：identification、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_new_hope_026"></a>
## hook_new_hope_026 · 農務短工招呼人

公開需要：向臨時工說清驗收範圍與真正能支付的物資。
個人利害：不想為雇主承諾自己沒有的咖啡或好裝備。
能提供：能看當日待完成工作與雇主同意的報酬清單。
限制：不能只因招呼就自動雇用玩家或扣工錢。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『農務短工招呼人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：工作仍空缺且雇主物資能確認。
不介入：若另一工人已接下或完成，關閉邀請；報酬不足就重談或撤回，不憑空補獎勵。

物品：[咖啡](items.md#content_coffee)、[乾糧](items.md#content_food)、[工兵鏟](items.md#content_entrenching_shovel)
遭遇：[想換成咖啡的工錢](encounters-npc.md#npc_023)、[削繩的小刀](encounters-npc.md#npc_011)

- [工錢見證人](npc-new_hope.md#hook_new_hope_027)：分歧：工錢見證人要求先寫清楚，招呼人想快找到幫手。 合作：簡短清單可讓雙方知道哪些結果能驗收。

利益群體：nh_growers、nh_newcomers。前置缺口：equipment、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROAD、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_new_hope_027"></a>
## hook_new_hope_027 · 工錢見證人

公開需要：區分已承諾工錢與另談的奢侈品交換。
個人利害：自己收過不需要的代用品，對模糊『等值』承諾敏感。
能提供：能保留兩方自願確認的條款副本。
限制：不能替任何人制定全城價格或强迫收物。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『工錢見證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：雙方尚未完成報酬交付且同意見證。
不介入：若已有合法結算，只處理可證實勘誤；不因事後不喜歡報酬就倒帶交易。

物品：[咖啡](items.md#content_coffee)、[茶葉](items.md#content_tea)、[乾糧](items.md#content_food)
遭遇：[想換成咖啡的工錢](encounters-npc.md#npc_023)

- [農務短工招呼人](npc-new_hope.md#hook_new_hope_026)：分歧：招呼人想口頭先開工，見證人希望先列出驗收與對價。 合作：已確認短條款可以保留工作進度與公平退出。

利益群體：nh_newcomers、nh_growers。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：LD-P02、WG-02、WG-04。

<a id="hook_new_hope_028"></a>
## hook_new_hope_028 · 獵物皮張交接人

公開需要：把皮革材料和家族烙記的公開用途分開談。
個人利害：怕自己的來源被收藏者拿來冒充地方身份。
能提供：可出示合法取得與寄放說明。
限制：不授權買家用皮張代表整個獵戶群體。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『獵物皮張交接人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：皮張仍未切裁，相關持有人可同意。
不介入：若已合法裁切，記錄失去哪些特徵，不重新生成完整原皮。

物品：[皮革](items.md#content_leather)、[獵刀](items.md#content_hunting_knife)
遭遇：[稱重前先說清楚的皮革](encounters-npc.md#npc_025)

- [獵具保管人](npc-new_hope.md#hook_new_hope_012)：分歧：獵具保管人願留歷史特徵，交接人希望材料仍能日常使用。 合作：事先列出保留區域可避免不可逆毀損爭議。

利益群體：nh_growers。前置缺口：crafting、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_029"></a>
## hook_new_hope_029 · 遠行背包借用人

公開需要：安排採集與遠行兩次工作的背包使用順序。
個人利害：怕照顧家人需求就永遠失去自己的旅行機會。
能提供：知道自己能接受的最晚出發與要攜物品。
限制：不得讓同一背包同時留在家又在路上。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『遠行背包借用人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：兩次旅程尚未開始且包的所有權清楚。
不介入：若其中一程已實際出發，依真正位置調整可用性，不把包瞬移回聚落。

物品：[登山背包](items.md#content_hiking_backpack)、[舊旅行包](items.md#content_travel_backpack)
遭遇：[留給誰的登山背包](encounters-npc.md#npc_029)

- [帳篷借用登記人](npc-new_hope.md#hook_new_hope_021)：分歧：借用登記人要準時歸還，遠行者希望保留延後回程彈性。 合作：限定借期與替代物可使承諾可實行。

利益群體：nh_newcomers、nh_growers。前置缺口：cargo、equipment、item_ownership、jobs、knowledge、navigation、npc_relationship。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_030"></a>
## hook_new_hope_030 · 濾水器維護人

公開需要：說清濾水器適用與保養缺項，避免所有髒水都被當可喝。
個人利害：怕拒絕背書被認為故意保留好水。
能提供：可提供現有濾材標示與已做的維護紀錄。
限制：沒有權限用機器名稱替水質鑑定。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『濾水器維護人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：裝置仍在且標示可合法查閱。
不介入：若濾材或檢測條件不足，維護邀請改為找資料；不為推進事件偷偷產水。

物品：[濾水器](items.md#content_water_filter)、[淨水錠](items.md#content_purification_tablets)、[淨水](items.md#content_clean_water)
遭遇：[嫌麻煩的濾水器](encounters-npc.md#npc_021)

- [水務保管人](npc-new_hope.md#hook_new_hope_001)：分歧：保管人面臨取水壓力，維護人不肯超出已驗證範圍。 合作：把立即可交付淨水與待驗處理分開。

利益群體：nh_water_stewards。前置缺口：hazards、identification、item_ownership、jobs、knowledge、npc_relationship、water_treatment。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_031"></a>
## hook_new_hope_031 · 防雨包裝短工

公開需要：在雨前為已分裝貨物加上可追蹤包材。
個人利害：想按完成袋數領工錢，怕事後被算成所有貨物的保險人。
能提供：能逐包標記自己的處理範圍。
限制：防水袋不是無限深水防護，不保證整批貨零損。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『防雨包裝短工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：貨物尚未出庫，包材與截止條件明確。
不介入：若雨已開始或貨已出發，重驗可接範圍，不補寫已完成包裝。

物品：[防水袋](items.md#content_waterproof_bag)、[布袋](items.md#content_cloth_sack)
遭遇：[雨前的種子領取人](encounters-npc.md#npc_030)、[種庫照管人的破角箱](encounters-npc.md#npc_002)

- [種庫照管人](npc-new_hope.md#hook_new_hope_002)：分歧：照管人希望所有箱都包好，短工只能承諾現有材料可做部分。 合作：先處理已確定出庫批次可讓有限材料有用。

利益群體：nh_growers、nh_newcomers。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_new_hope_032"></a>
## hook_new_hope_032 · 種子傳言澄清者

公開需要：要求販售灰種的人說明哪些效果有實際試種證據。
個人利害：想保护家人的田，也怕被當成排斥新作物。
能提供：可連繫願意公開紀錄的本地試種人。
限制：不因傳言誇張就宣布樣本有毒或捏造犯罪。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『種子傳言澄清者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：傳言仍在流通且有願意對話的現存賣方。
不介入：若交易已依法結束，轉成自願資訊補充；不倒帶交付或自動毀掉作物。

物品：[灰種](items.md#content_gray_seed)、[種植手冊](items.md#content_planting_manual)
遭遇：[要把灰種賣給誰](encounters-npc.md#npc_027)、[以灰種抵糧的契約](encounters-anomaly.md#anomaly_032)

- [儲種外觀整理人](npc-new_hope.md#hook_new_hope_014)：分歧：外觀整理人只想保留未知，澄清者想直接阻止宣傳。 合作：共同提供已知與待驗清單比武斷禁令可靠。

利益群體：nh_growers、nh_newcomers。前置缺口：exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROADSIDE、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_033"></a>
## hook_new_hope_033 · 地質圖保管學徒

公開需要：找出地圖座標基準與現地地標的對應。
個人利害：想證明自己會做調查，但不願保證挖哪裡都有水。
能提供：知道圖上可讀的鑽孔號與缺角位置。
限制：舊圖不是當前地下資源，不能增加泉眼。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『地質圖保管學徒』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：圖仍可借閱且現場有合法進入條件。
不介入：若另一調查已確認基準，改為校對；若地標消失，保留未知而不虛構座標。

物品：[地質調查圖](items.md#content_geological_survey_map)、[指南針](items.md#content_compass)
遭遇：[排水溝旁的借鏟](encounters-npc.md#npc_016)、[老照片裡的井壁](encounters-npc.md#npc_020)

- [排水溝清理人](npc-new_hope.md#hook_new_hope_006)：分歧：清溝人只問眼前管路，學徒希望調查更大範圍。 合作：先核對一個可見地標能服務有限施工需求。

利益群體：nh_water_stewards、nh_growers。前置缺口：hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、repair、reputation。研究：FICTION-CANTICLE、FICTION-METRO、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_034"></a>
## hook_new_hope_034 · 小額鹽料商販

公開需要：按已有承諾分配有限鹽，避免一位買家包下未屬於他的份額。
個人利害：需要跑商維生，但不想失去本地熟客信任。
能提供：可以出示可售與已承諾的分列庫存。
限制：不能把高需求直接當成固定暴利倍率。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『小額鹽料商販』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：鹽還在合法庫存且未完成其他交付。
不介入：若另一買家先按約成交，縮減可售量；未買者不自動蒙受災難。

物品：[鹽](items.md#content_salt)、[香料](items.md#content_spices)
遭遇：[第一袋鹽該給誰](encounters-npc.md#npc_017)

- [醃藏工作承接人](npc-new_hope.md#hook_new_hope_015)：分歧：醃藏人優先本地工作，商販有外地訂單。 合作：清楚分開剩餘可售份額能保住两種生計。

利益群體：nh_growers。前置缺口：cooking、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_035"></a>
## hook_new_hope_035 · 舊書搬運者

公開需要：把醫療與農業手冊分開裝運，保留版本與頁面狀態。
個人利害：怕途中受潮被責怪原本就缺頁的書。
能提供：有出發前的外觀清單與交接對象。
限制：不能憑搬書給玩家技能，不能複制整庫書。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『舊書搬運者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：书仍在本地且運送尚未正式開始。
不介入：若班次出發，邀請終止；不得把書留在原處同時當作送達。

物品：[醫療手冊](items.md#content_medical_manual)、[種植手冊](items.md#content_planting_manual)、[防水袋](items.md#content_waterproof_bag)
遭遇：[缺頁的醫療索引](encounters-npc.md#npc_022)、[雨前的種子領取人](encounters-npc.md#npc_030)

- [診療文獻整理人](npc-new_hope.md#hook_new_hope_019)：分歧：文獻整理人想多看一天，搬運者要趕實際出發班次。 合作：先記錄版本可讓收件端接著校對。

利益群體：nh_clinic、nh_growers。前置缺口：cargo、identification、injury、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_new_hope_036"></a>
## hook_new_hope_036 · 新到者的寄信幫手

公開需要：替不熟地址的人查詢信封外面的兩個地名。
個人利害：想幫忙卻不願替人讀私人信件。
能提供：可介紹有權查閱的地址登記處。
限制：不因信裡有人名就生成收件者。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『新到者的寄信幫手』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：信尚未交付且寄件權利人允許查詢。
不介入：若其他信差已接走，這裡改查運送紀錄，不提供第二封原信。

物品：[沒有寄出的信](items.md#content_unsent_letter)、[身分證件](items.md#content_identity_document)
遭遇：[返程信差的兩個地址](encounters-npc.md#npc_010)、[不接受猜測的尋人表](encounters-npc.md#npc_026)

- [地址沿革登記人](npc-new_hope.md#hook_new_hope_025)：分歧：地址登記人要更多證據，幫手怕詢問太久錯過返程信差。 合作：先核對外封可以保住隐私並縮小路線。

利益群體：nh_newcomers。前置缺口：identification、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_new_hope_037"></a>
## hook_new_hope_037 · 烹煮排班助手

公開需要：讓有限燃料與食材的使用時段對上實際工作。
個人利害：不想自己的用餐被誤當額外偷吃。
能提供：知道已登記的輪值和實際有的鍋具位置。
限制：不能直接提升食品產出或取消每日食物消耗。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『烹煮排班助手』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當次烹煮尚未開始且合法物資可確認。
不介入：若食材已用於其他已授權工作，重排或取消，不補出免費一餐。

物品：[燃料罐](items.md#content_fuel_can)、[罐頭](items.md#content_canned_food)、[打火機](items.md#content_lighter)
遭遇：[第一袋鹽該給誰](encounters-npc.md#npc_017)、[想換成咖啡的工錢](encounters-npc.md#npc_023)

- [醃藏工作承接人](npc-new_hope.md#hook_new_hope_015)：分歧：醃藏工作者想多占準備空間，助手要保住已排的煮食時間。 合作：把準備與加熱分開可減少空間衝突。

利益群體：nh_growers、nh_newcomers。前置缺口：cooking、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_038"></a>
## hook_new_hope_038 · 日常罐頭收購者

公開需要：確認罐頭來源與包裝狀態，只收自己能合法保存的數量。
個人利害：不願被比作只看外盒漂亮的古董買家。
能提供：可說清現有儲存空間與實際需求。
限制：不替食品安全做肉眼保證，不無限收同款。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『日常罐頭收購者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有可售實物且收購空間尚可確認。
不介入：若需求已被其他貨滿足，縮小收購窗口，不能變成永遠可套現商店。

物品：[罐頭](items.md#content_canned_food)、[舊世罐頭](items.md#content_old_world_canned_food)
遭遇：[乾糧袋裡的私人標記](encounters-npc.md#npc_018)、[第一袋鹽該給誰](encounters-npc.md#npc_017)

- [糧袋秤重人](npc-new_hope.md#hook_new_hope_008)：分歧：秤重人要逐批留紀錄，收購者想一次驗完。 合作：共同按批交付可使有問題的部分不混入正常貨。

利益群體：nh_growers、nh_newcomers。前置缺口：cargo、cooking、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_039"></a>
## hook_new_hope_039 · 拒收空瓶的取水幫工

公開需要：區分居民交來的空水壺與實際已交水份額。
個人利害：怕大家把容器漂亮程度當優先資格。
能提供：能展示目前容器和飲水分開的點交簿。
限制：不得把水壺本身換算成固定water單位。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『拒收空瓶的取水幫工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：取水交接尚未完成，雙方同意點看。
不介入：若交付已完成就保留原憑證；後來空瓶不得再領同一份水。

物品：[水壺](items.md#content_water)、[淨水](items.md#content_clean_water)
遭遇：[不想上鎖的水袋](encounters-npc.md#npc_019)、[嫌麻煩的濾水器](encounters-npc.md#npc_021)

- [領水見證人](npc-new_hope.md#hook_new_hope_007)：分歧：見證人看隊伍順序，幫工還要檢查交付是否真有水。 合作：同一張單分列容器與內容可避免重算。

利益群體：nh_water_stewards、nh_newcomers。前置缺口：cargo、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、reputation、water_treatment。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_040"></a>
## hook_new_hope_040 · 舊泵聲音記錄者

公開需要：把設備異音與鳴石觀察分開，避免聽錯就停公共泵。
個人利害：想證明記錄有用，卻怕被追究不必要停機。
能提供：能提供噪音出現時刻與可比較位置。
限制：不因錄音或奇物聲響直接判定機械故障。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『舊泵聲音記錄者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：設備仍有可合法觀察窗口，樣本未轉走。
不介入：若正常輪值停機已過，等下一實際窗口；不為玩家強制改供水。

物品：[鳴石](items.md#content_humming_stone)、[音樂播放器](items.md#content_music_player)
遭遇：[泵聲掩住石聲](encounters-anomaly.md#anomaly_015)、[收音機裡的私人名字](encounters-npc.md#npc_028)

- [濾水器維護人](npc-new_hope.md#hook_new_hope_030)：分歧：維護人要求直接量測，記錄者希望声音也被保留。 合作：兩類資料可互相指向需要查驗的部位。

利益群體：nh_water_stewards。前置缺口：electronics、exploration、identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-ROADSIDE、FICTION-WOOL、LD-P02、WG-04、WG-06。

<a id="hook_new_hope_041"></a>
## hook_new_hope_041 · 藥品清單抄寫人

公開需要：把外盒可讀名稱抄清，未知縮寫留白給有資格者查。
個人利害：字寫得好不代表懂醫療，不想因代抄被當醫師。
能提供：能保留原字樣與抄本對照。
限制：沒有處方、治療或鑑定權。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『藥品清單抄寫人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：合法查阅同意有效且原包裝仍可見。
不介入：若原件已送走，不能憑記憶補齊字；可改為核對收到的新版本。

物品：[醫療手冊](items.md#content_medical_manual)、[紙本日記](items.md#content_paper_journal)
遭遇：[診療所收貨人的空格](encounters-npc.md#npc_003)、[缺頁的醫療索引](encounters-npc.md#npc_022)

- [診療文獻整理人](npc-new_hope.md#hook_new_hope_019)：分歧：文獻整理人要查版本，抄寫人想先把可見字交差。 合作：清楚標明未識字樣能讓後續不靠猜測。

利益群體：nh_clinic、nh_newcomers。前置缺口：identification、injury、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_042"></a>
## hook_new_hope_042 · 收容處睡袋看守人

公開需要：知道哪個睡袋實际借出、哪個仍在庫內。
個人利害：不願對急需休息的人逼問多餘私事。
能提供：能提供最小必要的借還紀錄。
限制：不得讓同一睡袋同時保護多人，不能以布料治病。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『收容處睡袋看守人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：收容用品尚有待交接事項。
不介入：若床位使用者正式離開，按實際歸還更新；未歸還是待查，不自動判偷竊。

物品：[睡袋](items.md#content_sleeping_bag)、[醫療袋](items.md#content_medical_satchel)
遭遇：[帳篷要先留給病人嗎](encounters-npc.md#npc_024)

- [帳篷借用登記人](npc-new_hope.md#hook_new_hope_021)：分歧：帳篷登記人要完整資料，看守人只想收必要資訊。 合作：共用最少欄位能保住隐私與可追蹤性。

利益群體：nh_newcomers、nh_clinic。前置缺口：camping、cargo、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROAD、LD-P02、WG-04。

<a id="hook_new_hope_043"></a>
## hook_new_hope_043 · 農具換手介紹人

公開需要：介紹想出售伐木斧的人和确有工具需求的人見面。
個人利害：靠介紹維生，不想用誇大功能促成一次買賣就失信。
能提供：知道有限、已同意公開的需求清單。
限制：不能保證斧頭同時適合所有砍伐、戰鬥和施工。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『農具換手介紹人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：雙方都有現存實物與未滿足需求。
不介入：若買家已找到替代工具，介紹邀請關閉；不強行創造需求維持收入。

物品：[伐木斧](items.md#content_wood_axe)、[工兵鏟](items.md#content_entrenching_shovel)
遭遇：[廢鐵砍刀與棚邊枝條](encounters-npc.md#npc_013)、[排水溝旁的借鏟](encounters-npc.md#npc_016)

- [菜圃繫繩幫工](npc-new_hope.md#hook_new_hope_011)：分歧：幫工只需解繩，介紹人容易推薦過大的工具。 合作：先問工作範圍可以避免不必要購買。

利益群體：nh_growers。前置缺口：equipment、hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、repair。研究：FICTION-METRO、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_044"></a>
## hook_new_hope_044 · 文書保存紙套看守人

公開需要：把老照片、日記與寄信分開，不讓私人文件成公開公告。
個人利害：某頁提到自己家，擔心因保管職責被懷疑偷偷删改。
能提供：可提供封存清單和誰曾合法查閱的紀錄。
限制：無權靠保管身份決定內容真偽或刪世界歷史。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『文書保存紙套看守人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原主同意保管且尚未決定歸還或公開。
不介入：若原主依法收回，只保留合法交接紀錄，不複製秘密副本給玩家。

物品：[老照片](items.md#content_old_photograph)、[紙本日記](items.md#content_paper_journal)、[沒有寄出的信](items.md#content_unsent_letter)
遭遇：[老照片裡的井壁](encounters-npc.md#npc_020)、[收音機裡的私人名字](encounters-npc.md#npc_028)

- [口述聲音記錄者](npc-new_hope.md#hook_new_hope_023)：分歧：錄音記錄者希望保留可公開材料，看守人較保守。 合作：每份物件有單獨同意範圍可減少一刀切。

利益群體：nh_newcomers。前置缺口：electronics、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-WOOL、LD-P02、WG-04。

<a id="hook_new_hope_045"></a>
## hook_new_hope_045 · 井邊熱心勸買者

公開需要：想說服居民購買濾水器，但必須說清已知適用範圍。
個人利害：曾被裝備救過急，容易把一次有效當成全部有效。
能提供：能介紹自己那次有資料支持的使用情境。
限制：個人經驗不構成水質認證或永遠安全。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『井邊熱心勸買者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：宣傳仍在進行且本人願意接受查證。
不介入：若正式測試否定某用途，更新說明；不製造對立陣營或自動扣道德值。

物品：[濾水器](items.md#content_water_filter)、[淨水錠](items.md#content_purification_tablets)
遭遇：[嫌麻煩的濾水器](encounters-npc.md#npc_021)

- [濾水器維護人](npc-new_hope.md#hook_new_hope_030)：分歧：維護人覺得宣傳過頭，勸買者覺得太保守會失去機會。 合作：共同整理具體適用條件可保留有用經驗。

利益群體：nh_water_stewards、nh_newcomers。前置缺口：hazards、identification、item_ownership、jobs、knowledge、npc_relationship、water_treatment。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_046"></a>
## hook_new_hope_046 · 節水菜圃試驗人

公開需要：在有限地塊試記種植手冊條件，不挪全城飲水。
個人利害：希望有自己的新方法，又怕失敗讓家人失去配水。
能提供：可展示試驗範圍與經管理者同意的水源。
限制：不保證產量，不能先把未發芽種子算成糧食。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『節水菜圃試驗人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有已同意的地塊與合法有限物資。
不介入：若水源約定終止或試驗完成，停止新增投入；不因玩家缺席自動毀掉作物。

物品：[種植手冊](items.md#content_planting_manual)、[種子](items.md#content_seeds)、[水壺](items.md#content_water)
遭遇：[替種子找名字的人](encounters-npc.md#npc_014)、[要把灰種賣給誰](encounters-npc.md#npc_027)

- [水務保管人](npc-new_hope.md#hook_new_hope_001)：分歧：水務保管人要保住飲水承諾，試驗人想延長觀察。 合作：限定小範圍和可停止條件能讓雙方接受。

利益群體：nh_growers、nh_water_stewards。前置缺口：hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、FICTION-ROADSIDE、LD-P02、WG-02、WG-04、WG-06。

<a id="hook_new_hope_047"></a>
## hook_new_hope_047 · 外地茶葉寄賣人

公開需要：為一小批茶找真正願意交換的人，不把它當普通糧食。
個人利害：想帶一點家鄉味留下，怕全部賣完再也找不到。
能提供：能限定可售份額並保留私人部分。
限制：不能用奢侈品代替已承諾的工錢而不經對方同意。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『外地茶葉寄賣人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：寄賣物仍在且原主尚願售出指定份額。
不介入：若原主撤回未承諾部分，取消新詢價；已合法成交部分不倒帶。

物品：[茶葉](items.md#content_tea)、[咖啡](items.md#content_coffee)
遭遇：[想換成咖啡的工錢](encounters-npc.md#npc_023)

- [工錢見證人](npc-new_hope.md#hook_new_hope_027)：分歧：工錢見證人拒絕模糊等值，寄賣人希望有彈性。 合作：把私人交換與雇主報酬分開可同時成立。

利益群體：nh_newcomers、nh_growers。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：LD-P02、WG-02、WG-04。

<a id="hook_new_hope_048"></a>
## hook_new_hope_048 · 家用繩結教學人

公開需要：教一次能看清的簡單解結與固定方法，不代替工程安全認證。
個人利害：怕學生把家庭用法搬到井架重載上。
能提供：能用自己的繩索做不承重的示範。
限制：示範不增加技能rank，不能保證攀爬或救援安全。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『家用繩結教學人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有自願參與者與安全演示場所。
不介入：若教學時段已結束，可等實際下次安排；不提供永久等待玩家的課堂。

物品：[繩索](items.md#content_rope)、[工具腰帶](items.md#content_tool_belt)
遭遇：[削繩的小刀](encounters-npc.md#npc_011)、[廢鐵砍刀與棚邊枝條](encounters-npc.md#npc_013)

- [井繩檢查工](npc-new_hope.md#hook_new_hope_005)：分歧：井繩檢查工反對把演示當承重證書。 合作：清楚限定使用範圍可讓日常技巧仍有價值。

利益群體：nh_growers、nh_newcomers。前置缺口：equipment、hazards、item_ownership、jobs、knowledge、npc_relationship、repair。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_new_hope_049"></a>
## hook_new_hope_049 · 留存普通物件的人

公開需要：替將遠行的人保管一件沒有市價意義的私人舊物。
個人利害：自己也有沒能歸還的照片，不想輕易承諾一定重逢。
能提供：可提供清楚寄物條款與見證者。
限制：不得承諾亡者復活或讓存物變成自動繼承。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『留存普通物件的人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：物主仍存活且自願留下有限寄物。
不介入：若物主依正式生命狀態死亡，只依未來合法處置規則保持待處理，不自動給下一角色。

物品：[老照片](items.md#content_old_photograph)、[舊世界手錶](items.md#content_old_world_watch)
遭遇：[老照片裡的井壁](encounters-npc.md#npc_020)、[留給誰的登山背包](encounters-npc.md#npc_029)

- [寄物箱看守人](npc-new_hope.md#hook_new_hope_024)：分歧：寄物箱看守人重視可查編號，保管人更在乎私人故事。 合作：物件和故事分層記錄可兼顧追溯與尊重。

利益群體：nh_newcomers。前置缺口：cargo、equipment、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_new_hope_050"></a>
## hook_new_hope_050 · 公共借物規則整理人

公開需要：把扳手、繩索、醫療袋等不同用品的借用條款分開。
個人利害：不想讓新規則變成限制新來者的一道門檻。
能提供：能收集各保管者已同意公開的現行作法。
限制：無權一句話改所有庫存、任命守衛或建立新派系。
人口綁定：未來從新希望當前在場且存活的人口中，確認有意願承擔『公共借物規則整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：各保管人仍願參與，至少一筆真實借用需求存在。
不介入：若部分角色撤回，不把規則強加全城；只保留已有同意與明確缺口。

物品：[扳手](items.md#content_wrench)、[繩索](items.md#content_rope)、[醫療袋](items.md#content_medical_satchel)
遭遇：[水務保管人的借具簿](encounters-npc.md#npc_001)、[種庫照管人的破角箱](encounters-npc.md#npc_002)、[診療所收貨人的空格](encounters-npc.md#npc_003)

- [新住民聯絡人](npc-new_hope.md#hook_new_hope_010)：分歧：聯絡人怕規則太複雜，整理人怕只靠口頭造成重複交付。 合作：先用三種常見交接做清楚範例可以共同檢查。

利益群體：nh_water_stewards、nh_growers、nh_clinic、nh_newcomers。前置缺口：cargo、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。
