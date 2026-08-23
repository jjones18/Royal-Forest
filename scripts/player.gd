class_name Player
extends CharacterBody3D
## Royal Forest player — first-person, slow deliberate pacing.
## Builds its own camera, sword viewmodel, and interaction ray in _ready.

const WALK_SPEED := 3.2          # deliberately slow — tension comes from pace
const ACCELERATION := 10.0
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0022

const INTERACT_RANGE := 2.6
const ATTACK_RANGE := 2.4        # reach of the swing (sphere center distance)
const ATTACK_RADIUS := 1.1       # swing sweep radius
const ATTACK_ARC_COS := 0.35     # ~70 degree half-cone acceptance
const ATTACK_DAMAGE := 34
const SWING_TIME := 0.45
const SWING_COOLDOWN := 0.75

var camera: Camera3D
var _pitch := 0.0
var _cooldown := 0.0
var _swinging := false
var _bare_hand_msg_cd := 0.0
var _ray: RayCast3D
var _bob_t := 0.0
var sword_holder: Node3D
var _sword_rest := Transform3D()


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4   # world + enemies (so we can't ghost through foes)

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)

	camera = Camera3D.new()
	camera.position = Vector3(0, 1.6, 0)
	camera.fov = 70.0
	add_child(camera)
	camera.make_current()

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -INTERACT_RANGE)
	_ray.collide_with_areas = true
	_ray.collision_mask = 1
	camera.add_child(_ray)

	_build_sword_viewmodel()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_sword_viewmodel() -> void:
	sword_holder = Node3D.new()
	sword_holder.visible = false
	camera.add_child(sword_holder)

	var spr := Sprite3D.new()
	spr.texture = load("res://assets/sprites/sword.png")
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = false
	spr.no_depth_test = true      # never clip into walls
	spr.render_priority = 10
	spr.pixel_size = 0.0018       # 256 px -> ~0.46 m
	spr.position = Vector3(0.44, -0.40, -0.66)
	spr.rotation_degrees = Vector3(-6, -14, -14)
	sword_holder.add_child(spr)
	_sword_rest = sword_holder.transform


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -PI / 2.0, PI / 2.0)
		camera.rotation.x = _pitch
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # recapture click does NOT swing
	elif event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_bare_hand_msg_cd = maxf(0.0, _bare_hand_msg_cd - delta)
	if sword_holder != null:
		sword_holder.visible = GameState.has_sword

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = move_toward(velocity.x, direction.x * WALK_SPEED, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * WALK_SPEED, ACCELERATION * delta)

	move_and_slide()

	_update_interaction_hint()
	_update_head_bob(delta, direction)


func _update_head_bob(delta: float, direction: Vector3) -> void:
	if direction.length() > 0.1 and is_on_floor():
		_bob_t += delta * 7.5
	else:
		_bob_t = lerpf(_bob_t, roundf(_bob_t / PI) * PI, 8.0 * delta)
	camera.position.y = 1.6 + sin(_bob_t) * 0.035


# ------------------------------------------------------------------ interact

func _update_interaction_hint() -> void:
	if GameState.dead or GameState.game_won:
		GameState.set_hint("")
		return
	var col := _ray.get_collider()
	if col != null and col.has_method("interact_hint"):
		GameState.set_hint("[E] " + col.interact_hint())
	else:
		GameState.set_hint("")


func _try_interact() -> void:
	if GameState.dead or GameState.game_won:
		return
	var col := _ray.get_collider()
	if col != null and col.has_method("interact"):
		col.interact()


# ------------------------------------------------------------------- combat

func _try_attack() -> void:
	if GameState.dead or GameState.game_won or _swinging or _cooldown > 0.0:
		return
	if not GameState.has_sword:
		if _bare_hand_msg_cd <= 0.0:
			GameState.say("Empty hands. I need a weapon.")
			_bare_hand_msg_cd = 2.0
		return
	_swinging = true
	_cooldown = SWING_COOLDOWN
	_animate_swing()
	await get_tree().create_timer(SWING_TIME * 0.35).timeout
	if not is_inside_tree():
		return
	_apply_hit()
	await get_tree().create_timer(SWING_TIME * 0.65).timeout
	if not is_inside_tree():
		return
	_swinging = false


func _animate_swing() -> void:
	sword_holder.transform = _sword_rest
	var tw := create_tween()
	tw.tween_property(sword_holder, "rotation_degrees",
			Vector3(-30, 10, 74), SWING_TIME * 0.4)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sword_holder, "rotation_degrees",
			Vector3(0, 0, 0), SWING_TIME * 0.6)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _apply_hit() -> void:
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var center := camera.global_position + forward * ATTACK_RANGE
	center.y -= 1.2  # bring sweep down to torso height (camera is at 1.6)

	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ATTACK_RADIUS
	params.shape = sphere
	params.transform = Transform3D(Basis.IDENTITY, center)
	params.collision_mask = 4  # enemies layer
	params.exclude = [get_rid()]

	var hits := get_world_3d().direct_space_state.intersect_shape(params, 8)
	var struck_any := false
	for hit in hits:
		var c: Object = hit["collider"]
		if c == null or not c.has_method("take_damage"):
			continue
		var to_c: Vector3 = c.global_position - global_position
		to_c.y = 0.0
		if to_c.length() < 0.01 or forward.dot(to_c.normalized()) >= ATTACK_ARC_COS:
			c.take_damage(ATTACK_DAMAGE, global_position)
			struck_any = true
	if struck_any:
		GameState.say("")  # clear stale hints quickly (hit feedback comes from flash/knockback)
