extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const ROOT_CHECKPOINT: CheckpointDefinition = preload("res://game/data/checkpoints/root_tree.tres")

func test_schema_v1_roundtrip_and_transient_fields_are_excluded(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal(SaveManager.SCHEMA_VERSION, 1, "M2C_SCHEMA_VERSION_EXACT")
	var context := _context("roundtrip")
	var manager: SaveManager = context["manager"]
	var world := WorldState.new()
	var narrative := NarrativeState.new()
	world.activate_checkpoint(ROOT_CHECKPOINT.id)
	world.open_shortcut(&"shortcut.saved")
	narrative.add_note(&"note.saved")
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 42.5))
	var raw := FileAccess.get_file_as_string(manager.save_path)
	assertions.is_false(raw.contains("PlayerStance"), "M2C_TRANSIENT_STANCE_EXCLUDED")
	assertions.is_false(raw.contains("dodge_commit_guard"), "M2C_TRANSIENT_ACTION_EXCLUDED")
	assertions.is_false(raw.contains("enemy"), "ordinary enemy state must not be serialized")
	var fresh_world := WorldState.new()
	var fresh_narrative := NarrativeState.new()
	var loaded := manager.load_game(fresh_world, fresh_narrative)
	assertions.is_true(loaded)
	assertions.equal(manager.last_status, &"loaded_primary")
	assertions.equal(manager.loaded_playtime_seconds, 42.5)
	assertions.equal(fresh_world.snapshot(), world.snapshot())
	assertions.equal(fresh_narrative.snapshot(), narrative.snapshot())
	_cleanup(context["dir"])
	return true

func test_unknown_version_malformed_shape_and_unresolved_checkpoint_fail_without_mutation(assertions: Assertions, _fixture: RefCounted) -> bool:
	var context := _context("invalid")
	var manager: SaveManager = context["manager"]
	var world := WorldState.new()
	var narrative := NarrativeState.new()
	world.open_shortcut(&"shortcut.keep")
	narrative.add_note(&"note.keep")
	var world_before := world.snapshot()
	var narrative_before := narrative.snapshot()
	var valid_world := WorldState.new()
	valid_world.activate_checkpoint(ROOT_CHECKPOINT.id)
	var valid_payload := {
		"schema_version": 1,
		"world_state": valid_world.snapshot(),
		"narrative_state": NarrativeState.new().snapshot(),
		"player": {"checkpoint_id": String(ROOT_CHECKPOINT.id)},
		"playtime_seconds": 1.0,
	}
	var float_version := valid_payload.duplicate(true)
	float_version["schema_version"] = 1.0
	var boolean_version := valid_payload.duplicate(true)
	boolean_version["schema_version"] = true
	var boolean_playtime := valid_payload.duplicate(true)
	boolean_playtime["playtime_seconds"] = true
	var unknown_world_field := valid_payload.duplicate(true)
	unknown_world_field["world_state"]["unexpected"] = []
	for payload in [
		{"schema_version": 99},
		{"schema_version": 1, "world_state": [], "narrative_state": {}, "player": {"checkpoint_id": "checkpoint.root_tree"}, "playtime_seconds": 1.0},
		{"schema_version": 1, "world_state": WorldState.new().snapshot(), "narrative_state": NarrativeState.new().snapshot(), "player": {"checkpoint_id": "checkpoint.unresolved"}, "playtime_seconds": 1.0},
		float_version,
		boolean_version,
		boolean_playtime,
		unknown_world_field,
	]:
		_write_json(manager.save_path, payload)
		assertions.is_false(manager.load_game(world, narrative), "M2C_SCHEMA_VERSION_AND_SHAPE_VALIDATION")
		assertions.equal(world.snapshot(), world_before)
		assertions.equal(narrative.snapshot(), narrative_before)
	_cleanup(context["dir"])
	return true

func test_interrupted_and_failed_save_leave_previous_primary(assertions: Assertions, _fixture: RefCounted) -> bool:
	var context := _context("atomic")
	var manager: SaveManager = context["manager"]
	var world := WorldState.new()
	var narrative := NarrativeState.new()
	world.activate_checkpoint(ROOT_CHECKPOINT.id)
	world.open_shortcut(&"shortcut.old")
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 1.0))
	var old_primary := FileAccess.get_file_as_string(manager.save_path)
	world.open_shortcut(&"shortcut.backed_up")
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 1.5))
	var old_backup := FileAccess.get_file_as_string(manager.backup_path)
	world.open_shortcut(&"shortcut.new")
	manager.inject_stop_before_replace_once = true
	assertions.is_false(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 2.0), "M2C_ATOMIC_NON_REPLACE")
	assertions.is_false(FileAccess.file_exists(manager.temp_path), "interrupted save must clean validated temp file")
	assertions.equal(FileAccess.get_file_as_string(manager.backup_path), old_backup)
	var current_primary := FileAccess.get_file_as_string(manager.save_path)
	assertions.is_false(current_primary == old_primary)
	manager.inject_fail_save_once = true
	assertions.is_false(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 3.0))
	assertions.equal(FileAccess.get_file_as_string(manager.save_path), current_primary)
	assertions.equal(FileAccess.get_file_as_string(manager.backup_path), old_backup)
	_cleanup(context["dir"])
	return true

func test_corrupt_primary_recovers_one_valid_backup(assertions: Assertions, _fixture: RefCounted) -> bool:
	var context := _context("backup")
	var manager: SaveManager = context["manager"]
	var world := WorldState.new()
	var narrative := NarrativeState.new()
	world.activate_checkpoint(ROOT_CHECKPOINT.id)
	world.open_shortcut(&"shortcut.backup")
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 5.0))
	world.open_shortcut(&"shortcut.primary")
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 6.0))
	var corrupt := FileAccess.open(manager.save_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.flush()
	corrupt.close()
	var restored_world := WorldState.new()
	assertions.is_true(manager.load_game(restored_world, NarrativeState.new()), "M2C_BACKUP_RECOVERY")
	assertions.equal(manager.last_status, &"recovered_backup")
	assertions.is_true(restored_world.has_opened_shortcut(&"shortcut.backup"))
	assertions.is_false(restored_world.has_opened_shortcut(&"shortcut.primary"))
	_cleanup(context["dir"])
	return true

func _context(label: String) -> Dictionary:
	var directory := "user://m2c-tests/%s-%d" % [label, Time.get_ticks_usec()]
	_cleanup(directory)
	var registry := ContentRegistry.new()
	registry.register_checkpoint(ROOT_CHECKPOINT)
	return {"dir": directory, "manager": SaveManager.new("%s/profile.json" % directory, registry)}

func _write_json(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func _cleanup(directory: String) -> void:
	var absolute := ProjectSettings.globalize_path(directory)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var dir := DirAccess.open(absolute)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	DirAccess.remove_absolute(absolute)
