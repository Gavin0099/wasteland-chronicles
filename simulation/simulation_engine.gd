class_name SimulationEngine
extends RefCounted

const COMMODITIES: Array[String] = ["water", "food", "scrap", "fuel"]

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
			if p.get_total_inventory_load() > p.capacity_total:
				return "S5-A: Player inventory exceeds capacity (%d > %d)" % [
					p.get_total_inventory_load(), p.capacity_total
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

func process_player_daily_needs(world: WorldState, current_day: int, tick_events: Array[EventRecord]) -> void:
	if world.player == null:
		return

	var p: PlayerState = world.player
	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(p.npc_id)
	if ls == null or not ls.is_alive():
		return

	# If IN_TRANSIT, consumption must come from personal backpack
	if ls.status == NpcLifeState.Status.IN_TRANSIT:
		var cur_water := p.inventory.get_amount(&"water")
		if cur_water >= 1:
			p.inventory.set_amount(&"water", cur_water - 1)
			p.water_pressure = maxf(0.0, p.water_pressure - 15.0)
			p.days_deprived_water = 0
		else:
			p.water_pressure = minf(100.0, p.water_pressure + 10.0)
			p.days_deprived_water += 1

		var cur_food := p.inventory.get_amount(&"food")
		if cur_food >= 1:
			p.inventory.set_amount(&"food", cur_food - 1)
			p.food_pressure = maxf(0.0, p.food_pressure - 15.0)
			p.days_deprived_food = 0
		else:
			p.food_pressure = minf(100.0, p.food_pressure + 10.0)
			p.days_deprived_food += 1

	elif ls.status == NpcLifeState.Status.SETTLED:
		var s: SettlementState = world.get_settlement(ls.population_container_id)
		if s != null:
			p.water_pressure = s.water_pressure
			p.food_pressure = s.food_pressure

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

func authorize_player_intent(world: WorldState, intent: PlayerIntent) -> String:
	if world.player == null:
		return "NO_PLAYER: World does not have an active player avatar"
	if intent.player_id != world.player.npc_id:
		return "INVALID_PLAYER_ID: Intent player_id %s does not match world player %s" % [
			intent.player_id, world.player.npc_id
		]
	if not PlayerIntent.is_authorized_action(intent.action):
		return "UNAUTHORIZED_ACTION: %s is outside the S5-A closed action space" % PlayerIntent.action_name(intent.action)

	var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
	if ls == null or not ls.is_alive():
		return "DECEASED_OR_NO_LIFE_STATE: Player is not alive or has no life state"

	match intent.action:
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
	return "UNKNOWN_ACTION"

func commit_player_intent(world: WorldState, intent: PlayerIntent, tick_events: Array[EventRecord] = []) -> Dictionary:
	var auth_err := authorize_player_intent(world, intent)
	if auth_err != "":
		return {"success": false, "error": auth_err}

	match intent.action:
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
			var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(intent.player_id)
			var origin_id: StringName = ls.population_container_id
			var dest_id: StringName = intent.destination_id
			var route_days := get_route_days_between(world, origin_id, dest_id)
			var party_id := StringName("refugee:player_d%d_%s_to_%s" % [
				world.current_day,
				String(origin_id).replace("settlement:", ""),
				String(dest_id).replace("settlement:", "")
			])

			var result: Dictionary = world.npc_life_state_registry.begin_named_migration(
				world, intent.player_id, dest_id, party_id, route_days, world.current_day
			)
			if not result["success"]:
				return result

			var travel_evt := EventRecord.new(
				world.current_day,
				"PLAYER_TRAVEL_STARTED",
				intent.player_id,
				dest_id,
				{
					"origin": String(origin_id),
					"destination": String(dest_id),
					"party_id": String(party_id),
					"route_days": route_days
				}
			)
			if tick_events != null:
				tick_events.append(travel_evt)
			world.record_event(travel_evt)

			return {
				"success": true,
				"action": "TRAVEL",
				"party_id": party_id,
				"route_days": route_days
			}

	return {"success": false, "error": "UNREACHABLE"}

func execute_player_wait(world: WorldState) -> Dictionary:
	if world == null or world.player == null:
		return {"success": false, "error": "NO_PLAYER: World does not have an active player"}
	var intent := PlayerIntent.create_wait(world.player.npc_id)
	return commit_player_intent(world, intent)

