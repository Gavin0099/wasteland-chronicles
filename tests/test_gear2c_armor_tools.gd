extends SceneTree

const Fixture = preload("res://tests/fixtures/gear2c_world.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Well = preload("res://simulation/well_repair.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Catalogue = preload("res://simulation/item_catalogue.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-2C: " + label)

func _init() -> void:
	call_deferred("run")

func buy(world: WorldState, id: String, slot: String = "") -> void:
	check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, StringName(id), 1)).success, "actual purchase " + id)
	if slot != "":
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), slot)).success, "actual equip " + id)

func turn(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": command, "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)}))

func checked(world: WorldState) -> WorldState:
	var raw: String = world.to_canonical_json()
	var loaded: Dictionary = WorldState.from_json_checked(raw)
	check(loaded.success, "checked save " + String(loaded.get("error", "")))
	if not loaded.success:
		return world
	check(loaded.world.to_canonical_json() == raw and engine.validate_invariants(loaded.world) == "", "save fixed point and global invariants")
	return loaded.world

func repair(method: String, tool: String, skill: String, rank: int, bonus: int, resume: bool) -> String:
	var world: WorldState = Fixture.repair_site(tool)
	world.player.capability._data.skill_ranks[skill] = rank
	if resume:
		world = checked(world)
	var before: int = world.get_settlement(&"settlement:dry_well").production.water
	var day: int = world.current_day
	check(Fixture.answer(world, StringName(method)).success, "commit method " + method)
	check(world.current_day == day + 1 and world.player.inventory.scrap == 0 and world.player.item_inventory.contains(tool), "actual day, scrap and retained tool")
	check(world.get_settlement(&"settlement:dry_well").production.water == before + bonus and Well.state(world).status == "WORKING", "specified production and state")
	var receipt: Dictionary = world.event_log[world.pending_encounter_result].payload
	check(receipt.skill_practice.skill_id == skill and receipt.equipment_repair.production_after == before + bonus, "method practice and real effect receipt")
	check(receipt.equipment_repair.size() == (10 if method == "REPAIR_PUMP" else 11), "legacy or extended receipt")
	var raw: String = world.to_canonical_json()
	var projected: Dictionary = PlayerUIProjection.project(world)
	check(String(projected.encounter_result.place_note).contains("故障 → 運轉") and world.to_canonical_json() == raw, "actual production projection is read-only")
	var shell: PlayableShell = PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	check(shell.lbl_encounter_body.text.begins_with(String(projected.encounter_result.place_note)), "rendered result leads with production effect")
	shell.free()
	check(not Fixture.answer(world, StringName(method)).success and world.to_canonical_json() == raw, "duplicate method atomic")
	world = checked(world) if resume else world
	for fault: String in ["effect", "method", "paired_method", "cost"]:
		var wire: Dictionary = JSON.parse_string(raw)
		for event: Dictionary in wire.events:
			if event.type == "EQUIPMENT_REPAIRED":
				if fault == "effect": event.payload.production_after += 1
				if fault == "method": event.payload["method"] = "FORGED"
				if fault == "cost": event.payload.scrap_spent = 2
			if fault == "paired_method" and event.type == "TRAVEL_ENCOUNTER_RESOLVED" and event.payload.option == method:
				event.payload.option = "REWIRE_PUMP" if method != "REWIRE_PUMP" else "OVERHAUL_PUMP"
		check(not WorldState.from_json_checked(JSON.stringify(wire)).success, "reject forged " + fault)
	Fixture.finish(world)
	Fixture.resupply(world)
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well")).success, "return to owner")
	Fixture.finish(world)
	var money: int = world.player.money
	check(engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, Well.state(world).quest_id)).success and world.player.money == money + 80, "same real contract paid once")
	check(engine.validate_invariants(world) == "", "repair final invariants")
	return world.to_canonical_json().sha256_text()

func run() -> void:
	check(Registry.all_definitions().size() == 45 and Catalogue.all_definitions().size() == 45, "44 gear identities plus AID-1 bandage remain consistent")
	# Caller mutations and rejected candidates cannot install a catalogue.
	var detached: Array = Registry.all_definitions()
	var original_properties: Array = detached[0].properties.duplicate()
	detached[0].properties.append("forged")
	check(Registry.resolve(String(detached[0].item_id)).definition.properties == original_properties, "rich cache deeply detached")
	var candidate: Array = Catalogue.all_definitions()
	candidate[0].asset_id = "forged"
	check(not Catalogue.canonicalize(candidate).success and Catalogue.resolve(String(candidate[0].item_id)).success, "candidate validation does not poison canonical cache")
	for id: String in {"thick_cloth_coat": 0, "leather_jacket": 1, "reinforced_leather_jacket": 2, "ballistic_vest": 3}:
		var p: int = int({"thick_cloth_coat": 0, "leather_jacket": 1, "reinforced_leather_jacket": 2, "ballistic_vest": 3}[id])
		for command: String in ["ATTACK", "DEFEND"]:
			var world: WorldState = Fixture.fresh()
			buy(world, id, "body")
			check(Gear.protection(world.player) == p and world.player.get_effective_capacity() == (17 if id == "ballistic_vest" else 20), "specified protection and capacity")
			Fixture.road_battle(world)
			var twin: WorldState = checked(world)
			var preview: Dictionary = Field.intent_preview(world)
			var expected: int = maxi(0, (0 if command == "DEFEND" else 3) - p)
			check(preview.get("braced_taken" if command == "DEFEND" else "taken") == expected, "forecast specified armor/brace order")
			check(turn(world, command).success and turn(twin, command).success, "commit both armor tracks")
			check(world.player.field_kit.hp == 12 - expected and world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "actual armor effect and replay")
			check(engine.validate_invariants(world) == "", "armor global invariants")
		var low: WorldState = Fixture.fresh()
		buy(low, id, "body")
		low.player.field_kit.hp = 1
		Fixture.road_battle(low, "bandit")
		check(turn(low, "DEFEND").success and not low.field_state.battle.is_empty(), "1 HP zero-damage brace remains active")
	var capacity: WorldState = Fixture.fresh()
	buy(capacity, "ballistic_vest")
	capacity.player.inventory.set_amount("water", 18)
	capacity.player.inventory.set_amount("food", 0)
	var before: String = capacity.to_canonical_json()
	check(not engine.commit_player_intent(capacity, PlayerIntent.create_equip_item(capacity.player.npc_id, &"ballistic_vest", "body")).success and capacity.to_canonical_json() == before, "armor capacity reduction atomic")
	# Reviewed heavy-blow fixture: turn 3 is 9 damage, or 2 after bracing.
	for armor: String in ["thick_cloth_coat", "ballistic_vest"]:
		for command: String in ["ATTACK", "DEFEND"]:
			var heavy: WorldState = Fixture.fresh()
			buy(heavy, armor, "body")
			Fixture.road_battle(heavy)
			heavy.field_state.battle.turn = 3
			var expected: int = {"thick_cloth_coat": {"ATTACK": 9, "DEFEND": 2}, "ballistic_vest": {"ATTACK": 6, "DEFEND": 0}}[armor][command]
			check(Field.intent_preview(heavy).get("taken" if command == "ATTACK" else "braced_taken") == expected, "heavy blow armor and brace preview")
			check(turn(heavy, command).success and heavy.player.field_kit.hp == 12 - expected, "specified heavy blow actual damage")
			check(engine.validate_invariants(checked(heavy)) == "", "heavy blow persistence and invariants")
	for pack: String in ["travel_backpack", "reinforced_travel_backpack"]:
		var world: WorldState = Fixture.fresh()
		buy(world, pack, "back")
		check(world.player.get_effective_capacity() == (30 if pack == "reinforced_travel_backpack" else 28), "specified bag cargo")
		world.player.field_kit.hp = 2
		Fixture.resupply(world)
		Fixture.road_battle(world, "bandit")
		var twin: WorldState = checked(world)
		check(turn(world, "ATTACK").success and turn(twin, "ATTACK").success, "defeat both tracks")
		check(world.player.inventory.water == (7 if pack == "reinforced_travel_backpack" else 6) and world.field_state.battle.is_empty(), "real bag defeat loss")
		check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "defeat bag replay")
	var stealth: WorldState = Fixture.fresh()
	buy(stealth, "ballistic_vest", "body")
	stealth.player.capability._data.skill_ranks.STEALTH = 3
	check(engine.begin_player_travel(stealth, PlayerIntent.create_travel(stealth.player.npc_id, &"settlement:dry_well")).success, "roadblock travel")
	stealth.active_encounter = TravelEncounterState.create(TravelEncounter.ROADBLOCK, stealth.current_day, &"settlement:gray_valley", &"settlement:dry_well", 1)
	before = stealth.to_canonical_json()
	check(String(Fixture.answer(stealth, &"SLIP_PAST").get("error", "")).begins_with("ARMOR_BLOCKS_STEALTH") and stealth.to_canonical_json() == before, "skill cannot bypass physical armor restriction")
	for spec: Array in [["REPAIR_PUMP", "wrench", "MECHANICS", 2, 1], ["REPAIR_PUMP", "repair_toolbox", "MECHANICS", 2, 1], ["OVERHAUL_PUMP", "precision_repair_kit", "MECHANICS", 3, 2], ["REWIRE_PUMP", "electronic_repair_kit", "ELECTRONICS", 2, 1]]:
		var sha: String = repair(spec[0], spec[1], spec[2], spec[3], spec[4], false)
		check(sha == repair(spec[0], spec[1], spec[2], spec[3], spec[4], true), "repair dual-track SHA256 " + sha)
	for method: String in ["OPEN_ARMORY", "BRIDGE_ARMORY", "CALIBRATE_ARMORY"]:
		var tool: String = {"OPEN_ARMORY": "repair_toolbox", "BRIDGE_ARMORY": "simple_meter", "CALIBRATE_ARMORY": "military_electronic_tools"}[method]
		var skill: String = "MECHANICS" if method == "OPEN_ARMORY" else "ELECTRONICS"
		var world: WorldState = Fixture.armory(tool)
		world.player.capability._data.skill_ranks[skill] = 3 if method == "CALIBRATE_ARMORY" else 2
		var twin: WorldState = checked(world)
		check(Fixture.answer(world, StringName(method)).success and Fixture.answer(twin, StringName(method)).success, "armory tool method")
		check(world.player.item_inventory.contains("old_world_saber") and world.player.item_inventory.contains(tool), "shared unique and retained real tool")
		check(world.player.inventory.scrap == (4 if method == "BRIDGE_ARMORY" else 6), "calibration saves material; fixed shared prize")
		check(checked(world).to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), "armory tool replay and invariants")
	var tool_gate: WorldState = Fixture.armory("wrench")
	before = tool_gate.to_canonical_json()
	check(String(Fixture.answer(tool_gate, &"OPEN_ARMORY").get("error", "")).begins_with("TOOL_REQUIRED") and tool_gate.to_canonical_json() == before, "knowledge without adequate tool atomic")
	tool_gate.player.pickup_item("precision_repair_kit")
	tool_gate.player.capability._data.skill_ranks.MECHANICS = 0
	before = tool_gate.to_canonical_json()
	check(String(Fixture.answer(tool_gate, &"OPEN_ARMORY").get("error", "")).begins_with("CAPABILITY_NOT_MET") and tool_gate.to_canonical_json() == before, "best tool cannot supply knowledge")
	print("GEAR-2C: assertions=%d failures=%d" % [assertions, failures])
	quit(1 if failures else 0)
