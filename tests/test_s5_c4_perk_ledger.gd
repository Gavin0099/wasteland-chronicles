extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("Perk ledger: " + label)

func fixture() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var created := engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley",
		"character_name": "LedgerTester", "age": 25,
		"background_id": "MECHANIC", "trait_ids": [],
	}))
	check(created.success, "character creation succeeds")
	return world

func rejected(raw: Dictionary, code: String) -> bool:
	var result := WorldState.from_dict_checked(raw)
	return not result.success and result.world == null and String(result.error) == code

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var legacy := fixture()
	check(legacy.player.perk_ids.is_empty() and WorldState.from_json_checked(legacy.to_canonical_json()).success, "old profile without perks or perk events still loads")

	var left := fixture()
	var right := fixture()
	for world_variant in [left, right]:
		var world: WorldState = world_variant
		world.player.xp = 45
		var selected := engine.commit_player_intent(world, PlayerIntent.create_select_perk(world.player.npc_id, "CAREFUL_SALVAGER"))
		check(selected.success and engine.validate_invariants(world) == "", "committed perk and ledger satisfy global invariants")
		check(WorldState.from_json_checked(world.to_canonical_json()).success, "committed perk survives checked JSON loading")
	check(left.to_canonical_json().sha256_text() == right.to_canonical_json().sha256_text(), "two committed tracks have identical full-world SHA")

	var valid: Dictionary = left.to_dict()
	var switched: Dictionary = valid.duplicate(true)
	switched.player.perk_ids = ["ROAD_RUNNER"]
	check(rejected(switched, "PERK_LEDGER_MISMATCH"), "switching to another legal perk is refused")

	var missing_list: Dictionary = valid.duplicate(true)
	missing_list.player.erase("perk_ids")
	check(rejected(missing_list, "PERK_LEDGER_MISMATCH"), "removing the perk list while retaining its event is refused")

	var missing_event: Dictionary = valid.duplicate(true)
	missing_event.events.pop_back()
	missing_event.event_count = missing_event.events.size()
	check(rejected(missing_event, "PERK_LEDGER_MISMATCH"), "adding a legal perk without its event is refused")

	var duplicate_event: Dictionary = valid.duplicate(true)
	duplicate_event.events.append(duplicate_event.events.back().duplicate(true))
	duplicate_event.event_count = duplicate_event.events.size()
	check(rejected(duplicate_event, "PERK_LEDGER_MISMATCH"), "duplicate perk events cannot buy a second grant")

	var malformed_event: Dictionary = valid.duplicate(true)
	var last_event: Dictionary = malformed_event.events.back()
	last_event.payload.perk_id = "UNKNOWN"
	malformed_event.events[malformed_event.events.size() - 1] = last_event
	check(rejected(malformed_event, "PERK_LEDGER_MALFORMED"), "invalid perk ID in a committed event is refused")

	var wrong_actor: Dictionary = valid.duplicate(true)
	var moved_event: Dictionary = wrong_actor.events.back()
	moved_event.actor_id = "npc:other"
	wrong_actor.events[wrong_actor.events.size() - 1] = moved_event
	check(rejected(wrong_actor, "PERK_LEDGER_MISMATCH"), "another actor's event cannot justify the current player's perk")

	var live_tamper := left.duplicate_state()
	live_tamper.player.perk_ids = ["ROAD_RUNNER"]
	check(engine.validate_invariants(live_tamper) == "PERK_LEDGER_MISMATCH", "live global invariant catches the same divergence")
	check(engine.validate_invariants(left) == "" and engine.validate_invariants(right) == "", "failed loads did not mutate either original track")
	check(left.to_canonical_json().sha256_text() == right.to_canonical_json().sha256_text(), "two original worlds retain identical full-world SHA after rejection cases")
	print("S5-C4 perk ledger: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(0 if failures == 0 else 1)
