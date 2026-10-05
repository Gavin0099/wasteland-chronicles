extends "res://tests/test_relay_journey.gd"

# DIAGNOSTIC TOOL, NOT A TEST. Not part of runtime and not a CI pass/fail condition.
#
# Question it answers (docs/mine-min1-entrance.md, "續遊預算 gate"):
#   From the real RLY-8 `shared_return` state, can a single player who only reads
#   the visible job board and shops, doing at most two ordinary local jobs, prepare
#   a nominal Gray Valley -> Iron Pass -> (one mine day) -> Gray Valley round trip?
#
# It deliberately bakes in today's prices, job rotation and road events. Those are
# observations about this world seed, not a specification; re-run it after economy
# or road changes and read the table, do not assert on it.
#
# Run (needs the real engine; headless is enough):
#   godot --headless --path . --script res://tools/probe_min1_budget.gd
# It replays the full RLY-8 journey first, so expect about a minute. Output lines
# start with MIN1_PROBE. The process always exits 0.
#
# Fixed strategy (nothing is foreknown):
#   - start from the restored `shared_return` world, Abban dismissed (solo only);
#   - day 6+ waits in town with the same world tick REST uses (HP +4 up to 12);
#   - only local, non-combat jobs visible that day (delivery of food/water to Gray
#     Valley, hand-over of a purchasable item), at most two, positive visible net,
#     affordable; no bounty combat, no cross-city funding;
#   - prepare 1 scrap, 3 water, 3 food (round trip 2 + one mine day 1);
#   - rockslide: CLEAR with scrap else DETOUR; roadblock: PAY else DETOUR;
#     bandit ambush: BRIBE with >= 15 caps else FLEE_ROAD; everything else LEAVE;
#   - the mine day is modelled as one world tick plus 1 water and 1 food.
#
# Per day it runs the strategy twice: with all visible jobs and without the single
# highest-net job. Classification:
#   ROBUST  passes even without the top-net job
#   FRAGILE passes only when the top-net job is available
#   FAIL    does not finish with zero unmet needs, back in Gray Valley
# "Pass" = arrived at Iron Pass, returned to Gray Valley, alive, zero
# PLAYER_NEED_UNMET events after departure. Surviving on the grace period is a FAIL.

const GRAY: StringName = &"settlement:gray_valley"
const IRON: StringName = &"settlement:iron_pass"
const FIRST_DAY: int = 5
const LAST_DAY: int = 10
const BASE_WATER: int = 3
const BASE_FOOD: int = 3
const JOB_LIMIT: int = 2
const BRIBE_CAPS: int = 15

var saved_json: String = ""

func _init() -> void:
	store = Store.new("user://tests/min1/probe.json")
	call_deferred("probe")

func journey_checkpoint(world: WorldState, label: String) -> WorldState:
	var twin: WorldState = super.journey_checkpoint(world, label)
	if label == "shared_return": saved_json = world.to_canonical_json()
	return twin

func restore() -> WorldState:
	return WorldState.from_json_checked(saved_json).world

func attempt(w: WorldState, intent: PlayerIntent) -> bool:
	return engine.commit_player_intent(w, intent).success

func buy_up(w: WorldState, res: StringName, n: int) -> void:
	for i: int in range(n):
		if not attempt(w, PlayerIntent.create_buy(w.player.npc_id, res, 1)): break

func buy_to(w: WorldState, res: StringName, target: int) -> void:
	var have: int = w.player.inventory.get_amount(String(res))
	if target > have: buy_up(w, res, target - have)

func advance_to(w: WorldState, day: int) -> void:
	while w.current_day < day:
		engine.tick(w)
		w.player.field_kit.hp = mini(12, w.player.field_kit.hp + 4)

func unmet_after(w: WorldState, day: int) -> int:
	var n: int = 0
	for e: EventRecord in w.event_log:
		if e.type == "PLAYER_NEED_UNMET" and e.day >= day: n += 1
	return n

func item_cost(w: WorldState, item_id: String) -> int:
	var c: WorldState = WorldState.from_json_checked(w.to_canonical_json()).world
	var before: int = c.player.money
	if engine.commit_player_intent(c, PlayerIntent.create_buy_item(c.player.npc_id, item_id, 1)).success: return before - c.player.money
	return -1

func visible_local_jobs(w: WorldState) -> Array:
	var out: Array = []
	for j in Board.postings(w, GRAY):
		var d: Dictionary = j.definition
		var obj: Dictionary = d.objectives[0]
		var reward: int = 0
		for r in d.outcomes.resolved.rewards:
			if r.type == "CURRENCY": reward = int(r.amount)
		var cost: int = -1
		if obj.type == "DELIVER_RESOURCE" and obj.settlement_id == "gray_valley":
			cost = int(ceil(w.get_settlement(GRAY).get_current_price(obj.resource) * int(obj.quantity)))
		elif obj.type == "DELIVER_ITEM" and obj.settlement_id == "gray_valley":
			var unit: int = item_cost(w, obj.item_id)
			cost = unit * int(obj.quantity) if unit >= 0 else -1
		if cost >= 0: out.append({"id": String(d.id), "obj": obj, "reward": reward, "cost": cost, "net": reward - cost})
	return out

func do_job(w: WorldState, j: Dictionary) -> bool:
	if not attempt(w, PlayerIntent.create_accept_quest(w.player.npc_id, j.id)): return false
	if j.obj.type == "DELIVER_RESOURCE": buy_up(w, StringName(j.obj.resource), int(j.obj.quantity))
	else:
		for k: int in range(int(j.obj.quantity)): attempt(w, PlayerIntent.create_buy_item(w.player.npc_id, String(j.obj.item_id), 1))
	return attempt(w, PlayerIntent.create_turn_in_quest(w.player.npc_id, j.id))

func road(w: WorldState, dest: StringName) -> Array:
	var seen: Array = []
	attempt(w, PlayerIntent.create_travel(w.player.npc_id, dest))
	for stop: int in range(24):
		if w.pending_encounter_result >= 0:
			attempt(w, PlayerIntent.create_continue_journey(w.player.npc_id, w.pending_encounter_result))
		elif w.active_encounter != null:
			var t: StringName = w.active_encounter.encounter_type
			var choice: StringName = &"LEAVE"
			var fallback: StringName = &"DETOUR"
			if t == TravelEncounter.ROCKSLIDE: choice = &"CLEAR" if w.player.inventory.scrap >= 1 else &"DETOUR"
			elif t == TravelEncounter.ROADBLOCK: choice = &"PAY" if w.player.money >= 10 else &"DETOUR"
			elif t == TravelEncounter.BANDIT_AMBUSH:
				choice = &"BRIBE" if w.player.money >= BRIBE_CAPS else &"FLEE_ROAD"
				fallback = &"FLEE_ROAD"
			seen.append(String(t) + ":" + String(choice))
			if not attempt(w, PlayerIntent.create_resolve_encounter(w.player.npc_id, choice)):
				attempt(w, PlayerIntent.create_resolve_encounter(w.player.npc_id, fallback))
		else: break
	return seen

func place(w: WorldState) -> String:
	return String(w.npc_life_state_registry.get_life_state(w.player.npc_id).population_container_id)

func compact(w: WorldState) -> String:
	return "%dc %dw %df %ds" % [w.player.money, w.player.inventory.water, w.player.inventory.food, w.player.inventory.scrap]

# Runs one departure day. exclude_top drops the single highest-net eligible job.
func run_day(day: int, exclude_top: bool) -> Dictionary:
	var w: WorldState = restore()
	attempt(w, PlayerIntent.create_dismiss_companion(w.player.npc_id))
	advance_to(w, day)
	var caps_before: int = w.player.money
	var eligible: Array = visible_local_jobs(w).filter(func(j): return j.net >= 1 and j.cost <= w.player.money)
	eligible.sort_custom(func(a, b): return a.net > b.net)
	if exclude_top and not eligible.is_empty(): eligible.remove_at(0)
	var chosen: Array = []
	for j in eligible:
		if chosen.size() >= JOB_LIMIT: break
		if do_job(w, j): chosen.append(String(j.id).trim_prefix("job_gray_valley_") + "(" + str(j.net) + ")")
	var caps_after_jobs: int = w.player.money
	buy_to(w, &"scrap", 1); buy_to(w, &"water", BASE_WATER); buy_to(w, &"food", BASE_FOOD)
	var ready: String = compact(w)
	var spare: int = w.player.money
	var departure_day: int = w.current_day
	var out_events: Array = road(w, IRON)
	var arrived: bool = place(w) == String(IRON)
	var at_iron: String = compact(w)
	# One mine day: a world tick plus the dungeon-day pack cost (1 water, 1 food).
	var mine_short: bool = w.player.inventory.water < 1 or w.player.inventory.food < 1
	w.player.inventory.add_amount("water", -mini(1, w.player.inventory.water))
	w.player.inventory.add_amount("food", -mini(1, w.player.inventory.food))
	engine.tick(w)
	var back_events: Array = road(w, GRAY)
	var home: bool = place(w) == String(GRAY)
	var alive: bool = w.npc_life_state_registry.get_life_state(w.player.npc_id).is_alive()
	var unmet: int = unmet_after(w, departure_day)
	var passed: bool = arrived and home and alive and unmet == 0 and not mine_short
	return {"day": day, "passed": passed, "jobs": chosen, "caps_before": caps_before, "caps_after_jobs": caps_after_jobs, "ready": ready, "spare": spare,
		"out": out_events, "at_iron": at_iron, "back": back_events, "end": compact(w), "unmet": unmet, "arrived": arrived, "home": home}

func line(r: Dictionary, label: String) -> void:
	print("MIN1_PROBE ", label, " day=", r.day, " pass=", r.passed, " jobs=", r.jobs, " caps ", r.caps_before, "->", r.caps_after_jobs, " ready[", r.ready, "] spare=", r.spare,
		" out=", r.out, " at_iron[", r.at_iron, "] back=", r.back, " end[", r.end, "] unmet=", r.unmet, " arrived=", r.arrived, " home=", r.home)

func probe() -> void:
	ordinary_journey()
	var counts: Dictionary = {"ROBUST": 0, "FRAGILE": 0, "FAIL": 0}
	var summary: Array = []
	for day: int in range(FIRST_DAY, LAST_DAY + 1):
		var full: Dictionary = run_day(day, false)
		var without_top: Dictionary = run_day(day, true)
		line(full, "all_jobs")
		line(without_top, "without_top_job")
		var verdict: String = "FAIL"
		if full.passed: verdict = "ROBUST" if without_top.passed else "FRAGILE"
		counts[verdict] += 1
		summary.append("d%d=%s" % [day, verdict])
	print("MIN1_PROBE SUMMARY ", JSON.stringify(counts), " ", summary, " (diagnostic only; prices, postings and road events are this world's, not a specification)")
	quit(0)
