class_name PlayerController
extends CharacterBody3D

signal attack_requested
signal cast_requested(origin: Vector3, direction: Vector3)
signal restart_requested
signal combat_feedback(kind: StringName, text: String)

const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")
var stats := PlayerStats.new(TUNING)
var vessel := HealingVessel.new()
var actions := PlayerActionMachine.new(stats, TUNING, null, vessel)
var input_router: InputRouter
var camera: Camera3D
var viewmodel: PlayerViewmodel
var look_pitch := 0.0
var spawn_transform: Transform3D

func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.position.y = 1.62
	camera.fov = TUNING.fov
	camera.current = true
	add_child(camera)
	viewmodel = PlayerViewmodel.new()
	viewmodel.player = self
	camera.add_child(viewmodel)
	input_router = InputRouter.new()
	add_child(input_router)
	spawn_transform = transform
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var command := input_router.sample()
	simulate_command(command, delta)

func simulate_command(command: InputCommand, delta: float) -> void:
	apply_command(command, delta)
	actions.advance(delta)
	if actions.consume_attack_hit():
		attack_requested.emit()
	if actions.consume_cast_release():
		var cast_direction := (-camera.global_transform.basis.z).normalized()
		cast_requested.emit(camera.global_position, cast_direction)
	if actions.consume_heal_tick():
		var restored := stats.heal(vessel.heal_amount(stats.tuning.max_hp))
		combat_feedback.emit(&"healed", "HEALED  +%.0f" % restored)
	if actions.phase == PlayerActionMachine.Phase.DODGE:
		var local_dodge := Vector3(actions.dodge_direction.x, 0.0, actions.dodge_direction.y)
		var world_dodge := global_transform.basis * local_dodge
		velocity.x = world_dodge.x * actions.dodge_speed()
		velocity.z = world_dodge.z * actions.dodge_speed()
	move_and_slide()

func apply_command(command: InputCommand, delta: float) -> void:
	var look_delta := command.look * TUNING.mouse_sensitivity + command.look_rate * TUNING.stick_look_speed * delta
	rotate_y(-look_delta.x)
	look_pitch = clampf(look_pitch - look_delta.y, deg_to_rad(-85.0), deg_to_rad(85.0))
	camera.rotation.x = look_pitch
	if command.release_mouse_pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if command.restart_pressed:
		restart_requested.emit()
	if command.attack_pressed:
		actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	if command.cast_pressed:
		actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST))
	if command.heal_pressed:
		actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL))
	if command.dodge_pressed:
		actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE, command.move))
	if command.guard_released:
		actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_END))
	elif command.guard_held and actions.phase == PlayerActionMachine.Phase.FREE:
		actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START))
	if actions.phase in [PlayerActionMachine.Phase.FREE, PlayerActionMachine.Phase.GUARD]:
		var local := Vector3(command.move.x, 0.0, command.move.y)
		var speed := TUNING.walk_speed
		if command.move.y > 0.0: speed = TUNING.backpedal_speed
		elif absf(command.move.x) > absf(command.move.y): speed = TUNING.strafe_speed
		if actions.phase == PlayerActionMachine.Phase.GUARD: speed *= TUNING.guard_move_multiplier
		var target := global_transform.basis * local.normalized() * speed if local.length() > 0.0 else Vector3.ZERO
		velocity.x = move_toward(velocity.x, target.x, TUNING.acceleration * delta)
		velocity.z = move_toward(velocity.z, target.z, TUNING.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, TUNING.acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, TUNING.acceleration * delta)

func receive_enemy_damage(amount: float) -> float:
	var was_guarding := actions.phase == PlayerActionMachine.Phase.GUARD
	var applied := actions.receive_damage(amount)
	if applied <= 0.0:
		return applied
	if was_guarding:
		viewmodel.play_block_recoil(TUNING.guard_block_recoil_seconds)
	if was_guarding and actions.phase == PlayerActionMachine.Phase.GUARD_BROKEN:
		combat_feedback.emit(&"guard_broken", "GUARD BROKEN — %.1f CHIP" % applied)
	elif was_guarding:
		combat_feedback.emit(&"blocked", "BLOCKED — %.1f CHIP" % applied)
	else:
		combat_feedback.emit(&"hurt", "HURT — %.1f" % applied)
	return applied

func confirm_player_hit(hit_count: int, damage_each: float) -> void:
	if hit_count > 0:
		combat_feedback.emit(&"hit", "HIT  +%.0f%s" % [damage_each, "  x%d" % hit_count if hit_count > 1 else ""])

func reset_player() -> void:
	actions.reset()
	vessel.refill()
	transform = spawn_transform
	velocity = Vector3.ZERO
