extends "res://tests/test_two_towns.gd"

const Trust = preload("res://simulation/local_trust.gd")
const Training = preload("res://simulation/training.gd")
const Party = preload("res://simulation/party.gd")
const Drawer = preload("res://ui/components/faction_window.gd")

func work_at(world: WorldState, town: String, kind: String) -> Dictionary:
	for entry: Dictionary in Board.postings(world, StringName(town)):
		if entry.archetype == kind: return entry
	return {}

func cash(definition: Dictionary) -> int:
	for reward: Dictionary in definition.outcomes.resolved.rewards:
		if reward.type == "CURRENCY": return int(reward.amount)
	return 0

func prepare_delivery(world: WorldState, twin: WorldState, entry: Dictionary) -> void:
	# Owned delivery materials are explicit fixtures, not fabricated trust receipts.
	var objective: Dictionary = entry.definition.objectives[0]
	if objective.type == "DELIVER_ITEM":
		for state: WorldState in [world, twin]:
			check(state.player.item_inventory.pickup_item(String(objective.item_id), int(objective.quantity)).success, "owned work part fixture")
	else:
		for state: WorldState in [world, twin]:
			state.player.inventory.set_amount(String(objective.resource), maxi(int(objective.quantity), state.player.inventory.get_amount(String(objective.resource))))
	parity(world, twin, "material fixture")

func deliver_pair(world: WorldState, twin: WorldState, entry: Dictionary) -> void:
	check(not entry.is_empty(), "actual posting exists")
	if entry.is_empty(): return
	prepare_delivery(world, twin, entry)
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id), "accept actual faction work")
	var promise: Dictionary = world.accepted_jobs[entry.definition.id].duplicate(true)
	var before: int = world.player.money
	pair_intent(world, twin, PlayerIntent.create_turn_in_quest(world.player.npc_id, entry.definition.id), "fulfil actual faction work")
	check(world.player.money == before + cash(promise), "actual payout equals immutable accepted promise")
	var original: String = world.to_canonical_json()
	check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, entry.definition.id)).success and world.to_canonical_json() == original, "duplicate faction payout refuses atomically")

func wait_pair(world: WorldState, twin: WorldState, days: int) -> void:
	for day: int in range(days):
		pair_intent(world, twin, PlayerIntent.create_wait(world.player.npc_id), "real wait/decay day")

func positive_standing() -> void:
	var world: WorldState = fresh_towns("settlement:new_hope")
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	# Five actual salvage deliveries in distinct three-day posting windows.
	for index: int in range(5):
		if index > 0: wait_pair(world, twin, 3)
		deliver_pair(world, twin, work_at(world, "settlement:new_hope", "SALVAGE"))
		check(Trust.faction_score(world, "oasis") == 2 * (index + 1), "only committed issuer deliveries contribute")
		check(Trust.score(world, "settlement:spring_ford") == 0, "peer local history stays zero")
		if index == 0:
			check(Trust.faction_tier(world, "oasis") == Trust.FACTION_WATCH and Trust.reward_multiplier(world, "spring_ford") == 1.0, "below4 no shared bonus")
		if index == 1:
			check(Trust.faction_tier(world, "oasis") == Trust.FACTION_COOPERATE and Trust.reward_multiplier(world, "spring_ford") == 1.05, "at4 peer earns5percent")
			check(Trust.reward_multiplier(world, "new_hope") == 1.1, "local10 wins without multiplying by shared5")
			# Authored non-urgent Spring salvage fixture:50 caps, cooperative round53.
			check(cash(work_at(world, "settlement:spring_ford", "SALVAGE").definition) == 53, "actual future peer offer pays53")
	check(Trust.faction_tier(world, "oasis") == Trust.FACTION_ALLY and Trust.reward_multiplier(world, "spring_ford") == 1.1, "at10 shared ally bonus10")
	check(Trust.reward_multiplier(world, "new_hope") == 1.2, "local20 wins without compounding")
	check(Trust.reward_multiplier(world, "iron_pass") == 1.0 and Trust.faction_score(world, "forge") == 0, "other faction remains neutral")
	walk_pair(world, twin, "settlement:spring_ford")
	var entry: Dictionary = work_at(world, "settlement:spring_ford", "SALVAGE")
	check(cash(entry.definition) == 55, "actual ally offer pays55 on authored50 fixture")
	var xp_before: int = world.player.xp
	var normal_xp: int = 0
	for reward: Dictionary in entry.definition.outcomes.resolved.rewards:
		if reward.type == "XP": normal_xp = int(reward.amount)
	deliver_pair(world, twin, entry)
	check(world.player.xp == xp_before + normal_xp and normal_xp == 5, "faction does not multiply normal5XP")
	check(Trust.score(world, "settlement:spring_ford") == 2 and Trust.faction_score(world, "oasis") == 12, "peer delivery is counted exactly once")

func accepted_pay() -> void:
	var world: WorldState = fresh_towns("settlement:spring_ford")
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	var entry: Dictionary = work_at(world, "settlement:spring_ford", "SALVAGE")
	check(cash(entry.definition) == 50, "neutral authored pay50")
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id), "accept before shared improvement")
	walk_pair(world, twin, "settlement:new_hope")
	deliver_pair(world, twin, work_at(world, "settlement:new_hope", "SALVAGE"))
	deliver_pair(world, twin, work_at(world, "settlement:new_hope", "COURIER"))
	check(Trust.faction_score(world, "oasis") == 4, "two actual different jobs reach cooperation")
	walk_pair(world, twin, "settlement:spring_ford")
	check(cash(world.accepted_jobs[entry.definition.id]) == 50, "accepted pay preserved despite improved standing")
	prepare_delivery(world, twin, entry)
	var money: int = world.player.money
	pair_intent(world, twin, PlayerIntent.create_turn_in_quest(world.player.npc_id, entry.definition.id), "deliver original accepted contract")
	check(world.player.money == money + 50, "actual original contract pays50")

func betray_pair(world: WorldState, twin: WorldState, town: String) -> int:
	var entry: Dictionary = work_at(world, town, "CONSIGNMENT")
	check(not entry.is_empty(), "actual producing town has consignment")
	if entry.is_empty(): return -1
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id), "accept actual entrusted cargo")
	var resource: String = entry.definition.consign_resource
	var kept: int = world.player.inventory.get_amount(resource)
	var day: int = world.current_day
	pair_intent(world, twin, PlayerIntent.create_betray_job(world.player.npc_id, entry.definition.id), "keep actual entrusted cargo")
	check(world.player.inventory.get_amount(resource) == kept and world.quest_state.get_quest(entry.definition.id).status == "FAILED", "betrayal keeps physical cargo and fails contract")
	return day

func refusal_pair(world: WorldState, twin: WorldState, intent: PlayerIntent, reason: String) -> void:
	var before: String = world.to_canonical_json()
	for state: WorldState in [world, twin]:
		var result: Dictionary = engine.commit_player_intent(state, intent)
		check(not result.success and String(result.error).contains(reason), "actual authority refusal " + reason)
	check(world.to_canonical_json() == before and twin.to_canonical_json() == before, "refusal is byte-atomic in both tracks")
	parity(world, twin, "refused action")

func resistance() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	world.player.money = 500 # Funded fixture so trust, not funds, decides services.
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	var promised: Dictionary = work_at(world, "settlement:gray_valley", "SALVAGE")
	prepare_delivery(world, twin, promised)
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, promised.definition.id), "accept peer work before boycott")
	var agreed: int = cash(world.accepted_jobs[promised.definition.id])
	walk_pair(world, twin, "settlement:iron_pass")
	var betrayed_on: int = betray_pair(world, twin, "settlement:iron_pass")
	check(Trust.faction_score(world, "forge") == -10 and Trust.faction_tier(world, "forge") == Trust.FACTION_RESIST, "actual betrayal causes regional resistance")
	check(Trust.score(world, "settlement:gray_valley") == 0 and not Trust.gives_work(world, "gray_valley"), "neutral peer shares service refusal")
	check(Trust.buy_markup(world, "iron_pass") == 1.25 and Trust.buy_markup(world, "gray_valley") == 1.15, "local25 and peer15 do not compound")
	check(Trust.gives_work(world, "new_hope") and Trust.gives_work(world, "dry_well") and Trust.buy_markup(world, "new_hope") == 1.0, "other factions retain access and prices")
	walk_pair(world, twin, "settlement:gray_valley") # Travel remains possible.
	var offered: Dictionary = work_at(world, "settlement:gray_valley", "COURIER")
	refusal_pair(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, offered.definition.id), "TOWN_DISTRUSTS_YOU")
	refusal_pair(world, twin, PlayerIntent.create_train_skill(world.player.npc_id, "ELECTRONICS"), "TOWN_DISTRUSTS_YOU")
	refusal_pair(world, twin, PlayerIntent.create_hire_companion(world.player.npc_id, "companion:abban"), "TOWN_DISTRUSTS_YOU")
	var town: SettlementState = world.get_settlement(&"settlement:gray_valley")
	var quote: int = int(ceil(town.get_current_price("water") * 1.15))
	check(UiProjection.project(world, false).current_settlement.quote_buy_water == quote, "visible peer quote matches independent15percent rule")
	var money: int = world.player.money
	var water: int = world.player.inventory.water
	pair_intent(world, twin, PlayerIntent.create_buy(world.player.npc_id, &"water", 1), "actual marked-up resource purchase still allowed")
	check(world.player.money == money - quote and world.player.inventory.water == water + 1, "real marked caps debit and owned resource")
	var item_market: RefCounted = town.item_market if town.item_market != null else ItemMarketState.seeded_for(town.id)
	var item_quote: int = int(ceil(float(ItemMarketState.buy_quote("rusted_knife", town.id, item_market)) * 1.15))
	money = world.player.money
	var stock: int = item_market.quantity("rusted_knife")
	pair_intent(world, twin, PlayerIntent.create_buy_item(world.player.npc_id, &"rusted_knife", 1), "actual marked-up item purchase still allowed")
	check(world.player.money == money - item_quote and town.item_market.quantity("rusted_knife") == stock - 1, "item authority uses marked quote and stock")
	money = world.player.money
	pair_intent(world, twin, PlayerIntent.create_turn_in_quest(world.player.npc_id, promised.definition.id), "pre-boycott contract remains deliverable")
	check(world.player.money == money + agreed, "boycott does not rewrite accepted reward")
	check(Trust.score(world, "gray_valley") == 2 and Trust.faction_score(world, "forge") == -8 and Trust.gives_work(world, "gray_valley"), "honest peer delivery can move shared score above resistance")
	# Isolate natural decay with a separate actual betrayal and no offsetting delivery.
	world = fresh_towns("settlement:iron_pass")
	twin = WorldState.from_json_checked(world.to_canonical_json()).world
	betrayed_on = betray_pair(world, twin, "settlement:iron_pass")
	wait_pair(world, twin, 19)
	check(world.current_day == betrayed_on + 19 and Trust.faction_score(world, "forge") == -10 and not Trust.gives_work(world, "gray_valley"), "day19 resistance still applies")
	wait_pair(world, twin, 1)
	check(world.current_day == betrayed_on + 20 and Trust.faction_score(world, "forge") == -3 and Trust.gives_work(world, "gray_valley") and Trust.buy_markup(world, "gray_valley") == 1.0, "day20 real receipts decay/reopen peer without reset")

func abandonment_and_legacy() -> void:
	var world: WorldState = fresh_towns("settlement:iron_pass")
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	var entry: Dictionary = work_at(world, "settlement:iron_pass", "CONSIGNMENT")
	pair_intent(world, twin, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id), "accept consignment expiry boundary")
	var deadline: int = world.quest_state.get_quest(entry.definition.id).deadline_day
	wait_pair(world, twin, deadline - world.current_day + 1)
	check(world.quest_state.get_quest(entry.definition.id).status == "EXPIRED" and Trust.faction_score(world, "forge") == -5, "real expiry contributes5 not betrayal10")
	check(Trust.gives_work(world, "gray_valley") and Trust.buy_markup(world, "gray_valley") == 1.0 and not Trust.gives_work(world, "iron_pass"), "shared -5 leaves peer neutral; original local cutoff preserved")
	wait_pair(world, twin, 20)
	check(Trust.faction_score(world, "forge") == -2, "expiry scar at20 days")
	world = S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:new_hope", "character_name": "舊旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "actual legacy creation")
	world.player.inventory.set_amount("water", 4)
	world.player.inventory.set_amount("food", 4)
	twin = WorldState.from_json_checked(world.to_canonical_json()).world
	betray_pair(world, twin, "settlement:new_hope")
	check(Trust.faction_score(world, "oasis") == -10 and Trust.buy_markup(world, "new_hope") == 1.25 and not Trust.gives_work(world, "new_hope"), "one-member legacy behavior unchanged")
	check(Trust.gives_work(world, "gray_valley") and Trust.buy_markup(world, "gray_valley") == 1.0 and Trust.reward_multiplier(world, "dry_well") == 1.0, "legacy other towns remain independent")
	var projected: Array = UiProjection.project(world, false).factions
	for faction: Dictionary in projected:
		check(faction.members.size() == 1, "absent new towns never appear in legacy projection")
	check(Trust.faction_score(null, "oasis") == 0 and Trust.faction_score(world, "unknown") == 0 and Trust.reward_multiplier(world, "unknown") == 1.0, "null/unknown faction and unknown town safe neutral")
	world.settlements.erase(&"settlement:new_hope") # Query-only absent-member fixture.
	check(Trust.faction_score(world, "oasis") == 0, "absent receipt issuer contributes nothing")

func ui_boundaries() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var twin: WorldState = WorldState.from_json_checked(world.to_canonical_json()).world
	var before: String = world.to_canonical_json()
	var projection: Dictionary = UiProjection.project(world, false)
	check(projection.factions.size() == 3, "three real faction rows")
	for faction: Dictionary in projection.factions:
		check(not faction.has("stock") and not faction.has("price") and faction.standing == "觀望", "only public history/standing, no remote economic values")
	var shell: PlayableShell = Shell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	# Exercise the actual toolbar connection, not only the private opener.
	var toolbar: Button = find_button(shell, "陣營")
	check(toolbar != null, "visible faction toolbar entry")
	if toolbar != null: toolbar.pressed.emit()
	await process_frame
	check(is_instance_valid(shell.faction_window) and shell.faction_window.visible and shell.faction_window.title == "陣營往來", "toolbar opens actual projected dialog")
	check(shell.faction_window.get_ok_button().has_focus(), "keyboard starts on visible close command")
	check(shell.lbl_local_hint.text.contains("熔爐協約"), "current town shows affiliation status")
	shell.faction_window.confirmed.emit()
	await process_frame
	check(not is_instance_valid(shell.faction_window) and world.to_canonical_json() == before, "confirm-close spends no time or state")
	shell._show_factions()
	await process_frame
	shell.faction_window.canceled.emit()
	await process_frame
	check(not is_instance_valid(shell.faction_window), "cancel/Esc path closes")
	parity(world, twin, "opening/closing faction PDA is read-only")
	shell.queue_free()
	await process_frame
	var empty: AcceptDialog = Drawer.new()
	root.add_child(empty)
	empty.setup([])
	empty.queue_free()
	await process_frame

func find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child: Node in node.get_children():
		var result: Button = find_button(child, text)
		if result != null: return result
	return null

func run() -> void:
	positive_standing()
	accepted_pay()
	resistance()
	abandonment_and_legacy()
	await ui_boundaries()
	print("Shared factions: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
