extends SceneTree

# ==============================================================================
# S4-A TOOL: EXPORT CANONICAL WORLD SNAPSHOT
# ==============================================================================
# Generates a valid runtime WorldState with materialized NPC identities and
# exports it to artifacts/world_snapshot.json for independent Python verification.
# ==============================================================================

func _init() -> void:
	var world := S1WorldData.create_s1_world()

	# Materialize identities
	world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Mara", 28)
	world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Eli", 35)
	world.npc_registry.materialize_identity(world, &"settlement:gray_valley", "Jon", 42)
	world.npc_registry.materialize_identity(world, &"settlement:new_hope", "Sarah", 24)
	world.npc_registry.materialize_identity(world, &"settlement:dry_well", "Kael", 50)

	var json_str := world.to_canonical_json()

	# Ensure artifacts directory exists
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("artifacts"):
		dir.make_dir("artifacts")

	var file := FileAccess.open("res://artifacts/world_snapshot.json", FileAccess.WRITE)
	if file == null:
		print("ERROR: Failed to open artifacts/world_snapshot.json for writing!")
		quit(1)
		return

	file.store_string(json_str)
	file.close()

	print("Successfully exported world snapshot to artifacts/world_snapshot.json")
	print("  NPCs materialized: %d" % world.npc_registry.get_all_npcs().size())
	print("  next_npc_sequence: %d" % world.next_npc_sequence)
	quit(0)
