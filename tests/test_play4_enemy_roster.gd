extends SceneTree

# ==============================================================================
# PLAY-4 ENEMY ROSTER — three enemies, not three health bars
# ==============================================================================
# Hand-play twice: "敵人只有一種 是狼", then "戰鬥畫面還是有點死板". The second
# was not really a picture problem. One enemy with one damage pattern means
# every fight is ATTACK until something falls over, and no animation fixes that.
#
# The owner's gates, in order:
#   G1 Enemy Truth        name, art and data agree; no dog standing in for a person
#   G2 Behavior Difference at least two genuinely different deterministic patterns
#   G3 Player Choice      ATTACK and DEFEND, and DEFEND is sometimes the right call
#   G4 Telegraph          a heavy blow is readable before it lands
#   G5 Progression Payoff the raider is brutal at first and manageable after growth
#   G6 Visual Readability the stage shows the enemy actually being fought
#
# The hard gate is G2. Three enemies that differ only in HP and ATK would be
# three health bars wearing different names, and the suite fails that explicitly.
#
# Not here, deliberately: loot tables, enemy AI, status effects, criticals.
# ==============================================================================

const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Route = preload("res://simulation/travel_route.gd")
const Stage = preload("res://ui/components/battle_stage.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-4: " + label)

func _init() -> void:
	call_deferred("run")

func world_with(background: String) -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "Fighter",
		"age": 30, "background_id": background, "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 9)
	world.player.inventory.set_amount("food", 9)
	return world

func act(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload.battle_id = world.field_state.battle.id
		payload.turn = world.field_state.battle.turn
	elif command == "CONFIRM":
		payload.receipt = world.field_state.receipt
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))

# Start a road battle on a chosen route and report the opponent. Route choice
# only exists between Dry Well and New Hope, which is exactly where the player
# decides to take the worse road, so that is where this is tested.
func ambush(world: WorldState, route_type: StringName) -> String:
	var id: StringName = world.player.npc_id
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(id, &"settlement:new_hope", String(route_type))).success,
		"travel starts on the %s route" % String(route_type))
	world.active_encounter = TravelEncounterState.create(
		TravelEncounter.BANDIT_AMBUSH, world.current_day, &"settlement:dry_well", &"settlement:new_hope", 1)
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(id, &"FIGHT")).success, "FIGHT starts the road battle")
	return Field.battle_enemy(world.field_state)

func run() -> void:
	# ---- G1 the roster is real and distinct ----
	var ids := [Enemies.FERAL_DOG, Enemies.BANDIT, Enemies.HEAVY_RAIDER]
	var seen_names := {}
	var seen_art := {}
	for enemy_id in ids:
		var record := Enemies.resolve(enemy_id)
		check(String(record.name_zh) != "", "G1: %s has a name" % enemy_id)
		check(not seen_names.has(String(record.name_zh)), "G1: %s is not a renamed duplicate" % enemy_id)
		check(not seen_art.has(String(record.art)), "G1: %s does not borrow another enemy's art" % enemy_id)
		seen_names[String(record.name_zh)] = true
		seen_art[String(record.art)] = true
	check(Enemies.max_hp(Enemies.HEAVY_RAIDER) > Enemies.max_hp(Enemies.BANDIT), "G1: the raider is the heavy one")
	check(Enemies.max_hp(Enemies.FERAL_DOG) < Enemies.max_hp(Enemies.BANDIT), "G1: the dog is the fragile one")
	check(not bool(Enemies.resolve(Enemies.FERAL_DOG).can_parley), "G1: a dog cannot be talked to")
	check(bool(Enemies.resolve(Enemies.BANDIT).can_parley), "G1: a person can")

	# ---- G2 THE HARD GATE: the patterns must actually differ ----
	var patterns := {}
	for enemy_id in ids:
		var shape := PackedStringArray()
		for turn in range(1, 10):
			var action := Enemies.action_for(enemy_id, turn)
			shape.append("%d%s" % [int(action.damage), "H" if bool(action.heavy) else ""])
		patterns[enemy_id] = ",".join(shape)
	check(patterns.values().size() == 3, "G2: three patterns were measured")
	var distinct := {}
	for enemy_id in patterns:
		distinct[patterns[enemy_id]] = true
	check(distinct.size() >= 2, "G2: at least two genuinely different attack patterns exist, not three health bars")
	check(patterns[Enemies.FERAL_DOG] != patterns[Enemies.BANDIT], "G2: the dog does not fight like the bandit")
	check(patterns[Enemies.HEAVY_RAIDER] != patterns[Enemies.BANDIT], "G2: the raider does not fight like the bandit")

	# The dog has no rhythm to read; the raider does.
	var dog_damages := {}
	for turn in range(1, 10):
		dog_damages[int(Enemies.action_for(Enemies.FERAL_DOG, turn).damage)] = true
		check(not bool(Enemies.action_for(Enemies.FERAL_DOG, turn).heavy), "G2: the dog never winds up")
	check(dog_damages.size() == 1, "G2: the dog is relentless rather than rhythmic")

	var heavy_turns := 0
	for turn in range(1, 10):
		if bool(Enemies.action_for(Enemies.HEAVY_RAIDER, turn).heavy):
			heavy_turns += 1
	check(heavy_turns == 3, "G2: the raider's hammer lands on a readable cycle (%d of 9 turns)" % heavy_turns)

	# ---- G4 the heavy blow is announced before it lands ----
	for turn in range(1, 10):
		var action := Enemies.action_for(Enemies.HEAVY_RAIDER, turn)
		var told := Enemies.telegraph(Enemies.HEAVY_RAIDER, turn)
		check(told.find(str(int(action.damage))) >= 0, "G4: the telegraph states the real number for turn %d" % turn)
		if bool(action.heavy):
			check(told.find("鐵鎚") >= 0, "G4: the wind-up is unmistakable on turn %d" % turn)

	# ---- G3 bracing has to be worth a turn against that blow ----
	var ordinary := Enemies.brace_reduction(Enemies.HEAVY_RAIDER, 1)
	var against_heavy := Enemies.brace_reduction(Enemies.HEAVY_RAIDER, 3)
	check(against_heavy > ordinary, "G3: bracing is worth more against the blow worth bracing for")
	var heavy_damage := int(Enemies.action_for(Enemies.HEAVY_RAIDER, 3).damage)
	check(heavy_damage - against_heavy < heavy_damage - ordinary, "G3: bracing really blunts the hammer")
	check(heavy_damage > Enemies.max_hp(Enemies.FERAL_DOG) / 2, "G3: the hammer is frightening enough to answer")

	# ---- the route the player chose decides who is waiting ----
	var highway := world_with("CARAVAN_GUARD")
	check(ambush(highway, Route.ROUTE_HIGHWAY) == Enemies.BANDIT, "the highway holds a bandit")
	var wild := world_with("CARAVAN_GUARD")
	check(ambush(wild, Route.ROUTE_WILDERNESS) == Enemies.HEAVY_RAIDER, "the wilderness holds the raider")

	# ---- G6 the stage shows who is actually being fought ----
	var stage = Stage.new()
	stage.size = Vector2(640, 360)
	root.add_child(stage)
	stage.configure(Enemies.resolve(Enemies.BANDIT).art, "rebar_club", true)
	stage.refresh(false, true)
	check(stage.enemy_placeholder.visible and not stage.enemy.visible, "G6: a bandit is not drawn as the dog")
	var bandit_bulk: float = stage.enemy_placeholder.bulk
	stage.configure(Enemies.resolve(Enemies.HEAVY_RAIDER).art, "rebar_club", true)
	stage.refresh(false, true)
	check(stage.enemy_placeholder.visible and not stage.enemy.visible,
		"G6: the raider is not quietly drawn as the dog either")
	check(stage.enemy_placeholder.bulk > bandit_bulk,
		"G6: the raider does not look like the bandit in a different hat")
	stage.configure(Enemies.resolve(Enemies.FERAL_DOG).art, "rebar_club", false)
	stage.refresh(false, true)
	check(stage.enemy.visible and not stage.enemy_placeholder.visible, "G6: the dog uses its own art")
	stage.free()

	# ---- G5 the raider is brutal now and manageable later ----
	# Fought bare-handed by a starting character, the hammer puts them on the
	# floor. The same fight after growth and a weapon is survivable. Nothing is
	# hand-waved: both numbers come from the same public combat functions.
	var novice := world_with("SCAVENGER")
	var novice_hit: int = Field.attack_damage(novice)
	var raider_hp: int = Enemies.max_hp(Enemies.HEAVY_RAIDER)
	var novice_turns: int = int(ceil(float(raider_hp) / float(novice_hit)))
	var novice_taken := 0
	for turn in range(1, novice_turns):
		novice_taken += int(Enemies.action_for(Enemies.HEAVY_RAIDER, turn).damage)
	check(novice_taken >= Field.MAX_HP, "G5: a starting character cannot simply out-punch the raider (would take %d of %d health)" % [novice_taken, Field.MAX_HP])

	var veteran := world_with("SCAVENGER")
	veteran.player.pickup_item("scrap_machete")
	check(engine.commit_player_intent(veteran, PlayerIntent.create_equip_item(veteran.player.npc_id, &"scrap_machete", "main_hand")).success, "the veteran equips a real weapon")
	check(veteran.player.capability.raise_rank_by_point("MELEE").success, "the veteran spent growth on melee")
	check(veteran.player.capability.raise_rank_by_point("MELEE").success, "and again")
	var veteran_hit: int = Field.attack_damage(veteran)
	check(veteran_hit > novice_hit, "G5: growth and gear really raise the blow (%d -> %d)" % [novice_hit, veteran_hit])
	var veteran_turns: int = int(ceil(float(raider_hp) / float(veteran_hit)))
	var veteran_taken := 0
	for turn in range(1, veteran_turns):
		veteran_taken += int(Enemies.action_for(Enemies.HEAVY_RAIDER, turn).damage)
	check(veteran_turns < novice_turns, "G5: the veteran ends it sooner (%d turns vs %d)" % [veteran_turns, novice_turns])
	check(veteran_taken < novice_taken, "G5: and walks away with more left (%d taken vs %d)" % [veteran_taken, novice_taken])
	check(veteran_taken < Field.MAX_HP, "G5: the fight the novice could not take is now one the veteran can")

	# ---- persistence: a saved battle remembers its opponent ----
	var saved := world_with("CARAVAN_GUARD")
	check(ambush(saved, Route.ROUTE_WILDERNESS) == Enemies.HEAVY_RAIDER, "a raider fight is in progress")
	var reloaded := WorldState.from_json_checked(saved.to_canonical_json())
	check(reloaded.success, "a battle against the raider saves and loads")
	check(Field.battle_enemy(reloaded.world.field_state) == Enemies.HEAVY_RAIDER, "the reloaded fight is still against the raider")
	check(engine.validate_invariants(saved) == "", "invariants hold mid-battle")

	# A battle saved before PLAY-4 carries no enemy at all and must still load
	# as what it used to be rather than being rejected or silently upgraded.
	var legacy: Dictionary = saved.to_dict().duplicate(true)
	legacy.field_state.battle.erase("enemy")
	legacy.field_state.enemy_hp = Enemies.max_hp(Enemies.BANDIT)
	var legacy_loaded := WorldState.from_dict_checked(legacy)
	check(legacy_loaded.success, "a pre-PLAY-4 battle still loads")
	if legacy_loaded.success:
		check(Field.battle_enemy(legacy_loaded.world.field_state) == Enemies.BANDIT, "a pre-PLAY-4 road battle reads as the bandit it was")

	if failures == 0:
		print("PLAY-4 enemy roster: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("PLAY-4 enemy roster: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
