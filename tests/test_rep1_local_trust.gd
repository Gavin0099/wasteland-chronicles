extends SceneTree

# ==============================================================================
# REP-1: LOCAL TRUST + BETRAYAL
# ==============================================================================
# Owner ruling: per-town trust, not a world reputation or a good/evil meter.
# Only once towns remember can a contract be broken, and the break has to cost
# something the world keeps: short-term gain against long-term life.
#
#   T1 Every town starts as a stranger
#   T2 Consignment: a producing town posts its own goods to carry to a
#      neighbour that needs them
#   T3 Taking it moves the goods out of the town's stores into your pack, and
#      is refused if you cannot carry them
#   T4 Delivering pays, lands the goods in the destination's stores, and the
#      issuing town trusts you more
#   T5 Keeping them: the goods are yours, the job fails, and that town turns -
#      no work from it, its goods cost 25% more, other towns do not care
#   T6 "For a while": after the memory period the door opens again, scarred
#   T7 A town that knows you pays more for its own work
#   T8 The player sees it: the betray button, the trust line; saves round-trip
# ==============================================================================

const LocalTrust = preload("res://simulation/local_trust.gd")
const Board = preload("res://simulation/job_board.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("REP-1: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(origin: String) -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "Carrier",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 4)
	world.player.inventory.set_amount("food", 4)
	return world

func consignment_at(world: WorldState, settlement_id: String) -> Dictionary:
	for entry in Board.postings(world, StringName(settlement_id)):
		if entry.archetype == "CONSIGNMENT":
			return entry
	return {}

func walk_to(world: WorldState, destination: String) -> void:
	engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, StringName(destination)))
	var guard := 0
	while guard < 12:
		guard += 1
		if world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
			continue
		if world.active_encounter == null:
			return
		var choice := &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice))

func run() -> void:
	# ---- T1 strangers ----
	var world := fresh_world("settlement:new_hope")
	for town in LocalTrust.TOWNS:
		check(LocalTrust.tier(world, town) == LocalTrust.STRANGER, "T1: %s starts as a stranger" % town)

	# ---- T2 consignment ----
	var posting := consignment_at(world, "settlement:new_hope")
	check(not posting.is_empty(), "T2: New Hope posts a consignment")
	var defn: Dictionary = posting.definition
	var resource := String(defn.consign_resource)
	var quantity := int(defn.consign_quantity)
	var nh: SettlementState = world.get_settlement(&"settlement:new_hope")
	check(nh.production.get_amount(resource) > nh.consumption.get_amount(resource), "T2: it ships something New Hope produces (%s)" % resource)
	var dest_id := "settlement:" + String(defn.consign_to)
	check(dest_id != "settlement:new_hope" and String(defn.objectives[0].settlement_id) == String(defn.consign_to), "T2: to another town, where it is delivered")
	check(String(defn.description_zh).contains("私吞"), "T2: the contract says the goods could be kept")
	check(Definition_ok(defn), "T2: the contract validates")

	# ---- T3 taking it ----
	var job_id := String(defn.id)
	var cramped := fresh_world("settlement:new_hope")
	cramped.player.inventory.set_amount("water", 10)
	cramped.player.inventory.set_amount("food", 10)
	var refused := engine.commit_player_intent(cramped, PlayerIntent.create_accept_quest(cramped.player.npc_id, job_id))
	check(not refused.success and String(refused.error).contains("CONSIGNMENT_NO_ROOM"), "T3: refused with no room to carry it: %s" % refused.get("error", ""))
	var town_before := nh.inventory.get_amount(resource)
	var pack_before := world.player.inventory.get_amount(resource)
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, job_id)).success, "T3: accept")
	check(nh.inventory.get_amount(resource) == town_before - quantity, "T3: the goods left New Hope's stores")
	check(world.player.inventory.get_amount(resource) == pack_before + quantity, "T3: and are in your pack")
	var accepted: EventRecord = null
	for event in world.event_log:
		if event.type == "QUEST_ACCEPTED" and String(event.payload.quest_id) == job_id:
			accepted = event
	check(accepted != null and int(accepted.payload.get("consigned", {}).get("quantity", 0)) == quantity, "T3: the receipt says what was handed over")

	# ---- T4 delivering ----
	var honest := world.duplicate_state()
	walk_to(honest, dest_id)
	honest.player.inventory.set_amount(resource, maxi(quantity, honest.player.inventory.get_amount(resource)))
	var dest: SettlementState = honest.get_settlement(StringName(dest_id))
	var dest_before := dest.inventory.get_amount(resource)
	var delivered := engine.commit_player_intent(honest, PlayerIntent.create_turn_in_quest(honest.player.npc_id, job_id))
	check(delivered.success, "T4: delivered at %s" % dest_id)
	check(dest.inventory.get_amount(resource) == dest_before + quantity, "T4: the goods are in the destination's stores")
	check(LocalTrust.score(honest, "settlement:new_hope") == LocalTrust.DELIVERED, "T4: New Hope trusts you more (%d)" % LocalTrust.score(honest, "settlement:new_hope"))
	check(LocalTrust.score(honest, dest_id) == 0, "T4: the receiving town is not the one that trusted you")

	# ---- T5 keeping them ----
	var thief := world.duplicate_state()
	var kept := engine.commit_player_intent(thief, PlayerIntent.create_betray_job(thief.player.npc_id, job_id))
	check(kept.success, "T5: betrayal commits")
	check(thief.player.inventory.get_amount(resource) == pack_before + quantity, "T5: the goods are still yours")
	check(String(thief.quest_state.get_quest(job_id).status) == "FAILED", "T5: the job fails")
	check(not engine.commit_player_intent(thief, PlayerIntent.create_betray_job(thief.player.npc_id, job_id)).success, "T5: cannot be betrayed twice")
	check(LocalTrust.tier(thief, "settlement:new_hope") == LocalTrust.UNWELCOME, "T5: New Hope turns on you")
	for town in LocalTrust.TOWNS:
		if town != "settlement:new_hope":
			check(LocalTrust.tier(thief, town) == LocalTrust.STRANGER, "T5: %s does not care" % town)
	var next_window := thief.duplicate_state()
	while Board.window_for_day(next_window.current_day) == Board.window_for_day(thief.current_day):
		engine.tick(next_window)
	var any_job := ""
	for entry in Board.postings(next_window, &"settlement:new_hope"):
		any_job = String(entry.definition.id)
	var shut := engine.commit_player_intent(next_window, PlayerIntent.create_accept_quest(next_window.player.npc_id, any_job))
	check(not shut.success and String(shut.error).contains("TOWN_DISTRUSTS_YOU"), "T5: New Hope gives you no work: %s" % shut.get("error", ""))
	var nh_t: SettlementState = thief.get_settlement(&"settlement:new_hope")
	var plain := SimulationEngine.get_buy_quote(nh_t, &"water")
	var marked := SimulationEngine.get_buy_quote(nh_t, &"water", LocalTrust.buy_markup(thief, "settlement:new_hope"))
	check(marked == int(ceil(nh_t.get_current_price("water") * LocalTrust.UNWELCOME_MARKUP)) and marked > plain, "T5: New Hope's water costs you more (%d vs %d)" % [marked, plain])
	var proj_quote := int(PlayerUIProjection.project(thief).get("current_settlement", {}).get("quote_buy_water", -1))
	thief.player.money = 500
	var money_before := thief.player.money
	check(engine.commit_player_intent(thief, PlayerIntent.create_buy(thief.player.npc_id, &"water", 1)).success, "T5: you can still buy, at a price")
	check(money_before - thief.player.money == marked, "T5: and the engine charges the marked-up price")
	check(proj_quote == marked, "T5: the market screen shows the same price the engine charges")

	# ---- T6 for a while ----
	var later := thief.duplicate_state()
	for day in range(LocalTrust.BETRAYAL_MEMORY_DAYS + 1):
		engine.tick(later)
	check(LocalTrust.tier(later, "settlement:new_hope") == LocalTrust.STRANGER, "T6: after %d days New Hope will deal with you again" % LocalTrust.BETRAYAL_MEMORY_DAYS)
	check(LocalTrust.score(later, "settlement:new_hope") == LocalTrust.BETRAYED_SCAR, "T6: but it has not forgotten (%d)" % LocalTrust.score(later, "settlement:new_hope"))

	# ---- T7 a town that knows you pays more ----
	var known := fresh_world("settlement:gray_valley")
	for i in range(2):
		known.record_event(EventRecord.new(known.current_day, "PLACE_REPORTED", known.player.npc_id, &"settlement:gray_valley",
			{"place_id": "place:old_well", "settlement_id": "settlement:gray_valley"}))
	check(LocalTrust.tier(known, "settlement:gray_valley") == LocalTrust.REGULAR, "T7: two reports make you a regular in Gray Valley")
	var stranger := fresh_world("settlement:gray_valley")
	var pay_known := 0
	var pay_stranger := 0
	for entry in Board.postings(known, &"settlement:gray_valley"):
		if entry.archetype == "SALVAGE":
			pay_known = int(entry.definition.outcomes.resolved.rewards[0].amount)
	for entry in Board.postings(stranger, &"settlement:gray_valley"):
		if entry.archetype == "SALVAGE":
			pay_stranger = int(entry.definition.outcomes.resolved.rewards[0].amount)
	check(pay_known == int(round(pay_stranger * 1.1)) and pay_known > pay_stranger, "T7: Gray Valley pays its regular 10%% more (%d vs %d)" % [pay_known, pay_stranger])

	# ---- T8 the player sees it ----
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	await process_frame
	var row := {}
	for candidate in PlayerUIProjection.project(world).quests:
		if String(candidate.id) == job_id:
			row = candidate
	check(bool(row.get("can_betray", false)) and bool(row.get("is_consignment", false)), "T8: an active consignment offers the betrayal")
	shell.quest_id_shown = job_id
	shell._render_quests(PlayerUIProjection.project(world).quests)
	check(shell.quest_betray_button != null and shell.quest_betray_button.visible, "T8: the 私吞貨物 button is shown")
	shell.queue_free()
	var thief_shell := PlayableShell.new()
	root.add_child(thief_shell)
	thief_shell.setup(thief, engine)
	await process_frame
	check(thief_shell.lbl_local_hint.text.contains("不受歡迎"), "T8: the town panel says New Hope wants nothing to do with you: %s" % thief_shell.lbl_local_hint.text)
	thief_shell.queue_free()
	for saved in [honest, thief]:
		var loaded := WorldState.from_json_checked(saved.to_canonical_json())
		check(loaded.success, "T8: loads: %s" % String(loaded.get("error", "")))
		if loaded.success:
			check(loaded.world.to_canonical_json() == saved.to_canonical_json(), "T8: byte-identical")
			check(LocalTrust.tier(loaded.world, "settlement:new_hope") == LocalTrust.tier(saved, "settlement:new_hope"), "T8: trust survives the save")

	print("REP-1 local trust: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)

func Definition_ok(defn: Dictionary) -> bool:
	return preload("res://simulation/quest_definition.gd").validate_definition(defn) == ""
