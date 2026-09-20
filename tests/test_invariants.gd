extends SceneTree

func _init() -> void:
	print("--- Running Invariant Test Suite ---")
	var engine := SimulationEngine.new()
	var world := M0WorldData.create_m0_world()

	# 驗證初始狀態不變量
	var initial_err: String = engine.validate_invariants(world)
	if initial_err != "":
		print("FAIL: Initial state invariant violated: ", initial_err)
		quit(1)
		return

	# 執行 30 天並在每日驗證不變量
	for day in range(1, 31):
		engine.tick(world)
		var err: String = engine.validate_invariants(world)
		if err != "":
			print("FAIL: Day %d invariant violated: %s" % [day, err])
			quit(1)
			return

	# 測試故意破壞不變量是否被成功抓出 (Negative Test)
	var corrupt_world := M0WorldData.create_m0_world()
	corrupt_world.settlements[&"settlement:gray_valley"].inventory.water = -10
	var negative_err: String = engine.validate_invariants(corrupt_world)
	if negative_err == "":
		print("FAIL: Negative water was not caught by invariant checker!")
		quit(1)
		return

	print("PASS: Invariant Test Suite (All 30 days valid + negative detection verified)")
	quit(0)
