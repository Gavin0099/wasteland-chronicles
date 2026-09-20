class_name PlayableShell
extends Control

# ==============================================================================
# S5-A.2: PLAYABLE UI SHELL (FAST LANE)
# ==============================================================================
# Architecture Boundary:
#   WorldState -> PlayerUIProjection -> Godot UI
#
# Rules:
#   1. UI strictly NEVER writes to WorldState directly (UI5 Simulation Isolation).
#   2. Travel button ONLY dispatches PlayerIntent(TRAVEL) and commits it.
#      It does NOT auto-advance days (WAIT is reserved for S5-B1).
#   3. Current settlement displays LIVE data; remote settlements display only
#      basic route availability and distance (preventing Information Leak).
#   4. HUD displays only authoritative player fields (strictly no HP/XP/levels).
#   5. Event Feed is explicitly labeled [DEBUG WORLD FEED].
# ==============================================================================

signal ui_refreshed(projection_data: Dictionary)
signal travel_triggered(destination_id: String, success: bool)
signal wait_triggered(result: Dictionary)
signal trade_triggered(action_name: String, commodity: String, quantity: int, result: Dictionary)

var world: WorldState = null
var engine: SimulationEngine = null
var current_projection: Dictionary = {}
var selected_settlement_id: String = "settlement:gray_valley"
var debug_world_feed_enabled: bool = true

# Node references
var lbl_day: Label
var lbl_player_header: Label
var lbl_hud_location: Label
var lbl_hud_status: Label
var lbl_hud_money: Label
var lbl_hud_backpack: Label
var lbl_hud_commodities: Label
var lbl_settlement_title: Label
var lbl_settlement_details: Label
var market_panel: VBoxContainer
var market_trade_buttons: Dictionary = {}
var btn_wait: Button
var btn_travel: Button
var event_feed_container: VBoxContainer
var map_node_buttons: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(960, 540)

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

	# Pure read-only projection (WorldState -> PlayerUIProjection)
	current_projection = PlayerUIProjection.project(world, debug_world_feed_enabled)
	_render_projection(current_projection)
	ui_refreshed.emit(current_projection)

func _render_projection(proj: Dictionary) -> void:
	if not is_inside_tree() and lbl_day == null:
		return

	var day: int = proj.get("current_day", 0)
	var p: Dictionary = proj.get("player", {})

	# 1. Header Ribbon (Dirty Ivory & Muted Amber)
	if lbl_day != null:
		lbl_day.text = "DAY %d" % day
	if lbl_player_header != null:
		lbl_player_header.text = "%s  |  $%d CAPS" % [p.get("name", "Drifter"), p.get("money", 0)]

	# 2. Player HUD
	if lbl_hud_location != null:
		lbl_hud_location.text = "LOCATION: %s" % p.get("location_display", "Unknown")
	if lbl_hud_status != null:
		lbl_hud_status.text = "STATUS: %s" % p.get("status", "UNKNOWN")
	if lbl_hud_money != null:
		lbl_hud_money.text = "CAPS: $%d" % p.get("money", 0)

	var bp: Dictionary = p.get("backpack", {})
	if lbl_hud_backpack != null:
		lbl_hud_backpack.text = "BACKPACK LOAD: %d / %d" % [bp.get("load", 0), bp.get("capacity", 20)]
	if lbl_hud_commodities != null:
		lbl_hud_commodities.text = "Water: %d  |  Food: %d  |  Scrap: %d  |  Fuel: %d" % [
			bp.get("water", 0), bp.get("food", 0), bp.get("scrap", 0), bp.get("fuel", 0)
		]

	# 3. Map Node Highlights
	var current_cont: String = p.get("current_container_id", "")
	for node_id in map_node_buttons:
		var btn: Button = map_node_buttons[node_id]
		var clean_name: String = node_id.replace("settlement:", "").replace("_", " ").capitalize()
		if node_id == current_cont and not p.get("is_in_transit", false):
			btn.text = "[*] %s (HERE)" % clean_name
		else:
			btn.text = clean_name

	# 4. Settlement Panel (Selected Node)
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

	var clean_title: String = selected_settlement_id.replace("settlement:", "").replace("_", " ").to_upper()

	if is_current:
		# LIVE settlement view (Current location only)
		var cs: Dictionary = proj.get("current_settlement", {})
		lbl_settlement_title.text = "[ %s ] - CURRENT LOCATION (LIVE)" % clean_title
		lbl_settlement_details.text = (
			"Population: %d\n" +
			"Warehouse Stock:\n" +
			"  Water: %d (Price: %.2f)  |  Food: %d (Price: %.2f)\n" +
			"  Scrap: %d (Price: %.2f)  |  Fuel: %d (Price: %.2f)\n" +
			"Security: %.1f / 100.0\n" +
			"Deprivation Pressure: Water %.1f | Food %.1f"
		) % [
			cs.get("population", 0),
			cs.get("water", 0), cs.get("price_water", 0.0),
			cs.get("food", 0), cs.get("price_food", 0.0),
			cs.get("scrap", 0), cs.get("price_scrap", 0.0),
			cs.get("fuel", 0), cs.get("price_fuel", 0.0),
			cs.get("security", 0.0),
			cs.get("water_pressure", 0.0), cs.get("food_pressure", 0.0)
		]
	# Update WAIT button state (S5-B1)
	if btn_wait != null:
		if is_in_transit:
			btn_wait.text = "[CONTINUE — 1 DAY]"
			btn_wait.disabled = false
			btn_wait.visible = true
		elif p.get("status") == "SETTLED":
			btn_wait.text = "[WAIT 1 DAY]"
			btn_wait.disabled = false
			btn_wait.visible = true
		else:
			btn_wait.disabled = true

	if is_current:
		# LIVE settlement view (Current location only)
		var cs: Dictionary = proj.get("current_settlement", {})
		var w_stat: String = cs.get("water_supply_status", "STABLE")
		var f_stat: String = cs.get("food_supply_status", "STABLE")
		var wp_stat: String = cs.get("water_pressure_status", "NORMAL")
		var fp_stat: String = cs.get("food_pressure_status", "NORMAL")

		lbl_settlement_title.text = "[ %s ] - CURRENT LOCATION (LIVE)" % clean_title
		lbl_settlement_details.text = (
			"Population: %d  |  Market Reserve: $%d Caps\n" +
			"Warehouse Stock:\n" +
			"  Water: %d [%s] (Buy: $%d / Sell: $%d)  |  Food: %d [%s] (Buy: $%d / Sell: $%d)\n" +
			"  Scrap: %d (Buy: $%d / Sell: $%d)  |  Fuel: %d (Buy: $%d / Sell: $%d)\n" +
			"Security: %.1f / 100.0\n" +
			"Deprivation Pressure: Water %.1f [%s]  |  Food %.1f [%s]"
		) % [
			cs.get("population", 0), cs.get("market_cash", 500),
			cs.get("water", 0), w_stat, cs.get("quote_buy_water", 0), cs.get("quote_sell_water", 0),
			cs.get("food", 0), f_stat, cs.get("quote_buy_food", 0), cs.get("quote_sell_food", 0),
			cs.get("scrap", 0), cs.get("quote_buy_scrap", 0), cs.get("quote_sell_scrap", 0),
			cs.get("fuel", 0), cs.get("quote_buy_fuel", 0), cs.get("quote_sell_fuel", 0),
			cs.get("security", 0.0),
			cs.get("water_pressure", 0.0), wp_stat,
			cs.get("food_pressure", 0.0), fp_stat
		]

		if market_panel != null:
			market_panel.visible = true
			for res in ["water", "food", "scrap", "fuel"]:
				var buy_q: int = cs.get("quote_buy_" + res, 1)
				var sell_q: int = cs.get("quote_sell_" + res, 1)
				var stock: int = cs.get(res, 0)
				var player_has: int = bp.get(res, 0)
				var player_money: int = p.get("money", 0)
				var bp_load: int = bp.get("load", 0)
				var bp_cap: int = bp.get("capacity", 20)
				var market_cash: int = cs.get("market_cash", 0)

				var stat_tag: String = ""
				if res == "water" and w_stat != "STABLE":
					stat_tag = " [%s]" % w_stat
				elif res == "food" and f_stat != "STABLE":
					stat_tag = " [%s]" % f_stat

				var lbl: Label = market_trade_buttons.get(res + "_label", null)
				if lbl != null:
					lbl.text = "%s: %d%s" % [res.capitalize(), stock, stat_tag]

				var b_buy: Button = market_trade_buttons.get("buy_" + res, null)
				if b_buy != null:
					b_buy.text = "BUY ($%d)" % buy_q
					b_buy.disabled = (stock < 1) or (player_money < buy_q) or (bp_load >= bp_cap)

				var b_sell: Button = market_trade_buttons.get("sell_" + res, null)
				if b_sell != null:
					b_sell.text = "SELL ($%d)" % sell_q
					b_sell.disabled = (player_has < 1) or (market_cash < sell_q)

		if btn_travel != null:
			btn_travel.visible = false
			btn_travel.disabled = true
	else:
		if market_panel != null:
			market_panel.visible = false
		# Remote settlement view (ONLY Route & Distance. NO economic leaks)
		lbl_settlement_title.text = "[ %s ] - REMOTE DESTINATION" % clean_title
		var dest_info: Dictionary = {}
		for d in proj.get("destinations", []):
			if d.get("id") == selected_settlement_id:
				dest_info = d
				break

		var route_days: int = dest_info.get("route_days", 3)

		lbl_settlement_details.text = (
			"Route: Available\n" +
			"Distance: %d days overland\n" +
			"\n" +
			"(Detailed economy obscured by distance — S7 Information Fog)"
		) % [route_days]

		if btn_travel != null:
			btn_travel.visible = true
			if is_in_transit:
				btn_travel.disabled = true
				btn_travel.text = "CANNOT TRAVEL (CURRENTLY IN TRANSIT)"
			else:
				btn_travel.disabled = false
				btn_travel.text = "TRAVEL TO %s (%d DAYS)" % [clean_title, route_days]

func _render_event_feed(events: Array) -> void:
	if event_feed_container == null:
		return

	for child in event_feed_container.get_children():
		event_feed_container.remove_child(child)
		child.queue_free()

	if not debug_world_feed_enabled:
		var disabled_lbl := Label.new()
		disabled_lbl.text = "[Debug world feed disabled]"
		disabled_lbl.add_theme_color_override("font_color", Color("#555960"))
		event_feed_container.add_child(disabled_lbl)
		return

	for evt in events:
		var lbl := Label.new()
		lbl.text = "[Day %02d] %s" % [evt.get("day", 0), evt.get("summary", "")]
		lbl.add_theme_color_override("font_color", Color("#8B949E"))
		event_feed_container.add_child(lbl)

# ==============================================================================
# PLAYER INTERACTION (INTENT CHAIN ONLY - NO DOUBLE-TICK)
# ==============================================================================

func select_settlement(settlement_id: String) -> void:
	selected_settlement_id = settlement_id
	if current_projection.size() > 0:
		_render_settlement_panel(current_projection)

func on_travel_pressed() -> Dictionary:
	if world == null or engine == null or world.player == null:
		return {"success": false, "error": "NO_WORLD_OR_PLAYER"}

	var player_id := world.player.npc_id
	var dest_id := StringName(selected_settlement_id)

	# 1. Construct controlled PlayerIntent (UI5 Simulation Isolation)
	var intent := PlayerIntent.create_travel(player_id, dest_id)

	# 2. Authorize & Commit via canonical engine API
	var commit_res := engine.commit_player_intent(world, intent)
	if not commit_res["success"]:
		travel_triggered.emit(selected_settlement_id, false)
		return commit_res

	# 3. Refresh UI view immediately. DO NOT tick the world!
	# The UI simply records that the player is now IN_TRANSIT.
	# Advancing time via WAIT belongs to S5-B1.
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

# External tick progression (driven by test harness or unified player wait)
func advance_day() -> Dictionary:
	if world != null and world.player != null:
		return on_wait_pressed()
	elif world != null and engine != null:
		engine.tick(world)
		refresh_ui()
		return {"success": true}
	return {"success": false}

# ==============================================================================
# PROGRAMMATIC UI CONSTRUCTION (SURVIVOR PDA THEME)
# ==============================================================================

func _build_ui_layout_if_needed() -> void:
	if lbl_day != null:
		return

	# Substrate: Dark Charcoal #121316
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 6)
	add_child(main_vbox)

	# --- HEADER RIBBON ---
	var header_panel := PanelContainer.new()
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 20)
	header_panel.add_child(header_hbox)
	main_vbox.add_child(header_panel)

	lbl_day = Label.new()
	lbl_day.text = "DAY 0"
	lbl_day.add_theme_color_override("font_color", Color("#D9822B")) # Muted amber
	header_hbox.add_child(lbl_day)

	var title_lbl := Label.new()
	title_lbl.text = "WASTELAND CHRONICLES — SURVIVOR PDA"
	title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color("#D8D3C8")) # Dirty ivory
	header_hbox.add_child(title_lbl)

	lbl_player_header = Label.new()
	lbl_player_header.text = "Vagrant | $50 CAPS"
	lbl_player_header.add_theme_color_override("font_color", Color("#D9822B")) # Muted amber
	header_hbox.add_child(lbl_player_header)

	# --- MIDDLE SPLIT (MAP vs SETTLEMENT) ---
	var mid_split := HBoxContainer.new()
	mid_split.size_flags_vertical = SIZE_EXPAND_FILL
	mid_split.add_theme_constant_override("separation", 8)
	main_vbox.add_child(mid_split)

	# Left: Map Panel
	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var map_vbox := VBoxContainer.new()
	map_vbox.add_theme_constant_override("separation", 8)
	map_panel.add_child(map_vbox)
	mid_split.add_child(map_panel)

	var map_title := Label.new()
	map_title.text = "--- [ SECTOR MAP ] ---"
	map_title.add_theme_color_override("font_color", Color("#D9822B"))
	map_vbox.add_child(map_title)

	var nodes_box := VBoxContainer.new()
	nodes_box.size_flags_vertical = SIZE_EXPAND_FILL
	nodes_box.add_theme_constant_override("separation", 6)
	map_vbox.add_child(nodes_box)

	var settlement_ids := [
		"settlement:gray_valley",
		"settlement:dry_well",
		"settlement:new_hope"
	]
	for s_id in settlement_ids:
		var btn := Button.new()
		btn.text = s_id.replace("settlement:", "").replace("_", " ").capitalize()
		btn.pressed.connect(func(): select_settlement(s_id))
		nodes_box.add_child(btn)
		map_node_buttons[s_id] = btn

	# Right: Settlement Panel
	var settlement_panel := PanelContainer.new()
	settlement_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var settlement_vbox := VBoxContainer.new()
	settlement_vbox.add_theme_constant_override("separation", 8)
	settlement_panel.add_child(settlement_vbox)
	mid_split.add_child(settlement_panel)

	lbl_settlement_title = Label.new()
	lbl_settlement_title.text = "[ SETTLEMENT PANEL ]"
	lbl_settlement_title.add_theme_color_override("font_color", Color("#D9822B"))
	settlement_vbox.add_child(lbl_settlement_title)

	lbl_settlement_details = Label.new()
	lbl_settlement_details.text = "Select a settlement on the map to inspect."
	lbl_settlement_details.size_flags_vertical = SIZE_EXPAND_FILL
	lbl_settlement_details.add_theme_color_override("font_color", Color("#D8D3C8"))
	settlement_vbox.add_child(lbl_settlement_details)

	# Market Panel (Trading Rows)
	market_panel = VBoxContainer.new()
	market_panel.add_theme_constant_override("separation", 4)
	settlement_vbox.add_child(market_panel)

	var market_hdr := Label.new()
	market_hdr.text = "--- [ LOCAL MARKET ] ---"
	market_hdr.add_theme_color_override("font_color", Color("#D9822B"))
	market_panel.add_child(market_hdr)

	for res in ["water", "food", "scrap", "fuel"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var row_lbl := Label.new()
		row_lbl.text = "%s: 0" % res.capitalize()
		row_lbl.custom_minimum_size = Vector2(160, 0)
		row_lbl.add_theme_color_override("font_color", Color("#D8D3C8"))
		row.add_child(row_lbl)
		market_trade_buttons[res + "_label"] = row_lbl

		var btn_buy := Button.new()
		btn_buy.text = "BUY 1"
		btn_buy.custom_minimum_size = Vector2(90, 28)
		var comm_for_buy: String = String(res)
		btn_buy.pressed.connect(func(): on_buy_pressed(comm_for_buy, 1))
		row.add_child(btn_buy)
		market_trade_buttons["buy_" + res] = btn_buy

		var btn_sell := Button.new()
		btn_sell.text = "SELL 1"
		btn_sell.custom_minimum_size = Vector2(90, 28)
		var comm_for_sell: String = String(res)
		btn_sell.pressed.connect(func(): on_sell_pressed(comm_for_sell, 1))
		row.add_child(btn_sell)
		market_trade_buttons["sell_" + res] = btn_sell

		market_panel.add_child(row)

	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 8)
	settlement_vbox.add_child(action_hbox)

	btn_wait = Button.new()
	btn_wait.text = "[WAIT 1 DAY]"
	btn_wait.custom_minimum_size = Vector2(0, 36)
	btn_wait.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_wait.pressed.connect(func(): on_wait_pressed())
	action_hbox.add_child(btn_wait)

	btn_travel = Button.new()
	btn_travel.text = "TRAVEL"
	btn_travel.custom_minimum_size = Vector2(0, 36)
	btn_travel.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_travel.pressed.connect(func(): on_travel_pressed())
	action_hbox.add_child(btn_travel)

	# --- BOTTOM SPLIT (HUD vs DEBUG WORLD FEED) ---
	var bot_split := HBoxContainer.new()
	bot_split.custom_minimum_size = Vector2(0, 130)
	bot_split.add_theme_constant_override("separation", 8)
	main_vbox.add_child(bot_split)

	# Bottom Left: Player HUD
	var hud_panel := PanelContainer.new()
	hud_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var hud_vbox := VBoxContainer.new()
	hud_vbox.add_theme_constant_override("separation", 4)
	hud_panel.add_child(hud_vbox)
	bot_split.add_child(hud_panel)

	var hud_title := Label.new()
	hud_title.text = "--- [ PLAYER HUD ] ---"
	hud_title.add_theme_color_override("font_color", Color("#D8D3C8"))
	hud_vbox.add_child(hud_title)

	lbl_hud_location = Label.new()
	lbl_hud_location.text = "LOCATION: ..."
	lbl_hud_location.add_theme_color_override("font_color", Color("#D8D3C8"))
	hud_vbox.add_child(lbl_hud_location)

	lbl_hud_status = Label.new()
	lbl_hud_status.text = "STATUS: ..."
	lbl_hud_status.add_theme_color_override("font_color", Color("#D8D3C8"))
	hud_vbox.add_child(lbl_hud_status)

	lbl_hud_money = Label.new()
	lbl_hud_money.text = "CAPS: $0"
	lbl_hud_money.add_theme_color_override("font_color", Color("#D9822B"))
	hud_vbox.add_child(lbl_hud_money)

	lbl_hud_backpack = Label.new()
	lbl_hud_backpack.text = "BACKPACK LOAD: 0 / 20"
	lbl_hud_backpack.add_theme_color_override("font_color", Color("#D8D3C8"))
	hud_vbox.add_child(lbl_hud_backpack)

	lbl_hud_commodities = Label.new()
	lbl_hud_commodities.text = "Water: 0 | Food: 0 | Scrap: 0 | Fuel: 0"
	lbl_hud_commodities.add_theme_color_override("font_color", Color("#8B949E"))
	hud_vbox.add_child(lbl_hud_commodities)

	# Bottom Right: Debug World Feed
	var feed_panel := PanelContainer.new()
	feed_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var feed_vbox := VBoxContainer.new()
	feed_vbox.add_theme_constant_override("separation", 4)
	feed_panel.add_child(feed_vbox)
	bot_split.add_child(feed_panel)

	var feed_title := Label.new()
	feed_title.text = "--- [ DEBUG WORLD FEED ] ---"
	feed_title.add_theme_color_override("font_color", Color("#8B949E"))
	feed_vbox.add_child(feed_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	event_feed_container = VBoxContainer.new()
	event_feed_container.add_theme_constant_override("separation", 2)
	scroll.add_child(event_feed_container)
	feed_vbox.add_child(scroll)
