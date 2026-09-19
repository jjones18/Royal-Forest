class_name SpellProjectile
extends Area3D

const COLLISION_LAYER := 8
const COLLISION_MASK := 5

var definition: SpellDefinition
var direction := Vector3.FORWARD
var distance_travelled := 0.0
var caster: CollisionObject3D
var spent := false
var _spawn_origin := Vector3.ZERO

func configure(spell: SpellDefinition, origin: Vector3, aim_direction: Vector3, source: CollisionObject3D = null) -> void:
	definition = spell
	_spawn_origin = origin
	direction = aim_direction.normalized()
	caster = source

func _ready() -> void:
	global_position = _spawn_origin
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	monitoring = true
	monitorable = true
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = definition.projectile_radius if definition != null else 0.16
	collision.shape = shape
	add_child(collision)
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = shape.radius
	mesh.height = shape.radius * 2.0
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.8, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.55, 1.0)
	material.emission_energy_multiplier = 2.0
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _physics_process(delta: float) -> void:
	if spent or definition == null or delta <= 0.0:
		return
	var travel := minf(definition.projectile_speed * delta, definition.max_range - distance_travelled)
	if travel <= 0.0:
		_expire()
		return
	var start := global_position
	var target := start + direction * travel
	var radius := definition.projectile_radius
	var sweep_shape := SphereShape3D.new()
	sweep_shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sweep_shape
	query.collision_mask = COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	if caster != null:
		query.exclude.append(caster.get_rid())
	# Overlapping sphere samples turn the authored radius into the actual swept
	# collision envelope and prevent thin walls or large deltas from tunneling.
	var sample_count := maxi(1, ceili(travel / radius))
	for sample_index in range(sample_count + 1):
		var fraction := float(sample_index) / float(sample_count)
		var sample_position := start.lerp(target, fraction)
		query.transform = Transform3D(Basis.IDENTITY, sample_position)
		var hits := get_world_3d().direct_space_state.intersect_shape(query, 1)
		if not hits.is_empty():
			global_position = sample_position
			_resolve_hit(hits[0]["collider"])
			return
	global_position = target
	distance_travelled += travel
	if distance_travelled + 0.00001 >= definition.max_range:
		_expire()

func _resolve_hit(collider: Object) -> void:
	if spent:
		return
	spent = true
	if collider is EnemyController:
		(collider as EnemyController).take_hit(definition.damage, global_position - direction)
	queue_free()

func _expire() -> void:
	if spent:
		return
	spent = true
	queue_free()

static func distance_after(current_distance: float, speed: float, max_range_value: float, delta: float) -> float:
	return minf(max_range_value, current_distance + maxf(0.0, speed) * maxf(0.0, delta))
