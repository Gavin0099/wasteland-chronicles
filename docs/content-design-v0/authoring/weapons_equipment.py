"""Authored design proposals for sections 1–6; never a runtime importer."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SEEDS = json.loads((ROOT / 'item-seeds.json').read_text(encoding='utf-8-sig'))
INDEX = {s['content_id'].removeprefix('content_'): s for s in SEEDS}
ITEMS = []

def words(value):
    return value.split() if value else []

def links(value):
    return ['content_' + key for key in words(value)]

def add(key, subtype, weight, value, rarity, tags, roles, actions, origin, loot,
        desc, known, identified, note, value_reason, markets, hooks,
        repair, salvage, dependencies, refs):
    seed = INDEX[key]
    category = 'WEAPON' if seed['art_sections'][0] <= 4 else ('APPAREL' if seed['art_sections'][0] == 5 else 'CONTAINER')
    dep = words(dependencies)
    for required in ['item_ownership', 'regional_trade'] + (['repair'] if repair[0] else []) + (['disassembly'] if salvage[0] else []):
        if required not in dep:
            dep.append(required)
    record = {k: seed[k] for k in ('content_id', 'name_zh', 'art_file', 'art_sections', 'art_role', 'runtime_item_id')}
    record.update(status='DESIGN_ONLY', category=category, subtype=subtype,
                  proposed_weight_g=weight, proposed_base_value_caps=value,
                  value_rationale_zh=value_reason, rarity=rarity, tags=words(tags),
                  roles=words(roles), actions=words(actions), origin_tags=words(origin),
                  loot_sources=words(loot), description_zh=desc, known_description_zh=known,
                  identified_description_zh=identified, world_notes_zh=note,
                  markets={place: {'supply': row[0], 'demand': row[1], 'reason_zh': row[2]}
                           for place, row in zip(('new_hope', 'gray_valley', 'dry_well'), markets)},
                  hooks=[{'situation_zh': h[0], 'use_zh': h[1], 'cost_or_limit_zh': h[2]} for h in hooks],
                  repair={'possible': bool(repair[0]), 'inputs': links(repair[0]), 'note_zh': repair[1]},
                  salvage={'possible': bool(salvage[0]), 'outputs': links(salvage[0]), 'note_zh': salvage[1]},
                  dependencies=dep, inspiration_refs=words(refs))
    ITEMS.append(record)

# All quantities below are editorial estimates. Hooks are individual proposals.
add('rusted_knife','utility_blade',250,18,'common','blade tool corroded','combat explore trade','cut_rope scrape_label defend','settlement_households abandoned_homes','kitchen_drawer discarded_travel_kit',
    '刀尖早已缺了一角，木柄刻著一排難以辨認的姓氏。','能割薄繩，鏽斑和鬆動握柄使它不適合精細工作。','普通家用短刃；缺口需要金屬加工，清潔外表不代表適合處理傷口。','廉價短刃來自家庭雜物，新的武器 authority 不得由 blade 標籤直接取得。','18 Caps 提案反映缺口與修理負擔；250 g 沿用 ITEM-1。',
    [('high','medium','農戶常用小刀處理包裝，但鏽刃收購價有限。'),('high','low','拆屋回收常見，工坊偏好狀態更好的刃具。'),('medium','medium','旅人需要便宜備用刀，品質差異必須可見。')],
    [('貨袋被舊繩纏死。','割斷繩結取出有主的貨物。','需失主同意；割下的繩不再可回收。'),('金屬牌被厚漆遮住。','刮出部分編號，再決定是否攜走。','耗調查時間；只能露出原有文字，不能憑刀生成情報。')],
    ('steel_stock cloth','提案：技工評估缺口後才能換修，材料不代表可自行修復。'),('scrap_iron','只回收失去刀具用途的金屬，不回收另一把完整小刀。'),
    'equipment combat_extension exploration knowledge','WG-01 WG-02')
add('hunting_knife','hunting_blade',400,72,'uncommon','blade hunting sheath','combat explore survival trade','dress_game cut_brush inspect_hide','new_hope hunters','hunting_lodge hunter_tool_roll',
    '磨薄的刃口旁留著深色水痕，皮鞘反覆補過線。','比家用小刀更便於攜帶和清理獵物，仍需知道如何使用。','有護手的固定刃獵刀；刃口完整度與鞘帶是否牢靠要分開檢查。','新希望的獵人會交換磨刀經驗，不把持刀等同於狩獵能力。','72 Caps 為完整刀鞘和專用刃具的提案價；400 g 沿用 ITEM-1。',
    [('medium','high','處理獵物與野外工作有穩定需求。'),('low','medium','收皮革的工人會買，但不是每間廢料店都收。'),('low','medium','遠行者需要可靠短刃，補鞘服務較少。')],
    [('一隻已死亡的野獸堵在山徑。','在懂得處理獵物時收集可用皮料。','需要生存知識與時間；來源、腐敗和採集規則仍待定。'),('農戶的皮帶卡在灌木中。','切開枝條保留皮帶完整。','需近身作業且耗時，無法清除整片荊棘。')],
    ('leather steel_stock','皮鞘與刃身分別維修；不因一次磨刃恢復所有損壞。'),('scrap_iron leather','拆毁後只保留可用金屬與鞘皮，品質與產率另定。'),
    'equipment combat_extension exploration hazards cooking','WG-01 LD-P01')
add('entrenching_shovel','folding_shovel',1250,95,'uncommon','digging military_fold tool','explore survival combat trade','dig_drain uncover_marker brace_door','old_world_depots field_camps','engineer_locker abandoned_camp',
    '折柄鏟面的黑漆已磨成銀灰色，鉸鏈仍能鎖住。','適合狹窄地點挖土；折柄並不適合當長距離攀登錨。','舊工程鏟，鎖扣完整時才能承受一般挖掘負荷。','退役工程器具會流入三地，出土地不代表仍有軍方認證。','95 Caps 提案包含折疊鉸鏈便利性，重量指乾燥空鏟。',
    [('medium','high','清理灌溉溝需要小鏟，木柄農具仍較便宜。'),('medium','medium','工業地基與瓦礫間適用，但鉸鏈維修要工坊。'),('low','high','埋設防風繩與挖排砂溝需要耐用鏟面。')],
    [('雨水正淹入临時宿營地。','挖短排水溝，替已有遮棚導流。','需土地允許與時間；石地或洪水不能靠短鏟解決。'),('路標底座埋進浮土。','局部挖開找出朝向記號。','只恢復現場可見資訊，不能揭露整張地圖。')],
    ('steel_stock bearing','鉸鏈與鏟面要分別鑑定；裂開鏟面可能不值得修。'),('scrap_iron','拆卸報廢工具回收金屬，取消其挖掘用途。'),
    'equipment combat_extension exploration camping navigation','WG-01 FICTION-ROAD')
add('crowbar','prying_bar',2000,65,'common','pry lever metal_tool','combat explore trade','pry_crate lift_grate lever_obstruction','gray_valley salvage_yards','workshop_rack maintenance_locker',
    '彎頭已被重磨過，握處纏著從座椅拆下的布。','有可插入的縫隙時能提供槓桿，封死的厚門仍需其他方案。','一根實心鋼製撬具；彎折和支點強度限制了可撬的目標。','既有 field_kit 撬棍例子繼續獨立存在；本提案不轉換其 ID、重量單位或配方。','65 Caps 與 2000 g 是一般化物品的未採用提案，不套用既有 2 carrying-unit crowbar。',
    [('low','high','倉庫修繕需要撬具，產地依賴外運。'),('high','medium','拆解場常備，完整直桿比扭曲廢件有用。'),('medium','high','維修燃料棧板需要槓桿工具，需求受運輸量影響。')],
    [('排水格柵卡住，底下傳來求助聲。','與現場人員協作抬起邊緣。','需安全支點與其他人承接格柵；不能單人保證救援。'),('貨箱的釘蓋可以從一角掀起。','撬開蓋板檢查內容。','必須有開箱權；可能破壞封條並留下明確責任。')],
    ('steel_stock cloth','只有工坊能評估校直是否安全；纏布不恢復結構。'),('scrap_iron','報廢後視為一般金屬，不產生另一支撬棍。'),
    'equipment combat_extension exploration jobs npc_relationship','WG-01 WG-04')
add('rebar_club','improvised_club',1800,22,'common','blunt rebar improvised','combat trade explore','brace_panel drive_stake defend','gray_valley construction_ruins','collapsed_slab salvage_heap',
    '一截混凝土鋼筋，握端留下被敲平的切口。','堅重而笨拙；拿來撐住板片前必須確認切口不會滑動。','建築用帶肋鋼材，沒有刀刃，也不是測試合格的起重桿。','灰谷常見的臨時器具；便宜來自回收便利，並非高品質武器。','22 Caps 提案只略高於可用廢鋼；1800 g 沿用 ITEM-1。',
    [('medium','low','可當粗用支桿，但長途運輸不劃算。'),('high','low','來源多，拆解工人通常能自行找到。'),('low','medium','固定破損棚架有臨時需求，會與更輕工具競爭。')],
    [('傾斜鐵皮擋住狹小通道。','短時間撑住鐵皮，讓同伴先通過。','必須留人看守，不能宣稱建築已安全。'),('營地樁頭難以敲下。','作為臨時鈍重物固定已有營樁。','需要可承受的樁頭與作業時間；不生成帳篷或營樁。')],
    ('cloth','只能換握布；嚴重彎折與裂縫應報廢。'),('scrap_iron','失去器具身分後回收廢鋼，不能同時保留鋼筋棍。'),
    'equipment combat_extension exploration camping hazards','WG-01 WG-02')
add('fire_axe','rescue_axe',3200,145,'uncommon','axe rescue heavy_tool','combat explore trade','break_wood_partition clear_frame','old_world_fire_stations civic_depots','rescue_cabinet fire_station_storage',
    '斧頭上仍留著半片紅漆，柄尾繫著褪色的救援標籤。','可處理木製障礙；劈開隔板之前必須知道另一側有沒有人。','完整斧頭需牢固斧柄和可用刃口，不具隔絕電源的效力。','消防器具首先是救援工具，舊標籤不賦予進入民宅的權利。','145 Caps 提案反映耐用斧頭與完整柄，重載是攜帶代價。',
    [('low','high','木造棚舍和災後救援需要重斧。'),('medium','medium','廢公共設施能取得，切金屬仍要別的工具。'),('low','medium','燃料場所只在安全評估後使用，不能任意破拆。')],
    [('倉庫木框變形卡住救援口。','在清空另一側後破拆木框。','耗作業時間並摧毁門框，後續修繕由救援方承擔。'),('倒木壓住一件有主背包。','劈開細枝讓失主取包。','厚樹幹需更多人手；斧頭不能保證一次清開。')],
    ('steel_stock leather','金屬刃與握部修繕分開；木柄來源另待 crafting 定義。'),('scrap_iron','只回收斧頭金屬，木柄不憑空轉為清單中不存在的木材物品。'),
    'equipment combat_extension exploration jobs hazards','WG-01 FICTION-ROAD')
add('wood_axe','woodcutting_axe',2600,105,'common','axe forestry camp_tool','survival explore combat trade','split_firewood trim_fallen_branch','new_hope woodcutters','farm_shed woodcutter_camp',
    '斧柄比握把更舊，刀頭倒是保養得乾淨。','適合已倒下或獲准採伐的木料，帶著它不代表可以砍任何樹。','伐木用楔形斧頭，斧柄鬆動需先處理。','新希望會重視林緣資源，砍伐行為可能涉及公共燃料分配。','105 Caps 提案來自農林工具需求，不因能當武器而自動增價。',
    [('high','high','農林邊緣持續需要，替換工具有買家。'),('medium','medium','工坊燒火需要劈材，成品通常由外地送來。'),('low','low','缺少木材使重斧不常用，遠行商隊偶爾收購。')],
    [('營地有濕木外皮與乾燥內層。','劈開已收集木料供後續生火。','需時間且仍需要點火物；不能直接抵消寒冷。'),('農道被落枝堵住。','協助農戶整理阻路枝條。','需地主同意，報酬先談妥；不自動取得全部木料。')],
    ('steel_stock leather','刃口由工坊處理，缺失木柄仍缺正式材料設計。'),('scrap_iron','回收金屬頭後失去完整斧具，無免費木材產出。'),
    'equipment combat_extension exploration camping cooking jobs','WG-01 LD-P02')
add('scrap_machete','salvage_machete',1200,48,'common','blade brush_cutting salvage_made','combat explore trade','clear_brush cut_binding','gray_valley local_smiths','smith_workbench scavenger_pack',
    '刀背保留著原鋼板的折線，刃口卻磨得整齊。','能處理輕枝和繫帶，厚金屬不是它的工作。','回收鋼材製成的砍刀，材料品質須逐把檢查。','灰谷的回收工藝有地方特色，但不把每把拼裝刀寫成同樣損壞。','48 Caps 提案體現在地加工與有限材料品質；1200 g 沿用 ITEM-1。',
    [('medium','high','開闢被灌木遮住的小徑有需求。'),('high','medium','在地成品多，交易重點是工匠與刃口品質。'),('medium','low','沙地植被較少，通常作旅行備刃。')],
    [('荒廢菜圃入口被藤蔓遮住。','清出一人通行的開口。','耗時間且會暴露來訪痕跡，不代表清除整片菜圃。'),('拋棄車架的繫帶拉住可回收物。','割開繫帶取下已確認無主的物件。','繫帶損失；不能切開車架或直接獲得未知戰利品。')],
    ('steel_stock cloth','只對可修刃口與握部生效，裂穿刀身應退役。'),('scrap_iron','廢刀只轉入金屬回收候選，不形成完整成品循環。'),
    'equipment combat_extension exploration disassembly','WG-01 WG-05')
add('car_panel_cleaver','heavy_plate_blade',3400,88,'uncommon','heavy_blade vehicle_salvage bulky','combat trade explore','cut_thick_fiber display_workmanship','gray_valley vehicle_yards','vehicle_breaker_stall heavy_tool_chest',
    '刀面還能看見一截舊車漆，寬柄必須雙手握持。','笨重的寬刃適合有作業空間的粗切，狹窄車廂反而難展開。','大面積回收鋼刀；變形與接合品質決定是否可用。','車板刀是廢車場的地方工藝，不是任何輕刀的必然升級。','88 Caps 提案保留重加工成本，但 3400 g 會擠占旅行負荷。',
    [('low','medium','粗切織物與防護簾有小眾需求，農民更常買輕刀。'),('medium','medium','廢車場可供貨，工匠之間看重加工品質。'),('low','low','長途攜行笨重，只有固定工地願意收。')],
    [('舊貨場的厚織物綁住落箱。','在卸除張力後切開織物。','必須先支撑箱體，不能靠重刀處理受力纜索。'),('買家想辨別灰谷工匠的貨。','展示刀背加工痕作為產地線索。','需行家確認；車漆不是所有權或品質證明。')],
    ('steel_stock leather','重刀變形只能交工坊評估，握皮可另換。'),('scrap_iron','回收笨重金屬而放棄成品價值。'),
    'equipment combat_extension exploration knowledge regional_trade','WG-02 WG-05')
add('desert_sabre','travel_sabre',1150,135,'uncommon','curved_blade desert_craft sheathed','combat trade survival','cut_fabric demonstrate_identity','dry_well desert_caravans','desert_smith_stall caravan_gear_chest',
    '窄鞘外纏著防砂布，刀柄端有乾井匠人的敲印。','長刃需妥善收鞘；防砂包覆不能免去清潔。','適合攜行的地方刀式，匠印須核對才能作為來源證據。','乾井文化可辨識器具造型，但攜帶當地刀具不等於受到居民信任。','135 Caps 提案反映刀鞘與在地手工，非保證高傷害。',
    [('low','low','農用刀較實惠，旅人會為攜行性買單。'),('low','medium','收藏地方工藝與護衛有需求，供應依靠商隊。'),('medium','high','熟悉維護方式且有配鞘工匠，地方需求明確。')],
    [('沙地帳篷外簾被風纏在支架。','先固定外簾，再裁掉已撕裂的部分。','需營地主同意，裁下布料不能當完整帳篷。'),('失蹤護衛留下帶匠印的刀鞘。','向乾井匠人求證製作者。','需旅行與詢問，不直接揭示護衛位置。')],
    ('steel_stock cloth leather','專門配鞘與刃口保養可能需返回產地。'),('scrap_iron leather','回收會失去匠印與工藝證據，須事先提示。'),
    'equipment combat_extension camping knowledge npc_relationship','LD-P01 WG-05')
add('spear','hunting_spear',2300,60,'common','polearm hunting long','combat explore survival trade','probe_shallow_ground hold_distance','new_hope hunting_parties','hunter_rack farm_guard_post',
    '桿身上綁著補強皮條，尖頭比桿子保存得更好。','長度提供距離，也使它難收進狹窄通道。','可拆換的矛頭與木桿；桿身裂痕不能靠磨利矛頭補救。','農獵社群看重可修桿身與熟悉操作，裝備需求不由價格階級決定。','60 Caps 提案適合普通護田器具；2300 g 不包含携行架。',
    [('high','high','獵人和護田隊熟悉長柄器具。'),('medium','low','廢墟狹窄，工人偏好短工具。'),('low','medium','商隊守夜偶有需求，長桿運輸不便。')],
    [('淺泥覆住小路上的坑洞。','站在安全邊緣試探前方近處地面。','只能探到桿長內，不能確認整段沼地安全。'),('野獸阻住通行而仍有退路。','以已裝備長矛保持距離後撤。','需未來戰鬥判定，無法保證嚇退；持矛不等於會使用。')],
    ('steel_stock leather','矛頭與綁束可評估修繕，木桿材料另待定義。'),('scrap_iron leather','只保留金屬頭與可用皮束，不產生完整替代矛。'),
    'equipment combat_extension exploration hazards','WG-01 LD-P01')
add('caravan_polearm','caravan_guard_polearm',2900,110,'uncommon','polearm caravan_hook long','combat explore trade','hold_cart_gap retrieve_dropped_bundle','caravan_guards route_workshops','guard_equipment_rack caravan_lost_property',
    '帶側鉤的長兵器，桿底磨出長年靠在車邊的凹痕。','此處的商隊槍是長柄兵器，不是槍械。','側鉤可勾近處固定物；桿和接頭未經起重認證。','圖、名稱與內容必須保持長兵器語義，不能誤導為需要彈藥的武器。','110 Caps 提案來自護車式樣及長柄運輸成本。',
    [('low','medium','糧車出發時會借用，平時需求低。'),('medium','medium','護車工坊能修頭部，完整長桿不常存放。'),('medium','high','燃料商隊需要熟悉護車器具的人手。')],
    [('小包落進貨車側面窄縫。','從可見位置勾回掛帶。','需卸車或停車，不能藉此打開未經同意的貨包。'),('兩車之間擠入受驚牲畜。','用長柄隔開人員，交由熟手處理。','不能保證控制動物，需協作與 hazards authority。')],
    ('steel_stock leather','先檢查接頭與鉤部，長桿更換另需材料來源。'),('scrap_iron leather','拆除武器後回收金屬與綁束。'),
    'equipment combat_extension cargo exploration hazards jobs','WG-01 FICTION-METRO')
add('hunting_fork','animal_control_fork',2700,80,'uncommon','fork hunting trapping','combat survival trade','hold_net_edge retrieve_trap','wilderness_hunters new_hope','trapper_camp hunting_shed',
    '叉齒間纏著獸毛與舊網線，柄上的刻痕記著一次次修補。','用於已有網具旁的控制作業；不是單靠叉子就能捕到獵物。','雙齒捕獸器具，彎曲齒端會增加滑脫風險。','捕獸提案需動物與採集規則，不將現有野狗直接改成可重複養殖資源。','80 Caps 提案反映專門用途而非較高戰力。',
    [('medium','medium','獵戶與護田工作有使用者。'),('low','low','城市廢墟內用途窄，收購多按金屬看待。'),('low','medium','商隊牲畜事故需要熟練者，器具供應稀少。')],
    [('棄置陷阱纏住路邊的網。','保持距離挑起可見網緣檢查。','需辨識陷阱，不保證已解除機構。'),('有主牲畜跌進矮溝。','固定鬆網邊緣協助原飼主救援。','需要網與其他人，不能把動物算成免費獎勵。')],
    ('steel_stock leather','齒端與桿部需熟手檢查，不能任意校直後宣稱安全。'),('scrap_iron','失去器具功能後回收叉頭。'),
    'equipment combat_extension exploration hazards npc_relationship','WG-01 WG-04')
add('stun_baton','powered_security_baton',950,260,'rare','electrical security powered','combat explore trade','inspect_contacts activate_indicator','old_world_security industrial_ruins','security_locker sealed_guard_room',
    '透明尾蓋裡的指示燈不再亮，握把保留舊警備編號。','需要相容電源才能確認是否工作，外殼完好不等於有效。','有絕緣握部的舊警備器材，電路狀態需要電子技術檢查。','不能由名稱保證非致命或自動麻痺；任何人體效果均待 combat_extension。','260 Caps 是可檢修器材的設計估值；無法證實工作的個體不保證此價。',
    [('none','low','缺少電子維護，需求限特定守衛或研究者。'),('low','medium','有能力檢修舊警備設備的工坊願意收。'),('none','low','電源補充不易，日常防衛不依賴它。')],
    [('警備器材箱有數支同款失效器具。','對比接點與編號，找出可送檢的一支。','耗檢查時間，不直接恢復電力或取得有效武器。'),('一名買家願意換取舊器材研究。','交出器具與觀察紀錄。','必須交付所有權，買家不保證能修好；價格另議。')],
    ('circuit_board copper_wire rubber','需相容電子零件與絕緣檢查，通電不代表安全可用。'),('copper_wire plastic','拆毁後只回收可分離材料，不保留可用放電模組。'),
    'equipment combat_extension electronics identification','WG-05 WG-03')
add('power_hammer','powered_industrial_hammer',11500,720,'rare','powered industrial heavy','explore combat trade','inspect_foundation_tool remove_worksite_obstruction','industrial_ruins gray_valley','demolition_store machinery_crate',
    '沉重機頭旁貼著起吊標記，舊電纜已被人截斷。','必須安排運輸、供電與熟手操作，徒手提走不代表能使用。','工業拆除器具；工作頭與驅動模組需分別確認，非一般手錘。','其吸引力是能完成特定工地工作，不能當成可隨身亂揮的終極武器。','720 Caps 提案是可修復工業資產估值，未含搬運與供電費用。',
    [('none','low','僅大工程會需要，日常農務負擔不起物流。'),('low','high','工業維修者能提供作業場所與運輸需求。'),('none','medium','燃料設施重修可能借用，通常以工作委託而非個人購買。')],
    [('坍塌泵房阻住既有檢修通道。','提出運入機具的工程方案。','先確認結構、供電與人員，不由持有物品直接拆通入口。'),('兩個聚落爭取同一件重型設備。','選擇送往哪個修復項目。','必須負擔搬運與契約代價，另一個項目仍未解決。')],
    ('gear bearing precision_parts copper_wire','只有設備齊全工坊能檢修；相容驅動及電源尚未定義。'),('steel_stock copper_wire','拆作材料會永久放棄整機用途，產率另定。'),
    'equipment combat_extension electronics exploration cargo jobs hazards','WG-03 WG-04')

def firearm(key, weight, value, rarity, subtype, desc, known, identified, note, value_reason,
            markets, hooks, actions, repair_inputs, salvage_outputs, origins, loot):
    add(key, subtype, weight, value, rarity, 'firearm unloaded ' + subtype, 'combat trade explore',
        actions, origins, loot, desc, known,
        identified + ' 所需彈藥的具體規格、供應與使用規則尚待設計，物品本身不含彈藥。',
        note, value_reason + ' 重量按空槍提案，價格不是現有商店報價。', markets, hooks,
        (repair_inputs, '提案僅為相容零件關係；須合格工坊檢查，不提供製造步驟或保證復原。'),
        (salvage_outputs, '拆解會失去完整槍械；只提議材料去向，無數量或可回收彈藥承諾。'),
        'equipment combat_extension exploration identification knowledge jobs', 'WG-05 WG-02 LD-P01')

firearm('old_revolver',1050,210,'uncommon','revolver',
    '磨亮的握柄與暗啞機件不太相稱，像是換過幾任主人。','外露結構較便於檢視，仍需工匠確認磨耗。','老式轉輪槍，年份不構成可靠性保證。','它的存在理由是常見維修經驗，並非自帶無故障特性。','210 Caps 對應可檢查的普通舊槍。',
    [('low','medium','獵戶與村落守衛熟悉舊式器材。'),('medium','medium','舊槍流通與維修工坊相對集中。'),('medium','high','護衛旅途中需要能找到維修者的型式。')],
    [('商隊招募臨時守夜者。','出示已確認可用且由自己持有的器材參加評估。','需另備相容彈藥與正式護衛資格；不能僅持槍領取報酬。'),('孤屋留下模糊的舊槍編號。','請工匠比對流通記錄。','耗詢問與檢查時間，記錄可能只指向前一位商人。')],
    'inspect_mechanism present_guard_gear','spring steel_stock leather','scrap_iron leather','caravan_routes old_households','locked_household_chest guard_personal_storage')
firearm('civilian_pistol',780,240,'uncommon','civilian_sidearm',
    '扁平槍身帶著家用保管盒留下的磨痕。','較便於攜帶，零件相容性不能只靠外形判斷。','民用短槍，保險與供彈部件需要逐件檢查。','適合輕裝護送的提案；不讓小體積等同於無代價隱藏武器。','240 Caps 反映完整機件與較低攜行負擔。',
    [('low','medium','短程貨主需要護衛，但不易自行維修。'),('medium','medium','舊住宅和回收商是主要來源。'),('low','medium','外來型式多，買家先確認可維修性。')],
    [('旅店要求客人寄存武器。','主動交由保管人登記存放。','需交出使用權直到領回；不自動換取信任獎勵。'),('回收商混裝了一箱手槍零件。','以完整樣品核對可送檢的相容部件。','需工匠與所有權許可，不當場拼出第二把槍。')],
    'register_storage compare_parts','spring precision_parts','scrap_iron plastic','old_world_homes salvage_merchants','house_safe confiscated_property_store')
firearm('police_pistol',880,310,'uncommon','service_sidearm',
    '槍柄底部還留著公物號碼，配套槍套已遺失。','來源編號可能可追查，卻不授予執法身分。','舊制式短槍；公物印記與機械可用程度分開判斷。','價值一部分是可辨識的型號與維護記錄，不是自動較準。','310 Caps 假設保存了可查的型號資料。',
    [('none','medium','守望隊有需求但不在本地生產。'),('low','high','舊警備倉與修理者可能提供配套資料。'),('low','medium','只對能取得相容補給的護衛有吸引力。')],
    [('失蹤守衛的家人尋找公物清單。','交付槍上編號供比對。','只提供線索，不能直接證明持有人死亡或犯罪。'),('聚落委託保管收繳器材。','將此槍列入可追溯交接。','需歸還原持有方或取得處分同意，不能一物兩賣。')],
    'trace_inventory_number transfer_custody','spring precision_parts','scrap_iron plastic','old_world_police civic_security','police_property_locker evidence_room')
firearm('improvised_pistol',1250,90,'common','workshop_sidearm',
    '不同顏色的零件拼在一起，工坊記號比型號醒目。','便宜但必須先檢驗；看似可扣動不代表適合使用。','地方拼裝短槍，個體間零件未必互通。','灰谷可找得到原工匠，是它相對於陌生制式槍的服務優勢。','90 Caps 提案扣除了檢驗與不確定性成本。',
    [('low','low','農戶不願為廉價器材承擔未知安全風險。'),('high','medium','本地工坊提供來源與售後線索。'),('low','low','無法找到製作者時收購意願低。')],
    [('便宜護衛裝備引發貨主疑慮。','請原工坊提供檢查與責任說明。','付出檢查時間與費用；檢查不保證護衛任務獲准。'),('工匠希望收回問題批次。','依記號將器材交回。','放棄使用或出售機會，補償先另行協商。')],
    'request_workshop_inspection return_batch','steel_stock spring','scrap_iron','gray_valley local_workshops','workshop_return_shelf barter_stall')
firearm('snub_revolver',720,250,'uncommon','compact_revolver',
    '短小的外形藏在已磨軟的皮袋裡。','便於減輕行李；短小不代表在所有距離都同樣適用。','短管轉輪槍，需要專門檢查握持和機件磨耗。','為短程出行保留輕裝選擇，不授予免費潛行或先手。','250 Caps 提案包含輕便需求而非單純傷害提升。',
    [('low','low','農務更重視通用長工具與獵具。'),('low','medium','短程信使與商人有攜行需求。'),('medium','medium','商隊人員偏好便攜備用器材，但仍需補給。')],
    [('信使出發前必須刪減行李。','在有正式裝備規則後選擇較輕的自衛器材。','仍占實際負重與裝備位，不增加攜帶容量。'),('守門人要求逐件申報小型武器。','申報並接受寄存。','不能靠造型避開檢查；寄存後暫時無法使用。')],
    'prepare_light_load declare_sidearm','spring leather','scrap_iron leather','caravan_traders old_households','traveller_lockbox guard_storage')
firearm('heavy_revolver',1650,390,'rare','large_frame_revolver',
    '厚重槍框壓得舊槍袋歪向一邊。','重量與操控負擔明顯，補給不如普通舊槍容易。','大型轉輪槍，需專門匹配彈藥與維修部件。','乾井少數護衛使用的重器材；並非每位新人都值得攜帶。','390 Caps 為小量流通與工坊支援的提案估值。',
    [('none','low','普通獵務不願負擔稀少補給。'),('low','medium','專門槍匠有研究與維修需求。'),('low','high','特定長線護衛團能支援其補給。')],
    [('護衛團只接受已檢驗的重器材。','委託乾井熟手核對裝備需求。','需時間與費用；不得用 FIREARMS rank 代替實物與彈藥。'),('旅人決定換回更輕的裝備。','與有需求的守衛談交換。','對方需真的持有可換物，不生成平價等值替代槍。')],
    'verify_guard_loadout negotiate_exchange','steel_stock spring precision_parts','scrap_iron','dry_well veteran_guards','specialist_guard_locker caravan_barter_chest')
firearm('machine_pistol',1450,470,'rare','automatic_sidearm',
    '額外的握持配件與短槍身擠在同一只盒內。','耗用補給的方式不同於普通手槍；缺少配件時更難管理。','舊自動短槍，射擊方式與安全操作需未來戰鬥系統定義。','不靠「自動」二字保證優勢；維修、彈藥和使用者經驗都限制去向。','470 Caps 提案來自罕見機件，未包含任何額外彈藥。',
    [('none','low','維護與補給能力不足，只有委託回收需求。'),('low','medium','電子與機械回收者會評估部件價值。'),('low','medium','只有準備充足的護衛隊願意負擔。')],
    [('舊守衛庫提供器材但沒有補給。','先記錄型號，再尋找可支援的工坊。','取得物品不代表獲得可射擊的裝備。'),('買家把外形相似的零件當成通用。','拒絕保證相容，送交專業檢驗。','需檢驗時間；不得把兩件不合零件變成有效新武器。')],
    'catalogue_weapon_type request_compatibility_check','spring precision_parts','scrap_iron plastic','old_world_security military_depots','sealed_security_crate armoury_shelf')
firearm('old_smg',3100,560,'rare','legacy_smg',
    '長期封存的槍身有一道油布壓痕，肩托鎖扣仍待檢查。','攜帶體積較大，需要成套維護而非只清掉表面灰塵。','舊世衝鋒槍；缺件、彈藥與操作方式須各自確認。','遺跡保存狀態決定用途，不把舊世出身當作天然高級。','560 Caps 假設主要部件齊全，仍不保證立即可用。',
    [('none','low','保管和後勤超出多數農戶需要。'),('low','high','工坊與有組織守衛可能收購可檢修器材。'),('low','medium','護運需要，但外地部件是限制。')],
    [('軍警遺跡的器材清單缺頁。','以槍身刻記補做物證記錄。','需保留原物供核驗；拆解會失去完整證據。'),('工坊要一支樣品判斷能否支援商隊。','借出器材進行非實戰檢查。','暫時失去使用權，研究結果可能是不值得修。')],
    'document_storage_record lend_for_inspection','spring precision_parts steel_stock','scrap_iron plastic','military_ruins security_depots','armoury_crate depot_rack')
firearm('caravan_smg',2800,520,'rare','caravan_smg',
    '背帶反覆補過，槍托記著一支商隊的交接記號。','適合已有後勤的護運隊，帶出補給網後價值會降低。','商隊維修過的短自動槍，替換件清單比外觀新舊更重要。','定位是有可追溯維護的護車器材，不是全世界通用上位槍。','520 Caps 提案包含交接資料完整時的維護價值。',
    [('low','medium','糧車護送可借用，但主要供應在商隊。'),('low','high','護車工坊需匹配零件，來源多為退役交接。'),('medium','high','燃料長線有持續維護與備件需求。')],
    [('退役護衛交出裝備與缺頁保養簿。','補查商隊交接紀錄後決定收購。','需聯絡原商隊，不保證其願意認領責任。'),('商隊中途缺一件已核驗護運器材。','在契約中借出而非無條件捐贈。','需記錄歸還條件，借出期間不能自己使用。')],
    'audit_service_record lend_guard_equipment','spring precision_parts leather','scrap_iron leather','caravan_workshops dry_well_routes','retired_guard_locker caravan_gear_case')
firearm('single_shot_rifle',2750,160,'common','single_shot_hunting_rifle',
    '木托磨出掌形凹陷，沒有多餘裝飾。','結構用途單純，適合懂得辨識獵場的人，而非保證命中。','單發獵用長槍，裝填節奏需要後續戰鬥規則呈現。','低成本獵務工具可支撐普通工作，不能以採集按鈕無限生肉。','160 Caps 提案保留新人可追求的完整器材。',
    [('high','high','農獵生活常見，當地有維護經驗。'),('medium','low','狹窄廢墟限制長槍用途。'),('low','medium','沿途獵務可能需要，但補給受路線限制。')],
    [('農戶尋人查明夜間損壞圍欄的動物。','先觀察足跡，攜已裝備獵槍作後備。','武器不取代追蹤知識，無目標不得直接獲得獵物。'),('長槍原主留下維修記號。','拜訪當地槍匠尋找持有人線索。','需詢問與對方同意，不從記號推定死因。')],
    'prepare_hunt trace_repair_mark','spring steel_stock leather','scrap_iron','new_hope hunters','hunting_cabin farm_guard_store')
firearm('bolt_action_rifle',3600,285,'uncommon','bolt_action_rifle',
    '槍身比肩帶整潔，金屬柄保留長年操作的亮痕。','長度和重量需行程規劃，熟悉動作比外觀更重要。','栓動式長槍，部件相容性與槍況需專業鑑定。','荒野熟手的耐用選擇，不承諾固定射程或精度增益。','285 Caps 提案反映廣泛維護知識與較完整槍況。',
    [('medium','high','獵人有用途且能找到保養者。'),('low','medium','護衛會找保存良好的長槍。'),('medium','medium','長途使用者重視可查驗器材與補給。')],
    [('獵戶不願讓陌生人帶不明槍況出發。','先接受他的裝備檢查與路線說明。','付出準備時間，仍須獵戶同意同行。'),('商隊把完好長槍列入貨物而非公用武器。','選擇押運交付或另談合法收購。','不能在運送期間擅自裝備委託物。')],
    'request_hunter_inspection transport_owned_cargo','spring precision_parts leather','scrap_iron leather','wilderness_hunters caravan_trade','hunter_lockbox caravan_weapons_case')
firearm('caravan_rifle',3400,335,'uncommon','caravan_service_rifle',
    '槍托刻著多次點收的方格，最近一格還沒有簽記。','價值在於可追溯交接與沿線支援，而非陌生的高規格。','護運用長槍，配件清單能幫助確認缺件。','商隊制式化是服務網的設計方向，不替所有聚落創造庫存。','335 Caps 提案把可追蹤的維修支持算入成品價值。',
    [('low','medium','糧運期間有需求，農閒供應仍依商隊。'),('medium','high','路線維修工坊會保有相容備件。'),('medium','high','長線護運比零星家用更需要統一支援。')],
    [('護衛換班時少了一筆器材簽收。','以交接刻記查明最後接手隊伍。','需比對文件，持槍人不能直接被判有罪。'),('遠行前只能選一條有維修支持的路線。','依服務據點安排行程。','可能繞遠，不能保證工坊當天有零件。')],
    'audit_handover plan_service_route','spring precision_parts leather','scrap_iron leather','caravan_guard_network gray_valley','guard_depot caravan_equipment_rack')
firearm('semi_auto_rifle',3700,470,'rare','semi_auto_rifle',
    '金屬表面尚好，保養盒卻只剩一張失色的零件圖。','供彈與動作部件更需要相容支援，不能靠少量廢鐵任意補齊。','半自動長槍，失去零件圖會增加檢修難度。','有準備才值得帶，讓普通可修長槍仍有位置。','470 Caps 提案反映完整機構與較稀少維修資源。',
    [('none','low','一般獵務難維持此類支援。'),('low','high','專門工坊可評估零件圖與整機用途。'),('low','medium','有後勤的護運隊願意收，零散旅人未必。')],
    [('遺跡發現只剩部分內容的零件圖。','與本體對照找出需送檢的部位。','需要知識與時間，圖紙不是自動修理配方。'),('買家只收能確認來源的舊槍。','提供保养盒與所有權記錄。','缺證時可以拒買，不用殺價判定抹去來源問題。')],
    'compare_parts_diagram document_provenance','spring precision_parts steel_stock','scrap_iron aluminum_stock','old_world_stores military_surplus','sealed_rifle_case maintenance_cage')
firearm('assault_rifle',3650,650,'rare','military_rifle',
    '舊軍方驗收章已模糊，箱內空位暗示配件並不完整。','使用與補給門檻高，遺跡出土不代表仍保持規格。','軍用長槍，需專用檢驗及相容彈藥體系。','軍事出身提供調查與後勤故事，不自動決定最高傷害。','650 Caps 是完整主要機件的未平衡估值。',
    [('none','low','地方農業需求與維護資源皆有限。'),('low','medium','軍械研究者或組織化守衛才可能出價。'),('low','medium','長線護運需要先解決相容補給。')],
    [('聚落要求軍事器材入城前封存。','接受登記封存以進行交涉。','暫時放棄裝備使用，不得把持槍直接變成社交通行權。'),('軍事倉庫的批號與一份運輸單相符。','保留原物供調查運輸去向。','放棄立即拆售機會，調查不保證更多軍械獎勵。')],
    'seal_for_entry trace_batch','precision_parts spring steel_stock','scrap_iron aluminum_stock','military_depots old_world_bases','sealed_armoury_crate convoy_lockbox')
firearm('scrap_rifle',4100,220,'uncommon','workshop_rifle',
    '木托、金屬罩與背帶明顯來自不同年代。','較重但原工坊可能就在灰谷，來源可追查。','地方修配長槍，每把的相容部件須個別建檔。','可接近的維修者是優點，跨區缺乏相容資料是代價。','220 Caps 提案扣除重量與個體差异造成的後勤負擔。',
    [('low','medium','農戶可透過灰谷委託維修，往返時間是成本。'),('high','medium','本地修配工坊有售後意願。'),('low','low','遠離製作者時難以保證維修，買家謹慎。')],
    [('原工坊願意替自家器材做巡迴保養。','用製作記號預約檢查。','等候實際工匠，不自動減少世界中的修理成本。'),('長途護送考慮更換笨重裝備。','衡量留用的維護便利與攜重。','更換必須有實際買家和替代物，不能按一下升級。')],
    'register_workshop_service evaluate_load','steel_stock spring leather','scrap_iron leather','gray_valley salvage_workshops','local_gunsmith_rack repair_return_crate')
firearm('sandstorm_rifle',3900,430,'uncommon','desert_service_rifle',
    '槍罩繫著多層防砂布，背帶採乾井常用的縫法。','防砂處理降低維護負擔的構想仍需規則，不能免疫沙塵。','為地方環境修配的長槍，覆布和接合處需定期檢查。','地域適應來自保養與供應網，而非武器名字本身帶 buff。','430 Caps 提案包含地方修配與防砂配套。',
    [('none','low','農業路線不常需要額外防砂配套。'),('low','medium','替乾井商隊服務的工坊有需求。'),('medium','high','當地有維護經驗與相容配件來源。')],
    [('沙塵季出發前護衛隊檢查所有器材。','請熟悉乾井工藝者確認覆布與接合。','耗準備時間，不能保證风暴中射擊無風險。'),('路上拾到有當地縫線的防砂套。','交給乾井維修者核對可能的商隊。','僅形成線索，不直接取得槍械或定位持有人。')],
    'inspect_dust_cover trace_regional_work','cloth rubber spring','scrap_iron cloth','dry_well desert_workshops','desert_guard_rack caravan_repair_case')
firearm('sniper_rifle',5200,980,'rare','precision_rifle',
    '長盒內的軟墊已壓扁，鏡架上有精細的檢查刻線。','重且怕碰撞，觀察配件與武器操作不能混成一個萬能按鈕。','精密長槍及其配套需要專業檢驗，鏡片清楚不代表整機準確。','屬少量有後勤支持的特殊器材，不作每張地圖都能撿到的高級掉落。','980 Caps 提案反映少見完整配套，物流與檢驗費另計。',
    [('none','low','農戶難以維護，可能只接受替專人轉運。'),('low','medium','精密工坊或特定委託人有需求。'),('none','medium','特定遠行隊有需求，絕非常備市場貨。')],
    [('精密器材委託要求原盒交付。','把長盒當有主貨物護送。','占負重與搬運空間，不能擅自拆盒試用。'),('未知鏡架有一組維修編號。','找光學技師辨識配套來源。','支付檢驗代價，不因辨識成功直接提高角色命中。')],
    'protect_precision_cargo identify_optics','precision_parts glass steel_stock','scrap_iron glass','military_specialists sealed_depots','precision_equipment_case specialist_lockroom')
firearm('old_hunter_rifle',3500,None,'unique','named_hunting_rifle',
    '木托留下多年補縫，一小片刻字說明它曾屬於同一個獵人。','不尋常的是持有人歷史，未必比普通獵槍更有威力。','特定獵人的私人物品；維修痕與刻字可和他留下的記錄比對。','此人與後續關係皆為設計候選，必須綁定既有人口，不臨時生成人。','沒有通用估價；家人、原同伴與收藏者各有不同目的。',
    [('none','high','只有與原獵人有關的人可能急於尋回，不代表常態大量需求。'),('none','low','一般廢料商不應為無法確認的故事付高價。'),('none','low','特定商隊可能保有舊交接線索，沒有例行庫存。')],
    [('一名農人認出木托上的補縫。','讓他描述舊主並核對其他證據。','需對方願意談，不因認物就確認親屬或贈送報酬。'),('收藏者想磨掉刻字翻新。','選擇保留原貌或交出處分權。','翻新會失去部分歷史證據，沒有固定最佳售價。')],
    'verify_personal_history preserve_inscription','leather spring','scrap_iron','named_hunter_history new_hope_routes','personal_bequest hidden_hunting_cabin')
firearm('single_shot_shotgun',2950,185,'common','single_barrel_shotgun',
    '簡單的木托被油布包著，農舍門框上有相同磨痕。','常見於鄉間守護器材，仍受單次裝填和補給限制。','單管散彈槍，槍況必須檢驗，不能因結構簡單免維護。','普通護田任務的器材候選，不把散彈當對所有目標都有效。','185 Caps 提案維持可取得性並保留檢驗成本。',
    [('medium','high','農舍與護田人員有具體需求。'),('medium','medium','回收商能找到舊民用器材。'),('low','medium','短程看守需求存在，補給須另核實。')],
    [('糧倉主想請人守住搬運區。','帶已核驗裝備接受工作說明。','需明確守則與彈藥來源；不能只用槍械圖片領任務。'),('農舍保管箱的主人已搬離。','先查明所有權再處理箱中槍械。','耗查訪時間，不能因空屋就默認無主。')],
    'prepare_store_watch verify_ownership','spring steel_stock','scrap_iron','new_hope households','farm_safe village_watch_cabinet')
firearm('double_barrel_shotgun',3350,300,'uncommon','double_barrel_shotgun',
    '兩根槍管的色澤略有不同，皮製背帶修了又修。','成對機件增加檢查需求，不能僅靠外觀看成兩倍能力。','雙管民用槍，需要確認兩側狀態與相容補給。','偏重的鄉間器材可具有家族傳承意義，不必永遠是上一型的傷害升級。','300 Caps 提案考慮完整配對與較高保養負擔。',
    [('medium','medium','獵戶認識型式，但會逐把檢查。'),('low','medium','工坊收購可檢修成對機件。'),('low','low','長途重量與補給使需求受限。')],
    [('兩兄弟對祖輩器材的處置意見不同。','先封存原物，協助釐清交接意願。','需双方同意，不能把一件完整物品自動分成兩把。'),('槍匠指出兩側保養記錄不一致。','選擇送檢而非立刻出售。','花時間且可能發現整機不值得修。')],
    'mediate_custody compare_service_history','spring steel_stock leather','scrap_iron leather','rural_households hunting_lodges','family_lockbox hunting_camp_storage')
firearm('pump_shotgun',3450,420,'rare','pump_action_shotgun',
    '滑動握部積著舊油，背帶曾換成工業織帶。','動作部件需要清理與檢查，不能靠名稱保證連續使用。','泵動式散彈槍，供彈與動作配合需由後續 combat authority 定義。','定位為有維護條件的看守裝備，遠地缺件時未必優於簡單器材。','420 Caps 提案來自較少見的完整機構。',
    [('low','medium','固定糧倉守衛能安排維護，但普通農戶較少買。'),('low','high','工業警備遺留與專門工坊可能配套。'),('low','medium','儲運場有需求，但零件依赖外來。')],
    [('固定倉庫尋求長期器材維護。','將樣品與工坊服務連成委託。','需持續後勤，不是交槍後永久提高治安。'),('器材失靈導致護衛拒絕出發。','安排專業檢查並重新協商行程。','路程可能延誤，不可用一個 MECHANICS 門檻直接修好。')],
    'arrange_maintenance delay_for_inspection','spring precision_parts','scrap_iron plastic','industrial_security old_world_police','security_equipment_cage warehouse_guard_store')
firearm('industrial_nailgun',3100,205,'uncommon','industrial_fastener_tool',
    '黃色外殼褪成土色，工班用紅線圈出一處舊裂痕。','原為緊固工具，需要匹配能源與耗材；不是自由彈藥武器。','工業釘具的工作頭和能源接口都須檢驗。','以工程需求為主要流通理由，是否可作戰留到 combat_extension。','205 Caps 提案反映可檢修工具；能源與釘料成本另列。',
    [('low','medium','修繕棚舍有需求，但能源限制採用。'),('medium','high','工坊可識別配套工具並提供檢修。'),('low','medium','貨箱修繕需要，但必須先運入相容耗材。')],
    [('貨箱工坊趕修破損包裝。','確認匹配耗材後承接緊固工作。','需作業權與工坊條件，不直接從持有釘槍生成箱子。'),('遺跡出土一批同型工具。','挑選可送檢樣本交給工班。','樣本需移交；不能把工具全當可射擊武器出售。')],
    'inspect_fastener_system perform_workshop_job','spring precision_parts rubber','scrap_iron plastic','gray_valley construction_sites','contractor_toolbox factory_store')
firearm('flare_pistol',620,145,'uncommon','signal_launcher',
    '橙色外殼上有一條已褪色的海事標記。','用於發出信號的構想，需要專用信號耗材；不能當免費照明。','單次信號發射器，信號種類與接收約定尚待建立。','重點是被誰看見及暴露位置的代價，不附帶固定救援保證。','145 Caps 提案反映罕見專用用途，不含任何信號彈。',
    [('low','medium','遠郊農場希望有求援方式，但需要約定。'),('low','low','密集建築遮擋視線，無線電可能更合適。'),('medium','high','荒漠長線商隊需要可見的失散信號。')],
    [('商隊在分岔地約好失散標記。','先協商何種情況才發信號。','耗材規格和信號規則未定義前不能使用；發射會暴露所在區域。'),('高處看見陌生求援光。','保留信號器，先確認是否有對應接收者。','觀察需時間，不保證遠方訊號可信或有人回應。')],
    'agree_signal_protocol observe_signal','spring steel_stock','scrap_iron plastic','old_world_maritime desert_caravans','rescue_kit signal_store')
firearm('grenade_launcher',5800,1100,'rare','restricted_launcher',
    '厚重外殼仍有封存標記，配套箱卻空著。','缺少特定彈藥與受控保管條件，帶走也不能立即使用。','軍用發射器，檢驗、彈藥與範圍後果都缺正式規則。','不設計製造、改裝或爆炸參數；其內容可圍繞保管與交付抉擇。','1100 Caps 僅是完整無彈器材的設計估值。',
    [('none','none','農業聚落無一般使用者或正常收購需求。'),('none','low','少數受託保管者或研究工坊可能介入。'),('none','low','只有具體委託會尋求，不列日常商店供貨。')],
    [('倉庫管理者發現不應混進民用貨箱的器材。','協助封存並追查交接文件。','不得擅自試用；移交要記錄所有權與責任。'),('陌生買家拒絕說明用途。','選擇保留封存或拒絕交易。','占據運輸與保管資源，沒有拒售的必然正面獎勵。')],
    'seal_sensitive_equipment audit_delivery','precision_parts steel_stock','scrap_iron','military_storage restricted_convoys','sealed_military_case impounded_cargo')
firearm('light_machine_gun',8400,1250,'rare','support_weapon',
    '長箱內還有專用架的空位，器材重得不像私人行李。','需要隊伍後勤、匹配補給與運輸，個人能背不等於適合帶。','支援型槍械，缺失配套需先確認。','作為聚落或商隊資產形成去向抉擇，不是到手即橫掃的獎勵。','1250 Caps 提案反映稀少完整機件，保管與長程運輸另付成本。',
    [('none','low','僅特定防衛委託可能需要，無一般採購量。'),('low','medium','大工坊能安排檢驗與重物搬運。'),('none','medium','護運組織考慮整套後勤才會接受。')],
    [('兩支護運隊都想取得唯一的支援器材。','要求雙方提出保管與補給方案再決定。','必須將所有權交給一方，不能兩隊同時受益。'),('廢軍庫的重箱擋住人員撤出。','選擇放棄搬運並記錄位置。','失去即時占有，後續回收需獨立運輸計畫。')],
    'evaluate_logistics record_recovery_site','spring precision_parts steel_stock','scrap_iron steel_stock','military_depots retired_convoys','heavy_armoury_case convoy_support_store')
firearm('flamethrower',13800,850,'rare','fuel_projection_equipment',
    '沉重背架上的警告標記比器材本身更清楚。','燃料系統與密封狀態都未知，不可因有燃料就當成可用。','危險舊裝備，須專門保管與檢查；不提供操作或製作參數。','內容重心是危險資產的去處和運輸責任，並非普通探索清障萬能解。','850 Caps 是無燃料器材的未採用估值，安全隔離可能比收購更昂貴。',
    [('none','none','農地與糧倉不需要此類普通貨物。'),('none','low','只有受託拆解或保管機構可能處理。'),('none','low','燃料產地不代表願意接受危險器材。')],
    [('回收商想把不明背架混入一般燃料貨物。','要求分隔保管並查明來源。','增加運輸成本，不可用燃料標籤跳過危險物管理。'),('廢工廠保管人要求移走封存器材。','協商交由專業拆解者處理。','需實際接收者與運輸能力，不直接拆成可售燃料。')],
    'isolate_hazardous_cargo arrange_specialist_handover','rubber steel_stock precision_parts','scrap_iron','restricted_old_world_sites military_storage','isolated_equipment_room sealed_hazard_case')

def wear(key, subtype, weight, value, rarity, tags, roles, actions, origins, loot,
         desc, known, identified, note, rationale, markets, hooks, inputs, outputs, deps, refs):
    add(key, subtype, weight, value, rarity, tags, roles, actions, origins, loot,
        desc, known, identified, note, rationale, markets, hooks,
        (inputs, '需先辨識破損部位與相容材料；補外觀不能保證恢復原防護能力。'),
        (outputs, '拆作材料會失去完整裝備；污染、材料狀態與回收量仍須規則決定。'),
        deps, refs)

wear('work_clothes','workwear',1200,28,'common','cloth workwear pockets','survival trade explore','wear_workwear inspect_name_patch','gray_valley settlements','worker_locker secondhand_clothing_stall',
    '袖口補丁壓著補丁，胸前名牌只剩一個姓。','普通衣物可以遮蔽身體，不能據此宣稱防彈或防污染。','耐磨布料工作服；衣袋和接縫完整度應分別檢查。','工作服在工人之間流通，名牌只是來源線索，不賦予職業權限。','28 Caps 提案反映二手布衣；1200 g 沿用 ITEM-1。',
    [('medium','medium','農務可穿，但較輕衣物也有用途。'),('high','high','工班更換頻繁，二手供應與日常需求並存。'),('medium','low','厚布在乾熱路線有負擔，固定工地仍會使用。')],
    [('失物堆出現有名字的工作服。','先尋找名牌可能對應的工班。','需查訪，不直接由衣物認定原主的命運。'),('工班願意借用合身衣物給臨時搬運者。','交出衣物作短期借用。','借出期間不能穿用，歸還與清洗條件先約定。')],
    'cloth','cloth','equipment exploration jobs npc_relationship','WG-02 FICTION-ROAD')
wear('farm_clothes','agricultural_workwear',1050,35,'common','cloth farming washable','survival trade explore','change_for_fieldwork dry_field_clothes','new_hope farms','farmhouse_clothesline agricultural_store',
    '褲腳留著灌溉渠的淤泥色，肩背多縫了一層布。','方便農務換洗，濕透後仍需晾乾。','較輕的農務服，補強處偏向肩背搬運磨耗。','看見農服不等於居民會將外來者當成本地人。','35 Caps 提案重視完整尺寸與換洗便利。',
    [('high','high','灌溉與收成工作需要日常替換。'),('medium','low','可作輕便工作衣，但工坊需要更耐磨材料。'),('low','medium','補給農田的外來短工可能收購。')],
    [('灌溉維修後參與者衣服全濕。','提供乾燥農服作替換。','需要合身與接收者同意，不能直接清除疾病或傷害。'),('農戶希望辨認被順手帶走的衣物。','讓他核對獨特補強縫線。','核對不是定罪，需其他所有權證據。')],
    'cloth','cloth','equipment hazards jobs npc_relationship','LD-P02 FICTION-ROAD')
wear('desert_robe','desert_wrap',900,55,'common','cloth desert loose_layers','survival trade explore','wrap_against_dust shade_supplies','dry_well desert_households','desert_clothing_stall caravan_spare_bundle',
    '寬鬆布層在腰間束起，褪色邊緣補著另一種織法。','能作穿著與遮蔭布使用；防砂效果要等環境規則。','乾井式長袍，布層仍透氣，不等同密封防護裝備。','它應與面罩、休息和路線選擇配合，不能單件取消風暴。','55 Caps 為地方常用服飾提案；900 g 沿用 ITEM-1。',
    [('low','low','潮濕農務環境不特別需要長袍。'),('medium','medium','前往乾井的旅客會在中轉地備貨。'),('high','high','本地製作與日常替換都存在。')],
    [('停車等候時一箱食物暴露在日照下。','暫時脫下長袍替貨物遮蔭。','自己失去穿著用途，布不能當冷藏或永久保存。'),('沙塵迫使旅人重新安排衣物包覆。','以已有長袍遮住外層行李。','占用衣物且仍可能需停行；不增加背包容量。')],
    'cloth','cloth','equipment hazards cargo camping','LD-P01 FICTION-ROAD')
wear('caravan_coat','travel_coat',1500,85,'uncommon','coat caravan reinforced','survival trade explore','wear_travel_coat inspect_route_patch','caravan_tailors route_settlements','caravan_lost_property travelling_tailor',
    '肩頭的舊路線章被拆掉，只留下較淺的一圈布色。','外套適合反覆旅行，並不代替正式的商隊契約。','補強肩背和大口袋是攜行便利，不等同額外負重容量。','沿線裁縫認得縫法，可以形成維修和尋人故事。','85 Caps 為有補強的旅行服提案；1500 g 沿用 ITEM-1。',
    [('medium','medium','糧運工作者會購買，農戶平時較少穿。'),('medium','high','中轉維修與二手交易活躍。'),('medium','high','長線商隊需要可修補的外套。')],
    [('一位裁縫認出外套已拆的路線章位置。','詢問該路線曾在哪裡換班。','得到的是待查線索，不直接開啟新路線。'),('夜間等候的人沒有遮蔽物。','借外套給對方披著等待。','自己暫時失去穿著，後續防寒效果待 hazards。')],
    'cloth leather','cloth leather','equipment knowledge npc_relationship hazards','FICTION-ROAD FICTION-METRO')
wear('worker_leather_jacket','industrial_leatherwear',2300,120,'uncommon','leather workwear industrial','survival trade explore','wear_for_work identify_workshop_patch','gray_valley leather_workers','factory_change_room leatherworker_stall',
    '皮面布滿細小擦痕，肩線仍紮實。','耐磨厚皮衣較重，不能宣稱能擋任何工業危險。','補強皮革工作衣，熱源、切割與化學防護需分別判定。','工人皮衣與輕甲有重疊外觀，但裝備分類不能偷帶護甲公式。','120 Caps 提案反映皮革用料與維修便利。',
    [('low','medium','畜務與粗搬運有需要，輕農務較少使用。'),('high','high','工業工作最常見，當地能修縫。'),('low','medium','油料搬運者可能需求，悶熱是代價。')],
    [('廢工班留下有特定補丁的皮衣。','以補丁縫法查詢原工作站。','耗查訪時間，不自動得到員工身分。'),('搬運隊要求自備耐磨衣物。','提交已持有皮衣供領班檢視。','領班仍需確認工作安全，衣物不保證免傷。')],
    'leather cloth','leather','equipment hazards jobs knowledge','WG-02 WG-05')
wear('motorcycle_jacket','reinforced_riding_jacket',2600,150,'uncommon','leather riding reinforced','survival combat trade','wear_riding_layers preserve_emblem','old_world_motorists road_salvagers','vehicle_seat_locker roadside_store',
    '背部舊徽記已有裂紋，拉鍊卻被新換過。','厚重皮層方便長途穿著，但重量與熱負擔需考慮。','騎行式補強皮衣；舊徽章只表示歷史，不證明現今組織關係。','可成為私人風格與來源話題，不讓外套自動威嚇所有 NPC。','150 Caps 提案包含完整拉鍊和厚皮料，收藏意願另看個人。',
    [('low','low','農務使用不便，少數旅人有興趣。'),('medium','medium','廢車回收可能取得，皮革匠能修。'),('low','medium','長線駕駛與護運者看重耐用穿著。')],
    [('道路老人認出夾克上的褪色圖案。','請他說明曾在哪個中轉站見過。','談話需信任，徽記不能替玩家取得舊組織通行權。'),('裁縫建議拆掉破損徽記換皮。','選擇保留歷史或改善衣物完整性。','修補可能永久失去原圖案。')],
    'leather cloth','leather','equipment combat_extension hazards knowledge npc_relationship','LD-P01 FICTION-CANTICLE')
wear('stab_vest','stab_resistant_vest',2100,230,'uncommon','vest layered_protection fitted','combat survival trade','fit_protective_vest inspect_layers','security_contractors old_world_civic','guard_locker security_store',
    '分層內襯藏在普通背心裡，側帶有不同主人的調整痕。','需要合身與完整內襯；名稱不是免傷保證。','防刺設計背心，不能當成防彈衣或化學防護。','以特定威脅下的準備作為定位，效果與傷害權限後續再定。','230 Caps 假設內襯可驗證且側帶完整。',
    [('none','medium','近身護送工作有需求，但無在地製造。'),('low','high','倉庫守衛與器材檢驗者需要。'),('low','medium','商隊保護有需求，合身尺碼限制交易。')],
    [('護衛隊要求檢查每個人的防護尺寸。','調整已有背心並接受檢視。','需時間與合適尺碼，不提升未定義的數值。'),('二手商把破損內襯藏在完整外衣下。','先拆開檢驗再決定是否購買。','需賣方允許，檢驗不是免費得知全部歷史。')],
    'cloth precision_parts','cloth','equipment combat_extension identification hazards','WG-04 WG-05')
wear('police_ballistic_vest','ballistic_vest',4200,460,'rare','vest ballistic_old fitted','combat survival trade','inspect_protective_panels register_guard_gear','old_world_police guarded_depots','police_locker sealed_protection_case',
    '防護板插袋仍在，封存日期早已褪去。','舊防具可能受過撞擊，外層完整不足以判定可靠。','舊制式防彈衣，材料與隱藏損傷需要專門檢驗。','不設定可擋口徑或護甲數值，先讓可靠檢驗成為珍貴服務。','460 Caps 是可驗證完整個體的設計估值。',
    [('none','low','日常農務不需要，特定護衛委託例外。'),('low','medium','警備遺跡與檢驗工坊形成有限流通。'),('none','medium','有後勤的護運團尋找可靠防具。')],
    [('收購者只看外觀就承諾高價。','要求共同檢驗再談交付。','需等待專業者，結果可能降低價值。'),('倉庫要借出防具給當班守衛。','建立清楚的領用與歸還紀錄。','必須符合尺寸與所有權，不同人不能同時穿同件。')],
    'cloth precision_parts','cloth','equipment combat_extension identification jobs','WG-02 WG-05')
wear('scrap_iron_armor','salvage_plate_harness',6500,190,'uncommon','metal_plate improvised heavy','combat trade explore','inspect_harness transport_local_armor','gray_valley local_smiths','armour_workbench militia_store',
    '不同厚度的鐵片被固定在皮帶上，走動時會互相碰撞。','沉重且需要合身，聲響和活動空間都是代價。','地方拼接護具，護片與承重皮帶需分別檢查。','低材料價格與高攜行成本並存，不能等同優良軍甲。','190 Caps 提案偏重本地材料取得容易，6500 g 為明显負擔。',
    [('low','low','農業出行不願攜帶重護具。'),('medium','medium','固定守衛與在地修配有需求。'),('low','low','遠行重量與散熱限制購買意願。')],
    [('工匠展示不同尺寸的拼裝護具。','量身調整已取得的承重帶。','需時間與皮料；未檢驗前不宣稱防護改善。'),('遠行貨物超出運輸計畫。','選擇留下重護具或另安排托運。','失去當段裝備機會，不由物品改寫既有容量。')],
    'steel_stock leather','scrap_iron leather','equipment combat_extension cargo identification','WG-02 WG-05')
wear('car_panel_cuirass','rigid_plate_cuirass',8200,250,'rare','rigid_plate vehicle_salvage heavy','combat trade','fit_fixed_guard_armor inspect_maker_stamp','gray_valley vehicle_breakers','heavy_guard_store metalworker_display',
    '胸前保留一道車板弧度，側帶被多次加長。','硬殼與重量限制活動，較適合固定場所準備。','以回收板材製成的胸甲，不能用原車型推導防護能力。','它是灰谷的粗重工藝候選，不是給所有人物追求的升級階梯。','250 Caps 提案包含整形工時，搬運與合身成本另計。',
    [('none','low','固定糧倉守衛也需權衡重量。'),('low','medium','近距離固定守望可能有小眾使用者。'),('none','low','長線商隊通常不願背負硬重甲。')],
    [('倉庫守衛留下不合身的胸甲。','找原工匠評估是否值得改帶。','合身不保證防護，拆改可能失去原有結構。'),('一名商人把車板來源當作品質保證。','要求檢驗板材與接合而非相信故事。','付出檢查成本，不直接得到完整製造史。')],
    'leather steel_stock','scrap_iron leather','equipment combat_extension identification jobs','WG-02 WG-04')
wear('old_world_military_armor','military_protective_set',9500,1150,'rare','military_protection fitted scarce_parts','combat explore trade','inspect_protective_set preserve_component_record','military_ruins old_world_depots','sealed_protection_locker officer_store',
    '多件防護組件裝在一只編號袋裡，有一條固定帶缺了扣。','稀有不代表完整；尺寸、缺件與檢驗能力决定能否使用。','舊世軍用防護組，具體防護項目需獨立鑑定。','這件不是自動開啟所有污染區的環境防護服，也不授予軍方身分。','1150 Caps 提案僅對應主要組件齊全的收藏與使用需求。',
    [('none','low','一般生活難以負擔，可能只接轉運委託。'),('low','medium','專門檢修工坊與收藏者有不同需求。'),('none','medium','特定高風險護運團會委託尋找。')],
    [('出土防護組缺少原始點收表。','調查同批設備記錄確定缺件。','需文件和時間，不因完成列表就自動修復。'),('研究者與護衛對唯一完整組件提出不同需求。','選擇保留研究或交給實際使用者。','移交後失去裝備機會；不得同時滿足兩方。')],
    'precision_parts cloth leather','steel_stock cloth','equipment combat_extension identification knowledge jobs','LD-P01 WG-05')
wear('hazmat_suit','chemical_protective_suit',2400,540,'rare','sealed_suit chemical_protection inspection_required','explore survival trade','inspect_seams prepare_controlled_entry','old_world_laboratories industrial_safety','safety_locker laboratory_store',
    '透明面窗發黃，包裝上的檢驗日期已無法讀清。','密封接縫與面窗都要檢查，外觀不代表能抵禦所有污染。','化學防護衣候選；適用危害、呼吸裝備及使用期限尚待規則。','只作特定區域通行準備，不把 hazmat 標籤當萬能通行證。','540 Caps 提案要求可檢驗完整，未計清理與配套呼吸器。',
    [('none','low','只在特定污染调查有需求。'),('low','high','工業場址调查與安全作業需要合適防護。'),('low','medium','燃料設施事故處理可能需要，危害類型仍須確認。')],
    [('舊實驗室門口列著不明危害標誌。','先比對防護衣適用範圍再規劃入內。','需 hazard identification 與完整配套，不能立即進門。'),('工坊準備接收用過的防護衣。','將可疑衣物隔離等待檢驗。','暫停穿用與出售，不能直接拆成乾淨布料。')],
    'rubber plastic','plastic','equipment hazards exploration identification jobs','WG-05 FICTION-WOOL')
wear('heat_insulation_suit','industrial_heatwear',5200,470,'rare','thermal_layers industrial bulky','explore survival trade','inspect_heat_layers prepare_hot_work','gray_valley foundries old_world_industry','foundry_change_room safety_store',
    '銀灰外層有幾處暗斑，內襯厚得不易摺好。','隔熱與防火不同；熱源、接觸時間和作業環境仍須確認。','工業隔熱衣，需要檢查反射層及內襯完整性。','允許提出短時設備檢查方案，不直接免除所有熱危害。','470 Caps 提案包含少見多層材料，體積與重量形成代價。',
    [('none','low','只有特殊設備工作會委託取得。'),('low','high','熔爐與高溫作業場有具體使用者。'),('low','medium','煉製設施維護需要先核對適用範圍。')],
    [('停機後設備仍過熱無法近看。','請專業者評估衣物與等待時間。','可能仍需等冷卻，不用道具跳過作業安全條件。'),('過厚防護衣使狹窄通道難通過。','放棄穿入，改從外側觀察。','失去近距離調查機會，但不強迫傷害結果。')],
    'cloth aluminum_stock','cloth','equipment hazards exploration identification','WG-05 WG-04')
wear('firefighter_suit','fire_resistant_workwear',6400,510,'rare','rescue_clothing layered bulky','survival explore trade','inspect_rescue_clothing lend_rescue_gear','old_world_fire_stations rescue_depots','fire_station_locker emergency_store',
    '袖口的救援編號仍在，褲腳有一次作業留下的焦痕。','防火衣不自帶可呼吸空氣，也不代表能進任何火場。','多層救援工作服，需要核對焦痕是否傷到內層。','衣物服務救援故事，不能替代水、呼吸器或已存在的消防隊。','510 Caps 為經檢驗可用救援服的提案價。',
    [('none','medium','木造棚舍多，集體救援備品有理由。'),('low','high','舊消防站與工業安全隊可能保管。'),('low','high','燃料事故需求迫切，但配套和訓練同樣重要。')],
    [('燃料庫外有人組織救援。','將衣物借給具備合適訓練的人。','需本人同意與衣物尺寸，不能宣稱火災因此熄滅。'),('封存庫找出一套有焦痕的服裝。','先送檢而非直接分配使用。','佔用運輸與檢驗時間，可能只剩展示或報廢價值。')],
    'cloth rubber','cloth','equipment hazards identification jobs npc_relationship','FICTION-ROAD WG-05')
wear('wilderness_cloak','travel_cloak',1350,95,'uncommon','cloak weather_layer reversible','survival explore trade','cover_camp_bundle conceal_reflective_gear','wilderness_tailors caravan_camps','outdoor_supply_stall traveller_cache',
    '外層被曬得灰綠，裡面仍留著舊主的細密補線。','可覆住衣物或行李，不能讓穿戴者隱形。','大幅外披布料，覆蓋範圍與濕重取捨需之後定義。','以露營與觀察準備為用途，是否影响潛行由獨立規則決定。','95 Caps 提案反映完整大面積布料與旅行耐用性。',
    [('medium','medium','林緣旅行和夜間等候有需求。'),('low','medium','出城拾荒者會找容易修補的披覆。'),('medium','medium','營地遮覆有用，但沙袍更常見。')],
    [('守望點附近的金屬行李反射光線。','用斗篷暫時覆住反光面。','失去穿著用途，仍不能保證不被發現。'),('營地突然下起細雨。','罩住自己選定的一包物資。','只能覆有限範圍，不讓全隊行李自動防水。')],
    'cloth','cloth','equipment camping hazards exploration','WG-01 FICTION-ROAD')
wear('dust_mask','dust_face_cover',180,38,'common','face_cover dust replaceable_cloth','survival explore trade','fit_dust_cover replace_dirty_liner','dry_well caravan_tailors','desert_market spare_cloth_bundle',
    '兩條綁帶顏色不一樣，內襯堆著洗不掉的砂色。','用於灰塵環境的穿戴提案；不等同防毒面具。','布面罩需合身且內衬可處理，不能針對所有氣體提供保護。','它應讓出發準備更具體，不在 ITEM-1 中偷偷取消風暴延誤。','38 Caps 提案比整件服裝便宜，定期換襯仍有成本。',
    [('low','medium','穀物搬運和乾燥農路也可能有需求。'),('medium','high','粉塵工地與拆解場常用。'),('high','high','沙地日常更換形成穩定流通。')],
    [('商隊出發檢查發現內襯已塞滿砂。','先更換或清理可處理的內襯。','花時間與材料，舊布不能即刻變成乾淨替換品。'),('工人誤把面罩當成未知氣體防護。','指出限制並改用隔離調查方案。','無立即入內收益，避免把道具名稱當安全證明。')],
    'cloth','cloth','equipment hazards exploration jobs','WG-05 FICTION-METRO')
wear('gas_mask','filtered_respirator_mask',950,310,'rare','respirator seal filter_dependent','survival explore trade','inspect_face_seal identify_filter_type','old_world_safety military_ruins','safety_equipment_case emergency_locker',
    '面窗仍透明，濾罐標籤卻被刮掉了一半。','面罩、密封和相容濾材缺一不可，持有不等於能呼吸安全空氣。','濾罐式面具，適用危害與耗材壽命尚待 hazards/water-independent 規則。','不假借污水處理或一般醫療 authority；呼吸防護需要獨立條件。','310 Caps 假設面體可用，不包含有效濾罐供應。',
    [('none','low','只在特殊環境調查有需求。'),('low','high','工業安全與遺跡調查者願意送檢。'),('low','medium','煉製場所需要確認具體危害後才採用。')],
    [('廢棄管道口有居民描述刺鼻氣味。','先尋找氣體與濾材相容資訊。','需專業檢測，不能戴面具直接穿越未知氣體。'),('商人出售外觀良好的面具卻無有效濾材。','只談面體收購或拒買。','完整防護尚缺耗材，不因高價就視為已解鎖區域。')],
    'rubber glass','rubber glass','equipment hazards identification exploration','WG-05 FICTION-WOOL')
wear('engineering_goggles','work_goggles',240,65,'common','eye_protection industrial clear_lens','explore survival trade','inspect_lens wear_for_work','gray_valley workshops','tool_counter workshop_change_room',
    '透明鏡片邊緣刻著一道細線，鬆緊帶看起來是新換的。','能作工作護目裝備候選；刮痕會妨礙觀察。','普通透明工作鏡，不是焊接面罩、夜視鏡或氣密防護。','保持專門用途界線，不能因工程二字提供所有 MECHANICS 解法。','65 Caps 提案包含完好鏡片與固定帶的日常工坊需求。',
    [('low','medium','谷物粉塵與修理工作需要。'),('high','high','加工工班有供應與換新需求。'),('medium','high','風砂和固定工地需要護目器材。')],
    [('技工準備檢查受損機件。','先確認鏡片視野與固定帶。','裝備不取代操作知識，未定義防護效果仍不生效。'),('商隊尋人辨認一副特別配鏡。','比對鏡架維修記號。','需原維修者核對，不把持物當身分證。')],
    'glass rubber','glass rubber','equipment hazards identification knowledge','WG-01 WG-02')
wear('night_vision_goggles','powered_low_light_optics',820,890,'rare','optics powered low_light','explore survival trade','inspect_powered_optics plan_night_observation','military_ruins old_world_security','optics_locker sealed_patrol_case',
    '鏡罩還掛在背帶上，電池座有乾涸的腐蝕痕。','需要相容電源與可用感測元件，不是照亮整片荒野的燈。','低光觀察設備，適用亮度與電源壽命尚待 lighting/electronics。','提供觀察可能性而非看穿牆面；普通手電筒仍有照明與分享視野用途。','890 Caps 提案反映罕見完好光電組件，不含電池。',
    [('none','low','只有特定守望需求，缺少維護者。'),('low','high','光電工坊和遺跡調查者有興趣。'),('none','medium','夜行商隊需權衡電源供應和維修距離。')],
    [('隊伍想在夜間查明遠處移動的輪廓。','準備相容電源後安排單人觀察。','需實際照明規則與可見範圍，不能直接揭露身份。'),('精密工坊想查看腐蝕元件。','交付樣品進行檢測。','失去當晚使用機會，檢測可能判定無法維修。')],
    'circuit_board glass copper_wire','circuit_board glass','equipment electronics lighting exploration identification','WG-05 WG-06')
wear('tactical_helmet','military_protective_helmet',1550,320,'rare','helmet fitted shell_inspection','combat survival trade','inspect_helmet_shell register_headgear','military_depots security_surplus','helmet_rack sealed_protection_box',
    '外殼上有一處凹痕，內部襯帶卻保存得很新。','外殼和襯帶需要分開檢查，不能只看新配件便當成可用。','舊制式頭盔，未知撞擊史會影響收購與使用判斷。','不是夜視鏡、呼吸器或軍方身分證；附掛能力未定義。','320 Caps 提案只適用檢驗後可接受的個體。',
    [('none','low','農務少需軍用頭具，特定守望者例外。'),('low','medium','安全器材工坊可檢驗並處理二手流通。'),('low','medium','護衛需要合身器材，但有重量及散熱代價。')],
    [('退役護衛想交換自己的頭盔。','先確認撞擊史與襯帶尺寸。','口述史可能不完整，檢驗費用仍需協商。'),('施工地有人拿軍帽冒充有效防護。','請負責者檢查真正保護需求。','不能用外型代替規格，也不因此立即提高工地安全。')],
    'cloth leather','steel_stock cloth','equipment combat_extension hazards identification','WG-04 WG-05')

wear('cloth_sack','simple_sack',180,12,'common','cloth container simple','trade explore survival','separate_small_cargo label_bundle','new_hope settlement_households','market_packaging farm_store',
    '袋口只有一條繩，布角繡著早已褪色的糧行記號。','便於分裝乾燥小物，沒有硬殼或防水能力。','180 g 為空布袋，袋內物資仍需逐件計重與確認所有權。','普通包裝能讓物資去向更清楚，不會讓既有背包容量憑空增加。','12 Caps 提案作低價包裝，仍比無主破布更完整。',
    [('high','high','種子與乾燥農產常需分裝。'),('high','medium','小零件要整理，但銳利材料容易刮破布袋。'),('medium','medium','乾燥貨物可分袋，燃料不能直接裝布袋。')],
    [('兩戶共同買下的種子混成一堆。','用已持有空袋分清雙方份額。','需双方確認數量，袋子也要記錄去向。'),('遺跡發現散落可回收小件。','先分裝已辨識且無主的物件。','仍占實際負重，不能以一袋代替無限物資。')],
    'cloth','cloth','equipment cargo exploration jobs','WG-01 WG-02')
wear('travel_backpack','travel_pack',1100,60,'common','backpack cloth repaired','survival explore trade','pack_trip_supplies inspect_straps','settlement_tailors caravan_routes','secondhand_pack_stall traveller_storage',
    '兩條肩帶磨成不同顏色，背面縫著三層補丁。','方便準備旅程，肩帶與底布必須檢查。','1100 g 是空包重量；容量、裝備位與負重效果均待 equipment/cargo authority。','ITEM-1 的 CONTAINER 類別現在不提供任何 capacity 加成。','60 Caps 提案反映完整但老舊的旅行包；重量沿用 ITEM-1。',
    [('medium','high','送貨與外出換物的居民需要可修補背包。'),('high','high','拾荒與中轉人口讓二手包流通頻繁。'),('medium','high','長線補給準備需要可靠攜行器具。')],
    [('出發前發現包底有開線。','先找裁縫修好再安排行李。','付出時間與布料；修補不增加既有容量。'),('陌生旅人尋找遺失背包。','核對補丁形狀後安排交還。','需確認所有權，不能因拾得包就取得其中全部物品。')],
    'cloth leather','cloth leather','equipment cargo exploration npc_relationship','FICTION-ROAD LD-P02')
wear('hiking_backpack','framed_hiking_pack',1900,145,'uncommon','backpack frame adjustable','survival explore trade','fit_pack_frame balance_load','old_world_outdoors caravan_outfitters','outdoor_store abandoned_camp',
    '支架貼著舊山徑貼紙，腰帶仍有調整餘量。','支架可幫助整理負荷的構想，尺寸不合也會造成負擔。','空包1900 g，支架和承重帶需逐件檢查；不自帶已生效的高負重。','優勢應來自合身和行程需求，而非永遠比舊旅行包高一級。','145 Caps 提案反映完整支架與可調背帶。',
    [('low','medium','山路採集者需要，但一般短途不一定值得。'),('medium','medium','遺跡回收可取得，維修金屬架較方便。'),('low','high','長線旅人願意為合身與平衡付代價。')],
    [('山路隊伍要在水與工具之間取捨。','先分配真實行李，再調整支架。','不增加補給或容量；體積、總重量仍待獨立規則。'),('二手包的支架已偏斜。','選擇送修或保留較輕舊包。','修理需工坊，不能用裝備切換立即恢復。')],
    'aluminum_stock cloth leather','aluminum_stock cloth','equipment cargo exploration navigation','WG-02 WG-05')
wear('military_backpack','field_supply_pack',2400,220,'uncommon','backpack military modular_pouches','survival explore trade','inventory_pouches preserve_unit_marks','military_surplus old_world_depots','supply_locker sealed_field_kit',
    '多個外袋的扣件不盡相同，內側有褪色的點收印。','口袋多方便分類，但總攜重與可用空間仍需規則。','空軍用包，不包含醫藥、武器或額外補給。','軍用出身提供來源故事，並非持有即得到免費工具套組。','220 Caps 提案包含完好扣具與厚實布料。',
    [('none','medium','長程搬運者需要，普通農務嫌重。'),('low','high','能處理扣具與厚布的工坊有市場。'),('low','high','商隊重視耐用外袋，仍需逐包檢查。')],
    [('出土軍包外袋被誤認仍有醫療用品。','逐袋清點，明確記錄實際空缺。','只記錄已存在內容，不生成完整軍用套裝。'),('收藏者想買走內側點收印。','選擇保留整包或同意破壞取樣。','拆除印記會損及來源證據與袋布。')],
    'cloth leather precision_parts','cloth leather','equipment cargo knowledge identification','WG-03 FICTION-CANTICLE')
wear('tool_belt','work_tool_belt',650,55,'common','belt tool_organizer fitted','explore trade survival','organize_owned_tools lend_empty_belt','gray_valley workshops','workbench_hook tool_stall',
    '幾個皮套被扳手磨出形狀，腰帶尾端多打了兩個孔。','方便收納已擁有工具，空套不會附贈相應工具。','650 g 空腰帶，套袋尺寸限制能放的東西。','快捷使用與裝備槽若未實作，畫面不能宣稱縮短行動時間。','55 Caps 提案反映皮套與縫線完整度。',
    [('medium','medium','農具修繕與棚舍維護有需求。'),('high','high','工坊最常用，修皮與工具需求互相連結。'),('low','high','煉製設備維護者需要整理小工具。')],
    [('檢修場要求清點帶入工具。','把自己已有工具逐件放入並登記。','不增加工具數量，也不能用套袋代替正式工具要求。'),('學徒的腰帶斷裂卻要趕去工作。','借出空腰帶讓他整理自己的工具。','腰帶暫時離手，不能同時給自己快捷效果。')],
    'leather cloth','leather','equipment cargo repair jobs npc_relationship','WG-01 WG-02')
wear('ammo_bandolier','cartridge_carrier',420,75,'uncommon','belt ammunition_organizer empty','combat trade survival','inspect_carrier_fit transport_empty_bandolier','caravan_guards military_surplus','guard_kit military_clothing_store',
    '皮環大小不一，只有幾環仍有彈殼留下的亮痕。','空彈藥帶只是一件攜具，適用規格需要先確認。','420 g 不含任何彈藥；現有 category illustration 彈藥也不是可裝填實物。','未來補給規格確立後才能定義攜帶與取用行為，不能現在增加彈量。','75 Caps 提案取決於皮環和扣件完整。',
    [('low','medium','獵戶需匹配規格，不能按外形買。'),('medium','medium','皮革匠可修，但完整彈藥供應另計。'),('medium','high','護運人員整理相容補給有需求。')],
    [('買家發現皮環與手上補給不合。','核對規格後拒絕不適用交易。','需具體彈藥設計才能驗證，不能憑 category tag 通用。'),('一箱空彈藥帶被列成已裝填補給。','修正貨單並交付實際空攜具。','可能失去原約定貨款，不能生成缺失彈藥。')],
    'leather','leather','equipment combat_extension cargo jobs','WG-05 WG-02')
wear('medical_satchel','medical_organizer_bag',850,100,'uncommon','bag medical_organizer washable','survival trade explore','sort_medical_supplies protect_labels','settlement_clinics caravan_medics','clinic_store travelling_medic_kit',
    '袋內隔層洗得比外布乾淨，每格都縫著空白標籤。','便於整理醫療用品，空袋不能治療或代表持有人是醫生。','850 g 為空袋；清潔、醫療耗材和醫療能力需要分開記錄。','醫疗身份與用品權限都不能從布袋圖案推得。','100 Caps 提案反映可清理隔層和分類需求。',
    [('low','high','偏遠診療需要整理少量補給。'),('medium','medium','工傷照護點可能維修或交換袋具。'),('low','high','遠行醫護需要可識別用品的攜具。')],
    [('診所收到標籤混亂的用品。','用空隔層暫存已辨識品項。','需醫護核對，袋子不自動鑑定藥物或清除污染。'),('旅人要求借醫療袋去裝燃料配件。','選擇拒絕或接受用途變更。','混裝後不能宣稱仍適合直接放醫療用品。')],
    'cloth leather','cloth','equipment cargo injury identification jobs','WG-01 FICTION-ROAD')
wear('waterskin','flexible_water_container',380,45,'common','liquid_container flexible empty','survival trade explore','carry_allocated_water inspect_seam','dry_well leather_workers caravan_stops','water_vendor_stall traveller_pack',
    '皮袋口被反覆綁緊，接縫處有深淺不一的水痕。','可提出儲水用途，但容器不是水本身。','380 g 是空袋，容量、可飲用性與內裝液體重量另待 cargo/water_treatment。','不能把買一只水袋等同增加 Water 或减少代謝消耗。','45 Caps 提案讓旅行容器可取得，但仍需支付或取得水。',
    [('medium','medium','水源較易取得，外出者會買攜具。'),('low','medium','運送個人配給時有需求，皮革維修要專人。'),('high','high','長段無補給路線需要可維護儲水容器。')],
    [('水站願分配水卻要求自備容器。','用空水袋領取已獲准份額。','必須扣除水站真實水量，不能由容器生成水。'),('旅人發現袋縫滲漏。','先轉移已有液體，再委託修補。','需要另一個真實容器，轉移損失與時間待規則。')],
    'leather rubber','leather','equipment cargo water_treatment survival','WG-01 FICTION-ROAD')
wear('waterproof_bag','sealed_document_bag',320,80,'uncommon','water_barrier sealed_pouch dry_storage','explore trade survival','protect_paper_cargo inspect_closure','caravan_outfitters old_world_outdoors','outdoor_store courier_supply',
    '半透明袋面有一道折白，封口仍能贴合。','適合保護特定乾燥物件，封口有缺陷時不能保證防水。','320 g 空防水袋，容量與完整性需檢驗；不是液體儲罐。','讓文件與醫療標籤在路上值得保護，不讓所有行李免費免受水害。','80 Caps 提案反映完整封口較難修復。',
    [('medium','high','灌溉區送信與種子資料需要防濕。'),('low','medium','精密零件文件運輸有需求。'),('medium','medium','可阻擋砂與潑濺，但不是長時間高溫防護。')],
    [('信使要涉過淺水卻帶著紙本日記。','將日記放進已檢查袋內。','只保護有限內容，仍需安全通行方案。'),('袋封口破損，委託文件即將出發。','选擇等待替換或改走乾燥路線。','花時間或增加路程，不能用布補丁保證密封。')],
    'plastic rubber','plastic','equipment cargo hazards knowledge navigation','FICTION-CANTICLE FICTION-METRO')
wear('sealed_cargo_crate','sealed_transport_crate',7800,185,'uncommon','crate sealable heavy container','trade explore survival','record_cargo_seal transfer_sealed_load','gray_valley freight_workshops dry_well','freight_depot warehouse_store',
    '箱邊有多次撬開又修補的印痕，封條槽卻仍完整。','適合可追溯運輸，封條只能显示是否被動過，不能防止一切偷竊。','7800 g 為空箱；內裝貨物、封條和所有權都需分別建模。','此箱不自動成為商隊或增加玩家容量，重物通常需運輸安排。','185 Caps 提案反映箱體與封條槽價值，不含貨物。',
    [('low','medium','較昂貴農產或種子運輸才值得使用。'),('high','high','工業成品與零件托運需要硬箱。'),('medium','high','燃料相關精密件需防串貨與交接追蹤。')],
    [('收貨方發現封條記號與貨單不符。','先共同驗封並隔離爭議貨物。','需當事人見證，不能直接判定偷竊者或開箱取走。'),('商隊超載但必須保住某件精密物。','選擇保留硬箱並放棄別項貨物運輸。','明確失去裝載機會，不能以箱子賺出額外容量。')],
    'steel_stock rubber','scrap_iron rubber','equipment cargo jobs reputation','WG-02 FICTION-METRO')

# Gameplay categories follow proposed use, not the artwork's folder taxonomy.
for record in ITEMS:
    if record['content_id'] in {'content_entrenching_shovel', 'content_crowbar', 'content_wood_axe',
                                'content_power_hammer', 'content_industrial_nailgun', 'content_flare_pistol'}:
        record['category'] = 'TOOL'
    if record['content_id'] in {'content_industrial_nailgun', 'content_flare_pistol'}:
        record['tags'].remove('firearm')
    if record['content_id'] == 'content_waterskin':
        record['dependencies'].remove('survival')  # Role, not an approved mechanic ID.
    if record['content_id'] == 'content_gas_mask':
        record['identified_description_zh'] = '濾罐式面具，適用危害與耗材壽命尚待環境危害規則；不能與淨水規則混用。'

if __name__ == '__main__':
    target_seeds = {s['content_id']: s for s in SEEDS if min(s['art_sections']) <= 6}
    assert len(ITEMS) == 71 == len(target_seeds)
    assert len({r['content_id'] for r in ITEMS}) == 71
    assert {r['content_id'] for r in ITEMS} == set(target_seeds)
    valid_ids = {s['content_id'] for s in SEEDS}
    allowed_deps = set('item_ownership equipment combat_extension injury repair lighting water_treatment cooking camping cargo navigation electronics identification knowledge npc_relationship reputation jobs regional_trade crafting disassembly hazards exploration succession skills_growth'.split())
    for r in ITEMS:
        seed = target_seeds[r['content_id']]
        for key in ('name_zh', 'art_file', 'art_sections', 'art_role', 'runtime_item_id'):
            assert r[key] == seed[key], (r['content_id'], key)
        assert seed['baseline_weight_g'] is None or seed['baseline_weight_g'] == r['proposed_weight_g']
        assert len(r['hooks']) >= 2 and all(h['cost_or_limit_zh'] for h in r['hooks'])
        assert set(r['repair']['inputs'] + r['salvage']['outputs']) <= valid_ids
        assert set(r['dependencies']) <= allowed_deps, (r['content_id'], r['dependencies'])
        assert r['status'] == 'DESIGN_ONLY'
    out = ROOT / 'items' / '01-weapons-equipment.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(ITEMS, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'items': len(ITEMS), 'hooks': sum(len(r['hooks']) for r in ITEMS), 'output': str(out)}, ensure_ascii=False))
