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

		# S3-C 難民遷徙觸發判定 (Refugee Migration Trigger)
		var eff_pressure := maxf(settlement.water_pressure, settlement.food_pressure)
		if enable_migration and eff_pressure >= MIGRATION_PRESSURE_THRESHOLD and settlement.days_since_last_migration >= MIGRATION_COOLDOWN_DAYS and settlement.population > MIGRATION_MIN_POPULATION:
			var headcount := maxi(1, int(floor(float(settlement.population) * MIGRATION_POPULATION_RATIO)))
			if settlement.population - headcount < MIGRATION_MIN_POPULATION:
				headcount = settlement.population - MIGRATION_MIN_POPULATION
			if headcount > 0:
				var dest_id := select_refugee_destination(world, settlement)
				if dest_id != &"":
					settlement.population -= headcount
					settlement.days_since_last_migration = 0
					var route_days := get_route_days_between(world, settlement.id, dest_id)
					var party_id := StringName("refugee:%s:%s:d%d" % [String(settlement.id), String(dest_id), current_day])
					var party := RefugeePartyState.new(
						party_id,
						settlement.id,
						dest_id,
						headcount,
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
							"headcount": headcount,
							"route_days": route_days,
							"origin_population_after": settlement.population,
							"pressure_trigger": eff_pressure
						}
					)
					tick_events.append(depart_evt)
					world.record_event(depart_evt)

	# -------------------------------------------------------------
	# 階段 2: 各聚落在地生產 (Optional Local Production)
	# -------------------------------------------------------------
	for s_id in sorted_settlement_ids:
		var settlement: SettlementState = world.settlements[s_id]
		for res in COMMODITIES:
			var cur := settlement.inventory.get_amount(res)
			var prod := settlement.production.get_amount(res)
			settlement.inventory.set_amount(res, cur + prod)

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
	for r_id in sorted_refugee_ids:
		var party: RefugeePartyState = world.refugees[r_id]
		if party.is_active and not party.is_arrived and party.days_remaining <= 0:
			var dest: SettlementState = world.get_settlement(party.destination_id)
			if dest != null:
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
						"headcount": party.headcount,
						"dest_population_after": dest.population
					}
				)
				tick_events.append(arrival_evt)
				world.record_event(arrival_evt)

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

# 不變量檢查函式
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
		for r in ["water", "food"]:
			if s.last_need_outcomes.has(r):
				var o: Dictionary = s.last_need_outcomes[r]
				if o["requested"] != o["fulfilled"] + o["unmet"]:
					return "Settlement %s %s accounting broken: %d != %d + %d" % [
						s.id, r, o["requested"], o["fulfilled"], o["unmet"]
					]

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
		if r.headcount <= 0:
			return "Refugee party %s has non-positive headcount: %d" % [r.id, r.headcount]
		if not world.settlements.has(r.origin_id):
			return "Refugee party %s references non-existent origin: %s" % [r.id, r.origin_id]
		if not world.settlements.has(r.destination_id):
			return "Refugee party %s references non-existent destination: %s" % [r.id, r.destination_id]
		if r.is_active and not r.is_arrived and r.days_remaining < 0:
			return "Refugee party %s has negative days remaining: %d" % [r.id, r.days_remaining]

	# S3-C 全域人類生命總量守恆不變量 (Conservation of Human Life)
	var current_total_pop := 0
	for s_id in world.settlements:
		current_total_pop += world.settlements[s_id].population
	for r_id in world.refugees:
		var r: RefugeePartyState = world.refugees[r_id]
		if r.is_active and not r.is_arrived:
			current_total_pop += r.headcount

	if world.total_initial_population >= 0 and current_total_pop != world.total_initial_population:
		return "Global population conservation broken: current %d != initial %d" % [
			current_total_pop, world.total_initial_population
		]

	return ""
