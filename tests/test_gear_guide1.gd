extends SceneTree
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Journey = preload("res://tests/fixtures/gear2e_world.gd")
const Guidance = preload("res://ui/item_guidance.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
const Rumors = preload("res://simulation/rumors.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("GEAR-GUIDE-1: " + label)
func run() -> void:
	root.size = Vector2i(1152, 648)
	var hidden: WorldState = Base.fresh("settlement:gray_valley")
	check(Guidance.project(hidden, "military_gas_mask").is_empty() and Guidance.project(hidden, "old_world_saber").is_empty(), "unheld unheard unique information hidden")
	check(Guidance.project(hidden, "unknown").is_empty(), "unknown id has no invented guide")
	var a: WorldState = Journey.checkpoint()
	check(Base.answer(a, &"RECOVER_GAS_MASK").success, "actual mask retrieval")
	check(PlayerUIProjection.project(a).encounter_result.place_note.contains("改追"), "retrieval receipt explains required tracking switch")
	Journey.finish(a)
	Base.resupply(a)
	var loaded: Dictionary = WorldState.from_json_checked(a.to_canonical_json())
	check(loaded.success, "checked mask journey save")
	var b: WorldState = loaded.world
	var before: String = a.to_canonical_json()
	var mask: Dictionary = Guidance.project(a, "military_gas_mask")
	check(mask.source == "一般商店沒有常備供應。" and mask.pursuit.contains("改選") and mask.pursuit.contains("荒野路第一天"), "known mask guide has correct route and voluntary pursuit")
	check(Rumors.progress(a, "rumor:gas_mask").next.contains("改追"), "settled rumor explains switch")
	var tool: Dictionary = Guidance.project(a, "repair_toolbox")
	check(tool.source.contains("新希望、灰谷、乾井") and tool.source.contains("實際庫存") and tool.use.contains("保留"), "public supply and reusable tool guidance without stock promise")
	check(Guidance.project(a, "first_aid_kit").is_empty(), "no unheld ordinary item detail")
	var shell: PlayableShell = PlayableShell.new()
	root.add_child(shell)
	shell.setup(a, engine)
	shell._show_character()
	await process_frame
	var sheet: AcceptDialog
	for child: Node in shell.get_children():
		if child.get_script() == Sheet: sheet = child as AcceptDialog
	sheet.show_item_detail("military_gas_mask")
	await process_frame
	check(sheet.item_guide_label.text.contains("2廢料") and sheet.item_rumor_button != null, "actual detail displays guide and rumor action")
	var compared: HBoxContainer = sheet.item_guide_label.get_parent().get_child(0) as HBoxContainer
	check(compared.size.y > 160 and compared.get_child(0).get_child(0).get_child_count() >= 6, "comparison body retains visible height and actual stat labels inside detail scroll")
	check(a.to_canonical_json() == before, "browsing details preserves entire world")
	sheet.item_rumor_button.pressed.emit()
	check(not sheet.visible and not sheet.item_detail.visible, "exclusive details and sheet released before rumor window")
	await process_frame
	await process_frame
	check(is_instance_valid(shell.rumor_window) and shell.rumor_window.visible and a.to_canonical_json() == before, "actual rumor entry does not choose or mutate")
	shell.rumor_window.rumor_buttons["rumor:engineer_tools"].pressed.emit()
	await process_frame
	await process_frame
	check(Rumors.tracked(a) == "rumor:engineer_tools", "player explicitly selects new pursuit through real button")
	check(engine.commit_player_intent(b, PlayerIntent.create_track_rumor(b.player.npc_id, "rumor:engineer_tools")).success, "direct twin track intent")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "UI and checked-load twin tracking SHA")
	shell.queue_free()
	await process_frame
	for world: WorldState in [a, b]:
		check(engine.commit_player_intent(world, PlayerIntent.create_travel(world.player.npc_id, &"settlement:dry_well", "WILDERNESS")).success, "guided real journey")
		Journey.seek(world, "place:toxic_workshop")
		check(Base.answer(world, &"ENTER_TOXIC_WORKSHOP").success, "real guided acquisition")
	check(a.player.item_inventory.contains("military_gas_mask") and a.player.item_inventory.contains("engineer_precision_tools"), "mask reusable and tools acquired")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "dual journey SHA")
	check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants")
	check(WorldState.from_json_checked(a.to_canonical_json()).success, "guided outcome checked save")
	print("GEAR-GUIDE-1: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
