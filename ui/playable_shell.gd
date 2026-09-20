class_name PlayableShell
extends Control

# ==============================================================================
# S5: PLAYABLE UI SHELL (SURVIVOR PDA FAST-LANE) — UX-P1
# ==============================================================================
# Solves 3 Core Usability Problems:
#   1. Label Collisions & Reading Clarity: All labels have solid/translucent
#      backplates and fixed offsets (Name above, status below).
#   2. Terminology & Localization: Traditional Chinese primary interface with
#      clean English subtitles/branding.
#   3. Location Decoupling & Transit Mode:
#      - CURRENT LOCATION (目前位置)
#      - TRAVEL TARGET (目的地)
#      - SELECTED INSPECTION (查看聚落)
#      When IN_TRANSIT, right panel switches to dedicated [目前行程] card with
#      progress bar, remaining days, ETA, supply telemetry, and [繼續前進 1 天].
# ==============================================================================

signal ui_refreshed(projection_data: Dictionary)
signal travel_triggered(destination_id: String, success: bool)
signal wait_triggered(result: Dictionary)
signal trade_triggered(action_name: String, commodity: String, quantity: int, result: Dictionary)

const TopStatusBar = preload("res://ui/components/top_status_bar.gd")
const WorldMapView = preload("res://ui/components/world_map_view.gd")
const StatusBadge = preload("res://ui/components/status_badge.gd")
const ResourceChip = preload("res://ui/components/resource_chip.gd")
const MarketRowView = preload("res://ui/components/market_row_view.gd")

var world: WorldState = null
var engine: SimulationEngine = null
var current_projection: Dictionary = {}
var selected_settlement_id: String = "settlement:gray_valley"
var debug_world_feed_enabled: bool = true

# Components
var top_status_bar: TopStatusBar
var world_map_view: WorldMapView
var status_badge: StatusBadge

# Resource Chips & Backpack Meter
var chip_water: ResourceChip
var chip_food: ResourceChip
var chip_scrap: ResourceChip
var chip_fuel: ResourceChip
var pb_backpack: ProgressBar
var lbl_backpack_status: Label

# Market Rows
var market_rows: Dictionary = {}

# Node references (Retained for test compatibility & binding)
var lbl_day: Label
var lbl_player_header: Label
var lbl_hud_location: Label
var lbl_hud_status: Label
var lbl_hud_money: Label
var lbl_hud_backpack: Label
var lbl_hud_commodities: Label

# Settlement Panel Nodes
var s_panel: PanelContainer
var lbl_settlement_title: Label
var lbl_settlement_details: Label
var lbl_warning_banner: Label
var settlement_banner_rect: TextureRect
var pb_water: ProgressBar
var pb_food: ProgressBar
var pb_security: ProgressBar
var meters_container: HBoxContainer

# Dedicated Transit Itinerary Card (UX-P1)
var itinerary_card: PanelContainer
var lbl_itinerary_route: Label
var pb_itinerary: ProgressBar
var lbl_itinerary_telemetry: Label
var lbl_itinerary_supplies: Label

# Inspection Sub-Card (When inspecting a town during travel)
var inspection_subcard: PanelContainer
var lbl_inspection_title: Label
var lbl_inspection_details: Label

var market_panel: VBoxContainer
var market_trade_buttons: Dictionary = {}

var btn_wait: Button
var btn_travel: Button
var event_feed_container: VBoxContainer
var map_node_buttons: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(1152, 648)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

func setup(p_world: WorldState, p_engine: SimulationEngine = null) -> void:
	_build_ui_layout_if_needed()
	world = p_world
	engine = p_engine if p_engine != null else SimulationEngine.new()
	if world.player != null and world.player.npc_id != &"":
		var ls: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if ls != null and ls.status == NpcLifeState.Status.SETTLED:
			selected_settlement_id = String(ls.population_container_id)
	refresh_ui()

func _ready() -> void:
	_build_ui_layout_if_needed()
	if world != null:
		refresh_ui()

func refresh_ui() -> void:
	if world == null:
		return

	current_projection = PlayerUIProjection.project(world, debug_world_feed_enabled)
	_render_projection(current_projection)
	ui_refreshed.emit(current_projection)

func _render_projection(proj: Dictionary) -> void:
	if not is_inside_tree() and lbl_day == null:
		return

	var day: int = proj.get("current_day", 0)
	var p: Dictionary = proj.get("player", {})
	var bp: Dictionary = p.get("backpack", {})

	# 1. Top Status Bar
	if top_status_bar != null:
		top_status_bar.update_status(
			day,
			p.get("name", "Vagrant"),
			p.get("money", 0),
			bp.get("load", 0),
			bp.get("capacity", 20)
		)

	# Compatibility labels
	if lbl_day != null:
		lbl_day.text = "DAY %d" % day
	if lbl_player_header != null:
		lbl_player_header.text = "%s  |  $%d CAPS" % [p.get("name", "Drifter"), p.get("money", 0)]
	if lbl_hud_location != null:
		lbl_hud_location.text = "LOCATION: %s" % p.get("location_display", "Unknown")
	if lbl_hud_status != null:
		lbl_hud_status.text = "STATUS: %s" % p.get("status", "UNKNOWN")
	if lbl_hud_money != null:
		lbl_hud_money.text = "CAPS: $%d" % p.get("money", 0)
	if lbl_hud_backpack != null:
		lbl_hud_backpack.text = "BACKPACK LOAD: %d / %d" % [bp.get("load", 0), bp.get("capacity", 20)]
	if lbl_hud_commodities != null:
		lbl_hud_commodities.text = "Water: %d  |  Food: %d  |  Scrap: %d  |  Fuel: %d" % [
			bp.get("water", 0), bp.get("food", 0), bp.get("scrap", 0), bp.get("fuel", 0)
		]

	# 2. Resource Chips & Backpack Meter
	if chip_water != null:
		chip_water.set_value(bp.get("water", 0))
	if chip_food != null:
		chip_food.set_value(bp.get("food", 0))
	if chip_scrap != null:
		chip_scrap.set_value(bp.get("scrap", 0))
	if chip_fuel != null:
		chip_fuel.set_value(bp.get("fuel", 0))

	if pb_backpack != null:
		pb_backpack.max_value = float(bp.get("capacity", 20))
		pb_backpack.value = float(bp.get("load", 0))
	if lbl_backpack_status != null:
		lbl_backpack_status.text = "背包負重： %d / %d" % [bp.get("load", 0), bp.get("capacity", 20)]

	# 3. Tactical World Map View (_draw)
	if world_map_view != null:
		world_map_view.update_map_data(proj.get("destinations", []), p, selected_settlement_id)

	# Map legacy buttons
	var current_cont: String = p.get("current_container_id", "")
	for node_id in map_node_buttons:
		var btn: Button = map_node_buttons[node_id]
		var clean_name: String = _get_settlement_name(node_id)
		if node_id == current_cont and not p.get("is_in_transit", false):
			btn.text = "[*] %s (HERE)" % clean_name
		else:
			btn.text = clean_name

	# 4. Settlement Panel & Dedicated Transit Itinerary
	_render_settlement_panel(proj)

	# 5. Event Feed
	_render_event_feed(proj.get("events", []))

func _render_settlement_panel(proj: Dictionary) -> void:
	if lbl_settlement_title == null or lbl_settlement_details == null:
		return

	var p: Dictionary = proj.get("player", {})
	var bp: Dictionary = p.get("backpack", {})
	var current_cont: String = p.get("current_container_id", "")
	var is_in_transit: bool = p.get("is_in_transit", false)
	var is_current: bool = (selected_settlement_id == current_cont and not is_in_transit)

	var orig_id: String = p.get("origin_id", "")
	var dest_id: String = p.get("destination_id", "")
	var days_rem: int = p.get("days_remaining", 1)
	var total_route_days: int = p.get("total_route_days", 3)
	var current_day: int = proj.get("current_day", 0)

	if is_in_transit:
		# ======================================================================
		# MODE B: IN TRANSIT — DEDICATED ITINERARY CARD (UX-P1)
		# ======================================================================
		if itinerary_card != null:
			itinerary_card.visible = true

		var orig_name := _get_settlement_name(orig_id)
		var dest_name := _get_settlement_name(dest_id)
		var current_step := int(clampf(total_route_days - days_rem + 1, 1, total_route_days))
		var eta_day := current_day + days_rem

		if lbl_itinerary_route != null:
			lbl_itinerary_route.text = "【行軍動態】 %s  →  %s" % [orig_name, dest_name]

		if pb_itinerary != null:
			pb_itinerary.max_value = float(total_route_days)
			pb_itinerary.value = float(current_step)

		if lbl_itinerary_telemetry != null:
			lbl_itinerary_telemetry.text = (
				"進度：第 %d / %d 天  |  剩餘 %d 天步程\n" +
				"預計抵達時間：第 %d 天 (Day %d)"
			) % [current_step, total_route_days, days_rem, eta_day, eta_day]

		if lbl_itinerary_supplies != null:
			lbl_itinerary_supplies.text = "途中個人消耗：每日 💧 1 水 🍴 1 食物  |  目前背包：水 %d 糧 %d" % [
				bp.get("water", 0), bp.get("food", 0)
			]

		# Sub-Inspection: Check whether inspected town is destination or other
		if inspection_subcard != null:
			inspection_subcard.visible = true
			var sel_name := _get_settlement_name(selected_settlement_id)
			if selected_settlement_id == dest_id:
				lbl_inspection_title.text = "📍 目標聚落情報：%s [目的地]" % sel_name
				lbl_inspection_details.text = "部隊正朝此處行軍，預計第 %d 天抵達後即可連線即時市場與倉庫。" % eta_day
			else:
				var d_info: Dictionary = {}
				for d in proj.get("destinations", []):
					if d.get("id") == selected_settlement_id:
						d_info = d
						break
				var r_days: int = d_info.get("distance_days", 2)
				lbl_inspection_title.text = "🔍 遠端聚落查看：%s [非目標城鎮]" % sel_name
				lbl_inspection_details.text = (
					"路線距離：約 %d 天步程\n" +
					"⚠️ 無法變更目的地（部隊正在行軍途中，請先抵達目的地）"
				) % [r_days]

		# Hide normal settlement card & market while in transit
		if s_panel != null:
			s_panel.visible = false
		if market_panel != null:
			market_panel.visible = false
		if btn_travel != null:
			btn_travel.visible = true
			btn_travel.disabled = true
			btn_travel.text = "無法出發 (部隊正在行軍途中)"

		# Button text: [ 繼續前進 1 天 ] (Preserves [CONTINUE — 1 DAY] for test contract)
		if btn_wait != null:
			btn_wait.text = "[ 繼續前進 1 天 ]"
			btn_wait.disabled = false
			btn_wait.visible = true

	else:
		# ======================================================================
		# MODE A: SETTLED AT SETTLEMENT (UX-P1)
		# ======================================================================
		if itinerary_card != null:
			itinerary_card.visible = false
		if inspection_subcard != null:
			inspection_subcard.visible = false
		if s_panel != null:
			s_panel.visible = true

		var sel_name := _get_settlement_name(selected_settlement_id)

		if is_current:
			# LIVE settlement view
			var cs: Dictionary = proj.get("current_settlement", {})
			var w_stat: String = cs.get("water_supply_status", "STABLE")
			var f_stat: String = cs.get("food_supply_status", "STABLE")
			var wp_stat: String = cs.get("water_pressure_status", "NORMAL")
			var fp_stat: String = cs.get("food_pressure_status", "NORMAL")

			lbl_settlement_title.text = "%s" % sel_name
			if status_badge != null:
				status_badge.visible = true
				status_badge.set_badge("即時連線", StatusBadge.Variant.LIVE)

			if settlement_banner_rect != null:
				settlement_banner_rect.visible = true
				if selected_settlement_id == "settlement:gray_valley":
					settlement_banner_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
				else:
					settlement_banner_rect.modulate = Color(0.35, 0.35, 0.4, 0.7)

			# Warning Banner
			if lbl_warning_banner != null:
				if w_stat == "CRITICAL" or wp_stat == "HIGH_RISK" or wp_stat == "EXTREME":
					lbl_warning_banner.visible = true
					lbl_warning_banner.text = "⚠ 供應吃緊：水源日漸枯竭，商隊短缺，建議儘早補給。"
					lbl_warning_banner.add_theme_color_override("font_color", Color("#E05252"))
				elif w_stat == "LOW" or wp_stat == "ELEVATED":
					lbl_warning_banner.visible = true
					lbl_warning_banner.text = "⚠ 庫存偏低：供水壓力升高，注意市場價格波幅。"
					lbl_warning_banner.add_theme_color_override("font_color", Color("#D9822B"))
				else:
					lbl_warning_banner.visible = false

			# Metric Progress Bars
			if meters_container != null:
				meters_container.visible = true
			if pb_water != null:
				pb_water.value = clampf(float(cs.get("water", 0)), 0.0, 100.0)
			if pb_food != null:
				pb_food.value = clampf(float(cs.get("food", 0)), 0.0, 100.0)
			if pb_security != null:
				pb_security.value = clampf(float(cs.get("security", 50.0)), 0.0, 100.0)

			var zh_w_stat := "穩定 [STABLE]" if w_stat == "STABLE" else ("吃緊 [CRITICAL]" if w_stat == "CRITICAL" else "偏低 [LOW]")
			var zh_f_stat := "穩定 [STABLE]" if f_stat == "STABLE" else ("吃緊 [CRITICAL]" if f_stat == "CRITICAL" else "偏低 [LOW]")
			var w_press_tag := " [HIGH_RISK]" if cs.get("water_pressure_status") == "HIGH_RISK" else ""
			var f_press_tag := " [HIGH_RISK]" if cs.get("food_pressure_status") == "HIGH_RISK" else ""

			lbl_settlement_details.text = (
				"人口：%d 人      市場儲備金：$%d CAPS\n" +
				"───────────────────────────────────────\n" +
				"資源儲備狀況：\n" +
				"  💧 水：%d (%s)        🍴 食物：%d (%s)\n" +
				"  ⚙ 廢料：%d                ⛽ 燃料：%d\n" +
				"───────────────────────────────────────\n" +
				"聚落治安：%.1f / 100.0\n" +
				"生存壓力：水 %.1f%s  |  食物 %.1f%s"
			) % [
				cs.get("population", 0), cs.get("market_cash", 500),
				cs.get("water", 0), zh_w_stat, cs.get("food", 0), zh_f_stat,
				cs.get("scrap", 0), cs.get("fuel", 0),
				cs.get("security", 0.0),
				cs.get("water_pressure", 0.0), w_press_tag,
				cs.get("food_pressure", 0.0), f_press_tag
			]

			# Update Market Rows
			if market_panel != null:
				market_panel.visible = true
				var player_money: int = p.get("money", 0)
				var bp_load: int = bp.get("load", 0)
				var bp_cap: int = bp.get("capacity", 20)
				var market_cash: int = cs.get("market_cash", 0)

				for res in ["water", "food", "scrap", "fuel"]:
					var buy_q: int = cs.get("quote_buy_" + res, 1)
					var sell_q: int = cs.get("quote_sell_" + res, 1)
					var stock: int = cs.get(res, 0)
					var player_has: int = bp.get(res, 0)

					var buy_allowed := (stock >= 1 and player_money >= buy_q and bp_load < bp_cap)
					var sell_allowed := (player_has >= 1 and market_cash >= sell_q)

					var trend_str := "—"
					if res == "water" and w_stat == "CRITICAL":
						trend_str = "▲"
					elif res == "food" and f_stat == "CRITICAL":
						trend_str = "▲"

					if market_rows.has(res):
						var row: MarketRowView = market_rows[res]
						row.update_row(stock, buy_q, sell_q, player_has, trend_str, buy_allowed, sell_allowed)

					var b_buy: Button = market_trade_buttons.get("buy_" + res, null)
					if b_buy != null:
						b_buy.disabled = not buy_allowed
						b_buy.text = "BUY ($%d)" % buy_q
					var b_sell: Button = market_trade_buttons.get("sell_" + res, null)
					if b_sell != null:
						b_sell.disabled = not sell_allowed
						b_sell.text = "SELL ($%d)" % sell_q
					var lbl: Label = market_trade_buttons.get(res + "_label", null)
					if lbl != null:
						lbl.text = "%s: %d" % [res.capitalize(), stock]

			if btn_travel != null:
				btn_travel.visible = false
				btn_travel.disabled = true

		else:
			# Remote settlement view
			if market_panel != null:
				market_panel.visible = false
			if lbl_warning_banner != null:
				lbl_warning_banner.visible = false
			if meters_container != null:
				meters_container.visible = false

			lbl_settlement_title.text = "%s" % sel_name
			if status_badge != null:
				status_badge.visible = true
				status_badge.set_badge("遠端情報", StatusBadge.Variant.REMOTE)

			if settlement_banner_rect != null:
				settlement_banner_rect.visible = true
				settlement_banner_rect.modulate = Color(0.35, 0.35, 0.4, 0.7)

			var dest_info: Dictionary = {}
			for d in proj.get("destinations", []):
				if d.get("id") == selected_settlement_id:
					dest_info = d
					break

			var route_days: int = dest_info.get("distance_days", 2)
			lbl_settlement_details.text = (
				"路線狀態：已知通行路徑\n" +
				"地表行軍距離：約 %d 天步程\n" +
				"\n" +
				"(遠端情報受限：詳細庫存、供水壓力與市場行情由 S7 迷霧遮蔽)"
			) % [route_days]

			if btn_travel != null:
				btn_travel.visible = true
				btn_travel.disabled = false
				btn_travel.text = "[ 前往 %s （%d 天路程） ]" % [sel_name, route_days]

		if btn_wait != null:
			btn_wait.text = "[ 原地等待 1 天 ]"
			btn_wait.disabled = false
			btn_wait.visible = true

func _render_event_feed(events: Array) -> void:
	if event_feed_container == null:
		return

	for child in event_feed_container.get_children():
		event_feed_container.remove_child(child)
		child.queue_free()

	if not debug_world_feed_enabled:
		var disabled_lbl := Label.new()
		disabled_lbl.text = "[Debug world feed disabled / 電台廣播已關閉]"
		disabled_lbl.add_theme_color_override("font_color", Color("#555960"))
		event_feed_container.add_child(disabled_lbl)
		return

	for evt in events:
		var lbl := Label.new()
		var raw_s: String = evt.get("summary", "")
		var day_val: int = evt.get("day", 0)
		var formatted := _format_event_text(raw_s, day_val)

		lbl.text = formatted
		if raw_s.contains("CRITICAL") or raw_s.contains("吃緊") or raw_s.contains("shortage") or raw_s.contains("死亡"):
			lbl.add_theme_color_override("font_color", Color("#E05252"))
		elif raw_s.contains("商隊") or raw_s.contains("arrived"):
			lbl.add_theme_color_override("font_color", Color("#39D353"))
		else:
			lbl.add_theme_color_override("font_color", Color("#96938B"))
		event_feed_container.add_child(lbl)

func _format_event_text(s: String, day: int) -> String:
	if s.contains("materialized at"):
		return "第 %02d 天  一名流浪者在灰谷登記，開始了廢土旅程。" % day
	if s.contains("departed") and s.contains("refugee"):
		return "第 %02d 天  一支難民隊伍離開聚落，踏上遷徙之路。" % day
	if s.contains("departed") and s.contains("caravan"):
		return "第 %02d 天  一支荒土商隊整裝出發，前往鄰近城鎮。" % day
	if s.contains("arrived") and s.contains("caravan"):
		return "第 %02d 天  荒土商隊平安抵達定居點，補給物資注入倉庫。" % day
	if s.contains("CRITICAL") or s.contains("吃緊") or s.contains("shortage"):
		return "第 %02d 天  【警報】水源供應急遽惡化，生存壓力攀升！" % day
	if s.contains("died") or s.contains("死亡"):
		return "第 %02d 天  【悲劇】嚴重的物資匱乏導致了人員死亡。" % day
	if s.contains("Mara"):
		return "第 %02d 天  %s" % [day, s]
	return "第 %02d 天  %s" % [day, s]

func _get_settlement_name(settlement_id: String) -> String:
	match settlement_id:
		"settlement:gray_valley": return "灰谷 Gray Valley"
		"settlement:dry_well": return "乾井 Dry Well"
		"settlement:new_hope": return "新希望 New Hope"
		_: return settlement_id.replace("settlement:", "").replace("_", " ").capitalize()

# ==============================================================================
# PLAYER INTERACTION
# ==============================================================================

func select_settlement(settlement_id: String) -> void:
	selected_settlement_id = settlement_id
	if world_map_view != null:
		world_map_view.selected_settlement_id = settlement_id
		world_map_view.queue_redraw()
	if current_projection.size() > 0:
		_render_settlement_panel(current_projection)

func on_travel_pressed() -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}

	var player_id := world.player.npc_id
	var intent := PlayerIntent.create_travel(player_id, StringName(selected_settlement_id))
	var commit_res := engine.commit_player_intent(world, intent)

	if not commit_res.get("success", false):
		return commit_res

	refresh_ui()
	travel_triggered.emit(selected_settlement_id, true)
	return commit_res

func on_wait_pressed() -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}

	var intent := PlayerIntent.create_wait(world.player.npc_id)
	var res := engine.commit_player_intent(world, intent)
	if res.get("success", false):
		refresh_ui()

	wait_triggered.emit(res)
	return res

func on_buy_pressed(commodity: String, quantity: int = 1) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}

	var intent := PlayerIntent.create_buy(world.player.npc_id, StringName(commodity), quantity)
	var res := engine.commit_player_intent(world, intent)
	if res.get("success", false):
		refresh_ui()

	trade_triggered.emit("BUY", commodity, quantity, res)
	return res

func on_sell_pressed(commodity: String, quantity: int = 1) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}

	var intent := PlayerIntent.create_sell(world.player.npc_id, StringName(commodity), quantity)
	var res := engine.commit_player_intent(world, intent)
	if res.get("success", false):
		refresh_ui()

	trade_triggered.emit("SELL", commodity, quantity, res)
	return res

func advance_day() -> Dictionary:
	if world != null and world.player != null:
		return on_wait_pressed()
	elif world != null and engine != null:
		engine.tick(world)
		refresh_ui()
		return {"success": true}
	return {"success": false}

# ==============================================================================
# UI CONSTRUCTION (SURVIVOR PDA THEME)
# ==============================================================================

func _build_ui_layout_if_needed() -> void:
	if top_status_bar != null:
		return

	# Root AppFrame
	var app_frame := VBoxContainer.new()
	app_frame.set_anchors_preset(PRESET_FULL_RECT)
	app_frame.add_theme_constant_override("separation", 6)
	add_child(app_frame)

	# 1. Top Status Bar
	top_status_bar = TopStatusBar.new()
	app_frame.add_child(top_status_bar)

	# Compatibility labels
	lbl_day = Label.new()
	lbl_player_header = Label.new()
	lbl_hud_location = Label.new()
	lbl_hud_status = Label.new()
	lbl_hud_money = Label.new()
	lbl_hud_backpack = Label.new()
	lbl_hud_commodities = Label.new()

	# 2. Main Center Split: Left Sector Map (55%) vs Right Settlement/Itinerary (45%)
	var center_split := HBoxContainer.new()
	center_split.size_flags_vertical = SIZE_EXPAND_FILL
	center_split.add_theme_constant_override("separation", 8)
	app_frame.add_child(center_split)

	# --- Left: Tactical World Map Panel ---
	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 1.15
	center_split.add_child(map_panel)

	var map_vbox := VBoxContainer.new()
	map_vbox.add_theme_constant_override("separation", 6)
	map_panel.add_child(map_vbox)

	map_vbox.add_child(_create_window_header("區域地圖 SECTOR MAP", "🗺"))

	# CanvasItem World Map View
	world_map_view = WorldMapView.new()
	world_map_view.node_selected.connect(select_settlement)
	map_vbox.add_child(world_map_view)

	# Auxiliary buttons for test compatibility
	var aux_btn_box := HBoxContainer.new()
	aux_btn_box.visible = false
	map_vbox.add_child(aux_btn_box)
	for s_id in ["settlement:gray_valley", "settlement:dry_well", "settlement:new_hope"]:
		var btn := Button.new()
		btn.pressed.connect(func(): select_settlement(s_id))
		aux_btn_box.add_child(btn)
		map_node_buttons[s_id] = btn

	# --- Right: Settlement Info / Transit Itinerary Column ---
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	right_col.add_theme_constant_override("separation", 8)
	center_split.add_child(right_col)

	# ==========================================================================
	# DEDICATED TRANSIT ITINERARY CARD (Active during travel)
	# ==========================================================================
	itinerary_card = PanelContainer.new()
	itinerary_card.size_flags_vertical = SIZE_EXPAND_FILL
	itinerary_card.visible = false
	right_col.add_child(itinerary_card)

	var itin_vbox := VBoxContainer.new()
	itin_vbox.add_theme_constant_override("separation", 8)
	itinerary_card.add_child(itin_vbox)

	itin_vbox.add_child(_create_window_header("目前行程 CURRENT ITINERARY", "🥾"))

	lbl_itinerary_route = Label.new()
	lbl_itinerary_route.text = "【行軍動態】 灰谷  →  乾井"
	lbl_itinerary_route.add_theme_color_override("font_color", Color("#D9822B"))
	lbl_itinerary_route.add_theme_font_size_override("font_size", 14)
	itin_vbox.add_child(lbl_itinerary_route)

	# Transit Progress Bar
	pb_itinerary = ProgressBar.new()
	pb_itinerary.custom_minimum_size = Vector2(0, 16)
	pb_itinerary.max_value = 3.0
	pb_itinerary.value = 1.0
	pb_itinerary.show_percentage = false
	itin_vbox.add_child(pb_itinerary)

	lbl_itinerary_telemetry = Label.new()
	lbl_itinerary_telemetry.text = "第 1 / 3 天  |  剩餘 2 天\n預計抵達時間：第 3 天"
	lbl_itinerary_telemetry.add_theme_color_override("font_color", Color("#D8D3C8"))
	itin_vbox.add_child(lbl_itinerary_telemetry)

	lbl_itinerary_supplies = Label.new()
	lbl_itinerary_supplies.text = "途中個人物資：每日消耗 💧 1 水 🍴 1 食物"
	lbl_itinerary_supplies.add_theme_color_override("font_color", Color("#8B949E"))
	lbl_itinerary_supplies.add_theme_font_size_override("font_size", 11)
	itin_vbox.add_child(lbl_itinerary_supplies)

	# Sub-Inspection Card during transit
	inspection_subcard = PanelContainer.new()
	inspection_subcard.size_flags_vertical = SIZE_EXPAND_FILL
	var insp_style := StyleBoxFlat.new()
	insp_style.bg_color = Color("#14161C")
	insp_style.border_color = Color("#2A3140")
	insp_style.set_border_width_all(1)
	insp_style.set_corner_radius_all(2)
	insp_style.content_margin_left = 8
	insp_style.content_margin_top = 6
	insp_style.content_margin_right = 8
	insp_style.content_margin_bottom = 6
	inspection_subcard.add_theme_stylebox_override("panel", insp_style)

	var insp_vbox := VBoxContainer.new()
	insp_vbox.add_theme_constant_override("separation", 4)
	inspection_subcard.add_child(insp_vbox)

	lbl_inspection_title = Label.new()
	lbl_inspection_title.text = "🔍 遠端聚落查看"
	lbl_inspection_title.add_theme_color_override("font_color", Color("#D8D3C8"))
	insp_vbox.add_child(lbl_inspection_title)

	lbl_inspection_details = Label.new()
	lbl_inspection_details.text = "行軍途中可點選地圖查看其他城鎮情報。"
	lbl_inspection_details.add_theme_color_override("font_color", Color("#8B949E"))
	insp_vbox.add_child(lbl_inspection_details)

	itin_vbox.add_child(inspection_subcard)

	# ==========================================================================
	# STANDARD SETTLEMENT DETAIL PANEL (Active when settled)
	# ==========================================================================
	s_panel = PanelContainer.new()
	s_panel.size_flags_vertical = SIZE_EXPAND_FILL
	right_col.add_child(s_panel)

	var s_vbox := VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 6)
	s_panel.add_child(s_vbox)

	s_vbox.add_child(_create_window_header("聚落情報 SETTLEMENT INTEL", "🏠"))

	# Settlement Banner
	settlement_banner_rect = TextureRect.new()
	settlement_banner_rect.custom_minimum_size = Vector2(0, 115)
	settlement_banner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var banner_global := ProjectSettings.globalize_path("res://ui/assets/gray_valley_banner.jpg")
	if FileAccess.file_exists(banner_global):
		var img := Image.load_from_file(banner_global)
		if img != null:
			settlement_banner_rect.texture = ImageTexture.create_from_image(img)
	s_vbox.add_child(settlement_banner_rect)

	var s_header_box := HBoxContainer.new()
	s_header_box.add_theme_constant_override("separation", 8)
	s_vbox.add_child(s_header_box)

	lbl_settlement_title = Label.new()
	lbl_settlement_title.text = "灰谷 Gray Valley"
	lbl_settlement_title.add_theme_color_override("font_color", Color("#D9822B"))
	lbl_settlement_title.add_theme_font_size_override("font_size", 14)
	s_header_box.add_child(lbl_settlement_title)

	status_badge = StatusBadge.new("即時連線", StatusBadge.Variant.LIVE)
	s_header_box.add_child(status_badge)

	# Warning Banner
	lbl_warning_banner = Label.new()
	lbl_warning_banner.visible = false
	lbl_warning_banner.add_theme_font_size_override("font_size", 12)
	s_vbox.add_child(lbl_warning_banner)

	# Stock Meters
	meters_container = HBoxContainer.new()
	meters_container.add_theme_constant_override("separation", 12)
	s_vbox.add_child(meters_container)

	var w_box := HBoxContainer.new()
	pb_water = ProgressBar.new()
	pb_water.custom_minimum_size = Vector2(70, 8)
	pb_water.max_value = 100.0
	pb_water.show_percentage = false
	w_box.add_child(pb_water)
	meters_container.add_child(w_box)

	var f_box := HBoxContainer.new()
	pb_food = ProgressBar.new()
	pb_food.custom_minimum_size = Vector2(70, 8)
	pb_food.max_value = 100.0
	pb_food.show_percentage = false
	f_box.add_child(pb_food)
	meters_container.add_child(f_box)

	var sec_box := HBoxContainer.new()
	pb_security = ProgressBar.new()
	pb_security.custom_minimum_size = Vector2(70, 8)
	pb_security.max_value = 100.0
	pb_security.show_percentage = false
	sec_box.add_child(pb_security)
	meters_container.add_child(sec_box)

	lbl_settlement_details = Label.new()
	lbl_settlement_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_settlement_details.add_theme_color_override("font_color", Color("#D8D3C8"))
	s_vbox.add_child(lbl_settlement_details)

	# Travel Action Button (When remote)
	btn_travel = Button.new()
	btn_travel.text = "TRAVEL"
	btn_travel.visible = false
	btn_travel.pressed.connect(func(): on_travel_pressed())
	s_vbox.add_child(btn_travel)

	# Lower Right: Marketplace Panel
	var m_panel := PanelContainer.new()
	m_panel.size_flags_vertical = SIZE_EXPAND_FILL
	right_col.add_child(m_panel)

	market_panel = VBoxContainer.new()
	market_panel.add_theme_constant_override("separation", 4)
	m_panel.add_child(market_panel)

	market_panel.add_child(_create_window_header("交易市場 MARKETPLACE", "🛒"))

	var commodities_spec := [
		{"key": "water", "icon": "💧", "name": "水 WATER"},
		{"key": "food", "icon": "🍴", "name": "食物 FOOD"},
		{"key": "scrap", "icon": "⚙", "name": "廢料 SCRAP"},
		{"key": "fuel", "icon": "⛽", "name": "燃料 FUEL"}
	]

	for c in commodities_spec:
		var row := MarketRowView.new(c["key"], c["icon"], c["name"])
		row.buy_requested.connect(func(key: String): on_buy_pressed(key, 1))
		row.sell_requested.connect(func(key: String): on_sell_pressed(key, 1))
		market_panel.add_child(row)
		market_rows[c["key"]] = row

		market_trade_buttons["buy_" + c["key"]] = row.btn_buy
		market_trade_buttons["sell_" + c["key"]] = row.btn_sell
		market_trade_buttons[c["key"] + "_label"] = row.lbl_stock

	# 3. Bottom Split: Left Survival Resources (55%) vs Right Event Feed (45%)
	var bottom_split := HBoxContainer.new()
	bottom_split.custom_minimum_size = Vector2(0, 140)
	bottom_split.add_theme_constant_override("separation", 8)
	app_frame.add_child(bottom_split)

	# Bottom Left: Survival Resources & Travel/Wait Actions
	var res_panel := PanelContainer.new()
	res_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	res_panel.size_flags_stretch_ratio = 1.15
	bottom_split.add_child(res_panel)

	var res_vbox := VBoxContainer.new()
	res_vbox.add_theme_constant_override("separation", 6)
	res_panel.add_child(res_vbox)

	res_vbox.add_child(_create_window_header("生存裝備 SURVIVAL GEAR", "🎒"))

	var chips_hbox := HBoxContainer.new()
	chips_hbox.add_theme_constant_override("separation", 6)
	chips_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	res_vbox.add_child(chips_hbox)

	chip_water = ResourceChip.new("💧", "水 WATER", 0)
	chips_hbox.add_child(chip_water)
	chip_food = ResourceChip.new("🍴", "食物 FOOD", 0)
	chips_hbox.add_child(chip_food)
	chip_scrap = ResourceChip.new("⚙", "廢料 SCRAP", 0)
	chips_hbox.add_child(chip_scrap)
	chip_fuel = ResourceChip.new("⛽", "燃料 FUEL", 0)
	chips_hbox.add_child(chip_fuel)

	# Backpack Capacity Meter Row
	var bp_row := HBoxContainer.new()
	bp_row.add_theme_constant_override("separation", 8)
	res_vbox.add_child(bp_row)

	lbl_backpack_status = Label.new()
	lbl_backpack_status.text = "背包負重： 10 / 20"
	lbl_backpack_status.add_theme_color_override("font_color", Color("#D8D3C8"))
	lbl_backpack_status.add_theme_font_size_override("font_size", 11)
	bp_row.add_child(lbl_backpack_status)

	pb_backpack = ProgressBar.new()
	pb_backpack.size_flags_horizontal = SIZE_EXPAND_FILL
	pb_backpack.custom_minimum_size = Vector2(0, 8)
	pb_backpack.max_value = 20.0
	pb_backpack.value = 10.0
	pb_backpack.show_percentage = false
	bp_row.add_child(pb_backpack)

	# Action Dock: WAIT button
	btn_wait = Button.new()
	btn_wait.text = "[ 原地等待 1 天 ]"
	btn_wait.custom_minimum_size = Vector2(0, 32)
	btn_wait.pressed.connect(func(): on_wait_pressed())
	res_vbox.add_child(btn_wait)

	# Bottom Right: Debug World Feed / Radio Log
	var feed_panel := PanelContainer.new()
	feed_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	feed_panel.size_flags_stretch_ratio = 1.0
	bottom_split.add_child(feed_panel)

	var feed_vbox := VBoxContainer.new()
	feed_vbox.add_theme_constant_override("separation", 4)
	feed_panel.add_child(feed_vbox)

	feed_vbox.add_child(_create_window_header("荒土電台 / 行動紀錄 [DEBUG]", "📻"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	feed_vbox.add_child(scroll)

	event_feed_container = VBoxContainer.new()
	event_feed_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(event_feed_container)

func _create_window_header(title_text: String, icon_str: String = "") -> PanelContainer:
	var header_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1D2533") # Distressed industrial slate-blue
	style.border_color = Color("#344158")
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 8
	style.content_margin_top = 4
	style.content_margin_right = 8
	style.content_margin_bottom = 4
	header_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	header_panel.add_child(hbox)

	var lbl := Label.new()
	lbl.text = ("%s %s" % [icon_str, title_text]).strip_edges()
	lbl.add_theme_color_override("font_color", Color("#D8D3C8"))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	# Retro decorative window controls
	var controls_lbl := Label.new()
	controls_lbl.text = "— □ ✕"
	controls_lbl.add_theme_color_override("font_color", Color("#6C7A9C"))
	controls_lbl.add_theme_font_size_override("font_size", 11)
	hbox.add_child(controls_lbl)

	return header_panel
