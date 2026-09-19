extends Node

const GAME_ROOT := preload("res://game/app/game_root.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")
const OUTPUT_DIR := "res://artifacts/visual"
const VISUAL_SAVE_DIR := "user://m2c-tests/visual-probe"

var game: Node
var playground: CombatPlayground


func _ready() -> void:
	_cleanup_visual_save()
	game = GAME_ROOT.instantiate()
	game.save_path = "%s/profile.json" % VISUAL_SAVE_DIR
	game.restore_save_on_startup = false
	add_child(game)
	for _frame in range(12):
		await get_tree().process_frame
	playground = game.playground
	playground.player.set_physics_process(false)
	playground.primary_enemy.set_physics_process(false)
	var signatures: Dictionary = {}
	signatures["neutral"] = await _capture("m1-neutral.png")
	playground.player.stats.stamina = TUNING.dodge_stamina_cost * 0.25
	signatures["low-stamina"] = await _capture("m1-low-stamina.png")
	playground.player.stats.stamina = TUNING.max_stamina
	var player_capture_position := playground.player.global_position
	playground.player.global_position += Vector3(0.0, 0.0, 1.5)
	playground.primary_enemy.state_machine.reset()
	playground.primary_enemy.turn_toward_position(playground.player.global_position, playground.primary_enemy.definition.pursuit_turn_speed_degrees, 1.0)
	playground.primary_enemy.state_machine.set_awareness(true, true, false)
	playground.primary_enemy.state_machine.request_attack(true, true)
	playground.primary_enemy._update_color()
	signatures["enemy-tell"] = await _capture("m1-enemy-tell.png")
	playground.primary_enemy.state_machine.advance(playground.primary_enemy.definition.windup_seconds)
	playground.primary_enemy.commit_strike_direction()
	playground.primary_enemy.global_rotation.y = atan2(-playground.primary_enemy.committed_strike_direction.x, -playground.primary_enemy.committed_strike_direction.z)
	playground.primary_enemy._update_color()
	signatures["enemy-active"] = await _capture("m1-enemy-active.png")
	playground.player.global_position = player_capture_position
	playground.primary_enemy.state_machine.reset()
	playground.primary_enemy._update_color()
	playground.player.actions.reset()
	playground.player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	playground.player.actions.advance(TUNING.attack_windup_seconds * 0.55)
	signatures["attack-windup"] = await _capture("m1-attack-windup.png")
	playground.player.actions.advance(TUNING.attack_windup_seconds * 0.45 + TUNING.attack_active_seconds * 0.5)
	signatures["attack-active"] = await _capture("m1-attack-active.png")
	playground.player.actions.advance(TUNING.attack_active_seconds * 0.5 + TUNING.attack_recovery_seconds * 0.5)
	signatures["attack-recovery"] = await _capture("m1-attack-recovery.png")
	playground.primary_enemy.take_hit(TUNING.attack_damage, playground.player.global_position)
	playground.player.confirm_player_hit(1, TUNING.attack_damage)
	signatures["hit-confirm"] = await _capture("m1-hit-confirm.png")
	playground.primary_enemy.reset_enemy()
	playground.player.actions.reset()
	playground.player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START))
	signatures["guarding"] = await _capture("m1-guarding.png")
	playground.player.receive_enemy_damage(playground.primary_enemy.definition.damage)
	playground.player.viewmodel.set_process(false)
	playground.player.viewmodel.apply_action_pose(playground.player.actions.phase, playground.player.actions.normalized_phase_progress())
	playground.player.viewmodel.position += Vector3(0.04, -0.08, 0.14)
	playground.player.viewmodel.rotation_degrees += Vector3(8.0, 0.0, 10.0)
	signatures["blocked"] = await _capture("m1-blocked.png")
	playground.player.viewmodel.set_process(true)
	playground.player.actions.reset()
	playground.player.stats.stamina = TUNING.guard_impact_stamina_cost * 0.5
	playground.player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START))
	playground.player.receive_enemy_damage(playground.primary_enemy.definition.damage)
	playground.player.actions.advance(TUNING.guard_break_seconds * 0.55)
	signatures["guard-break"] = await _capture("m1-guard-break.png")
	playground.player.actions.reset()
	playground.player.receive_enemy_damage(TUNING.max_hp * 2.0)
	signatures["death"] = await _capture("m1-death.png")
	playground.player.reset_player()
	playground.hud.feedback_remaining = 0.0
	playground.hud.feedback_label.visible = false
	playground.player.global_position = Vector3(-3.8, 0.0, -5.2)
	playground.player.rotation.y = PI
	playground.primary_enemy.global_position = Vector3(-3.8, 0.0, -1.8)
	playground.primary_enemy.reset_enemy()
	playground.primary_enemy.global_position = Vector3(-3.8, 0.0, -1.8)
	var crouch := InputCommand.new()
	crouch.crouch_pressed = true
	playground.player.simulate_command(crouch, 0.25)
	signatures["crouched-behind-low-cover"] = await _capture("m2-crouched-behind-low-cover.png")
	playground.player.reset_player()
	playground.primary_enemy.reset_enemy()
	playground.hud.feedback_remaining = 0.0
	playground.hud.feedback_label.visible = false
	var interact := InputCommand.new()
	interact.interact_pressed = true
	playground.player.simulate_command(interact, 0.0)
	if game.session.status_kind != &"save_success":
		_fail("root-tree interaction did not produce save success")
		return
	signatures["root-tree-saved"] = await _capture("m2-root-tree-saved.png")
	playground.player.receive_enemy_damage(TUNING.max_hp * 2.0)
	signatures["checkpoint-death"] = await _capture("m2-checkpoint-death.png")
	var capture_names := signatures.keys()
	for left_index in range(capture_names.size()):
		for right_index in range(left_index + 1, capture_names.size()):
			var left_name: String = capture_names[left_index]
			var right_name: String = capture_names[right_index]
			if _same_signature(signatures[left_name], signatures[right_name]):
				_fail("captures %s and %s are visually identical" % [left_name, right_name])
				return
	print("VISUAL CAPTURES: %s" % ", ".join(signatures.keys()))
	print("VISUAL RESULT: OK")
	_cleanup_visual_save()
	get_tree().quit(0)


func _cleanup_visual_save() -> void:
	var absolute := ProjectSettings.globalize_path(VISUAL_SAVE_DIR)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var directory := DirAccess.open(absolute)
	if directory != null:
		for filename in directory.get_files():
			directory.remove(filename)
	DirAccess.remove_absolute(absolute)


func _capture(filename: String) -> Dictionary:
	for _frame in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var absolute := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := image.save_png(absolute)
	if error != OK or image.is_empty() or image.get_width() < 640 or image.get_height() < 360:
		_fail("capture missing or undersized: %s" % filename)
		return {}
	var minimum := 1.0
	var maximum := 0.0
	var mean := Vector3.ZERO
	var samples := 0
	for y in range(0, image.get_height(), 24):
		for x in range(0, image.get_width(), 24):
			var color := image.get_pixel(x, y)
			var luminance := color.get_luminance()
			minimum = minf(minimum, luminance)
			maximum = maxf(maximum, luminance)
			mean += Vector3(color.r, color.g, color.b)
			samples += 1
	if maximum < 0.03 or maximum - minimum < 0.02:
		_fail("uniform/black capture: %s %.4f..%.4f" % [filename, minimum, maximum])
		return {}
	mean /= float(samples)
	print("VISUAL CAPTURE: %s %dx%d luminance %.4f..%.4f" % [absolute, image.get_width(), image.get_height(), minimum, maximum])
	return {"mean": mean, "minimum": minimum, "maximum": maximum, "pixel_hash": hash(image.get_data())}


func _same_signature(left: Dictionary, right: Dictionary) -> bool:
	if left.is_empty() or right.is_empty():
		return true
	return left["pixel_hash"] == right["pixel_hash"]


func _fail(message: String) -> void:
	print("VISUAL RESULT: FAIL (%s)" % message)
	_cleanup_visual_save()
	get_tree().quit(1)
