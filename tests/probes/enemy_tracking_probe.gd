extends Node

const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")
const STEP := 1.0 / 60.0
const MAX_STEPS := 1200

var playground: CombatPlayground
var player: PlayerController
var enemy: EnemyController
var failures: Array[String] = []
var elapsed := 0.0


func _ready() -> void:
	playground = PLAYGROUND.instantiate()
	add_child(playground)
	await get_tree().physics_frame
	await get_tree().physics_frame
	player = playground.player
	enemy = playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)

	_test_pillar_search_reveal()
	_test_recorded_same_direction_search_route()
	_test_recorded_green_recovery_reaim()
	_test_natural_return_reveal()
	_test_full_return_idle_reveal()
	_test_low_cover()

	if failures.is_empty():
		print("TRACKING RESULT: PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			print("TRACKING FAIL: %s" % failure)
		print("TRACKING RESULT: FAIL (%d failures)" % failures.size())
		get_tree().quit(1)


func _test_pillar_search_reveal() -> void:
	_reset_visible_encounter()
	player.global_position = Vector3(5.6, 0.0, -3.5)
	_check(not enemy.has_line_of_sight_to_player(), "tall pillar must break LOS")
	var entered_search := _tick_until_phase(EnemyStateMachine.Phase.SEARCH, 2.0, "pillar hide")
	_check(entered_search, "pillar concealment must enter SEARCH after LOS grace")
	player.global_position = Vector3(0.0, 0.0, 4.5)
	_check(enemy.has_line_of_sight_to_player(), "pillar reveal must restore LOS")
	_tick(0.1, "pillar reveal")
	_check(_is_engaged(), "SEARCH must reacquire within 0.1 seconds")


func _test_recorded_same_direction_search_route() -> void:
	# Exact geometry from rf-20260918-160214 at F10 mark 3. The player is
	# stationary on the same side used to enter cover; SEARCH must route around
	# the pillar instead of stopping at a detour corner 0.142 m away.
	enemy.reset_enemy()
	player.reset_player()
	enemy.global_position = Vector3(4.008135, 0.0, -2.855486)
	enemy.last_known_player_position = Vector3(2.976587, 0.0, 0.921867)
	player.global_position = Vector3(2.255312, 0.0, 0.863481)
	enemy.state_machine._enter(EnemyStateMachine.Phase.SEARCH)
	elapsed = 0.0
	_check(not enemy.has_line_of_sight_to_player(), "recorded same-direction hide must begin occluded")
	var start := enemy.global_position
	_tick(0.5, "recorded route")
	_check(enemy.global_position.distance_to(start) > 0.25, "SEARCH must cross the near detour corner instead of stalling")
	var reacquired := _tick_until_phase(EnemyStateMachine.Phase.PURSUIT, 4.0, "same-dir reveal")
	_check(reacquired, "SEARCH must route around the pillar and reacquire the same-direction reveal before giving up")


func _test_recorded_green_recovery_reaim() -> void:
	# Exact mark-1 geometry from rf-20260918-163816. Continue orbiting at the
	# player's full strafe speed; green RECOVERY must erase the facing error.
	enemy.reset_enemy()
	player.reset_player()
	enemy.global_position = Vector3(1.254006, 0.0, 1.343229)
	enemy.rotation.y = deg_to_rad(-106.0)
	player.global_position = Vector3(1.665227, 0.0, -0.238169)
	enemy.state_machine._enter(EnemyStateMachine.Phase.RECOVERY)
	elapsed = 0.0
	var radius := enemy.global_position.distance_to(player.global_position)
	var orbit_angle := atan2(player.global_position.z - enemy.global_position.z, player.global_position.x - enemy.global_position.x)
	var angular_speed := TUNING.strafe_speed / radius
	for _step in range(18):
		orbit_angle += angular_speed * STEP
		player.global_position = enemy.global_position + Vector3(cos(orbit_angle) * radius, 0.0, sin(orbit_angle) * radius)
		_tick_once("green re-aim")
	var target_offset := player.global_position - enemy.global_position
	var target_yaw := atan2(-target_offset.x, -target_offset.z)
	var facing_error := absf(rad_to_deg(wrapf(target_yaw - enemy.rotation.y, -PI, PI)))
	_check(enemy.state_machine.phase == EnemyStateMachine.Phase.RECOVERY, "green re-aim must remain inside RECOVERY")
	_check(facing_error < 5.0, "green RECOVERY must catch the recorded full-speed circle strafe")


func _test_natural_return_reveal() -> void:
	_reset_visible_encounter()
	player.global_position = Vector3(0.0, 0.0, -11.0)
	_check(not enemy.has_line_of_sight_to_player(), "north wall must conceal escaped player")
	var entered_return := _tick_until_phase(EnemyStateMachine.Phase.RETURN, 7.0, "give-up timeline")
	_check(entered_return, "grace plus search must naturally enter RETURN")
	var toward_home := enemy.home_position - enemy.global_position
	toward_home.y = 0.0
	player.global_position = enemy.global_position + toward_home.normalized() * 3.0
	_check(enemy.global_position.distance_to(player.global_position) < enemy.definition.detection_range, "return reveal must be in detection range")
	_check(enemy.has_line_of_sight_to_player(), "return reveal must have LOS")
	_tick(0.1, "return reveal")
	_check(enemy.state_machine.phase == EnemyStateMachine.Phase.PURSUIT, "RETURN must reacquire within 0.1 seconds")


func _test_full_return_idle_reveal() -> void:
	_reset_visible_encounter()
	player.global_position = Vector3(0.0, 0.0, -11.0)
	_check(_tick_until_phase(EnemyStateMachine.Phase.RETURN, 7.0, "full give-up"), "full give-up must enter RETURN")
	_check(_tick_until_phase(EnemyStateMachine.Phase.IDLE, 10.0, "walk home"), "RETURN must reach home and settle IDLE")
	player.global_position = Vector3(0.0, 0.0, 4.5)
	_check(enemy.has_line_of_sight_to_player(), "idle reveal must have LOS")
	_tick(0.1, "idle reveal")
	_check(enemy.state_machine.phase == EnemyStateMachine.Phase.PURSUIT, "IDLE must reacquire within 0.1 seconds")


func _test_low_cover() -> void:
	enemy.reset_enemy()
	enemy.global_position = Vector3(-3.8, 0.0, -1.8)
	player.global_position = Vector3(-3.8, 0.0, -5.2)
	_check(enemy.has_line_of_sight_to_player(), "waist-high LowBlock must not conceal a standing player")


func _reset_visible_encounter() -> void:
	enemy.reset_enemy()
	player.reset_player()
	enemy.global_position = enemy.home_position
	player.global_position = Vector3(0.0, 0.0, 4.5)
	elapsed = 0.0
	_tick(0.1, "initial sighting")
	_check(enemy.state_machine.phase == EnemyStateMachine.Phase.PURSUIT, "visible player must engage from IDLE")


func _tick_until_phase(target: EnemyStateMachine.Phase, timeout_seconds: float, label: String) -> bool:
	for _step in range(mini(ceili(timeout_seconds / STEP), MAX_STEPS)):
		_tick_once(label)
		if enemy.state_machine.phase == target:
			return true
	return false


func _tick(seconds: float, label: String) -> void:
	for _step in range(mini(ceili(seconds / STEP), MAX_STEPS)):
		_tick_once(label)


func _tick_once(label: String) -> void:
	var previous := enemy.state_machine.phase
	enemy._physics_process(STEP)
	elapsed += STEP
	if enemy.state_machine.phase != previous:
		print("TRACKING t=%.2f %-16s %s -> %s los=%s enemy=%s player=%s" % [
			elapsed,
			label,
			EnemyStateMachine.Phase.keys()[previous],
			EnemyStateMachine.Phase.keys()[enemy.state_machine.phase],
			enemy.has_line_of_sight_to_player(),
			enemy.global_position,
			player.global_position,
		])


func _is_engaged() -> bool:
	return enemy.state_machine.phase in [
		EnemyStateMachine.Phase.PURSUIT,
		EnemyStateMachine.Phase.WINDUP,
		EnemyStateMachine.Phase.ACTIVE,
		EnemyStateMachine.Phase.RECOVERY,
	]


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
