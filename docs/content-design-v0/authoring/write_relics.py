"""Editorial authoring helper; not imported by the game."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "docs/content-design-v0"
SEEDS = json.loads((BASE / "item-seeds.json").read_text(encoding="utf-8-sig"))
BY_ID = {row["content_id"]: row for row in SEEDS}
ITEMS = []


def relation(ids, note):
    return {"possible": bool(ids), "inputs": ["content_" + x for x in ids.split()], "note_zh": note}


def recover(ids, note):
    return {"possible": bool(ids), "outputs": ["content_" + x for x in ids.split()], "note_zh": note}


def item(key, subtype, weight, value, rarity, tags, roles, actions, origins,
         value_note, description, known, identified, world, markets, hooks,
         dependencies, refs, repair=None, salvage=None, category="MISC"):
    seed = BY_ID["content_" + key]
    row = {k: seed[k] for k in ("content_id", "name_zh", "art_file", "art_sections", "art_role", "runtime_item_id")}
    row.update({
        "status": "DESIGN_ONLY", "category": category, "subtype": subtype,
        "proposed_weight_g": weight, "proposed_base_value_caps": value,
        "value_rationale_zh": value_note, "rarity": rarity,
        "tags": tags.split(), "roles": roles.split(), "actions": actions.split(),
        "origin_tags": origins.split(),
        "markets": {place: {"supply": values[0], "demand": values[1], "reason_zh": values[2]}
                    for place, values in zip(("new_hope", "gray_valley", "dry_well"), markets)},
        "loot_sources": origins.split(),
        "description_zh": description, "known_description_zh": known,
        "identified_description_zh": identified, "world_notes_zh": world,
        "hooks": [{"situation_zh": h[0], "use_zh": h[1], "cost_or_limit_zh": h[2]} for h in hooks],
        "repair": repair or relation("", "目前沒有足以重建原物的工法；整理外觀不等於恢復功能。"),
        "salvage": salvage or recover("", "不提出拆解產物；必須先確認材料與保存需求，不能當作可再生資源。"),
        "dependencies": dependencies.split(), "inspiration_refs": refs.split(),
    })
    ITEMS.append(row)


item("old_world_watch", "mechanical_timepiece", 110, 90, "uncommon", "old_world clockwork personal", "trade explore", "inspect synchronize return_to_owner", "old_homes locker personal_effects",
     "價值來自可校時的機芯與可辨讀刻字；停擺或來源不明時不能直接套用此估值。",
     "錶帶換過三次，背蓋仍留著一圈比手腕細得多的磨痕。",
     "指針偶爾前進，背面有兩個縮寫；不知道它是否走得準。",
     "機芯可手動上鍊，日常走時會漂移；背蓋刻字是持有人標記，並非通行資格。",
     "候選來源是舊屋抽屜或私人寄存物；校時與尋找失主是兩條獨立用途，沒有自動導航效果。",
     [("low", "medium", "水閘輪值者可能需要可校準的時計；本地不能穩定製作機芯。"), ("medium", "high", "修表與精密拆件的候選工匠需要可修機芯，會先辨別是否缺件。"), ("low", "medium", "車隊交班可能需要計時，但只在有排班工作時形成需求。")],
     [("兩隊工人互相指責提早關閉灌溉閘。", "借出經校時的手錶，讓雙方在一次輪值中記錄開關時刻。", "必須先取得雙方同意並留錶一個輪值；僅提供紀錄，不自動裁定誰說謊。"), ("商隊失物單上的錶帶補線與此錶相同。", "帶著手錶查證刻字與領取人身分。", "需跑一趟交會地點；查證前不能因圖樣相似就轉移所有權。")],
     "item_ownership knowledge jobs npc_relationship regional_trade repair", "FICTION-CANTICLE WG-02",
     relation("precision_parts spring glass", "更換損壞機件或錶面，須有能辨識機芯的工匠；刻字與走時紀錄不能靠換件生成。"),
     recover("spring precision_parts", "拆解會失去完整時計與尋主證物，只保留經確認可用的零件，無固定回收比率。"), "TOOL")

item("camera", "film_camera", 720, 140, "rare", "old_world optics evidence", "explore trade", "inspect document_scene compare_image", "old_homes survey_case estate_locker",
     "完整光學與機械部件可供使用或研究；底片與沖洗供應未建立，不能把機身視為無限拍照器。",
     "鏡頭蓋內黏著一張手寫清單，最後一項只剩半個字。",
     "能看見取景器與捲片旋鈕；不知道快門或內部底片是否完好。",
     "這是使用底片的機身，快門可測但成像仍需相容底片與沖洗；取景器只可作有限目視觀察。",
     "候選定位是證據記錄與地方影像交易；需要另定有限耗材，不能憑照片敘事回溯生成世界事實。",
     [("low", "low", "一般農戶少有成像耗材，僅偶有家庭照片保存委託。"), ("low", "medium", "調查者或光學工匠可能收購完整機身。"), ("none", "medium", "運輸紀錄人有保存事故現場的理由，但沒有穩定底片來源。")],
     [("舊水塔裂縫是否擴大引起爭議。", "在建立相容耗材規則後，用同一視角記錄兩次檢查。", "需有限底片、兩次到訪與沖洗；單張影像不能直接判定結構安全。"), ("旅館展板上一張相片的取景角度指向被填平的巷口。", "比較取景器視線與地物，尋找拍攝位置。", "必須實地觀察；找出位置只得到調查線索，沒有直接開門或出土獎勵。")],
     "item_ownership exploration knowledge jobs regional_trade repair", "FICTION-CANTICLE LD-P01",
     relation("glass spring precision_parts", "只能由適當工具校正或更換機械件，不能用普通玻璃宣稱恢復精密鏡片品質。"),
     recover("glass spring", "僅分離可確認的玻璃與彈簧；拆解會破壞完整機身用途。"), "TOOL")

item("music_player", "portable_audio_player", 260, 70, "uncommon", "old_world audio battery_device", "trade explore", "test_playback share_recording trace_voice", "old_homes lost_luggage workshop_drawer",
     "可播放且介面相容的機器才有使用價值；沒有電源與媒體時只是待檢舊物。",
     "播放鍵磨得發亮，其餘按鍵還能摸到模壓字的凹槽。",
     "有耳機孔與電池艙，螢幕不亮；內部可能有資料但尚未讀取。",
     "可用相容電源檢測播放電路；媒體內容與來源仍須逐項確認，裝置不保證藏有重要情報。",
     "候選用途是留下地方聲音與私人記憶；娛樂或求證可有價值，但不自動改善全城士氣。",
     [("low", "medium", "公共休息處可能想保留歌聲或口述故事，需要可用電源。"), ("medium", "medium", "拆件者與電子維修者可能有零星舊機身。"), ("low", "low", "長途運輸偏重實用品，只有特定旅人尋找聲音紀錄。")],
     [("交班錄音只剩一段被雜訊蓋住的地點名稱。", "用相容播放器反覆比對音節，記錄可辨讀的部分。", "消耗檢測時間與相容電源；聽不清的字必須保留未知，不補出假座標。"), ("一位旅人認得機身上的家庭貼紙。", "讓對方聽到經同意公開的錄音片段，協助查證來源。", "需要持有人同意；分享內容可能洩露私人資訊，不能自動解鎖信任。")],
     "item_ownership electronics knowledge npc_relationship regional_trade repair", "FICTION-CANTICLE WG-03",
     relation("circuit_board copper_wire battery_cell", "先確認介面與電壓；換件不會恢復已失去的錄音。"),
     recover("circuit_board copper_wire plastic", "媒體與電路分開處理；拆解前必須告知可能喪失播放能力。"), "TOOL")

item("vinyl_record", "audio_record", 220, 60, "uncommon", "old_world music fragile", "trade explore", "inspect_label compare_catalogue offer_collection", "old_homes broadcasting_store estate_box",
     "內容、保存狀況與特定收藏需求形成價值；沒有唱機也不產生播放功能。",
     "紙套角落註明一場取消的演出，日期被另一種墨水改過。",
     "唱片有刮痕，標籤可讀一半；未確認能否完整播放。",
     "可辨識發行編號與曲目順序；是否跳針需用相容唱機測試，紙套筆記另有私人來源。",
     "候選來源是廣播站存櫃與居民家藏，不把所有唱片壓成相同的高價古董。",
     [("low", "medium", "有休息室或收藏活動時才有需求，農業生產不直接消耗唱片。"), ("medium", "low", "舊媒體較易從工業區住家回收，但能播放的設備較少。"), ("low", "medium", "外地商隊收藏者可能找指定編號，不無限收購同款。")],
     [("旅館老闆找不到一套地方歌謠的最後一面。", "比對編號後提出交換或出借。", "只有缺少的版本才有此用途；需承擔運送脆弱唱片的負擔。"), ("地下廣播室的目錄與唱片紙套記載不同日期。", "比對印刷與後加筆記，尋找搬遷時間線。", "需讀得到的目錄與調查時間；日期矛盾只是線索，不直接決定人物生死。")],
     "item_ownership identification knowledge npc_relationship regional_trade", "FICTION-CANTICLE WG-02")

item("old_photograph", "photographic_print", 15, 20, "uncommon", "old_world image personal", "explore trade", "compare_landmark seek_owner preserve_image", "old_homes personal_effects archive_folder",
     "一般相片交易價低；家族或調查需求另議，不能把私人意義換算為普遍高價。",
     "人群站在一口新井旁，畫面邊緣有人把臉轉向了別處。",
     "井旁有不完整招牌與山形，背面寫了名字；拍攝年代與地點尚未核實。",
     "可辨認的地物與手寫內容列為線索；相似外貌不能證明親屬、身分或所有權。",
     "候選內容重點是世界曾經怎麼使用某處，以及誰仍記得；相片不授予新人口或必然存在的家屬。",
     [("medium", "low", "居民家藏可能流出，但只對相關的人有明確需求。"), ("low", "medium", "地方紀錄者可能收集工業聚落變遷影像。"), ("low", "medium", "舊井與商路地景可能幫助比對歷史位置。")],
     [("新井選址者想確認照片中的舊排水溝走向。", "比對山形與尚存牆角，提出調查位置。", "需實地核對；相片不能證明地下水量或保證安全鑽探。"), ("旅人說照片上的名字與自己的寄存單相同。", "安排查證或將複製筆記交給地方記錄者。", "需尊重持有人意願；不能只憑姓名就交出原照或建立親屬關係。")],
     "item_ownership knowledge exploration npc_relationship jobs regional_trade", "FICTION-CANTICLE LD-P02")

item("identity_document", "civil_identity_paper", 25, 35, "uncommon", "old_world identity evidence", "explore trade", "verify_record compare_signature return_document", "personal_effects office_archive lost_luggage",
     "估值只反映保存與查證工作；證件不作可自由販售的現行通行權。",
     "塑封邊緣重新燙過，照片下方的舊住址仍未被刮掉。",
     "能看見姓名、照片與局部編號；有效期限和現行承認範圍都未知。",
     "這是舊制度留下的身分紀錄，可與其他檔案比對；持有者不是自動成為文件所指的人。",
     "候選任務由已有的人口代表提出尋物或查檔；不能用證件為世界生成另一個具名個體。",
     [("low", "medium", "安置與尋親工作可能需要查證舊住址，證件本身沒有供給功能。"), ("medium", "medium", "舊工務檔案較多，登記員可能協助核對編號。"), ("low", "low", "商隊較重現行見證，不把過期證件當保證書。")],
     [("寄存櫃領取人姓名相同，簽字卻不同。", "提供證件作交叉查證材料。", "需核對獨立紀錄與持有人同意；證件不直接打開寄存櫃。"), ("收容點只有一筆模糊的舊住址。", "比對文件地址與既有住民紀錄，縮小查詢範圍。", "耗費查檔時間；沒有匹配就明確記錄未找到，不生成家屬。")],
     "item_ownership identification knowledge npc_relationship jobs regional_trade", "FICTION-CANTICLE FICTION-WOOL")

item("military_dog_tags", "service_identification", 45, 40, "uncommon", "old_world identity metal", "explore trade", "read_service_mark return_effects compare_roster", "old_checkpoint personal_effects military_locker",
     "金屬本身不值高價，價值取決於可查證的服役紀錄或收回遺物的特定委託。",
     "兩片牌子的磨損程度不同，中間的鏈節像被人換成了細鐵絲。",
     "有編號與血型字樣，沒有足以確認現任持有人身分的證據。",
     "編號格式可對應某批舊紀錄；仍須核對名冊，不能由識別牌推定死亡或軍事權限。",
     "候選定位為遺物交還與舊哨站調查，不做軍階裝備加成或免費守衛通行。",
     [("low", "medium", "特定家庭可能希望收回已查證的遺物。"), ("low", "medium", "檔案整理者可能把牌號與工業守備紀錄對照。"), ("low", "high", "舊井守備故事與退伍旅人可能形成具名委託，非普遍收購。")],
     [("舊哨站名冊缺了一頁，箱中卻有一塊識別牌。", "將牌號與不同日期的值班紀錄交叉核對。", "需要名冊或見證者，只有識別牌不宣布某人曾在場。"), ("路邊紀念牌上有相同編號。", "查證後將遺物交還給管理紀念地的人。", "需放棄原物；回報可以是歷史資訊，不保證金錢或好感獎勵。")],
     "item_ownership identification knowledge npc_relationship jobs regional_trade", "FICTION-CANTICLE LD-P02",
     None, recover("scrap_iron", "熔解會永久失去牌號與交還用途；材料產量待拆解契約，不當高收益來源。"))

item("company_keycard", "site_access_card", 12, 80, "rare", "old_world access electronics", "explore trade", "read_identifier compare_access_log present_card", "company_office maintenance_locker lost_luggage",
     "估值來自特定設施的調查需求；卡號失效或讀取器不相容時不具一般通行價值。",
     "磨白的塑膠卡只剩一條藍線，掛孔處刻了簡單的扳手圖案。",
     "有公司標誌與序號；不知道它對應哪扇門，也不知道能否讀取。",
     "卡號屬於某類維護人員識別格式；需查驗設施、讀取器與授權紀錄後才能判斷是否適用。",
     "通行是設施狀態與授權共同決定，卡片不通吃所有電子門，也不代表取得物資所有權。",
     [("none", "low", "多數農業場所沒有相容讀取器，僅有調查委託需求。"), ("low", "high", "舊工業維護設施與識別檔案較相關。"), ("low", "medium", "燃料設施可能尋找特定公司序號，必須先查型號。")],
     [("泵站側門留下卡槽，主門外有居民封條。", "先讀取卡號並和舊值班表比對，確定可能的維修入口。", "需電子讀取設備、時間與現任管理者同意；不能以舊卡繞過現行所有權。"), ("遺跡內一扇門有電，另一扇只有空卡框。", "在確認相容性後嘗試有電的讀取器，記錄明確成功或拒絕。", "卡片不供電，不消除門後危險；失敗不能扣掉虛構開鎖耗材。")],
     "item_ownership electronics identification exploration knowledge npc_relationship regional_trade", "FICTION-WOOL WG-04")

item("hospital_id_card", "medical_staff_identifier", 15, 60, "rare", "old_world identity medical", "explore trade", "compare_staff_record trace_store_room return_identifier", "clinic_archive staff_locker personal_effects",
     "價值在醫療設施查檔與來源核對，不是偽造專業資格或現成的救治權限。",
     "掛繩洗得褪色，照片旁邊貼著一小片補過的透明膠。",
     "能看見部門縮寫與人名，可能是職員識別物；現行有效性未知。",
     "可與舊醫院排班與領料紀錄比對，但不證明現任持有者懂醫療，也不保證附帶電子門禁。",
     "候選內容是藥品出處與失物查證，避免把醫院標誌變成通用治療選項。",
     [("low", "high", "地方診療工作可能需要追溯舊庫房與採購紀錄。"), ("low", "medium", "舊職員檔案與工傷紀錄可能相關。"), ("none", "medium", "運藥委託會在意來源核實，但不承認過期牌證為醫師資格。")],
     [("一批未標示藥箱只留下領料人縮寫。", "比對識別卡與庫房簽領記錄，找出待核驗批次。", "仍需藥物鑑定與醫療權威；核對姓名不能讓未知藥安全可用。"), ("居民想找回曾在舊診所工作之人的物件。", "以照片與部門紀錄查證後歸還。", "需得到持有人同意並完成查證；不因相片相似建立新NPC。")],
     "item_ownership knowledge identification npc_relationship jobs regional_trade", "FICTION-CANTICLE WG-04")

item("data_disk", "archival_storage_disk", 90, 120, "rare", "old_world data fragile", "explore trade", "inspect_format read_archive make_verified_copy", "office_archive sealed_terminal_case research_locker",
     "估值按可讀介面與保存條件提出；未知內容不按寶藏價出售，讀取結果可能只是日常紀錄。",
     "防塵盒上的清單還在，勾選記號停在倒數第二行。",
     "有連接端與封條，無法從外殼確定內容或是否完整。",
     "相容讀取設備可檢查資料區與校驗狀態；實際能讀出的檔案才列入已知內容，損壞區保持缺失。",
     "候選用途是有出處的設備日誌、運輸表或普通文檔；不給每片磁碟保證藏有新配方。",
     [("none", "medium", "供水與農業歷史紀錄可能有用，但缺少常備讀取設備。"), ("low", "high", "電子工坊或紀錄者較可能處理相容介面。"), ("low", "medium", "煉製批次與運輸紀錄有特定查詢需求。")],
     [("兩份裝運清單對同一批燃料寫了不同目的地。", "讀取可驗證的磁碟記錄，比較日期與簽領編號。", "需相容終端與閱讀時間；沒有資料就記錄缺失，不自動判定詐欺。"), ("調查者要帶走唯一存檔，地方保管者希望留下證據。", "在有空白媒體與校驗流程時製作一份可核對副本。", "副本需有限媒體且權利人同意；複製不產生可無限賣出的稀有原件。")],
     "item_ownership electronics knowledge identification jobs regional_trade", "FICTION-CANTICLE FICTION-WOOL")

item("paper_journal", "personal_written_record", 320, 45, "uncommon", "old_world written personal", "explore trade", "read_entries compare_route return_journal", "personal_effects old_homes field_camp",
     "一般日記沒有固定寶藏價，估值僅作保存與有需求者交付的參考。",
     "有幾頁被整齊割去，後面的字卻寫得比前面更仔細。",
     "可讀到日期與行程片段，作者身分和描述真偽尚未核實。",
     "紙張與筆跡可分出原記錄和後加註；內容是作者觀察，不等於現今地圖或世界事實。",
     "日記可保存失敗嘗試與普通生活；不要求最後一頁總有遺產或秘密入口。",
     [("medium", "medium", "居民可能尋找種植、取水或家族紀錄。"), ("low", "medium", "設備維護手記與工人日記偶有調查價值。"), ("low", "high", "商路記錄與失聯車隊行程可能受到委託人關注。")],
     [("旅程記錄提到一處如今找不到的路標。", "用相鄰地物核對筆記，提出需要探查的路段。", "路況可能已改變；需花一次實地調查，不能直接提供安全捷徑。"), ("失物主人不願公開日記，調查者卻想讀。", "選擇封存交還或取得同意後只抄必要段落。", "交還會放棄後續自行閱讀；未獲同意公開的社交後果需另定權威。")],
     "item_ownership knowledge navigation npc_relationship jobs regional_trade", "FICTION-CANTICLE LD-P02")

item("repair_manual", "machine_service_manual", 650, 150, "uncommon", "old_world technical written", "explore trade", "identify_model compare_fault_steps reference_procedure", "workshop_shelf maintenance_office service_vehicle",
     "有型號索引、完整故障表的手冊對使用相同設備的人有價值；不適配的版本較難出售。",
     "最常翻的頁緣沾滿指印，工具清單上卻有兩項被鉛筆劃掉。",
     "封面能辨識設備系列，內頁有油污與缺角；不確定是否符合眼前機器。",
     "可按型號與版本查找檢查順序；手冊提供知識，操作仍需技術能力、工具與安全停機。",
     "候選維修用途先限定一組設備，避免成為所有機械的通用解答或一次性技能加點書。",
     [("low", "high", "泵、農具等設備若型號相容便有需求，當地印製來源稀少。"), ("medium", "high", "工坊保存與交換型號資料，也可能已有重複版本。"), ("low", "high", "燃料輸送設備的停機成本使相容手冊有價值。")],
     [("新希望水泵發出異音，操作員準備直接拆開。", "先比對型號與故障表，指出需要觀察的部位。", "需停機檢查時間與MECHANICS相關解讀能力；查表本身不完成修理。"), ("灰谷買家只缺手冊中的接線附頁。", "在確認版本相同後提供閱讀或抄錄安排。", "需持有人同意與抄錄時間；缺頁不能憑敘事補出，原本完整性仍有價值。")],
     "item_ownership knowledge repair jobs regional_trade", "WG-01 FICTION-CANTICLE")

item("medical_manual", "clinical_reference", 850, 180, "rare", "old_world medical written", "explore trade survival", "check_reference compare_supply_list consult_with_medic", "clinic_archive training_room medical_locker",
     "完整且可辨識版本的參考資料對合格照護者有用；不能把讀物視作藥物或即時醫療能力。",
     "書頁間夾著數張不一致的領料表，封底留下反覆消毒的水痕。",
     "可見症狀表、圖示與筆記，不知道哪些內容已過時或不適合目前環境。",
     "可辨識編纂目的及附錄缺失；具體照護需要專業判斷、用品與正式傷病規則。",
     "候選用途聚焦查證、整理用品與協助診療工作，不在描述裡寫治療量或確診結果。",
     [("low", "high", "地方照護者缺少可核對的參考資料。"), ("low", "medium", "工傷照護與藥品整理可能需要特定章節。"), ("none", "high", "長途醫療補給工作可能需要清楚版本與適用範圍。")],
     [("診所收到一批外盒縮寫難辨的舊用品。", "和照護者一起核對手冊的用品索引，分出需要另查的項目。", "需要專業者與時間；紙上對照不能證明藥物未變質。"), ("商隊準備運送醫療箱卻漏列基本耗材。", "依委託用途比對清單，指出缺項給雇主決定。", "只完成清單工作，不生成耗材；療效與補給交付需別的系統。")],
     "item_ownership knowledge identification injury jobs regional_trade", "FICTION-CANTICLE WG-01")

item("military_manual", "field_procedure_reference", 540, 110, "uncommon", "old_world doctrine written", "explore trade combat", "study_signals compare_position_plan reference_evacuation", "old_checkpoint training_store military_locker",
     "價值在可理解的程序與舊地圖註記；年代過舊或器材不同時不能直接套用戰術。",
     "封面的隊號被塗掉，撤離章節卻被人用布條特別標了出來。",
     "有隊形、信號與路障草圖；不知道是否符合目前道路或武器。",
     "是特定組織的野外程序參考，能協助解讀標記；不授予軍階、武器所有權或戰鬥熟練。",
     "候選用途可包括避免誤會與撤離，保留非殺傷解法；實際戰術效益另待combat_extension。",
     [("low", "low", "地方守衛只需要少數交通與撤離章節。"), ("low", "medium", "舊哨站調查者可能需要識讀標記。"), ("medium", "high", "商隊護衛對溝通與護送程序有具體需求。")],
     [("廢檢查站地面上的標記被誤認為安全通道。", "比對手冊符號，提出需要另查的禁行區。", "標記可能過期，仍須實地確認；讀懂符號不會清除危險。"), ("兩支護送隊的手勢互相衝突。", "安排共同參考的一套撤離信號並演練。", "需雙方同意與演練時間；不直接增加命中或保證戰鬥勝利。")],
     "item_ownership knowledge jobs npc_relationship combat_extension regional_trade", "WG-04 FICTION-METRO")

item("planting_manual", "agricultural_reference", 620, 140, "uncommon", "old_world agriculture written", "survival trade explore", "compare_crop_notes identify_storage_needs plan_trial_plot", "farmhouse_shelf agricultural_office seed_store",
     "適合本地作物與土壤條件的章節有價值；異地氣候與不明種子不能照書保證收成。",
     "封底折成一個小袋，裡面的種粒已經碎成深色的粉。",
     "可見播種、儲藏和輪作圖表，作者註記的氣候與現在未必相同。",
     "可區分一般栽培知識與地方試驗紀錄；實際成活率仍需作物、用水與土壤資料。",
     "候選內容讓文獻支持小規模試驗和農業工作，不用一次交書永久倍增全城糧食。",
     [("medium", "high", "農戶與種子保管者關心本地適用版本，也可能交換試驗註記。"), ("low", "medium", "工業聚落的小菜圃可能需要儲種與輪作知識。"), ("none", "medium", "節水栽培的特定章節可能有需求，但不是燃料地的固定商品。")],
     [("新希望發現一包來源不明的種子。", "比對儲藏與外觀記錄，制定小塊試種方案。", "需留出土地、水與觀察時間；不把外觀相似等同鑑定成功。"), ("乾井居民想把所有水一次投入新菜圃。", "對照書中的條件限制，提出分批觀察與保留飲水的方案。", "只提供計畫依據；實際耕作、用水與產量需另定世界規則。")],
     "item_ownership knowledge identification jobs regional_trade", "FICTION-CANTICLE WG-03")

item("geological_survey_map", "survey_document", 180, 190, "rare", "old_world map geology", "explore trade", "compare_strata locate_survey_point annotate_uncertainty", "survey_office field_case geological_archive",
     "位置與比例尺仍可對照的圖有調查價值，但地質標記不是可立即收取的資源。",
     "地圖邊框剪掉一角，保留下來的方格上擠滿了三種顏色的筆記。",
     "有等高線、鑽孔號與舊路標；日期、座標基準和現況尚待核對。",
     "可辨識調查範圍與採樣位置，部分標記只是推測層；需現地比對後才能建立候選位置。",
     "候選內容是把風險變得更可問，而非生成礦脈、泉眼或採集量；地貌也可能已變。",
     [("low", "high", "井址調查與坡地用水可能需要舊鑽孔資料。"), ("low", "medium", "材料來源調查者關心特定岩層而非整張圖。"), ("low", "high", "尋找舊井與穩定道路基底有具體需求。")],
     [("乾井附近兩個候選井址的傳言相互矛盾。", "對照舊鑽孔位置，先找可核對的實體標記。", "需實地行走與導航能力；舊孔位不保證有水，不直接改供水。"), ("灰谷商隊想跨過新塌坡節省路程。", "將圖上的坡層資訊與現場裂縫比較，提出調查範圍。", "地圖可能過期；只能指出疑點，安全通行仍需現況與路線權威。")],
     "item_ownership knowledge navigation exploration hazards jobs regional_trade", "FICTION-METRO LD-P01")

# Technology candidates: no instant stat/skill gains, all installation deferred.
item("neural_reflex_module", "sensor_interface_module", 160, 750, "rare", "old_world neural interface", "explore trade combat", "inspect_interface run_external_diagnostic seek_specialist", "sealed_research_case rehabilitation_lab prototype_locker",
     "估值反映完整介面與研究價值，並非按保證的反應增益計價；安裝風險未平衡。",
     "外殼邊緣有一排接點，其中一個被刻意封住。",
     "標籤提到反應測試，但無法知道受試者條件與實際功能。",
     "可檢查它接收外部感測訊號的介面；神經適配與長期影響仍未知，不能自行接入人體。",
     "候選成長路線先經外接測試與專家判讀，是否可安裝及效果另由未來規則決定。",
     [("none", "low", "一般居民沒有適配設備；有醫療研究委託時才有需求。"), ("none", "high", "電子研究者可能需要完整接點與來源紀錄。"), ("none", "medium", "外來收購者可能找特定型號，不能代表當地常備庫存。")],
     [("研究站的外接測試座仍留下相同介面。", "在隔離測試台讀取模組回應，確認是否能通訊。", "需相容電源、專門操作與時間；通訊成功不證明可安全植入。"), ("買家要拆開外殼取走一片基板。", "決定保留完整模組供後續診斷，或交給有資格的研究者。", "交付會放棄同一模組的其他去向；拆解前要明示會失去完整性。")],
     "item_ownership electronics identification injury equipment knowledge regional_trade", "WG-04 FICTION-CANTICLE")

item("old_world_tactical_chip", "training_data_chip", 35, 420, "rare", "old_world training data", "combat explore trade", "verify_simulation_format review_scenario compare_doctrine", "training_terminal military_archive sealed_case",
     "估值來自可讀的訓練資料；不能以未實作的永久戰力加成作保證。",
     "晶片殼上有一道深刮痕，旁邊的版本貼紙仍黏得很牢。",
     "標記像演訓資料，沒有相容終端便不知道內容。",
     "可載入特定模擬格式的舊演訓紀錄；和現今武器、地形是否適用需另外判讀。",
     "候選用途是訓練工作、舊設施調查與戰術理解；持有資料不等於學會技能。",
     [("none", "low", "地方守衛可能只對可讀的撤離演練有興趣。"), ("low", "medium", "舊終端工坊可處理格式，但通常沒有完整模擬設備。"), ("none", "high", "護送訓練委託可能需要可對照的行動紀錄。")],
     [("護送隊爭論一段演訓是否適用狹窄山口。", "讀取場景限制，指出哪些條件與現場不符。", "需相容終端、閱讀與討論時間；不直接提高隊伍命中或替玩家選戰術。"), ("軍事倉庫的演訓編號與晶片版本吻合。", "用資料索引縮小需要檢查的訓練室。", "只是地點線索；進入與取物仍需現場許可和探索規則。")],
     "item_ownership electronics knowledge combat_extension skills_growth jobs regional_trade", "WG-04 FICTION-CANTICLE")

item("muscle_stimulator", "rehabilitation_device", 950, 560, "rare", "old_world medical powered", "survival trade explore", "inspect_output compare_protocol seek_clinical_test", "rehabilitation_room medical_store research_locker",
     "完整設備可供研究或專業復健用途；不按力量增幅定價，也不保證適合健康人使用。",
     "旋鈕刻度保留著手工畫的停止線，電極包卻早已不在盒內。",
     "像是接觸式醫療裝置，知道需要電源與外接部件，尚未驗證輸出。",
     "這類設備用於受控條件下的肌肉刺激；缺少適配部件或專業監督時不能把它當力量增強器。",
     "候選長期用途需接正式傷病與復健設計；機器圖片不產生人體效果。",
     [("none", "medium", "若有復健需求與合格人員才可能需要設備。"), ("low", "high", "電子維修與醫療研究可分工檢查，但不能代替臨床判斷。"), ("none", "low", "運輸負擔高，缺乏相容配件時買家很少。")],
     [("舊診療室留下設備記錄，未註明最後一次校驗。", "先在測試負載上檢查輸出是否可控。", "需專業測試台與時間；禁止直接拿角色身體試機。"), ("照護者想接收設備，商人只願收外殼零件。", "選擇完整交付供評估，或保留等待配件線索。", "搬運佔重量；交付不即時治癒NPC，也不直接提升角色力量。")],
     "item_ownership electronics injury repair jobs regional_trade", "WG-03 FICTION-CANTICLE",
     relation("copper_wire precision_parts", "只能修復外部連接與可校驗機械件；醫療輸出校準需要專業規則，不能保證治療用途。"),
     recover("copper_wire circuit_board", "拆解後不再是完整刺激器；不提供可直接再次組裝的完整替代裝置。"), "TOOL")

item("memory_core", "archival_computing_core", 480, 680, "rare", "old_world data computing", "explore trade", "inspect_bus read_verified_blocks compare_archive", "sealed_server_case research_archive decommissioned_control_room",
     "完整接口與可驗證資料區有研究價值；未知檔案內容不預先估為萬用知識寶庫。",
     "冷卻片間塞著一小張紙，上面只有一個被反覆圈起的編號。",
     "核心未供電，編號與接頭能看見，資料是否仍在無法確定。",
     "它保存設備資料而非可直接轉給人的完整記憶；能讀到的區塊與錯誤區必須分開。",
     "候選內容可以通向設備史、研究紀錄或殘缺維修圖；不給讀取者即時技能加成。",
     [("none", "medium", "公共設備調查有可能需要舊資料，但無常備讀取設備。"), ("low", "high", "電子研究與控制設備維護對相容核心有需求。"), ("none", "medium", "燃料批次與管線資料若可讀才有特定用途。")],
     [("控制室終端只報出一個缺失的設備編號。", "對照核心可讀索引，找到對應機型的文檔名稱。", "需相容總線與讀取時間；查到名稱不等於取得完整修復步驟。"), ("兩位買家分別要資料與硬體。", "先確認可合法備份的區塊，再決定核心去向。", "備份需要媒體、驗證與所有人同意；不能把複製當成無限複製獨特物。")],
     "item_ownership electronics knowledge identification jobs regional_trade", "FICTION-CANTICLE WG-03")

item("military_medical_chip", "medical_archive_chip", 30, 500, "rare", "old_world medical data", "survival explore trade", "verify_protocol compare_triage_record consult_specialist", "field_hospital_terminal medical_archive sealed_case",
     "資料可能幫助專業人員理解舊醫療流程；不保證包含當前需要的處置或相容器材。",
     "防塵帽上畫著三個小點，盒內說明卻只有兩種狀態。",
     "標籤涉及醫療分流，未知內容和版本不能直接用來救治。",
     "可辨識資料適用的舊設備與流程版本；實際醫療判斷仍需合格人員和傷病規則。",
     "候選價值來自版本查證、找設備與研究工作；不設『吃掉晶片就會醫術』。",
     [("none", "high", "診療資料保存委託可能需要可核對版本。"), ("low", "medium", "讀取設備較可能找到，但專業解讀仍需醫療協作。"), ("none", "medium", "長途醫療後勤可能對分流紀錄有研究需求。")],
     [("舊野戰診所的標籤顏色與地方現行標準相反。", "讀取晶片中的版本註記，指出不應混用的標準。", "需終端與醫療專業；不能照字面把顏色直接當成傷勢判定。"), ("藥箱交付人想證明運送內容符合舊清單。", "比對資料版本、箱號與實物標記。", "需人工清點，物品保存狀態另驗；文件不能替不存在的用品背書。")],
     "item_ownership electronics knowledge injury identification jobs regional_trade", "FICTION-CANTICLE WG-01")

item("precision_engineering_manual", "precision_calibration_reference", 980, 360, "rare", "old_world technical calibration", "explore trade", "read_tolerance_table plan_measurement compare_fixture", "metrology_room engineering_archive precision_workshop",
     "特定公差表與量測方法對具備工具的人有用；沒有量具時不會自動得到精密加工能力。",
     "表格旁有一行細字提醒先量溫度，後面的測試頁保存得格外乾淨。",
     "可見公差、治具和校準圖，缺少實物量具不能照表直接完工。",
     "可辨識參考標準與允許偏差；操作仍需相容量具、材料、技術能力與檢驗。",
     "候選定位是高階維修的知識門檻，讓低階手冊保留日常故障用途而非被全面淘汰。",
     [("none", "medium", "水泵與農機只有特定部件需要高精度量測。"), ("low", "high", "工坊可能尋找校準依據，但是否有相容治具決定用途。"), ("none", "high", "燃料泵密封與量測工作可能需要專門資料。")],
     [("乾井兩個替換泵件外形相同卻不能互換。", "比對公差表，列出需要量測的尺寸。", "需適合量具與技術；手冊不把普通廢鐵直接變成精密零件。"), ("灰谷工坊的量具沒有校準紀錄。", "依手冊規劃比對流程並尋找可用參考件。", "需要參考件與停工時間；不能用待校準量具證明自己準確。")],
     "item_ownership knowledge repair crafting jobs regional_trade", "WG-01 FICTION-CANTICLE")

item("unknown_implant", "unclassified_medical_hardware", 75, None, "rare", "old_world unknown implant", "explore trade", "document_shell seek_identification keep_sealed", "sealed_medical_case research_locker contaminated_archive",
     "用途、適配條件與危害未知，不提出普遍售價；僅有具體研究委託人可表達收受意願。",
     "透明盒裡的金屬片像一片折起的葉，封條沒有常見醫療標記。",
     "只能看到外形與少量接點，不知道應放在哪裡或是否接觸過人體。",
     "初步檢查可分類材料與接口；即使識別型號，安全性、適配與是否可安裝仍需專門驗證。",
     "候選劇情從拒絕自行安裝開始也成立；保留、交付研究或封存都比隨機永久加點更合理。",
     [("none", "low", "地方照護者可能願意協助轉介，沒有直接使用需求。"), ("none", "high", "特定電子與醫療研究者願意檢查完整封裝，需先談保存條件。"), ("none", "medium", "外來收藏者可能詢問，但其說法不能作安全性證據。")],
     [("商人宣稱裝上就能改善反應，卻說不出型號。", "選擇查驗封條與紀錄，或將物件保持封存。", "查證需時間與專家，沒有資料就不提供安裝選項。"), ("研究者願意接收，但要求保留完整包裝與發現地點。", "提供來源紀錄並協商交付或暫借。", "交付需明確所有權與歸還條件；拆封可能使原本證據失去價值。")],
     "item_ownership identification electronics injury knowledge npc_relationship regional_trade", "FICTION-ROADSIDE WG-06")

item("black_box_memory", "incident_recording_module", 360, 450, "rare", "old_world data incident", "explore trade", "recover_readable_log verify_sequence submit_evidence", "crashed_service_vehicle control_room sealed_recorder_case",
     "完整事件序列對相關調查者有價值；記錄可能無關、缺失或不可讀，不能保證藏有高價秘密。",
     "外殼焦黑，固定螺絲旁卻有一圈被新近擦亮的金屬。",
     "像事故記錄單元，外部編號可讀；尚不知道何時停止記錄。",
     "可核對讀得出的時間序列與校驗標記；最後一段缺失就是缺失，不用敘事填入兇手。",
     "候選用途是釐清運輸事故與設備停機原因；公開、交還或封存可能有不同關係後果。",
     [("none", "medium", "補給事故牽涉當地供給時才有委託需求。"), ("low", "high", "設備事故調查較可能找到讀取能力。"), ("none", "high", "運輸與燃料事故的當事人可能需要可驗證記錄。")],
     [("運輸車沉沒後，兩個聚落互相指控未按時出發。", "讀取可驗證時間點，分開記錄已知與空白區。", "需讀取工具與現場資料；時鐘可能需校準，不能單靠一串數字定罪。"), ("設備管理者要求先銷毀記錄再交出零件。", "選擇保留完整證據、尋找合法查驗人或放棄交易。", "保留會佔運輸重量並放棄當次交易，關係變動需正式後果權威。")],
     "item_ownership electronics identification knowledge jobs reputation regional_trade", "FICTION-WOOL FICTION-CANTICLE")

# Anomalies: names are local labels, observations are bounded, no routine stock
# or universal prices. These are original phenomena, not copied artifacts.
item("uncold_ice", "persistent_cold_object", 420, None, "rare", "anomaly thermal unknown", "explore trade survival", "observe_temperature isolate_sample seek_researcher", "sealed_cold_room anomalous_drain mineral_case",
     "沒有穩定價格；灰谷熱工研究者或乾井冷藏委託人可能提出有條件的收受意願。",
     "一塊像透明冰的物件，包裹它的布卻沒有濕。",
     "附近溫度計讀數會下降，外形暫未改變；名字只是發現者的綽號。",
     "隔離測試可記錄特定距離與時間下的降溫現象；持續時間、可否接觸食物和材料成分仍未確認。",
     "候選用途是受控降溫研究，不是永動冰箱或保證保存所有食品的背包增益。",
     [("none", "medium", "食物保管者可能想了解降溫現象，需先驗證食物接觸安全。"), ("none", "high", "熱工研究者對隔離測試有具體需求。"), ("none", "high", "高溫運輸工作可能願意資助測試，不能假定已有冷鏈市場。")],
     [("舊冷庫的溫度紀錄與設備斷電時間不符。", "隔離物件並做同時段對照觀察。", "需量測器材與停留時間；只報讀數，不能據此宣布可食用或無害。"), ("保管人想把未知物直接放進公共水槽。", "提出先封閉容器測試，保留水槽供水。", "需容器與研究時間；拒絕直接使用不會獲得即時冷藏效果。")],
     "item_ownership identification hazards exploration knowledge regional_trade", "FICTION-ROADSIDE WG-06")

item("black_water_drop", "suspended_dark_liquid", 90, None, "rare", "anomaly liquid unknown", "explore trade", "seal_sample observe_volume compare_container", "anomalous_seep sealed_vial abandoned_lab",
     "未知液滴沒有通用售價；只記錄研究者是否願意在封存條件下接收。",
     "瓶內的黑點像液體，傾斜時卻比瓶身慢了一拍。",
     "短時間觀察未見體積改變；不知道成分、毒性或是否可與水混合。",
     "可測得在特定容器裡的流動與揮發行為；結果不證明長期不蒸發，更不代表可飲用。",
     "候選以樣本保管與觀察為主，不能轉成無限水源、燃料或出售循環。",
     [("none", "low", "供水者會關心污染風險，通常只願協助隔離而非購買。"), ("none", "high", "材料研究者可能接收有清楚來源的封存樣本。"), ("none", "medium", "煉製研究者對流動特性有興趣，但不當可燃料收購。")],
     [("一條排水渠旁發現相同黑點，居民擔心混入井水。", "保持樣本密封並標記發現位置供正式檢驗。", "需容器與運送時間；不能用肉眼檢查宣告水源安全或有毒。"), ("買家要求倒入自己的空瓶，卻不提供來源簽收。", "協商保留原容器或拒絕交接。", "轉瓶可能失去比較條件；交付必須記錄物件與保管責任。")],
     "item_ownership identification hazards knowledge jobs regional_trade", "FICTION-ROADSIDE WG-06")

item("hollow_stone", "low_mass_mineral", 65, None, "rare", "anomaly mineral mass", "explore trade", "compare_mass secure_sample inspect_structure", "rockfall_pocket anomalous_quarry survey_case",
     "沒有普遍市場估價；材料研究者與運輸工匠可能對量測結果提出特定委託。",
     "表面像密實石料，拿起時卻讓人錯估手中的重量。",
     "相同大小的普通石塊較重；不知道裡面是否真的空心。",
     "可比對質量與體積，但空腔、結構強度與成因需另外檢查；重量小不等於能承重或漂浮。",
     "候選價值來自不尋常材料，而非取消所有貨物重量的魔法背包。",
     [("none", "low", "農業工作沒有直接材料用途，除非有具體調查委託。"), ("none", "high", "材料工匠可能想確認是否為空腔或特殊結構。"), ("none", "medium", "運輸者可能對輕質材料有興趣，但需強度證據。")],
     [("礦坑秤臺把這塊石頭誤記成少交貨。", "用已校準的秤與普通樣本做對照，保留稱量紀錄。", "需要可靠量具與雙方見證；一次秤量不解釋成因。"), ("工匠想把石塊切開作展示。", "選擇保持原樣繼續量測，或先安排無損檢查。", "切開可能破壞唯一樣本；沒有正式檢查規則時不承諾內部結構。")],
     "item_ownership identification knowledge exploration regional_trade", "FICTION-ROADSIDE WG-06")

item("humming_stone", "electrically_responsive_mineral", 380, None, "rare", "anomaly sound electricity", "explore trade", "compare_hum isolate_from_power record_response", "substation_rubble anomalous_rock_pocket sealed_sample_box",
     "沒有通用售價；灰谷電子研究者關心可重複聲響，其他買家需求取決於可驗證用途。",
     "靠近某些舊電器時，它的細聲會從低鳴變成短促顫音。",
     "曾在帶電設備附近出聲，但尚未排除震動或其他干擾。",
     "對照測試可記錄與特定通電狀態的關聯；不能因此宣稱能定位所有電線或保證無害。",
     "候選先用於調查線索，驗證後才可能有特定測試用途；不取代萬用電表所有功能。",
     [("none", "low", "水閘設備有異音時才可能找研究協助。"), ("none", "high", "電子研究者願意接收有設備對照紀錄的樣本。"), ("none", "medium", "燃料站操作員可能對設備異常提示感興趣，但需先查干擾。")],
     [("變電棚斷電後仍聽到低鳴，居民以為有機器偷開。", "依次隔離設備，比對石頭聲響與可測電源。", "需安全隔離與時間；聲響不能單獨證明有人偷用能源。"), ("商人想把鳴石當尋寶器宣傳。", "提供已驗證範圍或拒絕誇大用途的交易。", "較窄的說明可能降低買家興趣；未證實能力不寫入使用選項。")],
     "item_ownership electronics identification hazards knowledge regional_trade", "FICTION-ROADSIDE WG-06")

item("static_bone", "charge_accumulating_fragment", 190, None, "rare", "anomaly charge fragment", "explore trade", "isolate_charge compare_dry_conditions transfer_to_specialist", "dry_channel anomalous_scrap_nest sample_locker",
     "只有特定靜電研究需求，未驗證能量輸出前不按電池或發電設備計價。",
     "骨狀碎片上常黏著細小灰塵，隔著布也能聽見輕微劈啪聲。",
     "靠近輕薄材料時有吸附現象，不知道是不是普通靜電或其他原因。",
     "可記錄濕度、接觸材料與累積電荷的關係；目前不證明可持續供電或安全接觸燃料。",
     "候選可形成保存與運輸難題，不能成為無限電池或沒有代價的電擊武器。",
     [("none", "low", "一般工作缺少用途，保管者更在意避免接觸易燃物。"), ("none", "high", "電學工匠可能願做受控對照。"), ("none", "medium", "燃料場所會要求隔離，有安全研究需求但不當常備貨物。")],
     [("樣本箱靠近燃料裝卸處時出現劈啪聲。", "先把樣本移至核準的隔離區，再安排檢驗。", "需要保管人同意與搬運距離；是否著火不能由敘事擲一個未定義風險。"), ("工匠提出用它直接替收音機充電。", "要求先量測輸出與穩定性，或保持封存。", "需測量設備與時間；微弱電荷不等同相容電源。")],
     "item_ownership electronics identification hazards cargo knowledge regional_trade", "FICTION-ROADSIDE WG-06")

item("reverse_magnetic_shard", "metal_repelling_fragment", 260, None, "rare", "anomaly magnetism fragment", "explore trade", "test_sample_response isolate_from_tools seek_metallurgist", "anomalous_machine_ruin sealed_sample_box fallen_pylon",
     "沒有標準價格；只有願意測試特定金屬反應的工匠或研究者提出需求。",
     "薄片邊緣缺了一角，旁邊散落的鐵屑像被人刻意推開。",
     "一小塊測試金屬曾向外移動；反應範圍、金屬種類與力度未知。",
     "可用已知材料測定有限距離內的反應；不能保證推開所有金屬、阻擋子彈或移動重門。",
     "候選用途是材料辨識與受控機構研究，不是全用途磁力工具或護甲加成。",
     [("none", "low", "農具使用者沒有未經測試樣本的直接需求。"), ("none", "high", "金屬工坊對不同材料的反應有實驗需求。"), ("none", "medium", "運輸機件研究可能有興趣，但需與羅盤及零件分開保管。")],
     [("修理台上的墊片總是滑離同一角落。", "隔離薄片並用已知金屬樣本做對照。", "需清空操作台與時間，不能在仍運作的設備上冒然測試。"), ("商隊想把薄片放進裝滿零件的工具箱。", "提出分箱保管，避免未查明的相互影響。", "需額外容器與負重安排；分箱不代表已證明全部運輸安全。")],
     "item_ownership identification electronics hazards cargo knowledge regional_trade", "FICTION-ROADSIDE WG-06")

item("shadowless_glass", "unusual_optical_plate", 340, None, "rare", "anomaly optics glass", "explore trade", "compare_lighting mark_edges inspect_refraction", "optics_lab anomalous_window_frame sealed_crate",
     "沒有一般玻璃的通用估價；光學研究者可能因可重複現象願意接收。",
     "把它靠在牆前，牆上的暗痕卻不像它的輪廓。",
     "在一種光線角度下看不到預期影子，其他角度尚未比較。",
     "可記錄特定光源與角度的透射現象；不證明穿過它的人會隱形，也不能假定不會割傷。",
     "候選以觀察、標記與運送易碎物為核心；名稱是地方俗稱，不是免疫偵測的規則。",
     [("none", "low", "一般窗戶需求偏重耐用，特殊樣本沒有直接民生用途。"), ("none", "high", "光學與照明研究者會在意原片邊緣與來源。"), ("none", "medium", "地景測量委託可能願意研究光線現象，但不常備進貨。")],
     [("廢樓窗框裡看似空著，布條卻被割開。", "先用可見標記圈出玻璃邊緣再安排取下。", "需保護包材與拆卸時間；接觸傷害須有正式hazards/injury規則。"), ("研究者想測試它能否遮住路標燈。", "在封閉測試區比較不同角度的照明。", "需光源與時間，不能拿公共路標直接實驗或宣稱永久隱蔽。")],
     "item_ownership identification lighting hazards injury cargo knowledge regional_trade", "FICTION-ROADSIDE WG-06")

item("gray_seed", "unclassified_seed", 8, None, "rare", "anomaly seed biological", "explore trade survival", "document_seed keep_quarantined plan_controlled_trial", "sealed_botanical_case anomalous_garden soil_sample_box",
     "沒有普通種子的確定農業價值；只有願意隔離試驗的研究者或種子保管者表達需求。",
     "灰色外皮像沾了細粉，用布擦拭後仍沒有露出別的顏色。",
     "外形像種子，未知是否有生命、能否發芽或接觸農田是否安全。",
     "可記錄外觀和封存條件；鑑定到植物類型也不等於知道產量、可食性或擴散風險。",
     "候選長期目標是有限、隔離的觀察，絕不直接成為永久增產道具或會自行擴散的世界事件。",
     [("none", "high", "種子保管者可能願意提供隔離試驗，需求以不危及現有作物為前提。"), ("none", "low", "工業聚落多半只能協助保存與轉運。"), ("none", "medium", "耐旱傳聞可能吸引買家，但無試驗不能保證沙地可種。")],
     [("農戶想把灰種混進下一批普通播種。", "提出單獨容器試驗，將普通種子保留給正常種植。", "需專用容器、水與多日觀察；不保證發芽，試驗不能污染正常田區。"), ("商人稱這是能免灌溉的作物，要求立即交易。", "索取來源與試種紀錄，或保持封存等待辨識。", "查證可能錯過當次交易；未證實的宣稱不進物品效果欄。")],
     "item_ownership identification hazards knowledge jobs regional_trade", "FICTION-ROADSIDE FICTION-CANTICLE")

item("heat_core", "persistent_warm_object", 1150, None, "rare", "anomaly thermal core", "explore trade survival", "measure_heat isolate_container plan_test_load", "sealed_thermal_chamber anomalous_boiler_case survey_locker",
     "不按永續能源估值；熱工與烹煮設備研究者可能以測試條件提出交付協議。",
     "粗糙外殼附近的霧氣總先散開，找不到可開關的地方。",
     "近處可量到持續溫熱；不知道可持續多久、是否會升溫或釋出其他物質。",
     "可在隔離條件下記錄溫度與時間；尚未驗證為可接觸食物的熱源，也不等於可驅動機械。",
     "候選用途有研究與有條件的保溫方向，重量與隔離運輸是負擔；不能生成無限燃料。",
     [("none", "medium", "食品保存或烹煮工作可能提出研究需求，需先驗證接觸安全。"), ("none", "high", "熱工工坊可能具備量測與隔離空間。"), ("none", "high", "煉製地對熱源有興趣，也需避免與燃料混放。")],
     [("商隊想把熱核塞入裝有食物的保溫袋。", "先要求隔離量測與獨立保管，再決定是否能使用。", "需容器、重量與等待時間；不直接替全隊提供保溫。"), ("工坊提出將熱核接到一個不完整的蒸汽裝置。", "提供測試負載方案或保留樣本拒絕破壞性嘗試。", "需設備、專門技術與明確風險權威；發熱不保證足夠功率或安全壓力。")],
     "item_ownership identification hazards cargo knowledge electronics regional_trade", "FICTION-ROADSIDE WG-03")

item("silence_box", "radio_interference_object", 620, None, "rare", "anomaly radio interference", "explore trade", "map_interference isolate_from_radio seek_signal_specialist", "abandoned_relay sealed_electronics_case anomalous_control_room",
     "只有明確通訊研究或隔離需求，不以尚未驗證的隱匿能力出售；普遍價格保持未知。",
     "沒有旋鈕的方盒一靠近桌邊，旁邊收音機的聲音便斷成幾截。",
     "一部收音機曾在附近失去清楚訊號；不知道受影響頻段、範圍或原因。",
     "可比對不同距離、頻段與設備的干擾；不能假定遮蔽所有通訊，更不能讓持有者無法被發現。",
     "候選價值同時包含調查與不方便：運送它可能需要避開己方聯絡設備。",
     [("none", "medium", "供水值班若靠無線電聯絡，會關注干擾來源而非希望擁有干擾器。"), ("none", "high", "訊號維修者可能願意建立測試紀錄。"), ("none", "high", "商隊聯絡站有隔離與查明問題的動機，但不代表可常規交易。")],
     [("灰谷聯絡桌在同一時段反覆失去聲音。", "移開樣本並比較距離，找出是否與盒子相關。", "需協調測試時段與備用聯絡方式；一次恢復不能證明全部問題解決。"), ("買家要求把盒子帶到正在值班的商隊電臺展示。", "改約封閉場地測試或拒絕干擾公共聯絡。", "需另找地點與時間；不以神祕能力直接切斷NPC通信狀態。")],
     "item_ownership electronics identification hazards cargo knowledge npc_relationship regional_trade", "FICTION-ROADSIDE FICTION-METRO")

# Unique personal objects: all supply is explicitly none, no repeatable stock.
item("last_round", "named_revolver", 1020, None, "unique", "unique firearm provenance", "combat explore trade", "inspect_inscription trace_ownership entrust_revolver", "named_estate_locker documented_personal_transfer",
     "唯一物件不設普遍售價；需要查明來源、持有權與特定買家目的後才談交付。",
     "彈巢旁刻了六個名字，其中一個字曾被反覆描深。",
     "是一把老式左輪，刻名可讀；不知道刻名者與槍的歷史，也未確認機械安全。",
     "可確認口徑與機械狀態，名字只在獨立紀錄核對後才成為已知人物關係；不因名稱保證最後一發更強。",
     "候選定位是有歷史的普通武器，唯一性由實例與來源決定；不從隨機箱子重複掉落。",
     [("none", "low", "只有與刻名或遺物交還有關的人可能提出請求。"), ("none", "medium", "工匠可能願意檢驗機械，收藏者也需先看出處。"), ("none", "high", "護送往事中的特定關係人可能尋找此槍，並非固定高價收購。")],
     [("酒館有人認得其中一個刻名，卻說另一個名字被拼錯。", "帶槍與獨立文書核對，查清刻字的先後。", "需尋訪時間與當事人同意；認得一個名字不證明擁有此槍。"), ("護衛需要臨時武器，遺物保管人不願再讓它開火。", "選擇保留為證物或在合法所有權下另行使用。", "戰鬥用途需裝備、彈藥與機械檢查規則；使用可能影響保存承諾，沒有傳說傷害加成。")],
     "item_ownership equipment combat_extension identification npc_relationship reputation regional_trade", "FICTION-CANTICLE WG-04",
     relation("spring precision_parts", "僅檢修可識別的機械件並保留刻字；修理不增加傳說屬性。"),
     recover("scrap_iron spring", "拆解會永久失去完整武器與遺物用途，須有明確毀損確認；不會產出另一把最後一發。"), "WEAPON")

item("homecoming", "named_hunting_rifle", 3400, None, "unique", "unique rifle personal", "combat explore trade", "compare_repair_marks trace_route return_rifle", "documented_personal_transfer abandoned_named_cache",
     "特定尋物者可能提出交付條件，沒有全世界一致售價；槍的歷史比型號稀有度更重要。",
     "木托補過一道長裂痕，補片上用小字刻著一個方向。",
     "是使用多年的獵槍，能看見補片與刻字；前主人的去向仍是傳聞。",
     "可核對工匠補修記號與已存在的委託紀錄；刻字不是自動定位器，機械狀態需另檢。",
     "候選故事圍繞失聯獵人的行程與熟人記憶；不保證持槍後每個居民都認得，也不生成前主人。",
     [("none", "high", "特定獵戶或失物委託人可能認得木托修補。"), ("none", "medium", "舊修理工若已有相關人物紀錄，可能辨認工法。"), ("none", "low", "一般商人只見到舊獵槍，私人來歷未必形成需求。")],
     [("新希望的修理簿留下與木托補片相同的尺寸。", "比對紀錄，找出最後一次可證實的維修時間。", "需取得查簿同意；紀錄只證明維修，不證明前主人的當前位置。"), ("一名旅人希望借槍護送補給，另有人正在尋找失物。", "決定是否暫借、保留查證或安排當面交接。", "需正式所有權與歸還條件；戰鬥另需裝備/彈藥權威，不能複製第二把槍。")],
     "item_ownership equipment combat_extension identification knowledge npc_relationship jobs regional_trade", "LD-P02 FICTION-CANTICLE",
     relation("precision_parts spring", "由適配工匠修理機械，保留木托補片的來源特徵。"),
     recover("scrap_iron spring", "拆解不可逆地失去完整遺物；回收只作符號關係，不設套利產量。"), "WEAPON")

item("number_sixty_three", "numbered_service_wrench", 860, None, "unique", "unique tool industrial", "explore trade", "compare_service_stamp operate_matching_fastener entrust_tool", "numbered_factory_tool_locker documented_personal_transfer",
     "價值取決於與特定舊設備匹配的幾何與維修紀錄，不是通用高階工具等級。",
     "柄上敲著六十三，鉗口內側另有一個不太規則的缺口。",
     "形狀像維修扳手，缺口可能是損壞也可能為特定接頭加工；尚未核對。",
     "可確認鉗口尺寸與匹配的舊固定件；只有明確適配部位可嘗試操作，無泛用開門能力。",
     "候選長期目標是回到曾看見的特殊維修口；來源與唯一所有權必須保留，不常規補貨。",
     [("none", "low", "沒有相容設備時只是一件難用的老工具，可能協助轉交。"), ("none", "high", "相關工廠的調查者可能尋找這把有記錄的工具。"), ("none", "medium", "若燃料設備沿用相同固定件才有特定需求，不能憑工業標籤通用。")],
     [("灰谷舊廠維修蓋上的螺帽有非標準缺口。", "先量測比對，確認後用六十三號轉動相容固定件。", "需安全停機與MECHANICS相關操作；匹配工具不消除內部危險或授予所有權。"), ("工匠要求磨平鉗口，好把它當普通扳手使用。", "保留原形等待專用設備線索，或選擇不可逆改造。", "改造會失去原有匹配用途；不能同時保有兩種形狀或生成另一把工具。")],
     "item_ownership exploration repair crafting knowledge npc_relationship regional_trade", "WG-01 LD-P01",
     relation("steel_stock", "只允許經量測的柄部補修；磨改鉗口是改造並可能失去匹配用途，不是假裝恢復原樣。"),
     recover("scrap_iron", "熔解會失去編號與特殊鉗口，不能從廢鐵重新產出唯一原物。"), "TOOL")

item("well_guardian", "named_watch_rifle", 3900, None, "unique", "unique rifle settlement_history", "combat explore trade", "compare_watch_record return_to_custodian inspect_mechanism", "dry_well_historical_lockbox documented_personal_transfer",
     "對乾井特定保管人具有地方歷史價值；外地沒有保證高價，且須先確認持有權。",
     "槍帶內側繡著一道水位線，鐵件的刮痕被多年擦拭磨圓了。",
     "是舊步槍，水位線標記與一些乾井舊用品相似；傳說尚未核實。",
     "可用守井值班紀錄與保管印記確認來歷；這不授予守井職權，戰鬥性能依機械狀態另定。",
     "候選去向可以是歸還公共收藏、合法保管或調查失竊，不能讓持有者自動控制井與居民。",
     [("none", "low", "外地居民通常不認得地方標記，除非已有相關委託。"), ("none", "medium", "工匠可檢查機械，但不能替乾井裁定歷史所有權。"), ("none", "high", "地方保管者與相關住民可能想查明去向；需求不是常態商店收購價。")],
     [("乾井新任值班者看到水位線繡記，懷疑它從公物箱流出。", "先核對保管紀錄再討論歸還或合法借用。", "需查證時間與現任保管權；持槍不代表任命玩家為守衛。"), ("商隊願用普通步槍交換，地方紀錄者則希望保留原物。", "在所有權清楚後選擇交換、保管或歸還。", "每條去向只移轉同一實例；交換不保留原槍，也不額外獲得地方職權。")],
     "item_ownership equipment combat_extension identification npc_relationship reputation jobs regional_trade", "FICTION-CANTICLE WG-02",
     relation("spring precision_parts", "僅檢修機械，保留槍帶與保管標記；是否射擊與文物保存承諾另定。"),
     recover("scrap_iron spring", "拆解永久失去完整地方遺物；必須先明示後果與權利人同意。"), "WEAPON")

item("unsent_letter", "unique_private_letter", 18, None, "unique", "unique written personal", "explore trade", "verify_addressee deliver_unopened preserve_letter", "documented_personal_effects lost_post_bag",
     "不設一般市場價格；可能有送達委託報酬，但報酬是工作條件，不是信件內在售價。",
     "封口只黏了一半，寄件人把收件地址寫了兩遍，又劃去其中一行。",
     "外封能讀到姓名與兩個地址；信未寄出，不知道收件人是否仍在原處。",
     "可核對書寫時期與地址沿革；信內資訊只有合法拆閱或收件者自願分享後才可知。",
     "候選故事允許送達、退回、查無此人或封存；不能為保證結局臨時生成收件者或復活死者。",
     [("none", "medium", "若住民紀錄匹配地址，可能提供轉交或查詢。"), ("none", "medium", "舊地址的工務紀錄可能提供去向線索，不代表當地買信。"), ("none", "medium", "商隊郵袋與旅人見證可能協助轉送，並非一般貨物需求。")],
     [("信封上的舊街名已改，兩處住址都有人聲稱知道。", "查閱已有住民與地址紀錄，選擇可核驗的下一站。", "需旅程與查詢時間；查無此人就是有效結果，不生成新人口。"), ("一位願意帶路的人要求先看完整信件。", "選擇保持封口並另找查詢途徑，或在權利人許可下分享必要資訊。", "不拆信可能增加路程；拆閱不能沒有代價地同時保有『未拆封』狀態。")],
     "item_ownership knowledge npc_relationship jobs reputation regional_trade", "FICTION-CANTICLE LD-P02")


def validate():
    expected = {s["content_id"] for s in SEEDS if s["art_sections"][0] in (12, 13, 14, 15)}
    assert len(ITEMS) == 39 and {i["content_id"] for i in ITEMS} == expected
    allowed_deps = set("item_ownership equipment combat_extension injury repair lighting water_treatment cooking camping cargo navigation electronics identification knowledge npc_relationship reputation jobs regional_trade crafting disassembly hazards exploration succession skills_growth".split())
    for row in ITEMS:
        assert row["status"] == "DESIGN_ONLY" and row["proposed_weight_g"] > 0
        assert len(row["hooks"]) >= 2 and row["runtime_item_id"] is None
        assert set(row["dependencies"]) <= allowed_deps, (row["content_id"], set(row["dependencies"]) - allowed_deps)
        for source in row["repair"]["inputs"] + row["salvage"]["outputs"]:
            assert source in BY_ID and source != row["content_id"]
        if row["rarity"] == "unique":
            assert all(v["supply"] == "none" for v in row["markets"].values())
        if row["art_sections"] == [14]:
            assert row["proposed_base_value_caps"] is None
        if row["repair"]["possible"] and "repair" not in row["dependencies"]:
            row["dependencies"].append("repair")
        if row["salvage"]["possible"] and "disassembly" not in row["dependencies"]:
            row["dependencies"].append("disassembly")
    ITEMS.sort(key=lambda row: row["content_id"])


if __name__ == "__main__":
    validate()
    output = BASE / "items/03-relics-anomalies-unique.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(ITEMS, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(ITEMS)} design-only records to {output}")
