extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const PROJECTILE := preload("res://game/combat/spell_projectile.tscn")
const ENEMY := preload("res://game/enemies/enemy_controller.tscn")
const SPELL: SpellDefinition = preload("res://game/data/spells/spectral_bolt.tres")

func test_projectile_contract_excludes_caster_layer_and_range_math(assertions: Assertions, fixture: RefCounted) -> bool:
	var projectile: SpellProjectile = PROJECTILE.instantiate()
	projectile.configure(SPELL, Vector3.ZERO, Vector3.FORWARD)
	fixture.add_node(projectile)
	await fixture.physics_frames(1)
	projectile.set_physics_process(false)
	assertions.equal(projectile.collision_layer, 8)
	assertions.equal(projectile.collision_mask, 5)
	assertions.equal(projectile.collision_mask & 2, 0, "projectile mask must never include player layer")
	assertions.equal(SpellProjectile.distance_after(23.0, 16.0, 24.0, 1.0), 24.0)
	return true

func test_projectile_hits_enemy_once(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := Node3D.new()
	fixture.add_node(root)
	var enemy: EnemyController = ENEMY.instantiate()
	enemy.position = Vector3(0, 0, -3)
	root.add_child(enemy)
	enemy.set_physics_process(false)
	var projectile: SpellProjectile = PROJECTILE.instantiate()
	projectile.configure(SPELL, Vector3(0, 0.8, 0), Vector3.FORWARD, null)
	root.add_child(projectile)
	await fixture.physics_frames(20)
	assertions.equal(enemy.hp, enemy.definition.max_hp - SPELL.damage, "enemy must take exactly one bolt hit")
	await fixture.physics_frames(5)
	assertions.equal(enemy.hp, enemy.definition.max_hp - SPELL.damage, "despawned bolt must not hit twice")
	return true

func test_large_delta_sweep_cannot_tunnel_through_enemy(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := Node3D.new()
	fixture.add_node(root)
	var enemy: EnemyController = ENEMY.instantiate()
	enemy.position = Vector3(0, 0, -3)
	root.add_child(enemy)
	enemy.set_physics_process(false)
	var projectile: SpellProjectile = PROJECTILE.instantiate()
	projectile.configure(SPELL, Vector3(0, 0.8, 0), Vector3.FORWARD)
	root.add_child(projectile)
	await fixture.physics_frames(1)
	projectile.set_physics_process(false)
	projectile._physics_process(0.25)
	assertions.equal(enemy.hp, enemy.definition.max_hp - SPELL.damage, "swept bolt must hit across a four-metre large-delta step")
	return true

func test_authored_radius_hits_near_miss_target(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := Node3D.new()
	fixture.add_node(root)
	var enemy: EnemyController = ENEMY.instantiate()
	enemy.position = Vector3(0.6, 0, -3)
	root.add_child(enemy)
	enemy.set_physics_process(false)
	var projectile: SpellProjectile = PROJECTILE.instantiate()
	projectile.configure(SPELL, Vector3(0, 0.8, 0), Vector3.FORWARD)
	root.add_child(projectile)
	await fixture.physics_frames(20)
	assertions.equal(enemy.hp, enemy.definition.max_hp - SPELL.damage, "authored projectile radius must contribute to collision, not only visuals")
	return true

func test_projectile_stops_on_world_wall(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := Node3D.new()
	fixture.add_node(root)
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(0, 0.8, -2)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2, 0.2)
	collision.shape = shape
	wall.add_child(collision)
	root.add_child(wall)
	var projectile: SpellProjectile = PROJECTILE.instantiate()
	projectile.configure(SPELL, Vector3(0, 0.8, 0), Vector3.FORWARD, null)
	root.add_child(projectile)
	await fixture.physics_frames(12)
	assertions.is_false(is_instance_valid(projectile), "bolt must despawn on first world hit")
	return true

func test_projectile_cleans_up_at_max_range(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := Node3D.new()
	fixture.add_node(root)
	var projectile: SpellProjectile = PROJECTILE.instantiate()
	projectile.configure(SPELL, Vector3.ZERO, Vector3.RIGHT, null)
	root.add_child(projectile)
	await fixture.physics_frames(100)
	assertions.is_false(is_instance_valid(projectile), "bolt must despawn at max range")
	return true
