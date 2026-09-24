"""Editorial source only; expands hand-authored rows into reviewable JSON.

No production import, effect evaluation, random choice or price calculation.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEEDS = json.loads((ROOT / "item-seeds.json").read_text(encoding="utf-8-sig"))
TARGET = [s for s in SEEDS if 7 <= s["art_sections"][0] <= 11]
ALL_IDS = {s["content_id"] for s in SEEDS}

def parse(block, width):
    result = {}
    for line in block.strip().splitlines():
        fields = line.split("|")
        assert len(fields) == width, (fields[0], len(fields), width)
        assert fields[0] not in result, fields[0]
        result[fields[0]] = fields[1:]
    return result

META = parse("""
clean_water|CONSUMABLE|sealed_water|1100|12|common|water,sealed|survival,trade|drink,share,deliver|new_hope,water_station|water_store,caravan_provisions|item_ownership,regional_trade,jobs|WG-02,FICTION-ROAD
dirty_water|CONSUMABLE|untreated_water|1100|2|common|water,untreated|survival,explore|sample,treat,deliver_sample|wilderness,runoff|collection_basin,abandoned_cistern|item_ownership,water_treatment,identification,exploration|WG-01,FICTION-ROAD
water|CONTAINER|canteen|300|18|common|water_container,reusable|survival,explore|fill,carry_water,lend|caravan,settlement_workshop|traveller_pack,camp_storage|item_ownership,cargo,water_treatment|WG-01,FICTION-ROAD
purification_tablets|CONSUMABLE|water_treatment_tablets|40|32|uncommon|water_treatment,sealed|survival,trade|treat_water,deliver|old_world_clinic,caravan|clinic_cabinet,expedition_cache|item_ownership,water_treatment,identification,regional_trade|WG-01,WG-02
water_filter|TOOL|portable_filter|600|120|uncommon|water_treatment,filter|survival,explore|filter_water,inspect_filter,lend|new_hope,old_world_utility|pump_house,caravan_service_box|item_ownership,water_treatment,repair,identification|WG-01,WG-03
food|CONSUMABLE|travel_ration|400|12|common|food,dry,portable|survival,trade|eat,share,deliver|new_hope,caravan|provision_store,traveller_pack|item_ownership,regional_trade,jobs|FICTION-ROAD,LD-P02
jerky|CONSUMABLE|dried_meat|200|16|common|food,dried_meat|survival,trade|eat,share,exchange|new_hope,hunters|hunter_pack,smoking_shed|item_ownership,cooking,regional_trade|FICTION-ROAD,WG-02
canned_food|CONSUMABLE|sealed_food|500|18|common|food,sealed|survival,trade|open,eat,donate|new_hope,caravan|ration_crate,store_shelf|item_ownership,cooking,identification,regional_trade|WG-01,FICTION-ROAD
wild_greens|CONSUMABLE|foraged_greens|250|4|common|food,perishable,foraged|survival,explore|identify,cook,deliver_sample|new_hope,wilderness|riverbank,forager_basket|item_ownership,identification,cooking,jobs|WG-01,FICTION-ROAD
raw_meat|CONSUMABLE|uncooked_meat|600|8|common|food,perishable,meat|survival,trade|cook,preserve,deliver|hunters,new_hope|hunter_camp,butcher_table|item_ownership,cooking,regional_trade,jobs|WG-01,WG-02
salt|CONSUMABLE|preserving_salt|250|10|common|food,preserving,trade_good|survival,trade|season,preserve,exchange|dry_well,salt_flat|dry_store,merchant_sack|item_ownership,cooking,regional_trade|WG-01,WG-02,LD-P01
matches|CONSUMABLE|matchbox|30|6|common|ignition,dry_storage|survival,explore|ignite,share|settlement_workshop,caravan|kitchen_drawer,camp_tin|item_ownership,camping,cooking,hazards|WG-01,FICTION-ROAD
lighter|TOOL|refillable_lighter|90|24|common|ignition,reusable|survival,explore|ignite,refill,lend|gray_valley,caravan|worker_pocket,market_stall|item_ownership,camping,cooking,repair,hazards|WG-01,WG-05
fuel_can|CONTAINER|empty_fuel_can|900|26|common|fuel_container,metal|trade,survival|fill_fuel,seal,transport|dry_well,gray_valley|refinery_store,garage_shelf|item_ownership,cargo,repair,regional_trade,hazards|WG-03,FICTION-METRO
sleeping_bag|TOOL|bedroll|1700|38|common|camping,textile|survival,explore|camp,lend,dry|caravan,settlement_workshop|traveller_pack,camp_bed|item_ownership,camping,repair|WG-03,FICTION-ROAD
tent|TOOL|portable_shelter|3800|75|uncommon|camping,shelter|survival,explore|pitch,shelter,loan|caravan,new_hope|expedition_store,abandoned_camp|item_ownership,camping,cargo,repair,hazards|WG-03,FICTION-ROAD
rope|TOOL|utility_rope|2500|30|common|rope,travel|explore,survival|secure_cargo,lower_bundle,anchor_line|caravan,settlement_workshop|cargo_store,bridge_maintenance_box|item_ownership,cargo,exploration,hazards|WG-01,LD-P01
flashlight|TOOL|handheld_light|400|35|common|lighting,electric|explore,survival|illuminate,signal,inspect|gray_valley,old_world_home|maintenance_box,household_drawer|item_ownership,lighting,electronics,repair|WG-01,WG-05
battery|CONSUMABLE|replaceable_battery|100|12|common|electricity,power_supply|explore,trade|power_device,test_charge,deliver|gray_valley,caravan|electrical_store,maintenance_box|item_ownership,electronics,identification,regional_trade|WG-03,WG-05
oil_lamp|TOOL|wick_lamp|650|24|common|lighting,flame|survival,explore|light_area,refill,hang|dry_well,settlement_workshop|pump_shed,roadside_shelter|item_ownership,lighting,camping,hazards,repair|WG-01,WG-03
bandage|CONSUMABLE|sterile_dressing|70|8|common|medical,dressing|survival,trade|provide_dressing,deliver|settlement_clinic,caravan|clinic_drawer,rescue_kit|item_ownership,injury,jobs,regional_trade|FICTION-ROAD,WG-04
disinfectant|CONSUMABLE|labelled_antiseptic|300|20|uncommon|medical,labelled|survival,trade|supply_clinic,inspect_label|old_world_clinic,settlement_clinic|clinic_cabinet,sealed_medical_crate|item_ownership,injury,identification,jobs|WG-01,WG-02
painkillers|CONSUMABLE|labelled_analgesic|40|22|uncommon|medical,labelled|survival,trade|consult_medic,deliver|old_world_clinic,caravan|pharmacy_drawer,clinic_stock|item_ownership,injury,identification,jobs|WG-04,FICTION-ROAD
antibiotics|CONSUMABLE|labelled_antibiotic|50|60|rare|medical,restricted_supply|survival,trade|deliver_to_medic,verify_stock|old_world_clinic,caravan|sealed_pharmacy_stock,medical_shipment|item_ownership,injury,identification,regional_trade,jobs|WG-02,FICTION-ROAD
first_aid_kit|CONSUMABLE|field_medical_kit|800|55|uncommon|medical|survival,trade|offer_field_aid,donate,check_contents|settlement_clinic,caravan|emergency_cabinet,caravan_medical_bag|item_ownership,injury,npc_relationship,jobs|FICTION-ROAD,WG-04
surgical_kit|TOOL|surgical_instrument_set|1100|180|rare|medical,instruments|survival,trade|lend_instruments,deliver_to_clinic|old_world_hospital|operating_room_store,medical_archive_cache|item_ownership,injury,repair,identification,jobs|WG-01,WG-02
adrenaline|CONSUMABLE|emergency_injector|80|90|rare|medical,emergency,labelled|survival,trade|deliver_emergency_stock,consult_medic|old_world_emergency_service|ambulance_locker,medical_shipment|item_ownership,injury,identification,jobs|WG-04,FICTION-ROAD
anti_radiation_medicine|CONSUMABLE|radiation_medicine|60|100|rare|medical,radiation,labelled|survival,explore|consult_specialist,deliver|old_world_hospital,restricted_facility|hazard_response_locker,clinic_vault|item_ownership,injury,hazards,identification|WG-06,WG-02
antidote|CONSUMABLE|specific_antidote|90|75|rare|medical,toxin_specific|survival,explore|identify_match,deliver_to_medic|old_world_clinic,field_research|toxicology_cabinet,field_medical_case|item_ownership,injury,hazards,identification|WG-01,WG-04
burn_ointment|CONSUMABLE|burn_dressing_supply|120|28|uncommon|medical,burn_care|survival,trade|supply_burn_station,deliver|settlement_clinic,old_world_factory|factory_first_aid_box,clinic_stock|item_ownership,injury,jobs,regional_trade|WG-02,FICTION-ROAD
old_world_medical_case|TOOL|sealed_medical_case|2400|240|rare|medical,sealed,old_world|explore,trade,survival|audit_contents,deliver_sealed,donate|old_world_hospital|sealed_clinic_store,ambulance_cache|item_ownership,identification,injury,jobs,cargo|WG-02,FICTION-CANTICLE
unlabelled_medicine|MISC|unidentified_vial|80|null|rare|medical,unidentified|explore,trade|submit_sample,quarantine,investigate|old_world_laboratory|unlabelled_lab_drawer,abandoned_clinic|item_ownership,identification,knowledge,hazards|WG-06,FICTION-ROADSIDE
wrench|TOOL|adjustable_wrench|700|25|common|hand_tool,metal|explore,trade|turn_fastener,hold_joint,lend|gray_valley,industrial_ruin|maintenance_box,pump_shed|item_ownership,repair,exploration,jobs|WG-01,WG-02
screwdriver|TOOL|screwdriver|180|12|common|hand_tool,fastener|explore,trade|remove_cover,adjust_screw,lend|gray_valley,old_world_home|electrical_drawer,workbench|item_ownership,repair,electronics,exploration|WG-01,WG-02
pliers|TOOL|combination_pliers|320|18|common|hand_tool,wire|explore,trade|grip_wire,bend_tab,extract_pin|gray_valley,industrial_ruin|wireman_bag,workbench|item_ownership,repair,electronics,exploration|WG-01,WG-02
toolbox|TOOL|maintenance_tool_set|4500|95|uncommon|hand_tools,maintenance|explore,trade|service_mechanism,lend_set,inventory_tools|gray_valley,industrial_ruin|maintenance_cart,garage_store|item_ownership,repair,jobs,cargo|WG-01,WG-03
welding_tools|TOOL|portable_welding_set|7000|220|rare|joining,powered_tool|explore,trade|join_metal,patch_frame,deliver_to_workshop|gray_valley,industrial_ruin|fabrication_shop,repair_truck|item_ownership,repair,crafting,hazards,electronics|WG-01,WG-03
multimeter|TOOL|electrical_meter|400|85|uncommon|measurement,electric|explore,trade|test_circuit,compare_cells,diagnose|gray_valley,old_world_utility|electrician_bag,control_room|item_ownership,electronics,identification,repair|WG-01,WG-05
hand_crank_generator|TOOL|manual_generator|1500|110|uncommon|electricity,manual_power|survival,explore|supply_temporary_power,signal_power,lend|old_world_emergency_service,gray_valley|emergency_store,relay_station|item_ownership,electronics,repair,jobs|WG-03,WG-05
jack|TOOL|mechanical_lifting_jack|6000|90|uncommon|lifting,vehicle_tool|explore,trade|raise_axle,prop_frame,lend|gray_valley,dry_well|roadside_garage,vehicle_tool_locker|item_ownership,repair,cargo,hazards,exploration|WG-01,WG-03
metal_detector|TOOL|portable_metal_detector|1800|150|rare|detection,electric|explore,trade|survey_ground,locate_metal,mark_search_area|old_world_security,gray_valley|survey_store,security_depot|item_ownership,electronics,exploration,identification,hazards|WG-06,WG-01
binoculars|TOOL|field_binoculars|650|65|uncommon|optics,observation|explore,survival|observe_route,read_distant_marker,watch_caravan|caravan,old_world_outpost|watch_post,scout_pack|item_ownership,exploration,navigation|WG-04,LD-P01
compass|TOOL|magnetic_compass|100|35|uncommon|navigation,magnetic|explore,survival|take_bearing,check_route,teach_bearing|caravan,old_world_survey|surveyor_pack,route_station|item_ownership,navigation,identification|WG-01,FICTION-METRO
old_world_map|MISC|historical_map|120|45|uncommon|document,navigation,old_world|explore,trade|compare_landmarks,annotate,copy_route|old_world_archive,survey_station|map_drawer,abandoned_route_office|item_ownership,navigation,knowledge,identification|FICTION-CANTICLE,FICTION-WOOL
radio|TOOL|portable_transceiver|700|95|uncommon|communication,electric|explore,survival,trade|call,listen,relay|caravan,old_world_security|convoy_cab,watch_post|item_ownership,electronics,navigation,npc_relationship|WG-03,FICTION-METRO
signal_receiver|TOOL|directional_receiver|1300|180|rare|signal,measurement,electric|explore,trade|trace_signal,record_band,compare_emissions|old_world_communications|relay_station,technical_lab|item_ownership,electronics,exploration,knowledge,identification|WG-06,FICTION-WOOL
lockpick_set|TOOL|mechanical_lockpick_set|180|65|uncommon|access,precision_tool|explore,trade|inspect_lock,manipulate_lock,lend|gray_valley,caravan|locksmith_roll,confiscated_goods_box|item_ownership,exploration,npc_relationship,reputation|WG-01,WG-04
scrap_iron|MISC|sorted_iron_scrap|1000|8|common|material,ferrous,salvaged|trade,explore|sort,deliver_material,brace|gray_valley,industrial_ruin|scrap_heap,dismantling_bin|item_ownership,crafting,repair,regional_trade|WG-01,WG-02
steel_stock|MISC|steel_bar_stock|1500|24|uncommon|material,steel,stock|trade,explore|fabricate_blank,deliver_material|gray_valley,industrial_ruin|metal_rack,factory_store|item_ownership,crafting,repair,regional_trade|WG-01,WG-03
aluminum_stock|MISC|aluminum_stock|800|26|uncommon|material,aluminum,light_stock|trade,explore|fabricate_bracket,deliver_material|gray_valley,old_world_transport|vehicle_skin_store,factory_rack|item_ownership,crafting,repair,regional_trade|WG-01,WG-02
copper_wire|MISC|insulated_wire_coil|300|20|common|material,copper,electrical|trade,explore|connect_circuit,deliver_material|gray_valley,old_world_utility|cable_duct,electrician_store|item_ownership,electronics,repair,crafting,regional_trade|WG-01,WG-03
circuit_board|MISC|salvaged_circuit_board|180|40|uncommon|material,electronic,model_specific|trade,explore|identify_board,test_board,donate_for_repair|old_world_utility,gray_valley|control_cabinet,electronics_bin|item_ownership,electronics,identification,repair,disassembly|WG-01,FICTION-CANTICLE
gear|MISC|machine_gear|450|18|common|material,mechanical,toothed|trade,explore|match_drive,replace_component|gray_valley,industrial_ruin|machine_spares,gearbox|item_ownership,repair,identification,crafting,regional_trade|WG-01,WG-03
bearing|MISC|machine_bearing|180|22|uncommon|material,mechanical,rotating|trade,explore|match_shaft,replace_component|gray_valley,old_world_transport|axle_spares,workshop_drawer|item_ownership,repair,identification,regional_trade|WG-01,WG-05
spring|MISC|steel_spring|80|8|common|material,mechanical,elastic|trade,explore|restore_latch,match_component|gray_valley,industrial_ruin|hardware_drawer,scrap_device|item_ownership,repair,identification,crafting|WG-01,WG-05
rubber|MISC|rubber_sheet|400|12|common|material,rubber,sealing|trade,survival|cut_gasket,patch_cover,deliver_material|gray_valley,old_world_transport|rubber_stock,garage_store|item_ownership,repair,crafting,regional_trade|WG-01,WG-03
plastic|MISC|plastic_sheet|250|6|common|material,plastic,sheet|trade,explore|cut_spacer,cover_label,deliver_material|gray_valley,old_world_home|packaging_store,sorted_scrap_bin|item_ownership,crafting,repair,regional_trade|WG-01,WG-02
cloth|MISC|cloth_roll|500|10|common|material,textile,unsterile|trade,survival|patch_fabric,wrap_cargo,deliver_material|new_hope,settlement_workshop|tailor_store,linen_shelf|item_ownership,crafting,repair,cargo,regional_trade|WG-01,FICTION-ROAD
leather|MISC|tanned_leather|600|24|uncommon|material,leather,worked|trade,survival|cut_strap,patch_bag,deliver_material|new_hope,hunters|tannery_store,saddler_bench|item_ownership,crafting,repair,regional_trade|WG-01,WG-02
glass|MISC|glass_pane|800|10|common|material,glass,fragile|trade,explore|replace_window,protect_document,deliver_material|gray_valley,old_world_home|glazier_rack,window_store|item_ownership,repair,crafting,cargo,regional_trade|WG-01,FICTION-CANTICLE
chemicals|MISC|labelled_workshop_chemicals|500|35|uncommon|material,chemical,labelled|trade,explore|identify_label,supply_workshop|gray_valley,old_world_laboratory|chemical_cabinet,workshop_store|item_ownership,identification,crafting,hazards,regional_trade|WG-01,WG-05
battery_cell|MISC|bare_battery_cell|120|18|uncommon|material,electric,unprotected|trade,explore|test_cell,rebuild_power_pack|gray_valley,old_world_utility|battery_workshop,electronics_store|item_ownership,electronics,repair,identification,hazards|WG-01,WG-03
precision_parts|MISC|matched_precision_components|150|75|rare|material,precision,model_specific|trade,explore|verify_tolerance,restore_instrument|old_world_laboratory,gray_valley|instrument_case,precision_workshop|item_ownership,repair,identification,electronics,regional_trade|WG-01,FICTION-CANTICLE
cigarettes|CONSUMABLE|sealed_cigarette_pack|30|18|uncommon|trade_good,tobacco|trade|exchange,offer_gift,deliver|caravan,old_world_store|merchant_stock,sealed_shop_drawer|item_ownership,regional_trade,npc_relationship,jobs|WG-02,LD-P02
liquor|CONSUMABLE|labelled_drink_bottle|750|28|uncommon|trade_good,drink,sealed|trade|exchange,serve,deliver|new_hope,caravan|tavern_store,merchant_case|item_ownership,regional_trade,npc_relationship,jobs|WG-02,LD-P01
coffee|CONSUMABLE|coffee_packet|200|45|rare|trade_good,food,luxury|trade,survival|brew,exchange,deliver|caravan,old_world_store|import_crate,sealed_shop_stock|item_ownership,cooking,regional_trade,npc_relationship|WG-02,LD-P01
tea|CONSUMABLE|dried_tea|100|24|uncommon|trade_good,food,leaf|trade,survival|brew,host,exchange|new_hope,caravan|dry_grocery,seller_tin|item_ownership,cooking,regional_trade,npc_relationship|WG-02,FICTION-ROAD
sugar|CONSUMABLE|sugar_packet|250|16|uncommon|trade_good,food,sweetener|trade,survival|cook,exchange,donate|new_hope,caravan|dry_store,merchant_sack|item_ownership,cooking,regional_trade,jobs|WG-01,WG-02
spices|CONSUMABLE|spice_packet|80|30|uncommon|trade_good,food,aromatic|trade|season,identify_origin,exchange|caravan,new_hope|import_case,cook_store|item_ownership,cooking,identification,regional_trade,knowledge|WG-02,LD-P01
old_world_canned_food|MISC|collectible_old_food_can|500|60|rare|old_world,collectible,sealed|trade,explore|inspect_label,deliver_to_collector,assess_contents|old_world_store|sealed_pantry,museum_household_display|item_ownership,identification,knowledge,regional_trade|FICTION-CANTICLE,WG-02
ammunition|MISC|ammunition_family|null|null|category|category_only,ammunition|combat,trade||editorial_catalogue||item_ownership,combat_extension,regional_trade|WG-05,WG-02
medicines|MISC|medicine_family|null|null|category|category_only,medical|survival,trade||editorial_catalogue||item_ownership,injury,regional_trade|WG-02,FICTION-ROAD
mechanical_parts|MISC|mechanical_parts_family|null|null|category|category_only,mechanical|explore,trade||editorial_catalogue||item_ownership,repair,regional_trade|WG-01,WG-03
seeds|CONSUMABLE|labelled_seed_packet|100|30|uncommon|agriculture,seed,trade_good|trade,survival|verify_variety,deliver_for_sowing,trial_plot|new_hope,old_world_seed_store|seed_store,farm_exchange|item_ownership,identification,jobs,regional_trade,crafting|WG-03,LD-P01
fuel|CONSUMABLE|sealed_fuel_portion|1000|18|common|fuel,energy,flammable|survival,trade|supply_generator,deliver_fuel,verify_grade|dry_well,refinery|fuel_depot,caravan_supply|item_ownership,identification,regional_trade,hazards,electronics|WG-03,FICTION-METRO
""", 13)

PROSE = {}
MARKETS = {}
HOOKS = {}

def add_text(prose, markets, hooks):
    for target, block, width in [(PROSE, prose, 6), (MARKETS, markets, 10), (HOOKS, hooks, 7)]:
        addition = parse(block, width)
        assert not target.keys() & addition.keys()
        target.update(addition)

add_text("""
cigarettes|小盒香菸的封膜還在，外觀比內容更容易辨認。|一盒可交易消耗品，不附社交成功或能力增益。|確認真偽與保存後可交易或送給願意接受的人，對方也可能不收。|18 Caps 來自習慣性需求和密封品完整性，不是通用貨幣。|有些守夜者收，有些家庭拒收；送禮不能自動買到信任。
liquor|玻璃酒瓶有地方釀造者的手寫牌記。|一瓶飲用品；用途與品質需核對，不能充當醫療消毒品。|已辨明可飲的批次可供聚會或交易，開瓶後整瓶收藏價值改變。|28 Caps 以地方成品和運送重量估價，非戰鬥增益。|新希望有季節性小批釀造，乾井更在乎貨能否完整送到。
coffee|封口袋裡的深色豆粒保留淡淡氣味。|兩百克一包，來源與受潮狀況需確認。|可交廚房沖煮或保留為外來商品；不給永久警覺或免睡能力。|45 Caps 因外來供應少且有人偏好，並非每個聚落都有高需求。|願意付錢的是特定買家，不把全體居民都寫成咖啡愛好者。
tea|小鐵包裡的乾葉有產地記號，開口用紙繩封住。|一百克一包，茶葉與野外相似葉片不能混為同物。|核對來源後可沖泡或待客；款待是否被接受仍看關係與情境。|24 Caps 為容易分量使用的地方商品估值，口味不等於能力加成。|新希望有少量葉茶來源，商隊帶來的不同款式不必形成稀有度階梯。
sugar|顆粒糖裝在有防潮內襯的小袋裡。|兩百五十克一袋，結塊和污染要分清。|確認可食後可作廚房材料或交易小貨，不單獨取代完整飲食。|16 Caps 因加工、保存和甜味需求，沿路供應仍有限。|診所與家庭可能為供餐求購，不把它寫成有醫療處置能力的藥品。
spices|一包少量香料混著乾葉與碎粒，外面寫著產區。|八十克一包，香氣不是來源真偽的充分證據。|辨明批次後可供烹調或比較商路來源，沒有固定社交增益。|30 Caps 以輕便外來貨定位，需求集中在廚師和特定買家。|同一道料理可讓居民認出舊鄉味道，但不能直接證明贈送者身份。
old_world_canned_food|舊商標完整保留在金屬罐上，封口沒有被拆。|原封不代表仍能食用；可讀標籤已是一份歷史資料。|可交收藏者研究封裝與商標；若要評估食用需另行檢驗，不能憑外觀保證。|60 Caps 是完整包裝對特定收藏者的提議價，普通廚房可能完全拒收。|與近期罐頭分開，最有價值的可能是還沒被打開這件事。
ammunition|此圖展示彈藥家族，供目錄與商店分類使用。|它不是一盒可持有、可射擊或可販售的統一彈藥。|日後必須先區分武器相容品項與包裝，才可能定義重量和價格。|分類圖沒有物理單位與統一底價，不參與掉落或交易數量。|同一張圖可以引導閱讀相關設計，不能把各口徑混成無限通用供應。
medicines|此圖概括醫藥用品家族，展示用途多樣的封裝。|它不是一件額外通用藥，不可替代急救包或抗生素。|必須指向已辨識的具體品項，才可討論交付與醫療條件。|分類沒有重量和價格；需求分析須回到具體醫療品。|診所的缺貨清單要保留品名和批次，不用泛稱掩蓋無法供應的項目。
mechanical_parts|此圖彙整齒輪、軸承等機械件的目錄視覺。|它不是一箱能修任何設備的通用零件。|維修委託要落到具體型號、零件和數量，分類圖只作索引。|沒有獨立物理單位與底價，不能和已列零件重複計入庫存。|地區工業特色可在這個分類下整理，但實際供需仍需逐件決定。
seeds|小紙袋外寫著作物名、收集地和上一季日期。|一百克一袋種子；有品名不保證仍能發芽或適合新地點。|可核對品種、做有限試種或交給農務者；收成需要未來農務規則。|30 Caps 取有來源品種的準備價值，不能按未來整片收成估現價。|新希望保存種源，乾井的求購更可能是試種而非立即大量播種。
fuel|封好的燃料份裝在有品級記號的運輸瓶裡。|一份含封裝暫估一千克；不等於現有 fuel 抽象資源的一單位。|先核對品級與設備相容性，再作發電或運輸供應提案。|18 Caps 參照既有燃料尺度作設計估值，未定物理換算或價格公式。|乾井的出產優勢與安全包裝需求同時存在；有油不代表每條路都能供應。
""", """
cigarettes|low|low|部分買家有需求，居民並非普遍接受。|medium|medium|值班工人和外來商人有零星市場。|medium|medium|隨商隊流通，不是所有攤販都收。
liquor|medium|medium|季節性釀造與聚會需求並存。|low|medium|工班聚餐時下單，非日常必需。|low|medium|旅店與特定買家需要完整瓶裝貨。
coffee|low|low|多數家庭先買主食，少數買家偏好。|low|medium|值班者和收藏外來口味的買家願意收。|low|medium|商隊停靠店希望提供少見飲品。
tea|medium|medium|小批加工與待客文化形成需求。|low|medium|工班休息棚與居民採買。|low|medium|停靠店歡迎輕便耐攜葉茶。
sugar|medium|medium|食品加工有來源與需求。|low|medium|廚房需要少量調味。|low|medium|小包裝便於商隊帶入。
spices|medium|low|部分本地品種易得，外來風味另找買家。|low|medium|聚落廚房想區別普通供餐。|low|medium|旅店會為指定客人預訂，非無限需求。
old_world_canned_food|none|low|廚房不把陳年封罐當正常食物。|low|medium|舊貨研究者重視商標與封口。|none|low|商隊可能代找指定收藏者。
ammunition|none|none|分類圖不設供需；須先定義相容的具體彈藥。|none|none|工業地區也不使分類圖變成可製造的一件貨。|none|none|武器使用者需求留待具體彈種設計。
medicines|none|none|診所的需求應分別記在具體用品。|none|none|分類彙整不等於存在通用醫藥庫存。|none|none|運送委託需要品項，不能交一個醫藥圖示。
mechanical_parts|none|none|農具需求要列齒輪、軸承等指定件。|none|none|工業概況可用分類，庫存與價格仍按實物。|none|none|泵站委託不能用泛稱零件充數。
seeds|high|high|保存種源與下一季播種都需要，供需可以同時高。|low|low|少量院落栽種，不是主要產業。|none|medium|缺水環境只為明確試種計畫採購。
fuel|low|medium|抽水和外來機具需相容油料。|medium|high|工坊設備與車隊都需要能源。|high|high|產出與裝運消耗並存，不能視作無限廉價庫存。
""", """
cigarettes|守夜者說只想用手上貨物換一盒菸。|提出自願的小額交換，確認對方願付出的東西。|實際交出一盒；不能自動換到情報或好感。|一戶人家拒收商隊送來的香菸援助。|保留該貨，改談對方真正需要的食物或工具。|接受拒絕，不把送禮行為當成必定加關係。
liquor|聚落要為返回的工隊準備一頓飯。|交付一瓶來源清楚的酒給主辦者。|失去整瓶；慶祝是否舉行仍由事件條件決定。|商人想把標籤不明的烈性液體當酒出售。|要求核對來源，不能確認便拒絕交易。|放棄便宜貨，不把工業液體改名成可飲品。
coffee|一名老技工只記得離鄉前的烘豆味道。|讓對方聞辨未開封包裝外留下的來源線索，再談是否交換。|懷念不是身份證明，也不保證對方接受這批。|夜班工棚想買咖啡卻欠飲水與燃料。|把沖煮所需條件列清，先處理基本供應。|咖啡不能取代睡眠或清水，且沖煮消耗實物。
tea|新希望調解者想讓爭執雙方坐下來談。|提供茶葉給願意待客的人準備飲品。|需水、器具與雙方同意，不自動提高說服成功率。|旅店收貨人認不出外來葉茶。|保留產地紙條並安排辨識，再決定購買。|辨識耗時，不把任何芳香葉片當可食茶葉。
sugar|臨時廚房要替返鄉者做一份甜食。|捐出一袋糖給負責供餐者。|糖被消耗，仍需其他食材與烹調條件。|商隊糖袋破口，混入一袋不明白色粉末。|把來源可確認的袋子分開，拒絕混批交貨。|清點有損耗，顏色相同不能直接認定成分相同。
spices|乾井旅店想重現外來商人的家鄉料理。|提供有產地記錄的香料，請廚師先辨味。|只改變供餐內容，不創造固定社交增益。|兩條商路的貨商都聲稱自己帶來原產香料。|比對封裝與買家舊記錄，保留可查證差異。|沒有證據時只能維持未知，不能靠香味直接判定誰說謊。
old_world_canned_food|收藏者想要完整商標，飢餓旅人只關心能不能吃。|保留封罐交收藏者，或另請人評估食用價值。|開罐會破壞收藏完整性，食用安全也不預先保證。|研究者想比對舊世食品配送區。|提供標籤與發現位置的記錄。|資訊價值依完整來源而定，不能憑一罐重建全部商路。
ammunition|武器商想把所有彈藥需求寫成同一欄。|在設計清單中改列相容品項與包裝需求。|這是內容編輯情境，不得作實物需求或獎勵。|商隊補給摘要缺少具體彈種。|將分類圖保留作索引，要求逐項補齊交易對象。|未具體化前不能設定重量、數量或價格。
medicines|診所需求板只寫著需要藥物。|把泛稱拆成已有具體用品與需要辨識的未知項。|分類本身不可交付，不會完成醫療工作。|商人想用一箱不明瓶子履行醫療採買。|要求按品項與批次重列清單。|沒有具體來源與醫療條件，不承諾用途或收貨。
mechanical_parts|維修委託只有一張零件分類圖。|由設計者補出設備型號與實際缺件。|分類圖不轉成萬用修理材料，也不新增重複 item ID。|灰谷庫存報表把齒輪和軸承重複算進零件總箱。|保留分類統計但從可交易庫存去掉重複總項。|只有具體物件參與數量，分類摘要不可另當獎勵。
seeds|乾井有人想把一袋種子當作明年豐收保證。|先交給農務者核對品種並安排小範圍試種。|消耗試種份量且需時間、水和農務權限，不預定收成。|新希望借出種源時希望保留原產記錄。|接下送種工作並保護紙袋標籤。|破損或混種會破壞來源資訊，不能按重量補另一品種。
fuel|商隊裝錯品級，泵房拒絕把燃料倒進設備。|核對標記後改送給相容用戶。|繞送增加時間與運費，不能把不同燃料直接混用。|乾井停靠點只剩最後一份可供小型設備的燃料。|選擇留給自己的裝置或交給已確認用途的公共設備。|交付就失去這份燃料，不保證同時解決所有供能需求。
""")

add_text("""
scrap_iron|分出尖角的廢鐵束還能看出幾塊舊機殼。|以一千克已粗分選的鐵料計，沒有保證牌號。|可進一步分選供低要求工件使用，不等於精密零件或所有 scrap 資源。|8 Caps 以重、常見且仍需加工的材料定位。|灰谷有大量回收來源，運到別處前要確認買家接受的形狀和雜質。
steel_stock|幾根規格接近的鋼條綁成一份，切口可見。|一份一千五百克材料；尺寸與材質仍需核對。|可供製作合要求的坯料，完成零件還需要工序和設備。|24 Caps 比混雜廢鐵高，因較容易量測與安排加工。|工坊願為可靠規格付出較高估值，不能只換標籤把廢鐵變成鋼材。
aluminum_stock|輕色金屬板的邊角被折起，表面留有舊鉚孔。|一份八百克板料；材質和厚度需辨識。|適合需要輕量板件的提案，不保證可代替受力鋼件。|26 Caps 反映可用板面與較少攜行負擔，非強度排序。|運輸維修者在乎尺寸是否足夠，碎片和整片不能同價交付。
copper_wire|一小卷帶皮線材用紙帶標出拆卸來源。|三百克按線材連絕緣皮估算，長度與規格待核對。|測試後可用於相符電路連接；斷皮、細徑和不明接點都有限制。|20 Caps 來自可辨來源的線材，分離污染和測試要花工。|灰谷回收多，乾井泵站維護卻常缺能用的那一種線。
circuit_board|一塊舊控制板留有插頭座與局部褪色編號。|外觀看似完整，不代表仍可運作。|可對照型號後測試、維修或拆取部分元件；不通用於所有設備。|40 Caps 只是可識別板件的基準提議，未測試不保證功能價值。|收貨者可能需要的是某個接頭位置，而非整塊板子的泛用能力。
gear|齒輪邊緣有可比對的齒形，輪孔稍帶油痕。|一個四百五十克齒輪，模數與軸孔沒有預設通用。|只有匹配的傳動機構能使用；磨損齒面也需檢查。|18 Caps 取常見可量測機械件定位，加工相容性比稀有度重要。|灰谷的箱裡很多齒輪，但農務泵缺的可能是其中很特定的一個。
bearing|包油紙裡的軸承轉起來有輕微摩擦聲。|一個一百八十克的零件，不能只憑能轉就判良好。|量測尺寸與檢查狀況後，才可匹配特定車軸或設備。|22 Caps 反映運轉精度需求，失效件沒有同樣功能價值。|長途車隊願找可靠備件，來路不明的舊件只適合先測。
spring|一根彈簧被紙筒套住，末端彎鉤仍完整。|一根八十克零件；尺寸、回彈與用途需對照。|可恢復匹配的扣件或機構，不提供通用武器強化。|8 Caps 是小而常見的替換件估值，匹配錯誤會失去用途。|門扣、工具盒和設備機構需要不同彈簧，不把所有形狀視作同一配方材料。
rubber|捲成小片的橡膠有切割記號，表面沒有大裂口。|四百克按片料計，耐油耐熱能力尚未確認。|經材質確認可裁切墊片或護套；飲水與燃料用途不能隨意互換。|12 Caps 取常用密封材料尺度，來源和老化狀況會改變可用性。|乾井修泵看重相容性，新希望則在乎接水部位是否適用。
plastic|平整塑膠片還留著舊包材的壓印。|一份兩百五十克，未核驗材質的片料不當食物容器。|可用於不承力隔片或標籤罩，熱源與日晒仍可能限制用途。|6 Caps 因來源廣但適用工作窄，需按片面完整程度挑選。|它不必成為高級材料；便宜的防濺標示罩也能解決真實問題。
cloth|一卷未漂白布料的邊沿有裁縫留下的粉筆線。|五百克布料，不是無菌繃帶。|可裁補衣物、包裹貨物或縫成簡單部件，耗去的布不能同時交作原料。|10 Caps 取常見可加工材料定位。|新希望有小型紡織與修補來源，灰谷工人則常要替換磨破布件。
leather|鞣過的皮料摺起時較硬，邊角仍留著針孔。|一份六百克皮料，完整面積和厚度決定能裁什麼。|適合部分背帶、護套與包具修補，不能保證任何皮甲等級。|24 Caps 包含處理與可用面積的價值，並非生皮直接等價。|狩獵來源連到新希望的皮件工人，乾井車隊需要耐磨綁帶。
glass|一片玻璃用厚紙護住邊緣，能看見幾道細痕。|八百克以受保護的一片計，搬運時仍會破裂。|可裁配合尺寸的窗片或展示罩，不是光學鏡片的等價替代。|10 Caps 材料常見但完整運到買家手中有成本。|灰谷容易找到舊窗片，遠程運輸最難的是尺寸不變且不碎。
chemicals|有原標籤的工坊用料瓶，瓶口加了二次封套。|這份設計限已標示工坊用途的一瓶，不包攬所有化學品。|先辨識品項與相容工序，再供給受控作業；不與醫藥品互換。|35 Caps 為可追溯工坊用料的設計尺度，種類未定前不承諾通用售價。|正式落地前須拆出具體品項與包裝，不以「化學品」授權任意製造。
battery_cell|沒有完整外殼的電池芯，接點被分開包住。|一顆一百二十克待檢部件，不能直接當封裝電池使用。|經專業測試與保護封裝後才可能加入匹配電源組。|18 Caps 反映可回收的內部部件，轉成可用電源另有工序成本。|和電池的用途不同，撿到電池芯不會立即讓手電筒恢復供電。
precision_parts|小盒裡的細件各有對應格位，旁邊留著型號字條。|一盒一百五十克匹配細件，不是任意機器的萬用零件。|先核對型號與公差，才能用於指定儀器修復；遺失一件也可能失配。|75 Caps 來自成套精度與難補製，不能按金屬重量直換。|灰谷技工會先看規格，新希望與乾井通常只為明確設備委託採購。
""", """
scrap_iron|low|medium|可補簡單農具構件，長途搬運未必合算。|high|medium|回收多，需再分選才有用途。|medium|medium|車場有零散來源，也需替換支架材料。
steel_stock|low|medium|指定農具加工會採買合規板條。|high|high|工坊能加工，穩定規格仍有需求。|low|high|車架與泵房構件希望用可靠坯料。
aluminum_stock|low|low|不是所有農具都需要輕金屬。|medium|medium|運輸廢料可回收，完整片面較少。|low|high|長途車體和可攜箱具想降低重量。
copper_wire|low|medium|水泵與簡單電器修理會採買。|high|high|拆解來源多，同時有大量配線工作。|low|high|泵站和中繼設備難取得相容線材。
circuit_board|none|medium|只有設備型號相符時有明確需求。|medium|high|回收與檢測條件集中。|low|high|控制設備故障時急需可匹配板件。
gear|low|medium|農具傳動有指定規格需求。|high|medium|拆機來源多但仍須挑規格。|medium|high|泵與車輛傳動要維護。
bearing|low|medium|農車與泵體要備合尺寸件。|medium|high|加工和拆解都會用到可靠軸承。|low|high|長途車隊難在途中補到匹配件。
spring|medium|low|日用扣件可拆取，需求零散。|high|medium|細機構維修常用。|low|medium|貨車門扣與箱扣需合規替換件。
rubber|low|medium|接水與農具修補需合用途材料。|high|medium|廢車和工業庫存有來源。|low|high|燃料接點需要已確認相容的密封料。
plastic|medium|low|舊包材常見，普通修補需求小。|high|medium|分選後可做保護與隔片。|medium|medium|路牌和貨單防濺需要便宜材料。
cloth|high|medium|有修補與家庭加工來源。|medium|high|工衣和擦拭耗材需求多。|low|high|商隊篷布與包袋磨損補料難。
leather|medium|medium|獵人與皮件工人形成小規模來源。|low|medium|工具護套與腰帶需要。|low|high|綁帶和行囊耐磨部位常要修補。
glass|medium|low|家屋窗片有零星來源。|high|medium|舊建築回收多，完整片仍需挑選。|low|medium|泵房窗與標示罩有需求，但運輸易損。
chemicals|low|medium|只有已辨明用途的工坊批次才收。|medium|high|加工業需要，標籤與相容性很重要。|low|medium|設備服務提出指定工序用料需求。
battery_cell|none|low|缺少封裝檢測工位，不適合普通商店大量收。|medium|high|電源維修工坊有專門需求。|low|medium|通訊電源重整時委託採購。
precision_parts|none|medium|指定水務儀器修復才會下單。|low|high|技工能辨規格但很難補製成套細件。|none|high|泵站儀表失效時可能急需對應套件。
""", """
scrap_iron|灰谷收貨場把尖銳混料也標成可加工鐵。|先分選可用料再交付，留下雜物清單。|分選耗時且有廢棄量，不保證原重量全部合格。|小橋的路牌支架折了一截。|提供尺寸合適的鐵片讓工匠加工。|需要工具與固定方案，不能拿任意鐵塊直接完成修復。
steel_stock|新希望的農具工匠缺一段可靠坯料。|按他畫的尺寸選料送達。|不合尺寸便退回，運費與重量仍已付出。|乾井工班爭論用便宜混料還是規格鋼條。|提出鋼材供應和較長運送時間的方案。|較可靠材料仍需加工，不保證工程永不失效。
aluminum_stock|商隊的空箱很重，想換一塊非承力蓋板。|提供足夠面積的鋁片給工匠製作。|需確認用途，不可代替車架受力件。|灰谷回收者把鋁片混進普通廢鐵。|辨明材質後分開交付給對應買家。|鑑別和分選耗時，沒有證據不能自行升價。
copper_wire|中繼棚的短線被人拆走。|提供規格相符的線材給技工補接。|需要斷電與測試；銅線會成為設備一部分。|村民想出售一卷來路不明的線。|要求保留來源並檢查斷皮，再決定收多少。|不能把可疑線材直接認定為安全或合法取得。
circuit_board|舊水泵控制箱只有部分型號可讀。|用板上標號比對資料，決定是否值得測試。|不同型號不能硬換，試驗可能只排除相容性。|技工願意收壞板拆件，研究者想保留電路布局。|選擇整板保存或授權拆件。|拆解會失去原布局，不能同時保留完整板和全部零件。
gear|手搖捲揚機的齒面缺了一角。|用帶來的齒輪比對齒形與軸孔。|不匹配便無替換方案，仍需修理者確認安裝。|灰谷商人提供一箱齒輪卻不讓量尺寸。|要求量測後才接指定件的運送。|查驗會耽誤裝車，不接受就只能放棄此批。
bearing|運貨車輪發出規律摩擦聲。|提供匹配軸承給修理者查驗，安排替換。|先判斷問題來源；有備件不等於所有摩擦都因此消失。|商人把生鏽件擦亮混入新貨。|分開測試與記錄狀態後議價。|簡單測試不能保證長期壽命，未知狀態需明示。
spring|驛站的帳本櫃扣不上，管理者怕風吹散紙張。|找匹配彈簧交給維修者恢復扣件。|規格錯誤會卡住機構，不能只按重量替代。|收藏者想保留完整老機構，買家卻只要裡面的彈簧。|先協商是否拆件或維持原物。|拆出便失去原機構完整性，兩個價值不能同時兌現。
rubber|水壺蓋墊片硬化，使用者想拿任何膠片來補。|先核對材料是否適合接觸飲水，再裁片。|未知膠料不能直接使用，裁切消耗材料。|乾井油管接頭滲漏，工班缺相容墊片。|把已辨識橡膠交給技工製作合尺寸件。|需要停機、材料相容性和測試，不保證一次修好。
plastic|路線告示被雨打濕，字跡每次都要重寫。|用透明片料做可替換的防濺罩。|要有固定方式，長期日晒仍可能變脆。|工匠要給鬆動箱蓋做一片不承力隔片。|裁出符合尺寸的塑膠片供試配。|不可當耐熱或高負載構件，裁剩邊角沒有完整原料價值。
cloth|商隊的糧袋邊縫破了，還沒漏出太多內容。|提供布料給裁縫補強破邊。|消耗裁片與時間，不能順便增加袋子容量。|診所有人想把新布直接當無菌敷料。|改交作清潔包裹或非醫療修補，另找正式敷料。|拒絕混用途，布料不因潔白就得到醫療效果。
leather|舊旅行包的肩帶斷在縫線旁。|用皮料裁一段合適背帶補強。|需技術與縫合工具；修好不增加背包原本承載能力。|乾井收貨者只要能裁長帶的整片。|攤開皮料讓對方確認可用範圍。|孔洞與裂口會降低可交付面積，不能按總重湊數。
glass|泵房窗口破了，風沙一直進到帳本桌上。|交付完整玻璃給工匠裁配。|需要尺寸、框架與運送保護；破片不算完成交付。|研究者想把潮濕文件先保護起來。|提供玻璃作展示罩的一部分。|需其他支撐和處理，不能把文件夾住就聲稱完成保存。
chemicals|工坊有一瓶原標籤用料，卻找不到對應工序。|先核對標示與設備記錄，選擇保留或交專人。|未知用途不得當作任意清潔或醫療用品。|商隊想把不同來源瓶子混裝成便宜整箱。|按標籤與相容性分批交接。|需要知識與隔離搬運，不能為了折價忽略混裝風險。
battery_cell|灰谷電源工坊收一批沒有外殼的電池芯。|以分開保護的方式送交測試。|需避免接點相碰，合格與否由測試決定。|旅人想直接把裸芯接進手電筒。|改委託工坊檢驗並製作相容封裝。|耗工耗材，不能當場免費升級為完整電池。
precision_parts|乾井泵站缺一個規格明確的儀表機構。|比對盒內細件與型號紙條，再安排維修。|缺一件或公差不符便不能完成組裝。|灰谷回收者想把細件按金屬重量散賣。|保留成套格位和標記，尋找真正的使用者。|佔用資金與存放時間，不保證立刻找到高價買家。
""")

add_text("""
wrench|可調開口的扳手，握柄沾著擦不掉的機油。|保持 ITEM-1 的七百克；開口範圍尚需和目標比對。|可轉動合適尺寸的緊固件，不自帶撬開所有鎖或修好整台機器的能力。|25 Caps 反映灰谷易維護的普通手工具，遠地需求來自用途而非稀有度。|乾井的泵房願意借用合尺寸扳手，新希望也會用於農具保養。
screwdriver|平整尖端與握柄間有一道更換過的固定環。|尖端形狀可見；與螺絲不匹配時不能硬套。|可拆相符蓋板與調整螺絲；不兼作安全的帶電探針或重撬桿。|12 Caps 是容易攜帶和補充的入門工具價格提議。|工匠在乎尖端是否仍合尺寸，多把不同規格不等於同一萬用工具。
pliers|鉗口內側磨得光亮，握柄纏了一層舊布。|布纏握柄不代表具備絕緣認證。|可夾持細件和處理合適金屬絲；對帶電、厚硬物仍有明確限制。|18 Caps 因常用且可維護，價值來自穩定夾持而非戰力。|失去插銷的農車與鬆開的線頭需要它做不同的工作。
toolbox|沉重盒子裡按空槽收著一組常用機械工具。|四千五百克按整套估算，並不生成每個工具的獨立副本。|清點後可支援一般機械維護，精密電子與醫療用途仍需專門設備。|95 Caps 包括完整套組與收納，攜行成本比單帶扳手高。|工班可能選擇租整套而非購買，每次借還都應清點。
welding_tools|可攜工具架固定著面罩、夾具與焊接裝置。|工具架不包含無限能源和焊接材料。|需確認材料、供能與操作場所；能連接金屬不代表可修任何容器。|220 Caps 因設備與配套稀少，使用前還有供能和技術成本。|灰谷有適用工位，乾井可能只缺一次帶設備的維修服務。
multimeter|小盒上的指針與兩支探棒仍能辨清刻度。|量程、探棒與供電狀況需要核對。|可提供電路測量證據，不會直接指出所有故障或自動修理。|85 Caps 取可靠測量工具的定位，校驗與知識都影響用途。|舊設備標記不全時，測量紀錄比單純帶回零件更有價值。
hand_crank_generator|折疊搖把連著小型機構，輸出端貼著規格紙。|供電相容性與輸出能力未核對前，不視作萬用電源。|可在合適條件下提供短時人工供電，持續使用佔用人力。|110 Caps 交換的是離網備援能力，不是免費無限電力。|通訊站可能願意借用測試，但不會靠這一台恢復整座聚落供電。
jack|低矮的金屬頂座上刻著磨損的承載標記。|六千克的重工具；承載限制和支撐地面都要確認。|可抬起符合條件的車軸或構件，不能代替固定支撐與安全判斷。|90 Caps 取救急用途，沉重使帶它上路本身就是選擇。|乾井車隊需要時很急，平時卻不一定每個旅人都願意背。
metal_detector|細長探桿末端繞著線圈，控制盒保留手寫刻線。|它找的是金屬訊號，不是寶物名稱或埋藏物安全性。|經供電與校驗後可縮小搜尋區，雜鐵和地形仍會干擾。|150 Caps 來自專門探查用途；不保證發現高價物。|灰谷廢料密集處反而可能難用，在較乾淨土層才能問清楚特定問題。
binoculars|雙筒鏡的一側罩蓋用細繩繫住，鏡面有輕微刮痕。|能看遠不代表能看穿遮蔽物或辨認每個人的意圖。|良好視線下可讀標記與觀察路況，得到的是有限可見資訊。|65 Caps 反映鏡片完整度和節省接近風險的用途。|巡路者喜歡它，商隊則重視能否辨清遠方約定標誌。
compass|盒蓋內有方向刻線，磁針停下後仍輕微晃動。|附近金屬與異常磁場可能使讀數失真。|需先核對環境與參考方向，才可用來維持方位；不能生成地圖。|35 Caps 以無需電源的導航工具估價，前提是可靠讀數。|乾井路線缺少地標時有用途，灰谷金屬設施旁需要交叉核對。
old_world_map|摺痕把舊路網分成幾塊，角落保留測繪日期。|記錄的是舊世界，不保證橋、道路與地名仍有效。|與現地標記或其他記錄比對後，可提出路線與入口線索。|45 Caps 是可讀地圖的設計估價，真正用途取決於覆蓋位置。|新加註的路況能比原印刷圖更實用，改寫也可能破壞歷史證據。
radio|手持無線電的旋鈕有磨損，側面標著值班頻段。|需要相容電池；聽到聲音不等於對方身份已確認。|可在訊號條件允許時通話或中繼，仍需共同頻段與約定。|95 Caps 包括可用通訊機構，範圍與電源限制不能忽略。|舊值班頻段可能已換人使用，不能憑一聲回應就綁定某個 NPC。
signal_receiver|帶刻度的接收器連著可折天線，沒有發話按鍵。|它擅長接收與比對訊號，不等於雙向無線電。|可記錄頻段與方向變化，來源判斷還要位置和技術交叉驗證。|180 Caps 取專門測量與稀少零件定位，而非保證發現秘密。|舊廣播、故障設備和未知現象都可能發聲，不能只剩一種寶箱用途。
lockpick_set|細工具收在皮套裡，各自有不同彎曲形狀。|只針對合適的機械鎖；電子門和焊死的蓋板另有條件。|先檢查鎖型與所有權，再提出操作方案；失敗可能損壞工具或留下痕跡。|65 Caps 來自精細形狀與難以隨地補造，並非保證開鎖成功。|灰谷鎖匠會要來源證明，拿著工具不代表有權打開別人的箱子。
""", """
wrench|medium|medium|農具與水泵需要，較少現地製造。|high|medium|工業來源多，常見規格易補貨。|low|high|燃料泵與貨車接頭需要合尺寸工具。
screwdriver|medium|medium|家用設備維護需求分散。|high|high|工地與電子修理都使用，規格需要分清。|low|medium|泵站護蓋要維護，從商隊補充。
pliers|medium|medium|農務固定與小零件維護有需求。|high|high|線材和插銷工作常見。|low|high|車隊現場拆裝需要可攜夾持工具。
toolbox|low|medium|農忙時租用整套較合算。|high|high|工班可備齊也會消耗或遺失工具。|low|high|長途車隊希望帶完整維修套件。
welding_tools|none|medium|少數大型農具修理要外請設備。|medium|high|有操作工位與配套供應。|low|high|車架與容器維修需求高，但作業場所受油氣限制。
multimeter|low|medium|供水設備控制箱需要檢測。|medium|high|電器多且有能讀數的技工。|low|high|泵站診斷常缺可靠儀表。
hand_crank_generator|low|medium|巡水隊可借用作臨時通訊供電。|medium|medium|能修小機構，但不取代固定供電。|low|high|遠程停靠點想要備援通訊電源。
jack|low|medium|農車故障時有需求，平時少備。|high|medium|車輛拆解來源多。|medium|high|運油貨車常需道路救援。
metal_detector|none|medium|可找埋入田間的金屬，但要有人解讀。|low|medium|有維護條件，廢料多也會造成干擾。|none|medium|荒地勘查隊偶爾提出指定委託。
binoculars|low|medium|巡田與觀察遠處水路有用途。|low|medium|外勤者要看遠方建築與標誌。|medium|high|商隊在開闊地追認停靠與同行訊號。
compass|medium|medium|採集者離開熟路才常用。|medium|medium|供應來自舊貨，金屬干擾區要檢驗。|low|high|沙地少地標，可靠方位資訊有價值。
old_world_map|low|medium|舊灌溉路網可能提供線索。|medium|high|舊工業道路和管線入口待比對。|low|high|油運路線的舊橋與便道資訊有用。
radio|medium|medium|取水站與外勤隊有聯絡需求。|medium|high|維修工班和商隊都需通訊。|low|high|停靠點距離長，補機仍靠外來貨。
signal_receiver|none|low|偶爾調查水泵控制訊號，不常備專機。|low|high|舊工業通訊設施有調查需求。|none|medium|遠征隊追查中繼訊號時會委託。
lockpick_set|low|low|鎖匠有合理用途，普通商店不囤。|medium|medium|舊機械鎖多，合法回收與維修可用。|low|medium|貨運封箱與失鑰情況需要專門服務。
""", """
wrench|農務水管接頭鬆動，卻找不到合尺寸工具。|比對開口後借出扳手給修理者處理接頭。|需要合尺寸與修理判定，不因持有就修好整段供水。|乾井買家一次要十把扳手。|先確認規格與收貨數量，再接分批交運。|搬運佔重量，供貨不足或規格錯誤便不能完成整單。
screwdriver|舊收音機的蓋板擋住型號牌。|用匹配尖端卸開蓋板以讀取型號。|先確認安全斷電；拆蓋不等於電子故障已修復。|新希望工人把螺絲起子拿來撬粗木箱。|借工具前改找正確開箱方式，保留尖端完整。|不能把細工具當重撬桿，拒借可能延誤搬運。
pliers|貨車插銷彎了，手指夾不到。|用鉗子取出可接近的插銷讓工人檢查。|先固定構件，鉗子不能承受整台車的重量。|線頭垂在泵房門口，沒人知道是否通電。|等技工確認斷電後才夾持整理。|需要檢驗與技術，不靠布纏握柄保證安全。
toolbox|村民想修農具，借來的工具卻缺了兩個規格。|清點自己的整套工具，決定能否承接這份維護。|重工具箱要搬到現場；超出套組能力的工作仍拒絕。|商隊分成兩隊，各想帶走唯一工具箱。|約定先修最急的車，再決定由哪隊保管。|另一隊暫無整套支援，不能複製工具滿足兩邊。
welding_tools|橋邊護欄的金屬框斷開，旁邊仍有行人通過。|提出封閉小段通路後由合格工人焊接的方案。|需要供能、材料和安全工位；阻路會延誤通行。|乾井有人要求在油罐旁就地修補。|把器材帶到合適工位，要求先處理危險條件。|搬運和停工耗時，工具不授權高風險現場直接開工。
multimeter|兩顆外觀相同的電池讓收貨者爭執。|用合適量程做比對，記錄可觀察差異。|測量不是完整壽命保證，也需要操作知識。|發電機停了，有人想直接換掉控制板。|先量測指定測試點，縮小故障範圍。|需要安全斷電與設備資料，不能只靠一次讀數診斷全部。
hand_crank_generator|中繼站只需要短時供電發出到站通知。|確認接口後由一人搖動供電，另一人操作通訊。|佔用人力和時間；沒有匹配接口便不可接入。|修理者想知道舊訊號燈是壞了還是沒電。|借發電機提供有限試驗電源。|輸出不合時拒絕測試，不會憑試機恢復全區供電。
jack|貨車輪陷進淺坑，司機想徒手抬軸。|核對頂點與地面，提出抬起一側的救援方案。|需要支撐和助手，鬆土或超載時不可用。|工地木架壓住了一只私人物件盒。|由懂結構的人判斷能否用千斤頂留出取物空間。|重物移動可能破壞支架；工具不免除結構檢查。
metal_detector|農田邊有一小段地每次耕作都撞上硬物。|用探測器縮小可能的金屬範圍，再標記給地主。|消耗能源，訊號不保證是可挖的安全廢鐵。|旅人遺失的金屬扣混在廢料坡。|先圈出較小搜尋區逐段比對。|廢鐵干擾多，需要時間，不能直接定位任意寶物。
binoculars|遠處商隊旗幟看似熟悉，但路線不對。|隔著安全距離觀察旗號與車隊配置。|只得到可見資訊，仍不能斷言敵意或真實身份。|舊橋另一頭的警示牌被水面反光遮住。|等光線合適時用望遠鏡辨讀。|花等待時間，視線受阻便沒有可靠讀取結果。
compass|砂地上舊路標倒了，兩名帶路者方向相反。|離開明顯干擾物後比對方位與已有路線記錄。|方位不等於目的地座標，仍可能需要繞行。|廢機械旁的磁針一直偏轉。|把異常讀數記下，改用可見地標核對。|不把錯讀當成新道路，也不自動識別奇物來源。
old_world_map|圖上的橋在現地只剩橋墩。|標註斷點，尋找可驗證的其他通路線索。|地圖不生成新路，調查可能只確認此路不可通。|灰谷技工想借圖找出舊維修入口。|允許抄錄相關區段而保留原件。|抄錄花時間，缺比例或已改建的區域仍不可靠。
radio|兩支商隊在視線外互相等待，無法確認誰已出發。|使用約定頻段核對口令並轉達各自位置。|需要電量與可用訊號，不能自動知道另一隊位置。|舊頻道傳來熟悉值班號，聲音卻不同。|先詢問可交叉核對的資訊，決定是否回應求援。|回話會暴露有人收聽，沒有身份驗證不能直接增加信任。
signal_receiver|每天傍晚都能在同一段路聽見短促雜訊。|記錄不同位置的接收變化，找出值得調查的方向。|耗電和時間，方向只是線索而非確切入口。|技工懷疑停機與附近設備訊號相互干擾。|在約定測試時段記錄頻段，交給技工比對。|需要雙方協作，接收器不會自行修正干擾來源。
lockpick_set|回收隊找到一只刻有私人姓名的鎖箱。|先尋找所有者或授權，再嘗試合適機械鎖。|工具不能取代所有權，未獲同意會有關係後果。|驛站鑰匙斷在儲物櫃裡，管理者等著取帳本。|檢查鎖型並提出非破壞開啟方案。|需技能、時間和工具狀況；焊死或電子鎖不適用。
""")

add_text("""
clean_water|封口袋裡的清水，外側繫著取水站的批次繩。|一份以含包材約一千一百克估重；透明不等於已檢驗。|來源與封口均核對後，可列作旅行飲水候選；不直接增加現有 water 資源。|12 Caps 以普通旅途補給作尺度，支付的是取水、檢驗與封裝。|新希望的取水站有固定接水時段，商隊帶來的水也要保留批次資訊。
dirty_water|瓶底沉著細灰，搖晃後整瓶變成褐色。|這是一份待處理水樣，不是可直接飲用的補給。|可觀察沉澱與來源；是否可處理仍須檢驗，濾清不能證明安全。|2 Caps 只代表取樣與搬運價值，不按飲水售價估算。|溪流上游的修路和聚落排水都可能改變水樣；來源須由事件事實決定。
water|扁平水壺的背帶被反覆縫過，內壁能透過壺口檢查。|重量是空壺，不包含任何水。|壺口、內壁與密封檢查合格後才可裝飲水；用途由裝載內容決定。|18 Caps 主要來自可重複使用的密封與攜行便利。|水壺圖沿用早期水資源圖，內容設計仍將空容器與淨水分開。
purification_tablets|一板獨立封裝的小錠劑，背面留有褪色批號。|單位是一板；包裝完整也不能證明適用所有水源。|核對標示與適用污染類型後，才列入有限次的處理方案。|32 Caps 反映輕便、難補充與來源可信度；不是無限淨水權。|商隊只替有批次紀錄的貨物背書，散裝無標示品不能混作同一批。
water_filter|可拆開的濾筒帶著手壓泵，側面留有清潔記號。|濾筒可拆檢，但外觀無法判定剩餘處理能力。|只能針對經確認適用的水源提出過濾方案；濾材和密封狀況都重要。|120 Caps 來自可維護的機構與攜行用途，仍要負擔替換濾材。|新希望有人會保養泵體；不代表當地能重製所有濾芯。
food|乾燥穀餅用油紙分成小包，方便在路邊分食。|一份四百克旅行乾糧；包裝破損要另行檢查。|批次合格後可作耐攜補給；分享會實際減少自己攜帶的份數。|12 Caps 與普通食物資源尺度接近，取方便攜帶的設計定位。|旅店把不同家庭做的乾糧分批記帳，不能把一包視作無限餐食。
jerky|煙燻肉條上仍繫著製作者用的細繩記號。|單位是兩百克一包，不保證受潮後仍可保存。|來源、氣味與封裝檢查後，可選作輕便肉食；鹹味不能代替飲水。|16 Caps 包含肉料與保存工序，單位較小而運送方便。|新希望的獵人偶爾供貨，獵獲不穩時不應固定無限上架。
canned_food|近期重封的食物罐上寫著裝罐日期。|單位是一罐；鼓脹、漏氣與日期必須分別檢查。|確認來源與罐況後才能列作食物；打開後不再保有原封裝條件。|18 Caps 包含封裝與較方便運輸的成本，不是永久不壞。|和舊世收藏罐頭分開：這類是日常供餐批次，關心內容多於商標。
wild_greens|一束仍帶泥的葉菜，根部用草莖鬆鬆束起。|以一小束計；相似外觀不等於同一植物。|辨識採集地與品種後，可交給廚房處理或保留作樣本。|4 Caps 反映近產地易得但運送時間敏感。|農夫熟悉的採集區也會受污染或採集壓力影響，不能只看地名判安全。
raw_meat|包在厚紙裡的生肉，切口還能看見來源章記。|以六百克包裝計；等待與高溫會影響可用狀態。|由來源及保存紀錄決定能否供餐，烹調或保存各有時間與耗材。|8 Caps 低於成品肉乾，因需處理且不適合長途無照料搬運。|獵人可能願意換鹽或運送服務，並非每次帶回城都有人立即收購。
salt|粗粒鹽放在厚紙袋裡，袋口有結晶痕。|一袋兩百五十克；工業鹽與食用批次需辨清。|已辨明用途的鹽可入廚房或保存工序；不能隨意把材料當藥物。|10 Caps 以小袋耐運商品估值，來源與用途確認影響是否有人收。|乾井附近鹽貨可隨燃料商隊流通，但農業聚落的保存需求另有季節。
matches|小紙盒裡的火柴用蠟紙隔著潮氣。|單位是一盒；受潮與盒側磨損都可能讓它失去用途。|可提供有限次點火嘗試，仍需要適合燃物與允許生火的環境。|6 Caps 便宜且輕，價值在乾燥時可立即使用。|雨後驛站收購的是乾燥批次，不是圖示上看起來相同的所有盒子。
lighter|黃銅外殼的打火機，底部有可旋開的補充口。|目前是否有燃料需要檢查，不隨取得自動補滿。|可重複補充但需要相容燃料與完好的點火機構。|24 Caps 高於火柴，交換的是可維護性而非無耗材點火。|灰谷攤販可修外殼與機構，補充燃料仍有自己的來源。
fuel_can|空金屬罐散著舊燃料味，罐蓋帶有鎖扣。|九百克是空罐重量；不能直接視作一份燃料。|密封合格後可裝指定燃料，曾盛燃料的罐不轉作飲水壺。|26 Caps 來自耐搬運的罐體與封蓋，未包含燃料售價。|乾井會回收可用罐，灰谷可修罐體；兩地需求原因不同。
sleeping_bag|厚布睡袋的內襯被曬得發白，拉鍊仍能閉合。|一個完整睡袋，乾燥程度比外觀新舊更重要。|提供休息用的隔離層，但不能代替安全營地與遮雨處。|38 Caps 主要是填料、縫製與攜行成本。|旅人會借睡袋給傷疲者，也會約定交還地點；不是穿上即永久增益。
tent|捲起的篷布裹著短桿與地釘，袋口能清點配件。|一套可攜帳篷；缺桿或釘子時不能假定可搭起。|在合適地面和天候下可提供遮蔽；搭設位置仍須判斷。|75 Caps 包括成套支架與篷布，較重的運送負擔壓低通用性。|商隊租借帳篷會清點配件，惡劣天候並非所有帳篷都能承受。
rope|粗繩盤成一圈，繩端包著便於辨認的布條。|保持 ITEM-1 的二千五百克；沒有先假定長度或承重等級。|檢查磨損、長度與固定點後，才能選擇對應的牽引或固定方案。|30 Caps 反映多次使用的固定用途，但不保證可承受任何重量。|斷橋邊的繩索可能要留給後來者，救人和回收自用有不同代價。
flashlight|磨花的燈罩旁刻著前任使用者的值班號碼。|保持 ITEM-1 的四百克；電池存量另算。|裝入相容電池並確認燈泡後，才有可持續一段時間的照明方案。|35 Caps 來自可攜光源與外殼維護，不附贈能源。|灰谷工人偏好容易換電池的款式；遺跡燈具可能用不同接點。
battery|外殼印有規格的電池，兩端被紙套隔開。|一顆可更換電池；剩餘電量與接點相容性尚需檢查。|測試後才知道能支援哪些裝置；不代表任何電子用品都能插上使用。|12 Caps 以小型電源估價，電量未知時不能當足額新品交易。|和電池芯分開：這是可正常裝入相容設備的封裝電池。
oil_lamp|玻璃罩裡垂著燈芯，金屬提把被煙熏黑。|六百五十克按空燈估計，燈油不包含在內。|需要相容油料、燈芯和通風場所；明火也可能暴露營地。|24 Caps 取低技術可維護的照明定位，需攜帶額外燃料。|乾井泵站常見這種燈，不代表可在有油氣的場所安全點燃。
""", """
clean_water|high|medium|取水與封裝方便，但田間工班仍用水。|low|high|工地飲水多仰賴運入。|low|high|燃料產地仍需可靠飲水補給。
dirty_water|medium|low|水樣採集容易，只收有來源記錄的樣本。|medium|medium|排水檢查需要不同位置的樣本。|low|medium|井邊異常水樣有調查價值，不能當飲水補貨。
water|medium|medium|取水家庭會修用水壺。|medium|medium|工人和旅人都需密封容器。|low|high|長路攜水需求高，空壺仍須另找水源。
purification_tablets|low|medium|正常取水時需求有限，出行者備用。|low|high|工班離開供水點時需要備案。|low|high|長距離水源不確定，使可信批次吃緊。
water_filter|medium|medium|有人維護泵體，但替換濾材仍有限。|low|high|工地臨時供水需要可檢驗設備。|low|high|繞遠水路的商隊希望重複使用設備。
food|high|medium|農產可加工，居民和商隊都消費。|low|high|工人需要方便帶進工地的餐食。|low|high|油料商隊出發前大量準備旅行口糧。
jerky|medium|medium|獵人有不定期供貨，並非農產固定產量。|low|medium|值班工人接受耐攜肉食。|low|high|長途貨運偏好輕便補給。
canned_food|medium|medium|有少量近期封裝，但罐材要回收。|medium|high|金屬容器易得，內容仍靠食物來源。|low|high|封裝食物適合備在路線補給點。
wild_greens|high|medium|採集區近，廚房只收已辨識鮮貨。|low|medium|市場想添鮮食，長途貨容易失去價值。|low|low|長程運送不利於普通葉菜，適合就近採買。
raw_meat|medium|medium|獵人可短距離交貨。|low|medium|廚房可處理，前提是能及時送達。|low|low|沒有可靠保存時不積壓生鮮肉。
salt|low|high|保存收成和肉食時有需求。|medium|medium|商隊轉運，廚房與材料批次分開。|high|medium|鄰近鹽貨來源，仍要分辨用途。
matches|medium|medium|廚房與旅行者都要乾燥火種。|medium|medium|工棚可供應，潮濕貨不收。|low|high|野外停靠點缺乾燥補充品。
lighter|medium|medium|重用方便，但居民也有固定灶火。|high|medium|外殼維修和舊貨拆件較方便。|medium|high|能補相容燃料的旅人偏好重用器具。
fuel_can|medium|low|常用於外來機具燃料，不是主產貨。|high|medium|金屬加工可修罐蓋與焊縫。|high|high|燃料裝運周轉使空罐仍有需求。
sleeping_bag|medium|medium|裁縫可維修，外出工作者需要。|low|medium|夜班工棚與旅人採買。|medium|high|乾井是長途出行補給點。
tent|medium|medium|農務季外勤可租借使用。|low|medium|臨時工地想要遮蔽卻難備齊支架。|medium|high|商隊停靠時間不固定，完整帳篷有需求。
rope|medium|medium|農務搬運會綁束物資。|high|medium|工地有舊繩供應，但承載狀況需查。|medium|high|長途貨箱固定與道路救援需求多。
flashlight|medium|medium|夜間巡水需要可攜光源。|high|high|工地常用，替換零件也較容易找。|low|high|夜間卸貨與泵房檢查依賴照明。
battery|low|medium|巡水燈具需可靠電源。|medium|high|電子與照明設備密集，供需同時存在。|low|high|長途通訊裝置很難沿路補充。
oil_lamp|medium|medium|灶棚與停電時可用。|medium|medium|工地有照明需求，但油氣區限制使用。|high|medium|可維護燈體常見，相容油料另取。
""", """
clean_water|驛站搬水工要留下最後一袋水照顧遲到的人。|把自己一袋淨水交給驛站，讓工人能先回家。|實際交付一袋，自己下一段路的備用量降低。|運水商隊的封條有兩種顏色，收貨人拒絕混批。|出示取水批次，將自己的袋水列入可核對的一批。|核對需花時間；沒有來源記錄便不能取得認證。
dirty_water|灰谷排水渠與上游溪流顏色不同。|分別帶來源清楚的水樣交給檢查者比較。|需保留取樣位置；一瓶混水無法回答源頭在哪。|旅人想把桶裡的灰水當晚餐用水。|保留污水供處理評估，改請旅人先找可靠水源。|不保證能處理成功，也不把外觀澄清當作飲用許可。
water|臨時取水點沒有可帶走的容器。|用空水壺接取經確認可飲的水。|要先清潔並核對壺況，裝水增加的重量另計。|一名信使的水壺蓋掉進井裡。|把空壺借給信使，約好在下一個聚落交還。|借出期間失去這個容器；能否交還需要後續人物狀態。
purification_tablets|繞路後只能找到用途待確認的取水點。|請懂處理的人核對水源與錠劑標示，再決定是否處理。|處理會消耗錠劑；不適用的污染不能靠多放幾錠解決。|外勤工隊要求補一批有完整批號的錠劑。|交付封裝完整的補給，保留批次去向記錄。|失去所交份數；破封或批號不清的貨不能充數。
water_filter|舊驛站的沉水桶讓旅人排了長隊。|提供可檢查的濾水器，協助評估一條處理方案。|需合適水源與濾材；使用時間擠占出發時間。|新希望的濾筒保養者想借一台不同接頭的泵。|借出設備讓對方比對規格，換取泵體檢查記錄。|只比對機構，不自動補滿濾芯或改善全城供水。
food|旅人為等同行者錯過了晚餐供應。|分出一份乾糧，讓對方不必立即離開尋食。|消耗一份；對方不保證給回更值錢的東西。|灰谷工班午餐車卡在路上。|用易分配的乾糧先完成小批交貨。|交貨份數有限，不能因此宣稱整個工地已免於飢餓。
jerky|獵人不想讓陌生人碰剛切好的肉。|拿可辨認製作者的肉乾作交換物，談一段帶路服務。|對方仍可拒絕；沒有信任便不能強制成交。|貨隊希望夜間少升一次火。|留下肉乾作不需現場烹調的晚餐候選。|仍需檢查可食狀態，也不能省掉飲水需求。
canned_food|商隊載著兩罐凹痕明顯的食物，想混進捐贈貨。|把可驗證罐況的食物分開列單，拒絕拿壞罐補數。|檢查耗時，不會自動修復破壞的封口。|守夜人想保留一份食物等明天換班。|交付一罐合格食物，讓對方自行決定何時開封。|實際交出整罐；不能同時保留為自己的供餐份數。
wild_greens|採集者帶回兩種長得相似的葉菜。|用已辨識的樣本比對採集範圍並做標記。|不能只憑樣本認證整批，未知部分要留下不用。|新希望廚房缺少當日配菜。|把新鮮且已辨識的野菜就近交給廚房。|需趁仍可用時交貨，不能無限跨城囤積。
raw_meat|獵人背不動全部獵獲，準備把餘肉留在路邊。|接下短程送往廚房的肉包。|必須安排及時處理；多拿會擠掉自己的補給空間。|商隊要在兩條不同長度的路線中選一條。|以生肉需要及時處理為條件，協商先走有廚房的停靠點。|較近廚房可能偏離原路，不保證交易利潤。
salt|肉販想在出車前處理一批肉，但保存材料用完。|交付已確認可食用的鹽作有限批次加工。|鹽會被消耗；保存仍需要工序，不能瞬間消除腐敗。|乾井貨商把食用與工業批次袋子放在一起。|要求分清標記後才接運其中一批。|清點會延遲裝車，不能按同一價格收下未知批次。
matches|雨後營地的引火盒全部濕掉。|拿出乾燥火柴協助點燃合適火種。|使用會消耗火柴；若無乾燃物，點火條件仍未滿足。|哨棚請求一盒備用火種，卻靠近燃料裝卸區。|把火柴封存交給管理者，改在指定安全區使用。|交付不等於允許任何地方點火，需遵守現場限制。
lighter|路旁有人有乾柴，卻一直點不著火。|借出經檢查有燃料的打火機。|需回收器具，燃料消耗不會免費恢復。|灰谷攤販想用一盒火柴換走壞打火機。|請他指出故障，決定交換或保留給修理者。|檢查只能提供資訊，不能憑對話直接修好。
fuel_can|乾井有一份燃料可帶走，卻沒有可運容器。|提供已驗證密封的空罐承裝。|燃料要另外支付或交付，容器容量也要確認。|灰谷收罐工拒絕有滲漏痕的貨。|將空罐交給工匠做密封檢查。|檢查可能判定不可用；無權自動修補或返還滿罐油。
sleeping_bag|疲倦旅人把披風鋪在濕地上準備睡。|借出乾睡袋並協助另找可休息地點。|借用期間自己少了休息用品，也不能消除營地危險。|睡袋內襯在過河後濕透。|選擇停靠曬乾而不是立刻繼續遠行。|花時間並尋找安全場所，不能按一下就得到完整休息效果。
tent|平地上風太強，商隊打算沿廢牆紮營。|用完整帳篷在確認安全的背風位置搭設。|搭設和收起耗時，牆體不穩時仍不可用。|農務隊想在遠田多留一天。|借出帳篷並清點支架地釘，約定回收。|自己失去當晚遮蔽用品；配件丟失需另外處理。
rope|貨箱固定帶斷裂，下一段路坡度很大。|用檢查過的繩索重新固定貨箱。|部分繩長會被佔用；固定不等於車體能承受所有重量。|橋下有一只工具袋卡在矮台上。|在確認固定點後用繩索吊回工具袋。|先確認距離與重量，若必須剪斷或留下繩段要明示失去部分物品。
flashlight|配電間的刻字躲在架子底部。|用手電筒照明讀取標記，決定是否值得繼續調查。|消耗相容電池電量；照明不等於具備修理技術。|夜間迎面商隊看不清路障後的人。|用燈光發出事先約定的停靠訊號。|必須已有共同訊號約定，亂閃可能被誤解。
battery|驛站的通訊機只剩很弱的指示燈。|提供規格與剩餘電量已確認的電池試機。|只有相容型號才可用；試機會消耗電量。|商人想把混裝舊電池當成新品賣。|要求逐批測試後只交易有證據的份數。|測試需要設備和時間，不能由標籤保證滿電。
oil_lamp|地下避雨點沒有電，但通風口仍暢通。|在確認無可燃氣體的區域架起油燈。|需要燈油與燈芯，明火會暴露位置。|乾井值班者把油燈掛在漏油泵旁。|借燈供安全位置照明，先搬離危險點。|不能用油燈替代所有檢查工具，也不能在油氣區點燃。
""")

add_text("""
bandage|紙封裡是一卷未開封敷料，封邊容易辨認。|一卷一次交付的醫療用品；普通布料不自動等同無菌敷料。|確認封裝後交由具處置能力者使用，實際效果等待傷勢規則。|8 Caps 讓它成為可負擔的基礎急救耗材，但仍要可靠供應。|巡路隊的求援常先缺敷料，捐贈用途要和自己的備用量分開。
disinfectant|棕色瓶上還能讀出用途與批號，瓶蓋沒有破損。|一瓶有標示的用品，不能只看顏色判斷內容。|核對品項與可用狀況後，可成為診所處置耗材，不直接治癒傷勢。|20 Caps 反映可靠標示與封裝成本，未知液體不照此估值。|診所會拒絕來源不明的補充瓶，工業化學品不能冒充這個品項。
painkillers|藥板外套有幾行已磨淡的字，仍保留品名。|一板藥品；能止痛不代表受傷部位已恢復。|應由醫療角色核對用途與狀況；內容設計不指定真實用藥方式。|22 Caps 以有來源的常備藥估值，非立即續戰的增益商品。|疲倦搬運工可能想掩蓋傷痛繼續工作，這會是協商休息的情境。
antibiotics|封存藥盒上有診所驗收的批次紙條。|一盒待核驗藥品，不是所有疾病的解方。|由醫療角色確認適用問題和有效狀況，交付不等於病人必然痊癒。|60 Caps 來自難以本地補產與可靠來源的稀缺性。|新希望與灰谷都有需要者，不能僅依誰出價高就假稱醫療需求已解決。
first_aid_kit|耐磨小包以分格收好未拆封的急救耗材。|保持 ITEM-1 的八百克；物品不因名為急救包就自帶補血指令。|可核對整包內容後交給能處置的人；一次使用哪些內容需未來規則。|55 Caps 為成套、易攜且可核對內容的準備成本。|商隊購買時重視清單是否完整，過去使用過的包不能冒充完整新包。
surgical_kit|捲式器械包裡的金屬工具按位置扣緊。|一套器械，不包含乾淨場所、耗材或醫師技術。|核對器械用途與狀況後可供診所使用，不能在任何路旁直接完成手術。|180 Caps 反映精度和完整性，不能按普通廢鐵秤價。|有器械的診所仍可能欠缺照明與後續照護，工具只是條件之一。
adrenaline|保護套裡是一支仍附標籤的緊急注射用品。|需辨明品項與存放狀況，不作自用加速道具。|交由醫療角色判斷用途；本設計不承諾復活、提速或忽略傷勢。|90 Caps 是可信緊急庫存的設計估值，非效果強弱排名。|保存與轉運紀錄決定收貨方是否接受，長途塞在熱貨車上不算合格交付。
anti_radiation_medicine|密封盒有舊設施的危害應變標記。|標記只說明原用途，不能證明現在仍可用。|由專業者確認後才可能納入危害應變；不能替代防護或清除所有污染。|100 Caps 反映來源受限與檢驗成本，價值不是通行禁區的保證。|附近遺跡的傳聞會推高求購意願，但需求傳聞仍要和實際危害分開。
antidote|小藥瓶標示著一種特定應變用途。|一瓶針對性用品，沒有通用解毒含義。|必須先辨識問題是否相符，錯配時即使有藥也不提供有效方案。|75 Caps 由可信來源和狹窄用途估值，不能按所有中毒共用定價。|研究者要的是完整標籤和相關樣本，旅人則容易誤以為它能治所有毒。
burn_ointment|扁管裝在小紙盒內，旁邊附著工地診所印記。|一份醫療用品，不能代替防火裝備。|確認可用後交由醫療角色處理燒傷照護；傷勢輕重仍需另外判斷。|28 Caps 反映工地常備需求，不提供固定回血量。|灰谷和乾井可能需求高，但原因分別來自熱工與燃料作業。
old_world_medical_case|硬殼箱封條仍在，外側清單只能讀出一半。|以封存整箱計；未開箱不能宣稱有完整藥物或器械。|可先核對清單與封條，再決定交付整箱或在合適場所清點。|240 Caps 是完整來源可驗證時的收藏／醫療設備提議價，內容未知須重估。|把箱子交給診所或保存封條交給研究者，是用途不同的交付。
unlabelled_medicine|細頸瓶裡的液體透著淡色，標籤只剩膠痕。|只能確認外觀，未知成分不開放試喝捷徑。|鑑定可得到成分或用途線索，也可能判定不可用；不預設增益。|沒有通用底價；只列願意接收封存樣本的研究者，鑑定前不當成有效藥。|來源位置比液體顏色重要，混進正常藥品會破壞追查鏈。
""", """
bandage|medium|medium|診所有基礎存量，農務受傷仍會消耗。|medium|high|工地常備需求較大。|low|high|巡路隊補貨依賴商隊。
disinfectant|low|medium|診所按來源收貨，不自製所有品項。|medium|high|工地診所多，可信醫用品仍有限。|low|high|燃料作業點需要可靠醫療備品。
painkillers|low|medium|診所少量儲備，按需發放。|low|high|工人求購多，但不能只靠藥物替代休養。|low|medium|商隊帶入，收貨方看重保存紀錄。
antibiotics|low|high|居民診所需要可信批次。|low|high|工傷照護與人口密集增加備貨需求。|low|high|遠離可靠醫療來源，供貨很少。
first_aid_kit|medium|medium|可由診所整理有限套數。|medium|high|外勤工隊出發前常補貨。|low|high|車隊長途旅行需要完整套件。
surgical_kit|none|medium|診所願意接收，不能穩定製造精密器械。|low|high|有精加工修復條件但缺完整醫療套件。|none|medium|偏遠處置點希望備有器械，仍缺完整醫療條件。
adrenaline|none|medium|只為診所保留緊急庫存。|low|medium|舊設施偶有封存貨，必須核驗。|none|medium|需求窄但補貨困難，不能當普通提神貨販售。
anti_radiation_medicine|none|low|沒有已確認危害時不囤大量專門品。|low|medium|調查舊設施者求購，仍需專業檢驗。|none|medium|遠征商隊可能提出專門委託。
antidote|none|medium|採集區問題需先辨識，診所不收未知配方。|low|medium|工業環境需要特定應變品，不接受通用宣稱。|none|medium|荒野隊伍希望備用，但要能對應已知風險。
burn_ointment|medium|low|日常診所少量存備。|medium|high|熱工車間有具體照護需求。|low|high|燃料裝卸區需要可核對的醫療供應。
old_world_medical_case|none|medium|診所重視可用內容，不能按封條推定完整。|low|high|遺跡回收偶有整箱，可安排檢驗。|none|medium|偏遠醫療點可能委託運送整箱。
unlabelled_medicine|none|low|診所拒作正常藥品，只可能協助轉交樣本。|low|medium|能接觸到調查設備的研究者願意評估。|none|low|普通商人不承擔未知液體風險。
""", """
bandage|搬運者的隨行醫護用完封裝敷料。|把一卷完整繃帶交給醫護。|實際失去一卷；是否能處置仍看傷勢與醫護能力。|診所收到混著普通碎布的援助包。|協助按封裝狀態分開可用敷料。|分類耗時，不能把碎布改名就變成醫療品。
disinfectant|灰谷臨時診所只剩幾瓶無標示液體。|交付有批號的消毒水，隔開未知液體。|交出一瓶；檢查與使用等待醫療權限。|乾井收貨者質疑瓶蓋曾經被開過。|允許核對封口和運送紀錄，接受拒收。|核驗不能恢復無法證明的保存歷史。
painkillers|工人想吃藥後帶傷完成最後一班。|將用品交給醫護評估，另談換班安排。|不直接消除傷勢；換班需雇主與工人同意。|村落有人拿空藥板索取同款補貨。|把標籤資料帶到診所詢問是否有相符庫存。|只取得資訊，不保證可供應或適合當事人。
antibiotics|兩個診所同時託商隊送同一盒藥。|要求先確認需求及分配權，再決定交付哪處。|交出後不能重複交另一方；不預設救治結果。|舊藥盒批號與交貨單不一致。|暫停交貨，追查正確批次。|會延誤委託，不能用高售價掩蓋來源不明。
first_aid_kit|倒車事故後有人呼叫具備醫療能力的旅人。|把完整急救包提供給合格處置者。|所用內容要記為消耗；持包不代表自己能處置。|商隊買到一包缺少封裝內容的急救包。|展開自己的清單協助比對並要求賣家說明。|只能辨明缺項，不能自動補成完整套件。
surgical_kit|聚落有醫師卻沒有匹配的器械。|借出整套器械，先清點交接。|仍需適當場所、耗材和處置權限；不能保證結果。|舊醫院器械上刻有庫存編號。|將整套交給診所辨認來源，保留編號記錄。|拆散售鐵會失去整套辨識價值，核對需時間。
adrenaline|急診補貨單要求緊急用品和保存紀錄一同到達。|接下封存運送，按原包裝交接。|路上不能擅自拆用；保存條件失證可能被拒收。|陌生人要求拿它交換一件高價武器。|選擇保留給已確認的診所委託，或取消委託後交易。|交易要承擔失去供應承諾的後果，不附帶服用增益。
anti_radiation_medicine|遠征者以為帶一盒藥就能進入危險區。|將藥品資料交給專業者，重新核對防護與撤退方案。|消耗諮詢時間，沒有防護時不能因此取得通行條件。|舊應變站的藥箱標籤已褪色。|帶回一盒作核驗，保留發現位置。|核驗可能判定不可用，不承諾恢復成有效藥品。
antidote|診所請人找回與一份樣本相符的應變藥。|攜帶有完整標示的解毒劑供核對。|不相符時不能消耗來換任意治療效果。|商人把幾種瓶子統稱萬用解毒藥。|要求按標示分清品項再談交易。|需辨識者協助；無證據的瓶子仍不能定用途。
burn_ointment|乾井小型事故後，診所請求補充照護耗材。|交付一份已核驗藥膏給診所。|實際交出用品，傷勢評估與效果不能由交貨文字代替。|灰谷工班打算用備藥為由省下防護準備。|保留備藥並指出缺少防護條件，改期處理熱工工作。|延誤會有工作成本；藥膏不使危險作業自動安全。
old_world_medical_case|封存醫療箱外的清單有一頁遺失。|保持封條帶回診所核對，或在有人見證下清點。|完整交付和開箱調查互斥；內含物未確認前無獎勵清單。|研究者重視箱上的編號，醫師更關心內容。|協商先記錄外觀，再交診所檢查。|需兩方同意與時間，不可同時賣出整箱兩次。
unlabelled_medicine|失去標籤的瓶子和日記片段放在同一抽屜。|把瓶子連同來源記錄交給研究者辨識。|消耗調查時間，結果可能只是排除用途。|旅人希望喝一口試試是否能提神。|封存瓶子，改找有標示的補給。|放棄當場試用；未知物不提供隨機永久能力獎勵。
""")

REPAIR = {
    "water": ("rubber", "僅提議更換已確認可接觸飲水的密封件；壺體破壞另行判廢。"),
    "water_filter": ("rubber,cloth", "只能維護泵體密封與外套；布料不是淨水濾芯，不恢復未知濾材能力。"),
    "lighter": ("spring,scrap_iron", "只處理匹配的小機構與外殼；加燃料是補充，不算免費修理。"),
    "fuel_can": ("rubber,steel_stock", "確認空罐已符合安全作業條件後，由工匠處理密封與罐體；不能保證所有罐可救。"),
    "sleeping_bag": ("cloth", "修補外布及縫線，濕透填料仍要處理；不增加保暖等級。"),
    "tent": ("cloth,rope,steel_stock", "只修補篷布與合規支架，材料尺寸及天候限制仍需核對。"),
    "rope": ("cloth", "僅修護繩端標記；承載纖維損壞不能靠包布恢復，應縮短用途或判廢。"),
    "flashlight": ("glass,copper_wire,spring", "依故障更換合規燈罩、線路或接點；沒有相容燈泡時不能保證修復。"),
    "oil_lamp": ("glass,cloth,scrap_iron", "玻璃罩、合適燈芯與支架可分別維護；不附帶燃料。"),
    "surgical_kit": ("precision_parts", "只允許專門維護者處理匹配器械部件；清潔與醫療可用性需獨立核驗。"),
    "old_world_medical_case": ("rubber,cloth", "只能修復箱體封套與內襯；不恢復過期或不明內容物。"),
    "wrench": ("steel_stock", "由工匠判斷是否可替換調整機構；已失準或開裂的受力部位可判廢。"),
    "screwdriver": ("steel_stock,plastic", "需匹配材料重整握柄或更換尖端，不把磨平工具直接宣稱已恢復。"),
    "pliers": ("steel_stock,spring", "只提議鉸接與匹配回位機構維護；不產生絕緣認證。"),
    "toolbox": ("cloth,steel_stock", "修收納盒與分隔；補齊遺失工具需另交實物，不能用原料自動生成整套。"),
    "welding_tools": ("copper_wire,rubber,precision_parts", "由專業者檢查供能、接點與工具結構；焊材能源另外消耗。"),
    "multimeter": ("copper_wire,precision_parts", "替換匹配探棒或部件後仍需校驗，不能把通電當作精度保證。"),
    "hand_crank_generator": ("gear,bearing,copper_wire", "只在零件規格匹配時維護傳動與線路；輸出測試不可省。"),
    "jack": ("steel_stock,gear", "受力件需專業檢查與匹配更換，無法驗證承載時保持不可用。"),
    "metal_detector": ("copper_wire,circuit_board", "對應型號才可更換線圈或控制板，修後要以已知物校驗。"),
    "binoculars": ("rubber,precision_parts", "只維護目罩與調焦機構；一般玻璃不能補成合格光學鏡片。"),
    "compass": ("glass,precision_parts", "只更換匹配罩片和機構，完成後仍要核對可靠方向。"),
    "radio": ("copper_wire,circuit_board", "匹配型號後修接點與線路，通訊測試需另一端配合。"),
    "signal_receiver": ("copper_wire,precision_parts,circuit_board", "需匹配測量部件並重新校驗，不把任意控制板視為替代。"),
    "lockpick_set": ("steel_stock,leather", "工匠可重整護套與特定形狀工具；折斷細件不保證可接回。"),
}
SALVAGE = {
    "water": ("scrap_iron", "金屬壺報廢後僅可能回收部分潔淨金屬，失去容器用途。"),
    "water_filter": ("plastic,scrap_iron", "只回收可分離外殼，污染濾材不當作淨水產品或完整材料返還。"),
    "lighter": ("spring,scrap_iron", "安全清空後可能留下少量可用機構；不等於足以重製完整打火機。"),
    "fuel_can": ("scrap_iron", "需先由合格作業者處理殘留物；金屬回收會破壞罐體。"),
    "sleeping_bag": ("cloth", "可裁取未污染外布，填料不保證可用；整個睡袋隨之失去完整性。"),
    "tent": ("cloth,scrap_iron", "部分布面和支架可回收，不返還完整帳篷或全部原料。"),
    "flashlight": ("copper_wire,spring,glass", "只提議回收仍完好的小件，拆解後不再保留完整光源。"),
    "oil_lamp": ("glass,scrap_iron", "清除殘留油料後才能回收未破罩片與金屬，舊燈芯不作潔淨布料。"),
    "surgical_kit": ("scrap_iron", "無法使用的金屬器械可作降級回收，需處理污染，失去醫療器械身份。"),
    "old_world_medical_case": ("plastic,scrap_iron", "只處理已清點的空箱外殼；箱內用品不從拆箱文字自動生成。"),
    "wrench": ("scrap_iron", "報廢金屬回收不保留精度，不能直接兌回完整扳手。"),
    "screwdriver": ("scrap_iron,plastic", "分離可用金屬與握柄材料，實際可回收量等待拆解規則。"),
    "pliers": ("scrap_iron,spring", "僅回收仍完好的回位件與金屬，拆後不能再使用整把鉗子。"),
    "toolbox": ("scrap_iron,cloth", "這裡只拆空的收納盒；套內工具需先清點移交，不複製成免費實物。"),
    "welding_tools": ("copper_wire,scrap_iron", "停用並確認供能安全後拆分可回收件，不能保留完整設備。"),
    "multimeter": ("copper_wire,plastic", "小線材與外殼可降級利用，儀表精度與整機身份消失。"),
    "hand_crank_generator": ("gear,bearing,copper_wire", "只可能留下部分完好件；沒有重製整機的可逆等量關係。"),
    "jack": ("scrap_iron", "報廢後只作金屬來源，不把受力件自動認證為別的承載工具。"),
    "metal_detector": ("copper_wire,plastic", "拆取部分線圈線材與外殼，偵測功能消失。"),
    "binoculars": ("glass,scrap_iron", "鏡片降級為一般材料用途，不保留光學精度承諾。"),
    "compass": ("glass,scrap_iron", "罩片與外殼可分離，磁針不自動生成另一只指南針。"),
    "radio": ("copper_wire,circuit_board", "只有匹配且完好的板件可保留作待測物，不能視為已修好的另一台機器。"),
    "signal_receiver": ("copper_wire,circuit_board", "保存部分待測板件會犧牲整機與校驗資訊。"),
    "lockpick_set": ("scrap_iron,leather", "細件報廢時只回收殘料，不將剪裁護套當完整新皮料。"),
    "steel_stock": ("scrap_iron", "切壞或失去規格的鋼料只降級成回收鐵，不能原樣等量升回鋼材。"),
    "circuit_board": ("copper_wire,plastic", "回收局部導線與外殼，破壞電路布局，不能返還完整板件。"),
    "gear": ("scrap_iron", "失準齒輪只能降級作金屬，齒形精度不能從回收描述中恢復。"),
    "bearing": ("scrap_iron", "磨損軸承分解後只保留可回收金屬，不獲得一批新軸承。"),
    "spring": ("scrap_iron", "報廢彈簧僅保留材料，不保留回彈性能。"),
    "precision_parts": ("scrap_iron", "拆散報廢套件可能回收少量金屬，成套匹配與標記價值消失。"),
}

def listing(value):
    return value.split(",") if value else []

def relation(table, key, output):
    if key not in table:
        note = "分類摘要沒有可修理或拆解的實體。" if META[key][4] == "category" else "本稿不設這項處理；使用、檢驗或交付不返還完整替代品。"
        return {"possible": False, output: [], "note_zh": note}
    ids, note = table[key]
    return {"possible": True, output: ["content_" + x for x in listing(ids)], "note_zh": note}

def main():
    keys = {s["content_id"].removeprefix("content_") for s in TARGET}
    for table in (META, PROSE, MARKETS, HOOKS):
        assert set(table) == keys, ("coverage", keys - table.keys(), table.keys() - keys)
    assert len(keys) == 75
    result = []
    for seed in TARGET:
        key = seed["content_id"].removeprefix("content_")
        category, subtype, grams, caps, rarity, tags, roles, actions, origins, loot, deps, refs = META[key]
        desc, known, identified, rationale, world = PROSE[key]
        market = MARKETS[key]
        hook = HOOKS[key]
        row = {k: seed[k] for k in ("content_id", "name_zh", "art_file", "art_sections", "art_role", "runtime_item_id")}
        row.update(status="DESIGN_ONLY", category=category, subtype=subtype,
                   proposed_weight_g=None if grams == "null" else int(grams),
                   proposed_base_value_caps=None if caps == "null" else int(caps),
                   value_rationale_zh=rationale, rarity=rarity, tags=listing(tags),
                   roles=listing(roles), actions=listing(actions), origin_tags=listing(origins),
                   loot_sources=listing(loot), description_zh=desc, known_description_zh=known,
                   identified_description_zh=identified, world_notes_zh=world,
                   markets={name: dict(zip(("supply", "demand", "reason_zh"), market[i*3:i*3+3]))
                            for i, name in enumerate(("new_hope", "gray_valley", "dry_well"))},
                   hooks=[dict(zip(("situation_zh", "use_zh", "cost_or_limit_zh"), hook[i*3:i*3+3])) for i in range(2)],
                   repair=relation(REPAIR, key, "inputs"), salvage=relation(SALVAGE, key, "outputs"),
                   dependencies=listing(deps), inspiration_refs=listing(refs))
        for mode, field in (("repair", "inputs"), ("salvage", "outputs")):
            assert set(row[mode][field]) <= ALL_IDS, (key, "unknown reference")
            assert row["content_id"] not in row[mode][field], (key, "self-producing relationship")
            if row[mode]["possible"] and mode not in row["dependencies"]:
                row["dependencies"].append("repair" if mode == "repair" else "disassembly")
        row["dependencies"] = sorted(set(row["dependencies"]))
        if seed["baseline_weight_g"] is not None:
            assert row["proposed_weight_g"] == seed["baseline_weight_g"]
        if seed["art_role"] == "category_illustration":
            assert row["proposed_weight_g"] is None and row["proposed_base_value_caps"] is None
            assert row["actions"] == [] and row["rarity"] == "category" and row["loot_sources"] == []
        result.append(row)
    output = ROOT / "items/02-supplies-materials-trade.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"records": len(result), "physical": 72, "category_only": 3,
                      "hooks": sum(len(r["hooks"]) for r in result), "status": "DESIGN_ONLY"}))

if __name__ == "__main__":
    main()
