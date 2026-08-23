class_name Arrow
extends Area3D
## Projectile: flies straight (slight drop), damages the first enemy hit,
## sticks into world geometry, then shrinks away.
## Self-contained: builds its own shaft/head meshes and world-check ray.

const SPEED := 18.0
const GRAVITY := 4.0        # gentle arc, not simulated ballistics
const MAX_LIFETIME := 4.0
const DAMAGE := 25

var velocity := Vector3.ZERO
var _life := 0.0
var _stuck := false
var _ray: RayCast3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4   # world + enemies

	# hitbox near the arrowhead
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.12
	cs.shape = sph
	cs.position = Vector3(0, 0, 0.28)
	add_child(cs)

	# shaft (+Z is the flight direction)
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.height = 0.55
	cyl.radial_segments = 6
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.33, 0.18)
	cyl.material = wood
	shaft.mesh = cyl
	shaft.rotation_degrees = Vector3(90, 0, 0)   # cylinder Y-axis -> +Z
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft)

	# head
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.02
	cone.height = 0.08
	cone.radial_segments = 6
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.75, 0.77, 0.82)
	cone.material = steel
	tip.mesh = cone
	tip.rotation_degrees = Vector3(-90, 0, 0)
	tip.position = Vector3(0, 0, 0.31)
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tip)

	# world-only sweep ray (enemies arrive via body_entered)
	_ray = RayCast3D.new()
	_ray.name = "Ray"
	_ray.enabled = false
	_ray.collision_mask = 1
	_ray.collide_with_areas = false
	add_child(_ray)

	body_entered.connect(_on_body_entered)

	# Godot's forward is -Z, and look_at() aims -Z at the target — so aim it
	# BACKWARD along the velocity to make local +Z (where the head meshes are)
	# point along the flight direction.
	if velocity.length() > 0.01:
		var fwd := global_position + velocity
		look_at(fwd - 2.0 * velocity, Vector3.UP)


## Convenience for tests / scripted shots: aim from `from` toward `dir`.
static func make(from: Vector3, dir: Vector3) -> Arrow:
	var arrow := Arrow.new()
	arrow.position = from + dir.normalized() * 0.9
	arrow.velocity = dir.normalized() * SPEED
	return arrow


func _physics_process(delta: float) -> void:
	if _stuck:
		return
	_life += delta
	if _life > MAX_LIFETIME:
		queue_free()
		return

	velocity.y -= GRAVITY * delta
	var motion := velocity * delta
	global_position += motion
	if velocity.length() > 0.01:
		# same -Z correction as _ready (see comment there)
		look_at(global_position - 2.0 * velocity, Vector3.UP)

	# swept check so fast arrows don't tunnel through thin walls
	if motion.length() > 0.001:
		_ray.target_position = _ray.to_local(global_position + motion * 2.0)
	_ray.force_raycast_update()
	if _ray.is_colliding():
		_hit(_ray.get_collider(), _ray.get_collision_point())


func _on_body_entered(body: Node3D) -> void:
	if not _stuck:
		_hit(body, global_position)


func _hit(collider: Object, point: Vector3) -> void:
	if collider != null and collider.has_method("take_damage") \
			and collider.is_in_group("enemies"):
		collider.take_damage(DAMAGE, global_position - velocity.normalized())
	_stuck = true
	set_physics_process(false)
	set_deferred("monitoring", false)   # can't flip during a signal callback
	global_position = point
	# stick for a moment, then shrink away (GL-safe fade)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
