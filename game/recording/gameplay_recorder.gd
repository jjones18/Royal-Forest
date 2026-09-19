class_name GameplayRecorder
extends Node

const SAMPLE_INTERVAL := 1.0 / 20.0
const VIDEO_FRAME_INTERVAL := 1.0 / 24.0
const VIDEO_JPEG_QUALITY := 0.78
const DEFAULT_RECORDINGS_DIR := "user://recordings"
const HELPER_PATH := "res://tools/record_clip.sh"
const FLASH_SECONDS := 0.35

var playground: CombatPlayground
var recordings_dir := DEFAULT_RECORDINGS_DIR
var recording := false
var session_id := ""
var telemetry_path := ""
var telemetry_file: FileAccess
var elapsed := 0.0
var sample_accumulator := 0.0
var video_frame_accumulator := 0.0
var video_frame_index := 0
var video_frames_dir := ""
var video_capture_active := false
var video_encode_pending := false
var video_output_path := ""
var video_log_path := ""
var video_encode_started_msec := 0
var mark_number := 0
var status_label: Label
var detail_label: Label
var flash_panel: ColorRect
var flash_label: Label
var notice_text := ""
var notice_remaining := 0.0
var flash_remaining := 0.0


func _ready() -> void:
	_build_overlay()
	set_process_input(true)
	set_process(true)
	set_physics_process(true)


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F9 or event.physical_keycode == KEY_F9:
		toggle_recording()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F10 or event.physical_keycode == KEY_F10:
		mark_issue()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if video_encode_pending:
		_poll_video_encode()
	if not recording or not video_capture_active:
		return
	video_frame_accumulator += delta
	while video_frame_accumulator + 0.000001 >= VIDEO_FRAME_INTERVAL:
		video_frame_accumulator -= VIDEO_FRAME_INTERVAL
		_capture_video_frame()


func _physics_process(delta: float) -> void:
	if notice_remaining > 0.0:
		notice_remaining = maxf(0.0, notice_remaining - delta)
	if flash_remaining > 0.0:
		flash_remaining = maxf(0.0, flash_remaining - delta)
		flash_panel.visible = true
		flash_panel.color.a = minf(0.24, flash_remaining / FLASH_SECONDS * 0.24)
	else:
		flash_panel.visible = false
	if not recording:
		return
	elapsed += delta
	sample_accumulator += delta
	while sample_accumulator + 0.000001 >= SAMPLE_INTERVAL:
		sample_accumulator -= SAMPLE_INTERVAL
		_write_event("sample")
	_update_recording_overlay()


func toggle_recording() -> void:
	if recording:
		stop_recording()
	else:
		start_recording()


func start_recording(start_video := true) -> bool:
	if recording or video_encode_pending or playground == null:
		return false
	DirAccess.make_dir_recursive_absolute(recordings_absolute_path())
	session_id = "rf-%s" % _timestamp_id()
	telemetry_path = "%s/%s.jsonl" % [recordings_dir, session_id]
	telemetry_file = FileAccess.open(telemetry_path, FileAccess.WRITE)
	if telemetry_file == null:
		_show_notice("RECORD FAILED — telemetry file", 4.0)
		return false
	recording = true
	elapsed = 0.0
	sample_accumulator = 0.0
	video_frame_accumulator = VIDEO_FRAME_INTERVAL
	video_frame_index = 0
	video_capture_active = false
	video_encode_pending = false
	video_output_path = ""
	video_log_path = ""
	video_encode_started_msec = 0
	mark_number = 0
	_write_event("start")
	_flash("REC START")
	if start_video and DisplayServer.get_name() != "headless":
		_start_platform_video()
	_update_recording_overlay()
	return true


func stop_recording(stop_video := true) -> bool:
	if not recording:
		return false
	_write_event("stop")
	if telemetry_file != null:
		telemetry_file.flush()
		telemetry_file.close()
	telemetry_file = null
	recording = false
	_write_latest_pointer()
	_flash("REC STOP")
	if stop_video and DisplayServer.get_name() != "headless":
		_stop_platform_video()
	if video_encode_pending:
		status_label.text = "PROCESSING 24 FPS VIDEO…"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	else:
		status_label.text = "F9: RECORD ISSUE  •  F10: MARK MOMENT"
		status_label.add_theme_color_override("font_color", Color.WHITE)
	detail_label.text = "%s  •  telemetry saved" % session_id
	return true


func mark_issue() -> bool:
	if not recording:
		_show_notice("Press F9 to start recording before marking", 3.0)
		return false
	mark_number += 1
	_write_event("mark", {"mark": mark_number})
	_show_notice("ISSUE MARK %d" % mark_number, 2.0)
	_flash("ISSUE %d" % mark_number)
	return true


func telemetry_snapshot() -> Dictionary:
	if playground == null or playground.player == null or playground.primary_enemy == null:
		return {}
	var player := playground.player
	var enemy := playground.primary_enemy
	return {
		"t": snappedf(elapsed, 0.001),
		"player_position": _vector3_array(player.global_position),
		"player_yaw_degrees": rad_to_deg(player.global_rotation.y),
		"player_hp": player.stats.hp,
		"player_stamina": player.stats.stamina,
		"player_crouching": player.stance.crouching,
		"player_eye_height": player.stance.current_eye_height,
		"player_phase": _phase_name(PlayerActionMachine.Phase.keys(), player.actions.phase),
		"enemy_position": _vector3_array(enemy.global_position),
		"enemy_yaw_degrees": rad_to_deg(enemy.global_rotation.y),
		"enemy_hp": enemy.hp,
		"enemy_phase": _phase_name(EnemyStateMachine.Phase.keys(), enemy.state_machine.phase),
		"enemy_los": enemy.has_line_of_sight_to_player(),
		"enemy_distance": enemy.global_position.distance_to(player.global_position),
		"enemy_last_known_position": _vector3_array(enemy.last_known_player_position),
		"enemy_los_lost_elapsed": enemy.state_machine.los_lost_elapsed,
		"enemy_search_elapsed": enemy.state_machine.search_elapsed,
		"enemy_from_home": enemy.global_position.distance_to(enemy.home_position),
	}


func recordings_absolute_path() -> String:
	return ProjectSettings.globalize_path(recordings_dir)


func _write_event(kind: String, extra := {}) -> void:
	if telemetry_file == null:
		return
	var payload := telemetry_snapshot()
	payload["event"] = kind
	payload["session_id"] = session_id
	for key in extra:
		payload[key] = extra[key]
	telemetry_file.store_line(JSON.stringify(payload))
	if kind != "sample":
		telemetry_file.flush()


func _write_latest_pointer() -> void:
	var latest := FileAccess.open("%s/latest.txt" % recordings_dir, FileAccess.WRITE)
	if latest != null:
		latest.store_line(session_id)
		latest.close()


func _start_platform_video() -> void:
	if OS.get_name() == "Linux" and OS.has_feature("editor") and FileAccess.file_exists(HELPER_PATH):
		video_frames_dir = "%s/.frames-%s" % [recordings_dir, session_id]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(video_frames_dir))
		video_capture_active = true
		_show_notice("24 FPS game capture started — gameplay frame rate unchanged", 4.0)
	elif OS.get_name() == "Windows":
		_show_notice("Telemetry active — press Win+Alt+R for Game Bar video", 6.0)
	else:
		_show_notice("Telemetry active — platform video helper unavailable", 5.0)


func _stop_platform_video() -> void:
	if video_capture_active:
		video_capture_active = false
		video_output_path = "%s/%s.mp4" % [recordings_dir, session_id]
		video_log_path = "%s/%s.video.log" % [recordings_dir, session_id]
		video_encode_started_msec = Time.get_ticks_msec()
		var encoder_pid := OS.create_process("/usr/bin/bash", [
			ProjectSettings.globalize_path(HELPER_PATH),
			"encode",
			session_id,
			recordings_absolute_path(),
		])
		video_encode_pending = encoder_pid > 0
		if not video_encode_pending:
			status_label.text = "VIDEO FAILED — TELEMETRY SAVED"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	elif OS.get_name() == "Windows":
		_show_notice("Telemetry saved — press Win+Alt+R to stop Game Bar", 6.0)


func _poll_video_encode() -> void:
	var log_text := FileAccess.get_file_as_string(video_log_path) if FileAccess.file_exists(video_log_path) else ""
	if FileAccess.file_exists(video_output_path) and log_text.contains("Created verified 24 FPS video"):
		video_encode_pending = false
		status_label.text = "VIDEO READY  •  F9: RECORD ANOTHER"
		status_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
		detail_label.text = "%s.mp4 + .jsonl" % session_id
		_flash("VIDEO READY")
		return
	if log_text.contains("failed") or log_text.contains("unavailable") or log_text.contains("No captured frames"):
		video_encode_pending = false
		status_label.text = "VIDEO FAILED — TEMP FRAMES KEPT"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		detail_label.text = "%s  •  see video.log" % session_id
		return
	if Time.get_ticks_msec() - video_encode_started_msec > 60000:
		video_encode_pending = false
		status_label.text = "VIDEO ENCODE TIMEOUT — TEMP FRAMES KEPT"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		detail_label.text = "%s  •  see recordings folder" % session_id


func _capture_video_frame() -> void:
	if not video_capture_active or video_frames_dir.is_empty():
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return
	var target_size := _fit_inside(image.get_size(), Vector2i(1280, 720))
	if target_size != image.get_size():
		image.resize(target_size.x, target_size.y, Image.INTERPOLATE_BILINEAR)
	var frame_path := "%s/frame-%06d.jpg" % [video_frames_dir, video_frame_index]
	if image.save_jpg(frame_path, VIDEO_JPEG_QUALITY) == OK:
		video_frame_index += 1


func _fit_inside(source: Vector2i, bounds: Vector2i) -> Vector2i:
	if source.x <= bounds.x and source.y <= bounds.y:
		return source
	var scale := minf(float(bounds.x) / source.x, float(bounds.y) / source.y)
	return Vector2i(maxi(2, int(source.x * scale) & ~1), maxi(2, int(source.y * scale) & ~1))


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	flash_panel = ColorRect.new()
	flash_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_panel.color = Color(1.0, 0.08, 0.04, 0.0)
	flash_panel.visible = false
	layer.add_child(flash_panel)
	flash_label = Label.new()
	flash_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	flash_label.position = Vector2(-130, -30)
	flash_label.size = Vector2(260, 60)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	flash_label.add_theme_font_size_override("font_size", 30)
	flash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_panel.add_child(flash_label)
	var panel := PanelContainer.new()
	panel.name = "DiagnosticCapture"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.position = Vector2(-610, -90)
	panel.size = Vector2(590, 70)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rows)
	status_label = Label.new()
	status_label.text = "F9: RECORD ISSUE  •  F10: MARK MOMENT"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(status_label)
	detail_label = Label.new()
	detail_label.text = "24 FPS saved video + 20 Hz enemy telemetry"
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.72))
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(detail_label)


func _update_recording_overlay() -> void:
	if not recording:
		return
	status_label.text = "● REC  %05.1fs  •  F9 STOP  •  F10 MARK" % elapsed
	status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.16))
	if notice_remaining > 0.0:
		detail_label.text = notice_text
		return
	if playground != null and playground.primary_enemy != null and playground.player != null:
		var enemy := playground.primary_enemy
		detail_label.text = "%s • LOS %s • lost %.1f • search %.1f • dist %.1f • home %.1f • marks %d" % [
			_phase_name(EnemyStateMachine.Phase.keys(), enemy.state_machine.phase),
			"YES" if enemy.has_line_of_sight_to_player() else "NO",
			enemy.state_machine.los_lost_elapsed,
			enemy.state_machine.search_elapsed,
			enemy.global_position.distance_to(playground.player.global_position),
			enemy.global_position.distance_to(enemy.home_position),
			mark_number,
		]


func _show_notice(message: String, seconds: float) -> void:
	notice_text = message
	notice_remaining = seconds
	if detail_label != null:
		detail_label.text = message


func _flash(message: String) -> void:
	flash_label.text = message
	flash_remaining = FLASH_SECONDS
	flash_panel.visible = true


func _timestamp_id() -> String:
	var value := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d-%02d%02d%02d" % [
		value.year,
		value.month,
		value.day,
		value.hour,
		value.minute,
		value.second,
	]


func _phase_name(names: Array, phase: int) -> String:
	return str(names[phase]) if phase >= 0 and phase < names.size() else "UNKNOWN_%d" % phase


func _vector3_array(value: Vector3) -> Array[float]:
	var result: Array[float] = [value.x, value.y, value.z]
	return result


func _exit_tree() -> void:
	if recording:
		stop_recording()
