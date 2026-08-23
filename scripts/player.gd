class_name Player
extends CharacterBody3D
## Royal Forest player — first-person, slow deliberate pacing.
## Builds its own camera, bow viewmodel, and interaction ray in _ready.

const WALK_SPEED := 3.2          # deliberately slow — tension comes from pace
const ACCELERATION := 10.0
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0022

const INTERACT_RANGE := 2.6
const ARROW_SPAWN_AHEAD := 0.9   # spawn point ahead of the camera (m)
const DRAW_TIME := 0.55          # draw before the arrow is ready to loose
const MIN_DRAW_FRACTION := 0.35  # releasing early still fires, just weaker feel
const RELEASE_COOLDOWN := 0.35   # nock-another-arrow pause after a shot

var camera: Camera3D
var _pitch := 0.0
var _drawing := false
var _draw_t := 0.0
var _cooldown := 0.0
var _bare_hand_msg_cd := 0.0
var _ray: RayCast3D
var _bob_t := 0.0
var bow_holder: Node3D
var _bow_rest := Transform3D()


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

	_build_bow_viewmodel()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_bow_viewmodel() -> void:
	bow_holder = Node3D.new()
	bow_holder.visible = false
	camera.add_child(bow_holder)

	var spr := Sprite3D.new()
	spr.texture = load("res://assets/sprites/bow.png")
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = false
	spr.no_depth_test = true      # never clip into walls
	spr.render_priority = 10
	spr.pixel_size = 0.0018       # 256 px -> ~0.46 m
	spr.position = Vector3(0.34, -0.34, -0.66)
	spr.rotation_degrees = Vector3(-4, -10, -8)
	bow_holder.add_child(spr)
	_bow_rest = bow_holder.transform


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -PI / 2.0, PI / 2.0)
		camera.rotation.x = _pitch
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # recapture click does NOT fire
	elif event.is_action_pressed("attack"):
		_begin_draw()
	elif event.is_action_released("attack"):
		_release_draw()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_bare_hand_msg_cd = maxf(0.0, _bare_hand_msg_cd - delta)
	if bow_holder != null:
		bow_holder.visible = GameState.has_bow

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


# --------------------------------------------------------------------- combat

func _begin_draw() -> void:
	if GameState.dead or GameState.game_won or _drawing or _cooldown > 0.0:
		return
	if not GameState.has_bow:
		if _bare_hand_msg_cd <= 0.0:
			GameState.say("No weapon but my hands.")
			_bare_hand_msg_cd = 2.0
		return
	_drawing = true
	_draw_t = 0.0


func _release_draw() -> void:
	if not _drawing or GameState.dead or GameState.game_won:
		return
	_drawing = false
	if _draw_t < DRAW_TIME * MIN_DRAW_FRACTION:
		return   # tapped too fast — treat as a mispress, no arrow wasted... yet
	_cooldown = RELEASE_COOLDOWN
	_fire_arrow()


func _fire_arrow() -> void:
	var forward := -camera.global_transform.basis.z
	var origin := camera.global_position + forward * ARROW_SPAWN_AHEAD
	var arrow := Arrow.new()
	arrow.position = origin
	# aim slightly up so gravity drop crosses the aim point at ~10 m
	arrow.velocity = forward.normalized() * Arrow.SPEED \
			+ Vector3.UP * Arrow.GRAVITY * (10.0 / Arrow.SPEED) * 0.5
	get_tree().current_scene.add_child(arrow)

	# quick release kick on the viewmodel
	bow_holder.transform = _bow_rest
	var tw := create_tween()
	tw.tween_property(bow_holder, "position:z", _bow_rest.origin.z + 0.05,
			0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(bow_holder, "position", _bow_rest.origin, 0.18)


func _process(delta: float) -> void:
	# draw pose: pull the viewmodel slightly toward center + back while drawing
	if _drawing and bow_holder != null:
		_draw_t += delta
		var f := clampf(_draw_t / DRAW_TIME, 0.0, 1.0)
		var target := _bow_rest.origin \
				+ Vector3(-0.06 * f, -0.02 * f, 0.07 * f)   # draw in and back
		bow_holder.position = bow_holder.position.lerp(target, 12.0 * delta)
