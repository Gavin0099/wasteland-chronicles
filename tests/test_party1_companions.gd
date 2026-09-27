extends SceneTree

# ==============================================================================
# PARTY-1: ONE COMPANION
# ==============================================================================
# Owner ruling: a companion is another mouth on the road and a different set of
# abilities that changes what the party can do - not +20% damage.
#
#   P1 Three companions, one per town, three different abilities
#   P2 Hiring: in their town, for a fee, one at a time - refused otherwise,
#      by the engine
#   P3 The mechanic opens what the player cannot: the armory door
#   P4 The fighter hits too: the raider the player alone cannot beat, the
#      two of them can
#   P5 The cost is the road: a companion eats from the pack on a travel day,
#      and nothing extra in town
#   P6 The guide finds water: on the road the party drinks nothing from the pack
#   P7 An unfed companion leaves you on the road
#   P8 Letting them go: in town only
#   P9 The player sees it; saves round-trip
# ==============================================================================

const Party = preload("res://simulation/party.gd")
const RoadPlaces = preload("res://simulation/road_places.gd")
const Rumors = preload("res://simulation/rumors.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PARTY-1: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(origin: String) -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": origin, "character_name": "Leader",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	world.player.money = 200
	return world

func hire(world: WorldState, companion_id: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, companion_id))

# One day on the road, without encounters: what did the pack lose?
func road_day(world: WorldState, destination: String) -> Dictionary:
	check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, StringName(destination))).success, "the trip starts")
	var w0 := world.player.inventory.get_amount("water")
	var f0 := world.player.inventory.get_amount("food")
	engine.tick(world)
	return {"water": w0 - world.player.inventory.get_amount("water"), "food": f0 - world.player.inventory.get_amount("food")}

func run() -> void:
	# ---- P1 roster ----
	var towns := {}
	for companion_id in Party.ids():
		var c := Party.info(companion_id)
		check(not towns.has(String(c.town)), "P1: one companion per town")
		towns[String(c.town)] = companion_id
	check(towns.size() == 3, "P1: three companions")
	check(not (Party.info("companion:abban").skills as Dictionary).is_empty(), "P1: the mechanic brings a skill")
	check(int(Party.info("companion:tieniu").damage_bonus) > 0, "P1: the fighter brings a blow")
	check(bool(Party.info("companion:shahu").finds_water), "P1: the guide brings water")

	# ---- P2 hiring ----
	var gv := fresh_world("settlement:gray_valley")
	check(Party.current(gv) == "", "P2: nobody walks with you at the start")
	var wrong := hire(gv, "companion:tieniu")
	check(not wrong.success and String(wrong.error) == "COMPANION_NOT_HERE", "P2: the fighter is not in Gray Valley")
	var money0 := gv.player.money
	check(hire(gv, "companion:abban").success, "P2: hire the mechanic in Gray Valley")
	check(Party.current(gv) == "companion:abban", "P2: he walks with you")
	check(money0 - gv.player.money == int(Party.info("companion:abban").fee), "P2: for his fee")
	var second := fresh_world("settlement:gray_valley")
	hire(second, "companion:abban")
	var twice := hire(second, "companion:abban")
	check(not twice.success and String(twice.error) == "ALREADY_HAS_COMPANION", "P2: one at a time")
	var poor := fresh_world("settlement:gray_valley")
	poor.player.money = 10
	check(String(hire(poor, "companion:abban").get("error", "")) == "INSUFFICIENT_FUNDS", "P2: not without the fee")
	var shunned := fresh_world("settlement:gray_valley")
	shunned.record_event(EventRecord.new(shunned.current_day, "JOB_BETRAYED", shunned.player.npc_id, &"settlement:gray_valley",
		{"quest_id": "job_gray_valley_consign_0", "settlement_id": "settlement:gray_valley", "resource": "scrap", "quantity": 2}))
	check(String(hire(shunned, "companion:abban").get("error", "")) == "TOWN_DISTRUSTS_YOU", "P2: not from a town that has turned on you")

	# ---- P3 the mechanic opens the armory ----
	gv.player.capability._data.skill_ranks["MECHANICS"] = 0
	check(Party.skill_rank(gv, "MECHANICS") == 2, "P3: with him the party counts as MECHANICS 2")
	var gate := Party.meets(gv, {"all": [{"kind": "skill", "skill_id": "MECHANICS", "min_rank": RoadPlaces.ARMORY_MECHANICS}]})
	check(gate.success and gate.met, "P3: the armory's requirement is met by the party")
	var alone := fresh_world("settlement:gray_valley")
	alone.player.capability._data.skill_ranks["MECHANICS"] = 0
	var gate_alone := Party.meets(alone, {"all": [{"kind": "skill", "skill_id": "MECHANICS", "min_rank": RoadPlaces.ARMORY_MECHANICS}]})
	check(gate_alone.success and not gate_alone.met, "P3: alone it is not")
	var trait_gate := Party.meets(gv, {"all": [{"kind": "trait_present", "trait_id": "GREEDY"}]})
	check(trait_gate.success and not trait_gate.met, "P3: a companion does not lend you their temperament")

	# ---- P4 the fighter ----
	var nh := fresh_world("settlement:new_hope")
	nh.player.capability._data.skill_ranks["MELEE"] = 0
	nh.player.item_inventory.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(nh, PlayerIntent.create_equip_item(nh.player.npc_id, &"scrap_machete", "main_hand"))
	var solo_hit := Field.attack_damage(nh)
	check(bool(Field.forecast_for_enemy(nh, Enemies.HEAVY_RAIDER, true).beaten), "P4: alone with a machete, the raider wins")
	check(hire(nh, "companion:tieniu").success, "P4: hire the fighter in New Hope")
	check(Field.attack_damage(nh) == solo_hit + int(Party.info("companion:tieniu").damage_bonus), "P4: every attack lands +%d" % int(Party.info("companion:tieniu").damage_bonus))
	check(not bool(Field.forecast_for_enemy(nh, Enemies.HEAVY_RAIDER, true).beaten), "P4: together, the raider can be beaten")

	# ---- P5 the cost is the road ----
	var lone := fresh_world("settlement:gray_valley")
	var lone_cost := road_day(lone, "settlement:dry_well")
	var pair := fresh_world("settlement:gray_valley")
	hire(pair, "companion:abban")
	var pair_cost := road_day(pair, "settlement:dry_well")
	check(pair_cost.water == lone_cost.water + 1 and pair_cost.food == lone_cost.food + 1, "P5: a companion eats 1 water and 1 food more per travel day (%s vs %s)" % [pair_cost, lone_cost])
	var in_town := fresh_world("settlement:gray_valley")
	hire(in_town, "companion:abban")
	var w_town := in_town.player.inventory.get_amount("water")
	var f_town := in_town.player.inventory.get_amount("food")
	engine.commit_player_intent(in_town, PlayerIntent.create_wait(in_town.player.npc_id))
	check(in_town.player.inventory.get_amount("water") == w_town and in_town.player.inventory.get_amount("food") == f_town, "P5: in town the town feeds you both")

	# ---- P6 the guide ----
	var guided := fresh_world("settlement:dry_well")
	check(hire(guided, "companion:shahu").success, "P6: hire the guide in Dry Well")
	var guide_cost := road_day(guided, "settlement:gray_valley")
	check(guide_cost.water == 0, "P6: nobody drinks from the pack on the road (%s)" % [guide_cost])
	check(guide_cost.food == 2, "P6: you both still eat")

	# ---- P7 an unfed companion leaves ----
	var hungry := fresh_world("settlement:gray_valley")
	hire(hungry, "companion:abban")
	hungry.player.inventory.set_amount("food", 1)
	road_day(hungry, "settlement:dry_well")
	check(Party.current(hungry) == "", "P7: with food for one, he leaves you on the road")
	var gone: EventRecord = null
	for event in hungry.event_log:
		if event.type == "COMPANION_LEFT":
			gone = event
	check(gone != null and String(gone.payload.reason) == "HUNGER", "P7: and the receipt says why")

	# ---- P8 letting go ----
	var road := fresh_world("settlement:gray_valley")
	hire(road, "companion:abban")
	engine.begin_player_travel(road, PlayerIntent.create_travel(road.player.npc_id, &"settlement:dry_well"))
	check(not engine.commit_player_intent(road, PlayerIntent.create_dismiss_companion(road.player.npc_id)).success, "P8: not in the middle of the road")
	check(engine.commit_player_intent(gv, PlayerIntent.create_dismiss_companion(gv.player.npc_id)).success, "P8: in town, let him go home")
	check(Party.current(gv) == "", "P8: nobody walks with you now")
	check(hire(gv, "companion:abban").success, "P8: and he can be hired again")

	# ---- P9 the player sees it ----
	var shown := fresh_world("settlement:gray_valley")
	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(shown, engine)
	await process_frame
	check(shell.btn_local_train.text == "找人", "P9: the town button is 找人")
	shell._show_training()
	await process_frame
	check(shell.companion_buttons.has("companion:abban") and not shell.companion_buttons["companion:abban"].disabled, "P9: the mechanic can be hired from the 找人 window")
	shell.companion_buttons["companion:abban"].pressed.emit()
	check(Party.current(shown) == "companion:abban", "P9: pressing it hires him")
	shell.refresh_ui()
	check(shell.desktop_aim_label.visible and shell.desktop_aim_label.text.contains("阿扳"), "P9: the main screen says who walks with you: %s" % shell.desktop_aim_label.text)
	shell.queue_free()
	for saved in [gv, nh, hungry]:
		var loaded := WorldState.from_json_checked(saved.to_canonical_json())
		check(loaded.success, "P9: loads: %s" % String(loaded.get("error", "")))
		if loaded.success:
			check(loaded.world.to_canonical_json() == saved.to_canonical_json(), "P9: byte-identical")
			check(Party.current(loaded.world) == Party.current(saved), "P9: the party survives the save")

	print("PARTY-1 companions: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
