# 灰谷人物與關係鉤子

DESIGN_ONLY；是角色候選，沒有新增150人口。

<a id="hook_gray_valley_001"></a>
## hook_gray_valley_001 · 拆解場帶班工

公開需要：辨認舊工作服上的班別標記，找回借出的撬棍。
個人利害：怕把衣物當證據冤枉換班者，也不願丟掉整班工錢。
能提供：可提供真實領用簿與當日在場見證人。
限制：衣服不能證明身分；不得把員工當新增人口。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『拆解場帶班工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：工具仍未結清且帶班職責仍有效。
不介入：若工具先歸還，催還需求結束；若已交班，只移交有證據的未結事項。

物品：[舊工作服](items.md#content_work_clothes)、[撬棍](items.md#content_crowbar)
遭遇：[帶班工的卡住貨蓋](encounters-settlement.md#town_035)、[帶班工的衣物標記](encounters-npc.md#npc_004)

- [材料記帳員](npc-gray_valley.md#hook_gray_valley_003)：分歧：記帳員要先封帳，帶班工想等最後一位借用人說明。 合作：逐件對照可分清未還工具與已報廢材料。

利益群體：gv_yard_workers。前置缺口：cargo、exploration、item_ownership、jobs、knowledge、npc_relationship、repair、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_002"></a>
## hook_gray_valley_002 · 流動技工

公開需要：借足照明，檢查暗處故障並交回工具。
個人利害：寧可少接一單也不肯保證所有舊機器都能修好。
能提供：有可確認的工具清單與有限檢查能力。
限制：看見問題不等於取得修理或設備控制權。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『流動技工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本人尚未離城且設備管理者同意檢查。
不介入：若按既有行程離開，未接工作關閉；已接工作按約移交，不憑空留下替身。

物品：[手電筒](items.md#content_flashlight)、[扳手](items.md#content_wrench)
遭遇：[流動技工的磨損接頭](encounters-settlement.md#town_036)、[流動技工的暗角](encounters-npc.md#npc_005)

- [拆解場帶班工](npc-gray_valley.md#hook_gray_valley_001)：分歧：帶班工急著復工，技工要求先界定可安全檢查區。 合作：確認可做與不可做的範圍能減少空等。

利益群體：gv_workshops。前置缺口：identification、item_ownership、jobs、knowledge、lighting、npc_relationship、repair。研究：LD-P02、WG-01、WG-03、WG-04。

<a id="hook_gray_valley_003"></a>
## hook_gray_valley_003 · 材料記帳員

公開需要：分開可回收鋼筋與登記為借物的鋼筋棍。
個人利害：怕漏帳被認為私吞，又不想拿重量掩蓋用途差異。
能提供：掌握當批交接單與尚未熔解的物件。
限制：不能把有主工具自動改成廢料或直接更改市價。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『材料記帳員』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本批材料仍可辨認且尚未正式結算。
不介入：若已合法移交，改為追溯勘誤；不倒轉熔解或生成遺失工具。

物品：[鋼筋棍](items.md#content_rebar_club)、[廢鐵](items.md#content_scrap_iron)
遭遇：[材料記帳員的兩盤銅線](encounters-settlement.md#town_037)、[材料記帳員的兩種鋼筋](encounters-npc.md#npc_006)

- [拆解場帶班工](npc-gray_valley.md#hook_gray_valley_001)：分歧：帶班工想立即再用材料，記帳員要求先查原主。 合作：保留用途標記後可共同釋出確實可售部分。

利益群體：gv_yard_workers、gv_salvage_buyers。前置缺口：cargo、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_004"></a>
## hook_gray_valley_004 · 整具回收分揀人

公開需要：先把完整扳手從散料堆取出給原保管者核認。
個人利害：拆成料比較快結工錢，但完整工具可能更有用。
能提供：知道本批來源與尚未拆解的位置。
限制：沒有權利擅自據有回收場所有物件。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『整具回收分揀人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：整具仍在待分堆且所有權尚可查。
不介入：若原主已領回，只結清實際分揀勞動；不能再提供同一把作獎勵。

物品：[扳手](items.md#content_wrench)、[鉗子](items.md#content_pliers)
遭遇：[拆解場的整把工具](encounters-npc.md#npc_031)

- [材料記帳員](npc-gray_valley.md#hook_gray_valley_003)：分歧：記帳員看來源單，分揀人看實際完整程度。 合作：兩種證據合併可避免把借物當耗材。

利益群體：gv_yard_workers、gv_salvage_buyers。前置缺口：disassembly、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_005"></a>
## hook_gray_valley_005 · 宿舍照明接洽人

公開需要：替一段可合法停電檢查的燈線找技工。
個人利害：怕工坊先接高價急單，居民又要摸黑交班。
能提供：可召集同意檢查的住戶與現有故障記錄。
限制：不能擅闖房間、偷接電或宣告永久供電。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『宿舍照明接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：故障仍存在且住戶同意本次查驗。
不介入：若其他技工已修好，停止招工；若住戶搬離，依實際權責尋新聯絡人。

物品：[銅線](items.md#content_copper_wire)、[手電筒](items.md#content_flashlight)
遭遇：[比工錢更急的燈泡線](encounters-npc.md#npc_032)

- [流動技工](npc-gray_valley.md#hook_gray_valley_002)：分歧：技工不願跨過未知線路，接洽人希望一次修完。 合作：把檢查與修復分單可先建立可靠故障資料。

利益群體：gv_residents、gv_workshops。前置缺口：electronics、item_ownership、jobs、knowledge、lighting、npc_relationship、regional_trade、repair。研究：LD-P02、WG-02、WG-03、WG-04。

<a id="hook_gray_valley_006"></a>
## hook_gray_valley_006 · 工具換柄師傅

公開需要：替鏽扳手處理可握部分，保留原有刻記。
個人利害：不願用漂亮新柄掩飾金屬已裂的事實。
能提供：能指出外觀可見缺口並報有限工項。
限制：換柄不保證承重與機械性能，不能直接提升技能。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工具換柄師傅』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：物主同意處理且原工具尚未報廢。
不介入：若查出必須停用的實際缺陷，重新協商；未做的工項不自動收費。

物品：[扳手](items.md#content_wrench)、[橡膠](items.md#content_rubber)
遭遇：[生鏽扳手的新柄](encounters-npc.md#npc_033)

- [學徒工具整理人](npc-gray_valley.md#hook_gray_valley_029)：分歧：學徒想把工具弄得像新的一樣，師傅重視留下缺陷說明。 合作：先標出不可修部分，學徒仍可練有界線的手工。

利益群體：gv_workshops。前置缺口：crafting、item_ownership、jobs、knowledge、npc_relationship、repair。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_007"></a>
## hook_gray_valley_007 · 校準件保管人

公開需要：確認量測借具的歸還時段與使用範圍。
個人利害：最後一件可比較的樣本失準，就再也說不清責任。
能提供：持有既有借具紀錄與對照件。
限制：不能把私人標準件當全城認證權威。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『校準件保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍存在且有安全合法的觀察條件。
不介入：若樣本損壞或被合法領走，停止借用；不免費刷新一套。

物品：[萬用電表](items.md#content_multimeter)、[精密零件](items.md#content_precision_parts)
遭遇：[不肯交出校準件的人](encounters-npc.md#npc_034)

- [燒痕電表借用人](npc-gray_valley.md#hook_gray_valley_015)：分歧：電表借用人想立即復測，保管人要求先說明燒痕。 合作：有限對照並保存原始讀數能共同查因。

利益群體：gv_workshops。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_008"></a>
## hook_gray_valley_008 · 車板來源追查人

公開需要：核對胸甲車板是否出自有主車輛。
個人利害：想買便宜護具，但不想被當成拆走鄰居車門的人。
能提供：有可比對的舊照片與板面印記。
限制：相似印記不能單獨證明偷竊或定罪。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『車板來源追查人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原板與資料仍可查且當事人願意說明。
不介入：若已有合法讓渡證據，撤回疑問；若來源無解，保留未知而不發明犯罪。

物品：[車板胸甲](items.md#content_car_panel_cuirass)、[相機](items.md#content_camera)
遭遇：[車板胸甲的來歷](encounters-npc.md#npc_035)

- [材料記帳員](npc-gray_valley.md#hook_gray_valley_003)：分歧：記帳員只有批次資料，追查人要求到具體物主核認。 合作：先把確定來源與未知來源分欄。

利益群體：gv_salvage_buyers、gv_residents。前置缺口：equipment、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_gray_valley_009"></a>
## hook_gray_valley_009 · 唱片修整委託人

公開需要：只清理唱片一面，另一面留下原主的刻字。
個人利害：物件市價不高，卻怕修好聲音時抹去私人記號。
能提供：能指出可處理範圍並同意有限試聽。
限制：不擁有錄音裡所有人的公開同意。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『唱片修整委託人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原盤尚在且物主授權仍有效。
不介入：若物主撤回未開始部分即停工；已完成工作如實留下，不複製獎勵品。

物品：[黑膠唱片](items.md#content_vinyl_record)、[音樂播放器](items.md#content_music_player)
遭遇：[唱片的一面要留下](encounters-npc.md#npc_036)

- [工作錄音整理人](npc-gray_valley.md#hook_gray_valley_017)：分歧：錄音整理者想完整複製，委託人只授權私人保存。 合作：分開公開曲目與私人聲音可以共享部分記錄。

利益群體：gv_residents。前置缺口：electronics、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-02、WG-04。

<a id="hook_gray_valley_010"></a>
## hook_gray_valley_010 · 電池芯隔離記錄人

公開需要：把狀態未明的電池芯與普通廢鐵分堆。
個人利害：怕分揀速度慢影響工錢，又不想讓搬運人不知道帶了什麼。
能提供：可展示外觀異常與來源批次。
限制：不宣稱電芯能用或安全，也不隨意拆開。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『電池芯隔離記錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：該批物料仍未處置且有管理者同意的存放處。
不介入：若正式檢測或合法收運完成，關閉待查需求；不重生危險批次。

物品：[電池芯](items.md#content_battery_cell)、[工程護目鏡](items.md#content_engineering_goggles)
遭遇：[蓄電池芯不是普通貨](encounters-npc.md#npc_037)

- [整具回收分揀人](npc-gray_valley.md#hook_gray_valley_004)：分歧：分揀人要趕清場，記錄人要求保留隔離區。 合作：先移出已確認普通材料可以減輕場地壓力。

利益群體：gv_yard_workers、gv_workshops。前置缺口：cargo、electronics、hazards、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：LD-P02、WG-01、WG-04、WG-05。

<a id="hook_gray_valley_011"></a>
## hook_gray_valley_011 · 特號扳手守藏人

公開需要：保留六十三號的規格與刻印，不接受直接磨平。
個人利害：想知道它是否能找到原工廠，也怕被搶作古董。
能提供：可同意看外形與既有工廠線索。
限制：持物不等於擁有工廠，不能複製唯一工具。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『特號扳手守藏人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：真實唯一物仍在且物主有能力同意。
不介入：若原件轉交，依真實持有者重驗；不替舊保管者生成第二把。

物品：[六十三號](items.md#content_number_sixty_three)、[維修手冊](items.md#content_repair_manual)
遭遇：[六十三號的磨平提議](encounters-npc.md#npc_038)

- [工具故事展示人](npc-gray_valley.md#hook_gray_valley_032)：分歧：工具展覽人想公開展示，守藏人擔心引來不必要索取。 合作：可展示經同意的外觀圖，原件保持私人保管。

利益群體：gv_workshops、gv_residents。前置缺口：crafting、exploration、item_ownership、jobs、knowledge、npc_relationship、repair。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_012"></a>
## hook_gray_valley_012 · 舊錶修理委託人

公開需要：用共同可見事件核對手錶快慢，而不是改寫工時。
個人利害：怕自己的慢錶害人被扣工，也捨不得直接丟掉。
能提供：能提供多次在同一交班點做的觀察。
限制：私人鐘錶不是世界日數或付薪權威。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『舊錶修理委託人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原錶與當事人仍可比較尚未結清的記錄。
不介入：若工時已依法結清，修錶仍可另談；不得倒扣過去工錢。

物品：[舊世界手錶](items.md#content_old_world_watch)、[紙本日記](items.md#content_paper_journal)
遭遇：[舊手錶的慢十分鐘](encounters-npc.md#npc_039)

- [報工見證人](npc-gray_valley.md#hook_gray_valley_028)：分歧：報工人要確切時數，委託人只能提供有誤差的記錄。 合作：標出誤差後仍可還原事件先後。

利益群體：gv_residents、gv_workshops。前置缺口：item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_gray_valley_013"></a>
## hook_gray_valley_013 · 缺頁手冊追索人

公開需要：找出被剪走的維修頁是遺失、合法借用還是另有版次。
個人利害：自己曾只抄結論，怕錯版造成不實期待。
能提供：有封面、頁碼與可合法檢查的殘頁。
限制：不能從缺頁直接推定蓄意破壞。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『缺頁手冊追索人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：殘頁尚在且有可聯絡的合法持有人。
不介入：若借頁已歸還，改為版本核對；若原頁已毀，明記缺失不憑記憶造答案。

物品：[維修手冊](items.md#content_repair_manual)、[資料磁碟](items.md#content_data_disk)
遭遇：[誰把維修頁剪走](encounters-npc.md#npc_040)

- [維修頁抄寫人](npc-gray_valley.md#hook_gray_valley_030)：分歧：抄寫人希望借頁補本，追索人要求先核定版本。 合作：對照勘誤與頁碼可避免多抄一份錯誤。

利益群體：gv_workshops。前置缺口：identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-WOOL、LD-P02、WG-04。

<a id="hook_gray_valley_014"></a>
## hook_gray_valley_014 · 工具腰帶出借人

公開需要：核對空扣原來掛什麼，分清漏還工具與舊缺件。
個人利害：怕每次借出都慢慢少一件，卻不願無證據向工人討錢。
能提供：有最近一次可核實的交接描述。
限制：空扣不是偷竊證據，不可扣留借用人的私物。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工具腰帶出借人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本次借用尚未結清且工具仍可核查。
不介入：若舊記錄證明原先就缺件，撤掉追索；不另造被告。

物品：[工具腰帶](items.md#content_tool_belt)、[螺絲起子](items.md#content_screwdriver)
遭遇：[工具腰帶的空扣](encounters-npc.md#npc_041)

- [拆解場帶班工](npc-gray_valley.md#hook_gray_valley_001)：分歧：帶班工怕查物拖延散班，出借人要完成至少一次交接。 合作：按已知清單當場確認可免後來互相追討。

利益群體：gv_workshops、gv_yard_workers。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、reputation。研究：LD-P02、WG-02、WG-04。

<a id="hook_gray_valley_015"></a>
## hook_gray_valley_015 · 燒痕電表借用人

公開需要：把燒痕何時出現的事實說清，申請有限復查。
個人利害：擔心承認不知道就被要求賠整台。
能提供：能指出實際操作步驟與當時連接物。
限制：不能修改舊記錄或把不確定原因說成他人過失。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『燒痕電表借用人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：表仍封存且雙方同意查因。
不介入：若已有可信鑑定，按結果協商；玩家缺席不自動判賠。

物品：[萬用電表](items.md#content_multimeter)、[銅線](items.md#content_copper_wire)
遭遇：[電表燒痕的責任](encounters-npc.md#npc_045)

- [校準件保管人](npc-gray_valley.md#hook_gray_valley_007)：分歧：保管人怕再損害校準件，借用人希望證明不是誤用。 合作：共同先做不通電的外觀查驗。

利益群體：gv_workshops。前置缺口：electronics、item_ownership、jobs、knowledge、npc_relationship、repair、reputation。研究：LD-P02、WG-04、WG-05。

<a id="hook_gray_valley_016"></a>
## hook_gray_valley_016 · 班表攝影記錄人

公開需要：為工作交接保留照片，但隱去不願公開的人的名字。
個人利害：照片能證明自己到班，卻可能暴露別人的私人行程。
能提供：持有原照片並能提供經同意的局部查閱。
限制：物件持有權不等於可任意公開個人資料。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『班表攝影記錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原照片仍可讀且當事人願意限定查驗。
不介入：若其他證據已結清工作，停止為此公開照片；私人保存另循同意。

物品：[相機](items.md#content_camera)、[老照片](items.md#content_old_photograph)
遭遇：[拍照者與班表上的人](encounters-npc.md#npc_046)

- [報工見證人](npc-gray_valley.md#hook_gray_valley_028)：分歧：報工人需要足夠證據，攝影人受限於其他在場者同意。 合作：只核對相關時段與工具位置能減少侵入。

利益群體：gv_residents、gv_yard_workers。前置缺口：identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-WOOL、LD-P02、WG-04。

<a id="hook_gray_valley_017"></a>
## hook_gray_valley_017 · 工作錄音整理人

公開需要：把斷掉的半句與確實聽清的部分分開保存。
個人利害：怕自己補一句合理的話，反而決定工人責任。
能提供：能重播合法取得的原錄音。
限制：不能替失真部分編台詞或自動鑑定聲音身分。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工作錄音整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：載體尚可讀且授權未撤回。
不介入：若來源人不同意公開，停止新副本；不因沉默視為同意。

物品：[音樂播放器](items.md#content_music_player)、[無線電](items.md#content_radio)
遭遇：[只剩半句的工作錄音](encounters-npc.md#npc_047)

- [唱片修整委託人](npc-gray_valley.md#hook_gray_valley_009)：分歧：唱片委託人重私人聲音，整理人想建立可查公共片段。 合作：先保留原件與公開範圍可共同保存記憶。

利益群體：gv_residents、gv_workshops。前置缺口：electronics、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_gray_valley_018"></a>
## hook_gray_valley_018 · 記憶核心接洽人

公開需要：在研究與轉賣之間找合法保管方式。
個人利害：想先看內容又怕先讀就失去談判籌碼。
能提供：有原件保管鏈與願意接洽的買家名單。
限制：核心不是免費技能升級，讀取也不等於可公開。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『記憶核心接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原件仍存在且物主尚未承諾排他交易。
不介入：若合法成交，其他報價關閉；不多賣同一核心或複製唯一內容作獎勵。

物品：[記憶核心](items.md#content_memory_core)、[防水袋](items.md#content_waterproof_bag)
遭遇：[記憶核心先交誰](encounters-npc.md#npc_048)

- [資料載體估價人](npc-gray_valley.md#hook_gray_valley_036)：分歧：材料買家想按殼體收購，接洽人認為資料可能更有價值。 合作：先不破壞的鑑別能釐清價格基礎。

利益群體：gv_workshops、gv_salvage_buyers。前置缺口：electronics、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-02、WG-04。

<a id="hook_gray_valley_019"></a>
## hook_gray_valley_019 · 未知植入物受推銷者

公開需要：要求推銷者說出型號、來源與尚未證實的風險。
個人利害：很想變得能幹，也怕被看出急切就被抬價。
能提供：可提供推銷原話與實物外觀。
限制：不得先安裝再補同意，不因稀有就宣告有效。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『未知植入物受推銷者』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：推銷仍有效且尚未發生任何安裝。
不介入：若賣方撤貨，邀約結束；若有正式檢驗，依結果更新，不憑空使人受傷。

物品：[未知植入物](items.md#content_unknown_implant)、[軍醫資料晶片](items.md#content_military_medical_chip)
遭遇：[說不出型號的植入推銷](encounters-npc.md#npc_049)

- [醫療資料看守人](npc-gray_valley.md#hook_gray_valley_038)：分歧：醫療資料整理人要求證據，受推銷者擔心錯過唯一機會。 合作：先保留可退出的鑑別窗口。

利益群體：gv_residents、gv_salvage_buyers。前置缺口：equipment、identification、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROADSIDE、LD-P02、WG-04。

<a id="hook_gray_valley_020"></a>
## hook_gray_valley_020 · 受質疑的收料人

公開需要：公開哪些雜質、搬運與處理成本影響本批出價。
個人利害：低價被叫奸商，但不願收了難處理材料再轉嫁工人。
能提供：能分開可驗重量、可用比例與未知品項。
限制：沒有權力規定全城價格，也不能把質疑者當敵人。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『受質疑的收料人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：貨尚未成交且雙方仍願比較條款。
不介入：若別人合法買走就停止報價；市場後續由真實交易與既有模擬推導。

物品：[廢鐵](items.md#content_scrap_iron)、[鋁材](items.md#content_aluminum_stock)
遭遇：[被叫作奸商的收料人](encounters-npc.md#npc_050)

- [材料記帳員](npc-gray_valley.md#hook_gray_valley_003)：分歧：記帳員想按總重量結算，收料人只願為可確認部分報價。 合作：共同分堆可讓不同材料各有明確交易基礎。

利益群體：gv_salvage_buyers。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：LD-P02、WG-02、WG-04。

<a id="hook_gray_valley_021"></a>
## hook_gray_valley_021 · 欠薪協商代表

公開需要：讓討薪者先收起刀，再逐筆核對已做的工作。
個人利害：自己也被欠薪，怕一退讓就被看作站在雇主那邊。
能提供：有真實工項見證與願協商的人。
限制：不能用武器威脅直接改帳或凍結居民資產。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『欠薪協商代表』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：有仍未結清的真實委託且雙方在場。
不介入：若已支付則關閉相應部分；若雇主離開只保留待處理證據，不發明追殺。

物品：[廢鐵砍刀](items.md#content_scrap_machete)、[紙本日記](items.md#content_paper_journal)
遭遇：[砍刀出鞘前的討薪](encounters-npc.md#npc_051)

- [報工見證人](npc-gray_valley.md#hook_gray_valley_028)：分歧：報工人要求精準，代表希望先承認共同債務事實。 合作：把無爭議部分先確認可降低衝突。

利益群體：gv_yard_workers、gv_residents。前置缺口：combat_extension、equipment、hazards、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROAD、LD-P02、WG-04。

<a id="hook_gray_valley_022"></a>
## hook_gray_valley_022 · 共享工具箱協調人

公開需要：拆開兩位師傅的私物與共同購買用品清單。
個人利害：怕分家之後誰都做不了完整工作。
能提供：能安排兩人當面確認箱內現存物。
限制：不能因方便就把私人工具變公有。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『共享工具箱協調人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：工具箱尚未分配且雙方同意談。
不介入：若雙方已自行分妥，停止介入；不拆回既成合法分配。

物品：[工具箱](items.md#content_toolbox)、[鉗子](items.md#content_pliers)
遭遇：[兩位師傅的工具箱](encounters-npc.md#npc_052)

- [工具腰帶出借人](npc-gray_valley.md#hook_gray_valley_014)：分歧：腰帶出借人要求每件都記名，協調人希望保留彈性互借。 合作：建立有限借用時段可兼顧歸屬與合作。

利益群體：gv_workshops。前置缺口：identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、LD-P02、WG-04。

<a id="hook_gray_valley_023"></a>
## hook_gray_valley_023 · 彈簧批次分辨人

公開需要：把尺寸相近但來源不同的舊彈簧留在各自袋內。
個人利害：想靠細工獲得報酬，不願被要求用一袋抵所有型號。
能提供：可提供尺寸與原袋標記的對照。
限制：外觀相似不證明適配武器或安全。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『彈簧批次分辨人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：批次尚未混合且有合法查驗窗口。
不介入：若被別人混袋，只報來源失去的範圍；不虛造每件過往。

物品：[彈簧](items.md#content_spring)、[布袋](items.md#content_cloth_sack)
遭遇：[混在同袋的舊彈簧](encounters-npc.md#npc_053)

- [零件限額採買人](npc-gray_valley.md#hook_gray_valley_037)：分歧：零件採買人急要可用件，分辨人只願保證已測尺寸。 合作：先交明確相符的部分，未知件另列。

利益群體：gv_yard_workers、gv_workshops。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_024"></a>
## hook_gray_valley_024 · 釘槍借用工

公開需要：趕在原主需要前完成已許可的小段工程。
個人利害：怕工具被當武器沒收，也怕自己延誤讓原主無法開工。
能提供：有借條與明確的施工範圍。
限制：持有釘槍不授權攻擊，不能超時占用。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『釘槍借用工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：借期尚有效且剩餘工項仍需要。
不介入：若到期原主要收回，按約交還；未完成工項另行安排。

物品：[工業釘槍](items.md#content_industrial_nailgun)、[工具腰帶](items.md#content_tool_belt)
遭遇：[釘槍是借來的](encounters-npc.md#npc_054)

- [工具腰帶出借人](npc-gray_valley.md#hook_gray_valley_014)：分歧：出借人重準時歸還，借用工想再做一小段。 合作：另約下一窗口比含糊延長更可行。

利益群體：gv_yard_workers、gv_workshops。前置缺口：crafting、equipment、hazards、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_025"></a>
## hook_gray_valley_025 · 拒絕空白保證的技工

公開需要：先做故障分段檢查，再決定是否接修復。
個人利害：怕一句『試試看』被居民當成一定修得好。
能提供：能提供觀察與不確定性的清楚清單。
限制：修理提案不是設備狀態修改，費用需另經同意。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『拒絕空白保證的技工』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：設備仍可合法接近且尚無既成修復安排。
不介入：若其他人已診斷，先讀可驗記錄再接續；不重收同一調查作無效工作。

物品：[扳手](items.md#content_wrench)、[維修手冊](items.md#content_repair_manual)
遭遇：[不願承諾修好的技工](encounters-npc.md#npc_055)

- [宿舍照明接洽人](npc-gray_valley.md#hook_gray_valley_005)：分歧：住戶想在付款前確知結果，技工無法憑未知故障保證。 合作：把診斷報酬與修復報酬分開。

利益群體：gv_workshops、gv_residents。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_026"></a>
## hook_gray_valley_026 · 舊管位置見證人

公開需要：把探測器訊號與居民記得的舊管路分開標記。
個人利害：怕挖錯破壞住家，也怕自己記錯被當阻工。
能提供：能指出可見接頭與當年維修入口。
限制：記憶不是精確地下圖，不能保證可開挖。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『舊管位置見證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：現場仍可查且有住戶同意的路線。
不介入：若已取得正式管線資料，修正記憶版本；未確認處保持封存提案。

物品：[金屬探測器](items.md#content_metal_detector)、[地質調查圖](items.md#content_geological_survey_map)
遭遇：[探測器下方的舊管](encounters-npc.md#npc_042)

- [拆解場帶班工](npc-gray_valley.md#hook_gray_valley_001)：分歧：帶班工要清出作業地，見證人要求先排除仍用管段。 合作：共同做不破土查證可建立下一步依據。

利益群體：gv_residents、gv_yard_workers。前置缺口：electronics、exploration、hazards、item_ownership、jobs、knowledge、npc_relationship。研究：LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_027"></a>
## hook_gray_valley_027 · 面罩標籤核對人

公開需要：區分防塵用途與來源不明濾罐，不把外形當防毒證據。
個人利害：怕自己過去推薦錯款，想補正又怕失去信任。
能提供：能提供包裝殘標與原購買記錄。
限制：不能因佩戴面罩就宣布污染區可進入。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『面罩標籤核對人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：物件與標籤尚在，使用者願核查。
不介入：若檢驗已證實失效，改談合法替換；不免費更新所有居民裝備。

物品：[沙塵面罩](items.md#content_dust_mask)、[防毒面具](items.md#content_gas_mask)
遭遇：[面具上沒有日期](encounters-npc.md#npc_043)

- [電池芯隔離記錄人](npc-gray_valley.md#hook_gray_valley_010)：分歧：隔離人要求保守處理，核對人希望找回可用的部分。 合作：保留確知用途、撤回未證實說法。

利益群體：gv_yard_workers、gv_residents。前置缺口：equipment、hazards、item_ownership、jobs、knowledge、npc_relationship。研究：LD-P02、WG-04、WG-05。

<a id="hook_gray_valley_028"></a>
## hook_gray_valley_028 · 報工見證人

公開需要：核對確實完成的工項與已承諾付款。
個人利害：不想自己的名字被用來證明沒看見的整天工作。
能提供：能見證有限時段與明確成果。
限制：不能替缺席者造出工時、獎勵或債務。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『報工見證人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：相關委託尚未結清且原記錄可查。
不介入：若雙方已合法結算，證詞轉作留存；不重複支付。

物品：[紙本日記](items.md#content_paper_journal)、[舊世界手錶](items.md#content_old_world_watch)
遭遇：[舊手錶的慢十分鐘](encounters-npc.md#npc_039)、[砍刀出鞘前的討薪](encounters-npc.md#npc_051)

- [欠薪協商代表](npc-gray_valley.md#hook_gray_valley_021)：分歧：協商代表想快速定總額，見證人只確認親眼所見部分。 合作：把確認與爭議分開可先處理無爭議款。

利益群體：gv_yard_workers、gv_residents。前置缺口：combat_extension、equipment、hazards、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-ROAD、LD-P02、WG-04。

<a id="hook_gray_valley_029"></a>
## hook_gray_valley_029 · 學徒工具整理人

公開需要：按實際借入用途整理工具，不擅自翻新私人物件。
個人利害：想被當可靠幫手，容易答應超出能力的修補。
能提供：熟悉自己確實收過的工具位置。
限制：沒有師傅授權不能修高風險設備或傳授技能rank。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『學徒工具整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：本人自願承接且工具原主同意整理。
不介入：若師傅改派工作，移交已查清單；未完成項目不假報完成。

物品：[螺絲起子](items.md#content_screwdriver)、[工具腰帶](items.md#content_tool_belt)
遭遇：[生鏽扳手的新柄](encounters-npc.md#npc_033)、[工具腰帶的空扣](encounters-npc.md#npc_041)

- [工具換柄師傅](npc-gray_valley.md#hook_gray_valley_006)：分歧：換柄師傅要留下缺陷，學徒想把所有工具磨亮。 合作：由簡單清點開始可留下可信工作證據。

利益群體：gv_workshops、gv_yard_workers。前置缺口：crafting、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_030"></a>
## hook_gray_valley_030 · 維修頁抄寫人

公開需要：抄錄有權共享的索引並標明缺頁。
個人利害：想換取閱讀機會，但不希望錯版流傳都算自己責任。
能提供：能提供原頁、版本與已核查的抄本。
限制：抄書不直接增加技能，也不能公開私密資料。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『維修頁抄寫人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原持有人同意抄錄且內容尚可讀。
不介入：若授權撤回即停新抄本；已同意留存部分照條款處理。

物品：[維修手冊](items.md#content_repair_manual)、[精密工程手冊](items.md#content_precision_engineering_manual)
遭遇：[誰把維修頁剪走](encounters-npc.md#npc_040)

- [缺頁手冊追索人](npc-gray_valley.md#hook_gray_valley_013)：分歧：追索人想找原件，抄寫人想先保存已知內容。 合作：分清引用版次可讓兩項工作並行。

利益群體：gv_workshops、gv_residents。前置缺口：identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-WOOL、LD-P02、WG-04。

<a id="hook_gray_valley_031"></a>
## hook_gray_valley_031 · 焊線歸還聯絡人

公開需要：找到尚在借期內的最後一組線，先協商下一班時段。
個人利害：不願為趕工犧牲自己的工具，也怕被說不肯互助。
能提供：保存線材原主與當次使用位置。
限制：不能強拿仍在合法借期內的物件。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『焊線歸還聯絡人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：線仍存在且兩份工作時段尚可協商。
不介入：若前工完成，正常交還；若需延期先詢原主，不靠玩家缺席延長借期。

物品：[焊接工具](items.md#content_welding_tools)、[銅線](items.md#content_copper_wire)
遭遇：[焊工借出的最後一組線](encounters-npc.md#npc_044)

- [共享工具箱協調人](npc-gray_valley.md#hook_gray_valley_022)：分歧：共享箱協調人希望整套留場，聯絡人需按約歸還。 合作：排出可查的先後次序可保住兩方工作。

利益群體：gv_workshops。前置缺口：crafting、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_032"></a>
## hook_gray_valley_032 · 工具故事展示人

公開需要：用物主同意的圖樣講工具來歷，不把傳說當真實通行證。
個人利害：展覽能吸引交換消息的人，也可能讓原主被騷擾。
能提供：持有自願提供的口述與外觀圖。
限制：不能因展出就複製唯一物、改其所有權或開工廠。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工具故事展示人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原資料可合法展示且物主仍願参與。
不介入：若撤回展示授權，收起相應部分；不刪改已發生的真正歷史。

物品：[六十三號](items.md#content_number_sixty_three)、[相機](items.md#content_camera)
遭遇：[六十三號的磨平提議](encounters-npc.md#npc_038)、[拍照者與班表上的人](encounters-npc.md#npc_046)

- [特號扳手守藏人](npc-gray_valley.md#hook_gray_valley_011)：分歧：守藏人怕公開過多，展示人希望留足辨識資訊。 合作：匿名展示一般工法，特定印記另徵同意。

利益群體：gv_residents、gv_workshops。前置缺口：crafting、exploration、identification、item_ownership、jobs、knowledge、npc_relationship、repair、reputation。研究：FICTION-CANTICLE、FICTION-WOOL、LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_033"></a>
## hook_gray_valley_033 · 夜班燈具保管人

公開需要：分清手電筒、電池與借期，讓不同班都有已承諾的照明。
個人利害：怕歸還時剩空殼卻找不到誰用了電池。
能提供：可出示現物與分開的借用、耗用約定。
限制：不把電池無限刷新，也不把照明視為無條件安全。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『夜班燈具保管人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：現有燈具未售出且仍有有效借用承諾。
不介入：若設備已壞，停止對外保證；新的缺口需實際來源才能補。

物品：[手電筒](items.md#content_flashlight)、[電池](items.md#content_battery)
遭遇：[比工錢更急的燈泡線](encounters-npc.md#npc_032)、[借來的電池何時歸還](encounters-npc.md#npc_070)

- [宿舍照明接洽人](npc-gray_valley.md#hook_gray_valley_005)：分歧：宿舍也想借燈，保管人已答應夜班檢查。 合作：排出不重疊窗口可同時滿足有限需求。

利益群體：gv_yard_workers、gv_workshops。前置缺口：electronics、item_ownership、jobs、knowledge、lighting、navigation、npc_relationship、regional_trade、repair。研究：LD-P02、WG-02、WG-03、WG-04、WG-05。

<a id="hook_gray_valley_034"></a>
## hook_gray_valley_034 · 電路板收納人

公開需要：把受潮與外觀完整的板件分袋，保留原設備來源。
個人利害：怕只按重量收料讓可辨識的舊技術都消失。
能提供：有可觀察焊點與來源標記。
限制：外觀完整不等於可通電使用或能修復一切。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『電路板收納人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：板件仍在且場地管理者允許分存。
不介入：若已有合法買家接收，移交來源清單；不再把同批板件作拆解獎勵。

物品：[電路板](items.md#content_circuit_board)、[防水袋](items.md#content_waterproof_bag)
遭遇：[蓄電池芯不是普通貨](encounters-npc.md#npc_037)、[記憶核心先交誰](encounters-npc.md#npc_048)

- [記憶核心接洽人](npc-gray_valley.md#hook_gray_valley_018)：分歧：核心接洽人想優先保存資料，收納人也需要有限乾燥空間。 合作：共同排序不可再生來源資訊。

利益群體：gv_yard_workers、gv_workshops。前置缺口：cargo、electronics、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04、WG-05。

<a id="hook_gray_valley_035"></a>
## hook_gray_valley_035 · 空心石稱量記錄人

公開需要：在相同容器與同一秤上比較異常重量，保留誤差。
個人利害：想向買家證明自己沒換樣本，卻不懂現象原因。
能提供：能維持有限樣本保管鏈與原始測值。
限制：不能宣稱增加背包容量或永遠不受重量限制。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『空心石稱量記錄人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原樣本仍可合法觀察且測試條件未改。
不介入：若樣本交走，當地測試結束；只保留真實資料，不另造石頭。

物品：[空心石](items.md#content_hollow_stone)、[舊旅行包](items.md#content_travel_backpack)
遭遇：[少了一半的石料帳](encounters-anomaly.md#anomaly_009)、[想切開的學徒](encounters-anomaly.md#anomaly_010)

- [受質疑的收料人](npc-gray_valley.md#hook_gray_valley_020)：分歧：收料人只信可驗重量，記錄人想把異常觀察納入報價。 合作：做共同可重現的有限比較。

利益群體：gv_salvage_buyers、gv_workshops。前置缺口：cargo、crafting、exploration、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_gray_valley_036"></a>
## hook_gray_valley_036 · 資料載體估價人

公開需要：把殼體材料價與可讀資料興趣分開報價。
個人利害：怕花錢買到空殼，也怕不懂而讓重要記錄被拆掉。
能提供：有真實願意鑑別的買家與有限檢查條款。
限制：不能先讀後無償複製，未知內容不保證技能收益。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『資料載體估價人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：賣方仍願接洽且尚未有排他承諾。
不介入：若賣方接受他人報價，關閉本詢價；不操纵既有市場價格公式。

物品：[記憶核心](items.md#content_memory_core)、[黑盒記憶體](items.md#content_black_box_memory)
遭遇：[記憶核心先交誰](encounters-npc.md#npc_048)

- [記憶核心接洽人](npc-gray_valley.md#hook_gray_valley_018)：分歧：接洽人想先保密，估價人需要最低限度證據。 合作：約定只確認載體可讀性而不公開內容。

利益群體：gv_salvage_buyers、gv_workshops。前置缺口：electronics、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、LD-P02、WG-02、WG-04。

<a id="hook_gray_valley_037"></a>
## hook_gray_valley_037 · 零件限額採買人

公開需要：只買當前工程確實需要的規格，拒收拿不出用途的整袋料。
個人利害：怕被叫挑剔，卻沒有庫位替別人存所有雜件。
能提供：能列出本單用途與有限可收數量。
限制：採購意向不是無限需求或固定售價。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『零件限額採買人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：真實委託尚需零件且採購未滿。
不介入：若別處已補足，關閉剩餘需求；不得繼續無限收購等玩家刷錢。

物品：[齒輪](items.md#content_gear)、[軸承](items.md#content_bearing)、[彈簧](items.md#content_spring)
遭遇：[混在同袋的舊彈簧](encounters-npc.md#npc_053)、[被叫作奸商的收料人](encounters-npc.md#npc_050)

- [彈簧批次分辨人](npc-gray_valley.md#hook_gray_valley_023)：分歧：分辨人希望每件都有價，採買人只接受核對規格部分。 合作：把剩餘料留給別的合法需求者。

利益群體：gv_workshops、gv_salvage_buyers。前置缺口：item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_038"></a>
## hook_gray_valley_038 · 醫療資料看守人

公開需要：為技術晶片保留型號與閱讀限制，阻止當場試裝未知物。
個人利害：想讓醫療知識有用，又怕自己被當成會治病的人。
能提供：可提供經允許查閱的索引與來源資料。
限制：看懂文字不等於行醫資格或植入authority。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『醫療資料看守人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：資料仍可讀且當事人自願查詢。
不介入：若買賣已取消，關閉緊急協助；資料保管仍依原授權。

物品：[軍醫資料晶片](items.md#content_military_medical_chip)、[未知植入物](items.md#content_unknown_implant)
遭遇：[說不出型號的植入推銷](encounters-npc.md#npc_049)

- [未知植入物受推銷者](npc-gray_valley.md#hook_gray_valley_019)：分歧：受推銷者急想變強，看守人要求保留可拒絕步驟。 合作：先找合法鑑別者而非讓人當試驗對象。

利益群體：gv_residents、gv_workshops。前置缺口：equipment、identification、injury、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-ROADSIDE、LD-P02、WG-04。

<a id="hook_gray_valley_039"></a>
## hook_gray_valley_039 · 逆磁片搬運協調人

公開需要：先讓金屬工具避開可見排斥區，再決定有限搬運方式。
個人利害：怕耽誤清場，也不願把未知物交給沒聽到風險的人。
能提供：有原位置記錄與有限隔離範圍。
限制：不保證永久作用或抗彈效果。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『逆磁片搬運協調人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原樣本仍在且現場管理者同意處理。
不介入：若合法接收者先取走，清場提案結束；不在原地刷新新碎片。

物品：[逆磁片](items.md#content_reverse_magnetic_shard)、[繩索](items.md#content_rope)
遭遇：[滑離工作臺的墊片](encounters-anomaly.md#anomaly_021)、[羅盤不肯安定](encounters-anomaly.md#anomaly_022)

- [拆解場帶班工](npc-gray_valley.md#hook_gray_valley_001)：分歧：帶班工想恢復通路，協調人需要樣本歸屬與接收同意。 合作：先標明可繞路範圍，移動另行授權。

利益群體：gv_yard_workers、gv_workshops。前置缺口：cargo、exploration、hazards、identification、item_ownership、jobs、knowledge、navigation、npc_relationship。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_gray_valley_040"></a>
## hook_gray_valley_040 · 鳴石電器對照人

公開需要：用可退出的距離測試記錄鳴聲與電器位置。
個人利害：想知道夜裡吵聲來源，怕設備被拿去試到壞掉。
能提供：可提供本人設備的有限測試時段。
限制：聲響相關不證明供電、導航或敵人預警。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『鳴石電器對照人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本與設備均有物主同意，借期未滿。
不介入：若有任一物主撤回，停止新測試並歸還；已有觀察仍標明條件。

物品：[鳴石](items.md#content_humming_stone)、[無線電](items.md#content_radio)
遭遇：[斷電後的低鳴](encounters-anomaly.md#anomaly_013)、[尋寶器招牌](encounters-anomaly.md#anomaly_014)

- [夜班燈具保管人](npc-gray_valley.md#hook_gray_valley_033)：分歧：燈具保管人不願占用夜班電池，對照人想延長觀察。 合作：先用不影響既定用途的短時段。

利益群體：gv_workshops、gv_residents。前置缺口：cargo、electronics、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_gray_valley_041"></a>
## hook_gray_valley_041 · 靜電骨包材試驗人

公開需要：比較不同外包下可觀察的放電現象，避免直接接觸設備。
個人利害：想找可靠包法，又怕包住後被誤認普通骨頭。
能提供：有原樣本標記與合法保管的測試容器。
限制：不宣稱發電無限或可直接替代電池。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『靜電骨包材試驗人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍在且管理者同意有限觀察。
不介入：若樣本封存不再開放，停試並保留資料；不憑空增加能源庫存。

物品：[靜電骨](items.md#content_static_bone)、[橡膠](items.md#content_rubber)
遭遇：[燃料桌旁的劈啪聲](encounters-anomaly.md#anomaly_017)、[收音機需要的不是火花](encounters-anomaly.md#anomaly_018)

- [電池芯隔離記錄人](npc-gray_valley.md#hook_gray_valley_010)：分歧：隔離記錄人要清楚標示，試驗人想用外包降低干擾。 合作：在外包保留樣本標記與未知欄位。

利益群體：gv_yard_workers、gv_workshops。前置缺口：cargo、electronics、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_gray_valley_042"></a>
## hook_gray_valley_042 · 沉默盒值班聯絡人

公開需要：標記無線電失聯發生的範圍，安排人工傳話的可行窗口。
個人利害：怕被以失聯推定怠工，也不願把無線電都搬走。
能提供：有實際通聯記錄與值班路線。
限制：不能斷定盒子能阻止所有訊號或所有監聽。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『沉默盒值班聯絡人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原盒仍在且實際通信問題尚待處理。
不介入：若盒被合法移走，依新通聯事實結束替代安排；不永久封鎖全城。

物品：[沉默盒](items.md#content_silence_box)、[無線電](items.md#content_radio)
遭遇：[聽不見交班聲的桌子](encounters-anomaly.md#anomaly_037)、[把沉默盒當隱身許可](encounters-anomaly.md#anomaly_040)

- [工作錄音整理人](npc-gray_valley.md#hook_gray_valley_017)：分歧：錄音整理人想確認細節，聯絡人擔心談話內容被擅自記錄。 合作：只交換測試時點與是否收到，不公開私人訊息。

利益群體：gv_yard_workers、gv_residents。前置缺口：cargo、combat_extension、electronics、exploration、hazards、identification、item_ownership、jobs、knowledge、navigation、npc_relationship、reputation。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_gray_valley_043"></a>
## hook_gray_valley_043 · 熱核用途接洽人

公開需要：區分可見發熱與尚未證實的安全加熱用途。
個人利害：想替居民找熱源，怕急用者跳過隔離程序。
能提供：有樣本保管人同意分享的有限觀察。
限制：未知熱源不等於可煮食、治病或免費燃料。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『熱核用途接洽人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：樣本仍可接洽且當次測試條件合法。
不介入：若物主不再開放就關閉提案；居民需求須另找真實來源。

物品：[熱核](items.md#content_heat_core)、[隔熱服](items.md#content_heat_insulation_suit)
遭遇：[沒有開關的保溫箱](encounters-anomaly.md#anomaly_033)、[熱核與燃料桶的位置](encounters-anomaly.md#anomaly_034)

- [宿舍照明接洽人](npc-gray_valley.md#hook_gray_valley_005)：分歧：住戶急要可用設備，接洽人只能提出未定案試驗。 合作：把急需補給與長期鑑別分開安排。

利益群體：gv_workshops、gv_residents。前置缺口：camping、cargo、equipment、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship。研究：FICTION-ROADSIDE、LD-P02、WG-04、WG-06。

<a id="hook_gray_valley_044"></a>
## hook_gray_valley_044 · 工具回收押記人

公開需要：把押物與買斷單分開，避免到期前先拆工具。
個人利害：怕借款人不回來，也怕被認為刻意吞掉家傳工具。
能提供：有真實條款與仍在保管的物件。
限制：押物不自动歸己，逾期處置需未來合法合約authority。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工具回收押記人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：當事人合約仍有效且物件尚未合法處分。
不介入：若債務已結清，歸還押物並關閉；不再把它作買賣庫存。

物品：[工具箱](items.md#content_toolbox)、[舊世界手錶](items.md#content_old_world_watch)
遭遇：[拆解場的整把工具](encounters-npc.md#npc_031)、[舊手錶的慢十分鐘](encounters-npc.md#npc_039)

- [受質疑的收料人](npc-gray_valley.md#hook_gray_valley_020)：分歧：收料人想買可拆件，押記人不能出售未取得處分權的押物。 合作：先列出可出售與不可售清單。

利益群體：gv_salvage_buyers、gv_workshops。前置缺口：disassembly、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_045"></a>
## hook_gray_valley_045 · 居民通路協商人

公開需要：讓拆解場搬料時保留已同意的住家出入口。
個人利害：怕抗議被當阻礙工作，又不想每天多走很遠。
能提供：可提供現場可見界標與居民同意的時段。
限制：不能以口頭提案永久封路或製造新地點。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『居民通路協商人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：通路仍受阻且現場雙方願協商。
不介入：若搬料已完成，撤下臨時安排；不再次堆物給玩家清理。

物品：[繩索](items.md#content_rope)、[車板胸甲](items.md#content_car_panel_cuirass)
遭遇：[車板胸甲的來歷](encounters-npc.md#npc_035)、[探測器下方的舊管](encounters-npc.md#npc_042)

- [舊管位置見證人](npc-gray_valley.md#hook_gray_valley_026)：分歧：舊管見證人要求避免挖動，通路人想先移開表層堆料。 合作：找不碰地下設施的有限暫存位置。

利益群體：gv_residents、gv_yard_workers。前置缺口：electronics、equipment、exploration、hazards、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-04。

<a id="hook_gray_valley_046"></a>
## hook_gray_valley_046 · 工衣識別補記人

公開需要：把人員交班記錄與衣物標記拆開，避免穿錯就被冒認。
個人利害：曾把借衣當代班，想修正但怕被罰沒工錢。
能提供：能說明自己見到的衣物與真正見到的人。
限制：不能用外套生成NPC身分或抹消真實在場狀態。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工衣識別補記人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：該班記錄尚待核對且相關人願說明。
不介入：若正式更正已完成，本次補記結束；不重開指控以等待玩家。

物品：[舊工作服](items.md#content_work_clothes)、[工人皮衣](items.md#content_worker_leather_jacket)
遭遇：[帶班工的衣物標記](encounters-npc.md#npc_004)、[拍照者與班表上的人](encounters-npc.md#npc_046)

- [拆解場帶班工](npc-gray_valley.md#hook_gray_valley_001)：分歧：帶班工想快點補全名冊，補記人拒絕填沒看見的名字。 合作：保留未知欄位後再找其他證據。

利益群體：gv_residents、gv_yard_workers。前置缺口：identification、item_ownership、jobs、knowledge、npc_relationship、reputation。研究：FICTION-CANTICLE、FICTION-WOOL、LD-P02、WG-04。

<a id="hook_gray_valley_047"></a>
## hook_gray_valley_047 · 拆解前留影人

公開需要：在合法拆解前替物主保留一張外觀與刻記照片。
個人利害：想留下舊物故事，又不想拖住已付工錢的工程。
能提供：有相機與物主同意的短暫拍攝範圍。
限制：照片不恢復被拆物，不自動揭示所有歷史。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『拆解前留影人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：物件尚未拆解且物主授權拍攝。
不介入：若已依法拆完，只記未能保存的部分；不還原原件。

物品：[相機](items.md#content_camera)、[軍人識別牌](items.md#content_military_dog_tags)
遭遇：[拍照者與班表上的人](encounters-npc.md#npc_046)、[拆解場的整把工具](encounters-npc.md#npc_031)

- [整具回收分揀人](npc-gray_valley.md#hook_gray_valley_004)：分歧：分揀人怕每件都等拍照，留影人只挑不可重建的記號。 合作：事先同意有限清單可縮短等待。

利益群體：gv_yard_workers、gv_residents。前置缺口：disassembly、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、reputation。研究：FICTION-CANTICLE、FICTION-WOOL、LD-P02、WG-01、WG-02、WG-04。

<a id="hook_gray_valley_048"></a>
## hook_gray_valley_048 · 工坊接單轉介人

公開需要：替超出本坊能力的委託找願承接者，先交代未知故障。
個人利害：轉介可維持信譽，也可能被認為把麻煩推給別人。
能提供：知道自願公开的可接工項與目前排期。
限制：不能擅自代別人承諾、插隊或保證一定修好。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『工坊接單轉介人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：原委託人同意轉介且接洽者仍有空檔。
不介入：若另有人已合法接單，停止重複媒合；不製造第二份獎勵。

物品：[維修手冊](items.md#content_repair_manual)、[無線電](items.md#content_radio)
遭遇：[不願承諾修好的技工](encounters-npc.md#npc_055)、[比工錢更急的燈泡線](encounters-npc.md#npc_032)

- [拒絕空白保證的技工](npc-gray_valley.md#hook_gray_valley_025)：分歧：謹慎技工要求檢查再接，轉介人怕客人等不及。 合作：把診斷工作單獨介紹給合適者。

利益群體：gv_workshops、gv_salvage_buyers。前置缺口：electronics、item_ownership、jobs、knowledge、lighting、npc_relationship、regional_trade、repair。研究：LD-P02、WG-01、WG-02、WG-03、WG-04。

<a id="hook_gray_valley_049"></a>
## hook_gray_valley_049 · 舊資料公開異議人

公開需要：要求公開前辨認資料裡的私人地址與家屬資訊。
個人利害：希望保留技術知識，卻不願家人的住處成交易籌碼。
能提供：能指出自己有權要求保護的具體片段。
限制：不能因此封鎖所有公共技術，也不代表所有資料當事人。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『舊資料公開異議人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：資料仍未公開且相關權利人可確認。
不介入：若已合法公開部分，不假裝可撤回世界記憶；後續複製依有效條款處理。

物品：[資料磁碟](items.md#content_data_disk)、[身分證件](items.md#content_identity_document)
遭遇：[只剩半句的工作錄音](encounters-npc.md#npc_047)、[記憶核心先交誰](encounters-npc.md#npc_048)

- [記憶核心接洽人](npc-gray_valley.md#hook_gray_valley_018)：分歧：核心接洽人想增加買家，異議人要求分層授權。 合作：先分享非私人技術目錄可維持談判。

利益群體：gv_residents、gv_workshops。前置缺口：electronics、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、reputation。研究：FICTION-CANTICLE、LD-P02、WG-02、WG-04。

<a id="hook_gray_valley_050"></a>
## hook_gray_valley_050 · 跨班交接整理人

公開需要：把工具借用、材料買賣與居民寄物分開交接。
個人利害：怕自己成為所有缺失的替罪者，不願簽沒見到的物件。
能提供：可協調各保管者核對現存清單。
限制：無權改人口、價格或把所有私人用品收歸場方。
人口綁定：未來從灰谷當前在場且存活的人口中，確認有意願承擔『跨班交接整理人』職責者後綁定；若需具名化只能標記既有人口。這是角色候選，可由同一既有人物兼任相容職責，不新增總人口或自動生成家屬。接受與提交時重驗在場、存活、職責與同意。
出現條件：真實交班尚未完成且參與者自願核對。
不介入：若班別已交完，只補有證據的勘誤；不倒帶已完成交易或叫回離開者。

物品：[工具箱](items.md#content_toolbox)、[布袋](items.md#content_cloth_sack)、[紙本日記](items.md#content_paper_journal)
遭遇：[拆解場的整把工具](encounters-npc.md#npc_031)、[被叫作奸商的收料人](encounters-npc.md#npc_050)、[兩位師傅的工具箱](encounters-npc.md#npc_052)

- [材料記帳員](npc-gray_valley.md#hook_gray_valley_003)：分歧：記帳員追求結清當批，整理人要保留跨班未決責任。 合作：共同列已結與待續事項可讓新班正常工作。

利益群體：gv_yard_workers、gv_workshops、gv_salvage_buyers、gv_residents。前置缺口：disassembly、identification、item_ownership、jobs、knowledge、npc_relationship、regional_trade、repair、reputation。研究：FICTION-CANTICLE、LD-P02、WG-01、WG-02、WG-04。
