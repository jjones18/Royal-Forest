extends Node

const GAME_ROOT := preload("res://game/app/game_root.tscn")
const OUTPUT_DIR := "/tmp/royal-forest-recording-probe"
const CAPTURE_SECONDS := 3.0
const ENCODE_TIMEOUT_SECONDS := 30.0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := GAME_ROOT.instantiate()
	add_child(root)
	await get_tree().process_frame
	await get_tree().process_frame
	var recorder: GameplayRecorder = root.recorder
	recorder.recordings_dir = OUTPUT_DIR
	if not recorder.start_recording(true):
		_fail("recorder did not start")
		return
	await get_tree().create_timer(CAPTURE_SECONDS * 0.5).timeout
	if not recorder.mark_issue():
		_fail("issue mark was rejected")
		return
	await get_tree().create_timer(CAPTURE_SECONDS * 0.5).timeout
	var captured_frames := recorder.video_frame_index
	var session_id := recorder.session_id
	if not recorder.stop_recording(true):
		_fail("recorder did not stop")
		return
	var video_path := "%s/%s.mp4" % [OUTPUT_DIR, session_id]
	var frames_path := "%s/.frames-%s" % [OUTPUT_DIR, session_id]
	var log_path := "%s/%s.video.log" % [OUTPUT_DIR, session_id]
	var waited := 0.0
	while waited < ENCODE_TIMEOUT_SECONDS:
		var encode_verified := FileAccess.file_exists(log_path) and FileAccess.get_file_as_string(log_path).contains("Created verified 24 FPS video")
		if FileAccess.file_exists(video_path) and not DirAccess.dir_exists_absolute(frames_path) and encode_verified:
			break
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	if not FileAccess.file_exists(video_path):
		_fail("24 FPS MP4 was not produced: %s" % video_path)
		return
	if FileAccess.get_file_as_bytes(video_path).is_empty():
		_fail("MP4 is empty: %s" % video_path)
		return
	if captured_frames < 60 or captured_frames > 90:
		_fail("expected about 72 frames, captured %d" % captured_frames)
		return
	if DirAccess.dir_exists_absolute(frames_path):
		_fail("temporary frames were not removed after verified encode")
		return
	if not FileAccess.get_file_as_string(log_path).contains("Created verified 24 FPS video"):
		_fail("encoder did not report a verified 24 FPS output")
		return
	print("RECORDING PROBE: PASS session=%s frames=%d video=%s" % [session_id, captured_frames, video_path])
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("RECORDING PROBE: FAIL — %s" % message)
	get_tree().quit(1)
