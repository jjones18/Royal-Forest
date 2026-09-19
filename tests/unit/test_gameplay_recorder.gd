extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const GAME_ROOT := preload("res://game/app/game_root.tscn")


func test_recording_writes_synchronized_jsonl_events(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := GAME_ROOT.instantiate()
	root.restore_save_on_startup = false
	fixture.add_node(root)
	await fixture.physics_frames(2)
	var recorder: GameplayRecorder = root.recorder
	var test_dir := "user://recording-tests/%d" % Time.get_ticks_usec()
	recorder.recordings_dir = test_dir
	assertions.is_true(recorder.start_recording(false), "headless telemetry recording must start")
	await fixture.physics_frames(15)
	assertions.is_true(recorder.mark_issue(), "F10-equivalent mark must be accepted while recording")
	await fixture.physics_frames(6)
	assertions.is_true(recorder.stop_recording(false), "headless telemetry recording must stop")

	var telemetry_text := FileAccess.get_file_as_string(recorder.telemetry_path)
	var events: Array[String] = []
	var sample_count := 0
	var saw_required_snapshot := false
	for line in telemetry_text.split("\n", false):
		var parsed: Variant = JSON.parse_string(line)
		assertions.is_true(parsed is Dictionary, "every telemetry line must be valid JSON")
		if parsed is not Dictionary:
			continue
		var payload: Dictionary = parsed
		events.append(str(payload.get("event", "")))
		if payload.get("event") == "sample":
			sample_count += 1
		saw_required_snapshot = saw_required_snapshot or (
			payload.has("enemy_phase")
			and payload.has("player_crouching")
			and payload.has("player_eye_height")
			and payload.has("enemy_los")
			and payload.has("enemy_los_lost_elapsed")
			and payload.has("enemy_search_elapsed")
			and payload.has("enemy_distance")
		)

	assertions.is_true(events.size() >= 5, "recording must contain start, timed samples, mark, and stop")
	assertions.equal(events.front(), "start", "first telemetry event must synchronize recording start")
	assertions.equal(events.back(), "stop", "last telemetry event must synchronize recording stop")
	assertions.is_true(events.has("mark"), "telemetry must retain the visible issue mark")
	assertions.is_true(sample_count >= 4, "20 Hz telemetry must produce timed samples")
	assertions.is_true(saw_required_snapshot, "telemetry must include enemy tracking state needed for diagnosis")
	assertions.equal(FileAccess.get_file_as_string("%s/latest.txt" % test_dir).strip_edges(), recorder.session_id)

	_cleanup_recording_test(recorder.telemetry_path, test_dir)
	return true


func _cleanup_recording_test(telemetry_path: String, test_dir: String) -> void:
	for path in [telemetry_path, "%s/latest.txt" % test_dir]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var absolute_dir := ProjectSettings.globalize_path(test_dir)
	DirAccess.remove_absolute(absolute_dir)
	DirAccess.remove_absolute(absolute_dir.get_base_dir())
