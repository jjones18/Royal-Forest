class_name SaveManager
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_SAVE_PATH := "user://saves/profile_1.json"

var save_path: String
var backup_path: String
var temp_path: String
var registry: ContentRegistry
var last_status: StringName = &"idle"
var last_error := ""
var loaded_playtime_seconds := 0.0
var inject_stop_before_replace_once := false
var inject_fail_save_once := false

func _init(configured_path: String = DEFAULT_SAVE_PATH, content_registry: ContentRegistry = null) -> void:
	save_path = configured_path
	backup_path = configured_path + ".bak"
	temp_path = configured_path + ".tmp"
	registry = content_registry if content_registry != null else ContentRegistry.new()

func save_game(world: WorldState, narrative: NarrativeState, checkpoint_id: StringName, playtime_seconds: float) -> bool:
	last_error = ""
	_remove_if_exists(temp_path)
	if inject_fail_save_once:
		inject_fail_save_once = false
		return _fail(&"save_failed", "injected save failure")
	if world == null or narrative == null:
		return _fail(&"save_failed", "state owners are required")
	if not ContentId.is_namespace(checkpoint_id, "checkpoint") or registry.checkpoint(checkpoint_id) == null:
		return _fail(&"save_failed", "checkpoint id is unresolved")
	if world.current_checkpoint_id != checkpoint_id or not world.has_activated_checkpoint(checkpoint_id):
		return _fail(&"save_failed", "checkpoint must be activated before saving")
	if not is_finite(playtime_seconds) or playtime_seconds < 0.0:
		return _fail(&"save_failed", "playtime must be finite and non-negative")
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"world_state": world.snapshot(),
		"narrative_state": narrative.snapshot(),
		"player": {"checkpoint_id": String(checkpoint_id)},
		"playtime_seconds": playtime_seconds,
	}
	if not _validate_payload(payload)["ok"]:
		return _fail(&"save_failed", "generated save payload failed validation")
	var absolute_directory := ProjectSettings.globalize_path(save_path).get_base_dir()
	if DirAccess.make_dir_recursive_absolute(absolute_directory) != OK:
		return _fail(&"save_failed", "could not create save directory")
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return _fail(&"save_failed", "could not open temporary save")
	temp.store_string(JSON.stringify(payload, "\t", false))
	temp.flush()
	var write_error := temp.get_error()
	temp.close()
	if write_error != OK or not _read_valid_payload(temp_path)["ok"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return _fail(&"save_failed", "temporary save was incomplete")
	if inject_stop_before_replace_once:
		inject_stop_before_replace_once = false
		_remove_if_exists(temp_path)
		return _fail(&"interrupted", "injected interruption before atomic replace")
	if FileAccess.file_exists(save_path):
		var previous := _read_valid_payload(save_path)
		if previous["ok"] and not _copy_file(save_path, backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return _fail(&"save_failed", "could not preserve rolling backup")
	var replace_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path))
	if replace_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return _fail(&"save_failed", "could not replace primary save")
	last_status = &"saved"
	return true

func load_game(world: WorldState, narrative: NarrativeState) -> bool:
	last_error = ""
	if world == null or narrative == null:
		return _fail(&"load_failed", "state owners are required")
	var primary := _read_valid_payload(save_path)
	if primary["ok"] and _apply_validated(primary, world, narrative):
		last_status = &"loaded_primary"
		return true
	var backup := _read_valid_payload(backup_path)
	if backup["ok"] and _apply_validated(backup, world, narrative):
		last_status = &"recovered_backup"
		return true
	return _fail(&"load_failed", "no valid primary or backup save")

func has_any_save() -> bool:
	return FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)

func _read_valid_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok": false}
	var raw := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(raw) != OK or not _has_exact_schema_version(raw): return {"ok": false}
	if typeof(json.data) == TYPE_DICTIONARY:
		json.data["schema_version"] = SCHEMA_VERSION
	return _validate_payload(json.data)

func _validate_payload(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY: return {"ok": false}
	var payload: Dictionary = value
	var expected := ["schema_version", "world_state", "narrative_state", "player", "playtime_seconds"]
	if payload.size() != expected.size(): return {"ok": false}
	for key in expected:
		if not payload.has(key): return {"ok": false}
	if typeof(payload["schema_version"]) != TYPE_INT or payload["schema_version"] != SCHEMA_VERSION:
		return {"ok": false}
	if typeof(payload["player"]) != TYPE_DICTIONARY: return {"ok": false}
	var player: Dictionary = payload["player"]
	if player.size() != 1 or not player.has("checkpoint_id") or typeof(player["checkpoint_id"]) != TYPE_STRING:
		return {"ok": false}
	var checkpoint_id := StringName(player["checkpoint_id"])
	if not ContentId.is_namespace(checkpoint_id, "checkpoint") or registry.checkpoint(checkpoint_id) == null:
		return {"ok": false}
	if typeof(payload["playtime_seconds"]) not in [TYPE_INT, TYPE_FLOAT]: return {"ok": false}
	var playtime := float(payload["playtime_seconds"])
	if not is_finite(playtime) or playtime < 0.0: return {"ok": false}
	var candidate_world := WorldState.new()
	var candidate_narrative := NarrativeState.new()
	if not candidate_world.apply_snapshot(payload["world_state"]): return {"ok": false}
	if not candidate_narrative.apply_snapshot(payload["narrative_state"]): return {"ok": false}
	if candidate_world.current_checkpoint_id != checkpoint_id: return {"ok": false}
	return {"ok": true, "world": candidate_world.snapshot(), "narrative": candidate_narrative.snapshot(), "checkpoint_id": checkpoint_id, "playtime_seconds": playtime}

func _apply_validated(validated: Dictionary, world: WorldState, narrative: NarrativeState) -> bool:
	# Both candidates were already accepted by fresh owners. Applying these exact
	# snapshots is therefore an all-or-nothing operation for the live owners.
	if not world.apply_snapshot(validated["world"]): return false
	if not narrative.apply_snapshot(validated["narrative"]): return false
	loaded_playtime_seconds = validated["playtime_seconds"]
	return true

func _copy_file(source_path: String, destination_path: String) -> bool:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null: return false
	var bytes := source.get_buffer(source.get_length())
	source.close()
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null: return false
	destination.store_buffer(bytes)
	destination.flush()
	var result := destination.get_error() == OK
	destination.close()
	return result and _read_valid_payload(destination_path)["ok"]

func _has_exact_schema_version(raw: String) -> bool:
	if raw.count("\"schema_version\"") != 1:
		return false
	var pattern := RegEx.new()
	if pattern.compile("\"schema_version\"\\s*:\\s*%d\\s*[,}]" % SCHEMA_VERSION) != OK:
		return false
	return pattern.search(raw) != null

func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _fail(status: StringName, message: String) -> bool:
	last_status = status
	last_error = message
	return false
