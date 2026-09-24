# 關聯矩陣與覆蓋檢查

由 JSON 的實際引用生成；不是 185×480 的填滿格子，也不是玩法驗收。

quest_encounter 是編輯關聯，可表示同一工作、可選線索或情境改編；不是自動執行的任務步驟。是否共享實物與結算須讀該筆 followup，只有綁定同一次工作時才共用憑證。不同事實版本不得直接串接。

共有 2416 條語義連結；555 筆聚落供需提案；434 條材料關係。

## 物品 × 遭遇 × 任務 × 人物

| 物品 | 遭遇數 | 任務數 | 人物鉤子數 |
| --- | ---: | ---: | ---: |
| [腎上腺素](../catalogue/items.md#content_adrenaline) | 0 | 0 | 0 |
| [鋁材](../catalogue/items.md#content_aluminum_stock) | 1 | 0 | 1 |
| [彈藥帶](../catalogue/items.md#content_ammo_bandolier) | 1 | 0 | 0 |
| [彈藥](../catalogue/items.md#content_ammunition) | 0 | 0 | 0 |
| [抗輻射藥](../catalogue/items.md#content_anti_radiation_medicine) | 0 | 0 | 0 |
| [抗生素](../catalogue/items.md#content_antibiotics) | 0 | 0 | 0 |
| [解毒劑](../catalogue/items.md#content_antidote) | 0 | 0 | 0 |
| [軍用突擊步槍](../catalogue/items.md#content_assault_rifle) | 0 | 0 | 0 |
| [繃帶](../catalogue/items.md#content_bandage) | 2 | 0 | 1 |
| [電池](../catalogue/items.md#content_battery) | 4 | 1 | 5 |
| [電池芯](../catalogue/items.md#content_battery_cell) | 0 | 0 | 1 |
| [軸承](../catalogue/items.md#content_bearing) | 7 | 1 | 1 |
| [望遠鏡](../catalogue/items.md#content_binoculars) | 20 | 4 | 1 |
| [黑盒記憶體](../catalogue/items.md#content_black_box_memory) | 0 | 0 | 1 |
| [黑色水滴](../catalogue/items.md#content_black_water_drop) | 1 | 0 | 1 |
| [栓動步槍](../catalogue/items.md#content_bolt_action_rifle) | 0 | 0 | 0 |
| [燒傷藥膏](../catalogue/items.md#content_burn_ointment) | 0 | 0 | 0 |
| [相機](../catalogue/items.md#content_camera) | 5 | 0 | 5 |
| [罐頭](../catalogue/items.md#content_canned_food) | 3 | 1 | 3 |
| [車板刀](../catalogue/items.md#content_car_panel_cleaver) | 0 | 0 | 0 |
| [車板胸甲](../catalogue/items.md#content_car_panel_cuirass) | 1 | 0 | 2 |
| [商隊外套](../catalogue/items.md#content_caravan_coat) | 5 | 0 | 3 |
| [商隊槍](../catalogue/items.md#content_caravan_polearm) | 0 | 0 | 0 |
| [商隊步槍](../catalogue/items.md#content_caravan_rifle) | 1 | 0 | 0 |
| [商隊護衛槍](../catalogue/items.md#content_caravan_smg) | 0 | 0 | 0 |
| [化學品](../catalogue/items.md#content_chemicals) | 0 | 0 | 0 |
| [香菸](../catalogue/items.md#content_cigarettes) | 0 | 0 | 0 |
| [電路板](../catalogue/items.md#content_circuit_board) | 2 | 2 | 1 |
| [民用手槍](../catalogue/items.md#content_civilian_pistol) | 0 | 0 | 0 |
| [淨水](../catalogue/items.md#content_clean_water) | 8 | 1 | 2 |
| [布料](../catalogue/items.md#content_cloth) | 13 | 8 | 3 |
| [布袋](../catalogue/items.md#content_cloth_sack) | 25 | 14 | 6 |
| [咖啡](../catalogue/items.md#content_coffee) | 3 | 0 | 3 |
| [公司門禁卡](../catalogue/items.md#content_company_keycard) | 2 | 0 | 0 |
| [指南針](../catalogue/items.md#content_compass) | 13 | 2 | 3 |
| [銅線](../catalogue/items.md#content_copper_wire) | 8 | 2 | 3 |
| [撬棍](../catalogue/items.md#content_crowbar) | 8 | 5 | 1 |
| [資料磁碟](../catalogue/items.md#content_data_disk) | 1 | 0 | 2 |
| [沙地長袍](../catalogue/items.md#content_desert_robe) | 6 | 0 | 2 |
| [沙地彎刀](../catalogue/items.md#content_desert_sabre) | 0 | 0 | 0 |
| [污水](../catalogue/items.md#content_dirty_water) | 3 | 0 | 0 |
| [消毒水](../catalogue/items.md#content_disinfectant) | 0 | 0 | 0 |
| [雙管散彈槍](../catalogue/items.md#content_double_barrel_shotgun) | 0 | 0 | 0 |
| [沙塵面罩](../catalogue/items.md#content_dust_mask) | 5 | 1 | 2 |
| [工程護目鏡](../catalogue/items.md#content_engineering_goggles) | 11 | 1 | 3 |
| [工兵鏟](../catalogue/items.md#content_entrenching_shovel) | 3 | 2 | 3 |
| [農務服](../catalogue/items.md#content_farm_clothes) | 1 | 1 | 0 |
| [消防斧](../catalogue/items.md#content_fire_axe) | 0 | 0 | 0 |
| [防火服](../catalogue/items.md#content_firefighter_suit) | 1 | 0 | 0 |
| [急救包](../catalogue/items.md#content_first_aid_kit) | 5 | 0 | 4 |
| [火焰噴射器](../catalogue/items.md#content_flamethrower) | 0 | 0 | 0 |
| [信號槍](../catalogue/items.md#content_flare_pistol) | 0 | 0 | 0 |
| [手電筒](../catalogue/items.md#content_flashlight) | 15 | 3 | 5 |
| [乾糧](../catalogue/items.md#content_food) | 13 | 8 | 4 |
| [燃料](../catalogue/items.md#content_fuel) | 1 | 0 | 0 |
| [燃料罐](../catalogue/items.md#content_fuel_can) | 5 | 1 | 6 |
| [防毒面具](../catalogue/items.md#content_gas_mask) | 3 | 0 | 1 |
| [齒輪](../catalogue/items.md#content_gear) | 2 | 0 | 1 |
| [地質調查圖](../catalogue/items.md#content_geological_survey_map) | 2 | 0 | 4 |
| [玻璃](../catalogue/items.md#content_glass) | 5 | 0 | 1 |
| [灰種](../catalogue/items.md#content_gray_seed) | 5 | 0 | 3 |
| [榴彈發射器](../catalogue/items.md#content_grenade_launcher) | 0 | 0 | 0 |
| [手搖發電機](../catalogue/items.md#content_hand_crank_generator) | 2 | 0 | 0 |
| [防化服](../catalogue/items.md#content_hazmat_suit) | 1 | 0 | 0 |
| [熱核](../catalogue/items.md#content_heat_core) | 3 | 0 | 2 |
| [隔熱服](../catalogue/items.md#content_heat_insulation_suit) | 3 | 1 | 1 |
| [大口徑左輪](../catalogue/items.md#content_heavy_revolver) | 0 | 0 | 0 |
| [登山背包](../catalogue/items.md#content_hiking_backpack) | 3 | 0 | 1 |
| [空心石](../catalogue/items.md#content_hollow_stone) | 3 | 0 | 2 |
| [回家](../catalogue/items.md#content_homecoming) | 1 | 0 | 1 |
| [醫院識別卡](../catalogue/items.md#content_hospital_id_card) | 2 | 0 | 1 |
| [鳴石](../catalogue/items.md#content_humming_stone) | 4 | 0 | 3 |
| [捕獸叉](../catalogue/items.md#content_hunting_fork) | 2 | 0 | 0 |
| [獵刀](../catalogue/items.md#content_hunting_knife) | 8 | 2 | 3 |
| [身分證件](../catalogue/items.md#content_identity_document) | 2 | 0 | 4 |
| [土製手槍](../catalogue/items.md#content_improvised_pistol) | 0 | 0 | 0 |
| [工業釘槍](../catalogue/items.md#content_industrial_nailgun) | 1 | 0 | 1 |
| [千斤頂](../catalogue/items.md#content_jack) | 2 | 1 | 0 |
| [肉乾](../catalogue/items.md#content_jerky) | 2 | 0 | 2 |
| [最後一發](../catalogue/items.md#content_last_round) | 1 | 0 | 1 |
| [皮革](../catalogue/items.md#content_leather) | 10 | 1 | 2 |
| [輕機槍](../catalogue/items.md#content_light_machine_gun) | 0 | 0 | 0 |
| [打火機](../catalogue/items.md#content_lighter) | 0 | 0 | 1 |
| [酒](../catalogue/items.md#content_liquor) | 1 | 0 | 0 |
| [開鎖工具](../catalogue/items.md#content_lockpick_set) | 2 | 0 | 0 |
| [衝鋒手槍](../catalogue/items.md#content_machine_pistol) | 0 | 0 | 0 |
| [火柴](../catalogue/items.md#content_matches) | 0 | 0 | 0 |
| [機械零件](../catalogue/items.md#content_mechanical_parts) | 0 | 0 | 0 |
| [醫療手冊](../catalogue/items.md#content_medical_manual) | 3 | 2 | 4 |
| [醫療袋](../catalogue/items.md#content_medical_satchel) | 1 | 0 | 5 |
| [藥物](../catalogue/items.md#content_medicines) | 0 | 0 | 0 |
| [記憶核心](../catalogue/items.md#content_memory_core) | 1 | 0 | 2 |
| [金屬探測器](../catalogue/items.md#content_metal_detector) | 2 | 0 | 1 |
| [軍用背包](../catalogue/items.md#content_military_backpack) | 1 | 0 | 0 |
| [軍人識別牌](../catalogue/items.md#content_military_dog_tags) | 2 | 0 | 2 |
| [軍用手冊](../catalogue/items.md#content_military_manual) | 2 | 0 | 0 |
| [軍醫資料晶片](../catalogue/items.md#content_military_medical_chip) | 0 | 0 | 3 |
| [摩托夾克](../catalogue/items.md#content_motorcycle_jacket) | 2 | 1 | 0 |
| [萬用電表](../catalogue/items.md#content_multimeter) | 14 | 4 | 2 |
| [肌纖維刺激器](../catalogue/items.md#content_muscle_stimulator) | 0 | 0 | 0 |
| [音樂播放器](../catalogue/items.md#content_music_player) | 3 | 0 | 4 |
| [神經反射模組](../catalogue/items.md#content_neural_reflex_module) | 0 | 0 | 0 |
| [夜視鏡](../catalogue/items.md#content_night_vision_goggles) | 0 | 0 | 0 |
| [六十三號](../catalogue/items.md#content_number_sixty_three) | 1 | 0 | 2 |
| [油燈](../catalogue/items.md#content_oil_lamp) | 4 | 0 | 1 |
| [老獵人的槍](../catalogue/items.md#content_old_hunter_rifle) | 0 | 0 | 0 |
| [老照片](../catalogue/items.md#content_old_photograph) | 2 | 0 | 5 |
| [老式左輪](../catalogue/items.md#content_old_revolver) | 1 | 0 | 1 |
| [舊世衝鋒槍](../catalogue/items.md#content_old_smg) | 0 | 0 | 0 |
| [舊世罐頭](../catalogue/items.md#content_old_world_canned_food) | 2 | 0 | 1 |
| [舊世地圖](../catalogue/items.md#content_old_world_map) | 18 | 4 | 3 |
| [舊世醫療箱](../catalogue/items.md#content_old_world_medical_case) | 0 | 0 | 1 |
| [舊世軍甲](../catalogue/items.md#content_old_world_military_armor) | 0 | 0 | 0 |
| [舊世戰術晶片](../catalogue/items.md#content_old_world_tactical_chip) | 0 | 0 | 0 |
| [舊世界手錶](../catalogue/items.md#content_old_world_watch) | 4 | 0 | 6 |
| [止痛藥](../catalogue/items.md#content_painkillers) | 0 | 0 | 0 |
| [紙本日記](../catalogue/items.md#content_paper_journal) | 15 | 0 | 15 |
| [種植手冊](../catalogue/items.md#content_planting_manual) | 7 | 4 | 6 |
| [塑膠](../catalogue/items.md#content_plastic) | 3 | 0 | 0 |
| [鉗子](../catalogue/items.md#content_pliers) | 9 | 3 | 2 |
| [警用防彈衣](../catalogue/items.md#content_police_ballistic_vest) | 0 | 0 | 0 |
| [警用手槍](../catalogue/items.md#content_police_pistol) | 0 | 0 | 0 |
| [動力錘](../catalogue/items.md#content_power_hammer) | 0 | 0 | 0 |
| [精密工程手冊](../catalogue/items.md#content_precision_engineering_manual) | 3 | 0 | 1 |
| [精密零件](../catalogue/items.md#content_precision_parts) | 1 | 1 | 1 |
| [泵動散彈槍](../catalogue/items.md#content_pump_shotgun) | 0 | 0 | 0 |
| [淨水錠](../catalogue/items.md#content_purification_tablets) | 0 | 0 | 2 |
| [無線電](../catalogue/items.md#content_radio) | 6 | 0 | 6 |
| [生肉](../catalogue/items.md#content_raw_meat) | 0 | 0 | 0 |
| [鋼筋棍](../catalogue/items.md#content_rebar_club) | 4 | 0 | 1 |
| [維修手冊](../catalogue/items.md#content_repair_manual) | 11 | 3 | 6 |
| [逆磁片](../catalogue/items.md#content_reverse_magnetic_shard) | 2 | 0 | 3 |
| [繩索](../catalogue/items.md#content_rope) | 33 | 12 | 13 |
| [橡膠](../catalogue/items.md#content_rubber) | 1 | 1 | 2 |
| [生鏽小刀](../catalogue/items.md#content_rusted_knife) | 3 | 1 | 1 |
| [鹽](../catalogue/items.md#content_salt) | 8 | 6 | 3 |
| [沙暴步槍](../catalogue/items.md#content_sandstorm_rifle) | 1 | 0 | 0 |
| [廢鐵](../catalogue/items.md#content_scrap_iron) | 7 | 5 | 2 |
| [拼裝鐵甲](../catalogue/items.md#content_scrap_iron_armor) | 0 | 0 | 0 |
| [廢鐵砍刀](../catalogue/items.md#content_scrap_machete) | 3 | 0 | 2 |
| [廢土拼裝步槍](../catalogue/items.md#content_scrap_rifle) | 0 | 0 | 0 |
| [螺絲起子](../catalogue/items.md#content_screwdriver) | 10 | 3 | 2 |
| [密封貨箱](../catalogue/items.md#content_sealed_cargo_crate) | 13 | 1 | 4 |
| [種子](../catalogue/items.md#content_seeds) | 8 | 1 | 3 |
| [半自動步槍](../catalogue/items.md#content_semi_auto_rifle) | 0 | 0 | 0 |
| [無影玻璃](../catalogue/items.md#content_shadowless_glass) | 2 | 0 | 1 |
| [訊號接收器](../catalogue/items.md#content_signal_receiver) | 4 | 0 | 1 |
| [沉默盒](../catalogue/items.md#content_silence_box) | 1 | 0 | 2 |
| [單發獵槍](../catalogue/items.md#content_single_shot_rifle) | 0 | 0 | 0 |
| [單管散彈槍](../catalogue/items.md#content_single_shot_shotgun) | 0 | 0 | 0 |
| [睡袋](../catalogue/items.md#content_sleeping_bag) | 3 | 1 | 3 |
| [狙擊步槍](../catalogue/items.md#content_sniper_rifle) | 0 | 0 | 0 |
| [短管左輪](../catalogue/items.md#content_snub_revolver) | 0 | 0 | 0 |
| [長矛](../catalogue/items.md#content_spear) | 4 | 0 | 0 |
| [香料](../catalogue/items.md#content_spices) | 2 | 0 | 2 |
| [彈簧](../catalogue/items.md#content_spring) | 3 | 1 | 2 |
| [防刺背心](../catalogue/items.md#content_stab_vest) | 2 | 1 | 0 |
| [靜電骨](../catalogue/items.md#content_static_bone) | 1 | 0 | 2 |
| [鋼材](../catalogue/items.md#content_steel_stock) | 6 | 1 | 0 |
| [電擊棒](../catalogue/items.md#content_stun_baton) | 0 | 0 | 0 |
| [糖](../catalogue/items.md#content_sugar) | 0 | 0 | 0 |
| [手術包](../catalogue/items.md#content_surgical_kit) | 0 | 0 | 0 |
| [舊世戰術頭盔](../catalogue/items.md#content_tactical_helmet) | 0 | 0 | 0 |
| [茶葉](../catalogue/items.md#content_tea) | 4 | 0 | 3 |
| [帳篷](../catalogue/items.md#content_tent) | 6 | 2 | 2 |
| [工具腰帶](../catalogue/items.md#content_tool_belt) | 5 | 1 | 5 |
| [工具箱](../catalogue/items.md#content_toolbox) | 10 | 2 | 3 |
| [舊旅行包](../catalogue/items.md#content_travel_backpack) | 10 | 4 | 7 |
| [不冷的冰](../catalogue/items.md#content_uncold_ice) | 2 | 0 | 2 |
| [未知植入物](../catalogue/items.md#content_unknown_implant) | 1 | 0 | 2 |
| [未標示藥劑](../catalogue/items.md#content_unlabelled_medicine) | 1 | 0 | 2 |
| [沒有寄出的信](../catalogue/items.md#content_unsent_letter) | 1 | 0 | 5 |
| [黑膠唱片](../catalogue/items.md#content_vinyl_record) | 2 | 0 | 2 |
| [水壺](../catalogue/items.md#content_water) | 6 | 0 | 7 |
| [濾水器](../catalogue/items.md#content_water_filter) | 2 | 0 | 2 |
| [防水袋](../catalogue/items.md#content_waterproof_bag) | 31 | 7 | 10 |
| [水袋](../catalogue/items.md#content_waterskin) | 5 | 0 | 4 |
| [焊接工具](../catalogue/items.md#content_welding_tools) | 1 | 0 | 1 |
| [守井人](../catalogue/items.md#content_well_guardian) | 1 | 0 | 1 |
| [野菜](../catalogue/items.md#content_wild_greens) | 1 | 0 | 0 |
| [荒野斗篷](../catalogue/items.md#content_wilderness_cloak) | 1 | 0 | 0 |
| [伐木斧](../catalogue/items.md#content_wood_axe) | 3 | 1 | 1 |
| [舊工作服](../catalogue/items.md#content_work_clothes) | 5 | 2 | 3 |
| [工人皮衣](../catalogue/items.md#content_worker_leather_jacket) | 1 | 0 | 2 |
| [扳手](../catalogue/items.md#content_wrench) | 17 | 5 | 7 |

## 出現最多的物品

數量只表示編輯引用密度。必須另看是否壟斷解法；持有、消耗與獎勵已在 JSON 分欄。

- 繩索：33 個遭遇。
- 防水袋：31 個遭遇。
- 布袋：25 個遭遇。
- 望遠鏡：20 個遭遇。
- 舊世地圖：18 個遭遇。
- 扳手：17 個遭遇。
- 手電筒：15 個遭遇。
- 紙本日記：15 個遭遇。
- 萬用電表：14 個遭遇。
- 布料：13 個遭遇。
- 指南針：13 個遭遇。
- 乾糧：13 個遭遇。
- 密封貨箱：13 個遭遇。
- 工程護目鏡：11 個遭遇。
- 維修手冊：11 個遭遇。

## 保留的缺口

完全無四庫引用：腎上腺素、彈藥、抗輻射藥、抗生素、解毒劑、軍用突擊步槍、栓動步槍、燒傷藥膏、車板刀、商隊槍、商隊護衛槍、化學品、香菸、民用手槍、沙地彎刀、消毒水、雙管散彈槍、消防斧、火焰噴射器、信號槍、榴彈發射器、大口徑左輪、土製手槍、輕機槍、衝鋒手槍、火柴、機械零件、藥物、肌纖維刺激器、神經反射模組、夜視鏡、老獵人的槍、舊世衝鋒槍、舊世軍甲、舊世戰術晶片、止痛藥、警用防彈衣、警用手槍、動力錘、泵動散彈槍、生肉、拼裝鐵甲、廢土拼裝步槍、半自動步槍、單發獵槍、單管散彈槍、狙擊步槍、短管左輪、電擊棒、糖、手術包、舊世戰術頭盔。
未作為遭遇物件的實體候選：腎上腺素、抗輻射藥、抗生素、解毒劑、軍用突擊步槍、電池芯、黑盒記憶體、栓動步槍、燒傷藥膏、車板刀、商隊槍、商隊護衛槍、化學品、香菸、民用手槍、沙地彎刀、消毒水、雙管散彈槍、消防斧、火焰噴射器、信號槍、榴彈發射器、大口徑左輪、土製手槍、輕機槍、打火機、衝鋒手槍、火柴、軍醫資料晶片、肌纖維刺激器、神經反射模組、夜視鏡、老獵人的槍、舊世衝鋒槍、舊世醫療箱、舊世軍甲、舊世戰術晶片、止痛藥、警用防彈衣、警用手槍、動力錘、泵動散彈槍、淨水錠、生肉、拼裝鐵甲、廢土拼裝步槍、半自動步槍、單發獵槍、單管散彈槍、狙擊步槍、短管左輪、電擊棒、糖、手術包、舊世戰術頭盔。
沒有具體獎勵入口：腎上腺素、鋁材、彈藥帶、彈藥、抗輻射藥、抗生素、解毒劑、軍用突擊步槍、電池、電池芯、望遠鏡、黑盒記憶體、黑色水滴、栓動步槍、燒傷藥膏、相機、車板刀、車板胸甲、商隊外套、商隊槍、商隊步槍、商隊護衛槍、化學品、香菸、民用手槍、公司門禁卡、指南針、撬棍、資料磁碟、沙地長袍、沙地彎刀、消毒水、雙管散彈槍、沙塵面罩、工程護目鏡、工兵鏟、農務服、消防斧、防火服、火焰噴射器、信號槍、燃料、防毒面具、齒輪、地質調查圖、榴彈發射器、手搖發電機、防化服、隔熱服、大口徑左輪、登山背包、回家、醫院識別卡、捕獸叉、獵刀、身分證件、土製手槍、工業釘槍、千斤頂、最後一發、輕機槍、打火機、酒、開鎖工具、衝鋒手槍、火柴、機械零件、醫療手冊、醫療袋、藥物、記憶核心、金屬探測器、軍用背包、軍人識別牌、軍用手冊、軍醫資料晶片、摩托夾克、肌纖維刺激器、音樂播放器、神經反射模組、夜視鏡、六十三號、老獵人的槍、老照片、老式左輪、舊世衝鋒槍、舊世地圖、舊世醫療箱、舊世軍甲、舊世戰術晶片、舊世界手錶、止痛藥、種植手冊、警用防彈衣、警用手槍、動力錘、精密工程手冊、精密零件、泵動散彈槍、淨水錠、無線電、生肉、鋼筋棍、生鏽小刀、沙暴步槍、拼裝鐵甲、廢鐵砍刀、廢土拼裝步槍、密封貨箱、半自動步槍、訊號接收器、單發獵槍、單管散彈槍、睡袋、狙擊步槍、短管左輪、長矛、香料、防刺背心、靜電骨、電擊棒、糖、手術包、舊世戰術頭盔、工具腰帶、工具箱、舊旅行包、未知植入物、未標示藥劑、沒有寄出的信、濾水器、防水袋、焊接工具、守井人、荒野斗篷、伐木斧、工人皮衣。

無獎勵入口不代表必須補掉落：可由購買、借用、既有持有或明確故事交付取得；未指定取得流程者仍是實作缺口。三種分類示意圖永遠不作實體掉落。

材料關係僅表示可能投入／產物，不含數量、耗損或時間。即使沒有自產邊，也不能證明沒有套利；配方上線前需完整質量與價值守恆檢查。
