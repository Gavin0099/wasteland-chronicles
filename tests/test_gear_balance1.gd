extends SceneTree
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Gear = preload("res://ui/gear_presentation.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-BALANCE-1: " + label)
func turn(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, {"command": command, "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)}))
func fight(id: String, enemy: String, shots: bool, expected: Array) -> void:
	var a: WorldState = Base.fresh("settlement:new_hope" if shots else "settlement:gray_valley")
	if not shots: a.player.capability._data.skill_ranks.MELEE = 1
	check(engine.commit_player_intent(a, PlayerIntent.create_buy_item(a.player.npc_id, StringName(id), 1)).success, "actual weapon purchase " + id)
	check(engine.commit_player_intent(a, PlayerIntent.create_equip_item(a.player.npc_id, StringName(id), "main_hand")).success, "actual equip " + id)
	var ammo: String = "shotgun_shell" if id == "short_shotgun" else "revolver_round"
	if shots:
		var money: int = a.player.money
		check(engine.commit_player_intent(a, PlayerIntent.create_buy_item(a.player.npc_id, StringName(ammo), int(expected[0]))).success, "buy exact fight ammunition")
		check(money - a.player.money == int(expected[3]), "actual local ammo cost at reviewed baseline")
		check(engine.begin_player_travel(a, PlayerIntent.create_travel(a.player.npc_id, &"settlement:dry_well")).success, "prepared real travel")
		a.active_encounter = TravelEncounterState.create(TravelEncounter.BANDIT_AMBUSH, a.current_day, &"settlement:new_hope", &"settlement:dry_well", 1, {"target_enemy": enemy})
		check(Base.answer(a, &"FIGHT").success, "controlled opponent real authority battle")
	else:
		Base.road_battle(a, enemy)
	var loaded: Dictionary = WorldState.from_json_checked(a.to_canonical_json())
	check(loaded.success, "checked starting battle " + id)
	var b: WorldState = loaded.world
	for strike: int in range(int(expected[0])):
		var intent: PlayerIntent = PlayerIntent.create_field_action(a.player.npc_id, {"command": "SHOOT" if shots else "ATTACK", "battle_id": int(a.field_state.battle.id), "turn": int(a.field_state.battle.turn)})
		check(engine.commit_player_intent(a, intent).success and engine.commit_player_intent(b, intent).success, "both committed strikes")
		check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "loaded/current twin SHA per turn")
		check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants per turn")
		var before: String = a.to_canonical_json()
		check(not engine.commit_player_intent(a, intent).success and a.to_canonical_json() == before, "stale strike atomic")
	check(a.player.field_kit.hp == int(expected[1]) and a.field_state.enemy_hp == int(expected[2]), "independent authored fight outcome " + id + " " + enemy)
	check(a.field_state.battle.is_empty() and a.field_state.receipt >= 0, "fight actually settled")
	check(WorldState.from_json_checked(a.to_canonical_json()).success, "checked outcome receipts")
	if shots: check(a.player.item_inventory.quantity(ammo) == 0, "exact actual ammunition depletion")
func run() -> void:
	# Independent authored fixture contract: [base damage, grams, base caps], no rule-derived expected values.
	var table: Dictionary = {"rusted_knife": [3,250,18], "hunting_knife": [4,400,72], "rebar_club": [4,1800,22], "scrap_machete": [5,1200,48], "sledgehammer": [6,3200,38], "combat_knife": [5,450,90], "reinforced_saber": [6,1600,200], "old_world_saber": [7,1300,300], "balanced_combat_knife": [5,450,120]}
	for id: String in table:
		var world: WorldState = Base.fresh()
		check(world.player.pickup_item(id).success and engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(id), "main_hand")).success, "controlled owned-weapon fixture " + id)
		var definition: Dictionary = Registry.resolve(id).definition
		check(Field.attack_damage(world) == int(table[id][0]) and definition.base_weight == int(table[id][1]) and definition.base_value == int(table[id][2]), "independent damage/weight/baseprice table " + id)
		check(definition.quality == ("MODIFIED" if id == "balanced_combat_knife" else ("UNIQUE" if id == "old_world_saber" else "COMMON")), "quality label does not scale damage")
		var before: String = world.to_canonical_json()
		check(not Gear.weapon_choice(id).is_empty() and Gear.stats(world, id, "main_hand").melee == int(table[id][0]) and world.to_canonical_json() == before, "truthful detached choice/stats " + id)
	fight("hunting_knife", "heavy_raider", false, [3,1,1,0])
	fight("combat_knife", "heavy_raider", false, [3,6,0,0])
	fight("hunting_knife", "feral_dog", false, [2,9,0,0])
	fight("combat_knife", "feral_dog", false, [1,12,0,0])
	fight("old_revolver", "heavy_raider", true, [3,6,0,36])
	fight("police_revolver", "heavy_raider", true, [3,6,0,36])
	fight("short_shotgun", "heavy_raider", true, [2,9,0,60])
	root.size = Vector2i(1152,648)
	var view_world: WorldState = Base.fresh("settlement:new_hope")
	check(engine.commit_player_intent(view_world, PlayerIntent.create_buy_item(view_world.player.npc_id, &"combat_knife", 1)).success, "UI held knife")
	var shell: PlayableShell = PlayableShell.new()
	root.add_child(shell)
	shell.setup(view_world, engine)
	shell._show_character()
	await process_frame
	for child: Node in shell.get_children():
		if child.get_script() == Sheet:
			child.show_item_detail("combat_knife")
			await process_frame
			check(child.gear_data.details.combat_knife.candidate.melee == 5 and child.gear_data.details.combat_knife.candidate.lines.has(Gear.weapon_choice("combat_knife")), "actual detail includes revised damage and choice")
	shell.queue_free()
	await process_frame
	print("GEAR-BALANCE-1: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
