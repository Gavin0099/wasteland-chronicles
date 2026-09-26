class_name GodotSkillSetImportOptions
extends RefCounted

# Patches the [params] section of an asset's .import sidecar — the canonical
# home of importer options like audio loop settings (`loop` on Ogg/MP3,
# `edit/loop_mode` on WAV) or texture filters. The change only takes effect
# after a reimport: run scripts/import/import_project.py (or
# `godot --headless --import`) afterwards.

var utils_script = preload("../core/utils.gd")
var codec_script = preload("../core/variant_codec.gd")

func execute(params: Dictionary) -> void:
    var file_path := _normalize_res_path(params.get("file_path", ""))
    if file_path.is_empty():
        utils_script.log_error("set_import_options requires file_path")
        return
    var sidecar_path := file_path + ".import"
    if not FileAccess.file_exists(sidecar_path):
        utils_script.log_error("Import sidecar does not exist (import the project first): " + sidecar_path)
        return

    var options = params.get("options", {})
    if not (options is Dictionary) or options.is_empty():
        utils_script.log_error("set_import_options requires a non-empty options dictionary")
        return

    var config := ConfigFile.new()
    var load_error := config.load(sidecar_path)
    if load_error != OK:
        utils_script.log_error("Cannot parse import sidecar: " + error_string(load_error))
        return

    # A sidecar is project data, not authority to delete arbitrary files. Check
    # every artifact and its companion before saving even the option change.
    var invalidation: Dictionary = _validate_invalidation(config)
    if not invalidation.ok:
        utils_script.log_error("Unsafe import cache destination: " + str(invalidation.error))
        return

    var codec = codec_script.new()
    var applied := {}
    for key in options.keys():
        var raw_value = options[key]
        var value = codec.decode(raw_value, "options.%s" % str(key))
        if value == null and raw_value != null:
            return
        # JSON numbers always decode as float; importer params are typed, so
        # whole numbers must be written back as int (e.g. enum loop_mode).
        if value is float and is_equal_approx(value, roundf(value)):
            value = int(value)
        config.set_value("params", str(key), value)
        applied[str(key)] = value

    var save_error := config.save(sidecar_path)
    if save_error != OK:
        utils_script.log_error("Failed to save import sidecar: " + error_string(save_error))
        return

    # Drop the imported artifacts so the next `--import` cannot skip this file:
    # a params-only edit does not change the source hash, and the scan may
    # otherwise consider the asset up to date. The .godot/imported cache is
    # regenerable by design.
    var removed_artifacts: Array[String] = []
    for target in invalidation.targets:
        var destination_path: String = target.source
        var absolute_destination: String = target.artifact
        if FileAccess.file_exists(absolute_destination):
            DirAccess.remove_absolute(absolute_destination)
            removed_artifacts.append(destination_path)
        var md5_path: String = target.md5
        if FileAccess.file_exists(md5_path):
            DirAccess.remove_absolute(md5_path)

    print(JSON.stringify({
        "ok": true,
        "file_path": file_path,
        "import_path": sidecar_path,
        "options_applied": applied.keys(),
        "invalidated_artifacts": removed_artifacts,
        "reimport_required": true
    }))

func _validate_invalidation(config: ConfigFile) -> Dictionary:
    var destinations: Variant = config.get_value("deps", "dest_files", [])
    if typeof(destinations) not in [TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY]:
        return {"ok": false, "error": "dest_files must be an array of paths"}
    var targets: Array[Dictionary] = []
    if destinations.is_empty():
        return {"ok": true, "targets": targets}

    # Refuse directory links/junctions as well as linked artifact files. No
    # attacker-controlled ancestor remains between this project and the cache.
    var project_dir: DirAccess = DirAccess.open("res://")
    if project_dir == null or project_dir.is_link(".godot"):
        return {"ok": false, "error": "the project cache must not be a link"}
    var data_dir: DirAccess = DirAccess.open("res://.godot")
    if data_dir == null or data_dir.is_link("imported"):
        return {"ok": false, "error": "the import cache must be a local directory"}
    var cache_dir: DirAccess = DirAccess.open("res://.godot/imported")
    if cache_dir == null:
        return {"ok": false, "error": "the import cache cannot be inspected"}
    var cache_root: String = ProjectSettings.globalize_path("res://.godot/imported").simplify_path()
    for destination in destinations:
        if typeof(destination) != TYPE_STRING:
            return {"ok": false, "error": "dest_files contains a non-string path"}
        var path: String = destination.replace("\\", "/")
        var parts: PackedStringArray = path.split("/")
        if parts.has(".") or parts.has(".."):
            return {"ok": false, "error": "traversal components are not allowed"}
        var absolute_path: String = ProjectSettings.globalize_path(path).simplify_path()
        var md5_path: String = absolute_path.get_basename() + ".md5"
        for candidate in [absolute_path, md5_path]:
            var filename: String = candidate.get_file()
            if candidate.get_base_dir() != cache_root or not filename.is_valid_filename():
                return {"ok": false, "error": "only direct import-cache files may be invalidated"}
            if cache_dir.is_link(filename) or cache_dir.dir_exists(filename):
                return {"ok": false, "error": "cache targets must not be links or directories"}
        targets.append({"source": destination, "artifact": absolute_path, "md5": md5_path})
    return {"ok": true, "targets": targets}

func _normalize_res_path(path_value: Variant) -> String:
    var path := str(path_value).strip_edges().replace("\\", "/")
    if path.is_empty():
        return ""
    if path.begins_with("res://"):
        return path
    return "res://" + path.trim_prefix("/")
