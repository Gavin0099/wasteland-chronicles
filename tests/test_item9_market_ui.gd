extends SceneTree

var failures := 0
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("ITEM-9: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()
	engine.materialize_player(world, &"settlement:gray_valley", "Market UI Tester", 27)
	world.player.money = 1000
	var projection := PlayerUIProjection.project(world)
	var current: Dictionary = projection.current_settlement
	var offers: Array = current.get("item_market", [])
	check(offers.size() == 12, "current settlement projects all canonical item offers")
	var wrench: Dictionary = {}
	for offer in offers:
		if offer.item_id == "wrench":
			wrench = offer
	check(not wrench.is_empty() and wrench.stock == 6 and wrench.quote_buy == 25 and wrench.quote_sell == 12, "Gray Valley wrench stock and quotes are projected")
	check(not current.has("item_market_state"), "projection exposes a view, not a mutable market object")

	var shell := PlayableShell.new()
	root.add_child(shell)
	shell.setup(world, engine)
	check(shell.item_market_rows.size() == 13 and not shell.item_market_rows["military_backpack"].visible, "Survivor PDA keeps route-only loot out of regular shop rows")
	check(shell.item_market_toggle != null and not shell.item_market_toggle.button_pressed, "item market starts collapsed")
	shell.item_market_toggle.button_pressed = true
	shell.item_market_toggle.toggled.emit(true)
	check(shell.item_market_scroll.visible, "item market can be expanded")
	var before := world.to_canonical_json()
	var buy := shell.on_buy_item_pressed("wrench", 1)
	check(buy.success and world.player.inspect_item("wrench").success, "PDA item buy dispatches an authority intent")
	check(world.current_day == 0, "item trade from UI does not spend time")
	var sell := shell.on_sell_item_pressed("wrench", 1)
	check(sell.success and not world.player.inspect_item("wrench").success, "PDA item sell dispatches an authority intent")
	check(world.current_day == 0 and world.player.money == 987, "round-trip item trade applies the declared spread without time")
	check(world.to_canonical_json() != before, "committed trades are visible in the projection/save")
	check(engine.validate_invariants(world) == "", "market UI transactions preserve invariants")
	shell.queue_free()
	await process_frame
	print("ITEM-9 market UI: ", "PASS" if failures == 0 else "FAIL", "; assertions=", assertions, "; failures=", failures)
	quit(0 if failures == 0 else 1)
