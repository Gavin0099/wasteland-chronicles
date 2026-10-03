extends SceneTree
const Fixture = preload("res://tests/fixtures/gear2c_world.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Well = preload("res://simulation/well_repair.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Market = preload("res://simulation/item_market_catalogue.gd")
const ItemGear = preload("res://simulation/item_gear.gd")
var engine := SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-2D: " + label)

func _init() -> void:
	call_deferred("run")

func buy(world: WorldState, id: String, slot: String = "", quantity: int = 1) -> void:
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), quantity)).success, "purchase " + id)
	if slot != "":
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), slot)).success, "equip " + id)

func turn(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": command, "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)}))

func checked(world: WorldState) -> WorldState:
	var raw: String = world.to_canonical_json()
	var result: Dictionary = WorldState.from_json_checked(raw)
	check(result.success, "checked persistence " + String(result.get("error", "")))
	if not result.success:
		return world
	check(result.world.to_canonical_json() == raw and engine.validate_invariants(result.world) == "", "fixed point and global invariants")
	return result.world

func twin_equal(a: WorldState, b: WorldState) -> void:
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "dual track SHA-256")
	check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants")

func repair(method: String, resume: bool) -> String:
	var world: WorldState = Fixture.repair_site("fieldrepair_precision_kit")
	world.player.capability._data.skill_ranks.MECHANICS = 3
	world.player.inventory.set_amount("scrap", 2)
	check(world.player.pickup_item("precision_repair_kit").success, "tie tool fixture")
	check(Gear.best_tool(world.player, "MECHANICS") == "fieldrepair_precision_kit", "equal grade uses actual discount tool")
	if resume:
		world = checked(world)
	var projection: Dictionary = PlayerUIProjection.project(world)
	var option: Dictionary = {}
	for row: Dictionary in projection.active_encounter.options:
		if row.id == method: option = row
	check(String(option.get("detail", "")).contains("廢料 2") or String(option.get("detail", "")).contains("廢料 −2"), "actual visible discounted cost")
	var before: int = world.get_settlement(&"settlement:dry_well").production.water
	var day: int = world.current_day
	check(Fixture.answer(world, StringName(method)).success, "discounted repair authority")
	var receipt: Dictionary = world.event_log[world.pending_encounter_result].payload
	check(world.current_day == day + 1 and world.player.inventory.scrap == 0 and world.player.item_inventory.contains("fieldrepair_precision_kit"), "actual two scrap one day retained tool")
	check(receipt.equipment_repair.size() == 12 and receipt.equipment_repair.scrap_spent == 2 and receipt.equipment_repair.tool_id == "fieldrepair_precision_kit" and receipt.spent.scrap == 2, "explicit tool receipt")
	check(world.get_settlement(&"settlement:dry_well").production.water == before + (2 if method == "OVERHAUL_PUMP" else 1), "specified method production")
	var raw: String = world.to_canonical_json()
	for fault: String in ["ordinary_tool", "electronic_tool", "missing_tool", "cost", "method", "paired_cost", "paired_tool"]:
		var wire: Dictionary = JSON.parse_string(raw)
		for event: Dictionary in wire.events:
			if event.type == "EQUIPMENT_REPAIRED":
				match fault:
					"ordinary_tool": event.payload.tool_id = "precision_repair_kit"
					"electronic_tool": event.payload.tool_id = "military_electronic_tools"
					"missing_tool": event.payload.erase("tool_id")
					"cost": event.payload.scrap_spent = 3
					"method": event.payload.method = "REWIRE_PUMP"
			if event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.payload.option == method:
				if fault == "paired_cost": event.payload.spent.scrap = 3
				if fault == "paired_tool": event.payload.equipment_repair.tool_id = "precision_repair_kit"
		check(not WorldState.from_json_checked(JSON.stringify(wire)).success, "forged discounted receipt " + fault)
	world = checked(world) if resume else world
	return world.to_canonical_json().sha256_text()

func run() -> void:
	var specs := {
		"quickdraw_police_revolver": [1200, 290, "T2", "quick_draw"],
		"heavyhead_sledgehammer": [3400, 70, "T1", "heavy_head"],
		"balanced_combat_knife": [450, 120, "T2", "balanced"],
		"toolloop_travel_backpack": [1200, 100, "T1", "tool_loops"],
		"waterpouch_travel_backpack": [1250, 95, "T1", "water_pouch"],
		"lightweight_ballistic_vest": [2400, 300, "T3", "lightweight"],
		"plated_leather_jacket": [2400, 210, "T2", "plated"],
		"fieldrepair_precision_kit": [1800, 310, "T3", "field_repair"],
		"precision_repair_toolbox": [2200, 160, "T2", "precision_set"],
		"expedition_travel_backpack": [1400, 150, "T1", "tool_loops"],
	}
	check(Registry.all_definitions().size() == 45, "44 gear identities plus explicit AID-1 bandage")
	for id: String in specs:
		var row: Dictionary = Registry.resolve(id).definition
		check(row.base_weight == specs[id][0] and row.base_value == specs[id][1] and row.tier == specs[id][2], "independent explicit stats " + id)
		check(row.quality == ("RARE" if id == "expedition_travel_backpack" else "MODIFIED") and row.properties == (["tool_loops", "water_pouch"] if id == "expedition_travel_backpack" else [specs[id][3]]), "explicit quality cardinality " + id)
	for town: String in {"gray_valley": 34, "new_hope": 41, "dry_well": 32}:
		check(Market.offers_for(town).offers.size() == {"gray_valley": 34, "new_hope": 41, "dry_well": 32}[town], "specified regional supply plus AID-1 bandage")
	check(ItemGear.validate({"tier": "T1", "quality": "MODIFIED", "properties": ["forged"], "unique_effect": ""}) != "", "unknown effect rejected")
	# First-turn firearm advantage is consumed by the turn, not by firing.
	for first_command: String in ["SHOOT", "DEFEND"]:
		var gun: WorldState = Fixture.fresh("settlement:new_hope")
		buy(gun, "quickdraw_police_revolver", "main_hand")
		buy(gun, "revolver_round", "", 3)
		gun.player.capability._data.skill_ranks.FIREARMS = 1
		Fixture.resupply(gun)
		check(engine.begin_player_travel(gun, PlayerIntent.create_travel(gun.player.npc_id, &"settlement:dry_well")).success, "gun road")
		gun.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, gun.current_day, &"settlement:new_hope", &"settlement:dry_well", 1, {"target_enemy": "heavy_raider"})
		check(Fixture.answer(gun, &"FIGHT").success, "gun fight")
		check(Field.shot_damage(gun) == 10, "quick draw specified first turn 7+1+2")
		var copy: WorldState = checked(gun)
		check(turn(gun, first_command).success and turn(copy, first_command).success, "gun first commands")
		check(Field.shot_damage(gun) == (10 if first_command == "DEFEND" else 8), "turn two only normal or prepared damage")
		if first_command == "SHOOT":
			check(gun.player.item_inventory.quantity("revolver_round") == 2 and gun.field_state.enemy_hp == 6, "actual 10 damage one ammo")
		twin_equal(gun, copy)
	var hammer: WorldState = Fixture.fresh()
	buy(hammer, "heavyhead_sledgehammer", "main_hand")
	Fixture.road_battle(hammer)
	check(Field.attack_damage(hammer) == 6 and Field.flee_damage(hammer) == 2, "heavy base and retreat unchanged")
	var hammer_twin: WorldState = checked(hammer)
	for command: String in ["DEFEND", "DEFEND", "ATTACK"]:
		check(turn(hammer, command).success and turn(hammer_twin, command).success, "heavy prepared commands")
		check(Field.attack_damage(hammer) == (6 if command == "ATTACK" else 9), "heavy extra one; repeated brace never stacks")
		twin_equal(hammer, hammer_twin)
	check(hammer.field_state.enemy_hp == 7, "real heavy hit 6+2+1")
	for command: String in ["ATTACK", "DEFEND", "FLEE"]:
		var knife: WorldState = Fixture.fresh()
		buy(knife, "balanced_combat_knife", "main_hand")
		Fixture.road_battle(knife)
		check(Field.intent_preview(knife).taken == 2 and Field.intent_preview(knife).braced_taken == 0, "balanced preview matches attack/brace")
		var knife_twin: WorldState = checked(knife)
		check(turn(knife, command).success and turn(knife_twin, command).success, "balanced commands")
		check(knife.player.field_kit.hp == 12 - {"ATTACK": 2, "DEFEND": 0, "FLEE": 1}[command], "only ATTACK gains one retaliation reduction")
		twin_equal(knife, knife_twin)
	var floor_case: WorldState = Fixture.fresh()
	buy(floor_case, "balanced_combat_knife", "main_hand")
	buy(floor_case, "leather_jacket", "body")
	floor_case.player.field_kit.hp = 1
	Fixture.road_battle(floor_case, "bandit")
	check(Field.intent_preview(floor_case).taken == 0, "balanced plus armor zero-damage preview at road floor")
	check(turn(floor_case, "ATTACK").success and floor_case.player.field_kit.hp == 1 and not floor_case.field_state.battle.is_empty(), "zero raw damage cannot cause road defeat")
	checked(floor_case)
	for body: String in ["lightweight_ballistic_vest", "plated_leather_jacket"]:
		var armor: WorldState = Fixture.fresh()
		buy(armor, body, "body")
		check(Gear.protection(armor.player) == 3 and armor.player.get_effective_capacity() == (19 if body == "lightweight_ballistic_vest" else 20), "specified modified armor")
		check(Gear.method_refusal(armor.player, "SLIP_PAST").begins_with("ARMOR_") == (body == "lightweight_ballistic_vest"), "lightweight keeps stealth tradeoff")
		Fixture.road_battle(armor)
		var armor_twin: WorldState = checked(armor)
		check(turn(armor, "ATTACK").success and turn(armor_twin, "ATTACK").success and armor.player.field_kit.hp == 12, "modified armor actual protection")
		twin_equal(armor, armor_twin)
	# The prospective tool itself contributes to the bounded exemption.
	for bag: String in ["toolloop_travel_backpack", "expedition_travel_backpack"]:
		var pack: WorldState = Fixture.fresh()
		buy(pack, bag, "back")
		for id: String in ["sledgehammer", "ballistic_vest", "reinforced_saber", "caravan_coat", "desert_robe"]:
			check(pack.player.pickup_item(id).success, "physical capacity fixture " + id)
		check(pack.player.item_inventory.tool_weight_g() == 0, "no tool gives no exemption")
		buy(pack, "repair_toolbox")
		check(pack.player.item_inventory.total_weight_g() == (13600 if bag == "toolloop_travel_backpack" else 13800) and pack.player.item_inventory.capacity_grams(bag) == 14000, "actual 2kg bound and tool purchase")
		check(not pack.player.pickup_item("first_aid_kit").success, "non-tool cannot exceed bounded 14kg")
		check(not ItemInventoryState.from_dict_checked(pack.player.item_inventory.to_dict()).success, "standalone inventory still 12kg")
		var pack_twin: WorldState = checked(pack)
		twin_equal(pack, pack_twin)
		var raw: String = pack.to_canonical_json()
		check(not engine.commit_player_intent(pack, PlayerIntent.create_unequip_item(pack.player.npc_id, "back")).success and pack.to_canonical_json() == raw, "formal overload unequip atomic")
		var wire: Dictionary = JSON.parse_string(raw)
		wire.player.erase("equipment")
		check(not WorldState.from_json_checked(JSON.stringify(wire)).success, "holding unequipped bag cannot load overload")
		wire = JSON.parse_string(raw)
		for entry: Dictionary in wire.player.item_inventory.items:
			if entry.item_id == bag: entry.item_id = "travel_backpack"
		check(not WorldState.from_json_checked(JSON.stringify(wire)).success, "unowned claimed tool-loop bag rejected")
	for bag: String in ["waterpouch_travel_backpack", "expedition_travel_backpack"]:
		var water: WorldState = Fixture.fresh()
		buy(water, bag, "back")
		water.player.inventory.set_amount("water", 0)
		water.player.inventory.set_amount("food", 28)
		var copy: WorldState = checked(water)
		check(engine.commit_player_intent(water, PlayerIntent.create_buy(water.player.npc_id, &"water", 2)).success and engine.commit_player_intent(copy, PlayerIntent.create_buy(copy.player.npc_id, &"water", 2)).success, "water can fill its pouch while main cargo full")
		check(water.player.get_total_inventory_load() == 28 and water.player.inventory.water == 2, "water exemption actual contents")
		twin_equal(water, copy)
		var raw: String = water.to_canonical_json()
		check(not engine.commit_player_intent(water, PlayerIntent.create_buy(water.player.npc_id, &"scrap", 1)).success and water.to_canonical_json() == raw, "water pouch never adds generic cargo")
		check(not engine.commit_player_intent(water, PlayerIntent.create_unequip_item(water.player.npc_id, "back")).success and water.to_canonical_json() == raw, "water overload unequip atomic")
	var tools: WorldState = Fixture.armory("precision_repair_toolbox")
	check(Gear.grade_for("precision_repair_toolbox", "ELECTRONICS") == 0, "mechanical precision set cannot become electronic tool")
	check(Gear.tool_grade(tools.player, "MECHANICS") == 3, "precision set real grade")
	tools.player.capability._data.skill_ranks.MECHANICS = 1
	var before: String = tools.to_canonical_json()
	check(not Fixture.answer(tools, &"OPEN_ARMORY").success and tools.to_canonical_json() == before, "advanced tool cannot grant skill")
	tools.player.capability._data.skill_ranks.MECHANICS = 2
	check(Fixture.answer(tools, &"OPEN_ARMORY").success and tools.player.item_inventory.contains("old_world_saber"), "tool opens existing grade two method")
	checked(tools)
	for method: String in ["REPAIR_PUMP", "OVERHAUL_PUMP"]:
		check(repair(method, false) == repair(method, true), "discount method interrupted replay")
	var delivery: WorldState = Fixture.fresh()
	buy(delivery, "rusted_knife", "main_hand")
	var town: SettlementState = delivery.get_settlement(&"settlement:gray_valley")
	check(town.item_market.remove("rusted_knife", town.item_market.quantity("rusted_knife")).success, "real empty stock creates knife procurement")
	var delivery_job: String = ""
	for entry: Dictionary in JobBoard.postings(delivery, &"settlement:gray_valley"):
		if String(entry.definition.id).contains("item_request_rusted_knife"):
			delivery_job = entry.definition.id
	check(delivery_job != "" and engine.commit_player_intent(delivery, PlayerIntent.create_accept_quest(delivery.player.npc_id, delivery_job)).success, "accept actual knife contract")
	before = delivery.to_canonical_json()
	var denied: Dictionary = engine.commit_player_intent(delivery, PlayerIntent.create_turn_in_quest(delivery.player.npc_id, delivery_job))
	check(not denied.success and String(denied.error) == "ITEM_EQUIPPED" and delivery.to_canonical_json() == before, "equipped item hand-in rejected atomically before stock reward or XP")
	var blocked_row: Dictionary = {}
	for row: Dictionary in PlayerUIProjection.project(delivery).quests:
		if row.id == delivery_job: blocked_row = row
	check(bool(blocked_row.get("equipped_delivery", false)) and not blocked_row.get("can_act", true), "projection explains equipped-delivery refusal")
	var handoff_shell := PlayableShell.new()
	root.add_child(handoff_shell)
	handoff_shell.setup(delivery, engine)
	handoff_shell.quest_id_shown = delivery_job
	handoff_shell._render_quests(PlayerUIProjection.project(delivery).quests)
	check(handoff_shell.quest_button.disabled and handoff_shell.quest_button.text.contains("先卸下") and delivery.to_canonical_json() == before, "rendered handoff button states action without mutating world")
	handoff_shell.free()
	var delivery_twin: WorldState = checked(delivery)
	for track: WorldState in [delivery, delivery_twin]:
		check(engine.commit_player_intent(track, PlayerIntent.create_unequip_item(track.player.npc_id, "main_hand")).success, "explicit unequip before hand-in")
		check(engine.commit_player_intent(track, PlayerIntent.create_turn_in_quest(track.player.npc_id, delivery_job)).success and not track.player.item_inventory.contains("rusted_knife"), "unequipped delivery succeeds")
		engine.tick(track)
		check(engine.validate_invariants(track) == "", "day after delivery does not assert equipment ownership")
	twin_equal(delivery, delivery_twin)
	checked(delivery)
	var elec: WorldState = Fixture.repair_site("fieldrepair_precision_kit")
	elec.player.pickup_item("electronic_repair_kit")
	elec.player.capability._data.skill_ranks.ELECTRONICS = 2
	elec.player.inventory.set_amount("scrap", 2)
	before = elec.to_canonical_json()
	check(Well.material_cost(elec, "REWIRE_PUMP") == 3 and not Fixture.answer(elec, &"REWIRE_PUMP").success and elec.to_canonical_json() == before, "discount cannot subsidize electronic method")
	var low: WorldState = Fixture.repair_site("fieldrepair_precision_kit")
	low.player.capability._data.skill_ranks.MECHANICS = 3
	low.player.inventory.set_amount("scrap", 1)
	before = low.to_canonical_json()
	check(not Fixture.answer(low, &"OVERHAUL_PUMP").success and low.to_canonical_json() == before, "discount still requires two scrap")
	print("GEAR-2D: assertions=%d failures=%d" % [assertions, failures])
	quit(1 if failures else 0)

