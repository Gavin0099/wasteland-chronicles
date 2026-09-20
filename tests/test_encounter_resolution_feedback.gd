extends SceneTree

var engine := SimulationEngine.new()
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

# Fixed catalogue fixtures: day 1/index 1 yields scrap 5, fuel 2;
# day 6/index 1 is empty. Capacity and 1 water/food per day are independent
# contracts; expected amounts below do not call production payout logic.
func fixture(day: int = 1, kind: StringName = TravelEncounter.WRECK) -> WorldState:
	var w := S1WorldData.create_s1_world()
	engine.materialize_player(w, &"settlement:gray_valley", "Tester", 25)
	w.player.inventory.water = 4
	w.player.inventory.food = 4
	engine.begin_player_travel(w, PlayerIntent.create_travel(w.player.npc_id, &"settlement:new_hope"))
	w.active_encounter = TravelEncounterState.create(kind, day, &"settlement:gray_valley", &"settlement:new_hope", 1)
	return w

func choose(w: WorldState, option: StringName = &"SEARCH") -> Dictionary:
	return engine.commit_player_intent(w, PlayerIntent.create_resolve_encounter(w.player.npc_id, option))

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var w := fixture()
	var ls := w.npc_life_state_registry.get_life_state(w.player.npc_id)
	var remaining := w.get_refugee_party(ls.population_container_id).days_remaining
	var result := choose(w)
	check(result.success and result.gained == {"scrap": 5, "fuel": 2}, "fixed wreck must grant 5 scrap/2 fuel")
	check(result.spent == {"water": 1, "food": 1} and result.elapsed_days == 1, "receipt must include exactly one day of actual metabolism")
	check(w.current_day == 1 and w.player.inventory.water == 3 and w.player.inventory.food == 3, "no later travel consumption before confirmation")
	check(w.get_refugee_party(ls.population_container_id).days_remaining == remaining, "search day must not shorten journey")
	check(w.active_encounter == null and w.pending_encounter_result >= 0, "choice must transition to receipt")
	var receipt := w.pending_encounter_result
	var before := w.to_canonical_json().sha256_text()
	check(w.duplicate_state().to_canonical_json().sha256_text() == before, "world copies must preserve pending receipt")
	for intent in [PlayerIntent.create_wait(w.player.npc_id), PlayerIntent.create_resolve_encounter(w.player.npc_id, &"SEARCH"), PlayerIntent.create_buy(w.player.npc_id, &"water", 1), PlayerIntent.create_travel(w.player.npc_id, &"settlement:new_hope"), PlayerIntent.create_continue_journey(w.player.npc_id, receipt + 1)]:
		check(not engine.commit_player_intent(w, intent).success, "pending receipt must reject unrelated/stale intents")
		check(w.to_canonical_json().sha256_text() == before, "rejected intent must not mutate world")
	engine.advance_player_travel(w, w.player.npc_id, 3)
	check(w.to_canonical_json().sha256_text() == before, "direct travel advance must honor receipt pause")

	var restored := WorldState.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	check(restored != null and restored.to_canonical_json().sha256_text() == before, "pending receipt must survive save/load exactly")
	if restored == null:
		quit(1)
		return
	var ui := PlayableShell.new()
	root.add_child(ui)
	ui.debug_world_feed_enabled = false
	ui.setup(restored, engine)
	check(ui.encounter_panel.visible and ui.lbl_encounter_body.text.contains("廢料 +5") and ui.lbl_encounter_body.text.contains("燃料 +2"), "receipt must show actual rewards without debug feed")
	check(ui.lbl_encounter_body.text.contains("水 −1") and ui.lbl_encounter_body.text.contains("+1 天"), "receipt must show losses and time")
	check(not ui.btn_wait.visible and not ui.itinerary_card.visible, "ordinary travel controls must be hidden")
	check(ui.encounter_options_box.get_child_count() == 1 and ui.encounter_options_box.get_child(0).text == "繼續上路", "receipt requires one explicit continue button")
	ui.refresh_ui()
	check(restored.to_canonical_json().sha256_text() == before, "re-render must not spend resources or time")
	ui.encounter_options_box.get_child(0).pressed.emit()
	engine.commit_player_intent(w, PlayerIntent.create_continue_journey(w.player.npc_id, receipt))
	check(w.current_day > 1, "confirmation must resume journey")
	check(restored.to_canonical_json().sha256_text() == w.to_canonical_json().sha256_text(), "UI confirmation and saved/loaded replay must match SHA-256")
	var after := restored.to_canonical_json().sha256_text()
	check(not ui.on_encounter_continue_pressed(receipt).success, "duplicate confirmation must be rejected")
	check(restored.to_canonical_json().sha256_text() == after, "duplicate confirmation must be inert")
	print("Replay SHA-256: ", after)

	var empty := fixture(6)
	check(choose(empty).gained.is_empty(), "empty wreck fixture must remain empty")
	ui.setup(empty, engine)
	check(ui.lbl_encounter_body.text.contains("沒有找到值得帶走"), "empty search needs explicit explanation")
	var full := fixture()
	full.player.capacity_total = 8
	var full_result := choose(full)
	check(full_result.gained.is_empty() and full_result.left_behind == {"scrap": 5, "fuel": 2}, "full backpack must record actual uncollected loot")
	ui.setup(full, engine)
	check(ui.lbl_encounter_body.text.contains("背包空間不足") and not ui.lbl_encounter_body.text.contains("沒有找到值得帶走"), "capacity failure is not an empty wreck")
	var partial := fixture()
	partial.player.capacity_total = 10
	var partial_result := choose(partial)
	check(partial_result.gained == {"scrap": 2} and partial_result.left_behind == {"scrap": 3, "fuel": 2}, "partially full pack must distinguish collected and remaining goods")

	for pair in [[TravelEncounter.WRECK, &"LEAVE", {}], [TravelEncounter.ROADBLOCK, &"PAY", {"caps": 10}], [TravelEncounter.ROCKSLIDE, &"CLEAR", {"scrap": 1}], [TravelEncounter.DEHYDRATED_TRAVELLER, &"GIVE_WATER", {"water": 1}], [TravelEncounter.REFUGEE_COLUMN, &"SHARE_FOOD", {"food": 1}]]:
		var other := fixture(1, pair[0])
		other.player.money = 20
		other.player.inventory.scrap = 1
		var r := choose(other, pair[1])
		check(r.success and r.spent == pair[2] and r.elapsed_days == 0 and other.current_day == 0, "zero-day option must show exact cost and pause")
		check(engine.validate_invariants(other) == "", "global invariants after zero-day choice")

	var fatal := fixture(6)
	fatal.player.inventory.water = 0
	fatal.player.water_exposure = SimulationEngine.WATER_EXPOSURE_GRACE_DAYS
	var fatal_result := choose(fatal)
	check(not fatal_result.spent.has("water") and fatal_result.spent.food == 1, "missing water cannot be reported as consumed")
	ui.setup(fatal, engine)
	check(ui.lbl_encounter_body.text.contains("旅程結束") and ui.encounter_options_box.get_child(0).text == "確認結果", "fatal receipt must not offer travel")
	var fatal_day := fatal.current_day
	check(ui.on_encounter_continue_pressed(fatal.pending_encounter_result).success and fatal.current_day == fatal_day, "fatal receipt can be dismissed without ticking")

	for world in [w, restored, empty, full, partial, fatal]:
		check(engine.validate_invariants(world) == "", "global invariants after receipt handling")
	for invalid in [-2, 0.5, "0", 999999, null]:
		var snapshot := empty.to_dict()
		snapshot.pending_encounter_result = invalid
		check(not WorldState.from_dict_checked(snapshot).success, "malformed receipt reference must fail closed")
	var malformed := empty.to_dict()
	malformed.events[empty.pending_encounter_result].payload.gained = {"scrap": -1}
	check(not WorldState.from_dict_checked(malformed).success, "malformed receipt contents must fail closed")
	var legacy := fixture().to_dict()
	legacy.erase("pending_encounter_result")
	check(WorldState.from_dict_checked(legacy).success, "old saves without receipt field must still load")
	await process_frame
	ui.free()
	await process_frame
	print("Encounter result checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
