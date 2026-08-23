extends CharacterBody3D
## Royal Forest player controller — first-person, King's Field pacing.
## Slow walk speed, full mouse look, click to recapture mouse.

const WALK_SPEED := 3.2          # deliberately slow — tension comes from pace
const ACCELERATION := 10.0       # quick stop/start so control feels deliberate, not slippery
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0022

@onready var camera: Camera3D = $Camera3D

var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_pitch = camera.rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENSITIVITY, -PI / 2.0, PI / 2.0)
		camera.rotation.x = _pitch
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	# move_toward gives a tiny bit of inertia without feeling like ice skating
	velocity.x = move_toward(velocity.x, direction.x * WALK_SPEED, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * WALK_SPEED, ACCELERATION * delta)

	move_and_slide()
