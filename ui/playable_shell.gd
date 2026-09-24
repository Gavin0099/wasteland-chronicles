class_name PlayableShell
extends Control

const ItemRegistry = preload("res://simulation/item_registry.gd")
const Tokens = preload("res://ui/theme/pda_tokens.gd")
const CharacterPresentation = preload("res://ui/character_presentation.gd")

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
const DesktopWindow = preload("res://ui/components/desktop_window.gd")
const DesktopBackdrop = preload("res://ui/components/desktop_backdrop.gd")

var world: WorldState = null
var engine: SimulationEngine = null
var current_projection: Dictionary = {}
var selected_settlement_id: String = "settlement:gray_valley"
var debug_world_feed_enabled: bool = false

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
var encounter_panel: PanelContainer
var encounter_vbox: VBoxContainer
var lbl_encounter_route: Label
var lbl_encounter_title: Label
var lbl_encounter_body: Label
var lbl_encounter_supplies: Label
var encounter_options_box: VBoxContainer
var encounter_art: Control
var lbl_settlement_title: Label
var lbl_settlement_subtitle: Label
var lbl_settlement_condition: Label
var lbl_settlement_details: Label
var lbl_warning_banner: Label
var settlement_banner_rect: TextureRect
var settlement_detail_toggle: Button
var settlement_detail_body: VBoxContainer
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
var market_practice_label: Label
var market_practice_context := ""
var market_trade_buttons: Dictionary = {}
var item_market_toggle: Button
var item_market_scroll: ScrollContainer
var item_market_rows_box: VBoxContainer
var item_market_rows: Dictionary = {}
var item_market_trade_buttons: Dictionary = {}
var quest_panel: PanelContainer
var quest_access_button: Button
var local_action_panel: PanelContainer
var lbl_local_context: Label
var lbl_local_hint: Label
var btn_return_local: Button
var btn_local_market: Button
var quest_close_button: Button
var right_scroll: ScrollContainer
var quest_journal_open: bool = false
var quest_selector: OptionButton
var quest_title: Label
var quest_description: Label
var quest_progress: Label
var quest_button: Button
var quest_id_shown: String = ""

var field_button: Button
var btn_wait: Button
var btn_travel: Button
var death_banner: PanelContainer
var lbl_death_title: Label
var lbl_death_body: Label
var lbl_action_error: Label
var lbl_supply_warning: Label
var supply_alert: PanelContainer
var lbl_supply_alert: Label
var event_feed_container: VBoxContainer
var feed_panel: PanelContainer
var desktop_scene_window: DesktopWindow
var desktop_details_window: DesktopWindow
var desktop_window_layer: Control
var desktop_scene_art: TextureRect
var desktop_details_open := false
var desktop_last_location := ""
var desktop_back_button: Button
var desktop_profile_name: Label
var desktop_profile_vitals: Label
var desktop_message: Label
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
	if market_practice_label != null and market_practice_context != String(current_projection.get("player", {}).get("current_container_id", "")):
		market_practice_label.visible = false
	_render_projection(current_projection)
	ui_refreshed.emit(current_projection)

func _render_projection(proj: Dictionary) -> void:
	if not is_inside_tree() and lbl_day == null:
		return

	var day: int = proj.get("current_day", 0)
	var p: Dictionary = proj.get("player", {})
	var bp: Dictionary = p.get("backpack", {})
	if field_button != null:
		var field_in_progress: bool = not world.field_state.battle.is_empty() or world.field_state.receipt >= 0
		field_button.disabled = not field_in_progress and (p.get("status") != "SETTLED" or p.get("current_container_id") != "settlement:gray_valley")
		field_button.text = "探索灰谷近郊" if not field_button.disabled else "近郊探索（灰谷）"
		field_button.tooltip_text = "需停留在灰谷才能進入附近補給棚。" if field_button.disabled else "灰谷近郊：準備裝備與回合制戰鬥"

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

	var current_cont: String = p.get("current_container_id", "")
	if not bool(p.get("is_in_transit", false)) and desktop_last_location != "" and desktop_last_location != current_cont and not desktop_last_location.begins_with("settlement:"):
		desktop_details_open = false
		selected_settlement_id = current_cont
	desktop_last_location = current_cont

	# 3. Tactical World Map View (_draw)
	if world_map_view != null:
		world_map_view.update_map_data(proj.get("destinations", []), p, selected_settlement_id)

	# Map legacy buttons
	for node_id in map_node_buttons:
		var btn: Button = map_node_buttons[node_id]
		var clean_name: String = _get_settlement_name(node_id)
		if node_id == current_cont and not p.get("is_in_transit", false):
			btn.text = "[*] %s (HERE)" % clean_name
		else:
			btn.text = clean_name

	# 4. Settlement Panel & Dedicated Transit Itinerary
	_render_settlement_panel(proj)
	_render_quests(proj.get("quests", []))
	_render_local_actions(proj)

	# 5. Event Feed
	_render_event_feed(proj.get("events", []))
	_render_encounter(proj.get("active_encounter", {}), proj.get("encounter_result", {}))
	_render_supply_warning(p)
	_render_death(proj.get("death", {}))
	_sync_desktop(proj)

# How close the player is to dying of it, in whole days, using the same grace
# the engine kills by. Returns -1 when this need is not currently a problem.
func _days_until_fatal(exposure: float, grace: float) -> int:
	if exposure <= 0.0:
		return -1
	return int(ceil(grace - exposure)) + 1

func _render_supply_warning(p: Dictionary) -> void:
	if lbl_supply_warning == null:
		return
	var bp: Dictionary = p.get("backpack", {})
	var water := int(bp.get("water", 0))
	var food := int(bp.get("food", 0))
	if supply_alert != null:
		supply_alert.visible = water == 0 or food == 0
		if supply_alert.visible:
			var missing: PackedStringArray = []
			var risks: PackedStringArray = []
			if water == 0:
				missing.append("水")
				risks.append("缺水")
			if food == 0:
				missing.append("食物")
				risks.append("飢餓")
			if bool(p.get("is_in_transit", false)):
				lbl_supply_alert.text = "⚠ 隨身補給耗盡：%s。後續行程可能累積%s風險。" % ["、".join(missing), "、".join(risks)]
			else:
				lbl_supply_alert.text = "⚠ 隨身補給耗盡：%s。請確認聚落供給，出發前備足補給。" % "、".join(missing)
	var lines: PackedStringArray = []
	var critical := false

	var w_left := _days_until_fatal(float(p.get("water_exposure", 0.0)), SimulationEngine.WATER_EXPOSURE_GRACE_DAYS)
	var f_left := _days_until_fatal(float(p.get("food_exposure", 0.0)), SimulationEngine.FOOD_EXPOSURE_GRACE_DAYS)
	if w_left >= 0:
		critical = true
		lines.append("⚠ 你已經在缺水了。再撐約 %d 天就會脫水而死。" % w_left)
	if f_left >= 0:
		critical = true
		lines.append("⚠ 你已經在挨餓了。再撐約 %d 天就會餓死。" % f_left)

	var low_supplies: PackedStringArray = []
	if water > 0 and water <= 2:
		low_supplies.append("水 %d" % water)
	if food > 0 and food <= 2:
		low_supplies.append("食物 %d" % food)
	if not low_supplies.is_empty():
		lines.append("隨身補給偏低：%s。路上每天各消耗 1。" % "、".join(low_supplies))

	# Setting out with less water than the road is long is the decision this
	# warning exists for. Stated before departure, never after.
	if not p.get("is_in_transit", false) and btn_travel != null and btn_travel.visible and not btn_travel.disabled:
		var route_days := 0
		for d in current_projection.get("destinations", []):
			if String(d.get("id", "")) == selected_settlement_id:
				route_days = int(d.get("distance_days", 0))
				break
		if route_days > 0 and (water < route_days or food < route_days):
			critical = true
			lines.append("⚠ 前往%s要 %d 天，你只帶了 💧 %d、🍴 %d。" % [
				_get_settlement_name(selected_settlement_id), route_days, water, food])

	lbl_supply_warning.visible = lines.size() > 0
	lbl_supply_warning.text = "
".join(lines)
	lbl_supply_warning.add_theme_color_override(
		"font_color", Color("#E0555B") if critical else Color("#C9A227"))

func _render_death(death: Dictionary) -> void:
	if death_banner == null:
		return
	var dead := not death.is_empty()
	death_banner.visible = dead
	if not dead:
		return

	var causes := {"dehydration": "脫水", "starvation": "飢餓"}
	var cause := String(causes.get(String(death.get("cause", "")), "荒原"))
	var place := String(death.get("place", ""))
	# The receipt names the settlement the death was COUNTED against, which is
	# not the same as where the player was heading. Saying "on the road" is the
	# only thing the receipt actually supports.
	var where := "死在路上" if bool(death.get("in_transit", false)) else ("在%s" % place if place != "" else "")
	lbl_death_title.text = "旅程結束 — %s死於%s" % [
		current_projection.get("player", {}).get("name", "旅人"), cause]
	lbl_death_body.text = "%s，第 %d 天。你走了 %d 天。
這個角色不能再行動了；要繼續就得重新建立一個人。" % [
		where, int(death.get("day", 0)), int(death.get("days_survived", 0))]
	if bool(death.get("in_transit", false)) and place != "":
		lbl_death_body.text += "
（這次死亡計入%s）" % place

	# Nothing on the map is actionable any more. Leaving the controls lit is
	# what made death read as a freeze.
	for b in [btn_wait, btn_travel, field_button]:
		if b != null:
			b.disabled = true
	if lbl_supply_warning != null:
		lbl_supply_warning.visible = false
	if supply_alert != null:
		supply_alert.visible = false

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
		if settlement_detail_body != null:
			settlement_detail_body.visible = not is_current or settlement_detail_toggle.button_pressed
		if settlement_detail_toggle != null:
			settlement_detail_toggle.visible = is_current

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
				# The only authored town illustration depicts Gray Valley. Do not
				# present it as another settlement or spend room on a false view.
				settlement_banner_rect.visible = selected_settlement_id == "settlement:gray_valley"
				settlement_banner_rect.modulate = Color.WHITE

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

			var zh_w_stat := _supply_word(w_stat)
			var zh_f_stat := _supply_word(f_stat)

			# The card answers "where is this, and how are things?" first.
			if lbl_settlement_subtitle != null:
				lbl_settlement_subtitle.visible = true
				lbl_settlement_subtitle.text = _settlement_flavour(selected_settlement_id)
			if lbl_settlement_condition != null:
				lbl_settlement_condition.visible = true
				lbl_settlement_condition.text = (
					"人口 %d\n供水 %s\n糧食 %s\n治安 %s"
				) % [
					int(cs.get("population", 0)),
					zh_w_stat,
					zh_f_stat,
					_security_word(float(cs.get("security", 100.0)))
				]
			var w_press_tag := "（高風險）" if cs.get("water_pressure_status") == "HIGH_RISK" else ""
			var f_press_tag := "（高風險）" if cs.get("food_pressure_status") == "HIGH_RISK" else ""

			lbl_settlement_details.text = (
				"倉儲　水 %d ／ 食物 %d ／ 廢料 %d ／ 燃料 %d\n" +
				"市場儲備金 %d 瓶蓋　·　治安 %.0f\n" +
				"生存壓力　水 %.0f%s　食物 %.0f%s"
			) % [
				cs.get("water", 0), cs.get("food", 0),
				cs.get("scrap", 0), cs.get("fuel", 0),
				cs.get("market_cash", 500),
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

					var buy_allowed := (bool(p.get("is_alive", true)) and stock >= 1 and player_money >= buy_q and bp_load < bp_cap)
					var sell_allowed := (bool(p.get("is_alive", true)) and player_has >= 1 and market_cash >= sell_q)

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
						b_buy.text = "買 1（%d）" % buy_q
					var b_sell: Button = market_trade_buttons.get("sell_" + res, null)
					if b_sell != null:
						b_sell.disabled = not sell_allowed
						b_sell.text = "賣 1（%d）" % sell_q
					var lbl: Label = market_trade_buttons.get(res + "_label", null)
					if lbl != null:
						lbl.text = "庫存：%d" % stock

				if item_market_toggle != null:
					item_market_toggle.visible = true
				if item_market_scroll != null:
					item_market_scroll.visible = item_market_toggle != null and item_market_toggle.button_pressed
				var item_offers: Array = cs.get("item_market", [])
				for offer in item_offers:
					var item_id := String(offer.get("item_id", ""))
					if not item_market_rows.has(item_id):
						continue
					var item_row: MarketRowView = item_market_rows[item_id]
					var supply_word := _market_level_word(String(offer.get("supply", "")))
					var demand_word := _market_level_word(String(offer.get("demand", "")))
					item_row.update_row(
						int(offer.get("stock", 0)),
						int(offer.get("quote_buy", 0)),
						int(offer.get("quote_sell", 0)),
						int(offer.get("owned", 0)),
						"供%s／需%s" % [supply_word, demand_word],
						bool(offer.get("can_buy", false)),
						bool(offer.get("can_sell", false))
					)

			if btn_travel != null:
				btn_travel.visible = false
				btn_travel.disabled = true

		else:
			# Remote settlement view
			if market_panel != null:
				market_panel.visible = false
			if item_market_scroll != null:
				item_market_scroll.visible = false
			if item_market_toggle != null:
				item_market_toggle.visible = false
			if lbl_warning_banner != null:
				lbl_warning_banner.visible = false
			if meters_container != null:
				meters_container.visible = false

			lbl_settlement_title.text = "%s" % sel_name
			if status_badge != null:
				status_badge.visible = true
				status_badge.set_badge("遠端情報", StatusBadge.Variant.REMOTE)

			if settlement_banner_rect != null:
				settlement_banner_rect.visible = false

			var dest_info: Dictionary = {}
			for d in proj.get("destinations", []):
				if d.get("id") == selected_settlement_id:
					dest_info = d
					break

			var route_days: int = dest_info.get("distance_days", 2)
			if lbl_settlement_subtitle != null:
				lbl_settlement_subtitle.visible = true
				lbl_settlement_subtitle.text = _settlement_flavour(selected_settlement_id)
			if lbl_settlement_condition != null:
				lbl_settlement_condition.visible = false

			lbl_settlement_details.text = (
				"路線狀態：已知通行路徑\n" +
				"地表行軍距離：約 %d 天步程\n" +
				"遠端情報有限；抵達後可查看倉儲與市場行情。"
			) % [route_days]

			if btn_travel != null:
				btn_travel.visible = true
				btn_travel.disabled = false
				btn_travel.text = "前往 %s · %d 天" % [sel_name, route_days]

		if btn_wait != null:
			btn_wait.text = "[ 原地等待 1 天 ]"
			btn_wait.disabled = false
			btn_wait.visible = true
	# Map selection can change the inspected town without a world refresh. Keep
	# the market frame in sync here as well as during encounter rendering.
	if market_panel != null and market_panel.get_parent() != null:
		var active_encounter: Dictionary = proj.get("active_encounter", {})
		var encounter_receipt: Dictionary = proj.get("encounter_result", {})
		market_panel.get_parent().visible = market_panel.visible and active_encounter.is_empty() and encounter_receipt.is_empty()

func _render_event_feed(events: Array) -> void:
	if event_feed_container == null:
		return
	if feed_panel != null:
		feed_panel.visible = debug_world_feed_enabled and not events.is_empty()

	for child in event_feed_container.get_children():
		event_feed_container.remove_child(child)
		child.queue_free()

	if not debug_world_feed_enabled:
		var disabled_lbl := Label.new()
		disabled_lbl.text = "電台靜默中……"
		disabled_lbl.add_theme_color_override("font_color", Color("#555960"))
		event_feed_container.add_child(disabled_lbl)
		return

	for evt in events:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var category: String = evt.get("category", "world")
		var icon_lbl := Label.new()
		icon_lbl.text = _feed_icon(category)
		icon_lbl.add_theme_font_size_override("font_size", 11)
		icon_lbl.custom_minimum_size = Vector2(16, 0)
		row.add_child(icon_lbl)

		var lbl := Label.new()
		lbl.text = "第 %02d 天　%s" % [int(evt.get("day", 0)), String(evt.get("text", ""))]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", _feed_color(category))
		row.add_child(lbl)

		event_feed_container.add_child(row)

# Small icon per event category, so the feed can be skimmed at a glance.
func _feed_icon(category: String) -> String:
	match category:
		"caravan": return "🚚"
		"danger": return "⚠"
		"person": return "👤"
		"people": return "👣"
		"player": return "🧭"
		"trade": return "💰"
	return "•"

func _feed_color(category: String) -> Color:
	match category:
		"danger": return Color("#E05252")
		"caravan": return Color("#39D353")
		"person": return Color("#D9822B")
		"player": return Color("#58A6FF")
		"trade": return Color("#C9A227")
	return Color("#96938B")


# ==============================================================================
# PLACE VOCABULARY
# ==============================================================================
# Plain words the player already understands. Internal status codes such as
# STABLE / HIGH_RISK stay inside the simulation where they belong.
func _supply_word(status: String) -> String:
	match status:
		"STABLE": return "穩定"
		"LOW": return "偏低"
		"CRITICAL": return "吃緊"
	return "未知"

func _market_level_word(level: String) -> String:
	match level:
		"high": return "高"
		"medium": return "中"
		"low": return "低"
		"none": return "無"
		_: return "?"

func _security_word(security: float) -> String:
	if security >= 80.0:
		return "良好"
	if security >= 55.0:
		return "尚可"
	if security >= 30.0:
		return "不安"
	return "動盪"

func _settlement_flavour(settlement_id: String) -> String:
	match settlement_id:
		"settlement:gray_valley": return "工業聚落 · 西部荒谷"
		"settlement:dry_well": return "水井小鎮 · 南方乾原"
		"settlement:new_hope": return "農業聚落 · 東部綠帶"
	return "荒土聚落"

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
	var current_id := String(current_projection.get("player", {}).get("current_container_id", ""))
	desktop_details_open = settlement_id != current_id
	if world_map_view != null:
		world_map_view.selected_settlement_id = settlement_id
		world_map_view.queue_redraw()
	if current_projection.size() > 0:
		_render_settlement_panel(current_projection)
		_render_local_actions(current_projection)
		_sync_desktop(current_projection)

func _return_to_current_settlement() -> void:
	var p: Dictionary = current_projection.get("player", {})
	var location := String(p.get("current_container_id", ""))
	if location.begins_with("settlement:") and not bool(p.get("is_in_transit", false)):
		select_settlement(location)
		if quest_access_button.is_inside_tree() and quest_access_button.visible:
			quest_access_button.grab_focus()

func _show_local_market() -> void:
	var p: Dictionary = current_projection.get("player", {})
	var location := String(p.get("current_container_id", ""))
	if not location.begins_with("settlement:") or bool(p.get("is_in_transit", false)):
		return
	if market_practice_label != null:
		market_practice_label.visible = false
	select_settlement(location)
	desktop_details_open = true
	_sync_desktop(current_projection)
	quest_journal_open = false
	_render_quests(current_projection.get("quests", []))
	await get_tree().process_frame
	if is_instance_valid(right_scroll) and right_scroll.visible and is_instance_valid(market_panel) and market_panel.get_parent().visible:
		var market_top: float = market_panel.get_parent().global_position.y - right_scroll.global_position.y + right_scroll.scroll_vertical
		right_scroll.scroll_vertical = int(market_top)

func _render_local_actions(proj: Dictionary) -> void:
	if local_action_panel == null:
		return
	var p: Dictionary = proj.get("player", {})
	var in_transit := bool(p.get("is_in_transit", false))
	var location := String(p.get("current_container_id", ""))
	var encounter: Dictionary = proj.get("active_encounter", {})
	var encounter_result: Dictionary = proj.get("encounter_result", {})
	var encounter_active := not encounter.is_empty() or not encounter_result.is_empty()
	local_action_panel.visible = not encounter_active
	if in_transit:
		lbl_local_context.text = "目前：旅途中"
		lbl_local_hint.text = "抵達聚落後可查看當地委託與可探索地點。"
		btn_return_local.visible = false
		btn_local_market.visible = false
		return
	lbl_local_context.text = "目前：%s" % _get_settlement_name(location)
	btn_return_local.visible = selected_settlement_id != location
	btn_local_market.visible = true
	var available := 0
	for row in proj.get("quests", []):
		if String(row.status) == "AVAILABLE":
			available += 1
	if location == "settlement:gray_valley":
		lbl_local_hint.text = "此地可接委託 %d 件。近郊補給棚可查看裝備；戰鬥依現場狀態開啟。" % available
	else:
		lbl_local_hint.text = "此地目前可接委託 %d 件。近郊補給棚位於灰谷。" % available

# Every refusal the engine issues has to reach the player. The authority still
# decides; this only stops the screen from pretending nothing was asked.
func _report_action_result(res: Dictionary) -> Dictionary:
	if lbl_action_error == null:
		return res
	if res.get("success", false):
		lbl_action_error.visible = false
		lbl_action_error.text = ""
		return res
	lbl_action_error.visible = true
	lbl_action_error.text = _action_error_text(String(res.get("error", "")))
	return res

func _action_error_text(raw: String) -> String:
	var code := raw.split(":")[0]
	match code:
		"DECEASED_OR_NO_LIFE_STATE": return "這個角色已經死了，無法再行動。"
		"ENCOUNTER_PENDING": return "路上的事還沒處理完。"
		"ENCOUNTER_RESULT_PENDING": return "先確認上一個結算結果。"
		"ALREADY_AT_DESTINATION": return "你已經在這裡了。"
		"INVALID_DESTINATION": return "沒有通往那裡的已知路線。"
	return "目前無法執行這項動作。請確認位置、補給與尚未處理的事件。"

func on_travel_pressed() -> Dictionary:
	if world == null or engine == null or world.player == null:
		return _report_action_result({"success": false, "error": "NO_WORLD_OR_PLAYER"})

	var player_id := world.player.npc_id
	var intent := PlayerIntent.create_travel(player_id, StringName(selected_settlement_id))
	var commit_res := engine.commit_player_intent(world, intent)

	if not commit_res.get("success", false):
		refresh_ui()
		return _report_action_result(commit_res)

	_report_action_result(commit_res)
	refresh_ui()
	travel_triggered.emit(selected_settlement_id, true)
	return commit_res

func on_wait_pressed() -> Dictionary:
	if world == null or engine == null or world.player == null:
		return _report_action_result({"success": false, "error": "NO_WORLD_OR_PLAYER"})

	var intent := PlayerIntent.create_wait(world.player.npc_id)
	var res := engine.commit_player_intent(world, intent)
	_report_action_result(res)
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
		_show_trade_practice(res)

	trade_triggered.emit("BUY", commodity, quantity, res)
	return res

func on_sell_pressed(commodity: String, quantity: int = 1) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}

	var intent := PlayerIntent.create_sell(world.player.npc_id, StringName(commodity), quantity)
	var res := engine.commit_player_intent(world, intent)
	if res.get("success", false):
		refresh_ui()
		_show_trade_practice(res)

	trade_triggered.emit("SELL", commodity, quantity, res)
	return res

func on_buy_item_pressed(item_id: String, quantity: int = 1) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}
	var intent := PlayerIntent.create_buy_item(world.player.npc_id, StringName(item_id), quantity)
	var res := engine.commit_player_intent(world, intent)
	if res.get("success", false):
		refresh_ui()
		_show_trade_practice(res)
	trade_triggered.emit("BUY", item_id, quantity, res)
	return res

func on_sell_item_pressed(item_id: String, quantity: int = 1) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}
	var intent := PlayerIntent.create_sell_item(world.player.npc_id, StringName(item_id), quantity)
	var res := engine.commit_player_intent(world, intent)
	if res.get("success", false):
		refresh_ui()
		_show_trade_practice(res)
	trade_triggered.emit("SELL", item_id, quantity, res)
	return res

func _show_trade_practice(result: Dictionary) -> void:
	if market_practice_label == null:
		return
	var practice: Dictionary = result.get("skill_practice", {})
	market_practice_label.visible = not practice.is_empty()
	if practice.is_empty():
		return
	market_practice_context = String(current_projection.get("player", {}).get("current_container_id", ""))
	market_practice_label.text = "交易能力提升：%d %s" % [int(practice.to_rank),
		CharacterPresentation.RANK_NAMES[int(practice.to_rank)]] if practice.rank_up else \
		"交易練習 +1（%d/%d）" % [int(practice.points), int(practice.required)]

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
	var header := HBoxContainer.new()
	app_frame.add_child(header)
	header.add_child(top_status_bar)
	var character_button := Button.new()
	character_button.text = "人物 / 補給"
	character_button.pressed.connect(_show_character)
	header.add_child(character_button)

	supply_alert = PanelContainer.new()
	supply_alert.visible = false
	supply_alert.theme_type_variation = "PdaPanel"
	app_frame.add_child(supply_alert)
	lbl_supply_alert = Label.new()
	lbl_supply_alert.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_supply_alert.add_theme_font_size_override("font_size", Tokens.SMALL)
	lbl_supply_alert.add_theme_color_override("font_color", Tokens.TEXT)
	supply_alert.add_child(lbl_supply_alert)

	# The run is over. The engine refuses every intent from a dead player, so
	# the screen has to say so; before this existed the buttons stayed lit and
	# the game simply stopped responding.
	death_banner = PanelContainer.new()
	death_banner.visible = false
	var death_style := StyleBoxFlat.new()
	death_style.bg_color = Color("#2A1416")
	death_style.border_color = Color("#8B2F33")
	death_style.set_border_width_all(1)
	death_style.set_corner_radius_all(2)
	death_style.content_margin_left = 12
	death_style.content_margin_right = 12
	death_style.content_margin_top = 8
	death_style.content_margin_bottom = 8
	death_banner.add_theme_stylebox_override("panel", death_style)
	app_frame.add_child(death_banner)

	var death_vbox := VBoxContainer.new()
	death_vbox.add_theme_constant_override("separation", 4)
	death_banner.add_child(death_vbox)

	lbl_death_title = Label.new()
	lbl_death_title.text = "旅程結束"
	lbl_death_title.add_theme_color_override("font_color", Color("#E0555B"))
	lbl_death_title.add_theme_font_size_override("font_size", 18)
	death_vbox.add_child(lbl_death_title)

	lbl_death_body = Label.new()
	lbl_death_body.add_theme_color_override("font_color", Color("#D8D3C8"))
	lbl_death_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	death_vbox.add_child(lbl_death_body)

	# Compatibility labels
	lbl_day = Label.new()
	lbl_player_header = Label.new()
	lbl_hud_location = Label.new()
	lbl_hud_status = Label.new()
	lbl_hud_money = Label.new()
	lbl_hud_backpack = Label.new()
	lbl_hud_commodities = Label.new()

	# The current place and its available actions lead the reading order. The map
	# remains the route selector, not the largest surface on every screen.
	var center_split := HBoxContainer.new()
	center_split.size_flags_vertical = SIZE_EXPAND_FILL
	center_split.add_theme_constant_override("separation", 8)
	app_frame.add_child(center_split)

	# --- Left: Tactical World Map Panel ---
	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 0.8
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
	# The right column stacks a settlement card, an encounter card and a market,
	# and their combined MINIMUM height was larger than the window: a Godot
	# VBoxContainer will not shrink a child below its minimum, so the whole
	# bottom row (supplies, radio, the WAIT button) was pushed off the screen
	# and the market itself was clipped. Scrolling the column keeps every panel
	# reachable at any window size instead of silently losing the ones below.
	var right_workspace := VBoxContainer.new()
	right_workspace.size_flags_horizontal = SIZE_EXPAND_FILL
	right_workspace.size_flags_vertical = SIZE_EXPAND_FILL
	right_workspace.size_flags_stretch_ratio = 1.6
	right_workspace.add_theme_constant_override("separation", Tokens.GAP)
	center_split.add_child(right_workspace)
	center_split.move_child(right_workspace, 0)

	local_action_panel = PanelContainer.new()
	local_action_panel.theme_type_variation = "PdaPanel"
	right_workspace.add_child(local_action_panel)
	var local_column := VBoxContainer.new()
	local_column.add_theme_constant_override("separation", 4)
	local_action_panel.add_child(local_column)
	var local_row := HBoxContainer.new()
	local_row.add_theme_constant_override("separation", Tokens.GAP)
	local_column.add_child(local_row)
	lbl_local_context = Label.new()
	lbl_local_context.theme_type_variation = "PdaSection"
	lbl_local_context.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl_local_context.clip_text = true
	local_row.add_child(lbl_local_context)
	btn_return_local = Button.new()
	btn_return_local.text = "查看所在地"
	btn_return_local.theme_type_variation = "PdaCommand"
	btn_return_local.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	btn_return_local.pressed.connect(_return_to_current_settlement)
	local_row.add_child(btn_return_local)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", Tokens.GAP)
	local_column.add_child(action_row)
	btn_local_market = Button.new()
	btn_local_market.text = "本地市場"
	btn_local_market.theme_type_variation = "PdaCommand"
	btn_local_market.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	btn_local_market.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_local_market.pressed.connect(_show_local_market)
	action_row.add_child(btn_local_market)
	field_button = Button.new()
	field_button.theme_type_variation = "PdaCommand"
	field_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	field_button.size_flags_horizontal = SIZE_EXPAND_FILL
	field_button.pressed.connect(_show_field)
	action_row.add_child(field_button)
	btn_wait = Button.new()
	btn_wait.text = "[ 原地等待 1 天 ]"
	btn_wait.theme_type_variation = "PdaCommand"
	btn_wait.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	btn_wait.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_wait.pressed.connect(func(): on_wait_pressed())
	action_row.add_child(btn_wait)
	lbl_local_hint = Label.new()
	lbl_local_hint.theme_type_variation = "PdaMuted"
	lbl_local_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	local_column.add_child(lbl_local_hint)

	quest_access_button = Button.new()
	quest_access_button.theme_type_variation = "PdaCommand"
	quest_access_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	quest_access_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	quest_access_button.clip_text = true
	quest_access_button.focus_mode = Control.FOCUS_ALL
	quest_access_button.pressed.connect(_on_quest_access_pressed)
	right_workspace.add_child(quest_access_button)

	right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_workspace.add_child(right_scroll)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = SIZE_EXPAND_FILL
	right_col.size_flags_vertical = SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 8)
	right_scroll.add_child(right_col)

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
	settlement_banner_rect.custom_minimum_size = Vector2(0, 64)
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
	# Subtitle: what kind of place this is, before any number appears.
	lbl_settlement_subtitle = Label.new()
	lbl_settlement_subtitle.text = "工業聚落 · 西部荒谷"
	lbl_settlement_subtitle.add_theme_color_override("font_color", Color("#96938B"))
	lbl_settlement_subtitle.add_theme_font_size_override("font_size", 11)
	s_vbox.add_child(lbl_settlement_subtitle)

	lbl_warning_banner = Label.new()
	lbl_warning_banner.visible = false
	lbl_warning_banner.add_theme_font_size_override("font_size", 12)
	s_vbox.add_child(lbl_warning_banner)

	# Plain-language condition lines answer "how is it here?" before the meters
	# answer "exactly how much is in the warehouse?".
	lbl_settlement_condition = Label.new()
	lbl_settlement_condition.add_theme_color_override("font_color", Color("#D8D3C8"))
	lbl_settlement_condition.add_theme_font_size_override("font_size", 12)
	s_vbox.add_child(lbl_settlement_condition)

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
	btn_travel.text = "前往"
	btn_travel.theme_type_variation = "PdaPrimary"
	btn_travel.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	btn_travel.visible = false
	btn_travel.pressed.connect(func(): on_travel_pressed())
	s_vbox.add_child(btn_travel)

	settlement_detail_toggle = Button.new()
	settlement_detail_toggle.text = "查看聚落數據 ▸"
	settlement_detail_toggle.toggle_mode = true
	settlement_detail_toggle.theme_type_variation = "PdaCommand"
	settlement_detail_toggle.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	settlement_detail_toggle.toggled.connect(func(open: bool):
		settlement_detail_toggle.text = "收起聚落數據 ▾" if open else "查看聚落數據 ▸"
		if settlement_detail_body != null:
			settlement_detail_body.visible = open
	)
	s_vbox.add_child(settlement_detail_toggle)
	settlement_detail_body = VBoxContainer.new()
	settlement_detail_body.add_theme_constant_override("separation", Tokens.GAP)
	settlement_detail_body.visible = false
	s_vbox.add_child(settlement_detail_body)
	for detail in [settlement_banner_rect, lbl_settlement_condition, meters_container, lbl_settlement_details]:
		detail.reparent(settlement_detail_body)
	s_vbox.move_child(settlement_detail_toggle, 4)
	s_vbox.move_child(settlement_detail_body, 5)

	quest_panel = PanelContainer.new()
	quest_panel.theme_type_variation = "PdaPanel"
	quest_panel.size_flags_vertical = SIZE_EXPAND_FILL
	right_workspace.add_child(quest_panel)
	var quest_column := VBoxContainer.new()
	quest_column.add_theme_constant_override("separation", Tokens.GAP)
	quest_panel.add_child(quest_column)
	var quest_header := HBoxContainer.new()
	quest_column.add_child(quest_header)
	var quest_heading := Label.new()
	quest_heading.text = "委託紀錄"
	quest_heading.theme_type_variation = "PdaSection"
	quest_heading.size_flags_horizontal = SIZE_EXPAND_FILL
	quest_header.add_child(quest_heading)
	quest_close_button = Button.new()
	quest_close_button.text = "返回聚落"
	quest_close_button.theme_type_variation = "PdaCommand"
	quest_close_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	quest_close_button.pressed.connect(_on_quest_close_pressed)
	quest_header.add_child(quest_close_button)
	quest_selector = OptionButton.new()
	quest_selector.theme_type_variation = "PdaCommand"
	quest_selector.focus_mode = Control.FOCUS_ALL
	quest_selector.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	quest_selector.item_selected.connect(_on_quest_selected)
	quest_column.add_child(quest_selector)
	var quest_scroll := ScrollContainer.new()
	quest_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	quest_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	quest_column.add_child(quest_scroll)
	var quest_details := VBoxContainer.new()
	quest_details.size_flags_horizontal = SIZE_EXPAND_FILL
	quest_details.add_theme_constant_override("separation", Tokens.GAP)
	quest_scroll.add_child(quest_details)
	quest_title = Label.new()
	quest_title.theme_type_variation = "PdaSection"
	quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_details.add_child(quest_title)
	quest_description = Label.new()
	quest_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_details.add_child(quest_description)
	quest_progress = Label.new()
	quest_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_details.add_child(quest_progress)
	quest_button = Button.new()
	quest_button.theme_type_variation = "PdaPrimary"
	quest_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	quest_button.pressed.connect(_on_quest_pressed)
	quest_column.add_child(quest_button)
	quest_panel.visible = false

	# ==========================================================================
	# TRAVEL ENCOUNTER PANEL (Active only while the road is asking something)
	# ==========================================================================
	# Shown INSTEAD of the settlement panel: standing at a barricade is not a
	# moment for reading market prices.
	encounter_panel = PanelContainer.new()
	encounter_panel.size_flags_vertical = SIZE_EXPAND_FILL
	encounter_panel.visible = false
	right_col.add_child(encounter_panel)

	encounter_vbox = VBoxContainer.new()
	encounter_vbox.add_theme_constant_override("separation", 6)
	encounter_panel.add_child(encounter_vbox)

	encounter_vbox.add_child(_create_window_header("路上 TRAVEL ENCOUNTER", "⚠"))

	lbl_encounter_route = Label.new()
	lbl_encounter_route.add_theme_color_override("font_color", Color("#96938B"))
	lbl_encounter_route.add_theme_font_size_override("font_size", 11)
	encounter_vbox.add_child(lbl_encounter_route)

	# Hide the reserved art slot until a real encounter illustration exists.
	var art_placeholder := PanelContainer.new()
	art_placeholder.visible = false
	art_placeholder.custom_minimum_size = Vector2(0, 96)
	var art_style := StyleBoxFlat.new()
	art_style.bg_color = Color("#141A24")
	art_style.border_color = Color("#344158")
	art_style.set_border_width_all(1)
	art_style.set_corner_radius_all(2)
	art_placeholder.add_theme_stylebox_override("panel", art_style)
	var art_lbl := Label.new()
	art_lbl.text = "（場景插畫）"
	art_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_lbl.add_theme_color_override("font_color", Color("#3D4657"))
	art_lbl.add_theme_font_size_override("font_size", 11)
	art_placeholder.add_child(art_lbl)
	encounter_vbox.add_child(art_placeholder)
	encounter_art = art_placeholder

	lbl_encounter_title = Label.new()
	lbl_encounter_title.add_theme_color_override("font_color", Color("#D9822B"))
	lbl_encounter_title.add_theme_font_size_override("font_size", 14)
	encounter_vbox.add_child(lbl_encounter_title)

	lbl_encounter_body = Label.new()
	lbl_encounter_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_encounter_body.add_theme_color_override("font_color", Color("#D8D3C8"))
	lbl_encounter_body.add_theme_font_size_override("font_size", 12)
	encounter_vbox.add_child(lbl_encounter_body)

	# What you are carrying, shown right next to the decision that spends it.
	lbl_encounter_supplies = Label.new()
	lbl_encounter_supplies.add_theme_color_override("font_color", Color("#C9A227"))
	lbl_encounter_supplies.add_theme_font_size_override("font_size", 12)
	encounter_vbox.add_child(lbl_encounter_supplies)

	encounter_options_box = VBoxContainer.new()
	encounter_options_box.add_theme_constant_override("separation", 4)
	encounter_vbox.add_child(encounter_options_box)

	# Lower Right: Marketplace Panel
	var m_panel := PanelContainer.new()
	m_panel.size_flags_vertical = SIZE_EXPAND_FILL
	right_col.add_child(m_panel)

	market_panel = VBoxContainer.new()
	market_panel.add_theme_constant_override("separation", 4)
	m_panel.add_child(market_panel)

	market_panel.add_child(_create_window_header("交易市場 MARKETPLACE", "🛒"))
	market_practice_label = Label.new()
	market_practice_label.theme_type_variation = "PdaMuted"
	market_practice_label.visible = false
	market_panel.add_child(market_practice_label)

	var commodities_spec := [
		{"key": "water", "name": "水"},
		{"key": "food", "name": "食物"},
		{"key": "scrap", "name": "廢料"},
		{"key": "fuel", "name": "燃料"}
	]

	for c in commodities_spec:
		var row := MarketRowView.new(c["key"], c["name"])
		row.buy_requested.connect(func(key: String): on_buy_pressed(key, 1))
		row.sell_requested.connect(func(key: String): on_sell_pressed(key, 1))
		market_panel.add_child(row)
		market_rows[c["key"]] = row

		market_trade_buttons["buy_" + c["key"]] = row.btn_buy
		market_trade_buttons["sell_" + c["key"]] = row.btn_sell
		market_trade_buttons[c["key"] + "_label"] = row.lbl_stock

	item_market_toggle = Button.new()
	item_market_toggle.text = "物品商店／區域供需　▸"
	item_market_toggle.toggle_mode = true
	item_market_toggle.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	item_market_toggle.theme_type_variation = "PdaCommand"
	item_market_toggle.toggled.connect(func(open: bool):
		item_market_toggle.text = "物品商店／區域供需　%s" % ("▾" if open else "▸")
		if item_market_scroll != null:
			item_market_scroll.visible = open
	)
	market_panel.add_child(item_market_toggle)

	item_market_scroll = ScrollContainer.new()
	item_market_scroll.custom_minimum_size = Vector2(0, 150)
	item_market_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	item_market_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_market_scroll.visible = false
	market_panel.add_child(item_market_scroll)
	item_market_rows_box = VBoxContainer.new()
	item_market_rows_box.add_theme_constant_override("separation", 4)
	item_market_rows_box.size_flags_horizontal = SIZE_EXPAND_FILL
	item_market_scroll.add_child(item_market_rows_box)
	for definition in ItemRegistry.all_definitions():
		var item_id := String(definition.item_id)
		var item_row := MarketRowView.new(item_id, String(definition.display_name_zh))
		item_row.buy_requested.connect(func(key: String): on_buy_item_pressed(key, 1))
		item_row.sell_requested.connect(func(key: String): on_sell_item_pressed(key, 1))
		item_market_rows_box.add_child(item_row)
		item_market_rows[item_id] = item_row

	# 3. Bottom Split: Left Survival Resources (55%) vs Right Event Feed (45%)
	var bottom_split := HBoxContainer.new()
	bottom_split.custom_minimum_size = Vector2(0, 92)
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

	res_vbox.add_child(_create_window_header("隨身補給", "🎒"))

	var chips_hbox := HBoxContainer.new()
	chips_hbox.add_theme_constant_override("separation", 6)
	chips_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	res_vbox.add_child(chips_hbox)

	chip_water = ResourceChip.new("water", "水", 0)
	chips_hbox.add_child(chip_water)
	chip_food = ResourceChip.new("food", "食物", 0)
	chips_hbox.add_child(chip_food)
	chip_scrap = ResourceChip.new("scrap", "廢料", 0)
	chips_hbox.add_child(chip_scrap)
	chip_fuel = ResourceChip.new("fuel", "燃料", 0)
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

	# Running out of water used to be invisible until it killed you. The warning
	# is stated in days, not in a pressure number, because days are what the
	# player is actually budgeting against the road ahead.
	lbl_supply_warning = Label.new()
	lbl_supply_warning.visible = false
	lbl_supply_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_supply_warning.add_theme_font_size_override("font_size", Tokens.SMALL)
	res_vbox.add_child(lbl_supply_warning)

	# A refused intent is a fact the player is entitled to. Silently dropping it
	# is what made a dead character look like a frozen UI.
	lbl_action_error = Label.new()
	lbl_action_error.visible = false
	lbl_action_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_action_error.add_theme_color_override("font_color", Color("#E0555B"))
	lbl_action_error.add_theme_font_size_override("font_size", 11)
	res_vbox.add_child(lbl_action_error)

	# Debug history is optional; an empty log does not reserve half the screen.
	feed_panel = PanelContainer.new()
	feed_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	feed_panel.size_flags_stretch_ratio = 1.0
	bottom_split.add_child(feed_panel)

	var feed_vbox := VBoxContainer.new()
	feed_vbox.add_theme_constant_override("separation", 4)
	feed_panel.add_child(feed_vbox)

	feed_vbox.add_child(_create_window_header("世界紀錄（開發資訊）", "📻"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	feed_vbox.add_child(scroll)

	event_feed_container = VBoxContainer.new()
	event_feed_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(event_feed_container)
	_install_desktop_layout(app_frame, center_split, map_panel, right_workspace, bottom_split, res_vbox, map_vbox)

func _install_desktop_layout(app_frame: VBoxContainer, center_split: HBoxContainer, map_panel: PanelContainer, right_workspace: VBoxContainer, bottom_split: HBoxContainer, res_vbox: VBoxContainer, map_vbox: VBoxContainer) -> void:
	var backdrop := DesktopBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	app_frame.add_theme_constant_override("separation", 6)
	app_frame.get_child(0).hide()
	var toolbar := PanelContainer.new()
	var toolbar_style := StyleBoxFlat.new()
	toolbar_style.bg_color = Color("#DCDAD2")
	toolbar_style.border_color = Color("#7E7E7C")
	toolbar_style.set_border_width_all(1)
	toolbar_style.content_margin_left = 6
	toolbar_style.content_margin_right = 6
	toolbar_style.content_margin_top = 3
	toolbar_style.content_margin_bottom = 3
	toolbar.add_theme_stylebox_override("panel", toolbar_style)
	app_frame.add_child(toolbar)
	app_frame.move_child(toolbar, 0)
	var toolbar_row := HBoxContainer.new()
	toolbar_row.add_theme_constant_override("separation", 4)
	toolbar.add_child(toolbar_row)
	for command in [{"label": "場景", "action": _show_desktop_scene}, {"label": "資訊", "action": _show_desktop_details}, {"label": "委託", "action": _on_quest_access_pressed}, {"label": "市場", "action": _show_local_market}, {"label": "人物", "action": _show_character}, {"label": "近郊", "action": _show_field}]:
		var button := DesktopWindow.toolbar_button(command.label)
		button.pressed.connect(command.action)
		toolbar_row.add_child(button)
	var toolbar_spacer := Control.new()
	toolbar_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	toolbar_row.add_child(toolbar_spacer)
	var toolbar_title := Label.new()
	toolbar_title.text = "荒原編年史"
	toolbar_title.add_theme_color_override("font_color", Color("#20242C"))
	toolbar_row.add_child(toolbar_title)
	center_split.add_theme_constant_override("separation", 12)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.size_flags_vertical = SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.8
	left.add_theme_constant_override("separation", 8)
	center_split.add_child(left)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = SIZE_EXPAND_FILL
	side.size_flags_vertical = SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 0.95
	side.add_theme_constant_override("separation", 8)
	center_split.add_child(side)

	desktop_scene_window = DesktopWindow.new("聚落場景")
	desktop_scene_window.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_child(desktop_scene_window)
	desktop_scene_art = TextureRect.new()
	desktop_scene_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desktop_scene_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desktop_scene_art.custom_minimum_size.y = 180
	desktop_scene_art.size_flags_vertical = SIZE_EXPAND_FILL
	desktop_scene_window.body.add_child(desktop_scene_art)
	local_action_panel.reparent(desktop_scene_window.body)

	desktop_window_layer = Control.new()
	desktop_window_layer.name = "FloatingWindows"
	desktop_window_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	desktop_window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desktop_window_layer)
	desktop_window_layer.resized.connect(_layout_desktop_details)
	desktop_details_window = DesktopWindow.new("聚落與旅途")
	desktop_details_window.name = "InformationWindow"
	desktop_details_window.visible = false
	desktop_details_window.enable_floating()
	desktop_details_window.close_requested.connect(_show_desktop_scene)
	desktop_window_layer.add_child(desktop_details_window)
	desktop_back_button = Button.new()
	desktop_back_button.text = "關閉資訊視窗"
	desktop_back_button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
	desktop_back_button.pressed.connect(_show_desktop_scene)
	desktop_details_window.body.add_child(desktop_back_button)
	right_workspace.reparent(desktop_details_window.body)
	right_workspace.size_flags_vertical = SIZE_EXPAND_FILL
	# Information is an independent desktop window. The scene remains mounted.
	_layout_desktop_details()

	var message_window := DesktopWindow.new("訊息與隨身補給")
	message_window.custom_minimum_size.y = 106
	left.add_child(message_window)
	bottom_split.reparent(message_window.body)
	bottom_split.custom_minimum_size.y = 0
	var old_supply_header := res_vbox.get_child(0)
	res_vbox.remove_child(old_supply_header)
	old_supply_header.queue_free()
	desktop_message = Label.new()
	desktop_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desktop_message.add_theme_color_override("font_color", Tokens.TEXT)
	res_vbox.add_child(desktop_message)
	res_vbox.move_child(desktop_message, 0)

	var character_window := DesktopWindow.new("人物")
	character_window.custom_minimum_size.y = 112
	side.add_child(character_window)
	var person_row := HBoxContainer.new()
	person_row.add_theme_constant_override("separation", 12)
	character_window.body.add_child(person_row)
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(64, 72)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var avatar_image := Image.load_from_file(ProjectSettings.globalize_path("res://ui/assets/combat/drifter.png"))
	if avatar_image != null:
		avatar.texture = ImageTexture.create_from_image(avatar_image)
	person_row.add_child(avatar)
	var person_text := VBoxContainer.new()
	person_text.size_flags_horizontal = SIZE_EXPAND_FILL
	person_row.add_child(person_text)
	desktop_profile_name = Label.new()
	desktop_profile_name.theme_type_variation = "PdaSection"
	desktop_profile_name.clip_text = true
	person_text.add_child(desktop_profile_name)
	desktop_profile_vitals = Label.new()
	desktop_profile_vitals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	person_text.add_child(desktop_profile_vitals)

	var tools_window := DesktopWindow.new("工具")
	side.add_child(tools_window)
	var tool_row := HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 4)
	tools_window.body.add_child(tool_row)
	for command in [{"label": "場景", "action": _show_desktop_scene}, {"label": "資料", "action": _show_desktop_details}, {"label": "人物", "action": _show_character}]:
		var button := Button.new()
		button.text = command.label
		button.custom_minimum_size.y = Tokens.COMMAND_HEIGHT
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(command.action)
		tool_row.add_child(button)
	quest_access_button.reparent(tools_window.body)
	quest_access_button.text = "委託"

	var map_window := DesktopWindow.new("地圖")
	map_window.size_flags_vertical = SIZE_EXPAND_FILL
	side.add_child(map_window)
	var old_map_header := map_vbox.get_child(0)
	map_vbox.remove_child(old_map_header)
	old_map_header.queue_free()
	map_panel.reparent(map_window.body)
	map_panel.size_flags_vertical = SIZE_EXPAND_FILL
	world_map_view.custom_minimum_size = Vector2(300, 220)

func _show_desktop_scene() -> void:
	var location := String(current_projection.get("player", {}).get("current_container_id", ""))
	if location.begins_with("settlement:") and not bool(current_projection.get("player", {}).get("is_in_transit", false)):
		select_settlement(location)
	quest_journal_open = false
	_render_quests(current_projection.get("quests", []))
	desktop_details_open = false
	_sync_desktop(current_projection)

func _show_desktop_details() -> void:
	desktop_details_open = true
	_sync_desktop(current_projection)

func _layout_desktop_details() -> void:
	if desktop_details_window == null or desktop_window_layer == null:
		return
	var available := desktop_window_layer.size
	if available.x < 1.0 or available.y < 1.0:
		return
	var window_size := Vector2(minf(680.0, maxf(500.0, available.x * 0.38)), minf(620.0, maxf(360.0, available.y - 190.0)))
	# Encounter action text can make the window wider than the requested size.
	# Place it using the actual minimum so narrow viewports keep every choice visible.
	var content_minimum := desktop_details_window.get_combined_minimum_size()
	window_size.x = minf(maxf(window_size.x, content_minimum.x), available.x - 16.0)
	window_size.y = minf(maxf(window_size.y, content_minimum.y), available.y - 64.0)
	desktop_details_window.size = window_size
	var initial := Vector2(available.x - window_size.x - 12.0, minf(205.0, available.y - window_size.y - 12.0))
	if not desktop_details_window.has_meta("placed"):
		desktop_details_window.position = initial
		desktop_details_window.set_meta("placed", true)
	else:
		desktop_details_window.position = Vector2(
			clampf(desktop_details_window.position.x, 0.0, maxf(0.0, available.x - window_size.x)),
			clampf(desktop_details_window.position.y, 48.0, maxf(48.0, available.y - window_size.y)))

func _sync_desktop(proj: Dictionary) -> void:
	if desktop_scene_window == null:
		return
	var player: Dictionary = proj.get("player", {})
	var current_id := String(player.get("current_container_id", ""))
	var in_transit := bool(player.get("is_in_transit", false))
	var encounter: Dictionary = proj.get("active_encounter", {})
	var encounter_result: Dictionary = proj.get("encounter_result", {})
	var active_encounter := not encounter.is_empty() or not encounter_result.is_empty()
	var show_details := desktop_details_open or quest_journal_open or in_transit or active_encounter
	desktop_scene_window.visible = true
	desktop_details_window.visible = show_details
	desktop_details_window.close_button.disabled = in_transit or active_encounter
	desktop_details_window.close_button.tooltip_text = "先完成旅程或路上事件。" if desktop_details_window.close_button.disabled else "關閉視窗"
	if show_details:
		_layout_desktop_details()
	if desktop_back_button != null:
		desktop_back_button.visible = false
		desktop_back_button.disabled = in_transit or active_encounter
		desktop_back_button.tooltip_text = "先完成旅程或路上事件。" if desktop_back_button.disabled else ""
	if desktop_profile_name != null:
		desktop_profile_name.text = String(player.get("name", "流浪者"))
	if desktop_profile_vitals != null:
		var health := int(player.get("health", 12))
		desktop_profile_vitals.text = "生命 %d / 12\n第 %d 天 · %d 瓶蓋" % [health, int(proj.get("current_day", 0)), int(player.get("money", 0))]
	if desktop_message != null:
		if active_encounter:
			desktop_message.text = "路上有事需要處理。選擇做法後，確認結果再繼續。"
		elif in_transit:
			desktop_message.text = "正在前往 %s；還有 %d 天路程。" % [_get_settlement_name(String(player.get("destination_id", ""))), int(player.get("days_remaining", 0))]
		else:
			desktop_message.text = "%s　·　%s" % [_get_settlement_name(current_id), _settlement_flavour(current_id)]
	if current_id.begins_with("settlement:"):
		desktop_scene_window.title_label.text = "%s｜聚落場景" % _get_settlement_name(current_id)
		var scene_file: String = {"settlement:gray_valley": "gray_valley_scene.png", "settlement:dry_well": "dry_well_scene.png", "settlement:new_hope": "new_hope_scene.png"}.get(current_id, "")
		if scene_file != "" and desktop_scene_art.get_meta("scene_file", "") != scene_file:
			var img := Image.load_from_file(ProjectSettings.globalize_path("res://ui/assets/settlements/" + scene_file))
			if img != null:
				desktop_scene_art.texture = ImageTexture.create_from_image(img)
				desktop_scene_art.set_meta("scene_file", scene_file)


# ==============================================================================
# S5-B4: TRAVEL ENCOUNTER
# ==============================================================================
func _render_encounter(enc: Dictionary, result: Dictionary = {}) -> void:
	if encounter_panel == null:
		return

	var resolved := not result.is_empty()
	var active: bool = not enc.is_empty() or resolved
	encounter_panel.visible = active
	encounter_art.visible = false
	if s_panel != null and active:
		s_panel.visible = false
	if market_panel != null and market_panel.get_parent() != null:
		# Hide the container too. Leaving an empty market frame visible for a
		# remote town made half of the detail pane look like missing content.
		market_panel.get_parent().visible = not active and market_panel.visible
	if btn_wait != null:
		btn_wait.visible = not active
	if active:
		itinerary_card.visible = false
		inspection_subcard.visible = false
		btn_travel.visible = false

	for child in encounter_options_box.get_children():
		encounter_options_box.remove_child(child)
		child.queue_free()
	if not active:
		return
	if resolved:
		_render_encounter_result(result)
		return

	lbl_encounter_route.text = String(enc.get("route_label", ""))
	lbl_encounter_title.text = String(enc.get("title", ""))
	lbl_encounter_body.text = String(enc.get("body", ""))

	var bp: Dictionary = current_projection.get("player", {}).get("backpack", {})
	lbl_encounter_supplies.text = "目前：💧 %d　🍴 %d　⚙ %d　⛽ %d　💰 %d" % [
		int(bp.get("water", 0)), int(bp.get("food", 0)),
		int(bp.get("scrap", 0)), int(bp.get("fuel", 0)),
		int(current_projection.get("player", {}).get("money", 0))
	]

	for option in enc.get("options", []):
		var btn := Button.new()
		# S5-C2: an approach only this character has is marked with the thing
		# that unlocked it, so "I can do this because I am a mechanic" is
		# readable on the road rather than inferred afterwards.
		var requirement := String(option.get("requirement_label", ""))
		if bool(option.get("locked", false)):
			# Shown so the player can see what they would need. This is the
			# "以前做不到，後來做得到" moment waiting to happen.
			btn.text = "%s　—　需要：%s" % [String(option.get("label", "")), requirement]
		elif requirement != "":
			btn.text = "〔%s〕%s　—　%s" % [
				requirement, String(option.get("label", "")), String(option.get("detail", ""))
			]
			btn.add_theme_color_override("font_color", Color("#C9A227"))
			btn.add_theme_color_override("font_hover_color", Color("#E5BC4A"))
		else:
			btn.text = "%s　—　%s" % [String(option.get("label", "")), String(option.get("detail", ""))]
		btn.custom_minimum_size = Vector2(0, Tokens.COMMAND_HEIGHT)
		btn.disabled = not bool(option.get("enabled", true))
		if btn.disabled:
			btn.tooltip_text = _encounter_blocked_text(option)
		var option_id := String(option.get("id", ""))
		btn.pressed.connect(func(): on_encounter_option_pressed(option_id))
		encounter_options_box.add_child(btn)

func _resource_lines(amounts: Dictionary, prefix: String) -> String:
	var names := {"water": "💧 水", "food": "🍴 食物", "scrap": "⚙ 廢料", "fuel": "⛽ 燃料", "caps": "💰 瓶蓋"}
	var lines: PackedStringArray = []
	for key in names:
		if int(amounts.get(key, 0)) > 0:
			lines.append("%s %s%d" % [names[key], prefix, int(amounts[key])])
	return "\n".join(lines)

func _item_lines(amounts: Dictionary, prefix: String) -> String:
	var lines: PackedStringArray = []
	var ids: Array = amounts.keys()
	ids.sort()
	for item_id in ids:
		var resolved := ItemRegistry.resolve(item_id)
		if not resolved.success or int(amounts[item_id]) <= 0:
			continue
		lines.append("▣ %s %s%d" % [String(resolved.definition.display_name_zh), prefix, int(amounts[item_id])])
	return "\n".join(lines)

func _render_encounter_result(result: Dictionary) -> void:
	lbl_encounter_route.text = String(result.route_label)
	lbl_encounter_title.text = "%s · 結算結果" % String(result.title)
	var descriptions := {
		"SEARCH": "你花了一天搜尋貨車殘骸。", "LEAVE": "你決定離開。",
		"CLEAR": "你用廢料墊出了通道。", "DETOUR": "你花了一天繞過障礙。",
		"PAY": "你付了過路費。", "GIVE_WATER": "你交給旅人一份水。",
		"SHARE_FOOD": "你分給逃難的人群一份食物。",
		"STRIP_PARTS": "你花了一天，把引擎和傳動上還能用的部件拆了下來。",
		"QUICK_PICK": "你掃了一眼車廂，把值得帶走的拿了就走，沒有耽誤行程。",
		"SCOUT_PATH": "你從坡面的走向看出一條路，繞過了崩塌處。",
		"FORCE_THROUGH": "你直接從土石上翻了過去。",
		"HAGGLE": "你把過路費談了下來。",
		"SLIP_PAST": "你等到天黑，從關卡旁邊摸了過去。",
		"HYDRATE": "你讓他慢慢喝下水，確認他能自己站起來。",
		"TAKE_PACK": "你拿走了他的背包。他還坐在那裡。",
		"TRADE_COLUMN": "你用瓶蓋跟他們換了些東西。",
		"BRIBE": "你交出瓶蓋破財消災，劫匪收下後放你通行。",
		"FLEE_ROAD": "你找準時機轉身逃跑，繞了一大圈才甩開劫匪。",
	}
	var gains := _resource_lines(result.gained, "+")
	var item_gains := _item_lines(result.get("items_gained", {}), "+")
	var losses := _resource_lines(result.spent, "−")
	var left := _resource_lines(result.left_behind, "")
	var item_left := _item_lines(result.get("items_left_behind", {}), "")
	if not item_gains.is_empty():
		gains = gains + ("\n" if not gains.is_empty() else "") + item_gains
	if gains.is_empty():
		gains = "沒有獲得物資。"
		if result.option == "SEARCH" and left.is_empty() and item_left.is_empty():
			gains = "你翻遍了車廂，沒有找到值得帶走的東西。"
	lbl_encounter_body.text = "%s\n\n獲得\n%s\n\n消耗\n%s\n\n時間\n+%d 天" % [
		descriptions.get(result.option, "選擇已結算。"), gains,
		losses if not losses.is_empty() else "無", int(result.elapsed_days)]
	var practice: Dictionary = result.get("skill_practice", {})
	if not practice.is_empty():
		var name: String = CharacterPresentation.SKILL_NAMES.get(String(practice.skill_id), String(practice.skill_id))
		if practice.rank_up:
			lbl_encounter_body.text += "\n\n能力成長\n%s %d → %d %s" % [name, int(practice.from_rank),
				int(practice.to_rank), CharacterPresentation.RANK_NAMES[int(practice.to_rank)]]
		else:
			lbl_encounter_body.text += "\n\n能力練習\n%s +1（%d/%d）" % [name, int(practice.points), int(practice.required)]
	if not left.is_empty():
		lbl_encounter_body.text += "\n\n背包空間不足，未帶走\n%s" % left
	if not item_left.is_empty():
		lbl_encounter_body.text += "\n\n物品容量不足，未帶走\n%s" % item_left
	if result.is_dead:
		lbl_encounter_body.text += "\n\n你已在這段時間死亡，旅程結束。"
	var bp: Dictionary = current_projection.player.backpack
	lbl_encounter_supplies.text = "目前補給：💧 水 %d　🍴 食物 %d" % [int(bp.water), int(bp.food)]
	var btn := Button.new()
	btn.text = "繼續上路" if result.can_continue else "確認結果"
	btn.custom_minimum_size = Vector2(0, 36)
	var receipt := int(result.result_index)
	btn.pressed.connect(func():
		btn.disabled = true
		on_encounter_continue_pressed(receipt))
	encounter_options_box.add_child(btn)
	_focus_result_button.call_deferred(btn)

func _focus_result_button(btn: Button) -> void:
	if is_instance_valid(btn) and btn.is_inside_tree() and btn.is_visible_in_tree():
		btn.grab_focus()

func on_encounter_continue_pressed(receipt: int) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}
	var res := engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, receipt))
	_report_action_result(res)
	refresh_ui()
	return res

# The button dispatches an intent. It never applies the encounter itself.
func on_encounter_option_pressed(option_id: String) -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}
	var intent := PlayerIntent.create_resolve_encounter(world.player.npc_id, StringName(option_id))
	var res := engine.commit_player_intent(world, intent)
	_report_action_result(res)
	refresh_ui()
	if not world.field_state.battle.is_empty():
		_show_field()
	return res

func _create_window_header(title_text: String, icon_str: String = "") -> PanelContainer:
	var header_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Tokens.ELEVATED
	style.border_color = Tokens.BORDER
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
	lbl.add_theme_font_size_override("font_size", Tokens.SMALL)
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	return header_panel

func _render_quests(rows: Array) -> void:
	if quest_panel == null:
		return
	var can_show: bool = world.active_encounter == null and world.pending_encounter_result < 0 and world.field_state.battle.is_empty() and world.field_state.receipt < 0
	if not can_show:
		quest_journal_open = false
	quest_access_button.visible = can_show
	quest_panel.visible = can_show and quest_journal_open
	right_scroll.visible = not quest_panel.visible
	if not can_show:
		return
	var available_count := 0
	var active_count := 0
	var completed_count := 0
	var other_ended_count := 0
	for option in rows:
		match String(option.status):
			"AVAILABLE": available_count += 1
			"ACTIVE": active_count += 1
			"RESOLVED": completed_count += 1
			_: other_ended_count += 1
	var other_ended_label := "　未完成 %d" % other_ended_count if other_ended_count > 0 else ""
	quest_access_button.text = "委託　可接 %d　進行中 %d　已完成 %d%s　%s" % [available_count, active_count, completed_count, other_ended_label, "返回聚落 ›" if quest_journal_open else "查看 ›"]
	quest_access_button.tooltip_text = "查看當地可接委託，以及已接受委託的進度和紀錄。"
	if rows.is_empty():
		quest_id_shown = ""
		quest_selector.clear()
		quest_selector.visible = false
		quest_title.text = "此地目前沒有可接的委託"
		quest_description.text = "委託告示板只顯示當地工作；其他聚落的工作需要親自到當地查看。"
		quest_progress.text = "已接下的委託與完成紀錄也會列在這裡。"
		quest_button.visible = false
		return
	var selected_index := -1
	for i in rows.size():
		if String(rows[i].id) == quest_id_shown:
			selected_index = i
			break
	if selected_index < 0:
		selected_index = 0
	quest_selector.clear()
	for i in rows.size():
		var option: Dictionary = rows[i]
		var state_label: String = {"AVAILABLE": "可接", "ACTIVE": "進行中", "RESOLVED": "已完成", "EXPIRED": "已過期", "FAILED": "已失敗"}.get(String(option.status), "未開放")
		quest_selector.add_item("委託 %d/%d · %s · %s" % [i + 1, rows.size(), state_label, String(option.title)])
		quest_selector.set_item_metadata(i, String(option.id))
	quest_selector.select(selected_index)
	quest_selector.visible = rows.size() > 1
	var row: Dictionary = rows[selected_index]
	quest_id_shown = String(row.id)
	quest_title.text = "委託 · %s" % String(row.title)
	quest_description.text = String(row.description)
	var status := String(row.status)
	if status == "AVAILABLE":
		quest_progress.text = "期限：接下後 %d 天\n交付：%s ×%d → %s\n目前持有：%d／%d；接受後仍需自行取得物品。\n報酬：%d 瓶蓋、%d XP" % [int(row.deadline_days), String(row.item_name), int(row.required), String(row.target), int(row.held), int(row.required), int(row.reward_caps), int(row.reward_xp)]
		quest_button.text = "接受委託"
	elif status == "ACTIVE":
		quest_progress.text = "進行中 · 第 %d 天截止\n交付：%s ×%d → %s\n目前持有：%d／%d；需自行取得物品後前往交付。\n報酬：%d 瓶蓋、%d XP" % [int(row.deadline_day), String(row.item_name), int(row.required), String(row.target), int(row.held), int(row.required), int(row.reward_caps), int(row.reward_xp)]
		quest_button.text = "交付物品"
	else:
		if status == "RESOLVED":
			quest_progress.text = "已完成 · 已交付 %s ×%d → %s\n獲得：%d 瓶蓋、%d XP" % [String(row.item_name), int(row.required), String(row.target), int(row.reward_caps), int(row.reward_xp)]
		else:
			quest_progress.text = {"EXPIRED": "已過期 · 未交付", "FAILED": "已失敗 · 未交付"}.get(status, "目前不可接")
		quest_button.text = "委託已結束"
	quest_button.visible = status in ["AVAILABLE", "ACTIVE"]
	quest_button.disabled = not bool(row.can_act)
	quest_button.tooltip_text = "需要持有足量物品、抵達交付地點，且仍在期限內。" if status == "ACTIVE" and quest_button.disabled else ""

func _on_quest_access_pressed() -> void:
	quest_journal_open = not quest_journal_open
	desktop_details_open = quest_journal_open
	_render_quests(current_projection.get("quests", []))
	_sync_desktop(current_projection)
	if quest_journal_open:
		quest_close_button.grab_focus()
	else:
		quest_access_button.grab_focus()

func _on_quest_close_pressed() -> void:
	quest_journal_open = false
	desktop_details_open = false
	_render_quests(current_projection.get("quests", []))
	_sync_desktop(current_projection)
	quest_access_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if quest_journal_open and event.is_action_pressed("ui_cancel"):
		_on_quest_close_pressed()
		get_viewport().set_input_as_handled()
	elif desktop_details_window != null and desktop_details_window.visible and event.is_action_pressed("ui_cancel"):
		var player: Dictionary = current_projection.get("player", {})
		if not bool(player.get("is_in_transit", false)) and current_projection.get("active_encounter", {}).is_empty() and current_projection.get("encounter_result", {}).is_empty():
			_show_desktop_scene()
			get_viewport().set_input_as_handled()

func _on_quest_selected(index: int) -> void:
	if quest_selector == null or index < 0 or index >= quest_selector.item_count:
		return
	quest_id_shown = String(quest_selector.get_item_metadata(index))
	_render_quests(current_projection.get("quests", []))

func _on_quest_pressed() -> void:
	if world == null or world.player == null or quest_id_shown == "":
		return
	var rows: Array = current_projection.get("quests", [])
	var row: Dictionary = {}
	for candidate in rows:
		if String(candidate.id) == quest_id_shown:
			row = candidate
			break
	if row.is_empty():
		return
	var accepting := String(row.status) == "AVAILABLE"
	var intent := PlayerIntent.create_accept_quest(world.player.npc_id, quest_id_shown) if accepting else PlayerIntent.create_turn_in_quest(world.player.npc_id, quest_id_shown)
	var result: Dictionary = engine.commit_player_intent(world, intent)
	if not result.success:
		if lbl_action_error != null:
			lbl_action_error.text = "委託狀態已變更，請查看目前位置、持有物品與期限。"
		refresh_ui()
		return
	refresh_ui()
	var receipt := AcceptDialog.new()
	receipt.theme_type_variation = "PdaDialog"
	receipt.title = "委託結果"
	if accepting:
		receipt.dialog_text = "委託已接受。第 %d 天截止。" % world.quest_state.get_quest(quest_id_shown).deadline_day
	else:
		var delivered: Array = result.get("delivered", [])
		var delivered_text := "%s ×%d" % [String(row.item_name), int(row.required)]
		if not delivered.is_empty():
			delivered_text = "%s ×%d" % [String(row.item_name), int(delivered[0].quantity)]
		receipt.dialog_text = "已交付%s。獲得 %d 瓶蓋、%d XP。" % [delivered_text, int(row.reward_caps), int(row.reward_xp)]
	receipt.ok_button_text = "繼續旅程"
	receipt.confirmed.connect(receipt.queue_free)
	receipt.canceled.connect(receipt.queue_free)
	add_child(receipt)
	receipt.popup_centered()

func _show_character() -> void:
	if world == null or world.player == null:
		return
	var presentation = preload("res://ui/character_presentation.gd")
	var dialog = preload("res://ui/components/character_sheet.gd").new()
	var equip_action := func(item_id: String, slot: String):
		var result := engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(item_id), slot))
		if result.get("success", false):
			dialog.queue_free()
			refresh_ui()
			call_deferred("_show_character")
	var unequip_action := func(slot: String):
		var result := engine.commit_player_intent(world, PlayerIntent.create_unequip_item(world.player.npc_id, slot))
		if result.get("success", false):
			dialog.queue_free()
			refresh_ui()
			call_deferred("_show_character")
	add_child(dialog)
	dialog.setup(presentation.project(world), PlayerUIProjection.project(world).player, equip_action, unequip_action)
	var viewport_size := get_viewport_rect().size
	var sheet_size := Vector2i(mini(460, int(viewport_size.x) - 24), mini(560, int(viewport_size.y) - 72))
	var sheet_position := Vector2i(int(viewport_size.x) - sheet_size.x - 12, 56)
	dialog.popup(Rect2i(sheet_position, sheet_size))

func _encounter_blocked_text(option: Dictionary) -> String:
	if bool(option.get("locked", false)):
		return "目前能力未達需求：" + String(option.get("requirement_label", ""))
	var reason := String(option.get("blocked_reason", ""))
	for code in {"INSUFFICIENT_WATER": "水不足", "INSUFFICIENT_FOOD": "食物不足", "INSUFFICIENT_SCRAP": "廢料不足", "INSUFFICIENT_MONEY": "瓶蓋不足", "BACKPACK_FULL": "背包容量不足"}:
		if reason.begins_with(code):
			return {"INSUFFICIENT_WATER": "水不足", "INSUFFICIENT_FOOD": "食物不足", "INSUFFICIENT_SCRAP": "廢料不足", "INSUFFICIENT_MONEY": "瓶蓋不足", "BACKPACK_FULL": "背包容量不足"}[code]
	return "目前無法採取這個做法，請查看需求與消耗。"

func _show_field() -> void:
	if world == null or world.player == null or get_node_or_null("FieldScreen") != null:
		return
	var battle_or_receipt: bool = not world.field_state.battle.is_empty() or world.field_state.receipt >= 0
	if not battle_or_receipt and (field_button == null or field_button.disabled):
		return
	var screen = preload("res://ui/field_screen.gd").new()
	screen.name = "FieldScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	screen.setup(world, engine)
	screen.world_changed.connect(refresh_ui)
	screen.closed.connect(refresh_ui)
