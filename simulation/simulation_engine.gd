class_name SimulationEngine
extends RefCounted

const COMMODITIES: Array[String] = ["water", "food", "scrap", "fuel"]
const ItemRegistry = preload("res://simulation/item_registry.gd")
const ItemMarketCatalogue = preload("res://simulation/item_market_catalogue.gd")
const ItemMarketState = preload("res://simulation/item_market_state.gd")
const EquipmentState = preload("res://simulation/equipment_state.gd")
const TravelRoute = preload("res://simulation/travel_route.gd")

const PRICE_ELASTICITY_K: float = 1.5
const MIN_PRICE_RATIO: float = 0.2
const MAX_PRICE_RATIO: float = 5.0

# S3-B 生理短缺壓力規則 (Simulation Rules - State != Rules)
const WATER_PRESSURE_GAIN_RATE: float = 25.0
const WATER_PRESSURE_RECOVERY_RATE: float = 15.0
const FOOD_PRESSURE_GAIN_RATE: float = 25.0
const FOOD_PRESSURE_RECOVERY_RATE: float = 15.0

# S3-C 難民遷徙規則 (Simulation Rules - State != Rules)
const MIGRATION_PRESSURE_THRESHOLD: float = 60.0
const MIGRATION_POPULATION_RATIO: float = 0.10
const MIGRATION_MIN_POPULATION: int = 10
const MIGRATION_COOLDOWN_DAYS: int = 3
const DEFAULT_MIGRATION_ROUTE_DAYS: int = 3
# A journey must never run away with the simulation if arrival goes wrong, so
# auto-advance is bounded rather than trusting the loop to terminate.
const TRAVEL_SAFETY_MARGIN_DAYS: int = 2
# What the people at the barricade ask for. Not a faction, just a price.
const ROADBLOCK_TOLL_CAPS: int = 10

var enable_migration: bool = true

# S3-D 生理匱乏暴露與極限死亡規則 (Simulation Rules - State != Rules)
const WATER_EXPOSURE_GRACE_DAYS: float = 6.0
const FOOD_EXPOSURE_GRACE_DAYS: float = 18.0
const DEPRIVATION_RECOVERY_RATE: float = 1.0
const MORTALITY_BASE_RATE: float = 0.05

var enable_mortality: bool = true

# S3-E 勞動力敏感度與反饋規則 (Labor Sensitivity & Feedback Rules - State != Rules)
const LABOR_SENSITIVITY: Dictionary = {
	"water": 0.0,
	"food": 0.0,
	"scrap": 1.0,
	"fuel": 1.0
}

var enable_labor: bool = true
var enable_npc_decisions: bool = true

# S3-F 社會秩序與商路掠奪規則 (Social Order & Route Predation Rules - State != Rules)
const CIVIC_CAPACITY_DRAG_RATE: float = 3.0
const DESPERATION_DRAG_RATE: float = 5.0
const SECURITY_RECOVERY_RATE: float = 2.0
const DISORDER_LOSS_THRESHOLD: float = 40.0
const DISORDER_LOSS_RATE: float = 0.05
const ROUTE_RISK_THRESHOLD: float = 40.0
const TRANSIT_PREDATION_RATE: float = 0.10

var enable_security: bool = true
var enable_disorder_loss: bool = true
var enable_transit_predation: bool = true

# 嚴格依序執行的 7 階段離散 Tick
func tick(world: WorldState) -> Array[EventRecord]:
	var tick_events: Array[EventRecord] = []
	world.current_day += 1
	var current_day := world.current_day

	# S3-C 全域初始人口記錄 (供守恆不變量驗證)
	if world.total_initial_population < 0:
		var initial_pop := 0
		for s_id in world.settlements:
			initial_pop += world.settlements[s_id].population
		for r_id in world.refugees:
			var r: RefugeePartyState = world.refugees[r_id]
			if r.is_active and not r.is_arrived:
				initial_pop += r.headcount
		world.total_initial_population = initial_pop

	# 取得排序過之聚落與商隊 Key，確保迭代順序 100% 確定
	var sorted_settlement_ids := world.settlements.keys()
	sorted_settlement_ids.sort()

	var sorted_caravan_ids := world.caravans.keys()
	sorted_caravan_ids.sort()

	# S3-F 日初治安快照 (Start-of-Day Security Snapshot 確保因果傳導延遲性)
	var start_of_day_security: Dictionary = {}
	for s_id in sorted_settlement_ids:
		start_of_day_security[s_id] = world.settlements[s_id].security

	# -------------------------------------------------------------
	# 階段 1: 聚落生存消耗與會計記帳 (Consumption & Demand Accounting)
	# -------------------------------------------------------------
	for s_id in sorted_settlement_ids:
		var settlement: SettlementState = world.settlements[s_id]
		# S3-C 冷卻計時推進
		settlement.days_since_last_migration += 1

		# S3-A: 動態由人口規模與人均代謝率計算今日生存消耗
		settlement.update_consumption_from_metabolism()
		settlement.last_need_outcomes.clear()

		for res in COMMODITIES:
			var cur := settlement.inventory.get_amount(res)
			var con := settlement.consumption.get_amount(res)
			var fulfilled := mini(cur, con)
			var unmet := con - fulfilled
			settlement.inventory.set_amount(res, cur - fulfilled)
			if res == &"water" or res == &"food":
				settlement.last_need_outcomes[String(res)] = {
					"stock_before": cur,
					"requested": con,
					"fulfilled": fulfilled,
					"unmet": unmet,
					"stock_after": cur - fulfilled
				}
				apply_need_pressure(settlement, res, con, fulfilled, unmet)

		# S3-D 生理匱乏暴露時長累積與恢復 (Deprivation Exposure)
		if settlement.last_need_outcomes.has("water"):
			var w_out: Dictionary = settlement.last_need_outcomes["water"]
			if w_out["unmet"] > 0 and w_out["requested"] > 0:
				settlement.water_exposure += float(w_out["unmet"]) / float(w_out["requested"])
			else:
				settlement.water_exposure = maxf(0.0, settlement.water_exposure - DEPRIVATION_RECOVERY_RATE)

		if settlement.last_need_outcomes.has("food"):
			var f_out: Dictionary = settlement.last_need_outcomes["food"]
			if f_out["unmet"] > 0 and f_out["requested"] > 0:
				settlement.food_exposure += float(f_out["unmet"]) / float(f_out["requested"])
			else:
				settlement.food_exposure = maxf(0.0, settlement.food_exposure - DEPRIVATION_RECOVERY_RATE)

		# S3-C 難民遷徙觸發判定 (Refugee Migration Trigger - 遷徙優先於死亡)
		# Anonymous-First Bridge (G1.5-X): aggregate rules only act on anonymous population.
		var eff_pressure := maxf(settlement.water_pressure, settlement.food_pressure)
		if enable_migration and eff_pressure >= MIGRATION_PRESSURE_THRESHOLD and settlement.days_since_last_migration >= MIGRATION_COOLDOWN_DAYS and settlement.population > MIGRATION_MIN_POPULATION:
			var requested_headcount := maxi(1, int(floor(float(settlement.population) * MIGRATION_POPULATION_RATIO)))
			if settlement.population - requested_headcount < MIGRATION_MIN_POPULATION:
				requested_headcount = settlement.population - MIGRATION_MIN_POPULATION
			if requested_headcount > 0:
				var dest_id := select_refugee_destination(world, settlement)
				if dest_id != &"":
					# Compute anonymous count (population not attributed to a named living NPC)
					var named_living: int = world.npc_life_state_registry.get_named_living_count_in_settlement(settlement.id)
					var anonymous_count: int = settlement.population - named_living
					var actual_headcount: int = mini(requested_headcount, anonymous_count)

					if actual_headcount <= 0:
						# FAIL CLOSED: cannot select named individuals for aggregate migration
						var fail_evt := EventRecord.new(
							current_day,
							"NAMED_MIGRATION_DECISION_REQUIRED",
							settlement.id,
							settlement.id,
							{
								"origin": String(settlement.id),
								"requested_headcount": requested_headcount,
								"anonymous_count": 0,
								"named_living_count": named_living,
								"pressure_trigger": eff_pressure,
								"cause": "anonymous_population_exhausted"
							}
						)
						tick_events.append(fail_evt)
						world.record_event(fail_evt)
					else:
						# Normal anonymous migration
						settlement.population -= actual_headcount
						settlement.days_since_last_migration = 0
						var route_days := get_route_days_between(world, settlement.id, dest_id)
						var party_id := StringName("refugee:%s:%s:d%d" % [String(settlement.id), String(dest_id), current_day])
						var party := RefugeePartyState.new(
							party_id,
							settlement.id,
							dest_id,
							actual_headcount,
							route_days,
							route_days,
							current_day
						)
						world.add_refugee_party(party)

						var depart_evt := EventRecord.new(
							current_day,
							"REFUGEES_DEPARTED",
							party_id,
							dest_id,
							{
								"origin": String(settlement.id),
								"destination": String(dest_id),
								"headcount": actual_headcount,
								"route_days": route_days,
								"origin_population_after": settlement.population,
								"pressure_trigger": eff_pressure,
								"anonymous_only": true
							}
						)
						tick_events.append(depart_evt)
						world.record_event(depart_evt)

		# S3-D 極限生理死亡判定 (Mortality Trigger - Anonymous-First Bridge)
		# G1.5-X: Aggregate mortality only acts on anonymous population.
		if enable_mortality and settlement.population > 0:
			var daily_water_unmet: int = settlement.last_need_outcomes.get("water", {}).get("unmet", 0)
			var daily_food_unmet: int = settlement.last_need_outcomes.get("food", {}).get("unmet", 0)

			var water_fatal := daily_water_unmet > 0 and settlement.water_exposure > WATER_EXPOSURE_GRACE_DAYS
			var food_fatal := daily_food_unmet > 0 and settlement.food_exposure > FOOD_EXPOSURE_GRACE_DAYS

			var causes: Array[String] = []
			if water_fatal:
				causes.append("water")
			if food_fatal:
				causes.append("food")

			if not causes.is_empty():
				# Compute requested deaths and anonymous capacity
				var post_migration_pop := settlement.population
				var requested_deaths := mini(post_migration_pop, maxi(1, int(floor(float(post_migration_pop) * MORTALITY_BASE_RATE))))

				var named_living: int = world.npc_life_state_registry.get_named_living_count_in_settlement(settlement.id)
				var anonymous_count: int = post_migration_pop - named_living
				var actual_deaths: int = mini(requested_deaths, anonymous_count)

				if actual_deaths > 0:
					settlement.population -= actual_deaths
					settlement.cumulative_deaths += actual_deaths

					var mort_evt := EventRecord.new(
						current_day,
						"SETTLEMENT_MORTALITY",
						settlement.id,
						settlement.id,
						{
							"deaths": actual_deaths,
							"anonymous_deaths": actual_deaths,
							"causes": causes,
							"population_before": post_migration_pop,
							"population_after": settlement.population,
							"cumulative_deaths": settlement.cumulative_deaths,
							"water_exposure": settlement.water_exposure,
							"food_exposure": settlement.food_exposure
						}
					)
					tick_events.append(mort_evt)
					world.record_event(mort_evt)

				var shortfall := requested_deaths - actual_deaths
				if shortfall > 0:
					# FAIL CLOSED: cannot select named individuals for aggregate mortality
					var fail_evt := EventRecord.new(
						current_day,
						"NAMED_SELECTION_REQUIRED",
						settlement.id,
						settlement.id,
						{
							"settlement_id": String(settlement.id),
							"requested_deaths": requested_deaths,
							"actual_anonymous_deaths": actual_deaths,
							"shortfall": shortfall,
							"named_living_count": named_living,
							"causes": causes,
							"cause": "anonymous_population_exhausted"
						}
					)
					tick_events.append(fail_evt)
					world.record_event(fail_evt)

	# -------------------------------------------------------------
	# 階段 1.5: 具名 NPC 自主決策 (S4-F1 Autonomous Decision Authority)
	# -------------------------------------------------------------
	# Runs AFTER the aggregate per-settlement pass, as its own phase, so the
	# anonymous cohort (S3 rules) and named individuals (S4 decision engine)
	# never interleave. The macro system still must not choose for Mara.
	if enable_npc_decisions:
		run_npc_decision_phase(world, current_day, tick_events)

	# -------------------------------------------------------------
	# 階段 2: 各聚落在地生產 (Local Production with Labor Feedback)
	# -------------------------------------------------------------
	for s_id in sorted_settlement_ids:
		var settlement: SettlementState = world.settlements[s_id]
		if enable_labor and settlement.reference_population > 0:
			var labor_factor: float = clampf(float(settlement.population) / float(settlement.reference_population), 0.0, 1.0)
			for res in COMMODITIES:
				var base_prod: int = settlement.production.get_amount(res)
				if base_prod <= 0:
					continue
				var sens: float = LABOR_SENSITIVITY.get(res, 0.0)
				var effective_factor: float = 1.0 - sens * (1.0 - labor_factor)
				var daily_prod: float = float(base_prod) * effective_factor

				var current_credit: float = settlement.production_credits.get(res, 0.0)
				current_credit += daily_prod
				var to_add: int = int(floor(current_credit + 1e-9))
				current_credit = maxf(0.0, current_credit - float(to_add))
				settlement.production_credits[res] = current_credit

				if to_add > 0:
					settlement.inventory.add_amount(res, to_add)
		else:
			for res in COMMODITIES:
				var cur := settlement.inventory.get_amount(res)
				var prod := settlement.production.get_amount(res)
				settlement.inventory.set_amount(res, cur + prod)

	# -------------------------------------------------------------
	# 階段 2.5: 在地秩序損耗 (Local Disorder Loss - 使用日初治安快照)
	# -------------------------------------------------------------
	if enable_security and enable_disorder_loss:
		for s_id in sorted_settlement_ids:
			var settlement: SettlementState = world.settlements[s_id]
			var sec: float = start_of_day_security.get(s_id, 100.0)
			if sec < DISORDER_LOSS_THRESHOLD:
				apply_settlement_disorder_loss(settlement, sec, current_day, tick_events, world)

	# -------------------------------------------------------------
	# 階段 3: 重新計算市場報價 (Price Recalculation)
	# -------------------------------------------------------------
	for s_id in sorted_settlement_ids:
		var settlement: SettlementState = world.settlements[s_id]
		recalculate_prices(settlement)
		if settlement.item_market != null:
			settlement.item_market.restock_for(settlement.id, current_day)

	# -------------------------------------------------------------
	# 階段 4: 在途商隊與難民推進航程 (Caravan & Refugee Advances)
	# -------------------------------------------------------------
	for c_id in sorted_caravan_ids:
		var caravan: CaravanState = world.caravans[c_id]
		if caravan.is_active and not caravan.is_destroyed:
			caravan.days_remaining -= 1

	var sorted_refugee_ids := world.refugees.keys()
	sorted_refugee_ids.sort()
	for r_id in sorted_refugee_ids:
		var party: RefugeePartyState = world.refugees[r_id]
		if party.is_active and not party.is_arrived:
			party.days_remaining -= 1

	# -------------------------------------------------------------
	# 階段 5: 商隊抵達、卸貨與折返裝貨 (Arrival & Logistics)
	# -------------------------------------------------------------
	for c_id in sorted_caravan_ids:
		var caravan: CaravanState = world.caravans[c_id]
		if caravan.is_active and not caravan.is_destroyed and caravan.days_remaining <= 0:
			var dest: SettlementState = world.get_settlement(caravan.destination_id)
			if dest != null:
				# S3-F 商路危險度與在途物流掠奪判定 (Route Risk & Transit Predation - 每 leg 一次結算)
				var orig_sec: float = start_of_day_security.get(caravan.origin_id, 100.0)
				var dest_sec: float = start_of_day_security.get(caravan.destination_id, 100.0)
				var route_risk: float = ((100.0 - orig_sec) + (100.0 - dest_sec)) / 2.0

				if enable_security and enable_transit_predation and route_risk >= ROUTE_RISK_THRESHOLD:
					var lost_cargo: Dictionary = {}
					for res in COMMODITIES:
						var cargo_amt := caravan.cargo.get_amount(res)
						if cargo_amt > 0:
							var toll: int = maxi(1, int(floor(float(cargo_amt) * TRANSIT_PREDATION_RATE)))
							toll = mini(toll, cargo_amt)
							caravan.cargo.add_amount(res, -toll)
							lost_cargo[res] = toll
					if lost_cargo.size() > 0:
						var predation_evt := EventRecord.new(
							current_day,
							"TRANSIT_PREDATION",
							caravan.id,
							dest.id,
							{
								"route_risk": route_risk,
								"origin": String(caravan.origin_id),
								"destination": String(caravan.destination_id),
								"lost": lost_cargo,
								"cause_class": "low_security",
								"cargo_after": caravan.cargo.to_dict()
							}
						)
						tick_events.append(predation_evt)
						world.record_event(predation_evt)

				# 1. 卸貨轉移入庫
				var unloaded_payload: Dictionary = {}
				for res in COMMODITIES:
					var amt := caravan.cargo.get_amount(res)
					if amt > 0:
						dest.inventory.add_amount(res, amt)
						caravan.cargo.set_amount(res, 0)
						unloaded_payload[res] = amt

				var arrival_evt := EventRecord.new(
					current_day,
					"CARAVAN_ARRIVED",
					caravan.id,
					dest.id,
					{
						"unloaded": unloaded_payload,
						"dest_inventory_after": dest.inventory.to_dict()
					}
				)
				# 保持向後相容欄位 (供 M0-A 測試讀取)
				arrival_evt.payload["unloaded_water"] = unloaded_payload.get("water", 0)
				arrival_evt.payload["dest_water_after"] = dest.inventory.water

				tick_events.append(arrival_evt)
				world.record_event(arrival_evt)

				# 重新計算卸貨後的目的地價格
				recalculate_prices(dest)

				# 2. 商隊折返設定
				var prev_origin := caravan.origin_id
				caravan.origin_id = caravan.destination_id
				caravan.destination_id = prev_origin
				caravan.days_remaining = caravan.route_days

				# 3. 雙向裝貨 (Trade Need Matching)
				# 計算新起點 (當前所在聚落) 與新目的地之間的供需匹配
				var current_origin: SettlementState = world.get_settlement(caravan.origin_id)
				var target_dest: SettlementState = world.get_settlement(caravan.destination_id)

				if current_origin != null and target_dest != null:
					var loaded_payload := load_caravan_cargo(caravan, current_origin, target_dest)
					if loaded_payload.size() > 0:
						var load_evt := EventRecord.new(
							current_day,
							"CARAVAN_LOADED",
							caravan.id,
							current_origin.id,
							{
								"loaded": loaded_payload,
								"destination": String(target_dest.id),
								"origin_inventory_after": current_origin.inventory.to_dict()
							}
						)
						load_evt.payload["loaded_water"] = loaded_payload.get("water", 0)
						load_evt.payload["origin_water_after"] = current_origin.inventory.water

						tick_events.append(load_evt)
						world.record_event(load_evt)

	# 難民抵達與入籍 (Refugee Arrival & Settlement Integration)
	# Named NPCs in transit are processed individually first (complete_named_migration),
	# then remaining anonymous headcount is added to destination aggregate.
	for r_id in sorted_refugee_ids:
		var party: RefugeePartyState = world.refugees[r_id]
		if party.is_active and not party.is_arrived and party.days_remaining <= 0:
			var dest: SettlementState = world.get_settlement(party.destination_id)
			if dest != null:
				# 1. Process named NPCs in this party first (individual atomic arrival)
				var named_in_party := world.npc_life_state_registry.get_all_living_in(
					NpcLifeState.ContainerType.REFUGEE_PARTY, party.id
				)
				var named_arrived: Array[StringName] = []
				for npc_id in named_in_party:
					var result := world.npc_life_state_registry.complete_named_migration(world, npc_id)
					if result["success"]:
						named_arrived.append(npc_id)
						var npc_evt := EventRecord.new(
							current_day,
							"NAMED_MIGRATION_COMPLETED",
							npc_id,
							dest.id,
							{
								"npc_id": String(npc_id),
								"party_id": String(party.id),
								"destination": String(dest.id)
							}
						)
						tick_events.append(npc_evt)
						world.record_event(npc_evt)

				# 2. Add remaining anonymous headcount (party.headcount was decremented per named NPC)
				if party.headcount > 0:
					dest.population += party.headcount

				party.is_active = false
				party.is_arrived = true

				var arrival_evt := EventRecord.new(
					current_day,
					"REFUGEES_ARRIVED",
					party.id,
					dest.id,
					{
						"origin": String(party.origin_id),
						"destination": String(dest.id),
						"headcount": party.headcount + named_arrived.size(),
						"anonymous_headcount": party.headcount,
						"named_arrived": named_arrived.map(func(x): return String(x)),
						"dest_population_after": dest.population
					}
				)
				tick_events.append(arrival_evt)
				world.record_event(arrival_evt)


	# -------------------------------------------------------------
	# 階段 5.5: 聚落治安更新 (Security Update - 根據今日人口/壓力產生明日治安)
	# -------------------------------------------------------------
	if enable_security:
		for s_id in sorted_settlement_ids:
			var settlement: SettlementState = world.settlements[s_id]
			if settlement.reference_population > 0:
				update_settlement_security(settlement)

	# -------------------------------------------------------------
	# 階段 5.4: 玩家化身生理需求處理 (S5-A Player Personal Needs)
	# -------------------------------------------------------------
	process_player_daily_needs(world, current_day, tick_events)

	# -------------------------------------------------------------
	# 階段 5.45: Quest 截止日判定 (QUEST-1 Deadline Check)
	# -------------------------------------------------------------
	# After survival resolution (player may have died), before numeric commit.
	# Transitions all ACTIVE quests past their deadline_day to EXPIRED.
	load("res://simulation/quest_engine.gd").check_deadlines(world)

	# -------------------------------------------------------------
	# 階段 5.5: 正規數值提交 (S4-C.2 Canonical Numeric Commit)
	# -------------------------------------------------------------
	# The day's physics are finished; commit the authoritative state in the form
	# persistence can faithfully carry. This runs ONCE per day, at the end-of-day
	# commit boundary — not after every individual arithmetic step — so the
	# committed world IS the persistable world, and save never has to repair it.
	world.canonicalize_numeric_state()

	# -------------------------------------------------------------
	# 階段 6: 不變量驗證 (Invariant Validation)
	# -------------------------------------------------------------
	var invariant_err := validate_invariants(world)
	if invariant_err != "":
		push_error("Invariant violation at Day %d: %s" % [current_day, invariant_err])
		assert(false, invariant_err)

	return tick_events

# 雙向智能配貨邏輯：依聚落專業分工與供需失衡，按比例在起點盈餘中裝載所需物資
func load_caravan_cargo(caravan: CaravanState, origin: SettlementState, dest: SettlementState) -> Dictionary:
	var loaded: Dictionary = {}
	var remaining_cap := caravan.capacity_total - caravan.get_total_cargo()
	if remaining_cap <= 0:
		return loaded

	var round_trip_days := caravan.route_days * 2

	# 1. 統計目的地真正缺乏的物資 (淨赤字或庫存低於目標)，且起點為合法出口者
	var fulfillable_needs: Dictionary = {}
	var total_fulfillable: int = 0

	var sorted_res := COMMODITIES.duplicate()
	sorted_res.sort()

	for res in sorted_res:
		var dest_net: int = dest.production.get_amount(res) - dest.consumption.get_amount(res)
		var dest_stock: int = dest.inventory.get_amount(res)
		var dest_target: int = dest.get_target(res)

		# 目的地檢查：若本聚落能自給自足且庫存達到目標，絕不進口
		if dest_net >= 0 and dest_stock >= dest_target:
			continue

		# 目的地在途需求量：現有缺口 + 往返期間預估赤字消耗
		var deficit: int = dest.get_deficit(res)
		var future_deficit: int = maxi(0, -dest_net * round_trip_days)
		var dest_need: int = deficit + future_deficit
		if dest_need <= 0:
			continue

		# 起點檢查：若起點本身亦為淨赤字且庫存不高於目標，絕不出口
		var origin_net: int = origin.production.get_amount(res) - origin.consumption.get_amount(res)
		var origin_stock: int = origin.inventory.get_amount(res)
		var origin_target: int = origin.get_target(res)

		if origin_net <= 0 and origin_stock <= origin_target:
			continue

		# 起點可出口上限：確保優先滿足起點自身的安全底線
		var safe_floor: int = origin_target if origin_net <= 0 else maxi(0, origin_target / 2)
		var can_supply: int = maxi(0, origin_stock - safe_floor)
		var fulfillable: int = mini(dest_need, can_supply)

		if fulfillable > 0:
			fulfillable_needs[res] = fulfillable
			total_fulfillable += fulfillable

	if total_fulfillable <= 0:
		return loaded

	# 2. 配額分配：若總需求超出容量，依需求權重分配；否則滿足全部需求
	var to_load_map: Dictionary = {}
	if total_fulfillable <= remaining_cap:
		to_load_map = fulfillable_needs
	else:
		var allocated := 0
		for res in sorted_res:
			if not fulfillable_needs.has(res):
				continue
			var share := int(round(float(remaining_cap) * float(fulfillable_needs[res]) / float(total_fulfillable)))
			share = mini(share, int(fulfillable_needs[res]))
			to_load_map[res] = share
			allocated += share

		# 若四捨五入有微小餘額，按需求順序填補至滿載
		var remainder := remaining_cap - allocated
		if remainder > 0:
			for res in sorted_res:
				if not fulfillable_needs.has(res):
					continue
				var max_possible: int = fulfillable_needs[res]
				var cur: int = to_load_map.get(res, 0)
				var room: int = max_possible - cur
				var add_amt: int = mini(remainder, room)
				to_load_map[res] = cur + add_amt
				remainder -= add_amt
				if remainder <= 0:
					break

	# 3. 實際扣除起點庫存並裝載入商隊
	for res in to_load_map:
		var amt: int = to_load_map[res]
		if amt > 0:
			origin.inventory.add_amount(res, -amt)
			caravan.cargo.add_amount(res, amt)
			loaded[res] = amt

	return loaded

# 重新計算聚落全品項價格
func recalculate_prices(settlement: SettlementState) -> void:
	for res in COMMODITIES:
		var cur_stock := settlement.inventory.get_amount(res)
		var target_stock := settlement.get_target(res)
		var base_p := settlement.get_base_price(res)
		var new_p := calculate_price(base_p, cur_stock, target_stock)
		settlement.set_current_price(res, new_p)

# 稀缺度比例計算 (Scarcity Ratio)
func calculate_scarcity_ratio(current_stock: int, target_stock: int) -> float:
	if target_stock <= 0:
		return 0.0
	return float(target_stock - current_stock) / float(target_stock)

# 單純有界稀缺價格計算模型
func calculate_price(base_price: float, current_stock: int, target_stock: int) -> float:
	if target_stock <= 0:
		return base_price

	var min_p: float = base_price * MIN_PRICE_RATIO
	var max_p: float = base_price * MAX_PRICE_RATIO

	var scarcity_ratio: float = calculate_scarcity_ratio(current_stock, target_stock)
	var raw_price: float = base_price * (1.0 + PRICE_ELASTICITY_K * scarcity_ratio)

	return clampf(raw_price, min_p, max_p)

# 外部衝擊：摧毀指定商隊 (Supply Shock)
func destroy_caravan(world: WorldState, caravan_id: StringName, day_override: int = -1) -> EventRecord:
	var caravan := world.get_caravan(caravan_id)
	if caravan == null:
		push_error("Cannot destroy non-existent caravan: %s" % caravan_id)
		return null

	var current_day := day_override if day_override >= 0 else world.current_day
	var lost_cargo := caravan.cargo.duplicate_state()

	caravan.is_destroyed = true
	caravan.is_active = false
	for res in COMMODITIES:
		caravan.cargo.set_amount(res, 0)

	var shock_evt := EventRecord.new(
		current_day,
		"CARAVAN_DESTROYED",
		caravan.id,
		caravan.destination_id,
		{
			"origin": String(caravan.origin_id),
			"destination": String(caravan.destination_id),
			"lost_cargo": lost_cargo.to_dict(),
			"days_remaining": caravan.days_remaining
		}
	)
	shock_evt.payload["lost_water"] = lost_cargo.water
	shock_evt.payload["lost_food"] = lost_cargo.food

	world.record_event(shock_evt)
	return shock_evt

# 外部修復：重啟指定商隊航線 (S2-E Post-restoration Recovery)
func restore_caravan(
	world: WorldState,
	caravan_id: StringName,
	day_override: int = -1,
	origin_override: StringName = &"",
	dest_override: StringName = &""
) -> EventRecord:
	var caravan := world.get_caravan(caravan_id)
	if caravan == null:
		push_error("Cannot restore non-existent caravan: %s" % caravan_id)
		return null

	var current_day := day_override if day_override >= 0 else world.current_day

	caravan.is_destroyed = false
	caravan.is_active = true

	if origin_override != &"":
		caravan.origin_id = origin_override
	if dest_override != &"":
		caravan.destination_id = dest_override

	# 重設自起點重新出發，嚴格歷經完整旅行天數
	caravan.days_remaining = caravan.route_days

	# 起點重新裝載物資 (依供需自動等比裝載)
	var origin: SettlementState = world.get_settlement(caravan.origin_id)
	var dest: SettlementState = world.get_settlement(caravan.destination_id)
	var loaded_payload: Dictionary = {}
	if origin != null and dest != null:
		loaded_payload = load_caravan_cargo(caravan, origin, dest)

	var restore_evt := EventRecord.new(
		current_day,
		"CARAVAN_RESTORED",
		caravan.id,
		caravan.destination_id,
		{
			"origin": String(caravan.origin_id),
			"destination": String(caravan.destination_id),
			"loaded": loaded_payload,
			"days_remaining": caravan.days_remaining
		}
	)
	world.record_event(restore_evt)
	return restore_evt

# S3-B 生理短缺壓力規則應用 (State != Rules)
func apply_need_pressure(settlement: SettlementState, resource: StringName, requested: int, fulfilled: int, unmet: int) -> void:
	if settlement.population <= 0:
		if resource == &"water":
			settlement.water_pressure = 0.0
		elif resource == &"food":
			settlement.food_pressure = 0.0
		return

	if resource == &"water":
		if requested > 0 and unmet > 0:
			var unmet_ratio := float(unmet) / float(requested)
			settlement.water_pressure = minf(100.0, settlement.water_pressure + unmet_ratio * WATER_PRESSURE_GAIN_RATE)
		else:
			settlement.water_pressure = maxf(0.0, settlement.water_pressure - WATER_PRESSURE_RECOVERY_RATE)
	elif resource == &"food":
		if requested > 0 and unmet > 0:
			var unmet_ratio := float(unmet) / float(requested)
			settlement.food_pressure = minf(100.0, settlement.food_pressure + unmet_ratio * FOOD_PRESSURE_GAIN_RATE)
		else:
			settlement.food_pressure = maxf(0.0, settlement.food_pressure - FOOD_PRESSURE_RECOVERY_RATE)

# S3-C 難民目的地理性選擇 (Rational Destination Selection)
func select_refugee_destination(world: WorldState, origin: SettlementState) -> StringName:
	var candidate_ids: Array[StringName] = []
	var sorted_s_ids := world.settlements.keys()
	sorted_s_ids.sort()
	for s_id in sorted_s_ids:
		if s_id != origin.id:
			candidate_ids.append(s_id)

	if candidate_ids.is_empty():
		return &""

	var best_id: StringName = &""
	var best_score: float = -999999.0

	for s_id in candidate_ids:
		var dest: SettlementState = world.settlements[s_id]
		var dest_pressure := maxf(dest.water_pressure, dest.food_pressure)
		var net_survival_prod: float = float(
			(dest.production.water - dest.consumption.water) +
			(dest.production.food - dest.consumption.food)
		)
		var current_survival_stock: float = float(dest.inventory.water + dest.inventory.food)
		var target_survival_stock: float = float(dest.get_target("water") + dest.get_target("food"))
		var stock_ratio: float = (current_survival_stock / target_survival_stock) if target_survival_stock > 0 else 1.0
		var route_d := float(get_route_days_between(world, origin.id, s_id))

		# 吸引力評分 (Desirability Score):
		# + 淨生存產能權重 (能自給自足並產出水糧者優先)
		# + 庫存充裕度權重 (現有儲備越滿越有保障)
		# - 短缺壓力重扣 (-2.0)
		# - 路線距離懲罰 (-5.0/天)
		var score: float = (net_survival_prod * 3.0) + (stock_ratio * 10.0) - (dest_pressure * 2.0) - (route_d * 5.0)
		if best_id == &"" or score > best_score:
			best_score = score
			best_id = s_id

	return best_id

# 查詢兩聚落間路線距離 (若無商隊則採用預設路線天數)
func get_route_days_between(world: WorldState, origin_id: StringName, dest_id: StringName) -> int:
	for c_id in world.caravans:
		var c: CaravanState = world.caravans[c_id]
		if (c.origin_id == origin_id and c.destination_id == dest_id) or (c.origin_id == dest_id and c.destination_id == origin_id):
			return c.route_days
	return DEFAULT_MIGRATION_ROUTE_DAYS

# S3-F 聚落治安度動態更新 (Security Dynamics - Civic Capacity & Needs Desperation)
func update_settlement_security(settlement: SettlementState) -> void:
	if settlement.reference_population <= 0:
		return

	var civic_capacity_ratio: float = clampf(float(settlement.population) / float(settlement.reference_population), 0.0, 1.0)
	var civic_capacity_drag: float = (1.0 - civic_capacity_ratio) * CIVIC_CAPACITY_DRAG_RATE
	var max_pressure: float = maxf(settlement.water_pressure, settlement.food_pressure)
	var desperation_drag: float = (max_pressure / 100.0) * DESPERATION_DRAG_RATE

	var total_drag: float = civic_capacity_drag + desperation_drag
	if total_drag > 0.0:
		settlement.security = maxf(0.0, settlement.security - total_drag)
	elif civic_capacity_ratio >= 0.8 and max_pressure == 0.0:
		settlement.security = minf(100.0, settlement.security + SECURITY_RECOVERY_RATE)

# S3-F 在地秩序損耗判定 (Local Disorder Loss - 確定性小數累加器)
func apply_settlement_disorder_loss(
	settlement: SettlementState,
	snapshot_security: float,
	current_day: int,
	tick_events: Array[EventRecord],
	world: WorldState
) -> void:
	var lost: Dictionary = {}
	for res in [&"scrap", &"fuel"]:
		var res_str := String(res)
		var stock: int = settlement.inventory.get_amount(res_str)
		if stock > 0:
			var current_credit: float = settlement.disorder_loss_credits.get(res_str, 0.0)
			current_credit += float(stock) * DISORDER_LOSS_RATE
			var to_remove: int = int(floor(current_credit + 1e-9))
			current_credit = maxf(0.0, current_credit - float(to_remove))
			settlement.disorder_loss_credits[res_str] = current_credit

			if to_remove > 0:
				to_remove = mini(to_remove, stock)
				settlement.inventory.add_amount(res_str, -to_remove)
				settlement.cumulative_disorder_loss[res_str] = settlement.cumulative_disorder_loss.get(res_str, 0) + to_remove
				lost[res_str] = to_remove

	if lost.size() > 0:
		var loss_evt := EventRecord.new(
			current_day,
			"DISORDER_LOSS",
			settlement.id,
			settlement.id,
			{
				"security": snapshot_security,
				"lost": lost,
				"inventory_after": settlement.inventory.to_dict()
			}
		)
		tick_events.append(loss_evt)
		world.record_event(loss_evt)

# S3-F 兩聚落間商路危險度推導 (Route Risk Derivation)
func calculate_route_risk(world: WorldState, origin_id: StringName, dest_id: StringName) -> float:
	var orig: SettlementState = world.get_settlement(origin_id)
	var dest: SettlementState = world.get_settlement(dest_id)
	var orig_sec: float = orig.security if orig != null else 100.0
	var dest_sec: float = dest.security if dest != null else 100.0
	return ((100.0 - orig_sec) + (100.0 - dest_sec)) / 2.0

# 不變量檢查函式
# ==============================================================================
# S4-F1: AUTONOMOUS DECISION PHASE
# ==============================================================================
# BATCH SEMANTICS, deliberately:
#
#   start-of-phase observation snapshot
#     -> every NPC decides from that SAME world, in canonical npc_id order
#     -> intents collected
#     -> canonical commit order
#     -> revalidate preconditions
#     -> commit or reject
#
# NOT this:
#   Mara decides and immediately changes the world, then Eli observes a world
#   Mara already altered, then Jon observes a third world.
#
# Sequential decisions would make the outcome depend on iteration order, which
# is exactly the kind of thing that quietly breaks replay. If we ever want
# sequential semantics, that will be a deliberate design decision with its own
# evidence, not an accident of Dictionary ordering.
#
# Intents are NOT committed blindly. Between deciding and committing the world
# may have moved (an earlier commit in this same batch can empty a settlement),
# so every intent is revalidated at commit time. A refused intent leaves
# evidence and nothing else, never a world event saying it happened.
func run_npc_decision_phase(world: WorldState, current_day: int, tick_events: Array[EventRecord]) -> void:
	if world.npc_life_state_registry == null:
		return

	# 1. OBSERVE - one immutable snapshot for the whole batch.
	# Canonical order is LEXICOGRAPHIC npc_id order, obtained by sorting Strings.
	# Sorting StringName values directly is NOT safe here: StringName compares by
	# internal pointer, so `[&"zeta", &"alpha", &"mid"].sort()` yields
	# [mid, alpha, zeta]. That ordering depends on allocation, not on the id, and
	# would make evaluation order an accident. Gate F6 exists because of this.
	var decider_ids: Array[StringName] = []
	var sorted_npc_ids: Array[String] = []
	for k in world.npc_life_state_registry.life_states:
		sorted_npc_ids.append(String(k))
	sorted_npc_ids.sort()
	for npc_id_str in sorted_npc_ids:
		var npc_id := StringName(npc_id_str)
		# The player is a named NPC in every other respect, but nobody decides for
		# the player. Without this the decision engine would quietly evacuate them
		# from a failing town - removing the very choice the game is about.
		if world.player != null and npc_id == world.player.npc_id:
			continue
		var ls: NpcLifeState = world.npc_life_state_registry.life_states[npc_id]
		# Only a settled, living individual has anything to decide in S4-F1.
		if ls.is_alive() and ls.status == NpcLifeState.Status.SETTLED:
			decider_ids.append(npc_id)
	if decider_ids.is_empty():
		return

	var observations: Array[NpcDecisionObservation] = []
	for npc_id in decider_ids:
		var obs := build_npc_observation(world, npc_id, current_day)
		if obs != null:
			observations.append(obs)

	# 2. DECIDE - pure functions of the observations. No world access.
	var intents: Array[NpcDecisionIntent] = []
	for obs in observations:
		intents.append(NpcDecisionEngine.decide(obs))

	# 3. AUTHORIZE, REVALIDATE, COMMIT - in canonical order.
	for intent in intents:
		var auth_error := NpcDecisionEngine.authorize(intent)
		if auth_error != "":
			world.record_decision(NpcDecisionEvidence.create(
				current_day, "PHASE_1_5_NPC_DECISION", intent,
				NpcDecisionEvidence.Result.REJECTED, auth_error, -1
			))
			continue

		if intent.action == NpcDecisionEngine.Action.STAY:
			world.record_decision(NpcDecisionEvidence.create(
				current_day, "PHASE_1_5_NPC_DECISION", intent,
				NpcDecisionEvidence.Result.NO_OP, "", -1
			))
			continue

		# MIGRATE: revalidate against the world as it is NOW, not as observed.
		var revalidation := revalidate_migration_intent(world, intent)
		if revalidation != "":
			world.record_decision(NpcDecisionEvidence.create(
				current_day, "PHASE_1_5_NPC_DECISION", intent,
				NpcDecisionEvidence.Result.REJECTED, revalidation, -1
			))
			continue

		# Commit through the EXISTING S4-B atomic lifecycle transaction. The
		# decision layer owns no mutation path of its own.
		var route_days := get_route_days_between(world, intent.observation.current_settlement_id, intent.destination_id)
		var party_id := StringName("refugee:named_d%d_%s_to_%s" % [
			current_day,
			String(intent.observation.current_settlement_id).replace("settlement:", ""),
			String(intent.destination_id).replace("settlement:", "")
		])
		var result: Dictionary = world.npc_life_state_registry.begin_named_migration(
			world, intent.npc_id, intent.destination_id, party_id, route_days, current_day
		)
		if not result["success"]:
			world.record_decision(NpcDecisionEvidence.create(
				current_day, "PHASE_1_5_NPC_DECISION", intent,
				NpcDecisionEvidence.Result.REJECTED, String(result.get("error", "")), -1
			))
			continue

		var evt := EventRecord.new(
			current_day,
			"NAMED_NPC_MIGRATION_STARTED",
			intent.npc_id,
			intent.destination_id,
			{
				"origin": String(intent.observation.current_settlement_id),
				"destination": String(intent.destination_id),
				"party_id": String(party_id),
				"route_days": route_days,
				"rule_invoked": String(intent.rule_invoked),
				"water_pressure": intent.observation.water_pressure,
				"food_pressure": intent.observation.food_pressure,
				"security": intent.observation.security,
			}
		)
		tick_events.append(evt)
		world.record_event(evt)
		world.record_decision(NpcDecisionEvidence.create(
			current_day, "PHASE_1_5_NPC_DECISION", intent,
			NpcDecisionEvidence.Result.COMMITTED, "", world.event_log.size() - 1
		))

# Build the narrow read-only projection this NPC is allowed to see.
func build_npc_observation(world: WorldState, npc_id: StringName, current_day: int) -> NpcDecisionObservation:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(npc_id)
	if ls == null:
		return null
	var here: SettlementState = world.get_settlement(ls.population_container_id)
	if here == null:
		return null

	# Destination candidates come from the world OWN evaluation (S3-C), not a
	# private algorithm for named individuals. Otherwise the anonymous cohort
	# could believe New Hope is safest while Mara walks to Dry Well, with no
	# stated reason for the disagreement.
	var candidates: Array = []
	var best := select_refugee_destination(world, here)
	if best != &"":
		var dest: SettlementState = world.get_settlement(best)
		if dest != null:
			candidates.append({
				"settlement_id": String(best),
				"route_days": get_route_days_between(world, here.id, best),
				"water_pressure": NumericCanon.canonical_float(dest.water_pressure),
				"food_pressure": NumericCanon.canonical_float(dest.food_pressure),
				"security": NumericCanon.canonical_float(dest.security),
			})

	return NpcDecisionObservation.create(
		npc_id, current_day, here.id,
		here.water_pressure, here.food_pressure, here.security,
		candidates
	)

# Preconditions re-checked at commit time. Returns "" when the intent may proceed.
func revalidate_migration_intent(world: WorldState, intent: NpcDecisionIntent) -> String:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.npc_id)
	if ls == null:
		return "PRECONDITION_CHANGED: no life state"
	if not ls.is_alive():
		return "PRECONDITION_CHANGED: NPC is no longer alive"
	if ls.status != NpcLifeState.Status.SETTLED:
		return "PRECONDITION_CHANGED: NPC is no longer settled"
	if ls.population_container_id != intent.observation.current_settlement_id:
		return "PRECONDITION_CHANGED: NPC is no longer in the observed settlement"
	var origin: SettlementState = world.get_settlement(ls.population_container_id)
	if origin == null:
		return "PRECONDITION_CHANGED: origin settlement no longer exists"
	if origin.population <= 0:
		return "PRECONDITION_CHANGED: origin settlement has no population left"
	if origin.population <= MIGRATION_MIN_POPULATION:
		return "PRECONDITION_CHANGED: origin population at or below migration floor (%d)" % MIGRATION_MIN_POPULATION
	if world.get_settlement(intent.destination_id) == null:
		return "PRECONDITION_CHANGED: destination no longer exists"
	return ""

func validate_invariants(world: WorldState) -> String:
	var field_error := WorldState.Field.validate_world(world)
	if field_error != "":
		return field_error
	if world.player != null:
		if world.player.capability == null:
			return "MISSING_CAPABILITY_PROFILE"
		var capability_data: Dictionary = world.player.capability.to_dict()
		var capability_error: String = PlayerState.Capability.validate(capability_data)
		if capability_error != "":
			return capability_error
		if capability_data.npc_id != String(world.player.npc_id):
			return "CAPABILITY_OWNER_MISMATCH"
		for skill_id in capability_data.get("skill_practice", {}):
			if int(capability_data.skill_practice[skill_id].last_day) > world.current_day:
				return "PRACTICE_DAY_IN_FUTURE"
	for s_id in world.settlements:
		var s: SettlementState = world.settlements[s_id]
		for res in COMMODITIES:
			var stock := s.inventory.get_amount(res)
			if stock < 0:
				return "Settlement %s has negative %s: %d" % [s.id, res, stock]
			var price := s.get_current_price(res)
			if price <= 0.0 or is_nan(price) or is_inf(price):
				return "Settlement %s has invalid %s price: %f" % [s.id, res, price]

		# S3-A 人口與代謝率不變量檢驗
		if s.population < 0:
			return "Settlement %s has negative population: %d" % [s.id, s.population]
		if is_nan(s.metabolism_water_rate) or is_inf(s.metabolism_water_rate) or s.metabolism_water_rate < 0.0:
			return "Settlement %s has invalid metabolism_water_rate: %f" % [s.id, s.metabolism_water_rate]
		if is_nan(s.metabolism_food_rate) or is_inf(s.metabolism_food_rate) or s.metabolism_food_rate < 0.0:
			return "Settlement %s has invalid metabolism_food_rate: %f" % [s.id, s.metabolism_food_rate]

		# S3-B 短缺壓力與需求會計不變量檢驗
		if s.water_pressure < 0.0 or s.water_pressure > 100.0 or is_nan(s.water_pressure) or is_inf(s.water_pressure):
			return "Settlement %s has invalid water_pressure: %f" % [s.id, s.water_pressure]
		if s.food_pressure < 0.0 or s.food_pressure > 100.0 or is_nan(s.food_pressure) or is_inf(s.food_pressure):
			return "Settlement %s has invalid food_pressure: %f" % [s.id, s.food_pressure]
		if s.days_since_last_migration < 0:
			return "Settlement %s has negative days_since_last_migration: %d" % [s.id, s.days_since_last_migration]

		# S3-D 匱乏暴露時長與累積死亡不變量檢驗
		if s.water_exposure < 0.0 or is_nan(s.water_exposure) or is_inf(s.water_exposure):
			return "Settlement %s has invalid water_exposure: %f" % [s.id, s.water_exposure]
		if s.food_exposure < 0.0 or is_nan(s.food_exposure) or is_inf(s.food_exposure):
			return "Settlement %s has invalid food_exposure: %f" % [s.id, s.food_exposure]
		if s.cumulative_deaths < 0:
			return "Settlement %s has negative cumulative_deaths: %d" % [s.id, s.cumulative_deaths]

		for r in ["water", "food"]:
			if s.last_need_outcomes.has(r):
				var o: Dictionary = s.last_need_outcomes[r]
				if o["requested"] != o["fulfilled"] + o["unmet"]:
					return "Settlement %s %s accounting broken: %d != %d + %d" % [
						s.id, r, o["requested"], o["fulfilled"], o["unmet"]
					]

		# S3-E 基準人口與生產累加器不變量檢驗
		if s.reference_population < 0:
			return "Settlement %s has negative reference_population: %d" % [s.id, s.reference_population]
		for res in COMMODITIES:
			var credit: float = s.production_credits.get(res, 0.0)
			if credit < 0.0 or is_nan(credit) or is_inf(credit) or credit >= 1.0 + 1e-5:
				return "Settlement %s has invalid production_credit for %s: %f" % [s.id, res, credit]

		# S3-F 治安度與在地秩序損耗不變量檢驗
		if s.security < 0.0 or s.security > 100.0 or is_nan(s.security) or is_inf(s.security):
			return "Settlement %s has invalid security: %f" % [s.id, s.security]
		for res in COMMODITIES:
			var credit: float = s.disorder_loss_credits.get(res, 0.0)
			if credit < 0.0 or is_nan(credit) or is_inf(credit) or credit >= 1.0 + 1e-5:
				return "Settlement %s has invalid disorder_loss_credit for %s: %f" % [s.id, res, credit]
		for res in s.cumulative_disorder_loss:
			var loss_amt: int = s.cumulative_disorder_loss[res]
			if loss_amt < 0:
				return "Settlement %s has negative cumulative_disorder_loss for %s: %d" % [s.id, res, loss_amt]

	for c_id in world.caravans:
		var c: CaravanState = world.caravans[c_id]
		for res in COMMODITIES:
			var cargo_amt := c.cargo.get_amount(res)
			if cargo_amt < 0:
				return "Caravan %s has negative %s cargo: %d" % [c.id, res, cargo_amt]

		if not world.settlements.has(c.origin_id):
			return "Caravan %s references non-existent origin: %s" % [c.id, c.origin_id]
		if not world.settlements.has(c.destination_id):
			return "Caravan %s references non-existent destination: %s" % [c.id, c.destination_id]
		if c.is_active and not c.is_destroyed and c.days_remaining < 0:
			return "Caravan %s has negative days remaining: %d" % [c.id, c.days_remaining]
		if c.is_destroyed and c.get_total_cargo() != 0:
			return "Destroyed caravan %s retains cargo: %s" % [c.id, c.cargo.to_dict()]

	# S3-C 難民隊伍不變量檢驗
	for r_id in world.refugees:
		var r: RefugeePartyState = world.refugees[r_id]
		# S4-B 例外（僅此一種）：named-only refugee party 於全部具名 NPC 完成 arrival 後，
		# headcount 會被 complete_named_migration() 遞減至 0。此為該 party 的
		# **合法終態（legal terminal state）**，且必然伴隨 is_arrived == true。
		# 注意：headcount <= 0 在 is_active 且尚未 is_arrived 的 party 上仍是 corruption，
		# 必須 fail-closed。請勿將本例外放寬為「所有 headcount=0 的 party 皆合法」。
		if r.headcount <= 0 and (r.is_active and not r.is_arrived):
			return "Refugee party %s has non-positive headcount: %d" % [r.id, r.headcount]
		if not world.settlements.has(r.origin_id):
			return "Refugee party %s references non-existent origin: %s" % [r.id, r.origin_id]
		if not world.settlements.has(r.destination_id):
			return "Refugee party %s references non-existent destination: %s" % [r.id, r.destination_id]
		if r.is_active and not r.is_arrived and r.days_remaining < 0:
			return "Refugee party %s has negative days remaining: %d" % [r.id, r.days_remaining]

	# S3-D 全域人類生命總量守恆不變量 (Living + In-Transit + Cumulative Deaths == Initial)
	var current_living_pop := 0
	var total_deaths := 0
	for s_id in world.settlements:
		var s: SettlementState = world.settlements[s_id]
		current_living_pop += s.population
		total_deaths += s.cumulative_deaths
	for r_id in world.refugees:
		var r: RefugeePartyState = world.refugees[r_id]
		if r.is_active and not r.is_arrived:
			current_living_pop += r.headcount

	var total_accounted := current_living_pop + total_deaths
	if world.total_initial_population >= 0 and total_accounted != world.total_initial_population:
		return "Global population conservation broken: living (%d) + deaths (%d) = %d != initial (%d)" % [
			current_living_pop, total_deaths, total_accounted, world.total_initial_population
		]

	# S4-A Identity invariants (origin_settlement_id reference integrity)
	if world.npc_registry != null:
		for npc in world.npc_registry.get_all_npcs():
			if not world.settlements.has(npc.origin_settlement_id):
				return "NPC %s has invalid origin_settlement_id: %s" % [npc.id, npc.origin_settlement_id]

	# S4-B Life State invariants (B1: Exactly-One Container, B2: Subset Invariant, B3: DEAD has no container)
	if world.npc_life_state_registry != null:
		var seen_in_containers: Dictionary = {}  # npc_id -> container_id (for dual membership check)

		for k in world.npc_life_state_registry.life_states:
			var ls: NpcLifeState = world.npc_life_state_registry.life_states[k]

			# B3: DEAD NPC must have NONE container
			if ls.status == NpcLifeState.Status.DEAD:
				if ls.population_container_type != NpcLifeState.ContainerType.NONE or ls.population_container_id != &"":
					return "S4-B B3: DEAD NPC %s still has a living container: type=%d id=%s" % [
						ls.npc_id, ls.population_container_type, ls.population_container_id
					]
				continue

			# B1: Living NPC must have valid container
			if ls.status == NpcLifeState.Status.SETTLED:
				if ls.population_container_type != NpcLifeState.ContainerType.SETTLEMENT:
					return "S4-B B1: SETTLED NPC %s has wrong container type: %d" % [ls.npc_id, ls.population_container_type]
				if not world.settlements.has(ls.population_container_id):
					return "S4-B B1: SETTLED NPC %s references non-existent settlement %s" % [ls.npc_id, ls.population_container_id]
			elif ls.status == NpcLifeState.Status.IN_TRANSIT:
				if ls.population_container_type != NpcLifeState.ContainerType.REFUGEE_PARTY:
					return "S4-B B1: IN_TRANSIT NPC %s has wrong container type: %d" % [ls.npc_id, ls.population_container_type]
				if not world.refugees.has(ls.population_container_id):
					return "S4-B B1: IN_TRANSIT NPC %s references non-existent party %s" % [ls.npc_id, ls.population_container_id]

			# Track for dual membership detection
			var container_key := str(int(ls.population_container_type)) + ":" + String(ls.population_container_id)
			if seen_in_containers.has(String(ls.npc_id)):
				return "S4-B B1: NPC %s appears in multiple containers!" % ls.npc_id
			seen_in_containers[String(ls.npc_id)] = container_key

		# B2: Named-settled count <= settlement population
		for s_id in world.settlements:
			var s: SettlementState = world.settlements[s_id]
			var named_settled := world.npc_life_state_registry.get_named_living_count_in_settlement(s.id)
			if named_settled > s.population:
				return "S4-B B2: Named SETTLED count at %s (%d) > aggregate population (%d)" % [
					s.id, named_settled, s.population
				]

		# B2': Named-transit count <= refugee party headcount
		for r_id in world.refugees:
			var party: RefugeePartyState = world.refugees[r_id]
			if party.is_active and not party.is_arrived:
				var named_transit := world.npc_life_state_registry.get_named_living_count_in_party(party.id)
				if named_transit > party.headcount:
					return "S4-B B2: Named IN_TRANSIT count in party %s (%d) > headcount (%d)" % [
						party.id, named_transit, party.headcount
					]

	# S4-C Profile invariants (C1: closed enum, C6: profiles ⊆ identities, living only)
	if world.npc_profile_registry != null:
		for k in world.npc_profile_registry.profiles:
			var profile: NpcProfile = world.npc_profile_registry.profiles[k]
			if not NpcProfile.is_valid_background(profile.background):
				return "S4-C C1: NPC %s carries background value %d outside the closed enum" % [
					profile.npc_id, profile.background
				]
			if not world.npc_registry.has_npc(profile.npc_id):
				return "S4-C C6: Profile %s has no corresponding identity (profiles must be a subset of identities)" % profile.npc_id
			var p_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(profile.npc_id)
			if p_ls == null:
				return "S4-C C6: Profile %s has no life state" % profile.npc_id
			# S4-D: traits are closed-enum, duplicate-free, and canonically ordered.
			var seen_traits := {}
			var last_trait := -1
			for t in profile.traits:
				if not NpcProfile.is_valid_trait(t):
					return "S4-D D1: NPC %s carries trait value %d outside the closed enum" % [profile.npc_id, t]
				if seen_traits.has(t):
					return "S4-D D3: NPC %s holds duplicate trait %s" % [profile.npc_id, NpcProfile.trait_name(t)]
				if t < last_trait:
					return "S4-D D3: NPC %s traits are not in canonical order" % profile.npc_id
				seen_traits[t] = true
				last_trait = t
			# S4-E: aptitudes follow the same set-like discipline.
			var seen_apts := {}
			var last_apt := -1
			for a in profile.aptitudes:
				if not NpcProfile.is_valid_aptitude(a):
					return "S4-E E1: NPC %s carries aptitude value %d outside the closed enum" % [profile.npc_id, a]
				if seen_apts.has(a):
					return "S4-E E3: NPC %s holds duplicate aptitude %s" % [profile.npc_id, NpcProfile.aptitude_name(a)]
				if a < last_apt:
					return "S4-E E3: NPC %s aptitudes are not in canonical order" % profile.npc_id
				seen_apts[a] = true
				last_apt = a

	# S4-C.1 Event Ledger invariants (L4: derived count, payload representability)
	if world.get_event_count() != world.event_log.size():
		return "S4-C.1 L4: derived event_count (%d) disagrees with ledger size (%d)" % [
			world.get_event_count(), world.event_log.size()
		]
	for i in range(world.event_log.size()):
		var rec: EventRecord = world.event_log[i]
		var rec_err := rec.validate()
		if rec_err != "":
			return "S4-C.1 L3: events[%d] (%s) is not persistable: %s" % [i, rec.type, rec_err]

	# S5-A Player Avatar invariants
	if world.player != null:
		var p: PlayerState = world.player
		if not world.npc_registry.has_npc(p.npc_id):
			return "S5-A: Player npc_id %s not in npc_registry" % p.npc_id
		if not world.npc_life_state_registry.has_life_state(p.npc_id):
			return "S5-A: Player npc_id %s has no life state" % p.npc_id
		if p.money < 0:
			return "S5-A: Player has negative money: %d" % p.money
		if p.capacity_total <= 0:
			return "S5-A: Player has non-positive capacity: %d" % p.capacity_total
		if p.inventory != null:
			if p.get_total_inventory_load() > p.get_effective_capacity():
				return "S5-A: Player inventory exceeds capacity (%d > %d)" % [
					p.get_total_inventory_load(), p.get_effective_capacity()
				]
			for res in COMMODITIES:
				if p.inventory.get_amount(res) < 0:
					return "S5-A: Player has negative %s: %d" % [res, p.inventory.get_amount(res)]
		if p.water_pressure < 0.0 or p.water_pressure > 100.0 or is_nan(p.water_pressure) or is_inf(p.water_pressure):
			return "S5-A: Player has invalid water_pressure: %f" % p.water_pressure
		if p.food_pressure < 0.0 or p.food_pressure > 100.0 or is_nan(p.food_pressure) or is_inf(p.food_pressure):
			return "S5-A: Player has invalid food_pressure: %f" % p.food_pressure

	return ""

# ==============================================================================
# S5-A: PLAYER AVATAR ARCHITECTURE & LIFECYCLE
# ==============================================================================

# ==============================================================================
# S5-B5: PLAYER SURVIVAL
# ==============================================================================
# Water and food are only real resources if going without them costs something.
# This reuses the model the world already runs on settlements, so a person and a
# town suffer by the same rules:
#
#   need outcome -> pressure -> equivalent deprivation exposure -> grace -> death
#
# The two situations differ in WHERE the need is met from, and that difference
# is the whole reason double metabolism has to be avoided:
#
#   IN TRANSIT: nobody is feeding you. Requested 1 water + 1 food per day, met
#               from your own backpack. This is what makes "three days of road,
#               two days of water" an actual decision before departure.
#
#   SETTLED:    you are already counted inside settlement.population, and the
#               settlement consumed on your behalf during Phase 1. Taking from
#               the backpack as well would charge you twice. Instead the player
#               shares the town's fortune: if Gray Valley met 40% of its water
#               need today, the player went 60% unmet too. You do not get to be
#               personally fine in a town that is dying of thirst, and you do
#               not get to drink your backpack dry while the town is fine.
#
# Deliberately NOT here: HP, stamina, injury, disease, combat, succession.
func process_player_daily_needs(world: WorldState, current_day: int, tick_events: Array[EventRecord]) -> void:
	if world.player == null:
		return

	var p: PlayerState = world.player
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(p.npc_id)
	if ls == null or not ls.is_alive():
		return

	var water_unmet_ratio := 0.0
	var food_unmet_ratio := 0.0

	if ls.status == NpcLifeState.Status.IN_TRANSIT:
		# Requested one of each per day, met from the backpack.
		var cur_water := p.inventory.get_amount("water")
		if cur_water >= 1:
			p.inventory.set_amount("water", cur_water - 1)
		else:
			water_unmet_ratio = 1.0

		var cur_food := p.inventory.get_amount("food")
		if cur_food >= 1:
			p.inventory.set_amount("food", cur_food - 1)
		else:
			food_unmet_ratio = 1.0

	elif ls.status == NpcLifeState.Status.SETTLED:
		# Share the settlement's fortune; consume nothing personally.
		var s: SettlementState = world.get_settlement(ls.population_container_id)
		if s == null:
			return
		water_unmet_ratio = _settlement_unmet_ratio(s, "water")
		food_unmet_ratio = _settlement_unmet_ratio(s, "food")

		# Private rations. If the town could not meet its need today, the player
		# may fall back on what they are carrying. This protects the PLAYER only:
		# it adds nothing to settlement inventory, relieves nobody else's
		# pressure and changes no aggregate figure. Sharing your water with a
		# town and drinking it yourself stay completely different acts.
		if water_unmet_ratio > 0.0 and p.inventory.get_amount("water") >= 1:
			p.inventory.set_amount("water", p.inventory.get_amount("water") - 1)
			water_unmet_ratio = 0.0
		if food_unmet_ratio > 0.0 and p.inventory.get_amount("food") >= 1:
			p.inventory.set_amount("food", p.inventory.get_amount("food") - 1)
			food_unmet_ratio = 0.0

	_apply_player_need_outcome(p, water_unmet_ratio, food_unmet_ratio)
	_check_player_mortality(world, p, ls, current_day, tick_events)

# How much of what this settlement asked for today went unmet, 0.0 .. 1.0.
func _settlement_unmet_ratio(s: SettlementState, resource: String) -> float:
	if not s.last_need_outcomes.has(resource):
		return 0.0
	var outcome: Dictionary = s.last_need_outcomes[resource]
	var requested: int = int(outcome.get("requested", 0))
	var unmet: int = int(outcome.get("unmet", 0))
	if requested <= 0 or unmet <= 0:
		return 0.0
	return clampf(float(unmet) / float(requested), 0.0, 1.0)

# Same pressure and exposure arithmetic the settlements use.
func _apply_player_need_outcome(p: PlayerState, water_unmet_ratio: float, food_unmet_ratio: float) -> void:
	if water_unmet_ratio > 0.0:
		p.water_pressure = minf(100.0, p.water_pressure + water_unmet_ratio * WATER_PRESSURE_GAIN_RATE)
		p.water_exposure += water_unmet_ratio
	else:
		p.water_pressure = maxf(0.0, p.water_pressure - WATER_PRESSURE_RECOVERY_RATE)
		p.water_exposure = maxf(0.0, p.water_exposure - DEPRIVATION_RECOVERY_RATE)

	if food_unmet_ratio > 0.0:
		p.food_pressure = minf(100.0, p.food_pressure + food_unmet_ratio * FOOD_PRESSURE_GAIN_RATE)
		p.food_exposure += food_unmet_ratio
	else:
		p.food_pressure = maxf(0.0, p.food_pressure - FOOD_PRESSURE_RECOVERY_RATE)
		p.food_exposure = maxf(0.0, p.food_exposure - DEPRIVATION_RECOVERY_RATE)

# A hard day does not kill anyone. Sustained deprivation past the grace period
# does, and thirst kills far sooner than hunger.
func _check_player_mortality(world: WorldState, p: PlayerState, ls: NpcLifeState, current_day: int, tick_events: Array[EventRecord]) -> void:
	var cause := ""
	if p.water_exposure > WATER_EXPOSURE_GRACE_DAYS:
		cause = "dehydration"
	elif p.food_exposure > FOOD_EXPOSURE_GRACE_DAYS:
		cause = "starvation"
	if cause == "":
		return

	var died_in_transit: bool = ls.status == NpcLifeState.Status.IN_TRANSIT
	var last_place := ls.population_container_id
	var death_res: Dictionary = world.npc_life_state_registry.commit_named_death(world, p.npc_id)
	if not death_res.get("success", false):
		return

	var death_evt := EventRecord.new(
		current_day,
		"PLAYER_DIED",
		p.npc_id,
		StringName(String(death_res.get("settlement_id", last_place))),
		{
			"cause": cause,
			"days_survived": current_day,
			"in_transit": died_in_transit,
			"water_exposure": p.water_exposure,
			"food_exposure": p.food_exposure,
		}
	)
	if tick_events != null:
		tick_events.append(death_evt)
	world.record_event(death_evt)

# C0 headless entry point. Stage the existing materialization lifecycle on a
# private copy; a rejected operation never allocates IDs or writes real history.
func commit_character_creation(world: WorldState, intent: RefCounted) -> Dictionary:
	const CreationIntent = preload("res://simulation/character_creation_intent.gd")
	const Catalogue = preload("res://simulation/background_catalogue.gd")
	if not intent is CreationIntent:
		return {"success": false, "error": "INVALID_CREATION_INTENT"}
	var input: Dictionary = intent.to_dict()
	if input.size() != 5:
		return {"success": false, "error": "INVALID_CREATION_FIELDS"}
	for field in ["source_settlement_id", "character_name", "background_id", "trait_ids", "age"]:
		if not input.has(field):
			return {"success": false, "error": "MISSING_CREATION_FIELD: " + field}
	if typeof(input.source_settlement_id) != TYPE_STRING or typeof(input.character_name) != TYPE_STRING or input.character_name.strip_edges().is_empty() or typeof(input.age) != TYPE_INT or input.age < 0:
		return {"success": false, "error": "INVALID_CREATION_IDENTITY"}
	if world.player != null:
		return {"success": false, "error": "PLAYER_ALREADY_EXISTS"}
	var package: Dictionary = Catalogue.resolve(input.background_id)
	if not package.success:
		return package
	var trait_error: String = PlayerState.Capability.validate_traits(input.trait_ids)
	if trait_error != "":
		return {"success": false, "error": trait_error}
	var existing_error := validate_invariants(world)
	if existing_error != "":
		return {"success": false, "error": existing_error}
	var staged := world.duplicate_state()
	var result := materialize_player(staged, StringName(input.source_settlement_id), input.character_name, input.age, package.background)
	if not result.success:
		return result
	var profile_result: Dictionary = PlayerState.Capability.from_dict_checked({
		"npc_id": String(staged.player.npc_id), "creation_origin": "CHARACTER_CREATION",
		"background_id": input.background_id, "package_version": package.version,
		"skill_ranks": package.ranks, "selected_creation_traits": input.trait_ids,
	})
	if not profile_result.success:
		return {"success": false, "error": profile_result.error}
	staged.player.capability = profile_result.profile
	staged.record_event(EventRecord.new(staged.current_day, "CHARACTER_CREATED", staged.player.npc_id, StringName(input.source_settlement_id), {
		"background_id": input.background_id, "package_version": package.version,
		"selected_creation_traits": profile_result.profile.to_dict().selected_creation_traits,
	}))
	var error := validate_invariants(staged)
	if error != "":
		return {"success": false, "error": error}
	world.npc_registry = staged.npc_registry
	world.npc_life_state_registry = staged.npc_life_state_registry
	world.npc_profile_registry = staged.npc_profile_registry
	world.next_npc_sequence = staged.next_npc_sequence
	world.player = staged.player
	world.event_log = staged.event_log
	return {"success": true, "npc_id": world.player.npc_id, "player": world.player, "error": ""}

func materialize_player(
	world: WorldState,
	settlement_id: StringName,
	name: String = "Drifter",
	age: int = 25,
	background: int = NpcProfile.Background.SCAVENGER
) -> Dictionary:
	if world.player != null:
		return {"success": false, "error": "PLAYER_ALREADY_EXISTS: World already has an active player avatar"}

	var settlement: SettlementState = world.get_settlement(settlement_id)
	if settlement == null:
		return {"success": false, "error": "INVALID_SETTLEMENT: Settlement %s not found" % settlement_id}

	# Claim an anonymous population slot in the settlement
	var id_res := world.npc_registry.materialize_identity(world, settlement_id, name, age)
	if not id_res["success"]:
		return id_res

	var nid: StringName = id_res["npc"].id

	# Register settled life state
	var ls_res := world.npc_life_state_registry.register_life_state(world, nid, settlement_id)
	if not ls_res["success"]:
		return ls_res

	# Assign background biography
	var prof_res := world.npc_profile_registry.assign_background(world, nid, background)
	if not prof_res["success"]:
		return prof_res

	# Create player avatar state
	var p := PlayerState.new(nid, 20, 50)
	p.inventory.set_amount(&"water", 5)
	p.inventory.set_amount(&"food", 5)
	world.player = p

	var evt := EventRecord.new(
		world.current_day,
		"PLAYER_MATERIALIZED",
		nid,
		settlement_id,
		{
			"name": name,
			"age": age,
			"background": background,
			"capacity": p.capacity_total,
			"money": p.money
		}
	)
	world.record_event(evt)

	return {
		"success": true,
		"player": p,
		"npc_id": nid,
		"settlement_id": settlement_id
	}

static func get_buy_quote(settlement: SettlementState, commodity: StringName) -> int:
	if settlement == null:
		return 1
	var price := settlement.get_current_price(String(commodity))
	return maxi(1, int(ceil(price)))

static func get_sell_quote(settlement: SettlementState, commodity: StringName) -> int:
	if settlement == null:
		return 1
	var price := settlement.get_current_price(String(commodity))
	return maxi(1, int(floor(price)))

static func get_item_buy_quote(settlement: SettlementState, item_id: StringName, market: RefCounted = null) -> int:
	if settlement == null:
		return 0
	return ItemMarketState.buy_quote(item_id, settlement.id, market)

static func get_item_sell_quote(settlement: SettlementState, item_id: StringName) -> int:
	if settlement == null:
		return 0
	return ItemMarketState.sell_quote(item_id, settlement.id)

func _authorize_equipment_intent(world: WorldState, intent: PlayerIntent, equipping: bool) -> String:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
	if ls == null or ls.status != NpcLifeState.Status.SETTLED:
		return "INVALID_STATUS: Equipment can only change while settled"
	var expected_size := 2 if equipping else 1
	if typeof(intent.payload) != TYPE_DICTIONARY or intent.payload.size() != expected_size or typeof(intent.payload.get("slot", "")) != TYPE_STRING:
		return "INVALID_EQUIPMENT_INTENT"
	var candidate: RefCounted = world.player.equipment.duplicate_state()
	if equipping:
		if typeof(intent.payload.get("item_id", "")) != TYPE_STRING:
			return "INVALID_EQUIPMENT_INTENT"
		var result: Dictionary = candidate.equip(intent.payload.item_id, intent.payload.slot, world.player.item_inventory)
		if not result.success:
			return String(result.error)
	else:
		var removed: Dictionary = candidate.unequip(intent.payload.slot)
		if not removed.success:
			return String(removed.error)
	var candidate_player: PlayerState = world.player.duplicate_state()
	candidate_player.equipment = candidate
	if candidate_player.get_total_inventory_load() > candidate_player.get_effective_capacity():
		return "INSUFFICIENT_CAPACITY: Cargo load %d exceeds capacity %d" % [
			candidate_player.get_total_inventory_load(), candidate_player.get_effective_capacity()
		]
	return ""

func _commit_equipment_intent(world: WorldState, intent: PlayerIntent, equipping: bool, tick_events: Array[EventRecord]) -> Dictionary:
	var equipment: RefCounted = world.player.equipment.duplicate_state()
	var result: Dictionary
	var action_name := "EQUIP" if equipping else "UNEQUIP"
	if equipping:
		result = equipment.equip(intent.payload.item_id, intent.payload.slot, world.player.item_inventory)
	else:
		result = equipment.unequip(intent.payload.slot)
	if not result.success:
		return {"success": false, "error": String(result.error)}
	world.player.equipment = equipment
	var payload := {
		"action": action_name,
		"slot": String(intent.payload.slot),
		"item_id": String(result.item_id)
	}
	var event := EventRecord.new(world.current_day, "EQUIPMENT_CHANGED", intent.player_id, StringName("equipment"), payload)
	if tick_events != null:
		tick_events.append(event)
	world.record_event(event)
	return {"success": true, "action": action_name, "slot": result.slot, "item_id": result.item_id}

func _item_market_view(settlement: SettlementState) -> RefCounted:
	if settlement.item_market != null:
		return settlement.item_market
	return ItemMarketState.seeded_for(settlement.id)

func _authorize_item_trade(world: WorldState, settlement: SettlementState, intent: PlayerIntent, buying: bool) -> String:
	if intent.commodity != &"":
		return "INVALID_ITEM_TRADE: item trade cannot also carry an aggregate commodity"
	if intent.quantity <= 0:
		return "INVALID_QUANTITY: Quantity must be positive, got %d" % intent.quantity
	var resolved := ItemRegistry.resolve(String(intent.item_id))
	if not resolved.success:
		return "UNKNOWN_ITEM_ID: Item '%s' is not registered" % intent.item_id
	var profile := ItemMarketCatalogue.profile_for(intent.item_id, settlement.id)
	if not profile.success:
		return "INVALID_ITEM_MARKET: %s" % profile.error
	var market := _item_market_view(settlement)
	if buying:
		if not profile.is_routinely_supplied:
			return "ITEM_NOT_SOLD_HERE: %s has no routine supply in %s" % [intent.item_id, settlement.id]
		if market.quantity(intent.item_id) < intent.quantity:
			return "INSUFFICIENT_ITEM_STOCK: %s has %d, requested %d" % [intent.item_id, market.quantity(intent.item_id), intent.quantity]
		var quote := get_item_buy_quote(settlement, intent.item_id, market)
		var total_cost := quote * intent.quantity
		if world.player.money < total_cost:
			return "INSUFFICIENT_FUNDS: Player has %d caps, total cost is %d" % [world.player.money, total_cost]
		var candidate: RefCounted = world.player.item_inventory.duplicate_state()
		var pickup: Dictionary = candidate.pickup_item(String(intent.item_id), intent.quantity)
		if not pickup.success:
			return String(pickup.error)
		return ""
	if profile.demand == "none":
		return "ITEM_NOT_BOUGHT_HERE: %s has no demand in %s" % [intent.item_id, settlement.id]
	if not world.player.item_inventory.contains(String(intent.item_id), intent.quantity):
		return "INSUFFICIENT_PLAYER_ITEM: Player does not hold %d of %s" % [intent.quantity, intent.item_id]
	for slot in EquipmentState.SLOTS:
		if world.player.equipment.equipped_item(slot) == String(intent.item_id):
			return "ITEM_EQUIPPED: Unequip %s before selling it" % intent.item_id
	var sell_quote := get_item_sell_quote(settlement, intent.item_id)
	var total_revenue := sell_quote * intent.quantity
	if settlement.market_cash < total_revenue:
		return "INSUFFICIENT_MARKET_CASH: Settlement %s has %d caps, required %d" % [settlement.id, settlement.market_cash, total_revenue]
	return ""

func _commit_item_trade(world: WorldState, intent: PlayerIntent, tick_events: Array[EventRecord]) -> Dictionary:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
	var settlement: SettlementState = world.get_settlement(ls.population_container_id)
	var buying := intent.action == PlayerIntent.Action.BUY
	var market: RefCounted = settlement.item_market.duplicate_state() if settlement.item_market != null else ItemMarketState.seeded_for(settlement.id)
	var player_items: RefCounted = world.player.item_inventory.duplicate_state()
	var quote := get_item_buy_quote(settlement, intent.item_id, market) if buying else get_item_sell_quote(settlement, intent.item_id)
	var total := quote * intent.quantity
	if buying:
		market.remove(String(intent.item_id), intent.quantity)
		player_items.pickup_item(String(intent.item_id), intent.quantity)
		settlement.market_cash += total
		world.player.money -= total
	else:
		player_items.drop_item(String(intent.item_id), intent.quantity)
		market.add(String(intent.item_id), intent.quantity)
		settlement.market_cash -= total
		world.player.money += total
	settlement.item_market = market
	world.player.item_inventory = player_items
	var action_name := "BUY" if buying else "SELL"
	var practice := _practice_after_action(world, "BARTER")
	var trade_payload := {
		"action": action_name, "item_id": String(intent.item_id), "quantity": intent.quantity,
		"unit_price": quote, "total_amount": total,
		"market_stock": market.quantity(intent.item_id),
		"settlement_cash": settlement.market_cash, "player_money": world.player.money,
	}
	if not practice.is_empty():
		trade_payload["skill_practice"] = practice
	var evt := EventRecord.new(
		world.current_day,
		"ITEM_TRADE_COMPLETED",
		intent.player_id,
		settlement.id,
		trade_payload
	)
	if tick_events != null:
		tick_events.append(evt)
	world.record_event(evt)
	var result := trade_payload.duplicate(true)
	result["success"] = true
	return result

func _practice_after_action(world: WorldState, skill_id: String, action_day: int = -1) -> Dictionary:
	if world.player == null or world.player.capability == null:
		return {}
	var practice: Dictionary = world.player.capability.grant_practice(skill_id,
		world.current_day if action_day < 0 else action_day)
	if not practice.get("awarded", false):
		return {}
	return {"skill_id": skill_id, "rank_up": practice.rank_up,
		"from_rank": practice.from_rank, "to_rank": practice.to_rank,
		"points": practice.points, "required": practice.required}

# ==============================================================================
# S5-B4.1: WHAT IS ACTUALLY HAPPENING ON THIS ROAD
# ==============================================================================
# The road is not a backdrop. These are the facts the world can offer about the
# stretch the player is walking, and they decide what can be met out there.
func gather_road_facts(world: WorldState, party: RefugeePartyState) -> Dictionary:
	var origin: SettlementState = world.get_settlement(party.origin_id)
	var destination: SettlementState = world.get_settlement(party.destination_id)

	var min_security := 100.0
	if origin != null:
		min_security = minf(min_security, origin.security)
	if destination != null:
		min_security = minf(min_security, destination.security)

	var facts := {
		"min_security": min_security,
		"destination_water_pressure": destination.water_pressure if destination != null else 0.0,
		"origin_water_pressure": origin.water_pressure if origin != null else 0.0,
		"thirsty_place_name": _thirsty_end_of_road(world, origin, destination),
		"refugee_column": _find_refugee_column(world, party),
		"fresh_wreck": _find_fresh_wreck(world, party),
	}
	if party != null and party.route_type != &"":
		facts["route_type"] = String(party.route_type)
	return facts

# Whichever end of this road is in real water trouble, if either is.
func _thirsty_end_of_road(world: WorldState, origin: SettlementState, destination: SettlementState) -> String:
	var worst: SettlementState = null
	if origin != null and origin.water_pressure >= 50.0:
		worst = origin
	if destination != null and destination.water_pressure >= 50.0:
		if worst == null or destination.water_pressure > worst.water_pressure:
			worst = destination
	if worst == null:
		return ""
	return _settlement_display_name(world, worst.id)

# A column of people actually walking this road right now. Not a spawned prop:
# this is a party the simulation created because a settlement failed them.
func _find_refugee_column(world: WorldState, player_party: RefugeePartyState) -> Dictionary:
	var sorted_ids: Array[String] = []
	for k in world.refugees:
		sorted_ids.append(String(k))
	sorted_ids.sort()
	for r_id_str in sorted_ids:
		var r: RefugeePartyState = world.refugees[StringName(r_id_str)]
		if r.id == player_party.id or not r.is_active or r.is_arrived or r.headcount <= 0:
			continue
		var same_road: bool = (r.origin_id == player_party.origin_id and r.destination_id == player_party.destination_id) \
			or (r.origin_id == player_party.destination_id and r.destination_id == player_party.origin_id)
		if same_road:
			return {
				"party_id": String(r.id),
				"headcount": r.headcount,
				"origin": String(r.origin_id),
				"destination": String(r.destination_id),
			}
	return {}

# A caravan this road really lost in the last few days. If the world recorded a
# predation or a destruction here, the player can walk past the evidence.
const FRESH_WRECK_WINDOW_DAYS: int = 12

func _find_fresh_wreck(world: WorldState, party: RefugeePartyState) -> Dictionary:
	var cutoff := world.current_day - FRESH_WRECK_WINDOW_DAYS
	var start := maxi(0, world.event_log.size() - 200)
	for i in range(world.event_log.size() - 1, start - 1, -1):
		var evt: EventRecord = world.event_log[i]
		if evt.day < cutoff:
			break
		if evt.type != "TRANSIT_PREDATION" and evt.type != "CARAVAN_DESTROYED":
			continue
		var o := String(evt.payload.get("origin", ""))
		var d := String(evt.payload.get("destination", ""))
		var same_road: bool = (o == String(party.origin_id) and d == String(party.destination_id)) \
			or (o == String(party.destination_id) and d == String(party.origin_id))
		if same_road:
			return {"day": evt.day, "type": evt.type}
	return {}

# Only the facts this particular encounter needs, so the stored context stays
# small and readable in a snapshot.
func _encounter_context(world: WorldState, facts: Dictionary, encounter_type: StringName) -> Dictionary:
	var ctx := {}
	match encounter_type:
		TravelEncounter.REFUGEE_COLUMN:
			var column: Dictionary = facts.get("refugee_column", {})
			ctx = {
				"headcount": column.get("headcount", 0),
				"origin_name": _settlement_display_name(world, StringName(String(column.get("origin", "")))),
				"destination_name": _settlement_display_name(world, StringName(String(column.get("destination", "")))),
			}
		TravelEncounter.WRECK:
			ctx = {"fresh_wreck": facts.get("fresh_wreck", {})}
		TravelEncounter.ROADBLOCK:
			ctx = {"min_security": facts.get("min_security", 100.0)}
		TravelEncounter.DEHYDRATED_TRAVELLER:
			# Someone dying of thirst on this road most likely walked out of
			# whichever end of it has run dry. Name that place only when it is
			# genuinely in trouble, so the detail is never invented.
			ctx = {"from_name": String(facts.get("thirsty_place_name", ""))}
	if facts.has("route_type"):
		ctx["route_type"] = String(facts.get("route_type", ""))
	return ctx

func _settlement_display_name(world: WorldState, settlement_id: StringName) -> String:
	var s: SettlementState = world.get_settlement(settlement_id)
	if s != null and s.name != "":
		return s.name
	return String(settlement_id).replace("settlement:", "")

# ==============================================================================
# S5-B4: TRAVEL ENCOUNTERS
# ==============================================================================
# The travel-day index is DERIVED from the party rather than stored, so a saved
# journey cannot come back disagreeing with itself about how far along it is.
func _travel_day_index(party: RefugeePartyState) -> int:
	return party.route_days - party.days_remaining

func _check_travel_encounter(world: WorldState, ls: NpcLifeState) -> void:
	if world.active_encounter != null:
		return
	var party: RefugeePartyState = world.get_refugee_party(ls.population_container_id)
	if party == null:
		return
	# Nothing happens on the day you arrive; the road is behind you.
	if party.days_remaining <= 0:
		return

	var index := _travel_day_index(party)
	var facts := gather_road_facts(world, party)
	var encounter_type := TravelEncounter.select(
		facts, party.origin_id, party.destination_id, party.departure_day, index
	)
	if encounter_type == &"":
		return

	world.active_encounter = TravelEncounterState.create(
		encounter_type, world.current_day, party.origin_id, party.destination_id, index,
		_encounter_context(world, facts, encounter_type)
	)

	var evt := EventRecord.new(
		world.current_day,
		"TRAVEL_ENCOUNTER",
		world.player.npc_id if world.player != null else &"",
		party.destination_id,
		{
			"encounter_type": String(encounter_type),
			"origin": String(party.origin_id),
			"destination": String(party.destination_id),
			"travel_day_index": index,
		}
	)
	world.record_event(evt)

func _encounter_party_route(world: WorldState, enc: TravelEncounterState) -> String:
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or life.status != NpcLifeState.Status.IN_TRANSIT:
		return ""
	var party: RefugeePartyState = world.get_refugee_party(life.population_container_id)
	if party == null or party.origin_id != enc.origin_id or party.destination_id != enc.destination_id:
		return ""
	return String(party.route_type)

# Spend a day without getting any closer. The journey is padded by one day so
# that ticking costs time and supplies without also advancing progress: a
# detour is lost time, not free travel.
func _spend_extra_travel_day(world: WorldState, player_id: StringName) -> void:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(player_id)
	if ls != null and ls.status == NpcLifeState.Status.IN_TRANSIT:
		var party: RefugeePartyState = world.get_refugee_party(ls.population_container_id)
		if party != null:
			party.days_remaining += 1
	tick(world)

# What an encounter option costs, checked before anything is committed.
func authorize_encounter_option(world: WorldState, option_id: StringName) -> String:
	if world.pending_encounter_result >= 0:
		return "ENCOUNTER_RESULT_PENDING: confirm the previous result first"
	var enc := world.active_encounter
	if enc == null:
		return "NO_ACTIVE_ENCOUNTER: there is nothing on the road to answer"
	if not TravelEncounter.has_option(enc.encounter_type, option_id, enc.context):
		return "INVALID_OPTION: %s is not an option for %s" % [option_id, enc.encounter_type]

	var p: PlayerState = world.player
	var practice_skill: String = TravelEncounter.practice_skill(enc.encounter_type, option_id)
	if practice_skill != "" and p.capability != null:
		var practice_check: Dictionary = p.capability.get_practice_progress(practice_skill)
		if not practice_check.success:
			return "CAPABILITY_CHECK_FAILED: %s" % practice_check.error
		if world.current_day < 0:
			return "INVALID_PRACTICE_DAY: encounter day must be nonnegative"

	# S5-C2: an approach the character cannot take is refused HERE, at the
	# commit boundary, not merely hidden by the UI. The projection filters the
	# same catalogue with the same evaluator, so the two agree; but a replayed
	# intent, an old save or a UI that has drifted still cannot buy an approach
	# this character does not have.
	var requirements := TravelEncounter.option_requirements(enc.encounter_type, option_id)
	if not requirements.is_empty():
		if p.capability == null:
			return "CAPABILITY_UNAVAILABLE: %s requires a capability profile" % option_id
		var check: Dictionary = p.capability.meets_requirements(requirements)
		if not check.success:
			return "CAPABILITY_CHECK_FAILED: %s" % check.error
		if not check.met:
			return "CAPABILITY_NOT_MET: %s requires %s" % [
				option_id, TravelEncounter.option_requirement_label(enc.encounter_type, option_id)
			]
	var required_item := TravelEncounter.option_item_requirement(enc.encounter_type, option_id)
	if required_item != "" and not p.inspect_item(required_item).success:
		return "ITEM_NOT_HELD: %s requires %s" % [
			option_id, TravelEncounter.option_requirement_label(enc.encounter_type, option_id)
		]

	match option_id:
		&"CLEAR":
			if p.inventory.get_amount("scrap") < 1:
				return "INSUFFICIENT_SCRAP: clearing the road needs 1 scrap"
		&"PAY":
			if p.money < ROADBLOCK_TOLL_CAPS:
				return "INSUFFICIENT_FUNDS: the toll is %d caps" % ROADBLOCK_TOLL_CAPS
		&"PERSUADE":
			if p.money < ROADBLOCK_TOLL_CAPS:
				return "INSUFFICIENT_FUNDS: the toll is %d caps" % ROADBLOCK_TOLL_CAPS
		&"HAGGLE":
			if p.money < TravelEncounter.HAGGLED_TOLL_CAPS:
				return "INSUFFICIENT_FUNDS: even the haggled toll is %d caps" % TravelEncounter.HAGGLED_TOLL_CAPS
		&"GIVE_WATER":
			if p.inventory.get_amount("water") < 1:
				return "INSUFFICIENT_WATER: you have none to give"
		&"HYDRATE":
			if p.inventory.get_amount("water") < 1:
				return "INSUFFICIENT_WATER: you have none to give"
		&"SHARE_FOOD":
			if p.inventory.get_amount("food") < 1:
				return "INSUFFICIENT_FOOD: you have nothing to share"
		&"TRADE_COLUMN":
			if p.money < TravelEncounter.COLUMN_TRADE_CAPS:
				return "INSUFFICIENT_FUNDS: they want %d caps" % TravelEncounter.COLUMN_TRADE_CAPS
		&"FIGHT":
			if not world.field_state.battle.is_empty() or world.field_state.receipt >= 0:
				return "FIELD_BATTLE_CONFLICT: field battle or receipt is already pending"
			if p.field_kit == null or p.field_kit.get("hp", 0) <= 0:
				return "PLAYER_UNABLE_TO_FIGHT: player has no health"
		&"BRIBE":
			if p.money < TravelEncounter.BANDIT_BRIBE_CAPS:
				return "INSUFFICIENT_FUNDS: the bandits demand %d caps" % TravelEncounter.BANDIT_BRIBE_CAPS
		&"PARLEY":
			if p.money < TravelEncounter.BANDIT_BRIBE_CAPS:
				return "INSUFFICIENT_FUNDS: the bandits demand %d caps" % TravelEncounter.BANDIT_BRIBE_CAPS
		&"FLEE_ROAD":
			pass
	return ""

# Apply the choice and its time cost atomically, then wait for receipt confirmation.
func commit_encounter_choice(world: WorldState, option_id: StringName) -> Dictionary:
	var auth := authorize_encounter_option(world, option_id)
	if auth != "":
		return {"success": false, "error": auth}

	var enc := world.active_encounter
	var p: PlayerState = world.player
	var encounter_type := enc.encounter_type
	var committed_route_type := _encounter_party_route(world, enc)

	if option_id == &"FIGHT":
		var origin_str: String = String(enc.origin_id)
		var dest_str: String = String(enc.destination_id)
		var travel_idx: int = enc.travel_day_index
		world.active_encounter = null
		world.pending_encounter_result = -1
		var battle_info: Dictionary = WorldState.Field.begin_road_battle(world, {
			"encounter_type": "BANDIT_AMBUSH",
			"origin": origin_str,
			"destination": dest_str,
			"travel_day_index": travel_idx,
		})
		world.record_event(EventRecord.new(
			world.current_day,
			"ROAD_COMBAT_BEGAN",
			p.npc_id,
			StringName(dest_str),
			{
				"encounter_type": "BANDIT_AMBUSH",
				"battle_id": battle_info.id,
				"origin": origin_str,
			"destination": dest_str,
			"travel_day_index": travel_idx,
			}
		))
		return {
			"success": true,
			"action": "START_ROAD_COMBAT",
			"battle_id": battle_info.id,
			"current_day": world.current_day,
		}
	var gained: Dictionary = {}
	var spent: Dictionary = {}
	var extra_day := false
	var offered: Dictionary = {}
	var offered_items: Dictionary = {}
	var gained_items: Dictionary = {}
	var items_left_behind: Dictionary = {}
	var inventory_before := {}
	var day_before := world.current_day
	var persuasion_success := false
	var stealth_success := false
	for commodity in COMMODITIES:
		inventory_before[commodity] = p.inventory.get_amount(commodity)

	match option_id:
		&"SEARCH":
			# What is under this particular truck. Capped by what you can carry;
			# the ledger records what was really taken, not what was on offer.
			offered = TravelEncounter.wreck_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
			offered_items = TravelEncounter.wreck_item_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, option_id, committed_route_type)
			extra_day = true
		&"CLEAR":
			p.inventory.add_amount("scrap", -1)
			spent["scrap"] = 1
		&"PAY":
			p.money -= ROADBLOCK_TOLL_CAPS
			spent["caps"] = ROADBLOCK_TOLL_CAPS
		&"PERSUADE":
			persuasion_success = TravelEncounter.check_persuasion_success(
				enc.encounter_type, enc.origin_id, enc.destination_id, enc.day, enc.travel_day_index,
				p.capability.get_rank("SPEECH"), enc.context)
			var cost: int = TravelEncounter.ROADBLOCK_PERSUADED_CAPS if persuasion_success else ROADBLOCK_TOLL_CAPS
			p.money -= cost
			spent["caps"] = cost
		&"GIVE_WATER":
			p.inventory.add_amount("water", -1)
			spent["water"] = 1
			offered = TravelEncounter.traveller_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
		&"DETOUR":
			extra_day = true
		&"SHARE_FOOD":
			p.inventory.add_amount("food", -1)
			spent["food"] = 1
			offered = TravelEncounter.refugee_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
		&"LEAVE":
			pass

		# ── S5-C2 capability approaches ──────────────────────────────────────
		# Each one is the same road answered by a different person. They move
		# existing resources and existing days only; none of them creates a
		# world fact the simulation could not already state.
		&"STRIP_PARTS":
			offered = TravelEncounter.strip_parts_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
			offered_items = TravelEncounter.wreck_item_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, option_id, committed_route_type)
			extra_day = true
		&"USE_WRENCH":
			offered = TravelEncounter.strip_parts_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
			offered_items = TravelEncounter.wreck_item_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, option_id, committed_route_type)
			extra_day = true
		&"QUICK_PICK":
			# The capability bought is the DAY, not the loot: no tick happens.
			offered = TravelEncounter.quick_pick_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
			offered_items = TravelEncounter.wreck_item_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index, option_id)
		&"SCOUT_PATH":
			pass
		&"FORCE_THROUGH":
			# Stated before the choice and taken from what is actually in the
			# pack, so the receipt can never claim you dropped something you
			# never carried. Carrying nothing costs nothing.
			for commodity in TravelEncounter.FORCE_THROUGH_LOSS_PRIORITY:
				if p.inventory.get_amount(commodity) >= 1:
					_take_from_player(p, {commodity: 1})
					break
		&"USE_ROPE":
			pass
		&"HAGGLE":
			p.money -= TravelEncounter.HAGGLED_TOLL_CAPS
			spent["caps"] = TravelEncounter.HAGGLED_TOLL_CAPS
		&"SLIP_PAST":
			stealth_success = TravelEncounter.check_stealth_success(
				enc.encounter_type, enc.origin_id, enc.destination_id, enc.day, enc.travel_day_index,
				p.capability.get_rank("STEALTH"), enc.context)
			extra_day = true
		&"HYDRATE":
			p.inventory.add_amount("water", -1)
			spent["water"] = 1
			offered = TravelEncounter.hydrate_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
		&"TAKE_PACK":
			offered = TravelEncounter.take_pack_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
		&"TRADE_COLUMN":
			p.money -= TravelEncounter.COLUMN_TRADE_CAPS
			spent["caps"] = TravelEncounter.COLUMN_TRADE_CAPS
			offered = TravelEncounter.column_trade_yield(
				enc.day, enc.origin_id, enc.destination_id, enc.travel_day_index)
		&"BRIBE":
			p.money -= TravelEncounter.BANDIT_BRIBE_CAPS
			spent["caps"] = TravelEncounter.BANDIT_BRIBE_CAPS
		&"PARLEY":
			persuasion_success = TravelEncounter.check_persuasion_success(
				enc.encounter_type, enc.origin_id, enc.destination_id, enc.day, enc.travel_day_index,
				p.capability.get_rank("SPEECH"), enc.context)
			var cost: int = TravelEncounter.BANDIT_PERSUADED_CAPS if persuasion_success else TravelEncounter.BANDIT_BRIBE_CAPS
			p.money -= cost
			spent["caps"] = cost
		&"FLEE_ROAD":
			extra_day = true

	gained = _give_player_goods(p, offered)
	for item_id in offered_items:
		var requested_items: int = int(offered_items[item_id])
		var item_result := p.pickup_item(item_id, requested_items)
		if item_result.success:
			gained_items[item_id] = requested_items
		else:
			items_left_behind[item_id] = requested_items
	var left_behind := {}
	for commodity in offered:
		var amount := int(offered[commodity]) - int(gained.get(commodity, 0))
		if amount > 0:
			left_behind[commodity] = amount

	world.active_encounter = null
	if extra_day:
		_spend_extra_travel_day(world, p.npc_id)

	var ls_after := world.npc_life_state_registry.get_life_state(p.npc_id)
	var player_alive: bool = ls_after != null and ls_after.is_alive()
	if not player_alive:
		stealth_success = false

	# Measure actual consumption, including the extra day's metabolism. No
	# subsequent travel has happened yet, and missing rations are not fake losses.
	for commodity in COMMODITIES:
		var consumed := int(inventory_before[commodity]) + int(gained.get(commodity, 0)) - p.inventory.get_amount(commodity)
		if consumed > 0:
			spent[commodity] = consumed
	var receipt := {
		"encounter_type": String(encounter_type), "option": String(option_id),
		"gained": gained, "spent": spent, "left_behind": left_behind,
		"cost_extra_day": extra_day, "elapsed_days": world.current_day - day_before,
		"origin": String(enc.origin_id), "destination": String(enc.destination_id),
	}
	var skill_id: String = TravelEncounter.practice_skill(encounter_type, option_id)
	if not player_alive:
		skill_id = ""
	elif option_id in [&"PERSUADE", &"PARLEY"] and not persuasion_success:
		skill_id = ""
	elif option_id == &"SLIP_PAST" and not stealth_success:
		skill_id = ""
	if skill_id != "":
		var practice := _practice_after_action(world, skill_id, day_before)
		if not practice.is_empty():
			receipt["skill_practice"] = practice
	if option_id in [&"PERSUADE", &"PARLEY"]:
		receipt["persuasion_success"] = persuasion_success
	if option_id == &"SLIP_PAST":
		receipt["stealth_success"] = stealth_success
		if not stealth_success and player_alive:
			var resume_context: Dictionary = enc.context.duplicate(true)
			resume_context["stealth_failed"] = true
			receipt["resume_encounter"] = {
				"encounter_type": String(enc.encounter_type),
				"day": world.current_day,
				"origin_id": String(enc.origin_id),
				"destination_id": String(enc.destination_id),
				"travel_day_index": enc.travel_day_index,
				"context": resume_context,
			}
	if not gained_items.is_empty() or not items_left_behind.is_empty():
		receipt["items_gained"] = gained_items
		receipt["items_left_behind"] = items_left_behind
	var backpack_needed_for_haul := p.get_total_inventory_load() > p.capacity_total
	if enc.encounter_type == TravelEncounter.WRECK and option_id == &"SEARCH" and String(enc.context.get("route_type", "")) == "WILDERNESS" and (not gained.is_empty() or not gained_items.is_empty()) and left_behind.is_empty() and items_left_behind.is_empty() and p.equipment != null and p.equipment.equipped_item("back") == "travel_backpack" and backpack_needed_for_haul:
		receipt["attribution"] = "旅行背包讓你把貨車殘骸中的物資全部帶走。"
	world.record_event(EventRecord.new(world.current_day, "TRAVEL_ENCOUNTER_RESOLVED", p.npc_id, enc.destination_id, receipt))
	world.pending_encounter_result = world.event_log.size() - 1
	var result := receipt.duplicate(true)
	result.merge({"success": true, "action": "RESOLVE_ENCOUNTER", "days_travelled": 0,
		"arrived": false, "current_day": world.current_day})
	return result

# Confirmation consumes the receipt exactly once, then resumes existing travel.
func _continue_after_encounter(world: WorldState) -> Dictionary:
	var receipt_index := world.pending_encounter_result
	world.pending_encounter_result = -1
	var ls := world.npc_life_state_registry.get_life_state(world.player.npc_id)
	var result := {"days_travelled": 0, "arrived": false}
	if ls != null and ls.is_alive():
		var last_event: EventRecord = world.event_log[receipt_index] if receipt_index >= 0 and receipt_index < world.event_log.size() else null
		var resume_enc: Dictionary = last_event.payload.get("resume_encounter", {}) if last_event != null and typeof(last_event.payload) == TYPE_DICTIONARY else {}
		if not resume_enc.is_empty():
			world.active_encounter = TravelEncounterState.from_dict(resume_enc)
			result["resumed_encounter"] = true
		elif ls.status == NpcLifeState.Status.IN_TRANSIT:
			var party := world.get_refugee_party(ls.population_container_id)
			result = advance_player_travel(world, world.player.npc_id, party.days_remaining)
		else:
			result["arrived"] = ls.status == NpcLifeState.Status.SETTLED
	result.merge({"success": true, "action": "CONTINUE_JOURNEY", "current_day": world.current_day})
	return result

# Take goods off the player, limited by what is actually in the pack. Returns
# what was really taken; the end-of-commit inventory comparison then reports it
# as spent, so there is only one place that decides what a loss looks like.
func _take_from_player(p: PlayerState, goods: Dictionary) -> Dictionary:
	var taken: Dictionary = {}
	for key in goods:
		var actual: int = clampi(int(goods[key]), 0, p.inventory.get_amount(String(key)))
		if actual > 0:
			p.inventory.add_amount(String(key), -actual)
			taken[key] = actual
	return taken

# Hand goods to the player, limited by what the backpack can hold. Returns what
# was actually received.
func _give_player_goods(p: PlayerState, goods: Dictionary) -> Dictionary:
	var received: Dictionary = {}
	for key in goods:
		var wanted: int = int(goods[key])
		var room: int = p.get_effective_capacity() - p.get_total_inventory_load()
		var actual: int = clampi(wanted, 0, maxi(room, 0))
		if actual > 0:
			p.inventory.add_amount(String(key), actual)
			received[key] = actual
	return received

func authorize_player_intent(world: WorldState, intent: PlayerIntent) -> String:
	if world.player == null:
		return "NO_PLAYER: World does not have an active player avatar"
	if intent.player_id != world.player.npc_id:
		return "INVALID_PLAYER_ID: Intent player_id %s does not match world player %s" % [
			intent.player_id, world.player.npc_id
		]
	if not PlayerIntent.is_authorized_action(intent.action):
		return "UNAUTHORIZED_ACTION: %s is outside the S5-B2 closed action space" % PlayerIntent.action_name(intent.action)

	if intent.action == PlayerIntent.Action.FIELD_ACTION:
		return WorldState.Field.authorize(world, intent.payload)
	if not world.field_state.battle.is_empty() or world.field_state.receipt >= 0:
		return "FIELD_ACTIVITY_PENDING"

	# A dead player may dismiss a fatal receipt, but cannot resume travelling.
	if intent.action == PlayerIntent.Action.CONTINUE_JOURNEY:
		var receipt: Variant = intent.payload.get("result_index", -1)
		if typeof(receipt) not in [TYPE_INT, TYPE_FLOAT] or receipt != world.pending_encounter_result or world.pending_encounter_result < 0:
			return "NO_MATCHING_ENCOUNTER_RESULT: receipt is absent or already confirmed"
		return ""
	if world.pending_encounter_result >= 0:
		return "ENCOUNTER_RESULT_PENDING: confirm the result before acting"

	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
	if ls == null or not ls.is_alive():
		return "DECEASED_OR_NO_LIFE_STATE: Player is not alive or has no life state"

	# Standing in front of an unanswered encounter, nothing else is available.
	if world.active_encounter != null and intent.action != PlayerIntent.Action.RESOLVE_ENCOUNTER:
		return "ENCOUNTER_PENDING: the road is waiting for an answer"

	match intent.action:
		PlayerIntent.Action.ACCEPT_QUEST, PlayerIntent.Action.TURN_IN_QUEST:
			if intent.payload.size() != 1 or typeof(intent.payload.get("quest_id")) != TYPE_STRING:
				return "INVALID_QUEST_INTENT"
			var quest_script = load("res://simulation/quest_engine.gd")
			return quest_script.authorize_accept(world, String(intent.payload.quest_id)) if intent.action == PlayerIntent.Action.ACCEPT_QUEST else quest_script.authorize_turn_in(world, String(intent.payload.quest_id))
		PlayerIntent.Action.RESOLVE_ENCOUNTER:
			return authorize_encounter_option(world, StringName(String(intent.payload.get("option_id", ""))))
		PlayerIntent.Action.EQUIP_ITEM:
			return _authorize_equipment_intent(world, intent, true)
		PlayerIntent.Action.UNEQUIP_ITEM:
			return _authorize_equipment_intent(world, intent, false)
		PlayerIntent.Action.WAIT:
			return ""
		PlayerIntent.Action.TRAVEL:
			if ls.status != NpcLifeState.Status.SETTLED:
				return "INVALID_STATUS: Player must be SETTLED to begin travel (currently %d)" % ls.status
			if intent.destination_id == &"":
				return "INVALID_INTENT: TRAVEL requires a non-empty destination_id"
			if intent.destination_id == ls.population_container_id:
				return "INVALID_DESTINATION: Cannot travel to current settlement %s" % intent.destination_id
			if not world.settlements.has(intent.destination_id):
				return "INVALID_DESTINATION: Destination settlement %s does not exist" % intent.destination_id
			var origin: SettlementState = world.get_settlement(ls.population_container_id)
			if origin == null:
				return "INVALID_ORIGIN: Origin settlement %s does not exist" % ls.population_container_id
			if origin.population <= MIGRATION_MIN_POPULATION:
				return "PRECONDITION_CHANGED: Origin population (%d) is at or below minimum (%d)" % [
					origin.population, MIGRATION_MIN_POPULATION
				]
			return ""
		PlayerIntent.Action.BUY:
			if ls.status != NpcLifeState.Status.SETTLED:
				return "INVALID_STATUS: Player must be SETTLED to trade (currently %d)" % ls.status
			var settlement: SettlementState = world.get_settlement(ls.population_container_id)
			if settlement == null:
				return "INVALID_SETTLEMENT: Origin settlement %s does not exist" % ls.population_container_id
			if intent.item_id != &"":
				return _authorize_item_trade(world, settlement, intent, true)
			var comm_str := String(intent.commodity)
			if not comm_str in COMMODITIES:
				return "INVALID_COMMODITY: Commodity '%s' is not in %s" % [comm_str, COMMODITIES]
			if intent.quantity <= 0:
				return "INVALID_QUANTITY: Quantity must be positive, got %d" % intent.quantity
			var settlement_stock := settlement.inventory.get_amount(comm_str)
			if settlement_stock < intent.quantity:
				return "INSUFFICIENT_STOCK: Settlement %s has %d %s, requested %d" % [
					settlement.id, settlement_stock, comm_str, intent.quantity
				]
			var quote := get_buy_quote(settlement, intent.commodity)
			var total_cost := quote * intent.quantity
			if world.player.money < total_cost:
				return "INSUFFICIENT_FUNDS: Player has %d caps, total cost is %d" % [
					world.player.money, total_cost
				]
			if not world.player.has_cargo_capacity(intent.quantity):
				return "INSUFFICIENT_CAPACITY: Player carrying %d/%d, cannot fit %d" % [
					world.player.get_total_inventory_load(), world.player.get_effective_capacity(), intent.quantity
				]
			return ""
		PlayerIntent.Action.SELL:
			if ls.status != NpcLifeState.Status.SETTLED:
				return "INVALID_STATUS: Player must be SETTLED to trade (currently %d)" % ls.status
			var settlement: SettlementState = world.get_settlement(ls.population_container_id)
			if settlement == null:
				return "INVALID_SETTLEMENT: Origin settlement %s does not exist" % ls.population_container_id
			if intent.item_id != &"":
				return _authorize_item_trade(world, settlement, intent, false)
			var comm_str := String(intent.commodity)
			if not comm_str in COMMODITIES:
				return "INVALID_COMMODITY: Commodity '%s' is not in %s" % [comm_str, COMMODITIES]
			if intent.quantity <= 0:
				return "INVALID_QUANTITY: Quantity must be positive, got %d" % intent.quantity
			var player_stock := world.player.inventory.get_amount(comm_str)
			if player_stock < intent.quantity:
				return "INSUFFICIENT_PLAYER_STOCK: Player has %d %s, requested %d" % [
					player_stock, comm_str, intent.quantity
				]
			var quote := get_sell_quote(settlement, intent.commodity)
			var total_revenue := quote * intent.quantity
			if settlement.market_cash < total_revenue:
				return "INSUFFICIENT_MARKET_CASH: Settlement %s has %d caps, required %d" % [
					settlement.id, settlement.market_cash, total_revenue
				]
			return ""
	return "UNKNOWN_ACTION"

# ==============================================================================
# PLAYER TRAVEL (two explicit stages)
# ==============================================================================
# Stage 1 starts the journey and advances no time. Stage 2 lets the days pass.
# They are separate for two reasons: a travel encounter must be able to stop a
# journey mid-route and hand control back to the player, and the transit
# mechanics themselves (departure accounting, Axiom 9 arrival timing, backpack
# consumption) are verified one day at a time.
func begin_player_travel(world: WorldState, intent: PlayerIntent, tick_events: Array[EventRecord] = []) -> Dictionary:
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
	if ls == null:
		return {"success": false, "error": "INVALID_PLAYER: no life state"}
	var origin_id: StringName = ls.population_container_id
	var dest_id: StringName = intent.destination_id
	var route_type_str := String(intent.payload.get("route_type", ""))
	var route_type := StringName(route_type_str) if route_type_str != "" else &""
	var route_days: int = get_route_days_between(world, origin_id, dest_id)
	if route_type != &"":
		route_days = TravelRoute.get_route_days(origin_id, dest_id, route_type)
		if route_days < 1:
			return {"success": false, "error": "INVALID_ROUTE"}
	var party_id := StringName("refugee:player_d%d_%s_to_%s" % [
		world.current_day,
		String(origin_id).replace("settlement:", ""),
		String(dest_id).replace("settlement:", "")
	])

	var result: Dictionary = world.npc_life_state_registry.begin_named_migration(
		world, intent.player_id, dest_id, party_id, route_days, world.current_day,
		route_type
	)
	if not result["success"]:
		return result

	var travel_payload := {
		"origin": String(origin_id),
		"destination": String(dest_id),
		"party_id": String(party_id),
		"route_days": route_days
	}
	if route_type != &"":
		travel_payload["route_type"] = String(route_type)

	var travel_evt := EventRecord.new(
		world.current_day,
		"PLAYER_TRAVEL_STARTED",
		intent.player_id,
		dest_id,
		travel_payload
	)
	if tick_events != null:
		tick_events.append(travel_evt)
	world.record_event(travel_evt)

	var out_res := {
		"success": true,
		"action": "TRAVEL",
		"party_id": party_id,
		"route_days": route_days
	}
	if route_type != &"":
		out_res["route_type"] = String(route_type)
	return out_res

# Stage 2: run the clock until the journey ends. Written as "advance until
# something stops us" rather than "advance exactly route_days", so that a travel
# encounter can later halt the loop while the player is still on the road.
func advance_player_travel(world: WorldState, player_id: StringName, route_days: int) -> Dictionary:
	var days_travelled := 0
	var max_days := route_days + TRAVEL_SAFETY_MARGIN_DAYS
	while days_travelled < max_days and not is_player_travel_interrupted(world, player_id):
		tick(world)
		days_travelled += 1
		var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(player_id)
		if ls == null or ls.status != NpcLifeState.Status.IN_TRANSIT:
			break
		_check_travel_encounter(world, ls)
		if is_player_travel_interrupted(world, player_id):
			break

	var arrival_ls: NpcLifeState = world.npc_life_state_registry.get_life_state(player_id)
	return {
		"days_travelled": days_travelled,
		"arrived": arrival_ls != null and arrival_ls.status == NpcLifeState.Status.SETTLED
	}

# A journey halts while an encounter is waiting for an answer.
func is_player_travel_interrupted(world: WorldState, _player_id: StringName) -> bool:
	return world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0

func commit_player_intent(world: WorldState, intent: PlayerIntent, tick_events: Array[EventRecord] = []) -> Dictionary:
	var auth_err := authorize_player_intent(world, intent)
	if auth_err != "":
		return {"success": false, "error": auth_err}

	match intent.action:
		PlayerIntent.Action.ACCEPT_QUEST, PlayerIntent.Action.TURN_IN_QUEST:
			var quest_id := String(intent.payload.quest_id)
			var quest_script = load("res://simulation/quest_engine.gd")
			var accepting := intent.action == PlayerIntent.Action.ACCEPT_QUEST
			var quest_result: Dictionary = quest_script.accept(world, quest_id) if accepting else quest_script.turn_in(world, quest_id)
			if not quest_result.success:
				return quest_result
			var target: StringName = world.npc_life_state_registry.get_life_state(intent.player_id).population_container_id
			var event := EventRecord.new(world.current_day, "QUEST_ACCEPTED" if accepting else "QUEST_RESOLVED", intent.player_id, target, {
				"quest_id": quest_id,
				"deadline_day": world.quest_state.get_quest(quest_id).deadline_day if accepting else -1,
				"delivered": [] if accepting else quest_result.delivered,
				"rewards": [] if accepting else quest_result.rewards,
			})
			world.record_event(event)
			if tick_events != null:
				tick_events.append(event)
			return quest_result
		PlayerIntent.Action.FIELD_ACTION:
			return WorldState.Field.commit(world, self, intent.payload)
		PlayerIntent.Action.CONTINUE_JOURNEY:
			return _continue_after_encounter(world)
		PlayerIntent.Action.RESOLVE_ENCOUNTER:
			return commit_encounter_choice(world, StringName(String(intent.payload.get("option_id", ""))))
		PlayerIntent.Action.EQUIP_ITEM:
			return _commit_equipment_intent(world, intent, true, tick_events)
		PlayerIntent.Action.UNEQUIP_ITEM:
			return _commit_equipment_intent(world, intent, false, tick_events)

		PlayerIntent.Action.WAIT:
			var wait_evt := EventRecord.new(
				world.current_day,
				"PLAYER_WAIT",
				intent.player_id,
				world.npc_life_state_registry.get_life_state(intent.player_id).population_container_id,
				{}
			)
			if tick_events != null:
				tick_events.append(wait_evt)
			world.record_event(wait_evt)
			tick(world)
			return {"success": true, "action": "WAIT", "current_day": world.current_day}

		PlayerIntent.Action.TRAVEL:
			# Choosing a destination IS the decision. The days of walking are not
			# a second decision the player has to keep confirming, so time runs
			# forward on its own until the journey ends.
			var begin_res := begin_player_travel(world, intent, tick_events)
			if not begin_res.get("success", false):
				return begin_res
			var advance_res := advance_player_travel(world, intent.player_id, int(begin_res["route_days"]))
			begin_res["days_travelled"] = advance_res["days_travelled"]
			begin_res["arrived"] = advance_res["arrived"]
			begin_res["current_day"] = world.current_day
			return begin_res

		PlayerIntent.Action.BUY:
			if intent.item_id != &"":
				return _commit_item_trade(world, intent, tick_events)
			var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
			var settlement: SettlementState = world.get_settlement(ls.population_container_id)
			var comm_str := String(intent.commodity)
			var quote := get_buy_quote(settlement, intent.commodity)
			var total_cost := quote * intent.quantity

			settlement.inventory.add_amount(comm_str, -intent.quantity)
			settlement.market_cash += total_cost
			world.player.inventory.add_amount(comm_str, intent.quantity)
			world.player.money -= total_cost
			var buy_practice := _practice_after_action(world, "BARTER")

			var buy_payload := {
				"action": "BUY", "commodity": comm_str, "quantity": intent.quantity,
				"unit_price": quote, "total_amount": total_cost,
				"settlement_cash": settlement.market_cash, "player_money": world.player.money,
			}
			if not buy_practice.is_empty():
				buy_payload["skill_practice"] = buy_practice
			var trade_evt := EventRecord.new(
				world.current_day,
				"TRADE_COMPLETED",
				intent.player_id,
				settlement.id,
				buy_payload
			)
			if tick_events != null:
				tick_events.append(trade_evt)
			world.record_event(trade_evt)

			var buy_result := buy_payload.duplicate(true)
			buy_result["success"] = true
			return buy_result

		PlayerIntent.Action.SELL:
			if intent.item_id != &"":
				return _commit_item_trade(world, intent, tick_events)
			var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
			var settlement: SettlementState = world.get_settlement(ls.population_container_id)
			var comm_str := String(intent.commodity)
			var quote := get_sell_quote(settlement, intent.commodity)
			var total_revenue := quote * intent.quantity

			world.player.inventory.add_amount(comm_str, -intent.quantity)
			world.player.money += total_revenue
			settlement.inventory.add_amount(comm_str, intent.quantity)
			settlement.market_cash -= total_revenue
			var sell_practice := _practice_after_action(world, "BARTER")

			var sell_payload := {
				"action": "SELL", "commodity": comm_str, "quantity": intent.quantity,
				"unit_price": quote, "total_amount": total_revenue,
				"settlement_cash": settlement.market_cash, "player_money": world.player.money,
			}
			if not sell_practice.is_empty():
				sell_payload["skill_practice"] = sell_practice
			var trade_evt := EventRecord.new(
				world.current_day,
				"TRADE_COMPLETED",
				intent.player_id,
				settlement.id,
				sell_payload
			)
			if tick_events != null:
				tick_events.append(trade_evt)
			world.record_event(trade_evt)

			var sell_result := sell_payload.duplicate(true)
			sell_result["success"] = true
			return sell_result

	return {"success": false, "error": "UNREACHABLE"}

func execute_player_wait(world: WorldState) -> Dictionary:
	if world == null or world.player == null:
		return {"success": false, "error": "NO_PLAYER: World does not have an active player"}
	var intent := PlayerIntent.create_wait(world.player.npc_id)
	return commit_player_intent(world, intent)

func execute_player_buy(world: WorldState, commodity: StringName, quantity: int = 1) -> Dictionary:
	if world == null or world.player == null:
		return {"success": false, "error": "NO_PLAYER: World does not have an active player"}
	var intent := PlayerIntent.create_buy(world.player.npc_id, commodity, quantity)
	return commit_player_intent(world, intent)

func execute_player_sell(world: WorldState, commodity: StringName, quantity: int = 1) -> Dictionary:
	if world == null or world.player == null:
		return {"success": false, "error": "NO_PLAYER: World does not have an active player"}
	var intent := PlayerIntent.create_sell(world.player.npc_id, commodity, quantity)
	return commit_player_intent(world, intent)

func execute_player_buy_item(world: WorldState, item_id: StringName, quantity: int = 1) -> Dictionary:
	if world == null or world.player == null:
		return {"success": false, "error": "NO_PLAYER: World does not have an active player"}
	return commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, item_id, quantity))

func execute_player_sell_item(world: WorldState, item_id: StringName, quantity: int = 1) -> Dictionary:
	if world == null or world.player == null:
		return {"success": false, "error": "NO_PLAYER: World does not have an active player"}
	return commit_player_intent(world, PlayerIntent.create_sell_item(world.player.npc_id, item_id, quantity))

