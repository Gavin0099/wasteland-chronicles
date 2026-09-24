# 185 件物品內容稿

DESIGN_ONLY；數字皆為提案。圖庫分類與 gameplay 類別分開；只有十二個 runtime ID 已存在。

<a id="content_adrenaline"></a>
## 腎上腺素 · content_adrenaline

CONSUMABLE / emergency_injector｜80 g｜參考估值 90 Caps｜rare。
估值理由：90 Caps 是可信緊急庫存的設計估值，非效果強弱排名。
[既有圖片](../../../ui/assets/items/library/supplies/adrenaline.png)｜runtime ID：尚未註冊

保護套裡是一支仍附標籤的緊急注射用品。

**初見：** 需辨明品項與存放狀況，不作自用加速道具。

**調查後可確認：** 交由醫療角色判斷用途；本設計不承諾復活、提速或忽略傷勢。

保存與轉運紀錄決定收貨方是否接受，長途塞在熱貨車上不算合格交付。

候選動作：deliver_emergency_stock、consult_medic。來源：old_world_emergency_service。

- 新希望：供應 none／需求 medium。只為診所保留緊急庫存。
- 灰谷：供應 low／需求 medium。舊設施偶有封存貨，必須核驗。
- 乾井：供應 none／需求 medium。需求窄但補貨困難，不能當普通提神貨販售。

- 急診補貨單要求緊急用品和保存紀錄一同到達。 → 接下封存運送，按原包裝交接。 代價／限制：路上不能擅自拆用；保存條件失證可能被拒收。
- 陌生人要求拿它交換一件高價武器。 → 選擇保留給已確認的診所委託，或取消委託後交易。 代價／限制：交易要承擔失去供應承諾的後果，不附帶服用增益。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、injury、item_ownership、jobs。研究：WG-04、FICTION-ROAD。

<a id="content_aluminum_stock"></a>
## 鋁材 · content_aluminum_stock

MISC / aluminum_stock｜800 g｜參考估值 26 Caps｜uncommon。
估值理由：26 Caps 反映可用板面與較少攜行負擔，非強度排序。
[既有圖片](../../../ui/assets/items/library/supplies/aluminum_stock.png)｜runtime ID：尚未註冊

輕色金屬板的邊角被折起，表面留有舊鉚孔。

**初見：** 一份八百克板料；材質和厚度需辨識。

**調查後可確認：** 適合需要輕量板件的提案，不保證可代替受力鋼件。

運輸維修者在乎尺寸是否足夠，碎片和整片不能同價交付。

候選動作：fabricate_bracket、deliver_material。來源：gray_valley、old_world_transport。

- 新希望：供應 low／需求 low。不是所有農具都需要輕金屬。
- 灰谷：供應 medium／需求 medium。運輸廢料可回收，完整片面較少。
- 乾井：供應 low／需求 high。長途車體和可攜箱具想降低重量。

- 商隊的空箱很重，想換一塊非承力蓋板。 → 提供足夠面積的鋁片給工匠製作。 代價／限制：需確認用途，不可代替車架受力件。
- 灰谷回收者把鋁片混進普通廢鐵。 → 辨明材質後分開交付給對應買家。 代價／限制：鑑別和分選耗時，沒有證據不能自行升價。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、item_ownership、regional_trade、repair。研究：WG-01、WG-02。

<a id="content_ammo_bandolier"></a>
## 彈藥帶 · content_ammo_bandolier

CONTAINER / cartridge_carrier｜420 g｜參考估值 75 Caps｜uncommon。
估值理由：75 Caps 提案取決於皮環和扣件完整。
[既有圖片](../../../ui/assets/items/library/clothing/ammo_bandolier.png)｜runtime ID：尚未註冊

皮環大小不一，只有幾環仍有彈殼留下的亮痕。

**初見：** 空彈藥帶只是一件攜具，適用規格需要先確認。

**調查後可確認：** 420 g 不含任何彈藥；現有 category illustration 彈藥也不是可裝填實物。

未來補給規格確立後才能定義攜帶與取用行為，不能現在增加彈量。

候選動作：inspect_carrier_fit、transport_empty_bandolier。來源：caravan_guards、military_surplus。

- 新希望：供應 low／需求 medium。獵戶需匹配規格，不能按外形買。
- 灰谷：供應 medium／需求 medium。皮革匠可修，但完整彈藥供應另計。
- 乾井：供應 medium／需求 high。護運人員整理相容補給有需求。

- 買家發現皮環與手上補給不合。 → 核對規格後拒絕不適用交易。 代價／限制：需具體彈藥設計才能驗證，不能憑 category tag 通用。
- 一箱空彈藥帶被列成已裝填補給。 → 修正貨單並交付實際空攜具。 代價／限制：可能失去原約定貨款，不能生成缺失彈藥。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：皮革

前置缺口：equipment、combat_extension、cargo、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02。

<a id="content_ammunition"></a>
## 彈藥 · content_ammunition

MISC / ammunition_family｜None g｜參考估值 None Caps｜category。
估值理由：分類圖沒有物理單位與統一底價，不參與掉落或交易數量。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/supplies/ammunition.png)｜runtime ID：尚未註冊

此圖展示彈藥家族，供目錄與商店分類使用。

**初見：** 它不是一盒可持有、可射擊或可販售的統一彈藥。

**調查後可確認：** 日後必須先區分武器相容品項與包裝，才可能定義重量和價格。

同一張圖可以引導閱讀相關設計，不能把各口徑混成無限通用供應。

候選動作：。來源：editorial_catalogue。

- 新希望：供應 none／需求 none。分類圖不設供需；須先定義相容的具體彈藥。
- 灰谷：供應 none／需求 none。工業地區也不使分類圖變成可製造的一件貨。
- 乾井：供應 none／需求 none。武器使用者需求留待具體彈種設計。

- 武器商想把所有彈藥需求寫成同一欄。 → 在設計清單中改列相容品項與包裝需求。 代價／限制：這是內容編輯情境，不得作實物需求或獎勵。
- 商隊補給摘要缺少具體彈種。 → 將分類圖保留作索引，要求逐項補齊交易對象。 代價／限制：未具體化前不能設定重量、數量或價格。

維修：分類摘要沒有可修理或拆解的實體。 候選投入：無
拆解：分類摘要沒有可修理或拆解的實體。 候選產物：無

前置缺口：combat_extension、item_ownership、regional_trade。研究：WG-05、WG-02。

<a id="content_anti_radiation_medicine"></a>
## 抗輻射藥 · content_anti_radiation_medicine

CONSUMABLE / radiation_medicine｜60 g｜參考估值 100 Caps｜rare。
估值理由：100 Caps 反映來源受限與檢驗成本，價值不是通行禁區的保證。
[既有圖片](../../../ui/assets/items/library/supplies/anti_radiation_medicine.png)｜runtime ID：尚未註冊

密封盒有舊設施的危害應變標記。

**初見：** 標記只說明原用途，不能證明現在仍可用。

**調查後可確認：** 由專業者確認後才可能納入危害應變；不能替代防護或清除所有污染。

附近遺跡的傳聞會推高求購意願，但需求傳聞仍要和實際危害分開。

候選動作：consult_specialist、deliver。來源：old_world_hospital、restricted_facility。

- 新希望：供應 none／需求 low。沒有已確認危害時不囤大量專門品。
- 灰谷：供應 low／需求 medium。調查舊設施者求購，仍需專業檢驗。
- 乾井：供應 none／需求 medium。遠征商隊可能提出專門委託。

- 遠征者以為帶一盒藥就能進入危險區。 → 將藥品資料交給專業者，重新核對防護與撤退方案。 代價／限制：消耗諮詢時間，沒有防護時不能因此取得通行條件。
- 舊應變站的藥箱標籤已褪色。 → 帶回一盒作核驗，保留發現位置。 代價／限制：核驗可能判定不可用，不承諾恢復成有效藥品。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：hazards、identification、injury、item_ownership。研究：WG-06、WG-02。

<a id="content_antibiotics"></a>
## 抗生素 · content_antibiotics

CONSUMABLE / labelled_antibiotic｜50 g｜參考估值 60 Caps｜rare。
估值理由：60 Caps 來自難以本地補產與可靠來源的稀缺性。
[既有圖片](../../../ui/assets/items/library/supplies/antibiotics.png)｜runtime ID：尚未註冊

封存藥盒上有診所驗收的批次紙條。

**初見：** 一盒待核驗藥品，不是所有疾病的解方。

**調查後可確認：** 由醫療角色確認適用問題和有效狀況，交付不等於病人必然痊癒。

新希望與灰谷都有需要者，不能僅依誰出價高就假稱醫療需求已解決。

候選動作：deliver_to_medic、verify_stock。來源：old_world_clinic、caravan。

- 新希望：供應 low／需求 high。居民診所需要可信批次。
- 灰谷：供應 low／需求 high。工傷照護與人口密集增加備貨需求。
- 乾井：供應 low／需求 high。遠離可靠醫療來源，供貨很少。

- 兩個診所同時託商隊送同一盒藥。 → 要求先確認需求及分配權，再決定交付哪處。 代價／限制：交出後不能重複交另一方；不預設救治結果。
- 舊藥盒批號與交貨單不一致。 → 暫停交貨，追查正確批次。 代價／限制：會延誤委託，不能用高售價掩蓋來源不明。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、injury、item_ownership、jobs、regional_trade。研究：WG-02、FICTION-ROAD。

<a id="content_antidote"></a>
## 解毒劑 · content_antidote

CONSUMABLE / specific_antidote｜90 g｜參考估值 75 Caps｜rare。
估值理由：75 Caps 由可信來源和狹窄用途估值，不能按所有中毒共用定價。
[既有圖片](../../../ui/assets/items/library/supplies/antidote.png)｜runtime ID：尚未註冊

小藥瓶標示著一種特定應變用途。

**初見：** 一瓶針對性用品，沒有通用解毒含義。

**調查後可確認：** 必須先辨識問題是否相符，錯配時即使有藥也不提供有效方案。

研究者要的是完整標籤和相關樣本，旅人則容易誤以為它能治所有毒。

候選動作：identify_match、deliver_to_medic。來源：old_world_clinic、field_research。

- 新希望：供應 none／需求 medium。採集區問題需先辨識，診所不收未知配方。
- 灰谷：供應 low／需求 medium。工業環境需要特定應變品，不接受通用宣稱。
- 乾井：供應 none／需求 medium。荒野隊伍希望備用，但要能對應已知風險。

- 診所請人找回與一份樣本相符的應變藥。 → 攜帶有完整標示的解毒劑供核對。 代價／限制：不相符時不能消耗來換任意治療效果。
- 商人把幾種瓶子統稱萬用解毒藥。 → 要求按標示分清品項再談交易。 代價／限制：需辨識者協助；無證據的瓶子仍不能定用途。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：hazards、identification、injury、item_ownership。研究：WG-01、WG-04。

<a id="content_assault_rifle"></a>
## 軍用突擊步槍 · content_assault_rifle

WEAPON / military_rifle｜3650 g｜參考估值 650 Caps｜rare。
估值理由：650 Caps 是完整主要機件的未平衡估值。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/assault_rifle.png)｜runtime ID：尚未註冊

舊軍方驗收章已模糊，箱內空位暗示配件並不完整。

**初見：** 使用與補給門檻高，遺跡出土不代表仍保持規格。

**調查後可確認：** 軍用長槍，需專用檢驗及相容彈藥體系。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

軍事出身提供調查與後勤故事，不自動決定最高傷害。

候選動作：seal_for_entry、trace_batch。來源：military_depots、old_world_bases。

- 新希望：供應 none／需求 low。地方農業需求與維護資源皆有限。
- 灰谷：供應 low／需求 medium。軍械研究者或組織化守衛才可能出價。
- 乾井：供應 low／需求 medium。長線護運需要先解決相容補給。

- 聚落要求軍事器材入城前封存。 → 接受登記封存以進行交涉。 代價／限制：暫時放棄裝備使用，不得把持槍直接變成社交通行權。
- 軍事倉庫的批號與一份運輸單相符。 → 保留原物供調查運輸去向。 代價／限制：放棄立即拆售機會，調查不保證更多軍械獎勵。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：精密零件、彈簧、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、鋁材

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_bandage"></a>
## 繃帶 · content_bandage

CONSUMABLE / sterile_dressing｜70 g｜參考估值 8 Caps｜common。
估值理由：8 Caps 讓它成為可負擔的基礎急救耗材，但仍要可靠供應。
[既有圖片](../../../ui/assets/items/library/supplies/bandage.png)｜runtime ID：尚未註冊

紙封裡是一卷未開封敷料，封邊容易辨認。

**初見：** 一卷一次交付的醫療用品；普通布料不自動等同無菌敷料。

**調查後可確認：** 確認封裝後交由具處置能力者使用，實際效果等待傷勢規則。

巡路隊的求援常先缺敷料，捐贈用途要和自己的備用量分開。

候選動作：provide_dressing、deliver。來源：settlement_clinic、caravan。

- 新希望：供應 medium／需求 medium。診所有基礎存量，農務受傷仍會消耗。
- 灰谷：供應 medium／需求 high。工地常備需求較大。
- 乾井：供應 low／需求 high。巡路隊補貨依賴商隊。

- 搬運者的隨行醫護用完封裝敷料。 → 把一卷完整繃帶交給醫護。 代價／限制：實際失去一卷；是否能處置仍看傷勢與醫護能力。
- 診所收到混著普通碎布的援助包。 → 協助按封裝狀態分開可用敷料。 代價／限制：分類耗時，不能把碎布改名就變成醫療品。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：injury、item_ownership、jobs、regional_trade。研究：FICTION-ROAD、WG-04。

<a id="content_battery"></a>
## 電池 · content_battery

CONSUMABLE / replaceable_battery｜100 g｜參考估值 12 Caps｜common。
估值理由：12 Caps 以小型電源估價，電量未知時不能當足額新品交易。
[既有圖片](../../../ui/assets/items/library/supplies/battery.png)｜runtime ID：尚未註冊

外殼印有規格的電池，兩端被紙套隔開。

**初見：** 一顆可更換電池；剩餘電量與接點相容性尚需檢查。

**調查後可確認：** 測試後才知道能支援哪些裝置；不代表任何電子用品都能插上使用。

和電池芯分開：這是可正常裝入相容設備的封裝電池。

候選動作：power_device、test_charge、deliver。來源：gray_valley、caravan。

- 新希望：供應 low／需求 medium。巡水燈具需可靠電源。
- 灰谷：供應 medium／需求 high。電子與照明設備密集，供需同時存在。
- 乾井：供應 low／需求 high。長途通訊裝置很難沿路補充。

- 驛站的通訊機只剩很弱的指示燈。 → 提供規格與剩餘電量已確認的電池試機。 代價／限制：只有相容型號才可用；試機會消耗電量。
- 商人想把混裝舊電池當成新品賣。 → 要求逐批測試後只交易有證據的份數。 代價／限制：測試需要設備和時間，不能由標籤保證滿電。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：electronics、identification、item_ownership、regional_trade。研究：WG-03、WG-05。

<a id="content_battery_cell"></a>
## 電池芯 · content_battery_cell

MISC / bare_battery_cell｜120 g｜參考估值 18 Caps｜uncommon。
估值理由：18 Caps 反映可回收的內部部件，轉成可用電源另有工序成本。
[既有圖片](../../../ui/assets/items/library/supplies/battery_cell.png)｜runtime ID：尚未註冊

沒有完整外殼的電池芯，接點被分開包住。

**初見：** 一顆一百二十克待檢部件，不能直接當封裝電池使用。

**調查後可確認：** 經專業測試與保護封裝後才可能加入匹配電源組。

和電池的用途不同，撿到電池芯不會立即讓手電筒恢復供電。

候選動作：test_cell、rebuild_power_pack。來源：gray_valley、old_world_utility。

- 新希望：供應 none／需求 low。缺少封裝檢測工位，不適合普通商店大量收。
- 灰谷：供應 medium／需求 high。電源維修工坊有專門需求。
- 乾井：供應 low／需求 medium。通訊電源重整時委託採購。

- 灰谷電源工坊收一批沒有外殼的電池芯。 → 以分開保護的方式送交測試。 代價／限制：需避免接點相碰，合格與否由測試決定。
- 旅人想直接把裸芯接進手電筒。 → 改委託工坊檢驗並製作相容封裝。 代價／限制：耗工耗材，不能當場免費升級為完整電池。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：electronics、hazards、identification、item_ownership、repair。研究：WG-01、WG-03。

<a id="content_bearing"></a>
## 軸承 · content_bearing

MISC / machine_bearing｜180 g｜參考估值 22 Caps｜uncommon。
估值理由：22 Caps 反映運轉精度需求，失效件沒有同樣功能價值。
[既有圖片](../../../ui/assets/items/library/supplies/bearing.png)｜runtime ID：尚未註冊

包油紙裡的軸承轉起來有輕微摩擦聲。

**初見：** 一個一百八十克的零件，不能只憑能轉就判良好。

**調查後可確認：** 量測尺寸與檢查狀況後，才可匹配特定車軸或設備。

長途車隊願找可靠備件，來路不明的舊件只適合先測。

候選動作：match_shaft、replace_component。來源：gray_valley、old_world_transport。

- 新希望：供應 low／需求 medium。農車與泵體要備合尺寸件。
- 灰谷：供應 medium／需求 high。加工和拆解都會用到可靠軸承。
- 乾井：供應 low／需求 high。長途車隊難在途中補到匹配件。

- 運貨車輪發出規律摩擦聲。 → 提供匹配軸承給修理者查驗，安排替換。 代價／限制：先判斷問題來源；有備件不等於所有摩擦都因此消失。
- 商人把生鏽件擦亮混入新貨。 → 分開測試與記錄狀態後議價。 代價／限制：簡單測試不能保證長期壽命，未知狀態需明示。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：磨損軸承分解後只保留可回收金屬，不獲得一批新軸承。 候選產物：廢鐵

前置缺口：disassembly、identification、item_ownership、regional_trade、repair。研究：WG-01、WG-05。

<a id="content_binoculars"></a>
## 望遠鏡 · content_binoculars

TOOL / field_binoculars｜650 g｜參考估值 65 Caps｜uncommon。
估值理由：65 Caps 反映鏡片完整度和節省接近風險的用途。
[既有圖片](../../../ui/assets/items/library/supplies/binoculars.png)｜runtime ID：尚未註冊

雙筒鏡的一側罩蓋用細繩繫住，鏡面有輕微刮痕。

**初見：** 能看遠不代表能看穿遮蔽物或辨認每個人的意圖。

**調查後可確認：** 良好視線下可讀標記與觀察路況，得到的是有限可見資訊。

巡路者喜歡它，商隊則重視能否辨清遠方約定標誌。

候選動作：observe_route、read_distant_marker、watch_caravan。來源：caravan、old_world_outpost。

- 新希望：供應 low／需求 medium。巡田與觀察遠處水路有用途。
- 灰谷：供應 low／需求 medium。外勤者要看遠方建築與標誌。
- 乾井：供應 medium／需求 high。商隊在開闊地追認停靠與同行訊號。

- 遠處商隊旗幟看似熟悉，但路線不對。 → 隔著安全距離觀察旗號與車隊配置。 代價／限制：只得到可見資訊，仍不能斷言敵意或真實身份。
- 舊橋另一頭的警示牌被水面反光遮住。 → 等光線合適時用望遠鏡辨讀。 代價／限制：花等待時間，視線受阻便沒有可靠讀取結果。

維修：只維護目罩與調焦機構；一般玻璃不能補成合格光學鏡片。 候選投入：橡膠、精密零件
拆解：鏡片降級為一般材料用途，不保留光學精度承諾。 候選產物：玻璃、廢鐵

前置缺口：disassembly、exploration、item_ownership、navigation、repair。研究：WG-04、LD-P01。

<a id="content_black_box_memory"></a>
## 黑盒記憶體 · content_black_box_memory

MISC / incident_recording_module｜360 g｜參考估值 450 Caps｜rare。
估值理由：完整事件序列對相關調查者有價值；記錄可能無關、缺失或不可讀，不能保證藏有高價秘密。
[既有圖片](../../../ui/assets/items/library/relics/black_box_memory.png)｜runtime ID：尚未註冊

外殼焦黑，固定螺絲旁卻有一圈被新近擦亮的金屬。

**初見：** 像事故記錄單元，外部編號可讀；尚不知道何時停止記錄。

**調查後可確認：** 可核對讀得出的時間序列與校驗標記；最後一段缺失就是缺失，不用敘事填入兇手。

候選用途是釐清運輸事故與設備停機原因；公開、交還或封存可能有不同關係後果。

候選動作：recover_readable_log、verify_sequence、submit_evidence。來源：crashed_service_vehicle、control_room、sealed_recorder_case。

- 新希望：供應 none／需求 medium。補給事故牽涉當地供給時才有委託需求。
- 灰谷：供應 low／需求 high。設備事故調查較可能找到讀取能力。
- 乾井：供應 none／需求 high。運輸與燃料事故的當事人可能需要可驗證記錄。

- 運輸車沉沒後，兩個聚落互相指控未按時出發。 → 讀取可驗證時間點，分開記錄已知與空白區。 代價／限制：需讀取工具與現場資料；時鐘可能需校準，不能單靠一串數字定罪。
- 設備管理者要求先銷毀記錄再交出零件。 → 選擇保留完整證據、尋找合法查驗人或放棄交易。 代價／限制：保留會佔運輸重量並放棄當次交易，關係變動需正式後果權威。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、identification、knowledge、jobs、reputation、regional_trade。研究：FICTION-WOOL、FICTION-CANTICLE。

<a id="content_black_water_drop"></a>
## 黑色水滴 · content_black_water_drop

MISC / suspended_dark_liquid｜90 g｜參考估值 None Caps｜rare。
估值理由：未知液滴沒有通用售價；只記錄研究者是否願意在封存條件下接收。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/black_water_drop.png)｜runtime ID：尚未註冊

瓶內的黑點像液體，傾斜時卻比瓶身慢了一拍。

**初見：** 短時間觀察未見體積改變；不知道成分、毒性或是否可與水混合。

**調查後可確認：** 可測得在特定容器裡的流動與揮發行為；結果不證明長期不蒸發，更不代表可飲用。

候選以樣本保管與觀察為主，不能轉成無限水源、燃料或出售循環。

候選動作：seal_sample、observe_volume、compare_container。來源：anomalous_seep、sealed_vial、abandoned_lab。

- 新希望：供應 none／需求 low。供水者會關心污染風險，通常只願協助隔離而非購買。
- 灰谷：供應 none／需求 high。材料研究者可能接收有清楚來源的封存樣本。
- 乾井：供應 none／需求 medium。煉製研究者對流動特性有興趣，但不當可燃料收購。

- 一條排水渠旁發現相同黑點，居民擔心混入井水。 → 保持樣本密封並標記發現位置供正式檢驗。 代價／限制：需容器與運送時間；不能用肉眼檢查宣告水源安全或有毒。
- 買家要求倒入自己的空瓶，卻不提供來源簽收。 → 協商保留原容器或拒絕交接。 代價／限制：轉瓶可能失去比較條件；交付必須記錄物件與保管責任。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、hazards、knowledge、jobs、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_bolt_action_rifle"></a>
## 栓動步槍 · content_bolt_action_rifle

WEAPON / bolt_action_rifle｜3600 g｜參考估值 285 Caps｜uncommon。
估值理由：285 Caps 提案反映廣泛維護知識與較完整槍況。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/bolt_action_rifle.png)｜runtime ID：尚未註冊

槍身比肩帶整潔，金屬柄保留長年操作的亮痕。

**初見：** 長度和重量需行程規劃，熟悉動作比外觀更重要。

**調查後可確認：** 栓動式長槍，部件相容性與槍況需專業鑑定。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

荒野熟手的耐用選擇，不承諾固定射程或精度增益。

候選動作：request_hunter_inspection、transport_owned_cargo。來源：wilderness_hunters、caravan_trade。

- 新希望：供應 medium／需求 high。獵人有用途且能找到保養者。
- 灰谷：供應 low／需求 medium。護衛會找保存良好的長槍。
- 乾井：供應 medium／需求 medium。長途使用者重視可查驗器材與補給。

- 獵戶不願讓陌生人帶不明槍況出發。 → 先接受他的裝備檢查與路線說明。 代價／限制：付出準備時間，仍須獵戶同意同行。
- 商隊把完好長槍列入貨物而非公用武器。 → 選擇押運交付或另談合法收購。 代價／限制：不能在運送期間擅自裝備委託物。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_burn_ointment"></a>
## 燒傷藥膏 · content_burn_ointment

CONSUMABLE / burn_dressing_supply｜120 g｜參考估值 28 Caps｜uncommon。
估值理由：28 Caps 反映工地常備需求，不提供固定回血量。
[既有圖片](../../../ui/assets/items/library/supplies/burn_ointment.png)｜runtime ID：尚未註冊

扁管裝在小紙盒內，旁邊附著工地診所印記。

**初見：** 一份醫療用品，不能代替防火裝備。

**調查後可確認：** 確認可用後交由醫療角色處理燒傷照護；傷勢輕重仍需另外判斷。

灰谷和乾井可能需求高，但原因分別來自熱工與燃料作業。

候選動作：supply_burn_station、deliver。來源：settlement_clinic、old_world_factory。

- 新希望：供應 medium／需求 low。日常診所少量存備。
- 灰谷：供應 medium／需求 high。熱工車間有具體照護需求。
- 乾井：供應 low／需求 high。燃料裝卸區需要可核對的醫療供應。

- 乾井小型事故後，診所請求補充照護耗材。 → 交付一份已核驗藥膏給診所。 代價／限制：實際交出用品，傷勢評估與效果不能由交貨文字代替。
- 灰谷工班打算用備藥為由省下防護準備。 → 保留備藥並指出缺少防護條件，改期處理熱工工作。 代價／限制：延誤會有工作成本；藥膏不使危險作業自動安全。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：injury、item_ownership、jobs、regional_trade。研究：WG-02、FICTION-ROAD。

<a id="content_camera"></a>
## 相機 · content_camera

TOOL / film_camera｜720 g｜參考估值 140 Caps｜rare。
估值理由：完整光學與機械部件可供使用或研究；底片與沖洗供應未建立，不能把機身視為無限拍照器。
[既有圖片](../../../ui/assets/items/library/relics/camera.png)｜runtime ID：尚未註冊

鏡頭蓋內黏著一張手寫清單，最後一項只剩半個字。

**初見：** 能看見取景器與捲片旋鈕；不知道快門或內部底片是否完好。

**調查後可確認：** 這是使用底片的機身，快門可測但成像仍需相容底片與沖洗；取景器只可作有限目視觀察。

候選定位是證據記錄與地方影像交易；需要另定有限耗材，不能憑照片敘事回溯生成世界事實。

候選動作：inspect、document_scene、compare_image。來源：old_homes、survey_case、estate_locker。

- 新希望：供應 low／需求 low。一般農戶少有成像耗材，僅偶有家庭照片保存委託。
- 灰谷：供應 low／需求 medium。調查者或光學工匠可能收購完整機身。
- 乾井：供應 none／需求 medium。運輸紀錄人有保存事故現場的理由，但沒有穩定底片來源。

- 舊水塔裂縫是否擴大引起爭議。 → 在建立相容耗材規則後，用同一視角記錄兩次檢查。 代價／限制：需有限底片、兩次到訪與沖洗；單張影像不能直接判定結構安全。
- 旅館展板上一張相片的取景角度指向被填平的巷口。 → 比較取景器視線與地物，尋找拍攝位置。 代價／限制：必須實地觀察；找出位置只得到調查線索，沒有直接開門或出土獎勵。

維修：只能由適當工具校正或更換機械件，不能用普通玻璃宣稱恢復精密鏡片品質。 候選投入：玻璃、彈簧、精密零件
拆解：僅分離可確認的玻璃與彈簧；拆解會破壞完整機身用途。 候選產物：玻璃、彈簧

前置缺口：item_ownership、exploration、knowledge、jobs、regional_trade、repair、disassembly。研究：FICTION-CANTICLE、LD-P01。

<a id="content_canned_food"></a>
## 罐頭 · content_canned_food

CONSUMABLE / sealed_food｜500 g｜參考估值 18 Caps｜common。
估值理由：18 Caps 包含封裝與較方便運輸的成本，不是永久不壞。
[既有圖片](../../../ui/assets/items/library/supplies/canned_food.png)｜runtime ID：尚未註冊

近期重封的食物罐上寫著裝罐日期。

**初見：** 單位是一罐；鼓脹、漏氣與日期必須分別檢查。

**調查後可確認：** 確認來源與罐況後才能列作食物；打開後不再保有原封裝條件。

和舊世收藏罐頭分開：這類是日常供餐批次，關心內容多於商標。

候選動作：open、eat、donate。來源：new_hope、caravan。

- 新希望：供應 medium／需求 medium。有少量近期封裝，但罐材要回收。
- 灰谷：供應 medium／需求 high。金屬容器易得，內容仍靠食物來源。
- 乾井：供應 low／需求 high。封裝食物適合備在路線補給點。

- 商隊載著兩罐凹痕明顯的食物，想混進捐贈貨。 → 把可驗證罐況的食物分開列單，拒絕拿壞罐補數。 代價／限制：檢查耗時，不會自動修復破壞的封口。
- 守夜人想保留一份食物等明天換班。 → 交付一罐合格食物，讓對方自行決定何時開封。 代價／限制：實際交出整罐；不能同時保留為自己的供餐份數。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、identification、item_ownership、regional_trade。研究：WG-01、FICTION-ROAD。

<a id="content_car_panel_cleaver"></a>
## 車板刀 · content_car_panel_cleaver

WEAPON / heavy_plate_blade｜3400 g｜參考估值 88 Caps｜uncommon。
估值理由：88 Caps 提案保留重加工成本，但 3400 g 會擠占旅行負荷。
[既有圖片](../../../ui/assets/items/library/weapons/car_panel_cleaver.png)｜runtime ID：尚未註冊

刀面還能看見一截舊車漆，寬柄必須雙手握持。

**初見：** 笨重的寬刃適合有作業空間的粗切，狹窄車廂反而難展開。

**調查後可確認：** 大面積回收鋼刀；變形與接合品質決定是否可用。

車板刀是廢車場的地方工藝，不是任何輕刀的必然升級。

候選動作：cut_thick_fiber、display_workmanship。來源：gray_valley、vehicle_yards。

- 新希望：供應 low／需求 medium。粗切織物與防護簾有小眾需求，農民更常買輕刀。
- 灰谷：供應 medium／需求 medium。廢車場可供貨，工匠之間看重加工品質。
- 乾井：供應 low／需求 low。長途攜行笨重，只有固定工地願意收。

- 舊貨場的厚織物綁住落箱。 → 在卸除張力後切開織物。 代價／限制：必須先支撑箱體，不能靠重刀處理受力纜索。
- 買家想辨別灰谷工匠的貨。 → 展示刀背加工痕作為產地線索。 代價／限制：需行家確認；車漆不是所有權或品質證明。

維修：重刀變形只能交工坊評估，握皮可另換。 候選投入：鋼材、皮革
拆解：回收笨重金屬而放棄成品價值。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、knowledge、regional_trade、item_ownership、repair、disassembly。研究：WG-02、WG-05。

<a id="content_car_panel_cuirass"></a>
## 車板胸甲 · content_car_panel_cuirass

APPAREL / rigid_plate_cuirass｜8200 g｜參考估值 250 Caps｜rare。
估值理由：250 Caps 提案包含整形工時，搬運與合身成本另計。
[既有圖片](../../../ui/assets/items/library/clothing/car_panel_cuirass.png)｜runtime ID：尚未註冊

胸前保留一道車板弧度，側帶被多次加長。

**初見：** 硬殼與重量限制活動，較適合固定場所準備。

**調查後可確認：** 以回收板材製成的胸甲，不能用原車型推導防護能力。

它是灰谷的粗重工藝候選，不是給所有人物追求的升級階梯。

候選動作：fit_fixed_guard_armor、inspect_maker_stamp。來源：gray_valley、vehicle_breakers。

- 新希望：供應 none／需求 low。固定糧倉守衛也需權衡重量。
- 灰谷：供應 low／需求 medium。近距離固定守望可能有小眾使用者。
- 乾井：供應 none／需求 low。長線商隊通常不願背負硬重甲。

- 倉庫守衛留下不合身的胸甲。 → 找原工匠評估是否值得改帶。 代價／限制：合身不保證防護，拆改可能失去原有結構。
- 一名商人把車板來源當作品質保證。 → 要求檢驗板材與接合而非相信故事。 代價／限制：付出檢查成本，不直接得到完整製造史。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：皮革、鋼材
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、identification、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-02、WG-04。

<a id="content_caravan_coat"></a>
## 商隊外套 · content_caravan_coat

APPAREL / travel_coat｜1500 g｜參考估值 85 Caps｜uncommon。
估值理由：85 Caps 為有補強的旅行服提案；1500 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/caravan_coat.png)｜runtime ID：caravan_coat

肩頭的舊路線章被拆掉，只留下較淺的一圈布色。

**初見：** 外套適合反覆旅行，並不代替正式的商隊契約。

**調查後可確認：** 補強肩背和大口袋是攜行便利，不等同額外負重容量。

沿線裁縫認得縫法，可以形成維修和尋人故事。

候選動作：wear_travel_coat、inspect_route_patch。來源：caravan_tailors、route_settlements。

- 新希望：供應 medium／需求 medium。糧運工作者會購買，農戶平時較少穿。
- 灰谷：供應 medium／需求 high。中轉維修與二手交易活躍。
- 乾井：供應 medium／需求 high。長線商隊需要可修補的外套。

- 一位裁縫認出外套已拆的路線章位置。 → 詢問該路線曾在哪裡換班。 代價／限制：得到的是待查線索，不直接開啟新路線。
- 夜間等候的人沒有遮蔽物。 → 借外套給對方披著等待。 代價／限制：自己暫時失去穿著，後續防寒效果待 hazards。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料、皮革

前置缺口：equipment、knowledge、npc_relationship、hazards、item_ownership、regional_trade、repair、disassembly。研究：FICTION-ROAD、FICTION-METRO。

<a id="content_caravan_polearm"></a>
## 商隊槍 · content_caravan_polearm

WEAPON / caravan_guard_polearm｜2900 g｜參考估值 110 Caps｜uncommon。
估值理由：110 Caps 提案來自護車式樣及長柄運輸成本。
[既有圖片](../../../ui/assets/items/library/weapons/caravan_polearm.png)｜runtime ID：尚未註冊

帶側鉤的長兵器，桿底磨出長年靠在車邊的凹痕。

**初見：** 此處的商隊槍是長柄兵器，不是槍械。

**調查後可確認：** 側鉤可勾近處固定物；桿和接頭未經起重認證。

圖、名稱與內容必須保持長兵器語義，不能誤導為需要彈藥的武器。

候選動作：hold_cart_gap、retrieve_dropped_bundle。來源：caravan_guards、route_workshops。

- 新希望：供應 low／需求 medium。糧車出發時會借用，平時需求低。
- 灰谷：供應 medium／需求 medium。護車工坊能修頭部，完整長桿不常存放。
- 乾井：供應 medium／需求 high。燃料商隊需要熟悉護車器具的人手。

- 小包落進貨車側面窄縫。 → 從可見位置勾回掛帶。 代價／限制：需卸車或停車，不能藉此打開未經同意的貨包。
- 兩車之間擠入受驚牲畜。 → 用長柄隔開人員，交由熟手處理。 代價／限制：不能保證控制動物，需協作與 hazards authority。

維修：先檢查接頭與鉤部，長桿更換另需材料來源。 候選投入：鋼材、皮革
拆解：拆除武器後回收金屬與綁束。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、cargo、exploration、hazards、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-01、FICTION-METRO。

<a id="content_caravan_rifle"></a>
## 商隊步槍 · content_caravan_rifle

WEAPON / caravan_service_rifle｜3400 g｜參考估值 335 Caps｜uncommon。
估值理由：335 Caps 提案把可追蹤的維修支持算入成品價值。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/caravan_rifle.png)｜runtime ID：尚未註冊

槍托刻著多次點收的方格，最近一格還沒有簽記。

**初見：** 價值在於可追溯交接與沿線支援，而非陌生的高規格。

**調查後可確認：** 護運用長槍，配件清單能幫助確認缺件。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

商隊制式化是服務網的設計方向，不替所有聚落創造庫存。

候選動作：audit_handover、plan_service_route。來源：caravan_guard_network、gray_valley。

- 新希望：供應 low／需求 medium。糧運期間有需求，農閒供應仍依商隊。
- 灰谷：供應 medium／需求 high。路線維修工坊會保有相容備件。
- 乾井：供應 medium／需求 high。長線護運比零星家用更需要統一支援。

- 護衛換班時少了一筆器材簽收。 → 以交接刻記查明最後接手隊伍。 代價／限制：需比對文件，持槍人不能直接被判有罪。
- 遠行前只能選一條有維修支持的路線。 → 依服務據點安排行程。 代價／限制：可能繞遠，不能保證工坊當天有零件。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_caravan_smg"></a>
## 商隊護衛槍 · content_caravan_smg

WEAPON / caravan_smg｜2800 g｜參考估值 520 Caps｜rare。
估值理由：520 Caps 提案包含交接資料完整時的維護價值。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/caravan_smg.png)｜runtime ID：尚未註冊

背帶反覆補過，槍托記著一支商隊的交接記號。

**初見：** 適合已有後勤的護運隊，帶出補給網後價值會降低。

**調查後可確認：** 商隊維修過的短自動槍，替換件清單比外觀新舊更重要。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

定位是有可追溯維護的護車器材，不是全世界通用上位槍。

候選動作：audit_service_record、lend_guard_equipment。來源：caravan_workshops、dry_well_routes。

- 新希望：供應 low／需求 medium。糧車護送可借用，但主要供應在商隊。
- 灰谷：供應 low／需求 high。護車工坊需匹配零件，來源多為退役交接。
- 乾井：供應 medium／需求 high。燃料長線有持續維護與備件需求。

- 退役護衛交出裝備與缺頁保養簿。 → 補查商隊交接紀錄後決定收購。 代價／限制：需聯絡原商隊，不保證其願意認領責任。
- 商隊中途缺一件已核驗護運器材。 → 在契約中借出而非無條件捐贈。 代價／限制：需記錄歸還條件，借出期間不能自己使用。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_chemicals"></a>
## 化學品 · content_chemicals

MISC / labelled_workshop_chemicals｜500 g｜參考估值 35 Caps｜uncommon。
估值理由：35 Caps 為可追溯工坊用料的設計尺度，種類未定前不承諾通用售價。
[既有圖片](../../../ui/assets/items/library/supplies/chemicals.png)｜runtime ID：尚未註冊

有原標籤的工坊用料瓶，瓶口加了二次封套。

**初見：** 這份設計限已標示工坊用途的一瓶，不包攬所有化學品。

**調查後可確認：** 先辨識品項與相容工序，再供給受控作業；不與醫藥品互換。

正式落地前須拆出具體品項與包裝，不以「化學品」授權任意製造。

候選動作：identify_label、supply_workshop。來源：gray_valley、old_world_laboratory。

- 新希望：供應 low／需求 medium。只有已辨明用途的工坊批次才收。
- 灰谷：供應 medium／需求 high。加工業需要，標籤與相容性很重要。
- 乾井：供應 low／需求 medium。設備服務提出指定工序用料需求。

- 工坊有一瓶原標籤用料，卻找不到對應工序。 → 先核對標示與設備記錄，選擇保留或交專人。 代價／限制：未知用途不得當作任意清潔或醫療用品。
- 商隊想把不同來源瓶子混裝成便宜整箱。 → 按標籤與相容性分批交接。 代價／限制：需要知識與隔離搬運，不能為了折價忽略混裝風險。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、hazards、identification、item_ownership、regional_trade。研究：WG-01、WG-05。

<a id="content_cigarettes"></a>
## 香菸 · content_cigarettes

CONSUMABLE / sealed_cigarette_pack｜30 g｜參考估值 18 Caps｜uncommon。
估值理由：18 Caps 來自習慣性需求和密封品完整性，不是通用貨幣。
[既有圖片](../../../ui/assets/items/library/supplies/cigarettes.png)｜runtime ID：尚未註冊

小盒香菸的封膜還在，外觀比內容更容易辨認。

**初見：** 一盒可交易消耗品，不附社交成功或能力增益。

**調查後可確認：** 確認真偽與保存後可交易或送給願意接受的人，對方也可能不收。

有些守夜者收，有些家庭拒收；送禮不能自動買到信任。

候選動作：exchange、offer_gift、deliver。來源：caravan、old_world_store。

- 新希望：供應 low／需求 low。部分買家有需求，居民並非普遍接受。
- 灰谷：供應 medium／需求 medium。值班工人和外來商人有零星市場。
- 乾井：供應 medium／需求 medium。隨商隊流通，不是所有攤販都收。

- 守夜者說只想用手上貨物換一盒菸。 → 提出自願的小額交換，確認對方願付出的東西。 代價／限制：實際交出一盒；不能自動換到情報或好感。
- 一戶人家拒收商隊送來的香菸援助。 → 保留該貨，改談對方真正需要的食物或工具。 代價／限制：接受拒絕，不把送禮行為當成必定加關係。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：item_ownership、jobs、npc_relationship、regional_trade。研究：WG-02、LD-P02。

<a id="content_circuit_board"></a>
## 電路板 · content_circuit_board

MISC / salvaged_circuit_board｜180 g｜參考估值 40 Caps｜uncommon。
估值理由：40 Caps 只是可識別板件的基準提議，未測試不保證功能價值。
[既有圖片](../../../ui/assets/items/library/supplies/circuit_board.png)｜runtime ID：尚未註冊

一塊舊控制板留有插頭座與局部褪色編號。

**初見：** 外觀看似完整，不代表仍可運作。

**調查後可確認：** 可對照型號後測試、維修或拆取部分元件；不通用於所有設備。

收貨者可能需要的是某個接頭位置，而非整塊板子的泛用能力。

候選動作：identify_board、test_board、donate_for_repair。來源：old_world_utility、gray_valley。

- 新希望：供應 none／需求 medium。只有設備型號相符時有明確需求。
- 灰谷：供應 medium／需求 high。回收與檢測條件集中。
- 乾井：供應 low／需求 high。控制設備故障時急需可匹配板件。

- 舊水泵控制箱只有部分型號可讀。 → 用板上標號比對資料，決定是否值得測試。 代價／限制：不同型號不能硬換，試驗可能只排除相容性。
- 技工願意收壞板拆件，研究者想保留電路布局。 → 選擇整板保存或授權拆件。 代價／限制：拆解會失去原布局，不能同時保留完整板和全部零件。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：回收局部導線與外殼，破壞電路布局，不能返還完整板件。 候選產物：銅線、塑膠

前置缺口：disassembly、electronics、identification、item_ownership、repair。研究：WG-01、FICTION-CANTICLE。

<a id="content_civilian_pistol"></a>
## 民用手槍 · content_civilian_pistol

WEAPON / civilian_sidearm｜780 g｜參考估值 240 Caps｜uncommon。
估值理由：240 Caps 反映完整機件與較低攜行負擔。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/civilian_pistol.png)｜runtime ID：尚未註冊

扁平槍身帶著家用保管盒留下的磨痕。

**初見：** 較便於攜帶，零件相容性不能只靠外形判斷。

**調查後可確認：** 民用短槍，保險與供彈部件需要逐件檢查。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

適合輕裝護送的提案；不讓小體積等同於無代價隱藏武器。

候選動作：register_storage、compare_parts。來源：old_world_homes、salvage_merchants。

- 新希望：供應 low／需求 medium。短程貨主需要護衛，但不易自行維修。
- 灰谷：供應 medium／需求 medium。舊住宅和回收商是主要來源。
- 乾井：供應 low／需求 medium。外來型式多，買家先確認可維修性。

- 旅店要求客人寄存武器。 → 主動交由保管人登記存放。 代價／限制：需交出使用權直到領回；不自動換取信任獎勵。
- 回收商混裝了一箱手槍零件。 → 以完整樣品核對可送檢的相容部件。 代價／限制：需工匠與所有權許可，不當場拼出第二把槍。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_clean_water"></a>
## 淨水 · content_clean_water

CONSUMABLE / sealed_water｜1100 g｜參考估值 12 Caps｜common。
估值理由：12 Caps 以普通旅途補給作尺度，支付的是取水、檢驗與封裝。
[既有圖片](../../../ui/assets/items/library/supplies/clean_water.png)｜runtime ID：尚未註冊

封口袋裡的清水，外側繫著取水站的批次繩。

**初見：** 一份以含包材約一千一百克估重；透明不等於已檢驗。

**調查後可確認：** 來源與封口均核對後，可列作旅行飲水候選；不直接增加現有 water 資源。

新希望的取水站有固定接水時段，商隊帶來的水也要保留批次資訊。

候選動作：drink、share、deliver。來源：new_hope、water_station。

- 新希望：供應 high／需求 medium。取水與封裝方便，但田間工班仍用水。
- 灰谷：供應 low／需求 high。工地飲水多仰賴運入。
- 乾井：供應 low／需求 high。燃料產地仍需可靠飲水補給。

- 驛站搬水工要留下最後一袋水照顧遲到的人。 → 把自己一袋淨水交給驛站，讓工人能先回家。 代價／限制：實際交付一袋，自己下一段路的備用量降低。
- 運水商隊的封條有兩種顏色，收貨人拒絕混批。 → 出示取水批次，將自己的袋水列入可核對的一批。 代價／限制：核對需花時間；沒有來源記錄便不能取得認證。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：item_ownership、jobs、regional_trade。研究：WG-02、FICTION-ROAD。

<a id="content_cloth"></a>
## 布料 · content_cloth

MISC / cloth_roll｜500 g｜參考估值 10 Caps｜common。
估值理由：10 Caps 取常見可加工材料定位。
[既有圖片](../../../ui/assets/items/library/supplies/cloth.png)｜runtime ID：尚未註冊

一卷未漂白布料的邊沿有裁縫留下的粉筆線。

**初見：** 五百克布料，不是無菌繃帶。

**調查後可確認：** 可裁補衣物、包裹貨物或縫成簡單部件，耗去的布不能同時交作原料。

新希望有小型紡織與修補來源，灰谷工人則常要替換磨破布件。

候選動作：patch_fabric、wrap_cargo、deliver_material。來源：new_hope、settlement_workshop。

- 新希望：供應 high／需求 medium。有修補與家庭加工來源。
- 灰谷：供應 medium／需求 high。工衣和擦拭耗材需求多。
- 乾井：供應 low／需求 high。商隊篷布與包袋磨損補料難。

- 商隊的糧袋邊縫破了，還沒漏出太多內容。 → 提供布料給裁縫補強破邊。 代價／限制：消耗裁片與時間，不能順便增加袋子容量。
- 診所有人想把新布直接當無菌敷料。 → 改交作清潔包裹或非醫療修補，另找正式敷料。 代價／限制：拒絕混用途，布料不因潔白就得到醫療效果。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cargo、crafting、item_ownership、regional_trade、repair。研究：WG-01、FICTION-ROAD。

<a id="content_cloth_sack"></a>
## 布袋 · content_cloth_sack

CONTAINER / simple_sack｜180 g｜參考估值 12 Caps｜common。
估值理由：12 Caps 提案作低價包裝，仍比無主破布更完整。
[既有圖片](../../../ui/assets/items/library/clothing/cloth_sack.png)｜runtime ID：尚未註冊

袋口只有一條繩，布角繡著早已褪色的糧行記號。

**初見：** 便於分裝乾燥小物，沒有硬殼或防水能力。

**調查後可確認：** 180 g 為空布袋，袋內物資仍需逐件計重與確認所有權。

普通包裝能讓物資去向更清楚，不會讓既有背包容量憑空增加。

候選動作：separate_small_cargo、label_bundle。來源：new_hope、settlement_households。

- 新希望：供應 high／需求 high。種子與乾燥農產常需分裝。
- 灰谷：供應 high／需求 medium。小零件要整理，但銳利材料容易刮破布袋。
- 乾井：供應 medium／需求 medium。乾燥貨物可分袋，燃料不能直接裝布袋。

- 兩戶共同買下的種子混成一堆。 → 用已持有空袋分清雙方份額。 代價／限制：需双方確認數量，袋子也要記錄去向。
- 遺跡發現散落可回收小件。 → 先分裝已辨識且無主的物件。 代價／限制：仍占實際負重，不能以一袋代替無限物資。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、cargo、exploration、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-01、WG-02。

<a id="content_coffee"></a>
## 咖啡 · content_coffee

CONSUMABLE / coffee_packet｜200 g｜參考估值 45 Caps｜rare。
估值理由：45 Caps 因外來供應少且有人偏好，並非每個聚落都有高需求。
[既有圖片](../../../ui/assets/items/library/supplies/coffee.png)｜runtime ID：尚未註冊

封口袋裡的深色豆粒保留淡淡氣味。

**初見：** 兩百克一包，來源與受潮狀況需確認。

**調查後可確認：** 可交廚房沖煮或保留為外來商品；不給永久警覺或免睡能力。

願意付錢的是特定買家，不把全體居民都寫成咖啡愛好者。

候選動作：brew、exchange、deliver。來源：caravan、old_world_store。

- 新希望：供應 low／需求 low。多數家庭先買主食，少數買家偏好。
- 灰谷：供應 low／需求 medium。值班者和收藏外來口味的買家願意收。
- 乾井：供應 low／需求 medium。商隊停靠店希望提供少見飲品。

- 一名老技工只記得離鄉前的烘豆味道。 → 讓對方聞辨未開封包裝外留下的來源線索，再談是否交換。 代價／限制：懷念不是身份證明，也不保證對方接受這批。
- 夜班工棚想買咖啡卻欠飲水與燃料。 → 把沖煮所需條件列清，先處理基本供應。 代價／限制：咖啡不能取代睡眠或清水，且沖煮消耗實物。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、item_ownership、npc_relationship、regional_trade。研究：WG-02、LD-P01。

<a id="content_company_keycard"></a>
## 公司門禁卡 · content_company_keycard

MISC / site_access_card｜12 g｜參考估值 80 Caps｜rare。
估值理由：估值來自特定設施的調查需求；卡號失效或讀取器不相容時不具一般通行價值。
[既有圖片](../../../ui/assets/items/library/relics/company_keycard.png)｜runtime ID：尚未註冊

磨白的塑膠卡只剩一條藍線，掛孔處刻了簡單的扳手圖案。

**初見：** 有公司標誌與序號；不知道它對應哪扇門，也不知道能否讀取。

**調查後可確認：** 卡號屬於某類維護人員識別格式；需查驗設施、讀取器與授權紀錄後才能判斷是否適用。

通行是設施狀態與授權共同決定，卡片不通吃所有電子門，也不代表取得物資所有權。

候選動作：read_identifier、compare_access_log、present_card。來源：company_office、maintenance_locker、lost_luggage。

- 新希望：供應 none／需求 low。多數農業場所沒有相容讀取器，僅有調查委託需求。
- 灰谷：供應 low／需求 high。舊工業維護設施與識別檔案較相關。
- 乾井：供應 low／需求 medium。燃料設施可能尋找特定公司序號，必須先查型號。

- 泵站側門留下卡槽，主門外有居民封條。 → 先讀取卡號並和舊值班表比對，確定可能的維修入口。 代價／限制：需電子讀取設備、時間與現任管理者同意；不能以舊卡繞過現行所有權。
- 遺跡內一扇門有電，另一扇只有空卡框。 → 在確認相容性後嘗試有電的讀取器，記錄明確成功或拒絕。 代價／限制：卡片不供電，不消除門後危險；失敗不能扣掉虛構開鎖耗材。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、identification、exploration、knowledge、npc_relationship、regional_trade。研究：FICTION-WOOL、WG-04。

<a id="content_compass"></a>
## 指南針 · content_compass

TOOL / magnetic_compass｜100 g｜參考估值 35 Caps｜uncommon。
估值理由：35 Caps 以無需電源的導航工具估價，前提是可靠讀數。
[既有圖片](../../../ui/assets/items/library/supplies/compass.png)｜runtime ID：尚未註冊

盒蓋內有方向刻線，磁針停下後仍輕微晃動。

**初見：** 附近金屬與異常磁場可能使讀數失真。

**調查後可確認：** 需先核對環境與參考方向，才可用來維持方位；不能生成地圖。

乾井路線缺少地標時有用途，灰谷金屬設施旁需要交叉核對。

候選動作：take_bearing、check_route、teach_bearing。來源：caravan、old_world_survey。

- 新希望：供應 medium／需求 medium。採集者離開熟路才常用。
- 灰谷：供應 medium／需求 medium。供應來自舊貨，金屬干擾區要檢驗。
- 乾井：供應 low／需求 high。沙地少地標，可靠方位資訊有價值。

- 砂地上舊路標倒了，兩名帶路者方向相反。 → 離開明顯干擾物後比對方位與已有路線記錄。 代價／限制：方位不等於目的地座標，仍可能需要繞行。
- 廢機械旁的磁針一直偏轉。 → 把異常讀數記下，改用可見地標核對。 代價／限制：不把錯讀當成新道路，也不自動識別奇物來源。

維修：只更換匹配罩片和機構，完成後仍要核對可靠方向。 候選投入：玻璃、精密零件
拆解：罩片與外殼可分離，磁針不自動生成另一只指南針。 候選產物：玻璃、廢鐵

前置缺口：disassembly、identification、item_ownership、navigation、repair。研究：WG-01、FICTION-METRO。

<a id="content_copper_wire"></a>
## 銅線 · content_copper_wire

MISC / insulated_wire_coil｜300 g｜參考估值 20 Caps｜common。
估值理由：20 Caps 來自可辨來源的線材，分離污染和測試要花工。
[既有圖片](../../../ui/assets/items/library/supplies/copper_wire.png)｜runtime ID：尚未註冊

一小卷帶皮線材用紙帶標出拆卸來源。

**初見：** 三百克按線材連絕緣皮估算，長度與規格待核對。

**調查後可確認：** 測試後可用於相符電路連接；斷皮、細徑和不明接點都有限制。

灰谷回收多，乾井泵站維護卻常缺能用的那一種線。

候選動作：connect_circuit、deliver_material。來源：gray_valley、old_world_utility。

- 新希望：供應 low／需求 medium。水泵與簡單電器修理會採買。
- 灰谷：供應 high／需求 high。拆解來源多，同時有大量配線工作。
- 乾井：供應 low／需求 high。泵站和中繼設備難取得相容線材。

- 中繼棚的短線被人拆走。 → 提供規格相符的線材給技工補接。 代價／限制：需要斷電與測試；銅線會成為設備一部分。
- 村民想出售一卷來路不明的線。 → 要求保留來源並檢查斷皮，再決定收多少。 代價／限制：不能把可疑線材直接認定為安全或合法取得。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、electronics、item_ownership、regional_trade、repair。研究：WG-01、WG-03。

<a id="content_crowbar"></a>
## 撬棍 · content_crowbar

TOOL / prying_bar｜2000 g｜參考估值 65 Caps｜common。
估值理由：65 Caps 與 2000 g 是一般化物品的未採用提案，不套用既有 2 carrying-unit crowbar。
[既有圖片](../../../ui/assets/items/crowbar.png)｜runtime ID：尚未註冊

彎頭已被重磨過，握處纏著從座椅拆下的布。

**初見：** 有可插入的縫隙時能提供槓桿，封死的厚門仍需其他方案。

**調查後可確認：** 一根實心鋼製撬具；彎折和支點強度限制了可撬的目標。

既有 field_kit 撬棍例子繼續獨立存在；本提案不轉換其 ID、重量單位或配方。

候選動作：pry_crate、lift_grate、lever_obstruction。來源：gray_valley、salvage_yards。

- 新希望：供應 low／需求 high。倉庫修繕需要撬具，產地依賴外運。
- 灰谷：供應 high／需求 medium。拆解場常備，完整直桿比扭曲廢件有用。
- 乾井：供應 medium／需求 high。維修燃料棧板需要槓桿工具，需求受運輸量影響。

- 排水格柵卡住，底下傳來求助聲。 → 與現場人員協作抬起邊緣。 代價／限制：需安全支點與其他人承接格柵；不能單人保證救援。
- 貨箱的釘蓋可以從一角掀起。 → 撬開蓋板檢查內容。 代價／限制：必須有開箱權；可能破壞封條並留下明確責任。

維修：只有工坊能評估校直是否安全；纏布不恢復結構。 候選投入：鋼材、布料
拆解：報廢後視為一般金屬，不產生另一支撬棍。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、jobs、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：WG-01、WG-04。

<a id="content_data_disk"></a>
## 資料磁碟 · content_data_disk

MISC / archival_storage_disk｜90 g｜參考估值 120 Caps｜rare。
估值理由：估值按可讀介面與保存條件提出；未知內容不按寶藏價出售，讀取結果可能只是日常紀錄。
[既有圖片](../../../ui/assets/items/library/relics/data_disk.png)｜runtime ID：尚未註冊

防塵盒上的清單還在，勾選記號停在倒數第二行。

**初見：** 有連接端與封條，無法從外殼確定內容或是否完整。

**調查後可確認：** 相容讀取設備可檢查資料區與校驗狀態；實際能讀出的檔案才列入已知內容，損壞區保持缺失。

候選用途是有出處的設備日誌、運輸表或普通文檔；不給每片磁碟保證藏有新配方。

候選動作：inspect_format、read_archive、make_verified_copy。來源：office_archive、sealed_terminal_case、research_locker。

- 新希望：供應 none／需求 medium。供水與農業歷史紀錄可能有用，但缺少常備讀取設備。
- 灰谷：供應 low／需求 high。電子工坊或紀錄者較可能處理相容介面。
- 乾井：供應 low／需求 medium。煉製批次與運輸紀錄有特定查詢需求。

- 兩份裝運清單對同一批燃料寫了不同目的地。 → 讀取可驗證的磁碟記錄，比較日期與簽領編號。 代價／限制：需相容終端與閱讀時間；沒有資料就記錄缺失，不自動判定詐欺。
- 調查者要帶走唯一存檔，地方保管者希望留下證據。 → 在有空白媒體與校驗流程時製作一份可核對副本。 代價／限制：副本需有限媒體且權利人同意；複製不產生可無限賣出的稀有原件。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、knowledge、identification、jobs、regional_trade。研究：FICTION-CANTICLE、FICTION-WOOL。

<a id="content_desert_robe"></a>
## 沙地長袍 · content_desert_robe

APPAREL / desert_wrap｜900 g｜參考估值 55 Caps｜common。
估值理由：55 Caps 為地方常用服飾提案；900 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/desert_robe.png)｜runtime ID：desert_robe

寬鬆布層在腰間束起，褪色邊緣補著另一種織法。

**初見：** 能作穿著與遮蔭布使用；防砂效果要等環境規則。

**調查後可確認：** 乾井式長袍，布層仍透氣，不等同密封防護裝備。

它應與面罩、休息和路線選擇配合，不能單件取消風暴。

候選動作：wrap_against_dust、shade_supplies。來源：dry_well、desert_households。

- 新希望：供應 low／需求 low。潮濕農務環境不特別需要長袍。
- 灰谷：供應 medium／需求 medium。前往乾井的旅客會在中轉地備貨。
- 乾井：供應 high／需求 high。本地製作與日常替換都存在。

- 停車等候時一箱食物暴露在日照下。 → 暫時脫下長袍替貨物遮蔭。 代價／限制：自己失去穿著用途，布不能當冷藏或永久保存。
- 沙塵迫使旅人重新安排衣物包覆。 → 以已有長袍遮住外層行李。 代價／限制：占用衣物且仍可能需停行；不增加背包容量。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、hazards、cargo、camping、item_ownership、regional_trade、repair、disassembly。研究：LD-P01、FICTION-ROAD。

<a id="content_desert_sabre"></a>
## 沙地彎刀 · content_desert_sabre

WEAPON / travel_sabre｜1150 g｜參考估值 135 Caps｜uncommon。
估值理由：135 Caps 提案反映刀鞘與在地手工，非保證高傷害。
[既有圖片](../../../ui/assets/items/library/weapons/desert_sabre.png)｜runtime ID：尚未註冊

窄鞘外纏著防砂布，刀柄端有乾井匠人的敲印。

**初見：** 長刃需妥善收鞘；防砂包覆不能免去清潔。

**調查後可確認：** 適合攜行的地方刀式，匠印須核對才能作為來源證據。

乾井文化可辨識器具造型，但攜帶當地刀具不等於受到居民信任。

候選動作：cut_fabric、demonstrate_identity。來源：dry_well、desert_caravans。

- 新希望：供應 low／需求 low。農用刀較實惠，旅人會為攜行性買單。
- 灰谷：供應 low／需求 medium。收藏地方工藝與護衛有需求，供應依靠商隊。
- 乾井：供應 medium／需求 high。熟悉維護方式且有配鞘工匠，地方需求明確。

- 沙地帳篷外簾被風纏在支架。 → 先固定外簾，再裁掉已撕裂的部分。 代價／限制：需營地主同意，裁下布料不能當完整帳篷。
- 失蹤護衛留下帶匠印的刀鞘。 → 向乾井匠人求證製作者。 代價／限制：需旅行與詢問，不直接揭示護衛位置。

維修：專門配鞘與刃口保養可能需返回產地。 候選投入：鋼材、布料、皮革
拆解：回收會失去匠印與工藝證據，須事先提示。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、camping、knowledge、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：LD-P01、WG-05。

<a id="content_dirty_water"></a>
## 污水 · content_dirty_water

CONSUMABLE / untreated_water｜1100 g｜參考估值 2 Caps｜common。
估值理由：2 Caps 只代表取樣與搬運價值，不按飲水售價估算。
[既有圖片](../../../ui/assets/items/library/supplies/dirty_water.png)｜runtime ID：尚未註冊

瓶底沉著細灰，搖晃後整瓶變成褐色。

**初見：** 這是一份待處理水樣，不是可直接飲用的補給。

**調查後可確認：** 可觀察沉澱與來源；是否可處理仍須檢驗，濾清不能證明安全。

溪流上游的修路和聚落排水都可能改變水樣；來源須由事件事實決定。

候選動作：sample、treat、deliver_sample。來源：wilderness、runoff。

- 新希望：供應 medium／需求 low。水樣採集容易，只收有來源記錄的樣本。
- 灰谷：供應 medium／需求 medium。排水檢查需要不同位置的樣本。
- 乾井：供應 low／需求 medium。井邊異常水樣有調查價值，不能當飲水補貨。

- 灰谷排水渠與上游溪流顏色不同。 → 分別帶來源清楚的水樣交給檢查者比較。 代價／限制：需保留取樣位置；一瓶混水無法回答源頭在哪。
- 旅人想把桶裡的灰水當晚餐用水。 → 保留污水供處理評估，改請旅人先找可靠水源。 代價／限制：不保證能處理成功，也不把外觀澄清當作飲用許可。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：exploration、identification、item_ownership、water_treatment。研究：WG-01、FICTION-ROAD。

<a id="content_disinfectant"></a>
## 消毒水 · content_disinfectant

CONSUMABLE / labelled_antiseptic｜300 g｜參考估值 20 Caps｜uncommon。
估值理由：20 Caps 反映可靠標示與封裝成本，未知液體不照此估值。
[既有圖片](../../../ui/assets/items/library/supplies/disinfectant.png)｜runtime ID：尚未註冊

棕色瓶上還能讀出用途與批號，瓶蓋沒有破損。

**初見：** 一瓶有標示的用品，不能只看顏色判斷內容。

**調查後可確認：** 核對品項與可用狀況後，可成為診所處置耗材，不直接治癒傷勢。

診所會拒絕來源不明的補充瓶，工業化學品不能冒充這個品項。

候選動作：supply_clinic、inspect_label。來源：old_world_clinic、settlement_clinic。

- 新希望：供應 low／需求 medium。診所按來源收貨，不自製所有品項。
- 灰谷：供應 medium／需求 high。工地診所多，可信醫用品仍有限。
- 乾井：供應 low／需求 high。燃料作業點需要可靠醫療備品。

- 灰谷臨時診所只剩幾瓶無標示液體。 → 交付有批號的消毒水，隔開未知液體。 代價／限制：交出一瓶；檢查與使用等待醫療權限。
- 乾井收貨者質疑瓶蓋曾經被開過。 → 允許核對封口和運送紀錄，接受拒收。 代價／限制：核驗不能恢復無法證明的保存歷史。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、injury、item_ownership、jobs。研究：WG-01、WG-02。

<a id="content_double_barrel_shotgun"></a>
## 雙管散彈槍 · content_double_barrel_shotgun

WEAPON / double_barrel_shotgun｜3350 g｜參考估值 300 Caps｜uncommon。
估值理由：300 Caps 提案考慮完整配對與較高保養負擔。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/double_barrel_shotgun.png)｜runtime ID：尚未註冊

兩根槍管的色澤略有不同，皮製背帶修了又修。

**初見：** 成對機件增加檢查需求，不能僅靠外觀看成兩倍能力。

**調查後可確認：** 雙管民用槍，需要確認兩側狀態與相容補給。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

偏重的鄉間器材可具有家族傳承意義，不必永遠是上一型的傷害升級。

候選動作：mediate_custody、compare_service_history。來源：rural_households、hunting_lodges。

- 新希望：供應 medium／需求 medium。獵戶認識型式，但會逐把檢查。
- 灰谷：供應 low／需求 medium。工坊收購可檢修成對機件。
- 乾井：供應 low／需求 low。長途重量與補給使需求受限。

- 兩兄弟對祖輩器材的處置意見不同。 → 先封存原物，協助釐清交接意願。 代價／限制：需双方同意，不能把一件完整物品自動分成兩把。
- 槍匠指出兩側保養記錄不一致。 → 選擇送檢而非立刻出售。 代價／限制：花時間且可能發現整機不值得修。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、鋼材、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_dust_mask"></a>
## 沙塵面罩 · content_dust_mask

APPAREL / dust_face_cover｜180 g｜參考估值 38 Caps｜common。
估值理由：38 Caps 提案比整件服裝便宜，定期換襯仍有成本。
[既有圖片](../../../ui/assets/items/library/clothing/dust_mask.png)｜runtime ID：尚未註冊

兩條綁帶顏色不一樣，內襯堆著洗不掉的砂色。

**初見：** 用於灰塵環境的穿戴提案；不等同防毒面具。

**調查後可確認：** 布面罩需合身且內衬可處理，不能針對所有氣體提供保護。

它應讓出發準備更具體，不在 ITEM-1 中偷偷取消風暴延誤。

候選動作：fit_dust_cover、replace_dirty_liner。來源：dry_well、caravan_tailors。

- 新希望：供應 low／需求 medium。穀物搬運和乾燥農路也可能有需求。
- 灰谷：供應 medium／需求 high。粉塵工地與拆解場常用。
- 乾井：供應 high／需求 high。沙地日常更換形成穩定流通。

- 商隊出發檢查發現內襯已塞滿砂。 → 先更換或清理可處理的內襯。 代價／限制：花時間與材料，舊布不能即刻變成乾淨替換品。
- 工人誤把面罩當成未知氣體防護。 → 指出限制並改用隔離調查方案。 代價／限制：無立即入內收益，避免把道具名稱當安全證明。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、hazards、exploration、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、FICTION-METRO。

<a id="content_engineering_goggles"></a>
## 工程護目鏡 · content_engineering_goggles

APPAREL / work_goggles｜240 g｜參考估值 65 Caps｜common。
估值理由：65 Caps 提案包含完好鏡片與固定帶的日常工坊需求。
[既有圖片](../../../ui/assets/items/library/clothing/engineering_goggles.png)｜runtime ID：尚未註冊

透明鏡片邊緣刻著一道細線，鬆緊帶看起來是新換的。

**初見：** 能作工作護目裝備候選；刮痕會妨礙觀察。

**調查後可確認：** 普通透明工作鏡，不是焊接面罩、夜視鏡或氣密防護。

保持專門用途界線，不能因工程二字提供所有 MECHANICS 解法。

候選動作：inspect_lens、wear_for_work。來源：gray_valley、workshops。

- 新希望：供應 low／需求 medium。谷物粉塵與修理工作需要。
- 灰谷：供應 high／需求 high。加工工班有供應與換新需求。
- 乾井：供應 medium／需求 high。風砂和固定工地需要護目器材。

- 技工準備檢查受損機件。 → 先確認鏡片視野與固定帶。 代價／限制：裝備不取代操作知識，未定義防護效果仍不生效。
- 商隊尋人辨認一副特別配鏡。 → 比對鏡架維修記號。 代價／限制：需原維修者核對，不把持物當身分證。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：玻璃、橡膠
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：玻璃、橡膠

前置缺口：equipment、hazards、identification、knowledge、item_ownership、regional_trade、repair、disassembly。研究：WG-01、WG-02。

<a id="content_entrenching_shovel"></a>
## 工兵鏟 · content_entrenching_shovel

TOOL / folding_shovel｜1250 g｜參考估值 95 Caps｜uncommon。
估值理由：95 Caps 提案包含折疊鉸鏈便利性，重量指乾燥空鏟。
[既有圖片](../../../ui/assets/items/library/weapons/entrenching_shovel.png)｜runtime ID：尚未註冊

折柄鏟面的黑漆已磨成銀灰色，鉸鏈仍能鎖住。

**初見：** 適合狹窄地點挖土；折柄並不適合當長距離攀登錨。

**調查後可確認：** 舊工程鏟，鎖扣完整時才能承受一般挖掘負荷。

退役工程器具會流入三地，出土地不代表仍有軍方認證。

候選動作：dig_drain、uncover_marker、brace_door。來源：old_world_depots、field_camps。

- 新希望：供應 medium／需求 high。清理灌溉溝需要小鏟，木柄農具仍較便宜。
- 灰谷：供應 medium／需求 medium。工業地基與瓦礫間適用，但鉸鏈維修要工坊。
- 乾井：供應 low／需求 high。埋設防風繩與挖排砂溝需要耐用鏟面。

- 雨水正淹入临時宿營地。 → 挖短排水溝，替已有遮棚導流。 代價／限制：需土地允許與時間；石地或洪水不能靠短鏟解決。
- 路標底座埋進浮土。 → 局部挖開找出朝向記號。 代價／限制：只恢復現場可見資訊，不能揭露整張地圖。

維修：鉸鏈與鏟面要分別鑑定；裂開鏟面可能不值得修。 候選投入：鋼材、軸承
拆解：拆卸報廢工具回收金屬，取消其挖掘用途。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、camping、navigation、item_ownership、regional_trade、repair、disassembly。研究：WG-01、FICTION-ROAD。

<a id="content_farm_clothes"></a>
## 農務服 · content_farm_clothes

APPAREL / agricultural_workwear｜1050 g｜參考估值 35 Caps｜common。
估值理由：35 Caps 提案重視完整尺寸與換洗便利。
[既有圖片](../../../ui/assets/items/library/clothing/farm_clothes.png)｜runtime ID：尚未註冊

褲腳留著灌溉渠的淤泥色，肩背多縫了一層布。

**初見：** 方便農務換洗，濕透後仍需晾乾。

**調查後可確認：** 較輕的農務服，補強處偏向肩背搬運磨耗。

看見農服不等於居民會將外來者當成本地人。

候選動作：change_for_fieldwork、dry_field_clothes。來源：new_hope、farms。

- 新希望：供應 high／需求 high。灌溉與收成工作需要日常替換。
- 灰谷：供應 medium／需求 low。可作輕便工作衣，但工坊需要更耐磨材料。
- 乾井：供應 low／需求 medium。補給農田的外來短工可能收購。

- 灌溉維修後參與者衣服全濕。 → 提供乾燥農服作替換。 代價／限制：需要合身與接收者同意，不能直接清除疾病或傷害。
- 農戶希望辨認被順手帶走的衣物。 → 讓他核對獨特補強縫線。 代價／限制：核對不是定罪，需其他所有權證據。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、hazards、jobs、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：LD-P02、FICTION-ROAD。

<a id="content_fire_axe"></a>
## 消防斧 · content_fire_axe

WEAPON / rescue_axe｜3200 g｜參考估值 145 Caps｜uncommon。
估值理由：145 Caps 提案反映耐用斧頭與完整柄，重載是攜帶代價。
[既有圖片](../../../ui/assets/items/library/weapons/fire_axe.png)｜runtime ID：尚未註冊

斧頭上仍留著半片紅漆，柄尾繫著褪色的救援標籤。

**初見：** 可處理木製障礙；劈開隔板之前必須知道另一側有沒有人。

**調查後可確認：** 完整斧頭需牢固斧柄和可用刃口，不具隔絕電源的效力。

消防器具首先是救援工具，舊標籤不賦予進入民宅的權利。

候選動作：break_wood_partition、clear_frame。來源：old_world_fire_stations、civic_depots。

- 新希望：供應 low／需求 high。木造棚舍和災後救援需要重斧。
- 灰谷：供應 medium／需求 medium。廢公共設施能取得，切金屬仍要別的工具。
- 乾井：供應 low／需求 medium。燃料場所只在安全評估後使用，不能任意破拆。

- 倉庫木框變形卡住救援口。 → 在清空另一側後破拆木框。 代價／限制：耗作業時間並摧毁門框，後續修繕由救援方承擔。
- 倒木壓住一件有主背包。 → 劈開細枝讓失主取包。 代價／限制：厚樹幹需更多人手；斧頭不能保證一次清開。

維修：金屬刃與握部修繕分開；木柄來源另待 crafting 定義。 候選投入：鋼材、皮革
拆解：只回收斧頭金屬，木柄不憑空轉為清單中不存在的木材物品。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、jobs、hazards、item_ownership、regional_trade、repair、disassembly。研究：WG-01、FICTION-ROAD。

<a id="content_firefighter_suit"></a>
## 防火服 · content_firefighter_suit

APPAREL / fire_resistant_workwear｜6400 g｜參考估值 510 Caps｜rare。
估值理由：510 Caps 為經檢驗可用救援服的提案價。
[既有圖片](../../../ui/assets/items/library/clothing/firefighter_suit.png)｜runtime ID：尚未註冊

袖口的救援編號仍在，褲腳有一次作業留下的焦痕。

**初見：** 防火衣不自帶可呼吸空氣，也不代表能進任何火場。

**調查後可確認：** 多層救援工作服，需要核對焦痕是否傷到內層。

衣物服務救援故事，不能替代水、呼吸器或已存在的消防隊。

候選動作：inspect_rescue_clothing、lend_rescue_gear。來源：old_world_fire_stations、rescue_depots。

- 新希望：供應 none／需求 medium。木造棚舍多，集體救援備品有理由。
- 灰谷：供應 low／需求 high。舊消防站與工業安全隊可能保管。
- 乾井：供應 low／需求 high。燃料事故需求迫切，但配套和訓練同樣重要。

- 燃料庫外有人組織救援。 → 將衣物借給具備合適訓練的人。 代價／限制：需本人同意與衣物尺寸，不能宣稱火災因此熄滅。
- 封存庫找出一套有焦痕的服裝。 → 先送檢而非直接分配使用。 代價／限制：佔用運輸與檢驗時間，可能只剩展示或報廢價值。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、橡膠
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、hazards、identification、jobs、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：FICTION-ROAD、WG-05。

<a id="content_first_aid_kit"></a>
## 急救包 · content_first_aid_kit

CONSUMABLE / field_medical_kit｜800 g｜參考估值 55 Caps｜uncommon。
估值理由：55 Caps 為成套、易攜且可核對內容的準備成本。
[既有圖片](../../../ui/assets/items/candidates/medkit.png)｜runtime ID：first_aid_kit

耐磨小包以分格收好未拆封的急救耗材。

**初見：** 保持 ITEM-1 的八百克；物品不因名為急救包就自帶補血指令。

**調查後可確認：** 可核對整包內容後交給能處置的人；一次使用哪些內容需未來規則。

商隊購買時重視清單是否完整，過去使用過的包不能冒充完整新包。

候選動作：offer_field_aid、donate、check_contents。來源：settlement_clinic、caravan。

- 新希望：供應 medium／需求 medium。可由診所整理有限套數。
- 灰谷：供應 medium／需求 high。外勤工隊出發前常補貨。
- 乾井：供應 low／需求 high。車隊長途旅行需要完整套件。

- 倒車事故後有人呼叫具備醫療能力的旅人。 → 把完整急救包提供給合格處置者。 代價／限制：所用內容要記為消耗；持包不代表自己能處置。
- 商隊買到一包缺少封裝內容的急救包。 → 展開自己的清單協助比對並要求賣家說明。 代價／限制：只能辨明缺項，不能自動補成完整套件。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：injury、item_ownership、jobs、npc_relationship。研究：FICTION-ROAD、WG-04。

<a id="content_flamethrower"></a>
## 火焰噴射器 · content_flamethrower

WEAPON / fuel_projection_equipment｜13800 g｜參考估值 850 Caps｜rare。
估值理由：850 Caps 是無燃料器材的未採用估值，安全隔離可能比收購更昂貴。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/flamethrower.png)｜runtime ID：尚未註冊

沉重背架上的警告標記比器材本身更清楚。

**初見：** 燃料系統與密封狀態都未知，不可因有燃料就當成可用。

**調查後可確認：** 危險舊裝備，須專門保管與檢查；不提供操作或製作參數。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

內容重心是危險資產的去處和運輸責任，並非普通探索清障萬能解。

候選動作：isolate_hazardous_cargo、arrange_specialist_handover。來源：restricted_old_world_sites、military_storage。

- 新希望：供應 none／需求 none。農地與糧倉不需要此類普通貨物。
- 灰谷：供應 none／需求 low。只有受託拆解或保管機構可能處理。
- 乾井：供應 none／需求 low。燃料產地不代表願意接受危險器材。

- 回收商想把不明背架混入一般燃料貨物。 → 要求分隔保管並查明來源。 代價／限制：增加運輸成本，不可用燃料標籤跳過危險物管理。
- 廢工廠保管人要求移走封存器材。 → 協商交由專業拆解者處理。 代價／限制：需實際接收者與運輸能力，不直接拆成可售燃料。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：橡膠、鋼材、精密零件
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_flare_pistol"></a>
## 信號槍 · content_flare_pistol

TOOL / signal_launcher｜620 g｜參考估值 145 Caps｜uncommon。
估值理由：145 Caps 提案反映罕見專用用途，不含任何信號彈。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/flare_pistol.png)｜runtime ID：尚未註冊

橙色外殼上有一條已褪色的海事標記。

**初見：** 用於發出信號的構想，需要專用信號耗材；不能當免費照明。

**調查後可確認：** 單次信號發射器，信號種類與接收約定尚待建立。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

重點是被誰看見及暴露位置的代價，不附帶固定救援保證。

候選動作：agree_signal_protocol、observe_signal。來源：old_world_maritime、desert_caravans。

- 新希望：供應 low／需求 medium。遠郊農場希望有求援方式，但需要約定。
- 灰谷：供應 low／需求 low。密集建築遮擋視線，無線電可能更合適。
- 乾井：供應 medium／需求 high。荒漠長線商隊需要可見的失散信號。

- 商隊在分岔地約好失散標記。 → 先協商何種情況才發信號。 代價／限制：耗材規格和信號規則未定義前不能使用；發射會暴露所在區域。
- 高處看見陌生求援光。 → 保留信號器，先確認是否有對應接收者。 代價／限制：觀察需時間，不保證遠方訊號可信或有人回應。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_flashlight"></a>
## 手電筒 · content_flashlight

TOOL / handheld_light｜400 g｜參考估值 35 Caps｜common。
估值理由：35 Caps 來自可攜光源與外殼維護，不附贈能源。
[既有圖片](../../../ui/assets/items/candidates/flashlight.png)｜runtime ID：flashlight

磨花的燈罩旁刻著前任使用者的值班號碼。

**初見：** 保持 ITEM-1 的四百克；電池存量另算。

**調查後可確認：** 裝入相容電池並確認燈泡後，才有可持續一段時間的照明方案。

灰谷工人偏好容易換電池的款式；遺跡燈具可能用不同接點。

候選動作：illuminate、signal、inspect。來源：gray_valley、old_world_home。

- 新希望：供應 medium／需求 medium。夜間巡水需要可攜光源。
- 灰谷：供應 high／需求 high。工地常用，替換零件也較容易找。
- 乾井：供應 low／需求 high。夜間卸貨與泵房檢查依賴照明。

- 配電間的刻字躲在架子底部。 → 用手電筒照明讀取標記，決定是否值得繼續調查。 代價／限制：消耗相容電池電量；照明不等於具備修理技術。
- 夜間迎面商隊看不清路障後的人。 → 用燈光發出事先約定的停靠訊號。 代價／限制：必須已有共同訊號約定，亂閃可能被誤解。

維修：依故障更換合規燈罩、線路或接點；沒有相容燈泡時不能保證修復。 候選投入：玻璃、銅線、彈簧
拆解：只提議回收仍完好的小件，拆解後不再保留完整光源。 候選產物：銅線、彈簧、玻璃

前置缺口：disassembly、electronics、item_ownership、lighting、repair。研究：WG-01、WG-05。

<a id="content_food"></a>
## 乾糧 · content_food

CONSUMABLE / travel_ration｜400 g｜參考估值 12 Caps｜common。
估值理由：12 Caps 與普通食物資源尺度接近，取方便攜帶的設計定位。
[既有圖片](../../../ui/assets/items/food.png)｜runtime ID：尚未註冊

乾燥穀餅用油紙分成小包，方便在路邊分食。

**初見：** 一份四百克旅行乾糧；包裝破損要另行檢查。

**調查後可確認：** 批次合格後可作耐攜補給；分享會實際減少自己攜帶的份數。

旅店把不同家庭做的乾糧分批記帳，不能把一包視作無限餐食。

候選動作：eat、share、deliver。來源：new_hope、caravan。

- 新希望：供應 high／需求 medium。農產可加工，居民和商隊都消費。
- 灰谷：供應 low／需求 high。工人需要方便帶進工地的餐食。
- 乾井：供應 low／需求 high。油料商隊出發前大量準備旅行口糧。

- 旅人為等同行者錯過了晚餐供應。 → 分出一份乾糧，讓對方不必立即離開尋食。 代價／限制：消耗一份；對方不保證給回更值錢的東西。
- 灰谷工班午餐車卡在路上。 → 用易分配的乾糧先完成小批交貨。 代價／限制：交貨份數有限，不能因此宣稱整個工地已免於飢餓。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：item_ownership、jobs、regional_trade。研究：FICTION-ROAD、LD-P02。

<a id="content_fuel"></a>
## 燃料 · content_fuel

CONSUMABLE / sealed_fuel_portion｜1000 g｜參考估值 18 Caps｜common。
估值理由：18 Caps 參照既有燃料尺度作設計估值，未定物理換算或價格公式。
[既有圖片](../../../ui/assets/items/fuel.png)｜runtime ID：尚未註冊

封好的燃料份裝在有品級記號的運輸瓶裡。

**初見：** 一份含封裝暫估一千克；不等於現有 fuel 抽象資源的一單位。

**調查後可確認：** 先核對品級與設備相容性，再作發電或運輸供應提案。

乾井的出產優勢與安全包裝需求同時存在；有油不代表每條路都能供應。

候選動作：supply_generator、deliver_fuel、verify_grade。來源：dry_well、refinery。

- 新希望：供應 low／需求 medium。抽水和外來機具需相容油料。
- 灰谷：供應 medium／需求 high。工坊設備與車隊都需要能源。
- 乾井：供應 high／需求 high。產出與裝運消耗並存，不能視作無限廉價庫存。

- 商隊裝錯品級，泵房拒絕把燃料倒進設備。 → 核對標記後改送給相容用戶。 代價／限制：繞送增加時間與運費，不能把不同燃料直接混用。
- 乾井停靠點只剩最後一份可供小型設備的燃料。 → 選擇留給自己的裝置或交給已確認用途的公共設備。 代價／限制：交付就失去這份燃料，不保證同時解決所有供能需求。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：electronics、hazards、identification、item_ownership、regional_trade。研究：WG-03、FICTION-METRO。

<a id="content_fuel_can"></a>
## 燃料罐 · content_fuel_can

CONTAINER / empty_fuel_can｜900 g｜參考估值 26 Caps｜common。
估值理由：26 Caps 來自耐搬運的罐體與封蓋，未包含燃料售價。
[既有圖片](../../../ui/assets/items/library/supplies/fuel_can.png)｜runtime ID：尚未註冊

空金屬罐散著舊燃料味，罐蓋帶有鎖扣。

**初見：** 九百克是空罐重量；不能直接視作一份燃料。

**調查後可確認：** 密封合格後可裝指定燃料，曾盛燃料的罐不轉作飲水壺。

乾井會回收可用罐，灰谷可修罐體；兩地需求原因不同。

候選動作：fill_fuel、seal、transport。來源：dry_well、gray_valley。

- 新希望：供應 medium／需求 low。常用於外來機具燃料，不是主產貨。
- 灰谷：供應 high／需求 medium。金屬加工可修罐蓋與焊縫。
- 乾井：供應 high／需求 high。燃料裝運周轉使空罐仍有需求。

- 乾井有一份燃料可帶走，卻沒有可運容器。 → 提供已驗證密封的空罐承裝。 代價／限制：燃料要另外支付或交付，容器容量也要確認。
- 灰谷收罐工拒絕有滲漏痕的貨。 → 將空罐交給工匠做密封檢查。 代價／限制：檢查可能判定不可用；無權自動修補或返還滿罐油。

維修：確認空罐已符合安全作業條件後，由工匠處理密封與罐體；不能保證所有罐可救。 候選投入：橡膠、鋼材
拆解：需先由合格作業者處理殘留物；金屬回收會破壞罐體。 候選產物：廢鐵

前置缺口：cargo、disassembly、hazards、item_ownership、regional_trade、repair。研究：WG-03、FICTION-METRO。

<a id="content_gas_mask"></a>
## 防毒面具 · content_gas_mask

APPAREL / filtered_respirator_mask｜950 g｜參考估值 310 Caps｜rare。
估值理由：310 Caps 假設面體可用，不包含有效濾罐供應。
[既有圖片](../../../ui/assets/items/library/clothing/gas_mask.png)｜runtime ID：尚未註冊

面窗仍透明，濾罐標籤卻被刮掉了一半。

**初見：** 面罩、密封和相容濾材缺一不可，持有不等於能呼吸安全空氣。

**調查後可確認：** 濾罐式面具，適用危害與耗材壽命尚待環境危害規則；不能與淨水規則混用。

不假借污水處理或一般醫療 authority；呼吸防護需要獨立條件。

候選動作：inspect_face_seal、identify_filter_type。來源：old_world_safety、military_ruins。

- 新希望：供應 none／需求 low。只在特殊環境調查有需求。
- 灰谷：供應 low／需求 high。工業安全與遺跡調查者願意送檢。
- 乾井：供應 low／需求 medium。煉製場所需要確認具體危害後才採用。

- 廢棄管道口有居民描述刺鼻氣味。 → 先尋找氣體與濾材相容資訊。 代價／限制：需專業檢測，不能戴面具直接穿越未知氣體。
- 商人出售外觀良好的面具卻無有效濾材。 → 只談面體收購或拒買。 代價／限制：完整防護尚缺耗材，不因高價就視為已解鎖區域。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：橡膠、玻璃
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：橡膠、玻璃

前置缺口：equipment、hazards、identification、exploration、item_ownership、regional_trade、repair、disassembly。研究：WG-05、FICTION-WOOL。

<a id="content_gear"></a>
## 齒輪 · content_gear

MISC / machine_gear｜450 g｜參考估值 18 Caps｜common。
估值理由：18 Caps 取常見可量測機械件定位，加工相容性比稀有度重要。
[既有圖片](../../../ui/assets/items/library/supplies/gear.png)｜runtime ID：尚未註冊

齒輪邊緣有可比對的齒形，輪孔稍帶油痕。

**初見：** 一個四百五十克齒輪，模數與軸孔沒有預設通用。

**調查後可確認：** 只有匹配的傳動機構能使用；磨損齒面也需檢查。

灰谷的箱裡很多齒輪，但農務泵缺的可能是其中很特定的一個。

候選動作：match_drive、replace_component。來源：gray_valley、industrial_ruin。

- 新希望：供應 low／需求 medium。農具傳動有指定規格需求。
- 灰谷：供應 high／需求 medium。拆機來源多但仍須挑規格。
- 乾井：供應 medium／需求 high。泵與車輛傳動要維護。

- 手搖捲揚機的齒面缺了一角。 → 用帶來的齒輪比對齒形與軸孔。 代價／限制：不匹配便無替換方案，仍需修理者確認安裝。
- 灰谷商人提供一箱齒輪卻不讓量尺寸。 → 要求量測後才接指定件的運送。 代價／限制：查驗會耽誤裝車，不接受就只能放棄此批。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：失準齒輪只能降級作金屬，齒形精度不能從回收描述中恢復。 候選產物：廢鐵

前置缺口：crafting、disassembly、identification、item_ownership、regional_trade、repair。研究：WG-01、WG-03。

<a id="content_geological_survey_map"></a>
## 地質調查圖 · content_geological_survey_map

MISC / survey_document｜180 g｜參考估值 190 Caps｜rare。
估值理由：位置與比例尺仍可對照的圖有調查價值，但地質標記不是可立即收取的資源。
[既有圖片](../../../ui/assets/items/library/relics/geological_survey_map.png)｜runtime ID：尚未註冊

地圖邊框剪掉一角，保留下來的方格上擠滿了三種顏色的筆記。

**初見：** 有等高線、鑽孔號與舊路標；日期、座標基準和現況尚待核對。

**調查後可確認：** 可辨識調查範圍與採樣位置，部分標記只是推測層；需現地比對後才能建立候選位置。

候選內容是把風險變得更可問，而非生成礦脈、泉眼或採集量；地貌也可能已變。

候選動作：compare_strata、locate_survey_point、annotate_uncertainty。來源：survey_office、field_case、geological_archive。

- 新希望：供應 low／需求 high。井址調查與坡地用水可能需要舊鑽孔資料。
- 灰谷：供應 low／需求 medium。材料來源調查者關心特定岩層而非整張圖。
- 乾井：供應 low／需求 high。尋找舊井與穩定道路基底有具體需求。

- 乾井附近兩個候選井址的傳言相互矛盾。 → 對照舊鑽孔位置，先找可核對的實體標記。 代價／限制：需實地行走與導航能力；舊孔位不保證有水，不直接改供水。
- 灰谷商隊想跨過新塌坡節省路程。 → 將圖上的坡層資訊與現場裂縫比較，提出調查範圍。 代價／限制：地圖可能過期；只能指出疑點，安全通行仍需現況與路線權威。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、navigation、exploration、hazards、jobs、regional_trade。研究：FICTION-METRO、LD-P01。

<a id="content_glass"></a>
## 玻璃 · content_glass

MISC / glass_pane｜800 g｜參考估值 10 Caps｜common。
估值理由：10 Caps 材料常見但完整運到買家手中有成本。
[既有圖片](../../../ui/assets/items/library/supplies/glass.png)｜runtime ID：尚未註冊

一片玻璃用厚紙護住邊緣，能看見幾道細痕。

**初見：** 八百克以受保護的一片計，搬運時仍會破裂。

**調查後可確認：** 可裁配合尺寸的窗片或展示罩，不是光學鏡片的等價替代。

灰谷容易找到舊窗片，遠程運輸最難的是尺寸不變且不碎。

候選動作：replace_window、protect_document、deliver_material。來源：gray_valley、old_world_home。

- 新希望：供應 medium／需求 low。家屋窗片有零星來源。
- 灰谷：供應 high／需求 medium。舊建築回收多，完整片仍需挑選。
- 乾井：供應 low／需求 medium。泵房窗與標示罩有需求，但運輸易損。

- 泵房窗口破了，風沙一直進到帳本桌上。 → 交付完整玻璃給工匠裁配。 代價／限制：需要尺寸、框架與運送保護；破片不算完成交付。
- 研究者想把潮濕文件先保護起來。 → 提供玻璃作展示罩的一部分。 代價／限制：需其他支撐和處理，不能把文件夾住就聲稱完成保存。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cargo、crafting、item_ownership、regional_trade、repair。研究：WG-01、FICTION-CANTICLE。

<a id="content_gray_seed"></a>
## 灰種 · content_gray_seed

MISC / unclassified_seed｜8 g｜參考估值 None Caps｜rare。
估值理由：沒有普通種子的確定農業價值；只有願意隔離試驗的研究者或種子保管者表達需求。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/gray_seed.png)｜runtime ID：尚未註冊

灰色外皮像沾了細粉，用布擦拭後仍沒有露出別的顏色。

**初見：** 外形像種子，未知是否有生命、能否發芽或接觸農田是否安全。

**調查後可確認：** 可記錄外觀和封存條件；鑑定到植物類型也不等於知道產量、可食性或擴散風險。

候選長期目標是有限、隔離的觀察，絕不直接成為永久增產道具或會自行擴散的世界事件。

候選動作：document_seed、keep_quarantined、plan_controlled_trial。來源：sealed_botanical_case、anomalous_garden、soil_sample_box。

- 新希望：供應 none／需求 high。種子保管者可能願意提供隔離試驗，需求以不危及現有作物為前提。
- 灰谷：供應 none／需求 low。工業聚落多半只能協助保存與轉運。
- 乾井：供應 none／需求 medium。耐旱傳聞可能吸引買家，但無試驗不能保證沙地可種。

- 農戶想把灰種混進下一批普通播種。 → 提出單獨容器試驗，將普通種子保留給正常種植。 代價／限制：需專用容器、水與多日觀察；不保證發芽，試驗不能污染正常田區。
- 商人稱這是能免灌溉的作物，要求立即交易。 → 索取來源與試種紀錄，或保持封存等待辨識。 代價／限制：查證可能錯過當次交易；未證實的宣稱不進物品效果欄。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、hazards、knowledge、jobs、regional_trade。研究：FICTION-ROADSIDE、FICTION-CANTICLE。

<a id="content_grenade_launcher"></a>
## 榴彈發射器 · content_grenade_launcher

WEAPON / restricted_launcher｜5800 g｜參考估值 1100 Caps｜rare。
估值理由：1100 Caps 僅是完整無彈器材的設計估值。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/grenade_launcher.png)｜runtime ID：尚未註冊

厚重外殼仍有封存標記，配套箱卻空著。

**初見：** 缺少特定彈藥與受控保管條件，帶走也不能立即使用。

**調查後可確認：** 軍用發射器，檢驗、彈藥與範圍後果都缺正式規則。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

不設計製造、改裝或爆炸參數；其內容可圍繞保管與交付抉擇。

候選動作：seal_sensitive_equipment、audit_delivery。來源：military_storage、restricted_convoys。

- 新希望：供應 none／需求 none。農業聚落無一般使用者或正常收購需求。
- 灰谷：供應 none／需求 low。少數受託保管者或研究工坊可能介入。
- 乾井：供應 none／需求 low。只有具體委託會尋求，不列日常商店供貨。

- 倉庫管理者發現不應混進民用貨箱的器材。 → 協助封存並追查交接文件。 代價／限制：不得擅自試用；移交要記錄所有權與責任。
- 陌生買家拒絕說明用途。 → 選擇保留封存或拒絕交易。 代價／限制：占據運輸與保管資源，沒有拒售的必然正面獎勵。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：精密零件、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_hand_crank_generator"></a>
## 手搖發電機 · content_hand_crank_generator

TOOL / manual_generator｜1500 g｜參考估值 110 Caps｜uncommon。
估值理由：110 Caps 交換的是離網備援能力，不是免費無限電力。
[既有圖片](../../../ui/assets/items/library/supplies/hand_crank_generator.png)｜runtime ID：尚未註冊

折疊搖把連著小型機構，輸出端貼著規格紙。

**初見：** 供電相容性與輸出能力未核對前，不視作萬用電源。

**調查後可確認：** 可在合適條件下提供短時人工供電，持續使用佔用人力。

通訊站可能願意借用測試，但不會靠這一台恢復整座聚落供電。

候選動作：supply_temporary_power、signal_power、lend。來源：old_world_emergency_service、gray_valley。

- 新希望：供應 low／需求 medium。巡水隊可借用作臨時通訊供電。
- 灰谷：供應 medium／需求 medium。能修小機構，但不取代固定供電。
- 乾井：供應 low／需求 high。遠程停靠點想要備援通訊電源。

- 中繼站只需要短時供電發出到站通知。 → 確認接口後由一人搖動供電，另一人操作通訊。 代價／限制：佔用人力和時間；沒有匹配接口便不可接入。
- 修理者想知道舊訊號燈是壞了還是沒電。 → 借發電機提供有限試驗電源。 代價／限制：輸出不合時拒絕測試，不會憑試機恢復全區供電。

維修：只在零件規格匹配時維護傳動與線路；輸出測試不可省。 候選投入：齒輪、軸承、銅線
拆解：只可能留下部分完好件；沒有重製整機的可逆等量關係。 候選產物：齒輪、軸承、銅線

前置缺口：disassembly、electronics、item_ownership、jobs、repair。研究：WG-03、WG-05。

<a id="content_hazmat_suit"></a>
## 防化服 · content_hazmat_suit

APPAREL / chemical_protective_suit｜2400 g｜參考估值 540 Caps｜rare。
估值理由：540 Caps 提案要求可檢驗完整，未計清理與配套呼吸器。
[既有圖片](../../../ui/assets/items/library/clothing/hazmat_suit.png)｜runtime ID：尚未註冊

透明面窗發黃，包裝上的檢驗日期已無法讀清。

**初見：** 密封接縫與面窗都要檢查，外觀不代表能抵禦所有污染。

**調查後可確認：** 化學防護衣候選；適用危害、呼吸裝備及使用期限尚待規則。

只作特定區域通行準備，不把 hazmat 標籤當萬能通行證。

候選動作：inspect_seams、prepare_controlled_entry。來源：old_world_laboratories、industrial_safety。

- 新希望：供應 none／需求 low。只在特定污染调查有需求。
- 灰谷：供應 low／需求 high。工業場址调查與安全作業需要合適防護。
- 乾井：供應 low／需求 medium。燃料設施事故處理可能需要，危害類型仍須確認。

- 舊實驗室門口列著不明危害標誌。 → 先比對防護衣適用範圍再規劃入內。 代價／限制：需 hazard identification 與完整配套，不能立即進門。
- 工坊準備接收用過的防護衣。 → 將可疑衣物隔離等待檢驗。 代價／限制：暫停穿用與出售，不能直接拆成乾淨布料。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：橡膠、塑膠
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：塑膠

前置缺口：equipment、hazards、exploration、identification、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、FICTION-WOOL。

<a id="content_heat_core"></a>
## 熱核 · content_heat_core

MISC / persistent_warm_object｜1150 g｜參考估值 None Caps｜rare。
估值理由：不按永續能源估值；熱工與烹煮設備研究者可能以測試條件提出交付協議。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/heat_core.png)｜runtime ID：尚未註冊

粗糙外殼附近的霧氣總先散開，找不到可開關的地方。

**初見：** 近處可量到持續溫熱；不知道可持續多久、是否會升溫或釋出其他物質。

**調查後可確認：** 可在隔離條件下記錄溫度與時間；尚未驗證為可接觸食物的熱源，也不等於可驅動機械。

候選用途有研究與有條件的保溫方向，重量與隔離運輸是負擔；不能生成無限燃料。

候選動作：measure_heat、isolate_container、plan_test_load。來源：sealed_thermal_chamber、anomalous_boiler_case、survey_locker。

- 新希望：供應 none／需求 medium。食品保存或烹煮工作可能提出研究需求，需先驗證接觸安全。
- 灰谷：供應 none／需求 high。熱工工坊可能具備量測與隔離空間。
- 乾井：供應 none／需求 high。煉製地對熱源有興趣，也需避免與燃料混放。

- 商隊想把熱核塞入裝有食物的保溫袋。 → 先要求隔離量測與獨立保管，再決定是否能使用。 代價／限制：需容器、重量與等待時間；不直接替全隊提供保溫。
- 工坊提出將熱核接到一個不完整的蒸汽裝置。 → 提供測試負載方案或保留樣本拒絕破壞性嘗試。 代價／限制：需設備、專門技術與明確風險權威；發熱不保證足夠功率或安全壓力。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、hazards、cargo、knowledge、electronics、regional_trade。研究：FICTION-ROADSIDE、WG-03。

<a id="content_heat_insulation_suit"></a>
## 隔熱服 · content_heat_insulation_suit

APPAREL / industrial_heatwear｜5200 g｜參考估值 470 Caps｜rare。
估值理由：470 Caps 提案包含少見多層材料，體積與重量形成代價。
[既有圖片](../../../ui/assets/items/library/clothing/heat_insulation_suit.png)｜runtime ID：尚未註冊

銀灰外層有幾處暗斑，內襯厚得不易摺好。

**初見：** 隔熱與防火不同；熱源、接觸時間和作業環境仍須確認。

**調查後可確認：** 工業隔熱衣，需要檢查反射層及內襯完整性。

允許提出短時設備檢查方案，不直接免除所有熱危害。

候選動作：inspect_heat_layers、prepare_hot_work。來源：gray_valley、foundries、old_world_industry。

- 新希望：供應 none／需求 low。只有特殊設備工作會委託取得。
- 灰谷：供應 low／需求 high。熔爐與高溫作業場有具體使用者。
- 乾井：供應 low／需求 medium。煉製設施維護需要先核對適用範圍。

- 停機後設備仍過熱無法近看。 → 請專業者評估衣物與等待時間。 代價／限制：可能仍需等冷卻，不用道具跳過作業安全條件。
- 過厚防護衣使狹窄通道難通過。 → 放棄穿入，改從外側觀察。 代價／限制：失去近距離調查機會，但不強迫傷害結果。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、鋁材
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、hazards、exploration、identification、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-04。

<a id="content_heavy_revolver"></a>
## 大口徑左輪 · content_heavy_revolver

WEAPON / large_frame_revolver｜1650 g｜參考估值 390 Caps｜rare。
估值理由：390 Caps 為小量流通與工坊支援的提案估值。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/heavy_revolver.png)｜runtime ID：尚未註冊

厚重槍框壓得舊槍袋歪向一邊。

**初見：** 重量與操控負擔明顯，補給不如普通舊槍容易。

**調查後可確認：** 大型轉輪槍，需專門匹配彈藥與維修部件。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

乾井少數護衛使用的重器材；並非每位新人都值得攜帶。

候選動作：verify_guard_loadout、negotiate_exchange。來源：dry_well、veteran_guards。

- 新希望：供應 none／需求 low。普通獵務不願負擔稀少補給。
- 灰谷：供應 low／需求 medium。專門槍匠有研究與維修需求。
- 乾井：供應 low／需求 high。特定長線護衛團能支援其補給。

- 護衛團只接受已檢驗的重器材。 → 委託乾井熟手核對裝備需求。 代價／限制：需時間與費用；不得用 FIREARMS rank 代替實物與彈藥。
- 旅人決定換回更輕的裝備。 → 與有需求的守衛談交換。 代價／限制：對方需真的持有可換物，不生成平價等值替代槍。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：鋼材、彈簧、精密零件
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_hiking_backpack"></a>
## 登山背包 · content_hiking_backpack

CONTAINER / framed_hiking_pack｜1900 g｜參考估值 145 Caps｜uncommon。
估值理由：145 Caps 提案反映完整支架與可調背帶。
[既有圖片](../../../ui/assets/items/library/clothing/hiking_backpack.png)｜runtime ID：尚未註冊

支架貼著舊山徑貼紙，腰帶仍有調整餘量。

**初見：** 支架可幫助整理負荷的構想，尺寸不合也會造成負擔。

**調查後可確認：** 空包1900 g，支架和承重帶需逐件檢查；不自帶已生效的高負重。

優勢應來自合身和行程需求，而非永遠比舊旅行包高一級。

候選動作：fit_pack_frame、balance_load。來源：old_world_outdoors、caravan_outfitters。

- 新希望：供應 low／需求 medium。山路採集者需要，但一般短途不一定值得。
- 灰谷：供應 medium／需求 medium。遺跡回收可取得，維修金屬架較方便。
- 乾井：供應 low／需求 high。長線旅人願意為合身與平衡付代價。

- 山路隊伍要在水與工具之間取捨。 → 先分配真實行李，再調整支架。 代價／限制：不增加補給或容量；體積、總重量仍待獨立規則。
- 二手包的支架已偏斜。 → 選擇送修或保留較輕舊包。 代價／限制：修理需工坊，不能用裝備切換立即恢復。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：鋁材、布料、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：鋁材、布料

前置缺口：equipment、cargo、exploration、navigation、item_ownership、regional_trade、repair、disassembly。研究：WG-02、WG-05。

<a id="content_hollow_stone"></a>
## 空心石 · content_hollow_stone

MISC / low_mass_mineral｜65 g｜參考估值 None Caps｜rare。
估值理由：沒有普遍市場估價；材料研究者與運輸工匠可能對量測結果提出特定委託。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/hollow_stone.png)｜runtime ID：尚未註冊

表面像密實石料，拿起時卻讓人錯估手中的重量。

**初見：** 相同大小的普通石塊較重；不知道裡面是否真的空心。

**調查後可確認：** 可比對質量與體積，但空腔、結構強度與成因需另外檢查；重量小不等於能承重或漂浮。

候選價值來自不尋常材料，而非取消所有貨物重量的魔法背包。

候選動作：compare_mass、secure_sample、inspect_structure。來源：rockfall_pocket、anomalous_quarry、survey_case。

- 新希望：供應 none／需求 low。農業工作沒有直接材料用途，除非有具體調查委託。
- 灰谷：供應 none／需求 high。材料工匠可能想確認是否為空腔或特殊結構。
- 乾井：供應 none／需求 medium。運輸者可能對輕質材料有興趣，但需強度證據。

- 礦坑秤臺把這塊石頭誤記成少交貨。 → 用已校準的秤與普通樣本做對照，保留稱量紀錄。 代價／限制：需要可靠量具與雙方見證；一次秤量不解釋成因。
- 工匠想把石塊切開作展示。 → 選擇保持原樣繼續量測，或先安排無損檢查。 代價／限制：切開可能破壞唯一樣本；沒有正式檢查規則時不承諾內部結構。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、knowledge、exploration、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_homecoming"></a>
## 回家 · content_homecoming

WEAPON / named_hunting_rifle｜3400 g｜參考估值 None Caps｜unique。
估值理由：特定尋物者可能提出交付條件，沒有全世界一致售價；槍的歷史比型號稀有度更重要。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/homecoming.png)｜runtime ID：尚未註冊

木托補過一道長裂痕，補片上用小字刻著一個方向。

**初見：** 是使用多年的獵槍，能看見補片與刻字；前主人的去向仍是傳聞。

**調查後可確認：** 可核對工匠補修記號與已存在的委託紀錄；刻字不是自動定位器，機械狀態需另檢。

候選故事圍繞失聯獵人的行程與熟人記憶；不保證持槍後每個居民都認得，也不生成前主人。

候選動作：compare_repair_marks、trace_route、return_rifle。來源：documented_personal_transfer、abandoned_named_cache。

- 新希望：供應 none／需求 high。特定獵戶或失物委託人可能認得木托修補。
- 灰谷：供應 none／需求 medium。舊修理工若已有相關人物紀錄，可能辨認工法。
- 乾井：供應 none／需求 low。一般商人只見到舊獵槍，私人來歷未必形成需求。

- 新希望的修理簿留下與木托補片相同的尺寸。 → 比對紀錄，找出最後一次可證實的維修時間。 代價／限制：需取得查簿同意；紀錄只證明維修，不證明前主人的當前位置。
- 一名旅人希望借槍護送補給，另有人正在尋找失物。 → 決定是否暫借、保留查證或安排當面交接。 代價／限制：需正式所有權與歸還條件；戰鬥另需裝備/彈藥權威，不能複製第二把槍。

維修：由適配工匠修理機械，保留木托補片的來源特徵。 候選投入：精密零件、彈簧
拆解：拆解不可逆地失去完整遺物；回收只作符號關係，不設套利產量。 候選產物：廢鐵、彈簧

前置缺口：item_ownership、equipment、combat_extension、identification、knowledge、npc_relationship、jobs、regional_trade、repair、disassembly。研究：LD-P02、FICTION-CANTICLE。

<a id="content_hospital_id_card"></a>
## 醫院識別卡 · content_hospital_id_card

MISC / medical_staff_identifier｜15 g｜參考估值 60 Caps｜rare。
估值理由：價值在醫療設施查檔與來源核對，不是偽造專業資格或現成的救治權限。
[既有圖片](../../../ui/assets/items/library/relics/hospital_id_card.png)｜runtime ID：尚未註冊

掛繩洗得褪色，照片旁邊貼著一小片補過的透明膠。

**初見：** 能看見部門縮寫與人名，可能是職員識別物；現行有效性未知。

**調查後可確認：** 可與舊醫院排班與領料紀錄比對，但不證明現任持有者懂醫療，也不保證附帶電子門禁。

候選內容是藥品出處與失物查證，避免把醫院標誌變成通用治療選項。

候選動作：compare_staff_record、trace_store_room、return_identifier。來源：clinic_archive、staff_locker、personal_effects。

- 新希望：供應 low／需求 high。地方診療工作可能需要追溯舊庫房與採購紀錄。
- 灰谷：供應 low／需求 medium。舊職員檔案與工傷紀錄可能相關。
- 乾井：供應 none／需求 medium。運藥委託會在意來源核實，但不承認過期牌證為醫師資格。

- 一批未標示藥箱只留下領料人縮寫。 → 比對識別卡與庫房簽領記錄，找出待核驗批次。 代價／限制：仍需藥物鑑定與醫療權威；核對姓名不能讓未知藥安全可用。
- 居民想找回曾在舊診所工作之人的物件。 → 以照片與部門紀錄查證後歸還。 代價／限制：需得到持有人同意並完成查證；不因相片相似建立新NPC。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、identification、npc_relationship、jobs、regional_trade。研究：FICTION-CANTICLE、WG-04。

<a id="content_humming_stone"></a>
## 鳴石 · content_humming_stone

MISC / electrically_responsive_mineral｜380 g｜參考估值 None Caps｜rare。
估值理由：沒有通用售價；灰谷電子研究者關心可重複聲響，其他買家需求取決於可驗證用途。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/humming_stone.png)｜runtime ID：尚未註冊

靠近某些舊電器時，它的細聲會從低鳴變成短促顫音。

**初見：** 曾在帶電設備附近出聲，但尚未排除震動或其他干擾。

**調查後可確認：** 對照測試可記錄與特定通電狀態的關聯；不能因此宣稱能定位所有電線或保證無害。

候選先用於調查線索，驗證後才可能有特定測試用途；不取代萬用電表所有功能。

候選動作：compare_hum、isolate_from_power、record_response。來源：substation_rubble、anomalous_rock_pocket、sealed_sample_box。

- 新希望：供應 none／需求 low。水閘設備有異音時才可能找研究協助。
- 灰谷：供應 none／需求 high。電子研究者願意接收有設備對照紀錄的樣本。
- 乾井：供應 none／需求 medium。燃料站操作員可能對設備異常提示感興趣，但需先查干擾。

- 變電棚斷電後仍聽到低鳴，居民以為有機器偷開。 → 依次隔離設備，比對石頭聲響與可測電源。 代價／限制：需安全隔離與時間；聲響不能單獨證明有人偷用能源。
- 商人想把鳴石當尋寶器宣傳。 → 提供已驗證範圍或拒絕誇大用途的交易。 代價／限制：較窄的說明可能降低買家興趣；未證實能力不寫入使用選項。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、identification、hazards、knowledge、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_hunting_fork"></a>
## 捕獸叉 · content_hunting_fork

WEAPON / animal_control_fork｜2700 g｜參考估值 80 Caps｜uncommon。
估值理由：80 Caps 提案反映專門用途而非較高戰力。
[既有圖片](../../../ui/assets/items/library/weapons/hunting_fork.png)｜runtime ID：尚未註冊

叉齒間纏著獸毛與舊網線，柄上的刻痕記著一次次修補。

**初見：** 用於已有網具旁的控制作業；不是單靠叉子就能捕到獵物。

**調查後可確認：** 雙齒捕獸器具，彎曲齒端會增加滑脫風險。

捕獸提案需動物與採集規則，不將現有野狗直接改成可重複養殖資源。

候選動作：hold_net_edge、retrieve_trap。來源：wilderness_hunters、new_hope。

- 新希望：供應 medium／需求 medium。獵戶與護田工作有使用者。
- 灰谷：供應 low／需求 low。城市廢墟內用途窄，收購多按金屬看待。
- 乾井：供應 low／需求 medium。商隊牲畜事故需要熟練者，器具供應稀少。

- 棄置陷阱纏住路邊的網。 → 保持距離挑起可見網緣檢查。 代價／限制：需辨識陷阱，不保證已解除機構。
- 有主牲畜跌進矮溝。 → 固定鬆網邊緣協助原飼主救援。 代價／限制：需要網與其他人，不能把動物算成免費獎勵。

維修：齒端與桿部需熟手檢查，不能任意校直後宣稱安全。 候選投入：鋼材、皮革
拆解：失去器具功能後回收叉頭。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、hazards、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：WG-01、WG-04。

<a id="content_hunting_knife"></a>
## 獵刀 · content_hunting_knife

WEAPON / hunting_blade｜400 g｜參考估值 72 Caps｜uncommon。
估值理由：72 Caps 為完整刀鞘和專用刃具的提案價；400 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/hunting_knife.png)｜runtime ID：hunting_knife

磨薄的刃口旁留著深色水痕，皮鞘反覆補過線。

**初見：** 比家用小刀更便於攜帶和清理獵物，仍需知道如何使用。

**調查後可確認：** 有護手的固定刃獵刀；刃口完整度與鞘帶是否牢靠要分開檢查。

新希望的獵人會交換磨刀經驗，不把持刀等同於狩獵能力。

候選動作：dress_game、cut_brush、inspect_hide。來源：new_hope、hunters。

- 新希望：供應 medium／需求 high。處理獵物與野外工作有穩定需求。
- 灰谷：供應 low／需求 medium。收皮革的工人會買，但不是每間廢料店都收。
- 乾井：供應 low／需求 medium。遠行者需要可靠短刃，補鞘服務較少。

- 一隻已死亡的野獸堵在山徑。 → 在懂得處理獵物時收集可用皮料。 代價／限制：需要生存知識與時間；來源、腐敗和採集規則仍待定。
- 農戶的皮帶卡在灌木中。 → 切開枝條保留皮帶完整。 代價／限制：需近身作業且耗時，無法清除整片荊棘。

維修：皮鞘與刃身分別維修；不因一次磨刃恢復所有損壞。 候選投入：皮革、鋼材
拆解：拆毁後只保留可用金屬與鞘皮，品質與產率另定。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、hazards、cooking、item_ownership、regional_trade、repair、disassembly。研究：WG-01、LD-P01。

<a id="content_identity_document"></a>
## 身分證件 · content_identity_document

MISC / civil_identity_paper｜25 g｜參考估值 35 Caps｜uncommon。
估值理由：估值只反映保存與查證工作；證件不作可自由販售的現行通行權。
[既有圖片](../../../ui/assets/items/library/relics/identity_document.png)｜runtime ID：尚未註冊

塑封邊緣重新燙過，照片下方的舊住址仍未被刮掉。

**初見：** 能看見姓名、照片與局部編號；有效期限和現行承認範圍都未知。

**調查後可確認：** 這是舊制度留下的身分紀錄，可與其他檔案比對；持有者不是自動成為文件所指的人。

候選任務由已有的人口代表提出尋物或查檔；不能用證件為世界生成另一個具名個體。

候選動作：verify_record、compare_signature、return_document。來源：personal_effects、office_archive、lost_luggage。

- 新希望：供應 low／需求 medium。安置與尋親工作可能需要查證舊住址，證件本身沒有供給功能。
- 灰谷：供應 medium／需求 medium。舊工務檔案較多，登記員可能協助核對編號。
- 乾井：供應 low／需求 low。商隊較重現行見證，不把過期證件當保證書。

- 寄存櫃領取人姓名相同，簽字卻不同。 → 提供證件作交叉查證材料。 代價／限制：需核對獨立紀錄與持有人同意；證件不直接打開寄存櫃。
- 收容點只有一筆模糊的舊住址。 → 比對文件地址與既有住民紀錄，縮小查詢範圍。 代價／限制：耗費查檔時間；沒有匹配就明確記錄未找到，不生成家屬。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、knowledge、npc_relationship、jobs、regional_trade。研究：FICTION-CANTICLE、FICTION-WOOL。

<a id="content_improvised_pistol"></a>
## 土製手槍 · content_improvised_pistol

WEAPON / workshop_sidearm｜1250 g｜參考估值 90 Caps｜common。
估值理由：90 Caps 提案扣除了檢驗與不確定性成本。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/improvised_pistol.png)｜runtime ID：尚未註冊

不同顏色的零件拼在一起，工坊記號比型號醒目。

**初見：** 便宜但必須先檢驗；看似可扣動不代表適合使用。

**調查後可確認：** 地方拼裝短槍，個體間零件未必互通。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

灰谷可找得到原工匠，是它相對於陌生制式槍的服務優勢。

候選動作：request_workshop_inspection、return_batch。來源：gray_valley、local_workshops。

- 新希望：供應 low／需求 low。農戶不願為廉價器材承擔未知安全風險。
- 灰谷：供應 high／需求 medium。本地工坊提供來源與售後線索。
- 乾井：供應 low／需求 low。無法找到製作者時收購意願低。

- 便宜護衛裝備引發貨主疑慮。 → 請原工坊提供檢查與責任說明。 代價／限制：付出檢查時間與費用；檢查不保證護衛任務獲准。
- 工匠希望收回問題批次。 → 依記號將器材交回。 代價／限制：放棄使用或出售機會，補償先另行協商。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：鋼材、彈簧
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_industrial_nailgun"></a>
## 工業釘槍 · content_industrial_nailgun

TOOL / industrial_fastener_tool｜3100 g｜參考估值 205 Caps｜uncommon。
估值理由：205 Caps 提案反映可檢修工具；能源與釘料成本另列。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/industrial_nailgun.png)｜runtime ID：尚未註冊

黃色外殼褪成土色，工班用紅線圈出一處舊裂痕。

**初見：** 原為緊固工具，需要匹配能源與耗材；不是自由彈藥武器。

**調查後可確認：** 工業釘具的工作頭和能源接口都須檢驗。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

以工程需求為主要流通理由，是否可作戰留到 combat_extension。

候選動作：inspect_fastener_system、perform_workshop_job。來源：gray_valley、construction_sites。

- 新希望：供應 low／需求 medium。修繕棚舍有需求，但能源限制採用。
- 灰谷：供應 medium／需求 high。工坊可識別配套工具並提供檢修。
- 乾井：供應 low／需求 medium。貨箱修繕需要，但必須先運入相容耗材。

- 貨箱工坊趕修破損包裝。 → 確認匹配耗材後承接緊固工作。 代價／限制：需作業權與工坊條件，不直接從持有釘槍生成箱子。
- 遺跡出土一批同型工具。 → 挑選可送檢樣本交給工班。 代價／限制：樣本需移交；不能把工具全當可射擊武器出售。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、橡膠
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_jack"></a>
## 千斤頂 · content_jack

TOOL / mechanical_lifting_jack｜6000 g｜參考估值 90 Caps｜uncommon。
估值理由：90 Caps 取救急用途，沉重使帶它上路本身就是選擇。
[既有圖片](../../../ui/assets/items/library/supplies/jack.png)｜runtime ID：尚未註冊

低矮的金屬頂座上刻著磨損的承載標記。

**初見：** 六千克的重工具；承載限制和支撐地面都要確認。

**調查後可確認：** 可抬起符合條件的車軸或構件，不能代替固定支撐與安全判斷。

乾井車隊需要時很急，平時卻不一定每個旅人都願意背。

候選動作：raise_axle、prop_frame、lend。來源：gray_valley、dry_well。

- 新希望：供應 low／需求 medium。農車故障時有需求，平時少備。
- 灰谷：供應 high／需求 medium。車輛拆解來源多。
- 乾井：供應 medium／需求 high。運油貨車常需道路救援。

- 貨車輪陷進淺坑，司機想徒手抬軸。 → 核對頂點與地面，提出抬起一側的救援方案。 代價／限制：需要支撐和助手，鬆土或超載時不可用。
- 工地木架壓住了一只私人物件盒。 → 由懂結構的人判斷能否用千斤頂留出取物空間。 代價／限制：重物移動可能破壞支架；工具不免除結構檢查。

維修：受力件需專業檢查與匹配更換，無法驗證承載時保持不可用。 候選投入：鋼材、齒輪
拆解：報廢後只作金屬來源，不把受力件自動認證為別的承載工具。 候選產物：廢鐵

前置缺口：cargo、disassembly、exploration、hazards、item_ownership、repair。研究：WG-01、WG-03。

<a id="content_jerky"></a>
## 肉乾 · content_jerky

CONSUMABLE / dried_meat｜200 g｜參考估值 16 Caps｜common。
估值理由：16 Caps 包含肉料與保存工序，單位較小而運送方便。
[既有圖片](../../../ui/assets/items/library/supplies/jerky.png)｜runtime ID：尚未註冊

煙燻肉條上仍繫著製作者用的細繩記號。

**初見：** 單位是兩百克一包，不保證受潮後仍可保存。

**調查後可確認：** 來源、氣味與封裝檢查後，可選作輕便肉食；鹹味不能代替飲水。

新希望的獵人偶爾供貨，獵獲不穩時不應固定無限上架。

候選動作：eat、share、exchange。來源：new_hope、hunters。

- 新希望：供應 medium／需求 medium。獵人有不定期供貨，並非農產固定產量。
- 灰谷：供應 low／需求 medium。值班工人接受耐攜肉食。
- 乾井：供應 low／需求 high。長途貨運偏好輕便補給。

- 獵人不想讓陌生人碰剛切好的肉。 → 拿可辨認製作者的肉乾作交換物，談一段帶路服務。 代價／限制：對方仍可拒絕；沒有信任便不能強制成交。
- 貨隊希望夜間少升一次火。 → 留下肉乾作不需現場烹調的晚餐候選。 代價／限制：仍需檢查可食狀態，也不能省掉飲水需求。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、item_ownership、regional_trade。研究：FICTION-ROAD、WG-02。

<a id="content_last_round"></a>
## 最後一發 · content_last_round

WEAPON / named_revolver｜1020 g｜參考估值 None Caps｜unique。
估值理由：唯一物件不設普遍售價；需要查明來源、持有權與特定買家目的後才談交付。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/last_round.png)｜runtime ID：尚未註冊

彈巢旁刻了六個名字，其中一個字曾被反覆描深。

**初見：** 是一把老式左輪，刻名可讀；不知道刻名者與槍的歷史，也未確認機械安全。

**調查後可確認：** 可確認口徑與機械狀態，名字只在獨立紀錄核對後才成為已知人物關係；不因名稱保證最後一發更強。

候選定位是有歷史的普通武器，唯一性由實例與來源決定；不從隨機箱子重複掉落。

候選動作：inspect_inscription、trace_ownership、entrust_revolver。來源：named_estate_locker、documented_personal_transfer。

- 新希望：供應 none／需求 low。只有與刻名或遺物交還有關的人可能提出請求。
- 灰谷：供應 none／需求 medium。工匠可能願意檢驗機械，收藏者也需先看出處。
- 乾井：供應 none／需求 high。護送往事中的特定關係人可能尋找此槍，並非固定高價收購。

- 酒館有人認得其中一個刻名，卻說另一個名字被拼錯。 → 帶槍與獨立文書核對，查清刻字的先後。 代價／限制：需尋訪時間與當事人同意；認得一個名字不證明擁有此槍。
- 護衛需要臨時武器，遺物保管人不願再讓它開火。 → 選擇保留為證物或在合法所有權下另行使用。 代價／限制：戰鬥用途需裝備、彈藥與機械檢查規則；使用可能影響保存承諾，沒有傳說傷害加成。

維修：僅檢修可識別的機械件並保留刻字；修理不增加傳說屬性。 候選投入：彈簧、精密零件
拆解：拆解會永久失去完整武器與遺物用途，須有明確毀損確認；不會產出另一把最後一發。 候選產物：廢鐵、彈簧

前置缺口：item_ownership、equipment、combat_extension、identification、npc_relationship、reputation、regional_trade、repair、disassembly。研究：FICTION-CANTICLE、WG-04。

<a id="content_leather"></a>
## 皮革 · content_leather

MISC / tanned_leather｜600 g｜參考估值 24 Caps｜uncommon。
估值理由：24 Caps 包含處理與可用面積的價值，並非生皮直接等價。
[既有圖片](../../../ui/assets/items/library/supplies/leather.png)｜runtime ID：尚未註冊

鞣過的皮料摺起時較硬，邊角仍留著針孔。

**初見：** 一份六百克皮料，完整面積和厚度決定能裁什麼。

**調查後可確認：** 適合部分背帶、護套與包具修補，不能保證任何皮甲等級。

狩獵來源連到新希望的皮件工人，乾井車隊需要耐磨綁帶。

候選動作：cut_strap、patch_bag、deliver_material。來源：new_hope、hunters。

- 新希望：供應 medium／需求 medium。獵人與皮件工人形成小規模來源。
- 灰谷：供應 low／需求 medium。工具護套與腰帶需要。
- 乾井：供應 low／需求 high。綁帶和行囊耐磨部位常要修補。

- 舊旅行包的肩帶斷在縫線旁。 → 用皮料裁一段合適背帶補強。 代價／限制：需技術與縫合工具；修好不增加背包原本承載能力。
- 乾井收貨者只要能裁長帶的整片。 → 攤開皮料讓對方確認可用範圍。 代價／限制：孔洞與裂口會降低可交付面積，不能按總重湊數。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、item_ownership、regional_trade、repair。研究：WG-01、WG-02。

<a id="content_light_machine_gun"></a>
## 輕機槍 · content_light_machine_gun

WEAPON / support_weapon｜8400 g｜參考估值 1250 Caps｜rare。
估值理由：1250 Caps 提案反映稀少完整機件，保管與長程運輸另付成本。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/light_machine_gun.png)｜runtime ID：尚未註冊

長箱內還有專用架的空位，器材重得不像私人行李。

**初見：** 需要隊伍後勤、匹配補給與運輸，個人能背不等於適合帶。

**調查後可確認：** 支援型槍械，缺失配套需先確認。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

作為聚落或商隊資產形成去向抉擇，不是到手即橫掃的獎勵。

候選動作：evaluate_logistics、record_recovery_site。來源：military_depots、retired_convoys。

- 新希望：供應 none／需求 low。僅特定防衛委託可能需要，無一般採購量。
- 灰谷：供應 low／需求 medium。大工坊能安排檢驗與重物搬運。
- 乾井：供應 none／需求 medium。護運組織考慮整套後勤才會接受。

- 兩支護運隊都想取得唯一的支援器材。 → 要求雙方提出保管與補給方案再決定。 代價／限制：必須將所有權交給一方，不能兩隊同時受益。
- 廢軍庫的重箱擋住人員撤出。 → 選擇放棄搬運並記錄位置。 代價／限制：失去即時占有，後續回收需獨立運輸計畫。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、鋼材

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_lighter"></a>
## 打火機 · content_lighter

TOOL / refillable_lighter｜90 g｜參考估值 24 Caps｜common。
估值理由：24 Caps 高於火柴，交換的是可維護性而非無耗材點火。
[既有圖片](../../../ui/assets/items/library/supplies/lighter.png)｜runtime ID：尚未註冊

黃銅外殼的打火機，底部有可旋開的補充口。

**初見：** 目前是否有燃料需要檢查，不隨取得自動補滿。

**調查後可確認：** 可重複補充但需要相容燃料與完好的點火機構。

灰谷攤販可修外殼與機構，補充燃料仍有自己的來源。

候選動作：ignite、refill、lend。來源：gray_valley、caravan。

- 新希望：供應 medium／需求 medium。重用方便，但居民也有固定灶火。
- 灰谷：供應 high／需求 medium。外殼維修和舊貨拆件較方便。
- 乾井：供應 medium／需求 high。能補相容燃料的旅人偏好重用器具。

- 路旁有人有乾柴，卻一直點不著火。 → 借出經檢查有燃料的打火機。 代價／限制：需回收器具，燃料消耗不會免費恢復。
- 灰谷攤販想用一盒火柴換走壞打火機。 → 請他指出故障，決定交換或保留給修理者。 代價／限制：檢查只能提供資訊，不能憑對話直接修好。

維修：只處理匹配的小機構與外殼；加燃料是補充，不算免費修理。 候選投入：彈簧、廢鐵
拆解：安全清空後可能留下少量可用機構；不等於足以重製完整打火機。 候選產物：彈簧、廢鐵

前置缺口：camping、cooking、disassembly、hazards、item_ownership、repair。研究：WG-01、WG-05。

<a id="content_liquor"></a>
## 酒 · content_liquor

CONSUMABLE / labelled_drink_bottle｜750 g｜參考估值 28 Caps｜uncommon。
估值理由：28 Caps 以地方成品和運送重量估價，非戰鬥增益。
[既有圖片](../../../ui/assets/items/library/supplies/liquor.png)｜runtime ID：尚未註冊

玻璃酒瓶有地方釀造者的手寫牌記。

**初見：** 一瓶飲用品；用途與品質需核對，不能充當醫療消毒品。

**調查後可確認：** 已辨明可飲的批次可供聚會或交易，開瓶後整瓶收藏價值改變。

新希望有季節性小批釀造，乾井更在乎貨能否完整送到。

候選動作：exchange、serve、deliver。來源：new_hope、caravan。

- 新希望：供應 medium／需求 medium。季節性釀造與聚會需求並存。
- 灰谷：供應 low／需求 medium。工班聚餐時下單，非日常必需。
- 乾井：供應 low／需求 medium。旅店與特定買家需要完整瓶裝貨。

- 聚落要為返回的工隊準備一頓飯。 → 交付一瓶來源清楚的酒給主辦者。 代價／限制：失去整瓶；慶祝是否舉行仍由事件條件決定。
- 商人想把標籤不明的烈性液體當酒出售。 → 要求核對來源，不能確認便拒絕交易。 代價／限制：放棄便宜貨，不把工業液體改名成可飲品。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：item_ownership、jobs、npc_relationship、regional_trade。研究：WG-02、LD-P01。

<a id="content_lockpick_set"></a>
## 開鎖工具 · content_lockpick_set

TOOL / mechanical_lockpick_set｜180 g｜參考估值 65 Caps｜uncommon。
估值理由：65 Caps 來自精細形狀與難以隨地補造，並非保證開鎖成功。
[既有圖片](../../../ui/assets/items/library/supplies/lockpick_set.png)｜runtime ID：尚未註冊

細工具收在皮套裡，各自有不同彎曲形狀。

**初見：** 只針對合適的機械鎖；電子門和焊死的蓋板另有條件。

**調查後可確認：** 先檢查鎖型與所有權，再提出操作方案；失敗可能損壞工具或留下痕跡。

灰谷鎖匠會要來源證明，拿著工具不代表有權打開別人的箱子。

候選動作：inspect_lock、manipulate_lock、lend。來源：gray_valley、caravan。

- 新希望：供應 low／需求 low。鎖匠有合理用途，普通商店不囤。
- 灰谷：供應 medium／需求 medium。舊機械鎖多，合法回收與維修可用。
- 乾井：供應 low／需求 medium。貨運封箱與失鑰情況需要專門服務。

- 回收隊找到一只刻有私人姓名的鎖箱。 → 先尋找所有者或授權，再嘗試合適機械鎖。 代價／限制：工具不能取代所有權，未獲同意會有關係後果。
- 驛站鑰匙斷在儲物櫃裡，管理者等著取帳本。 → 檢查鎖型並提出非破壞開啟方案。 代價／限制：需技能、時間和工具狀況；焊死或電子鎖不適用。

維修：工匠可重整護套與特定形狀工具；折斷細件不保證可接回。 候選投入：鋼材、皮革
拆解：細件報廢時只回收殘料，不將剪裁護套當完整新皮料。 候選產物：廢鐵、皮革

前置缺口：disassembly、exploration、item_ownership、npc_relationship、repair、reputation。研究：WG-01、WG-04。

<a id="content_machine_pistol"></a>
## 衝鋒手槍 · content_machine_pistol

WEAPON / automatic_sidearm｜1450 g｜參考估值 470 Caps｜rare。
估值理由：470 Caps 提案來自罕見機件，未包含任何額外彈藥。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/machine_pistol.png)｜runtime ID：尚未註冊

額外的握持配件與短槍身擠在同一只盒內。

**初見：** 耗用補給的方式不同於普通手槍；缺少配件時更難管理。

**調查後可確認：** 舊自動短槍，射擊方式與安全操作需未來戰鬥系統定義。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

不靠「自動」二字保證優勢；維修、彈藥和使用者經驗都限制去向。

候選動作：catalogue_weapon_type、request_compatibility_check。來源：old_world_security、military_depots。

- 新希望：供應 none／需求 low。維護與補給能力不足，只有委託回收需求。
- 灰谷：供應 low／需求 medium。電子與機械回收者會評估部件價值。
- 乾井：供應 low／需求 medium。只有準備充足的護衛隊願意負擔。

- 舊守衛庫提供器材但沒有補給。 → 先記錄型號，再尋找可支援的工坊。 代價／限制：取得物品不代表獲得可射擊的裝備。
- 買家把外形相似的零件當成通用。 → 拒絕保證相容，送交專業檢驗。 代價／限制：需檢驗時間；不得把兩件不合零件變成有效新武器。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_matches"></a>
## 火柴 · content_matches

CONSUMABLE / matchbox｜30 g｜參考估值 6 Caps｜common。
估值理由：6 Caps 便宜且輕，價值在乾燥時可立即使用。
[既有圖片](../../../ui/assets/items/library/supplies/matches.png)｜runtime ID：尚未註冊

小紙盒裡的火柴用蠟紙隔著潮氣。

**初見：** 單位是一盒；受潮與盒側磨損都可能讓它失去用途。

**調查後可確認：** 可提供有限次點火嘗試，仍需要適合燃物與允許生火的環境。

雨後驛站收購的是乾燥批次，不是圖示上看起來相同的所有盒子。

候選動作：ignite、share。來源：settlement_workshop、caravan。

- 新希望：供應 medium／需求 medium。廚房與旅行者都要乾燥火種。
- 灰谷：供應 medium／需求 medium。工棚可供應，潮濕貨不收。
- 乾井：供應 low／需求 high。野外停靠點缺乾燥補充品。

- 雨後營地的引火盒全部濕掉。 → 拿出乾燥火柴協助點燃合適火種。 代價／限制：使用會消耗火柴；若無乾燃物，點火條件仍未滿足。
- 哨棚請求一盒備用火種，卻靠近燃料裝卸區。 → 把火柴封存交給管理者，改在指定安全區使用。 代價／限制：交付不等於允許任何地方點火，需遵守現場限制。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：camping、cooking、hazards、item_ownership。研究：WG-01、FICTION-ROAD。

<a id="content_mechanical_parts"></a>
## 機械零件 · content_mechanical_parts

MISC / mechanical_parts_family｜None g｜參考估值 None Caps｜category。
估值理由：沒有獨立物理單位與底價，不能和已列零件重複計入庫存。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/supplies/mechanical_parts.png)｜runtime ID：尚未註冊

此圖彙整齒輪、軸承等機械件的目錄視覺。

**初見：** 它不是一箱能修任何設備的通用零件。

**調查後可確認：** 維修委託要落到具體型號、零件和數量，分類圖只作索引。

地區工業特色可在這個分類下整理，但實際供需仍需逐件決定。

候選動作：。來源：editorial_catalogue。

- 新希望：供應 none／需求 none。農具需求要列齒輪、軸承等指定件。
- 灰谷：供應 none／需求 none。工業概況可用分類，庫存與價格仍按實物。
- 乾井：供應 none／需求 none。泵站委託不能用泛稱零件充數。

- 維修委託只有一張零件分類圖。 → 由設計者補出設備型號與實際缺件。 代價／限制：分類圖不轉成萬用修理材料，也不新增重複 item ID。
- 灰谷庫存報表把齒輪和軸承重複算進零件總箱。 → 保留分類統計但從可交易庫存去掉重複總項。 代價／限制：只有具體物件參與數量，分類摘要不可另當獎勵。

維修：分類摘要沒有可修理或拆解的實體。 候選投入：無
拆解：分類摘要沒有可修理或拆解的實體。 候選產物：無

前置缺口：item_ownership、regional_trade、repair。研究：WG-01、WG-03。

<a id="content_medical_manual"></a>
## 醫療手冊 · content_medical_manual

MISC / clinical_reference｜850 g｜參考估值 180 Caps｜rare。
估值理由：完整且可辨識版本的參考資料對合格照護者有用；不能把讀物視作藥物或即時醫療能力。
[既有圖片](../../../ui/assets/items/library/relics/medical_manual.png)｜runtime ID：尚未註冊

書頁間夾著數張不一致的領料表，封底留下反覆消毒的水痕。

**初見：** 可見症狀表、圖示與筆記，不知道哪些內容已過時或不適合目前環境。

**調查後可確認：** 可辨識編纂目的及附錄缺失；具體照護需要專業判斷、用品與正式傷病規則。

候選用途聚焦查證、整理用品與協助診療工作，不在描述裡寫治療量或確診結果。

候選動作：check_reference、compare_supply_list、consult_with_medic。來源：clinic_archive、training_room、medical_locker。

- 新希望：供應 low／需求 high。地方照護者缺少可核對的參考資料。
- 灰谷：供應 low／需求 medium。工傷照護與藥品整理可能需要特定章節。
- 乾井：供應 none／需求 high。長途醫療補給工作可能需要清楚版本與適用範圍。

- 診所收到一批外盒縮寫難辨的舊用品。 → 和照護者一起核對手冊的用品索引，分出需要另查的項目。 代價／限制：需要專業者與時間；紙上對照不能證明藥物未變質。
- 商隊準備運送醫療箱卻漏列基本耗材。 → 依委託用途比對清單，指出缺項給雇主決定。 代價／限制：只完成清單工作，不生成耗材；療效與補給交付需別的系統。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、identification、injury、jobs、regional_trade。研究：FICTION-CANTICLE、WG-01。

<a id="content_medical_satchel"></a>
## 醫療袋 · content_medical_satchel

CONTAINER / medical_organizer_bag｜850 g｜參考估值 100 Caps｜uncommon。
估值理由：100 Caps 提案反映可清理隔層和分類需求。
[既有圖片](../../../ui/assets/items/library/clothing/medical_satchel.png)｜runtime ID：尚未註冊

袋內隔層洗得比外布乾淨，每格都縫著空白標籤。

**初見：** 便於整理醫療用品，空袋不能治療或代表持有人是醫生。

**調查後可確認：** 850 g 為空袋；清潔、醫療耗材和醫療能力需要分開記錄。

醫疗身份與用品權限都不能從布袋圖案推得。

候選動作：sort_medical_supplies、protect_labels。來源：settlement_clinics、caravan_medics。

- 新希望：供應 low／需求 high。偏遠診療需要整理少量補給。
- 灰谷：供應 medium／需求 medium。工傷照護點可能維修或交換袋具。
- 乾井：供應 low／需求 high。遠行醫護需要可識別用品的攜具。

- 診所收到標籤混亂的用品。 → 用空隔層暫存已辨識品項。 代價／限制：需醫護核對，袋子不自動鑑定藥物或清除污染。
- 旅人要求借醫療袋去裝燃料配件。 → 選擇拒絕或接受用途變更。 代價／限制：混裝後不能宣稱仍適合直接放醫療用品。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、cargo、injury、identification、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-01、FICTION-ROAD。

<a id="content_medicines"></a>
## 藥物 · content_medicines

MISC / medicine_family｜None g｜參考估值 None Caps｜category。
估值理由：分類沒有重量和價格；需求分析須回到具體醫療品。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/supplies/medicines.png)｜runtime ID：尚未註冊

此圖概括醫藥用品家族，展示用途多樣的封裝。

**初見：** 它不是一件額外通用藥，不可替代急救包或抗生素。

**調查後可確認：** 必須指向已辨識的具體品項，才可討論交付與醫療條件。

診所的缺貨清單要保留品名和批次，不用泛稱掩蓋無法供應的項目。

候選動作：。來源：editorial_catalogue。

- 新希望：供應 none／需求 none。診所的需求應分別記在具體用品。
- 灰谷：供應 none／需求 none。分類彙整不等於存在通用醫藥庫存。
- 乾井：供應 none／需求 none。運送委託需要品項，不能交一個醫藥圖示。

- 診所需求板只寫著需要藥物。 → 把泛稱拆成已有具體用品與需要辨識的未知項。 代價／限制：分類本身不可交付，不會完成醫療工作。
- 商人想用一箱不明瓶子履行醫療採買。 → 要求按品項與批次重列清單。 代價／限制：沒有具體來源與醫療條件，不承諾用途或收貨。

維修：分類摘要沒有可修理或拆解的實體。 候選投入：無
拆解：分類摘要沒有可修理或拆解的實體。 候選產物：無

前置缺口：injury、item_ownership、regional_trade。研究：WG-02、FICTION-ROAD。

<a id="content_memory_core"></a>
## 記憶核心 · content_memory_core

MISC / archival_computing_core｜480 g｜參考估值 680 Caps｜rare。
估值理由：完整接口與可驗證資料區有研究價值；未知檔案內容不預先估為萬用知識寶庫。
[既有圖片](../../../ui/assets/items/library/relics/memory_core.png)｜runtime ID：尚未註冊

冷卻片間塞著一小張紙，上面只有一個被反覆圈起的編號。

**初見：** 核心未供電，編號與接頭能看見，資料是否仍在無法確定。

**調查後可確認：** 它保存設備資料而非可直接轉給人的完整記憶；能讀到的區塊與錯誤區必須分開。

候選內容可以通向設備史、研究紀錄或殘缺維修圖；不給讀取者即時技能加成。

候選動作：inspect_bus、read_verified_blocks、compare_archive。來源：sealed_server_case、research_archive、decommissioned_control_room。

- 新希望：供應 none／需求 medium。公共設備調查有可能需要舊資料，但無常備讀取設備。
- 灰谷：供應 low／需求 high。電子研究與控制設備維護對相容核心有需求。
- 乾井：供應 none／需求 medium。燃料批次與管線資料若可讀才有特定用途。

- 控制室終端只報出一個缺失的設備編號。 → 對照核心可讀索引，找到對應機型的文檔名稱。 代價／限制：需相容總線與讀取時間；查到名稱不等於取得完整修復步驟。
- 兩位買家分別要資料與硬體。 → 先確認可合法備份的區塊，再決定核心去向。 代價／限制：備份需要媒體、驗證與所有人同意；不能把複製當成無限複製獨特物。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、knowledge、identification、jobs、regional_trade。研究：FICTION-CANTICLE、WG-03。

<a id="content_metal_detector"></a>
## 金屬探測器 · content_metal_detector

TOOL / portable_metal_detector｜1800 g｜參考估值 150 Caps｜rare。
估值理由：150 Caps 來自專門探查用途；不保證發現高價物。
[既有圖片](../../../ui/assets/items/library/supplies/metal_detector.png)｜runtime ID：尚未註冊

細長探桿末端繞著線圈，控制盒保留手寫刻線。

**初見：** 它找的是金屬訊號，不是寶物名稱或埋藏物安全性。

**調查後可確認：** 經供電與校驗後可縮小搜尋區，雜鐵和地形仍會干擾。

灰谷廢料密集處反而可能難用，在較乾淨土層才能問清楚特定問題。

候選動作：survey_ground、locate_metal、mark_search_area。來源：old_world_security、gray_valley。

- 新希望：供應 none／需求 medium。可找埋入田間的金屬，但要有人解讀。
- 灰谷：供應 low／需求 medium。有維護條件，廢料多也會造成干擾。
- 乾井：供應 none／需求 medium。荒地勘查隊偶爾提出指定委託。

- 農田邊有一小段地每次耕作都撞上硬物。 → 用探測器縮小可能的金屬範圍，再標記給地主。 代價／限制：消耗能源，訊號不保證是可挖的安全廢鐵。
- 旅人遺失的金屬扣混在廢料坡。 → 先圈出較小搜尋區逐段比對。 代價／限制：廢鐵干擾多，需要時間，不能直接定位任意寶物。

維修：對應型號才可更換線圈或控制板，修後要以已知物校驗。 候選投入：銅線、電路板
拆解：拆取部分線圈線材與外殼，偵測功能消失。 候選產物：銅線、塑膠

前置缺口：disassembly、electronics、exploration、hazards、identification、item_ownership、repair。研究：WG-06、WG-01。

<a id="content_military_backpack"></a>
## 軍用背包 · content_military_backpack

CONTAINER / field_supply_pack｜2400 g｜參考估值 220 Caps｜uncommon。
估值理由：220 Caps 提案包含完好扣具與厚實布料。
[既有圖片](../../../ui/assets/items/library/clothing/military_backpack.png)｜runtime ID：尚未註冊

多個外袋的扣件不盡相同，內側有褪色的點收印。

**初見：** 口袋多方便分類，但總攜重與可用空間仍需規則。

**調查後可確認：** 空軍用包，不包含醫藥、武器或額外補給。

軍用出身提供來源故事，並非持有即得到免費工具套組。

候選動作：inventory_pouches、preserve_unit_marks。來源：military_surplus、old_world_depots。

- 新希望：供應 none／需求 medium。長程搬運者需要，普通農務嫌重。
- 灰谷：供應 low／需求 high。能處理扣具與厚布的工坊有市場。
- 乾井：供應 low／需求 high。商隊重視耐用外袋，仍需逐包檢查。

- 出土軍包外袋被誤認仍有醫療用品。 → 逐袋清點，明確記錄實際空缺。 代價／限制：只記錄已存在內容，不生成完整軍用套裝。
- 收藏者想買走內側點收印。 → 選擇保留整包或同意破壞取樣。 代價／限制：拆除印記會損及來源證據與袋布。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、皮革、精密零件
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料、皮革

前置缺口：equipment、cargo、knowledge、identification、item_ownership、regional_trade、repair、disassembly。研究：WG-03、FICTION-CANTICLE。

<a id="content_military_dog_tags"></a>
## 軍人識別牌 · content_military_dog_tags

MISC / service_identification｜45 g｜參考估值 40 Caps｜uncommon。
估值理由：金屬本身不值高價，價值取決於可查證的服役紀錄或收回遺物的特定委託。
[既有圖片](../../../ui/assets/items/library/relics/military_dog_tags.png)｜runtime ID：尚未註冊

兩片牌子的磨損程度不同，中間的鏈節像被人換成了細鐵絲。

**初見：** 有編號與血型字樣，沒有足以確認現任持有人身分的證據。

**調查後可確認：** 編號格式可對應某批舊紀錄；仍須核對名冊，不能由識別牌推定死亡或軍事權限。

候選定位為遺物交還與舊哨站調查，不做軍階裝備加成或免費守衛通行。

候選動作：read_service_mark、return_effects、compare_roster。來源：old_checkpoint、personal_effects、military_locker。

- 新希望：供應 low／需求 medium。特定家庭可能希望收回已查證的遺物。
- 灰谷：供應 low／需求 medium。檔案整理者可能把牌號與工業守備紀錄對照。
- 乾井：供應 low／需求 high。舊井守備故事與退伍旅人可能形成具名委託，非普遍收購。

- 舊哨站名冊缺了一頁，箱中卻有一塊識別牌。 → 將牌號與不同日期的值班紀錄交叉核對。 代價／限制：需要名冊或見證者，只有識別牌不宣布某人曾在場。
- 路邊紀念牌上有相同編號。 → 查證後將遺物交還給管理紀念地的人。 代價／限制：需放棄原物；回報可以是歷史資訊，不保證金錢或好感獎勵。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：熔解會永久失去牌號與交還用途；材料產量待拆解契約，不當高收益來源。 候選產物：廢鐵

前置缺口：item_ownership、identification、knowledge、npc_relationship、jobs、regional_trade、disassembly。研究：FICTION-CANTICLE、LD-P02。

<a id="content_military_manual"></a>
## 軍用手冊 · content_military_manual

MISC / field_procedure_reference｜540 g｜參考估值 110 Caps｜uncommon。
估值理由：價值在可理解的程序與舊地圖註記；年代過舊或器材不同時不能直接套用戰術。
[既有圖片](../../../ui/assets/items/library/relics/military_manual.png)｜runtime ID：尚未註冊

封面的隊號被塗掉，撤離章節卻被人用布條特別標了出來。

**初見：** 有隊形、信號與路障草圖；不知道是否符合目前道路或武器。

**調查後可確認：** 是特定組織的野外程序參考，能協助解讀標記；不授予軍階、武器所有權或戰鬥熟練。

候選用途可包括避免誤會與撤離，保留非殺傷解法；實際戰術效益另待combat_extension。

候選動作：study_signals、compare_position_plan、reference_evacuation。來源：old_checkpoint、training_store、military_locker。

- 新希望：供應 low／需求 low。地方守衛只需要少數交通與撤離章節。
- 灰谷：供應 low／需求 medium。舊哨站調查者可能需要識讀標記。
- 乾井：供應 medium／需求 high。商隊護衛對溝通與護送程序有具體需求。

- 廢檢查站地面上的標記被誤認為安全通道。 → 比對手冊符號，提出需要另查的禁行區。 代價／限制：標記可能過期，仍須實地確認；讀懂符號不會清除危險。
- 兩支護送隊的手勢互相衝突。 → 安排共同參考的一套撤離信號並演練。 代價／限制：需雙方同意與演練時間；不直接增加命中或保證戰鬥勝利。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、jobs、npc_relationship、combat_extension、regional_trade。研究：WG-04、FICTION-METRO。

<a id="content_military_medical_chip"></a>
## 軍醫資料晶片 · content_military_medical_chip

MISC / medical_archive_chip｜30 g｜參考估值 500 Caps｜rare。
估值理由：資料可能幫助專業人員理解舊醫療流程；不保證包含當前需要的處置或相容器材。
[既有圖片](../../../ui/assets/items/library/relics/military_medical_chip.png)｜runtime ID：尚未註冊

防塵帽上畫著三個小點，盒內說明卻只有兩種狀態。

**初見：** 標籤涉及醫療分流，未知內容和版本不能直接用來救治。

**調查後可確認：** 可辨識資料適用的舊設備與流程版本；實際醫療判斷仍需合格人員和傷病規則。

候選價值來自版本查證、找設備與研究工作；不設『吃掉晶片就會醫術』。

候選動作：verify_protocol、compare_triage_record、consult_specialist。來源：field_hospital_terminal、medical_archive、sealed_case。

- 新希望：供應 none／需求 high。診療資料保存委託可能需要可核對版本。
- 灰谷：供應 low／需求 medium。讀取設備較可能找到，但專業解讀仍需醫療協作。
- 乾井：供應 none／需求 medium。長途醫療後勤可能對分流紀錄有研究需求。

- 舊野戰診所的標籤顏色與地方現行標準相反。 → 讀取晶片中的版本註記，指出不應混用的標準。 代價／限制：需終端與醫療專業；不能照字面把顏色直接當成傷勢判定。
- 藥箱交付人想證明運送內容符合舊清單。 → 比對資料版本、箱號與實物標記。 代價／限制：需人工清點，物品保存狀態另驗；文件不能替不存在的用品背書。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、knowledge、injury、identification、jobs、regional_trade。研究：FICTION-CANTICLE、WG-01。

<a id="content_motorcycle_jacket"></a>
## 摩托夾克 · content_motorcycle_jacket

APPAREL / reinforced_riding_jacket｜2600 g｜參考估值 150 Caps｜uncommon。
估值理由：150 Caps 提案包含完整拉鍊和厚皮料，收藏意願另看個人。
[既有圖片](../../../ui/assets/items/library/clothing/motorcycle_jacket.png)｜runtime ID：尚未註冊

背部舊徽記已有裂紋，拉鍊卻被新換過。

**初見：** 厚重皮層方便長途穿著，但重量與熱負擔需考慮。

**調查後可確認：** 騎行式補強皮衣；舊徽章只表示歷史，不證明現今組織關係。

可成為私人風格與來源話題，不讓外套自動威嚇所有 NPC。

候選動作：wear_riding_layers、preserve_emblem。來源：old_world_motorists、road_salvagers。

- 新希望：供應 low／需求 low。農務使用不便，少數旅人有興趣。
- 灰谷：供應 medium／需求 medium。廢車回收可能取得，皮革匠能修。
- 乾井：供應 low／需求 medium。長線駕駛與護運者看重耐用穿著。

- 道路老人認出夾克上的褪色圖案。 → 請他說明曾在哪個中轉站見過。 代價／限制：談話需信任，徽記不能替玩家取得舊組織通行權。
- 裁縫建議拆掉破損徽記換皮。 → 選擇保留歷史或改善衣物完整性。 代價／限制：修補可能永久失去原圖案。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：皮革、布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：皮革

前置缺口：equipment、combat_extension、hazards、knowledge、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：LD-P01、FICTION-CANTICLE。

<a id="content_multimeter"></a>
## 萬用電表 · content_multimeter

TOOL / electrical_meter｜400 g｜參考估值 85 Caps｜uncommon。
估值理由：85 Caps 取可靠測量工具的定位，校驗與知識都影響用途。
[既有圖片](../../../ui/assets/items/library/supplies/multimeter.png)｜runtime ID：尚未註冊

小盒上的指針與兩支探棒仍能辨清刻度。

**初見：** 量程、探棒與供電狀況需要核對。

**調查後可確認：** 可提供電路測量證據，不會直接指出所有故障或自動修理。

舊設備標記不全時，測量紀錄比單純帶回零件更有價值。

候選動作：test_circuit、compare_cells、diagnose。來源：gray_valley、old_world_utility。

- 新希望：供應 low／需求 medium。供水設備控制箱需要檢測。
- 灰谷：供應 medium／需求 high。電器多且有能讀數的技工。
- 乾井：供應 low／需求 high。泵站診斷常缺可靠儀表。

- 兩顆外觀相同的電池讓收貨者爭執。 → 用合適量程做比對，記錄可觀察差異。 代價／限制：測量不是完整壽命保證，也需要操作知識。
- 發電機停了，有人想直接換掉控制板。 → 先量測指定測試點，縮小故障範圍。 代價／限制：需要安全斷電與設備資料，不能只靠一次讀數診斷全部。

維修：替換匹配探棒或部件後仍需校驗，不能把通電當作精度保證。 候選投入：銅線、精密零件
拆解：小線材與外殼可降級利用，儀表精度與整機身份消失。 候選產物：銅線、塑膠

前置缺口：disassembly、electronics、identification、item_ownership、repair。研究：WG-01、WG-05。

<a id="content_muscle_stimulator"></a>
## 肌纖維刺激器 · content_muscle_stimulator

TOOL / rehabilitation_device｜950 g｜參考估值 560 Caps｜rare。
估值理由：完整設備可供研究或專業復健用途；不按力量增幅定價，也不保證適合健康人使用。
[既有圖片](../../../ui/assets/items/library/relics/muscle_stimulator.png)｜runtime ID：尚未註冊

旋鈕刻度保留著手工畫的停止線，電極包卻早已不在盒內。

**初見：** 像是接觸式醫療裝置，知道需要電源與外接部件，尚未驗證輸出。

**調查後可確認：** 這類設備用於受控條件下的肌肉刺激；缺少適配部件或專業監督時不能把它當力量增強器。

候選長期用途需接正式傷病與復健設計；機器圖片不產生人體效果。

候選動作：inspect_output、compare_protocol、seek_clinical_test。來源：rehabilitation_room、medical_store、research_locker。

- 新希望：供應 none／需求 medium。若有復健需求與合格人員才可能需要設備。
- 灰谷：供應 low／需求 high。電子維修與醫療研究可分工檢查，但不能代替臨床判斷。
- 乾井：供應 none／需求 low。運輸負擔高，缺乏相容配件時買家很少。

- 舊診療室留下設備記錄，未註明最後一次校驗。 → 先在測試負載上檢查輸出是否可控。 代價／限制：需專業測試台與時間；禁止直接拿角色身體試機。
- 照護者想接收設備，商人只願收外殼零件。 → 選擇完整交付供評估，或保留等待配件線索。 代價／限制：搬運佔重量；交付不即時治癒NPC，也不直接提升角色力量。

維修：只能修復外部連接與可校驗機械件；醫療輸出校準需要專業規則，不能保證治療用途。 候選投入：銅線、精密零件
拆解：拆解後不再是完整刺激器；不提供可直接再次組裝的完整替代裝置。 候選產物：銅線、電路板

前置缺口：item_ownership、electronics、injury、repair、jobs、regional_trade、disassembly。研究：WG-03、FICTION-CANTICLE。

<a id="content_music_player"></a>
## 音樂播放器 · content_music_player

TOOL / portable_audio_player｜260 g｜參考估值 70 Caps｜uncommon。
估值理由：可播放且介面相容的機器才有使用價值；沒有電源與媒體時只是待檢舊物。
[既有圖片](../../../ui/assets/items/library/relics/music_player.png)｜runtime ID：尚未註冊

播放鍵磨得發亮，其餘按鍵還能摸到模壓字的凹槽。

**初見：** 有耳機孔與電池艙，螢幕不亮；內部可能有資料但尚未讀取。

**調查後可確認：** 可用相容電源檢測播放電路；媒體內容與來源仍須逐項確認，裝置不保證藏有重要情報。

候選用途是留下地方聲音與私人記憶；娛樂或求證可有價值，但不自動改善全城士氣。

候選動作：test_playback、share_recording、trace_voice。來源：old_homes、lost_luggage、workshop_drawer。

- 新希望：供應 low／需求 medium。公共休息處可能想保留歌聲或口述故事，需要可用電源。
- 灰谷：供應 medium／需求 medium。拆件者與電子維修者可能有零星舊機身。
- 乾井：供應 low／需求 low。長途運輸偏重實用品，只有特定旅人尋找聲音紀錄。

- 交班錄音只剩一段被雜訊蓋住的地點名稱。 → 用相容播放器反覆比對音節，記錄可辨讀的部分。 代價／限制：消耗檢測時間與相容電源；聽不清的字必須保留未知，不補出假座標。
- 一位旅人認得機身上的家庭貼紙。 → 讓對方聽到經同意公開的錄音片段，協助查證來源。 代價／限制：需要持有人同意；分享內容可能洩露私人資訊，不能自動解鎖信任。

維修：先確認介面與電壓；換件不會恢復已失去的錄音。 候選投入：電路板、銅線、電池芯
拆解：媒體與電路分開處理；拆解前必須告知可能喪失播放能力。 候選產物：電路板、銅線、塑膠

前置缺口：item_ownership、electronics、knowledge、npc_relationship、regional_trade、repair、disassembly。研究：FICTION-CANTICLE、WG-03。

<a id="content_neural_reflex_module"></a>
## 神經反射模組 · content_neural_reflex_module

MISC / sensor_interface_module｜160 g｜參考估值 750 Caps｜rare。
估值理由：估值反映完整介面與研究價值，並非按保證的反應增益計價；安裝風險未平衡。
[既有圖片](../../../ui/assets/items/library/relics/neural_reflex_module.png)｜runtime ID：尚未註冊

外殼邊緣有一排接點，其中一個被刻意封住。

**初見：** 標籤提到反應測試，但無法知道受試者條件與實際功能。

**調查後可確認：** 可檢查它接收外部感測訊號的介面；神經適配與長期影響仍未知，不能自行接入人體。

候選成長路線先經外接測試與專家判讀，是否可安裝及效果另由未來規則決定。

候選動作：inspect_interface、run_external_diagnostic、seek_specialist。來源：sealed_research_case、rehabilitation_lab、prototype_locker。

- 新希望：供應 none／需求 low。一般居民沒有適配設備；有醫療研究委託時才有需求。
- 灰谷：供應 none／需求 high。電子研究者可能需要完整接點與來源紀錄。
- 乾井：供應 none／需求 medium。外來收購者可能找特定型號，不能代表當地常備庫存。

- 研究站的外接測試座仍留下相同介面。 → 在隔離測試台讀取模組回應，確認是否能通訊。 代價／限制：需相容電源、專門操作與時間；通訊成功不證明可安全植入。
- 買家要拆開外殼取走一片基板。 → 決定保留完整模組供後續診斷，或交給有資格的研究者。 代價／限制：交付會放棄同一模組的其他去向；拆解前要明示會失去完整性。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、identification、injury、equipment、knowledge、regional_trade。研究：WG-04、FICTION-CANTICLE。

<a id="content_night_vision_goggles"></a>
## 夜視鏡 · content_night_vision_goggles

APPAREL / powered_low_light_optics｜820 g｜參考估值 890 Caps｜rare。
估值理由：890 Caps 提案反映罕見完好光電組件，不含電池。
[既有圖片](../../../ui/assets/items/library/clothing/night_vision_goggles.png)｜runtime ID：尚未註冊

鏡罩還掛在背帶上，電池座有乾涸的腐蝕痕。

**初見：** 需要相容電源與可用感測元件，不是照亮整片荒野的燈。

**調查後可確認：** 低光觀察設備，適用亮度與電源壽命尚待 lighting/electronics。

提供觀察可能性而非看穿牆面；普通手電筒仍有照明與分享視野用途。

候選動作：inspect_powered_optics、plan_night_observation。來源：military_ruins、old_world_security。

- 新希望：供應 none／需求 low。只有特定守望需求，缺少維護者。
- 灰谷：供應 low／需求 high。光電工坊和遺跡調查者有興趣。
- 乾井：供應 none／需求 medium。夜行商隊需權衡電源供應和維修距離。

- 隊伍想在夜間查明遠處移動的輪廓。 → 準備相容電源後安排單人觀察。 代價／限制：需實際照明規則與可見範圍，不能直接揭露身份。
- 精密工坊想查看腐蝕元件。 → 交付樣品進行檢測。 代價／限制：失去當晚使用機會，檢測可能判定無法維修。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：電路板、玻璃、銅線
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：電路板、玻璃

前置缺口：equipment、electronics、lighting、exploration、identification、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-06。

<a id="content_number_sixty_three"></a>
## 六十三號 · content_number_sixty_three

TOOL / numbered_service_wrench｜860 g｜參考估值 None Caps｜unique。
估值理由：價值取決於與特定舊設備匹配的幾何與維修紀錄，不是通用高階工具等級。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/number_sixty_three.png)｜runtime ID：尚未註冊

柄上敲著六十三，鉗口內側另有一個不太規則的缺口。

**初見：** 形狀像維修扳手，缺口可能是損壞也可能為特定接頭加工；尚未核對。

**調查後可確認：** 可確認鉗口尺寸與匹配的舊固定件；只有明確適配部位可嘗試操作，無泛用開門能力。

候選長期目標是回到曾看見的特殊維修口；來源與唯一所有權必須保留，不常規補貨。

候選動作：compare_service_stamp、operate_matching_fastener、entrust_tool。來源：numbered_factory_tool_locker、documented_personal_transfer。

- 新希望：供應 none／需求 low。沒有相容設備時只是一件難用的老工具，可能協助轉交。
- 灰谷：供應 none／需求 high。相關工廠的調查者可能尋找這把有記錄的工具。
- 乾井：供應 none／需求 medium。若燃料設備沿用相同固定件才有特定需求，不能憑工業標籤通用。

- 灰谷舊廠維修蓋上的螺帽有非標準缺口。 → 先量測比對，確認後用六十三號轉動相容固定件。 代價／限制：需安全停機與MECHANICS相關操作；匹配工具不消除內部危險或授予所有權。
- 工匠要求磨平鉗口，好把它當普通扳手使用。 → 保留原形等待專用設備線索，或選擇不可逆改造。 代價／限制：改造會失去原有匹配用途；不能同時保有兩種形狀或生成另一把工具。

維修：只允許經量測的柄部補修；磨改鉗口是改造並可能失去匹配用途，不是假裝恢復原樣。 候選投入：鋼材
拆解：熔解會失去編號與特殊鉗口，不能從廢鐵重新產出唯一原物。 候選產物：廢鐵

前置缺口：item_ownership、exploration、repair、crafting、knowledge、npc_relationship、regional_trade、disassembly。研究：WG-01、LD-P01。

<a id="content_oil_lamp"></a>
## 油燈 · content_oil_lamp

TOOL / wick_lamp｜650 g｜參考估值 24 Caps｜common。
估值理由：24 Caps 取低技術可維護的照明定位，需攜帶額外燃料。
[既有圖片](../../../ui/assets/items/library/supplies/oil_lamp.png)｜runtime ID：尚未註冊

玻璃罩裡垂著燈芯，金屬提把被煙熏黑。

**初見：** 六百五十克按空燈估計，燈油不包含在內。

**調查後可確認：** 需要相容油料、燈芯和通風場所；明火也可能暴露營地。

乾井泵站常見這種燈，不代表可在有油氣的場所安全點燃。

候選動作：light_area、refill、hang。來源：dry_well、settlement_workshop。

- 新希望：供應 medium／需求 medium。灶棚與停電時可用。
- 灰谷：供應 medium／需求 medium。工地有照明需求，但油氣區限制使用。
- 乾井：供應 high／需求 medium。可維護燈體常見，相容油料另取。

- 地下避雨點沒有電，但通風口仍暢通。 → 在確認無可燃氣體的區域架起油燈。 代價／限制：需要燈油與燈芯，明火會暴露位置。
- 乾井值班者把油燈掛在漏油泵旁。 → 借燈供安全位置照明，先搬離危險點。 代價／限制：不能用油燈替代所有檢查工具，也不能在油氣區點燃。

維修：玻璃罩、合適燈芯與支架可分別維護；不附帶燃料。 候選投入：玻璃、布料、廢鐵
拆解：清除殘留油料後才能回收未破罩片與金屬，舊燈芯不作潔淨布料。 候選產物：玻璃、廢鐵

前置缺口：camping、disassembly、hazards、item_ownership、lighting、repair。研究：WG-01、WG-03。

<a id="content_old_hunter_rifle"></a>
## 老獵人的槍 · content_old_hunter_rifle

WEAPON / named_hunting_rifle｜3500 g｜參考估值 None Caps｜unique。
估值理由：沒有通用估價；家人、原同伴與收藏者各有不同目的。 重量按空槍提案，價格不是現有商店報價。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/weapons/old_hunter_rifle.png)｜runtime ID：尚未註冊

木托留下多年補縫，一小片刻字說明它曾屬於同一個獵人。

**初見：** 不尋常的是持有人歷史，未必比普通獵槍更有威力。

**調查後可確認：** 特定獵人的私人物品；維修痕與刻字可和他留下的記錄比對。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

此人與後續關係皆為設計候選，必須綁定既有人口，不臨時生成人。

候選動作：verify_personal_history、preserve_inscription。來源：named_hunter_history、new_hope_routes。

- 新希望：供應 none／需求 high。只有與原獵人有關的人可能急於尋回，不代表常態大量需求。
- 灰谷：供應 none／需求 low。一般廢料商不應為無法確認的故事付高價。
- 乾井：供應 none／需求 low。特定商隊可能保有舊交接線索，沒有例行庫存。

- 一名農人認出木托上的補縫。 → 讓他描述舊主並核對其他證據。 代價／限制：需對方願意談，不因認物就確認親屬或贈送報酬。
- 收藏者想磨掉刻字翻新。 → 選擇保留原貌或交出處分權。 代價／限制：翻新會失去部分歷史證據，沒有固定最佳售價。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：皮革、彈簧
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_old_photograph"></a>
## 老照片 · content_old_photograph

MISC / photographic_print｜15 g｜參考估值 20 Caps｜uncommon。
估值理由：一般相片交易價低；家族或調查需求另議，不能把私人意義換算為普遍高價。
[既有圖片](../../../ui/assets/items/library/relics/old_photograph.png)｜runtime ID：尚未註冊

人群站在一口新井旁，畫面邊緣有人把臉轉向了別處。

**初見：** 井旁有不完整招牌與山形，背面寫了名字；拍攝年代與地點尚未核實。

**調查後可確認：** 可辨認的地物與手寫內容列為線索；相似外貌不能證明親屬、身分或所有權。

候選內容重點是世界曾經怎麼使用某處，以及誰仍記得；相片不授予新人口或必然存在的家屬。

候選動作：compare_landmark、seek_owner、preserve_image。來源：old_homes、personal_effects、archive_folder。

- 新希望：供應 medium／需求 low。居民家藏可能流出，但只對相關的人有明確需求。
- 灰谷：供應 low／需求 medium。地方紀錄者可能收集工業聚落變遷影像。
- 乾井：供應 low／需求 medium。舊井與商路地景可能幫助比對歷史位置。

- 新井選址者想確認照片中的舊排水溝走向。 → 比對山形與尚存牆角，提出調查位置。 代價／限制：需實地核對；相片不能證明地下水量或保證安全鑽探。
- 旅人說照片上的名字與自己的寄存單相同。 → 安排查證或將複製筆記交給地方記錄者。 代價／限制：需尊重持有人意願；不能只憑姓名就交出原照或建立親屬關係。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、exploration、npc_relationship、jobs、regional_trade。研究：FICTION-CANTICLE、LD-P02。

<a id="content_old_revolver"></a>
## 老式左輪 · content_old_revolver

WEAPON / revolver｜1050 g｜參考估值 210 Caps｜uncommon。
估值理由：210 Caps 對應可檢查的普通舊槍。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/old_revolver.png)｜runtime ID：尚未註冊

磨亮的握柄與暗啞機件不太相稱，像是換過幾任主人。

**初見：** 外露結構較便於檢視，仍需工匠確認磨耗。

**調查後可確認：** 老式轉輪槍，年份不構成可靠性保證。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

它的存在理由是常見維修經驗，並非自帶無故障特性。

候選動作：inspect_mechanism、present_guard_gear。來源：caravan_routes、old_households。

- 新希望：供應 low／需求 medium。獵戶與村落守衛熟悉舊式器材。
- 灰谷：供應 medium／需求 medium。舊槍流通與維修工坊相對集中。
- 乾井：供應 medium／需求 high。護衛旅途中需要能找到維修者的型式。

- 商隊招募臨時守夜者。 → 出示已確認可用且由自己持有的器材參加評估。 代價／限制：需另備相容彈藥與正式護衛資格；不能僅持槍領取報酬。
- 孤屋留下模糊的舊槍編號。 → 請工匠比對流通記錄。 代價／限制：耗詢問與檢查時間，記錄可能只指向前一位商人。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、鋼材、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_old_smg"></a>
## 舊世衝鋒槍 · content_old_smg

WEAPON / legacy_smg｜3100 g｜參考估值 560 Caps｜rare。
估值理由：560 Caps 假設主要部件齊全，仍不保證立即可用。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/old_smg.png)｜runtime ID：尚未註冊

長期封存的槍身有一道油布壓痕，肩托鎖扣仍待檢查。

**初見：** 攜帶體積較大，需要成套維護而非只清掉表面灰塵。

**調查後可確認：** 舊世衝鋒槍；缺件、彈藥與操作方式須各自確認。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

遺跡保存狀態決定用途，不把舊世出身當作天然高級。

候選動作：document_storage_record、lend_for_inspection。來源：military_ruins、security_depots。

- 新希望：供應 none／需求 low。保管和後勤超出多數農戶需要。
- 灰谷：供應 low／需求 high。工坊與有組織守衛可能收購可檢修器材。
- 乾井：供應 low／需求 medium。護運需要，但外地部件是限制。

- 軍警遺跡的器材清單缺頁。 → 以槍身刻記補做物證記錄。 代價／限制：需保留原物供核驗；拆解會失去完整證據。
- 工坊要一支樣品判斷能否支援商隊。 → 借出器材進行非實戰檢查。 代價／限制：暫時失去使用權，研究結果可能是不值得修。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_old_world_canned_food"></a>
## 舊世罐頭 · content_old_world_canned_food

MISC / collectible_old_food_can｜500 g｜參考估值 60 Caps｜rare。
估值理由：60 Caps 是完整包裝對特定收藏者的提議價，普通廚房可能完全拒收。
[既有圖片](../../../ui/assets/items/library/supplies/old_world_canned_food.png)｜runtime ID：尚未註冊

舊商標完整保留在金屬罐上，封口沒有被拆。

**初見：** 原封不代表仍能食用；可讀標籤已是一份歷史資料。

**調查後可確認：** 可交收藏者研究封裝與商標；若要評估食用需另行檢驗，不能憑外觀保證。

與近期罐頭分開，最有價值的可能是還沒被打開這件事。

候選動作：inspect_label、deliver_to_collector、assess_contents。來源：old_world_store。

- 新希望：供應 none／需求 low。廚房不把陳年封罐當正常食物。
- 灰谷：供應 low／需求 medium。舊貨研究者重視商標與封口。
- 乾井：供應 none／需求 low。商隊可能代找指定收藏者。

- 收藏者想要完整商標，飢餓旅人只關心能不能吃。 → 保留封罐交收藏者，或另請人評估食用價值。 代價／限制：開罐會破壞收藏完整性，食用安全也不預先保證。
- 研究者想比對舊世食品配送區。 → 提供標籤與發現位置的記錄。 代價／限制：資訊價值依完整來源而定，不能憑一罐重建全部商路。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、item_ownership、knowledge、regional_trade。研究：FICTION-CANTICLE、WG-02。

<a id="content_old_world_map"></a>
## 舊世地圖 · content_old_world_map

MISC / historical_map｜120 g｜參考估值 45 Caps｜uncommon。
估值理由：45 Caps 是可讀地圖的設計估價，真正用途取決於覆蓋位置。
[既有圖片](../../../ui/assets/items/library/supplies/old_world_map.png)｜runtime ID：尚未註冊

摺痕把舊路網分成幾塊，角落保留測繪日期。

**初見：** 記錄的是舊世界，不保證橋、道路與地名仍有效。

**調查後可確認：** 與現地標記或其他記錄比對後，可提出路線與入口線索。

新加註的路況能比原印刷圖更實用，改寫也可能破壞歷史證據。

候選動作：compare_landmarks、annotate、copy_route。來源：old_world_archive、survey_station。

- 新希望：供應 low／需求 medium。舊灌溉路網可能提供線索。
- 灰谷：供應 medium／需求 high。舊工業道路和管線入口待比對。
- 乾井：供應 low／需求 high。油運路線的舊橋與便道資訊有用。

- 圖上的橋在現地只剩橋墩。 → 標註斷點，尋找可驗證的其他通路線索。 代價／限制：地圖不生成新路，調查可能只確認此路不可通。
- 灰谷技工想借圖找出舊維修入口。 → 允許抄錄相關區段而保留原件。 代價／限制：抄錄花時間，缺比例或已改建的區域仍不可靠。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、item_ownership、knowledge、navigation。研究：FICTION-CANTICLE、FICTION-WOOL。

<a id="content_old_world_medical_case"></a>
## 舊世醫療箱 · content_old_world_medical_case

TOOL / sealed_medical_case｜2400 g｜參考估值 240 Caps｜rare。
估值理由：240 Caps 是完整來源可驗證時的收藏／醫療設備提議價，內容未知須重估。
[既有圖片](../../../ui/assets/items/library/supplies/old_world_medical_case.png)｜runtime ID：尚未註冊

硬殼箱封條仍在，外側清單只能讀出一半。

**初見：** 以封存整箱計；未開箱不能宣稱有完整藥物或器械。

**調查後可確認：** 可先核對清單與封條，再決定交付整箱或在合適場所清點。

把箱子交給診所或保存封條交給研究者，是用途不同的交付。

候選動作：audit_contents、deliver_sealed、donate。來源：old_world_hospital。

- 新希望：供應 none／需求 medium。診所重視可用內容，不能按封條推定完整。
- 灰谷：供應 low／需求 high。遺跡回收偶有整箱，可安排檢驗。
- 乾井：供應 none／需求 medium。偏遠醫療點可能委託運送整箱。

- 封存醫療箱外的清單有一頁遺失。 → 保持封條帶回診所核對，或在有人見證下清點。 代價／限制：完整交付和開箱調查互斥；內含物未確認前無獎勵清單。
- 研究者重視箱上的編號，醫師更關心內容。 → 協商先記錄外觀，再交診所檢查。 代價／限制：需兩方同意與時間，不可同時賣出整箱兩次。

維修：只能修復箱體封套與內襯；不恢復過期或不明內容物。 候選投入：橡膠、布料
拆解：只處理已清點的空箱外殼；箱內用品不從拆箱文字自動生成。 候選產物：塑膠、廢鐵

前置缺口：cargo、disassembly、identification、injury、item_ownership、jobs、repair。研究：WG-02、FICTION-CANTICLE。

<a id="content_old_world_military_armor"></a>
## 舊世軍甲 · content_old_world_military_armor

APPAREL / military_protective_set｜9500 g｜參考估值 1150 Caps｜rare。
估值理由：1150 Caps 提案僅對應主要組件齊全的收藏與使用需求。
[既有圖片](../../../ui/assets/items/library/clothing/old_world_military_armor.png)｜runtime ID：尚未註冊

多件防護組件裝在一只編號袋裡，有一條固定帶缺了扣。

**初見：** 稀有不代表完整；尺寸、缺件與檢驗能力决定能否使用。

**調查後可確認：** 舊世軍用防護組，具體防護項目需獨立鑑定。

這件不是自動開啟所有污染區的環境防護服，也不授予軍方身分。

候選動作：inspect_protective_set、preserve_component_record。來源：military_ruins、old_world_depots。

- 新希望：供應 none／需求 low。一般生活難以負擔，可能只接轉運委託。
- 灰谷：供應 low／需求 medium。專門檢修工坊與收藏者有不同需求。
- 乾井：供應 none／需求 medium。特定高風險護運團會委託尋找。

- 出土防護組缺少原始點收表。 → 調查同批設備記錄確定缺件。 代價／限制：需文件和時間，不因完成列表就自動修復。
- 研究者與護衛對唯一完整組件提出不同需求。 → 選擇保留研究或交給實際使用者。 代價／限制：移交後失去裝備機會；不得同時滿足兩方。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：精密零件、布料、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：鋼材、布料

前置缺口：equipment、combat_extension、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：LD-P01、WG-05。

<a id="content_old_world_tactical_chip"></a>
## 舊世戰術晶片 · content_old_world_tactical_chip

MISC / training_data_chip｜35 g｜參考估值 420 Caps｜rare。
估值理由：估值來自可讀的訓練資料；不能以未實作的永久戰力加成作保證。
[既有圖片](../../../ui/assets/items/library/relics/old_world_tactical_chip.png)｜runtime ID：尚未註冊

晶片殼上有一道深刮痕，旁邊的版本貼紙仍黏得很牢。

**初見：** 標記像演訓資料，沒有相容終端便不知道內容。

**調查後可確認：** 可載入特定模擬格式的舊演訓紀錄；和現今武器、地形是否適用需另外判讀。

候選用途是訓練工作、舊設施調查與戰術理解；持有資料不等於學會技能。

候選動作：verify_simulation_format、review_scenario、compare_doctrine。來源：training_terminal、military_archive、sealed_case。

- 新希望：供應 none／需求 low。地方守衛可能只對可讀的撤離演練有興趣。
- 灰谷：供應 low／需求 medium。舊終端工坊可處理格式，但通常沒有完整模擬設備。
- 乾井：供應 none／需求 high。護送訓練委託可能需要可對照的行動紀錄。

- 護送隊爭論一段演訓是否適用狹窄山口。 → 讀取場景限制，指出哪些條件與現場不符。 代價／限制：需相容終端、閱讀與討論時間；不直接提高隊伍命中或替玩家選戰術。
- 軍事倉庫的演訓編號與晶片版本吻合。 → 用資料索引縮小需要檢查的訓練室。 代價／限制：只是地點線索；進入與取物仍需現場許可和探索規則。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、knowledge、combat_extension、skills_growth、jobs、regional_trade。研究：WG-04、FICTION-CANTICLE。

<a id="content_old_world_watch"></a>
## 舊世界手錶 · content_old_world_watch

TOOL / mechanical_timepiece｜110 g｜參考估值 90 Caps｜uncommon。
估值理由：價值來自可校時的機芯與可辨讀刻字；停擺或來源不明時不能直接套用此估值。
[既有圖片](../../../ui/assets/items/library/relics/old_world_watch.png)｜runtime ID：尚未註冊

錶帶換過三次，背蓋仍留著一圈比手腕細得多的磨痕。

**初見：** 指針偶爾前進，背面有兩個縮寫；不知道它是否走得準。

**調查後可確認：** 機芯可手動上鍊，日常走時會漂移；背蓋刻字是持有人標記，並非通行資格。

候選來源是舊屋抽屜或私人寄存物；校時與尋找失主是兩條獨立用途，沒有自動導航效果。

候選動作：inspect、synchronize、return_to_owner。來源：old_homes、locker、personal_effects。

- 新希望：供應 low／需求 medium。水閘輪值者可能需要可校準的時計；本地不能穩定製作機芯。
- 灰谷：供應 medium／需求 high。修表與精密拆件的候選工匠需要可修機芯，會先辨別是否缺件。
- 乾井：供應 low／需求 medium。車隊交班可能需要計時，但只在有排班工作時形成需求。

- 兩隊工人互相指責提早關閉灌溉閘。 → 借出經校時的手錶，讓雙方在一次輪值中記錄開關時刻。 代價／限制：必須先取得雙方同意並留錶一個輪值；僅提供紀錄，不自動裁定誰說謊。
- 商隊失物單上的錶帶補線與此錶相同。 → 帶著手錶查證刻字與領取人身分。 代價／限制：需跑一趟交會地點；查證前不能因圖樣相似就轉移所有權。

維修：更換損壞機件或錶面，須有能辨識機芯的工匠；刻字與走時紀錄不能靠換件生成。 候選投入：精密零件、彈簧、玻璃
拆解：拆解會失去完整時計與尋主證物，只保留經確認可用的零件，無固定回收比率。 候選產物：彈簧、精密零件

前置缺口：item_ownership、knowledge、jobs、npc_relationship、regional_trade、repair、disassembly。研究：FICTION-CANTICLE、WG-02。

<a id="content_painkillers"></a>
## 止痛藥 · content_painkillers

CONSUMABLE / labelled_analgesic｜40 g｜參考估值 22 Caps｜uncommon。
估值理由：22 Caps 以有來源的常備藥估值，非立即續戰的增益商品。
[既有圖片](../../../ui/assets/items/library/supplies/painkillers.png)｜runtime ID：尚未註冊

藥板外套有幾行已磨淡的字，仍保留品名。

**初見：** 一板藥品；能止痛不代表受傷部位已恢復。

**調查後可確認：** 應由醫療角色核對用途與狀況；內容設計不指定真實用藥方式。

疲倦搬運工可能想掩蓋傷痛繼續工作，這會是協商休息的情境。

候選動作：consult_medic、deliver。來源：old_world_clinic、caravan。

- 新希望：供應 low／需求 medium。診所少量儲備，按需發放。
- 灰谷：供應 low／需求 high。工人求購多，但不能只靠藥物替代休養。
- 乾井：供應 low／需求 medium。商隊帶入，收貨方看重保存紀錄。

- 工人想吃藥後帶傷完成最後一班。 → 將用品交給醫護評估，另談換班安排。 代價／限制：不直接消除傷勢；換班需雇主與工人同意。
- 村落有人拿空藥板索取同款補貨。 → 把標籤資料帶到診所詢問是否有相符庫存。 代價／限制：只取得資訊，不保證可供應或適合當事人。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、injury、item_ownership、jobs。研究：WG-04、FICTION-ROAD。

<a id="content_paper_journal"></a>
## 紙本日記 · content_paper_journal

MISC / personal_written_record｜320 g｜參考估值 45 Caps｜uncommon。
估值理由：一般日記沒有固定寶藏價，估值僅作保存與有需求者交付的參考。
[既有圖片](../../../ui/assets/items/library/relics/paper_journal.png)｜runtime ID：尚未註冊

有幾頁被整齊割去，後面的字卻寫得比前面更仔細。

**初見：** 可讀到日期與行程片段，作者身分和描述真偽尚未核實。

**調查後可確認：** 紙張與筆跡可分出原記錄和後加註；內容是作者觀察，不等於現今地圖或世界事實。

日記可保存失敗嘗試與普通生活；不要求最後一頁總有遺產或秘密入口。

候選動作：read_entries、compare_route、return_journal。來源：personal_effects、old_homes、field_camp。

- 新希望：供應 medium／需求 medium。居民可能尋找種植、取水或家族紀錄。
- 灰谷：供應 low／需求 medium。設備維護手記與工人日記偶有調查價值。
- 乾井：供應 low／需求 high。商路記錄與失聯車隊行程可能受到委託人關注。

- 旅程記錄提到一處如今找不到的路標。 → 用相鄰地物核對筆記，提出需要探查的路段。 代價／限制：路況可能已改變；需花一次實地調查，不能直接提供安全捷徑。
- 失物主人不願公開日記，調查者卻想讀。 → 選擇封存交還或取得同意後只抄必要段落。 代價／限制：交還會放棄後續自行閱讀；未獲同意公開的社交後果需另定權威。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、navigation、npc_relationship、jobs、regional_trade。研究：FICTION-CANTICLE、LD-P02。

<a id="content_planting_manual"></a>
## 種植手冊 · content_planting_manual

MISC / agricultural_reference｜620 g｜參考估值 140 Caps｜uncommon。
估值理由：適合本地作物與土壤條件的章節有價值；異地氣候與不明種子不能照書保證收成。
[既有圖片](../../../ui/assets/items/library/relics/planting_manual.png)｜runtime ID：尚未註冊

封底折成一個小袋，裡面的種粒已經碎成深色的粉。

**初見：** 可見播種、儲藏和輪作圖表，作者註記的氣候與現在未必相同。

**調查後可確認：** 可區分一般栽培知識與地方試驗紀錄；實際成活率仍需作物、用水與土壤資料。

候選內容讓文獻支持小規模試驗和農業工作，不用一次交書永久倍增全城糧食。

候選動作：compare_crop_notes、identify_storage_needs、plan_trial_plot。來源：farmhouse_shelf、agricultural_office、seed_store。

- 新希望：供應 medium／需求 high。農戶與種子保管者關心本地適用版本，也可能交換試驗註記。
- 灰谷：供應 low／需求 medium。工業聚落的小菜圃可能需要儲種與輪作知識。
- 乾井：供應 none／需求 medium。節水栽培的特定章節可能有需求，但不是燃料地的固定商品。

- 新希望發現一包來源不明的種子。 → 比對儲藏與外觀記錄，制定小塊試種方案。 代價／限制：需留出土地、水與觀察時間；不把外觀相似等同鑑定成功。
- 乾井居民想把所有水一次投入新菜圃。 → 對照書中的條件限制，提出分批觀察與保留飲水的方案。 代價／限制：只提供計畫依據；實際耕作、用水與產量需另定世界規則。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、identification、jobs、regional_trade。研究：FICTION-CANTICLE、WG-03。

<a id="content_plastic"></a>
## 塑膠 · content_plastic

MISC / plastic_sheet｜250 g｜參考估值 6 Caps｜common。
估值理由：6 Caps 因來源廣但適用工作窄，需按片面完整程度挑選。
[既有圖片](../../../ui/assets/items/library/supplies/plastic.png)｜runtime ID：尚未註冊

平整塑膠片還留著舊包材的壓印。

**初見：** 一份兩百五十克，未核驗材質的片料不當食物容器。

**調查後可確認：** 可用於不承力隔片或標籤罩，熱源與日晒仍可能限制用途。

它不必成為高級材料；便宜的防濺標示罩也能解決真實問題。

候選動作：cut_spacer、cover_label、deliver_material。來源：gray_valley、old_world_home。

- 新希望：供應 medium／需求 low。舊包材常見，普通修補需求小。
- 灰谷：供應 high／需求 medium。分選後可做保護與隔片。
- 乾井：供應 medium／需求 medium。路牌和貨單防濺需要便宜材料。

- 路線告示被雨打濕，字跡每次都要重寫。 → 用透明片料做可替換的防濺罩。 代價／限制：要有固定方式，長期日晒仍可能變脆。
- 工匠要給鬆動箱蓋做一片不承力隔片。 → 裁出符合尺寸的塑膠片供試配。 代價／限制：不可當耐熱或高負載構件，裁剩邊角沒有完整原料價值。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、item_ownership、regional_trade、repair。研究：WG-01、WG-02。

<a id="content_pliers"></a>
## 鉗子 · content_pliers

TOOL / combination_pliers｜320 g｜參考估值 18 Caps｜common。
估值理由：18 Caps 因常用且可維護，價值來自穩定夾持而非戰力。
[既有圖片](../../../ui/assets/items/library/supplies/pliers.png)｜runtime ID：尚未註冊

鉗口內側磨得光亮，握柄纏了一層舊布。

**初見：** 布纏握柄不代表具備絕緣認證。

**調查後可確認：** 可夾持細件和處理合適金屬絲；對帶電、厚硬物仍有明確限制。

失去插銷的農車與鬆開的線頭需要它做不同的工作。

候選動作：grip_wire、bend_tab、extract_pin。來源：gray_valley、industrial_ruin。

- 新希望：供應 medium／需求 medium。農務固定與小零件維護有需求。
- 灰谷：供應 high／需求 high。線材和插銷工作常見。
- 乾井：供應 low／需求 high。車隊現場拆裝需要可攜夾持工具。

- 貨車插銷彎了，手指夾不到。 → 用鉗子取出可接近的插銷讓工人檢查。 代價／限制：先固定構件，鉗子不能承受整台車的重量。
- 線頭垂在泵房門口，沒人知道是否通電。 → 等技工確認斷電後才夾持整理。 代價／限制：需要檢驗與技術，不靠布纏握柄保證安全。

維修：只提議鉸接與匹配回位機構維護；不產生絕緣認證。 候選投入：鋼材、彈簧
拆解：僅回收仍完好的回位件與金屬，拆後不能再使用整把鉗子。 候選產物：廢鐵、彈簧

前置缺口：disassembly、electronics、exploration、item_ownership、repair。研究：WG-01、WG-02。

<a id="content_police_ballistic_vest"></a>
## 警用防彈衣 · content_police_ballistic_vest

APPAREL / ballistic_vest｜4200 g｜參考估值 460 Caps｜rare。
估值理由：460 Caps 是可驗證完整個體的設計估值。
[既有圖片](../../../ui/assets/items/library/clothing/police_ballistic_vest.png)｜runtime ID：尚未註冊

防護板插袋仍在，封存日期早已褪去。

**初見：** 舊防具可能受過撞擊，外層完整不足以判定可靠。

**調查後可確認：** 舊制式防彈衣，材料與隱藏損傷需要專門檢驗。

不設定可擋口徑或護甲數值，先讓可靠檢驗成為珍貴服務。

候選動作：inspect_protective_panels、register_guard_gear。來源：old_world_police、guarded_depots。

- 新希望：供應 none／需求 low。日常農務不需要，特定護衛委託例外。
- 灰谷：供應 low／需求 medium。警備遺跡與檢驗工坊形成有限流通。
- 乾井：供應 none／需求 medium。有後勤的護運團尋找可靠防具。

- 收購者只看外觀就承諾高價。 → 要求共同檢驗再談交付。 代價／限制：需等待專業者，結果可能降低價值。
- 倉庫要借出防具給當班守衛。 → 建立清楚的領用與歸還紀錄。 代價／限制：必須符合尺寸與所有權，不同人不能同時穿同件。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、精密零件
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、combat_extension、identification、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-02、WG-05。

<a id="content_police_pistol"></a>
## 警用手槍 · content_police_pistol

WEAPON / service_sidearm｜880 g｜參考估值 310 Caps｜uncommon。
估值理由：310 Caps 假設保存了可查的型號資料。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/police_pistol.png)｜runtime ID：尚未註冊

槍柄底部還留著公物號碼，配套槍套已遺失。

**初見：** 來源編號可能可追查，卻不授予執法身分。

**調查後可確認：** 舊制式短槍；公物印記與機械可用程度分開判斷。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

價值一部分是可辨識的型號與維護記錄，不是自動較準。

候選動作：trace_inventory_number、transfer_custody。來源：old_world_police、civic_security。

- 新希望：供應 none／需求 medium。守望隊有需求但不在本地生產。
- 灰谷：供應 low／需求 high。舊警備倉與修理者可能提供配套資料。
- 乾井：供應 low／需求 medium。只對能取得相容補給的護衛有吸引力。

- 失蹤守衛的家人尋找公物清單。 → 交付槍上編號供比對。 代價／限制：只提供線索，不能直接證明持有人死亡或犯罪。
- 聚落委託保管收繳器材。 → 將此槍列入可追溯交接。 代價／限制：需歸還原持有方或取得處分同意，不能一物兩賣。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_power_hammer"></a>
## 動力錘 · content_power_hammer

TOOL / powered_industrial_hammer｜11500 g｜參考估值 720 Caps｜rare。
估值理由：720 Caps 提案是可修復工業資產估值，未含搬運與供電費用。
[既有圖片](../../../ui/assets/items/library/weapons/power_hammer.png)｜runtime ID：尚未註冊

沉重機頭旁貼著起吊標記，舊電纜已被人截斷。

**初見：** 必須安排運輸、供電與熟手操作，徒手提走不代表能使用。

**調查後可確認：** 工業拆除器具；工作頭與驅動模組需分別確認，非一般手錘。

其吸引力是能完成特定工地工作，不能當成可隨身亂揮的終極武器。

候選動作：inspect_foundation_tool、remove_worksite_obstruction。來源：industrial_ruins、gray_valley。

- 新希望：供應 none／需求 low。僅大工程會需要，日常農務負擔不起物流。
- 灰谷：供應 low／需求 high。工業維修者能提供作業場所與運輸需求。
- 乾井：供應 none／需求 medium。燃料設施重修可能借用，通常以工作委託而非個人購買。

- 坍塌泵房阻住既有檢修通道。 → 提出運入機具的工程方案。 代價／限制：先確認結構、供電與人員，不由持有物品直接拆通入口。
- 兩個聚落爭取同一件重型設備。 → 選擇送往哪個修復項目。 代價／限制：必須負擔搬運與契約代價，另一個項目仍未解決。

維修：只有設備齊全工坊能檢修；相容驅動及電源尚未定義。 候選投入：齒輪、軸承、精密零件、銅線
拆解：拆作材料會永久放棄整機用途，產率另定。 候選產物：鋼材、銅線

前置缺口：equipment、combat_extension、electronics、exploration、cargo、jobs、hazards、item_ownership、regional_trade、repair、disassembly。研究：WG-03、WG-04。

<a id="content_precision_engineering_manual"></a>
## 精密工程手冊 · content_precision_engineering_manual

MISC / precision_calibration_reference｜980 g｜參考估值 360 Caps｜rare。
估值理由：特定公差表與量測方法對具備工具的人有用；沒有量具時不會自動得到精密加工能力。
[既有圖片](../../../ui/assets/items/library/relics/precision_engineering_manual.png)｜runtime ID：尚未註冊

表格旁有一行細字提醒先量溫度，後面的測試頁保存得格外乾淨。

**初見：** 可見公差、治具和校準圖，缺少實物量具不能照表直接完工。

**調查後可確認：** 可辨識參考標準與允許偏差；操作仍需相容量具、材料、技術能力與檢驗。

候選定位是高階維修的知識門檻，讓低階手冊保留日常故障用途而非被全面淘汰。

候選動作：read_tolerance_table、plan_measurement、compare_fixture。來源：metrology_room、engineering_archive、precision_workshop。

- 新希望：供應 none／需求 medium。水泵與農機只有特定部件需要高精度量測。
- 灰谷：供應 low／需求 high。工坊可能尋找校準依據，但是否有相容治具決定用途。
- 乾井：供應 none／需求 high。燃料泵密封與量測工作可能需要專門資料。

- 乾井兩個替換泵件外形相同卻不能互換。 → 比對公差表，列出需要量測的尺寸。 代價／限制：需適合量具與技術；手冊不把普通廢鐵直接變成精密零件。
- 灰谷工坊的量具沒有校準紀錄。 → 依手冊規劃比對流程並尋找可用參考件。 代價／限制：需要參考件與停工時間；不能用待校準量具證明自己準確。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、repair、crafting、jobs、regional_trade。研究：WG-01、FICTION-CANTICLE。

<a id="content_precision_parts"></a>
## 精密零件 · content_precision_parts

MISC / matched_precision_components｜150 g｜參考估值 75 Caps｜rare。
估值理由：75 Caps 來自成套精度與難補製，不能按金屬重量直換。
[既有圖片](../../../ui/assets/items/library/supplies/precision_parts.png)｜runtime ID：尚未註冊

小盒裡的細件各有對應格位，旁邊留著型號字條。

**初見：** 一盒一百五十克匹配細件，不是任意機器的萬用零件。

**調查後可確認：** 先核對型號與公差，才能用於指定儀器修復；遺失一件也可能失配。

灰谷技工會先看規格，新希望與乾井通常只為明確設備委託採購。

候選動作：verify_tolerance、restore_instrument。來源：old_world_laboratory、gray_valley。

- 新希望：供應 none／需求 medium。指定水務儀器修復才會下單。
- 灰谷：供應 low／需求 high。技工能辨規格但很難補製成套細件。
- 乾井：供應 none／需求 high。泵站儀表失效時可能急需對應套件。

- 乾井泵站缺一個規格明確的儀表機構。 → 比對盒內細件與型號紙條，再安排維修。 代價／限制：缺一件或公差不符便不能完成組裝。
- 灰谷回收者想把細件按金屬重量散賣。 → 保留成套格位和標記，尋找真正的使用者。 代價／限制：佔用資金與存放時間，不保證立刻找到高價買家。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：拆散報廢套件可能回收少量金屬，成套匹配與標記價值消失。 候選產物：廢鐵

前置缺口：disassembly、electronics、identification、item_ownership、regional_trade、repair。研究：WG-01、FICTION-CANTICLE。

<a id="content_pump_shotgun"></a>
## 泵動散彈槍 · content_pump_shotgun

WEAPON / pump_action_shotgun｜3450 g｜參考估值 420 Caps｜rare。
估值理由：420 Caps 提案來自較少見的完整機構。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/pump_shotgun.png)｜runtime ID：尚未註冊

滑動握部積著舊油，背帶曾換成工業織帶。

**初見：** 動作部件需要清理與檢查，不能靠名稱保證連續使用。

**調查後可確認：** 泵動式散彈槍，供彈與動作配合需由後續 combat authority 定義。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

定位為有維護條件的看守裝備，遠地缺件時未必優於簡單器材。

候選動作：arrange_maintenance、delay_for_inspection。來源：industrial_security、old_world_police。

- 新希望：供應 low／需求 medium。固定糧倉守衛能安排維護，但普通農戶較少買。
- 灰谷：供應 low／需求 high。工業警備遺留與專門工坊可能配套。
- 乾井：供應 low／需求 medium。儲運場有需求，但零件依赖外來。

- 固定倉庫尋求長期器材維護。 → 將樣品與工坊服務連成委託。 代價／限制：需持續後勤，不是交槍後永久提高治安。
- 器材失靈導致護衛拒絕出發。 → 安排專業檢查並重新協商行程。 代價／限制：路程可能延誤，不可用一個 MECHANICS 門檻直接修好。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、塑膠

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_purification_tablets"></a>
## 淨水錠 · content_purification_tablets

CONSUMABLE / water_treatment_tablets｜40 g｜參考估值 32 Caps｜uncommon。
估值理由：32 Caps 反映輕便、難補充與來源可信度；不是無限淨水權。
[既有圖片](../../../ui/assets/items/library/supplies/purification_tablets.png)｜runtime ID：尚未註冊

一板獨立封裝的小錠劑，背面留有褪色批號。

**初見：** 單位是一板；包裝完整也不能證明適用所有水源。

**調查後可確認：** 核對標示與適用污染類型後，才列入有限次的處理方案。

商隊只替有批次紀錄的貨物背書，散裝無標示品不能混作同一批。

候選動作：treat_water、deliver。來源：old_world_clinic、caravan。

- 新希望：供應 low／需求 medium。正常取水時需求有限，出行者備用。
- 灰谷：供應 low／需求 high。工班離開供水點時需要備案。
- 乾井：供應 low／需求 high。長距離水源不確定，使可信批次吃緊。

- 繞路後只能找到用途待確認的取水點。 → 請懂處理的人核對水源與錠劑標示，再決定是否處理。 代價／限制：處理會消耗錠劑；不適用的污染不能靠多放幾錠解決。
- 外勤工隊要求補一批有完整批號的錠劑。 → 交付封裝完整的補給，保留批次去向記錄。 代價／限制：失去所交份數；破封或批號不清的貨不能充數。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：identification、item_ownership、regional_trade、water_treatment。研究：WG-01、WG-02。

<a id="content_radio"></a>
## 無線電 · content_radio

TOOL / portable_transceiver｜700 g｜參考估值 95 Caps｜uncommon。
估值理由：95 Caps 包括可用通訊機構，範圍與電源限制不能忽略。
[既有圖片](../../../ui/assets/items/library/supplies/radio.png)｜runtime ID：尚未註冊

手持無線電的旋鈕有磨損，側面標著值班頻段。

**初見：** 需要相容電池；聽到聲音不等於對方身份已確認。

**調查後可確認：** 可在訊號條件允許時通話或中繼，仍需共同頻段與約定。

舊值班頻段可能已換人使用，不能憑一聲回應就綁定某個 NPC。

候選動作：call、listen、relay。來源：caravan、old_world_security。

- 新希望：供應 medium／需求 medium。取水站與外勤隊有聯絡需求。
- 灰谷：供應 medium／需求 high。維修工班和商隊都需通訊。
- 乾井：供應 low／需求 high。停靠點距離長，補機仍靠外來貨。

- 兩支商隊在視線外互相等待，無法確認誰已出發。 → 使用約定頻段核對口令並轉達各自位置。 代價／限制：需要電量與可用訊號，不能自動知道另一隊位置。
- 舊頻道傳來熟悉值班號，聲音卻不同。 → 先詢問可交叉核對的資訊，決定是否回應求援。 代價／限制：回話會暴露有人收聽，沒有身份驗證不能直接增加信任。

維修：匹配型號後修接點與線路，通訊測試需另一端配合。 候選投入：銅線、電路板
拆解：只有匹配且完好的板件可保留作待測物，不能視為已修好的另一台機器。 候選產物：銅線、電路板

前置缺口：disassembly、electronics、item_ownership、navigation、npc_relationship、repair。研究：WG-03、FICTION-METRO。

<a id="content_raw_meat"></a>
## 生肉 · content_raw_meat

CONSUMABLE / uncooked_meat｜600 g｜參考估值 8 Caps｜common。
估值理由：8 Caps 低於成品肉乾，因需處理且不適合長途無照料搬運。
[既有圖片](../../../ui/assets/items/library/supplies/raw_meat.png)｜runtime ID：尚未註冊

包在厚紙裡的生肉，切口還能看見來源章記。

**初見：** 以六百克包裝計；等待與高溫會影響可用狀態。

**調查後可確認：** 由來源及保存紀錄決定能否供餐，烹調或保存各有時間與耗材。

獵人可能願意換鹽或運送服務，並非每次帶回城都有人立即收購。

候選動作：cook、preserve、deliver。來源：hunters、new_hope。

- 新希望：供應 medium／需求 medium。獵人可短距離交貨。
- 灰谷：供應 low／需求 medium。廚房可處理，前提是能及時送達。
- 乾井：供應 low／需求 low。沒有可靠保存時不積壓生鮮肉。

- 獵人背不動全部獵獲，準備把餘肉留在路邊。 → 接下短程送往廚房的肉包。 代價／限制：必須安排及時處理；多拿會擠掉自己的補給空間。
- 商隊要在兩條不同長度的路線中選一條。 → 以生肉需要及時處理為條件，協商先走有廚房的停靠點。 代價／限制：較近廚房可能偏離原路，不保證交易利潤。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、item_ownership、jobs、regional_trade。研究：WG-01、WG-02。

<a id="content_rebar_club"></a>
## 鋼筋棍 · content_rebar_club

WEAPON / improvised_club｜1800 g｜參考估值 22 Caps｜common。
估值理由：22 Caps 提案只略高於可用廢鋼；1800 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/rebar_club.png)｜runtime ID：rebar_club

一截混凝土鋼筋，握端留下被敲平的切口。

**初見：** 堅重而笨拙；拿來撐住板片前必須確認切口不會滑動。

**調查後可確認：** 建築用帶肋鋼材，沒有刀刃，也不是測試合格的起重桿。

灰谷常見的臨時器具；便宜來自回收便利，並非高品質武器。

候選動作：brace_panel、drive_stake、defend。來源：gray_valley、construction_ruins。

- 新希望：供應 medium／需求 low。可當粗用支桿，但長途運輸不劃算。
- 灰谷：供應 high／需求 low。來源多，拆解工人通常能自行找到。
- 乾井：供應 low／需求 medium。固定破損棚架有臨時需求，會與更輕工具競爭。

- 傾斜鐵皮擋住狹小通道。 → 短時間撑住鐵皮，讓同伴先通過。 代價／限制：必須留人看守，不能宣稱建築已安全。
- 營地樁頭難以敲下。 → 作為臨時鈍重物固定已有營樁。 代價／限制：需要可承受的樁頭與作業時間；不生成帳篷或營樁。

維修：只能換握布；嚴重彎折與裂縫應報廢。 候選投入：布料
拆解：失去器具身分後回收廢鋼，不能同時保留鋼筋棍。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、camping、hazards、item_ownership、regional_trade、repair、disassembly。研究：WG-01、WG-02。

<a id="content_repair_manual"></a>
## 維修手冊 · content_repair_manual

MISC / machine_service_manual｜650 g｜參考估值 150 Caps｜uncommon。
估值理由：有型號索引、完整故障表的手冊對使用相同設備的人有價值；不適配的版本較難出售。
[既有圖片](../../../ui/assets/items/library/relics/repair_manual.png)｜runtime ID：尚未註冊

最常翻的頁緣沾滿指印，工具清單上卻有兩項被鉛筆劃掉。

**初見：** 封面能辨識設備系列，內頁有油污與缺角；不確定是否符合眼前機器。

**調查後可確認：** 可按型號與版本查找檢查順序；手冊提供知識，操作仍需技術能力、工具與安全停機。

候選維修用途先限定一組設備，避免成為所有機械的通用解答或一次性技能加點書。

候選動作：identify_model、compare_fault_steps、reference_procedure。來源：workshop_shelf、maintenance_office、service_vehicle。

- 新希望：供應 low／需求 high。泵、農具等設備若型號相容便有需求，當地印製來源稀少。
- 灰谷：供應 medium／需求 high。工坊保存與交換型號資料，也可能已有重複版本。
- 乾井：供應 low／需求 high。燃料輸送設備的停機成本使相容手冊有價值。

- 新希望水泵發出異音，操作員準備直接拆開。 → 先比對型號與故障表，指出需要觀察的部位。 代價／限制：需停機檢查時間與MECHANICS相關解讀能力；查表本身不完成修理。
- 灰谷買家只缺手冊中的接線附頁。 → 在確認版本相同後提供閱讀或抄錄安排。 代價／限制：需持有人同意與抄錄時間；缺頁不能憑敘事補出，原本完整性仍有價值。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、repair、jobs、regional_trade。研究：WG-01、FICTION-CANTICLE。

<a id="content_reverse_magnetic_shard"></a>
## 逆磁片 · content_reverse_magnetic_shard

MISC / metal_repelling_fragment｜260 g｜參考估值 None Caps｜rare。
估值理由：沒有標準價格；只有願意測試特定金屬反應的工匠或研究者提出需求。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/reverse_magnetic_shard.png)｜runtime ID：尚未註冊

薄片邊緣缺了一角，旁邊散落的鐵屑像被人刻意推開。

**初見：** 一小塊測試金屬曾向外移動；反應範圍、金屬種類與力度未知。

**調查後可確認：** 可用已知材料測定有限距離內的反應；不能保證推開所有金屬、阻擋子彈或移動重門。

候選用途是材料辨識與受控機構研究，不是全用途磁力工具或護甲加成。

候選動作：test_sample_response、isolate_from_tools、seek_metallurgist。來源：anomalous_machine_ruin、sealed_sample_box、fallen_pylon。

- 新希望：供應 none／需求 low。農具使用者沒有未經測試樣本的直接需求。
- 灰谷：供應 none／需求 high。金屬工坊對不同材料的反應有實驗需求。
- 乾井：供應 none／需求 medium。運輸機件研究可能有興趣，但需與羅盤及零件分開保管。

- 修理台上的墊片總是滑離同一角落。 → 隔離薄片並用已知金屬樣本做對照。 代價／限制：需清空操作台與時間，不能在仍運作的設備上冒然測試。
- 商隊想把薄片放進裝滿零件的工具箱。 → 提出分箱保管，避免未查明的相互影響。 代價／限制：需額外容器與負重安排；分箱不代表已證明全部運輸安全。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、electronics、hazards、cargo、knowledge、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_rope"></a>
## 繩索 · content_rope

TOOL / utility_rope｜2500 g｜參考估值 30 Caps｜common。
估值理由：30 Caps 反映多次使用的固定用途，但不保證可承受任何重量。
[既有圖片](../../../ui/assets/items/candidates/rope.png)｜runtime ID：rope

粗繩盤成一圈，繩端包著便於辨認的布條。

**初見：** 保持 ITEM-1 的二千五百克；沒有先假定長度或承重等級。

**調查後可確認：** 檢查磨損、長度與固定點後，才能選擇對應的牽引或固定方案。

斷橋邊的繩索可能要留給後來者，救人和回收自用有不同代價。

候選動作：secure_cargo、lower_bundle、anchor_line。來源：caravan、settlement_workshop。

- 新希望：供應 medium／需求 medium。農務搬運會綁束物資。
- 灰谷：供應 high／需求 medium。工地有舊繩供應，但承載狀況需查。
- 乾井：供應 medium／需求 high。長途貨箱固定與道路救援需求多。

- 貨箱固定帶斷裂，下一段路坡度很大。 → 用檢查過的繩索重新固定貨箱。 代價／限制：部分繩長會被佔用；固定不等於車體能承受所有重量。
- 橋下有一只工具袋卡在矮台上。 → 在確認固定點後用繩索吊回工具袋。 代價／限制：先確認距離與重量，若必須剪斷或留下繩段要明示失去部分物品。

維修：僅修護繩端標記；承載纖維損壞不能靠包布恢復，應縮短用途或判廢。 候選投入：布料
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cargo、exploration、hazards、item_ownership、repair。研究：WG-01、LD-P01。

<a id="content_rubber"></a>
## 橡膠 · content_rubber

MISC / rubber_sheet｜400 g｜參考估值 12 Caps｜common。
估值理由：12 Caps 取常用密封材料尺度，來源和老化狀況會改變可用性。
[既有圖片](../../../ui/assets/items/library/supplies/rubber.png)｜runtime ID：尚未註冊

捲成小片的橡膠有切割記號，表面沒有大裂口。

**初見：** 四百克按片料計，耐油耐熱能力尚未確認。

**調查後可確認：** 經材質確認可裁切墊片或護套；飲水與燃料用途不能隨意互換。

乾井修泵看重相容性，新希望則在乎接水部位是否適用。

候選動作：cut_gasket、patch_cover、deliver_material。來源：gray_valley、old_world_transport。

- 新希望：供應 low／需求 medium。接水與農具修補需合用途材料。
- 灰谷：供應 high／需求 medium。廢車和工業庫存有來源。
- 乾井：供應 low／需求 high。燃料接點需要已確認相容的密封料。

- 水壺蓋墊片硬化，使用者想拿任何膠片來補。 → 先核對材料是否適合接觸飲水，再裁片。 代價／限制：未知膠料不能直接使用，裁切消耗材料。
- 乾井油管接頭滲漏，工班缺相容墊片。 → 把已辨識橡膠交給技工製作合尺寸件。 代價／限制：需要停機、材料相容性和測試，不保證一次修好。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、item_ownership、regional_trade、repair。研究：WG-01、WG-03。

<a id="content_rusted_knife"></a>
## 生鏽小刀 · content_rusted_knife

WEAPON / utility_blade｜250 g｜參考估值 18 Caps｜common。
估值理由：18 Caps 提案反映缺口與修理負擔；250 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/rusty_knife.png)｜runtime ID：rusted_knife

刀尖早已缺了一角，木柄刻著一排難以辨認的姓氏。

**初見：** 能割薄繩，鏽斑和鬆動握柄使它不適合精細工作。

**調查後可確認：** 普通家用短刃；缺口需要金屬加工，清潔外表不代表適合處理傷口。

廉價短刃來自家庭雜物，新的武器 authority 不得由 blade 標籤直接取得。

候選動作：cut_rope、scrape_label、defend。來源：settlement_households、abandoned_homes。

- 新希望：供應 high／需求 medium。農戶常用小刀處理包裝，但鏽刃收購價有限。
- 灰谷：供應 high／需求 low。拆屋回收常見，工坊偏好狀態更好的刃具。
- 乾井：供應 medium／需求 medium。旅人需要便宜備用刀，品質差異必須可見。

- 貨袋被舊繩纏死。 → 割斷繩結取出有主的貨物。 代價／限制：需失主同意；割下的繩不再可回收。
- 金屬牌被厚漆遮住。 → 刮出部分編號，再決定是否攜走。 代價／限制：耗調查時間；只能露出原有文字，不能憑刀生成情報。

維修：提案：技工評估缺口後才能換修，材料不代表可自行修復。 候選投入：鋼材、布料
拆解：只回收失去刀具用途的金屬，不回收另一把完整小刀。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、knowledge、item_ownership、regional_trade、repair、disassembly。研究：WG-01、WG-02。

<a id="content_salt"></a>
## 鹽 · content_salt

CONSUMABLE / preserving_salt｜250 g｜參考估值 10 Caps｜common。
估值理由：10 Caps 以小袋耐運商品估值，來源與用途確認影響是否有人收。
[既有圖片](../../../ui/assets/items/library/supplies/salt.png)｜runtime ID：尚未註冊

粗粒鹽放在厚紙袋裡，袋口有結晶痕。

**初見：** 一袋兩百五十克；工業鹽與食用批次需辨清。

**調查後可確認：** 已辨明用途的鹽可入廚房或保存工序；不能隨意把材料當藥物。

乾井附近鹽貨可隨燃料商隊流通，但農業聚落的保存需求另有季節。

候選動作：season、preserve、exchange。來源：dry_well、salt_flat。

- 新希望：供應 low／需求 high。保存收成和肉食時有需求。
- 灰谷：供應 medium／需求 medium。商隊轉運，廚房與材料批次分開。
- 乾井：供應 high／需求 medium。鄰近鹽貨來源，仍要分辨用途。

- 肉販想在出車前處理一批肉，但保存材料用完。 → 交付已確認可食用的鹽作有限批次加工。 代價／限制：鹽會被消耗；保存仍需要工序，不能瞬間消除腐敗。
- 乾井貨商把食用與工業批次袋子放在一起。 → 要求分清標記後才接運其中一批。 代價／限制：清點會延遲裝車，不能按同一價格收下未知批次。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、item_ownership、regional_trade。研究：WG-01、WG-02、LD-P01。

<a id="content_sandstorm_rifle"></a>
## 沙暴步槍 · content_sandstorm_rifle

WEAPON / desert_service_rifle｜3900 g｜參考估值 430 Caps｜uncommon。
估值理由：430 Caps 提案包含地方修配與防砂配套。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/sandstorm_rifle.png)｜runtime ID：尚未註冊

槍罩繫著多層防砂布，背帶採乾井常用的縫法。

**初見：** 防砂處理降低維護負擔的構想仍需規則，不能免疫沙塵。

**調查後可確認：** 為地方環境修配的長槍，覆布和接合處需定期檢查。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

地域適應來自保養與供應網，而非武器名字本身帶 buff。

候選動作：inspect_dust_cover、trace_regional_work。來源：dry_well、desert_workshops。

- 新希望：供應 none／需求 low。農業路線不常需要額外防砂配套。
- 灰谷：供應 low／需求 medium。替乾井商隊服務的工坊有需求。
- 乾井：供應 medium／需求 high。當地有維護經驗與相容配件來源。

- 沙塵季出發前護衛隊檢查所有器材。 → 請熟悉乾井工藝者確認覆布與接合。 代價／限制：耗準備時間，不能保證风暴中射擊無風險。
- 路上拾到有當地縫線的防砂套。 → 交給乾井維修者核對可能的商隊。 代價／限制：僅形成線索，不直接取得槍械或定位持有人。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：布料、橡膠、彈簧
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、布料

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_scrap_iron"></a>
## 廢鐵 · content_scrap_iron

MISC / sorted_iron_scrap｜1000 g｜參考估值 8 Caps｜common。
估值理由：8 Caps 以重、常見且仍需加工的材料定位。
[既有圖片](../../../ui/assets/items/library/supplies/scrap_iron.png)｜runtime ID：尚未註冊

分出尖角的廢鐵束還能看出幾塊舊機殼。

**初見：** 以一千克已粗分選的鐵料計，沒有保證牌號。

**調查後可確認：** 可進一步分選供低要求工件使用，不等於精密零件或所有 scrap 資源。

灰谷有大量回收來源，運到別處前要確認買家接受的形狀和雜質。

候選動作：sort、deliver_material、brace。來源：gray_valley、industrial_ruin。

- 新希望：供應 low／需求 medium。可補簡單農具構件，長途搬運未必合算。
- 灰谷：供應 high／需求 medium。回收多，需再分選才有用途。
- 乾井：供應 medium／需求 medium。車場有零散來源，也需替換支架材料。

- 灰谷收貨場把尖銳混料也標成可加工鐵。 → 先分選可用料再交付，留下雜物清單。 代價／限制：分選耗時且有廢棄量，不保證原重量全部合格。
- 小橋的路牌支架折了一截。 → 提供尺寸合適的鐵片讓工匠加工。 代價／限制：需要工具與固定方案，不能拿任意鐵塊直接完成修復。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、item_ownership、regional_trade、repair。研究：WG-01、WG-02。

<a id="content_scrap_iron_armor"></a>
## 拼裝鐵甲 · content_scrap_iron_armor

APPAREL / salvage_plate_harness｜6500 g｜參考估值 190 Caps｜uncommon。
估值理由：190 Caps 提案偏重本地材料取得容易，6500 g 為明显負擔。
[既有圖片](../../../ui/assets/items/library/clothing/scrap_iron_armor.png)｜runtime ID：尚未註冊

不同厚度的鐵片被固定在皮帶上，走動時會互相碰撞。

**初見：** 沉重且需要合身，聲響和活動空間都是代價。

**調查後可確認：** 地方拼接護具，護片與承重皮帶需分別檢查。

低材料價格與高攜行成本並存，不能等同優良軍甲。

候選動作：inspect_harness、transport_local_armor。來源：gray_valley、local_smiths。

- 新希望：供應 low／需求 low。農業出行不願攜帶重護具。
- 灰谷：供應 medium／需求 medium。固定守衛與在地修配有需求。
- 乾井：供應 low／需求 low。遠行重量與散熱限制購買意願。

- 工匠展示不同尺寸的拼裝護具。 → 量身調整已取得的承重帶。 代價／限制：需時間與皮料；未檢驗前不宣稱防護改善。
- 遠行貨物超出運輸計畫。 → 選擇留下重護具或另安排托運。 代價／限制：失去當段裝備機會，不由物品改寫既有容量。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：鋼材、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、cargo、identification、item_ownership、regional_trade、repair、disassembly。研究：WG-02、WG-05。

<a id="content_scrap_machete"></a>
## 廢鐵砍刀 · content_scrap_machete

WEAPON / salvage_machete｜1200 g｜參考估值 48 Caps｜common。
估值理由：48 Caps 提案體現在地加工與有限材料品質；1200 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/scrap_machete.png)｜runtime ID：scrap_machete

刀背保留著原鋼板的折線，刃口卻磨得整齊。

**初見：** 能處理輕枝和繫帶，厚金屬不是它的工作。

**調查後可確認：** 回收鋼材製成的砍刀，材料品質須逐把檢查。

灰谷的回收工藝有地方特色，但不把每把拼裝刀寫成同樣損壞。

候選動作：clear_brush、cut_binding。來源：gray_valley、local_smiths。

- 新希望：供應 medium／需求 high。開闢被灌木遮住的小徑有需求。
- 灰谷：供應 high／需求 medium。在地成品多，交易重點是工匠與刃口品質。
- 乾井：供應 medium／需求 low。沙地植被較少，通常作旅行備刃。

- 荒廢菜圃入口被藤蔓遮住。 → 清出一人通行的開口。 代價／限制：耗時間且會暴露來訪痕跡，不代表清除整片菜圃。
- 拋棄車架的繫帶拉住可回收物。 → 割開繫帶取下已確認無主的物件。 代價／限制：繫帶損失；不能切開車架或直接獲得未知戰利品。

維修：只對可修刃口與握部生效，裂穿刀身應退役。 候選投入：鋼材、布料
拆解：廢刀只轉入金屬回收候選，不形成完整成品循環。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、disassembly、item_ownership、regional_trade、repair。研究：WG-01、WG-05。

<a id="content_scrap_rifle"></a>
## 廢土拼裝步槍 · content_scrap_rifle

WEAPON / workshop_rifle｜4100 g｜參考估值 220 Caps｜uncommon。
估值理由：220 Caps 提案扣除重量與個體差异造成的後勤負擔。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/scrap_rifle.png)｜runtime ID：尚未註冊

木托、金屬罩與背帶明顯來自不同年代。

**初見：** 較重但原工坊可能就在灰谷，來源可追查。

**調查後可確認：** 地方修配長槍，每把的相容部件須個別建檔。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

可接近的維修者是優點，跨區缺乏相容資料是代價。

候選動作：register_workshop_service、evaluate_load。來源：gray_valley、salvage_workshops。

- 新希望：供應 low／需求 medium。農戶可透過灰谷委託維修，往返時間是成本。
- 灰谷：供應 high／需求 medium。本地修配工坊有售後意願。
- 乾井：供應 low／需求 low。遠離製作者時難以保證維修，買家謹慎。

- 原工坊願意替自家器材做巡迴保養。 → 用製作記號預約檢查。 代價／限制：等候實際工匠，不自動減少世界中的修理成本。
- 長途護送考慮更換笨重裝備。 → 衡量留用的維護便利與攜重。 代價／限制：更換必須有實際買家和替代物，不能按一下升級。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：鋼材、彈簧、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_screwdriver"></a>
## 螺絲起子 · content_screwdriver

TOOL / screwdriver｜180 g｜參考估值 12 Caps｜common。
估值理由：12 Caps 是容易攜帶和補充的入門工具價格提議。
[既有圖片](../../../ui/assets/items/library/supplies/screwdriver.png)｜runtime ID：尚未註冊

平整尖端與握柄間有一道更換過的固定環。

**初見：** 尖端形狀可見；與螺絲不匹配時不能硬套。

**調查後可確認：** 可拆相符蓋板與調整螺絲；不兼作安全的帶電探針或重撬桿。

工匠在乎尖端是否仍合尺寸，多把不同規格不等於同一萬用工具。

候選動作：remove_cover、adjust_screw、lend。來源：gray_valley、old_world_home。

- 新希望：供應 medium／需求 medium。家用設備維護需求分散。
- 灰谷：供應 high／需求 high。工地與電子修理都使用，規格需要分清。
- 乾井：供應 low／需求 medium。泵站護蓋要維護，從商隊補充。

- 舊收音機的蓋板擋住型號牌。 → 用匹配尖端卸開蓋板以讀取型號。 代價／限制：先確認安全斷電；拆蓋不等於電子故障已修復。
- 新希望工人把螺絲起子拿來撬粗木箱。 → 借工具前改找正確開箱方式，保留尖端完整。 代價／限制：不能把細工具當重撬桿，拒借可能延誤搬運。

維修：需匹配材料重整握柄或更換尖端，不把磨平工具直接宣稱已恢復。 候選投入：鋼材、塑膠
拆解：分離可用金屬與握柄材料，實際可回收量等待拆解規則。 候選產物：廢鐵、塑膠

前置缺口：disassembly、electronics、exploration、item_ownership、repair。研究：WG-01、WG-02。

<a id="content_sealed_cargo_crate"></a>
## 密封貨箱 · content_sealed_cargo_crate

CONTAINER / sealed_transport_crate｜7800 g｜參考估值 185 Caps｜uncommon。
估值理由：185 Caps 提案反映箱體與封條槽價值，不含貨物。
[既有圖片](../../../ui/assets/items/library/clothing/sealed_cargo_crate.png)｜runtime ID：尚未註冊

箱邊有多次撬開又修補的印痕，封條槽卻仍完整。

**初見：** 適合可追溯運輸，封條只能显示是否被動過，不能防止一切偷竊。

**調查後可確認：** 7800 g 為空箱；內裝貨物、封條和所有權都需分別建模。

此箱不自動成為商隊或增加玩家容量，重物通常需運輸安排。

候選動作：record_cargo_seal、transfer_sealed_load。來源：gray_valley、freight_workshops、dry_well。

- 新希望：供應 low／需求 medium。較昂貴農產或種子運輸才值得使用。
- 灰谷：供應 high／需求 high。工業成品與零件托運需要硬箱。
- 乾井：供應 medium／需求 high。燃料相關精密件需防串貨與交接追蹤。

- 收貨方發現封條記號與貨單不符。 → 先共同驗封並隔離爭議貨物。 代價／限制：需當事人見證，不能直接判定偷竊者或開箱取走。
- 商隊超載但必須保住某件精密物。 → 選擇保留硬箱並放棄別項貨物運輸。 代價／限制：明確失去裝載機會，不能以箱子賺出額外容量。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：鋼材、橡膠
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：廢鐵、橡膠

前置缺口：equipment、cargo、jobs、reputation、item_ownership、regional_trade、repair、disassembly。研究：WG-02、FICTION-METRO。

<a id="content_seeds"></a>
## 種子 · content_seeds

CONSUMABLE / labelled_seed_packet｜100 g｜參考估值 30 Caps｜uncommon。
估值理由：30 Caps 取有來源品種的準備價值，不能按未來整片收成估現價。
[既有圖片](../../../ui/assets/items/library/supplies/seeds.png)｜runtime ID：尚未註冊

小紙袋外寫著作物名、收集地和上一季日期。

**初見：** 一百克一袋種子；有品名不保證仍能發芽或適合新地點。

**調查後可確認：** 可核對品種、做有限試種或交給農務者；收成需要未來農務規則。

新希望保存種源，乾井的求購更可能是試種而非立即大量播種。

候選動作：verify_variety、deliver_for_sowing、trial_plot。來源：new_hope、old_world_seed_store。

- 新希望：供應 high／需求 high。保存種源與下一季播種都需要，供需可以同時高。
- 灰谷：供應 low／需求 low。少量院落栽種，不是主要產業。
- 乾井：供應 none／需求 medium。缺水環境只為明確試種計畫採購。

- 乾井有人想把一袋種子當作明年豐收保證。 → 先交給農務者核對品種並安排小範圍試種。 代價／限制：消耗試種份量且需時間、水和農務權限，不預定收成。
- 新希望借出種源時希望保留原產記錄。 → 接下送種工作並保護紙袋標籤。 代價／限制：破損或混種會破壞來源資訊，不能按重量補另一品種。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：crafting、identification、item_ownership、jobs、regional_trade。研究：WG-03、LD-P01。

<a id="content_semi_auto_rifle"></a>
## 半自動步槍 · content_semi_auto_rifle

WEAPON / semi_auto_rifle｜3700 g｜參考估值 470 Caps｜rare。
估值理由：470 Caps 提案反映完整機構與較稀少維修資源。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/semi_auto_rifle.png)｜runtime ID：尚未註冊

金屬表面尚好，保養盒卻只剩一張失色的零件圖。

**初見：** 供彈與動作部件更需要相容支援，不能靠少量廢鐵任意補齊。

**調查後可確認：** 半自動長槍，失去零件圖會增加檢修難度。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

有準備才值得帶，讓普通可修長槍仍有位置。

候選動作：compare_parts_diagram、document_provenance。來源：old_world_stores、military_surplus。

- 新希望：供應 none／需求 low。一般獵務難維持此類支援。
- 灰谷：供應 low／需求 high。專門工坊可評估零件圖與整機用途。
- 乾井：供應 low／需求 medium。有後勤的護運隊願意收，零散旅人未必。

- 遺跡發現只剩部分內容的零件圖。 → 與本體對照找出需送檢的部位。 代價／限制：需要知識與時間，圖紙不是自動修理配方。
- 買家只收能確認來源的舊槍。 → 提供保养盒與所有權記錄。 代價／限制：缺證時可以拒買，不用殺價判定抹去來源問題。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、精密零件、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、鋁材

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_shadowless_glass"></a>
## 無影玻璃 · content_shadowless_glass

MISC / unusual_optical_plate｜340 g｜參考估值 None Caps｜rare。
估值理由：沒有一般玻璃的通用估價；光學研究者可能因可重複現象願意接收。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/shadowless_glass.png)｜runtime ID：尚未註冊

把它靠在牆前，牆上的暗痕卻不像它的輪廓。

**初見：** 在一種光線角度下看不到預期影子，其他角度尚未比較。

**調查後可確認：** 可記錄特定光源與角度的透射現象；不證明穿過它的人會隱形，也不能假定不會割傷。

候選以觀察、標記與運送易碎物為核心；名稱是地方俗稱，不是免疫偵測的規則。

候選動作：compare_lighting、mark_edges、inspect_refraction。來源：optics_lab、anomalous_window_frame、sealed_crate。

- 新希望：供應 none／需求 low。一般窗戶需求偏重耐用，特殊樣本沒有直接民生用途。
- 灰谷：供應 none／需求 high。光學與照明研究者會在意原片邊緣與來源。
- 乾井：供應 none／需求 medium。地景測量委託可能願意研究光線現象，但不常備進貨。

- 廢樓窗框裡看似空著，布條卻被割開。 → 先用可見標記圈出玻璃邊緣再安排取下。 代價／限制：需保護包材與拆卸時間；接觸傷害須有正式hazards/injury規則。
- 研究者想測試它能否遮住路標燈。 → 在封閉測試區比較不同角度的照明。 代價／限制：需光源與時間，不能拿公共路標直接實驗或宣稱永久隱蔽。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、lighting、hazards、injury、cargo、knowledge、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_signal_receiver"></a>
## 訊號接收器 · content_signal_receiver

TOOL / directional_receiver｜1300 g｜參考估值 180 Caps｜rare。
估值理由：180 Caps 取專門測量與稀少零件定位，而非保證發現秘密。
[既有圖片](../../../ui/assets/items/library/supplies/signal_receiver.png)｜runtime ID：尚未註冊

帶刻度的接收器連著可折天線，沒有發話按鍵。

**初見：** 它擅長接收與比對訊號，不等於雙向無線電。

**調查後可確認：** 可記錄頻段與方向變化，來源判斷還要位置和技術交叉驗證。

舊廣播、故障設備和未知現象都可能發聲，不能只剩一種寶箱用途。

候選動作：trace_signal、record_band、compare_emissions。來源：old_world_communications。

- 新希望：供應 none／需求 low。偶爾調查水泵控制訊號，不常備專機。
- 灰谷：供應 low／需求 high。舊工業通訊設施有調查需求。
- 乾井：供應 none／需求 medium。遠征隊追查中繼訊號時會委託。

- 每天傍晚都能在同一段路聽見短促雜訊。 → 記錄不同位置的接收變化，找出值得調查的方向。 代價／限制：耗電和時間，方向只是線索而非確切入口。
- 技工懷疑停機與附近設備訊號相互干擾。 → 在約定測試時段記錄頻段，交給技工比對。 代價／限制：需要雙方協作，接收器不會自行修正干擾來源。

維修：需匹配測量部件並重新校驗，不把任意控制板視為替代。 候選投入：銅線、精密零件、電路板
拆解：保存部分待測板件會犧牲整機與校驗資訊。 候選產物：銅線、電路板

前置缺口：disassembly、electronics、exploration、identification、item_ownership、knowledge、repair。研究：WG-06、FICTION-WOOL。

<a id="content_silence_box"></a>
## 沉默盒 · content_silence_box

MISC / radio_interference_object｜620 g｜參考估值 None Caps｜rare。
估值理由：只有明確通訊研究或隔離需求，不以尚未驗證的隱匿能力出售；普遍價格保持未知。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/silence_box.png)｜runtime ID：尚未註冊

沒有旋鈕的方盒一靠近桌邊，旁邊收音機的聲音便斷成幾截。

**初見：** 一部收音機曾在附近失去清楚訊號；不知道受影響頻段、範圍或原因。

**調查後可確認：** 可比對不同距離、頻段與設備的干擾；不能假定遮蔽所有通訊，更不能讓持有者無法被發現。

候選價值同時包含調查與不方便：運送它可能需要避開己方聯絡設備。

候選動作：map_interference、isolate_from_radio、seek_signal_specialist。來源：abandoned_relay、sealed_electronics_case、anomalous_control_room。

- 新希望：供應 none／需求 medium。供水值班若靠無線電聯絡，會關注干擾來源而非希望擁有干擾器。
- 灰谷：供應 none／需求 high。訊號維修者可能願意建立測試紀錄。
- 乾井：供應 none／需求 high。商隊聯絡站有隔離與查明問題的動機，但不代表可常規交易。

- 灰谷聯絡桌在同一時段反覆失去聲音。 → 移開樣本並比較距離，找出是否與盒子相關。 代價／限制：需協調測試時段與備用聯絡方式；一次恢復不能證明全部問題解決。
- 買家要求把盒子帶到正在值班的商隊電臺展示。 → 改約封閉場地測試或拒絕干擾公共聯絡。 代價／限制：需另找地點與時間；不以神祕能力直接切斷NPC通信狀態。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、identification、hazards、cargo、knowledge、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、FICTION-METRO。

<a id="content_single_shot_rifle"></a>
## 單發獵槍 · content_single_shot_rifle

WEAPON / single_shot_hunting_rifle｜2750 g｜參考估值 160 Caps｜common。
估值理由：160 Caps 提案保留新人可追求的完整器材。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/single_shot_rifle.png)｜runtime ID：尚未註冊

木托磨出掌形凹陷，沒有多餘裝飾。

**初見：** 結構用途單純，適合懂得辨識獵場的人，而非保證命中。

**調查後可確認：** 單發獵用長槍，裝填節奏需要後續戰鬥規則呈現。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

低成本獵務工具可支撐普通工作，不能以採集按鈕無限生肉。

候選動作：prepare_hunt、trace_repair_mark。來源：new_hope、hunters。

- 新希望：供應 high／需求 high。農獵生活常見，當地有維護經驗。
- 灰谷：供應 medium／需求 low。狹窄廢墟限制長槍用途。
- 乾井：供應 low／需求 medium。沿途獵務可能需要，但補給受路線限制。

- 農戶尋人查明夜間損壞圍欄的動物。 → 先觀察足跡，攜已裝備獵槍作後備。 代價／限制：武器不取代追蹤知識，無目標不得直接獲得獵物。
- 長槍原主留下維修記號。 → 拜訪當地槍匠尋找持有人線索。 代價／限制：需詢問與對方同意，不從記號推定死因。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、鋼材、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_single_shot_shotgun"></a>
## 單管散彈槍 · content_single_shot_shotgun

WEAPON / single_barrel_shotgun｜2950 g｜參考估值 185 Caps｜common。
估值理由：185 Caps 提案維持可取得性並保留檢驗成本。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/single_shot_shotgun.png)｜runtime ID：尚未註冊

簡單的木托被油布包著，農舍門框上有相同磨痕。

**初見：** 常見於鄉間守護器材，仍受單次裝填和補給限制。

**調查後可確認：** 單管散彈槍，槍況必須檢驗，不能因結構簡單免維護。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

普通護田任務的器材候選，不把散彈當對所有目標都有效。

候選動作：prepare_store_watch、verify_ownership。來源：new_hope、households。

- 新希望：供應 medium／需求 high。農舍與護田人員有具體需求。
- 灰谷：供應 medium／需求 medium。回收商能找到舊民用器材。
- 乾井：供應 low／需求 medium。短程看守需求存在，補給須另核實。

- 糧倉主想請人守住搬運區。 → 帶已核驗裝備接受工作說明。 代價／限制：需明確守則與彈藥來源；不能只用槍械圖片領任務。
- 農舍保管箱的主人已搬離。 → 先查明所有權再處理箱中槍械。 代價／限制：耗查訪時間，不能因空屋就默認無主。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_sleeping_bag"></a>
## 睡袋 · content_sleeping_bag

TOOL / bedroll｜1700 g｜參考估值 38 Caps｜common。
估值理由：38 Caps 主要是填料、縫製與攜行成本。
[既有圖片](../../../ui/assets/items/library/supplies/sleeping_bag.png)｜runtime ID：尚未註冊

厚布睡袋的內襯被曬得發白，拉鍊仍能閉合。

**初見：** 一個完整睡袋，乾燥程度比外觀新舊更重要。

**調查後可確認：** 提供休息用的隔離層，但不能代替安全營地與遮雨處。

旅人會借睡袋給傷疲者，也會約定交還地點；不是穿上即永久增益。

候選動作：camp、lend、dry。來源：caravan、settlement_workshop。

- 新希望：供應 medium／需求 medium。裁縫可維修，外出工作者需要。
- 灰谷：供應 low／需求 medium。夜班工棚與旅人採買。
- 乾井：供應 medium／需求 high。乾井是長途出行補給點。

- 疲倦旅人把披風鋪在濕地上準備睡。 → 借出乾睡袋並協助另找可休息地點。 代價／限制：借用期間自己少了休息用品，也不能消除營地危險。
- 睡袋內襯在過河後濕透。 → 選擇停靠曬乾而不是立刻繼續遠行。 代價／限制：花時間並尋找安全場所，不能按一下就得到完整休息效果。

維修：修補外布及縫線，濕透填料仍要處理；不增加保暖等級。 候選投入：布料
拆解：可裁取未污染外布，填料不保證可用；整個睡袋隨之失去完整性。 候選產物：布料

前置缺口：camping、disassembly、item_ownership、repair。研究：WG-03、FICTION-ROAD。

<a id="content_sniper_rifle"></a>
## 狙擊步槍 · content_sniper_rifle

WEAPON / precision_rifle｜5200 g｜參考估值 980 Caps｜rare。
估值理由：980 Caps 提案反映少見完整配套，物流與檢驗費另計。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/sniper_rifle.png)｜runtime ID：尚未註冊

長盒內的軟墊已壓扁，鏡架上有精細的檢查刻線。

**初見：** 重且怕碰撞，觀察配件與武器操作不能混成一個萬能按鈕。

**調查後可確認：** 精密長槍及其配套需要專業檢驗，鏡片清楚不代表整機準確。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

屬少量有後勤支持的特殊器材，不作每張地圖都能撿到的高級掉落。

候選動作：protect_precision_cargo、identify_optics。來源：military_specialists、sealed_depots。

- 新希望：供應 none／需求 low。農戶難以維護，可能只接受替專人轉運。
- 灰谷：供應 low／需求 medium。精密工坊或特定委託人有需求。
- 乾井：供應 none／需求 medium。特定遠行隊有需求，絕非常備市場貨。

- 精密器材委託要求原盒交付。 → 把長盒當有主貨物護送。 代價／限制：占負重與搬運空間，不能擅自拆盒試用。
- 未知鏡架有一組維修編號。 → 找光學技師辨識配套來源。 代價／限制：支付檢驗代價，不因辨識成功直接提高角色命中。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：精密零件、玻璃、鋼材
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、玻璃

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_snub_revolver"></a>
## 短管左輪 · content_snub_revolver

WEAPON / compact_revolver｜720 g｜參考估值 250 Caps｜uncommon。
估值理由：250 Caps 提案包含輕便需求而非單純傷害提升。 重量按空槍提案，價格不是現有商店報價。
[既有圖片](../../../ui/assets/items/library/weapons/snub_revolver.png)｜runtime ID：尚未註冊

短小的外形藏在已磨軟的皮袋裡。

**初見：** 便於減輕行李；短小不代表在所有距離都同樣適用。

**調查後可確認：** 短管轉輪槍，需要專門檢查握持和機件磨耗。 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。

為短程出行保留輕裝選擇，不授予免費潛行或先手。

候選動作：prepare_light_load、declare_sidearm。來源：caravan_traders、old_households。

- 新希望：供應 low／需求 low。農務更重視通用長工具與獵具。
- 灰谷：供應 low／需求 medium。短程信使與商人有攜行需求。
- 乾井：供應 medium／需求 medium。商隊人員偏好便攜備用器材，但仍需補給。

- 信使出發前必須刪減行李。 → 在有正式裝備規則後選擇較輕的自衛器材。 代價／限制：仍占實際負重與裝備位，不增加攜帶容量。
- 守門人要求逐件申報小型武器。 → 申報並接受寄存。 代價／限制：不能靠造型避開檢查；寄存後暫時無法使用。

維修：提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。 候選投入：彈簧、皮革
拆解：拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、identification、knowledge、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-02、LD-P01。

<a id="content_spear"></a>
## 長矛 · content_spear

WEAPON / hunting_spear｜2300 g｜參考估值 60 Caps｜common。
估值理由：60 Caps 提案適合普通護田器具；2300 g 不包含携行架。
[既有圖片](../../../ui/assets/items/library/weapons/spear.png)｜runtime ID：尚未註冊

桿身上綁著補強皮條，尖頭比桿子保存得更好。

**初見：** 長度提供距離，也使它難收進狹窄通道。

**調查後可確認：** 可拆換的矛頭與木桿；桿身裂痕不能靠磨利矛頭補救。

農獵社群看重可修桿身與熟悉操作，裝備需求不由價格階級決定。

候選動作：probe_shallow_ground、hold_distance。來源：new_hope、hunting_parties。

- 新希望：供應 high／需求 high。獵人和護田隊熟悉長柄器具。
- 灰谷：供應 medium／需求 low。廢墟狹窄，工人偏好短工具。
- 乾井：供應 low／需求 medium。商隊守夜偶有需求，長桿運輸不便。

- 淺泥覆住小路上的坑洞。 → 站在安全邊緣試探前方近處地面。 代價／限制：只能探到桿長內，不能確認整段沼地安全。
- 野獸阻住通行而仍有退路。 → 以已裝備長矛保持距離後撤。 代價／限制：需未來戰鬥判定，無法保證嚇退；持矛不等於會使用。

維修：矛頭與綁束可評估修繕，木桿材料另待定義。 候選投入：鋼材、皮革
拆解：只保留金屬頭與可用皮束，不產生完整替代矛。 候選產物：廢鐵、皮革

前置缺口：equipment、combat_extension、exploration、hazards、item_ownership、regional_trade、repair、disassembly。研究：WG-01、LD-P01。

<a id="content_spices"></a>
## 香料 · content_spices

CONSUMABLE / spice_packet｜80 g｜參考估值 30 Caps｜uncommon。
估值理由：30 Caps 以輕便外來貨定位，需求集中在廚師和特定買家。
[既有圖片](../../../ui/assets/items/library/supplies/spices.png)｜runtime ID：尚未註冊

一包少量香料混著乾葉與碎粒，外面寫著產區。

**初見：** 八十克一包，香氣不是來源真偽的充分證據。

**調查後可確認：** 辨明批次後可供烹調或比較商路來源，沒有固定社交增益。

同一道料理可讓居民認出舊鄉味道，但不能直接證明贈送者身份。

候選動作：season、identify_origin、exchange。來源：caravan、new_hope。

- 新希望：供應 medium／需求 low。部分本地品種易得，外來風味另找買家。
- 灰谷：供應 low／需求 medium。聚落廚房想區別普通供餐。
- 乾井：供應 low／需求 medium。旅店會為指定客人預訂，非無限需求。

- 乾井旅店想重現外來商人的家鄉料理。 → 提供有產地記錄的香料，請廚師先辨味。 代價／限制：只改變供餐內容，不創造固定社交增益。
- 兩條商路的貨商都聲稱自己帶來原產香料。 → 比對封裝與買家舊記錄，保留可查證差異。 代價／限制：沒有證據時只能維持未知，不能靠香味直接判定誰說謊。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、identification、item_ownership、knowledge、regional_trade。研究：WG-02、LD-P01。

<a id="content_spring"></a>
## 彈簧 · content_spring

MISC / steel_spring｜80 g｜參考估值 8 Caps｜common。
估值理由：8 Caps 是小而常見的替換件估值，匹配錯誤會失去用途。
[既有圖片](../../../ui/assets/items/library/supplies/spring.png)｜runtime ID：尚未註冊

一根彈簧被紙筒套住，末端彎鉤仍完整。

**初見：** 一根八十克零件；尺寸、回彈與用途需對照。

**調查後可確認：** 可恢復匹配的扣件或機構，不提供通用武器強化。

門扣、工具盒和設備機構需要不同彈簧，不把所有形狀視作同一配方材料。

候選動作：restore_latch、match_component。來源：gray_valley、industrial_ruin。

- 新希望：供應 medium／需求 low。日用扣件可拆取，需求零散。
- 灰谷：供應 high／需求 medium。細機構維修常用。
- 乾井：供應 low／需求 medium。貨車門扣與箱扣需合規替換件。

- 驛站的帳本櫃扣不上，管理者怕風吹散紙張。 → 找匹配彈簧交給維修者恢復扣件。 代價／限制：規格錯誤會卡住機構，不能只按重量替代。
- 收藏者想保留完整老機構，買家卻只要裡面的彈簧。 → 先協商是否拆件或維持原物。 代價／限制：拆出便失去原機構完整性，兩個價值不能同時兌現。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：報廢彈簧僅保留材料，不保留回彈性能。 候選產物：廢鐵

前置缺口：crafting、disassembly、identification、item_ownership、repair。研究：WG-01、WG-05。

<a id="content_stab_vest"></a>
## 防刺背心 · content_stab_vest

APPAREL / stab_resistant_vest｜2100 g｜參考估值 230 Caps｜uncommon。
估值理由：230 Caps 假設內襯可驗證且側帶完整。
[既有圖片](../../../ui/assets/items/library/clothing/stab_vest.png)｜runtime ID：尚未註冊

分層內襯藏在普通背心裡，側帶有不同主人的調整痕。

**初見：** 需要合身與完整內襯；名稱不是免傷保證。

**調查後可確認：** 防刺設計背心，不能當成防彈衣或化學防護。

以特定威脅下的準備作為定位，效果與傷害權限後續再定。

候選動作：fit_protective_vest、inspect_layers。來源：security_contractors、old_world_civic。

- 新希望：供應 none／需求 medium。近身護送工作有需求，但無在地製造。
- 灰谷：供應 low／需求 high。倉庫守衛與器材檢驗者需要。
- 乾井：供應 low／需求 medium。商隊保護有需求，合身尺碼限制交易。

- 護衛隊要求檢查每個人的防護尺寸。 → 調整已有背心並接受檢視。 代價／限制：需時間與合適尺碼，不提升未定義的數值。
- 二手商把破損內襯藏在完整外衣下。 → 先拆開檢驗再決定是否購買。 代價／限制：需賣方允許，檢驗不是免費得知全部歷史。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、精密零件
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、combat_extension、identification、hazards、item_ownership、regional_trade、repair、disassembly。研究：WG-04、WG-05。

<a id="content_static_bone"></a>
## 靜電骨 · content_static_bone

MISC / charge_accumulating_fragment｜190 g｜參考估值 None Caps｜rare。
估值理由：只有特定靜電研究需求，未驗證能量輸出前不按電池或發電設備計價。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/static_bone.png)｜runtime ID：尚未註冊

骨狀碎片上常黏著細小灰塵，隔著布也能聽見輕微劈啪聲。

**初見：** 靠近輕薄材料時有吸附現象，不知道是不是普通靜電或其他原因。

**調查後可確認：** 可記錄濕度、接觸材料與累積電荷的關係；目前不證明可持續供電或安全接觸燃料。

候選可形成保存與運輸難題，不能成為無限電池或沒有代價的電擊武器。

候選動作：isolate_charge、compare_dry_conditions、transfer_to_specialist。來源：dry_channel、anomalous_scrap_nest、sample_locker。

- 新希望：供應 none／需求 low。一般工作缺少用途，保管者更在意避免接觸易燃物。
- 灰谷：供應 none／需求 high。電學工匠可能願做受控對照。
- 乾井：供應 none／需求 medium。燃料場所會要求隔離，有安全研究需求但不當常備貨物。

- 樣本箱靠近燃料裝卸處時出現劈啪聲。 → 先把樣本移至核準的隔離區，再安排檢驗。 代價／限制：需要保管人同意與搬運距離；是否著火不能由敘事擲一個未定義風險。
- 工匠提出用它直接替收音機充電。 → 要求先量測輸出與穩定性，或保持封存。 代價／限制：需測量設備與時間；微弱電荷不等同相容電源。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、electronics、identification、hazards、cargo、knowledge、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_steel_stock"></a>
## 鋼材 · content_steel_stock

MISC / steel_bar_stock｜1500 g｜參考估值 24 Caps｜uncommon。
估值理由：24 Caps 比混雜廢鐵高，因較容易量測與安排加工。
[既有圖片](../../../ui/assets/items/library/supplies/steel_stock.png)｜runtime ID：尚未註冊

幾根規格接近的鋼條綁成一份，切口可見。

**初見：** 一份一千五百克材料；尺寸與材質仍需核對。

**調查後可確認：** 可供製作合要求的坯料，完成零件還需要工序和設備。

工坊願為可靠規格付出較高估值，不能只換標籤把廢鐵變成鋼材。

候選動作：fabricate_blank、deliver_material。來源：gray_valley、industrial_ruin。

- 新希望：供應 low／需求 medium。指定農具加工會採買合規板條。
- 灰谷：供應 high／需求 high。工坊能加工，穩定規格仍有需求。
- 乾井：供應 low／需求 high。車架與泵房構件希望用可靠坯料。

- 新希望的農具工匠缺一段可靠坯料。 → 按他畫的尺寸選料送達。 代價／限制：不合尺寸便退回，運費與重量仍已付出。
- 乾井工班爭論用便宜混料還是規格鋼條。 → 提出鋼材供應和較長運送時間的方案。 代價／限制：較可靠材料仍需加工，不保證工程永不失效。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：切壞或失去規格的鋼料只降級成回收鐵，不能原樣等量升回鋼材。 候選產物：廢鐵

前置缺口：crafting、disassembly、item_ownership、regional_trade、repair。研究：WG-01、WG-03。

<a id="content_stun_baton"></a>
## 電擊棒 · content_stun_baton

WEAPON / powered_security_baton｜950 g｜參考估值 260 Caps｜rare。
估值理由：260 Caps 是可檢修器材的設計估值；無法證實工作的個體不保證此價。
[既有圖片](../../../ui/assets/items/library/weapons/stun_baton.png)｜runtime ID：尚未註冊

透明尾蓋裡的指示燈不再亮，握把保留舊警備編號。

**初見：** 需要相容電源才能確認是否工作，外殼完好不等於有效。

**調查後可確認：** 有絕緣握部的舊警備器材，電路狀態需要電子技術檢查。

不能由名稱保證非致命或自動麻痺；任何人體效果均待 combat_extension。

候選動作：inspect_contacts、activate_indicator。來源：old_world_security、industrial_ruins。

- 新希望：供應 none／需求 low。缺少電子維護，需求限特定守衛或研究者。
- 灰谷：供應 low／需求 medium。有能力檢修舊警備設備的工坊願意收。
- 乾井：供應 none／需求 low。電源補充不易，日常防衛不依賴它。

- 警備器材箱有數支同款失效器具。 → 對比接點與編號，找出可送檢的一支。 代價／限制：耗檢查時間，不直接恢復電力或取得有效武器。
- 一名買家願意換取舊器材研究。 → 交出器具與觀察紀錄。 代價／限制：必須交付所有權，買家不保證能修好；價格另議。

維修：需相容電子零件與絕緣檢查，通電不代表安全可用。 候選投入：電路板、銅線、橡膠
拆解：拆毁後只回收可分離材料，不保留可用放電模組。 候選產物：銅線、塑膠

前置缺口：equipment、combat_extension、electronics、identification、item_ownership、regional_trade、repair、disassembly。研究：WG-05、WG-03。

<a id="content_sugar"></a>
## 糖 · content_sugar

CONSUMABLE / sugar_packet｜250 g｜參考估值 16 Caps｜uncommon。
估值理由：16 Caps 因加工、保存和甜味需求，沿路供應仍有限。
[既有圖片](../../../ui/assets/items/library/supplies/sugar.png)｜runtime ID：尚未註冊

顆粒糖裝在有防潮內襯的小袋裡。

**初見：** 兩百五十克一袋，結塊和污染要分清。

**調查後可確認：** 確認可食後可作廚房材料或交易小貨，不單獨取代完整飲食。

診所與家庭可能為供餐求購，不把它寫成有醫療處置能力的藥品。

候選動作：cook、exchange、donate。來源：new_hope、caravan。

- 新希望：供應 medium／需求 medium。食品加工有來源與需求。
- 灰谷：供應 low／需求 medium。廚房需要少量調味。
- 乾井：供應 low／需求 medium。小包裝便於商隊帶入。

- 臨時廚房要替返鄉者做一份甜食。 → 捐出一袋糖給負責供餐者。 代價／限制：糖被消耗，仍需其他食材與烹調條件。
- 商隊糖袋破口，混入一袋不明白色粉末。 → 把來源可確認的袋子分開，拒絕混批交貨。 代價／限制：清點有損耗，顏色相同不能直接認定成分相同。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、item_ownership、jobs、regional_trade。研究：WG-01、WG-02。

<a id="content_surgical_kit"></a>
## 手術包 · content_surgical_kit

TOOL / surgical_instrument_set｜1100 g｜參考估值 180 Caps｜rare。
估值理由：180 Caps 反映精度和完整性，不能按普通廢鐵秤價。
[既有圖片](../../../ui/assets/items/library/supplies/surgical_kit.png)｜runtime ID：尚未註冊

捲式器械包裡的金屬工具按位置扣緊。

**初見：** 一套器械，不包含乾淨場所、耗材或醫師技術。

**調查後可確認：** 核對器械用途與狀況後可供診所使用，不能在任何路旁直接完成手術。

有器械的診所仍可能欠缺照明與後續照護，工具只是條件之一。

候選動作：lend_instruments、deliver_to_clinic。來源：old_world_hospital。

- 新希望：供應 none／需求 medium。診所願意接收，不能穩定製造精密器械。
- 灰谷：供應 low／需求 high。有精加工修復條件但缺完整醫療套件。
- 乾井：供應 none／需求 medium。偏遠處置點希望備有器械，仍缺完整醫療條件。

- 聚落有醫師卻沒有匹配的器械。 → 借出整套器械，先清點交接。 代價／限制：仍需適當場所、耗材和處置權限；不能保證結果。
- 舊醫院器械上刻有庫存編號。 → 將整套交給診所辨認來源，保留編號記錄。 代價／限制：拆散售鐵會失去整套辨識價值，核對需時間。

維修：只允許專門維護者處理匹配器械部件；清潔與醫療可用性需獨立核驗。 候選投入：精密零件
拆解：無法使用的金屬器械可作降級回收，需處理污染，失去醫療器械身份。 候選產物：廢鐵

前置缺口：disassembly、identification、injury、item_ownership、jobs、repair。研究：WG-01、WG-02。

<a id="content_tactical_helmet"></a>
## 舊世戰術頭盔 · content_tactical_helmet

APPAREL / military_protective_helmet｜1550 g｜參考估值 320 Caps｜rare。
估值理由：320 Caps 提案只適用檢驗後可接受的個體。
[既有圖片](../../../ui/assets/items/library/clothing/tactical_helmet.png)｜runtime ID：尚未註冊

外殼上有一處凹痕，內部襯帶卻保存得很新。

**初見：** 外殼和襯帶需要分開檢查，不能只看新配件便當成可用。

**調查後可確認：** 舊制式頭盔，未知撞擊史會影響收購與使用判斷。

不是夜視鏡、呼吸器或軍方身分證；附掛能力未定義。

候選動作：inspect_helmet_shell、register_headgear。來源：military_depots、security_surplus。

- 新希望：供應 none／需求 low。農務少需軍用頭具，特定守望者例外。
- 灰谷：供應 low／需求 medium。安全器材工坊可檢驗並處理二手流通。
- 乾井：供應 low／需求 medium。護衛需要合身器材，但有重量及散熱代價。

- 退役護衛想交換自己的頭盔。 → 先確認撞擊史與襯帶尺寸。 代價／限制：口述史可能不完整，檢驗費用仍需協商。
- 施工地有人拿軍帽冒充有效防護。 → 請負責者檢查真正保護需求。 代價／限制：不能用外型代替規格，也不因此立即提高工地安全。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：鋼材、布料

前置缺口：equipment、combat_extension、hazards、identification、item_ownership、regional_trade、repair、disassembly。研究：WG-04、WG-05。

<a id="content_tea"></a>
## 茶葉 · content_tea

CONSUMABLE / dried_tea｜100 g｜參考估值 24 Caps｜uncommon。
估值理由：24 Caps 為容易分量使用的地方商品估值，口味不等於能力加成。
[既有圖片](../../../ui/assets/items/library/supplies/tea.png)｜runtime ID：尚未註冊

小鐵包裡的乾葉有產地記號，開口用紙繩封住。

**初見：** 一百克一包，茶葉與野外相似葉片不能混為同物。

**調查後可確認：** 核對來源後可沖泡或待客；款待是否被接受仍看關係與情境。

新希望有少量葉茶來源，商隊帶來的不同款式不必形成稀有度階梯。

候選動作：brew、host、exchange。來源：new_hope、caravan。

- 新希望：供應 medium／需求 medium。小批加工與待客文化形成需求。
- 灰谷：供應 low／需求 medium。工班休息棚與居民採買。
- 乾井：供應 low／需求 medium。停靠店歡迎輕便耐攜葉茶。

- 新希望調解者想讓爭執雙方坐下來談。 → 提供茶葉給願意待客的人準備飲品。 代價／限制：需水、器具與雙方同意，不自動提高說服成功率。
- 旅店收貨人認不出外來葉茶。 → 保留產地紙條並安排辨識，再決定購買。 代價／限制：辨識耗時，不把任何芳香葉片當可食茶葉。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、item_ownership、npc_relationship、regional_trade。研究：WG-02、FICTION-ROAD。

<a id="content_tent"></a>
## 帳篷 · content_tent

TOOL / portable_shelter｜3800 g｜參考估值 75 Caps｜uncommon。
估值理由：75 Caps 包括成套支架與篷布，較重的運送負擔壓低通用性。
[既有圖片](../../../ui/assets/items/library/supplies/tent.png)｜runtime ID：尚未註冊

捲起的篷布裹著短桿與地釘，袋口能清點配件。

**初見：** 一套可攜帳篷；缺桿或釘子時不能假定可搭起。

**調查後可確認：** 在合適地面和天候下可提供遮蔽；搭設位置仍須判斷。

商隊租借帳篷會清點配件，惡劣天候並非所有帳篷都能承受。

候選動作：pitch、shelter、loan。來源：caravan、new_hope。

- 新希望：供應 medium／需求 medium。農務季外勤可租借使用。
- 灰谷：供應 low／需求 medium。臨時工地想要遮蔽卻難備齊支架。
- 乾井：供應 medium／需求 high。商隊停靠時間不固定，完整帳篷有需求。

- 平地上風太強，商隊打算沿廢牆紮營。 → 用完整帳篷在確認安全的背風位置搭設。 代價／限制：搭設和收起耗時，牆體不穩時仍不可用。
- 農務隊想在遠田多留一天。 → 借出帳篷並清點支架地釘，約定回收。 代價／限制：自己失去當晚遮蔽用品；配件丟失需另外處理。

維修：只修補篷布與合規支架，材料尺寸及天候限制仍需核對。 候選投入：布料、繩索、鋼材
拆解：部分布面和支架可回收，不返還完整帳篷或全部原料。 候選產物：布料、廢鐵

前置缺口：camping、cargo、disassembly、hazards、item_ownership、repair。研究：WG-03、FICTION-ROAD。

<a id="content_tool_belt"></a>
## 工具腰帶 · content_tool_belt

CONTAINER / work_tool_belt｜650 g｜參考估值 55 Caps｜common。
估值理由：55 Caps 提案反映皮套與縫線完整度。
[既有圖片](../../../ui/assets/items/library/clothing/tool_belt.png)｜runtime ID：尚未註冊

幾個皮套被扳手磨出形狀，腰帶尾端多打了兩個孔。

**初見：** 方便收納已擁有工具，空套不會附贈相應工具。

**調查後可確認：** 650 g 空腰帶，套袋尺寸限制能放的東西。

快捷使用與裝備槽若未實作，畫面不能宣稱縮短行動時間。

候選動作：organize_owned_tools、lend_empty_belt。來源：gray_valley、workshops。

- 新希望：供應 medium／需求 medium。農具修繕與棚舍維護有需求。
- 灰谷：供應 high／需求 high。工坊最常用，修皮與工具需求互相連結。
- 乾井：供應 low／需求 high。煉製設備維護者需要整理小工具。

- 檢修場要求清點帶入工具。 → 把自己已有工具逐件放入並登記。 代價／限制：不增加工具數量，也不能用套袋代替正式工具要求。
- 學徒的腰帶斷裂卻要趕去工作。 → 借出空腰帶讓他整理自己的工具。 代價／限制：腰帶暫時離手，不能同時給自己快捷效果。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：皮革、布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：皮革

前置缺口：equipment、cargo、repair、jobs、npc_relationship、item_ownership、regional_trade、disassembly。研究：WG-01、WG-02。

<a id="content_toolbox"></a>
## 工具箱 · content_toolbox

TOOL / maintenance_tool_set｜4500 g｜參考估值 95 Caps｜uncommon。
估值理由：95 Caps 包括完整套組與收納，攜行成本比單帶扳手高。
[既有圖片](../../../ui/assets/items/library/supplies/toolbox.png)｜runtime ID：尚未註冊

沉重盒子裡按空槽收著一組常用機械工具。

**初見：** 四千五百克按整套估算，並不生成每個工具的獨立副本。

**調查後可確認：** 清點後可支援一般機械維護，精密電子與醫療用途仍需專門設備。

工班可能選擇租整套而非購買，每次借還都應清點。

候選動作：service_mechanism、lend_set、inventory_tools。來源：gray_valley、industrial_ruin。

- 新希望：供應 low／需求 medium。農忙時租用整套較合算。
- 灰谷：供應 high／需求 high。工班可備齊也會消耗或遺失工具。
- 乾井：供應 low／需求 high。長途車隊希望帶完整維修套件。

- 村民想修農具，借來的工具卻缺了兩個規格。 → 清點自己的整套工具，決定能否承接這份維護。 代價／限制：重工具箱要搬到現場；超出套組能力的工作仍拒絕。
- 商隊分成兩隊，各想帶走唯一工具箱。 → 約定先修最急的車，再決定由哪隊保管。 代價／限制：另一隊暫無整套支援，不能複製工具滿足兩邊。

維修：修收納盒與分隔；補齊遺失工具需另交實物，不能用原料自動生成整套。 候選投入：布料、鋼材
拆解：這裡只拆空的收納盒；套內工具需先清點移交，不複製成免費實物。 候選產物：廢鐵、布料

前置缺口：cargo、disassembly、item_ownership、jobs、repair。研究：WG-01、WG-03。

<a id="content_travel_backpack"></a>
## 舊旅行包 · content_travel_backpack

CONTAINER / travel_pack｜1100 g｜參考估值 60 Caps｜common。
估值理由：60 Caps 提案反映完整但老舊的旅行包；重量沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/travel_backpack.png)｜runtime ID：travel_backpack

兩條肩帶磨成不同顏色，背面縫著三層補丁。

**初見：** 方便準備旅程，肩帶與底布必須檢查。

**調查後可確認：** 1100 g 是空包重量；容量、裝備位與負重效果均待 equipment/cargo authority。

ITEM-1 的 CONTAINER 類別現在不提供任何 capacity 加成。

候選動作：pack_trip_supplies、inspect_straps。來源：settlement_tailors、caravan_routes。

- 新希望：供應 medium／需求 high。送貨與外出換物的居民需要可修補背包。
- 灰谷：供應 high／需求 high。拾荒與中轉人口讓二手包流通頻繁。
- 乾井：供應 medium／需求 high。長線補給準備需要可靠攜行器具。

- 出發前發現包底有開線。 → 先找裁縫修好再安排行李。 代價／限制：付出時間與布料；修補不增加既有容量。
- 陌生旅人尋找遺失背包。 → 核對補丁形狀後安排交還。 代價／限制：需確認所有權，不能因拾得包就取得其中全部物品。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料、皮革
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料、皮革

前置缺口：equipment、cargo、exploration、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：FICTION-ROAD、LD-P02。

<a id="content_uncold_ice"></a>
## 不冷的冰 · content_uncold_ice

MISC / persistent_cold_object｜420 g｜參考估值 None Caps｜rare。
估值理由：沒有穩定價格；灰谷熱工研究者或乾井冷藏委託人可能提出有條件的收受意願。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/uncold_ice.png)｜runtime ID：尚未註冊

一塊像透明冰的物件，包裹它的布卻沒有濕。

**初見：** 附近溫度計讀數會下降，外形暫未改變；名字只是發現者的綽號。

**調查後可確認：** 隔離測試可記錄特定距離與時間下的降溫現象；持續時間、可否接觸食物和材料成分仍未確認。

候選用途是受控降溫研究，不是永動冰箱或保證保存所有食品的背包增益。

候選動作：observe_temperature、isolate_sample、seek_researcher。來源：sealed_cold_room、anomalous_drain、mineral_case。

- 新希望：供應 none／需求 medium。食物保管者可能想了解降溫現象，需先驗證食物接觸安全。
- 灰谷：供應 none／需求 high。熱工研究者對隔離測試有具體需求。
- 乾井：供應 none／需求 high。高溫運輸工作可能願意資助測試，不能假定已有冷鏈市場。

- 舊冷庫的溫度紀錄與設備斷電時間不符。 → 隔離物件並做同時段對照觀察。 代價／限制：需量測器材與停留時間；只報讀數，不能據此宣布可食用或無害。
- 保管人想把未知物直接放進公共水槽。 → 提出先封閉容器測試，保留水槽供水。 代價／限制：需容器與研究時間；拒絕直接使用不會獲得即時冷藏效果。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、hazards、exploration、knowledge、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_unknown_implant"></a>
## 未知植入物 · content_unknown_implant

MISC / unclassified_medical_hardware｜75 g｜參考估值 None Caps｜rare。
估值理由：用途、適配條件與危害未知，不提出普遍售價；僅有具體研究委託人可表達收受意願。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/unknown_implant.png)｜runtime ID：尚未註冊

透明盒裡的金屬片像一片折起的葉，封條沒有常見醫療標記。

**初見：** 只能看到外形與少量接點，不知道應放在哪裡或是否接觸過人體。

**調查後可確認：** 初步檢查可分類材料與接口；即使識別型號，安全性、適配與是否可安裝仍需專門驗證。

候選劇情從拒絕自行安裝開始也成立；保留、交付研究或封存都比隨機永久加點更合理。

候選動作：document_shell、seek_identification、keep_sealed。來源：sealed_medical_case、research_locker、contaminated_archive。

- 新希望：供應 none／需求 low。地方照護者可能願意協助轉介，沒有直接使用需求。
- 灰谷：供應 none／需求 high。特定電子與醫療研究者願意檢查完整封裝，需先談保存條件。
- 乾井：供應 none／需求 medium。外來收藏者可能詢問，但其說法不能作安全性證據。

- 商人宣稱裝上就能改善反應，卻說不出型號。 → 選擇查驗封條與紀錄，或將物件保持封存。 代價／限制：查證需時間與專家，沒有資料就不提供安裝選項。
- 研究者願意接收，但要求保留完整包裝與發現地點。 → 提供來源紀錄並協商交付或暫借。 代價／限制：交付需明確所有權與歸還條件；拆封可能使原本證據失去價值。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、electronics、injury、knowledge、npc_relationship、regional_trade。研究：FICTION-ROADSIDE、WG-06。

<a id="content_unlabelled_medicine"></a>
## 未標示藥劑 · content_unlabelled_medicine

MISC / unidentified_vial｜80 g｜參考估值 None Caps｜rare。
估值理由：沒有通用底價；只列願意接收封存樣本的研究者，鑑定前不當成有效藥。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/supplies/unlabelled_medicine.png)｜runtime ID：尚未註冊

細頸瓶裡的液體透著淡色，標籤只剩膠痕。

**初見：** 只能確認外觀，未知成分不開放試喝捷徑。

**調查後可確認：** 鑑定可得到成分或用途線索，也可能判定不可用；不預設增益。

來源位置比液體顏色重要，混進正常藥品會破壞追查鏈。

候選動作：submit_sample、quarantine、investigate。來源：old_world_laboratory。

- 新希望：供應 none／需求 low。診所拒作正常藥品，只可能協助轉交樣本。
- 灰谷：供應 low／需求 medium。能接觸到調查設備的研究者願意評估。
- 乾井：供應 none／需求 low。普通商人不承擔未知液體風險。

- 失去標籤的瓶子和日記片段放在同一抽屜。 → 把瓶子連同來源記錄交給研究者辨識。 代價／限制：消耗調查時間，結果可能只是排除用途。
- 旅人希望喝一口試試是否能提神。 → 封存瓶子，改找有標示的補給。 代價／限制：放棄當場試用；未知物不提供隨機永久能力獎勵。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：hazards、identification、item_ownership、knowledge。研究：WG-06、FICTION-ROADSIDE。

<a id="content_unsent_letter"></a>
## 沒有寄出的信 · content_unsent_letter

MISC / unique_private_letter｜18 g｜參考估值 None Caps｜unique。
估值理由：不設一般市場價格；可能有送達委託報酬，但報酬是工作條件，不是信件內在售價。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/unsent_letter.png)｜runtime ID：尚未註冊

封口只黏了一半，寄件人把收件地址寫了兩遍，又劃去其中一行。

**初見：** 外封能讀到姓名與兩個地址；信未寄出，不知道收件人是否仍在原處。

**調查後可確認：** 可核對書寫時期與地址沿革；信內資訊只有合法拆閱或收件者自願分享後才可知。

候選故事允許送達、退回、查無此人或封存；不能為保證結局臨時生成收件者或復活死者。

候選動作：verify_addressee、deliver_unopened、preserve_letter。來源：documented_personal_effects、lost_post_bag。

- 新希望：供應 none／需求 medium。若住民紀錄匹配地址，可能提供轉交或查詢。
- 灰谷：供應 none／需求 medium。舊地址的工務紀錄可能提供去向線索，不代表當地買信。
- 乾井：供應 none／需求 medium。商隊郵袋與旅人見證可能協助轉送，並非一般貨物需求。

- 信封上的舊街名已改，兩處住址都有人聲稱知道。 → 查閱已有住民與地址紀錄，選擇可核驗的下一站。 代價／限制：需旅程與查詢時間；查無此人就是有效結果，不生成新人口。
- 一位願意帶路的人要求先看完整信件。 → 選擇保持封口並另找查詢途徑，或在權利人許可下分享必要資訊。 代價／限制：不拆信可能增加路程；拆閱不能沒有代價地同時保有『未拆封』狀態。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、knowledge、npc_relationship、jobs、reputation、regional_trade。研究：FICTION-CANTICLE、LD-P02。

<a id="content_vinyl_record"></a>
## 黑膠唱片 · content_vinyl_record

MISC / audio_record｜220 g｜參考估值 60 Caps｜uncommon。
估值理由：內容、保存狀況與特定收藏需求形成價值；沒有唱機也不產生播放功能。
[既有圖片](../../../ui/assets/items/library/relics/vinyl_record.png)｜runtime ID：尚未註冊

紙套角落註明一場取消的演出，日期被另一種墨水改過。

**初見：** 唱片有刮痕，標籤可讀一半；未確認能否完整播放。

**調查後可確認：** 可辨識發行編號與曲目順序；是否跳針需用相容唱機測試，紙套筆記另有私人來源。

候選來源是廣播站存櫃與居民家藏，不把所有唱片壓成相同的高價古董。

候選動作：inspect_label、compare_catalogue、offer_collection。來源：old_homes、broadcasting_store、estate_box。

- 新希望：供應 low／需求 medium。有休息室或收藏活動時才有需求，農業生產不直接消耗唱片。
- 灰谷：供應 medium／需求 low。舊媒體較易從工業區住家回收，但能播放的設備較少。
- 乾井：供應 low／需求 medium。外地商隊收藏者可能找指定編號，不無限收購同款。

- 旅館老闆找不到一套地方歌謠的最後一面。 → 比對編號後提出交換或出借。 代價／限制：只有缺少的版本才有此用途；需承擔運送脆弱唱片的負擔。
- 地下廣播室的目錄與唱片紙套記載不同日期。 → 比對印刷與後加筆記，尋找搬遷時間線。 代價／限制：需讀得到的目錄與調查時間；日期矛盾只是線索，不直接決定人物生死。

維修：目前沒有足以重建原物的工法；整理外觀不等於恢復功能。 候選投入：無
拆解：不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。 候選產物：無

前置缺口：item_ownership、identification、knowledge、npc_relationship、regional_trade。研究：FICTION-CANTICLE、WG-02。

<a id="content_water"></a>
## 水壺 · content_water

CONTAINER / canteen｜300 g｜參考估值 18 Caps｜common。
估值理由：18 Caps 主要來自可重複使用的密封與攜行便利。
[既有圖片](../../../ui/assets/items/water.png)｜runtime ID：尚未註冊

扁平水壺的背帶被反覆縫過，內壁能透過壺口檢查。

**初見：** 重量是空壺，不包含任何水。

**調查後可確認：** 壺口、內壁與密封檢查合格後才可裝飲水；用途由裝載內容決定。

水壺圖沿用早期水資源圖，內容設計仍將空容器與淨水分開。

候選動作：fill、carry_water、lend。來源：caravan、settlement_workshop。

- 新希望：供應 medium／需求 medium。取水家庭會修用水壺。
- 灰谷：供應 medium／需求 medium。工人和旅人都需密封容器。
- 乾井：供應 low／需求 high。長路攜水需求高，空壺仍須另找水源。

- 臨時取水點沒有可帶走的容器。 → 用空水壺接取經確認可飲的水。 代價／限制：要先清潔並核對壺況，裝水增加的重量另計。
- 一名信使的水壺蓋掉進井裡。 → 把空壺借給信使，約好在下一個聚落交還。 代價／限制：借出期間失去這個容器；能否交還需要後續人物狀態。

維修：僅提議更換已確認可接觸飲水的密封件；壺體破壞另行判廢。 候選投入：橡膠
拆解：金屬壺報廢後僅可能回收部分潔淨金屬，失去容器用途。 候選產物：廢鐵

前置缺口：cargo、disassembly、item_ownership、repair、water_treatment。研究：WG-01、FICTION-ROAD。

<a id="content_water_filter"></a>
## 濾水器 · content_water_filter

TOOL / portable_filter｜600 g｜參考估值 120 Caps｜uncommon。
估值理由：120 Caps 來自可維護的機構與攜行用途，仍要負擔替換濾材。
[既有圖片](../../../ui/assets/items/library/supplies/water_filter.png)｜runtime ID：尚未註冊

可拆開的濾筒帶著手壓泵，側面留有清潔記號。

**初見：** 濾筒可拆檢，但外觀無法判定剩餘處理能力。

**調查後可確認：** 只能針對經確認適用的水源提出過濾方案；濾材和密封狀況都重要。

新希望有人會保養泵體；不代表當地能重製所有濾芯。

候選動作：filter_water、inspect_filter、lend。來源：new_hope、old_world_utility。

- 新希望：供應 medium／需求 medium。有人維護泵體，但替換濾材仍有限。
- 灰谷：供應 low／需求 high。工地臨時供水需要可檢驗設備。
- 乾井：供應 low／需求 high。繞遠水路的商隊希望重複使用設備。

- 舊驛站的沉水桶讓旅人排了長隊。 → 提供可檢查的濾水器，協助評估一條處理方案。 代價／限制：需合適水源與濾材；使用時間擠占出發時間。
- 新希望的濾筒保養者想借一台不同接頭的泵。 → 借出設備讓對方比對規格，換取泵體檢查記錄。 代價／限制：只比對機構，不自動補滿濾芯或改善全城供水。

維修：只能維護泵體密封與外套；布料不是淨水濾芯，不恢復未知濾材能力。 候選投入：橡膠、布料
拆解：只回收可分離外殼，污染濾材不當作淨水產品或完整材料返還。 候選產物：塑膠、廢鐵

前置缺口：disassembly、identification、item_ownership、repair、water_treatment。研究：WG-01、WG-03。

<a id="content_waterproof_bag"></a>
## 防水袋 · content_waterproof_bag

CONTAINER / sealed_document_bag｜320 g｜參考估值 80 Caps｜uncommon。
估值理由：80 Caps 提案反映完整封口較難修復。
[既有圖片](../../../ui/assets/items/library/clothing/waterproof_bag.png)｜runtime ID：尚未註冊

半透明袋面有一道折白，封口仍能贴合。

**初見：** 適合保護特定乾燥物件，封口有缺陷時不能保證防水。

**調查後可確認：** 320 g 空防水袋，容量與完整性需檢驗；不是液體儲罐。

讓文件與醫療標籤在路上值得保護，不讓所有行李免費免受水害。

候選動作：protect_paper_cargo、inspect_closure。來源：caravan_outfitters、old_world_outdoors。

- 新希望：供應 medium／需求 high。灌溉區送信與種子資料需要防濕。
- 灰谷：供應 low／需求 medium。精密零件文件運輸有需求。
- 乾井：供應 medium／需求 medium。可阻擋砂與潑濺，但不是長時間高溫防護。

- 信使要涉過淺水卻帶著紙本日記。 → 將日記放進已檢查袋內。 代價／限制：只保護有限內容，仍需安全通行方案。
- 袋封口破損，委託文件即將出發。 → 选擇等待替換或改走乾燥路線。 代價／限制：花時間或增加路程，不能用布補丁保證密封。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：塑膠、橡膠
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：塑膠

前置缺口：equipment、cargo、hazards、knowledge、navigation、item_ownership、regional_trade、repair、disassembly。研究：FICTION-CANTICLE、FICTION-METRO。

<a id="content_waterskin"></a>
## 水袋 · content_waterskin

CONTAINER / flexible_water_container｜380 g｜參考估值 45 Caps｜common。
估值理由：45 Caps 提案讓旅行容器可取得，但仍需支付或取得水。
[既有圖片](../../../ui/assets/items/library/clothing/waterskin.png)｜runtime ID：尚未註冊

皮袋口被反覆綁緊，接縫處有深淺不一的水痕。

**初見：** 可提出儲水用途，但容器不是水本身。

**調查後可確認：** 380 g 是空袋，容量、可飲用性與內裝液體重量另待 cargo/water_treatment。

不能把買一只水袋等同增加 Water 或减少代謝消耗。

候選動作：carry_allocated_water、inspect_seam。來源：dry_well、leather_workers、caravan_stops。

- 新希望：供應 medium／需求 medium。水源較易取得，外出者會買攜具。
- 灰谷：供應 low／需求 medium。運送個人配給時有需求，皮革維修要專人。
- 乾井：供應 high／需求 high。長段無補給路線需要可維護儲水容器。

- 水站願分配水卻要求自備容器。 → 用空水袋領取已獲准份額。 代價／限制：必須扣除水站真實水量，不能由容器生成水。
- 旅人發現袋縫滲漏。 → 先轉移已有液體，再委託修補。 代價／限制：需要另一個真實容器，轉移損失與時間待規則。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：皮革、橡膠
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：皮革

前置缺口：equipment、cargo、water_treatment、item_ownership、regional_trade、repair、disassembly。研究：WG-01、FICTION-ROAD。

<a id="content_welding_tools"></a>
## 焊接工具 · content_welding_tools

TOOL / portable_welding_set｜7000 g｜參考估值 220 Caps｜rare。
估值理由：220 Caps 因設備與配套稀少，使用前還有供能和技術成本。
[既有圖片](../../../ui/assets/items/library/supplies/welding_tools.png)｜runtime ID：尚未註冊

可攜工具架固定著面罩、夾具與焊接裝置。

**初見：** 工具架不包含無限能源和焊接材料。

**調查後可確認：** 需確認材料、供能與操作場所；能連接金屬不代表可修任何容器。

灰谷有適用工位，乾井可能只缺一次帶設備的維修服務。

候選動作：join_metal、patch_frame、deliver_to_workshop。來源：gray_valley、industrial_ruin。

- 新希望：供應 none／需求 medium。少數大型農具修理要外請設備。
- 灰谷：供應 medium／需求 high。有操作工位與配套供應。
- 乾井：供應 low／需求 high。車架與容器維修需求高，但作業場所受油氣限制。

- 橋邊護欄的金屬框斷開，旁邊仍有行人通過。 → 提出封閉小段通路後由合格工人焊接的方案。 代價／限制：需要供能、材料和安全工位；阻路會延誤通行。
- 乾井有人要求在油罐旁就地修補。 → 把器材帶到合適工位，要求先處理危險條件。 代價／限制：搬運和停工耗時，工具不授權高風險現場直接開工。

維修：由專業者檢查供能、接點與工具結構；焊材能源另外消耗。 候選投入：銅線、橡膠、精密零件
拆解：停用並確認供能安全後拆分可回收件，不能保留完整設備。 候選產物：銅線、廢鐵

前置缺口：crafting、disassembly、electronics、hazards、item_ownership、repair。研究：WG-01、WG-03。

<a id="content_well_guardian"></a>
## 守井人 · content_well_guardian

WEAPON / named_watch_rifle｜3900 g｜參考估值 None Caps｜unique。
估值理由：對乾井特定保管人具有地方歷史價值；外地沒有保證高價，且須先確認持有權。 空值表示不設通用估值。
[既有圖片](../../../ui/assets/items/library/relics/well_guardian.png)｜runtime ID：尚未註冊

槍帶內側繡著一道水位線，鐵件的刮痕被多年擦拭磨圓了。

**初見：** 是舊步槍，水位線標記與一些乾井舊用品相似；傳說尚未核實。

**調查後可確認：** 可用守井值班紀錄與保管印記確認來歷；這不授予守井職權，戰鬥性能依機械狀態另定。

候選去向可以是歸還公共收藏、合法保管或調查失竊，不能讓持有者自動控制井與居民。

候選動作：compare_watch_record、return_to_custodian、inspect_mechanism。來源：dry_well_historical_lockbox、documented_personal_transfer。

- 新希望：供應 none／需求 low。外地居民通常不認得地方標記，除非已有相關委託。
- 灰谷：供應 none／需求 medium。工匠可檢查機械，但不能替乾井裁定歷史所有權。
- 乾井：供應 none／需求 high。地方保管者與相關住民可能想查明去向；需求不是常態商店收購價。

- 乾井新任值班者看到水位線繡記，懷疑它從公物箱流出。 → 先核對保管紀錄再討論歸還或合法借用。 代價／限制：需查證時間與現任保管權；持槍不代表任命玩家為守衛。
- 商隊願用普通步槍交換，地方紀錄者則希望保留原物。 → 在所有權清楚後選擇交換、保管或歸還。 代價／限制：每條去向只移轉同一實例；交換不保留原槍，也不額外獲得地方職權。

維修：僅檢修機械，保留槍帶與保管標記；是否射擊與文物保存承諾另定。 候選投入：彈簧、精密零件
拆解：拆解永久失去完整地方遺物；必須先明示後果與權利人同意。 候選產物：廢鐵、彈簧

前置缺口：item_ownership、equipment、combat_extension、identification、npc_relationship、reputation、jobs、regional_trade、repair、disassembly。研究：FICTION-CANTICLE、WG-02。

<a id="content_wild_greens"></a>
## 野菜 · content_wild_greens

CONSUMABLE / foraged_greens｜250 g｜參考估值 4 Caps｜common。
估值理由：4 Caps 反映近產地易得但運送時間敏感。
[既有圖片](../../../ui/assets/items/library/supplies/wild_greens.png)｜runtime ID：尚未註冊

一束仍帶泥的葉菜，根部用草莖鬆鬆束起。

**初見：** 以一小束計；相似外觀不等於同一植物。

**調查後可確認：** 辨識採集地與品種後，可交給廚房處理或保留作樣本。

農夫熟悉的採集區也會受污染或採集壓力影響，不能只看地名判安全。

候選動作：identify、cook、deliver_sample。來源：new_hope、wilderness。

- 新希望：供應 high／需求 medium。採集區近，廚房只收已辨識鮮貨。
- 灰谷：供應 low／需求 medium。市場想添鮮食，長途貨容易失去價值。
- 乾井：供應 low／需求 low。長程運送不利於普通葉菜，適合就近採買。

- 採集者帶回兩種長得相似的葉菜。 → 用已辨識的樣本比對採集範圍並做標記。 代價／限制：不能只憑樣本認證整批，未知部分要留下不用。
- 新希望廚房缺少當日配菜。 → 把新鮮且已辨識的野菜就近交給廚房。 代價／限制：需趁仍可用時交貨，不能無限跨城囤積。

維修：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選投入：無
拆解：本稿不設這項處理；使用、檢驗或交付不返還完整替代品。 候選產物：無

前置缺口：cooking、identification、item_ownership、jobs。研究：WG-01、FICTION-ROAD。

<a id="content_wilderness_cloak"></a>
## 荒野斗篷 · content_wilderness_cloak

APPAREL / travel_cloak｜1350 g｜參考估值 95 Caps｜uncommon。
估值理由：95 Caps 提案反映完整大面積布料與旅行耐用性。
[既有圖片](../../../ui/assets/items/library/clothing/wilderness_cloak.png)｜runtime ID：尚未註冊

外層被曬得灰綠，裡面仍留著舊主的細密補線。

**初見：** 可覆住衣物或行李，不能讓穿戴者隱形。

**調查後可確認：** 大幅外披布料，覆蓋範圍與濕重取捨需之後定義。

以露營與觀察準備為用途，是否影响潛行由獨立規則決定。

候選動作：cover_camp_bundle、conceal_reflective_gear。來源：wilderness_tailors、caravan_camps。

- 新希望：供應 medium／需求 medium。林緣旅行和夜間等候有需求。
- 灰谷：供應 low／需求 medium。出城拾荒者會找容易修補的披覆。
- 乾井：供應 medium／需求 medium。營地遮覆有用，但沙袍更常見。

- 守望點附近的金屬行李反射光線。 → 用斗篷暫時覆住反光面。 代價／限制：失去穿著用途，仍不能保證不被發現。
- 營地突然下起細雨。 → 罩住自己選定的一包物資。 代價／限制：只能覆有限範圍，不讓全隊行李自動防水。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、camping、hazards、exploration、item_ownership、regional_trade、repair、disassembly。研究：WG-01、FICTION-ROAD。

<a id="content_wood_axe"></a>
## 伐木斧 · content_wood_axe

TOOL / woodcutting_axe｜2600 g｜參考估值 105 Caps｜common。
估值理由：105 Caps 提案來自農林工具需求，不因能當武器而自動增價。
[既有圖片](../../../ui/assets/items/library/weapons/wood_axe.png)｜runtime ID：尚未註冊

斧柄比握把更舊，刀頭倒是保養得乾淨。

**初見：** 適合已倒下或獲准採伐的木料，帶著它不代表可以砍任何樹。

**調查後可確認：** 伐木用楔形斧頭，斧柄鬆動需先處理。

新希望會重視林緣資源，砍伐行為可能涉及公共燃料分配。

候選動作：split_firewood、trim_fallen_branch。來源：new_hope、woodcutters。

- 新希望：供應 high／需求 high。農林邊緣持續需要，替換工具有買家。
- 灰谷：供應 medium／需求 medium。工坊燒火需要劈材，成品通常由外地送來。
- 乾井：供應 low／需求 low。缺少木材使重斧不常用，遠行商隊偶爾收購。

- 營地有濕木外皮與乾燥內層。 → 劈開已收集木料供後續生火。 代價／限制：需時間且仍需要點火物；不能直接抵消寒冷。
- 農道被落枝堵住。 → 協助農戶整理阻路枝條。 代價／限制：需地主同意，報酬先談妥；不自動取得全部木料。

維修：刃口由工坊處理，缺失木柄仍缺正式材料設計。 候選投入：鋼材、皮革
拆解：回收金屬頭後失去完整斧具，無免費木材產出。 候選產物：廢鐵

前置缺口：equipment、combat_extension、exploration、camping、cooking、jobs、item_ownership、regional_trade、repair、disassembly。研究：WG-01、LD-P02。

<a id="content_work_clothes"></a>
## 舊工作服 · content_work_clothes

APPAREL / workwear｜1200 g｜參考估值 28 Caps｜common。
估值理由：28 Caps 提案反映二手布衣；1200 g 沿用 ITEM-1。
[既有圖片](../../../ui/assets/items/candidates/work_clothes.png)｜runtime ID：work_clothes

袖口補丁壓著補丁，胸前名牌只剩一個姓。

**初見：** 普通衣物可以遮蔽身體，不能據此宣稱防彈或防污染。

**調查後可確認：** 耐磨布料工作服；衣袋和接縫完整度應分別檢查。

工作服在工人之間流通，名牌只是來源線索，不賦予職業權限。

候選動作：wear_workwear、inspect_name_patch。來源：gray_valley、settlements。

- 新希望：供應 medium／需求 medium。農務可穿，但較輕衣物也有用途。
- 灰谷：供應 high／需求 high。工班更換頻繁，二手供應與日常需求並存。
- 乾井：供應 medium／需求 low。厚布在乾熱路線有負擔，固定工地仍會使用。

- 失物堆出現有名字的工作服。 → 先尋找名牌可能對應的工班。 代價／限制：需查訪，不直接由衣物認定原主的命運。
- 工班願意借用合身衣物給臨時搬運者。 → 交出衣物作短期借用。 代價／限制：借出期間不能穿用，歸還與清洗條件先約定。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：布料

前置缺口：equipment、exploration、jobs、npc_relationship、item_ownership、regional_trade、repair、disassembly。研究：WG-02、FICTION-ROAD。

<a id="content_worker_leather_jacket"></a>
## 工人皮衣 · content_worker_leather_jacket

APPAREL / industrial_leatherwear｜2300 g｜參考估值 120 Caps｜uncommon。
估值理由：120 Caps 提案反映皮革用料與維修便利。
[既有圖片](../../../ui/assets/items/library/clothing/worker_leather_jacket.png)｜runtime ID：尚未註冊

皮面布滿細小擦痕，肩線仍紮實。

**初見：** 耐磨厚皮衣較重，不能宣稱能擋任何工業危險。

**調查後可確認：** 補強皮革工作衣，熱源、切割與化學防護需分別判定。

工人皮衣與輕甲有重疊外觀，但裝備分類不能偷帶護甲公式。

候選動作：wear_for_work、identify_workshop_patch。來源：gray_valley、leather_workers。

- 新希望：供應 low／需求 medium。畜務與粗搬運有需要，輕農務較少使用。
- 灰谷：供應 high／需求 high。工業工作最常見，當地能修縫。
- 乾井：供應 low／需求 medium。油料搬運者可能需求，悶熱是代價。

- 廢工班留下有特定補丁的皮衣。 → 以補丁縫法查詢原工作站。 代價／限制：耗查訪時間，不自動得到員工身分。
- 搬運隊要求自備耐磨衣物。 → 提交已持有皮衣供領班檢視。 代價／限制：領班仍需確認工作安全，衣物不保證免傷。

維修：需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。 候選投入：皮革、布料
拆解：拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。 候選產物：皮革

前置缺口：equipment、hazards、jobs、knowledge、item_ownership、regional_trade、repair、disassembly。研究：WG-02、WG-05。

<a id="content_wrench"></a>
## 扳手 · content_wrench

TOOL / adjustable_wrench｜700 g｜參考估值 25 Caps｜common。
估值理由：25 Caps 反映灰谷易維護的普通手工具，遠地需求來自用途而非稀有度。
[既有圖片](../../../ui/assets/items/candidates/wrench.png)｜runtime ID：wrench

可調開口的扳手，握柄沾著擦不掉的機油。

**初見：** 保持 ITEM-1 的七百克；開口範圍尚需和目標比對。

**調查後可確認：** 可轉動合適尺寸的緊固件，不自帶撬開所有鎖或修好整台機器的能力。

乾井的泵房願意借用合尺寸扳手，新希望也會用於農具保養。

候選動作：turn_fastener、hold_joint、lend。來源：gray_valley、industrial_ruin。

- 新希望：供應 medium／需求 medium。農具與水泵需要，較少現地製造。
- 灰谷：供應 high／需求 medium。工業來源多，常見規格易補貨。
- 乾井：供應 low／需求 high。燃料泵與貨車接頭需要合尺寸工具。

- 農務水管接頭鬆動，卻找不到合尺寸工具。 → 比對開口後借出扳手給修理者處理接頭。 代價／限制：需要合尺寸與修理判定，不因持有就修好整段供水。
- 乾井買家一次要十把扳手。 → 先確認規格與收貨數量，再接分批交運。 代價／限制：搬運佔重量，供貨不足或規格錯誤便不能完成整單。

維修：由工匠判斷是否可替換調整機構；已失準或開裂的受力部位可判廢。 候選投入：鋼材
拆解：報廢金屬回收不保留精度，不能直接兌回完整扳手。 候選產物：廢鐵

前置缺口：disassembly、exploration、item_ownership、jobs、repair。研究：WG-01、WG-02。
