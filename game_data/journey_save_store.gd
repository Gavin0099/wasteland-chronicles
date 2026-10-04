extends RefCounted

# One owned slot. Tests inject a separate path before Main enters the tree.
const DEFAULT_PATH: String = "user://saves/journey.json"
var path: String

func _init(slot_path: String = DEFAULT_PATH) -> void:
	path = ProjectSettings.globalize_path(slot_path)

func failure(code: String) -> Dictionary:
	return {"success": false, "world": null, "error": code, "fingerprint": ""}

func decode(raw: String) -> Dictionary:
	# Do not parse/re-encode first: strict skill-rank lexemes belong to the codec.
	var result: Dictionary = WorldState.from_json_checked(raw)
	if not result.success:
		return failure("INVALID")
	var candidate: WorldState = result.world
	if candidate.player == null or SimulationEngine.new().validate_invariants(candidate) != "":
		return failure("INVALID")
	return {"success": true, "world": candidate, "error": "", "fingerprint": raw.sha256_text()}

func load_game() -> Dictionary:
	var source: String = path
	if not FileAccess.file_exists(source):
		if DirAccess.dir_exists_absolute(source):
			return failure("UNREADABLE")
		if not FileAccess.file_exists(path + ".bak"):
			return failure("EMPTY")
		source = path + ".bak"
	var file: FileAccess = FileAccess.open(source, FileAccess.READ)
	if file == null:
		return failure("UNREADABLE")
	var raw: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK:
		return failure("UNREADABLE")
	var result: Dictionary = decode(raw)
	result["recovered"] = source != path
	return result

func move_file(source: String, destination: String) -> Error:
	return DirAccess.rename_absolute(source, destination)

func save_game(world: WorldState) -> Dictionary:
	if world == null or world.player == null:
		return failure("INVALID")
	var raw: String = world.to_canonical_json()
	var checked: Dictionary = decode(raw)
	if not checked.success:
		return checked
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return failure("WRITE_FAILED")
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return failure("WRITE_FAILED")
	file.store_string(raw)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return failure("WRITE_FAILED")
	var verification: FileAccess = FileAccess.open(temporary, FileAccess.READ)
	if verification == null:
		return failure("WRITE_FAILED")
	var stored: String = verification.get_as_text()
	var verify_error: Error = verification.get_error()
	verification.close()
	if verify_error != OK or stored != raw or not decode(stored).success:
		DirAccess.remove_absolute(temporary)
		return failure("WRITE_FAILED")
	# Windows Godot deletes existing rename destinations before moving. Move
	# the previous slot aside first; every rename below targets an absent file.
	var backup: String = path + ".bak"
	if DirAccess.dir_exists_absolute(path) or DirAccess.dir_exists_absolute(backup):
		DirAccess.remove_absolute(temporary)
		return failure("WRITE_FAILED")
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			DirAccess.remove_absolute(temporary)
			return failure("WRITE_FAILED")
		if move_file(path, backup) != OK:
			DirAccess.remove_absolute(temporary)
			return failure("WRITE_FAILED")
	if move_file(temporary, path) != OK:
		# If restoration also fails, retain .bak; startup/load can read it.
		if FileAccess.file_exists(backup):
			move_file(backup, path)
		DirAccess.remove_absolute(temporary)
		return failure("WRITE_FAILED")
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	return {"success": true, "world": null, "error": "", "fingerprint": raw.sha256_text()}
