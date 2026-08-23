class_name Player
extends CharacterBody3D
## Royal Forest player — first-person, slow deliberate pacing.
## Builds its own camera, weapon viewmodels, and interaction ray in _ready.
## Supports the Weapons.CATALOG set: bow (draw & loose) + sword/spear/axe melee.

const WALK_SPEED := 3.2          # deliberately slow — tension comes from pace
const ACCELERATION := 10.0
const GRAVITY := 14.0
const MOUSE_SENSITIVITY := 0.0022

const INTERACT_RANGE := 2.6
const ARROW_SPAWN_AHEAD := 0.9   # spawn point ahead of the camera (m)
const DRAW_TIME := 0.55          # draw before the arrow is ready to loose
const MIN_DRAW_FRACTION := 0.35  # releasing early still fires
const RELEASE_COOLDOWN := 0.35   # nock-another-arrow pause after a shot

var camera: Camera3D
var _pitch := 0.0
var _drawing := false            # bow is being drawn
var _draw_t := 0.0
var _swinging := false           # melee swing in progress
var _swing_t := 0.0
var _hit_done := false           # melee damage applied mid-swing
var _cooldown := 0.0
var _bare_hand_msg_cd := 0.0
var _ray: RayCast3D
var _bob_t := 0.0

var weapon_holder: Node3D
var _weapon_rest := Transform3D()
var _bow_frames: Array[Sprite3D] = []   # idle + 3 draw stages
var _melee_sprite: Sprite3D
var _melee_tex_cache := {}   # weapon id -> Texture2D (avoid load() per tick)


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

	_build_weapon_viewmodel()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _make_vm_sprite(tex_path: String) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = load(tex_path)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = false
	spr.no_depth_test = true      # never clip into walls
	spr.render_priority = 10
	return spr


func _build_weapon_viewmodel() -> void:
	weapon_holder = Node3D.new()
	weapon_holder.visible = false
	camera.add_child(weapon_holder)

	# --- bow: 4-frame Minecraft-style draw set ---
	for path in ["res://assets/sprites/bow.png", "res://assets/sprites/bow_pull_1.png",
			"res://assets/sprites/bow_pull_2.png", "res://assets/sprites/bow_pull_3.png"]:
		var f := _make_vm_sprite(path)
		f.pixel_size = 0.0018     # 256 px -> ~0.46 m
		f.position = Vector3(0.34, -0.34, -0.66)
		f.rotation_degrees = Vector3(-4, -10, -8)
		f.visible = path.ends_with("bow.png")   # idle frame first
		weapon_holder.add_child(f)
		_bow_frames.append(f)

	# --- melee viewmodels share one sprite slot; texture swaps per weapon ---
	_melee_sprite = _make_vm_sprite("res://assets/sprites/sword.png")
	_melee_sprite.pixel_size = 0.0018
	_melee_sprite.position = Vector3(0.44, -0.40, -0.66)
	_melee_sprite.rotation_degrees = Vector3(-6, -14, -14)
	_melee_sprite.visible = false
	weapon_holder.add_child(_melee_sprite)

	_weapon_rest = weapon_holder.transform


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
		_attack_pressed()
	elif event.is_action_released("attack"):
		_attack_released()
	elif event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_bare_hand_msg_cd = maxf(0.0, _bare_hand_msg_cd - delta)
	if weapon_holder != null:
		_update_viewmodel_visibility()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	# attacking/drawing slows you to half speed — committing to a shot is a risk
	var busy := _drawing or _swinging
	var speed := WALK_SPEED * (0.5 if busy else 1.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)

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

func _is_ranged() -> bool:
	if GameState.weapon == "":
		return false
	return Weapons.CATALOG[GameState.weapon]["ranged"] as bool


func _attack_pressed() -> void:
	if GameState.dead or GameState.game_won or _drawing or _swinging \
			or _cooldown > 0.0:
		return
	if GameState.weapon == "":
		if _bare_hand_msg_cd <= 0.0:
			GameState.say("No weapon but my hands.")
			_bare_hand_msg_cd = 2.0
		return
	if _is_ranged():
		_drawing = true
		_draw_t = 0.0
	else:
		_swinging = true
		_swing_t = 0.0
		_hit_done = false
		_cooldown = Weapons.CATALOG[GameState.weapon]["cooldown"]


func _attack_released() -> void:
	if _drawing:
		_drawing = false
		# weapon changed (or vanished) mid-draw — no shot
		if GameState.dead or GameState.game_won or not _is_ranged():
			return
		if _draw_t < DRAW_TIME * MIN_DRAW_FRACTION:
			return   # tapped too fast — treat as a mispress
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
	weapon_holder.transform = _weapon_rest
	var tw := create_tween()
	tw.tween_property(weapon_holder, "position:z", _weapon_rest.origin.z + 0.05,
			0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(weapon_holder, "position", _weapon_rest.origin, 0.18)


func _update_viewmodel_visibility() -> void:
	var w: String = GameState.weapon
	weapon_holder.visible = w != ""
	if w == "":
		return
	var ranged: bool = Weapons.CATALOG[w]["ranged"]
	# don't fight _process over draw frames while a draw is in progress
	for f in _bow_frames:
		f.visible = ranged and not _drawing and f.get_index() == 0
	_melee_sprite.visible = w != "" and not ranged
	if not ranged and w != "":
		if not _melee_tex_cache.has(w):
			_melee_tex_cache[w] = load("res://assets/sprites/%s.png" % w)
		_melee_sprite.texture = _melee_tex_cache[w]


func _process(delta: float) -> void:
	if weapon_holder == null:
		return
	# dead or disarmed mid-attack: cancel any in-flight swing/draw cleanly
	if GameState.dead or GameState.game_won or GameState.weapon == "":
		_drawing = false
		_swinging = false
		for i in _bow_frames.size():
			_bow_frames[i].visible = i == 0
		weapon_holder.transform = _weapon_rest
		return

	if _drawing:
		_draw_t += delta
		var f := clampf(_draw_t / DRAW_TIME, 0.0, 1.0)
		# Minecraft-style frame stages at ~1/3 thresholds
		var stage := mini(int(f * 3.0), 2) + 1   # 1..3
		for i in _bow_frames.size():
			_bow_frames[i].visible = i == stage
		# subtle whole-bow pull toward the shoulder as tension builds
		var target := _weapon_rest.origin + Vector3(-0.05 * f, -0.015 * f, 0.06 * f)
		weapon_holder.position = weapon_holder.position.lerp(target, 12.0 * delta)
	elif _swinging:
		_swing_t += delta
		var info: Dictionary = Weapons.CATALOG[GameState.weapon]
		var st: float = info["swing_time"]
		var t := clampf(_swing_t / st, 0.0, 1.0)
		# wind up-back, then sweep through; damage lands at 35% of the swing
		var ang := lerpf(0.0, 74.0, smoothstep(0.0, 1.0, t))
		var rest_euler := _weapon_rest.basis.get_euler()
		weapon_holder.rotation = Vector3(rest_euler.x, rest_euler.y,
				rest_euler.z - deg_to_rad(ang))
		if not _hit_done and t >= 0.35:
			_hit_done = true
			_apply_melee_hit(info)
		if _swing_t >= st:
			_swinging = false
			weapon_holder.transform = _weapon_rest
	else:
		# settle back to rest
		for i in _bow_frames.size():
			_bow_frames[i].visible = i == 0
		weapon_holder.transform = weapon_holder.transform.interpolate_with(
				_weapon_rest, minf(10.0 * delta, 1.0))


## Melee hit: sphere sweep in front of the camera inside an acceptance cone.
## Reach/arc/damage come from the weapon's catalog entry.
func _apply_melee_hit(info: Dictionary) -> void:
	if GameState.dead or GameState.game_won or _is_ranged():
		return
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var reach: float = info["reach"]
	# band from 1.4 m out to `reach`; clamped so short weapons keep a valid sphere
	var radius: float = maxf(0.15, reach - 1.4)
	var center := camera.global_position + forward * (reach - radius)
	center.y -= 1.2  # bring sweep down to torso height (camera is at 1.6)

	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	params.shape = sphere
	params.transform = Transform3D(Basis.IDENTITY, center)
	params.collision_mask = 4  # enemies layer
	params.exclude = [get_rid()]

	var hits := get_world_3d().direct_space_state.intersect_shape(params, 16)
	for hit in hits:
		var c: Object = hit["collider"]
		if c == null or not c.has_method("take_damage"):
			continue
		var to_c: Vector3 = c.global_position - global_position
		to_c.y = 0.0
		if to_c.length() < 0.01 or forward.dot(to_c.normalized()) >= info["arc_cos"]:
			c.take_damage(info["damage"], global_position)
