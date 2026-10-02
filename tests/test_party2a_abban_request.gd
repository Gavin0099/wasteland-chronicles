extends SceneTree

const Party = preload("res://simulation/party.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")
var engine := SimulationEngine.new()
var failures := 0
var assertions := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PARTY-2A: " + label)

func stock(world: WorldState) -> void:
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)

func fresh() -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:gray_valley", "character_name": "同行者", "age": 28, "background_id": "SCAVENGER", "trait_ids": []})).success, "create character")
	world.player.money = 500
	stock(world)
	return world

func hire(world: WorldState) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, Party.ABBAN))

func gift(world: WorldState) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id))

func finish(world: WorldState, stop_at_request: bool = false) -> void:
	for step in range(24):
		if world.pending_encounter_result >= 0:
			check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success, "continue journey")
			continue
		if world.active_encounter == null:
			return
		if stop_at_request and world.active_encounter.context.get("companion_request", false):
			return
		var option: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: option = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: option = &"DETOUR"
			TravelEncounter.ROADBLOCK: option = &"PAY"
			TravelEncounter.PLACE_VISIT:
				if world.active_encounter.context.get("companion_request", false): option = &"RECOVER_ABBAN_TOOL"
		check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option)).success, "pass encounter")
	check(false, "journey terminates")

func journey(world: WorldState, target: StringName) -> void:
	stock(world)
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, target)).success, "begin actual journey")
	finish(world)
	check(world.npc_life_state_registry.get_life_state(world.player.npc_id).population_container_id == target, "actually arrive")
	check(engine.validate_invariants(world) == "", "global invariants after travel")

func checkpoint(world: WorldState, reload_world: bool) -> WorldState:
	var checked := WorldState.from_json_checked(world.to_canonical_json())
	check(checked.success, "checked save loads: %s" % checked.get("error", ""))
	if not checked.success:
		return world
	check(checked.world.to_canonical_json() == world.to_canonical_json(), "byte-identical checkpoint")
	check(engine.validate_invariants(checked.world) == "", "global invariants after load")
	return checked.world if reload_world else world

func reject(world: WorldState, intent: PlayerIntent, expected: String) -> void:
	var before := world.to_canonical_json().sha256_text()
	var result := engine.commit_player_intent(world, intent)
	check(not result.success and String(result.error).begins_with(expected), "reject " + expected + ": " + str(result))
	check(before == world.to_canonical_json().sha256_text(), "rejection is atomic")

func loop(reload_world: bool) -> WorldState:
	var world := fresh()
	check(hire(world).fee == 50, "first contract costs 50")
	check(Party.personal_state(world).shared.is_empty(), "hiring does not invent shared history")
	check(engine.commit_player_intent(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT")).success, "accept personal detour")
	world = checkpoint(world, reload_world)
	journey(world, &"settlement:new_hope")
	var shared: Dictionary = Party.personal_state(world).shared
	check(shared.place_id == "place:convoy_wreck", "shared experience is actual recovery at named wreck")
	check(Party.personal_note(world).contains("商隊殘骸"), "shared story names the personal destination")
	world = checkpoint(world, reload_world)
	var money := world.player.money
	var day := world.current_day
	check(gift(world).success, "fulfil personal request in town")
	check(world.player.item_inventory.quantity("wrench") == 0, "one actual wrench leaves the pack")
	check(world.player.money == money and world.current_day == day, "gift creates no money or extra day")
	check(Party.hire_fee(world, Party.ABBAN) == 25, "future Abban hire costs 25")
	check(Party.hire_fee(world, "companion:tieniu") == 60 and Party.hire_fee(world, "companion:shahu") == 50, "other companions unchanged")
	check(Party.skill_rank(world, "MECHANICS") == 2, "existing companion skill unchanged")
	check(Party.personal_note(world).contains("原價 50"), "persistent benefit explained")
	reject(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "COMPANION_REQUEST_ALREADY_DONE")
	world = checkpoint(world, reload_world)
	check(engine.commit_player_intent(world, PlayerIntent.create_dismiss_companion(world.player.npc_id)).success, "dismiss in town")
	check(Party.hire_fee(world, Party.ABBAN) == 25, "dismissal preserves benefit")
	journey(world, &"settlement:gray_valley")
	check(world.player.item_inventory.quantity("wrench") == 0, "return route never respawns recovered tool")
	check(Party.personal_state(world).shared == shared, "later solo journey does not replace first memory")
	world.player.money = 24
	reject(world, PlayerIntent.create_hire_companion(world.player.npc_id, Party.ABBAN), "INSUFFICIENT_FUNDS")
	world.player.money = 25
	check(hire(world).success and world.player.money == 0, "rehire uses actual 25-cap price")
	check(int(world.event_log.back().payload.fee) == 25, "joined receipt records actual reduced fee")
	return checkpoint(world, reload_world)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var continuous := loop(false)
	var resumed := loop(true)
	var hash := continuous.to_canonical_json().sha256_text()
	check(hash == resumed.to_canonical_json().sha256_text(), "dual-track SHA-256")
	var world := fresh()
	reject(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "ABBAN_NOT_WITH_YOU")
	reject(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT"), "ABBAN_NOT_WITH_YOU")
	check(hire(world).success, "hire for rejection fixtures")
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"wrench", 1)).success, "buy ordinary tool")
	reject(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "RECOVER_TOOL_FIRST")
	world.player.item_inventory.remove_item("wrench", 1)
	check(engine.commit_player_intent(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "DEFER")).success, "may defer")
	check(Party.personal_state(world).status == "DEFERRED" and Party.hire_fee(world, Party.ABBAN) == 50, "deferral gives no benefit")
	reject(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "invent"), "INVALID_COMPANION_REQUEST_RESPONSE")
	var refused := checkpoint(world, true)
	check(engine.commit_player_intent(refused, PlayerIntent.create_respond_companion_request(refused.player.npc_id, "REFUSE")).success, "may refuse after deferring")
	check(Party.current(refused) == Party.ABBAN and Party.skill_rank(refused, "MECHANICS") == 2, "refusing preserves ordinary companionship")
	reject(refused, PlayerIntent.create_respond_companion_request(refused.player.npc_id, "ACCEPT"), "COMPANION_REQUEST_ALREADY_ANSWERED")
	refused = checkpoint(refused, true)
	check(Party.personal_state(refused).status == "REFUSED", "refusal persists")
	reject(world, PlayerIntent.create_fulfill_companion_request(&"npc:stranger"), "INVALID_PLAYER_ID")
	reject(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "RECOVER_TOOL_FIRST")
	check(engine.commit_player_intent(world, PlayerIntent.create_wait(world.player.npc_id)).success, "wait in town")
	check(Party.personal_state(world).shared.is_empty(), "waiting is not a shared journey")
	var malformed := PlayerIntent.create_fulfill_companion_request(world.player.npc_id)
	malformed.payload = {"item_id": "scrap"}
	reject(world, malformed, "INVALID_COMPANION_REQUEST_INTENT")
	var pending := checkpoint(world, true)
	pending.pending_encounter_result = 0
	reject(pending, PlayerIntent.create_fulfill_companion_request(pending.player.npc_id), "ENCOUNTER_RESULT_PENDING")
	var dead := checkpoint(world, true)
	dead.npc_life_state_registry.get_life_state(dead.player.npc_id).status = NpcLifeState.Status.DEAD
	reject(dead, PlayerIntent.create_fulfill_companion_request(dead.player.npc_id), "DECEASED_OR_NO_LIFE_STATE")
	check(engine.commit_player_intent(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT")).success, "accept before road guards")
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success, "begin for road guard")
	reject(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "REQUEST_REQUIRES_SETTLEMENT")
	engine.advance_player_travel(world, world.player.npc_id, 8)
	finish(world)
	check(Party.current(world) == Party.ABBAN, "Abban survives normal trip")
	reject(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT"), "COMPANION_REQUEST_ALREADY_ANSWERED")
	world.player.item_inventory.remove_item("wrench", 1)
	reject(world, PlayerIntent.create_fulfill_companion_request(world.player.npc_id), "WRENCH_REQUIRED")
	var hungry := fresh()
	check(hire(hungry).success, "hire before hunger")
	hungry.player.inventory.set_amount("food", 1)
	check(engine.begin_player_travel(hungry, PlayerIntent.create_travel(hungry.player.npc_id, &"settlement:dry_well")).success, "hungry departure")
	engine.tick(hungry)
	check(Party.current(hungry) == "", "hunger causes actual departure")
	stock(hungry)
	engine.advance_player_travel(hungry, hungry.player.npc_id, 8)
	finish(hungry)
	check(Party.personal_state(hungry).shared.is_empty(), "leaving before arrival does not count")
	check(engine.validate_invariants(hungry) == "", "hunger journey preserves invariants")
	var site := fresh()
	check(hire(site).success, "hire for site guard")
	check(engine.commit_player_intent(site, PlayerIntent.create_respond_companion_request(site.player.npc_id, "ACCEPT")).success, "accept for site guard")
	check(engine.commit_player_intent(site, PlayerIntent.create_travel(site.player.npc_id, &"settlement:new_hope")).success, "travel for site guard")
	finish(site, true)
	check(site.active_encounter.context.place_id == "place:convoy_wreck", "actual request site reached")
	var wrong_site := checkpoint(site, true)
	wrong_site.active_encounter.context.place_id = "place:fuel_station"
	reject(wrong_site, PlayerIntent.create_resolve_encounter(wrong_site.player.npc_id, &"RECOVER_ABBAN_TOOL"), "INVALID_OPTION")
	site.player.item_inventory.pickup_item("wrench", 1)
	reject(site, PlayerIntent.create_resolve_encounter(site.player.npc_id, &"RECOVER_ABBAN_TOOL"), "WRENCH_ALREADY_CARRIED")
	site.player.item_inventory.remove_item("wrench", 1)
	var day_before := site.current_day
	check(engine.commit_player_intent(site, PlayerIntent.create_resolve_encounter(site.player.npc_id, &"RECOVER_ABBAN_TOOL")).success, "recover tool at actual site")
	check(site.current_day == day_before + 1 and site.player.item_inventory.quantity("wrench") == 1, "recovery costs one real day and grants one tool")
	site = checkpoint(site, true)
	reject(site, PlayerIntent.create_resolve_encounter(site.player.npc_id, &"RECOVER_ABBAN_TOOL"), "ENCOUNTER_RESULT_PENDING")
	# Malformed historical receipts must fail checked load, not merely hide UI.
	var source: Dictionary = continuous.to_dict()
	check(WorldState.from_json_checked(JSON.stringify(source, "\t", true)).success, "unmodified serialized fixture passes")
	var receipt_index := -1
	for index in range(source.events.size()):
		if source.events[index].type == "COMPANION_REQUEST_COMPLETED":
			receipt_index = index
	check(receipt_index >= 0, "gift has persisted receipt")
	for field in ["quantity", "fee_after", "recovery_index", "item_id", "settlement_id", "companion_id"]:
		var bad := source.duplicate(true)
		bad.events[receipt_index].payload[field] = "invalid"
		var checked := WorldState.from_json_checked(JSON.stringify(bad, "\t", true))
		check(not checked.success and String(checked.error) == "INVALID_COMPANION_REQUEST_RECEIPT", "domain rejects malformed " + field + ": " + str(checked.get("error")))
	var duplicate := source.duplicate(true)
	duplicate.events.append(duplicate.events[receipt_index].duplicate(true))
	duplicate.event_count = duplicate.events.size()
	check(WorldState.from_json_checked(JSON.stringify(duplicate, "\t", true)).get("error") == "INVALID_COMPANION_REQUEST_RECEIPT", "domain rejects duplicate gift history")
	var no_shared := source.duplicate(true)
	var arrival_index := int(source.events[receipt_index].payload.recovery_index)
	no_shared.events[arrival_index].payload.option = "LEAVE"
	check(WorldState.from_json_checked(JSON.stringify(no_shared, "\t", true)).get("error") == "INVALID_COMPANION_REQUEST_RECEIPT", "domain rejects gift without shared arrival")
	# Visible action exercises the same authority path as the engine fixtures.
	var shown := fresh()
	check(hire(shown).success, "hire for UI")
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(shown, engine)
	shell._show_training()
	await process_frame
	check(shell.companion_buttons.has("ACCEPT") and shell.companion_buttons.has("DEFER") and shell.companion_buttons.has("REFUSE"), "three visible request choices")
	shell.companion_buttons.ACCEPT.pressed.emit()
	for frame in range(4): await process_frame
	check(Party.personal_state(shown).status == "ACCEPTED", "UI accept commits request")
	for child in shell.get_children():
		if child is AcceptDialog:
			child.hide()
			child.queue_free()
	journey(shown, &"settlement:new_hope")
	shell._show_training()
	await process_frame
	check(shell.companion_buttons.has("request") and not shell.companion_buttons.request.disabled, "request button enabled after actual shared trip")
	shell.companion_buttons.request.pressed.emit()
	for frame in range(4):
		await process_frame
	check(Party.personal_state(shown).tool_given and shown.player.item_inventory.quantity("wrench") == 0, "UI action transfers real tool")
	check(not shell.companion_buttons.has("request"), "fulfilled request is not offered twice")
	shell.queue_free()
	await process_frame
	print("PARTY-2A: assertions=%d failures=%d SHA256=%s" % [assertions, failures, hash])
	quit(0 if failures == 0 else 1)
