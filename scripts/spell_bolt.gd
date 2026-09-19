class_name SpellBolt
extends Area3D
## Magic projectile fired by the player. kind = "fire" | "frost".
## Fire: impact damage + chance to ignite the target (DoT).
## Frost: light impact damage + 30% slow for a duration.
## Self-contained like Arrow: builds its own mesh + world-check ray.

const SPEED := 14.0
const MAX_LIFETIME := 4.0

const FIRE_DAMAGE := 20
const FIRE_CHANCE := 0.5      # 50% to catch the mob on fire
const FIRE_TICKS := 4         # burn ticks (6 dmg each, 0.8 s apart)
const FROST_DAMAGE := 8
const FROST_SLOW := 0.7       # -30% speed
const FROST_DURATION := 3.0

var kind := "fire"
var velocity := Vector3.ZERO
var _life := 0.0
var _stuck := false
var _ray: RayCast3D


static func make(from: Vector3, dir: Vector3, spell_kind: String) -> SpellBolt:
	var b := SpellBolt.new()
	b.kind = spell_kind
	b.position = from + dir.normalized() * 0.9
	b.velocity = dir.normalized() * SPEED + Vector3.UP * 1.2   # slight loft
	return b


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4   # world + enemies

	# glowing core + halo, colored per school
	var fire := kind == "fire"
	var core_color := Color(1.0, 0.45, 0.12) if fire else Color(0.45, 0.75, 1.0)
	var halo_color := Color(1.0, 0.25, 0.05, 0.35) if fire else Color(0.55, 0.85, 1.0, 0.3)

	var core := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.09
	sph.height = 0.18
	sph.radial_segments = 10
	sph.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = core_color
	mat.emission_enabled = true
	mat.emission = core_color
	mat.emission_energy_multiplier = 1.6
	sph.material = mat
	core.mesh = sph
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)

	var halo := MeshInstance3D.new()
	var hsph := SphereMesh.new()
	hsph.radius = 0.16
	hsph.height = 0.32
	hsph.radial_segments = 10
	hsph.rings = 6
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(halo_color, 0.0)   # unshaded-ish via low alpha
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.albedo_color = halo_color
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hsph.material = hmat
	halo.mesh = hsph
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)

	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.16
	cs.shape = shape
	add_child(cs)

	_ray = RayCast3D.new()
	_ray.name = "Ray"
	_ray.enabled = false
	_ray.collision_mask = 1
	_ray.collide_with_areas = false
	add_child(_ray)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _stuck:
		return
	_life += delta
	if _life > MAX_LIFETIME:
		queue_free()
		return

	velocity.y -= 2.0 * delta   # gentle arc — spells are heavier than arrows feel
	var motion := velocity * delta
	global_position += motion

	if motion.length() > 0.001:
		_ray.target_position = _ray.to_local(global_position + motion * 2.0)
		_ray.force_raycast_update()
		if _ray.is_colliding():
			_impact(null, _ray.get_collision_point())


func _on_body_entered(body: Node3D) -> void:
	if not _stuck:
		_impact(body, global_position)


func _impact(collider: Object, point: Vector3) -> void:
	_stuck = true
	set_physics_process(false)
	set_deferred("monitoring", false)

	if collider != null and collider.has_method("take_damage") \
			and collider.is_in_group("enemies"):
		var from_pos: Vector3 = global_position - velocity.normalized()
		if kind == "fire":
			collider.take_damage(FIRE_DAMAGE, from_pos)
			if randf() < FIRE_CHANCE and collider.has_method("apply_burn"):
				collider.apply_burn(FIRE_TICKS, 6)
		else:
			collider.take_damage(FROST_DAMAGE, from_pos)
			if collider.has_method("apply_slow"):
				collider.apply_slow(FROST_SLOW, FROST_DURATION)

	global_position = point
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.8, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)   # burst
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.22)
	tw.tween_callback(queue_free)
