extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")
const ENEMY: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")


func test_restart_input_resets_player_and_enemy(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	playground.player.set_physics_process(false)
	playground.primary_enemy.set_physics_process(false)
	playground.player.stats.hp = 1.0
	playground.primary_enemy.hp = 1.0
	playground.primary_enemy.global_position += Vector3(2.0, 0.0, 0.0)
	var command := InputCommand.new()
	command.restart_pressed = true
	playground.player.simulate_command(command, 1.0 / 60.0)
	assertions.equal(playground.player.stats.hp, TUNING.max_hp, "restart input must reset player HP")
	assertions.equal(playground.primary_enemy.hp, ENEMY.max_hp, "restart input must reset enemy HP")
	assertions.equal(playground.primary_enemy.global_position, playground.primary_enemy.home_position, "restart input must reset enemy position")
	return true


func test_directional_motion_uses_tuning_and_stops(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	player.set_physics_process(false)
	var forward := _settle_motion(player, Vector2(0.0, -1.0))
	var strafe := _settle_motion(player, Vector2(1.0, 0.0))
	var backpedal := _settle_motion(player, Vector2(0.0, 1.0))
	assertions.is_true(absf(forward["speed"] - TUNING.walk_speed) < 0.01, "forward speed %.3f must match %.3f" % [forward["speed"], TUNING.walk_speed])
	assertions.is_true(absf(strafe["speed"] - TUNING.strafe_speed) < 0.01, "strafe speed %.3f must match %.3f" % [strafe["speed"], TUNING.strafe_speed])
	assertions.is_true(absf(backpedal["speed"] - TUNING.backpedal_speed) < 0.01, "backpedal speed %.3f must match %.3f" % [backpedal["speed"], TUNING.backpedal_speed])
	assertions.is_true(forward["distance"] > strafe["distance"] and strafe["distance"] > backpedal["distance"], "one-second displacement must preserve forward/strafe/backpedal ordering")
	var stop := InputCommand.new()
	for _step in range(30):
		player.simulate_command(stop, 1.0 / 60.0)
	assertions.is_true(Vector2(player.velocity.x, player.velocity.z).length() < 0.001, "released movement must decelerate to a stop")
	return true


func test_runtime_active_entry_commits_lane_and_flank_avoids_damage(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)

	# Enter WINDUP through the production controller, then move to the flank.
	enemy.global_position = Vector3.ZERO
	enemy.rotation.y = 0.0
	enemy.state_machine.reset()
	player.global_position = Vector3(0.0, 0.0, -1.2)
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.WINDUP, "production pursuit must enter WINDUP")
	player.global_position = Vector3(1.4, 0.0, 0.0)
	var hp_before := player.stats.hp
	var committed_position := enemy.global_position
	var completed_commitment := false
	var saw_active := false
	var active_facing_stayed_locked := true
	for _step in range(120):
		enemy._physics_process(1.0 / 60.0)
		if enemy.state_machine.phase == EnemyStateMachine.Phase.ACTIVE:
			saw_active = true
			active_facing_stayed_locked = active_facing_stayed_locked and (-enemy.global_transform.basis.z).normalized().is_equal_approx(enemy.committed_strike_direction)
		if enemy.state_machine.phase == EnemyStateMachine.Phase.PURSUIT:
			completed_commitment = true
			break
	assertions.is_true(completed_commitment, "production strike must complete windup/active/recovery")
	assertions.equal(player.stats.hp, hp_before, "flank outside committed red wedge must avoid production strike damage")
	assertions.is_true(Vector2(enemy.global_position.x, enemy.global_position.z).is_equal_approx(Vector2(committed_position.x, committed_position.z)), "enemy must not translate during committed windup/active/recovery")
	assertions.is_true(saw_active, "production strike must expose an ACTIVE frame")
	assertions.is_true(active_facing_stayed_locked, "red ACTIVE indicator facing must remain equal to the committed hit direction")
	assertions.is_false(enemy.committed_strike_direction.is_zero_approx(), "ACTIVE entry must snapshot a strike direction")

	# Repeat through the production path while staying in the visible lane.
	enemy.reset_enemy()
	enemy.global_position = Vector3.ZERO
	enemy.rotation.y = 0.0
	player.actions.reset()
	player.stats.hp = TUNING.max_hp
	player.global_position = Vector3(0.0, 0.0, -1.2)
	hp_before = player.stats.hp
	for _step in range(60):
		enemy._physics_process(1.0 / 60.0)
		if player.stats.hp < hp_before:
			break
	assertions.is_true(is_equal_approx(hp_before - player.stats.hp, ENEMY.damage), "target inside committed red wedge must take exactly one production strike")
	return true


func test_real_pillar_hide_reveal_and_return_reacquisition(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.reset_enemy()

	player.global_position = Vector3(0.0, 0.0, 4.5)
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.PURSUIT, "visible player must engage from IDLE")

	player.global_position = Vector3(5.6, 0.0, -3.5)
	assertions.is_false(enemy.has_line_of_sight_to_player(), "actual pillar must occlude the hidden player")
	var entered_search := false
	for _step in range(ceili((ENEMY.line_of_sight_grace_seconds + 0.25) * 60.0)):
		enemy._physics_process(1.0 / 60.0)
		if enemy.state_machine.phase == EnemyStateMachine.Phase.SEARCH:
			entered_search = true
			break
	assertions.is_true(entered_search, "continuous pillar occlusion must transition through SEARCH")

	player.global_position = Vector3(0.0, 0.0, 4.5)
	assertions.is_true(enemy.has_line_of_sight_to_player(), "revealed player must be visible after leaving pillar")
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.PURSUIT, "SEARCH must reacquire visible player on the next tick")

	# Slip outside the arena while occluded so the complete grace/search timeline
	# can expire without the enemy simply walking around the pillar and finding us.
	enemy.reset_enemy()
	player.global_position = Vector3(0.0, 0.0, 4.5)
	enemy._physics_process(1.0 / 60.0)
	player.global_position = Vector3(0.0, 0.0, -11.0)
	assertions.is_false(enemy.has_line_of_sight_to_player(), "north wall must conceal the escaped player")
	var entered_return := false
	for _step in range(ceili((ENEMY.line_of_sight_grace_seconds + ENEMY.search_duration_seconds + 0.5) * 60.0)):
		enemy._physics_process(1.0 / 60.0)
		if enemy.state_machine.phase == EnemyStateMachine.Phase.RETURN:
			entered_return = true
			break
	assertions.is_true(entered_return, "continuous loss must naturally complete grace/search and enter RETURN")
	var toward_home := enemy.home_position - enemy.global_position
	toward_home.y = 0.0
	player.global_position = enemy.global_position + toward_home.normalized() * 3.0
	assertions.is_true(enemy.global_position.distance_to(player.global_position) < ENEMY.detection_range, "return reveal must be inside detection range")
	assertions.is_true(enemy.has_line_of_sight_to_player(), "return reveal must have real LOS")
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.PURSUIT, "RETURN must reacquire visible player on the next tick")

	enemy.state_machine._enter(EnemyStateMachine.Phase.RETURN)
	enemy.global_position = enemy.home_position
	player.global_position = Vector3(5.6, 0.0, -3.5)
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.IDLE, "unobserved enemy at home must settle to IDLE")
	player.global_position = Vector3(0.0, 0.0, 4.5)
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.PURSUIT, "IDLE enemy must reacquire visible player")
	return true


func test_low_cover_does_not_block_eye_level_detection(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.global_position = Vector3(-3.8, 0.0, -1.8)
	player.global_position = Vector3(-3.8, 0.0, -5.2)
	assertions.is_true(enemy.has_line_of_sight_to_player(), "waist-high LowBlock must not hide a standing player from eye-level detection")
	return true


func test_real_low_cover_crouch_hide_and_stand_reveal_reacquisition(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.global_position = Vector3(-3.8, 0.0, -1.8)
	player.global_position = Vector3(-3.8, 0.0, -5.2)
	assertions.is_true(PlayerStance.STANDING_EYE_HEIGHT > 1.2 + 0.2, "standing eye must clear LowBlock with margin")
	assertions.is_true(PlayerStance.CROUCHED_EYE_HEIGHT < 1.2 - 0.2, "crouched eye must sit below LowBlock with margin")
	assertions.is_true(enemy.has_line_of_sight_to_player(), "standing setup must be visible")
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.PURSUIT, "standing player must engage")
	var crouch := InputCommand.new()
	crouch.crouch_pressed = true
	player.simulate_command(crouch, 0.25)
	assertions.is_false(enemy.has_line_of_sight_to_player(), "M2B1_CROUCH_BREAKS_LOS")
	var entered_search := false
	for _step in range(ceili((ENEMY.line_of_sight_grace_seconds + 0.25) * 60.0)):
		enemy._physics_process(1.0 / 60.0)
		if enemy.state_machine.phase == EnemyStateMachine.Phase.SEARCH:
			entered_search = true
			break
	assertions.is_true(entered_search, "continuous crouch concealment must enter SEARCH")
	var stand := InputCommand.new()
	stand.crouch_pressed = true
	player.simulate_command(stand, 0.25)
	assertions.is_true(enemy.has_line_of_sight_to_player(), "standing behind LowBlock must reveal player")
	enemy._physics_process(1.0 / 60.0)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.PURSUIT, "SEARCH must reacquire standing player on next tick")
	return true


func test_recorded_same_direction_search_route_does_not_stall_at_pillar_corner(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)

	# Exact failure geometry from rf-20260918-160214 at F10 mark 3. The old
	# pathfinder returned a corner 0.142 m away; the 0.15 m arrival tolerance
	# treated that intermediate waypoint as the final destination and stalled.
	enemy.global_position = Vector3(4.008135, 0.0, -2.855486)
	enemy.last_known_player_position = Vector3(2.976587, 0.0, 0.921867)
	player.global_position = Vector3(2.255312, 0.0, 0.863481)
	enemy.state_machine._enter(EnemyStateMachine.Phase.SEARCH)
	assertions.is_false(enemy.has_line_of_sight_to_player(), "recorded same-direction hide must remain pillar-occluded")
	var start := enemy.global_position
	var start_remaining := start.distance_to(enemy.last_known_player_position)
	for _step in range(30):
		enemy._physics_process(1.0 / 60.0)
	assertions.is_true(enemy.global_position.distance_to(start) > 0.25, "SEARCH must advance past a near intermediate corner instead of stalling")
	assertions.is_true(enemy.global_position.distance_to(enemy.last_known_player_position) < start_remaining, "SEARCH must make progress toward the recorded last-known position")
	return true


func test_recorded_green_recovery_reaims_at_full_pursuit_speed(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)

	# Exact geometry from rf-20260918-163816 at F10 mark 1. The old controller
	# held -106 degrees throughout green RECOVERY while the player was 91 degrees
	# off-axis, allowing each circle-strafe cycle to increase the facing error.
	enemy.global_position = Vector3(1.254006, 0.0, 1.343229)
	enemy.rotation.y = deg_to_rad(-106.0)
	player.global_position = Vector3(1.665227, 0.0, -0.238169)
	enemy.state_machine._enter(EnemyStateMachine.Phase.RECOVERY)
	var initial_error := _facing_error_degrees(enemy, player.global_position)
	assertions.is_true(initial_error > 90.0, "recorded recovery setup must begin more than 90 degrees off target")
	# Continue the recorded circle-strafe at the player's 2.9 m/s strafe speed.
	# A 180-degree/s recovery still loses this race from mark 2's 146-degree
	# error; the full green turn rate must catch it within 0.30 seconds.
	var radius := enemy.global_position.distance_to(player.global_position)
	var orbit_angle := atan2(player.global_position.z - enemy.global_position.z, player.global_position.x - enemy.global_position.x)
	var angular_speed := TUNING.strafe_speed / radius
	for _step in range(18):
		orbit_angle += angular_speed / 60.0
		player.global_position = enemy.global_position + Vector3(cos(orbit_angle) * radius, 0.0, sin(orbit_angle) * radius)
		enemy._physics_process(1.0 / 60.0)
	var final_error := _facing_error_degrees(enemy, player.global_position)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.RECOVERY, "0.30-second re-aim must remain inside green recovery")
	assertions.is_true(final_error < 5.0, "green RECOVERY must rapidly catch a full-speed circle-strafe target")
	return true


func test_cast_uses_camera_forward_including_pitch(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	player.set_physics_process(false)
	player.look_pitch = deg_to_rad(-30.0)
	player.camera.rotation.x = player.look_pitch
	var capture := {"count": 0, "origin": Vector3.ZERO, "direction": Vector3.ZERO}
	player.cast_requested.connect(func(origin: Vector3, direction: Vector3) -> void:
		capture["count"] += 1
		capture["origin"] = origin
		capture["direction"] = direction
	)
	var command := InputCommand.new()
	command.cast_pressed = true
	player.simulate_command(command, 0.0)
	player.simulate_command(InputCommand.new(), player.actions.spell.cast_windup_seconds)
	var expected := (-player.camera.global_transform.basis.z).normalized()
	assertions.equal(capture["count"], 1)
	assertions.is_true(capture["direction"].is_equal_approx(expected), "release direction must use normalized camera forward")
	assertions.is_true(absf(capture["direction"].y) > 0.2, "camera pitch must affect free aim")
	assertions.is_true(capture["origin"].is_equal_approx(player.camera.global_position), "bolt collision sweep must begin at the camera without a muzzle gap")
	return true

func test_production_cast_cannot_cross_thin_wall_at_camera(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var direction := (-player.camera.global_transform.basis.z).normalized()
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.0, 0.1)
	collision.shape = shape
	wall.add_child(collision)
	playground.add_child(wall)
	wall.global_position = player.camera.global_position + direction * 0.3
	await fixture.physics_frames(1)
	var hp_before := enemy.hp
	var command := InputCommand.new()
	command.cast_pressed = true
	player.simulate_command(command, 0.0)
	player.simulate_command(InputCommand.new(), player.actions.spell.cast_windup_seconds)
	var projectile := playground.get_children().filter(func(child: Node) -> bool: return child is SpellProjectile)
	assertions.equal(projectile.size(), 1, "production cast must spawn one bolt before collision resolution")
	await fixture.physics_frames(2)
	assertions.equal(enemy.hp, hp_before, "thin wall between camera and muzzle distance must block Spectral Bolt")
	if not projectile.is_empty():
		assertions.is_false(is_instance_valid(projectile[0]), "wall-blocked bolt must despawn")
	return true

func test_playground_bolt_damages_once_spends_and_regenerates_mana(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	var enemy := playground.primary_enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	var hp_before := enemy.hp
	var command := InputCommand.new()
	command.cast_pressed = true
	player.simulate_command(command, 0.0)
	assertions.equal(player.stats.mana, 75.0, "accepted playground cast must spend authored cost")
	player.simulate_command(InputCommand.new(), player.actions.spell.cast_windup_seconds)
	await fixture.physics_frames(20)
	assertions.equal(enemy.hp, hp_before - 30.0, "free-aim path must damage Shambler once")
	await fixture.physics_frames(5)
	assertions.equal(enemy.hp, hp_before - 30.0)
	player.stats.advance(3.0)
	assertions.is_true(player.stats.mana > 75.0, "mana must regenerate after the two-second post-cast delay")
	return true

func _facing_error_degrees(enemy: EnemyController, target: Vector3) -> float:
	var offset := target - enemy.global_position
	var target_yaw := atan2(-offset.x, -offset.z)
	return absf(rad_to_deg(wrapf(target_yaw - enemy.rotation.y, -PI, PI)))


func _settle_motion(player: PlayerController, direction: Vector2) -> Dictionary:
	player.velocity = Vector3.ZERO
	var distance := 0.0
	var command := InputCommand.new()
	command.move = direction
	for _step in range(60):
		player.simulate_command(command, 1.0 / 60.0)
		distance += Vector2(player.velocity.x, player.velocity.z).length() / 60.0
	return {
		"speed": Vector2(player.velocity.x, player.velocity.z).length(),
		"distance": distance,
	}
