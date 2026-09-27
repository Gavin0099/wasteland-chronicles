extends SceneTree

# ==============================================================================
# ASP-1: WORLD SECRET — THE OLD ARMORY
# ==============================================================================
# Owner brief: one place, not thirteen caves. Hear of it -> want it -> cannot
# get in -> work and grow -> prepare -> go back -> get it.
#
#   W1 The prize is real and the market never sells it
#   W2 You hear of it: the standing raider bounty points past the camp
#   W3 It is far: the wilderness road, past the raider's camp, on day three
#   W4 "Not yet" is visible: the door shows its MECHANICS requirement, and the
#      engine refuses it - hiding the button is not the protection
#   W5 It keeps asking: coming back is never met with silence
#   W6 With the skill, you get in: the prize, a day spent, practice earned
#   W7 A pack full of supplies still takes the prize; the scrap stays behind
#   W8 The prize changes the fight you could not take before; saves round-trip
# ==============================================================================

const RoadPlaces = preload("res://simulation/road_places.gd")
const Board = preload("res://simulation/job_board.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Field = preload("res://simulation/field_adventure.gd")
const ItemRegistry = preload("res://simulation/item_registry.gd")
const ItemMarketCatalogue = preload("res://simulation/item_market_catalogue.gd")
const ItemIcon = preload("res://ui/components/item_icon.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")

const ARMORY := "place:old_armory"
const PRIZE := "old_world_saber"

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ASP-1: " + label)

func _init() -> void:
	call_deferred("run")

func fresh_world(mechanics: int = 0) -> WorldState:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:dry_well", "character_name": "Seeker",
		"age": 30, "background_id": "SCAVENGER", "trait_ids": [],
	})).success, "character creation succeeds")
	world.player.capability._data.skill_ranks["MECHANICS"] = mechanics
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	return world

func answer(world: WorldState, option: StringName) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, option))

# Set out on the wilderness road and walk on through everything until the
# armory asks, or the road ends.
func reach_armory(world: WorldState, from_new_hope: bool = false) -> bool:
	var destination := &"settlement:dry_well" if from_new_hope else &"settlement:new_hope"
	world.player.inventory.set_amount("water", 8)
	world.player.inventory.set_amount("food", 8)
	if not engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, destination, "WILDERNESS")).success:
		return false
	var guard := 0
	while guard < 12:
		guard += 1
		if world.active_encounter != null and String(world.active_encounter.context.get("place_id", "")) == ARMORY:
			return true
		if world.pending_encounter_result >= 0:
			engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
			continue
		if world.active_encounter == null:
			return false
		var choice := &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		answer(world, choice)
	return false

func finish(world: WorldState) -> void:
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
		answer(world, choice)

func armory_option(world: WorldState) -> Dictionary:
	for o in PlayerUIProjection.project(world).get("active_encounter", {}).get("options", []):
		if String(o.id) == "OPEN_ARMORY":
			return o
	return {}

func run() -> void:
	# ---- W1 the prize ----
	var resolved := ItemRegistry.resolve(PRIZE)
	check(resolved.success, "W1: the saber is a canonical item")
	check(ItemIcon.texture_for(PRIZE) != null, "W1: it has real art")
	for settlement in [&"settlement:new_hope", &"settlement:gray_valley", &"settlement:dry_well"]:
		check(not ItemMarketCatalogue.profile_for(PRIZE, settlement).is_routinely_supplied, "W1: %s does not sell it" % settlement)

	# ---- W2 you hear of it ----
	var hear := fresh_world()
	var standing := {}
	for entry in Board.postings(hear, &"settlement:new_hope"):
		if bool(entry.get("standing", false)):
			standing = entry
	check(String(standing.get("definition", {}).get("description_zh", "")).contains("軍械庫"), "W2: the raider bounty says there is an armory past his camp")
	for row in PlayerUIProjection.project(hear).get("road_places", []):
		if String(row.id) == ARMORY:
			check(not bool(row.discovered) and String(row.name) == "？", "W2: on the map it is a '?' until found")

	# ---- W3/W4 far, and not yet ----
	var weak := fresh_world(0)
	check(reach_armory(weak), "W3: the wilderness road reaches the armory")
	check(weak.active_encounter.travel_day_index == 3, "W3: on day three, past the camp")
	var locked := armory_option(weak)
	check(not locked.is_empty(), "W4: the door is shown, not hidden")
	check(bool(locked.get("locked", false)) and not bool(locked.get("enabled", true)), "W4: and locked")
	check(String(locked.get("requirement_label", "")).contains("機械 2"), "W4: it says what it needs: %s" % locked.get("requirement_label", ""))
	var refused := answer(weak, &"OPEN_ARMORY")
	check(not refused.success and String(refused.get("error", "")).begins_with("CAPABILITY_NOT_MET"), "W4: the engine refuses it too: %s" % refused.get("error", ""))
	check(not weak.player.inspect_item(PRIZE).success, "W4: nothing was taken")
	check(answer(weak, &"LEAVE").success, "W4: walking on is always possible")
	finish(weak)

	# ---- W5 it keeps asking ----
	check(reach_armory(weak, true), "W5: on the way back it asks again")
	answer(weak, &"LEAVE")
	finish(weak)
	check(RoadPlaces.is_live(weak, ARMORY), "W5: still there to come back for")
	check(String(RoadPlaces.status_text(weak, ARMORY)).contains("機械 2"), "W5: the map says what it is waiting for")

	# ---- W6 with the skill, you get in ----
	var able := fresh_world(RoadPlaces.ARMORY_MECHANICS)
	able.player.inventory.set_amount("scrap", 0)
	check(reach_armory(able), "W6: reach the door")
	var open := armory_option(able)
	check(bool(open.get("enabled", false)), "W6: with MECHANICS %d the door can be opened" % RoadPlaces.ARMORY_MECHANICS)
	able.player.inventory.set_amount("water", 4)
	able.player.inventory.set_amount("food", 4)
	var day_before := able.current_day
	var opened := answer(able, &"OPEN_ARMORY")
	check(opened.success, "W6: opening commits")
	check(able.player.inspect_item(PRIZE).success, "W6: the saber is in the pack")
	check(able.current_day == day_before + 1, "W6: it cost a day")
	check(opened.has("skill_practice") and String(opened.skill_practice.skill_id) == "MECHANICS", "W6: and it was MECHANICS practice")
	check(bool(RoadPlaces.state(able, ARMORY).prize_taken) and not RoadPlaces.is_live(able, ARMORY), "W6: the armory is empty now")
	finish(able)

	# ---- W7 a full pack ----
	# The saber does not compete with water and food for room, so a pack full
	# of supplies still takes it; the scrap is what gets left.
	var full := fresh_world(RoadPlaces.ARMORY_MECHANICS)
	check(reach_armory(full), "W7: reach the door")
	full.player.inventory.set_amount("water", 10)
	full.player.inventory.set_amount("food", 10)
	var crammed := answer(full, &"OPEN_ARMORY")
	check(crammed.success, "W7: opening still commits")
	check(full.player.inspect_item(PRIZE).success, "W7: the saber is taken even with a full pack")
	check(int((crammed.get("left_behind", {}) as Dictionary).get("scrap", 0)) > 0, "W7: the scrap is what stays behind")
	finish(full)

	# ---- W8 the prize changes the fight ----
	var armed := fresh_world(0)
	armed.player.capability._data.skill_ranks["MELEE"] = 0
	armed.player.item_inventory.pickup_item("scrap_machete", 1)
	engine.commit_player_intent(armed, PlayerIntent.create_equip_item(armed.player.npc_id, &"scrap_machete", "main_hand"))
	check(bool(Field.forecast_for_enemy(armed, Enemies.HEAVY_RAIDER, true).beaten), "W8: with the machete at MELEE 0 the raider still wins")
	armed.player.item_inventory.pickup_item(PRIZE, 1)
	check(engine.commit_player_intent(armed, PlayerIntent.create_equip_item(armed.player.npc_id, StringName(PRIZE), "main_hand")).success, "W8: the saber can be wielded")
	check(Field.attack_damage(armed) == 7, "W8: it hits for 7 at MELEE 0")
	check(not bool(Field.forecast_for_enemy(armed, Enemies.HEAVY_RAIDER, true).beaten), "W8: and the raider can be beaten with it")
	for saved in [able, full]:
		var loaded := WorldState.from_json_checked(saved.to_canonical_json())
		check(loaded.success, "W8: a world with the armory receipt loads: %s" % String(loaded.get("error", "")))
		if loaded.success:
			check(loaded.world.to_canonical_json() == saved.to_canonical_json(), "W8: byte-identical after save/load")

	print("ASP-1 world secret: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
