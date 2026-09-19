extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const PLAYER_SCENE := preload("res://game/player/player_controller.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")


func test_literal_stance_tuning_is_exact(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal(PlayerStance.STANDING_EYE_HEIGHT, 1.62)
	assertions.equal(PlayerStance.CROUCHED_EYE_HEIGHT, 0.95)
	assertions.equal(PlayerStance.STANDING_CAPSULE_HEIGHT, 1.8)
	assertions.equal(PlayerStance.CROUCHED_CAPSULE_HEIGHT, 1.10)
	assertions.equal(PlayerStance.TRANSITION_SPEED, 4.0)
	assertions.equal(PlayerStance.CROUCH_SPEED_MULTIPLIER, 0.40, "M2B1_CROUCH_SPEED_EXACT")
	return true


func test_toggle_converges_monotonically_and_exactly(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stance := PlayerStance.new()
	assertions.is_false(stance.crouching)
	stance.toggle()
	assertions.is_true(stance.crouching)
	var previous_eye := stance.current_eye_height
	var previous_capsule := stance.current_capsule_height
	for _step in range(30):
		stance.advance(1.0 / 60.0)
		assertions.is_true(stance.current_eye_height <= previous_eye, "crouch eye transition must be monotonic")
		assertions.is_true(stance.current_capsule_height <= previous_capsule, "crouch capsule transition must be monotonic")
		previous_eye = stance.current_eye_height
		previous_capsule = stance.current_capsule_height
	assertions.equal(stance.current_eye_height, PlayerStance.CROUCHED_EYE_HEIGHT)
	assertions.equal(stance.current_capsule_height, PlayerStance.CROUCHED_CAPSULE_HEIGHT)
	stance.toggle()
	stance.advance(1.0)
	assertions.is_false(stance.crouching)
	assertions.equal(stance.current_eye_height, PlayerStance.STANDING_EYE_HEIGHT)
	assertions.equal(stance.current_capsule_height, PlayerStance.STANDING_CAPSULE_HEIGHT)
	return true


func test_large_delta_clamps_and_split_steps_are_equivalent(assertions: Assertions, _fixture: RefCounted) -> bool:
	var large := PlayerStance.new()
	large.request_crouch()
	large.advance(100.0)
	assertions.equal(large.current_eye_height, PlayerStance.CROUCHED_EYE_HEIGHT)
	assertions.equal(large.current_capsule_height, PlayerStance.CROUCHED_CAPSULE_HEIGHT)
	var one_step := PlayerStance.new()
	var split := PlayerStance.new()
	one_step.request_crouch()
	split.request_crouch()
	one_step.advance(0.1)
	for _step in range(10):
		split.advance(0.01)
	assertions.is_true(is_equal_approx(one_step.current_eye_height, split.current_eye_height), "eye transition must be split-step equivalent")
	assertions.is_true(is_equal_approx(one_step.current_capsule_height, split.current_capsule_height), "capsule transition must be split-step equivalent")
	return true


func test_speed_multiplier_tracks_requested_stance(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stance := PlayerStance.new()
	assertions.equal(stance.speed_multiplier(), 1.0)
	stance.request_crouch()
	assertions.equal(stance.speed_multiplier(), 0.40, "M2B1_CROUCH_SPEED_EXACT")
	stance.request_stand()
	assertions.equal(stance.speed_multiplier(), 1.0)
	return true


func test_controller_toggle_updates_camera_capsule_speed_and_reset(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)
	if not _has_property(player, "stance"):
		assertions.fail("controller must own PlayerStance")
		return true
	var crouch := InputCommand.new()
	crouch.crouch_pressed = true
	player.simulate_command(crouch, 0.0)
	for _step in range(20):
		player.simulate_command(InputCommand.new(), 1.0 / 60.0)
	assertions.is_true(player.stance.crouching)
	assertions.is_true(is_equal_approx(player.camera.position.y, PlayerStance.CROUCHED_EYE_HEIGHT))
	assertions.is_true(is_equal_approx(player.collision_shape.position.y, PlayerStance.CROUCHED_CAPSULE_HEIGHT * 0.5))
	assertions.is_true(is_equal_approx((player.collision_shape.shape as CapsuleShape3D).height, PlayerStance.CROUCHED_CAPSULE_HEIGHT))
	player.velocity = Vector3.ZERO
	var move := InputCommand.new()
	move.move = Vector2(0.0, -1.0)
	for _step in range(60):
		player.simulate_command(move, 1.0 / 60.0)
	assertions.is_true(absf(Vector2(player.velocity.x, player.velocity.z).length() - PlayerController.TUNING.walk_speed * 0.40) < 0.001, "M2B1_CROUCH_SPEED_EXACT")
	player.reset_player()
	assertions.is_false(player.stance.crouching)
	assertions.is_true(is_equal_approx(player.camera.position.y, PlayerStance.STANDING_EYE_HEIGHT))
	assertions.is_true(is_equal_approx((player.collision_shape.shape as CapsuleShape3D).height, PlayerStance.STANDING_CAPSULE_HEIGHT))
	return true


func test_standing_requires_real_headroom(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)
	if not _has_property(player, "stance"):
		assertions.fail("M2B1_STAND_REQUIRES_HEADROOM")
		return true
	_toggle_and_settle(player)
	var ceiling := _ceiling()
	fixture.add_node(ceiling)
	await fixture.physics_frames(2)
	var stand := InputCommand.new()
	stand.crouch_pressed = true
	player.simulate_command(stand, 0.25)
	assertions.is_true(player.stance.crouching, "M2B1_STAND_REQUIRES_HEADROOM")
	assertions.is_true(is_equal_approx((player.collision_shape.shape as CapsuleShape3D).height, PlayerStance.CROUCHED_CAPSULE_HEIGHT), "blocked stand must retain short capsule")
	assertions.is_true(player.collision_shape.position.y + PlayerStance.CROUCHED_CAPSULE_HEIGHT * 0.5 <= 1.15 + 0.0001, "blocked stand must not clip into ceiling")
	ceiling.queue_free()
	await fixture.physics_frames(2)
	player.simulate_command(stand, 0.25)
	assertions.is_false(player.stance.crouching, "stand toggle must succeed after obstruction clears")
	assertions.is_true(is_equal_approx((player.collision_shape.shape as CapsuleShape3D).height, PlayerStance.STANDING_CAPSULE_HEIGHT))
	return true


func test_mid_transition_obstruction_reverses_to_safe_crouch(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)
	_toggle_and_settle(player)

	var stand := InputCommand.new()
	stand.crouch_pressed = true
	player.simulate_command(stand, 0.02)
	assertions.is_false(player.stance.crouching, "clear headroom must begin standing transition")
	assertions.is_true(player.stance.current_capsule_height > PlayerStance.CROUCHED_CAPSULE_HEIGHT)
	assertions.is_true(player.stance.current_capsule_height < PlayerStance.STANDING_CAPSULE_HEIGHT)

	var ceiling := _ceiling()
	fixture.add_node(ceiling)
	await fixture.physics_frames(2)
	player.simulate_command(InputCommand.new(), 0.25)
	assertions.is_true(player.stance.crouching, "M2B1_STAND_REQUIRES_HEADROOM: new obstruction must reverse an incomplete stand")
	assertions.is_true(is_equal_approx(player.stance.current_capsule_height, PlayerStance.CROUCHED_CAPSULE_HEIGHT))
	assertions.is_true(is_equal_approx((player.collision_shape.shape as CapsuleShape3D).height, PlayerStance.CROUCHED_CAPSULE_HEIGHT))
	return true


func test_dodge_forces_safe_stand_or_is_blocked_without_spending(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)
	if not _has_property(player, "stance"):
		assertions.fail("controller dodge must coordinate with stance")
		return true
	_toggle_and_settle(player)
	var dodge := InputCommand.new()
	dodge.dodge_pressed = true
	dodge.move = Vector2(0.0, -1.0)
	player.simulate_command(dodge, 0.0)
	assertions.is_false(player.stance.crouching, "clear-headroom dodge must force immediate stand")
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.DODGE)

	player.reset_player()
	_toggle_and_settle(player)
	player.stats.stamina = TUNING.dodge_stamina_cost - 0.01
	player.simulate_command(dodge, 0.0)
	assertions.is_true(player.stance.crouching, "insufficient stamina must reject before standing preparation")
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(player.actions.blocked_reason, "insufficient stamina")

	player.reset_player()
	_toggle_and_settle(player)
	var ceiling := _ceiling()
	fixture.add_node(ceiling)
	await fixture.physics_frames(2)
	var stamina_before := player.stats.stamina
	player.simulate_command(dodge, 0.0)
	assertions.is_true(player.stance.crouching, "blocked-headroom dodge must remain crouched")
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE, "blocked-headroom dodge must not start")
	assertions.equal(player.stats.stamina, stamina_before, "blocked-headroom dodge must not spend stamina")
	return true


func test_crouch_is_ignored_during_committed_dodge(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)

	var dodge := InputCommand.new()
	dodge.dodge_pressed = true
	dodge.move = Vector2(0.0, -1.0)
	player.simulate_command(dodge, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.DODGE)

	var crouch := InputCommand.new()
	crouch.crouch_pressed = true
	while player.actions.phase == PlayerActionMachine.Phase.DODGE:
		assertions.is_false(player.stance.crouching, "M2B1_DODGE_REQUIRES_STANDING: committed dodge must ignore crouch toggles")
		assertions.is_true(is_equal_approx(player.stance.current_capsule_height, PlayerStance.STANDING_CAPSULE_HEIGHT), "committed dodge must retain standing capsule height")
		assertions.is_true(is_equal_approx(player.stance.current_eye_height, PlayerStance.STANDING_EYE_HEIGHT), "committed dodge must retain standing eye height")
		player.simulate_command(crouch, 0.05)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE)
	assertions.is_false(player.stance.crouching, "the final committed frame must ignore crouch before DODGE exits")
	return true


func test_buffered_dodge_stands_at_actual_commitment(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)

	player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	var attack_total := TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds
	player.actions.advance(attack_total - 0.1)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.ATTACK_RECOVERY)

	var dodge := InputCommand.new()
	dodge.dodge_pressed = true
	dodge.move = Vector2.RIGHT
	player.simulate_command(dodge, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.ATTACK_RECOVERY, "accepted buffer must not commit early")

	var crouch := InputCommand.new()
	crouch.crouch_pressed = true
	player.simulate_command(crouch, 0.1)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.DODGE, "buffered dodge must commit after recovery")
	assertions.is_false(player.stance.crouching, "actual buffered-dodge commitment must force standing")
	assertions.is_true(is_equal_approx(player.stance.current_capsule_height, PlayerStance.STANDING_CAPSULE_HEIGHT))
	assertions.is_true(player.actions.dodge_direction.is_equal_approx(Vector2.RIGHT), "M2B1_BUFFERED_DODGE_DIRECTION: buffered commitment must use the requested direction")
	return true


func test_buffered_dodge_rechecks_new_headroom_without_spending(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)
	_toggle_and_settle(player)

	player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	var attack_total := TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds
	player.actions.advance(attack_total - 0.1)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.ATTACK_RECOVERY)
	var stamina_before_dodge := player.stats.stamina

	var dodge := InputCommand.new()
	dodge.dodge_pressed = true
	dodge.move = Vector2.RIGHT
	player.simulate_command(dodge, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.ATTACK_RECOVERY, "dodge must still be buffered")
	assertions.equal(player.stats.stamina, stamina_before_dodge, "buffering must not spend dodge stamina")

	var ceiling := _ceiling()
	fixture.add_node(ceiling)
	await fixture.physics_frames(2)
	player.simulate_command(InputCommand.new(), 0.1)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE, "M2B1_DODGE_REQUIRES_STANDING: newly blocked headroom must cancel buffered dodge")
	assertions.equal(player.stats.stamina, stamina_before_dodge, "cancelled buffered dodge must not spend stamina")
	assertions.is_true(player.stance.crouching, "cancelled buffered dodge must remain safely crouched")
	assertions.equal(player.actions.blocked_reason, "headroom blocked")
	return true


func test_combat_actions_remain_available_while_crouched(assertions: Assertions, fixture: RefCounted) -> bool:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	fixture.add_node(player)
	await fixture.physics_frames(2)
	player.set_physics_process(false)
	_toggle_and_settle(player)

	var attack := InputCommand.new()
	attack.attack_pressed = true
	player.simulate_command(attack, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.ATTACK_WINDUP, "crouch must not block attack")
	assertions.is_true(player.stance.crouching)

	var rejected_dodge := InputCommand.new()
	rejected_dodge.dodge_pressed = true
	player.simulate_command(rejected_dodge, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.ATTACK_WINDUP, "committed attack must still reject dodge")
	assertions.is_true(player.stance.crouching, "rejected dodge must not silently stand the player")

	player.actions.reset()
	var cast := InputCommand.new()
	cast.cast_pressed = true
	player.simulate_command(cast, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.CAST_WINDUP, "crouch must not block casting")
	assertions.is_true(player.stance.crouching)

	player.actions.reset()
	player.stats.hp = 50.0
	var heal := InputCommand.new()
	heal.heal_pressed = true
	player.simulate_command(heal, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.HEAL_WINDUP, "crouch must not block healing")
	assertions.is_true(player.stance.crouching)

	player.actions.reset()
	var guard := InputCommand.new()
	guard.guard_held = true
	player.simulate_command(guard, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.GUARD, "crouch must not block guard")
	assertions.is_true(player.stance.crouching)
	return true


func test_input_map_has_exact_nonconflicting_crouch_bindings(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.is_true(InputMap.has_action("crouch"), "crouch input action must exist")
	var saw_c := false
	var saw_down := false
	for event in InputMap.action_get_events("crouch"):
		if event is InputEventKey and event.physical_keycode == 67:
			saw_c = true
		if event is InputEventJoypadButton and event.button_index == 12:
			saw_down = true
	assertions.is_true(saw_c, "crouch must bind physical C (67)")
	assertions.is_true(saw_down, "crouch must bind joy button 12 / D-pad Down")
	for event in InputMap.action_get_events("heal"):
		if event is InputEventJoypadButton:
			assertions.equal(event.button_index, 11, "heal must remain D-pad Up and not collide with crouch")
	return true


func _toggle_and_settle(player: PlayerController) -> void:
	var command := InputCommand.new()
	command.crouch_pressed = true
	player.simulate_command(command, 0.25)


func _ceiling() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(0.0, 1.25, 0.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 0.2, 1.5)
	collision.shape = shape
	body.add_child(collision)
	return body


func _has_property(object: Object, property_name: String) -> bool:
	return object.get_property_list().any(func(info: Dictionary) -> bool: return info["name"] == property_name)
