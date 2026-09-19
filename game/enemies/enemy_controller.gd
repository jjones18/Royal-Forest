class_name EnemyController
extends CharacterBody3D

const DEFAULT_DEFINITION: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")
const StrikeGeometry = preload("res://game/enemies/enemy_strike_geometry.gd")

@export var definition: EnemyDefinition = DEFAULT_DEFINITION
var state_machine := EnemyStateMachine.new()
var hp := 0.0
var player: PlayerController
var home_position := Vector3.ZERO
var last_known_player_position := Vector3.ZERO
var committed_strike_direction := Vector3.ZERO
var navigation_obstacles: Array[Rect2] = []
var display_mesh: MeshInstance3D
var attack_indicator: MeshInstance3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("combat_targets")
	home_position = global_position
	last_known_player_position = home_position
	hp = definition.max_hp
	state_machine.configure(definition)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.65
	shape.shape = capsule
	shape.position.y = 0.83
	add_child(shape)
	display_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.48
	body.height = 1.65
	display_mesh.mesh = body
	display_mesh.position.y = 0.83
	add_child(display_mesh)
	attack_indicator = MeshInstance3D.new()
	attack_indicator.name = "ActiveStrike"
	attack_indicator.mesh = StrikeGeometry.build_wedge_mesh(_strike_reach(), definition.attack_arc_degrees)
	attack_indicator.position = Vector3(0.0, 0.06, 0.0)
	var strike_material := StandardMaterial3D.new()
	strike_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	strike_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strike_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	strike_material.albedo_color = Color(1.0, 0.28, 0.02, 0.52)
	attack_indicator.material_override = strike_material
	attack_indicator.visible = false
	add_child(attack_indicator)
	_update_color()

func _physics_process(delta: float) -> void:
	if player == null or state_machine.phase == EnemyStateMachine.Phase.DEAD:
		velocity = Vector3.ZERO
		return
	var distance := global_position.distance_to(player.global_position)
	var los := has_line_of_sight_to_player()
	if los:
		last_known_player_position = player.global_position
	state_machine.update_awareness(los, distance <= definition.detection_range, global_position.distance_to(home_position) > definition.leash_range, delta)
	match state_machine.phase:
		EnemyStateMachine.Phase.PURSUIT:
			var pursuit_target := player.global_position if los else last_known_player_position
			turn_toward_position(pursuit_target, definition.pursuit_turn_speed_degrees, delta)
			if los and distance <= definition.attack_range:
				state_machine.request_attack(true, true)
			else:
				_move_toward_destination(pursuit_target, definition.move_speed)
		EnemyStateMachine.Phase.WINDUP:
			velocity = Vector3.ZERO
			if los:
				turn_toward_position(player.global_position, definition.windup_turn_speed_degrees, delta)
		EnemyStateMachine.Phase.RECOVERY:
			velocity = Vector3.ZERO
			if los:
				turn_toward_position(player.global_position, definition.pursuit_turn_speed_degrees, delta)
		EnemyStateMachine.Phase.SEARCH:
			if global_position.distance_to(last_known_player_position) <= definition.home_arrival_tolerance:
				velocity = Vector3.ZERO
				_scan_for_player(delta)
			else:
				turn_toward_position(last_known_player_position, definition.pursuit_turn_speed_degrees, delta)
				_move_toward_destination(last_known_player_position, definition.move_speed * definition.search_speed_multiplier)
		EnemyStateMachine.Phase.RETURN:
			if global_position.distance_to(home_position) <= definition.home_arrival_tolerance:
				global_position = home_position
				velocity = Vector3.ZERO
				state_machine.arrive_home()
			else:
				turn_toward_position(home_position, definition.pursuit_turn_speed_degrees, delta)
				_move_toward_destination(home_position, definition.move_speed)
		_:
			velocity = Vector3.ZERO
	var previous_phase := state_machine.phase
	state_machine.advance(delta)
	if previous_phase != EnemyStateMachine.Phase.ACTIVE and state_machine.phase == EnemyStateMachine.Phase.ACTIVE:
		commit_strike_direction()
		# Freeze the visible red cone in the same committed world direction as the hit test.
		global_rotation.y = atan2(-committed_strike_direction.x, -committed_strike_direction.z)
	if state_machine.consume_strike() and can_committed_strike_hit(player.global_position) and has_line_of_sight_to_player():
		player.receive_enemy_damage(definition.damage)
	_update_color()


func commit_strike_direction() -> void:
	committed_strike_direction = -global_transform.basis.z
	committed_strike_direction.y = 0.0
	committed_strike_direction = committed_strike_direction.normalized()


func turn_toward_position(target: Vector3, speed_degrees: float, delta: float) -> void:
	var offset := target - global_position
	if Vector2(offset.x, offset.z).length() <= 0.0001 or speed_degrees <= 0.0:
		return
	var target_yaw := atan2(-offset.x, -offset.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, deg_to_rad(speed_degrees) * maxf(delta, 0.0))

func can_committed_strike_hit(target_position: Vector3) -> bool:
	if committed_strike_direction.is_zero_approx():
		return false
	return StrikeGeometry.contains_world_offset(
		target_position - global_position,
		committed_strike_direction,
		_strike_reach(),
		definition.attack_arc_degrees
	)


func _strike_reach() -> float:
	return definition.attack_range + definition.attack_reach_lenience

func has_line_of_sight_to_player() -> bool:
	if player == null or not is_inside_tree():
		return false
	# Eye-to-upper-torso sight keeps waist-high cover from behaving like a full
	# wall while the three-metre pillar still provides genuine concealment.
	var origin := global_position + Vector3.UP * 1.35
	var target := player.global_position + Vector3.UP * 1.4
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _scan_for_player(delta: float) -> void:
	var scan_direction := 1.0 if int(state_machine.search_elapsed / 1.25) % 2 == 0 else -1.0
	rotate_y(deg_to_rad(definition.windup_turn_speed_degrees) * scan_direction * maxf(delta, 0.0))


func configure_navigation_obstacles(obstacles: Array[Rect2]) -> void:
	navigation_obstacles = obstacles.duplicate()

func _move_toward_destination(destination: Vector3, speed: float) -> void:
	var waypoint := ArenaPathfinder.next_corner(global_position, destination, navigation_obstacles, definition.navigation_clearance)
	var offset := waypoint - global_position
	offset.y = 0.0
	var waypoint_is_destination := Vector2(waypoint.x, waypoint.z).is_equal_approx(Vector2(destination.x, destination.z))
	var arrival_tolerance := definition.home_arrival_tolerance if waypoint_is_destination else 0.01
	if offset.length() <= arrival_tolerance:
		velocity = Vector3.ZERO
		return
	velocity = offset.normalized() * speed
	move_and_slide()

func take_hit(amount: float, source_position := Vector3.ZERO) -> void:
	if state_machine.phase == EnemyStateMachine.Phase.DEAD:
		return
	hp = maxf(0.0, hp - amount)
	var away := Vector3(global_position.x - source_position.x, 0.0, global_position.z - source_position.z)
	if not away.is_zero_approx():
		move_and_collide(away.normalized() * definition.hit_nudge_distance)
	if hp <= 0.0:
		state_machine.die()
		visible = false
		collision_layer = 0
	else:
		state_machine.stagger()
	_update_color()

func reset_enemy() -> void:
	hp = definition.max_hp
	global_position = home_position
	last_known_player_position = home_position
	committed_strike_direction = Vector3.ZERO
	visible = true
	collision_layer = 4
	state_machine.reset()
	_update_color()

func _update_color() -> void:
	if display_mesh == null:
		return
	if attack_indicator != null:
		attack_indicator.visible = state_machine.phase == EnemyStateMachine.Phase.ACTIVE
	var material := StandardMaterial3D.new()
	match state_machine.phase:
		EnemyStateMachine.Phase.WINDUP: material.albedo_color = Color(1.0, 0.7, 0.15)
		EnemyStateMachine.Phase.ACTIVE: material.albedo_color = Color(1.0, 0.1, 0.05)
		EnemyStateMachine.Phase.SEARCH: material.albedo_color = Color(0.5, 0.45, 0.18)
		EnemyStateMachine.Phase.HURT: material.albedo_color = Color(0.95, 0.95, 1.0)
		_: material.albedo_color = Color(0.25, 0.55, 0.22)
	display_mesh.material_override = material
