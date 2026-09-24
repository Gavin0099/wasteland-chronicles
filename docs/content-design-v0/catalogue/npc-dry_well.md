# 乾井人物與關係鉤子

DESIGN_ONLY；是角色候選，沒有新增150人口。

<a id="hook_dry_well_001"></a>
## hook_dry_well_001 · 燃料核帳員

公開需要：辨認同一只燃料袋上的兩張牌，核對實際交付而非重複計帳。
個人利害：怕少算惹怒供應者，多算又讓下一班空等。
能提供：能出示可查領條與仍在場的實物。
限制：不能憑一張牌生成燃料或指定全城售價。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『燃料核帳員』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當批燃料仍未結清且核帳職責有效。
不介入：若原收據已補齊，關閉查單需求；若商隊已正式出發，只記實際出庫，不倒帶。

物品：[燃料罐](items.md#content_fuel_can)、[紙本日記](items.md#content_paper_journal)
遭遇：[燃料核帳員的污漬欄位](encounters-settlement.md#town_068)、[燃料核帳員的第二張袋牌](encounters-npc.md#npc_007)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人想按預訂出發，核帳員只認已合法交付的份額。 合作：先確認無爭議部分，餘額保持待查。

利益群體：dw_fuel_cooperative。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、FICTION-METRO、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_002"></a>
## hook_dry_well_002 · 商隊排程人

公開需要：核對外套穿著者是否真是本次承諾的乘員，再安排有限車位。
個人利害：怕重複答應位置傷信譽，也不願因衣服相似誤放人。
能提供：持有當次自願提供的名單與真實行程。
限制：不能靠外套創造身分、座位或商隊。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『商隊排程人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：商隊仍在且尚有未完成的合法排程事項。
不介入：若按正式行程離開，未接邀約結束；不能讓整隊等待玩家或再生空位。

物品：[商隊外套](items.md#content_caravan_coat)、[舊旅行包](items.md#content_travel_backpack)
遭遇：[排程人手上的兩張路線單](encounters-settlement.md#town_069)、[排程人與相同的外套](encounters-npc.md#npc_008)

- [返程信差](npc-dry_well.md#hook_dry_well_004)：分歧：信差要留最後一位，排程人要遵守已承諾載貨。 合作：將乘員、信件與行李承諾分欄核對。

利益群體：dw_caravan_brokers。前置缺口：exploration、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade、reputation。研究：FICTION-METRO、LD-P01、LD-P02、WG-04。

<a id="hook_dry_well_003"></a>
## hook_dry_well_003 · 井口輪值人

公開需要：替遮布找合法固定方式，保留通風與交班視線。
個人利害：想讓排隊者少受沙塵，又怕自己被要求保證一切安全。
能提供：知道當前遮布借期與井架管理者。
限制：不能把長袍當防毒裝備或額外創造配水。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『井口輪值人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本輪仍負責井口且遮布固定需求尚在。
不介入：若交班先發生，移交已知限制；若遮布已取回，只關閉固定工作而不製造缺水。

物品：[沙地長袍](items.md#content_desert_robe)、[繩索](items.md#content_rope)
遭遇：[井口輪值人的空位](encounters-settlement.md#town_070)、[井口輪值人的遮布](encounters-npc.md#npc_009)

- [井架繩索原主](npc-dry_well.md#hook_dry_well_023)：分歧：井繩原主要求準時歸還，輪值人希望多留一班。 合作：先找不占用到期繩的可行綁點。

利益群體：dw_well_queue。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_004"></a>
## hook_dry_well_004 · 返程信差

公開需要：釐清一封未寄信上的兩個地址，守住收件人的閱讀權。
個人利害：想按時返程，但不願為了交差把信隨便塞給陌生人。
能提供：能提供外封地址與本人有效行程。
限制：不得拆信猜內容、造收件人或把死亡寫成劇情。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『返程信差』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原信仍在且尚無合法收件或轉交結果。
不介入：若確定收件者已正式遷徙，僅按新事實重查；出發時未完成交付依約保管，不自動送達。

物品：[沒有寄出的信](items.md#content_unsent_letter)、[防水袋](items.md#content_waterproof_bag)
遭遇：[返程信差的破袋口](encounters-settlement.md#town_071)、[返程信差的兩個地址](encounters-npc.md#npc_010)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人要準時走，信差還欠一個合法交付確認。 合作：可協商有見證的保管交接，無需拖住整隊。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：cargo、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-METRO、LD-P02、WG-04。

<a id="hook_dry_well_005"></a>
## hook_dry_well_005 · 油桶印記核對人

公開需要：比對領條上的手印、桶號與現有封記。
個人利害：不想把舊印重用當成偷油，也怕熟人鑽空格。
能提供：有本批原單與可查的實體桶。
限制：印記相似不是犯罪證據，不能直接凍結交易。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『油桶印記核對人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本批桶尚可查且交付仍待核對。
不介入：若已有原始收據釐清，終止疑點；貨已合法離開就轉為文書追溯，不造新桶。

物品：[燃料罐](items.md#content_fuel_can)、[紙本日記](items.md#content_paper_journal)
遭遇：[油桶領條的兩種印記](encounters-npc.md#npc_056)

- [燃料核帳員](npc-dry_well.md#hook_dry_well_001)：分歧：核帳員重總數，核對人關心同一桶是否被兩次簽領。 合作：共同將重複疑點排除後再結算。

利益群體：dw_fuel_cooperative。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-METRO、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_006"></a>
## hook_dry_well_006 · 急件修泵接洽人

公開需要：為一項具體檢查找扳手，說清不是借到就一定修好。
個人利害：兩邊都催，怕工具最後歸還時自己背下所有故障。
能提供：能提供設備管理者同意與已知症狀。
限制：無權代替技工判因或改寫水產量。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『急件修泵接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：設備仍有問題且借具需求未被別人解決。
不介入：若技工已自備工具，取消借具；設備後續只由真實檢查與修復authority更新。

物品：[扳手](items.md#content_wrench)、[維修手冊](items.md#content_repair_manual)
遭遇：[乾井最缺的一把扳手](encounters-npc.md#npc_057)

- [井口輪值人](npc-dry_well.md#hook_dry_well_003)：分歧：輪值人急需恢復可用狀態，接洽人只能安排有限檢查。 合作：先記未確定部分，再決定誰可合法接修。

利益群體：dw_fuel_cooperative、dw_well_queue。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：LD-P01、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_007"></a>
## hook_dry_well_007 · 長袍補洞裁補人

公開需要：替沙地長袍補破口，先問物主是否保留舊顏色記號。
個人利害：便宜補料會改變外觀，怕商隊把衣色當通行證誤認人。
能提供：能列出現有布料與可完成的縫補範圍。
限制：衣物顏色不授予陣營身分或抗沙能力數值。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『長袍補洞裁補人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：衣物仍由合法持有人委託且材料可用。
不介入：若物主先出發，按完成範圍交還；不替其自動生成另一件衣。

物品：[沙地長袍](items.md#content_desert_robe)、[布料](items.md#content_cloth)
遭遇：[沙地長袍的補洞顏色](encounters-npc.md#npc_058)

- [外套徽章保管者](npc-dry_well.md#hook_dry_well_029)：分歧：徽章保管者想保留識別，裁補人認為衣服首先要能穿。 合作：可在不遮掉已同意標記處修補。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：crafting、equipment、item_ownership、jobs、knowledge、npc_relationship、repair。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_008"></a>
## hook_dry_well_008 · 照護用品收貨人

公開需要：拒收拿空藥盒當滿盒交差，記清實際收到什麼。
個人利害：怕把短缺說出口讓家屬焦慮，但更怕帳上有貨卻找不到。
能提供：可展示現物、包裝與原交付清單。
限制：不能從藥盒名稱推定療效，也不製造病人。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『照護用品收貨人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有真實送貨仍待驗收且保管者在場。
不介入：若供應者撤回空盒，記未交付並關閉該批；不自動把缺貨變成居民死亡。

物品：[急救包](items.md#content_first_aid_kit)、[未標示藥劑](items.md#content_unlabelled_medicine)
遭遇：[不肯收空藥盒的照護者](encounters-npc.md#npc_059)

- [出發前醫療袋分配人](npc-dry_well.md#hook_dry_well_026)：分歧：護送方要求急件先留給車伕，收貨人有既定收貨承諾。 合作：先分已驗收實物與尚未承諾部分。

利益群體：dw_outer_camps、dw_well_queue。前置缺口：cargo、injury、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_009"></a>
## hook_dry_well_009 · 守井人遺物保管者

公開需要：核實步槍上的公物印與後來讓渡記錄。
個人利害：想保住共同歷史，又怕居民因此把私物強收公庫。
能提供：能提供真實舊簿與同意說明的在場見證人。
限制：名稱不代表免費守衛權或自動所有權。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『守井人遺物保管者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：唯一原件仍在且現任物主願核驗。
不介入：若合法繼受已確定，關閉歸屬爭議；不再把同一槍當井口可重領獎勵。

物品：[守井人](items.md#content_well_guardian)、[軍人識別牌](items.md#content_military_dog_tags)
遭遇：[守井人的公物印](encounters-npc.md#npc_060)

- [燃料核帳員](npc-dry_well.md#hook_dry_well_001)：分歧：核帳員重可查單據，保管者也重視未成文交接。 合作：把口述與文件並列，保留歧異。

利益群體：dw_well_queue、dw_outer_camps。前置缺口：combat_extension、equipment、identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_dry_well_010"></a>
## hook_dry_well_010 · 刻名核認接洽人

公開需要：尋找願核認左輪刻字的當事人，不公開猜測中的家屬名單。
個人利害：想替陌生名字找到來歷，也怕追問打擾仍活著的人。
能提供：可提供經物主同意的刻字描記。
限制：相同名字不證明同一人，不能生成過往死者。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『刻名核認接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原刻字可查且有自願提供線索的人。
不介入：若查得不相關就停止該支線；沒有答覆保持未知，不編寫死亡史。

物品：[最後一發](items.md#content_last_round)、[老照片](items.md#content_old_photograph)
遭遇：[六個刻名中的陌生人](encounters-npc.md#npc_061)

- [返程信差](npc-dry_well.md#hook_dry_well_004)：分歧：信差只願按可查地址送訊，接洽人想四處打聽。 合作：使用物主同意的有限詢問內容。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：equipment、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_dry_well_011"></a>
## hook_dry_well_011 · 失槍線索接收人

公開需要：核對名為回家的槍是否與一筆尚未結案寄物相符。
個人利害：希望等到原主消息，但不願承諾持槍者必有報酬。
能提供：有真實寄物描述與可核查日期。
限制：槍名不能證明原主仍活著或已遇害。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『失槍線索接收人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原線索未被證實或排除，且物主願意查。
不介入：若正式記錄已釐清歸屬，關閉查找；不靠玩家缺席安排失蹤者死亡。

物品：[回家](items.md#content_homecoming)、[舊世地圖](items.md#content_old_world_map)
遭遇：[叫作回家的槍](encounters-npc.md#npc_062)

- [返程信差](npc-dry_well.md#hook_dry_well_004)：分歧：信差要明確收件者，接收人只有尚待查證的舊地址。 合作：先留有權公開的物件特徵供日後核對。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：equipment、exploration、item_ownership、jobs、knowledge、navigation、npc_relationship。研究：FICTION-CANTICLE、FICTION-METRO、LD-P02、WG-04。

<a id="hook_dry_well_012"></a>
## hook_dry_well_012 · 護送條款核對人

公開需要：把護衛持槍與實際願承擔的工作範圍分開談。
個人利害：怕旅客把一把左輪當平安保證，出事又怪自己。
能提供：有當次路線、報酬與自願承接者。
限制：不能憑武器圖示決定戰鬥勝負或自動招募護衛。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『護送條款核對人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：真實商隊仍在招募且條款未定。
不介入：若已招足或正式出發，停止新媒合；不新增守衛人口。

物品：[老式左輪](items.md#content_old_revolver)、[商隊外套](items.md#content_caravan_coat)
遭遇：[左輪不是護送保證](encounters-npc.md#npc_063)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人急找人補位，核對人要求先有清楚責任。 合作：確認最低可承諾工作再安排其餘風險。

利益群體：dw_caravan_brokers。前置缺口：combat_extension、equipment、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：LD-P02、WG-02、WG-04。

<a id="hook_dry_well_013"></a>
## hook_dry_well_013 · 路況紙抄錄人

公開需要：把消息的觀察日、來源與尚未複核的部分標清。
個人利害：賣消息是收入，承認過期可能賣不出去。
能提供：可提供真正收到的版本與合法傳話人。
限制：舊消息不是當前路線安全保證。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『路況紙抄錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有尚未核對的舊消息且來源願說明。
不介入：若新可靠資料取代舊版，停止按舊狀態宣傳；不改寫當年觀察。

物品：[舊世地圖](items.md#content_old_world_map)、[紙本日記](items.md#content_paper_journal)
遭遇：[過期一天的路況紙](encounters-npc.md#npc_064)

- [遠望地標觀察人](npc-dry_well.md#hook_dry_well_035)：分歧：遠望觀察人要補新資料，抄錄人怕原版本被當造假。 合作：並列兩個觀察時間即可說明變化。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：hazards、item_ownership、jobs、knowledge、navigation、npc_relationship。研究：FICTION-METRO、LD-P01、LD-P02、WG-04。

<a id="hook_dry_well_014"></a>
## hook_dry_well_014 · 欠水帳協調人

公開需要：分清漏袋損失與原本承諾的借水數。
個人利害：怕窮人被算進無法證明的損耗，也怕借出者再不肯借。
能提供：有雙方可核查的交付描述與原水袋。
限制：不自行把實物水袋換算既有 water 總量或創造債務。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『欠水帳協調人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原借約尚待核對且當事人願協商。
不介入：若已合法結清，不重開追討；漏失只依實際紀錄，不事後補造數量。

物品：[水袋](items.md#content_waterskin)、[水壺](items.md#content_water)
遭遇：[漏水袋與欠水數](encounters-npc.md#npc_065)

- [井口輪值人](npc-dry_well.md#hook_dry_well_003)：分歧：輪值人只認實際領取，協調人還要處理私下借用。 合作：把公共領水與私人借約分開。

利益群體：dw_well_queue、dw_outer_camps。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_dry_well_015"></a>
## hook_dry_well_015 · 回程口糧分配人

公開需要：核對每份已承諾肉乾，先留出原主私人份。
個人利害：想幫晚到的人，又怕守約者因此少拿。
能提供：有可見包裹與自願公開的領取名單。
限制：無權新增食物或強迫原主捐出私人部分。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『回程口糧分配人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：該商隊尚未出發且口糧仍待交付。
不介入：若已有合法領取，減少未交份額；出發後不在原地刷新物資。

物品：[肉乾](items.md#content_jerky)、[乾糧](items.md#content_food)
遭遇：[回程前的肉乾分配](encounters-npc.md#npc_066)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人想多收乘客，分配人只有有限口糧。 合作：先確認每份來源，再決定新乘客需自備什麼。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_016"></a>
## hook_dry_well_016 · 值班通聯記錄人

公開需要：區分真正未接通與沒有記下回覆的時段。
個人利害：怕被當怠班，也不想把所有空白都推給設備。
能提供：能提供原班表、現有無線電與有限見證。
限制：無訊號不等於某人已死、失蹤或叛變。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『值班通聯記錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當班問題尚未查清且原記錄可看。
不介入：若換班完成，只把未明時段交接；不補寫沒有發生的通話。

物品：[無線電](items.md#content_radio)、[電池](items.md#content_battery)
遭遇：[值班耳機裡的空白](encounters-npc.md#npc_068)

- [舊呼號查證人](npc-dry_well.md#hook_dry_well_017)：分歧：呼號追索人想沿用舊頻道，記錄人要求先確認對方身份。 合作：先記實際可驗通聯而非補造回應。

利益群體：dw_fuel_cooperative、dw_caravan_brokers。前置缺口：electronics、item_ownership、jobs、knowledge、navigation、npc_relationship。研究：FICTION-METRO、FICTION-WOOL、LD-P02、WG-04。

<a id="hook_dry_well_017"></a>
## hook_dry_well_017 · 舊呼號查證人

公開需要：核對接收器記到的呼號是否仍有合法使用者。
個人利害：盼著找到老夥伴，怕承認可能只是重用號碼。
能提供：有真正收到的訊息片段與當時條件。
限制：不能從號碼自動生成NPC、位置或營地。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『舊呼號查證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原訊息仍可查且有合法聯絡窗口。
不介入：若核實已換人，更新來源；若無回覆只留未知，不自動觸發救援死者。

物品：[訊號接收器](items.md#content_signal_receiver)、[無線電](items.md#content_radio)
遭遇：[訊號接收器與舊呼號](encounters-npc.md#npc_069)

- [值班通聯記錄人](npc-dry_well.md#hook_dry_well_016)：分歧：值班人要求明確身份，查證人更想先回話。 合作：使用不泄露私人位置的有限核認。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：electronics、identification、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade。研究：FICTION-METRO、FICTION-WOOL、LD-P02、WG-04。

<a id="hook_dry_well_018"></a>
## hook_dry_well_018 · 借電池返還人

公開需要：確認借的是可耗用電力、整件電池還是抵押物。
個人利害：怕歸還空電池被說欠一顆新的，也不願裝滿已交付。
能提供：有原借用人與可回查的文字條款。
限制：不能免費充電或把物件憑空補滿。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『借電池返還人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：借用尚未結清且原物可查。
不介入：若原主接受有效替代，記清唯一交付；不讓舊新兩顆都留在玩家手上。

物品：[電池](items.md#content_battery)、[手電筒](items.md#content_flashlight)
遭遇：[借來的電池何時歸還](encounters-npc.md#npc_070)

- [值班通聯記錄人](npc-dry_well.md#hook_dry_well_016)：分歧：值班人要維持通聯，返還人需按約交物。 合作：先找合法可用替代來源，再結清原借約。

利益群體：dw_caravan_brokers、dw_fuel_cooperative。前置缺口：electronics、item_ownership、jobs、knowledge、lighting、navigation、npc_relationship、regional_trade。研究：LD-P02、WG-03、WG-04、WG-05。

<a id="hook_dry_well_019"></a>
## hook_dry_well_019 · 茶葉短工雇主

公開需要：用有限茶葉委託一次排隊代辦，先確認對方願意收實物。
個人利害：手頭貨多現錢少，怕把欠薪包裝成分享。
能提供：有自己可合法處分的一小批茶與明確工項。
限制：不把奢侈品當任意等值貨幣或無限工作獎勵。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『茶葉短工雇主』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本人仍有有限貨物且代辦尚未被完成。
不介入：若自己已辦完或茶已另售，關閉邀請；完成一單後不刷新同一報酬。

物品：[茶葉](items.md#content_tea)、[紙本日記](items.md#content_paper_journal)
遭遇：[茶葉換的是時間](encounters-npc.md#npc_071)

- [欠水帳協調人](npc-dry_well.md#hook_dry_well_014)：分歧：欠水協調人擔心代領混淆借水責任，雇主只需合法代辦。 合作：把受委託人、受益人與實物報酬分清。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：LD-P02、WG-02、WG-04。

<a id="hook_dry_well_020"></a>
## hook_dry_well_020 · 香料來源保管人

公開需要：分清外地袋印與袋內後來裝的實際貨物。
個人利害：想賣出家鄉商品，怕重新分裝被誤認成假貨。
能提供：有現存貨袋與自己能證明的交付鏈。
限制：袋印不是成分、品質或國籍的絕對證據。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『香料來源保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：貨尚未成交且物主願做有限查驗。
不介入：若已成交，後續更正依同意處理；不倒改原價或生成另一批貨。

物品：[香料](items.md#content_spices)、[布袋](items.md#content_cloth_sack)
遭遇：[香料袋上的外地印](encounters-npc.md#npc_072)

- [返程帳簿保管人](npc-dry_well.md#hook_dry_well_028)：分歧：帳簿保管人想統一品名，保管人要求保留混裝說明。 合作：分列外包與內物來源可降低爭議。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：LD-P01、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_021"></a>
## hook_dry_well_021 · 羅盤偏差觀察人

公開需要：在遠離可疑金屬的位置比較兩只指南針，記下條件。
個人利害：怕自己帶錯路失信，也不想隨便丟掉仍可能可用的工具。
能提供：有原路線觀察與物主同意的對照物。
限制：比較結果不是開新路或全程導航保證。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『羅盤偏差觀察人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：指南針仍可查且有安全合法的對照地點。
不介入：若器材已由專業者修復，更新記錄；若物主離開，停止借測。

物品：[指南針](items.md#content_compass)、[逆磁片](items.md#content_reverse_magnetic_shard)
遭遇：[兩個指南針指向不同](encounters-npc.md#npc_073)、[被誇大的擋彈展示](encounters-anomaly.md#anomaly_023)

- [路況紙抄錄人](npc-dry_well.md#hook_dry_well_013)：分歧：路況抄錄人想寫清方向，觀察人還不確定偏差原因。 合作：將異常區與可驗地標分開記。

利益群體：dw_caravan_brokers。前置缺口：combat_extension、equipment、exploration、hazards、identification、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade、reputation。研究：FICTION-METRO、FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_022"></a>
## hook_dry_well_022 · 護目鏡借用協調人

公開需要：替沙塵中的短工安排可確認用途的護目鏡。
個人利害：想早點上工，又怕別人把眼部防護說成呼吸防護。
能提供：能說明現有裝備種類與借用窗口。
限制：不能拿護目鏡替代面罩或發明抗污染數值。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『護目鏡借用協調人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：真實短工仍需要裝備且物主願借。
不介入：若工作取消或借期終了，交還物件；不自行把它配到玩家裝備欄。

物品：[工程護目鏡](items.md#content_engineering_goggles)、[沙塵面罩](items.md#content_dust_mask)
遭遇：[護目鏡不是面罩](encounters-npc.md#npc_074)

- [長袍補洞裁補人](npc-dry_well.md#hook_dry_well_007)：分歧：裁補人願用布擋沙，協調人要求清楚哪些部位仍未保護。 合作：把衣物、眼部與呼吸用途分開說明。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：equipment、hazards、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROAD、LD-P02、WG-04、WG-05。

<a id="hook_dry_well_023"></a>
## hook_dry_well_023 · 井架繩索原主

公開需要：在到期前通知井口需要歸還私人繩。
個人利害：自己也要裝貨，不想因取回私物被罵自私。
能提供：有真實借條與另一項已同意用途。
限制：不能擅自拆正在使用的承重構件造成危險。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『井架繩索原主』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原繩仍在且借期尚待結清。
不介入：若已有合法替代，正常交還；若未解決，只保留待協商，不用敘事自動斷繩。

物品：[繩索](items.md#content_rope)、[舊旅行包](items.md#content_travel_backpack)
遭遇：[留在井架上的繩索](encounters-npc.md#npc_067)

- [井口輪值人](npc-dry_well.md#hook_dry_well_003)：分歧：輪值人想延長遮布用途，原主已有在先出發承諾。 合作：先協商安全交還時間與真實替代物。

利益群體：dw_well_queue、dw_outer_camps。前置缺口：cargo、hazards、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_024"></a>
## hook_dry_well_024 · 油燈夜班保管人

公開需要：分配現有燈具的借用順序，燃料耗用另立條款。
個人利害：怕讓一班照明就使下一班無油，也怕暗處錯帳。
能提供：有可查的燈具、實際可用燃料與值班承諾。
限制：不能把油燈轉成永久光照或隨意挪飲用水容器裝油。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『油燈夜班保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：燈具仍可借且燃料來源已確認。
不介入：若夜班已結束，關閉本輪分配；下一輪依真實存量重新安排。

物品：[油燈](items.md#content_oil_lamp)、[燃料罐](items.md#content_fuel_can)
遭遇：[燈油該留給哪一班](encounters-npc.md#npc_076)

- [燃料核帳員](npc-dry_well.md#hook_dry_well_001)：分歧：核帳員要完整查單時間，保管人要照顧既定夜班。 合作：先處理可在白天核對的部分。

利益群體：dw_fuel_cooperative、dw_well_queue。前置缺口：cooking、item_ownership、jobs、knowledge、lighting、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-03、WG-04。

<a id="hook_dry_well_025"></a>
## hook_dry_well_025 · 混用水壺查驗人

公開需要：把曾裝油的壺與已知飲用容器分開保管。
個人利害：想挽回損失，卻不願因洗過就向人保證能喝。
能提供：可指出實際使用史與原主同意的外觀查驗。
限制：不能用手電照一下就認證清潔或可飲。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『混用水壺查驗人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：該壺仍在且來源史可核查。
不介入：若已由合格處理者驗證，依結果更新；不自動增加水存量。

物品：[水壺](items.md#content_water)、[燃料罐](items.md#content_fuel_can)
遭遇：[裝過油的空水壺](encounters-npc.md#npc_077)

- [欠水帳協調人](npc-dry_well.md#hook_dry_well_014)：分歧：欠水協調人急找可裝水物，查驗人要保留未知風險。 合作：先尋已知用途容器，問題壺另談處理。

利益群體：dw_well_queue、dw_outer_camps。前置缺口：hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、water_treatment。研究：LD-P02、WG-01、WG-04。

<a id="hook_dry_well_026"></a>
## hook_dry_well_026 · 出發前醫療袋分配人

公開需要：讓護衛與車伕釐清誰保管急救包，以及誰能合法使用。
個人利害：不想重要用品被當地位象徵，也怕交給不會用的人。
能提供：有原主授權與當次同行者同意。
限制：分配不產生治療效果或傷病，持有不是醫療資格。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『出發前醫療袋分配人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：真實出發仍在準備且物件歸屬清楚。
不介入：若行程取消，按原主指示交還；不用敘事自動消耗急救包。

物品：[急救包](items.md#content_first_aid_kit)、[醫療袋](items.md#content_medical_satchel)
遭遇：[急救包先給護衛還是車伕](encounters-npc.md#npc_075)

- [照護用品收貨人](npc-dry_well.md#hook_dry_well_008)：分歧：收貨人有聚落驗收承諾，分配人要為真實出行留有限物資。 合作：只協商尚未承諾的部分，已交付物不重複分派。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：cargo、injury、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_027"></a>
## hook_dry_well_027 · 末位車位申請人

公開需要：為自己與有限行李申請最後尚未承諾的位置。
個人利害：急著趕往已知聯絡地，但不願編造病重親人插隊。
能提供：可提供真實目的與自備補給。
限制：沒有權利把守約者擠掉或增加商隊容量。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『末位車位申請人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：商隊仍在且確有未承諾空位。
不介入：若空位合法給別人或商隊出發，邀約結束；不暫停行程等玩家。

物品：[舊旅行包](items.md#content_travel_backpack)、[水袋](items.md#content_waterskin)
遭遇：[最後一個仍未承諾的車位](encounters-npc.md#npc_080)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人需優先履行舊承諾，申請人希望新情況被聽見。 合作：比較合法可變更部分並取得原承諾者同意。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-METRO、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_028"></a>
## hook_dry_well_028 · 返程帳簿保管人

公開需要：保護尚未核對的紙帳，保留原筆跡與頁序。
個人利害：怕一本帳淋壞就讓所有人互不信任。
能提供：掌握原簿、可用防水袋與有權查閱者名單。
限制：不得偷偷補寫缺頁或把防水袋複製給每本帳。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『返程帳簿保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原簿仍存在且未完成合法歸檔。
不介入：若核帳完成且已歸檔，保管工作結束；對受損部分只能記缺失。

物品：[防水袋](items.md#content_waterproof_bag)、[紙本日記](items.md#content_paper_journal)
遭遇：[返程帳簿怕的是水](encounters-npc.md#npc_079)

- [燃料核帳員](npc-dry_well.md#hook_dry_well_001)：分歧：核帳員需要拆封看帳，保管人怕查完沒人重新包好。 合作：明定查閱、封回與交接步驟。

利益群體：dw_fuel_cooperative、dw_caravan_brokers。前置缺口：cargo、hazards、item_ownership、jobs、knowledge、navigation、npc_relationship。研究：FICTION-METRO、LD-P02、WG-04、WG-05。

<a id="hook_dry_well_029"></a>
## hook_dry_well_029 · 外套徽章保管者

公開需要：確認商隊徽章是否經合法同意轉交，避免穿衣者冒認。
個人利害：想保留舊夥伴記號，又不願讓它變通行特權。
能提供：有可查借衣記錄與原徽章描述。
限制：徽章不創造派系成員資格或免檢權。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『外套徽章保管者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原衣仍在且物主願意商議。
不介入：若已正式去除授權，僅改標示；不能把既有角色身份從世界抹掉。

物品：[工人皮衣](items.md#content_worker_leather_jacket)、[商隊外套](items.md#content_caravan_coat)
遭遇：[皮衣的商隊徽章](encounters-npc.md#npc_078)、[排程人與相同的外套](encounters-npc.md#npc_008)

- [長袍補洞裁補人](npc-dry_well.md#hook_dry_well_007)：分歧：裁補人要能穿的衣服，保管者希望徽章不被任意移走。 合作：另存徽章的合法方案可保留物件與紀念。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：crafting、equipment、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、FICTION-METRO、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_030"></a>
## hook_dry_well_030 · 外營寄物帳管理人

公開需要：讓未搭上車的人能自願寄存有限行李，說清領回條件。
個人利害：怕成為無限免費倉庫，也不想讓居民不得不賣掉私物。
能提供：有實际可用小空間與保管者同意。
限制：不能創造容量加成、永久倉庫或自動繼承。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『外營寄物帳管理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：仍有合法有限保管位置且物主在場同意。
不介入：若物主先領回，關閉對應寄物；到期處置需正式authority，不能自動吞物。

物品：[舊旅行包](items.md#content_travel_backpack)、[密封貨箱](items.md#content_sealed_cargo_crate)
遭遇：[最後一個仍未承諾的車位](encounters-npc.md#npc_080)、[返程帳簿怕的是水](encounters-npc.md#npc_079)

- [末位車位申請人](npc-dry_well.md#hook_dry_well_027)：分歧：車位申請人想立刻寄下所有物，管理人只能收已同意份額。 合作：挑最需保管部分並保留其他物的去向。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：cargo、hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade、reputation。研究：FICTION-METRO、LD-P02、WG-02、WG-04、WG-05。

<a id="hook_dry_well_031"></a>
## hook_dry_well_031 · 沙地露營位置協調人

公開需要：在已有管理者同意的區域安排帳篷，不擋取水通道。
個人利害：想給外營人遮蔽，也怕被說把井邊據為己有。
能提供：有真實可用區域與在場同意者。
限制：不能新增地點人口、保證安全或強占私地。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『沙地露營位置協調人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：現有在場者自願使用且管理者仍同意。
不介入：若使用者正式離開或場地許可到期，收起臨時安排；不自動生成新營民。

物品：[帳篷](items.md#content_tent)、[繩索](items.md#content_rope)
遭遇：[井口輪值人的遮布](encounters-npc.md#npc_009)、[帳篷要先留給病人嗎](encounters-npc.md#npc_024)

- [井口輪值人](npc-dry_well.md#hook_dry_well_003)：分歧：輪值人要通道清楚，協調人想靠近水源減少搬運。 合作：標出有限不擋路的暫住範圍。

利益群體：dw_outer_camps、dw_well_queue。前置缺口：camping、cargo、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_032"></a>
## hook_dry_well_032 · 地圖註記寄售人

公開需要：出售自己有權分享的路線註記，標出未走過的段落。
個人利害：想靠經驗賺錢，怕寫太多未知就無人肯買。
能提供：能提供親自觀察的地標與時間。
限制：地圖不直接解除危險、開通道路或保證有寶。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『地圖註記寄售人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：註記仍由合法持有人售出且未承諾獨家。
不介入：若新事實使某段過時，更新說明；已完成交易依原條款不倒帶。

物品：[舊世地圖](items.md#content_old_world_map)、[地質調查圖](items.md#content_geological_survey_map)
遭遇：[過期一天的路況紙](encounters-npc.md#npc_064)、[兩個指南針指向不同](encounters-npc.md#npc_073)

- [路況紙抄錄人](npc-dry_well.md#hook_dry_well_013)：分歧：抄錄人需保留來源，寄售人想避免私人藏身地公開。 合作：只交易同意分享的公共路段。

利益群體：dw_caravan_brokers。前置缺口：hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade。研究：FICTION-METRO、LD-P01、LD-P02、WG-04。

<a id="hook_dry_well_033"></a>
## hook_dry_well_033 · 有限鹽料買家

公開需要：為一次已存在的食物保存工作尋找可驗鹽料。
個人利害：不想每次到商隊快走才被迫接受不清楚的交換。
能提供：有現存食物與可協商的有限購買量。
限制：不構成永遠高價收鹽，保存效果需未來烹調規則。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『有限鹽料買家』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當次工作尚未完成且採購未滿。
不介入：若已向別人買足，就關閉需求；不讓相同工作無限重置。

物品：[鹽](items.md#content_salt)、[肉乾](items.md#content_jerky)
遭遇：[回程前的肉乾分配](encounters-npc.md#npc_066)、[香料袋上的外地印](encounters-npc.md#npc_072)

- [香料來源保管人](npc-dry_well.md#hook_dry_well_020)：分歧：香料保管人希望連帶出售，買家只需用途明確的鹽。 合作：分開報價與來源，讓雙方可拒絕捆售。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：cargo、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROAD、LD-P01、LD-P02、WG-02、WG-04。

<a id="hook_dry_well_034"></a>
## hook_dry_well_034 · 水具歸還接洽人

公開需要：在商隊出發前清楚核对哪些水壺是租借而非售出。
個人利害：怕工具追不回，也怕為找一只壺阻擋整隊。
能提供：有具體借條與可辨的現存容器。
限制：不能扣下全部乘員或把借物變成配水特權。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『水具歸還接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：借期仍有效且商隊尚可接洽。
不介入：若按有效條款交由代理人歸還，就關閉原追索；離隊者不被自動召回。

物品：[水壺](items.md#content_water)、[水袋](items.md#content_waterskin)
遭遇：[漏水袋與欠水數](encounters-npc.md#npc_065)、[裝過油的空水壺](encounters-npc.md#npc_077)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人需要準時離開，接洽人要完成合法歸還。 合作：先釐清借物去向，再協商合法替代而不重複交付。

利益群體：dw_well_queue、dw_caravan_brokers。前置缺口：cargo、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、water_treatment。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_dry_well_035"></a>
## hook_dry_well_035 · 遠望地標觀察人

公開需要：從可合法停留處核對遠方地標變化，不跟蹤私人營地。
個人利害：希望消息有價值，也怕看錯影子害人繞遠。
能提供：有望遠鏡、觀察位置與記錄時間。
限制：看見輪廓不代表確認敵人、藏寶或可通行路。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『遠望地標觀察人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：地標仍可見且觀察位置合法安全。
不介入：若氣候或場地條件改變，暂停新觀察；不宣告永久探測能力。

物品：[望遠鏡](items.md#content_binoculars)、[指南針](items.md#content_compass)
遭遇：[過期一天的路況紙](encounters-npc.md#npc_064)、[兩個指南針指向不同](encounters-npc.md#npc_073)

- [路況紙抄錄人](npc-dry_well.md#hook_dry_well_013)：分歧：路況抄錄人想寫明結論，觀察人只肯記實際所見。 合作：保留觀察角度與不確定性讓後續可比較。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade。研究：FICTION-METRO、LD-P01、LD-P02、WG-04。

<a id="hook_dry_well_036"></a>
## hook_dry_well_036 · 未知藥寄物保管人

公開需要：在合法專業查驗前把未標示藥劑與已知用品分開。
個人利害：不願錯失可能有用的東西，又不想讓急切的人先喝。
能提供：有原封裝與來源交接記錄。
限制：不得提供未驗證劑量、療效或讓人作試驗。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『未知藥寄物保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原件仍在且物主同意保管。
不介入：若合格鑑別完成，依結果重新歸類；若物主領回，不生成替代品。

物品：[未標示藥劑](items.md#content_unlabelled_medicine)、[醫療袋](items.md#content_medical_satchel)
遭遇：[不肯收空藥盒的照護者](encounters-npc.md#npc_059)

- [照護用品收貨人](npc-dry_well.md#hook_dry_well_008)：分歧：收貨人不願入已驗收帳，保管人想保留可查線索。 合作：分成待鑑別寄物，不列可用醫療存量。

利益群體：dw_outer_camps。前置缺口：cargo、injury、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、LD-P02、WG-01、WG-04。

<a id="hook_dry_well_037"></a>
## hook_dry_well_037 · 冷樣本買家聯絡人

公開需要：替不冷的冰找願在未知條件下接洽的合法買家。
個人利害：想得到好價，卻不肯讓食物商先把樣本放進食品。
能提供：能展示有限非食品接觸的溫感觀察。
限制：未知樣本沒有固定市價，也不保證冷藏安全。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『冷樣本買家聯絡人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原樣本尚未成交且物主同意接洽。
不介入：若已有合法轉交，其餘詢價關閉；不把同一樣本賣給第二位。

物品：[不冷的冰](items.md#content_uncold_ice)、[防水袋](items.md#content_waterproof_bag)
遭遇：[車隊的降溫承諾](encounters-anomaly.md#anomaly_003)、[兩只不同的測溫杯](encounters-anomaly.md#anomaly_004)

- [有限鹽料買家](npc-dry_well.md#hook_dry_well_033)：分歧：保存食物的買家急用，聯絡人希望先確認隔離條件。 合作：先談有限鑑別，不用食物品質作賭注。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：exploration、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_038"></a>
## hook_dry_well_038 · 黑滴封口記錄人

公開需要：記下容器外可見的液面與封口狀態，不先開封。
個人利害：怕未知物被誤認可用燃料，又擔心封太死無法觀察。
能提供：有原容器標記與合法保管链。
限制：不因黑色外觀判斷可燃、可飲或能治病。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『黑滴封口記錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原樣本仍封存且管理者同意外觀記錄。
不介入：若合法買家接收，移交封口記錄；不把它倒入公庫自動增產。

物品：[黑色水滴](items.md#content_black_water_drop)、[玻璃](items.md#content_glass)
遭遇：[井邊的黑點瓶](encounters-anomaly.md#anomaly_005)、[黑滴的重量爭執](encounters-anomaly.md#anomaly_007)

- [燃料核帳員](npc-dry_well.md#hook_dry_well_001)：分歧：核帳員拒絕把未知液體列燃料，記錄人想保留研究價值。 合作：另列待鑑別物，不混入既有fuel總量。

利益群體：dw_fuel_cooperative、dw_outer_camps。前置缺口：cargo、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_039"></a>
## hook_dry_well_039 · 輕石行李查驗人

公開需要：确认空心石的可見重量異常是否造成貨單誤解。
個人利害：怕真實輕物被當少交，也怕有人借異常名義偷換樣本。
能提供：有封包標記與相同條件稱量記錄。
限制：輕物不等於免費容量或可浮空運輸。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『輕石行李查驗人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍在本批貨內且查驗獲同意。
不介入：若已合法卸貨，關閉本批核查；之後不重複收取同一件運费。

物品：[空心石](items.md#content_hollow_stone)、[密封貨箱](items.md#content_sealed_cargo_crate)
遭遇：[輕石不是救生浮具](encounters-anomaly.md#anomaly_011)、[沒有保護層的寄送盒](encounters-anomaly.md#anomaly_012)

- [商隊排程人](npc-dry_well.md#hook_dry_well_002)：分歧：排程人按實際容量排貨，查驗人希望特殊樣本分列。 合作：維持唯一樣本記號並按真實尺寸重量記錄。

利益群體：dw_caravan_brokers。前置缺口：cargo、exploration、hazards、identification、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_040"></a>
## hook_dry_well_040 · 鳴石交易見證人

公開需要：讓買賣雙方聽到的是同一條件下的鳴聲。
個人利害：不想被用作保證奇效的人，只願見證已發生的交易。
能提供：可記錄樣本標記與實際演示條件。
限制：聲音不證明未來永遠有效，也不固定買家估價。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『鳴石交易見證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原物仍可合法交易且雙方願意在場。
不介入：若交易撤回則停止演示；收據只記真正交付與未驗證項目。

物品：[鳴石](items.md#content_humming_stone)、[電池](items.md#content_battery)
遭遇：[泵聲掩住石聲](encounters-anomaly.md#anomaly_015)、[兩位研究者的同一塊石頭](encounters-anomaly.md#anomaly_016)

- [值班通聯記錄人](npc-dry_well.md#hook_dry_well_016)：分歧：通聯值班人怕測試耗電，見證人要可比較環境。 合作：選不影響當班工作的有限演示時間。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：cargo、electronics、exploration、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_041"></a>
## hook_dry_well_041 · 靜電樣本接收人

公開需要：拒絕把靜電骨直接列成可供商隊使用的電池。
個人利害：想探索替代能源，卻不能拿別人的無線電當試具。
能提供：有有限隔離容器與原主同意的外觀記錄。
限制：不可宣稱可充電、永不耗盡或改寫fuel庫存。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『靜電樣本接收人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原樣本仍在且接收條件未被撤回。
不介入：若正式檢驗排除用途，更新提案；沒有結果就保持未知而不自動供電。

物品：[靜電骨](items.md#content_static_bone)、[電池](items.md#content_battery)
遭遇：[雨後不再吸灰](encounters-anomaly.md#anomaly_019)、[把樣本當武器的提議](encounters-anomaly.md#anomaly_020)

- [借電池返還人](npc-dry_well.md#hook_dry_well_018)：分歧：返還人急需可交還電池，接收人不願拿未知物冒充。 合作：將眼前歸還義務與未來研究分開。

利益群體：dw_fuel_cooperative、dw_caravan_brokers。前置缺口：camping、cargo、combat_extension、electronics、equipment、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_042"></a>
## hook_dry_well_042 · 異常磁片寄運人

公開需要：詢問接收者是否同意隔離寄運，先説明已觀察的金屬排斥。
個人利害：怕貨被當普通片材壓在羅盤旁，也怕被拒運後無處放。
能提供：有樣本原位與有限觀察紀錄。
限制：寄運同意不是用途認證，不保證對所有金屬有效。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『異常磁片寄運人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：物主仍有處分權且承運者明確同意條件。
不介入：若承運者拒絕，該邀約終止；不得偷偷放進別人的行李。

物品：[逆磁片](items.md#content_reverse_magnetic_shard)、[防水袋](items.md#content_waterproof_bag)
遭遇：[收樣櫃的鐵扣](encounters-anomaly.md#anomaly_024)、[兩個指南針指向不同](encounters-npc.md#npc_073)

- [羅盤偏差觀察人](npc-dry_well.md#hook_dry_well_021)：分歧：羅盤觀察人想把樣本留作對照，寄運人已有實際交付承諾。 合作：在原主同意下先完成有限記錄再交接。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：cargo、exploration、hazards、identification、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade。研究：FICTION-METRO、FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_043"></a>
## hook_dry_well_043 · 無影玻璃遮光試驗人

公開需要：在同一遮擋與光源下記錄影子異常，保留普通玻璃對照。
個人利害：想向研究者說明現象，怕只有照片被指弄假。
能提供：有原樣本與可合法使用的有限光源。
限制：不宣稱隱形、潛行加成或免受監視。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『無影玻璃遮光試驗人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍可觀察且照明原主同意。
不介入：若樣本移交研究者，當地測試結束；不複制另一片供反覆接任務。

物品：[無影玻璃](items.md#content_shadowless_glass)、[手電筒](items.md#content_flashlight)
遭遇：[看似空著的窗框](encounters-anomaly.md#anomaly_025)、[無影玻璃的包裹清單](encounters-anomaly.md#anomaly_027)

- [油燈夜班保管人](npc-dry_well.md#hook_dry_well_024)：分歧：油燈保管人要保障夜班，試驗人需要穩定光源。 合作：把觀察安排在借期內且明記實際耗用。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：cargo、exploration、hazards、identification、injury、item_ownership、jobs、knowledge、lighting、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_044"></a>
## hook_dry_well_044 · 灰種寄售異議人

公開需要：要求賣家保留未知標籤，不把種粒叫作耐旱糧種。
個人利害：想改善生活，卻不願外營人拿最後飲水種未驗證物。
能提供：有原袋照片與可核對的推銷說法。
限制：不能直接宣布有毒、可食或一定欺詐。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『灰種寄售異議人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原貨仍未成交且推銷說法可核查。
不介入：若賣方已更正，關閉異議；不因玩家缺席強制毀掉種子。

物品：[灰種](items.md#content_gray_seed)、[種植手冊](items.md#content_planting_manual)
遭遇：[混進普通種子的灰粒](encounters-anomaly.md#anomaly_029)、[以灰種抵糧的契約](encounters-anomaly.md#anomaly_032)

- [香料來源保管人](npc-dry_well.md#hook_dry_well_020)：分歧：來源保管人怕撤掉好聽名字難賣，異議人只要求誠實說明。 合作：改成有條件研究詢價，保留買家退出。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：cargo、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROADSIDE、LD-P02、WG-02、WG-04、WG-06。

<a id="hook_dry_well_045"></a>
## hook_dry_well_045 · 熱核夜宿接洽人

公開需要：把發熱樣本與睡袋保持可退出的觀察安排，不讓人直接抱著睡。
個人利害：夜冷時很想試，仍怕害別人相信永久安全。
能提供：有物主同意的有限觀察位置與隔離方案。
限制：熱量現象不構成醫療、露營安全或免費燃料authority。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『熱核夜宿接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍在且所有在場參與者知情同意。
不介入：若夜宿安排已改變，停止該輪試驗；不用寒冷敘事製造必然傷害。

物品：[熱核](items.md#content_heat_core)、[睡袋](items.md#content_sleeping_bag)
遭遇：[工坊的永動招標](encounters-anomaly.md#anomaly_035)、[雪夜的兩種暖意](encounters-anomaly.md#anomaly_036)

- [沙地露營位置協調人](npc-dry_well.md#hook_dry_well_031)：分歧：營位協調人想多容一人，接洽人要求保持樣本隔離空間。 合作：不占用既定睡位的範圍才可提測試。

利益群體：dw_outer_camps、dw_well_queue。前置缺口：camping、cargo、electronics、exploration、hazards、identification、injury、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROAD、FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_046"></a>
## hook_dry_well_046 · 沉默盒貨主

公開需要：告知承運者附近通聯可能異常，再談是否接受特殊貨。
個人利害：想把貨送走，怕誠實說明就沒人願收。
能提供：有真實可重現與不可重現的觀察清單。
限制：不能暗中屏蔽商隊訊號或承諾絕對保密。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『沉默盒貨主』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原盒仍由本人合法持有且寄運尚未成立。
不介入：若承運者拒運就保持未成交；不自動強塞商隊或關閉全區無線電。

物品：[沉默盒](items.md#content_silence_box)、[密封貨箱](items.md#content_sealed_cargo_crate)
遭遇：[要在市場試沉默盒](encounters-anomaly.md#anomaly_038)、[失聯商隊與錯放的箱子](encounters-anomaly.md#anomaly_039)

- [值班通聯記錄人](npc-dry_well.md#hook_dry_well_016)：分歧：值班人要保持通聯，貨主希望不用揭露全部私人研究。 合作：提供必要風險資訊，無關私人內容另保留。

利益群體：dw_caravan_brokers。前置缺口：electronics、exploration、identification、item_ownership、jobs、knowledge、navigation、npc_relationship、regional_trade、reputation。研究：FICTION-METRO、FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_dry_well_047"></a>
## hook_dry_well_047 · 外營手工介紹人

公開需要：為在場居民的裁補、搬運與記帳找有限合法短工。
個人利害：不願用悲慘身世替人換工作，更不想答應不存在的報酬。
能提供：知道自願公開的能力與實際可接時段。
限制：不能自動招募NPC、增加人口或替人承諾技能。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『外營手工介紹人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有既存自願接工者與真實未被承接的工作。
不介入：若雙方自行成交或需求完成，媒合關閉；不生成下一批無限工人。

物品：[工具腰帶](items.md#content_tool_belt)、[布料](items.md#content_cloth)
遭遇：[沙地長袍的補洞顏色](encounters-npc.md#npc_058)、[茶葉換的是時間](encounters-npc.md#npc_071)

- [茶葉短工雇主](npc-dry_well.md#hook_dry_well_019)：分歧：茶葉雇主偏好實物付酬，介紹人需確認工作者接受。 合作：先清楚列報酬與工項，再由本人選。

利益群體：dw_outer_camps、dw_caravan_brokers。前置缺口：crafting、equipment、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_dry_well_048"></a>
## hook_dry_well_048 · 公私物交接見證人

公開需要：在井口與商隊之間分清借具、售貨、捐贈三種交付。
個人利害：怕好心援助被當債，也怕借出物被誤當不要了。
能提供：能見證當事人明確同意的有限交易。
限制：不能代表缺席者放棄所有權或修改世界資源。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『公私物交接見證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有真實交接且雙方在場知情。
不介入：若交接取消即無物資變動；已合法交付只留收據，不再次發放。

物品：[繩索](items.md#content_rope)、[燃料罐](items.md#content_fuel_can)、[水壺](items.md#content_water)
遭遇：[油桶領條的兩種印記](encounters-npc.md#npc_056)、[漏水袋與欠水數](encounters-npc.md#npc_065)、[留在井架上的繩索](encounters-npc.md#npc_067)

- [欠水帳協調人](npc-dry_well.md#hook_dry_well_014)：分歧：欠水協調人想先解急需，見證人要先確定交付性質。 合作：只用一句清楚條款也能保存雙方理解。

利益群體：dw_fuel_cooperative、dw_well_queue、dw_outer_camps。前置缺口：cargo、hazards、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、reputation。研究：FICTION-METRO、FICTION-ROAD、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_dry_well_049"></a>
## hook_dry_well_049 · 私人路線消息保管人

公開需要：讓信差取得可送達的聯絡方法，不公開居民藏物點。
個人利害：希望失聯朋友被找到，又怕消息被商人轉售。
能提供：持有自願提供且可撤回的聯絡線索。
限制：不把私人地點寫成公開新城，也不推定消息中的人仍存活。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『私人路線消息保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：授權仍有效且線索未被正式排除。
不介入：若來源撤回或真實遷徙使其過時，停止新轉交；不叫回離開人口。

物品：[紙本日記](items.md#content_paper_journal)、[沒有寄出的信](items.md#content_unsent_letter)
遭遇：[返程信差的兩個地址](encounters-npc.md#npc_010)、[過期一天的路況紙](encounters-npc.md#npc_064)

- [返程信差](npc-dry_well.md#hook_dry_well_004)：分歧：信差需要可執行地址，保管人只獲準分享有限指引。 合作：經本人或有權代理同意後轉交必要部分。

利益群體：dw_caravan_brokers、dw_outer_camps。前置缺口：hazards、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-METRO、LD-P01、LD-P02、WG-04。

<a id="hook_dry_well_050"></a>
## hook_dry_well_050 · 三份交班簿整理人

公開需要：把燃料、車位與取水的承諾並列，標出同一人不能同時在兩處的時段。
個人利害：想減少互相埋怨，又怕一份總表變成控制所有人的藉口。
能提供：有各方自願提供的有限當日交接資料。
限制：沒有新派系權威，不能凍結商隊、分配全部飲水或新增居民。
人口綁定：未來從乾井當前在場且存活的人口中，確認有意願承擔『三份交班簿整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：至少兩方有真實交接需求且同意共同核對。
不介入：若一方先結束工作，只關閉對應欄；其他世界行程照已有authority繼續。

物品：[紙本日記](items.md#content_paper_journal)、[舊世界手錶](items.md#content_old_world_watch)
遭遇：[燃料核帳員的第二張袋牌](encounters-npc.md#npc_007)、[排程人與相同的外套](encounters-npc.md#npc_008)、[井口輪值人的遮布](encounters-npc.md#npc_009)

- [燃料核帳員](npc-dry_well.md#hook_dry_well_001)：分歧：核帳員怕總表壓過原帳，整理人需要各欄能互相追溯。 合作：每筆保留真正負責者與原始依據。

利益群體：dw_fuel_cooperative、dw_caravan_brokers、dw_well_queue、dw_outer_camps。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、FICTION-METRO、FICTION-ROAD、LD-P02、WG-01、WG-02、WG-04。
