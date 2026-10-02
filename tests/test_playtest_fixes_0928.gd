extends SceneTree

# ==============================================================================
# HAND-PLAY FIXES, 2026-09-28
# ==============================================================================
# Each gate is one thing the owner hit while playing:
#
#   D  "明明就有資源 但是不能交付" / "打完獵犬任務也沒有通過" - the work was
#      done, the player stood in the wrong town, and nothing said so. The
#      button now names where to hand it in.
#   W  (found while reproducing D) after a road fight the rest of the trip was
#      walked with [繼續前進 1 天] and never met the road or reported places;
#      confirming the fight now resumes the journey itself.
#   R  "打輸後跑到這邊" - confirming a road fight left the player on the Gray
#      Valley shed screen with every command refused.
#   O  "這個說明很怪" - a "這一回合" heading over a description of the enemy.
#   M  "下方的物品太短 導致很難找東西" - trading moves into its own window with
#      category tabs and one aligned row per thing.
# ==============================================================================

const Board = preload("res://simulation/job_board.gd")
const RoadPlaces = preload("res://simulation/road_places.gd")
const FieldScreen = preload("res://ui/field_screen.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("FIXES-0928: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(origin: String = "settlement:gray_valley") -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "Tester",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 4)
	world.player.inventory.set_amount("food", 4)
	world.player.money = 200
	return world

func shell_for(world: WorldState) -> PlayableShell:
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.setup(world, engine)
	return shell

func show_quest(shell: PlayableShell, world: WorldState, quest_id: String) -> void:
	shell.quest_id_shown = quest_id
	shell._render_quests(PlayerUIProjection.project(world).quests)

func run() -> void:
	# ---- D: say where to hand it in ----
	var cw := fresh_world()
	var consign := ""
	for entry in Board.postings(cw, &"settlement:gray_valley"):
		if entry.archetype == "CONSIGNMENT":
			consign = String(entry.definition.id)
	check(engine.commit_player_intent(cw, PlayerIntent.create_accept_quest(cw.player.npc_id, consign)).success, "D: take a consignment in Gray Valley")
	var cs := shell_for(cw)
	await process_frame
	show_quest(cs, cw, consign)
	check(cs.quest_button.text.begins_with("到") and cs.quest_button.text.ends_with("才能交貨"), "D: the button says where to deliver: %s" % cs.quest_button.text)
	check(cs.quest_button.disabled, "D: and cannot be pressed here")
	cs.queue_free()

	var bw := fresh_world()
	var bounty := ""
	for entry in Board.postings(bw, &"settlement:gray_valley"):
		if entry.archetype == "BOUNTY":
			bounty = String(entry.definition.id)
	engine.commit_player_intent(bw, PlayerIntent.create_accept_quest(bw.player.npc_id, bounty))
	engine.commit_player_intent(bw, PlayerIntent.create_travel(bw.player.npc_id, &"settlement:dry_well"))
	var guard := 0
	while guard < 30:
		guard += 1
		if bw.active_encounter != null:
			var t := bw.active_encounter.encounter_type
			var opt := &"FIGHT" if t == TravelEncounter.BANDIT_AMBUSH else &"LEAVE"
			if t == TravelEncounter.ROCKSLIDE: opt = &"DETOUR"
			if t == TravelEncounter.ROADBLOCK: opt = &"PAY"
			engine.commit_player_intent(bw, PlayerIntent.create_resolve_encounter(bw.player.npc_id, opt))
		elif not bw.field_state.battle.is_empty():
			engine.commit_player_intent(bw, PlayerIntent.create_field_action(bw.player.npc_id, {"command": "ATTACK", "battle_id": bw.field_state.battle.id, "turn": bw.field_state.battle.turn}))
		elif bw.field_state.receipt >= 0:
			engine.commit_player_intent(bw, PlayerIntent.create_field_action(bw.player.npc_id, {"command": "CONFIRM", "receipt": bw.field_state.receipt}))
		elif bw.pending_encounter_result >= 0:
			engine.commit_player_intent(bw, PlayerIntent.create_continue_journey(bw.player.npc_id, bw.pending_encounter_result))
		elif bw.npc_life_state_registry.get_life_state(bw.player.npc_id).status == NpcLifeState.Status.IN_TRANSIT:
			engine.commit_player_intent(bw, PlayerIntent.create_wait(bw.player.npc_id))
		else:
			break
	check(preload("res://simulation/quest_engine.gd").evaluate_objectives(bw, bounty), "D: the dog was beaten")
	var bs := shell_for(bw)
	await process_frame
	show_quest(bs, bw, bounty)
	check(bs.quest_button.text == "回灰谷領賞", "D: away from Gray Valley the button says to go back: %s" % bs.quest_button.text)
	check(bs.quest_progress.text.contains("回灰谷領賞"), "D: and so does the progress line")
	bs.queue_free()

	# ---- W: after a road fight the journey resumes, and meets the road ----
	var ww := fresh_world()
	check(engine.begin_player_travel(ww, PlayerIntent.create_travel(ww.player.npc_id, &"settlement:new_hope")).success, "W: set out for New Hope")
	engine.tick(ww)
	ww.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, ww.current_day, &"settlement:gray_valley", &"settlement:new_hope", 1, {"target_enemy": "feral_dog"})
	engine.commit_player_intent(ww, PlayerIntent.create_resolve_encounter(ww.player.npc_id, &"FIGHT"))
	ww.player.capability._data.skill_ranks["MELEE"] = 5
	while not ww.field_state.battle.is_empty():
		engine.commit_player_intent(ww, PlayerIntent.create_field_action(ww.player.npc_id, {"command": "ATTACK", "battle_id": ww.field_state.battle.id, "turn": ww.field_state.battle.turn}))
	var resumed := engine.commit_player_intent(ww, PlayerIntent.create_field_action(ww.player.npc_id, {"command": "CONFIRM", "receipt": ww.field_state.receipt}))
	check(resumed.success and bool(resumed.get("resumed_journey", false)), "W: confirming the fight resumes the journey")
	check(ww.active_encounter != null and String(ww.active_encounter.context.get("place_id", "")) == "place:convoy_wreck", "W: and the road goes on - the convoy wreck on day two is met")

	# ---- R: a confirmed road fight goes back to the road ----
	var road := fresh_world()
	engine.begin_player_travel(road, PlayerIntent.create_travel(road.player.npc_id, &"settlement:dry_well"))
	road.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, road.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1, {"target_enemy": "feral_dog"})
	engine.commit_player_intent(road, PlayerIntent.create_resolve_encounter(road.player.npc_id, &"FIGHT"))
	road.player.field_kit.hp = 1
	var screen = FieldScreen.new()
	root.add_child(screen)
	screen.setup(road, engine)
	await process_frame
	screen.perform({"command": "ATTACK", "battle_id": road.field_state.battle.id, "turn": road.field_state.battle.turn})
	var waited := 0
	while screen.busy and waited < 600:
		waited += 1
		await process_frame
	check(road.field_state.battle.is_empty() and road.field_state.receipt >= 0, "R: the fight ended")
	check(not screen.busy, "R: the blow has finished playing")
	var closed := [false]
	screen.closed.connect(func(): closed[0] = true)
	screen.perform({"command": "CONFIRM", "receipt": road.field_state.receipt})
	await process_frame
	check(closed[0], "R: confirming the road result closes the battle screen")
	var after_status := road.npc_life_state_registry.get_life_state(road.player.npc_id).status
	check(after_status == NpcLifeState.Status.IN_TRANSIT or road.npc_life_state_registry.get_life_state(road.player.npc_id).population_container_id == &"settlement:dry_well", "R: and the journey carries on")

	# ---- O: the side panel says what it is ----
	var shed := fresh_world()
	var o = FieldScreen.new()
	root.add_child(o)
	o.setup(shed, engine)
	await process_frame
	check(o.turn_window.title_label.text == "對手" and o.battle_map_label.text.begins_with("野犬："), "O: outside a turn the panel is about the opponent")
	o.perform({"command": "START"})
	for i in range(5):
		await process_frame
	check(o.turn_window.title_label.text == "這一回合", "O: during a turn it is about this turn")
	o.queue_free()

	# ---- M: the trade window ----
	var mw := fresh_world()
	var ms := shell_for(mw)
	await process_frame
	ms._show_local_market()
	await process_frame
	var market = ms.market_window
	check(market != null and market.visible, "M: 本地市場 opens the trade window")
	var keys: Array = []
	for e in market.visible_entries():
		keys.append(String(e.key))
	check(keys.has("water") and keys.has("scrap_machete"), "M: supplies and gear are in one list")
	check(not keys.has("military_backpack") and not keys.has("old_world_saber"), "M: what this town does not sell is not listed")
	market.tab_buttons["WEAPON"].pressed.emit()
	var weapons := true
	for e in market.visible_entries():
		weapons = weapons and String(e.tab) == "WEAPON"
	check(weapons and not market.visible_entries().is_empty(), "M: the weapons tab shows weapons only")
	market.tab_buttons["SUPPLY"].pressed.emit()
	await process_frame
	# Pick, then act: select water, step to five, buy.
	market.row_buttons["water"].pressed.emit()
	check(market.selected_key == "water", "M: a row click selects it")
	for i in range(4):
		market.plus_button.pressed.emit()
	check(market.quantity == 5 and market.buy_button.text.contains("買入 5"), "M: the stepper sets the amount and the button says it: %s" % market.buy_button.text)
	var price := int(PlayerUIProjection.project(mw).current_settlement.quote_buy_water)
	var money0 := mw.player.money
	var water0 := mw.player.inventory.get_amount("water")
	market.buy_button.pressed.emit()
	check(mw.player.inventory.get_amount("water") == water0 + 5 and money0 - mw.player.money == price * 5, "M: 買入 5 buys five at the quoted price")
	check(market.notice_label.visible and market.notice_label.text.contains("買入"), "M: the trade is confirmed in words")
	mw.player.money = 0
	ms.refresh_ui()
	market.refresh()
	market._trade("food", false, true, 1)
	check(market.notice_label.visible and market.notice_label.text.contains("瓶蓋不夠"), "M: a refused trade says why: %s" % market.notice_label.text)
	# ECON-1 replaces the temporary acceptance-triggered shortage with real stock.
	mw.player.money = 500
	for entry in Board.postings(mw, &"settlement:gray_valley"):
		if entry.archetype == "SALVAGE":
			check(engine.commit_player_intent(mw, PlayerIntent.create_accept_quest(mw.player.npc_id, String(entry.definition.id))).success, "M: take Gray Valley's salvage job")
	var town: SettlementState = mw.get_settlement(&"settlement:gray_valley")
	check(not Board.wanted_items(mw, town.id).has("rope"), "M: accepting a recovery order does not empty the shop")
	town.item_market = ItemMarketState.seeded_for(town.id)
	town.item_market.set_quantity("rope", 0)
	var refused: Dictionary = engine.commit_player_intent(mw, PlayerIntent.create_buy_item(mw.player.npc_id, &"rope", 1))
	check(not refused.success and String(refused.error).begins_with("INSUFFICIENT_ITEM_STOCK"), "M: real zero stock prevents purchase")
	ms.refresh_ui()
	market.refresh()
	var row: Dictionary = market.entry("rope")
	check(not row.is_empty() and bool(row.wanted) and int(row.stock) == 0, "M: market shows actual shortage")
	ms.queue_free()

	print("FIXES-0928: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
