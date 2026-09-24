extends SceneTree

const Intent = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")

var engine := SimulationEngine.new()
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
		print("FAIL: " + message)

func created() -> WorldState:
	var world := S1WorldData.create_s1_world()
	var result := engine.commit_character_creation(world, Intent.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Field Medic",
		"age": 25, "background_id": "MECHANIC", "trait_ids": [],
	}))
	check(result.success, "character is created through authority")
	world.player.money = 200 # Controlled purchase funding; shop stock and item transfer stay authoritative.
	return world

func act(world: WorldState, command: String) -> Dictionary:
	var payload := {"command": command}
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		payload.battle_id = world.field_state.battle.id
		payload.turn = world.field_state.battle.turn
	elif command == "CONFIRM":
		payload.receipt = world.field_state.receipt
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, payload))

func wounded(world: WorldState) -> void:
	check(act(world, "START").success, "real field battle starts")
	check(act(world, "ATTACK").success, "enemy deals real damage")
	check(act(world, "FLEE").success, "escape retains injury")
	check(act(world, "CONFIRM").success, "battle result is acknowledged")
	check(world.player.field_kit.hp < Field.MAX_HP, "real damage remains before treatment")

func reject_without_change(world: WorldState, command: String) -> void:
	var before := world.to_canonical_json().sha256_text()
	check(not act(world, command).success, "invalid treatment is rejected")
	check(world.to_canonical_json().sha256_text() == before, "rejected treatment changes no world state")

func track() -> Dictionary:
	var world := created()
	var initial_day: int = world.current_day
	var initial_xp: int = world.player.xp
	reject_without_change(world, "TREAT") # Full health, no kit.
	var buy := engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"first_aid_kit", 3))
	check(buy.success and world.player.item_inventory.quantity("first_aid_kit") == 3, "medical supplies come through the real market")
	wounded(world)
	var hp_before: int = world.player.field_kit.hp
	var treated := act(world, "TREAT")
	check(treated.success and world.player.field_kit.hp == mini(Field.MAX_HP, hp_before + 4), "treatment heals only missing real HP")
	check(world.player.item_inventory.quantity("first_aid_kit") == 2 and world.current_day == initial_day, "one kit is consumed without passing a day")
	check(treated.get("skill_practice", {}).get("skill_id", "") == "MEDICINE", "actual treatment awards medicine practice")
	check(world.event_log.back().payload.get("healed", 0) == Field.MAX_HP - hp_before, "ledger records actual recovered HP")
	check(engine.validate_invariants(world) == "", "treatment preserves world invariants")
	reject_without_change(world, "TREAT") # Full health with kit still held.
	wounded(world)
	var second := act(world, "TREAT")
	check(second.success and not second.has("skill_practice"), "second treatment in one day heals but cannot farm practice")
	check(world.player.item_inventory.quantity("first_aid_kit") == 1, "second treatment still spends a kit")
	check(engine.execute_player_wait(world).success, "next practice day advances by real wait")
	wounded(world)
	var third := act(world, "TREAT")
	check(third.success and third.get("skill_practice", {}).get("rank_up", false), "second practice day advances Medicine rank 0 to 1")
	check(world.player.capability.get_skill_rank("MEDICINE").rank == 1, "capability profile owns earned rank")
	check(world.player.item_inventory.quantity("first_aid_kit") == 0 and world.player.xp == initial_xp, "kits run out and Medicine does not mint Level XP")
	var loaded := WorldState.from_json_checked(world.to_canonical_json())
	check(loaded.success and loaded.world.to_canonical_json() == world.to_canonical_json(), "treatment survives save and load")
	check(engine.validate_invariants(world) == "", "full treatment path preserves global invariants")
	return {"world": world, "sha": world.to_canonical_json().sha256_text()}

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var no_kit := created()
	wounded(no_kit)
	reject_without_change(no_kit, "TREAT")
	var battle := created()
	check(act(battle, "START").success, "battle fixture starts")
	reject_without_change(battle, "TREAT")
	var first := track()
	var second := track()
	check(first.sha == second.sha, "two-track full-world SHA-256 replay")
	print("S5-C3 treatment replay SHA-256: " + String(first.sha))
	var tampered: Dictionary = first.world.to_dict().duplicate(true)
	for index in range(tampered.events.size()):
		if tampered.events[index].type == "FIELD_ACTION" and tampered.events[index].payload.get("command") == "TREAT":
			tampered.events[index].payload.healed = 0
			break
	check(not WorldState.from_dict_checked(tampered).success, "treatment receipt with zero healing fails load")
	check(not WorldState.from_json_checked(JSON.stringify(tampered)).success, "treatment receipt corruption fails JSON load")
	var wrong_skill: Dictionary = first.world.to_dict().duplicate(true)
	for index in range(wrong_skill.events.size()):
		if wrong_skill.events[index].type == "FIELD_ACTION" and wrong_skill.events[index].payload.get("command") == "TREAT" and wrong_skill.events[index].payload.has("skill_practice"):
			wrong_skill.events[index].payload.skill_practice.skill_id = "MELEE"
			break
	check(not WorldState.from_dict_checked(wrong_skill).success, "treatment cannot claim unrelated skill practice")
	var visual := created()
	var bought := engine.commit_player_intent(visual, PlayerIntent.create_buy_item(visual.player.npc_id, &"first_aid_kit", 1))
	check(bought.success, "visual fixture obtains a kit")
	wounded(visual)
	var screen = preload("res://ui/field_screen.gd").new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var before_setup := visual.to_canonical_json().sha256_text()
	screen.setup(visual, engine)
	check(visual.to_canonical_json().sha256_text() == before_setup, "opening treatment screen leaves world unchanged")
	check(screen.buttons.has("TREAT") and not screen.buttons.TREAT.disabled, "owned medkit offers an enabled treatment command")
	screen.perform({"command": "TREAT"})
	await process_frame
	check(screen.growth_notice_label.visible and screen.growth_notice_label.text.contains("生命 +") and screen.growth_notice_label.text.contains("醫療練習 +1"), "visible feedback names actual heal and skill award")
	if "--capture" in OS.get_cmdline_user_args():
		var folder := OS.get_user_data_dir().path_join("captures/c3-treatment")
		DirAccess.make_dir_recursive_absolute(folder)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1152, 648)]:
			root.size = viewport_size
			for frame in range(8):
				await process_frame
			var image_path := folder.path_join("field_treatment_%dx%d.png" % [viewport_size.x, viewport_size.y])
			check(root.get_texture().get_image().save_png(image_path) == OK, "renderer saves treatment screen at %dx%d" % [viewport_size.x, viewport_size.y])
			print("CAPTURED " + image_path)
	screen.queue_free()
	await process_frame
	print("S5-C3 field treatment: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
