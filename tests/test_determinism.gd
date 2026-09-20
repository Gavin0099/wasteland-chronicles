extends SceneTree

func _init() -> void:
	print("--- Running Determinism & Replay Test ---")
	
	# Run A: 獨立執行 30 天
	var engine_a := SimulationEngine.new()
	var world_a := M0WorldData.create_m0_world()
	for day in range(1, 31):
		engine_a.tick(world_a)
	var json_a: String = world_a.to_canonical_json()
	var hash_a: String = json_a.sha256_text()

	# Run B: 從同一初始狀態獨立執行 30 天
	var engine_b := SimulationEngine.new()
	var world_b := M0WorldData.create_m0_world()
	for day in range(1, 31):
		engine_b.tick(world_b)
	var json_b: String = world_b.to_canonical_json()
	var hash_b: String = json_b.sha256_text()

	print("Run A SHA-256: ", hash_a)
	print("Run B SHA-256: ", hash_b)

	if hash_a != hash_b:
		print("FAIL: Determinism mismatch between Run A and Run B!")
		quit(1)
		return

	if json_a != json_b:
		print("FAIL: Canonical JSON mismatch between Run A and Run B!")
		quit(1)
		return

	print("PASS: Determinism & Replay Test (Identical SHA-256: %s)" % hash_a)
	quit(0)
