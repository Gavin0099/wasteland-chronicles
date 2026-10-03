extends SceneTree
const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Registry = preload("res://simulation/item_registry.gd")
const Art = preload("res://game_data/item_art_references.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
const Guidance = preload("res://ui/item_guidance.gd")
var engine: SimulationEngine = SimulationEngine.new()
var assertions: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("AID-1: " + label)
func act(world: WorldState, fields: Dictionary) -> Dictionary:
	return engine.commit_player_intent(world, PlayerIntent.create_field_action(world.player.npc_id, fields))
func turn(world: WorldState, command: String) -> Dictionary:
	return act(world, {"command": command, "battle_id": int(world.field_state.battle.id), "turn": int(world.field_state.battle.turn)})
func reject(world: WorldState, fields: Dictionary, expected: String) -> void:
	var before: String = world.to_canonical_json()
	var result: Dictionary = act(world, fields)
	check(not result.success and result.error == expected, "specific refusal " + expected)
	check(world.to_canonical_json() == before, "refusal preserves all inventory/HP/day/practice/receipts")
func wounded(world: WorldState) -> void:
	check(act(world, {"command": "START"}).success and turn(world, "ATTACK").success and turn(world, "FLEE").success, "real injury via field battle")
	check(act(world, {"command": "CONFIRM", "receipt": int(world.field_state.receipt)}).success and world.player.field_kit.hp == 8, "actual four HP lost and result acknowledged")
func find_sheet(shell: Node) -> AcceptDialog:
	for child: Node in shell.get_children():
		if child.get_script() == Sheet: return child as AcceptDialog
	return null
func run() -> void:
	root.size = Vector2i(1152,648)
	var definition: Dictionary = Registry.resolve("bandage").definition
	check(definition.display_name_zh == "繃帶" and definition.base_weight == 200 and definition.base_value == 35 and definition.max_stack == 20 and definition.quality == "COMMON", "independent explicit bandage contract")
	check(Art.resolve("item_bandage").path == "res://ui/assets/items/library/supplies/bandage.png", "explicit reused original art")
	var a: WorldState = Base.fresh()
	var money: int = a.player.money
	check(engine.commit_player_intent(a, PlayerIntent.create_buy_item(a.player.npc_id, &"bandage", 2)).success and a.player.money == money - 70, "actual two bandages base70caps")
	check(a.player.item_inventory.quantity("bandage") == 2 and a.player.item_inventory.total_weight_g() == 400, "exact400g supply weight")
	reject(a, {"command": "TREAT", "item_id": "bandage"}, "HEALTH_FULL")
	wounded(a)
	var loaded: Dictionary = WorldState.from_json_checked(a.to_canonical_json())
	check(loaded.success, "checked injury/medical inventory save")
	var b: WorldState = loaded.world
	var before: String = a.to_canonical_json()
	check(Guidance.project(a, "bandage").use.contains("最多2") and a.to_canonical_json() == before, "truthful detached bandage guide")
	var shell: PlayableShell = PlayableShell.new()
	root.add_child(shell)
	shell.setup(a, engine)
	shell._show_character()
	await process_frame
	var sheet: AcceptDialog = find_sheet(shell)
	sheet.inventory_category.select(5)
	sheet.inventory_search.text = "繃帶"
	sheet.inventory_search.text_changed.emit("繃帶")
	check(not sheet.item_use_buttons.bandage.disabled and sheet.item_use_buttons.bandage.text.contains("+2"), "bandage enabled even with no first aid kit")
	for use_index: int in range(2):
		sheet.item_use_buttons.bandage.pressed.emit()
		await process_frame
		await process_frame
		sheet = find_sheet(shell)
		var receipt: Dictionary = a.event_log.back().payload
		check(a.player.field_kit.hp == 10 + use_index * 2 and a.player.item_inventory.quantity("bandage") == 1 - use_index, "real UI consumes1/heals2")
		check(receipt.item_id == "bandage" and receipt.healed == 2 and sheet.action_notice_label.text.contains("繃帶 −1 · 生命 +2"), "specific item/actual healing receipt and visible notice")
		check(receipt.has("skill_practice") == (use_index == 0), "both supplies share once-per-day medicine practice cap")
		check(act(b, {"command": "TREAT", "item_id": "bandage"}).success, "direct checked-load twin treatment")
		check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "UI/loaded-direct twin SHA")
		check(engine.validate_invariants(a) == "" and engine.validate_invariants(b) == "", "both global invariants")
	check(sheet.inventory_state.query == "繃帶" and sheet.inventory_empty.visible, "last consumed item retains matching empty inventory context")
	check(WorldState.from_json_checked(a.to_canonical_json()).success, "new bandage receipts persist")
	shell.queue_free()
	await process_frame
	for world: WorldState in [a,b]:
		check(engine.commit_player_intent(world, PlayerIntent.create_buy_item(world.player.npc_id, &"first_aid_kit", 1)).success, "kit purchased after bandages on same day")
		wounded(world)
		var xp_before: int = world.player.xp
		var kit_use: Dictionary = act(world, {"command":"TREAT"})
		check(kit_use.success and world.player.field_kit.hp == 12 and not kit_use.has("skill_practice") and world.player.xp == xp_before, "mixed bandage/kit use shares daily practice cap and mints no levelXP")
	check(a.to_canonical_json().sha256_text() == b.to_canonical_json().sha256_text(), "mixed legacy/new supplies twin SHA")
	for fault: Variant in [3,0,1.5]:
		var wire: Dictionary = a.to_dict().duplicate(true)
		for evt: Dictionary in wire.events:
			if evt.type == "FIELD_ACTION" and evt.payload.get("command") == "TREAT":
				evt.payload.healed = fault
				break
		check(not WorldState.from_dict_checked(wire).success, "forged bandage healing rejected " + str(fault))
	var legacy: WorldState = Base.fresh()
	var unknown_receipt: Dictionary = a.to_dict().duplicate(true)
	for evt: Dictionary in unknown_receipt.events:
		if evt.type == "FIELD_ACTION" and evt.payload.get("command") == "TREAT":
			evt.payload.item_id = "water"
			break
	check(not WorldState.from_dict_checked(unknown_receipt).success, "unknown treatment receipt item rejected")
	check(engine.commit_player_intent(legacy, PlayerIntent.create_buy_item(legacy.player.npc_id, &"first_aid_kit", 1)).success, "legacy kit real purchase")
	wounded(legacy)
	reject(legacy, {"command": "TREAT", "item_id": "bandage"}, "NEED_BANDAGE")
	for bad: Dictionary in [{"command":"TREAT","item_id":"water"},{"command":"TREAT","item_id":1},{"command":"TREAT","item_id":"bandage","extra":true},{"command":"REST","item_id":"bandage"}]:
		reject(legacy, bad, "INVALID_FIELD_PAYLOAD")
	check(act(legacy, {"command":"TREAT"}).success and legacy.player.field_kit.hp == 12 and legacy.player.item_inventory.quantity("first_aid_kit") == 0, "old one-field TREAT still heals4/consumeskit")
	check(legacy.event_log.back().payload.item_id == "first_aid_kit" and legacy.event_log.back().payload.healed == 4 and WorldState.from_json_checked(legacy.to_canonical_json()).success, "legacy kit receipt/save valid")
	var clamp: WorldState = Base.fresh()
	check(engine.commit_player_intent(clamp, PlayerIntent.create_buy_item(clamp.player.npc_id, &"bandage", 1)).success, "small wound supply")
	clamp.player.field_kit.hp = 11
	check(act(clamp, {"command":"TREAT","item_id":"bandage"}).success and clamp.player.field_kit.hp == 12 and clamp.event_log.back().payload.healed == 1, "missing HP clamps healing to1 without free supply")
	var locked: WorldState = Base.fresh()
	check(engine.commit_player_intent(locked, PlayerIntent.create_buy_item(locked.player.npc_id, &"bandage", 1)).success and act(locked, {"command":"START"}).success, "battle lock fixture")
	reject(locked, {"command":"TREAT","item_id":"bandage"}, "BATTLE_PENDING")
	check(turn(locked,"FLEE").success, "real result pending")
	reject(locked, {"command":"TREAT","item_id":"bandage"}, "FIELD_RESULT_PENDING")
	check(act(locked, {"command":"CONFIRM","receipt":int(locked.field_state.receipt)}).success and engine.commit_player_intent(locked, PlayerIntent.create_travel(locked.player.npc_id, &"settlement:dry_well")).success, "travel encounter lock fixture")
	reject(locked, {"command":"TREAT","item_id":"bandage"}, "ROAD_ENCOUNTER_PENDING")
	check(Base.answer(locked, &"LEAVE").success, "real road result pending")
	reject(locked, {"command":"TREAT","item_id":"bandage"}, "ROAD_ENCOUNTER_PENDING")
	var inventory: ItemInventoryState = ItemInventoryState.new()
	var transit: WorldState = Base.fresh()
	check(engine.begin_player_travel(transit, PlayerIntent.create_travel(transit.player.npc_id, &"settlement:dry_well")).success, "transit without encounter fixture")
	reject(transit, {"command":"TREAT","item_id":"bandage"}, "FIELD_REQUIRES_LIVING_SETTLED_PLAYER")
	check(inventory.add_item("bandage",20).success and inventory.total_weight_g() == 4000, "specified20 stack weighs4kg")
	var bag_before: Dictionary = inventory.to_dict()
	check(not inventory.add_item("bandage",1).success and inventory.to_dict() == bag_before, "stack overflow atomic")
	var full: ItemInventoryState = ItemInventoryState.new()
	check(full.add_item("sledgehammer",1).success and full.add_item("ballistic_vest",1).success and full.add_item("rope",1).success and full.add_item("bandage",16).success and full.total_weight_g() == 11900, "independent11.9kg boundary fixture")
	bag_before = full.to_dict()
	check(not full.add_item("bandage",1).success and full.to_dict() == bag_before, "12.1kg exceeds capacity atomically")
	var old: WorldState = Base.fresh()
	var stock: Dictionary = ItemMarketState.seeded_for("gray_valley").to_dict()
	stock.items = stock.items.filter(func(row: Dictionary) -> bool: return row.item_id != "bandage")
	old.get_settlement(&"settlement:gray_valley").item_market = ItemMarketState.from_dict_checked(stock).market
	old.get_settlement(&"settlement:gray_valley").item_market.set_quantity("wrench",42)
	var old_wire: String = old.to_canonical_json()
	var resumed: Dictionary = WorldState.from_json_checked(old_wire)
	check(resumed.success and resumed.world.to_canonical_json() == old_wire and resumed.world.get_settlement(&"settlement:gray_valley").item_market.quantity("bandage") == 0, "old shop loads byte-identically without new stock")
	for day: int in range(4):
		engine.tick(old)
		engine.tick(resumed.world)
		check(old.to_canonical_json().sha256_text() == resumed.world.to_canonical_json().sha256_text() and engine.validate_invariants(old) == "", "legacy restock dual SHA/global invariants")
		check(old.get_settlement(&"settlement:gray_valley").item_market.quantity("bandage") == [0,1,1,2][day], "ITEM10 medium-supply contract: one per two days")
	check(old.get_settlement(&"settlement:gray_valley").item_market.quantity("bandage") == 2 and old.get_settlement(&"settlement:gray_valley").item_market.quantity("wrench") >= 42, "new stock only by existing restock; old stock retained")
	print("AID-1: assertions=%d failures=%d" % [assertions,failures])
	quit(0 if failures == 0 else 1)
