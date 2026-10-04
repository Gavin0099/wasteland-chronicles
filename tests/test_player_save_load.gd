extends "res://tests/test_two_towns.gd"

const Store = preload("res://game_data/journey_save_store.gd")
const SaveDialog = preload("res://ui/components/save_game_dialog.gd")
var slot_path: String = "user://tests/save1/journey.json"
var store: RefCounted = Store.new(slot_path)

class FailedPromotion:
	extends "res://game_data/journey_save_store.gd"
	var fail_restore: bool = false
	func move_file(source: String, destination: String) -> Error:
		# Fault injection at the real filesystem handoff; assertions below inspect
		# actual bytes and reload through the ordinary Store, not a mock decoder.
		if source == path + ".tmp" or (fail_restore and source == path + ".bak"):
			return ERR_FILE_CANT_WRITE
		return super.move_file(source, destination)

func clear_slot() -> void:
	DirAccess.make_dir_recursive_absolute(store.path.get_base_dir())
	for path: String in [store.path, store.path + ".tmp", store.path + ".bak"]:
		if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
			check(DirAccess.remove_absolute(path) == OK, "remove only owned test slot/temp")

func write_raw(raw: String) -> void:
	var file: FileAccess = FileAccess.open(store.path, FileAccess.WRITE)
	check(file != null, "actual fixture disk open")
	if file == null: return
	file.store_string(raw)
	file.close()

func disk_copy(world: WorldState, label: String) -> WorldState:
	var before: String = world.to_canonical_json()
	check(store.save_game(world).success, label + " actual disk save")
	check(FileAccess.get_file_as_string(store.path) == before, label + " exact canonical disk bytes")
	check(world.to_canonical_json() == before, label + " save read-only")
	var loaded: Dictionary = store.load_game()
	check(loaded.success, label + " actual disk reload")
	if not loaded.success: return world.duplicate_state()
	parity(world, loaded.world, label + " uninterrupted/disk-resumed")
	return loaded.world

func storage_contract() -> void:
	clear_slot()
	check(store.load_game().error == "EMPTY", "missing distinct from corruption")
	var world: WorldState = fresh_towns("settlement:gray_valley")
	var twin: WorldState = disk_copy(world, "settled five-town save")
	pair_intent(world, twin, PlayerIntent.create_wait(world.player.npc_id), "resume real wait")
	twin = disk_copy(world, "overwrite previous slot")
	var original: String = FileAccess.get_file_as_string(store.path)
	check(DirAccess.make_dir_absolute(store.path + ".tmp") == OK, "real unwritable staging fixture")
	check(not store.save_game(world).success, "write failure refused")
	check(FileAccess.get_file_as_string(store.path) == original, "failed save retains prior exact bytes")
	check(DirAccess.remove_absolute(store.path + ".tmp") == OK, "remove owned staging directory")
	var changed: WorldState = world.duplicate_state()
	check(engine.commit_player_intent(changed, PlayerIntent.create_wait(changed.player.npc_id)).success, "different new progress for replacement failure")
	var fault: RefCounted = FailedPromotion.new(slot_path)
	check(not fault.save_game(changed).success, "promotion failure after old slot moved aside")
	check(FileAccess.get_file_as_string(store.path) == original and not FileAccess.file_exists(store.path + ".bak"), "failed promotion restores exact prior slot")
	fault.fail_restore = true
	check(not fault.save_game(changed).success, "both promotion and restoration failure")
	check(not FileAccess.file_exists(store.path) and FileAccess.get_file_as_string(store.path + ".bak") == original, "restoration failure retains exact backup bytes")
	var recovered: Dictionary = Store.new(slot_path).load_game()
	check(recovered.success and recovered.recovered, "new store/restart recovers interrupted replacement")
	parity(world, recovered.world, "restart recovery preserves prior snapshot")
	check(store.save_game(world).success and not FileAccess.file_exists(store.path + ".bak"), "saving after interrupted recovery commits new slot safely")
	check(not store.save_game(PlayableWorld.create_world()).success, "uncreated player cannot save")
	check(FileAccess.get_file_as_string(store.path) == original, "invalid world cannot overwrite")
	var bad_population: Dictionary = world.to_dict()
	bad_population.total_initial_population = int(bad_population.total_initial_population) + 1
	var bad_ledger: Dictionary = world.to_dict()
	bad_ledger.events = []
	var bad_rank: String = original.replace('"MECHANICS": 2', '"MECHANICS": 2.0')
	check(bad_rank != original, "independent raw rank-token negative fixture applied")
	for raw: String in ["{", "null", "{}", bad_rank, JSON.stringify(bad_population), JSON.stringify(bad_ledger), PlayableWorld.create_world().to_canonical_json()]:
		write_raw(raw)
		var before: String = world.to_canonical_json()
		check(not store.load_game().success, "corrupt/rank/invariant/ledger/no-player refused")
		check(FileAccess.get_file_as_string(store.path) == raw and world.to_canonical_json() == before, "refusal preserves source and live world")
	write_raw(original)
	parity(world, twin, "failed storage boundaries")
	clear_slot()
	check(DirAccess.make_dir_absolute(store.path) == OK, "unreadable slot directory fixture")
	check(store.load_game().error == "UNREADABLE" and not store.save_game(world).success, "unreadable destination and failed rename truthful")
	check(DirAccess.dir_exists_absolute(store.path), "rename failure retains prior destination")
	clear_slot()

func travel_replay() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:new_hope")).success, "real road starts")
	check(world.active_encounter != null, "actual travel interruption fixture")
	if world.active_encounter == null: return
	var twin: WorldState = disk_copy(world, "active travel encounter")
	for stop: int in range(12):
		if world.active_encounter == null: break
		var choice: StringName = &"LEAVE"
		match world.active_encounter.encounter_type:
			TravelEncounter.BANDIT_AMBUSH: choice = &"FLEE_ROAD"
			TravelEncounter.ROCKSLIDE: choice = &"DETOUR"
			TravelEncounter.ROADBLOCK: choice = &"PAY"
		pair_intent(world, twin, PlayerIntent.create_resolve_encounter(world.player.npc_id, choice), "resume saved real road choice")
		check(world.pending_encounter_result >= 0, "road receipt awaits explicit confirmation")
		twin = disk_copy(world, "unconfirmed road receipt")
		pair_intent(world, twin, PlayerIntent.create_continue_journey(world.player.npc_id, world.pending_encounter_result), "confirm saved receipt once")
	check(world.active_encounter == null and world.pending_encounter_result < 0, "interrupted journey completes identically")
	parity(world, twin, "resumed road arrival")

func settled_systems() -> void:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	world.player.money = 200 # Explicit funded-service fixture, no income claim.
	check(engine.commit_player_intent(world, PlayerIntent.create_hire_companion(world.player.npc_id, "companion:abban")).success, "actual companion hired before save")
	check(engine.commit_player_intent(world, PlayerIntent.create_respond_companion_request(world.player.npc_id, "ACCEPT")).success, "actual companion shared request accepted")
	var jobs: Array = Board.postings(world, &"settlement:gray_valley")
	check(not jobs.is_empty(), "actual local board fixture")
	check(engine.commit_player_intent(world, PlayerIntent.create_accept_quest(world.player.npc_id, jobs[0].definition.id)).success, "real accepted contract before save")
	check(world.player.item_inventory.pickup_item("rusted_knife", 1).success, "owned equipment fixture")
	check(engine.commit_player_intent(world, PlayerIntent.create_equip_item(world.player.npc_id, &"rusted_knife", "main_hand")).success, "actual equipment intent before save")
	var twin: WorldState = disk_copy(world, "companion/history/accepted contract/equipment")
	check(preload("res://simulation/party.gd").current(twin) == "companion:abban" and twin.accepted_jobs.has(jobs[0].definition.id), "loaded companion and pinned contract observable")
	pair_intent(world, twin, PlayerIntent.create_wait(world.player.npc_id), "resumed settled systems actual day")
	parity(world, twin, "derived faction/jobs/companion projections after reload")

func field_world() -> WorldState:
	var world: WorldState = fresh_towns("settlement:gray_valley")
	world.player.inventory.scrap = 3 # Owned material fixture; crafting itself is real.
	check(act(world, "CRAFT").success and act(world, "EQUIP").success and act(world, "START").success, "real equipped home battle")
	check(act(world, "ATTACK").success, "real first turn before save")
	check(world.field_state.battle.turn == 2 and world.player.field_kit.hp == 9, "independent home-battle turn fixture")
	return world

func battle_replay() -> void:
	var world: WorldState = field_world()
	var twin: WorldState = disk_copy(world, "battle turn two")
	for name: String in ["DEFEND", "ATTACK"]:
		check(act(world, name).success and act(twin, name).success, "real resumed home battle " + name)
		parity(world, twin, "resumed turn " + name)
	check(world.field_state.receipt >= 0, "victory awaiting confirmation")
	twin = disk_copy(world, "unconfirmed field victory")
	var xp: int = world.player.xp
	var receipt: int = world.field_state.receipt
	check(act(world, "CONFIRM").success and act(twin, "CONFIRM").success, "saved field result acknowledged")
	parity(world, twin, "acknowledgement after restart")
	check(world.player.xp == xp and not engine.commit_player_intent(twin, PlayerIntent.create_field_action(twin.player.npc_id, {"command": "CONFIRM", "receipt": receipt})).success, "no reward replay/second acknowledgement")
	# Existing legacy three-town hunt saves also remain loadable mid-road battle.
	world = battle_world(SPECS[0], "sledgehammer")
	twin = disk_copy(world, "legacy roadside hunt battle")
	for turn: int in range(8):
		if world.field_state.battle.is_empty(): break
		check(act(world, "ATTACK").success and act(twin, "ATTACK").success, "real resumed hunt attack")
		parity(world, twin, "disk-resumed hunt")
	twin = disk_copy(world, "roadside bounty result")
	check(act(world, "CONFIRM").success and act(twin, "CONFIRM").success, "saved hunt result resumes road")
	parity(world, twin, "resumed hunt travel")
	world = fresh_towns("settlement:gray_valley")
	world.player.inventory.water = 0 # Explicit depletion fixture; death is real daily survival.
	world.player.inventory.food = 0
	for day: int in range(40):
		if not world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive(): break
		var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if life.status != NpcLifeState.Status.IN_TRANSIT:
			var destination: StringName = &"settlement:new_hope" if life.population_container_id == &"settlement:gray_valley" else &"settlement:gray_valley"
			check(engine.begin_player_travel(world, PlayerIntent.create_travel(world.player.npc_id, destination)).success, "actual engine deprived journey")
		check(engine.execute_player_wait(world).success, "actual engine deprived survival day")
	check(not world.npc_life_state_registry.get_life_state(world.player.npc_id).is_alive(), "death before save is authoritative")
	twin = disk_copy(world, "dead player and death receipt")
	check(not twin.npc_life_state_registry.get_life_state(twin.player.npc_id).is_alive() and SaveDialog.describe(twin).contains("旅程已結束"), "load/menu do not resurrect player")

func frames() -> void:
	for tick: int in range(3): await process_frame

func new_main() -> Node:
	var main: Node = load("res://main.tscn").instantiate()
	main.save_store = store
	root.add_child(main)
	return main

func find_command(parent: Node, text: String) -> Button:
	if parent is Button and parent.text == text: return parent
	for child: Node in parent.get_children():
		var found: Button = find_command(child, text)
		if found != null: return found
	return null

func ui_contract() -> void:
	clear_slot()
	var main: Node = new_main()
	await frames()
	check(main.world.player == null and main.world.settlements.size() == 5 and main.save_dialog.load_button.disabled, "real startup missing-save state")
	main.save_dialog.get_ok_button().pressed.emit()
	await frames()
	check(main.creation.visible and not is_instance_valid(main.save_dialog), "actual New Journey shows creation")
	main.creation.name_input.text = "存檔旅人"
	check(main.creation.submit().success, "actual creation form commit")
	main.creation.enter_button.pressed.emit()
	await frames()
	check(main.shell != null, "actual enter-world button")
	var before: String = main.world.to_canonical_json()
	find_command(main.shell, "存讀檔").pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == before and main.save_dialog.load_button.disabled, "real toolbar menu is read-only")
	main.save_dialog.save_button.pressed.emit()
	check(main.save_dialog.message.text.begins_with("已存檔") and not main.save_dialog.load_button.disabled, "actual save button writes usable slot")
	check(DirAccess.make_dir_absolute(store.path + ".tmp") == OK, "actual UI save failure fixture")
	main.save_dialog.save_button.pressed.emit()
	check(main.save_dialog.message.text.contains("存檔失敗") and FileAccess.get_file_as_string(store.path) == before, "actual UI reports failed save and retains old slot")
	check(DirAccess.remove_absolute(store.path + ".tmp") == OK, "remove only UI staging fixture")
	main.save_dialog.get_ok_button().pressed.emit()
	await frames()
	check(engine.commit_player_intent(main.world, PlayerIntent.create_wait(main.world.player.npc_id)).success, "real unsaved live progress")
	main.shell.refresh_ui()
	var unsaved: String = main.world.to_canonical_json()
	find_command(main.shell, "存讀檔").pressed.emit()
	main.save_dialog.load_button.pressed.emit()
	await frames()
	check(main.save_dialog.confirmation.visible and main.save_dialog.confirmation.get_cancel_button().has_focus(), "load warns and defaults focus to preserving progress")
	main.save_dialog.confirmation.get_cancel_button().pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == unsaved, "real cancel retains progress")
	main.save_dialog.load_button.pressed.emit()
	await frames()
	write_raw("{")
	main.save_dialog.confirmation.get_ok_button().pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == unsaved and main.shell.world == main.world and main.save_dialog.message.text.contains("目前進度仍保留"), "corruption after confirmation preview cannot hand off")
	write_raw(before)
	main._request_load()
	await frames()
	write_raw(unsaved)
	main.save_dialog.confirmation.get_ok_button().pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == unsaved and main.save_dialog.message.text.contains("存檔已變更"), "valid slot changed after preview cannot silently load different progress")
	write_raw(before)
	main._request_load()
	await frames()
	main.save_dialog.confirmation.get_ok_button().pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == before and main.shell.world == main.world and not is_instance_valid(main.save_dialog), "actual confirmed world/shell replacement")
	main.queue_free()
	await frames()
	# A process interrupted after the old file moved still offers Continue.
	check(DirAccess.rename_absolute(store.path, store.path + ".bak") == OK, "actual interrupted-save restart fixture")
	main = new_main()
	await frames()
	check(not main.save_dialog.load_button.disabled and main.save_dialog.summary.text.contains("已復原"), "recovery source honestly shown at startup")
	main.save_dialog.load_button.pressed.emit()
	await frames()
	check(main.world.to_canonical_json() == before, "actual Continue from recovery retains prior progress")
	main.queue_free()
	await frames()
	# Real restart/Continue restores a battle screen and commands, then its receipt.
	var battle: WorldState = field_world()
	check(store.save_game(battle).success, "restart battle fixture saved")
	main = new_main()
	await frames()
	check(main.save_dialog.load_button.has_focus() and main.save_dialog.summary.text.contains("第 2 回合"), "startup valid slot preview/focus")
	main.save_dialog.load_button.pressed.emit()
	await frames()
	var screen: Control = main.shell.get_node_or_null("FieldScreen")
	check(screen != null and main.world.to_canonical_json() == battle.to_canonical_json(), "Continue reopens real battle without ticking/rewards")
	if screen != null:
		find_command(screen, "存讀檔").pressed.emit()
		await frames()
		check(main.save_dialog != null, "field toolbar save/load reachable")
		main.save_dialog.get_ok_button().pressed.emit()
		await frames()
		check(screen.buttons.ATTACK.disabled == false, "restored battle accepts player action")
	main.queue_free()
	await frames()
	clear_slot()
	write_raw("{")
	main = new_main()
	await frames()
	check(main.save_dialog.load_button.disabled and main.save_dialog.summary.text.contains("不完整"), "corrupt restart truthfully disabled")
	main.save_dialog.get_ok_button().pressed.emit()
	await frames()
	check(FileAccess.get_file_as_string(store.path) == "{", "New Journey does not delete prior slot")
	main.queue_free()
	await frames()
	clear_slot()

func run() -> void:
	root.size = Vector2i(1280, 720)
	storage_contract()
	settled_systems()
	travel_replay()
	battle_replay()
	await ui_contract()
	print("Player save/load: assertions=%d failures=%d" % [assertions, failures])
	quit(1 if failures > 0 else 0)
