extends SceneTree
const Fixture = preload("res://tests/fixtures/char2_world.gd")
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Unique = preload("res://tests/fixtures/gear2e_world.gd")
const Gear = preload("res://ui/gear_presentation.gd")
const Character = preload("res://ui/character_presentation.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
var assertions: int = 0
var failures: int = 0
var engine := SimulationEngine.new()

func _init() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("CHAR-2: " + text)

func run() -> void:
	var a: WorldState = Fixture.geared()
	var loaded: Dictionary = WorldState.from_json_checked(a.to_canonical_json())
	check(loaded.success, "actual equipment/tracked pursuit loads")
	var b: WorldState = loaded.world
	var before: String = a.to_canonical_json()
	var data: Dictionary = Gear.project(a)
	check(data.details.quickdraw_police_revolver.candidate.melee == 2 and data.details.quickdraw_police_revolver.candidate.shot == 7, "mechanic neutral damage is 2 melee / 7 shot, no quality multiplier or turn-one quickdraw")
	check(data.details.short_shotgun.current.shot == 7 and data.details.short_shotgun.candidate.shot == 10, "comparison exposes seven versus ten shot damage")
	check(data.details.short_shotgun.candidate.ammo == 1 and data.details.short_shotgun.candidate.lines.any(func(t: String) -> bool: return t.contains("霰彈") and t.contains("×1")), "uses real distinct ammunition and consumption")
	check(data.tools[0].rank == 2 and data.tools[0].grade == 3 and data.tools[1].rank == 1 and data.tools[1].grade == 1, "physical tools and knowledge remain separate")
	check(data.aspiration.id == "rumor:armory" and data.experiences.is_empty(), "heard/selected aim, no invented experiences")
	check(data.details.expedition_travel_backpack.candidate.properties.size() == 2, "rare properties remain real fixed descriptions")
	check(a.to_canonical_json() == before, "opening all comparisons changes no world field or receipt")
	data.details.short_shotgun.candidate.lines.clear()
	data.aspiration.title = "tampered"
	check(not Gear.project(a).details.short_shotgun.candidate.lines.is_empty() and Gear.project(a).aspiration.title != "tampered", "nested projection detached")
	var requests: Array = []
	var action := func(id: String, slot: String):
		requests.append([id, slot])
		return engine.commit_player_intent(a, PlayerIntent.create_equip_item(a.player.npc_id, StringName(id), slot))
	var sheet := Sheet.new()
	root.add_child(sheet)
	sheet.setup(Character.project(a), PlayerUIProjection.project(a).player, action)
	check(sheet.skill_rows.size() == 10 and sheet.tool_labels.MECHANICS.text.contains("知識 2 · 工具 3"), "real skills/tools visible")
	check(sheet.aspiration_label.text.contains("軍械庫"), "selected aim visible")
	sheet.detail_buttons.short_shotgun.pressed.emit()
	await process_frame
	check(is_instance_valid(sheet.item_detail) and sheet.item_detail.visible, "actual inspect button opens detail")
	check(sheet.item_detail.get_ok_button().text.contains("主手"), "selected compatible item exposes authoritative equip")
	check(a.to_canonical_json() == before, "detail popup preserves world")
	sheet.item_detail.confirmed.emit()
	check(requests == [["short_shotgun", "main_hand"]] and a.player.equipment.equipped_item("main_hand") == "short_shotgun", "detail action sends existing intent and commits equipment")
	check(engine.commit_player_intent(b, PlayerIntent.create_equip_item(b.player.npc_id, &"short_shotgun", "main_hand")).success, "reloaded track equips")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "dual-track SHA-256 after actual UI-equivalent action")
	check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants")
	sheet.queue_free()
	await process_frame
	var shared: WorldState = Fixture.shared_journey()
	check(Gear.project(shared).experiences.any(func(t: String) -> bool: return t.contains("阿扳") and t.contains("25")), "actual completed shared recovery visible")
	var shared_load: Dictionary = WorldState.from_json_checked(shared.to_canonical_json())
	check(shared_load.success and Gear.project(shared_load.world) == Gear.project(shared), "receipt experiences stable after load")
	var unique: WorldState = Unique.engineer_site()
	var unique_before: String = unique.to_canonical_json()
	check(Gear.project(unique).details.engineer_precision_tools.slot == "" and Gear.project(unique).tools[0].rank == 2, "unique held tool adds no fake equip slot or knowledge")
	check(not Gear.project(unique).experiences.any(func(t: String) -> bool: return t.contains("信任——")), "small positive local trust does not invent trusted tier")
	var dead_ui := PlayableShell.new()
	root.add_child(dead_ui)
	dead_ui.setup(unique, engine)
	dead_ui._show_character()
	await process_frame
	for child in dead_ui.get_children():
		if child.get_script() == Sheet:
			child.show_item_detail("engineer_precision_tools")
			check(child.item_detail.get_ok_button().text == "返回人物", "held unique tool has no fake equip command")
			child.item_detail.canceled.emit()
	check(unique.to_canonical_json() == unique_before, "locked journey inspection and cancel do not spend day")
	dead_ui.queue_free()
	await process_frame
	var overloaded: WorldState = Base.fresh("settlement:new_hope")
	check(engine.commit_player_intent(overloaded, PlayerIntent.create_buy_item(overloaded.player.npc_id, &"ballistic_vest", 1)).success, "buy real candidate armor")
	for resource: String in ["water", "food", "scrap", "fuel"]: overloaded.player.inventory.set_amount(resource, 20 if resource == "water" else 0)
	var locked_before: String = overloaded.to_canonical_json()
	var locked_shell := PlayableShell.new()
	root.add_child(locked_shell)
	locked_shell.setup(overloaded, engine)
	locked_shell._show_character()
	await process_frame
	for child in locked_shell.get_children():
		if child.get_script() != Sheet: continue
		child.show_item_detail("ballistic_vest")
		child.item_detail.confirmed.emit()
		check(child.action_notice_label.visible and child.action_notice_label.text.contains("超載"), "authority refusal visible in actual sheet")
	check(overloaded.to_canonical_json() == locked_before and engine.validate_invariants(overloaded) == "", "refused UI equip atomically preserves world")
	locked_shell.queue_free()
	await process_frame
	var seen: WorldState = Unique.workshop()
	check(Base.answer(seen, &"LEAVE").success, "leave actual workshop")
	Unique.seek(seen, "place:hammer_camp")
	check(Base.answer(seen, &"FIGHT").success, "start actual heavy-raider battle")
	check(Gear.project(seen).experiences.any(func(t: String) -> bool: return t.contains("見過重裝掠奪者")), "actual encounter adds seen experience before result")
	var empty: Dictionary = Gear.project(Base.fresh())
	check(empty.tools[0].grade == 0 and empty.aspiration.is_empty() and empty.experiences.is_empty(), "empty state honest")
	var no_player: WorldState = S1WorldData.create_s1_world()
	check(Gear.project(no_player).details.is_empty(), "no player projection safe")
	await process_frame
	print("CHAR-2: assertions=%d failures=%d" % [assertions, failures])
	quit(0 if failures == 0 else 1)
