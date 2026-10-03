extends SceneTree

const Creation = preload("res://simulation/character_creation_intent.gd")
const Board = preload("res://simulation/job_board.gd")
const Enemies = preload("res://simulation/enemy_catalogue.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Screen = preload("res://ui/field_screen.gd")
const Shell = preload("res://ui/playable_shell.gd")
const Stage = preload("res://ui/components/battle_stage.gd")
const UiProjection = preload("res://ui/player_ui_projection.gd")
# Independent reviewed contract fixtures; deliberately not copied from runtime maps.
const SPECS := [
	{"enemy": "feral_boar", "town": "new_hope", "destination": "dry_well", "route": "WILDERNESS", "days": 4, "hp": 10, "pattern": [2, 8, 2, 8, 2, 8, 2, 8], "caps": 125, "xp": 14},
	{"enemy": "desert_scorpion", "town": "dry_well", "destination": "gray_valley", "route": "HIGHWAY", "days": 3, "hp": 8, "pattern": [5, 1, 5, 1, 5, 1, 5, 1], "caps": 90, "xp": 10},
	{"enemy": "ash_ghoul", "town": "gray_valley", "destination": "new_hope", "route": "HIGHWAY", "days": 3, "hp": 12, "pattern": [1, 2, 4, 6, 1, 2, 4, 6], "caps": 115, "xp": 14},
]
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("CREATURE-HUNT: " + label)

func _init() -> void:
	call_deferred("run")

func hunter(spec: Dictionary, weapon: String = "rusted_knife") -> WorldState:
	var world: WorldState = S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({"source_settlement_id": "settlement:" + String(spec.town), "character_name": "狩獵旅人", "age": 28, "background_id": "MECHANIC", "trait_ids": []})).success, "create actual hunter")
	world.player.inventory.set_amount("water", 9)
	world.player.inventory.set_amount("food", 9)
	if weapon != "":
		check(world.player.item_inventory.pickup_item(weapon, 1).success, "reviewed fixture weapon ownership")
		check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, StringName(weapon), "main_hand")).success, "equip actual knife")
	return world

func posting(world: WorldState, spec: Dictionary) -> Dictionary:
	for entry: Dictionary in Board.postings(world, StringName("settlement:" + String(spec.town))):
		if entry.get("archetype") == "HUNT" and entry.get("target_enemy") == spec.enemy:
			return entry
	return {}

func command(world: WorldState, name: String) -> Dictionary:
	var data: Dictionary = {"command": name}
	if name in ["ATTACK", "DEFEND", "FLEE"]:
		data.battle_id = int(world.field_state.battle.id)
		data.turn = int(world.field_state.battle.turn)
	elif name == "CONFIRM": data.receipt = int(world.field_state.receipt)
	return data

func act(world: WorldState, name: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, command(world, name)))

func parity(world: WorldState, twin: WorldState, label: String) -> void:
	check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), label + " twin SHA-256")
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", label + " global invariants")
	var saved: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(saved.success and saved.world.to_canonical_json() == world.to_canonical_json(), label + " checked persistence")

func pass_encounters(world: WorldState) -> bool:
	for stop: int in range(16):
		if world.active_encounter == null: return true
		var choice: StringName = &"LEAVE"
		if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
		elif world.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
		if not engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice)).success: return false
		if not engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success: return false
	return false

func reach_target(world: WorldState, spec: Dictionary, job_id: String) -> bool:
	# Only New Hope–Dry Well offers an explicit route selector. Other original
	# caravan roads use the legacy blank route, normalized as HIGHWAY by hunts.
	var route_choice: String = String(spec.route) if spec.town == "new_hope" else ""
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, StringName("settlement:" + String(spec.destination)), route_choice)).success, "travel on real hunt route")
	for stop: int in range(12):
		if world.active_encounter == null: return false
		if world.active_encounter.context.get("bounty_job_id", "") == job_id: return true
		var choice: StringName = &"LEAVE"
		if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
		elif world.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
		if not engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice)).success: return false
		if not engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success: return false
	return false

func battle_world(spec: Dictionary, weapon: String = "rusted_knife") -> WorldState:
	var world: WorldState = hunter(spec, weapon)
	var entry: Dictionary = posting(world, spec)
	check(not entry.is_empty(), "actual reachable hunt posting")
	if entry.is_empty(): return world
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id)).success, "accept real hunt")
	check(reach_target(world, spec, entry.definition.id), "guaranteed target from real travel")
	if world.active_encounter == null: return world
	check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT")).success, "real fight handoff")
	return world

func run() -> void:
	root.size = Vector2i(1280, 720)
	for spec: Dictionary in SPECS:
		check(Enemies.exists(spec.enemy) and Enemies.max_hp(spec.enemy) == spec.hp, "independent creature roster")
	if failures > 0:
		quit(1)
		return
	check(Enemies.ENEMIES.size() == 6 and Enemies.highest_hp() == 16, "six distinct enemies within existing save bounds")
	for spec: Dictionary in SPECS:
		for index: int in range(8):
			var action: Dictionary = Enemies.action_for(spec.enemy, index + 1)
			check(action.damage == spec.pattern[index], "specified eight-turn rhythm")
			check(Enemies.telegraph(spec.enemy, index + 1).contains(str(spec.pattern[index])) and not Enemies.telegraph(spec.enemy, index + 1).contains("鐵鎚"), "truthful creature telegraph")
		var world: WorldState = hunter(spec)
		var before: String = world.to_canonical_json()
		var entry: Dictionary = posting(world, spec)
		check(not entry.is_empty() and world.to_canonical_json() == before, "board pure query")
		if entry.is_empty(): continue
		check(entry.route_days == spec.days and entry.definition.deadline_days == 9, "actual distance and return deadline")
		check(entry.definition.outcomes.resolved.rewards[0].amount == spec.caps and entry.definition.outcomes.resolved.rewards[1].amount == spec.xp, "independent baseline pay fixture")
		check(QuestDefinition.validate_definition(entry.definition) == "", "pass fixture executes contract validator")
		var bad: Dictionary = entry.definition.duplicate(true)
		bad.objectives[0].target_enemy = "feral_dog"
		check(QuestDefinition.validate_definition(bad) != "", "mismatched target fail fixture executes validator")
		bad = entry.definition.duplicate(true)
		bad.target_enemy = "invented_creature"
		check(QuestDefinition.validate_definition(bad) != "", "unknown target fail fixture")
		check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, entry.definition.id)).success, "real acceptance")
		check(reach_target(world, spec, entry.definition.id), "real target before arrival")
		if world.active_encounter == null: continue
		check(world.active_encounter.context.target_enemy == spec.enemy, "target identity retained")
		var options: Array = TravelEncounter.options(TravelEncounter.BANDIT_AMBUSH, world.active_encounter.context)
		check(options.size() == 2 and options[0].id == &"FIGHT" and options[1].id == &"FLEE_ROAD", "animals expose fight or escape")
		check(TravelEncounter.body(TravelEncounter.BANDIT_AMBUSH, world.active_encounter.context).contains(Enemies.display_name(spec.enemy)), "encounter body matches creature")
		before = world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"BRIBE")).success and world.to_canonical_json() == before, "animal bribe refuses atomically")
		check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT")).success, "real hunt combat")
		var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		check(loaded.success, "active hunt checked load")
		if not loaded.success: continue
		var twin: WorldState = loaded.world
		var ui: Control = Screen.new()
		root.add_child(ui)
		ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.setup(world, engine)
		ui.reduce_motion.button_pressed = true
		await process_frame
		check(not ui.buttons.ATTACK.disabled and not ui.buttons.DEFEND.disabled and not ui.buttons.FLEE.disabled, "actual hunt actions enabled")
		check(ui.stage.current_enemy_id == spec.enemy and not ui.stage.showing_placeholder, "correct original art installed")
		var original_texture: Texture2D = ui.stage.enemy_actor.texture_ref
		for pose: String in ["rest", "windup", "strike", "hurt", "charge", "kneel", "fall"]:
			ui.stage.enemy_actor.hold_pose(pose)
			check(ui.stage.enemy_actor.body.texture == original_texture, "all cutout poses preserve silhouette")
		check(absf(ui.stage.enemy_actor.body.rotation) > 0.8, "terminal cutout actually collapses")
		ui.stage.enemy_actor.hold_pose("rest")
		var stale: Dictionary = command(world, "ATTACK")
		for step: int in range(20):
			if world.field_state.battle.is_empty(): break
			var turn: int = int(world.field_state.battle.turn)
			var incoming: int = spec.pattern[(turn - 1) % 8]
			var move: String = "DEFEND" if incoming >= 5 else "ATTACK"
			var data: Dictionary = ui.payload_for(move)
			var health: int = int(world.player.field_kit.hp)
			var remaining: int = int(world.field_state.enemy_hp)
			check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, data)).success, "direct checked twin action")
			await ui.perform(data)
			var heavy: bool = spec.enemy == "feral_boar" and turn % 2 == 0 or spec.enemy == "ash_ghoul" and turn % 4 == 0
			var taken: int = maxi(0, incoming - (7 if heavy else 3)) if move == "DEFEND" else (0 if remaining <= 3 else incoming)
			check(world.player.field_kit.hp == health - taken, "observable HP follows independent damage/brace specification")
			parity(world, twin, "hunt turn")
		check(world.field_state.battle.is_empty() and world.field_state.receipt >= 0, "finite hunting outcome")
		if world.field_state.receipt < 0: continue
		var result: Dictionary = world.event_log[world.field_state.receipt].payload
		check(result.outcome == "VICTORY" and result.enemy == spec.enemy and result.bounty_job_id == entry.definition.id, "victory attributed to exact hunt")
		before = world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, stale)).success and world.to_canonical_json() == before, "stale hunt action atomic refusal")
		check(act(world, "CONFIRM").success and act(twin, "CONFIRM").success, "resume actual journey")
		check(pass_encounters(world) and pass_encounters(twin), "complete outgoing journey")
		parity(world, twin, "hunt arrival")
		check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, entry.definition.id)).success, "wrong town cannot pay hunt")
		check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, StringName("settlement:" + String(spec.town)))).success, "real return trip")
		check(engine.commit_player_intent(twin, PlayerIntent.create_travel(twin.player.npc_id, StringName("settlement:" + String(spec.town)))).success, "checked twin return")
		check(pass_encounters(world) and pass_encounters(twin), "finish return encounters")
		parity(world, twin, "return to issuer")
		var money: int = world.player.money
		var xp: int = world.player.xp
		check(engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, entry.definition.id)).success, "actual turn-in")
		check(engine.commit_player_intent(twin, PlayerIntent.create_turn_in_quest(twin.player.npc_id, entry.definition.id)).success, "checked twin turn-in")
		check(world.player.money == money + spec.caps and world.player.xp == xp + spec.xp, "accepted exact payout and work XP")
		parity(world, twin, "paid hunt")
		before = world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_turn_in_quest(world.player.npc_id, entry.definition.id)).success and world.to_canonical_json() == before, "duplicate payment atomic refusal")
		ui.queue_free()
		await process_frame
		var escaped: WorldState = battle_world(spec)
		check(act(escaped, "FLEE").success, "actual hunt escape")
		var escaped_id: String = escaped.event_log[escaped.field_state.receipt].payload.bounty_job_id
		check(not QuestEngine.evaluate_objectives(escaped, escaped_id), "escape cannot satisfy hunt")
		parity(escaped, WorldState.from_json_checked(escaped.to_canonical_json()).world, "escaped checked hunt")
	print("Creature hunts: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
