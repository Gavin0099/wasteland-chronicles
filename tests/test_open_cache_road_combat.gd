extends SceneTree

const Base = preload("res://tests/fixtures/combat_vis1_world.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Screen = preload("res://ui/field_screen.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("CACHE-ROAD: " + message)

func _init() -> void:
	call_deferred("run")

func payload(world: WorldState, command: String) -> Dictionary:
	var data: Dictionary = {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE", "SHOOT"]:
		data.battle_id = int(world.field_state.battle.id)
		data.turn = int(world.field_state.battle.turn)
	elif command == "CONFIRM": data.receipt = int(world.field_state.receipt)
	return data

func act(world: WorldState, command: String) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload(world, command)))

func skip_encounters(world: WorldState) -> bool:
	for stop: int in range(12):
		if world.active_encounter == null: return true
		var choice: StringName = &"LEAVE"
		if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
		elif world.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
		var skipped: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice))
		if not skipped.success: return false
		var onward: Dictionary = engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result))
		if not onward.success: return false
	return false

func opened_camp(site: String = "opened") -> WorldState:
	var world: WorldState = Base.create("shed", false, engine, false, "rusted_knife" if site == "partial" else "sledgehammer")
	# Preparation uses the existing reviewed character/equipment fixture. The journey
	# and cache/combat actions below all commit through the real authority.
	world.player.inventory.set_amount("water", 5)
	world.player.inventory.set_amount("food", 5)
	world.player.inventory.set_amount("scrap", 3)
	check(act(world, "CRAFT").success, "real home crowbar crafting")
	if site != "fresh":
		check(act(world, "START").success, "real home dog battle")
		check(act(world, "ATTACK").success, "real dog attack")
		if site == "partial": check(act(world, "FLEE").success, "real partial dog escape")
		check(act(world, "CONFIRM").success, "confirm home fight")
	if site == "opened":
		check(act(world, "OPEN").success, "real home cache opening")
		check(act(world, "CONFIRM").success, "confirm home loot")
		check(world.field_state.opened and world.field_state.enemy_hp == 0, "home site is permanently cleared/opened")
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success, "real first travel leg")
	check(skip_encounters(world), "continue actual first-leg encounters")
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well", "WILDERNESS")).success, "real wilderness route")
	for stop: int in range(12):
		if world.active_encounter == null: break
		if String(world.active_encounter.context.get("place_id", "")) == "place:hammer_camp":
			check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, &"FIGHT")).success, "real camp fight handoff")
			return world
		var choice: StringName = &"LEAVE"
		if world.active_encounter.encounter_type == TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
		elif world.active_encounter.encounter_type == TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
		check(engine.commit_player_intent(world, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice)).success, "skip actual preceding encounter")
		check(engine.commit_player_intent(world, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result)).success, "continue into camp")
	check(false, "authored camp reached")
	return world

func parity(world: WorldState, twin: WorldState, label: String) -> void:
	check(world.to_canonical_json().sha256_text() == twin.to_canonical_json().sha256_text(), label + " twin SHA-256")
	check(engine.validate_invariants(world) == "" and engine.validate_invariants(twin) == "", label + " global invariants")
	var saved: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
	check(saved.success and saved.world.to_canonical_json() == world.to_canonical_json(), label + " checked persistence")

func run() -> void:
	root.size = Vector2i(1280, 720)
	for outcome: String in ["VICTORY", "ESCAPED", "DEFEAT"]:
		var world: WorldState = opened_camp()
		check(engine.validate_invariants(world) == "", "opened cache permits a living road opponent")
		if engine.validate_invariants(world) != "":
			print("CACHE-ROAD pre-fix reproduction: assertions=%d failures=%d" % [assertions, failures])
			quit(1)
			return
		check(world.field_state.battle.site_enemy_hp == 0 and world.field_state.enemy_hp == 16, "separate reviewed home/road health")
		var restored: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		check(restored.success, "active camp save loads")
		var twin: WorldState = restored.world
		var ui: Control = Screen.new()
		root.add_child(ui)
		ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.setup(world, engine)
		ui.reduce_motion.button_pressed = true
		await process_frame
		check(not ui.buttons.ATTACK.disabled and not ui.buttons.DEFEND.disabled and not ui.buttons.FLEE.disabled, "legal camp commands are actually enabled")
		check(ui.buttons.SHOOT.disabled, "unowned gun remains locked")
		var stale: Dictionary = payload(world, "ATTACK")
		for turn: int in range(30):
			if world.field_state.battle.is_empty(): break
			var command: String = "FLEE" if outcome == "ESCAPED" else ("DEFEND" if outcome == "DEFEAT" else "ATTACK")
			var intent: Dictionary = ui.payload_for(command)
			check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, intent)).success, "direct checked-load camp command")
			await ui.perform(intent)
			parity(world, twin, "camp turn")
		check(world.field_state.battle.is_empty() and world.field_state.receipt >= 0, "finite road result")
		var receipt: Dictionary = world.event_log[world.field_state.receipt].payload
		check(receipt.outcome == outcome and receipt.source == "road" and receipt.site_enemy_hp == 0, "specified result retains home-health receipt")
		var before: String = world.to_canonical_json()
		check(not engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, stale)).success and world.to_canonical_json() == before, "stale attack refuses atomically")
		var confirm: Dictionary = ui.payload_for("CONFIRM")
		check(engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, confirm)).success, "direct road confirmation")
		await ui.perform(confirm)
		await process_frame
		parity(world, twin, "confirmed journey")
		check(world.field_state.opened and world.field_state.enemy_hp == 0, "confirmation restores cleared home site without new loot")
		check(skip_encounters(world) and skip_encounters(twin), "finish resumed real journey")
		parity(world, twin, "arrival")
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		check(life.status == NpcLifeState.Status.SETTLED and life.population_container_id == &"settlement:dry_well", "arrival preserved")
		if is_instance_valid(ui): ui.queue_free()
		await process_frame
		# Old road saves lacked the new snapshot; opened home is independently known0.
		var legacy: WorldState = opened_camp()
		legacy.field_state.battle.erase("site_enemy_hp")
		check(WorldState.from_json_checked(legacy.to_canonical_json()).success, "legacy opened-cache road battle remains loadable")
		check(act(legacy, "FLEE").success and act(legacy, "CONFIRM").success and legacy.field_state.enemy_hp == 0, "legacy opened-home restoration")
		# Forged home state/metadata must still fail closed.
		var bad: WorldState = opened_camp()
		bad.field_state.battle.site_enemy_hp = 1
		check(not WorldState.from_json_checked(bad.to_canonical_json()).success, "opened-home positive snapshot rejected")
		bad.field_state.battle.site_enemy_hp = 0.5
		check(not WorldState.from_json_checked(bad.to_canonical_json()).success, "fractional home snapshot rejected")
	for site: String in ["fresh", "partial", "cleared"]:
		var expected: int = 6 if site == "fresh" else (3 if site == "partial" else 0)
		var world: WorldState = opened_camp(site)
		check(not world.field_state.opened and world.field_state.battle.site_enemy_hp == expected, "independent original dog-health specification")
		var loaded: Dictionary = WorldState.from_json_checked(world.to_canonical_json())
		check(loaded.success, "unopened road save loads")
		var twin: WorldState = loaded.world
		check(act(world, "FLEE").success and act(twin, "FLEE").success, "unopened road escape")
		parity(world, twin, "unopened result")
		check(act(world, "CONFIRM").success and act(twin, "CONFIRM").success, "unopened road confirmation")
		check(not world.field_state.opened and world.field_state.enemy_hp == expected, "exact original dog health restored")
		parity(world, twin, "unopened restored home")
	# The repair permits only real road contexts, not a positive opened field site.
	var forged: WorldState = opened_camp()
	forged.field_state.battle.source = "field"
	check(not WorldState.from_json_checked(forged.to_canonical_json()).success, "forged field source remains rejected")
	var legacy_receipt: WorldState = opened_camp()
	check(act(legacy_receipt, "FLEE").success, "legacy receipt preparation")
	legacy_receipt.event_log[legacy_receipt.field_state.receipt].payload.erase("site_enemy_hp")
	check(WorldState.from_json_checked(legacy_receipt.to_canonical_json()).success and act(legacy_receipt, "CONFIRM").success and legacy_receipt.field_state.enemy_hp == 0, "legacy opened-home receipt remains loadable and confirmable")
	print("Open cache road combat: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
